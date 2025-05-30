/// API Configuration for Jisho.org dictionary API
library;

import 'package:universal_platform/universal_platform.dart';

class ApiConfig {
  /// Direct Jisho.org API URL
  static const String _directJishoUrl = 'https://jisho.org/api/v1/search/words';

  /// Returns the API URL
  static String get apiUrl => _directJishoUrl;

  /// Indicates whether we're using web platform (needs CORS workaround)
  static bool get isWeb => UniversalPlatform.isWeb;

  /// Returns the platform name
  static String get platform {
    if (UniversalPlatform.isWeb) return 'web';
    if (UniversalPlatform.isAndroid) return 'android';
    if (UniversalPlatform.isIOS) return 'ios';
    if (UniversalPlatform.isMacOS) return 'macos';
    if (UniversalPlatform.isWindows) return 'windows';
    if (UniversalPlatform.isLinux) return 'linux';
    return 'unknown';
  }


  /// Build the complete URL for a search request
  static String buildSearchUrl(String keyword) {
    final encodedKeyword = Uri.encodeComponent(keyword.trim());
    
    if (isWeb) {
      // Use CORS proxy for web
      final jishoUrl = Uri.encodeComponent('$apiUrl?keyword=$encodedKeyword');
      return 'https://api.allorigins.win/get?url=$jishoUrl';
    } else {
      // Direct API for mobile/desktop
      return '$apiUrl?keyword=$encodedKeyword';
    }
  }

}