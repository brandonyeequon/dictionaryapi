import 'package:flutter/foundation.dart';
import '../models/word_entry.dart';
import 'storage/storage_interface.dart';
import 'storage/storage_factory.dart';

class FavoritesService extends ChangeNotifier {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  final Set<String> _favoritesSlugs = <String>{};
  List<WordEntry> _favorites = [];
  bool _isLoaded = false;
  late final StorageInterface _storage;

  bool get isLoaded => _isLoaded;
  List<WordEntry> get favorites => List.unmodifiable(_favorites);
  int get favoritesCount => _favorites.length;

  Future<void> loadFavorites() async {
    if (_isLoaded) return;

    try {
      _storage = StorageFactory.createStorage();
      await _storage.initialize();
      
      _favorites = await _storage.getFavorites();
      _favoritesSlugs.clear();
      _favoritesSlugs.addAll(_favorites.map((word) => word.slug));
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }

  bool isFavorite(String slug) {
    return _favoritesSlugs.contains(slug);
  }

  Future<bool> toggleFavorite(WordEntry wordEntry) async {
    if (isFavorite(wordEntry.slug)) {
      return await removeFavorite(wordEntry.slug);
    } else {
      return await addFavorite(wordEntry);
    }
  }

  Future<bool> addFavorite(WordEntry wordEntry) async {
    try {
      if (!_isLoaded) await loadFavorites();
      
      final success = await _storage.addToFavorites(wordEntry);
      if (success) {
        _favoritesSlugs.add(wordEntry.slug);
        _favorites.insert(0, wordEntry);
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('Error adding favorite: $e');
      return false;
    }
  }

  Future<bool> removeFavorite(String slug) async {
    try {
      if (!_isLoaded) await loadFavorites();
      
      final success = await _storage.removeFromFavorites(slug);
      if (success) {
        _favoritesSlugs.remove(slug);
        _favorites.removeWhere((word) => word.slug == slug);
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('Error removing favorite: $e');
      return false;
    }
  }

  Future<void> refreshFavorites() async {
    _isLoaded = false;
    await loadFavorites();
  }
}