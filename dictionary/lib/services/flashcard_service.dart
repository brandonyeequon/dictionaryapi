import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/flashcard.dart';
import '../models/word_entry.dart';
import 'storage/storage_interface.dart';
import 'storage/storage_factory.dart';

enum ReviewDifficulty { again, hard, good, easy }

class FlashcardService extends ChangeNotifier {
  static final FlashcardService _instance = FlashcardService._internal();
  factory FlashcardService() => _instance;
  FlashcardService._internal();

  final List<Flashcard> _flashcards = [];
  bool _isLoaded = false;
  late final StorageInterface _storage;

  bool get isLoaded => _isLoaded;
  List<Flashcard> get flashcards => List.unmodifiable(_flashcards);
  int get totalFlashcards => _flashcards.length;
  
  List<Flashcard> get dueFlashcards => _flashcards
      .where((card) => card.isDueForReview)
      .toList()
    ..sort((a, b) => a.nextReview.compareTo(b.nextReview));

  List<Flashcard> get learningFlashcards => _flashcards
      .where((card) => card.isLearning)
      .toList();

  List<Flashcard> get reviewFlashcards => _flashcards
      .where((card) => !card.isLearning)
      .toList();

  int get dueCount => dueFlashcards.length;
  int get newCount => learningFlashcards.where((card) => card.repetitions == 0).length;

  Future<void> loadFlashcards() async {
    if (_isLoaded) return;

    try {
      _storage = StorageFactory.createStorage();
      await _storage.initialize();
      
      final flashcards = await _storage.getFlashcards();
      _flashcards.clear();
      _flashcards.addAll(flashcards);
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading flashcards: $e');
    }
  }

  Future<bool> addFlashcard(WordEntry wordEntry) async {
    try {
      if (!_isLoaded) await loadFlashcards();
      
      // Check if flashcard already exists
      if (_flashcards.any((card) => card.wordSlug == wordEntry.slug)) {
        return false; // Already exists
      }

      final id = _generateId();
      final flashcard = Flashcard.fromWordEntry(id, wordEntry);
      
      final success = await _storage.addFlashcard(flashcard);
      if (success) {
        _flashcards.add(flashcard);
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('Error adding flashcard: $e');
      return false;
    }
  }

  Future<bool> removeFlashcard(String flashcardId) async {
    try {
      if (!_isLoaded) await loadFlashcards();
      
      final success = await _storage.removeFlashcard(flashcardId);
      if (success) {
        _flashcards.removeWhere((card) => card.id == flashcardId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('Error removing flashcard: $e');
      return false;
    }
  }

  Future<bool> reviewFlashcard(String flashcardId, ReviewDifficulty difficulty) async {
    try {
      if (!_isLoaded) await loadFlashcards();
      
      final cardIndex = _flashcards.indexWhere((card) => card.id == flashcardId);
      if (cardIndex == -1) return false;

      final oldCard = _flashcards[cardIndex];
      final updatedCard = _calculateNextReview(oldCard, difficulty);
      
      final success = await _storage.updateFlashcard(updatedCard);
      if (success) {
        _flashcards[cardIndex] = updatedCard;
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('Error reviewing flashcard: $e');
      return false;
    }
  }

  bool hasFlashcard(String wordSlug) {
    return _flashcards.any((card) => card.wordSlug == wordSlug);
  }

  Flashcard? getFlashcard(String wordSlug) {
    try {
      return _flashcards.firstWhere((card) => card.wordSlug == wordSlug);
    } catch (e) {
      return null;
    }
  }

  // Spaced Repetition Algorithm (SM-2 based)
  Flashcard _calculateNextReview(Flashcard card, ReviewDifficulty difficulty) {
    final now = DateTime.now();
    int newInterval = card.intervalDays;
    int newEaseFactor = card.easeFactor;
    int newRepetitions = card.repetitions;
    bool newIsLearning = card.isLearning;

    switch (difficulty) {
      case ReviewDifficulty.again:
        // Reset to learning phase
        newInterval = 1;
        newRepetitions = 0;
        newIsLearning = true;
        newEaseFactor = max(130, newEaseFactor - 20);
        break;

      case ReviewDifficulty.hard:
        if (card.isLearning) {
          newInterval = max(1, (card.intervalDays * 1.2).round());
        } else {
          newInterval = max(1, (card.intervalDays * 1.2).round());
          newEaseFactor = max(130, newEaseFactor - 15);
        }
        newRepetitions++;
        break;

      case ReviewDifficulty.good:
        if (card.isLearning) {
          if (card.repetitions >= 1) {
            newInterval = 6; // Graduate to review
            newIsLearning = false;
          } else {
            newInterval = 10; // 10 minutes for learning
          }
        } else {
          if (card.repetitions == 0) {
            newInterval = 1;
          } else if (card.repetitions == 1) {
            newInterval = 6;
          } else {
            newInterval = (card.intervalDays * card.easeFactorAsDouble).round();
          }
        }
        newRepetitions++;
        break;

      case ReviewDifficulty.easy:
        if (card.isLearning) {
          newInterval = 4; // 4 days
          newIsLearning = false;
        } else {
          newInterval = (card.intervalDays * card.easeFactorAsDouble * 1.3).round();
          newEaseFactor = min(300, newEaseFactor + 15);
        }
        newRepetitions++;
        break;
    }

    // Calculate next review date
    DateTime nextReviewDate;
    if (newInterval < 1) {
      // Minutes for learning cards
      nextReviewDate = now.add(Duration(minutes: (newInterval * 1440).round()));
    } else {
      nextReviewDate = now.add(Duration(days: newInterval));
    }

    return card.copyWith(
      lastReviewed: now,
      nextReview: nextReviewDate,
      intervalDays: newInterval,
      easeFactor: newEaseFactor,
      repetitions: newRepetitions,
      isLearning: newIsLearning,
    );
  }

  String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  Future<void> refreshFlashcards() async {
    _isLoaded = false;
    await loadFlashcards();
  }
}