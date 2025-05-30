import 'word_mastery.dart';

/// Represents overall user progress and statistics
class UserProgress {
  final int totalWordsStudied;
  final int wordsPerLevel;
  final DateTime? lastStudySession;
  final int currentStreak;
  final int longestStreak;
  final DateTime? streakStartDate;
  final Map<MasteryLevel, int> wordCountByLevel;
  final int totalReviews;
  final double averageAccuracy;
  final int studyTimeMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProgress({
    this.totalWordsStudied = 0,
    this.wordsPerLevel = 10, // Words needed to level up
    this.lastStudySession,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.streakStartDate,
    this.wordCountByLevel = const {},
    this.totalReviews = 0,
    this.averageAccuracy = 0.0,
    this.studyTimeMinutes = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Calculate the user's current level based on mastered words
  int get currentLevel {
    final masteredWords = wordCountByLevel[MasteryLevel.mastered] ?? 0;
    final burnedWords = wordCountByLevel[MasteryLevel.burned] ?? 0;
    final totalMasteredWords = masteredWords + burnedWords;
    return (totalMasteredWords / wordsPerLevel).floor() + 1;
  }

  /// Get progress to next level (0.0 to 1.0)
  double get progressToNextLevel {
    final masteredWords = wordCountByLevel[MasteryLevel.mastered] ?? 0;
    final burnedWords = wordCountByLevel[MasteryLevel.burned] ?? 0;
    final totalMasteredWords = masteredWords + burnedWords;
    final currentLevelWords = totalMasteredWords % wordsPerLevel;
    return currentLevelWords / wordsPerLevel;
  }

  /// Words needed to reach next level
  int get wordsToNextLevel {
    final masteredWords = wordCountByLevel[MasteryLevel.mastered] ?? 0;
    final burnedWords = wordCountByLevel[MasteryLevel.burned] ?? 0;
    final totalMasteredWords = masteredWords + burnedWords;
    final currentLevelWords = totalMasteredWords % wordsPerLevel;
    return wordsPerLevel - currentLevelWords;
  }

  /// Check if user studied today
  bool get studiedToday {
    if (lastStudySession == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastStudy = DateTime(
      lastStudySession!.year,
      lastStudySession!.month,
      lastStudySession!.day,
    );
    return lastStudy.isAtSameMomentAs(today);
  }

  /// Check if user's streak is still valid (studied today or yesterday)
  bool get isStreakActive {
    if (lastStudySession == null) return false;
    final now = DateTime.now();
    final daysSinceLastStudy = now.difference(lastStudySession!).inDays;
    return daysSinceLastStudy <= 1;
  }

  /// Get total active words (not burned)
  int get activeWordsCount {
    return wordCountByLevel.entries
        .where((entry) => entry.key.isActive)
        .map((entry) => entry.value)
        .fold(0, (sum, count) => sum + count);
  }

  /// Get achievement milestones
  List<Achievement> get recentAchievements {
    final achievements = <Achievement>[];
    
    // Level achievements
    if (currentLevel >= 5) achievements.add(Achievement.level5);
    if (currentLevel >= 10) achievements.add(Achievement.level10);
    if (currentLevel >= 25) achievements.add(Achievement.level25);
    if (currentLevel >= 50) achievements.add(Achievement.level50);
    
    // Streak achievements
    if (currentStreak >= 7) achievements.add(Achievement.streak7);
    if (currentStreak >= 30) achievements.add(Achievement.streak30);
    if (currentStreak >= 100) achievements.add(Achievement.streak100);
    
    // Word count achievements
    if (totalWordsStudied >= 100) achievements.add(Achievement.words100);
    if (totalWordsStudied >= 500) achievements.add(Achievement.words500);
    if (totalWordsStudied >= 1000) achievements.add(Achievement.words1000);
    
    return achievements;
  }

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    final wordCountByLevel = <MasteryLevel, int>{};
    final wordCountJson = json['word_count_by_level'] as Map<String, dynamic>? ?? {};
    
    for (final entry in wordCountJson.entries) {
      final level = MasteryLevel.fromLevel(int.parse(entry.key));
      wordCountByLevel[level] = entry.value as int;
    }

    return UserProgress(
      totalWordsStudied: json['total_words_studied'] as int? ?? 0,
      wordsPerLevel: json['words_per_level'] as int? ?? 10,
      lastStudySession: json['last_study_session'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['last_study_session'] as int)
          : null,
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      streakStartDate: json['streak_start_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['streak_start_date'] as int)
          : null,
      wordCountByLevel: wordCountByLevel,
      totalReviews: json['total_reviews'] as int? ?? 0,
      averageAccuracy: (json['average_accuracy'] as num?)?.toDouble() ?? 0.0,
      studyTimeMinutes: json['study_time_minutes'] as int? ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updated_at'] as int),
    );
  }

  Map<String, dynamic> toJson() {
    final wordCountJson = <String, int>{};
    for (final entry in wordCountByLevel.entries) {
      wordCountJson[entry.key.level.toString()] = entry.value;
    }

    return {
      'total_words_studied': totalWordsStudied,
      'words_per_level': wordsPerLevel,
      'last_study_session': lastStudySession?.millisecondsSinceEpoch,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'streak_start_date': streakStartDate?.millisecondsSinceEpoch,
      'word_count_by_level': wordCountJson,
      'total_reviews': totalReviews,
      'average_accuracy': averageAccuracy,
      'study_time_minutes': studyTimeMinutes,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  UserProgress copyWith({
    int? totalWordsStudied,
    int? wordsPerLevel,
    DateTime? lastStudySession,
    int? currentStreak,
    int? longestStreak,
    DateTime? streakStartDate,
    Map<MasteryLevel, int>? wordCountByLevel,
    int? totalReviews,
    double? averageAccuracy,
    int? studyTimeMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProgress(
      totalWordsStudied: totalWordsStudied ?? this.totalWordsStudied,
      wordsPerLevel: wordsPerLevel ?? this.wordsPerLevel,
      lastStudySession: lastStudySession ?? this.lastStudySession,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      streakStartDate: streakStartDate ?? this.streakStartDate,
      wordCountByLevel: wordCountByLevel ?? this.wordCountByLevel,
      totalReviews: totalReviews ?? this.totalReviews,
      averageAccuracy: averageAccuracy ?? this.averageAccuracy,
      studyTimeMinutes: studyTimeMinutes ?? this.studyTimeMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Represents different achievements users can unlock
enum Achievement {
  // Level achievements
  level5('Level 5', 'Reached level 5', '🌟'),
  level10('Level 10', 'Reached level 10', '⭐'),
  level25('Level 25', 'Reached level 25', '🏆'),
  level50('Level 50', 'Reached level 50', '👑'),
  
  // Streak achievements
  streak7('Week Warrior', '7-day study streak', '🔥'),
  streak30('Monthly Master', '30-day study streak', '💪'),
  streak100('Century Scholar', '100-day study streak', '🎯'),
  
  // Word count achievements
  words100('Hundred Hunter', 'Studied 100 words', '📚'),
  words500('Word Warrior', 'Studied 500 words', '⚔️'),
  words1000('Vocabulary Victor', 'Studied 1000 words', '🏅'),
  
  // Special achievements
  perfectDay('Perfect Day', 'Perfect accuracy in a session', '💯'),
  speedster('Speedster', 'Completed 50 reviews in one session', '⚡'),
  consistent('Consistent Learner', 'Studied for 7 consecutive days', '📈');

  const Achievement(this.title, this.description, this.emoji);

  final String title;
  final String description;
  final String emoji;
}