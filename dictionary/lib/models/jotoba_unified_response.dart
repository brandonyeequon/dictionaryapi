import 'jotoba_word_entry.dart';
import 'jotoba_kanji_entry.dart';

/// Unified response model for Jotoba API that can contain both words and kanji
/// This handles the actual response structure from /api/search/words endpoint
class JotobaUnifiedResponse {
  final List<JotobaWordEntry> words;
  final List<JotobaKanjiEntry> kanji;
  final Map<String, dynamic>? metadata;

  JotobaUnifiedResponse({
    required this.words,
    required this.kanji,
    this.metadata,
  });

  factory JotobaUnifiedResponse.fromJson(Map<String, dynamic> json) {
    // Parse words array if present
    final words = <JotobaWordEntry>[];
    if (json['words'] is List) {
      for (final wordData in json['words'] as List) {
        try {
          if (wordData is Map<String, dynamic>) {
            words.add(JotobaWordEntry.fromJson(wordData));
          }
        } catch (e) {
          // Skip invalid word entries
          continue;
        }
      }
    }

    // Parse kanji array if present
    final kanji = <JotobaKanjiEntry>[];
    if (json['kanji'] is List) {
      for (final kanjiData in json['kanji'] as List) {
        try {
          if (kanjiData is Map<String, dynamic>) {
            kanji.add(JotobaKanjiEntry.fromJson(kanjiData));
          }
        } catch (e) {
          // Skip invalid kanji entries
          continue;
        }
      }
    }

    return JotobaUnifiedResponse(
      words: words,
      kanji: kanji,
      metadata: json,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'words': words.map((w) => w.toJson()).toList(),
      'kanji': kanji.map((k) => k.toJson()).toList(),
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// Check if response has any results
  bool get hasResults => words.isNotEmpty || kanji.isNotEmpty;

  /// Get total number of results
  int get totalResults => words.length + kanji.length;

  /// Check if response has words
  bool get hasWords => words.isNotEmpty;

  /// Check if response has kanji
  bool get hasKanji => kanji.isNotEmpty;

  /// Get all results as a mixed list (useful for display)
  List<dynamic> get allResults => [...words, ...kanji];

  /// Get words count
  int get wordCount => words.length;

  /// Get kanji count 
  int get kanjiCount => kanji.length;
}