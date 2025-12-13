import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_session.dart';
import 'kundli_service.dart';

class UserProvider extends ChangeNotifier {
  String _name = "User";
  String _email = "";
  String _dob = "";
  String? _profileImageBase64;
  String _zodiac = "Aries";

  String get name => _name;
  String get email => _email;
  String get dob => _dob;
  String? get profileImageBase64 => _profileImageBase64;
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
        _profileImageBase64 = await UserSession.getProfileImage();

        // Ensure zodiac is set
        String? z = await UserSession.getString('user_zodiac');
        if (z != null) {
          _zodiac = z;
        } else if (_dob.isNotEmpty) {
           try {
             _zodiac = KundliService.getSunSign(DateTime.parse(_dob));
           } catch (_) {}
        }

        // Sync with Firestore if needed (lazy sync)
        // We trust UserSession as the active state, but let's check firestore for fresh profile image if null
        if (_profileImageBase64 == null) {
          final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          if (doc.exists && doc.data() != null) {
            final data = doc.data()!;
            if (data.containsKey('profile_image_base64')) {
               _profileImageBase64 = data['profile_image_base64'];
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
      print("Error loading user data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    String? newName,
    DateTime? newDob,
    String? newImageBase64,
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

    if (newImageBase64 != null) {
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
    _profileImageBase64 = null;
    notifyListeners();
  }
}
