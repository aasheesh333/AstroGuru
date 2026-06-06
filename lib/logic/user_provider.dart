import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'kundli_context.dart';
import 'recent_mentions.dart';
import 'user_context_builder.dart';
import 'user_session.dart';
import 'kundli_service.dart';

class UserProvider extends ChangeNotifier {
  String _name = "User";
  String _email = "";
  String _dob = "";
  String _birthTime = "";
  String _birthPlace = "";
  String? _profileImageBase64;
  String? _profileImageUrl;
  String _zodiac = "Aries";

  String get name => _name;
  String get email => _email;
  String get dob => _dob;
  String get birthTime => _birthTime;
  String get birthPlace => _birthPlace;
  String? get profileImageBase64 => _profileImageBase64;
  String? get profileImageUrl => _profileImageUrl;
  String get zodiac => _zodiac;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  Future<void> loadUserData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _email = user.email ?? "";

        // Priority: Session (Local Cache) -> Firestore -> Auth Profile
        _name = await UserSession.getUserName();
        _dob = await UserSession.getUserDob();
        _birthTime = await UserSession.getBirthTime();
        _birthPlace = await UserSession.getBirthPlace();
        _profileImageBase64 = await UserSession.getProfileImage();
        _profileImageUrl = await UserSession.getProfileImageUrl();

        // Ensure zodiac is set
        String? z = await UserSession.getString('user_zodiac');
        if (z != null) {
          _zodiac = z;
        } else if (_dob.isNotEmpty) {
           try {
             _zodiac = KundliService.getSunSign(DateTime.parse(_dob));
           } catch (_) {}
        }

        // Lazy migration: if we still have a base64 string but no URL, upload
        // the base64 image to Firebase Storage and persist the download URL.
        if (_profileImageBase64 != null && _profileImageBase64!.isNotEmpty &&
            (_profileImageUrl == null || _profileImageUrl!.isEmpty)) {
          await _migrateBase64ToStorage(user.uid);
        }

