import 'dart:convert';
import 'package:idb_shim/idb_browser.dart';
import '../../models/word_entry.dart';
import '../../models/enhanced_flashcard.dart';
import '../../models/user_progress.dart';
import '../../models/study_session.dart';
import '../../models/word_list.dart';
import '../../models/word_mastery.dart';
import 'enhanced_storage_interface.dart';

/// Enhanced IndexedDB implementation for web platform
class EnhancedWebStorage implements EnhancedStorageInterface {
  Database? _database;
  static const String _dbName = 'enhanced_jisho_dictionary';
  static const int _dbVersion = 1;

  static const String _favoritesStore = 'favorites';
  static const String _wordListsStore = 'word_lists';
  static const String _wordListEntriesStore = 'word_list_entries';
  static const String _enhancedFlashcardsStore = 'enhanced_flashcards';
  static const String _userProgressStore = 'user_progress';
  static const String _studySessionsStore = 'study_sessions';

  @override
  Future<void> initialize() async {
    if (_database != null) return;

    final idbFactory = getIdbFactory()!;
    _database = await idbFactory.open(_dbName, version: _dbVersion,
        onUpgradeNeeded: (VersionChangeEvent event) {
      final db = event.database;
      
      // Create favorites store
      if (!db.objectStoreNames.contains(_favoritesStore)) {
        final favoritesStore = db.createObjectStore(_favoritesStore, keyPath: 'slug');
        favoritesStore.createIndex('created_at', 'created_at');
      }

      // Create word lists store
      if (!db.objectStoreNames.contains(_wordListsStore)) {
        final wordListsStore = db.createObjectStore(_wordListsStore, keyPath: 'id', autoIncrement: true);
        wordListsStore.createIndex('created_at', 'created_at');
        wordListsStore.createIndex('updated_at', 'updated_at');
      }

      // Create word list entries store
      if (!db.objectStoreNames.contains(_wordListEntriesStore)) {
        final wordListEntriesStore = db.createObjectStore(_wordListEntriesStore, keyPath: 'id', autoIncrement: true);
        wordListEntriesStore.createIndex('list_id', 'list_id');
        wordListEntriesStore.createIndex('word_slug', 'word_slug');
        wordListEntriesStore.createIndex('added_at', 'added_at');
      }

      // Create enhanced flashcards store
      if (!db.objectStoreNames.contains(_enhancedFlashcardsStore)) {
        final flashcardsStore = db.createObjectStore(_enhancedFlashcardsStore, keyPath: 'id');
        flashcardsStore.createIndex('word_slug', 'word_slug', unique: true);
        flashcardsStore.createIndex('next_review', 'next_review');
        flashcardsStore.createIndex('mastery_level', 'mastery_level');
        flashcardsStore.createIndex('created_at', 'created_at');
      }

      // Create user progress store
      if (!db.objectStoreNames.contains(_userProgressStore)) {
        db.createObjectStore(_userProgressStore, keyPath: 'id');
      }

      // Create study sessions store
      if (!db.objectStoreNames.contains(_studySessionsStore)) {
        final studySessionsStore = db.createObjectStore(_studySessionsStore, keyPath: 'id');
        studySessionsStore.createIndex('start_time', 'start_time');
      }
    });

    // Initialize default user progress
    await _initializeUserProgress();
  }

  Future<void> _initializeUserProgress() async {
    try {
      final existing = await getUserProgress();
      if (existing == null) {
        final now = DateTime.now();
        final defaultProgress = UserProgress(
          createdAt: now,
          updatedAt: now,
        );
        await saveUserProgress(defaultProgress);
      }
    } catch (e) {
      // Ignore errors during initialization
    }
  }

  @override
  Future<void> close() async {
    _database?.close();
    _database = null;
  }

  Database get _db {
    if (_database == null) {
      throw StateError('Database not initialized. Call initialize() first.');
    }
    return _database!;
  }

