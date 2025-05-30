import 'package:flutter/material.dart';
import '../models/enhanced_flashcard.dart';
import '../models/word_mastery.dart';
import '../models/study_session.dart';
import '../services/enhanced_flashcard_service.dart';
import '../widgets/flashcard_widget.dart';

/// Enhanced study screen with improved UX and progress tracking
class EnhancedStudyScreen extends StatefulWidget {
  final StudySessionType? initialSessionType;
  final List<int>? targetListIds;

  const EnhancedStudyScreen({
    super.key,
    this.initialSessionType,
    this.targetListIds,
  });

  @override
  State<EnhancedStudyScreen> createState() => _EnhancedStudyScreenState();
}

class _EnhancedStudyScreenState extends State<EnhancedStudyScreen>
    with TickerProviderStateMixin {
  final EnhancedFlashcardService _flashcardService = EnhancedFlashcardService();
  
  bool _isLoading = true;
  bool _showAnswer = false;
  
  late AnimationController _flipController;
  late AnimationController _progressController;
  late Animation<double> _flipAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeService();
  }

  void _initializeAnimations() {
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
    );
  }

  Future<void> _initializeService() async {
    await _flashcardService.initialize();
    
    if (!_flashcardService.hasCurrentSession) {
      await _startStudySession();
    }
    
    setState(() {
      _isLoading = false;
    });
    
    _updateProgress();
  }

  Future<void> _startStudySession() async {
    final sessionType = widget.initialSessionType ?? StudySessionType.due;
    await _flashcardService.startStudySession(
      sessionType: sessionType,
      targetListIds: widget.targetListIds,
      cardLimit: 20, // Default session limit
    );
  }

  void _updateProgress() {
    final session = _flashcardService.currentSession;
    if (session != null) {
      final progress = _flashcardService.sessionCardIndex / _flashcardService.sessionQueue.length;
      _progressController.animateTo(progress);
    }
  }

  void _showCardAnswer() {
    if (!_showAnswer) {
      setState(() {
        _showAnswer = true;
      });
      _flipController.forward();
    }
  }

  Future<void> _reviewCard(ReviewDifficulty difficulty) async {
    if (!_showAnswer) return;

    // Review the card
    await _flashcardService.reviewCurrentCard(difficulty);
    
    // Reset for next card or end session
    setState(() {
      _showAnswer = false;
    });
    
    _flipController.reset();
    _updateProgress();
    
    // Check if session is complete
    if (!_flashcardService.hasCurrentSession) {
      _showSessionComplete();
    }
  }

  void _showSessionComplete() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SessionCompleteDialog(
        onContinue: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop(); // Return to previous screen
        },
        onNewSession: () async {
          Navigator.of(context).pop();
          await _startStudySession();
          _updateProgress();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Session'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showSessionInfo,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildStudyInterface(),
    );
  }

  Widget _buildStudyInterface() {
    final currentCard = _flashcardService.currentCard;
    if (currentCard == null) {
      return const Center(
        child: Text('No cards available for study.'),
      );
    }

    return Column(
      children: [
        // Progress bar
        _buildProgressSection(),
        
        // Card display
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Mastery level indicator
                _buildMasteryIndicator(currentCard),
                
                const SizedBox(height: 16),
                
                // Flashcard
                Expanded(
                  child: FlashcardWidget(
                    flashcard: currentCard,
                    showAnswer: _showAnswer,
                    flipAnimation: _flipAnimation,
                    onTap: _showCardAnswer,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Action buttons
                if (_showAnswer) _buildReviewButtons() else _buildShowAnswerButton(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection() {
    final session = _flashcardService.currentSession;
    if (session == null) return const SizedBox.shrink();

    final current = _flashcardService.sessionCardIndex + 1;
    final total = _flashcardService.sessionQueue.length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$current of $total',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '${((current / total) * 100).round()}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: _progressAnimation.value,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMasteryIndicator(EnhancedFlashcard card) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color(card.masteryLevel.colorValue),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        card.masteryLevel.displayName,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildShowAnswerButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _showCardAnswer,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        child: const Text(
          'Show Answer',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildReviewButtons() {
    return Column(
      children: [
        const Text(
          'How well did you know this?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDifficultyButton(
                ReviewDifficulty.again,
                Colors.red,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDifficultyButton(
                ReviewDifficulty.hard,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDifficultyButton(
                ReviewDifficulty.good,
                Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDifficultyButton(
                ReviewDifficulty.easy,
                Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDifficultyButton(ReviewDifficulty difficulty, Color color) {
    return ElevatedButton(
      onPressed: () => _reviewCard(difficulty),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            difficulty.displayName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            difficulty.description,
            style: const TextStyle(fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showSessionInfo() {
    showDialog(
      context: context,
      builder: (context) => SessionInfoDialog(
        session: _flashcardService.currentSession,
        flashcardService: _flashcardService,
      ),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    _progressController.dispose();
    super.dispose();
  }
}

/// Dialog shown when study session is complete
class SessionCompleteDialog extends StatelessWidget {
  final VoidCallback onContinue;
  final VoidCallback onNewSession;

  const SessionCompleteDialog({
    super.key,
    required this.onContinue,
    required this.onNewSession,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('🎉 Session Complete!'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Great job! You\'ve completed your study session.'),
          SizedBox(height: 16),
          Text('What would you like to do next?'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onContinue,
          child: const Text('Finish'),
        ),
        ElevatedButton(
          onPressed: onNewSession,
          child: const Text('New Session'),
        ),
      ],
    );
  }
}

/// Dialog showing session information and statistics
class SessionInfoDialog extends StatelessWidget {
  final StudySession? session;
  final EnhancedFlashcardService flashcardService;

  const SessionInfoDialog({
    super.key,
    required this.session,
    required this.flashcardService,
  });

  @override
  Widget build(BuildContext context) {
    if (session == null) {
      return const AlertDialog(
        title: Text('No Active Session'),
        content: Text('There is no active study session.'),
      );
    }

    final current = flashcardService.sessionCardIndex + 1;
    final total = flashcardService.sessionQueue.length;
    final accuracy = session!.accuracy;

    return AlertDialog(
      title: const Text('Session Info'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Session Type', session!.sessionType.displayName),
          _buildInfoRow('Progress', '$current / $total cards'),
          _buildInfoRow('Accuracy', '${accuracy.toStringAsFixed(1)}%'),
          _buildInfoRow('Duration', _formatDuration(session!.duration)),
          if (session!.cardReviews.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Review Distribution:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...session!.cardsByDifficulty.entries.map(
              (entry) => _buildInfoRow(
                entry.key.displayName,
                '${entry.value} cards',
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }
}