import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/word_entry.dart';

class DatabaseService {
  static Database? _database;
  static const String _dbName = 'jisho_dictionary.db';
  static const int _dbVersion = 1;

  static const String _favoritesTable = 'favorites';
  static const String _wordListsTable = 'word_lists';
  static const String _wordListItemsTable = 'word_list_items';
  static const String _flashcardsTable = 'flashcards';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createDatabase,
    );
  }

  static Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_favoritesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        slug TEXT UNIQUE NOT NULL,
        word_data TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $_wordListsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $_wordListItemsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        list_id INTEGER NOT NULL,
        slug TEXT NOT NULL,
        word_data TEXT NOT NULL,
        added_at INTEGER NOT NULL,
        FOREIGN KEY (list_id) REFERENCES $_wordListsTable (id) ON DELETE CASCADE,
        UNIQUE(list_id, slug)
      )
    ''');

    await db.execute('''
      CREATE TABLE $_flashcardsTable (
        id TEXT PRIMARY KEY,
        word_slug TEXT NOT NULL,
        word TEXT NOT NULL,
        reading TEXT NOT NULL,
        definition TEXT NOT NULL,
        tags TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        last_reviewed INTEGER NOT NULL,
        next_review INTEGER NOT NULL,
        interval_days INTEGER NOT NULL DEFAULT 1,
        ease_factor INTEGER NOT NULL DEFAULT 250,
        repetitions INTEGER NOT NULL DEFAULT 0,
        is_learning INTEGER NOT NULL DEFAULT 1,
        UNIQUE(word_slug)
      )
    ''');
  }

  static Future<bool> addToFavorites(WordEntry wordEntry) async {
    try {
      final db = await database;
      await db.insert(
        _favoritesTable,
        {
          'slug': wordEntry.slug,
          'word_data': json.encode(wordEntry.toJson()),
          'created_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> removeFromFavorites(String slug) async {
    try {
      final db = await database;
      await db.delete(
        _favoritesTable,
        where: 'slug = ?',
        whereArgs: [slug],
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> isFavorite(String slug) async {
    try {
      final db = await database;
      final result = await db.query(
        _favoritesTable,
        where: 'slug = ?',
        whereArgs: [slug],
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  static Future<List<WordEntry>> getFavorites() async {
    try {
      final db = await database;
      final result = await db.query(
        _favoritesTable,
        orderBy: 'created_at DESC',
      );

      return result.map((row) {
        final wordData = json.decode(row['word_data'] as String);
        return WordEntry.fromJson(wordData);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<int> createWordList(String name, {String? description}) async {
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      return await db.insert(_wordListsTable, {
        'name': name,
        'description': description,
        'created_at': now,
        'updated_at': now,
      });
    } catch (e) {
      return -1;
    }
  }

  static Future<List<Map<String, dynamic>>> getWordLists() async {
    try {
      final db = await database;
      return await db.query(
        _wordListsTable,
        orderBy: 'updated_at DESC',
      );
    } catch (e) {
      return [];
    }
  }

  static Future<bool> addWordToList(int listId, WordEntry wordEntry) async {
    try {
      final db = await database;
      await db.insert(
        _wordListItemsTable,
        {
          'list_id': listId,
          'slug': wordEntry.slug,
          'word_data': json.encode(wordEntry.toJson()),
          'added_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await db.update(
        _wordListsTable,
        {'updated_at': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [listId],
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<List<WordEntry>> getWordsInList(int listId) async {
    try {
      final db = await database;
      final result = await db.query(
        _wordListItemsTable,
        where: 'list_id = ?',
        whereArgs: [listId],
        orderBy: 'added_at DESC',
      );

      return result.map((row) {
        final wordData = json.decode(row['word_data'] as String);
        return WordEntry.fromJson(wordData);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<bool> removeWordFromList(int listId, String slug) async {
    try {
      final db = await database;
      await db.delete(
        _wordListItemsTable,
        where: 'list_id = ? AND slug = ?',
        whereArgs: [listId, slug],
      );

      await db.update(
        _wordListsTable,
        {'updated_at': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [listId],
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteWordList(int listId) async {
    try {
      final db = await database;
      await db.delete(
        _wordListsTable,
        where: 'id = ?',
        whereArgs: [listId],
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // Flashcard methods
  static Future<bool> addFlashcard(dynamic flashcard) async {
    try {
      final db = await database;
      await db.insert(
        _flashcardsTable,
        {
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
          'is_learning': flashcard.isLearning ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateFlashcard(dynamic flashcard) async {
    try {
      final db = await database;
      await db.update(
        _flashcardsTable,
        {
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
          'is_learning': flashcard.isLearning ? 1 : 0,
        },
        where: 'id = ?',
        whereArgs: [flashcard.id],
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> removeFlashcard(String flashcardId) async {
    try {
      final db = await database;
      await db.delete(
        _flashcardsTable,
        where: 'id = ?',
        whereArgs: [flashcardId],
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<List<dynamic>> getFlashcards() async {
    try {
      final db = await database;
      final result = await db.query(
        _flashcardsTable,
        orderBy: 'next_review ASC',
      );

      return result.map((row) {
        final tagsData = json.decode(row['tags'] as String);
        return {
          'id': row['id'],
          'word_slug': row['word_slug'],
          'word': row['word'],
          'reading': row['reading'],
          'definition': row['definition'],
          'tags': tagsData,
          'created_at': row['created_at'],
          'last_reviewed': row['last_reviewed'],
          'next_review': row['next_review'],
          'interval_days': row['interval_days'],
          'ease_factor': row['ease_factor'],
          'repetitions': row['repetitions'],
          'is_learning': (row['is_learning'] as int) == 1,
        };
      }).map((data) => _createFlashcardFromData(data)).toList();
    } catch (e) {
      return [];
    }
  }

  static dynamic _createFlashcardFromData(Map<String, dynamic> data) {
    // This will be imported from flashcard.dart
    // For now, return the data as is and let FlashcardService handle it
    return data;
  }
}