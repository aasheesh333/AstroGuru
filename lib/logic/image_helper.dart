import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ImageHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Picks an image from the gallery, compresses it (target ~10kb), and returns Base64 string.
  /// Returns null if user cancels or error occurs.
  static Future<String?> pickAndCompressImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return null;

      File file = File(pickedFile.path);

      // Get temp dir
      final tempDir = await getTemporaryDirectory();
      final targetPath = p.join(tempDir.path, "temp_compressed.jpg");

      // Compress
      // We aim for low quality to keep it small for Base64 storage in Firestore/Prefs
      var result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 50, // Start with 50%
        minWidth: 500, // Resize to decent profile size
        minHeight: 500,
      );

      if (result == null) return null;

      File compressedFile = File(result.path);
      int size = await compressedFile.length();

      // If still too big (>20KB), compress further aggressively
      if (size > 20480) {
        var result2 = await FlutterImageCompress.compressAndGetFile(
          file.absolute.path,
          targetPath,
          quality: 20,
          minWidth: 300,
          minHeight: 300,
        );
        if (result2 != null) {
          compressedFile = File(result2.path);
        }
      }

      // Convert to Base64
      List<int> imageBytes = await compressedFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      return base64Image;
    } catch (e) {
      print("Error picking/compressing image: $e");
      return null;
    }
  }
}
