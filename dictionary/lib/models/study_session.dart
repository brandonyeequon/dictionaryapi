import 'word_mastery.dart';

/// Represents a complete study session with multiple card reviews
class StudySession {
  final String id;
  final DateTime startTime;
  DateTime? endTime;
  final List<CardReview> cardReviews;
  final StudySessionType sessionType;
  final List<int>? targetWordListIds; // Specific lists studied, if any

  StudySession({
    required this.id,
    required this.startTime,
    this.endTime,
    this.cardReviews = const [],
    this.sessionType = StudySessionType.mixed,
    this.targetWordListIds,
  });

  /// Duration of the study session
  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  /// Total number of cards reviewed
  int get totalCards => cardReviews.length;

  /// Number of correct answers
  int get correctAnswers => cardReviews.where((r) => r.wasCorrect).length;

  /// Number of incorrect answers
  int get incorrectAnswers => totalCards - correctAnswers;

  /// Accuracy percentage
  double get accuracy {
    if (totalCards == 0) return 0.0;
    return (correctAnswers / totalCards) * 100;
  }

  /// Average response time in seconds
  double get averageResponseTime {
    if (cardReviews.isEmpty) return 0.0;
    final totalTime = cardReviews
        .map((r) => r.responseTimeSeconds)
        .fold(0.0, (sum, time) => sum + time);
    return totalTime / cardReviews.length;
  }

  /// Cards by difficulty level
  Map<ReviewDifficulty, int> get cardsByDifficulty {
    final counts = <ReviewDifficulty, int>{};
    for (final difficulty in ReviewDifficulty.values) {
      counts[difficulty] = cardReviews
          .where((r) => r.difficulty == difficulty)
          .length;
    }
    return counts;
  }

  /// Check if session is complete (has end time)
  bool get isComplete => endTime != null;

  /// Check if this was a perfect session (100% accuracy)
  bool get isPerfectSession => totalCards > 0 && accuracy == 100.0;

  /// Check if this was a long session (>= 30 minutes)
  bool get isLongSession => duration.inMinutes >= 30;

  /// Check if this was a focused session (>= 20 cards)
  bool get isFocusedSession => totalCards >= 20;

  /// Add a card review to this session
  StudySession addCardReview(CardReview review) {
    return copyWith(
      cardReviews: [...cardReviews, review],
    );
  }

  /// Complete the study session
  StudySession complete() {
    return copyWith(endTime: DateTime.now());
  }

  factory StudySession.fromJson(Map<String, dynamic> json) {
    final cardReviewsJson = json['card_reviews'] as List<dynamic>? ?? [];
    final cardReviews = cardReviewsJson
        .map((e) => CardReview.fromJson(e as Map<String, dynamic>))
        .toList();

    return StudySession(
      id: json['id'] as String,
      startTime: DateTime.fromMillisecondsSinceEpoch(json['start_time'] as int),
      endTime: json['end_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['end_time'] as int)
          : null,
      cardReviews: cardReviews,
      sessionType: StudySessionType.fromValue(json['session_type'] as int? ?? 0),
      targetWordListIds: json['target_word_list_ids'] != null
          ? List<int>.from(json['target_word_list_ids'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': endTime?.millisecondsSinceEpoch,
      'card_reviews': cardReviews.map((e) => e.toJson()).toList(),
      'session_type': sessionType.value,
      'target_word_list_ids': targetWordListIds,
    };
  }

  StudySession copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    List<CardReview>? cardReviews,
    StudySessionType? sessionType,
    List<int>? targetWordListIds,
  }) {
    return StudySession(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      cardReviews: cardReviews ?? this.cardReviews,
      sessionType: sessionType ?? this.sessionType,
      targetWordListIds: targetWordListIds ?? this.targetWordListIds,
    );
  }
}

/// Individual card review within a study session
class CardReview {
  final String cardId;
  final String wordSlug;
  final ReviewDifficulty difficulty;
  final double responseTimeSeconds;
  final DateTime timestamp;
  final MasteryLevel previousLevel;
  final MasteryLevel newLevel;

  const CardReview({
    required this.cardId,
    required this.wordSlug,
    required this.difficulty,
    required this.responseTimeSeconds,
    required this.timestamp,
    required this.previousLevel,
    required this.newLevel,
  });

  /// Check if the answer was correct
  bool get wasCorrect => difficulty.value >= 2; // Good or Easy

  /// Check if the mastery level increased
  bool get leveledUp => newLevel.level > previousLevel.level;

  /// Check if the mastery level decreased
  bool get leveledDown => newLevel.level < previousLevel.level;

