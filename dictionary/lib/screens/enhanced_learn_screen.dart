import 'package:flutter/material.dart';
import '../models/user_progress.dart';
import '../models/study_session.dart';
import '../models/word_entry.dart';
import '../models/word_list.dart';
import '../services/enhanced_flashcard_service.dart';
import '../services/enhanced_word_list_service.dart';
import 'enhanced_study_screen.dart';

/// Enhanced learn screen with user progress, streaks, and level progression
class EnhancedLearnScreen extends StatefulWidget {
  const EnhancedLearnScreen({super.key});

  @override
  State<EnhancedLearnScreen> createState() => _EnhancedLearnScreenState();
}

class _EnhancedLearnScreenState extends State<EnhancedLearnScreen> {
  final EnhancedFlashcardService _flashcardService = EnhancedFlashcardService();
  final EnhancedWordListService _wordListService = EnhancedWordListService();
  
  bool _isLoading = true;
  UserProgress? _userProgress;
  Map<String, dynamic> _flashcardStats = {};
  
  @override
  void initState() {
    super.initState();
    _initializeServices();
    // Listen to word list changes
    _wordListService.addListener(_onWordListChanged);
  }

  @override
  void dispose() {
    _wordListService.removeListener(_onWordListChanged);
    super.dispose();
  }

  void _onWordListChanged() {
    if (mounted) {
      setState(() {
        // Trigger rebuild when word lists change
      });
    }
  }

  Future<void> _initializeServices() async {
    setState(() => _isLoading = true);
    
    try {
      await _flashcardService.initialize();
      await _wordListService.initialize();
      
      // Load user data
      await _loadUserData();
    } catch (e) {
      debugPrint('Error initializing services: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserData() async {
    try {
      final progress = await _flashcardService.getUserProgress();
      final stats = await _flashcardService.getFlashcardStats();
      
      // Also reload word lists to ensure they're up to date
      await _wordListService.loadWordLists();
      
      setState(() {
        _userProgress = progress;
        _flashcardStats = stats;
      });
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildUserProgressCard(),
                    const SizedBox(height: 24),
                    _buildGlobalStudyActions(),
                    const SizedBox(height: 24),
                    _buildMyListsSection(),
                    const SizedBox(height: 24),
                    _buildAchievementsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildUserProgressCard() {
    if (_userProgress == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.person, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              Text(
                'Welcome to Enhanced Learning!',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Start studying to track your progress',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final progress = _userProgress!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level ${progress.currentLevel}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    Text(
                      '${progress.wordsToNextLevel} words to next level',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    _showProgressDetails(progress);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          color: progress.currentStreak > 0 ? Colors.orange : Colors.grey,
                          size: 32,
                        ),
                        Text(
                          '${progress.currentStreak}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: progress.currentStreak > 0 ? Colors.orange : Colors.grey,
                          ),
                        ),
                        const Text('Day Streak', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Progress to Level ${progress.currentLevel + 1}'),
                    Text('${(progress.progressToNextLevel * 100).round()}%'),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress.progressToNextLevel,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Quick stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickStat('Total Words', '${progress.totalWordsStudied}'),
                _buildQuickStat('Accuracy', '${progress.averageAccuracy.toStringAsFixed(1)}%'),
                _buildQuickStat('Study Time', '${(progress.studyTimeMinutes / 60).toStringAsFixed(1)}h'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
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

  Widget _buildGlobalStudyActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Global Study Options',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: [
                _buildStudyButton(
                  'Due Cards',
                  Icons.schedule,
                  Colors.orange,
                  '${_flashcardStats['dueCards'] ?? 0} due',
                  () => _startStudySession(StudySessionType.due),
                ),
                _buildStudyButton(
                  'New Words',
                  Icons.fiber_new,
                  Colors.green,
                  '${_flashcardStats['newCards'] ?? 0} new',
                  () => _startStudySession(StudySessionType.newCards),
                ),
                _buildStudyButton(
                  'Mixed Review',
                  Icons.shuffle,
                  Colors.blue,
                  'Balanced study',
                  () => _startStudySession(StudySessionType.mixed),
                ),
                _buildStudyButton(
                  'Difficult',
                  Icons.trending_up,
                  Colors.red,
                  'Challenge mode',
                  () => _startStudySession(StudySessionType.difficult),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudyButton(
    String title,
    IconData icon,
    Color color,
    String subtitle,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }


  Widget _buildMyListsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Word Lists',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            OutlinedButton.icon(
              onPressed: _createNewList,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New List'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildWordListCards(),
      ],
    );
  }

  Widget _buildWordListCards() {
    final lists = _wordListService.wordLists;
    
    if (lists.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.list, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No Word Lists Yet',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create your first list to start organizing your vocabulary',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _createNewList,
                icon: const Icon(Icons.add),
                label: const Text('Create First List'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: lists.map((list) => _buildWordListCard(list)).toList(),
    );
  }

  Widget _buildWordListCard(list) {
    return FutureBuilder<List<WordEntry>>(
      future: _wordListService.getWordsInList(list.id),
      builder: (context, snapshot) {
        final wordCount = snapshot.data?.length ?? 0;
        return _buildWordListCardContent(list, wordCount);
      },
    );
  }

  Widget _buildWordListCardContent(list, int wordCount) {
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    list.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        list.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$wordCount words',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) => _handleListAction(value, list),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Study Options',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.8,
              children: [
                _buildListStudyButton(
                  'Study All',
                  Icons.play_arrow,
                  Colors.blue,
                  () => _startListStudy(list, StudySessionType.mixed),
                ),
                _buildListStudyButton(
                  'New Words',
                  Icons.fiber_new,
                  Colors.green,
                  () => _startListStudy(list, StudySessionType.newCards),
                ),
                _buildListStudyButton(
                  'Due Cards',
                  Icons.schedule,
                  Colors.orange,
                  () => _startListStudy(list, StudySessionType.due),
                ),
                _buildListStudyButton(
                  'Review',
                  Icons.refresh,
                  Colors.purple,
                  () => _startListStudy(list, StudySessionType.mixed),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListStudyButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection() {
    if (_userProgress == null) return const SizedBox.shrink();
    
    final achievements = _userProgress!.recentAchievements;
    if (achievements.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Achievements',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: achievements.take(6).map((achievement) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(achievement.emoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Text(
                        achievement.title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startStudySession(StudySessionType sessionType) async {
    try {
      final success = await _flashcardService.startStudySession(
        sessionType: sessionType,
        cardLimit: 20,
      );
      
      if (success && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => EnhancedStudyScreen(
              initialSessionType: sessionType,
            ),
          ),
        ).then((_) {
          // Refresh data when returning from study session
          _loadUserData();
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No cards available for this study type'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting study session: $e'),
          ),
        );
      }
    }
  }

  Future<void> _createNewList() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _CreateListDialog(),
    );
    
    if (result != null && result.isNotEmpty) {
      try {
        await _wordListService.createWordList(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Created list: $result')),
          );
          await _loadUserData(); // Refresh to show new list
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating list: $e')),
          );
        }
      }
    }
  }

  Future<void> _startListStudy(WordList list, StudySessionType sessionType) async {
    try {
      final success = await _flashcardService.startStudySession(
        sessionType: sessionType,
        targetListIds: [list.id],
        cardLimit: 20,
      );
      
      if (success && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => EnhancedStudyScreen(
              initialSessionType: sessionType,
            ),
          ),
        ).then((_) {
          // Refresh data when returning from study session
          _loadUserData();
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No ${sessionType.displayName.toLowerCase()} cards available in "${list.name}"'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting study session: $e'),
          ),
        );
      }
    }
  }

  Future<void> _handleListAction(String action, WordList list) async {
    switch (action) {
      case 'edit':
        await _editList(list);
        break;
      case 'delete':
        await _deleteList(list);
        break;
    }
  }

  Future<void> _editList(WordList list) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _EditListDialog(initialName: list.name),
    );
    
