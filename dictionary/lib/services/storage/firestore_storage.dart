import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/word_entry.dart';
import '../../models/enhanced_flashcard.dart';
import '../../models/user_progress.dart';
import '../../models/study_session.dart';
import '../../models/word_list.dart';
import '../../models/word_mastery.dart';
import '../auth_service.dart';
import '../enhanced_storage_interface.dart';

class FirestoreStorage implements EnhancedStorageInterface {
  static final FirestoreStorage _instance = FirestoreStorage._internal();
  factory FirestoreStorage() => _instance;
  FirestoreStorage._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  String get _userId => _authService.userId ?? '';
  bool get _isAuthenticated => _authService.isSignedIn;

  CollectionReference get _userDoc => _firestore.collection('users').doc(_userId).collection('data');
  CollectionReference get _favoritesCollection => _userDoc.doc('collections').collection('favorites');
  CollectionReference get _flashcardsCollection => _userDoc.doc('collections').collection('flashcards');
  CollectionReference get _wordListsCollection => _userDoc.doc('collections').collection('wordLists');
  CollectionReference get _wordListEntriesCollection => _userDoc.doc('collections').collection('wordListEntries');
  CollectionReference get _studySessionsCollection => _userDoc.doc('collections').collection('studySessions');
  DocumentReference get _userProgressDoc => _userDoc.doc('userProgress');

  @override
  Future<void> initialize() async {
    if (!_isAuthenticated) {
      throw Exception('User must be authenticated to initialize Firestore storage');
    }
    
    await _initializeUserDocument();
  }

