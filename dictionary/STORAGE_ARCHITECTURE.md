# Cross-Platform Storage Architecture

## Overview

The Japanese Dictionary app now uses a sophisticated storage abstraction layer that provides seamless data persistence across all Flutter platforms including web, mobile (iOS/Android), and desktop.

## Architecture Components

### 1. Storage Interface (`storage_interface.dart`)
- Abstract interface defining all storage operations
- Platform-agnostic API for favorites and flashcards
- Extensible for future features like word lists

### 2. Storage Factory (`storage_factory.dart`)
- Factory pattern implementation
- Automatically selects appropriate storage backend based on platform
- Uses `UniversalPlatform` to detect web vs native platforms

### 3. Platform-Specific Implementations

#### SQLite Storage (`sqlite_storage.dart`)
- **Platforms**: iOS, Android, macOS, Linux, Windows
- **Technology**: SQLite database with `sqflite` package
- **Features**:
  - Relational database structure
  - ACID compliance
  - Foreign key constraints
  - Efficient indexing and querying

#### Web Storage (`web_storage.dart`)
- **Platform**: Web browsers
- **Technology**: IndexedDB with `idb_shim` package
- **Features**:
  - NoSQL object store
  - Async operations
  - Indexes for efficient querying
  - Transaction support

## Database Schema

### Favorites Table/Store
```sql
- slug (PRIMARY KEY)
- word_data (JSON serialized WordEntry)
- created_at (timestamp)
```

### Flashcards Table/Store
```sql
- id (PRIMARY KEY)
- word_slug (UNIQUE)
- word (text)
- reading (text)
- definition (text)
- tags (JSON array)
- created_at (timestamp)
- last_reviewed (timestamp)
- next_review (timestamp)
- interval_days (integer)
- ease_factor (integer, stored as 250 = 2.5)
- repetitions (integer)
- is_learning (boolean)
```

## Service Layer Updates

### FlashcardService
- Updated to use storage abstraction
- Automatic platform detection and initialization
- Maintains in-memory cache for performance
- Spaced Repetition System (SRS) algorithm unchanged

### FavoritesService
- Updated to use storage abstraction
- Automatic platform detection and initialization
- Set-based slug tracking for O(1) lookup
- List management for UI display

## Benefits

### 1. Platform Compatibility
- **Web**: Uses IndexedDB for persistent browser storage
- **Mobile**: Uses SQLite for optimal performance and reliability
- **Desktop**: Uses SQLite with native file system access

### 2. Developer Experience
- Single codebase works across all platforms
- No platform-specific code in business logic
- Easy to add new storage backends

### 3. Performance Optimization
- IndexedDB provides async operations for web without blocking UI
- SQLite provides optimized queries and indexes for mobile
- In-memory caching reduces database calls

### 4. Data Consistency
- Same data model across all platforms
- JSON serialization ensures compatibility
- Transaction support maintains data integrity

## Future Extensibility

The architecture is designed to support:
- **Cloud Sync**: Add cloud storage backend (Firebase, Supabase)
- **Offline-First**: Current design already supports offline operation
- **Data Migration**: Version management for schema updates
- **Backup/Restore**: Export/import functionality
- **Multi-User**: User-specific data partitioning

## Usage

The storage abstraction is transparent to the UI layer:

```dart
// Services automatically use appropriate storage
final flashcardService = FlashcardService();
await flashcardService.loadFlashcards(); // Works on all platforms

final favoritesService = FavoritesService();
await favoritesService.loadFavorites(); // Works on all platforms
```

## Migration from Previous Architecture

The previous architecture used `DatabaseService` directly, which only supported SQLite. The new architecture:

1. Maintains API compatibility at the service layer
2. Automatically migrates existing SQLite data on mobile platforms
3. Provides new IndexedDB storage for web platform
4. No changes required in UI components

## Testing

- **Web**: Test in Chrome, Firefox, Safari, Edge
- **Mobile**: Test on iOS and Android devices
- **Desktop**: Test on macOS, Windows, Linux (if supported)
- **Cross-Platform**: Verify data consistency and feature parity

This architecture ensures the Japanese Dictionary app provides a consistent, reliable experience across all platforms while leveraging the best storage technology for each platform's capabilities.