import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import '../services/notification_service.dart';
import '../utils/permissions_helper.dart';

/// Settings screen
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final settings = provider.settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        children: [
          // --- Alerts Section ---
          _SectionHeader(title: 'Alerts'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Voice Alerts'),
                  subtitle: const Text('Say "You have a new message"'),
                  secondary: const Icon(Icons.record_voice_over),
                  value: settings.voiceAlertsEnabled,
                  onChanged: (val) => provider.saveSettings(
                    settings.copyWith(voiceAlertsEnabled: val),
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Sound Alerts'),
                  subtitle: const Text('Play notification sound'),
                  secondary: const Icon(Icons.volume_up),
                  value: settings.soundAlertsEnabled,
                  onChanged: (val) => provider.saveSettings(
                    settings.copyWith(soundAlertsEnabled: val),
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Vibration'),
                  subtitle: const Text('Vibrate on new message'),
                  secondary: const Icon(Icons.vibration),
                  value: settings.vibrationEnabled,
                  onChanged: (val) => provider.saveSettings(
                    settings.copyWith(vibrationEnabled: val),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // --- Voice Settings ---
          _SectionHeader(title: 'Voice Settings'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Column(
                children: [
                  _SliderSetting(
                    label: 'Speech Rate',
                    value: settings.speechRate,
                    min: 0.1,
                    max: 1.0,
                    icon: Icons.speed,
                    onChanged: (val) => provider.saveSettings(
                      settings.copyWith(speechRate: val),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SliderSetting(
                    label: 'Pitch',
                    value: settings.speechPitch,
                    min: 0.5,
                    max: 2.0,
                    icon: Icons.tune,
                    onChanged: (val) => provider.saveSettings(
                      settings.copyWith(speechPitch: val),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SliderSetting(
                    label: 'Volume',
                    value: settings.speechVolume,
                    min: 0.0,
                    max: 1.0,
                    icon: Icons.volume_up,
                    onChanged: (val) => provider.saveSettings(
                      settings.copyWith(speechVolume: val),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // --- Appearance ---
          _SectionHeader(title: 'Appearance'),
          Card(
            child: SwitchListTile(
              title: const Text('Dark Mode'),
              secondary: const Icon(Icons.dark_mode),
              value: settings.isDarkMode,
              onChanged: (val) => provider.saveSettings(
                settings.copyWith(isDarkMode: val),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // --- Permissions ---
          _SectionHeader(title: 'Permissions'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_active),
                  title: const Text('Notification Access'),
                  subtitle: const Text('Required to read messages'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await NotificationService.instance
                        .requestNotificationListenerPermission();
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.mic),
                  title: const Text('Microphone Access'),
                  subtitle: const Text('Required for voice commands'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await PermissionsHelper.requestMicrophonePermission();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // --- About ---
          _SectionHeader(title: 'About'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Version'),
                  trailing: const Text(AppConstants.appVersion,
                      style: TextStyle(color: Colors.grey)),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.apps),
                  title: const Text('Supported Apps'),
                  subtitle: Text(AppConstants.supportedApps.join(', ')),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppConstants.primaryColor,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SliderSetting extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final IconData icon;
  final ValueChanged<double> onChanged;

  const _SliderSetting({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppConstants.primaryColor),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            const Spacer(),
            Text(value.toStringAsFixed(1),
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: ((max - min) * 10).round(),
          onChanged: onChanged,
          activeColor: AppConstants.primaryColor,
        ),
      ],
    );
  }
}
