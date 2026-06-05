import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ImageHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Picks an image from the gallery and compresses it for profile use.
  /// Returns the compressed file or null on cancel/error.
  static Future<File?> pickAndCompressToFile() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return null;

      final file = File(pickedFile.path);
      final tempDir = await getTemporaryDirectory();
      final targetPath = p.join(tempDir.path, "temp_compressed.jpg");

      var result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 70,
        minWidth: 500,
        minHeight: 500,
      );
      if (result == null) return null;

      var compressed = File(result.path);
      if (await compressed.length() > 1 * 1024 * 1024) {
        final result2 = await FlutterImageCompress.compressAndGetFile(
          file.absolute.path,
          targetPath,
          quality: 40,
          minWidth: 300,
          minHeight: 300,
        );
        if (result2 != null) compressed = File(result2.path);
      }
      return compressed;
    } catch (e) {
      debugPrint("Error picking/compressing image: $e");
      return null;
    }
  }

  /// Backwards-compat helper used by existing callers that still expect a
  /// base64 string. New code should use [pickCompressAndUpload] instead.
  static Future<String?> pickAndCompressImage() async {
    final file = await pickAndCompressToFile();
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  /// Picks, compresses, and uploads a profile photo to Firebase Storage at
  /// `users/{uid}/avatar.jpg`. Returns the download URL on success.
  static Future<String?> pickCompressAndUpload(String uid) async {
    final compressed = await pickAndCompressToFile();
    if (compressed == null) return null;
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(uid)
          .child('avatar.jpg');
      final bytes = await compressed.readAsBytes();
      final task = await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await task.ref.getDownloadURL();
    } catch (e) {
      debugPrint("Error uploading avatar: $e");
      return null;
    }
  }
}
