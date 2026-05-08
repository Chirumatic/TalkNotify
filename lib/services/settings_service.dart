import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';

/// Service for managing app settings
class SettingsService {
  static final SettingsService instance = SettingsService._init();
  SharedPreferences? _prefs;

  SettingsService._init();

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Save settings
  Future<void> saveSettings(AppSettings settings) async {
    if (_prefs == null) await initialize();
    
    await _prefs!.setBool('voiceAlertsEnabled', settings.voiceAlertsEnabled);
    await _prefs!.setBool('soundAlertsEnabled', settings.soundAlertsEnabled);
    await _prefs!.setBool('vibrationEnabled', settings.vibrationEnabled);
    await _prefs!.setBool('isDarkMode', settings.isDarkMode);
    await _prefs!.setDouble('speechRate', settings.speechRate);
    await _prefs!.setDouble('speechPitch', settings.speechPitch);
    await _prefs!.setDouble('speechVolume', settings.speechVolume);
  }

  /// Load settings
  Future<AppSettings> loadSettings() async {
    if (_prefs == null) await initialize();

    return AppSettings(
      voiceAlertsEnabled: _prefs!.getBool('voiceAlertsEnabled') ?? true,
      soundAlertsEnabled: _prefs!.getBool('soundAlertsEnabled') ?? true,
      vibrationEnabled: _prefs!.getBool('vibrationEnabled') ?? true,
      isDarkMode: _prefs!.getBool('isDarkMode') ?? false,
      speechRate: _prefs!.getDouble('speechRate') ?? 0.5,
      speechPitch: _prefs!.getDouble('speechPitch') ?? 1.0,
      speechVolume: _prefs!.getDouble('speechVolume') ?? 1.0,
    );
  }

  /// Clear all settings
  Future<void> clearSettings() async {
    if (_prefs == null) await initialize();
    await _prefs!.clear();
  }
}
