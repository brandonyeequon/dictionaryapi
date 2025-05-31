import 'package:flutter/material.dart';
import '../models/word_list.dart';
import '../models/word_entry.dart';
import '../models/jotoba_word_entry.dart'; // Added import
import '../services/flashcard_service.dart';

enum StudyResult { again, hard, good, easy, next }

class ListStudySessionScreen extends StatefulWidget {
  final WordList wordList;
  final List<WordEntry> words;
  final bool useSpacedRepetition;

  const ListStudySessionScreen({
    super.key,
    required this.wordList,
    required this.words,
    required this.useSpacedRepetition,
  });

  @override
  State<ListStudySessionScreen> createState() => _ListStudySessionScreenState();
}

class _ListStudySessionScreenState extends State<ListStudySessionScreen> {
  final FlashcardService _flashcardService = FlashcardService();
  List<WordEntry> _sessionWords = [];
  int _currentIndex = 0;
  bool _showAnswer = false;
  int _studiedCount = 0;
  final Map<String, int> _studyStats = {
    'again': 0,
    'hard': 0,
    'good': 0,
    'easy': 0,
  };

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  void _initializeSession() {
    _sessionWords = List.from(widget.words);
    _sessionWords.shuffle(); // Randomize order for study
  }

  WordEntry? get _currentWord => 
      _currentIndex < _sessionWords.length ? _sessionWords[_currentIndex] : null;

  bool get _isSessionComplete => _currentIndex >= _sessionWords.length;

  @override
  Widget build(BuildContext context) {
    if (_sessionWords.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Study Session'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(
          child: Text('No words available for study'),
        ),
      );
    }

    if (_isSessionComplete) {
      return _buildSessionComplete();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.useSpacedRepetition ? 'Spaced Review' : 'Study'}: ${widget.wordList.name}',
        ),
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
    final word = _currentWord!;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _sessionWords.length,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_currentIndex + 1} of ${_sessionWords.length}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
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
                      word.mainWord,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    if (word.japanese.isNotEmpty)
                      Text(
                        word.japanese.first.reading,
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
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              ...word.senses.take(3).map((sense) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  '• ${sense.englishDefinitions.join(', ')}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      widget.useSpacedRepetition 
                          ? _buildSpacedRepetitionButtons() 
                          : _buildNormalStudyButtons(),
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
        ],
      ),
    );
  }

  Widget _buildSpacedRepetitionButtons() {
    return Column(
      children: [
        const Text(
          'How well did you know this word?',
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
                onPressed: () => _handleSpacedRepetition(ReviewDifficulty.again),
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
                onPressed: () => _handleSpacedRepetition(ReviewDifficulty.hard),
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
                onPressed: () => _handleSpacedRepetition(ReviewDifficulty.good),
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
                onPressed: () => _handleSpacedRepetition(ReviewDifficulty.easy),
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

  Widget _buildNormalStudyButtons() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _nextWord(StudyResult.next),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text(
          'Next Word',
          style: TextStyle(fontSize: 16),
        ),
      ),
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
                'You studied $_studiedCount words from "${widget.wordList.name}"',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (widget.useSpacedRepetition) _buildSessionStats(),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.home),
                label: const Text('Back to List'),
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

  Widget _buildSessionStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Session Stats',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Again', _studyStats['again']!, Colors.red),
                _buildStatItem('Hard', _studyStats['hard']!, Colors.orange),
                _buildStatItem('Good', _studyStats['good']!, Colors.green),
                _buildStatItem('Easy', _studyStats['easy']!, Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
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
    );
  }

  Future<void> _handleSpacedRepetition(ReviewDifficulty difficulty) async {
    final word = _currentWord!;
    
    // Update stats
    switch (difficulty) {
      case ReviewDifficulty.again:
        _studyStats['again'] = (_studyStats['again']! + 1);
        break;
      case ReviewDifficulty.hard:
        _studyStats['hard'] = (_studyStats['hard']! + 1);
        break;
      case ReviewDifficulty.good:
        _studyStats['good'] = (_studyStats['good']! + 1);
        break;
      case ReviewDifficulty.easy:
        _studyStats['easy'] = (_studyStats['easy']! + 1);
        break;
    }

    // Create flashcard if it doesn't exist and add to spaced repetition system
    await _flashcardService.loadFlashcards();
    
    if (!_flashcardService.hasFlashcard(word.slug)) {
      // Convert WordEntry to JotobaWordEntry before adding
      final jotobaEntry = JotobaWordEntry.fromWordEntry(word);
      await _flashcardService.addFlashcard(jotobaEntry);
    }
    
    // Update the flashcard with the review
    final flashcard = _flashcardService.getFlashcard(word.slug);
    if (flashcard != null) {
      await _flashcardService.reviewFlashcard(flashcard.id, difficulty);
    }

    _nextWord(StudyResult.values[difficulty.index]);
  }

  void _nextWord(StudyResult result) {
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
            Text('Words studied: $_studiedCount'),
            Text('Words remaining: ${_sessionWords.length - _currentIndex}'),
            Text('Total words: ${_sessionWords.length}'),
            if (widget.useSpacedRepetition) ...[
              const SizedBox(height: 12),
              const Text('Review Performance:'),
              Text('Again: ${_studyStats['again']}'),
              Text('Hard: ${_studyStats['hard']}'),
              Text('Good: ${_studyStats['good']}'),
              Text('Easy: ${_studyStats['easy']}'),
            ],
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