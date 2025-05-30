import 'package:flutter/material.dart';
import '../models/jotoba_word_entry.dart';
import '../models/word_entry.dart';
import '../models/word_list.dart';
import '../services/enhanced_word_list_service.dart';
import 'ruby_text_widget.dart';

/// Word card widget specifically designed for Jotoba word entries
class JotobaWordCard extends StatelessWidget {
  final JotobaWordEntry wordEntry;
  final VoidCallback? onTap;

  const JotobaWordCard({
    super.key,
    required this.wordEntry,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 8.0),
              _buildDefinition(context),
              if (wordEntry.hasPitchAccent) ...[
                const SizedBox(height: 8.0),
                _buildPitchAccent(context),
              ],
              if (wordEntry.hasAudio) ...[
                const SizedBox(height: 4.0),
                _buildAudioIndicator(context),
              ],
              if (wordEntry.frequencyRank != null) ...[
                const SizedBox(height: 4.0),
                _buildFrequencyInfo(context),
              ],
              const SizedBox(height: 8.0),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWordWithFurigana(context),
              if (wordEntry.primaryReading.isNotEmpty && 
                  wordEntry.primaryReading != wordEntry.primaryWord &&
                  !wordEntry.hasPrimaryFurigana)
                Text(
                  wordEntry.primaryReading,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),
        _buildTags(context),
      ],
    );
  }

  Widget _buildWordWithFurigana(BuildContext context) {
    if (wordEntry.hasPrimaryFurigana) {
      return RubyTextWidget(
        text: wordEntry.primaryWord,
        furigana: wordEntry.primaryFurigana,
        kanjiStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      );
    } else {
      return Text(
        wordEntry.primaryWord,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      );
    }
  }

  Widget _buildTags(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (wordEntry.isCommon)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: const Text(
              'Common',
              style: TextStyle(color: Colors.white, fontSize: 10.0),
            ),
          ),
        if (wordEntry.hasJlptLevel) ...[
          const SizedBox(height: 4.0),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Text(
              wordEntry.jlptLevel!,
              style: const TextStyle(color: Colors.white, fontSize: 10.0),
            ),
          ),
        ],
        if (wordEntry.hasAudio) ...[
          const SizedBox(height: 4.0),
          Icon(
            Icons.volume_up,
            size: 16.0,
            color: Colors.purple[600],
          ),
        ],
      ],
    );
  }

  Widget _buildDefinition(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          wordEntry.consolidatedDefinitions,
          style: Theme.of(context).textTheme.bodyMedium,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        if (_hasPrimaryPosTag()) ...[ 
          const SizedBox(height: 4.0),
          _buildPartsOfSpeech(context),
        ],
      ],
    );
  }
  
  bool _hasPrimaryPosTag() {
    return wordEntry.primaryPosTag != null;
  }
  
  Widget _buildPartsOfSpeech(BuildContext context) {
    final primaryTag = wordEntry.primaryPosTag;
    
    if (primaryTag == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: _getPrimaryPosColor(primaryTag).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(
          color: _getPrimaryPosColor(primaryTag).withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: Text(
        primaryTag,
        style: TextStyle(
          color: _getPrimaryPosColor(primaryTag),
          fontSize: 10.0,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  
  Color _getPrimaryPosColor(String tag) {
    switch (tag) {
      case 'Verb':
        return Colors.blue[700]!;
      case 'i-adj':
        return Colors.red[700]!;
      case 'na-adj':
        return Colors.orange[700]!;
      case 'no-adj':
        return Colors.green[600]!;
      case 'Noun':
        return Colors.green[700]!;
      case 'Suffix':
      case 'Expr':
        return Colors.purple[600]!;
      default:
        return Colors.grey[700]!;
    }
  }
  
  

  Widget _buildPitchAccent(BuildContext context) {
    final pitchInfo = wordEntry.pitchAccent.isNotEmpty 
        ? wordEntry.pitchAccent.first.patternDescription 
        : '';
    
    return Row(
      children: [
        Icon(Icons.trending_up, size: 14.0, color: Colors.purple[600]),
        const SizedBox(width: 4.0),
        Expanded(
          child: Text(
            'Pitch: $pitchInfo',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.purple[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildAudioIndicator(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.volume_up, size: 14.0, color: Colors.blue[600]),
        const SizedBox(width: 4.0),
        Text(
          'Audio available',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.blue[600],
          ),
        ),
      ],
    );
  }

  Widget _buildFrequencyInfo(BuildContext context) {
    final freq = wordEntry.frequencyRank!;
    String frequencyText;
    Color frequencyColor;

    if (freq <= 1000) {
      frequencyText = 'Very common (top 1000)';
      frequencyColor = Colors.green;
    } else if (freq <= 5000) {
      frequencyText = 'Common (top 5000)';
      frequencyColor = Colors.orange;
    } else if (freq <= 10000) {
      frequencyText = 'Moderately common (top 10000)';
      frequencyColor = Colors.yellow[700]!;
    } else {
      frequencyText = 'Less common';
      frequencyColor = Colors.grey;
    }

    return Row(
      children: [
        Icon(Icons.bar_chart, size: 14.0, color: frequencyColor),
        const SizedBox(width: 4.0),
        Expanded(
          child: Text(
            frequencyText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: frequencyColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showAddToListDialog(context),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add to List'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: const Size(0, 32),
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showAddToListDialog(BuildContext context) async {
    final wordListService = EnhancedWordListService();
    await wordListService.initialize();
    
    final wordLists = wordListService.wordLists;
    
    if (wordLists.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No word lists found. Create a list first in the Learn section.'),
        ),
      );
      return;
    }

    if (!context.mounted) return;
    final selectedList = await showDialog<WordList>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add to Word List'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select a list to add "${wordEntry.primaryWord}":'),
            const SizedBox(height: 16),
            ...wordLists.map((list) => ListTile(
              title: Text(list.name),
              onTap: () => Navigator.of(context).pop(list),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedList != null && context.mounted) {
      await _addWordToList(context, selectedList);
    }
  }

  Future<void> _addWordToList(BuildContext context, WordList selectedList) async {
    try {
      final wordListService = EnhancedWordListService();
      final convertedWord = _convertToWordEntry(wordEntry);
      
      final success = await wordListService.addWordToList(selectedList.id, convertedWord);
      
      if (!context.mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "${wordEntry.primaryWord}" to "${selectedList.name}"'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add word to list'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  WordEntry _convertToWordEntry(JotobaWordEntry jotobaEntry) {
    return WordEntry(
      slug: jotobaEntry.slug ?? jotobaEntry.primaryWord,
      isCommon: jotobaEntry.isCommon,
      tags: jotobaEntry.tags,
      jlpt: jotobaEntry.jlpt,
      japanese: jotobaEntry.reading.map((r) => JapaneseReading(
        word: r.kanji,
        reading: r.kana,
      )).toList(),
      senses: jotobaEntry.senses.map((s) => WordSense(
        englishDefinitions: s.allGlossTexts,
        partsOfSpeech: s.partsOfSpeech,
        tags: s.tags,
        info: s.info,
      )).toList(),
    );
  }
}