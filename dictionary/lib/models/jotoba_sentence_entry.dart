import 'jotoba_word_breakdown.dart';

/// Represents a sentence entry from Jotoba API
class JotobaSentenceEntry {
  final String japanese;
  final String? furigana;
  final Map<String, String> translations;
  final List<JotobaWordBreakdown> breakdown;
  final List<String> tags;
  final String? source;
  final int? id;

  JotobaSentenceEntry({
    required this.japanese,
    this.furigana,
    required this.translations,
    required this.breakdown,
    required this.tags,
    this.source,
    this.id,
  });

  factory JotobaSentenceEntry.fromJson(Map<String, dynamic> json) {
    return JotobaSentenceEntry(
      japanese: json['japanese'] ?? json['sentence'] ?? '',
      furigana: json['furigana'],
      translations: Map<String, String>.from(json['translations'] ?? {}),
      breakdown: (json['breakdown'] as List<dynamic>? ?? [])
          .map((b) => JotobaWordBreakdown.fromJson(b))
          .toList(),
      tags: List<String>.from(json['tags'] ?? []),
      source: json['source'],
      id: json['id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'japanese': japanese,
      if (furigana != null) 'furigana': furigana,
      'translations': translations,
      'breakdown': breakdown.map((b) => b.toJson()).toList(),
      'tags': tags,
      if (source != null) 'source': source,
      if (id != null) 'id': id,
    };
  }

  /// Get English translation (if available)
  String get englishTranslation {
    return translations['English'] ?? 
           translations['english'] ?? 
           (translations.values.isNotEmpty ? translations.values.first : '');
  }

  /// Get translation for specific language
  String? getTranslation(String language) {
    return translations[language] ?? translations[language.toLowerCase()];
  }

  /// Get available translation languages
  List<String> get availableLanguages {
    return translations.keys.toList();
  }

  /// Check if sentence has furigana
  bool get hasFurigana => furigana != null && furigana!.isNotEmpty;

  /// Check if sentence has breakdown analysis
  bool get hasBreakdown => breakdown.isNotEmpty;

  /// Check if sentence has source attribution
  bool get hasSource => source != null && source!.isNotEmpty;

  /// Get all words from breakdown
  List<String> get words {
    return breakdown.map((b) => b.word).toList();
  }

  /// Get all base forms from breakdown
  List<String> get baseForms {
    return breakdown.map((b) => b.baseForm ?? b.word).toList();
  }

  /// Check if sentence has tags
  bool get hasTags => tags.isNotEmpty;
}