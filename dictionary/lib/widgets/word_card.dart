import 'package:flutter/material.dart';
import '../models/word_entry.dart';
import '../services/favorites_service.dart';

class WordCard extends StatefulWidget {
  final WordEntry wordEntry;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;

  const WordCard({
    super.key,
    required this.wordEntry,
    this.onTap,
    this.onFavorite,
  });

  @override
  State<WordCard> createState() => _WordCardState();
}

class _WordCardState extends State<WordCard> {
  final FavoritesService _favoritesService = FavoritesService();

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
    await _favoritesService.toggleFavorite(widget.wordEntry);
    if (widget.onFavorite != null) {
      widget.onFavorite!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildWordHeader(),
                  ),
                  IconButton(
                    onPressed: _toggleFavorite,
                    icon: Icon(
                      _favoritesService.isFavorite(widget.wordEntry.slug)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: _favoritesService.isFavorite(widget.wordEntry.slug)
                          ? Colors.red
                          : Colors.grey[600],
                    ),
                    iconSize: 20,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildDefinitions(),
              if (widget.wordEntry.isCommon || widget.wordEntry.jlpt.isNotEmpty || widget.wordEntry.tags.isNotEmpty)
                const SizedBox(height: 8),
              _buildTags(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWordHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (widget.wordEntry.mainWord.isNotEmpty)
              Text(
                widget.wordEntry.mainWord,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            if (widget.wordEntry.mainWord != widget.wordEntry.mainReading && widget.wordEntry.mainReading.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  '【${widget.wordEntry.mainReading}】',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDefinitions() {
    final definitions = widget.wordEntry.allDefinitions.take(3).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: definitions.asMap().entries.map((entry) {
        final index = entry.key;
        final definition = entry.value;
        
        return Padding(
          padding: EdgeInsets.only(bottom: index < definitions.length - 1 ? 4 : 0),
          child: Text(
            '${index + 1}. $definition',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTags() {
    final tags = <Widget>[];

    if (widget.wordEntry.isCommon) {
      tags.add(_buildTag('Common', Colors.green));
    }

    for (final jlpt in widget.wordEntry.jlpt) {
      tags.add(_buildTag(jlpt.toUpperCase(), Colors.blue));
    }

    for (final tag in widget.wordEntry.tags.take(2)) {
      if (tag.startsWith('wanikani')) {
        tags.add(_buildTag('WK', Colors.purple));
      }
    }

    if (tags.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: tags,
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}