import 'package:flutter/material.dart';
import '../models/word_entry.dart';
import '../services/favorites_service.dart';

class WordDetailScreen extends StatefulWidget {
  final WordEntry wordEntry;

  const WordDetailScreen({super.key, required this.wordEntry});

  @override
  State<WordDetailScreen> createState() => _WordDetailScreenState();
}

class _WordDetailScreenState extends State<WordDetailScreen> {
  final FavoritesService _favoritesService = FavoritesService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _favoritesService.addListener(_onFavoritesChanged);
    _loadFavorites();
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
    await _favoritesService.loadFavorites();
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
            onPressed: () {},
            icon: const Icon(Icons.quiz),
            tooltip: 'Add to flashcards',
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
}