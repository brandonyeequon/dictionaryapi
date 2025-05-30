# 🛠️ Development Guide

A comprehensive guide for setting up and developing the Jisho Japanese Dictionary app.

## 🚀 Quick Start

The app is designed to work out-of-the-box on all platforms with zero configuration:

```bash
# Install dependencies
flutter pub get

# Run on your preferred platform
flutter run -d chrome    # Web
flutter run -d macos     # Desktop
flutter run              # Mobile (with device connected)
```

## 📋 Prerequisites

### **Flutter SDK**
- **Version**: 3.7.2 or higher
- **Installation**: [Flutter Install Guide](https://flutter.dev/docs/get-started/install)

### **Platform-Specific Tools**

| Platform | Requirements |
|----------|-------------|
| **Web** | Chrome, Firefox, Safari, or Edge |
| **iOS** | Xcode 14+, iOS Simulator or device |
| **Android** | Android Studio, Android SDK, emulator or device |
| **macOS** | Xcode (for native builds) |
| **Windows** | Visual Studio 2019+ with C++ tools |
| **Linux** | Standard build tools, GTK development libraries |

## 🏗️ Project Architecture

### **Directory Structure**
```
lib/
├── config/              # Platform detection & API configuration
│   └── api_config.dart  # CORS handling & endpoint management
├── models/              # Data models
│   ├── word_entry.dart  # Jisho API response models
│   ├── flashcard.dart   # SRS flashcard data
│   ├── word_list.dart   # User word list models
│   └── ...
├── screens/             # UI screens
│   ├── dictionary_screen.dart    # Main search interface
│   ├── word_detail_screen.dart   # Detailed word view
│   ├── flashcards_screen.dart    # SRS study interface
│   ├── api_debug_screen.dart     # Development tools
│   └── ...
├── services/            # Business logic
│   ├── jisho_api_service.dart    # API communication
│   ├── favorites_service.dart    # Favorites management
│   ├── flashcard_service.dart    # SRS implementation
│   ├── storage/                  # Cross-platform storage
│   │   ├── storage_interface.dart
│   │   ├── sqlite_storage.dart
│   │   └── web_storage.dart
│   └── ...
├── widgets/             # Reusable UI components
└── main.dart           # App entry point
```

### **Key Architectural Patterns**

#### **1. Storage Abstraction**
```dart
// Platform-agnostic storage interface
abstract class StorageInterface {
  Future<void> saveWord(String key, Map<String, dynamic> data);
  Future<Map<String, dynamic>?> getWord(String key);
  // ... other methods
}

// Automatic platform detection
class StorageFactory {
  static StorageInterface createStorage() {
    if (UniversalPlatform.isWeb) {
      return WebStorage();        // IndexedDB
    } else {
      return SqliteStorage();     // SQLite
    }
  }
}
```

#### **2. Service Layer Pattern**
```dart
// Singleton services with change notification
class FavoritesService extends ChangeNotifier {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  
  // Reactive UI updates
  void addFavorite(WordEntry word) {
    // ... business logic
    notifyListeners(); // Triggers UI rebuild
  }
}
```

#### **3. Cross-Platform API Handling**
```dart
class ApiConfig {
  // Automatic platform detection
  static String buildSearchUrl(String keyword) {
    if (isWeb) {
      // CORS proxy for web browsers
      return 'https://api.allorigins.win/get?url=${jishoUrl}';
    } else {
      // Direct API for mobile/desktop
      return 'https://jisho.org/api/v1/search/words?keyword=$keyword';
    }
  }
}
```

## 🌐 Platform-Specific Development

### **Web Development**

#### **CORS Solution**
Web browsers block direct API calls to external domains. The app automatically handles this:

```dart
// Web: Uses CORS proxy (transparent to developer)
// Mobile/Desktop: Direct API calls (no CORS restrictions)
```

#### **Storage: IndexedDB**
```dart
// Web storage implementation
class WebStorage implements StorageInterface {
  Future<void> saveWord(String key, Map<String, dynamic> data) async {
    final db = await idb.open('dictionary_db');
    // IndexedDB operations...
  }
}
```

#### **Development Workflow**
```bash
# Development with hot reload
flutter run -d chrome --web-port 8080

# Production build
flutter build web --release

# Serve locally
cd build/web && python -m http.server 8000
```

### **Mobile Development**

#### **Storage: SQLite**
```dart
class SqliteStorage implements StorageInterface {
  Future<Database> get database async {
    return openDatabase(
      join(await getDatabasesPath(), 'dictionary.db'),
      version: 1,
      onCreate: _createTables,
    );
  }
}
```

#### **iOS Development**
```bash
# Run on simulator
flutter run -d "iPhone 14 Pro Simulator"

# Build for App Store
flutter build ios --release
open ios/Runner.xcworkspace  # For signing & upload
```

#### **Android Development**
```bash
# Run on emulator/device
flutter run -d android

# Build APK
flutter build apk --release

# Build App Bundle (Play Store)
flutter build appbundle --release
```

### **Desktop Development**

#### **Direct API Access**
Desktop platforms don't have CORS restrictions:
```dart
// Desktop apps use direct API calls
if (!ApiConfig.isWeb) {
  // Direct HTTPS calls to jisho.org
  final response = await http.get(jishoApiUrl);
}
```

#### **Platform Commands**
```bash
# macOS
flutter run -d macos
flutter build macos --release

# Windows  
flutter run -d windows
flutter build windows --release

# Linux
flutter run -d linux
flutter build linux --release
```

## 🧪 Testing & Debugging

### **API Debug Screen**
Access through Dictionary screen → ⋮ menu → "API Debug":

```dart
// Debug information available:
- Platform detection (Web/Mobile/Desktop)
- Current API endpoint being used
- CORS proxy status
- Real-time connectivity testing
- Manual search testing
```

### **Debugging Tools**

#### **1. API Connectivity**
```dart
// Test API connectivity
final result = await JishoApiService.testConnectivity();
print('Status: ${result['status']}');
print('Response Time: ${result['responseTime']}ms');
```

#### **2. Storage Debugging**
```dart
// Inspect storage state
final favorites = await FavoritesService().getAllFavorites();
final flashcards = await FlashcardService().getAllFlashcards();
print('Favorites: ${favorites.length}');
print('Flashcards: ${flashcards.length}');
```

#### **3. Platform Detection**
```dart
print('Platform: ${ApiConfig.platform}');
print('Is Web: ${ApiConfig.isWeb}');
print('API URL: ${ApiConfig.apiUrl}');
```

### **Common Issues & Solutions**

#### **Web: CORS Errors**
```
❌ Error: "Access to fetch has been blocked by CORS policy"
✅ Solution: Already handled automatically by allorigins.win proxy
```

#### **Mobile: Network Permissions**
```xml
<!-- Android: Add to android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.INTERNET" />
```

#### **Desktop: Certificate Issues**
```dart
// If HTTPS certificate issues on older systems
HttpOverrides.global = MyHttpOverrides();
```

## 📊 Performance Optimization

### **API Response Times**
| Platform | Method | Typical Response Time |
|----------|--------|----------------------|
| Web | CORS Proxy | 300-500ms |
| Mobile | Direct API | 200-300ms |
| Desktop | Direct API | 150-250ms |

### **Storage Performance**
```dart
// Batch operations for better performance
await storage.batchInsert(multipleWords);

// Lazy loading for large datasets
final stream = storage.getWordsStream(limit: 50);
```

### **UI Optimization**
```dart
// Use const constructors where possible
const WordCard(word: word, key: ValueKey(word.slug));

// Implement efficient list building
ListView.builder(
  itemBuilder: (context, index) => WordCard(word: words[index]),
  itemCount: words.length,
);
```

## 🔄 Development Workflow

### **1. Feature Development**
```bash
# Create feature branch
git checkout -b feature/new-study-mode

# Develop with hot reload
flutter run -d chrome

# Test on multiple platforms
flutter run -d macos
flutter run -d android
```

### **2. Testing Strategy**
```bash
# Unit tests
flutter test

# Integration tests  
flutter test integration_test/

# Widget tests
flutter test test/widget_test.dart
```

### **3. Build & Release**
```bash
# Test builds for all target platforms
flutter build web --release
flutter build apk --release  
flutter build macos --release

# Verify functionality across platforms
```

## 🔧 Advanced Configuration

### **Custom Storage Location**
```dart
// Override default storage path
class CustomStorageFactory {
  static StorageInterface createStorage({String? customPath}) {
    // Custom implementation
  }
}
```

### **API Configuration**
```dart
// Environment-specific API settings
class ApiConfig {
  static const bool enableDebugLogging = kDebugMode;
  static const Duration requestTimeout = Duration(seconds: 10);
  
  // Custom proxy URL for testing
  static void setCustomProxyUrl(String url) {
    // Override default proxy
  }
}
```

### **Theme Customization**
```dart
// Custom app theme
ThemeData customTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
  // ... custom theme settings
);
```

## 📱 Platform-Specific Features

### **Web PWA Support**
```html
<!-- web/index.html - Already configured -->
<link rel="manifest" href="manifest.json">
<meta name="theme-color" content="#2196F3">
```

### **Mobile Deep Linking**
```dart
// Future enhancement: Deep link to specific words
// dictionary://word/house
```

### **Desktop Integration**
```dart
// Native menu integration (macOS/Windows/Linux)
// File associations for dictionary exports
```

## 🚀 Deployment

### **Web Deployment**
```bash
# Build for production
flutter build web --release

# Deploy to hosting service
# - Firebase Hosting: firebase deploy
# - Netlify: drag build/web folder
# - GitHub Pages: copy build/web to gh-pages branch
```

### **Mobile App Stores**
```bash
# iOS App Store
flutter build ios --release
# Submit via Xcode or Transporter

# Google Play Store  
flutter build appbundle --release
# Upload via Play Console
```

### **Desktop Distribution**
```bash
# macOS App Store
flutter build macos --release
# Submit via App Store Connect

# Windows Store
flutter build windows --release
# Package with MSIX for Store submission

# Linux Repositories
flutter build linux --release
# Create .deb/.rpm packages
```

---

## 🎯 Next Steps

1. **Set up your development environment** using the quick start guide
2. **Explore the API Debug screen** to understand the current configuration
3. **Review the Storage Architecture documentation** for advanced storage topics
4. **Start developing** - the app is ready for feature additions!

The architecture is designed to be developer-friendly with clear separation of concerns, comprehensive error handling, and cross-platform compatibility built-in from day one.