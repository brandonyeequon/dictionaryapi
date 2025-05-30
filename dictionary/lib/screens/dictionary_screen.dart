import 'package:flutter/material.dart';
import '../models/word_entry.dart';
import '../services/jisho_api_service.dart';
import '../widgets/word_card.dart';
import '../widgets/search_bar_widget.dart';
import 'word_detail_screen.dart';
import 'favorites_screen.dart';
import 'flashcards_screen.dart';
import 'api_debug_screen.dart';

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<WordEntry> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _lastSearchTerm = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String searchTerm) async {
    if (searchTerm.trim().isEmpty || searchTerm == _lastSearchTerm) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _lastSearchTerm = searchTerm;
    });

    try {
      final response = await JishoApiService.searchWords(searchTerm);
      
      if (response != null && response.isSuccessful) {
        setState(() {
          _searchResults = response.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _searchResults = [];
          _errorMessage = 'No results found for "$searchTerm"';
          _isLoading = false;
        });
      }
    } catch (e) {
      String errorMsg = 'Connection failed';
      final errorStr = e.toString().toLowerCase();
      
      if (errorStr.contains('network') || errorStr.contains('socket')) {
        errorMsg = 'Network connection failed. Please check your internet connection.';
      } else if (errorStr.contains('timeout')) {
        errorMsg = 'Request timed out. Please try again.';
      } else if (errorStr.contains('format')) {
        errorMsg = 'Invalid response from server. Please try again.';
      } else {
        errorMsg = 'Connection failed: ${e.toString().replaceAll('Exception: ', '')}';
      }
      
      setState(() {
        _searchResults = [];
        _errorMessage = errorMsg;
        _isLoading = false;
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _errorMessage = null;
      _lastSearchTerm = '';
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Jisho Dictionary',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const FlashcardsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.quiz),
            tooltip: 'Flashcards',
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const FavoritesScreen(),
                ),
              );
            },
            icon: const Icon(Icons.favorite),
            tooltip: 'Favorites',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'debug') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ApiDebugScreen(),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'debug',
                child: Row(
                  children: [
                    Icon(Icons.bug_report),
                    SizedBox(width: 8),
                    Text('API Debug'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.inversePrimary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: SearchBarWidget(
              controller: _searchController,
              onSearch: _performSearch,
              onClear: _clearSearch,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Searching...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _performSearch(_lastSearchTerm),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty && _lastSearchTerm.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Search for Japanese words, kanji, or English meanings',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching: house, 家, kanji',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No results found for "$_lastSearchTerm"',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final wordEntry = _searchResults[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: WordCard(
            wordEntry: wordEntry,
            onTap: () => _showWordDetails(wordEntry),
          ),
        );
      },
    );
  }

  void _showWordDetails(WordEntry wordEntry) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WordDetailScreen(wordEntry: wordEntry),
      ),
    );
  }
}

