import '../enhanced_storage_interface.dart';
import 'firestore_storage.dart';

/// Factory class to create Firebase/Firestore storage implementation
class FirebaseStorageFactory {
  static EnhancedStorageInterface createStorage() {
    return FirestoreStorage();
  }
}