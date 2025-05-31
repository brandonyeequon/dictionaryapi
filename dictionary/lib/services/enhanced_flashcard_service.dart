import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/enhanced_flashcard.dart';
import '../models/jotoba_word_entry.dart'; // Changed from word_entry.dart
import '../models/word_mastery.dart';
import '../models/study_session.dart';
import '../models/user_progress.dart';
import 'storage/enhanced_storage_interface.dart';
import 'storage/enhanced_storage_factory.dart';

/// Enhanced flashcard service with list integration, SRS, and progress tracking
class EnhancedFlashcardService extends ChangeNotifier {
  static final EnhancedFlashcardService _instance = EnhancedFlashcardService._internal();
  factory EnhancedFlashcardService() => _instance;
  EnhancedFlashcardService._internal();

  late final EnhancedStorageInterface _storage;
  bool _isInitialized = false;

  // In-memory caches for performance
  final Map<String, EnhancedFlashcard> _flashcardCache = {};
  final List<EnhancedFlashcard> _dueCardsCache = [];
  DateTime? _lastCacheUpdate;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  // Current study session
  StudySession? _currentSession;
  final List<EnhancedFlashcard> _sessionQueue = [];
  int _sessionCardIndex = 0;

  // Getters
  bool get isInitialized => _isInitialized;
  StudySession? get currentSession => _currentSession;
  List<EnhancedFlashcard> get sessionQueue => List.unmodifiable(_sessionQueue);
  int get sessionCardIndex => _sessionCardIndex;
  bool get hasCurrentSession => _currentSession != null;
  EnhancedFlashcard? get currentCard => 
      _sessionQueue.isNotEmpty && _sessionCardIndex < _sessionQueue.length 
          ? _sessionQueue[_sessionCardIndex] 
          : null;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _storage = EnhancedStorageFactory.createStorage();
      await _storage.initialize();
      _isInitialized = true;
      
      // Initial cache load
      await _refreshCaches();
      
