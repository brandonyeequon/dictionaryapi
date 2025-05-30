import 'package:flutter/material.dart';
import '../models/jotoba_word_entry.dart';
import '../models/word_entry.dart';
import '../models/word_list.dart';
import '../services/enhanced_word_list_service.dart';
import '../widgets/ruby_text_widget.dart';

/// Simplified word detail screen for Jotoba word entries
class WordDetailScreen extends StatelessWidget {
  final JotobaWordEntry wordEntry;

  const WordDetailScreen({super.key, required this.wordEntry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(wordEntry.primaryWord),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: () => _showAddToListDialog(context),
              icon: const Icon(Icons.add, color: Colors.white),
              tooltip: 'Add to Word List',
              iconSize: 24,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWordHeader(context),
            const SizedBox(height: 24),
            _buildDefinitions(context),
            if (wordEntry.hasPitchAccent) ...[
              const SizedBox(height: 24),
              _buildPitchAccent(context),
            ],
            if (wordEntry.hasAudio) ...[
              const SizedBox(height: 24),
              _buildAudioSection(context),
            ],
            if (wordEntry.frequencyRank != null) ...[
              const SizedBox(height: 24),
              _buildFrequencyInfo(context),
            ],
            const SizedBox(height: 24),
            _buildTags(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWordHeader(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (wordEntry.reading.isNotEmpty)
              ...wordEntry.reading.map((reading) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    if (reading.kanji != null) ...[
                      if (reading.hasFurigana)
                        RubyTextWidget(
                          text: reading.kanji!,
                          furigana: reading.furigana,
                          kanjiStyle: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        )
                      else
                        Text(
                          reading.kanji!,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      const SizedBox(width: 16),
                    ],
                    if (!reading.hasFurigana || reading.kanji == null)
                      Text(
                        reading.kana,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              )),
            if (wordEntry.isCommon)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Common Word',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefinitions(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Definitions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...wordEntry.senses.asMap().entries.map((senseEntry) {
              final index = senseEntry.key;
              final sense = senseEntry.value;
              
              return Padding(
                padding: EdgeInsets.only(bottom: index < wordEntry.senses.length - 1 ? 16 : 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (sense.comprehensivePosDisplay.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: sense.comprehensivePosDisplay.map((tag) =>
                            _buildPosTag(tag, small: true)
                          ).toList(),
                        ),
                      ),
                    // Consolidated definitions format: "1. hello, good day, good afternoon"
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 8, top: 2),
                          child: Text(
                            '${index + 1}.',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            sense.allGlossTexts.join(', '),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    if (sense.info.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Notes: ${sense.info.join(', ')}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPitchAccent(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Colors.purple[600]),
                const SizedBox(width: 8),
                Text(
                  'Pitch Accent',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...wordEntry.pitchAccent.map((accent) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reading: ${accent.reading}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Pattern: ${accent.patternDescription}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioSection(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.volume_up, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Text(
                  'Audio Pronunciation',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Audio is available for this word',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement audio playback
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Audio playback not implemented yet')),
                );
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Play Audio'),
            ),
          ],
        ),
      ),
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
      frequencyText = 'Less common (rank: $freq)';
      frequencyColor = Colors.grey;
    }

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.bar_chart, color: frequencyColor),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Frequency',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  frequencyText,
                  style: TextStyle(color: frequencyColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTags(BuildContext context) {
    final allTags = [
      ...wordEntry.tags,
      ...wordEntry.jlpt,
    ];

    if (allTags.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tags',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...wordEntry.jlpt.map((jlpt) => _buildTag(jlpt, Colors.blue)),
                ...wordEntry.tags.map((tag) => _buildTag(tag, Colors.purple)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color, {bool small = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 8,
        vertical: small ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: small ? 11 : 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
  
  Widget _buildPosTag(String tag, {bool small = false}) {
    Color color = _getPosTagColor(tag);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 8,
        vertical: small ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        tag,
        style: TextStyle(
          color: color,
          fontSize: small ? 11 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  
  Color _getPosTagColor(String tag) {
    // Primary POS types
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
    }
    
    // Verb details
    if (tag == 'Ichidan' || tag == 'Transitive' || tag == 'Intransitive' || 
        tag.contains('Godan') || tag == 'Irregular') {
      return Colors.blue[600]!;
    }
    
    // Adjective details
    if (tag.contains('adj')) {
      return Colors.red[600]!;
    }
    
    // Default
    return Colors.grey[700]!;
  }

  Future<void> _showAddToListDialog(BuildContext context) async {
    final wordListService = EnhancedWordListService();
    await wordListService.initialize();
    
    final wordLists = wordListService.wordLists;

    if (!context.mounted) return;
    final result = await showDialog<dynamic>(
      context: context,
      builder: (context) => _AddToListDialog(
        wordEntry: wordEntry,
        wordLists: wordLists,
      ),
    );

    if (result != null && context.mounted) {
      if (result is WordList) {
        // Selected existing list
        await _addWordToList(context, result);
      } else if (result is String) {
        // Create new list and add word
        await _createListAndAddWord(context, result);
      }
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
            content: Text('Added "${wordEntry.primaryWord}" to "${selectedList.name}" and created flashcard for study'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
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

  Future<void> _createListAndAddWord(BuildContext context, String listName) async {
    try {
      final wordListService = EnhancedWordListService();
      
      // Create the new list
      final newList = await wordListService.createWordList(listName);
      
      if (newList != null) {
        // Add the word to the new list
        final convertedWord = _convertToWordEntry(wordEntry);
        final success = await wordListService.addWordToList(newList.id, convertedWord);
        
        if (!context.mounted) return;
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Created "$listName", added "${wordEntry.primaryWord}", and created flashcard for study'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Created "$listName" but failed to add word'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create list'),
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

class _AddToListDialog extends StatefulWidget {
  final JotobaWordEntry wordEntry;
  final List<WordList> wordLists;

  const _AddToListDialog({
    required this.wordEntry,
    required this.wordLists,
  });

  @override
  State<_AddToListDialog> createState() => _AddToListDialogState();
}

class _AddToListDialogState extends State<_AddToListDialog> {
  bool _showCreateNew = false;
  final _newListController = TextEditingController();

  @override
  void dispose() {
    _newListController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.bookmark_add, color: Colors.green),
          const SizedBox(width: 8),
          const Text('Add to Word List'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add "${widget.wordEntry.primaryWord}" to:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            
            if (!_showCreateNew) ...[
              // Show existing lists
              if (widget.wordLists.isNotEmpty) ...[
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: widget.wordLists.length,
                    itemBuilder: (context, index) {
                      final list = widget.wordLists[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Text(
                              list.name.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(list.name),
                          subtitle: list.description != null 
                              ? Text(
                                  list.description!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () => Navigator.of(context).pop(list),
                        ),
                      );
                    },
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.list_alt, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'No word lists yet',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'Create your first list to get started',
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              
              // Create new list button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showCreateNew = true;
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create New List'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green),
                  ),
                ),
              ),
            ] else ...[
              // Show create new list form
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _showCreateNew = false;
                            _newListController.clear();
                          });
                        },
                        icon: const Icon(Icons.arrow_back),
                        iconSize: 20,
                      ),
                      const Text(
                        'Create New List',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _newListController,
                    decoration: const InputDecoration(
                      labelText: 'List Name',
                      hintText: 'e.g., JLPT N5 Vocabulary',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.list),
                    ),
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        Navigator.of(context).pop(value.trim());
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (_newListController.text.trim().isNotEmpty) {
                          Navigator.of(context).pop(_newListController.text.trim());
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Create & Add Word'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}