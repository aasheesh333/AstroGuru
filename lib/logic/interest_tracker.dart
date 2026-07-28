import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'user_session.dart';

class InterestTracker {
  static const String _storageKey = 'interest_counts';
  static const int _syncIntervalMs = 60 * 60 * 1000;
  static const Set<String> _validCategories = {
    'horoscope',
    'kundli',
    'chat',
    'love_match',
    'remedies',
  };

  static Future<void> track(String category) async {
    if (!_validCategories.contains(category)) return;
    try {
      final current = await getInterests();
      current[category] = (current[category] ?? 0) + 1;
      await UserSession.setString(_storageKey, _encode(current));
      await _maybeSync(current);
    } catch (e) {
      if (kDebugMode) debugPrint('InterestTracker.track error: $e');
    }
  }

  static Future<Map<String, int>> getInterests() async {
    final raw = await UserSession.getString(_storageKey);
    if (raw == null || raw.isEmpty) return {};
    return _decode(raw);
  }

  static String getInterestsSummary(Map<String, int> interests) {
    if (interests.isEmpty) return '';
    final total = interests.values.fold(0, (a, b) => a + b);
    if (total == 0) return '';
    final entries = interests.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries
        .take(3)
        .map((e) => '${e.key} (${((e.value / total) * 100).round()}%)')
        .join(', ');
  }

  static Future<void> syncNow({Map<String, int>? overrides}) async {
    final counts = overrides ?? await getInterests();
    await _writeToFirestore(counts);
    await UserSession.setInt('${_storageKey}_last_sync', DateTime.now().millisecondsSinceEpoch);
  }

  static Future<void> _maybeSync(Map<String, int> counts) async {
    final lastSync = await UserSession.getInt('${_storageKey}_last_sync') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - lastSync < _syncIntervalMs) return;
    await _writeToFirestore(counts);
    await UserSession.setInt('${_storageKey}_last_sync', now);
  }

  static Future<void> _writeToFirestore(Map<String, int> counts) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'interests': counts,
        'last_interest_sync': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) debugPrint('InterestTracker.syncToFirestore error: $e');
    }
  }

  static Future<Map<String, int>> loadFromFirestore(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) return {};
      final raw = doc.data()!['interests'];
      if (raw is! Map) return {};
      return raw.map((k, v) => MapEntry(k.toString(), (v is int) ? v : 0));
    } catch (e) {
      if (kDebugMode) debugPrint('InterestTracker.loadFromFirestore error: $e');
      return {};
    }
  }

  static Future<void> persistFromFirestore(Map<String, int> counts) async {
    await UserSession.setString(_storageKey, _encode(counts));
  }

  static Map<String, int> _decode(String raw) {
    try {
      final Map<String, dynamic> decoded = jsonDecode(raw);
      return decoded.map((k, v) => MapEntry(k, (v is int) ? v : 0));
    } catch (_) {
      return {};
    }
  }

  static String _encode(Map<String, int> counts) {
    return jsonEncode(counts);
  }
}
