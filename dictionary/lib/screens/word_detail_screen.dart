import 'package:flutter/material.dart';
import '../models/word_entry.dart';
import '../models/word_list.dart';
import '../services/favorites_service.dart';
import '../services/flashcard_service.dart';
import '../services/word_list_service.dart';

class WordDetailScreen extends StatefulWidget {
  final WordEntry wordEntry;

  const WordDetailScreen({super.key, required this.wordEntry});

  @override
  State<WordDetailScreen> createState() => _WordDetailScreenState();
}

class _WordDetailScreenState extends State<WordDetailScreen> {
  final FavoritesService _favoritesService = FavoritesService();
  final FlashcardService _flashcardService = FlashcardService();
  final WordListService _wordListService = WordListService();
  bool _isLoading = false;
  bool _isFlashcardLoading = false;

  @override
  void initState() {
    super.initState();
    _favoritesService.addListener(_onFavoritesChanged);
    _flashcardService.addListener(_onFlashcardsChanged);
    _wordListService.addListener(_onWordListsChanged);
    _loadServices();
  }

  @override
  void dispose() {
    _favoritesService.removeListener(_onFavoritesChanged);
    _flashcardService.removeListener(_onFlashcardsChanged);
    _wordListService.removeListener(_onWordListsChanged);
    super.dispose();
  }

  void _onFavoritesChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onFlashcardsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onWordListsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadServices() async {
    await _favoritesService.loadFavorites();
    await _flashcardService.loadFlashcards();
    await _wordListService.loadWordLists();
  }