      debugPrint('[EnhancedFlashcardService] Initialized successfully');
    } catch (e) {
      debugPrint('[EnhancedFlashcardService] Initialization failed: $e');
      rethrow;
    }
  }

  /// Ensure the service is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Refresh all caches
  Future<void> _refreshCaches() async {
    try {
      // Load all flashcards into cache
      final allCards = await _storage.getAllFlashcards();
      _flashcardCache.clear();
      for (final card in allCards) {
        _flashcardCache[card.id] = card;
      }

      // Load due cards
      _dueCardsCache.clear();
      _dueCardsCache.addAll(await _storage.getDueFlashcards());
      
      _lastCacheUpdate = DateTime.now();
      debugPrint('[EnhancedFlashcardService] Cache refreshed: ${_flashcardCache.length} cards, ${_dueCardsCache.length} due');
    } catch (e) {
      debugPrint('[EnhancedFlashcardService] Cache refresh failed: $e');
    }
  }

  /// Check if cache needs refresh
  bool _shouldRefreshCache() {
    if (_lastCacheUpdate == null) return true;
    return DateTime.now().difference(_lastCacheUpdate!) > _cacheValidDuration;
  }

  /// Create a flashcard from a word entry in specific lists
  Future<bool> createFlashcardFromWord(
    JotobaWordEntry wordEntry, // Changed parameter type
    List<int> wordListIds,
  ) async {
    await _ensureInitialized();
    
    try {
      // Check if flashcard already exists
      if (await _storage.hasFlashcard(wordEntry.slug ?? '')) { // Added null check for slug
        // Add to additional lists if not already present
        final existingCard = await _storage.getFlashcardByWordSlug(wordEntry.slug ?? ''); // Added null check
        if (existingCard != null) {
          final newListIds = <int>{...existingCard.wordListIds, ...wordListIds}.toList();
          if (newListIds.length > existingCard.wordListIds.length) {
            final updatedCard = existingCard.copyWith(wordListIds: newListIds);
            await _storage.updateFlashcard(updatedCard);
            _flashcardCache[updatedCard.id] = updatedCard;
            notifyListeners();
            return true;
          }
        }
        return false; // Already exists with same lists
      }

      // Create new flashcard
      final cardId = '${wordEntry.slug ?? wordEntry.primaryWord}_${DateTime.now().millisecondsSinceEpoch}'; // Updated cardId generation
      final flashcard = EnhancedFlashcard.fromWordEntry(cardId, wordEntry, wordListIds);
      
      final success = await _storage.saveFlashcard(flashcard);
      if (success) {
        _flashcardCache[flashcard.id] = flashcard;
        await _refreshCaches(); // Refresh to update due cards
        notifyListeners();
        
        debugPrint('[EnhancedFlashcardService] Created flashcard for ${wordEntry.slug ?? wordEntry.primaryWord} - notifying listeners');
      }
      
      return success;
    } catch (e) {
      debugPrint('[EnhancedFlashcardService] Create flashcard failed: $e');
      return false;
    }
  }

  /// Get all flashcards
  Future<List<EnhancedFlashcard>> getAllFlashcards() async {
    await _ensureInitialized();
    
    if (_shouldRefreshCache()) {
      await _refreshCaches();
    }
    
    return _flashcardCache.values.toList();
  }

  /// Get due flashcards
  Future<List<EnhancedFlashcard>> getDueFlashcards() async {
    await _ensureInitialized();
    
    if (_shouldRefreshCache()) {
      await _refreshCaches();
    }
    
    return List.from(_dueCardsCache);
  }

  /// Get flashcards in specific lists
  Future<List<EnhancedFlashcard>> getFlashcardsInLists(List<int> listIds) async {
    await _ensureInitialized();
    return await _storage.getFlashcardsInLists(listIds);
  }

  /// Get new flashcards (never studied)
  Future<List<EnhancedFlashcard>> getNewFlashcards() async {
    await _ensureInitialized();
    return await _storage.getNewFlashcards();
  }

  /// Get flashcards by mastery level
  Future<List<EnhancedFlashcard>> getFlashcardsByMastery(MasteryLevel level) async {
    await _ensureInitialized();
    return await _storage.getFlashcardsByMastery(level);
  }

  /// Get flashcard statistics
  Future<Map<String, dynamic>> getFlashcardStats() async {
    await _ensureInitialized();
    
    final allCards = await getAllFlashcards();
    final dueCards = await getDueFlashcards();
    final newCards = await getNewFlashcards();
    
    final statsByMastery = <MasteryLevel, int>{};
    for (final level in MasteryLevel.values) {
      statsByMastery[level] = allCards.where((c) => c.masteryLevel == level).length;
    }
    
    final totalAccuracy = allCards.isNotEmpty 
        ? allCards.map((c) => c.accuracy).reduce((a, b) => a + b) / allCards.length
        : 0.0;
    
    final stats = {
      'totalCards': allCards.length,
      'dueCards': dueCards.length,
      'newCards': newCards.length,
      'masteredCards': statsByMastery[MasteryLevel.mastered] ?? 0,
      'burnedCards': statsByMastery[MasteryLevel.burned] ?? 0,
      'averageAccuracy': totalAccuracy,
      'statsByMastery': statsByMastery.map((k, v) => MapEntry(k.displayName, v)),
    };
    
    debugPrint('[EnhancedFlashcardService] Stats calculated: ${stats['newCards']} new cards, ${stats['dueCards']} due cards, ${stats['totalCards']} total');
    return stats;
  }

  /// Start a study session
  Future<bool> startStudySession({
    StudySessionType sessionType = StudySessionType.due,
    List<int>? targetListIds,
    int? cardLimit,
  }) async {
    await _ensureInitialized();
    
    try {
      // End current session if exists
      if (_currentSession != null) {
        await endStudySession();
      }

      // Get cards based on session type
      List<EnhancedFlashcard> cards;
      switch (sessionType) {
        case StudySessionType.due:
          cards = await getDueFlashcards();
          break;
        case StudySessionType.newCards:
          cards = await getNewFlashcards();
          break;
        case StudySessionType.targeted:
          if (targetListIds != null && targetListIds.isNotEmpty) {
            cards = await getFlashcardsInLists(targetListIds);
          } else {
            cards = await getAllFlashcards();
          }
          break;
        case StudySessionType.difficult:
          cards = await getAllFlashcards();
          cards = cards.where((c) => c.accuracy < 70).toList(); // Cards with <70% accuracy
          break;
        case StudySessionType.cram:
          if (targetListIds != null && targetListIds.isNotEmpty) {
            cards = await getFlashcardsInLists(targetListIds);
          } else {
            cards = await getAllFlashcards();
          }
          break;
        case StudySessionType.mixed:
          final due = await getDueFlashcards();
          final newCards = await getNewFlashcards();
          cards = [...due, ...newCards.take(10)]; // Mix due + some new cards
          break;
      }

      // Shuffle cards for variety
      cards.shuffle();
      
      // Apply card limit
      if (cardLimit != null && cardLimit > 0) {
        cards = cards.take(cardLimit).toList();
      }

      if (cards.isEmpty) {
        debugPrint('[EnhancedFlashcardService] No cards available for study session');
        return false;
      }

      // Create study session
      final sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
      _currentSession = StudySession(
        id: sessionId,
        startTime: DateTime.now(),
        sessionType: sessionType,
        targetWordListIds: targetListIds,
      );

      // Set up session queue
      _sessionQueue.clear();
      _sessionQueue.addAll(cards);
      _sessionCardIndex = 0;

      notifyListeners();
      debugPrint('[EnhancedFlashcardService] Started study session: ${cards.length} cards');
      return true;
    } catch (e) {
      debugPrint('[EnhancedFlashcardService] Start study session failed: $e');
      return false;
    }
  }

  /// Review the current card with difficulty rating
  Future<bool> reviewCurrentCard(ReviewDifficulty difficulty) async {
    await _ensureInitialized();
    
    if (_currentSession == null || currentCard == null) {
      return false;
    }

    try {
      final card = currentCard!;
      final previousLevel = card.masteryLevel;
      
      // Record start time for response calculation
      final responseTime = 5.0; // TODO: Track actual response time from UI
      
      // Update card with review
      final updatedCard = card.reviewCard(difficulty);
      
      // Save updated card
      await _storage.updateFlashcard(updatedCard);
      _flashcardCache[updatedCard.id] = updatedCard;
      
      // Create card review record
      final cardReview = CardReview(
        cardId: card.id,
        wordSlug: card.wordSlug,
        difficulty: difficulty,
        responseTimeSeconds: responseTime,
        timestamp: DateTime.now(),
        previousLevel: previousLevel,
        newLevel: updatedCard.masteryLevel,
      );
      
      // Add to current session
      _currentSession = _currentSession!.addCardReview(cardReview);
      
      // Move to next card
      _sessionCardIndex++;
      
      notifyListeners();
      
      // Check if session is complete
      if (_sessionCardIndex >= _sessionQueue.length) {
        await endStudySession();
      }
      
      return true;
    } catch (e) {
      debugPrint('[EnhancedFlashcardService] Review card failed: $e');
      return false;
    }
  }

  /// End the current study session
  Future<bool> endStudySession() async {
    if (_currentSession == null) return false;
    
    try {
      // Complete the session
      final completedSession = _currentSession!.complete();
      
      // Save session to storage
      await _storage.saveStudySession(completedSession);
      
      // Update user progress
      await _updateUserProgressFromSession(completedSession);
      
      // Clear session state
      _currentSession = null;
      _sessionQueue.clear();
      _sessionCardIndex = 0;
      
      // Refresh caches to reflect changes
      await _refreshCaches();
      
      notifyListeners();
      
      debugPrint('[EnhancedFlashcardService] Ended study session: ${completedSession.totalCards} cards reviewed');
      return true;
    } catch (e) {
      debugPrint('[EnhancedFlashcardService] End study session failed: $e');
      return false;
    }
  }

  /// Update user progress based on completed study session
  Future<void> _updateUserProgressFromSession(StudySession session) async {
    try {
      var progress = await _storage.getUserProgress() ?? UserProgress(
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Update basic stats
      final totalReviews = progress.totalReviews + session.totalCards;
      final newCorrectReviews = progress.totalReviews * (progress.averageAccuracy / 100) + session.correctAnswers;
      final newAverageAccuracy = totalReviews > 0 ? (newCorrectReviews / totalReviews) * 100 : 0.0;
      
      // Update streak
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      var currentStreak = progress.currentStreak;
      var longestStreak = progress.longestStreak;
      
      if (progress.lastStudySession == null || 
          !DateTime(progress.lastStudySession!.year, progress.lastStudySession!.month, progress.lastStudySession!.day)
              .isAtSameMomentAs(today)) {
        // First study of the day
        if (progress.lastStudySession != null) {
          final lastStudyDay = DateTime(
            progress.lastStudySession!.year,
            progress.lastStudySession!.month,
            progress.lastStudySession!.day,
          );
          final yesterday = today.subtract(const Duration(days: 1));
          
          if (lastStudyDay.isAtSameMomentAs(yesterday)) {
            // Consecutive day
            currentStreak++;
          } else {
            // Streak broken
            currentStreak = 1;
          }
        } else {
          // First ever study
          currentStreak = 1;
        }
        
        if (currentStreak > longestStreak) {
          longestStreak = currentStreak;
        }
      }
      
      // Update word count by mastery level
      final allCards = await getAllFlashcards();
      final wordCountByLevel = <MasteryLevel, int>{};
      for (final level in MasteryLevel.values) {
        wordCountByLevel[level] = allCards.where((c) => c.masteryLevel == level).length;
      }
      
      // Calculate study time (session duration in minutes)
      final studyTimeMinutes = progress.studyTimeMinutes + session.duration.inMinutes;
      
      // Create updated progress
      final updatedProgress = progress.copyWith(
        totalWordsStudied: allCards.length,
        lastStudySession: session.endTime,
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        wordCountByLevel: wordCountByLevel,
        totalReviews: totalReviews,
        averageAccuracy: newAverageAccuracy,
        studyTimeMinutes: studyTimeMinutes,
        updatedAt: DateTime.now(),
      );
      
      await _storage.saveUserProgress(updatedProgress);
    } catch (e) {
      debugPrint('[EnhancedFlashcardService] Update user progress failed: $e');
    }
  }

  /// Get user progress
  Future<UserProgress?> getUserProgress() async {
    await _ensureInitialized();
    return await _storage.getUserProgress();
  }

  /// Get study session statistics
  Future<StudySessionStats> getStudySessionStats() async {
    await _ensureInitialized();
    return await _storage.getStudySessionStats();
  }

  /// Get recent study sessions
  Future<List<StudySession>> getRecentStudySessions({int limit = 10}) async {
    await _ensureInitialized();
    return await _storage.getStudySessions(limit: limit);
  }

  /// Delete a flashcard
  Future<bool> deleteFlashcard(String flashcardId) async {
    await _ensureInitialized();
    
    try {
      final success = await _storage.removeFlashcard(flashcardId);
      if (success) {
        _flashcardCache.remove(flashcardId);
        await _refreshCaches();
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('[EnhancedFlashcardService] Delete flashcard failed: $e');
      return false;
    }
  }

  /// Check if a word has a flashcard
  Future<bool> hasFlashcard(String wordSlug) async {
    await _ensureInitialized();
    return await _storage.hasFlashcard(wordSlug);
  }

  /// Get flashcard by word slug
  Future<EnhancedFlashcard?> getFlashcardByWordSlug(String wordSlug) async {
    await _ensureInitialized();
    return await _storage.getFlashcardByWordSlug(wordSlug);
  }

  /// Force refresh all caches and notify listeners (useful after external changes)
  Future<void> forceRefresh() async {
    await _refreshCaches();
    notifyListeners();
    debugPrint('[EnhancedFlashcardService] Force refresh completed');
  }

  @override
  void dispose() {
    _storage.close();
    super.dispose();
  }
}