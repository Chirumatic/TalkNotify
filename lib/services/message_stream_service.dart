import 'package:flutter/services.dart';
import '../models/message_model.dart';

/// Listens to the Android EventChannel for incoming notifications
class MessageStreamService {
  static final MessageStreamService instance = MessageStreamService._init();
  static const EventChannel _eventChannel =
      EventChannel('com.example.talknotify/message_stream');

  MessageStreamService._init();

  /// Returns a stream of incoming messages from the native side
  Stream<MessageModel> get messageStream {
    return _eventChannel.receiveBroadcastStream().map((event) {
      final data = Map<String, dynamic>.from(event as Map);
      return MessageModel(
        senderName: data['sender'] ?? 'Unknown',
        messageContent: data['message'] ?? '',
        appSource: data['appSource'] ?? 'Unknown',
        timestamp: DateTime.now(),
      );
    });
  }
}
