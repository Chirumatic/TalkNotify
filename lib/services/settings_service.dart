import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';

class SettingsService {
  static final SettingsService instance = SettingsService._init();
  SharedPreferences? _prefs;
  SettingsService._init();

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> saveSettings(AppSettings s) async {
    if (_prefs == null) await initialize();
    await _prefs!.setBool('voiceAlertsEnabled', s.voiceAlertsEnabled);
    await _prefs!.setBool('soundAlertsEnabled', s.soundAlertsEnabled);
    await _prefs!.setBool('vibrationEnabled', s.vibrationEnabled);
    await _prefs!.setBool('isDarkMode', s.isDarkMode);
    await _prefs!.setDouble('speechRate', s.speechRate);
    await _prefs!.setDouble('speechPitch', s.speechPitch);
    await _prefs!.setDouble('speechVolume', s.speechVolume);
    await _prefs!.setBool('drivingModeEnabled', s.drivingModeEnabled);
    await _prefs!.setBool('dndEnabled', s.dndEnabled);
    await _prefs!.setInt('dndStartHour', s.dndStartHour);
    await _prefs!.setInt('dndEndHour', s.dndEndHour);
    await _prefs!.setBool('readWhatsApp', s.readWhatsApp);
    await _prefs!.setBool('readSms', s.readSms);
    await _prefs!.setBool('readTelegram', s.readTelegram);
    await _prefs!.setBool('readMessenger', s.readMessenger);
    await _prefs!.setBool('readInstagram', s.readInstagram);
    await _prefs!.setString('priorityContacts', s.priorityContacts);
    await _prefs!.setString('autoReplyMessage', s.autoReplyMessage);
    await _prefs!.setBool('autoReplyEnabled', s.autoReplyEnabled);
    await _prefs!.setBool('skipGroupMessages', s.skipGroupMessages);
    await _prefs!.setBool('backgroundListeningEnabled', s.backgroundListeningEnabled);
  }

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
      drivingModeEnabled: _prefs!.getBool('drivingModeEnabled') ?? false,
      dndEnabled: _prefs!.getBool('dndEnabled') ?? false,
      dndStartHour: _prefs!.getInt('dndStartHour') ?? 22,
      dndEndHour: _prefs!.getInt('dndEndHour') ?? 6,
      readWhatsApp: _prefs!.getBool('readWhatsApp') ?? true,
      readSms: _prefs!.getBool('readSms') ?? true,
      readTelegram: _prefs!.getBool('readTelegram') ?? true,
      readMessenger: _prefs!.getBool('readMessenger') ?? true,
      readInstagram: _prefs!.getBool('readInstagram') ?? true,
      priorityContacts: _prefs!.getString('priorityContacts') ?? '',
      autoReplyMessage: _prefs!.getString('autoReplyMessage') ?? "I'm driving, will reply soon.",
      autoReplyEnabled: _prefs!.getBool('autoReplyEnabled') ?? false,
      skipGroupMessages: _prefs!.getBool('skipGroupMessages') ?? false,
      backgroundListeningEnabled: _prefs!.getBool('backgroundListeningEnabled') ?? false,
    );
  }

  Future<void> clearSettings() async {
    if (_prefs == null) await initialize();
    await _prefs!.clear();
  }
}
