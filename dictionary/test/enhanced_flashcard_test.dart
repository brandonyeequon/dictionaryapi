import 'package:flutter_test/flutter_test.dart';
import 'package:dictionary/models/enhanced_flashcard.dart';
import 'package:dictionary/models/word_mastery.dart';
import 'package:dictionary/models/user_progress.dart';

void main() {
  group('Enhanced Flashcard System Tests', () {
    group('Word Mastery Tests', () {
      test('mastery level progression works correctly', () {
        expect(MasteryLevel.newWord.next, MasteryLevel.learning);
        expect(MasteryLevel.learning.next, MasteryLevel.reviewing);
        expect(MasteryLevel.reviewing.next, MasteryLevel.mastered);
        expect(MasteryLevel.mastered.next, MasteryLevel.burned);
        expect(MasteryLevel.burned.next, null);
      });

      test('mastery level demotion works correctly', () {
        expect(MasteryLevel.newWord.previous, null);
        expect(MasteryLevel.learning.previous, MasteryLevel.newWord);
        expect(MasteryLevel.reviewing.previous, MasteryLevel.learning);
        expect(MasteryLevel.mastered.previous, MasteryLevel.reviewing);
        expect(MasteryLevel.burned.previous, MasteryLevel.mastered);
      });

      test('active levels are identified correctly', () {
        expect(MasteryLevel.newWord.isActive, true);
        expect(MasteryLevel.learning.isActive, true);
        expect(MasteryLevel.reviewing.isActive, true);
        expect(MasteryLevel.mastered.isActive, true);
        expect(MasteryLevel.burned.isActive, false);
      });

      test('initial intervals are correctly set', () {
        expect(MasteryLevel.newWord.initialIntervalHours, 4);
        expect(MasteryLevel.learning.initialIntervalHours, 8);
        expect(MasteryLevel.reviewing.initialIntervalHours, 24);
        expect(MasteryLevel.mastered.initialIntervalHours, 168);
        expect(MasteryLevel.burned.initialIntervalHours, 8760);
      });
    });

    group('Enhanced Flashcard Tests', () {
      test('flashcard creation works correctly', () {
        final now = DateTime.now();
        final flashcard = EnhancedFlashcard(
          id: 'test_id',
          wordSlug: 'house',
          word: '家',
          reading: 'いえ',
          definition: 'house, home',
          tags: ['N5', 'basic'],
          wordListIds: [1, 2],
          createdAt: now,
          lastReviewed: now,
          nextReview: now.add(const Duration(hours: 4)),
        );

        expect(flashcard.wordSlug, 'house');
        expect(flashcard.word, '家');
        expect(flashcard.reading, 'いえ');
        expect(flashcard.definition, 'house, home');
        expect(flashcard.wordListIds, [1, 2]);
        expect(flashcard.masteryLevel, MasteryLevel.newWord);
        expect(flashcard.correctStreak, 0);
        expect(flashcard.totalReviews, 0);
        expect(flashcard.accuracy, 0.0);
      });

      test('flashcard review updates stats correctly', () {
        final now = DateTime.now();
        final flashcard = EnhancedFlashcard(
          id: 'test',
          wordSlug: 'test',
          word: 'テスト',
          reading: 'tesuto',
          definition: 'test',
          tags: [],
          wordListIds: [1],
          createdAt: now,
          lastReviewed: now,
          nextReview: now,
        );

        // Review with "Good" difficulty
        final updatedCard = flashcard.reviewCard(ReviewDifficulty.good);

        expect(updatedCard.totalReviews, 1);
        expect(updatedCard.correctReviews, 1);
        expect(updatedCard.correctStreak, 1);
        expect(updatedCard.accuracy, 100.0);
        expect(updatedCard.intervalHours, greaterThan(flashcard.intervalHours));
        expect(updatedCard.nextReview.isAfter(flashcard.nextReview), true);
      });

      test('wrong answer resets streak', () {
        final now = DateTime.now();
        var flashcard = EnhancedFlashcard(
          id: 'test',
          wordSlug: 'test',
          word: 'テスト',
          reading: 'tesuto',
          definition: 'test',
          tags: [],
          wordListIds: [1],
          masteryLevel: MasteryLevel.learning,
          correctStreak: 5,
          totalReviews: 10,
          correctReviews: 8,
          createdAt: now,
          lastReviewed: now,
          nextReview: now,
        );

        final updatedCard = flashcard.reviewCard(ReviewDifficulty.again);

        expect(updatedCard.correctStreak, 0);
        expect(updatedCard.totalReviews, 11);
        expect(updatedCard.correctReviews, 8); // No increase for wrong answer
        expect(updatedCard.accuracy, lessThan(flashcard.accuracy));
      });

      test('due for review calculation works correctly', () {
        final now = DateTime.now();
        
        // Card due for review
        final dueCard = EnhancedFlashcard(
          id: 'due',
          wordSlug: 'due',
          word: 'due',
          reading: 'due',
          definition: 'due',
          tags: [],
          wordListIds: [1],
          createdAt: now,
          lastReviewed: now.subtract(const Duration(hours: 5)),
          nextReview: now.subtract(const Duration(hours: 1)), // 1 hour ago
        );

        // Card not due yet
        final notDueCard = EnhancedFlashcard(
          id: 'not_due',
          wordSlug: 'not_due',
          word: 'not_due',
          reading: 'not_due',
          definition: 'not_due',
          tags: [],
          wordListIds: [1],
          createdAt: now,
          lastReviewed: now,
          nextReview: now.add(const Duration(hours: 1)), // 1 hour from now
        );

        expect(dueCard.isDueForReview, true);
        expect(notDueCard.isDueForReview, false);
      });

      test('ease factor conversion works correctly', () {
        final flashcard = EnhancedFlashcard(
          id: 'test',
          wordSlug: 'test',
          word: 'test',
          reading: 'test',
          definition: 'test',
          tags: [],
          wordListIds: [1],
          easeFactor: 250, // 2.5 as integer
          createdAt: DateTime.now(),
          lastReviewed: DateTime.now(),
          nextReview: DateTime.now(),
        );

        expect(flashcard.easeFactorAsDouble, 2.5);
      });
    });

    group('User Progress Tests', () {
      test('user level calculation works correctly', () {
        final progress = UserProgress(
          wordCountByLevel: {
            MasteryLevel.mastered: 15,
            MasteryLevel.burned: 5,
          },
          wordsPerLevel: 10,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(progress.currentLevel, 3); // (15 + 5) / 10 + 1 = 3
        expect(progress.progressToNextLevel, 0.0); // 20 % 10 = 0
        expect(progress.wordsToNextLevel, 10);
      });

      test('partial level progress calculation works', () {
        final progress = UserProgress(
          wordCountByLevel: {
            MasteryLevel.mastered: 7,
            MasteryLevel.burned: 0,
          },
          wordsPerLevel: 10,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(progress.currentLevel, 1); // 7 / 10 + 1 = 1
        expect(progress.progressToNextLevel, 0.7); // 7 / 10 = 0.7
        expect(progress.wordsToNextLevel, 3); // 10 - 7 = 3
      });

      test('streak validation works correctly', () {
        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 1));
        final twoDaysAgo = now.subtract(const Duration(days: 2));

        // Active streak (studied yesterday)
        final activeProgress = UserProgress(
          lastStudySession: yesterday,
          currentStreak: 5,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(activeProgress.isStreakActive, true);

        // Broken streak (studied two days ago)
        final brokenProgress = UserProgress(
          lastStudySession: twoDaysAgo,
          currentStreak: 5,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(brokenProgress.isStreakActive, false);
      });

      test('studied today detection works correctly', () {
        final now = DateTime.now();
        final today = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 1));

        final studiedTodayProgress = UserProgress(
          lastStudySession: today,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final studiedYesterdayProgress = UserProgress(
          lastStudySession: yesterday,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(studiedTodayProgress.studiedToday, true);
        expect(studiedYesterdayProgress.studiedToday, false);
      });

      test('achievements are unlocked based on progress', () {
        final progress = UserProgress(
          currentStreak: 30,
          totalWordsStudied: 500,
          wordCountByLevel: {
            MasteryLevel.mastered: 25,
            MasteryLevel.burned: 25,
          },
          wordsPerLevel: 10,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final achievements = progress.recentAchievements;
        
        expect(achievements.contains(Achievement.streak30), true);
        expect(achievements.contains(Achievement.words500), true);
        expect(achievements.contains(Achievement.level5), true);
      });

      test('active words count calculation works', () {
        final progress = UserProgress(
          wordCountByLevel: {
            MasteryLevel.newWord: 10,
            MasteryLevel.learning: 15,
            MasteryLevel.reviewing: 20,
            MasteryLevel.mastered: 25,
            MasteryLevel.burned: 30, // Not active
          },
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(progress.activeWordsCount, 70); // 10 + 15 + 20 + 25 = 70
      });
    });

    group('Review Difficulty Tests', () {
      test('difficulty values are correctly ordered', () {
        expect(ReviewDifficulty.again.value, 0);
        expect(ReviewDifficulty.hard.value, 1);
        expect(ReviewDifficulty.good.value, 2);
        expect(ReviewDifficulty.easy.value, 3);
      });

      test('difficulty colors are assigned', () {
        expect(ReviewDifficulty.again.colorValue, isNonZero);
        expect(ReviewDifficulty.hard.colorValue, isNonZero);
        expect(ReviewDifficulty.good.colorValue, isNonZero);
        expect(ReviewDifficulty.easy.colorValue, isNonZero);
      });

      test('difficulty from value works correctly', () {
        expect(ReviewDifficulty.fromValue(0), ReviewDifficulty.again);
        expect(ReviewDifficulty.fromValue(1), ReviewDifficulty.hard);
        expect(ReviewDifficulty.fromValue(2), ReviewDifficulty.good);
        expect(ReviewDifficulty.fromValue(3), ReviewDifficulty.easy);
        expect(ReviewDifficulty.fromValue(999), ReviewDifficulty.good); // Invalid defaults to good
      });
    });

    group('JSON Serialization Tests', () {
      test('enhanced flashcard can be serialized and deserialized', () {
        final originalCard = EnhancedFlashcard(
          id: 'test_id',
          wordSlug: 'house',
          word: '家',
          reading: 'いえ',
          definition: 'house, home',
          tags: ['N5', 'basic'],
          wordListIds: [1, 2, 3],
          masteryLevel: MasteryLevel.learning,
          createdAt: DateTime(2024, 1, 1),
          lastReviewed: DateTime(2024, 1, 2),
          nextReview: DateTime(2024, 1, 3),
          intervalHours: 24,
          easeFactor: 250,
          repetitions: 5,
          correctStreak: 3,
          totalReviews: 8,
          correctReviews: 6,
        );

        final json = originalCard.toJson();
        final deserializedCard = EnhancedFlashcard.fromJson(json);

        expect(deserializedCard.id, originalCard.id);
        expect(deserializedCard.wordSlug, originalCard.wordSlug);
        expect(deserializedCard.word, originalCard.word);
        expect(deserializedCard.reading, originalCard.reading);
        expect(deserializedCard.definition, originalCard.definition);
        expect(deserializedCard.tags, originalCard.tags);
        expect(deserializedCard.wordListIds, originalCard.wordListIds);
        expect(deserializedCard.masteryLevel, originalCard.masteryLevel);
        expect(deserializedCard.correctStreak, originalCard.correctStreak);
        expect(deserializedCard.totalReviews, originalCard.totalReviews);
        expect(deserializedCard.accuracy, originalCard.accuracy);
        expect(deserializedCard.createdAt, originalCard.createdAt);
      });

      test('user progress can be serialized and deserialized', () {
        final originalProgress = UserProgress(
          totalWordsStudied: 100,
          currentStreak: 15,
          longestStreak: 30,
          wordCountByLevel: {
            MasteryLevel.newWord: 10,
            MasteryLevel.learning: 20,
            MasteryLevel.reviewing: 30,
            MasteryLevel.mastered: 25,
            MasteryLevel.burned: 15,
          },
          totalReviews: 500,
          averageAccuracy: 85.5,
          studyTimeMinutes: 1200,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 15),
        );

        final json = originalProgress.toJson();
        final deserializedProgress = UserProgress.fromJson(json);

        expect(deserializedProgress.totalWordsStudied, originalProgress.totalWordsStudied);
        expect(deserializedProgress.currentStreak, originalProgress.currentStreak);
        expect(deserializedProgress.longestStreak, originalProgress.longestStreak);
        expect(deserializedProgress.wordCountByLevel.length, originalProgress.wordCountByLevel.length);
        expect(deserializedProgress.averageAccuracy, originalProgress.averageAccuracy);
        expect(deserializedProgress.currentLevel, originalProgress.currentLevel);
        expect(deserializedProgress.createdAt, originalProgress.createdAt);
        expect(deserializedProgress.updatedAt, originalProgress.updatedAt);
      });
    });
  });
}