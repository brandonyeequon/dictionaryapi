import 'package:flutter/material.dart';
import '../models/flashcard.dart';
import '../models/study_mode.dart';
import '../services/flashcard_service.dart';

class StudySessionScreen extends StatefulWidget {
  final StudyMode mode;

  const StudySessionScreen({super.key, required this.mode});

  @override
  State<StudySessionScreen> createState() => _StudySessionScreenState();
}

class _StudySessionScreenState extends State<StudySessionScreen> {
  final FlashcardService _flashcardService = FlashcardService();
  List<Flashcard> _sessionCards = [];
  int _currentIndex = 0;
  bool _showAnswer = false;
  int _studiedCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  void _initializeSession() {
    switch (widget.mode) {
      case StudyMode.review:
        _sessionCards = _flashcardService.dueFlashcards;
        break;
      case StudyMode.all:
        _sessionCards = List.from(_flashcardService.flashcards);
        _sessionCards.shuffle();
        break;
    }
  }

  Flashcard? get _currentCard => 
      _currentIndex < _sessionCards.length ? _sessionCards[_currentIndex] : null;

  bool get _isSessionComplete => _currentIndex >= _sessionCards.length;

  @override
  Widget build(BuildContext context) {
    if (_sessionCards.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Study Session'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(
          child: Text('No cards available for study'),
        ),
      );
    }

    if (_isSessionComplete) {
      return _buildSessionComplete();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Study Session (${_currentIndex + 1}/${_sessionCards.length})'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _showSessionStats,
            icon: const Icon(Icons.info),
          ),
        ],
      ),
      body: _buildStudyCard(),
    );
  }

  Widget _buildStudyCard() {
    final card = _currentCard!;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _sessionCards.length,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          
          // Card content
          Expanded(
            child: Card(
              elevation: 8,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Question side
                    Text(
                      card.word,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      card.reading,
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Answer side (conditional)
                    if (_showAnswer) ...[
                      const Divider(thickness: 2),
                      const SizedBox(height: 24),
                      Text(
                        card.definition,
                        style: const TextStyle(
                          fontSize: 18,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      _buildDifficultyButtons(),
                    ] else ...[
                      ElevatedButton(
                        onPressed: () => setState(() => _showAnswer = true),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                        child: const Text(
                          'Show Answer',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          
          // Bottom info
          if (_showAnswer) _buildCardInfo(card),
        ],
      ),
    );
  }

  Widget _buildDifficultyButtons() {
    return Column(
      children: [
        const Text(
          'How difficult was this card?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _reviewCard(ReviewDifficulty.again),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Again'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _reviewCard(ReviewDifficulty.hard),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Hard'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _reviewCard(ReviewDifficulty.good),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Good'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _reviewCard(ReviewDifficulty.easy),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Easy'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardInfo(Flashcard card) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem('Reps', card.repetitions.toString()),
          _buildInfoItem('Ease', card.easeFactorAsDouble.toStringAsFixed(1)),
          _buildInfoItem('Interval', '${card.intervalDays}d'),
          _buildInfoItem('Type', card.isLearning ? 'Learning' : 'Review'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSessionComplete() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Complete'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.celebration,
                size: 80,
                color: Colors.green,
              ),
              const SizedBox(height: 24),
              const Text(
                'Great job!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'You studied $_studiedCount cards',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.home),
                label: const Text('Back to Flashcards'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _reviewCard(ReviewDifficulty difficulty) async {
    final card = _currentCard!;
    
    // Update the flashcard in the service
    await _flashcardService.reviewFlashcard(card.id, difficulty);
    
    // Move to next card
    setState(() {
      _currentIndex++;
      _showAnswer = false;
      _studiedCount++;
    });
  }

  void _showSessionStats() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Session Progress'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Cards studied: $_studiedCount'),
            Text('Cards remaining: ${_sessionCards.length - _currentIndex}'),
            Text('Total cards: ${_sessionCards.length}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('End Session'),
          ),
        ],
      ),
    );
  }
}