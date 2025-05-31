import '../../models/word_entry.dart';
import '../../models/flashcard.dart';
import '../../models/enhanced_flashcard.dart';
import 'storage_interface.dart';
import 'firestore_storage.dart';

/// Firebase storage adapter that implements the basic StorageInterface
/// This provides backward compatibility for services that expect the basic interface
class FirebaseBasicStorage implements StorageInterface {
  final FirestoreStorage _firestoreStorage = FirestoreStorage();

  @override
  Future<void> initialize() async {
    await _firestoreStorage.initialize();
  }

  @override
  Future<void> close() async {
    await _firestoreStorage.close();
  }

  // Favorites operations - delegate directly
  @override
  Future<bool> addToFavorites(WordEntry wordEntry) {
    return _firestoreStorage.addToFavorites(wordEntry);
  }

  @override
  Future<bool> removeFromFavorites(String slug) {
    return _firestoreStorage.removeFromFavorites(slug);
  }

  @override
  Future<bool> isFavorite(String slug) {
    return _firestoreStorage.isFavorite(slug);
  }

  @override
  Future<List<WordEntry>> getFavorites() {
    return _firestoreStorage.getFavorites();
  }

  // Flashcard operations - convert between basic and enhanced flashcards
  @override
  Future<bool> addFlashcard(Flashcard flashcard) async {
    // Convert basic flashcard to enhanced flashcard
    final enhancedCard = _convertBasicToEnhanced(flashcard);
    return await _firestoreStorage.saveFlashcard(enhancedCard);
  }

  @override
  Future<bool> updateFlashcard(Flashcard flashcard) async {
    // Convert basic flashcard to enhanced flashcard
    final enhancedCard = _convertBasicToEnhanced(flashcard);
    return await _firestoreStorage.updateFlashcard(enhancedCard);
  }

  @override
  Future<bool> removeFlashcard(String flashcardId) {
    return _firestoreStorage.removeFlashcard(flashcardId);
  }

  @override
  Future<List<Flashcard>> getFlashcards() async {
    final enhancedCards = await _firestoreStorage.getAllFlashcards();
    return enhancedCards.map(_convertEnhancedToBasic).toList();
  }

  @override
  Future<Flashcard?> getFlashcard(String flashcardId) async {
    final enhancedCard = await _firestoreStorage.getFlashcard(flashcardId);
    return enhancedCard != null ? _convertEnhancedToBasic(enhancedCard) : null;
  }

  @override
  Future<bool> hasFlashcard(String wordSlug) {
    return _firestoreStorage.hasFlashcard(wordSlug);
  }

  // Word list operations - delegate to enhanced interface
  @override
  Future<int> createWordList(String name, {String? description}) {
    return _firestoreStorage.createWordList(name, description: description);
  }

  @override
  Future<List<Map<String, dynamic>>> getWordLists() async {
    final wordLists = await _firestoreStorage.getAllWordLists();
    return wordLists.map((list) => list.toJson()).toList();
  }

  @override
  Future<bool> addWordToList(int listId, WordEntry wordEntry) {
    return _firestoreStorage.addWordToList(listId, wordEntry);
  }

  @override
  Future<List<WordEntry>> getWordsInList(int listId) {
    return _firestoreStorage.getWordsInList(listId);
  }

  @override
  Future<bool> removeWordFromList(int listId, String slug) {
    return _firestoreStorage.removeWordFromList(listId, slug);
  }

  @override
  Future<bool> deleteWordList(int listId) {
    return _firestoreStorage.deleteWordList(listId);
  }

  /// Convert basic Flashcard to EnhancedFlashcard
  EnhancedFlashcard _convertBasicToEnhanced(Flashcard basic) {
    return EnhancedFlashcard(
      id: basic.id,
      wordSlug: basic.wordSlug,
      word: basic.word,
      reading: basic.reading,
      definition: basic.definition,
      tags: basic.tags,
      wordListIds: [], // Basic flashcards don't have word list associations
      createdAt: basic.createdAt,
      lastReviewed: basic.lastReviewed,
      nextReview: basic.nextReview,
      intervalHours: _convertDaysToHours(basic.intervalDays),
      easeFactor: basic.easeFactor,
      repetitions: basic.repetitions,
      reviewHistory: [],
    );
  }

  /// Convert EnhancedFlashcard to basic Flashcard
  Flashcard _convertEnhancedToBasic(EnhancedFlashcard enhanced) {
    return Flashcard(
      id: enhanced.id,
      wordSlug: enhanced.wordSlug,
      word: enhanced.word,
      reading: enhanced.reading,
      definition: enhanced.definition,
      tags: enhanced.tags,
      createdAt: enhanced.createdAt,
      lastReviewed: enhanced.lastReviewed,
      nextReview: enhanced.nextReview,
      intervalDays: _convertHoursToDays(enhanced.intervalHours),
      easeFactor: enhanced.easeFactor,
      repetitions: enhanced.repetitions,
      isLearning: enhanced.masteryLevel.level <= 2, // Approximate learning status
    );
  }

  /// Convert days to hours (basic uses days, enhanced uses hours)
  int _convertDaysToHours(int days) {
    return days * 24;
  }

  /// Convert hours to days (enhanced uses hours, basic uses days)
  int _convertHoursToDays(int hours) {
    return (hours / 24).round();
  }
}