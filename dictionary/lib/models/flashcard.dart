class Flashcard {
  final String id;
  final String wordSlug;
  final String word;
  final String reading;
  final String definition;
  final List<String> tags;
  final DateTime createdAt;
  DateTime lastReviewed;
  DateTime nextReview;
  int intervalDays;
  int easeFactor; // Stored as integer (e.g., 250 = 2.5)
  int repetitions;
  bool isLearning;

  Flashcard({
    required this.id,
    required this.wordSlug,
    required this.word,
    required this.reading,
    required this.definition,
    required this.tags,
    required this.createdAt,
    required this.lastReviewed,
    required this.nextReview,
    this.intervalDays = 1,
    this.easeFactor = 250, // Default ease factor of 2.5
    this.repetitions = 0,
    this.isLearning = true,
  });

  factory Flashcard.fromWordEntry(String id, dynamic wordEntry) {
    final now = DateTime.now();
    return Flashcard(
      id: id,
      wordSlug: wordEntry.slug,
      word: wordEntry.mainWord,
      reading: wordEntry.mainReading,
      definition: wordEntry.primaryDefinition,
      tags: wordEntry.jlpt + wordEntry.tags,
      createdAt: now,
      lastReviewed: now,
      nextReview: now.add(const Duration(days: 1)),
    );
  }

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['id'],
      wordSlug: json['word_slug'],
      word: json['word'],
      reading: json['reading'],
      definition: json['definition'],
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at']),
      lastReviewed: DateTime.fromMillisecondsSinceEpoch(json['last_reviewed']),
      nextReview: DateTime.fromMillisecondsSinceEpoch(json['next_review']),
      intervalDays: json['interval_days'] ?? 1,
      easeFactor: json['ease_factor'] ?? 250,
      repetitions: json['repetitions'] ?? 0,
      isLearning: json['is_learning'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word_slug': wordSlug,
      'word': word,
      'reading': reading,
      'definition': definition,
      'tags': tags,
      'created_at': createdAt.millisecondsSinceEpoch,
      'last_reviewed': lastReviewed.millisecondsSinceEpoch,
      'next_review': nextReview.millisecondsSinceEpoch,
      'interval_days': intervalDays,
      'ease_factor': easeFactor,
      'repetitions': repetitions,
      'is_learning': isLearning,
    };
  }

  bool get isDueForReview => DateTime.now().isAfter(nextReview);
  
  double get easeFactorAsDouble => easeFactor / 100.0;

  Flashcard copyWith({
    DateTime? lastReviewed,
    DateTime? nextReview,
    int? intervalDays,
    int? easeFactor,
    int? repetitions,
    bool? isLearning,
  }) {
    return Flashcard(
      id: id,
      wordSlug: wordSlug,
      word: word,
      reading: reading,
      definition: definition,
      tags: tags,
      createdAt: createdAt,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      nextReview: nextReview ?? this.nextReview,
      intervalDays: intervalDays ?? this.intervalDays,
      easeFactor: easeFactor ?? this.easeFactor,
      repetitions: repetitions ?? this.repetitions,
      isLearning: isLearning ?? this.isLearning,
    );
  }
}