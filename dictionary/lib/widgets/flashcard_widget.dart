import 'package:flutter/material.dart';
import '../models/enhanced_flashcard.dart';

/// Widget for displaying a flashcard with flip animation
class FlashcardWidget extends StatelessWidget {
  final EnhancedFlashcard flashcard;
  final bool showAnswer;
  final Animation<double> flipAnimation;
  final VoidCallback? onTap;

  const FlashcardWidget({
    super.key,
    required this.flashcard,
    required this.showAnswer,
    required this.flipAnimation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: flipAnimation,
        builder: (context, child) {
          final isShowingFront = flipAnimation.value < 0.5;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(flipAnimation.value * 3.14159),
            child: Card(
              elevation: 8,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isShowingFront
                        ? [
                            Theme.of(context).colorScheme.primaryContainer,
                            Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.7),
                          ]
                        : [
                            Theme.of(context).colorScheme.secondaryContainer,
                            Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.7),
                          ],
                  ),
                ),
                child: isShowingFront
                    ? _buildFrontSide(context)
                    : Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(3.14159),
                        child: _buildBackSide(context),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFrontSide(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Word
        Text(
          flashcard.word,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 16),
        
        // Reading
        if (flashcard.reading.isNotEmpty && flashcard.reading != flashcard.word)
          Text(
            flashcard.reading,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        
        const Spacer(),
        
        // Tags
        if (flashcard.tags.isNotEmpty)
          Wrap(
            spacing: 8,
            children: flashcard.tags.take(3).map((tag) => Chip(
              label: Text(
                tag,
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            )).toList(),
          ),
        
        const SizedBox(height: 16),
        
        // Tap hint
        if (!showAnswer)
          Text(
            'Tap to reveal answer',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.6),
            ),
          ),
      ],
    );
  }

  Widget _buildBackSide(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Definition
        Text(
          flashcard.definition,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 24),
        
        // Statistics
        _buildStatistics(context),
        
        const Spacer(),
        
        // Additional info
        if (flashcard.tags.isNotEmpty)
          Wrap(
            spacing: 8,
            children: flashcard.tags.map((tag) => Chip(
              label: Text(
                tag,
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
            )).toList(),
          ),
      ],
    );
  }

  Widget _buildStatistics(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                context,
                'Accuracy',
                '${flashcard.accuracy.toStringAsFixed(0)}%',
                Icons.check_circle,
              ),
              _buildStatItem(
                context,
                'Reviews',
                '${flashcard.totalReviews}',
                Icons.repeat,
              ),
              _buildStatItem(
                context,
                'Streak',
                '${flashcard.correctStreak}',
                Icons.local_fire_department,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Next review: ${_formatNextReview()}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSecondaryContainer.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSecondaryContainer.withValues(alpha: 0.7),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSecondaryContainer.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  String _formatNextReview() {
    final now = DateTime.now();
    final nextReview = flashcard.nextReview;
    
    if (nextReview.isBefore(now)) {
      return 'Now';
    }
    
    final difference = nextReview.difference(now);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inMinutes}m';
    }
  }
}