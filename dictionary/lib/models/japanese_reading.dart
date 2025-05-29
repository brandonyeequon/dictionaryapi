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