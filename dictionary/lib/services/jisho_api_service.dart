import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/jisho_response.dart';
import '../config/api_config.dart';

class JishoApiService {
  static const Duration _timeout = Duration(seconds: 10);

  /// Search for words using the appropriate API endpoint based on platform
  static Future<JishoResponse?> searchWords(String keyword) async {
    try {
      if (keyword.trim().isEmpty) {
        return null;
      }

      // Build URL using the configuration system
      final url = Uri.parse(ApiConfig.buildSearchUrl(keyword));
      
      // Log API request details in debug mode
      if (kDebugMode) {
        debugPrint('[JishoApiService] Making request to: ${url.toString()}');
        debugPrint('[JishoApiService] Platform: ${ApiConfig.platform}');
      }

      // Prepare headers based on platform
      final headers = _buildRequestHeaders();

      final response = await http.get(url, headers: headers).timeout(_timeout);

      if (kDebugMode) {
        debugPrint('[JishoApiService] Response status: ${response.statusCode}');
        debugPrint('[JishoApiService] Response headers: ${response.headers}');
      }

      if (response.statusCode == 200) {
        dynamic jsonData = json.decode(response.body);
        
        // Handle CORS proxy response format (allorigins.win wraps the response)
        if (ApiConfig.isWeb && jsonData is Map<String, dynamic> && jsonData.containsKey('contents')) {
          jsonData = json.decode(jsonData['contents']);
        }
        
        // Validate response structure
        if (!_isValidJishoResponse(jsonData)) {
          throw Exception('Invalid response structure from API');
        }
        
        return JishoResponse.fromJson(jsonData);
      } else {
        // Enhanced error handling with platform-specific context
        final errorContext = ApiConfig.isWeb ? 'CORS proxy' : 'direct API';
        throw Exception(
          'HTTP ${response.statusCode} from $errorContext: ${response.reasonPhrase}'
        );
      }
    } on http.ClientException catch (e) {
      // Network-specific error handling
      final context = ApiConfig.isWeb 
          ? 'CORS proxy service' 
          : 'Jisho.org API';
      throw Exception('Network error connecting to $context: $e');
    } on FormatException catch (e) {
      throw Exception('Invalid JSON response format: $e');
    } on TimeoutException catch (e) {
      final context = ApiConfig.isWeb ? 'CORS proxy' : 'Jisho.org API';
      throw Exception('Request timeout connecting to $context: $e');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[JishoApiService] Unexpected error: $e');
      }
      throw Exception('Unexpected error: $e');
    }
  }

  /// Build appropriate request headers
  static Map<String, String> _buildRequestHeaders() {
    final headers = <String, String>{
      'Accept': 'application/json',
    };

    // For direct API calls (mobile/desktop), include full headers
    if (!ApiConfig.isWeb) {
      headers.addAll({
        'User-Agent': 'Flutter-Dictionary-App/1.0',
        'Accept-Encoding': 'gzip, deflate, br',
      });
    }

    return headers;
  }

  /// Validate that the response has the expected Jisho.org structure
  static bool _isValidJishoResponse(dynamic jsonData) {
    if (jsonData is! Map<String, dynamic>) return false;
    
    // Check for required fields
    if (!jsonData.containsKey('meta') || !jsonData.containsKey('data')) {
      return false;
    }
    
    // Validate meta structure
    final meta = jsonData['meta'];
    if (meta is! Map<String, dynamic> || !meta.containsKey('status')) {
      return false;
    }
    
    // Validate data structure
    final data = jsonData['data'];
    if (data is! List) return false;
    
    return true;
  }

  /// Get the current API configuration for debugging
  static Map<String, dynamic> getApiInfo() {
    return {
      'currentUrl': ApiConfig.apiUrl,
      'platform': ApiConfig.platform,
      'isWeb': ApiConfig.isWeb,
    };
  }

  /// Test API connectivity and return status information
  static Future<Map<String, dynamic>> testConnectivity() async {
    final startTime = DateTime.now();
    
    try {
      // Simple connectivity test
      final response = await searchWords('test');
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      
      return {
        'status': 'success',
        'responseTime': duration.inMilliseconds,
        'timestamp': endTime.toIso8601String(),
        'apiInfo': getApiInfo(),
        'hasResults': response?.data.isNotEmpty ?? false,
      };
    } catch (e) {
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      
      return {
        'status': 'error',
        'error': e.toString(),
        'responseTime': duration.inMilliseconds,
        'timestamp': endTime.toIso8601String(),
        'apiInfo': getApiInfo(),
      };
    }
  }

}