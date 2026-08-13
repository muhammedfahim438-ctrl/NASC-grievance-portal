import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class CloudinaryService {
  // Your Cloudinary account details from Phase 1
  static const String _cloudName = 'awmitkzw';
  static const String _uploadPreset = 'nasc_complaints';

  // Uploads one image (as raw bytes) to Cloudinary and returns its public URL.
  // Returns null if the upload fails.
  Future<String?> uploadImage(Uint8List imageBytes, String fileName) async {
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');

      // "Multipart" just means "this request contains a file, not just text"
      final request = http.MultipartRequest('POST', url);
      request.fields['upload_preset'] = _uploadPreset;
      request.files.add(
        http.MultipartFile.fromBytes('file', imageBytes, filename: fileName),
      );

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final jsonData = jsonDecode(responseBody);
        return jsonData['secure_url'] as String; // the public link to the uploaded photo
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Uploads a whole list of images one by one, and returns the list of URLs.
  // If some fail, we simply skip them rather than failing the entire complaint submission.
  Future<List<String>> uploadImages(List<Uint8List> imagesBytes) async {
    List<String> uploadedUrls = [];

    for (int i = 0; i < imagesBytes.length; i++) {
      final url = await uploadImage(imagesBytes[i], 'complaint_${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
      if (url != null) {
        uploadedUrls.add(url);
      }
    }

    return uploadedUrls;
  }
}