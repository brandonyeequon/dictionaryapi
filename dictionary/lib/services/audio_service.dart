import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../config/jotoba_config.dart';

/// Service for playing audio pronunciation of Japanese words
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  /// Get the current playing status
  bool get isPlaying => _isPlaying;

  /// Play audio from a URL (handles both relative and absolute URLs)
  Future<bool> playAudio(String audioUrl) async {
    try {
      if (_isPlaying) {
        await stopAudio();
      }

      // Convert relative URLs to absolute URLs
      final fullUrl = _getFullAudioUrl(audioUrl);
      debugPrint('[AudioService] Playing audio: $fullUrl');
      
      _isPlaying = true;
      await _audioPlayer.play(UrlSource(fullUrl));
      
      // Listen for completion
      _audioPlayer.onPlayerComplete.listen((_) {
        _isPlaying = false;
      });
      
      return true;
    } catch (e) {
      debugPrint('[AudioService] Error playing audio: $e');
      debugPrint('[AudioService] Original URL: $audioUrl');
      debugPrint('[AudioService] Full URL attempted: ${_getFullAudioUrl(audioUrl)}');
      _isPlaying = false;
      return false;
    }
  }

  /// Stop current audio playback
  Future<void> stopAudio() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
    } catch (e) {
      debugPrint('[AudioService] Error stopping audio: $e');
    }
  }

  /// Pause current audio playback
  Future<void> pauseAudio() async {
    try {
      await _audioPlayer.pause();
      _isPlaying = false;
    } catch (e) {
      debugPrint('[AudioService] Error pausing audio: $e');
    }
  }

  /// Resume paused audio playback
  Future<void> resumeAudio() async {
    try {
      await _audioPlayer.resume();
      _isPlaying = true;
    } catch (e) {
      debugPrint('[AudioService] Error resuming audio: $e');
    }
  }

  /// Set the audio volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      debugPrint('[AudioService] Error setting volume: $e');
    }
  }

  /// Convert relative URLs to absolute URLs
  String _getFullAudioUrl(String audioUrl) {
    // If already an absolute URL, return as-is
    if (audioUrl.startsWith('http://') || audioUrl.startsWith('https://')) {
      return audioUrl;
    }
    
    // If relative URL, prepend the Jotoba base URL
    if (audioUrl.startsWith('/')) {
      return '${JotobaConfig.apiBaseUrl}$audioUrl';
    }
    
    // If no leading slash, add it
    return '${JotobaConfig.apiBaseUrl}/$audioUrl';
  }

  /// Dispose of the audio player
  void dispose() {
    _audioPlayer.dispose();
  }
}