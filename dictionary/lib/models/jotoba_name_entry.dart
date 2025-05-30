/// Represents a Japanese name entry from Jotoba API
class JotobaNameEntry {
  final String name;
  final String? kana;
  final String type;
  final List<String> meanings;
  final String? gender;
  final String? origin;
  final List<String> tags;
  final int? frequency;
  final List<String> variants;

  JotobaNameEntry({
    required this.name,
    this.kana,
    required this.type,
    required this.meanings,
    this.gender,
    this.origin,
    required this.tags,
    this.frequency,
    required this.variants,
  });

  factory JotobaNameEntry.fromJson(Map<String, dynamic> json) {
    return JotobaNameEntry(
      name: json['name'] ?? json['kanji'] ?? '',
      kana: json['kana'] ?? json['reading'],
      type: json['type'] ?? 'unknown',
      meanings: List<String>.from(json['meanings'] ?? []),
      gender: json['gender'],
      origin: json['origin'],
      tags: List<String>.from(json['tags'] ?? []),
      frequency: json['frequency'],
      variants: List<String>.from(json['variants'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (kana != null) 'kana': kana,
      'type': type,
      'meanings': meanings,
      if (gender != null) 'gender': gender,
      if (origin != null) 'origin': origin,
      'tags': tags,
      if (frequency != null) 'frequency': frequency,
      'variants': variants,
    };
  }

  /// Get primary meaning
  String get primaryMeaning {
    return meanings.isNotEmpty ? meanings.first : '';
  }

  /// Check if name has reading
  bool get hasReading => kana != null && kana!.isNotEmpty;

  /// Check if name has gender information
  bool get hasGender => gender != null && gender!.isNotEmpty;

  /// Check if name has origin information
  bool get hasOrigin => origin != null && origin!.isNotEmpty;

  /// Check if name has variants
  bool get hasVariants => variants.isNotEmpty;

  /// Check if this is a person name
  bool get isPersonName => type.toLowerCase().contains('person') || 
                          type.toLowerCase().contains('given') ||
                          type.toLowerCase().contains('surname');

  /// Check if this is a place name
  bool get isPlaceName => type.toLowerCase().contains('place') ||
                         type.toLowerCase().contains('location');

  /// Get display text with reading if available
  String get displayText {
    if (hasReading) {
      return '$name ($kana)';
    }
    return name;
  }
}