  Future<void> _initializeUserDocument() async {
    final userRef = _firestore.collection('users').doc(_userId);
    
    await userRef.set({
      'email': _authService.userEmail,
      'displayName': _authService.userDisplayName,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> close() async {
    // Firestore connections are managed automatically
  }

  // Favorites operations
  @override
  Future<bool> addToFavorites(WordEntry wordEntry) async {
    try {
      await _favoritesCollection.doc(wordEntry.slug).set({
        ...wordEntry.toJson(),
        'addedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error adding to favorites: $e');
      return false;
    }
  }

  @override
  Future<bool> removeFromFavorites(String slug) async {
    try {
      await _favoritesCollection.doc(slug).delete();
      return true;
    } catch (e) {
      print('Error removing from favorites: $e');
      return false;
    }
  }

  @override
  Future<bool> isFavorite(String slug) async {
    try {
      final doc = await _favoritesCollection.doc(slug).get();
      return doc.exists;
    } catch (e) {
      print('Error checking favorite status: $e');
      return false;
    }
  }

  @override
  Future<List<WordEntry>> getFavorites() async {
    try {
      final snapshot = await _favoritesCollection.orderBy('addedAt', descending: true).get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data.remove('addedAt'); // Remove Firestore-specific field
        return WordEntry.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error getting favorites: $e');
      return [];
    }
  }

  // Enhanced flashcard operations
  @override
  Future<bool> saveFlashcard(EnhancedFlashcard flashcard) async {
    try {
      await _flashcardsCollection.doc(flashcard.id).set({
        ...flashcard.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error saving flashcard: $e');
      return false;
    }
  }

  @override
  Future<bool> updateFlashcard(EnhancedFlashcard flashcard) async {
    return await saveFlashcard(flashcard);
  }

  @override
  Future<bool> removeFlashcard(String flashcardId) async {
    try {
      await _flashcardsCollection.doc(flashcardId).delete();
      return true;
    } catch (e) {
      print('Error removing flashcard: $e');
      return false;
    }
  }

  @override
  Future<List<EnhancedFlashcard>> getAllFlashcards() async {
    try {
      final snapshot = await _flashcardsCollection.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data.remove('updatedAt'); // Remove Firestore-specific field
        return EnhancedFlashcard.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error getting flashcards: $e');
      return [];
    }
  }

  @override
  Future<EnhancedFlashcard?> getFlashcard(String flashcardId) async {
    try {
      final doc = await _flashcardsCollection.doc(flashcardId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data.remove('updatedAt'); // Remove Firestore-specific field
        return EnhancedFlashcard.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting flashcard: $e');
      return null;
    }
  }

  @override
  Future<EnhancedFlashcard?> getFlashcardByWordSlug(String wordSlug) async {
    try {
      final snapshot = await _flashcardsCollection.where('wordSlug', isEqualTo: wordSlug).limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data() as Map<String, dynamic>;
        data.remove('updatedAt'); // Remove Firestore-specific field
        return EnhancedFlashcard.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting flashcard by word slug: $e');
      return null;
    }
  }

  @override
  Future<bool> hasFlashcard(String wordSlug) async {
    try {
      final snapshot = await _flashcardsCollection.where('wordSlug', isEqualTo: wordSlug).limit(1).get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking flashcard existence: $e');
      return false;
    }
  }

  // List-based flashcard queries
  @override
  Future<List<EnhancedFlashcard>> getFlashcardsInList(int listId) async {
    try {
      final snapshot = await _flashcardsCollection.where('listIds', arrayContains: listId).get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data.remove('updatedAt'); // Remove Firestore-specific field
        return EnhancedFlashcard.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error getting flashcards in list: $e');
      return [];
    }
  }

  @override
  Future<List<EnhancedFlashcard>> getFlashcardsInLists(List<int> listIds) async {
    try {
      final snapshot = await _flashcardsCollection.where('listIds', arrayContainsAny: listIds).get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data.remove('updatedAt'); // Remove Firestore-specific field
        return EnhancedFlashcard.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error getting flashcards in lists: $e');
      return [];
    }
  }

  @override
  Future<List<EnhancedFlashcard>> getDueFlashcards() async {
    try {
      final now = Timestamp.now();
      final snapshot = await _flashcardsCollection
          .where('nextReview', isLessThanOrEqualTo: now)
          .orderBy('nextReview')
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data.remove('updatedAt'); // Remove Firestore-specific field
        return EnhancedFlashcard.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error getting due flashcards: $e');
      return [];
    }
  }

  @override
  Future<List<EnhancedFlashcard>> getDueFlashcardsInList(int listId) async {
    try {
      final now = Timestamp.now();
      final snapshot = await _flashcardsCollection
          .where('listIds', arrayContains: listId)
          .where('nextReview', isLessThanOrEqualTo: now)
          .orderBy('nextReview')
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data.remove('updatedAt'); // Remove Firestore-specific field
        return EnhancedFlashcard.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error getting due flashcards in list: $e');
      return [];
    }
  }

  @override
  Future<List<EnhancedFlashcard>> getNewFlashcards() async {
    try {
      final snapshot = await _flashcardsCollection
          .where('isLearning', isEqualTo: true)
          .where('repetitions', isEqualTo: 0)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data.remove('updatedAt'); // Remove Firestore-specific field
        return EnhancedFlashcard.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error getting new flashcards: $e');
      return [];
    }
  }

  @override
  Future<List<EnhancedFlashcard>> getFlashcardsByMastery(MasteryLevel level) async {
    try {
      final snapshot = await _flashcardsCollection.where('masteryLevel', isEqualTo: level.index).get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data.remove('updatedAt'); // Remove Firestore-specific field
        return EnhancedFlashcard.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error getting flashcards by mastery: $e');
      return [];
    }
  }

  // Word list operations
  @override
  Future<int> createWordList(String name, {String? description}) async {
    try {
      final doc = await _wordListsCollection.add({
        'name': name,
        'description': description ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'wordCount': 0,
      });
      
      // Return a hash-based integer ID for compatibility
      return doc.id.hashCode.abs();
    } catch (e) {
      print('Error creating word list: $e');
      return -1;
    }
  }

  @override
  Future<bool> updateWordList(WordList wordList) async {
    try {
      final snapshot = await _wordListsCollection.where('id', isEqualTo: wordList.id).limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.update({
          ...wordList.toJson(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating word list: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteWordList(int listId) async {
    try {
      final snapshot = await _wordListsCollection.where('id', isEqualTo: listId).limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.delete();
        
        // Also delete all entries in this list
        final entriesSnapshot = await _wordListEntriesCollection.where('listId', isEqualTo: listId).get();
        for (final doc in entriesSnapshot.docs) {
          await doc.reference.delete();
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting word list: $e');
      return false;
    }
  }

  @override
  Future<List<WordList>> getAllWordLists() async {
    try {
      final snapshot = await _wordListsCollection.orderBy('createdAt', descending: true).get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data.remove('updatedAt'); // Remove Firestore-specific field
        return WordList.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error getting word lists: $e');
      return [];
    }
  }

  @override
  Future<WordList?> getWordList(int listId) async {
    try {
      final snapshot = await _wordListsCollection.where('id', isEqualTo: listId).limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data() as Map<String, dynamic>;
        data.remove('updatedAt'); // Remove Firestore-specific field
        return WordList.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting word list: $e');
      return null;
    }
  }

  // Word list entries
  @override
  Future<bool> addWordToList(int listId, WordEntry wordEntry) async {
    try {
      await _wordListEntriesCollection.add({
        'listId': listId,
        'wordSlug': wordEntry.slug,
        'wordData': wordEntry.toJson(),
        'addedAt': FieldValue.serverTimestamp(),
        'position': 0, // Will be updated based on current count
      });
      
      // Update word count in the list
      final listSnapshot = await _wordListsCollection.where('id', isEqualTo: listId).limit(1).get();
      if (listSnapshot.docs.isNotEmpty) {
        await listSnapshot.docs.first.reference.update({
          'wordCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      return true;
    } catch (e) {
      print('Error adding word to list: $e');
      return false;
    }
  }

  @override
  Future<bool> removeWordFromList(int listId, String wordSlug) async {
    try {
      final snapshot = await _wordListEntriesCollection
          .where('listId', isEqualTo: listId)
          .where('wordSlug', isEqualTo: wordSlug)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.delete();
        
        // Update word count in the list
        final listSnapshot = await _wordListsCollection.where('id', isEqualTo: listId).limit(1).get();
        if (listSnapshot.docs.isNotEmpty) {
          await listSnapshot.docs.first.reference.update({
            'wordCount': FieldValue.increment(-1),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        
        return true;
      }
      return false;
    } catch (e) {
      print('Error removing word from list: $e');
      return false;
    }
  }

  @override
  Future<List<WordEntry>> getWordsInList(int listId) async {
    try {
      final snapshot = await _wordListEntriesCollection
          .where('listId', isEqualTo: listId)
          .orderBy('addedAt')
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return WordEntry.fromJson(data['wordData'] as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('Error getting words in list: $e');
      return [];
    }
  }

  @override
  Future<List<WordEntry>> getAllWordsInLists(List<int> listIds) async {
    try {
      final snapshot = await _wordListEntriesCollection
          .where('listId', whereIn: listIds)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return WordEntry.fromJson(data['wordData'] as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('Error getting words in lists: $e');
      return [];
    }
  }

  @override
  Future<List<int>> getListsContainingWord(String wordSlug) async {
    try {
      final snapshot = await _wordListEntriesCollection.where('wordSlug', isEqualTo: wordSlug).get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['listId'] as int;
      }).toList();
    } catch (e) {
      print('Error getting lists containing word: $e');
      return [];
    }
  }

  // Create flashcard from word in lists
  @override
  Future<bool> createFlashcardFromWord(String wordSlug, List<int> listIds, WordEntry wordEntry) async {
    try {
      final flashcardId = '${wordEntry.slug}_${DateTime.now().millisecondsSinceEpoch}';
      final flashcard = EnhancedFlashcard.fromWordEntry(flashcardId, wordEntry, listIds);
      return await saveFlashcard(flashcard);
    } catch (e) {
      print('Error creating flashcard from word: $e');
      return false;
    }
  }

  @override
  Future<bool> addFlashcardToLists(String flashcardId, List<int> listIds) async {
    try {
      await _flashcardsCollection.doc(flashcardId).update({
        'listIds': FieldValue.arrayUnion(listIds),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error adding flashcard to lists: $e');
      return false;
    }
  }

  @override
  Future<bool> removeFlashcardFromList(String flashcardId, int listId) async {
    try {
      await _flashcardsCollection.doc(flashcardId).update({
        'listIds': FieldValue.arrayRemove([listId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error removing flashcard from list: $e');
      return false;
    }
  }

  // User progress and statistics
  @override
  Future<bool> saveUserProgress(UserProgress progress) async {
    try {
      await _userProgressDoc.set(progress.toJson(), SetOptions(merge: true));
      return true;
    } catch (e) {
      print('Error saving user progress: $e');
      return false;
    }
  }

  @override
  Future<UserProgress?> getUserProgress() async {
    try {
      final doc = await _userProgressDoc.get();
      if (doc.exists) {
        return UserProgress.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting user progress: $e');
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
      await _studySessionsCollection.doc(session.id).set({
        ...session.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error saving study session: $e');
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
      Query query = _studySessionsCollection.orderBy('createdAt', descending: true);
      
      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }
      if (limit != null) {
        query = query.limit(limit);
      }
      
      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data.remove('createdAt'); // Remove Firestore-specific field
        return StudySession.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error getting study sessions: $e');
      return [];
    }
  }

  @override
  Future<StudySession?> getStudySession(String sessionId) async {
    try {
      final doc = await _studySessionsCollection.doc(sessionId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data.remove('createdAt'); // Remove Firestore-specific field
        return StudySession.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting study session: $e');
      return null;
    }
  }

  @override
  Future<StudySessionStats> getStudySessionStats() async {
    try {
      final snapshot = await _studySessionsCollection.get();
      final sessions = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data.remove('createdAt'); // Remove Firestore-specific field
        return StudySession.fromJson(data);
      }).toList();
      
      return StudySessionStats.fromStudySessions(sessions);
    } catch (e) {
      print('Error getting study session stats: $e');
      return const StudySessionStats();
    }
  }

  // Analytics and reporting
  @override
  Future<Map<String, dynamic>> getFlashcardStats() async {
    try {
      final snapshot = await _flashcardsCollection.get();
      final flashcards = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      
      final totalCards = flashcards.length;
      final dueCards = flashcards.where((f) {
        final nextReview = f['nextReview'] as Timestamp?;
        return nextReview != null && nextReview.toDate().isBefore(DateTime.now());
      }).length;
      final learningCards = flashcards.where((f) => f['isLearning'] == true).length;
      final masteredCards = flashcards.where((f) => f['repetitions'] != null && f['repetitions'] >= 5).length;
      
      return {
        'totalCards': totalCards,
        'dueCards': dueCards,
        'learningCards': learningCards,
        'masteredCards': masteredCards,
        'reviewedToday': 0, // Would need to track daily reviews
      };
    } catch (e) {
      print('Error getting flashcard stats: $e');
      return {};
    }
  }

  @override
  Future<Map<String, dynamic>> getWordListStats() async {
    try {
      final snapshot = await _wordListsCollection.get();
      final lists = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      
      final totalLists = lists.length;
      final totalWords = lists.fold<int>(0, (sum, list) => sum + ((list['wordCount'] as int?) ?? 0));
      
      return {
        'totalLists': totalLists,
        'totalWords': totalWords,
        'averageWordsPerList': totalLists > 0 ? totalWords / totalLists : 0,
      };
    } catch (e) {
      print('Error getting word list stats: $e');
      return {};
    }
  }

  @override
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final progress = await getUserProgress();
      final flashcardStats = await getFlashcardStats();
      final wordListStats = await getWordListStats();
      
      return {
        'userProgress': progress?.toJson() ?? {},
        'flashcards': flashcardStats,
        'wordLists': wordListStats,
      };
    } catch (e) {
      print('Error getting user stats: $e');
      return {};
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getDailyStats(DateTime startDate, DateTime endDate) async {
    try {
      final sessions = await getStudySessions(startDate: startDate, endDate: endDate);
      
      final dailyStats = <String, Map<String, dynamic>>{};
      
      for (final session in sessions) {
        final dateKey = session.startTime.toIso8601String().split('T')[0];
        if (!dailyStats.containsKey(dateKey)) {
          dailyStats[dateKey] = {
            'date': dateKey,
            'sessionsCount': 0,
            'totalDuration': 0,
            'cardsReviewed': 0,
            'averageScore': 0.0,
          };
        }
        
        final stats = dailyStats[dateKey]!;
        stats['sessionsCount'] = (stats['sessionsCount'] as int) + 1;
        stats['totalDuration'] = (stats['totalDuration'] as int) + session.duration.inMinutes;
        stats['cardsReviewed'] = (stats['cardsReviewed'] as int) + session.totalCards;
      }
      
      return dailyStats.values.toList()..sort((a, b) => a['date'].compareTo(b['date']));
    } catch (e) {
      print('Error getting daily stats: $e');
      return [];
    }
  }

  // Data management
  @override
  Future<Map<String, dynamic>> exportAllData() async {
    try {
      final favorites = await getFavorites();
      final flashcards = await getAllFlashcards();
      final wordLists = await getAllWordLists();
      final progress = await getUserProgress();
      final sessions = await getStudySessions();
      
      return {
        'favorites': favorites.map((f) => f.toJson()).toList(),
        'flashcards': flashcards.map((f) => f.toJson()).toList(),
        'wordLists': wordLists.map((l) => l.toJson()).toList(),
        'userProgress': progress?.toJson(),
        'studySessions': sessions.map((s) => s.toJson()).toList(),
        'exportedAt': DateTime.now().toIso8601String(),
        'userId': _userId,
      };
    } catch (e) {
      print('Error exporting data: $e');
      return {};
    }
  }

  @override
  Future<bool> importAllData(Map<String, dynamic> data) async {
    try {
      // This would be used for data migration from local storage
      // Implementation would depend on the specific data structure
      return true;
    } catch (e) {
      print('Error importing data: $e');
      return false;
    }
  }

  @override
  Future<bool> clearAllData() async {
    try {
      final batch = _firestore.batch();
      
      // Delete all collections for this user
      final collections = [
        _favoritesCollection,
        _flashcardsCollection,
        _wordListsCollection,
        _wordListEntriesCollection,
        _studySessionsCollection,
      ];
      
      for (final collection in collections) {
        final snapshot = await collection.get();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
      }
      
      // Delete user progress
      batch.delete(_userProgressDoc);
      
      await batch.commit();
      return true;
    } catch (e) {
      print('Error clearing data: $e');
      return false;
    }
  }

  // Maintenance operations
  @override
  Future<bool> optimizeDatabase() async {
    // Firestore is automatically optimized
    return true;
  }

  @override
  Future<int> getDatabaseSize() async {
    // This would require aggregating document sizes
    // Not easily available in Firestore without specific tracking
    return 0;
  }

  @override
  Future<bool> validateDataIntegrity() async {
    try {
      // Perform basic integrity checks
      final flashcards = await getAllFlashcards();
      final wordLists = await getAllWordLists();
      
      // Check if all flashcard list references are valid
      final validListIds = wordLists.map((l) => l.id).toSet();
      for (final flashcard in flashcards) {
        for (final listId in flashcard.wordListIds) {
          if (!validListIds.contains(listId)) {
            print('Warning: Flashcard ${flashcard.id} references invalid list $listId');
          }
        }
      }
      
      return true;
    } catch (e) {
      print('Error validating data integrity: $e');
      return false;
    }
  }
}