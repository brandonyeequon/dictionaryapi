import 'dart:convert';
import 'package:idb_shim/idb_browser.dart';
import '../../models/word_entry.dart';
import '../../models/flashcard.dart';
import 'storage_interface.dart';

/// IndexedDB implementation for web platform
class WebStorage implements StorageInterface {
  Database? _database;
  static const String _dbName = 'jisho_dictionary';
  static const int _dbVersion = 1;

  static const String _favoritesStore = 'favorites';
  static const String _wordListsStore = 'word_lists';
  static const String _wordListItemsStore = 'word_list_items';
  static const String _flashcardsStore = 'flashcards';

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
        wordListsStore.createIndex('updated_at', 'updated_at');
      }

      // Create word list items store
      if (!db.objectStoreNames.contains(_wordListItemsStore)) {
        final wordListItemsStore = db.createObjectStore(_wordListItemsStore, keyPath: 'id', autoIncrement: true);
        wordListItemsStore.createIndex('list_id', 'list_id');
        wordListItemsStore.createIndex('added_at', 'added_at');
      }

      // Create flashcards store
      if (!db.objectStoreNames.contains(_flashcardsStore)) {
        final flashcardsStore = db.createObjectStore(_flashcardsStore, keyPath: 'id');
        flashcardsStore.createIndex('word_slug', 'word_slug', unique: true);
        flashcardsStore.createIndex('next_review', 'next_review');
      }
    });
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
        'word_data': json.encode(wordEntry.toJson()),
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
        final wordData = json.decode(data['word_data'] as String);
        favorites.add(WordEntry.fromJson(wordData));
        cursorWithValue.next();
      }
      
      return favorites;
    } catch (e) {
      return [];
    }
  }

  // Flashcard operations
  @override
  Future<bool> addFlashcard(Flashcard flashcard) async {
    try {
      final txn = _db.transaction([_flashcardsStore], idbModeReadWrite);
      final store = txn.objectStore(_flashcardsStore);
      
      await store.put({
        'id': flashcard.id,
        'word_slug': flashcard.wordSlug,
        'word': flashcard.word,
        'reading': flashcard.reading,
        'definition': flashcard.definition,
        'tags': json.encode(flashcard.tags),
        'created_at': flashcard.createdAt.millisecondsSinceEpoch,
        'last_reviewed': flashcard.lastReviewed.millisecondsSinceEpoch,
        'next_review': flashcard.nextReview.millisecondsSinceEpoch,
        'interval_days': flashcard.intervalDays,
        'ease_factor': flashcard.easeFactor,
        'repetitions': flashcard.repetitions,
        'is_learning': flashcard.isLearning,
      });
      
      await txn.completed;
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> updateFlashcard(Flashcard flashcard) async {
    return addFlashcard(flashcard); // Same operation for IndexedDB
  }

  @override
  Future<bool> removeFlashcard(String flashcardId) async {
    try {
      final txn = _db.transaction([_flashcardsStore], idbModeReadWrite);
      final store = txn.objectStore(_flashcardsStore);
      
      await store.delete(flashcardId);
      await txn.completed;
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<Flashcard>> getFlashcards() async {
    try {
      final txn = _db.transaction([_flashcardsStore], idbModeReadOnly);
      final store = txn.objectStore(_flashcardsStore);
      final index = store.index('next_review');
      
      final flashcards = <Flashcard>[];
      final cursor = index.openCursor();
      
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
  Future<Flashcard?> getFlashcard(String flashcardId) async {
    try {
      final txn = _db.transaction([_flashcardsStore], idbModeReadOnly);
      final store = txn.objectStore(_flashcardsStore);
      
      final result = await store.getObject(flashcardId);
      if (result == null) return null;
      
      return _mapToFlashcard(result as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> hasFlashcard(String wordSlug) async {
    try {
      final txn = _db.transaction([_flashcardsStore], idbModeReadOnly);
      final store = txn.objectStore(_flashcardsStore);
      final index = store.index('word_slug');
      
      final result = await index.getKey(wordSlug);
      return result != null;
    } catch (e) {
      return false;
    }
  }

  Flashcard _mapToFlashcard(Map<String, dynamic> data) {
    final tagsData = json.decode(data['tags'] as String);
    return Flashcard(
      id: data['id'] as String,
      wordSlug: data['word_slug'] as String,
      word: data['word'] as String,
      reading: data['reading'] as String,
      definition: data['definition'] as String,
      tags: List<String>.from(tagsData),
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['created_at'] as int),
      lastReviewed: DateTime.fromMillisecondsSinceEpoch(data['last_reviewed'] as int),
      nextReview: DateTime.fromMillisecondsSinceEpoch(data['next_review'] as int),
      intervalDays: data['interval_days'] as int,
      easeFactor: data['ease_factor'] as int,
      repetitions: data['repetitions'] as int,
      isLearning: data['is_learning'] as bool,
    );
  }

  // Word lists operations (simplified implementation for web)
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
  Future<List<Map<String, dynamic>>> getWordLists() async {
    try {
      final txn = _db.transaction([_wordListsStore], idbModeReadOnly);
      final store = txn.objectStore(_wordListsStore);
      final index = store.index('updated_at');
      
      final wordLists = <Map<String, dynamic>>[];
      final cursor = index.openCursor(direction: idbDirectionPrev);
      
      await for (final cursorWithValue in cursor) {
        wordLists.add(cursorWithValue.value as Map<String, dynamic>);
        cursorWithValue.next();
      }
      
      return wordLists;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<bool> addWordToList(int listId, WordEntry wordEntry) async {
    try {
      final txn = _db.transaction([_wordListItemsStore, _wordListsStore], idbModeReadWrite);
      final itemsStore = txn.objectStore(_wordListItemsStore);
      final listsStore = txn.objectStore(_wordListsStore);
      
      await itemsStore.add({
        'list_id': listId,
        'slug': wordEntry.slug,
        'word_data': json.encode(wordEntry.toJson()),
        'added_at': DateTime.now().millisecondsSinceEpoch,
      });

      await listsStore.put({
        'id': listId,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });
      
      await txn.completed;
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<WordEntry>> getWordsInList(int listId) async {
    try {
      final txn = _db.transaction([_wordListItemsStore], idbModeReadOnly);
      final store = txn.objectStore(_wordListItemsStore);
      final index = store.index('list_id');
      
      final words = <WordEntry>[];
      final cursor = index.openCursor(key: listId);
      
      await for (final cursorWithValue in cursor) {
        final data = cursorWithValue.value as Map<String, dynamic>;
        final wordData = json.decode(data['word_data'] as String);
        words.add(WordEntry.fromJson(wordData));
        cursorWithValue.next();
      }
      
      return words;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<bool> removeWordFromList(int listId, String slug) async {
    try {
      final txn = _db.transaction([_wordListItemsStore, _wordListsStore], idbModeReadWrite);
      final itemsStore = txn.objectStore(_wordListItemsStore);
      final listsStore = txn.objectStore(_wordListsStore);
      final index = itemsStore.index('list_id');
      
      // Find and delete the item
      final cursor = index.openCursor(key: listId);
      await for (final cursorWithValue in cursor) {
        final data = cursorWithValue.value as Map<String, dynamic>;
        if (data['slug'] == slug) {
          await cursorWithValue.delete();
          break;
        }
        cursorWithValue.next();
      }

      // Update list timestamp
      await listsStore.put({
        'id': listId,
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
      final txn = _db.transaction([_wordListsStore, _wordListItemsStore], idbModeReadWrite);
      final listsStore = txn.objectStore(_wordListsStore);
      final itemsStore = txn.objectStore(_wordListItemsStore);
      final index = itemsStore.index('list_id');
      
      // Delete all items in the list
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
}