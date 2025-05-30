/// Minimal WordEntry stub for compatibility during Jotoba migration
/// This is a temporary compatibility layer for existing services
class WordEntry {
  final String slug;
  final bool isCommon;
  final List<String> tags;
  final List<String> jlpt;
  final List<JapaneseReading> japanese;
  final List<WordSense> senses;

  WordEntry({
    required this.slug,
    required this.isCommon,
    required this.tags,
    required this.jlpt,
    required this.japanese,
    required this.senses,
  });

  factory WordEntry.fromJson(Map<String, dynamic> json) {
    return WordEntry(
      slug: json['slug'] ?? '',
      isCommon: json['is_common'] ?? false,
      tags: List<String>.from(json['tags'] ?? []),
      jlpt: List<String>.from(json['jlpt'] ?? []),
      japanese: (json['japanese'] as List<dynamic>? ?? [])
          .map((j) => JapaneseReading.fromJson(j))
          .toList(),
      senses: (json['senses'] as List<dynamic>? ?? [])
          .map((s) => WordSense.fromJson(s))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slug': slug,
      'is_common': isCommon,
      'tags': tags,
      'jlpt': jlpt,
      'japanese': japanese.map((j) => j.toJson()).toList(),
      'senses': senses.map((s) => s.toJson()).toList(),
    };
  }

  String get mainWord => japanese.isNotEmpty 
      ? japanese.first.word ?? japanese.first.reading 
      : slug;

  String get mainReading => japanese.isNotEmpty 
      ? japanese.first.reading 
      : '';

  String get primaryDefinition => senses.isNotEmpty && 
      senses.first.englishDefinitions.isNotEmpty
      ? senses.first.englishDefinitions.first 
      : '';

  List<String> get allDefinitions => senses
      .expand((sense) => sense.englishDefinitions)
      .toList();
}

/// Minimal JapaneseReading stub
class JapaneseReading {
  final String? word;
  final String reading;

  JapaneseReading({
    this.word,
    required this.reading,
  });

  factory JapaneseReading.fromJson(Map<String, dynamic> json) {
    return JapaneseReading(
      word: json['word'],
      reading: json['reading'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'reading': reading,
    };
  }
}

/// Minimal WordSense stub
class WordSense {
  final List<String> englishDefinitions;
  final List<String> partsOfSpeech;
  final List<String> tags;
  final List<String> info;

  WordSense({
    required this.englishDefinitions,
    required this.partsOfSpeech,
    required this.tags,
    required this.info,
  });

  factory WordSense.fromJson(Map<String, dynamic> json) {
    return WordSense(
      englishDefinitions: List<String>.from(json['english_definitions'] ?? []),
      partsOfSpeech: List<String>.from(json['parts_of_speech'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      info: List<String>.from(json['info'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'english_definitions': englishDefinitions,
      'parts_of_speech': partsOfSpeech,
      'tags': tags,
      'info': info,
    };
  }
}