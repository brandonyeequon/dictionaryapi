import 'package:universal_platform/universal_platform.dart';
import 'storage_interface.dart';
import 'sqlite_storage.dart';
import 'web_storage.dart';

/// Factory class to create appropriate storage implementation based on platform
class StorageFactory {
  static StorageInterface createStorage() {
    if (UniversalPlatform.isWeb) {
      return WebStorage();
    } else {
      // Use SQLite for mobile platforms (iOS, Android, desktop)
      return SQLiteStorage();
    }
  }
}