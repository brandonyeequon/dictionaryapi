import '../../models/word_entry.dart';
import '../../models/enhanced_flashcard.dart';
import '../../models/user_progress.dart';
import '../../models/study_session.dart';
import '../../models/word_list.dart';
import '../../models/word_mastery.dart';

/// Enhanced storage interface for the advanced flashcard system
/// Supports list-based flashcards, user progress tracking, and study sessions
abstract class EnhancedStorageInterface {
  Future<void> initialize();
  Future<void> close();

  // Favorites operations (unchanged)
  Future<bool> addToFavorites(WordEntry wordEntry);
  Future<bool> removeFromFavorites(String slug);
  Future<bool> isFavorite(String slug);
  Future<List<WordEntry>> getFavorites();

  // Enhanced flashcard operations
  Future<bool> saveFlashcard(EnhancedFlashcard flashcard);
  Future<bool> updateFlashcard(EnhancedFlashcard flashcard);
  Future<bool> removeFlashcard(String flashcardId);
  Future<List<EnhancedFlashcard>> getAllFlashcards();
  Future<EnhancedFlashcard?> getFlashcard(String flashcardId);
  Future<EnhancedFlashcard?> getFlashcardByWordSlug(String wordSlug);
  Future<bool> hasFlashcard(String wordSlug);
  
  // List-based flashcard queries
  Future<List<EnhancedFlashcard>> getFlashcardsInList(int listId);
  Future<List<EnhancedFlashcard>> getFlashcardsInLists(List<int> listIds);
  Future<List<EnhancedFlashcard>> getDueFlashcards();
  Future<List<EnhancedFlashcard>> getDueFlashcardsInList(int listId);
  Future<List<EnhancedFlashcard>> getNewFlashcards();
  Future<List<EnhancedFlashcard>> getFlashcardsByMastery(MasteryLevel level);
  
  // Word list operations
  Future<int> createWordList(String name, {String? description});
  Future<bool> updateWordList(WordList wordList);
  Future<bool> deleteWordList(int listId);
  Future<List<WordList>> getAllWordLists();
  Future<WordList?> getWordList(int listId);
  
  // Word list entries
  Future<bool> addWordToList(int listId, WordEntry wordEntry);
  Future<bool> removeWordFromList(int listId, String wordSlug);
  Future<List<WordEntry>> getWordsInList(int listId);
  Future<List<WordEntry>> getAllWordsInLists(List<int> listIds);
  Future<List<int>> getListsContainingWord(String wordSlug);
  
  // Create flashcard from word in lists
  Future<bool> createFlashcardFromWord(String wordSlug, List<int> listIds, WordEntry wordEntry);
  Future<bool> addFlashcardToLists(String flashcardId, List<int> listIds);
  Future<bool> removeFlashcardFromList(String flashcardId, int listId);
  
  // User progress and statistics
  Future<bool> saveUserProgress(UserProgress progress);
  Future<UserProgress?> getUserProgress();
  Future<bool> updateUserProgress(UserProgress progress);
  
  // Study session operations
  Future<bool> saveStudySession(StudySession session);
  Future<bool> updateStudySession(StudySession session);
  Future<List<StudySession>> getStudySessions({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  });
  Future<StudySession?> getStudySession(String sessionId);
  Future<StudySessionStats> getStudySessionStats();
  
  // Analytics and reporting
  Future<Map<String, dynamic>> getFlashcardStats();
  Future<Map<String, dynamic>> getWordListStats();
  Future<Map<String, dynamic>> getUserStats();
  Future<List<Map<String, dynamic>>> getDailyStats(DateTime startDate, DateTime endDate);
  
  // Data management
  Future<Map<String, dynamic>> exportAllData();
  Future<bool> importAllData(Map<String, dynamic> data);
  Future<bool> clearAllData();
  
  // Maintenance operations
  Future<bool> optimizeDatabase();
  Future<int> getDatabaseSize();
  Future<bool> validateDataIntegrity();
}