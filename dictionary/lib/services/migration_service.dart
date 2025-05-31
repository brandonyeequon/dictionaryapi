import 'dart:async';
import 'package:flutter/foundation.dart';
import 'storage/firestore_storage.dart';
import 'auth_service.dart';

/// Service to migrate user data from local storage to Firebase
class MigrationService {
  static final MigrationService _instance = MigrationService._internal();
  factory MigrationService() => _instance;
  MigrationService._internal();

  final AuthService _authService = AuthService();

  /// Check if migration is needed (user has local data but no cloud data)
  Future<bool> isMigrationNeeded() async {
    if (!_authService.isSignedIn) return false;

    try {
      // Check if user has any cloud data
      final cloudStorage = FirestoreStorage();
      await cloudStorage.initialize();
      
      final cloudFavorites = await cloudStorage.getFavorites();
      final cloudFlashcards = await cloudStorage.getAllFlashcards();
      
      // If user has cloud data, no migration needed
      if (cloudFavorites.isNotEmpty || cloudFlashcards.isNotEmpty) {
        return false;
      }

      // For now, return false since we've removed local storage
      // In a real migration, you'd check SharedPreferences or other local storage
      return false;
    } catch (e) {
      debugPrint('Error checking migration status: $e');
      return false;
    }
  }

  /// Migrate user data from local storage to Firebase
  Future<MigrationResult> migrateUserData() async {
    if (!_authService.isSignedIn) {
      return MigrationResult(
        success: false,
        error: 'User must be signed in to migrate data',
      );
    }

    // Since we've removed local storage, this is now a no-op
    // In a real migration, you'd migrate from SharedPreferences or other storage
    return MigrationResult(success: true);
  }

  /// Clear local data after successful migration
  Future<bool> clearLocalData() async {
    // Since we've removed local storage, this is now a no-op
    return true;
  }
}

/// Result of migration operation
class MigrationResult {
  final bool success;
  final String? error;
  int migratedFavorites = 0;
  int migratedFlashcards = 0;
  int migratedWordLists = 0;
  int migratedStudySessions = 0;
  bool migratedUserProgress = false;

  MigrationResult({
    required this.success,
    this.error,
  });

  /// Total number of items migrated
  int get totalMigrated => 
      migratedFavorites + 
      migratedFlashcards + 
      migratedWordLists + 
      migratedStudySessions + 
      (migratedUserProgress ? 1 : 0);

  /// Summary message for display to user
  String get summary {
    if (!success) {
      return error ?? 'Migration failed';
    }
    
    if (totalMigrated == 0) {
      return 'No data to migrate';
    }

    final items = <String>[];
    if (migratedFavorites > 0) {
      items.add('$migratedFavorites favorites');
    }
    if (migratedFlashcards > 0) {
      items.add('$migratedFlashcards flashcards');
    }
    if (migratedWordLists > 0) {
      items.add('$migratedWordLists word lists');
    }
    if (migratedStudySessions > 0) {
      items.add('$migratedStudySessions study sessions');
    }
    if (migratedUserProgress) {
      items.add('user progress');
    }

    return 'Successfully migrated ${items.join(', ')}';
  }
}