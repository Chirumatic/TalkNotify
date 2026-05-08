/// Model for app settings
class AppSettings {
  final bool voiceAlertsEnabled;
  final bool soundAlertsEnabled;
  final bool vibrationEnabled;
  final bool isDarkMode;
  final double speechRate;
  final double speechPitch;
  final double speechVolume;

  AppSettings({
    this.voiceAlertsEnabled = true,
    this.soundAlertsEnabled = true,
    this.vibrationEnabled = true,
    this.isDarkMode = false,
    this.speechRate = 0.5,
    this.speechPitch = 1.0,
    this.speechVolume = 1.0,
  });

  AppSettings copyWith({
    bool? voiceAlertsEnabled,
    bool? soundAlertsEnabled,
    bool? vibrationEnabled,
    bool? isDarkMode,
    double? speechRate,
    double? speechPitch,
    double? speechVolume,
  }) {
    return AppSettings(
      voiceAlertsEnabled: voiceAlertsEnabled ?? this.voiceAlertsEnabled,
      soundAlertsEnabled: soundAlertsEnabled ?? this.soundAlertsEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      speechRate: speechRate ?? this.speechRate,
      speechPitch: speechPitch ?? this.speechPitch,
      speechVolume: speechVolume ?? this.speechVolume,
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
    );
  }
}