        // Pull profile_image_url from Firestore if missing locally.
        if (_profileImageUrl == null || _profileImageUrl!.isEmpty) {
          final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          if (doc.exists && doc.data() != null) {
            final data = doc.data()!;
            if (data['profile_image_url'] is String &&
                (data['profile_image_url'] as String).isNotEmpty) {
              _profileImageUrl = data['profile_image_url'] as String;
              await UserSession.setString('profile_image_url', _profileImageUrl!);
            }
            if (_profileImageBase64 == null && data['profile_image_base64'] is String) {
               _profileImageBase64 = data['profile_image_base64'] as String;
               await UserSession.setString('profile_image_base64', _profileImageBase64!);
            }
          }
        }
      } else {
        // Guest
        _name = "Guest User";
        _email = "";
      }
    } catch (e) {
      debugPrint("Error loading user data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// One-shot migration: decode the legacy base64 profile photo, upload to
  /// Firebase Storage at `users/{uid}/avatar.jpg`, persist the download URL,
  /// and clear the base64 from local + Firestore.
  Future<void> _migrateBase64ToStorage(String uid) async {
    try {
      final bytes = await _decodeBase64(_profileImageBase64!);
      if (bytes.isEmpty) return;
      final ref = FirebaseStorage.instance.ref().child('users').child(uid).child('avatar.jpg');
      final task = await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final url = await task.ref.getDownloadURL();
      _profileImageUrl = url;
      _profileImageBase64 = null;
      await UserSession.setString('profile_image_url', url);
      await UserSession.remove('profile_image_base64');
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'profile_image_url': url,
      }, SetOptions(merge: true));
      // Best-effort: clear legacy base64 in Firestore too.
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'profile_image_base64': FieldValue.delete(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Base64 -> Storage migration failed: $e");
      // Stay on base64 so the user still sees their photo; the next launch will retry.
    }
  }

  Future<Uint8List> _decodeBase64(String b64) async {
    try {
      return base64Decode(b64);
    } catch (_) {
      return Uint8List(0);
    }
  }

  Future<void> updateProfile({
    String? newName,
    DateTime? newDob,
    String? newBirthTime,
    String? newBirthPlace,
    String? newImageBase64,
    String? newImageUrl,
    bool updateFirestore = true
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (newName != null) {
      _name = newName;
      await UserSession.setString('user_name', newName);
      if (updateFirestore) {
         await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
           {'name': newName}, SetOptions(merge: true)
         );
         await user.updateDisplayName(newName);
      }
    }

    if (newDob != null) {
      _dob = newDob.toIso8601String();
      await UserSession.setString('user_dob', _dob);
      _zodiac = KundliService.getSunSign(newDob);
      await UserSession.setString('user_zodiac', _zodiac);

      if (updateFirestore) {
         await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
           {'dob': _dob}, SetOptions(merge: true)
         );
      }
    }

    if (newBirthTime != null) {
      _birthTime = newBirthTime;
      await UserSession.setBirthTime(newBirthTime);
      if (updateFirestore) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
          {'birth_time': newBirthTime}, SetOptions(merge: true)
        );
      }
    }

    if (newBirthPlace != null) {
      _birthPlace = newBirthPlace;
      await UserSession.setBirthPlace(newBirthPlace);
      if (updateFirestore) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
          {'birth_place': newBirthPlace}, SetOptions(merge: true)
        );
      }
    }

    if (newImageUrl != null) {
      _profileImageUrl = newImageUrl;
      _profileImageBase64 = null;
      await UserSession.setString('profile_image_url', newImageUrl);
      await UserSession.remove('profile_image_base64');
      if (updateFirestore) {
         await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
           'profile_image_url': newImageUrl,
           'profile_image_base64': FieldValue.delete(),
         }, SetOptions(merge: true));
      }
    } else if (newImageBase64 != null) {
      _profileImageBase64 = newImageBase64;
      await UserSession.setString('profile_image_base64', newImageBase64);
      if (updateFirestore) {
         await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
           {'profile_image_base64': newImageBase64}, SetOptions(merge: true)
         );
      }
    }

    notifyListeners();
  }

  void clear() {
    _name = "User";
    _email = "";
    _birthTime = "";
    _birthPlace = "";
    _profileImageBase64 = null;
    _profileImageUrl = null;
    notifyListeners();
  }

  /// Builds a 1-paragraph, AI-friendly narrative of this user's kundli
  /// chart, suitable for embedding in prompts (horoscope, chat, remedies).
  ///
  /// Returns the empty string when:
  /// * the user is a guest
  /// * no DOB is on file
  /// * the chart calculation fails for any reason
  ///
  /// Callers should check `.isNotEmpty` before passing the value to an AI
  /// service; the AI service methods already accept `null`/empty context
  /// and fall back to zodiac-only prompts.
  String getKundliContext() {
    if (_dob.isEmpty) return '';
    DateTime? dob;
    try {
      dob = DateTime.parse(_dob);
    } catch (_) {
      return '';
    }

    final (lat, lon) = KundliService.resolveLocation(_birthPlace);
    final hourMinute = _birthTime.split(':');
    int hour = 0;
    int minute = 0;
    if (hourMinute.length >= 2) {
      hour = int.tryParse(hourMinute[0]) ?? 0;
      minute = int.tryParse(hourMinute[1]) ?? 0;
    }
    final dt = DateTime(dob.year, dob.month, dob.day, hour, minute);

    Map<String, dynamic> chart;
    try {
      chart = KundliService.calculateChart(dt, lat, lon);
    } catch (_) {
      return '';
    }

    return KundliContextBuilder.build(
      chart: chart,
      birthDate: dob,
      birthTime: _birthTime.isEmpty ? null : _birthTime,
      birthPlace: _birthPlace.isEmpty ? null : _birthPlace,
    );
  }

  /// Builds the full AI context string for the user — identity (name,
  /// email, current address), zodiac, kundli chart, plus a caller-supplied
  /// [recent] digest of place/date/time mentioned in recent chat messages.
  ///
  /// Falls back to a minimal "Zodiac" line if the user has no birth data
  /// on file, so the AI Sage still knows who it is talking to.
  String getUserContext({RecentMentions recent = const RecentMentions()}) {
    return UserContextBuilder.build(
      name: _name,
      email: _email,
      zodiac: _zodiac,
      kundliContext: getKundliContext(),
      recent: recent,
    );
  }
}
