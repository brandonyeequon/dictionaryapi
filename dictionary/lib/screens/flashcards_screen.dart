import 'package:flutter/material.dart';
import '../models/flashcard.dart';
import '../models/study_mode.dart';
import '../services/flashcard_service.dart';
import 'study_session_screen.dart';

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  final FlashcardService _flashcardService = FlashcardService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFlashcards();
    _flashcardService.addListener(_onFlashcardsChanged);
  }

  @override
  void dispose() {
    _flashcardService.removeListener(_onFlashcardsChanged);
    super.dispose();
  }

  void _onFlashcardsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadFlashcards() async {
    setState(() => _isLoading = true);
    await _flashcardService.loadFlashcards();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcards'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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

    if (_flashcardService.totalFlashcards == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No flashcards yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add words to flashcards from word details',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStudyOptions(),
          const SizedBox(height: 24),
          _buildStatistics(),
          const SizedBox(height: 24),
          _buildFlashcardsList(),
        ],
      ),
    );
  }

  Widget _buildStudyOptions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Study Session',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _flashcardService.dueCount > 0
                        ? () => _startStudySession(StudyMode.review)
                        : null,
                    icon: const Icon(Icons.refresh),
                    label: Text('Review (${_flashcardService.dueCount})'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _flashcardService.totalFlashcards > 0
                        ? () => _startStudySession(StudyMode.all)
                        : null,
                    icon: const Icon(Icons.school),
                    label: const Text('Study All'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Cards',
                    _flashcardService.totalFlashcards.toString(),
                    Icons.quiz,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Due Today',
                    _flashcardService.dueCount.toString(),
                    Icons.schedule,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Learning',
                    _flashcardService.learningFlashcards.length.toString(),
                    Icons.school,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Review',
                    _flashcardService.reviewFlashcards.length.toString(),
                    Icons.check_circle,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashcardsList() {
    final dueCards = _flashcardService.dueFlashcards;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Due for Review',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (dueCards.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 12),
                const Text(
                  'All caught up! No cards due for review.',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          )
        else
          ...dueCards.take(5).map((card) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildFlashcardTile(card),
          )),
        if (dueCards.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'And ${dueCards.length - 5} more...',
              style: TextStyle(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFlashcardTile(Flashcard card) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: card.isLearning ? Colors.green : Colors.blue,
          child: Icon(
            card.isLearning ? Icons.school : Icons.refresh,
            color: Colors.white,
          ),
        ),
        title: Text(
          card.word,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(card.reading),
            Text(
              card.definition,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: Text(
          _getTimeUntilDue(card.nextReview),
          style: TextStyle(
            color: card.isDueForReview ? Colors.red : Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: () => _showCardDetail(card),
      ),
    );
  }

  String _getTimeUntilDue(DateTime nextReview) {
    final now = DateTime.now();
    final difference = nextReview.difference(now);
    
    if (difference.isNegative) {
      return 'Overdue';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inMinutes}m';
    }
  }

  void _startStudySession(StudyMode mode) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StudySessionScreen(mode: mode),
      ),
    );
  }

  void _showCardDetail(Flashcard card) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(card.word),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reading: ${card.reading}'),
            const SizedBox(height: 8),
            Text('Definition: ${card.definition}'),
            const SizedBox(height: 8),
            Text('Repetitions: ${card.repetitions}'),
            Text('Ease Factor: ${card.easeFactorAsDouble.toStringAsFixed(2)}'),
            Text('Interval: ${card.intervalDays} days'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _removeFlashcard(card);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeFlashcard(Flashcard card) async {
    final success = await _flashcardService.removeFlashcard(card.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed "${card.word}" from flashcards'),
        ),
      );
    }
  }
}