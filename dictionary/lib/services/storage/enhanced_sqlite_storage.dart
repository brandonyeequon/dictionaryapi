import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/word_entry.dart';
import '../../models/enhanced_flashcard.dart';
import '../../models/user_progress.dart';
import '../../models/study_session.dart';
import '../../models/word_list.dart';
import '../../models/word_mastery.dart';
import 'enhanced_storage_interface.dart';

/// Enhanced SQLite storage implementation for the advanced flashcard system
class EnhancedSqliteStorage implements EnhancedStorageInterface {
  static const String _dbName = 'enhanced_dictionary.db';
  static const int _dbVersion = 1;
  
  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _dbName);
    
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createTables,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // Favorites table (unchanged)
    await db.execute('''
      CREATE TABLE favorites (
        slug TEXT PRIMARY KEY,
        word_data TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // Word lists table
    await db.execute('''
      CREATE TABLE word_lists (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Word list entries (many-to-many relationship)
    await db.execute('''
      CREATE TABLE word_list_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        list_id INTEGER NOT NULL,
        word_slug TEXT NOT NULL,
        word_data TEXT NOT NULL,
        added_at INTEGER NOT NULL,
        position INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (list_id) REFERENCES word_lists (id) ON DELETE CASCADE,
        UNIQUE (list_id, word_slug)
      )
    ''');

    // Enhanced flashcards table
    await db.execute('''
      CREATE TABLE enhanced_flashcards (
        id TEXT PRIMARY KEY,
        word_slug TEXT UNIQUE NOT NULL,
        word TEXT NOT NULL,
        reading TEXT NOT NULL,
        definition TEXT NOT NULL,
        tags TEXT, -- JSON array
        word_list_ids TEXT, -- JSON array of list IDs
        mastery_level INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        last_reviewed INTEGER NOT NULL,
        next_review INTEGER NOT NULL,
        interval_hours INTEGER NOT NULL DEFAULT 4,
        ease_factor INTEGER NOT NULL DEFAULT 250,
        repetitions INTEGER NOT NULL DEFAULT 0,
        correct_streak INTEGER NOT NULL DEFAULT 0,
        total_reviews INTEGER NOT NULL DEFAULT 0,
        correct_reviews INTEGER NOT NULL DEFAULT 0,
        review_history TEXT -- JSON array of review sessions
      )
    ''');

    // User progress table
    await db.execute('''
      CREATE TABLE user_progress (
        id INTEGER PRIMARY KEY CHECK (id = 1), -- Single row table
        total_words_studied INTEGER NOT NULL DEFAULT 0,
        words_per_level INTEGER NOT NULL DEFAULT 10,
        last_study_session INTEGER,
        current_streak INTEGER NOT NULL DEFAULT 0,
        longest_streak INTEGER NOT NULL DEFAULT 0,
        streak_start_date INTEGER,
        word_count_by_level TEXT, -- JSON object
        total_reviews INTEGER NOT NULL DEFAULT 0,
        average_accuracy REAL NOT NULL DEFAULT 0.0,
        study_time_minutes INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Study sessions table
    await db.execute('''
      CREATE TABLE study_sessions (
        id TEXT PRIMARY KEY,
        start_time INTEGER NOT NULL,
        end_time INTEGER,
        card_reviews TEXT, -- JSON array
        session_type INTEGER NOT NULL DEFAULT 0,
        target_word_list_ids TEXT -- JSON array, nullable
      )
    ''');

    // Create indexes for performance
    await db.execute('CREATE INDEX idx_flashcards_next_review ON enhanced_flashcards(next_review)');
    await db.execute('CREATE INDEX idx_flashcards_mastery_level ON enhanced_flashcards(mastery_level)');
    await db.execute('CREATE INDEX idx_flashcards_word_slug ON enhanced_flashcards(word_slug)');
    await db.execute('CREATE INDEX idx_word_list_entries_list_id ON word_list_entries(list_id)');
    await db.execute('CREATE INDEX idx_word_list_entries_word_slug ON word_list_entries(word_slug)');
    await db.execute('CREATE INDEX idx_study_sessions_start_time ON study_sessions(start_time)');
    await db.execute('CREATE INDEX idx_favorites_created_at ON favorites(created_at)');

    // Insert default user progress
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert('user_progress', {
      'id': 1,
      'total_words_studied': 0,
      'words_per_level': 10,
      'current_streak': 0,
      'longest_streak': 0,
      'word_count_by_level': '{}',
      'total_reviews': 0,
      'average_accuracy': 0.0,
      'study_time_minutes': 0,
      'created_at': now,
      'updated_at': now,
    });
  }

  @override
  Future<void> initialize() async {
    await database; // Initialize database
  }

  @override
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // Favorites operations (unchanged)
  @override
  Future<bool> addToFavorites(WordEntry wordEntry) async {
    try {
      final db = await database;
      await db.insert(
        'favorites',
        {
          'slug': wordEntry.slug,
          'word_data': jsonEncode(wordEntry.toJson()),
          'created_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> removeFromFavorites(String slug) async {
    try {
      final db = await database;
      final count = await db.delete('favorites', where: 'slug = ?', whereArgs: [slug]);
      return count > 0;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> isFavorite(String slug) async {
    try {
      final db = await database;
      final result = await db.query(
        'favorites',
        where: 'slug = ?',
        whereArgs: [slug],
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<WordEntry>> getFavorites() async {
    try {
      final db = await database;
      final result = await db.query(
        'favorites',
        orderBy: 'created_at DESC',
      );
      
      return result.map((row) {
        final wordData = jsonDecode(row['word_data'] as String);
        return WordEntry.fromJson(wordData);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Enhanced flashcard operations
  @override
  Future<bool> saveFlashcard(EnhancedFlashcard flashcard) async {
    try {
      final db = await database;
      await db.insert(
        'enhanced_flashcards',
        _flashcardToMap(flashcard),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> updateFlashcard(EnhancedFlashcard flashcard) async {
    try {
      final db = await database;
      final count = await db.update(
        'enhanced_flashcards',
        _flashcardToMap(flashcard),
        where: 'id = ?',
        whereArgs: [flashcard.id],
      );
      return count > 0;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> removeFlashcard(String flashcardId) async {
    try {
      final db = await database;
      final count = await db.delete(
        'enhanced_flashcards',
        where: 'id = ?',
        whereArgs: [flashcardId],
      );
      return count > 0;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<EnhancedFlashcard>> getAllFlashcards() async {
    try {
      final db = await database;
      final result = await db.query('enhanced_flashcards');
      return result.map(_mapToFlashcard).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<EnhancedFlashcard?> getFlashcard(String flashcardId) async {
    try {
      final db = await database;
      final result = await db.query(
        'enhanced_flashcards',
        where: 'id = ?',
        whereArgs: [flashcardId],
        limit: 1,
      );
      
      if (result.isEmpty) return null;
      return _mapToFlashcard(result.first);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<EnhancedFlashcard?> getFlashcardByWordSlug(String wordSlug) async {
    try {
      final db = await database;
      final result = await db.query(
        'enhanced_flashcards',
        where: 'word_slug = ?',
        whereArgs: [wordSlug],
        limit: 1,
      );
      
      if (result.isEmpty) return null;
      return _mapToFlashcard(result.first);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> hasFlashcard(String wordSlug) async {
    try {
      final db = await database;
      final result = await db.query(
        'enhanced_flashcards',
        where: 'word_slug = ?',
        whereArgs: [wordSlug],
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<EnhancedFlashcard>> getFlashcardsInList(int listId) async {
    try {
      final db = await database;
      final result = await db.query(
        'enhanced_flashcards',
        where: 'word_list_ids LIKE ?',
        whereArgs: ['%[$listId]%'], // Simple JSON array search
      );
      return result.map(_mapToFlashcard).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<EnhancedFlashcard>> getFlashcardsInLists(List<int> listIds) async {
    if (listIds.isEmpty) return [];
    
    try {
      final db = await database;
      final conditions = listIds.map((_) => 'word_list_ids LIKE ?').join(' OR ');
      final args = listIds.map((id) => '%[$id]%').toList();
      
      final result = await db.query(
        'enhanced_flashcards',
        where: conditions,
        whereArgs: args,
      );
      return result.map(_mapToFlashcard).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<EnhancedFlashcard>> getDueFlashcards() async {
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;
      final result = await db.query(
        'enhanced_flashcards',
        where: 'next_review <= ?',
        whereArgs: [now],
        orderBy: 'next_review ASC',
      );
      return result.map(_mapToFlashcard).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<EnhancedFlashcard>> getDueFlashcardsInList(int listId) async {
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;
      final result = await db.query(
        'enhanced_flashcards',
        where: 'next_review <= ? AND word_list_ids LIKE ?',
        whereArgs: [now, '%[$listId]%'],
        orderBy: 'next_review ASC',
      );
      return result.map(_mapToFlashcard).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<EnhancedFlashcard>> getNewFlashcards() async {
    try {
      final db = await database;
      final result = await db.query(
        'enhanced_flashcards',
        where: 'mastery_level = ?',
        whereArgs: [MasteryLevel.newWord.level],
        orderBy: 'created_at ASC',
      );
      return result.map(_mapToFlashcard).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<EnhancedFlashcard>> getFlashcardsByMastery(MasteryLevel level) async {
    try {
      final db = await database;
      final result = await db.query(
        'enhanced_flashcards',
        where: 'mastery_level = ?',
        whereArgs: [level.level],
        orderBy: 'last_reviewed DESC',
      );
      return result.map(_mapToFlashcard).toList();
    } catch (e) {
      return [];
    }
  }

  // Word list operations
  @override
  Future<int> createWordList(String name, {String? description}) async {
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;
      final id = await db.insert('word_lists', {
        'name': name,
        'description': description,
        'created_at': now,
        'updated_at': now,
      });
      return id;
    } catch (e) {
      return -1;
    }
  }

  @override
  Future<bool> updateWordList(WordList wordList) async {
    try {
      final db = await database;
      final count = await db.update(
        'word_lists',
        {
          'name': wordList.name,
          'description': wordList.description,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [wordList.id],
      );
      return count > 0;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> deleteWordList(int listId) async {
    try {
      final db = await database;
      final count = await db.delete('word_lists', where: 'id = ?', whereArgs: [listId]);
      return count > 0;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<WordList>> getAllWordLists() async {
    try {
      final db = await database;
      final result = await db.query('word_lists', orderBy: 'created_at DESC');
      return result.map((row) => WordList.fromJson(row)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<WordList?> getWordList(int listId) async {
    try {
      final db = await database;
      final result = await db.query(
        'word_lists',
        where: 'id = ?',
        whereArgs: [listId],
        limit: 1,
      );
      
      if (result.isEmpty) return null;
      return WordList.fromJson(result.first);
    } catch (e) {
      return null;
    }
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

  EnhancedFlashcard _mapToFlashcard(Map<String, dynamic> row) {
    final tagsJson = row['tags'] as String?;
    final tags = tagsJson != null ? List<String>.from(jsonDecode(tagsJson)) : <String>[];
    
    final wordListIdsJson = row['word_list_ids'] as String?;
    final wordListIds = wordListIdsJson != null ? List<int>.from(jsonDecode(wordListIdsJson)) : <int>[];
    
    final reviewHistoryJson = row['review_history'] as String?;
    final reviewHistory = reviewHistoryJson != null 
        ? (jsonDecode(reviewHistoryJson) as List<dynamic>)
            .map((e) => ReviewSession.fromJson(e as Map<String, dynamic>))
            .toList()
        : <ReviewSession>[];

    return EnhancedFlashcard(
      id: row['id'] as String,
      wordSlug: row['word_slug'] as String,
      word: row['word'] as String,
      reading: row['reading'] as String,
      definition: row['definition'] as String,
      tags: tags,
      wordListIds: wordListIds,
      masteryLevel: MasteryLevel.fromLevel(row['mastery_level'] as int),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      lastReviewed: DateTime.fromMillisecondsSinceEpoch(row['last_reviewed'] as int),
      nextReview: DateTime.fromMillisecondsSinceEpoch(row['next_review'] as int),
      intervalHours: row['interval_hours'] as int,
      easeFactor: row['ease_factor'] as int,
      repetitions: row['repetitions'] as int,
      correctStreak: row['correct_streak'] as int,
      totalReviews: row['total_reviews'] as int,
      correctReviews: row['correct_reviews'] as int,
      reviewHistory: reviewHistory,
    );
  }

  // Remaining methods to be implemented...
  @override
  Future<bool> addWordToList(int listId, WordEntry wordEntry) async {
    // Implementation continues...
    try {
      final db = await database;
      await db.insert(
        'word_list_entries',
        {
          'list_id': listId,
          'word_slug': wordEntry.slug,
          'word_data': jsonEncode(wordEntry.toJson()),
          'added_at': DateTime.now().millisecondsSinceEpoch,
          'position': 0, // TODO: Calculate proper position
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> removeWordFromList(int listId, String wordSlug) async {
    try {
      final db = await database;
      final count = await db.delete(
        'word_list_entries',
        where: 'list_id = ? AND word_slug = ?',
        whereArgs: [listId, wordSlug],
      );
      return count > 0;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<WordEntry>> getWordsInList(int listId) async {
    try {
      final db = await database;
      final result = await db.query(
        'word_list_entries',
        where: 'list_id = ?',
        whereArgs: [listId],
        orderBy: 'position ASC, added_at ASC',
      );
      
      return result.map((row) {
        final wordData = jsonDecode(row['word_data'] as String);
        return WordEntry.fromJson(wordData);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<WordEntry>> getAllWordsInLists(List<int> listIds) async {
    if (listIds.isEmpty) return [];
    
    try {
      final db = await database;
      final placeholders = listIds.map((_) => '?').join(',');
      final result = await db.query(
        'word_list_entries',
        where: 'list_id IN ($placeholders)',
        whereArgs: listIds,
        orderBy: 'added_at ASC',
      );
      
      final uniqueWords = <String, WordEntry>{};
      for (final row in result) {
        final wordData = jsonDecode(row['word_data'] as String);
        final word = WordEntry.fromJson(wordData);
        uniqueWords[word.slug] = word; // Deduplicate by slug
      }
      
      return uniqueWords.values.toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<int>> getListsContainingWord(String wordSlug) async {
    try {
      final db = await database;
      final result = await db.query(
        'word_list_entries',
        columns: ['list_id'],
        where: 'word_slug = ?',
        whereArgs: [wordSlug],
      );
      
      return result.map((row) => row['list_id'] as int).toList();
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
      final db = await database;
      await db.insert(
        'user_progress',
        {
          'id': 1,
          ...progress.toJson(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<UserProgress?> getUserProgress() async {
    try {
      final db = await database;
      final result = await db.query('user_progress', where: 'id = 1', limit: 1);
      
      if (result.isEmpty) return null;
      return UserProgress.fromJson(result.first);
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
      final db = await database;
      await db.insert(
        'study_sessions',
        {
          'id': session.id,
          'start_time': session.startTime.millisecondsSinceEpoch,
          'end_time': session.endTime?.millisecondsSinceEpoch,
          'card_reviews': jsonEncode(session.cardReviews.map((e) => e.toJson()).toList()),
          'session_type': session.sessionType.value,
          'target_word_list_ids': session.targetWordListIds != null 
              ? jsonEncode(session.targetWordListIds) 
              : null,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
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
      final db = await database;
      var query = 'SELECT * FROM study_sessions';
      final args = <Object>[];
      
      if (startDate != null || endDate != null) {
        query += ' WHERE ';
        if (startDate != null) {
          query += 'start_time >= ?';
          args.add(startDate.millisecondsSinceEpoch);
        }
        if (endDate != null) {
          if (startDate != null) query += ' AND ';
          query += 'start_time <= ?';
          args.add(endDate.millisecondsSinceEpoch);
        }
      }
      
      query += ' ORDER BY start_time DESC';
      
      if (limit != null) {
        query += ' LIMIT ?';
        args.add(limit);
      }
      
      final result = await db.rawQuery(query, args);
      return result.map(_mapToStudySession).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<StudySession?> getStudySession(String sessionId) async {
    try {
      final db = await database;
      final result = await db.query(
        'study_sessions',
        where: 'id = ?',
        whereArgs: [sessionId],
        limit: 1,
      );
      
      if (result.isEmpty) return null;
      return _mapToStudySession(result.first);
    } catch (e) {
      return null;
    }
  }

  StudySession _mapToStudySession(Map<String, dynamic> row) {
    final cardReviewsJson = row['card_reviews'] as String?;
    final cardReviews = cardReviewsJson != null
        ? (jsonDecode(cardReviewsJson) as List<dynamic>)
            .map((e) => CardReview.fromJson(e as Map<String, dynamic>))
            .toList()
        : <CardReview>[];

    final targetWordListIdsJson = row['target_word_list_ids'] as String?;
    final targetWordListIds = targetWordListIdsJson != null
        ? List<int>.from(jsonDecode(targetWordListIdsJson))
        : null;

    return StudySession(
      id: row['id'] as String,
      startTime: DateTime.fromMillisecondsSinceEpoch(row['start_time'] as int),
      endTime: row['end_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(row['end_time'] as int)
          : null,
      cardReviews: cardReviews,
      sessionType: StudySessionType.fromValue(row['session_type'] as int),
      targetWordListIds: targetWordListIds,
    );
  }

  // Placeholder implementations for remaining methods
  @override
  Future<StudySessionStats> getStudySessionStats() async {
    // TODO: Implement comprehensive stats calculation
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> getFlashcardStats() async {
    // TODO: Implement flashcard statistics
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> getWordListStats() async {
    // TODO: Implement word list statistics
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> getUserStats() async {
    // TODO: Implement user statistics
    throw UnimplementedError();
  }

  @override
  Future<List<Map<String, dynamic>>> getDailyStats(DateTime startDate, DateTime endDate) async {
    // TODO: Implement daily statistics
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> exportAllData() async {
    // TODO: Implement data export
    throw UnimplementedError();
  }

  @override
  Future<bool> importAllData(Map<String, dynamic> data) async {
    // TODO: Implement data import
    throw UnimplementedError();
  }

  @override
  Future<bool> clearAllData() async {
    try {
      final db = await database;
      await db.transaction((txn) async {
        await txn.delete('favorites');
        await txn.delete('enhanced_flashcards');
        await txn.delete('word_list_entries');
        await txn.delete('word_lists');
        await txn.delete('study_sessions');
        await txn.delete('user_progress');
        
        // Reset user progress
        final now = DateTime.now().millisecondsSinceEpoch;
        await txn.insert('user_progress', {
          'id': 1,
          'total_words_studied': 0,
          'words_per_level': 10,
          'current_streak': 0,
          'longest_streak': 0,
          'word_count_by_level': '{}',
          'total_reviews': 0,
          'average_accuracy': 0.0,
          'study_time_minutes': 0,
          'created_at': now,
          'updated_at': now,
        });
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> optimizeDatabase() async {
    try {
      final db = await database;
      await db.execute('VACUUM');
      await db.execute('ANALYZE');
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<int> getDatabaseSize() async {
    try {
      final db = await database;
      final result = await db.rawQuery('PRAGMA page_count');
      final pageCount = result.first['page_count'] as int;
      
      final pageSizeResult = await db.rawQuery('PRAGMA page_size');
      final pageSize = pageSizeResult.first['page_size'] as int;
      
      return pageCount * pageSize;
    } catch (e) {
      return -1;
    }
  }

  @override
  Future<bool> validateDataIntegrity() async {
    try {
      final db = await database;
      final result = await db.rawQuery('PRAGMA integrity_check');
      return result.first['integrity_check'] == 'ok';
    } catch (e) {
      return false;
    }
  }
}