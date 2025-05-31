import 'dart:math' as math;
import 'word_mastery.dart';
import './jotoba_word_entry.dart'; // Changed from 'word_entry.dart'

/// Enhanced flashcard that integrates with word lists and tracks mastery
class EnhancedFlashcard {
  final String id;
  final String wordSlug;
  final String word;
  final String reading;
  final String? furiganaReading;
  final String definition;
  final List<String> tags;
  final List<int> wordListIds; // Lists this card belongs to
  final MasteryLevel masteryLevel;
  final DateTime createdAt;
  DateTime lastReviewed;
  DateTime nextReview;
  int intervalHours;
  int easeFactor; // Stored as integer (e.g., 250 = 2.5)
  int repetitions;
  int correctStreak; // Consecutive correct answers
  int totalReviews;
  int correctReviews;
  List<ReviewSession> reviewHistory;

  EnhancedFlashcard({
    required this.id,
    required this.wordSlug,
    required this.word,
    required this.reading,
    this.furiganaReading,
    required this.definition,
    required this.tags,
    required this.wordListIds,
    this.masteryLevel = MasteryLevel.newWord,
    required this.createdAt,
    required this.lastReviewed,
    required this.nextReview,
    this.intervalHours = 4, // Start with 4 hours
    this.easeFactor = 250, // Default ease factor of 2.5
    this.repetitions = 0,
    this.correctStreak = 0,
    this.totalReviews = 0,
    this.correctReviews = 0,
    this.reviewHistory = const [],
  });

  factory EnhancedFlashcard.fromWordEntry(
    String id,
    JotobaWordEntry wordEntry, // Changed type here
    List<int> wordListIds,
  ) {
    final now = DateTime.now();
    return EnhancedFlashcard(
      id: id,
      wordSlug: wordEntry.slug ?? '', // Added null check
      word: wordEntry.primaryWord,
      reading: wordEntry.primaryReading,
      furiganaReading: wordEntry.primaryFurigana, // Now uses primaryFurigana
      definition: wordEntry.primaryDefinition,
      tags: List<String>.from(wordEntry.jlpt)..addAll(wordEntry.tags), // Updated tags
      wordListIds: wordListIds,
      createdAt: now,
      lastReviewed: now,
      nextReview: now, // New cards are immediately available for study
    );
  }

