import 'package:flutter_tts/flutter_tts.dart';
import '../models/message_model.dart';

/// Service for Text-to-Speech functionality
class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  /// Initialize TTS engine
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _isInitialized = true;
  }

  /// Speak a message
  Future<void> speak(String text) async {
    await initialize();
    await _flutterTts.speak(text);
  }

  /// Read a message aloud with sender info
  Future<void> readMessage(MessageModel message) async {
    await initialize();
    final text = "New ${message.appSource} message from ${message.senderName}: ${message.messageContent}";
    await speak(text);
  }

  /// Announce new message arrival
  Future<void> announceNewMessage() async {
    await initialize();
    await speak("You have a new message");
  }

  /// Stop speaking
  Future<void> stop() async {
    await _flutterTts.stop();
  }

  /// Set speech rate (0.0 to 1.0)
  Future<void> setSpeechRate(double rate) async {
    await _flutterTts.setSpeechRate(rate);
  }

  /// Set pitch (0.5 to 2.0)
  Future<void> setPitch(double pitch) async {
    await _flutterTts.setPitch(pitch);
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    await _flutterTts.setVolume(volume);
  }

  /// Get available voices
  Future<List<dynamic>> getVoices() async {
    return await _flutterTts.getVoices;
  }

  /// Set voice
  Future<void> setVoice(Map<String, String> voice) async {
    await _flutterTts.setVoice(voice);
  }

  /// Check if speaking
  Future<bool> isSpeaking() async {
    return await _flutterTts.awaitSpeakCompletion(true);
  }
}
