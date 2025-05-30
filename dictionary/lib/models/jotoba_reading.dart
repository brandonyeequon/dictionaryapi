/// Represents a reading (kanji/kana pair) for a Japanese word
class JotobaReading {
  final String? kanji;
  final String kana;
  final List<String> tags;
  final List<String> info;
  final String? furigana;

  JotobaReading({
    this.kanji,
    required this.kana,
    required this.tags,
    required this.info,
    this.furigana,
  });

  factory JotobaReading.fromJson(Map<String, dynamic> json) {
    return JotobaReading(
      kanji: json['kanji'],
      kana: json['kana'] ?? json['reading'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      info: List<String>.from(json['info'] ?? []),
      furigana: json['furigana'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (kanji != null) 'kanji': kanji,
      'kana': kana,
      'tags': tags,
      'info': info,
      if (furigana != null) 'furigana': furigana,
    };
  }

  /// Get display text (kanji if available, otherwise kana)
  String get displayText => kanji ?? kana;

  /// Check if this reading has kanji
  bool get hasKanji => kanji != null && kanji!.isNotEmpty;

  /// Check if this reading is kana-only
  bool get isKanaOnly => !hasKanji;
  
  /// Check if this reading has furigana
  bool get hasFurigana => furigana != null && furigana!.isNotEmpty;
}