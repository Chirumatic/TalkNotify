import 'dart:async';
import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../models/app_settings.dart';
import '../services/database_service.dart';
import '../services/tts_service.dart';
import '../services/speech_service.dart';
import '../services/settings_service.dart';
import '../services/notification_service.dart';
import '../services/message_stream_service.dart';

/// Main app state provider
class AppProvider with ChangeNotifier {
  final TtsService _ttsService = TtsService();
  final SpeechService _speechService = SpeechService();
  final DatabaseService _dbService = DatabaseService.instance;
  final SettingsService _settingsService = SettingsService.instance;
  final NotificationService _notificationService = NotificationService.instance;

  MessageModel? _latestMessage;
  List<MessageModel> _messageHistory = [];
  AppSettings _settings = AppSettings();
  bool _isListening = false;
  String _recognizedText = '';
  StreamSubscription? _messageSubscription;

  // Getters
  MessageModel? get latestMessage => _latestMessage;
  List<MessageModel> get messageHistory => _messageHistory;
  AppSettings get settings => _settings;
  bool get isListening => _isListening;
  String get recognizedText => _recognizedText;

  /// Initialize all services
  Future<void> initialize() async {
    await _ttsService.initialize();
    await _speechService.initialize();
    await _settingsService.initialize();
    await _notificationService.initialize();
    await loadSettings();
    await loadMessages();
    _subscribeToMessageStream();
  }