    if (result != null && result.isNotEmpty && result != list.name) {
      try {
        final updatedList = WordList(
          id: list.id,
          name: result,
          createdAt: list.createdAt,
          updatedAt: DateTime.now(),
        );
        await _wordListService.updateWordList(updatedList);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Updated list name to: $result')),
          );
          await _loadUserData(); // Refresh to show updated list
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating list: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteList(WordList list) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete List'),
        content: Text('Are you sure you want to delete "${list.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _wordListService.deleteWordList(list.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Deleted "${list.name}"')),
          );
          await _loadUserData(); // Refresh to remove deleted list
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting list: $e')),
          );
        }
      }
    }
  }

  void _showProgressDetails(UserProgress progress) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Level ${progress.currentLevel} Progress'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Streak: ${progress.currentStreak} days'),
            Text('Longest Streak: ${progress.longestStreak} days'),
            Text('Total Words: ${progress.totalWordsStudied}'),
            Text('Study Time: ${(progress.studyTimeMinutes / 60).toStringAsFixed(1)} hours'),
            Text('Accuracy: ${progress.averageAccuracy.toStringAsFixed(1)}%'),
            const SizedBox(height: 16),
            const Text('Words by Level:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...progress.wordCountByLevel.entries.map((entry) => 
              Text('${entry.key.displayName}: ${entry.value}')
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _CreateListDialog extends StatefulWidget {
  @override
  State<_CreateListDialog> createState() => _CreateListDialogState();
}

class _CreateListDialogState extends State<_CreateListDialog> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New List'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'List Name',
          hintText: 'e.g., JLPT N5 Vocabulary',
        ),
        autofocus: true,
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            Navigator.of(context).pop(value);
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              Navigator.of(context).pop(_controller.text);
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _EditListDialog extends StatefulWidget {
  final String initialName;
  
  const _EditListDialog({required this.initialName});

  @override
  State<_EditListDialog> createState() => _EditListDialogState();
}

class _EditListDialogState extends State<_EditListDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit List Name'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'List Name',
        ),
        autofocus: true,
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            Navigator.of(context).pop(value);
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              Navigator.of(context).pop(_controller.text);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}