import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';

class SecurityService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Get Cloud Functions base URL
  String get _baseUrl {
    // Firebase Functions base URL (new project)
    return 'https://us-central1-love2learnsign-1914ce.cloudfunctions.net';
  }
  
  // Get device ID for mobile CAPTCHA verification
  Future<String> _getDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id; // Android ID
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown';
      }
    } catch (e) {
      debugPrint('Error getting device ID: $e');
    }
    return 'unknown';
  }
  
  // Check rate limit before signup
  Future<Map<String, dynamic>> checkRateLimit(String email, String ipAddress) async {
    try {
      final user = _auth.currentUser;
      final idToken = user != null ? await user.getIdToken() : null;
      
      final url = Uri.parse('$_baseUrl/checkRateLimit');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (idToken != null) 'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'data': {
            'email': email,
            'ipAddress': ipAddress,
          },
        }),
      );
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['result'] as Map<String, dynamic>? ?? {'allowed': true};
      } else {
        debugPrint('Rate limit check failed: ${response.statusCode}');
        // Fail open - allow signup if check fails
        return {'allowed': true};
      }
    } catch (e) {
      debugPrint('Error checking rate limit: $e');
      // Fail open - allow signup if check fails
      return {'allowed': true};
    }
  }
  
  // Verify CAPTCHA (for web) or device (for mobile)
  Future<Map<String, dynamic>> verifyCaptcha({String? captchaToken}) async {
    try {
      final user = _auth.currentUser;
      final idToken = user != null ? await user.getIdToken() : null;
      
      // For mobile, get device ID
      final deviceId = captchaToken == null ? await _getDeviceId() : null;
      
      final url = Uri.parse('$_baseUrl/verifyCaptcha');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (idToken != null) 'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'data': {
            if (captchaToken != null) 'captchaToken': captchaToken,
            if (deviceId != null) 'deviceId': deviceId,
          },
        }),
      );
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['result'] as Map<String, dynamic>? ?? {'verified': true};
      } else {
        debugPrint('CAPTCHA verification failed: ${response.statusCode}');
        // Fail open - allow signup if check fails
        return {'verified': true};
      }
    } catch (e) {
      debugPrint('Error verifying CAPTCHA: $e');
      // Fail open - allow signup if check fails
      return {'verified': true};
    }
  }
  
  // Get client IP address (simplified - in production, get from request headers)
  Future<String> getClientIp() async {
    // For mobile apps, IP detection is complex
    // This is a simplified version - in production, you might want to use a service
    // or get IP from Cloud Functions request headers
    try {
      // Try to get IP from a service (optional)
      final response = await http.get(Uri.parse('https://api.ipify.org?format=json'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['ip'] as String? ?? 'unknown';
      }
    } catch (e) {
      debugPrint('Error getting IP: $e');
    }
    return 'unknown';
  }
  
  // Approve user after email verification (automatically assigns freeUser role)
  Future<Map<String, dynamic>> approveUserAfterEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'User not authenticated'};
      }
      
      final idToken = await user.getIdToken();
      
      final url = Uri.parse('$_baseUrl/approveUserAfterEmailVerification');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'data': {},
        }),
      );
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['result'] as Map<String, dynamic>? ?? {'success': false};
      } else {
        final errorBody = jsonDecode(response.body);
        debugPrint('Approve user failed: ${response.statusCode} - ${errorBody['error']}');
        return {
          'success': false,
          'error': errorBody['error']?['message'] ?? 'Failed to approve user',
        };
      }
    } catch (e) {
      debugPrint('Error approving user after email verification: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}

