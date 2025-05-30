import 'package:universal_platform/universal_platform.dart';
import 'enhanced_storage_interface.dart';
import 'enhanced_sqlite_storage.dart';
import 'enhanced_web_storage.dart';

/// Factory class to create appropriate enhanced storage implementation based on platform
class EnhancedStorageFactory {
  static EnhancedStorageInterface createStorage() {
    if (UniversalPlatform.isWeb) {
      return EnhancedWebStorage();
    } else {
      // Use SQLite for mobile platforms (iOS, Android, desktop)
      return EnhancedSqliteStorage();
    }
  }
}