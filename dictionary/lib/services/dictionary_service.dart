/// Pure Jotoba dictionary service
/// Provides all dictionary functionality using Jotoba API exclusively
library;

import '../models/jotoba_response.dart';
import '../models/jotoba_word_entry.dart';
import '../models/jotoba_kanji_entry.dart';
import '../models/jotoba_sentence_entry.dart';
import '../models/jotoba_name_entry.dart';
import '../models/jotoba_suggestion.dart';
import '../models/jotoba_unified_response.dart';
import 'jotoba_api_service.dart';

class DictionaryService {
  static String _preferredLanguage = 'English';

  /// Feature flags for capabilities
  static bool enablePitchAccent = true;
  static bool enableSentenceSearch = true;
  static bool enableKanjiSearch = true;
  static bool enableNameSearch = true;
  static bool enableSearchSuggestions = true;
  static bool enableAudioUrls = true;

  /// Set preferred language
  static void setLanguage(String language) {
    _preferredLanguage = language;
  }

  /// Get current language
  static String get currentLanguage => _preferredLanguage;

  /// Search for words (primary search function)
  static Future<JotobaResponse<JotobaWordEntry>?> searchWords({
    required String query,
    String? language,
    int? limit,
  }) async {
    return await JotobaApiService.searchWords(
      query: query,
      language: language ?? _preferredLanguage,
      limit: limit,
    );
  }

  /// Comprehensive search that returns both words and kanji
  /// This matches the actual Jotoba API response structure
  static Future<JotobaUnifiedResponse?> searchUnified({
    required String query,
    String? language,
    int? limit,
  }) async {
    try {
      // Use existing searchWords method but parse response differently
      final wordResponse = await JotobaApiService.searchWords(
        query: query,
        language: language ?? _preferredLanguage,
        limit: limit,
      );
      
      if (wordResponse?.metadata != null) {
        return JotobaUnifiedResponse.fromJson(wordResponse!.metadata!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Search for kanji
  static Future<JotobaResponse<JotobaKanjiEntry>?> searchKanji({
    required String query,
    String? language,
    int? limit,
  }) async {
    if (!enableKanjiSearch) return null;

    return await JotobaApiService.searchKanji(
      query: query,
      language: language ?? _preferredLanguage,
      limit: limit,
    );
  }

  /// Search for sentences
  static Future<JotobaResponse<JotobaSentenceEntry>?> searchSentences({
    required String query,
    String? language,
    int? limit,
  }) async {
    if (!enableSentenceSearch) return null;

    return await JotobaApiService.searchSentences(
      query: query,
      language: language ?? _preferredLanguage,
      limit: limit,
    );
  }

  /// Search for Japanese names
  static Future<JotobaResponse<JotobaNameEntry>?> searchNames({
    required String query,
    String? language,
    int? limit,
  }) async {
    if (!enableNameSearch) return null;

    return await JotobaApiService.searchNames(
      query: query,
      language: language ?? _preferredLanguage,
      limit: limit,
    );
  }

  /// Get search suggestions
  static Future<List<JotobaSuggestion>> getSuggestions({
    required String query,
    String? language,
    int? limit,
  }) async {
    if (!enableSearchSuggestions) return [];

    return await JotobaApiService.getSuggestions(
      query: query,
      language: language ?? _preferredLanguage,
      limit: limit,
    );
  }

  /// Search kanji by radicals
  static Future<JotobaResponse<JotobaKanjiEntry>?> searchKanjiByRadicals({
    required List<String> radicals,
    String? language,
    int? limit,
  }) async {
    if (!enableKanjiSearch) return null;

    return await JotobaApiService.searchKanjiByRadicals(
      radicals: radicals,
      language: language ?? _preferredLanguage,
      limit: limit,
    );
  }

  /// Comprehensive search across all types
  static Future<Map<String, dynamic>> comprehensiveSearch({
    required String query,
    String? language,
    bool includeWords = true,
    bool includeKanji = true,
    bool includeSentences = true,
    bool includeNames = true,
    int? limit,
  }) async {
    return await JotobaApiService.batchSearch(
      query: query,
      language: language ?? _preferredLanguage,
      includeWords: includeWords,
      includeKanji: includeKanji && enableKanjiSearch,
      includeSentences: includeSentences && enableSentenceSearch,
      includeNames: includeNames && enableNameSearch,
      limit: limit,
    );
  }

  /// Test API connectivity
  static Future<Map<String, dynamic>> testConnectivity() async {
    return await JotobaApiService.testConnectivity();
  }

  /// Get API information
  static Map<String, dynamic> getApiInfo() {
    return {
      'service': 'DictionaryService',
      'backend': 'Jotoba',
      'preferredLanguage': _preferredLanguage,
      'features': {
        'pitchAccent': enablePitchAccent,
        'sentenceSearch': enableSentenceSearch,
        'kanjiSearch': enableKanjiSearch,
        'nameSearch': enableNameSearch,
        'searchSuggestions': enableSearchSuggestions,
        'audioUrls': enableAudioUrls,
      },
      'jotoba': JotobaApiService.getApiInfo(),
    };
  }

  /// Check if specific feature is available
  static bool isFeatureAvailable(String feature) {
    switch (feature) {
      case 'pitchAccent':
        return enablePitchAccent;
      case 'sentenceSearch':
        return enableSentenceSearch;
      case 'kanjiSearch':
        return enableKanjiSearch;
      case 'nameSearch':
        return enableNameSearch;
      case 'searchSuggestions':
        return enableSearchSuggestions;
      case 'audioUrls':
        return enableAudioUrls;
      case 'multilingualSearch':
        return true;
      case 'radicalSearch':
        return enableKanjiSearch;
      default:
        return false;
    }
  }

  /// Get available languages
  static List<String> get availableLanguages {
    return [
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
  }

  /// Check if language is supported
  static bool isLanguageSupported(String language) {
    return availableLanguages.contains(language);
  }
}