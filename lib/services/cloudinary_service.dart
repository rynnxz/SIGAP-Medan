import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/secrets.dart';

class CloudinaryService {
  static const String cloudName    = AppSecrets.cloudinaryCloudName;
  static const String uploadPreset = AppSecrets.cloudinaryUploadPreset;
  static const String apiKey       = AppSecrets.cloudinaryApiKey;
  static const String apiSecret    = AppSecrets.cloudinaryApiSecret;

  // Upload image to Cloudinary
  Future<Map<String, dynamic>> uploadImage({
    required File imageFile,
    String? folder,
    Map<String, dynamic>? transformation,
  }) async {
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      
      final request = http.MultipartRequest('POST', url);
      
      // Add file
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );
      
      // Add upload preset (unsigned upload)
      request.fields['upload_preset'] = uploadPreset;
      
      // Add folder if specified
      if (folder != null) {
        request.fields['folder'] = folder;
      }
      
      // Add transformation if specified (Cloudinary expects string format e.g. "w_1200,q_80")
      if (transformation != null) {
        final parts = <String>[];
        transformation.forEach((key, value) {
          switch (key) {
            case 'width':        parts.add('w_$value'); break;
            case 'height':       parts.add('h_$value'); break;
            case 'crop':         parts.add('c_$value'); break;
            case 'gravity':      parts.add('g_$value'); break;
            case 'quality':      parts.add('q_$value'); break;
            case 'fetch_format': parts.add('f_$value'); break;
            default:             parts.add('${key}_$value');
          }
        });
        request.fields['transformation'] = parts.join(',');
      }
      
      // Send request
      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      final jsonResponse = jsonDecode(responseString);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'url': jsonResponse['secure_url'],
          'publicId': jsonResponse['public_id'],
          'width': jsonResponse['width'],
          'height': jsonResponse['height'],
          'format': jsonResponse['format'],
          'bytes': jsonResponse['bytes'],
        };
      } else {
        return {
          'success': false,
          'error': jsonResponse['error']['message'] ?? 'Upload failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Upload with automatic optimization
  Future<Map<String, dynamic>> uploadOptimizedImage({
    required File imageFile,
    String? folder,
    int quality = 80,
    int maxWidth = 1920,
  }) async {
    return await uploadImage(
      imageFile: imageFile,
      folder: folder,
      transformation: {
        'quality': quality,
        'fetch_format': 'auto',
        'width': maxWidth,
        'crop': 'limit',
      },
    );
  }

  // Upload profile photo (circular crop, smaller size)
  Future<Map<String, dynamic>> uploadProfilePhoto({
    required File imageFile,
  }) async {
    return await uploadImage(
      imageFile: imageFile,
      folder: 'profiles',
      transformation: {
        'width': 400,
        'height': 400,
        'crop': 'fill',
        'gravity': 'face',
        'quality': 85,
        'fetch_format': 'auto',
      },
    );
  }

  // Upload report photo (optimized for reports)
  Future<Map<String, dynamic>> uploadReportPhoto({
    required File imageFile,
  }) async {
    return await uploadImage(
      imageFile: imageFile,
      folder: 'reports',
    );
  }

  // Upload destination photo (high quality)
  Future<Map<String, dynamic>> uploadDestinationPhoto({
    required File imageFile,
  }) async {
    return await uploadImage(
      imageFile: imageFile,
      folder: 'destinations',
    );
  }

  // Upload completion proof photo (bukti penyelesaian laporan)
  Future<Map<String, dynamic>> uploadCompletionPhoto({
    required File imageFile,
  }) async {
    return await uploadImage(
      imageFile: imageFile,
      folder: 'completion_proofs',
      transformation: {
        'quality': 80,
        'fetch_format': 'auto',
        'width': 1200,
        'crop': 'limit',
      },
    );
  }

  // Delete image from Cloudinary
  Future<Map<String, dynamic>> deleteImage(String publicId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final signature = _generateSignature(publicId, timestamp);
      
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/destroy');
      
      final response = await http.post(
        url,
        body: {
          'public_id': publicId,
          'signature': signature,
          'api_key': apiKey,
          'timestamp': timestamp,
        },
      );
      
      final jsonResponse = jsonDecode(response.body);
      
      if (response.statusCode == 200 && jsonResponse['result'] == 'ok') {
        return {
          'success': true,
          'message': 'Image deleted successfully',
        };
      } else {
        return {
          'success': false,
          'error': jsonResponse['error']?['message'] ?? 'Delete failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Generate signature for authenticated requests
  String _generateSignature(String publicId, String timestamp) {
    // This is a simplified version
    // In production, generate signature on backend for security
    final stringToSign = 'public_id=$publicId&timestamp=$timestamp$apiSecret';
    return stringToSign; // Use crypto package for actual SHA-1 hash
  }

  // Get optimized URL with transformations
  String getOptimizedUrl(
    String originalUrl, {
    int? width,
    int? height,
    int quality = 80,
    String? format,
  }) {
    if (!originalUrl.contains('cloudinary.com')) {
      return originalUrl;
    }

    final transformations = <String>[];
    
    if (width != null) transformations.add('w_$width');
    if (height != null) transformations.add('h_$height');
    transformations.add('q_$quality');
    if (format != null) transformations.add('f_$format');
    
    final transformation = transformations.join(',');
    
    // Insert transformation into URL
    return originalUrl.replaceFirst(
      '/upload/',
      '/upload/$transformation/',
    );
  }

  // Get thumbnail URL
  String getThumbnailUrl(String originalUrl, {int size = 200}) {
    return getOptimizedUrl(
      originalUrl,
      width: size,
      height: size,
      quality: 70,
    );
  }

  // Get responsive URLs for different screen sizes
  Map<String, String> getResponsiveUrls(String originalUrl) {
    return {
      'thumbnail': getThumbnailUrl(originalUrl, size: 200),
      'small': getOptimizedUrl(originalUrl, width: 400),
      'medium': getOptimizedUrl(originalUrl, width: 800),
      'large': getOptimizedUrl(originalUrl, width: 1200),
      'original': originalUrl,
    };
  }
}
