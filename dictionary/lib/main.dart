import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'services/migration_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jisho Dictionary',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          return const MigrationWrapper();
        }

        return const AuthScreen();
      },
    );
  }
}

class MigrationWrapper extends StatefulWidget {
  const MigrationWrapper({super.key});

  @override
  State<MigrationWrapper> createState() => _MigrationWrapperState();
}

class _MigrationWrapperState extends State<MigrationWrapper> {
  bool _isCheckingMigration = true;
  bool _showMigrationPrompt = false;
  bool _isMigrating = false;

  @override
  void initState() {
    super.initState();
    _checkMigrationStatus();
  }

  Future<void> _checkMigrationStatus() async {
    try {
      final migrationService = MigrationService();
      final needsMigration = await migrationService.isMigrationNeeded();
      
      setState(() {
        _isCheckingMigration = false;
        _showMigrationPrompt = needsMigration;
      });
    } catch (e) {
      setState(() {
        _isCheckingMigration = false;
        _showMigrationPrompt = false;
      });
    }
  }

  Future<void> _performMigration() async {
    setState(() {
      _isMigrating = true;
    });

    try {
      final migrationService = MigrationService();
      final result = await migrationService.migrateUserData();
      
      if (result.success && result.totalMigrated > 0) {
        // Clear local data after successful migration
        await migrationService.clearLocalData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.summary),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Migration failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isMigrating = false;
      _showMigrationPrompt = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingMigration) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Checking for data migration...'),
            ],
          ),
        ),
      );
    }

    if (_showMigrationPrompt) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_upload,
                      size: 64,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Migrate Your Data',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'We found local data on your device. Would you like to migrate your favorites, flashcards, and progress to the cloud?',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    if (_isMigrating) ...[
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      const Text('Migrating your data...'),
                    ] else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _showMigrationPrompt = false;
                              });
                            },
                            child: const Text('Skip'),
                          ),
                          ElevatedButton(
                            onPressed: _performMigration,
                            child: const Text('Migrate'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return const HomeScreen();
  }
}

