/// Represents the mastery level of a word in the spaced repetition system
enum MasteryLevel {
  /// Word is new, never studied
  newWord(0, 'New', 'Just added to study list'),
  
  /// Word is being learned, still making mistakes
  learning(1, 'Learning', 'Making progress, needs practice'),
  
  /// Word is being reviewed, occasional mistakes
  reviewing(2, 'Reviewing', 'Good recall with some effort'),
  
  /// Word is mastered, consistent correct answers
  mastered(3, 'Mastered', 'Confident recall, long intervals'),
  
  /// Word is burned/retired, extremely well known
  burned(4, 'Burned', 'Perfect recall, retired from active study');

  const MasteryLevel(this.level, this.displayName, this.description);

  final int level;
  final String displayName;
  final String description;

  /// Get the next mastery level
  MasteryLevel? get next {
    switch (this) {
      case MasteryLevel.newWord:
        return MasteryLevel.learning;
      case MasteryLevel.learning:
        return MasteryLevel.reviewing;
      case MasteryLevel.reviewing:
        return MasteryLevel.mastered;
      case MasteryLevel.mastered:
        return MasteryLevel.burned;
      case MasteryLevel.burned:
        return null; // Already at max level
    }
  }

  /// Get the previous mastery level (for demotions)
  MasteryLevel? get previous {
    switch (this) {
      case MasteryLevel.newWord:
        return null; // Already at minimum level
      case MasteryLevel.learning:
        return MasteryLevel.newWord;
      case MasteryLevel.reviewing:
        return MasteryLevel.learning;
      case MasteryLevel.mastered:
        return MasteryLevel.reviewing;
      case MasteryLevel.burned:
        return MasteryLevel.mastered;
    }
  }

  /// Check if this level is considered "active" (needs regular review)
  bool get isActive {
    return this != MasteryLevel.burned;
  }

  /// Get recommended initial interval for this mastery level (in hours)
  int get initialIntervalHours {
    switch (this) {
      case MasteryLevel.newWord:
        return 4; // 4 hours
      case MasteryLevel.learning:
        return 8; // 8 hours
      case MasteryLevel.reviewing:
        return 24; // 1 day
      case MasteryLevel.mastered:
        return 168; // 1 week
      case MasteryLevel.burned:
        return 8760; // 1 year (rarely reviewed)
    }
  }

  /// Get the color associated with this mastery level
  int get colorValue {
    switch (this) {
      case MasteryLevel.newWord:
        return 0xFF9E9E9E; // Grey
      case MasteryLevel.learning:
        return 0xFFFF9800; // Orange
      case MasteryLevel.reviewing:
        return 0xFF2196F3; // Blue
      case MasteryLevel.mastered:
        return 0xFF4CAF50; // Green
      case MasteryLevel.burned:
        return 0xFF9C27B0; // Purple
    }
  }

  static MasteryLevel fromLevel(int level) {
    return MasteryLevel.values.firstWhere(
      (m) => m.level == level,
      orElse: () => MasteryLevel.newWord,
    );
  }
}

/// Tracks the difficulty of a study session or individual word review
enum ReviewDifficulty {
  /// Completely forgot or got wrong
  again(0, 'Again', 'I forgot completely'),
  
  /// Very difficult, barely remembered
  hard(1, 'Hard', 'I barely remembered'),
  
  /// Some effort required but got it right
  good(2, 'Good', 'I remembered with some effort'),
  
  /// Easy recall, confident answer
  easy(3, 'Easy', 'I remembered easily');

  const ReviewDifficulty(this.value, this.displayName, this.description);

  final int value;
  final String displayName;
  final String description;

  /// Get the color associated with this difficulty
  int get colorValue {
    switch (this) {
      case ReviewDifficulty.again:
        return 0xFFF44336; // Red
      case ReviewDifficulty.hard:
        return 0xFFFF9800; // Orange
      case ReviewDifficulty.good:
        return 0xFF4CAF50; // Green
      case ReviewDifficulty.easy:
        return 0xFF2196F3; // Blue
    }
  }

  static ReviewDifficulty fromValue(int value) {
    return ReviewDifficulty.values.firstWhere(
      (d) => d.value == value,
      orElse: () => ReviewDifficulty.good,
    );
  }
}