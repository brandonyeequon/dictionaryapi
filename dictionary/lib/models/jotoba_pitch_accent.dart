/// Represents pitch accent information for Japanese words
class JotobaPitchAccent {
  final String reading;
  final int? accents;
  final List<int> accentPositions;
  final String? accentType;
  final String? description;

  JotobaPitchAccent({
    required this.reading,
    this.accents,
    required this.accentPositions,
    this.accentType,
    this.description,
  });

  factory JotobaPitchAccent.fromJson(Map<String, dynamic> json) {
    return JotobaPitchAccent(
      reading: json['reading'] ?? '',
      accents: json['accents'],
      accentPositions: List<int>.from(json['accent_positions'] ?? []),
      accentType: json['accent_type'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reading': reading,
      if (accents != null) 'accents': accents,
      'accent_positions': accentPositions,
      if (accentType != null) 'accent_type': accentType,
      if (description != null) 'description': description,
    };
  }

  /// Check if pitch accent has specific positions marked
  bool get hasPositions => accentPositions.isNotEmpty;

  /// Check if this is a heiban (flat) accent
  bool get isHeiban => accentType?.toLowerCase() == 'heiban' || accents == 0;

  /// Check if this is an atamadaka (head-high) accent
  bool get isAtamadaka => accents == 1;

  /// Check if this is an odaka (tail-high) accent
  bool get isOdaka => accents != null && accents! > 0 && accents == reading.length;

  /// Check if this is a nakadaka (middle-high) accent
  bool get isNakadaka => accents != null && accents! > 1 && accents! < reading.length;

  /// Get accent pattern description
  String get patternDescription {
    if (description != null) return description!;
    
    if (isHeiban) return 'Heiban (平板)';
    if (isAtamadaka) return 'Atamadaka (頭高)';
    if (isOdaka) return 'Odaka (尾高)';
    if (isNakadaka) return 'Nakadaka (中高)';
    
    return 'Unknown pattern';
  }
}