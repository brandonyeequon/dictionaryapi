import 'package:flutter/material.dart';

/// A widget that displays Japanese text with furigana (ruby text)
/// Parses furigana format like "[食|た]べる" and displays hiragana above kanji
class RubyTextWidget extends StatelessWidget {
  final String text;
  final String? furigana;
  final TextStyle? kanjiStyle;
  final TextStyle? furiganaStyle;
  final double rubyGap;

  const RubyTextWidget({
    super.key,
    required this.text,
    this.furigana,
    this.kanjiStyle,
    this.furiganaStyle,
    this.rubyGap = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    if (furigana == null || furigana!.isEmpty) {
      return Text(text, style: kanjiStyle);
    }

    final segments = _parseFurigana(text, furigana!);
    
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      children: segments.map((segment) => _buildSegment(context, segment)).toList(),
    );
  }

  Widget _buildSegment(BuildContext context, TextSegment segment) {
    final defaultKanjiStyle = kanjiStyle ?? 
        Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        );
    
    final defaultFuriganaStyle = furiganaStyle ?? 
        Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: (defaultKanjiStyle?.fontSize ?? 16) * 0.6,
          height: 1.0,
        );

    if (segment.reading == null) {
      // Plain text without furigana
      return Text(segment.text, style: defaultKanjiStyle);
    }

    // Text with furigana
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          segment.reading!,
          style: defaultFuriganaStyle,
        ),
        SizedBox(height: rubyGap),
        Text(
          segment.text,
          style: defaultKanjiStyle,
        ),
      ],
    );
  }

  List<TextSegment> _parseFurigana(String text, String furigana) {
    final segments = <TextSegment>[];
    final regex = RegExp(r'\[([^\]]+)\]');
    
    int lastIndex = 0;
    
    for (final match in regex.allMatches(furigana)) {
      // Add any text before this match
      if (match.start > lastIndex) {
        final beforeText = furigana.substring(lastIndex, match.start);
        if (beforeText.isNotEmpty) {
          segments.add(TextSegment(text: beforeText, reading: null));
        }
      }
      
      // Parse the bracket content which could be "kanji|reading" or "kanji|syllable|syllable"
      final bracketContent = match.group(1)!;
      final parts = bracketContent.split('|');
      
      if (parts.length >= 2) {
        final kanji = parts[0];
        // Join all reading parts (handles cases like [学校|がっ|こう])
        final reading = parts.sublist(1).join('');
        segments.add(TextSegment(text: kanji, reading: reading));
      } else {
        // If no pipe, treat as plain text
        segments.add(TextSegment(text: bracketContent, reading: null));
      }
      
      lastIndex = match.end;
    }
    
    // Add any remaining text after the last match
    if (lastIndex < furigana.length) {
      final remainingText = furigana.substring(lastIndex);
      if (remainingText.isNotEmpty) {
        segments.add(TextSegment(text: remainingText, reading: null));
      }
    }
    
    // If no matches found, treat as plain text
    if (segments.isEmpty) {
      segments.add(TextSegment(text: text, reading: null));
    }
    
    return segments;
  }
}

/// Represents a segment of text that may or may not have furigana
class TextSegment {
  final String text;
  final String? reading;

  TextSegment({
    required this.text,
    this.reading,
  });
}