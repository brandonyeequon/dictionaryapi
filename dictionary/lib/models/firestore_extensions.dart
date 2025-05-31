import 'package:cloud_firestore/cloud_firestore.dart';
import 'enhanced_flashcard.dart';
import 'study_session.dart';
import 'user_progress.dart';
import 'word_entry.dart';
import 'word_list.dart';
import 'word_mastery.dart';

/// Extensions to handle Firestore Timestamp conversions
extension EnhancedFlashcardFirestore on EnhancedFlashcard {
  /// Convert to Firestore-compatible JSON with Timestamps
  Map<String, dynamic> toFirestoreJson() {
    return {
      'id': id,
      'wordSlug': wordSlug,
      'word': word,
      'reading': reading,
      'definition': definition,
      'tags': tags,
      'wordListIds': wordListIds,
      'masteryLevel': masteryLevel.level,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastReviewed': Timestamp.fromDate(lastReviewed),
      'nextReview': Timestamp.fromDate(nextReview),
      'intervalHours': intervalHours,
      'easeFactor': easeFactor,
      'repetitions': repetitions,
      'correctStreak': correctStreak,
      'totalReviews': totalReviews,
      'correctReviews': correctReviews,
      'reviewHistory': reviewHistory.map((e) => e.toFirestoreJson()).toList(),
      'isLearning': !isLearned,
    };
  }

  /// Create from Firestore document data
  static EnhancedFlashcard fromFirestoreJson(Map<String, dynamic> json) {
    final reviewHistoryJson = json['reviewHistory'] as List<dynamic>? ?? [];
    final reviewHistory = reviewHistoryJson
        .map((e) => ReviewSessionFirestoreStatic.fromFirestoreJson(e as Map<String, dynamic>))
        .toList();

    return EnhancedFlashcard(
      id: json['id'] as String,
      wordSlug: json['wordSlug'] as String,
      word: json['word'] as String,
      reading: json['reading'] as String,
      definition: json['definition'] as String,
      tags: List<String>.from(json['tags'] ?? []),
      wordListIds: List<int>.from(json['wordListIds'] ?? []),
      masteryLevel: MasteryLevel.fromLevel(json['masteryLevel'] as int? ?? 0),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      lastReviewed: (json['lastReviewed'] as Timestamp).toDate(),
      nextReview: (json['nextReview'] as Timestamp).toDate(),
      intervalHours: json['intervalHours'] as int? ?? 4,
      easeFactor: json['easeFactor'] as int? ?? 250,
      repetitions: json['repetitions'] as int? ?? 0,
      correctStreak: json['correctStreak'] as int? ?? 0,
      totalReviews: json['totalReviews'] as int? ?? 0,
      correctReviews: json['correctReviews'] as int? ?? 0,
      reviewHistory: reviewHistory,
    );
  }
}

extension ReviewSessionFirestore on ReviewSession {
  Map<String, dynamic> toFirestoreJson() {
    return {
      'timestamp': Timestamp.fromDate(timestamp),
      'difficulty': difficulty.value,
      'intervalHours': intervalHours,
      'masteryLevel': masteryLevel.level,
    };
  }
}

extension ReviewSessionFirestoreStatic on ReviewSession {
  static ReviewSession fromFirestoreJson(Map<String, dynamic> json) {
    return ReviewSession(
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      difficulty: ReviewDifficulty.fromValue(json['difficulty'] as int),
      intervalHours: json['intervalHours'] as int,
      masteryLevel: MasteryLevel.fromLevel(json['masteryLevel'] as int),
    );
  }
}

extension StudySessionFirestore on StudySession {
  Map<String, dynamic> toFirestoreJson() {
    return {
      'id': id,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'cardReviews': cardReviews.map((e) => e.toFirestoreJson()).toList(),
      'sessionType': sessionType.value,
      'targetWordListIds': targetWordListIds,
    };
  }

  static StudySession fromFirestoreJson(Map<String, dynamic> json) {
    final cardReviewsJson = json['cardReviews'] as List<dynamic>? ?? [];
    final cardReviews = cardReviewsJson
        .map((e) => CardReviewFirestoreStatic.fromFirestoreJson(e as Map<String, dynamic>))
        .toList();

    return StudySession(
      id: json['id'] as String,
      startTime: (json['startTime'] as Timestamp).toDate(),
      endTime: json['endTime'] != null ? (json['endTime'] as Timestamp).toDate() : null,
      cardReviews: cardReviews,
      sessionType: StudySessionType.fromValue(json['sessionType'] as int? ?? 0),
      targetWordListIds: json['targetWordListIds'] != null
          ? List<int>.from(json['targetWordListIds'])
          : null,
    );
  }
}

