import 'package:flutter/material.dart';
import '../models/word_list.dart';
import '../models/word_entry.dart';
import '../services/word_list_service.dart';
import '../widgets/word_card.dart';
import 'word_detail_screen.dart';
import 'list_study_session_screen.dart';

class WordListDetailScreen extends StatefulWidget {
  final WordList wordList;

  const WordListDetailScreen({super.key, required this.wordList});

  @override
  State<WordListDetailScreen> createState() => _WordListDetailScreenState();
}

class _WordListDetailScreenState extends State<WordListDetailScreen> {
  final WordListService _wordListService = WordListService();
  final bool _isLoading = false;
  List<WordEntry> _words = [];

  @override
  void initState() {
    super.initState();
    _loadWords();
    _wordListService.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _wordListService.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) {
      _loadWords();
    }
  }

  void _loadWords() {
    setState(() {
      _words = _wordListService.getWordsInList(widget.wordList.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.wordList.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'study_normal':
                  _startStudySession(false);
                  break;
                case 'study_spaced':
                  _startStudySession(true);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'study_normal',
                child: Row(
                  children: [
                    Icon(Icons.school),
                    SizedBox(width: 8),
                    Text('Normal Study'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'study_spaced',
                child: Row(
                  children: [
                    Icon(Icons.timeline),
                    SizedBox(width: 8),
                    Text('Spaced Review'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildStudyOptions(),
          const SizedBox(height: 8),
          Expanded(child: _buildWordsList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.inversePrimary.withValues(alpha: 0.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                radius: 20,
                child: Text(
                  widget.wordList.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.wordList.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.wordList.description != null && widget.wordList.description!.isNotEmpty)
                      Text(
                        widget.wordList.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.book, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${_words.length} ${_words.length == 1 ? 'word' : 'words'}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'Updated ${_formatTimeAgo(widget.wordList.updatedAt)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudyOptions() {
    if (_words.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _startStudySession(false),
              icon: const Icon(Icons.school),
              label: const Text('Normal Study'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _startStudySession(true),
              icon: const Icon(Icons.timeline),
              label: const Text('Spaced Review'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_words.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_books,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No words in this list yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add words from the dictionary by searching and tapping the bookmark icon',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _words.length,
      itemBuilder: (context, index) {
        final word = _words[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: WordCard(
            wordEntry: word,
            onTap: () => _showWordDetails(word),
            trailing: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'remove') {
                  await _removeWordFromList(word);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.remove_circle, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Remove from list'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }

  void _showWordDetails(WordEntry wordEntry) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WordDetailScreen(wordEntry: wordEntry),
      ),
    );
  }

  void _startStudySession(bool useSpacedRepetition) {
    if (_words.isEmpty) return;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ListStudySessionScreen(
          wordList: widget.wordList,
          words: _words,
          useSpacedRepetition: useSpacedRepetition,
        ),
      ),
    );
  }

  Future<void> _removeWordFromList(WordEntry wordEntry) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Word'),
        content: Text(
          'Remove "${wordEntry.mainWord}" from "${widget.wordList.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    
    if (result == true) {
      final success = await _wordListService.removeWordFromList(
        widget.wordList.id,
        wordEntry.slug,
      );
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed "${wordEntry.mainWord}" from list'),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to remove word from list'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}