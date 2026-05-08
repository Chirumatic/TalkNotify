import 'package:speech_to_text/speech_to_text.dart';

/// Service for Speech Recognition
class SpeechService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  bool get isListening => _isListening;

  /// Initialize speech recognition
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    _isInitialized = await _speechToText.initialize(
      onError: (error) => print('Speech error: $error'),
      onStatus: (status) => print('Speech status: $status'),
    );
    return _isInitialized;
  }

  /// Start listening for voice commands
  Future<void> startListening({
    required Function(String) onResult,
    Function(String)? onPartialResult,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_isInitialized) return;

    _isListening = true;
    await _speechToText.listen(
      onResult: (result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
          _isListening = false;
        } else if (onPartialResult != null) {
          onPartialResult(result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      cancelOnError: true,
      listenMode: ListenMode.confirmation,
    );
  }

  /// Stop listening
  Future<void> stopListening() async {
    _isListening = false;
    await _speechToText.stop();
  }

  /// Cancel listening
  Future<void> cancelListening() async {
    _isListening = false;
    await _speechToText.cancel();
  }

  /// Check if speech recognition is available
  Future<bool> isAvailable() async {
    return await _speechToText.initialize();
  }

  /// Get available locales
  Future<List<dynamic>> getLocales() async {
    return await _speechToText.locales();
  }
}
