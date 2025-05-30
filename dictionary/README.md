# 🗾 Jisho Japanese Dictionary App

A comprehensive Japanese learning app built with Flutter, featuring dictionary search, spaced repetition flashcards, and cross-platform compatibility.

## ✨ Features

### 📚 **Dictionary & Word Lookup**
- **Multi-language search**: English, Japanese (kanji/hiragana/katakana), and full sentences
- **Rich word details**: Multiple readings, definitions, parts of speech, JLPT levels
- **Real-time search** powered by Jisho.org API
- **Cross-references**: Links to related words and additional context

### ⭐ **Favorites System**
- Save words for later reference with persistent storage
- Quick toggle from search results and word details
- Dedicated favorites screen for browsing saved words

### 🧠 **Advanced Flashcard System**
- **Spaced Repetition System (SRS)** using SM-2 algorithm
- **Four difficulty levels**: Again, Hard, Good, Easy
- **Smart scheduling**: Adaptive intervals based on performance
- **Study modes**: Review due cards or study all cards
- **Progress tracking**: Learning phases and review statistics

### 📋 **Word Lists Management**
- Create custom word lists for organized vocabulary learning
- Add words directly from search results to specific lists
- List-based study sessions and organizational tools

### 🎯 **Study Interface**
- Interactive flashcard review with show/hide answers
- Real-time progress tracking during study sessions
- Difficulty-based feedback that adjusts future schedules

## 🌐 Platform Support

**Fully Cross-Platform Compatible:**
- 📱 **Mobile**: iOS and Android
- 🖥️ **Desktop**: macOS, Windows, Linux  
- 🌐 **Web**: All modern browsers (Chrome, Firefox, Safari, Edge)

**Smart Platform Adaptation:**
- Direct API access on mobile/desktop platforms
- Automatic CORS proxy routing for web browsers
- Platform-optimized storage (SQLite for native, IndexedDB for web)

## 🚀 Quick Start

### Prerequisites
- [Flutter](https://flutter.dev/docs/get-started/install) (SDK 3.7.2+)
- Platform-specific development tools:
  - **iOS**: Xcode
  - **Android**: Android Studio
  - **Web**: Chrome/Firefox
  - **Desktop**: Platform-specific toolchain

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd dictionary
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   # Web
   flutter run -d chrome
   
   # Mobile (with device connected)
   flutter run
   
   # Desktop
   flutter run -d macos    # macOS
   flutter run -d windows  # Windows
   flutter run -d linux    # Linux
   ```

### Building for Production

```bash
# Web (optimized build)
flutter build web --release

# Mobile
flutter build apk --release    # Android
flutter build ios --release    # iOS

# Desktop
flutter build macos --release  # macOS
flutter build windows --release # Windows
flutter build linux --release  # Linux
```

## 🏗️ Architecture

### **Storage System**
- **Cross-platform abstraction**: Unified storage interface
- **SQLite**: High-performance local database for mobile/desktop
- **IndexedDB**: Browser-native storage for web platforms
- **Auto-detection**: Platform-appropriate storage backend selection

### **API Integration**
- **Jisho.org API**: Primary Japanese dictionary data source
- **CORS Solution**: Transparent proxy routing for web browsers
- **Error Handling**: Robust network error recovery and retry logic
- **Debug Tools**: Built-in API connectivity testing and troubleshooting

### **Service Architecture**
- **Singleton Services**: `FavoritesService`, `FlashcardService`, `WordListService`
- **Reactive Updates**: ChangeNotifier pattern for real-time UI updates
- **Lazy Loading**: Efficient data loading on first access

## 📱 Screenshots & Demo

### Example API Responses
The app handles various search types seamlessly:

- **English search**: `house` → [house.json](house.json)
- **Japanese kanji**: `漢字` → [漢字.json](漢字.json)  
- **Full sentences**: `私は駅に行きます` → [私は駅に行きます.json](私は駅に行きます.json)

## 🔧 Development

### **Debug Tools**
Access the API Debug screen through the Dictionary screen (⋮ menu):
- **Connectivity testing**: Real-time API health checks
- **Configuration display**: Current platform and endpoint info
- **Manual search testing**: Custom API query testing
- **Troubleshooting**: Platform-specific recommendations

### **Project Structure**
```
lib/
├── config/          # API configuration and platform detection
├── models/          # Data models (WordEntry, Flashcard, etc.)
├── screens/         # UI screens and navigation
├── services/        # Business logic and data management
├── widgets/         # Reusable UI components
└── main.dart        # App entry point
```

### **Key Dependencies**
- **HTTP**: API communication (`http: ^1.2.0`)
- **Storage**: Cross-platform persistence (`sqflite`, `idb_shim`, `shared_preferences`)
- **Platform Detection**: `universal_platform: ^1.1.0`
- **UI**: Material Design 3 components

## 📚 Learning Features

### **Spaced Repetition System**
The app implements the scientifically-proven SM-2 algorithm:
- **Adaptive intervals**: Difficulty-based scheduling (1 day → weeks → months)
- **Ease factor**: Performance-based adjustment (1.3 - 2.5 range)
- **Learning phases**: New cards graduate to review status
- **Due date calculation**: Intelligent scheduling based on past performance

### **Study Statistics**
- Total flashcards and favorites count
- Due cards for review today
- Learning vs. review card ratios
- Session completion tracking

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 Documentation

- **[Development Guide](DEVELOPMENT_GUIDE.md)**: Detailed development setup and workflows
- **[Storage Architecture](STORAGE_ARCHITECTURE.md)**: Technical deep-dive into data persistence

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- **Jisho.org**: Excellent Japanese dictionary API and data source
- **Flutter Team**: Amazing cross-platform development framework
- **Contributors**: Everyone who has contributed to making this app better

---

**Built with ❤️ for Japanese language learners**