  factory EnhancedFlashcard.fromJson(Map<String, dynamic> json) {
    final reviewHistoryJson = json['review_history'] as List<dynamic>? ?? [];
    final reviewHistory = reviewHistoryJson
        .map((e) => ReviewSession.fromJson(e as Map<String, dynamic>))
        .toList();

    return EnhancedFlashcard(
      id: json['id'] as String,
      wordSlug: json['word_slug'] as String,
      word: json['word'] as String,
      reading: json['reading'] as String,
      furiganaReading: json['furigana_reading'] as String?,
      definition: json['definition'] as String,
      tags: List<String>.from(json['tags'] ?? []),
      wordListIds: List<int>.from(json['word_list_ids'] ?? []),
      masteryLevel: MasteryLevel.fromLevel(json['mastery_level'] as int? ?? 0),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int),
      lastReviewed: DateTime.fromMillisecondsSinceEpoch(json['last_reviewed'] as int),
      nextReview: DateTime.fromMillisecondsSinceEpoch(json['next_review'] as int),
      intervalHours: json['interval_hours'] as int? ?? 4,
      easeFactor: json['ease_factor'] as int? ?? 250,
      repetitions: json['repetitions'] as int? ?? 0,
      correctStreak: json['correct_streak'] as int? ?? 0,
      totalReviews: json['total_reviews'] as int? ?? 0,
      correctReviews: json['correct_reviews'] as int? ?? 0,
      reviewHistory: reviewHistory,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word_slug': wordSlug,
      'word': word,
      'reading': reading,
      'furigana_reading': furiganaReading,
      'definition': definition,
      'tags': tags,
      'word_list_ids': wordListIds,
      'mastery_level': masteryLevel.level,
      'created_at': createdAt.millisecondsSinceEpoch,
      'last_reviewed': lastReviewed.millisecondsSinceEpoch,
      'next_review': nextReview.millisecondsSinceEpoch,
      'interval_hours': intervalHours,
      'ease_factor': easeFactor,
      'repetitions': repetitions,
      'correct_streak': correctStreak,
      'total_reviews': totalReviews,
      'correct_reviews': correctReviews,
      'review_history': reviewHistory.map((e) => e.toJson()).toList(),
    };
  }

  /// Check if the card is due for review
  bool get isDueForReview => DateTime.now().isAfter(nextReview);

  /// Get accuracy percentage
  double get accuracy {
    if (totalReviews == 0) return 0.0;
    return (correctReviews / totalReviews) * 100;
  }

  /// Get ease factor as double
  double get easeFactorAsDouble => easeFactor / 100.0;

  /// Check if the card is considered "learned" (passed initial learning phase)
  bool get isLearned => masteryLevel != MasteryLevel.newWord;

  /// Get time until next review
  Duration get timeUntilNextReview {
    final now = DateTime.now();
    if (nextReview.isBefore(now)) return Duration.zero;
    return nextReview.difference(now);
  }

  /// Update the card after a review
  EnhancedFlashcard reviewCard(ReviewDifficulty difficulty) {
    final now = DateTime.now();
    final wasCorrect = difficulty.value >= 2; // Good or Easy
    
    // Create review session record
    final session = ReviewSession(
      timestamp: now,
      difficulty: difficulty,
      intervalHours: intervalHours,
      masteryLevel: masteryLevel,
    );

    // Update statistics
    final newTotalReviews = totalReviews + 1;
    final newCorrectReviews = correctReviews + (wasCorrect ? 1 : 0);
    final newCorrectStreak = wasCorrect ? correctStreak + 1 : 0;
    final newRepetitions = wasCorrect ? repetitions + 1 : repetitions;

    // Calculate new interval and ease factor using enhanced SM-2 algorithm
    final intervalResult = _calculateNextInterval(difficulty, wasCorrect);
    final newIntervalHours = intervalResult.intervalHours;
    final newEaseFactor = intervalResult.easeFactor;
    
    // Determine new mastery level
    final newMasteryLevel = _calculateMasteryLevel(
      difficulty,
      newCorrectStreak,
      newRepetitions,
    );

    // Update review history (keep last 50 reviews)
    final newReviewHistory = List<ReviewSession>.from(reviewHistory)
      ..add(session);
    if (newReviewHistory.length > 50) {
      newReviewHistory.removeAt(0);
    }

    return copyWith(
      lastReviewed: now,
      nextReview: now.add(Duration(hours: newIntervalHours)),
      intervalHours: newIntervalHours,
      easeFactor: newEaseFactor,
      repetitions: newRepetitions,
      correctStreak: newCorrectStreak,
      totalReviews: newTotalReviews,
      correctReviews: newCorrectReviews,
      masteryLevel: newMasteryLevel,
      reviewHistory: newReviewHistory,
    );
  }

  /// Calculate next interval and ease factor using enhanced SM-2 algorithm
  IntervalResult _calculateNextInterval(ReviewDifficulty difficulty, bool wasCorrect) {
    final currentEase = easeFactorAsDouble;
    
    switch (difficulty) {
      case ReviewDifficulty.again:
        // Reset to learning phase with short interval
        return IntervalResult(
          intervalHours: masteryLevel.initialIntervalHours,
          easeFactor: math.max(130, easeFactor - 20), // Decrease ease factor
        );
        
      case ReviewDifficulty.hard:
        // Slightly increase interval, decrease ease factor
        final newInterval = (intervalHours * 1.2 * currentEase).round();
        return IntervalResult(
          intervalHours: math.max(masteryLevel.initialIntervalHours, newInterval),
          easeFactor: math.max(130, easeFactor - 15),
        );
        
      case ReviewDifficulty.good:
        // Standard SM-2 interval calculation
        final newInterval = (intervalHours * currentEase).round();
        return IntervalResult(
          intervalHours: newInterval,
          easeFactor: easeFactor, // Keep ease factor stable
        );
        
      case ReviewDifficulty.easy:
        // Increase interval more aggressively, increase ease factor
        final newInterval = (intervalHours * currentEase * 1.3).round();
        return IntervalResult(
          intervalHours: newInterval,
          easeFactor: math.min(300, easeFactor + 15), // Increase ease factor
        );
    }
  }

  /// Calculate new mastery level based on performance
  MasteryLevel _calculateMasteryLevel(
    ReviewDifficulty difficulty,
    int newCorrectStreak,
    int newRepetitions,
  ) {
    // If answered wrong, might demote
    if (difficulty == ReviewDifficulty.again) {
      return masteryLevel.previous ?? masteryLevel;
    }

    // Promote based on correct streak and repetitions
    switch (masteryLevel) {
      case MasteryLevel.newWord:
        if (newCorrectStreak >= 2) return MasteryLevel.learning;
        break;
      case MasteryLevel.learning:
        if (newCorrectStreak >= 4 && newRepetitions >= 3) {
          return MasteryLevel.reviewing;
        }
        break;
      case MasteryLevel.reviewing:
        if (newCorrectStreak >= 6 && newRepetitions >= 6) {
          return MasteryLevel.mastered;
        }
        break;
      case MasteryLevel.mastered:
        if (newCorrectStreak >= 10 && newRepetitions >= 10) {
          return MasteryLevel.burned;
        }
        break;
      case MasteryLevel.burned:
        // Already at max level
        break;
    }

    return masteryLevel;
  }

  EnhancedFlashcard copyWith({
    String? id,
    String? wordSlug,
    String? word,
    String? reading,
    String? furiganaReading,
    String? definition,
    List<String>? tags,
    List<int>? wordListIds,
    MasteryLevel? masteryLevel,
    DateTime? createdAt,
    DateTime? lastReviewed,
    DateTime? nextReview,
    int? intervalHours,
    int? easeFactor,
    int? repetitions,
    int? correctStreak,
    int? totalReviews,
    int? correctReviews,
    List<ReviewSession>? reviewHistory,
  }) {
    return EnhancedFlashcard(
      id: id ?? this.id,
      wordSlug: wordSlug ?? this.wordSlug,
      word: word ?? this.word,
      reading: reading ?? this.reading,
      furiganaReading: furiganaReading ?? this.furiganaReading,
      definition: definition ?? this.definition,
      tags: tags ?? this.tags,
      wordListIds: wordListIds ?? this.wordListIds,
      masteryLevel: masteryLevel ?? this.masteryLevel,
      createdAt: createdAt ?? this.createdAt,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      nextReview: nextReview ?? this.nextReview,
      intervalHours: intervalHours ?? this.intervalHours,
      easeFactor: easeFactor ?? this.easeFactor,
      repetitions: repetitions ?? this.repetitions,
      correctStreak: correctStreak ?? this.correctStreak,
      totalReviews: totalReviews ?? this.totalReviews,
      correctReviews: correctReviews ?? this.correctReviews,
      reviewHistory: reviewHistory ?? this.reviewHistory,
    );
  }
}

/// Represents a single review session for a flashcard
class ReviewSession {
  final DateTime timestamp;
  final ReviewDifficulty difficulty;
  final int intervalHours;
  final MasteryLevel masteryLevel;

  const ReviewSession({
    required this.timestamp,
    required this.difficulty,
    required this.intervalHours,
    required this.masteryLevel,
  });

  factory ReviewSession.fromJson(Map<String, dynamic> json) {
    return ReviewSession(
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      difficulty: ReviewDifficulty.fromValue(json['difficulty'] as int),
      intervalHours: json['interval_hours'] as int,
      masteryLevel: MasteryLevel.fromLevel(json['mastery_level'] as int),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.millisecondsSinceEpoch,
      'difficulty': difficulty.value,
      'interval_hours': intervalHours,
      'mastery_level': masteryLevel.level,
    };
  }
}

/// Result of interval calculation
class IntervalResult {
  final int intervalHours;
  final int easeFactor;

  const IntervalResult({
    required this.intervalHours,
    required this.easeFactor,
  });
}