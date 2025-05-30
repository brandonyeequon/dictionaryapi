import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/jotoba_response.dart';
import '../models/jotoba_word_entry.dart';
import '../models/jotoba_kanji_entry.dart';
import '../models/jotoba_sentence_entry.dart';
import '../models/jotoba_name_entry.dart';
import '../models/jotoba_suggestion.dart';
import '../config/jotoba_config.dart';

class JotobaApiService {
  static const Duration _timeout = Duration(seconds: 15);
  static const String _userAgent = 'Flutter-Dictionary-App/2.0-Jotoba';

  /// Search for words using Jotoba API
  static Future<JotobaResponse<JotobaWordEntry>?> searchWords({
    required String query,
    String language = 'English',
    bool noEnglish = false,
    int? limit,
  }) async {
    try {
      if (query.trim().isEmpty) return null;

      final requestBody = {
        'query': query.trim(),
        'language': language,
        'no_english': noEnglish,
        if (limit != null) 'limit': limit,
      };

      final response = await _makeRequest(
        endpoint: '/api/search/words',
        body: requestBody,
      );

      if (response != null) {
        return JotobaResponse<JotobaWordEntry>.fromJson(
          response,
          (data) => JotobaWordEntry.fromJson(data),
        );
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[JotobaApiService] searchWords error: $e');
      }
      rethrow;
    }
  }

  /// Search for Japanese names
  static Future<JotobaResponse<JotobaNameEntry>?> searchNames({
    required String query,
    String language = 'English',
    int? limit,
  }) async {
    try {
      if (query.trim().isEmpty) return null;

      final requestBody = {
        'query': query.trim(),
        'language': language,
        if (limit != null) 'limit': limit,
      };

      final response = await _makeRequest(
        endpoint: '/api/search/names',
        body: requestBody,
      );

      if (response != null) {
        return JotobaResponse<JotobaNameEntry>.fromJson(
          response,
          (data) => JotobaNameEntry.fromJson(data),
        );
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[JotobaApiService] searchNames error: $e');
      }
      rethrow;
    }
  }

  /// Search for kanji
  static Future<JotobaResponse<JotobaKanjiEntry>?> searchKanji({
    required String query,
    String language = 'English',
    int? limit,
  }) async {
    try {
      if (query.trim().isEmpty) return null;

      final requestBody = {
        'query': query.trim(),
        'language': language,
        if (limit != null) 'limit': limit,
      };

      final response = await _makeRequest(
        endpoint: '/api/search/kanji',
        body: requestBody,
      );

      if (response != null) {
        return JotobaResponse<JotobaKanjiEntry>.fromJson(
          response,
          (data) => JotobaKanjiEntry.fromJson(data),
        );
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[JotobaApiService] searchKanji error: $e');
      }
      rethrow;
    }
  }

  /// Search for sentences
  static Future<JotobaResponse<JotobaSentenceEntry>?> searchSentences({
    required String query,
    String language = 'English',
    int? limit,
  }) async {
    try {
      if (query.trim().isEmpty) return null;

      final requestBody = {
        'query': query.trim(),
        'language': language,
        if (limit != null) 'limit': limit,
      };

      final response = await _makeRequest(
        endpoint: '/api/search/sentences',
        body: requestBody,
      );

      if (response != null) {
        return JotobaResponse<JotobaSentenceEntry>.fromJson(
          response,
          (data) => JotobaSentenceEntry.fromJson(data),
        );
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[JotobaApiService] searchSentences error: $e');
      }
      rethrow;
    }
  }

  /// Search kanji by radicals
  static Future<JotobaResponse<JotobaKanjiEntry>?> searchKanjiByRadicals({
    required List<String> radicals,
    String language = 'English',
    int? limit,
  }) async {
    try {
      if (radicals.isEmpty) return null;

      final requestBody = {
        'radicals': radicals,
        'language': language,
        if (limit != null) 'limit': limit,
      };

      final response = await _makeRequest(
        endpoint: '/api/kanji/by_radical',
        body: requestBody,
      );

      if (response != null) {
        return JotobaResponse<JotobaKanjiEntry>.fromJson(
          response,
          (data) => JotobaKanjiEntry.fromJson(data),
        );
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[JotobaApiService] searchKanjiByRadicals error: $e');
      }
      rethrow;
    }
  }

