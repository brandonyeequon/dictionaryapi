import 'storage_interface.dart';
import 'firebase_basic_storage.dart';

/// Factory class to create Firebase storage implementation
/// Updated to use Firebase/Firestore for all platforms
class StorageFactory {
  static StorageInterface createStorage() {
    return FirebaseBasicStorage();
  }
}