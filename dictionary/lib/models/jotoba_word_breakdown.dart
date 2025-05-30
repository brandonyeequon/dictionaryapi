/// Represents a word breakdown in a sentence analysis
class JotobaWordBreakdown {
  final String word;
  final String? baseForm;
  final String? reading;
  final String? partOfSpeech;
  final List<String> features;
  final String? meaning;
  final bool isInflected;

  JotobaWordBreakdown({
    required this.word,
    this.baseForm,
    this.reading,
    this.partOfSpeech,
    required this.features,
    this.meaning,
    required this.isInflected,
  });

  factory JotobaWordBreakdown.fromJson(Map<String, dynamic> json) {
    return JotobaWordBreakdown(
      word: json['word'] ?? json['surface'] ?? '',
      baseForm: json['base_form'] ?? json['base'],
      reading: json['reading'] ?? json['kana'],
      partOfSpeech: json['part_of_speech'] ?? json['pos'],
      features: List<String>.from(json['features'] ?? []),
      meaning: json['meaning'],
      isInflected: json['is_inflected'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      if (baseForm != null) 'base_form': baseForm,
      if (reading != null) 'reading': reading,
      if (partOfSpeech != null) 'part_of_speech': partOfSpeech,
      'features': features,
      if (meaning != null) 'meaning': meaning,
      'is_inflected': isInflected,
    };
  }

  /// Get display form (base form if inflected, otherwise word)
  String get displayForm => isInflected && baseForm != null ? baseForm! : word;

  /// Check if word has reading
  bool get hasReading => reading != null && reading!.isNotEmpty;

  /// Check if word has part of speech
  bool get hasPartOfSpeech => partOfSpeech != null && partOfSpeech!.isNotEmpty;

  /// Check if word has meaning
  bool get hasMeaning => meaning != null && meaning!.isNotEmpty;

  /// Check if word has features
  bool get hasFeatures => features.isNotEmpty;

  /// Get grammatical features as string
  String get featuresText => features.join(', ');
}