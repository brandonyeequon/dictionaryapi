/// API Configuration for Jotoba.de dictionary API
library;

import 'package:universal_platform/universal_platform.dart';

class JotobaConfig {
  /// Jotoba.de API base URL
  static const String _jotobaBaseUrl = 'https://jotoba.de';

  /// Returns the API base URL
  static String get apiBaseUrl => _jotobaBaseUrl;

  /// Indicates whether we're using web platform
  static bool get isWeb => UniversalPlatform.isWeb;

  /// Returns the platform name
  static String get platform {
    if (UniversalPlatform.isWeb) return 'web';
    if (UniversalPlatform.isAndroid) return 'android';
    if (UniversalPlatform.isIOS) return 'ios';
    if (UniversalPlatform.isMacOS) return 'macos';
    if (UniversalPlatform.isWindows) return 'windows';
    if (UniversalPlatform.isLinux) return 'linux';
    return 'unknown';
  }

  /// Supported languages for Jotoba API
  static const List<String> supportedLanguages = [
    'English',
    'German', 
    'Spanish',
    'Russian',
    'Dutch',
    'French',
    'Swedish',
    'Hungarian',
    'Slovenian',
  ];

  /// Default language
  static const String defaultLanguage = 'English';

  /// Validate if a language is supported
  static bool isLanguageSupported(String language) {
    return supportedLanguages.contains(language);
  }

  /// Get language code for API requests
  static String getLanguageCode(String language) {
    // Jotoba uses full language names, not codes
    return isLanguageSupported(language) ? language : defaultLanguage;
  }

  /// API rate limiting recommendations
  static const Duration recommendedDelay = Duration(milliseconds: 100);
  static const int maxConcurrentRequests = 5;

  /// Request timeout settings
  static const Duration requestTimeout = Duration(seconds: 15);
  static const Duration shortTimeout = Duration(seconds: 5);

  /// Search limits
  static const int defaultSearchLimit = 20;
  static const int maxSearchLimit = 100;
  static const int minSearchLimit = 1;

  /// Validate search limit
  static int validateSearchLimit(int? limit) {
    if (limit == null) return defaultSearchLimit;
    if (limit < minSearchLimit) return minSearchLimit;
    if (limit > maxSearchLimit) return maxSearchLimit;
    return limit;
  }

  /// Feature flags for optional functionality
  static const bool enablePitchAccent = true;
  static const bool enableAudioUrls = true;
  static const bool enableSentenceBreakdown = true;
  static const bool enableMultilingualSearch = true;
  static const bool enableSearchSuggestions = true;
  static const bool enableRadicalSearch = true;
  static const bool enableNameSearch = true;

  /// API endpoints
  static const Map<String, String> endpoints = {
    'searchWords': '/api/search/words',
    'searchNames': '/api/search/names', 
    'searchKanji': '/api/search/kanji',
    'searchSentences': '/api/search/sentences',
    'searchByRadical': '/api/kanji/by_radical',
    'radicalSearch': '/api/radical/search',
    'suggestions': '/api/suggestion',
    'newsShort': '/api/news/short',
    'newsDetailed': '/api/news/detailed',
  };

  /// Get full endpoint URL
  static String getEndpointUrl(String endpointKey) {
    final endpoint = endpoints[endpointKey];
    if (endpoint == null) {
      throw ArgumentError('Unknown endpoint: $endpointKey');
    }
    return '$apiBaseUrl$endpoint';
  }

  /// Default request headers
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'Flutter-Dictionary-App/2.0-Jotoba',
  };

  /// Get platform-specific headers
  static Map<String, String> getHeaders() {
    final headers = Map<String, String>.from(defaultHeaders);
    
    if (!isWeb) {
      headers.addAll({
        'Accept-Encoding': 'gzip, deflate, br',
      });
    }
    
    return headers;
  }
}