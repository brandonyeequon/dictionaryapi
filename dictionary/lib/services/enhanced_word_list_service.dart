import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/word_entry.dart';
import '../models/word_list.dart';
import '../models/enhanced_flashcard.dart';
import '../models/study_session.dart';
import 'enhanced_storage_interface.dart';
import 'storage/firebase_storage_factory.dart';
import 'enhanced_flashcard_service.dart';

/// Enhanced word list service that integrates with the flashcard system
class EnhancedWordListService extends ChangeNotifier {
  static final EnhancedWordListService _instance = EnhancedWordListService._internal();
  factory EnhancedWordListService() => _instance;
  EnhancedWordListService._internal();

  late final EnhancedStorageInterface _storage;
  bool _isInitialized = false;

  // In-memory caches
  final List<WordList> _wordLists = [];
  final Map<int, List<WordEntry>> _listWordsCache = {};

  // Getters
  bool get isInitialized => _isInitialized;
  List<WordList> get wordLists => List.unmodifiable(_wordLists);
  bool get hasLists => _wordLists.isNotEmpty;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _storage = FirebaseStorageFactory.createStorage();
      await _storage.initialize();
      _isInitialized = true;
      
      // Load initial data
      await loadWordLists();
      
      debugPrint('[EnhancedWordListService] Initialized successfully');
    } catch (e) {
      debugPrint('[EnhancedWordListService] Initialization failed: $e');
      rethrow;
    }
  }

  /// Ensure the service is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Load all word lists
  Future<void> loadWordLists() async {
    await _ensureInitialized();
    
    try {
      final lists = await _storage.getAllWordLists();
      _wordLists.clear();
      _wordLists.addAll(lists);
      notifyListeners();
      
      debugPrint('[EnhancedWordListService] Loaded ${lists.length} word lists');
    } catch (e) {
      debugPrint('[EnhancedWordListService] Load word lists failed: $e');
    }
  }

  /// Create a new word list
  Future<WordList?> createWordList(String name, {String? description}) async {
    await _ensureInitialized();
    
    try {
      final listId = await _storage.createWordList(name, description: description);
      if (listId > 0) {
        final newList = WordList(
          id: listId,
          name: name,
          description: description,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        _wordLists.add(newList);
        notifyListeners();
        
        debugPrint('[EnhancedWordListService] Created word list: $name');
        return newList;
      }
      return null;
    } catch (e) {
      debugPrint('[EnhancedWordListService] Create word list failed: $e');
      return null;
    }
  }

  /// Update a word list
  Future<bool> updateWordList(WordList wordList) async {
    await _ensureInitialized();
    
    try {
      final success = await _storage.updateWordList(wordList);
      if (success) {
        final index = _wordLists.indexWhere((list) => list.id == wordList.id);
        if (index >= 0) {
          _wordLists[index] = wordList;
          notifyListeners();
        }
      }
      return success;
    } catch (e) {
      debugPrint('[EnhancedWordListService] Update word list failed: $e');
      return false;
    }
  }

  /// Delete a word list
  Future<bool> deleteWordList(int listId) async {
    await _ensureInitialized();
    
    try {
      final success = await _storage.deleteWordList(listId);
      if (success) {
        _wordLists.removeWhere((list) => list.id == listId);
        _listWordsCache.remove(listId);
        notifyListeners();
        
        debugPrint('[EnhancedWordListService] Deleted word list: $listId');
      }
      return success;
    } catch (e) {
      debugPrint('[EnhancedWordListService] Delete word list failed: $e');
      return false;
    }
  }

  /// Get a specific word list
  WordList? getWordList(int listId) {
    return _wordLists.where((list) => list.id == listId).firstOrNull;
  }

  /// Add a word to a list and automatically create flashcard
  Future<bool> addWordToList(int listId, WordEntry wordEntry) async {
    await _ensureInitialized();
    
    try {
      final success = await _storage.addWordToList(listId, wordEntry);
      if (success) {
        // Update cache
        _listWordsCache[listId]?.add(wordEntry);
        
        // Automatically create flashcard for this word
        await _createFlashcardForWord(wordEntry, [listId]);
        
        notifyListeners();
        
        // Force refresh flashcard service to ensure UI updates immediately
        final flashcardService = EnhancedFlashcardService();
        await flashcardService.forceRefresh();
        
        debugPrint('[EnhancedWordListService] Added word to list $listId: ${wordEntry.slug}');
      }
      return success;
    } catch (e) {
      debugPrint('[EnhancedWordListService] Add word to list failed: $e');
      return false;
    }
  }

  /// Remove a word from a list and update flashcard associations
  Future<bool> removeWordFromList(int listId, String wordSlug) async {
    await _ensureInitialized();
    
    try {
      final success = await _storage.removeWordFromList(listId, wordSlug);
      if (success) {
        // Update cache
        _listWordsCache[listId]?.removeWhere((word) => word.slug == wordSlug);
        
        // Update flashcard associations
        await _updateFlashcardAfterWordRemoval(wordSlug, listId);
        
        notifyListeners();
        
        debugPrint('[EnhancedWordListService] Removed word from list $listId: $wordSlug');
      }
      return success;
    } catch (e) {
      debugPrint('[EnhancedWordListService] Remove word from list failed: $e');
      return false;
    }
  }

  /// Get words in a specific list
  Future<List<WordEntry>> getWordsInList(int listId) async {
    await _ensureInitialized();
    
    // Check cache first
    if (_listWordsCache.containsKey(listId)) {
      return List.from(_listWordsCache[listId]!);
    }
    
    try {
      final words = await _storage.getWordsInList(listId);
      _listWordsCache[listId] = words;
      return words;
    } catch (e) {
      debugPrint('[EnhancedWordListService] Get words in list failed: $e');
      return [];
    }
  }

  /// Get all words from multiple lists
  Future<List<WordEntry>> getAllWordsInLists(List<int> listIds) async {
    await _ensureInitialized();
    return await _storage.getAllWordsInLists(listIds);
  }

  /// Get lists containing a specific word
  Future<List<int>> getListsContainingWord(String wordSlug) async {
    await _ensureInitialized();
    return await _storage.getListsContainingWord(wordSlug);
  }

  /// Create flashcard from word and add to lists
  Future<bool> createFlashcardFromWord(String wordSlug, List<int> listIds, WordEntry wordEntry) async {
    await _ensureInitialized();
    
    try {
      // Use the flashcard service to create the flashcard
      final flashcardService = EnhancedFlashcardService();
      await flashcardService.initialize();
      
      return await flashcardService.createFlashcardFromWord(wordEntry, listIds);
    } catch (e) {
      debugPrint('[EnhancedWordListService] Create flashcard from word failed: $e');
      return false;
    }
  }

  /// Helper method to create flashcard for a word when added to lists
  Future<void> _createFlashcardForWord(WordEntry wordEntry, List<int> listIds) async {
    try {
      final flashcardService = EnhancedFlashcardService();
      // Don't call initialize again if already initialized
      
      // The EnhancedFlashcardService.createFlashcardFromWord already handles
      // both creating new flashcards and updating existing ones with new list IDs
      final success = await flashcardService.createFlashcardFromWord(wordEntry, listIds);
      
      if (success) {
        debugPrint('[EnhancedWordListService] Successfully ensured flashcard exists for ${wordEntry.slug} in lists: $listIds');
      } else {
        debugPrint('[EnhancedWordListService] Failed to ensure flashcard for ${wordEntry.slug}');
      }
    } catch (e) {
      debugPrint('[EnhancedWordListService] Error creating flashcard for word: $e');
    }
  }

  /// Helper method to update flashcard associations when word is removed from a list
  Future<void> _updateFlashcardAfterWordRemoval(String wordSlug, int removedListId) async {
    try {
      final flashcardService = EnhancedFlashcardService();
      await flashcardService.initialize();
      
      // Get the existing flashcard
      final existingCard = await flashcardService.getFlashcardByWordSlug(wordSlug);
      if (existingCard != null) {
        // Remove the list ID from the flashcard's word list associations
        final updatedListIds = existingCard.wordListIds.where((id) => id != removedListId).toList();
        
        if (updatedListIds.isEmpty) {
          // If no lists remain, optionally delete the flashcard
          // For now, we'll keep it but it won't be associated with any lists
          debugPrint('[EnhancedWordListService] Flashcard ${existingCard.id} for $wordSlug is no longer associated with any lists');
        } else if (updatedListIds.length != existingCard.wordListIds.length) {
          // Update the flashcard with the new list associations through the storage
          final updatedCard = existingCard.copyWith(wordListIds: updatedListIds);
          await _storage.updateFlashcard(updatedCard);
          debugPrint('[EnhancedWordListService] Updated flashcard ${existingCard.id} - removed list $removedListId');
        }
      }
    } catch (e) {
      debugPrint('[EnhancedWordListService] Error updating flashcard after word removal: $e');
    }
  }

  /// Get flashcards for a specific list
  Future<List<EnhancedFlashcard>> getFlashcardsInList(int listId) async {
    await _ensureInitialized();
    return await _storage.getFlashcardsInList(listId);
  }

  /// Get flashcards for multiple lists
  Future<List<EnhancedFlashcard>> getFlashcardsInLists(List<int> listIds) async {
    await _ensureInitialized();
    return await _storage.getFlashcardsInLists(listIds);
  }

  /// Get word list statistics
  Future<Map<String, dynamic>> getWordListStats(int listId) async {
    await _ensureInitialized();
    
    try {
      final words = await getWordsInList(listId);
      final flashcards = await getFlashcardsInList(listId);
      
      // Calculate flashcard coverage
      final wordsWithFlashcards = flashcards.map((f) => f.wordSlug).toSet();
      final coverage = words.isEmpty ? 0.0 : 
          (wordsWithFlashcards.length / words.length) * 100;
      
      // Calculate mastery distribution
      final masteryStats = <String, int>{};
      for (final card in flashcards) {
        final level = card.masteryLevel.displayName;
        masteryStats[level] = (masteryStats[level] ?? 0) + 1;
      }
      
      // Calculate average accuracy
      final totalAccuracy = flashcards.isNotEmpty 
          ? flashcards.map((c) => c.accuracy).reduce((a, b) => a + b) / flashcards.length
          : 0.0;
      
      return {
        'listId': listId,
        'totalWords': words.length,
        'totalFlashcards': flashcards.length,
        'flashcardCoverage': coverage,
        'averageAccuracy': totalAccuracy,
        'masteryDistribution': masteryStats,
        'wordsWithoutFlashcards': words.length - flashcards.length,
      };
    } catch (e) {
      debugPrint('[EnhancedWordListService] Get word list stats failed: $e');
      return {
        'listId': listId,
        'totalWords': 0,
        'totalFlashcards': 0,
        'flashcardCoverage': 0.0,
        'averageAccuracy': 0.0,
        'masteryDistribution': <String, int>{},
        'wordsWithoutFlashcards': 0,
      };
    }
  }

  /// Get all word list statistics
  Future<Map<String, dynamic>> getAllWordListStats() async {
    await _ensureInitialized();
    
    try {
      final allStats = <Map<String, dynamic>>[];
      int totalWords = 0;
      int totalFlashcards = 0;
      double totalAccuracy = 0.0;
      
      for (final list in _wordLists) {
        final stats = await getWordListStats(list.id);
        allStats.add({
          'list': list,
          'stats': stats,
        });
        
        totalWords += stats['totalWords'] as int;
        totalFlashcards += stats['totalFlashcards'] as int;
        totalAccuracy += stats['averageAccuracy'] as double;
      }
      
      final overallAccuracy = _wordLists.isNotEmpty ? totalAccuracy / _wordLists.length : 0.0;
      
      return {
        'totalLists': _wordLists.length,
        'totalWords': totalWords,
        'totalFlashcards': totalFlashcards,
        'overallAccuracy': overallAccuracy,
        'listStats': allStats,
      };
    } catch (e) {
      debugPrint('[EnhancedWordListService] Get all word list stats failed: $e');
      return {
        'totalLists': 0,
        'totalWords': 0,
        'totalFlashcards': 0,
        'overallAccuracy': 0.0,
        'listStats': <Map<String, dynamic>>[],
      };
    }
  }

  /// Start a study session for specific lists
  Future<bool> startListStudySession(List<int> listIds, {int? cardLimit}) async {
    await _ensureInitialized();
    
    try {
      final flashcardService = EnhancedFlashcardService();
      await flashcardService.initialize();
      
      return await flashcardService.startStudySession(
        sessionType: StudySessionType.targeted,
        targetListIds: listIds,
        cardLimit: cardLimit,
      );
    } catch (e) {
      debugPrint('[EnhancedWordListService] Start list study session failed: $e');
      return false;
    }
  }

  /// Clear words cache for a specific list
  void clearWordsCache(int listId) {
    _listWordsCache.remove(listId);
  }

  /// Clear all caches
  void clearAllCaches() {
    _listWordsCache.clear();
  }

  @override
  void dispose() {
    _storage.close();
    super.dispose();
  }
}