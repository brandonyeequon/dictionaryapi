import 'package:flutter/material.dart';
import '../models/jotoba_pitch_part.dart';

/// Professional pitch accent widget using overline/underline system
/// Based on OJAD (Online Japanese Accent Dictionary) standards
class PitchAccentWidget extends StatelessWidget {
  final List<JotobaPitchPart> pitchParts;
  final double? fontSize;
  final Color? textColor;
  final Color? accentColor;

  const PitchAccentWidget({
    super.key,
    required this.pitchParts,
    this.fontSize = 18,
    this.textColor,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    if (pitchParts.isEmpty) {
      return const SizedBox.shrink();
    }

    final effectiveTextColor = textColor ?? Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final effectiveAccentColor = accentColor ?? Colors.red[600]!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: _buildPitchSegments(effectiveTextColor, effectiveAccentColor),
    );
  }

  List<Widget> _buildPitchSegments(Color textColor, Color accentColor) {
    final segments = <Widget>[];
    
    // Group consecutive characters with same pitch
    final groups = <List<JotobaPitchPart>>[];
    List<JotobaPitchPart> currentGroup = [pitchParts.first];
    
    for (int i = 1; i < pitchParts.length; i++) {
      if (pitchParts[i].high == currentGroup.last.high) {
        currentGroup.add(pitchParts[i]);
      } else {
        groups.add(currentGroup);
        currentGroup = [pitchParts[i]];
      }
    }
    groups.add(currentGroup);
    
    // Build segments with proper transitions
    for (int groupIndex = 0; groupIndex < groups.length; groupIndex++) {
      final group = groups[groupIndex];
      final isLast = groupIndex == groups.length - 1;
      final nextGroup = isLast ? null : groups[groupIndex + 1];
      
      // Check if there's a pitch transition
      final hasTransition = nextGroup != null && group.first.high != nextGroup.first.high;
      final isDownstep = hasTransition && group.first.high && !nextGroup.first.high;
      
      segments.add(_buildPitchSegment(
        group,
        textColor,
        accentColor,
        hasDownstep: isDownstep,
      ));
      
      // Add minimal spacing between groups
      if (!isLast) {
        segments.add(const SizedBox(width: 1));
      }
    }
    
    return segments;
  }

  Widget _buildPitchSegment(
    List<JotobaPitchPart> group,
    Color textColor,
    Color accentColor, {
    bool hasDownstep = false,
  }) {
    final isHigh = group.first.high;
    final text = group.map((p) => p.part).join();
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border(
              top: isHigh 
                ? BorderSide(color: accentColor, width: 2.0)
                : BorderSide.none,
              bottom: !isHigh 
                ? BorderSide(color: accentColor, width: 2.0)
                : BorderSide.none,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: textColor,
                height: 1.2,
              ),
            ),
          ),
        ),
        if (hasDownstep) _buildDownstepIndicator(accentColor),
      ],
    );
  }

  Widget _buildDownstepIndicator(Color accentColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: CustomPaint(
        size: Size(fontSize! * 0.3, fontSize! * 0.8),
        painter: DownstepPainter(accentColor),
      ),
    );
  }
}

/// Custom painter for downstep indicator (falling tone marker)
class DownstepPainter extends CustomPainter {
  final Color color;

  DownstepPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Draw downward arrow line
    canvas.drawLine(
      Offset(0, size.height * 0.2),
      Offset(size.width, size.height * 0.8),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Compact pitch accent widget for use in lists and cards
class CompactPitchAccentWidget extends StatelessWidget {
  final List<JotobaPitchPart> pitchParts;
  final double fontSize;

  const CompactPitchAccentWidget({
    super.key,
    required this.pitchParts,
    this.fontSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    return PitchAccentWidget(
      pitchParts: pitchParts,
      fontSize: fontSize,
      textColor: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
      accentColor: Colors.red[400],
    );
  }
}

/// Ultra compact pitch accent for very small spaces
class MinimalPitchAccentWidget extends StatelessWidget {
  final List<JotobaPitchPart> pitchParts;

  const MinimalPitchAccentWidget({
    super.key,
    required this.pitchParts,
  });

  @override
  Widget build(BuildContext context) {
    if (pitchParts.isEmpty) return const SizedBox.shrink();
    
    // Generate simple pattern notation (e.g., "LHL")
    final pattern = pitchParts.map((p) => p.high ? 'H' : 'L').join();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red[200]!, width: 0.5),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        pattern,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: Colors.red[600],
          height: 1.0,
        ),
      ),
    );
  }
}