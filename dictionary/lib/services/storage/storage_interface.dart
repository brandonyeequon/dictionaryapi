import '../../models/word_entry.dart';
import '../../models/flashcard.dart';

/// Abstract interface for data storage operations
/// Provides platform-agnostic storage for favorites and flashcards
abstract class StorageInterface {
  Future<void> initialize();
  Future<void> close();

  // Favorites operations
  Future<bool> addToFavorites(WordEntry wordEntry);
  Future<bool> removeFromFavorites(String slug);
  Future<bool> isFavorite(String slug);
  Future<List<WordEntry>> getFavorites();

  // Flashcard operations
  Future<bool> addFlashcard(Flashcard flashcard);
  Future<bool> updateFlashcard(Flashcard flashcard);
  Future<bool> removeFlashcard(String flashcardId);
  Future<List<Flashcard>> getFlashcards();
  Future<Flashcard?> getFlashcard(String flashcardId);
  Future<bool> hasFlashcard(String wordSlug);

  // Word lists operations (future extension)
  Future<int> createWordList(String name, {String? description});
  Future<List<Map<String, dynamic>>> getWordLists();
  Future<bool> addWordToList(int listId, WordEntry wordEntry);
  Future<List<WordEntry>> getWordsInList(int listId);
  Future<bool> removeWordFromList(int listId, String slug);
  Future<bool> deleteWordList(int listId);
}