/// Represents a search suggestion from Jotoba API
class JotobaSuggestion {
  final String text;
  final String type;
  final double? score;
  final Map<String, dynamic>? metadata;

  JotobaSuggestion({
    required this.text,
    required this.type,
    this.score,
    this.metadata,
  });

  factory JotobaSuggestion.fromJson(Map<String, dynamic> json) {
    return JotobaSuggestion(
      text: json['text'] ?? json['suggestion'] ?? '',
      type: json['type'] ?? 'word',
      score: json['score']?.toDouble(),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'type': type,
      if (score != null) 'score': score,
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// Check if this is a word suggestion
  bool get isWord => type.toLowerCase() == 'word';

  /// Check if this is a kanji suggestion
  bool get isKanji => type.toLowerCase() == 'kanji';

  /// Check if this is a sentence suggestion
  bool get isSentence => type.toLowerCase() == 'sentence';

  /// Check if this is a name suggestion
  bool get isName => type.toLowerCase() == 'name';

  /// Get relevance score (0.0 to 1.0)
  double get relevance => score ?? 0.0;

  /// Check if suggestion has high relevance
  bool get isHighRelevance => relevance > 0.8;

  /// Check if suggestion has metadata
  bool get hasMetadata => metadata != null && metadata!.isNotEmpty;
}