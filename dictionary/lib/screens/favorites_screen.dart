import 'package:flutter/material.dart';
import '../models/word_entry.dart';
import '../services/favorites_service.dart';
import '../widgets/word_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoritesService _favoritesService = FavoritesService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _favoritesService.addListener(_onFavoritesChanged);
  }

  @override
  void dispose() {
    _favoritesService.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _onFavoritesChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    await _favoritesService.loadFavorites();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFavorite(WordEntry wordEntry) async {
    final success = await _favoritesService.removeFavorite(wordEntry.slug);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed "${wordEntry.mainWord}" from favorites'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => _favoritesService.addFavorite(wordEntry),
          ),
        ),
      );
    }
  }

  void _showWordDetails(WordEntry wordEntry) {
    // Temporarily disabled during Jotoba migration
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Word details temporarily unavailable during API migration')),
    );
    // Navigator.of(context).push(
    //   MaterialPageRoute(
    //     builder: (context) => WordDetailScreen(wordEntry: wordEntry),
    //   ),
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_favoritesService.favoritesCount > 0)
            IconButton(
              onPressed: _showClearAllDialog,
              icon: const Icon(Icons.clear_all),
              tooltip: 'Clear all favorites',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_favoritesService.favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No favorite words yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Search for words and add them to favorites',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _favoritesService.favorites.length,
      itemBuilder: (context, index) {
        final wordEntry = _favoritesService.favorites[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: WordCard(
            wordEntry: wordEntry,
            onTap: () => _showWordDetails(wordEntry),
            onFavorite: () => _removeFavorite(wordEntry),
          ),
        );
      },
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear All Favorites'),
          content: Text(
            'Are you sure you want to remove all ${_favoritesService.favoritesCount} favorites? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _clearAllFavorites();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Clear All'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearAllFavorites() async {
    final favorites = List.from(_favoritesService.favorites);
    
    for (final favorite in favorites) {
      await _favoritesService.removeFavorite(favorite.slug);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All favorites cleared'),
        ),
      );
    }
  }
}