/// Represents a kanji entry from Jotoba API
class JotobaKanjiEntry {
  final String kanji;
  final List<String> onReadings;
  final List<String> kunReadings;
  final List<String> meanings;
  final int? strokeCount;
  final String? grade;
  final String? jlptLevel;
  final int? frequency;
  final List<String> radicals;
  final List<String> parts;
  final List<String> variants;
  final Map<String, dynamic>? strokeOrder;
  final List<String> examples;
  final List<String> chineseReadings;
  final List<String> koreanReadings;
  final List<String> koreanHangul;
  final String? radical;

  JotobaKanjiEntry({
    required this.kanji,
    required this.onReadings,
    required this.kunReadings,
    required this.meanings,
    this.strokeCount,
    this.grade,
    this.jlptLevel,
    this.frequency,
    required this.radicals,
    required this.parts,
    required this.variants,
    this.strokeOrder,
    required this.examples,
    required this.chineseReadings,
    required this.koreanReadings,
    required this.koreanHangul,
    this.radical,
  });

  factory JotobaKanjiEntry.fromJson(Map<String, dynamic> json) {
    return JotobaKanjiEntry(
      kanji: json['kanji'] ?? json['literal'] ?? '',
      onReadings: List<String>.from(json['on_readings'] ?? json['onyomi'] ?? []),
      kunReadings: List<String>.from(json['kun_readings'] ?? json['kunyomi'] ?? []),
      meanings: List<String>.from(json['meanings'] ?? []),
      strokeCount: json['stroke_count'] ?? json['strokes'],
      grade: json['grade']?.toString(),
      jlptLevel: json['jlpt_level'] ?? json['jlpt']?.toString(),
      frequency: json['frequency'],
      radicals: List<String>.from(json['radicals'] ?? []),
      parts: List<String>.from(json['parts'] ?? []),
      variants: List<String>.from(json['variants'] ?? json['variant'] ?? []),
      strokeOrder: json['stroke_order'],
      examples: List<String>.from(json['examples'] ?? []),
      chineseReadings: List<String>.from(json['chinese'] ?? []),
      koreanReadings: List<String>.from(json['korean_r'] ?? []),
      koreanHangul: List<String>.from(json['korean_h'] ?? []),
      radical: json['radical'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kanji': kanji,
      'on_readings': onReadings,
      'kun_readings': kunReadings,
      'meanings': meanings,
      if (strokeCount != null) 'stroke_count': strokeCount,
      if (grade != null) 'grade': grade,
      if (jlptLevel != null) 'jlpt_level': jlptLevel,
      if (frequency != null) 'frequency': frequency,
      'radicals': radicals,
      'parts': parts,
      'variants': variants,
      if (strokeOrder != null) 'stroke_order': strokeOrder,
      'examples': examples,
      'chinese': chineseReadings,
      'korean_r': koreanReadings,
      'korean_h': koreanHangul,
      if (radical != null) 'radical': radical,
    };
  }

  /// Get primary meaning
  String get primaryMeaning {
    return meanings.isNotEmpty ? meanings.first : '';
  }

  /// Get all readings (on + kun)
  List<String> get allReadings {
    return [...onReadings, ...kunReadings];
  }

  /// Check if kanji has on readings
  bool get hasOnReadings => onReadings.isNotEmpty;

  /// Check if kanji has kun readings
  bool get hasKunReadings => kunReadings.isNotEmpty;

  /// Check if kanji has stroke order data
  bool get hasStrokeOrder => strokeOrder != null;

  /// Check if kanji has examples
  bool get hasExamples => examples.isNotEmpty;

  /// Check if kanji has JLPT level
  bool get hasJlptLevel => jlptLevel != null && jlptLevel!.isNotEmpty;

  /// Check if kanji has grade level
  bool get hasGrade => grade != null && grade!.isNotEmpty;

  /// Get difficulty description based on grade/JLPT
  String get difficultyDescription {
    if (hasGrade) {
      return 'Grade $grade';
    } else if (hasJlptLevel) {
      return 'JLPT $jlptLevel';
    } else {
      return 'Advanced';
    }
  }
}