  /// Get search suggestions
  static Future<List<JotobaSuggestion>> getSuggestions({
    required String query,
    String language = 'English',
    int? limit,
  }) async {
    try {
      if (query.trim().isEmpty) return [];

      final requestBody = {
        'query': query.trim(),
        'language': language,
        if (limit != null) 'limit': limit,
      };

      final response = await _makeRequest(
        endpoint: '/api/suggestion',
        body: requestBody,
      );

      if (response != null && response['suggestions'] is List) {
        return (response['suggestions'] as List)
            .map((item) => JotobaSuggestion.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[JotobaApiService] getSuggestions error: $e');
      }
      return [];
    }
  }

  /// Make HTTP request to Jotoba API
  static Future<Map<String, dynamic>?> _makeRequest({
    required String endpoint,
    required Map<String, dynamic> body,
  }) async {
    try {
      final url = Uri.parse('${JotobaConfig.apiBaseUrl}$endpoint');
      
      if (kDebugMode) {
        debugPrint('[JotobaApiService] Making request to: ${url.toString()}');
        debugPrint('[JotobaApiService] Request body: ${json.encode(body)}');
        debugPrint('[JotobaApiService] Platform: ${JotobaConfig.platform}');
      }

      final headers = _buildRequestHeaders();
      final requestBody = json.encode(body);

      final response = await http.post(
        url,
        headers: headers,
        body: requestBody,
      ).timeout(_timeout);

      if (kDebugMode) {
        debugPrint('[JotobaApiService] Response status: ${response.statusCode}');
        debugPrint('[JotobaApiService] Response headers: ${response.headers}');
      }

      if (response.statusCode == 200) {
        if (kDebugMode) {
          debugPrint('[JotobaApiService] Response body length: ${response.body.length}');
        }
        
        late dynamic jsonData;
        try {
          jsonData = json.decode(response.body);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('[JotobaApiService] JSON decode error: $e');
            debugPrint('[JotobaApiService] Raw response: ${response.body}');
          }
          throw Exception('Invalid JSON response format from Jotoba: $e');
        }
        
        if (kDebugMode) {
          debugPrint('[JotobaApiService] Response has words: ${jsonData.containsKey('words')}');
          debugPrint('[JotobaApiService] Response has kanji: ${jsonData.containsKey('kanji')}');
        }
        
        if (!_isValidJotobaResponse(jsonData)) {
          if (kDebugMode) {
            debugPrint('[JotobaApiService] Invalid response structure: $jsonData');
          }
          throw Exception('Invalid response structure from Jotoba API');
        }
        
        return jsonData;
      } else {
        throw Exception(
          'HTTP ${response.statusCode} from Jotoba API: ${response.reasonPhrase}'
        );
      }
    } on http.ClientException catch (e) {
      throw Exception('Network error connecting to Jotoba API: $e');
    } on FormatException catch (e) {
      throw Exception('Invalid JSON response format from Jotoba: $e');
    } on TimeoutException catch (e) {
      throw Exception('Request timeout connecting to Jotoba API: $e');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[JotobaApiService] Unexpected error: $e');
      }
      rethrow;
    }
  }

  /// Build request headers for Jotoba API
  static Map<String, String> _buildRequestHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': _userAgent,
      // Explicitly request no compression to avoid Brotli issues
      'Accept-Encoding': 'identity',
    };

    return headers;
  }

  /// Validate Jotoba API response structure
  static bool _isValidJotobaResponse(dynamic jsonData) {
    if (jsonData is! Map<String, dynamic>) return false;
    
    // Based on official docs, word search responses should have 'words' and/or 'kanji' keys
    final validKeys = ['words', 'kanji', 'sentences', 'names', 'suggestions'];
    return validKeys.any((key) => jsonData.containsKey(key));
  }

  /// Get current API configuration for debugging
  static Map<String, dynamic> getApiInfo() {
    return {
      'apiBaseUrl': JotobaConfig.apiBaseUrl,
      'platform': JotobaConfig.platform,
      'isWeb': JotobaConfig.isWeb,
      'userAgent': _userAgent,
      'timeout': _timeout.inSeconds,
    };
  }

  /// Test API connectivity
  static Future<Map<String, dynamic>> testConnectivity() async {
    final startTime = DateTime.now();
    
    try {
      final response = await searchWords(query: 'test', limit: 1);
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      
      return {
        'status': 'success',
        'responseTime': duration.inMilliseconds,
        'timestamp': endTime.toIso8601String(),
        'apiInfo': getApiInfo(),
        'hasResults': response?.data.isNotEmpty ?? false,
        'apiVersion': 'jotoba-v2',
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
        'apiVersion': 'jotoba-v2',
      };
    }
  }

  /// Batch search across multiple types
  static Future<Map<String, dynamic>> batchSearch({
    required String query,
    String language = 'English',
    bool includeWords = true,
    bool includeKanji = false,
    bool includeSentences = false,
    bool includeNames = false,
    int? limit,
  }) async {
    final results = <String, dynamic>{};
    final futures = <Future<void>>[];

    if (includeWords) {
      futures.add(
        searchWords(query: query, language: language, limit: limit)
            .then((result) {
              results['words'] = result;
            })
            .catchError((e) {
              results['words_error'] = e.toString();
            })
      );
    }

    if (includeKanji) {
      futures.add(
        searchKanji(query: query, language: language, limit: limit)
            .then((result) {
              results['kanji'] = result;
            })
            .catchError((e) {
              results['kanji_error'] = e.toString();
            })
      );
    }

    if (includeSentences) {
      futures.add(
        searchSentences(query: query, language: language, limit: limit)
            .then((result) {
              results['sentences'] = result;
            })
            .catchError((e) {
              results['sentences_error'] = e.toString();
            })
      );
    }

    if (includeNames) {
      futures.add(
        searchNames(query: query, language: language, limit: limit)
            .then((result) {
              results['names'] = result;
            })
            .catchError((e) {
              results['names_error'] = e.toString();
            })
      );
    }

    await Future.wait(futures);
    return results;
  }
}