  /// Subscribe to incoming notifications from Android
  void _subscribeToMessageStream() {
    _messageSubscription?.cancel();
    _messageSubscription = MessageStreamService.instance.messageStream.listen(
      (message) => addMessage(message),
      onError: (e) => print('Message stream error: $e'),
    );
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  /// Load settings from storage
  Future<void> loadSettings() async {
    _settings = await _settingsService.loadSettings();
    await _ttsService.setSpeechRate(_settings.speechRate);
    await _ttsService.setPitch(_settings.speechPitch);
    await _ttsService.setVolume(_settings.speechVolume);
    notifyListeners();
  }

  /// Save settings
  Future<void> saveSettings(AppSettings newSettings) async {
    _settings = newSettings;
    await _settingsService.saveSettings(newSettings);
    await _ttsService.setSpeechRate(newSettings.speechRate);
    await _ttsService.setPitch(newSettings.speechPitch);
    await _ttsService.setVolume(newSettings.speechVolume);
    notifyListeners();
  }

  /// Load messages from database
  Future<void> loadMessages() async {
    _messageHistory = await _dbService.getAllMessages();
    if (_messageHistory.isNotEmpty) {
      _latestMessage = _messageHistory.first;
    }
    notifyListeners();
  }

  /// Add new message
  Future<void> addMessage(MessageModel message) async {
    final savedMessage = await _dbService.insertMessage(message);
    _latestMessage = savedMessage;
    _messageHistory.insert(0, savedMessage);
    notifyListeners();

    // In driving mode — always read full message aloud
    if (_settings.drivingModeEnabled) {
      await _ttsService.readMessage(savedMessage);
      return;
    }

    // Alert user based on settings
    if (_settings.voiceAlertsEnabled) {
      await _ttsService.announceNewMessage();
    }
    if (_settings.soundAlertsEnabled || _settings.vibrationEnabled) {
      await _notificationService.showNotification(
        title: 'New Message from ${message.senderName}',
        body: message.messageContent,
        playSound: _settings.soundAlertsEnabled,
        vibrate: _settings.vibrationEnabled,
      );
    }
  }

  /// Read latest message aloud
  Future<void> readLatestMessage() async {
    if (_latestMessage != null) {
      await _ttsService.readMessage(_latestMessage!);
      if (_latestMessage!.id != null) {
        await _dbService.markAsRead(_latestMessage!.id!);
        await loadMessages();
      }
    }
  }

  /// Read specific message
  Future<void> readMessage(MessageModel message) async {
    await _ttsService.readMessage(message);
    if (message.id != null) {
      await _dbService.markAsRead(message.id!);
      await loadMessages();
    }
  }

  /// Stop reading
  Future<void> stopReading() async {
    await _ttsService.stop();
  }

  /// Start voice listening
  Future<void> startListening() async {
    _isListening = true;
    notifyListeners();

    await _speechService.startListening(
      onResult: (text) {
        _recognizedText = text;
        _isListening = false;
        notifyListeners();
        _processVoiceCommand(text);
      },
      onPartialResult: (text) {
        _recognizedText = text;
        notifyListeners();
      },
    );
  }

  /// Stop voice listening
  Future<void> stopListening() async {
    _isListening = false;
    await _speechService.stopListening();
    notifyListeners();
  }

  /// Process voice commands
  Future<void> _processVoiceCommand(String command) async {
    final lowerCommand = command.toLowerCase();

    // Wake word check — "hey talknotify"
    if (lowerCommand.contains('hey talknotify') || lowerCommand.contains('hey talk notify')) {
      await _ttsService.speak('Yes, I am listening');
      await startListening();
      return;
    }

    if (lowerCommand.contains('read') &&
        (lowerCommand.contains('message') || lowerCommand.contains('latest'))) {
      await readLatestMessage();
    } else if (lowerCommand.contains('who texted') || lowerCommand.contains('who messaged')) {
      if (_latestMessage != null) {
        await _ttsService.speak('${_latestMessage!.senderName} sent you a message via ${_latestMessage!.appSource}');
      }
    } else if (lowerCommand.contains('whatsapp')) {
      final msgs = await _dbService.getMessagesByApp('WhatsApp');
      if (msgs.isNotEmpty) await _ttsService.readMessage(msgs.first);
    } else if (lowerCommand.contains('telegram')) {
      final msgs = await _dbService.getMessagesByApp('Telegram');
      if (msgs.isNotEmpty) await _ttsService.readMessage(msgs.first);
    } else if (lowerCommand.contains('sms')) {
      final msgs = await _dbService.getMessagesByApp('SMS');
      if (msgs.isNotEmpty) await _ttsService.readMessage(msgs.first);
    } else if (lowerCommand.contains('stop')) {
      await stopReading();
    } else if (lowerCommand.contains('repeat')) {
      await readLatestMessage();
    } else if (lowerCommand.contains('driving mode on')) {
      await saveSettings(_settings.copyWith(drivingModeEnabled: true));
      await _ttsService.speak('Driving mode activated. I will read all messages automatically.');
    } else if (lowerCommand.contains('driving mode off')) {
      await saveSettings(_settings.copyWith(drivingModeEnabled: false));
      await _ttsService.speak('Driving mode deactivated.');
    } else if (lowerCommand.contains('how many messages') || lowerCommand.contains('unread')) {
      final unread = _messageHistory.where((m) => !m.isRead).length;
      await _ttsService.speak('You have $unread unread messages.');
    } else {
      // Unknown command
      await _ttsService.speak('Sorry, I did not understand that command.');
    }
  }

  /// Filter messages by app
  List<MessageModel> filterMessagesByApp(String appSource) {
    return _messageHistory.where((msg) => msg.appSource == appSource).toList();
  }

  /// Search messages
  List<MessageModel> searchMessages(String query) {
    final lowerQuery = query.toLowerCase();
    return _messageHistory.where((msg) {
      return msg.senderName.toLowerCase().contains(lowerQuery) ||
          msg.messageContent.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Clear all messages
  Future<void> clearAllMessages() async {
    await _dbService.clearAllMessages();
    _messageHistory.clear();
    _latestMessage = null;
    notifyListeners();
  }

  /// Delete specific message
  Future<void> deleteMessage(int id) async {
    await _dbService.deleteMessage(id);
    await loadMessages();
  }
}
