import 'package:flutter/foundation.dart';
import '../models/word_entry.dart';
import '../models/word_list.dart';
import 'storage/storage_interface.dart';
import 'storage/storage_factory.dart';

class WordListService extends ChangeNotifier {
  static final WordListService _instance = WordListService._internal();
  factory WordListService() => _instance;
  WordListService._internal();

  final List<WordList> _wordLists = [];
  final Map<int, List<WordEntry>> _listWords = {};
  bool _isLoaded = false;
  late final StorageInterface _storage;

  bool get isLoaded => _isLoaded;
  List<WordList> get wordLists => List.unmodifiable(_wordLists);
  int get totalLists => _wordLists.length;

  Future<void> loadWordLists() async {
    if (_isLoaded) return;

    try {
      _storage = StorageFactory.createStorage();
      await _storage.initialize();
      
      final listData = await _storage.getWordLists();
      _wordLists.clear();
      _listWords.clear();
      
      for (final data in listData) {
        final wordList = WordList.fromJson(data);
        _wordLists.add(wordList);
        
        // Load words for each list
        final words = await _storage.getWordsInList(wordList.id);
        _listWords[wordList.id] = words;
      }
      
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading word lists: $e');
    }
  }

  Future<bool> createWordList(String name, {String? description}) async {
    try {
      if (!_isLoaded) await loadWordLists();
      
      final id = await _storage.createWordList(name, description: description);
      if (id > 0) {
        final wordList = WordList(
          id: id,
          name: name,
          description: description,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        _wordLists.add(wordList);
        _listWords[id] = [];
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error creating word list: $e');
      return false;
    }
  }

  Future<bool> deleteWordList(int listId) async {
    try {
      if (!_isLoaded) await loadWordLists();
      
      final success = await _storage.deleteWordList(listId);
      if (success) {
        _wordLists.removeWhere((list) => list.id == listId);
        _listWords.remove(listId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('Error deleting word list: $e');
      return false;
    }
  }

  Future<bool> addWordToList(int listId, WordEntry wordEntry) async {
    try {
      if (!_isLoaded) await loadWordLists();
      
      // Check if word already exists in list
      final existingWords = _listWords[listId] ?? [];
      if (existingWords.any((word) => word.slug == wordEntry.slug)) {
        return false; // Word already in list
      }
      
      final success = await _storage.addWordToList(listId, wordEntry);
      if (success) {
        _listWords[listId] = [...existingWords, wordEntry];
        
        // Update the list's updated time
        final listIndex = _wordLists.indexWhere((list) => list.id == listId);
        if (listIndex != -1) {
          _wordLists[listIndex] = _wordLists[listIndex].copyWith(
            updatedAt: DateTime.now(),
          );
        }
        
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('Error adding word to list: $e');
      return false;
    }
  }

  Future<bool> removeWordFromList(int listId, String wordSlug) async {
    try {
      if (!_isLoaded) await loadWordLists();
      
      final success = await _storage.removeWordFromList(listId, wordSlug);
      if (success) {
        final existingWords = _listWords[listId] ?? [];
        _listWords[listId] = existingWords.where((word) => word.slug != wordSlug).toList();
        
        // Update the list's updated time
        final listIndex = _wordLists.indexWhere((list) => list.id == listId);
        if (listIndex != -1) {
          _wordLists[listIndex] = _wordLists[listIndex].copyWith(
            updatedAt: DateTime.now(),
          );
        }
        
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('Error removing word from list: $e');
      return false;
    }
  }

  List<WordEntry> getWordsInList(int listId) {
    return List.unmodifiable(_listWords[listId] ?? []);
  }

  int getWordCountInList(int listId) {
    return _listWords[listId]?.length ?? 0;
  }

  bool isWordInList(int listId, String wordSlug) {
    final words = _listWords[listId] ?? [];
    return words.any((word) => word.slug == wordSlug);
  }

  WordList? getWordList(int listId) {
    try {
      return _wordLists.firstWhere((list) => list.id == listId);
    } catch (e) {
      return null;
    }
  }

  Future<void> refreshWordLists() async {
    _isLoaded = false;
    await loadWordLists();
  }
}