  // Favorites operations
  @override
  Future<bool> addToFavorites(WordEntry wordEntry) async {
    try {
      final txn = _db.transaction([_favoritesStore], idbModeReadWrite);
      final store = txn.objectStore(_favoritesStore);
      
      await store.put({
        'slug': wordEntry.slug,
        'word_data': jsonEncode(wordEntry.toJson()),
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
      
      await txn.completed;
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> removeFromFavorites(String slug) async {
    try {
      final txn = _db.transaction([_favoritesStore], idbModeReadWrite);
      final store = txn.objectStore(_favoritesStore);
      
      await store.delete(slug);
      await txn.completed;
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> isFavorite(String slug) async {
    try {
      final txn = _db.transaction([_favoritesStore], idbModeReadOnly);
      final store = txn.objectStore(_favoritesStore);
      
      final result = await store.getObject(slug);
      return result != null;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<WordEntry>> getFavorites() async {
    try {
      final txn = _db.transaction([_favoritesStore], idbModeReadOnly);
      final store = txn.objectStore(_favoritesStore);
      final index = store.index('created_at');
      
      final favorites = <WordEntry>[];
      final cursor = index.openCursor(direction: idbDirectionPrev);
      
      await for (final cursorWithValue in cursor) {
        final data = cursorWithValue.value as Map<String, dynamic>;
        final wordData = jsonDecode(data['word_data'] as String);
        favorites.add(WordEntry.fromJson(wordData));
        cursorWithValue.next();
      }
      
      return favorites;
    } catch (e) {
      return [];
    }
  }

  // Enhanced flashcard operations
  @override
  Future<bool> saveFlashcard(EnhancedFlashcard flashcard) async {
    try {
      final txn = _db.transaction([_enhancedFlashcardsStore], idbModeReadWrite);
      final store = txn.objectStore(_enhancedFlashcardsStore);
      
      await store.put(_flashcardToMap(flashcard));
      await txn.completed;
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> updateFlashcard(EnhancedFlashcard flashcard) async {
    return saveFlashcard(flashcard);
  }

  @override
  Future<bool> removeFlashcard(String flashcardId) async {
    try {
      final txn = _db.transaction([_enhancedFlashcardsStore], idbModeReadWrite);
      final store = txn.objectStore(_enhancedFlashcardsStore);
      
      await store.delete(flashcardId);
      await txn.completed;
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<EnhancedFlashcard>> getAllFlashcards() async {
    try {
      final txn = _db.transaction([_enhancedFlashcardsStore], idbModeReadOnly);
      final store = txn.objectStore(_enhancedFlashcardsStore);
      
      final flashcards = <EnhancedFlashcard>[];
      final cursor = store.openCursor();
      
      await for (final cursorWithValue in cursor) {
        final data = cursorWithValue.value as Map<String, dynamic>;
        flashcards.add(_mapToFlashcard(data));
        cursorWithValue.next();
      }
      
      return flashcards;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<EnhancedFlashcard?> getFlashcard(String flashcardId) async {
    try {
      final txn = _db.transaction([_enhancedFlashcardsStore], idbModeReadOnly);
      final store = txn.objectStore(_enhancedFlashcardsStore);
      
      final result = await store.getObject(flashcardId);
      if (result == null) return null;
      
      return _mapToFlashcard(result as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<EnhancedFlashcard?> getFlashcardByWordSlug(String wordSlug) async {
    try {
      final txn = _db.transaction([_enhancedFlashcardsStore], idbModeReadOnly);
      final store = txn.objectStore(_enhancedFlashcardsStore);
      final index = store.index('word_slug');
      
      final cursor = index.openCursor(key: wordSlug);
      await for (final cursorWithValue in cursor) {
        return _mapToFlashcard(cursorWithValue.value as Map<String, dynamic>);
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> hasFlashcard(String wordSlug) async {
    try {
      final txn = _db.transaction([_enhancedFlashcardsStore], idbModeReadOnly);
      final store = txn.objectStore(_enhancedFlashcardsStore);
      final index = store.index('word_slug');
      
      final result = await index.getKey(wordSlug);
      return result != null;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<EnhancedFlashcard>> getFlashcardsInList(int listId) async {
    // For web, we'll filter in memory since IndexedDB doesn't support complex JSON queries
    final allCards = await getAllFlashcards();
    return allCards.where((card) => card.wordListIds.contains(listId)).toList();
  }

  @override
  Future<List<EnhancedFlashcard>> getFlashcardsInLists(List<int> listIds) async {
    if (listIds.isEmpty) return [];
    
    final allCards = await getAllFlashcards();
    return allCards.where((card) => 
      card.wordListIds.any((id) => listIds.contains(id))
    ).toList();
  }

  @override
  Future<List<EnhancedFlashcard>> getDueFlashcards() async {
    try {
      final txn = _db.transaction([_enhancedFlashcardsStore], idbModeReadOnly);
      final store = txn.objectStore(_enhancedFlashcardsStore);
      
      final now = DateTime.now().millisecondsSinceEpoch;
      final dueCards = <EnhancedFlashcard>[];
      
      final cursor = store.openCursor();
      await for (final cursorWithValue in cursor) {
        final data = cursorWithValue.value as Map<String, dynamic>;
        final card = _mapToFlashcard(data);
        if (card.nextReview.millisecondsSinceEpoch <= now) {
          dueCards.add(card);
        }
        cursorWithValue.next();
      }
      
      return dueCards;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<EnhancedFlashcard>> getDueFlashcardsInList(int listId) async {
    final dueCards = await getDueFlashcards();
    return dueCards.where((card) => card.wordListIds.contains(listId)).toList();
  }

  @override
  Future<List<EnhancedFlashcard>> getNewFlashcards() async {
    try {
      final txn = _db.transaction([_enhancedFlashcardsStore], idbModeReadOnly);
      final store = txn.objectStore(_enhancedFlashcardsStore);
      final index = store.index('mastery_level');
      
      final newCards = <EnhancedFlashcard>[];
      final cursor = index.openCursor(key: MasteryLevel.newWord.level);
      
      await for (final cursorWithValue in cursor) {
        final data = cursorWithValue.value as Map<String, dynamic>;
        final card = _mapToFlashcard(data);
        // Only include cards that have never been reviewed
        if (card.totalReviews == 0) {
          newCards.add(card);
        }
        cursorWithValue.next();
      }
      
      return newCards;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<EnhancedFlashcard>> getFlashcardsByMastery(MasteryLevel level) async {
    try {
      final txn = _db.transaction([_enhancedFlashcardsStore], idbModeReadOnly);
      final store = txn.objectStore(_enhancedFlashcardsStore);
      final index = store.index('mastery_level');
      
      final cards = <EnhancedFlashcard>[];
      final cursor = index.openCursor(key: level.level);
      
      await for (final cursorWithValue in cursor) {
        final data = cursorWithValue.value as Map<String, dynamic>;
        cards.add(_mapToFlashcard(data));
        cursorWithValue.next();
      }
      
      return cards;
    } catch (e) {
      return [];
    }
  }

  // Word list operations
  @override
  Future<int> createWordList(String name, {String? description}) async {
    try {
      final txn = _db.transaction([_wordListsStore], idbModeReadWrite);
      final store = txn.objectStore(_wordListsStore);
      final now = DateTime.now().millisecondsSinceEpoch;
      
      final result = await store.add({
        'name': name,
        'description': description,
        'created_at': now,
        'updated_at': now,
      });
      
      await txn.completed;
      return result as int;
    } catch (e) {
      return -1;
    }
  }

  @override
  Future<bool> updateWordList(WordList wordList) async {
    try {
      final txn = _db.transaction([_wordListsStore], idbModeReadWrite);
      final store = txn.objectStore(_wordListsStore);
      
      await store.put({
        'id': wordList.id,
        'name': wordList.name,
        'description': wordList.description,
        'created_at': wordList.createdAt.millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });
      
      await txn.completed;
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> deleteWordList(int listId) async {
    try {
      final txn = _db.transaction([_wordListsStore, _wordListEntriesStore], idbModeReadWrite);
      final listsStore = txn.objectStore(_wordListsStore);
      final entriesStore = txn.objectStore(_wordListEntriesStore);
      final index = entriesStore.index('list_id');
      
      // Delete all entries in the list
      final cursor = index.openCursor(key: listId);
      await for (final cursorWithValue in cursor) {
        await cursorWithValue.delete();
        cursorWithValue.next();
      }
      
      // Delete the list itself
      await listsStore.delete(listId);
      
      await txn.completed;
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<WordList>> getAllWordLists() async {
    try {
      final txn = _db.transaction([_wordListsStore], idbModeReadOnly);
      final store = txn.objectStore(_wordListsStore);
      final index = store.index('created_at');
      
      final wordLists = <WordList>[];
      final cursor = index.openCursor(direction: idbDirectionPrev);
      
      await for (final cursorWithValue in cursor) {
        final data = cursorWithValue.value as Map<String, dynamic>;
        wordLists.add(WordList.fromJson(data));
        cursorWithValue.next();
      }
      
      return wordLists;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<WordList?> getWordList(int listId) async {
    try {
      final txn = _db.transaction([_wordListsStore], idbModeReadOnly);
      final store = txn.objectStore(_wordListsStore);
      
      final result = await store.getObject(listId);
      if (result == null) return null;
      
      return WordList.fromJson(result as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  // Word list entries
  @override
  Future<bool> addWordToList(int listId, WordEntry wordEntry) async {
    try {
      final txn = _db.transaction([_wordListEntriesStore], idbModeReadWrite);
      final store = txn.objectStore(_wordListEntriesStore);
      
      await store.add({
        'list_id': listId,
        'word_slug': wordEntry.slug,
        'word_data': jsonEncode(wordEntry.toJson()),
        'added_at': DateTime.now().millisecondsSinceEpoch,
        'position': 0,
      });
      
      await txn.completed;
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> removeWordFromList(int listId, String wordSlug) async {
    try {
      final txn = _db.transaction([_wordListEntriesStore], idbModeReadWrite);
      final store = txn.objectStore(_wordListEntriesStore);
      final index = store.index('list_id');
      
      final cursor = index.openCursor(key: listId);
      await for (final cursorWithValue in cursor) {
        final data = cursorWithValue.value as Map<String, dynamic>;
        if (data['word_slug'] == wordSlug) {
          await cursorWithValue.delete();
          break;
        }
        cursorWithValue.next();
      }
      
      await txn.completed;
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<WordEntry>> getWordsInList(int listId) async {
    try {
      final txn = _db.transaction([_wordListEntriesStore], idbModeReadOnly);
      final store = txn.objectStore(_wordListEntriesStore);
      final index = store.index('list_id');
      
      final words = <WordEntry>[];
      final cursor = index.openCursor(key: listId);
      
      await for (final cursorWithValue in cursor) {
        final data = cursorWithValue.value as Map<String, dynamic>;
        final wordData = jsonDecode(data['word_data'] as String);
        words.add(WordEntry.fromJson(wordData));
        cursorWithValue.next();
      }
      
      return words;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<WordEntry>> getAllWordsInLists(List<int> listIds) async {
    if (listIds.isEmpty) return [];
    
    final uniqueWords = <String, WordEntry>{};
    
    for (final listId in listIds) {
      final words = await getWordsInList(listId);
      for (final word in words) {
        uniqueWords[word.slug] = word;
      }
    }
    
    return uniqueWords.values.toList();
  }

  @override
  Future<List<int>> getListsContainingWord(String wordSlug) async {
    try {
      final txn = _db.transaction([_wordListEntriesStore], idbModeReadOnly);
      final store = txn.objectStore(_wordListEntriesStore);
      final index = store.index('word_slug');
      
      final listIds = <int>[];
      final cursor = index.openCursor(key: wordSlug);
      
      await for (final cursorWithValue in cursor) {
        final data = cursorWithValue.value as Map<String, dynamic>;
        listIds.add(data['list_id'] as int);
        cursorWithValue.next();
      }
      
      return listIds;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<bool> createFlashcardFromWord(String wordSlug, List<int> listIds, WordEntry wordEntry) async {
    try {
      final flashcard = EnhancedFlashcard.fromWordEntry(
        DateTime.now().millisecondsSinceEpoch.toString(),
        wordEntry,
        listIds,
      );
      return await saveFlashcard(flashcard);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> addFlashcardToLists(String flashcardId, List<int> listIds) async {
    try {
      final flashcard = await getFlashcard(flashcardId);
      if (flashcard == null) return false;
      
      final updatedListIds = <int>{...flashcard.wordListIds, ...listIds}.toList();
      final updatedFlashcard = flashcard.copyWith(wordListIds: updatedListIds);
      return await updateFlashcard(updatedFlashcard);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> removeFlashcardFromList(String flashcardId, int listId) async {
    try {
      final flashcard = await getFlashcard(flashcardId);
      if (flashcard == null) return false;
      
      final updatedListIds = flashcard.wordListIds.where((id) => id != listId).toList();
      final updatedFlashcard = flashcard.copyWith(wordListIds: updatedListIds);
      return await updateFlashcard(updatedFlashcard);
    } catch (e) {
      return false;
    }
  }

  // User progress operations
  @override
  Future<bool> saveUserProgress(UserProgress progress) async {
    try {
      final txn = _db.transaction([_userProgressStore], idbModeReadWrite);
      final store = txn.objectStore(_userProgressStore);
      
      final data = progress.toJson();
      data['id'] = 1; // Single user progress record
      
      await store.put(data);
      await txn.completed;
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<UserProgress?> getUserProgress() async {
    try {
      final txn = _db.transaction([_userProgressStore], idbModeReadOnly);
      final store = txn.objectStore(_userProgressStore);
      
      final result = await store.getObject(1);
      if (result == null) return null;
      
      return UserProgress.fromJson(result as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> updateUserProgress(UserProgress progress) async {
    return await saveUserProgress(progress);
  }

  // Study session operations
  @override
  Future<bool> saveStudySession(StudySession session) async {
    try {
      final txn = _db.transaction([_studySessionsStore], idbModeReadWrite);
      final store = txn.objectStore(_studySessionsStore);
      
      await store.put({
        'id': session.id,
        'start_time': session.startTime.millisecondsSinceEpoch,
        'end_time': session.endTime?.millisecondsSinceEpoch,
        'card_reviews': jsonEncode(session.cardReviews.map((e) => e.toJson()).toList()),
        'session_type': session.sessionType.value,
        'target_word_list_ids': session.targetWordListIds != null 
            ? jsonEncode(session.targetWordListIds) 
            : null,
      });
      
      await txn.completed;
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> updateStudySession(StudySession session) async {
    return await saveStudySession(session);
  }

  @override
  Future<List<StudySession>> getStudySessions({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      final txn = _db.transaction([_studySessionsStore], idbModeReadOnly);
      final store = txn.objectStore(_studySessionsStore);
      final index = store.index('start_time');
      
      final sessions = <StudySession>[];
      final cursor = index.openCursor(direction: idbDirectionPrev);
      
      await for (final cursorWithValue in cursor) {
        final data = cursorWithValue.value as Map<String, dynamic>;
        final session = _mapToStudySession(data);
        
        // Apply date filters
        if (startDate != null && session.startTime.isBefore(startDate)) {
          cursorWithValue.next();
          continue;
        }
        if (endDate != null && session.startTime.isAfter(endDate)) {
          cursorWithValue.next();
          continue;
        }
        
        sessions.add(session);
        
        // Apply limit
        if (limit != null && sessions.length >= limit) {
          break;
        }
        
        cursorWithValue.next();
      }
      
      return sessions;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<StudySession?> getStudySession(String sessionId) async {
    try {
      final txn = _db.transaction([_studySessionsStore], idbModeReadOnly);
      final store = txn.objectStore(_studySessionsStore);
      
      final result = await store.getObject(sessionId);
      if (result == null) return null;
      
      return _mapToStudySession(result as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  StudySession _mapToStudySession(Map<String, dynamic> data) {
    final cardReviewsJson = data['card_reviews'] as String?;
    final cardReviews = cardReviewsJson != null
        ? (jsonDecode(cardReviewsJson) as List<dynamic>)
            .map((e) => CardReview.fromJson(e as Map<String, dynamic>))
            .toList()
        : <CardReview>[];

    final targetWordListIdsJson = data['target_word_list_ids'] as String?;
    final targetWordListIds = targetWordListIdsJson != null
        ? List<int>.from(jsonDecode(targetWordListIdsJson))
        : null;

    return StudySession(
      id: data['id'] as String,
      startTime: DateTime.fromMillisecondsSinceEpoch(data['start_time'] as int),
      endTime: data['end_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['end_time'] as int)
          : null,
      cardReviews: cardReviews,
      sessionType: StudySessionType.fromValue(data['session_type'] as int),
      targetWordListIds: targetWordListIds,
    );
  }

  // Helper methods
  Map<String, dynamic> _flashcardToMap(EnhancedFlashcard flashcard) {
    return {
      'id': flashcard.id,
      'word_slug': flashcard.wordSlug,
      'word': flashcard.word,
      'reading': flashcard.reading,
      'definition': flashcard.definition,
      'tags': jsonEncode(flashcard.tags),
      'word_list_ids': jsonEncode(flashcard.wordListIds),
      'mastery_level': flashcard.masteryLevel.level,
      'created_at': flashcard.createdAt.millisecondsSinceEpoch,
      'last_reviewed': flashcard.lastReviewed.millisecondsSinceEpoch,
      'next_review': flashcard.nextReview.millisecondsSinceEpoch,
      'interval_hours': flashcard.intervalHours,
      'ease_factor': flashcard.easeFactor,
      'repetitions': flashcard.repetitions,
      'correct_streak': flashcard.correctStreak,
      'total_reviews': flashcard.totalReviews,
      'correct_reviews': flashcard.correctReviews,
      'review_history': jsonEncode(flashcard.reviewHistory.map((e) => e.toJson()).toList()),
    };
  }

  EnhancedFlashcard _mapToFlashcard(Map<String, dynamic> data) {
    final tagsJson = data['tags'] as String?;
    final tags = tagsJson != null ? List<String>.from(jsonDecode(tagsJson)) : <String>[];
    
    final wordListIdsJson = data['word_list_ids'] as String?;
    final wordListIds = wordListIdsJson != null ? List<int>.from(jsonDecode(wordListIdsJson)) : <int>[];
    
    final reviewHistoryJson = data['review_history'] as String?;
    final reviewHistory = reviewHistoryJson != null 
        ? (jsonDecode(reviewHistoryJson) as List<dynamic>)
            .map((e) => ReviewSession.fromJson(e as Map<String, dynamic>))
            .toList()
        : <ReviewSession>[];

    return EnhancedFlashcard(
      id: data['id'] as String,
      wordSlug: data['word_slug'] as String,
      word: data['word'] as String,
      reading: data['reading'] as String,
      definition: data['definition'] as String,
      tags: tags,
      wordListIds: wordListIds,
      masteryLevel: MasteryLevel.fromLevel(data['mastery_level'] as int),
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['created_at'] as int),
      lastReviewed: DateTime.fromMillisecondsSinceEpoch(data['last_reviewed'] as int),
      nextReview: DateTime.fromMillisecondsSinceEpoch(data['next_review'] as int),
      intervalHours: data['interval_hours'] as int,
      easeFactor: data['ease_factor'] as int,
      repetitions: data['repetitions'] as int,
      correctStreak: data['correct_streak'] as int,
      totalReviews: data['total_reviews'] as int,
      correctReviews: data['correct_reviews'] as int,
      reviewHistory: reviewHistory,
    );
  }

  // Placeholder implementations for unimplemented methods
  @override
  Future<StudySessionStats> getStudySessionStats() async {
    // Simple implementation for web
    return const StudySessionStats();
  }

  @override
  Future<Map<String, dynamic>> getFlashcardStats() async {
    // Simple implementation for web
    return {};
  }

  @override
  Future<Map<String, dynamic>> getWordListStats() async {
    return {};
  }

  @override
  Future<Map<String, dynamic>> getUserStats() async {
    return {};
  }

  @override
  Future<List<Map<String, dynamic>>> getDailyStats(DateTime startDate, DateTime endDate) async {
    return [];
  }

  @override
  Future<Map<String, dynamic>> exportAllData() async {
    return {};
  }

  @override
  Future<bool> importAllData(Map<String, dynamic> data) async {
    return false;
  }

  @override
  Future<bool> clearAllData() async {
    try {
      final txn = _db.transaction([
        _favoritesStore,
        _enhancedFlashcardsStore,
        _wordListEntriesStore,
        _wordListsStore,
        _studySessionsStore,
        _userProgressStore,
      ], idbModeReadWrite);
      
      final stores = [
        txn.objectStore(_favoritesStore),
        txn.objectStore(_enhancedFlashcardsStore),
        txn.objectStore(_wordListEntriesStore),
        txn.objectStore(_wordListsStore),
        txn.objectStore(_studySessionsStore),
        txn.objectStore(_userProgressStore),
      ];
      
      for (final store in stores) {
        await store.clear();
      }
      
      await txn.completed;
      
      // Re-initialize default user progress
      await _initializeUserProgress();
      
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> optimizeDatabase() async {
    return true; // No-op for IndexedDB
  }

  @override
  Future<int> getDatabaseSize() async {
    return -1; // Not easily available in IndexedDB
  }

  @override
  Future<bool> validateDataIntegrity() async {
    return true; // IndexedDB handles this internally
  }
}