  factory CardReview.fromJson(Map<String, dynamic> json) {
    return CardReview(
      cardId: json['card_id'] as String,
      wordSlug: json['word_slug'] as String,
      difficulty: ReviewDifficulty.fromValue(json['difficulty'] as int),
      responseTimeSeconds: (json['response_time_seconds'] as num).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      previousLevel: MasteryLevel.fromLevel(json['previous_level'] as int),
      newLevel: MasteryLevel.fromLevel(json['new_level'] as int),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'card_id': cardId,
      'word_slug': wordSlug,
      'difficulty': difficulty.value,
      'response_time_seconds': responseTimeSeconds,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'previous_level': previousLevel.level,
      'new_level': newLevel.level,
    };
  }
}

/// Types of study sessions
enum StudySessionType {
  /// Mixed review from all lists
  mixed(0, 'Mixed Review', 'Review cards from all word lists'),
  
  /// Review specific word lists
  targeted(1, 'List Study', 'Study specific word lists'),
  
  /// Review only due cards
  due(2, 'Due Cards', 'Review cards that are due for review'),
  
  /// Review only new cards
  newCards(3, 'New Cards', 'Study newly added words'),
  
  /// Review only difficult cards (low accuracy)
  difficult(4, 'Difficult Cards', 'Focus on challenging words'),
  
  /// Cram session (ignore intervals)
  cram(5, 'Cram Session', 'Intensive review session');

  const StudySessionType(this.value, this.displayName, this.description);

  final int value;
  final String displayName;
  final String description;

  static StudySessionType fromValue(int value) {
    return StudySessionType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => StudySessionType.mixed,
    );
  }
}

/// Study session statistics and analytics
class StudySessionStats {
  final int totalSessions;
  final int totalCards;
  final double averageAccuracy;
  final Duration totalStudyTime;
  final DateTime? lastSessionDate;
  final int currentStreak;
  final int longestStreak;
  final Map<StudySessionType, int> sessionsByType;
  final Map<ReviewDifficulty, int> reviewsByDifficulty;

  const StudySessionStats({
    this.totalSessions = 0,
    this.totalCards = 0,
    this.averageAccuracy = 0.0,
    this.totalStudyTime = Duration.zero,
    this.lastSessionDate,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.sessionsByType = const {},
    this.reviewsByDifficulty = const {},
  });

  /// Average cards per session
  double get averageCardsPerSession {
    if (totalSessions == 0) return 0.0;
    return totalCards / totalSessions;
  }

  /// Average study time per session
  Duration get averageSessionDuration {
    if (totalSessions == 0) return Duration.zero;
    return Duration(
      milliseconds: totalStudyTime.inMilliseconds ~/ totalSessions,
    );
  }

  /// Check if user studied today
  bool get studiedToday {
    if (lastSessionDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastStudy = DateTime(
      lastSessionDate!.year,
      lastSessionDate!.month,
      lastSessionDate!.day,
    );
    return lastStudy.isAtSameMomentAs(today);
  }

  factory StudySessionStats.fromJson(Map<String, dynamic> json) {
    final sessionsByTypeJson = json['sessions_by_type'] as Map<String, dynamic>? ?? {};
    final sessionsByType = <StudySessionType, int>{};
    for (final entry in sessionsByTypeJson.entries) {
      final type = StudySessionType.fromValue(int.parse(entry.key));
      sessionsByType[type] = entry.value as int;
    }

    final reviewsByDifficultyJson = json['reviews_by_difficulty'] as Map<String, dynamic>? ?? {};
    final reviewsByDifficulty = <ReviewDifficulty, int>{};
    for (final entry in reviewsByDifficultyJson.entries) {
      final difficulty = ReviewDifficulty.fromValue(int.parse(entry.key));
      reviewsByDifficulty[difficulty] = entry.value as int;
    }

    return StudySessionStats(
      totalSessions: json['total_sessions'] as int? ?? 0,
      totalCards: json['total_cards'] as int? ?? 0,
      averageAccuracy: (json['average_accuracy'] as num?)?.toDouble() ?? 0.0,
      totalStudyTime: Duration(
        milliseconds: json['total_study_time_ms'] as int? ?? 0,
      ),
      lastSessionDate: json['last_session_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['last_session_date'] as int)
          : null,
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      sessionsByType: sessionsByType,
      reviewsByDifficulty: reviewsByDifficulty,
    );
  }

  Map<String, dynamic> toJson() {
    final sessionsByTypeJson = <String, int>{};
    for (final entry in sessionsByType.entries) {
      sessionsByTypeJson[entry.key.value.toString()] = entry.value;
    }

    final reviewsByDifficultyJson = <String, int>{};
    for (final entry in reviewsByDifficulty.entries) {
      reviewsByDifficultyJson[entry.key.value.toString()] = entry.value;
    }

    return {
      'total_sessions': totalSessions,
      'total_cards': totalCards,
      'average_accuracy': averageAccuracy,
      'total_study_time_ms': totalStudyTime.inMilliseconds,
      'last_session_date': lastSessionDate?.millisecondsSinceEpoch,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'sessions_by_type': sessionsByTypeJson,
      'reviews_by_difficulty': reviewsByDifficultyJson,
    };
  }
}