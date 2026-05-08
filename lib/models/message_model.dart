/// Model class representing a notification message
class MessageModel {
  final int? id;
  final String senderName;
  final String messageContent;
  final String appSource;
  final DateTime timestamp;
  final bool isRead;

  MessageModel({
    this.id,
    required this.senderName,
    required this.messageContent,
    required this.appSource,
    required this.timestamp,
    this.isRead = false,
  });

  /// Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderName': senderName,
      'messageContent': messageContent,
      'appSource': appSource,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead ? 1 : 0,
    };
  }

  /// Create from Map (database)
  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'],
      senderName: map['senderName'],
      messageContent: map['messageContent'],
      appSource: map['appSource'],
      timestamp: DateTime.parse(map['timestamp']),
      isRead: map['isRead'] == 1,
    );
  }

  /// Create a copy with modified fields
  MessageModel copyWith({
    int? id,
    String? senderName,
    String? messageContent,
    String? appSource,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderName: senderName ?? this.senderName,
      messageContent: messageContent ?? this.messageContent,
      appSource: appSource ?? this.appSource,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}
