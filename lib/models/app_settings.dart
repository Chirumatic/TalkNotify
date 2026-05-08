/// Model for app settings
class AppSettings {
  final bool voiceAlertsEnabled;
  final bool soundAlertsEnabled;
  final bool vibrationEnabled;
  final bool isDarkMode;
  final double speechRate;
  final double speechPitch;
  final double speechVolume;
  final bool drivingModeEnabled;
  final bool dndEnabled;
  final int dndStartHour;
  final int dndEndHour;
  // Per-app settings
  final bool readWhatsApp;
  final bool readSms;
  final bool readTelegram;
  final bool readMessenger;
  final bool readInstagram;
  // Priority contacts (comma-separated names)
  final String priorityContacts;
  // Auto-reply message
  final String autoReplyMessage;
  final bool autoReplyEnabled;

  AppSettings({
    this.voiceAlertsEnabled = true,
    this.soundAlertsEnabled = true,
    this.vibrationEnabled = true,
    this.isDarkMode = false,
    this.speechRate = 0.5,
    this.speechPitch = 1.0,
    this.speechVolume = 1.0,
    this.drivingModeEnabled = false,
    this.dndEnabled = false,
    this.dndStartHour = 22,
    this.dndEndHour = 6,
    this.readWhatsApp = true,
    this.readSms = true,
    this.readTelegram = true,
    this.readMessenger = true,
    this.readInstagram = true,
    this.priorityContacts = '',
    this.autoReplyMessage = "I'm driving, will reply soon.",
    this.autoReplyEnabled = false,
  });

  /// Check if a given app source is enabled
  bool isAppEnabled(String appSource) {
    switch (appSource.toLowerCase()) {
      case 'whatsapp':
      case 'whatsapp business':
        return readWhatsApp;
      case 'sms':
        return readSms;
      case 'telegram':
        return readTelegram;
      case 'messenger':
        return readMessenger;
      case 'instagram':
        return readInstagram;
      default:
        return true;
    }
  }

  /// Check if sender is a priority contact
  bool isPriorityContact(String senderName) {
    if (priorityContacts.isEmpty) return false;
    final contacts = priorityContacts.toLowerCase().split(',').map((e) => e.trim());
    return contacts.any((c) => senderName.toLowerCase().contains(c));
  }

  AppSettings copyWith({
    bool? voiceAlertsEnabled,
    bool? soundAlertsEnabled,
    bool? vibrationEnabled,
    bool? isDarkMode,
    double? speechRate,
    double? speechPitch,
    double? speechVolume,
    bool? drivingModeEnabled,
    bool? dndEnabled,
    int? dndStartHour,
    int? dndEndHour,
    bool? readWhatsApp,
    bool? readSms,
    bool? readTelegram,
    bool? readMessenger,
    bool? readInstagram,
    String? priorityContacts,
    String? autoReplyMessage,
    bool? autoReplyEnabled,
  }) {
    return AppSettings(
      voiceAlertsEnabled: voiceAlertsEnabled ?? this.voiceAlertsEnabled,
      soundAlertsEnabled: soundAlertsEnabled ?? this.soundAlertsEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      speechRate: speechRate ?? this.speechRate,
      speechPitch: speechPitch ?? this.speechPitch,
      speechVolume: speechVolume ?? this.speechVolume,
      drivingModeEnabled: drivingModeEnabled ?? this.drivingModeEnabled,
      dndEnabled: dndEnabled ?? this.dndEnabled,
      dndStartHour: dndStartHour ?? this.dndStartHour,
      dndEndHour: dndEndHour ?? this.dndEndHour,
      readWhatsApp: readWhatsApp ?? this.readWhatsApp,
      readSms: readSms ?? this.readSms,
      readTelegram: readTelegram ?? this.readTelegram,
      readMessenger: readMessenger ?? this.readMessenger,
      readInstagram: readInstagram ?? this.readInstagram,
      priorityContacts: priorityContacts ?? this.priorityContacts,
      autoReplyMessage: autoReplyMessage ?? this.autoReplyMessage,
      autoReplyEnabled: autoReplyEnabled ?? this.autoReplyEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'voiceAlertsEnabled': voiceAlertsEnabled,
      'soundAlertsEnabled': soundAlertsEnabled,
      'vibrationEnabled': vibrationEnabled,
      'isDarkMode': isDarkMode,
      'speechRate': speechRate,
      'speechPitch': speechPitch,
      'speechVolume': speechVolume,
      'drivingModeEnabled': drivingModeEnabled,
      'dndEnabled': dndEnabled,
      'dndStartHour': dndStartHour,
      'dndEndHour': dndEndHour,
      'readWhatsApp': readWhatsApp,
      'readSms': readSms,
      'readTelegram': readTelegram,
      'readMessenger': readMessenger,
      'readInstagram': readInstagram,
      'priorityContacts': priorityContacts,
      'autoReplyMessage': autoReplyMessage,
      'autoReplyEnabled': autoReplyEnabled,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      voiceAlertsEnabled: map['voiceAlertsEnabled'] ?? true,
      soundAlertsEnabled: map['soundAlertsEnabled'] ?? true,
      vibrationEnabled: map['vibrationEnabled'] ?? true,
      isDarkMode: map['isDarkMode'] ?? false,
      speechRate: map['speechRate'] ?? 0.5,
      speechPitch: map['speechPitch'] ?? 1.0,
      speechVolume: map['speechVolume'] ?? 1.0,
      drivingModeEnabled: map['drivingModeEnabled'] ?? false,
      dndEnabled: map['dndEnabled'] ?? false,
      dndStartHour: map['dndStartHour'] ?? 22,
      dndEndHour: map['dndEndHour'] ?? 6,
      readWhatsApp: map['readWhatsApp'] ?? true,
      readSms: map['readSms'] ?? true,
      readTelegram: map['readTelegram'] ?? true,
      readMessenger: map['readMessenger'] ?? true,
      readInstagram: map['readInstagram'] ?? true,
      priorityContacts: map['priorityContacts'] ?? '',
      autoReplyMessage: map['autoReplyMessage'] ?? "I'm driving, will reply soon.",
      autoReplyEnabled: map['autoReplyEnabled'] ?? false,
    );
  }
}
