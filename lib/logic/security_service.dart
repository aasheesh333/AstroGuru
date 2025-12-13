import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class SecurityService {
  static Future<void> checkPasswordResetLimit(String email) async {
    final sanitizedEmail = base64Url.encode(utf8.encode(email));
    final docRef = FirebaseFirestore.instance.collection('password_resets').doc(sanitizedEmail);

    final doc = await docRef.get();
    final now = DateTime.now();
    final windowStart = now.subtract(const Duration(hours: 24));

    List<DateTime> attempts = [];

    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      if (data.containsKey('attempts')) {
        final List<dynamic> timestamps = data['attempts'];
        attempts = timestamps
            .map((t) => (t as Timestamp).toDate())
            .where((d) => d.isAfter(windowStart)) // Filter > 24h
            .toList();
      }
    }

    if (attempts.length >= 5) {
      throw "Limit Exceeded: You have reached the maximum of 5 password reset attempts in 24 hours. Please try again later.";
    }

    // Add current attempt
    attempts.add(now);

    // Save back to Firestore
    await docRef.set({
      'attempts': attempts.map((d) => Timestamp.fromDate(d)).toList(),
      'email': email, // Store original email for reference/debugging if needed
      'last_attempt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
