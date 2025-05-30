import 'package:flutter/material.dart';
import '../models/user_progress.dart';
import '../models/study_session.dart';
import '../services/enhanced_flashcard_service.dart';
import '../services/enhanced_word_list_service.dart';
import 'enhanced_study_screen.dart';
import 'word_lists_screen.dart';

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
                    _buildQuickStudyActions(),
                    const SizedBox(height: 24),
                    _buildStatisticsCard(),
                    const SizedBox(height: 24),
                    _buildWordListsSection(),
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
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
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

  Widget _buildQuickStudyActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Study',
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
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.3)),
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

  Widget _buildStatisticsCard() {
    final stats = _flashcardStats;
    if (stats.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vocabulary Overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Cards',
                    '${stats['totalCards'] ?? 0}',
                    Icons.quiz,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Mastered',
                    '${stats['masteredCards'] ?? 0}',
                    Icons.star,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Accuracy',
                    '${(stats['averageAccuracy'] ?? 0.0).toStringAsFixed(1)}%',
                    Icons.check_circle,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWordListsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Word Lists',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const WordListsScreen(),
                      ),
                    );
                  },
                  child: const Text('Manage All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const WordListsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.list),
                    label: const Text('View Lists'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _createNewList,
                    icon: const Icon(Icons.add),
                    label: const Text('New List'),
                  ),
                ),
              ],
            ),
          ],
        ),
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
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
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
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const WordListsScreen(),
            ),
          );
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