  Future<void> _toggleFavorite() async {
    setState(() => _isLoading = true);
    
    final success = await _favoritesService.toggleFavorite(widget.wordEntry);
    
    if (mounted) {
      setState(() => _isLoading = false);
      
      if (success) {
        final isFavorite = _favoritesService.isFavorite(widget.wordEntry.slug);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFavorite 
                  ? 'Added "${widget.wordEntry.mainWord}" to favorites'
                  : 'Removed "${widget.wordEntry.mainWord}" from favorites',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _toggleFlashcard() async {
    setState(() => _isFlashcardLoading = true);
    
    bool success;
    final hasFlashcard = _flashcardService.hasFlashcard(widget.wordEntry.slug);
    
    if (hasFlashcard) {
      final flashcard = _flashcardService.getFlashcard(widget.wordEntry.slug);
      success = await _flashcardService.removeFlashcard(flashcard!.id);
    } else {
      success = await _flashcardService.addFlashcard(widget.wordEntry);
    }
    
    if (mounted) {
      setState(() => _isFlashcardLoading = false);
      
      if (success) {
        final isNowFlashcard = _flashcardService.hasFlashcard(widget.wordEntry.slug);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isNowFlashcard 
                  ? 'Added "${widget.wordEntry.mainWord}" to flashcards'
                  : 'Removed "${widget.wordEntry.mainWord}" from flashcards',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.wordEntry.mainWord),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _toggleFavorite,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _favoritesService.isFavorite(widget.wordEntry.slug)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: _favoritesService.isFavorite(widget.wordEntry.slug)
                        ? Colors.red
                        : null,
                  ),
            tooltip: _favoritesService.isFavorite(widget.wordEntry.slug)
                ? 'Remove from favorites'
                : 'Add to favorites',
          ),
          IconButton(
            onPressed: _isFlashcardLoading ? null : _toggleFlashcard,
            icon: _isFlashcardLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _flashcardService.hasFlashcard(widget.wordEntry.slug)
                        ? Icons.quiz
                        : Icons.quiz_outlined,
                    color: _flashcardService.hasFlashcard(widget.wordEntry.slug)
                        ? Colors.green
                        : null,
                  ),
            tooltip: _flashcardService.hasFlashcard(widget.wordEntry.slug)
                ? 'Remove from flashcards'
                : 'Add to flashcards',
          ),
          IconButton(
            onPressed: _showAddToListDialog,
            icon: const Icon(Icons.playlist_add),
            tooltip: 'Add to list',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWordHeader(),
            const SizedBox(height: 24),
            _buildDefinitions(),
            const SizedBox(height: 24),
            _buildTags(),
            if (widget.wordEntry.senses.any((sense) => sense.info.isNotEmpty))
              const SizedBox(height: 24),
            _buildAdditionalInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildWordHeader() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.wordEntry.japanese.isNotEmpty)
              ...widget.wordEntry.japanese.map((reading) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    if (reading.word != null)
                      Text(
                        reading.word!,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    const SizedBox(width: 16),
                    Text(
                      reading.reading,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )),
            if (widget.wordEntry.isCommon || widget.wordEntry.jlpt.isNotEmpty)
              const SizedBox(height: 12),
            _buildHeaderTags(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderTags() {
    final tags = <Widget>[];

    if (widget.wordEntry.isCommon) {
      tags.add(_buildTag('Common word', Colors.green, large: true));
    }

    for (final jlpt in widget.wordEntry.jlpt) {
      tags.add(_buildTag(jlpt.toUpperCase(), Colors.blue, large: true));
    }

    if (tags.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: tags,
    );
  }

  Widget _buildDefinitions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Definitions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ...widget.wordEntry.senses.asMap().entries.map((entry) {
          final index = entry.key;
          final sense = entry.value;
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (sense.partsOfSpeech.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Wrap(
                        spacing: 6,
                        children: sense.partsOfSpeech.map((pos) => 
                          _buildTag(pos, Colors.orange, small: true)
                        ).toList(),
                      ),
                    ),
                  ...sense.englishDefinitions.asMap().entries.map((defEntry) {
                    final defIndex = defEntry.key;
                    final definition = defEntry.value;
                    
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: defIndex < sense.englishDefinitions.length - 1 ? 6 : 0
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 8, top: 2),
                            child: Text(
                              '${index + 1}.${sense.englishDefinitions.length > 1 ? '${defIndex + 1}' : ''}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              definition,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (sense.seeAlso.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'See also: ${sense.seeAlso.join(', ')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  if (sense.source.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Source: ${_formatSource(sense.source)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTags() {
    final allTags = <Widget>[];

    for (final tag in widget.wordEntry.tags) {
      if (tag.startsWith('wanikani')) {
        allTags.add(_buildTag('WaniKani Level ${tag.substring(8)}', Colors.purple));
      } else {
        allTags.add(_buildTag(tag, Colors.grey));
      }
    }

    if (allTags.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tags',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: allTags,
        ),
      ],
    );
  }

  Widget _buildAdditionalInfo() {
    final infoList = widget.wordEntry.senses
        .expand((sense) => sense.info)
        .where((info) => info.isNotEmpty)
        .toList();

    if (infoList.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: infoList.map((info) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(child: Text(info)),
                  ],
                ),
              )).toList(),
            ),
          ),
        ),
      ],
    );
  }

  String _formatSource(List<Map<String, dynamic>> sources) {
    return sources.map((source) {
      if (source.containsKey('language') && source.containsKey('word')) {
        return '${source['language']}: ${source['word']}';
      } else if (source.containsKey('text')) {
        return source['text'];
      } else {
        return source.toString();
      }
    }).join(', ');
  }

  Widget _buildTag(String text, Color color, {bool large = false, bool small = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : (large ? 12 : 8),
        vertical: small ? 2 : (large ? 6 : 4),
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(small ? 4 : (large ? 8 : 6)),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: small ? 10 : (large ? 14 : 12),
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildListTileForDialog(WordList list) {
    final isAlreadyInList = _wordListService.isWordInList(list.id, widget.wordEntry.slug);
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isAlreadyInList ? Colors.grey : Theme.of(context).primaryColor,
        child: Text(
          list.name.substring(0, 1).toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(list.name),
      subtitle: Text('${_wordListService.getWordCountInList(list.id)} words'),
      trailing: isAlreadyInList 
          ? const Icon(Icons.check_circle, color: Colors.green)
          : const Icon(Icons.add_circle_outline),
      enabled: !isAlreadyInList,
      onTap: isAlreadyInList 
          ? null 
          : () => Navigator.of(context).pop(list),
    );
  }

  Future<void> _showAddToListDialog() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Loading lists...'),
            ],
          ),
        ),
      );

      // Ensure word lists are loaded before accessing them
      if (!_wordListService.isLoaded) {
        await _wordListService.loadWordLists();
      }
      
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      final lists = _wordListService.wordLists;
    
    if (lists.isEmpty) {
      // Show dialog to create a list first
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('No Lists Available'),
            content: const Text('You need to create a word list first. Go to the Learn tab to create your first list.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return;
    }

    WordList? selectedList;
    if (mounted) {
      selectedList = await showDialog<WordList>(
        context: context,
        builder: (context) => AlertDialog(
        title: const Text('Add to List'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add "${widget.wordEntry.mainWord}" to which list?'),
              const SizedBox(height: 16),
              if (lists.length > 5)
                SizedBox(
                  height: 300,
                  child: ListView.builder(
                    itemCount: lists.length,
                    itemBuilder: (context, index) => _buildListTileForDialog(lists[index]),
                  ),
                )
              else
                ...lists.map((list) => _buildListTileForDialog(list)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
      );
    }

    if (selectedList != null) {
      final success = await _wordListService.addWordToList(
        selectedList.id,
        widget.wordEntry,
      );
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added "${widget.wordEntry.mainWord}" to "${selectedList.name}"'),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to add word to list'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading lists: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}