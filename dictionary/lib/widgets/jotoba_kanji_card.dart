import 'package:flutter/material.dart';
import '../models/jotoba_kanji_entry.dart';

class JotobaKanjiCard extends StatelessWidget {
  final JotobaKanjiEntry kanjiEntry;
  final VoidCallback? onTap;

  const JotobaKanjiCard({
    super.key,
    required this.kanjiEntry,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Large kanji character
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        kanjiEntry.kanji,
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Kanji info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Meanings
                        Text(
                          kanjiEntry.meanings.take(3).join(', '),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Readings row
                        if (kanjiEntry.hasOnReadings || kanjiEntry.hasKunReadings) ...[
                          Row(
                            children: [
                              if (kanjiEntry.hasOnReadings) ...[
                                Text(
                                  'On: ',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    kanjiEntry.onReadings.take(2).join(', '),
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (kanjiEntry.hasKunReadings) ...[
                                Text(
                                  'Kun: ',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.secondary,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    kanjiEntry.kunReadings.take(2).join(', '),
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        // Badges row
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            if (kanjiEntry.hasGrade)
                              _buildBadge(
                                context,
                                'Grade ${kanjiEntry.grade}',
                                Colors.green,
                              ),
                            if (kanjiEntry.hasJlptLevel)
                              _buildBadge(
                                context,
                                'JLPT N${kanjiEntry.jlptLevel}',
                                Colors.blue,
                              ),
                            if (kanjiEntry.strokeCount != null)
                              _buildBadge(
                                context,
                                '${kanjiEntry.strokeCount} strokes',
                                Colors.orange,
                              ),
                            if (kanjiEntry.frequency != null)
                              _buildBadge(
                                context,
                                '#${kanjiEntry.frequency}',
                                Colors.purple,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}