extension CardReviewFirestore on CardReview {
  Map<String, dynamic> toFirestoreJson() {
    return {
      'cardId': cardId,
      'wordSlug': wordSlug,
      'difficulty': difficulty.value,
      'responseTimeSeconds': responseTimeSeconds,
      'timestamp': Timestamp.fromDate(timestamp),
      'previousLevel': previousLevel.level,
      'newLevel': newLevel.level,
    };
  }
}

extension CardReviewFirestoreStatic on CardReview {
  static CardReview fromFirestoreJson(Map<String, dynamic> json) {
    return CardReview(
      cardId: json['cardId'] as String,
      wordSlug: json['wordSlug'] as String,
      difficulty: ReviewDifficulty.fromValue(json['difficulty'] as int),
      responseTimeSeconds: (json['responseTimeSeconds'] as num).toDouble(),
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      previousLevel: MasteryLevel.fromLevel(json['previousLevel'] as int),
      newLevel: MasteryLevel.fromLevel(json['newLevel'] as int),
    );
  }
}

extension UserProgressFirestore on UserProgress {
  Map<String, dynamic> toFirestoreJson() {
    final wordCountJson = <String, int>{};
    for (final entry in wordCountByLevel.entries) {
      wordCountJson[entry.key.level.toString()] = entry.value;
    }

    return {
      'totalWordsStudied': totalWordsStudied,
      'wordsPerLevel': wordsPerLevel,
      'lastStudySession': lastStudySession != null 
          ? Timestamp.fromDate(lastStudySession!) 
          : null,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'streakStartDate': streakStartDate != null 
          ? Timestamp.fromDate(streakStartDate!) 
          : null,
      'wordCountByLevel': wordCountJson,
      'totalReviews': totalReviews,
      'averageAccuracy': averageAccuracy,
      'studyTimeMinutes': studyTimeMinutes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static UserProgress fromFirestoreJson(Map<String, dynamic> json) {
    final wordCountByLevel = <MasteryLevel, int>{};
    final wordCountJson = json['wordCountByLevel'] as Map<String, dynamic>? ?? {};
    
    for (final entry in wordCountJson.entries) {
      final level = MasteryLevel.fromLevel(int.parse(entry.key));
      wordCountByLevel[level] = entry.value as int;
    }

    return UserProgress(
      totalWordsStudied: json['totalWordsStudied'] as int? ?? 0,
      wordsPerLevel: json['wordsPerLevel'] as int? ?? 10,
      lastStudySession: json['lastStudySession'] != null
          ? (json['lastStudySession'] as Timestamp).toDate()
          : null,
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      streakStartDate: json['streakStartDate'] != null
          ? (json['streakStartDate'] as Timestamp).toDate()
          : null,
      wordCountByLevel: wordCountByLevel,
      totalReviews: json['totalReviews'] as int? ?? 0,
      averageAccuracy: (json['averageAccuracy'] as num?)?.toDouble() ?? 0.0,
      studyTimeMinutes: json['studyTimeMinutes'] as int? ?? 0,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }
}

extension WordListFirestore on WordList {
  Map<String, dynamic> toFirestoreJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

extension WordListFirestoreStatic on WordList {
  static WordList fromFirestoreJson(Map<String, dynamic> json) {
    return WordList(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }
}

extension WordEntryFirestore on WordEntry {
  Map<String, dynamic> toFirestoreJson() {
    return {
      'slug': slug,
      'isCommon': isCommon,
      'tags': tags,
      'jlpt': jlpt,
      'japanese': japanese.map((j) => j.toJson()).toList(),
      'senses': senses.map((s) => s.toJson()).toList(),
      'addedToFavoritesAt': Timestamp.now(),
    };
  }
}

extension WordEntryFirestoreStatic on WordEntry {
  static WordEntry fromFirestoreJson(Map<String, dynamic> json) {
    return WordEntry.fromJson(json);
  }
}