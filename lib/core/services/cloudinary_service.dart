import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:nexus_app/core/config/cloudinary_config.dart';

class CloudinaryService {
  Future<String?> uploadImage(File file) async {
    if (CloudinaryConfig.cloudName.isEmpty ||
        CloudinaryConfig.apiKey.isEmpty ||
        CloudinaryConfig.apiSecret.isEmpty) {
      throw 'Cloudinary credentials are not fully configured in cloudinary_config.dart.';
    }

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      // Calculate Cloudinary signature: parameters sorted alphabetically, joined, and appended with API secret.
      // For a simple upload, only 'timestamp' needs signing.
      final signatureBase = 'timestamp=$timestamp${CloudinaryConfig.apiSecret}';
      
      // Hash with SHA-1
      final bytes = utf8.encode(signatureBase);
      final signature = sha1.convert(bytes).toString();

      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload',
      );

      final request = http.MultipartRequest('POST', uri)
        ..fields['api_key'] = CloudinaryConfig.apiKey
        ..fields['timestamp'] = timestamp.toString()
        ..fields['signature'] = signature
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = await response.stream.bytesToString();
        final jsonDecoded = jsonDecode(responseData);
        return jsonDecoded['secure_url'] as String?;
      } else {
        final errorResponse = await response.stream.bytesToString();
        throw 'Cloudinary API error. Code: ${response.statusCode}, Body: $errorResponse';
      }
    } catch (e) {
      throw 'Cloudinary Upload Failure: $e';
    }
  }
}
