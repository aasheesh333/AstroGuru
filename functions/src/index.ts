import * as functions from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import Groq from "groq-sdk";

admin.initializeApp();
const db = admin.firestore();

// ---------------------------------------------------------------------------
// In-memory cache for the single Groq API key. Rotated manually by the
// operator via the `groq_api_keys/groq_api_list` Firestore document; the
// app does NOT see the key directly anymore.
// ---------------------------------------------------------------------------

let cachedKey: string | null = null;
let cachedKeyAt = 0;
const KEY_TTL_MS = 5 * 60 * 1000;

async function getGroqKey(): Promise<string> {
  const now = Date.now();
  if (cachedKey && now - cachedKeyAt < KEY_TTL_MS) return cachedKey;
  const doc = await db.collection("groq_api_keys").doc("groq_api_list").get();
  if (!doc.exists) {
    throw new functions.HttpsError("failed-precondition", "Groq API key not configured.");
  }
  const data = doc.data() || {};
  const first = Object.values(data).find(
    (v) => typeof v === "string" && v.length > 0
  );
  if (!first) {
    throw new functions.HttpsError("failed-precondition", "Groq API key is empty.");
  }
  cachedKey = first as string;
  cachedKeyAt = now;
  return cachedKey;
}

// ---------------------------------------------------------------------------
// Rate limits. Conservative numbers because we have a single shared key.
// ---------------------------------------------------------------------------

const PER_MINUTE = 30;
const PER_DAY = 500;
const MINUTE_MS = 60 * 1000;
const DAY_MS = 24 * 60 * 60 * 1000;

async function checkRateLimit(uid: string): Promise<void> {
  const now = Date.now();
  const ref = db.collection("groq_usage").doc(uid);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.exists ? (snap.data() as Record<string, unknown>) : {};
    const minute = (Array.isArray(data.minute) ? data.minute : []) as admin.firestore.Timestamp[];
    const day = (Array.isArray(data.day) ? data.day : []) as admin.firestore.Timestamp[];

    const freshMinute = minute.filter(
      (t) => now - t.toMillis() < MINUTE_MS
    );
    const freshDay = day.filter(
      (t) => now - t.toMillis() < DAY_MS
    );
    if (freshMinute.length >= PER_MINUTE) {
      throw new functions.HttpsError(
        "resource-exhausted",
        "Too many requests. Please wait a minute."
      );
    }
    if (freshDay.length >= PER_DAY) {
      throw new functions.HttpsError(
        "resource-exhausted",
        "Daily limit reached. Please try again tomorrow."
      );
    }
    freshMinute.push(admin.firestore.Timestamp.now());
    freshDay.push(admin.firestore.Timestamp.now());
    tx.set(ref, { minute: freshMinute, day: freshDay }, { merge: true });
  });
}

async function logUsage(
  uid: string,
  status: "ok" | "rate_limited" | "error",
  latencyMs: number
): Promise<void> {
  try {
    await db.collection("groq_usage_log").add({
      uid,
      status,
      latencyMs,
      ts: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (_) {
    // Best-effort logging.
  }
}

// ---------------------------------------------------------------------------
// Public HTTPS callable: `groqProxy`.
// Accepts: { messages: ChatMessage[], lang: string, model?: string }
// Returns: { content: string } on success.
// ---------------------------------------------------------------------------

interface ChatMessage {
  role: "system" | "user" | "assistant";
  content: string;
}

interface GroqProxyRequest {
  messages: ChatMessage[];
  lang?: string;
  model?: string;
  maxTokens?: number;
  temperature?: number;
}

export const groqProxy = functions.onCall(
  {
    region: "us-central1",
    cors: false,
    enforceAppCheck: false,
  },
  async (req) => {
    if (!req.auth) {
      throw new functions.HttpsError(
        "unauthenticated",
        "Sign in to use the AI Sage."
      );
    }
    const uid = req.auth.uid;
    const data = req.data as GroqProxyRequest;
    if (
      !data ||
      !Array.isArray(data.messages) ||
      data.messages.length === 0
    ) {
      throw new functions.HttpsError(
        "invalid-argument",
        "Missing or empty `messages`."
      );
    }

    await checkRateLimit(uid);

    const apiKey = await getGroqKey();
    const groq = new Groq({ apiKey });

    const start = Date.now();
    try {
      const completion = await groq.chat.completions.create({
        model: data.model || "llama-3.3-70b-versatile",
        messages: data.messages,
        max_tokens: data.maxTokens || 1024,
        temperature: data.temperature ?? 0.7,
      });
      const content =
        completion.choices[0]?.message?.content?.toString() || "";
      await logUsage(uid, "ok", Date.now() - start);
      return { content };
    } catch (err: unknown) {
      const e = err as { status?: number; error?: { code?: string; message?: string } };
      const upstreamStatus = e?.status ?? 500;
      const upstreamMsg = e?.error?.message || (err as Error).message;
      await logUsage(uid, upstreamStatus === 429 ? "rate_limited" : "error", Date.now() - start);
      if (upstreamStatus === 429) {
        throw new functions.HttpsError(
          "resource-exhausted",
          "AI Sage is busy. Please try again in a moment."
        );
      }
      throw new functions.HttpsError("internal", `Upstream error: ${upstreamMsg}`);
    }
  }
);
