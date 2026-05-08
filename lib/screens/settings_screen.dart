import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import '../services/notification_service.dart';
import '../utils/permissions_helper.dart';

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
          _SectionHeader(title: 'Driving Mode'),
          Card(child: Column(children: [
            SwitchListTile(
              title: const Text('Driving Mode'),
              subtitle: const Text('Auto-read every message aloud'),
              secondary: const Icon(Icons.directions_car, color: Colors.orange),
              value: settings.drivingModeEnabled,
              onChanged: (v) => provider.saveSettings(settings.copyWith(drivingModeEnabled: v)),
            ),
            if (settings.drivingModeEnabled)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text('🚗 All messages read aloud automatically.',
                  style: TextStyle(fontSize: 12, color: Colors.orange)),
              ),
          ])),
          const SizedBox(height: 16),
          _SectionHeader(title: 'Apps to Monitor'),
          Card(child: Column(children: [
            _AppToggle(label: 'WhatsApp', color: const Color(0xFF25D366),
              icon: Icons.chat, value: settings.readWhatsApp,
              onChanged: (v) => provider.saveSettings(settings.copyWith(readWhatsApp: v))),
            const Divider(height: 1),
            _AppToggle(label: 'SMS', color: const Color(0xFF4CAF50),
              icon: Icons.sms, value: settings.readSms,
              onChanged: (v) => provider.saveSettings(settings.copyWith(readSms: v))),
            const Divider(height: 1),
            _AppToggle(label: 'Telegram', color: const Color(0xFF0088CC),
              icon: Icons.send, value: settings.readTelegram,
              onChanged: (v) => provider.saveSettings(settings.copyWith(readTelegram: v))),
            const Divider(height: 1),
            _AppToggle(label: 'Messenger', color: const Color(0xFF0084FF),
              icon: Icons.messenger_outline, value: settings.readMessenger,
              onChanged: (v) => provider.saveSettings(settings.copyWith(readMessenger: v))),
            const Divider(height: 1),
            _AppToggle(label: 'Instagram', color: const Color(0xFFE1306C),
              icon: Icons.camera_alt, value: settings.readInstagram,
              onChanged: (v) => provider.saveSettings(settings.copyWith(readInstagram: v))),
            const Divider(height: 1),
            SwitchListTile(
              title: const Text('Individual messages only'),
              subtitle: const Text('Skip group chat messages'),
              secondary: const Icon(Icons.person, color: AppConstants.primaryColor),
              value: settings.skipGroupMessages,
              onChanged: (v) => provider.saveSettings(settings.copyWith(skipGroupMessages: v)),
            ),
          ])),
          const SizedBox(height: 16),
          _SectionHeader(title: 'Priority Contacts'),
          Card(child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Always read messages from these contacts.',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 8),
              _EditableField(
                value: settings.priorityContacts,
                hint: 'e.g. John, Sarah, Mom',
                helper: 'Separate names with commas',
                icon: Icons.star,
                iconColor: Colors.amber,
                onChanged: (v) => provider.saveSettings(settings.copyWith(priorityContacts: v)),
              ),
            ]),
          )),
          const SizedBox(height: 16),
          _SectionHeader(title: 'Auto Reply'),
          Card(child: Column(children: [
            SwitchListTile(
              title: const Text('Auto Reply'),
              subtitle: const Text('Send automatic reply when driving'),
              secondary: const Icon(Icons.reply, color: Colors.teal),
              value: settings.autoReplyEnabled,
              onChanged: (v) => provider.saveSettings(settings.copyWith(autoReplyEnabled: v)),
            ),
            if (settings.autoReplyEnabled) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                child: _EditableField(
                  value: settings.autoReplyMessage,
                  hint: "I'm driving, will reply soon.",
                  helper: 'This message will be shown as your status',
                  icon: Icons.message,
                  iconColor: Colors.teal,
                  maxLines: 2,
                  onChanged: (v) => provider.saveSettings(settings.copyWith(autoReplyMessage: v)),
                ),
              ),
            ],
          ])),
          const SizedBox(height: 16),
          _SectionHeader(title: 'Do Not Disturb'),
          Card(child: Column(children: [
            SwitchListTile(
              title: const Text('Do Not Disturb'),
              subtitle: Text(settings.dndEnabled
                ? 'Silent ${settings.dndStartHour}:00 – ${settings.dndEndHour}:00'
                : 'Silence alerts during set hours'),
              secondary: const Icon(Icons.do_not_disturb_on, color: Colors.red),
              value: settings.dndEnabled,
              onChanged: (v) => provider.saveSettings(settings.copyWith(dndEnabled: v)),
            ),
            if (settings.dndEnabled) ...[
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.bedtime),
                title: const Text('Start time'),
                trailing: DropdownButton<int>(
                  value: settings.dndStartHour,
                  items: List.generate(24, (i) => DropdownMenuItem(
                    value: i, child: Text('${i.toString().padLeft(2, '0')}:00'))),
                  onChanged: (v) => provider.saveSettings(settings.copyWith(dndStartHour: v)),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.wb_sunny),
                title: const Text('End time'),
                trailing: DropdownButton<int>(
                  value: settings.dndEndHour,
                  items: List.generate(24, (i) => DropdownMenuItem(
                    value: i, child: Text('${i.toString().padLeft(2, '0')}:00'))),
                  onChanged: (v) => provider.saveSettings(settings.copyWith(dndEndHour: v)),
                ),
              ),
            ],
          ])),
          const SizedBox(height: 16),
          _SectionHeader(title: 'Alerts'),
          Card(child: Column(children: [
            SwitchListTile(
              title: const Text('Background Voice Commands'),
              subtitle: const Text('Speak commands even when app is closed'),
              secondary: const Icon(Icons.mic_external_on, color: Colors.deepPurple),
              value: settings.backgroundListeningEnabled,
              onChanged: (v) => provider.saveSettings(
                settings.copyWith(backgroundListeningEnabled: v)),
            ),
            if (settings.backgroundListeningEnabled)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  '🎙 App will listen for voice commands in the background. Uses more battery.',
                  style: TextStyle(fontSize: 12, color: Colors.deepPurple)),
              ),
            const Divider(height: 1),
            SwitchListTile(
              title: const Text('Voice Alerts'),
              subtitle: const Text('Say "You have a new message"'),
              secondary: const Icon(Icons.record_voice_over),
              value: settings.voiceAlertsEnabled,
              onChanged: (v) => provider.saveSettings(settings.copyWith(voiceAlertsEnabled: v)),
            ),
            const Divider(height: 1),
            SwitchListTile(
              title: const Text('Sound Alerts'),
              secondary: const Icon(Icons.volume_up),
              value: settings.soundAlertsEnabled,
              onChanged: (v) => provider.saveSettings(settings.copyWith(soundAlertsEnabled: v)),
            ),
            const Divider(height: 1),
            SwitchListTile(
              title: const Text('Vibration'),
              secondary: const Icon(Icons.vibration),
              value: settings.vibrationEnabled,
              onChanged: (v) => provider.saveSettings(settings.copyWith(vibrationEnabled: v)),
            ),
          ])),
          const SizedBox(height: 16),
          _SectionHeader(title: 'Voice Settings'),
          Card(child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(children: [
              _SliderSetting(label: 'Speech Rate', value: settings.speechRate,
                min: 0.1, max: 1.0, icon: Icons.speed,
                onChanged: (v) => provider.saveSettings(settings.copyWith(speechRate: v))),
              const SizedBox(height: 12),
              _SliderSetting(label: 'Pitch', value: settings.speechPitch,
                min: 0.5, max: 2.0, icon: Icons.tune,
                onChanged: (v) => provider.saveSettings(settings.copyWith(speechPitch: v))),
              const SizedBox(height: 12),
              _SliderSetting(label: 'Volume', value: settings.speechVolume,
                min: 0.0, max: 1.0, icon: Icons.volume_up,
                onChanged: (v) => provider.saveSettings(settings.copyWith(speechVolume: v))),
            ]),
          )),
          const SizedBox(height: 16),
          _SectionHeader(title: 'Appearance'),
          Card(child: SwitchListTile(
            title: const Text('Dark Mode'),
            secondary: const Icon(Icons.dark_mode),
            value: settings.isDarkMode,
            onChanged: (v) => provider.saveSettings(settings.copyWith(isDarkMode: v)),
          )),
          const SizedBox(height: 16),
          _SectionHeader(title: 'Permissions'),
          Card(child: Column(children: [
            ListTile(
              leading: const Icon(Icons.notifications_active),
              title: const Text('Notification Access'),
              subtitle: const Text('Required to read messages'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => NotificationService.instance.requestNotificationListenerPermission(),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.mic),
              title: const Text('Microphone Access'),
              subtitle: const Text('Required for voice commands'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => PermissionsHelper.requestMicrophonePermission(),
            ),
          ])),
          const SizedBox(height: 16),
          _SectionHeader(title: 'About'),
          Card(child: Column(children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Version'),
              trailing: const Text(AppConstants.appVersion, style: TextStyle(color: Colors.grey)),
            ),
            const Divider(height: 1),
            const ListTile(
              leading: Icon(Icons.record_voice_over),
              title: Text('Wake Word'),
              subtitle: Text('"Hey TalkNotify"'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.apps),
              title: const Text('Supported Apps'),
              subtitle: Text(AppConstants.supportedApps.join(', ')),
            ),
          ])),
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(title.toUpperCase(), style: const TextStyle(
      fontSize: 12, fontWeight: FontWeight.bold,
      color: AppConstants.primaryColor, letterSpacing: 1.2)),
  );
}

class _AppToggle extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _AppToggle({required this.label, required this.color, required this.icon,
    required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => SwitchListTile(
    title: Text(label),
    secondary: Icon(icon, color: color),
    value: value,
    onChanged: onChanged,
  );
}

class _EditableField extends StatefulWidget {
  final String value;
  final String hint;
  final String helper;
  final IconData icon;
  final Color iconColor;
  final int maxLines;
  final ValueChanged<String> onChanged;
  const _EditableField({required this.value, required this.hint, required this.helper,
    required this.icon, required this.iconColor, this.maxLines = 1, required this.onChanged});
  @override
  State<_EditableField> createState() => _EditableFieldState();
}

class _EditableFieldState extends State<_EditableField> {
  late TextEditingController _ctrl;
  @override
  void initState() { super.initState(); _ctrl = TextEditingController(text: widget.value); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => TextField(
    controller: _ctrl,
    maxLines: widget.maxLines,
    decoration: InputDecoration(
      hintText: widget.hint,
      helperText: widget.helper,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      prefixIcon: Icon(widget.icon, color: widget.iconColor),
    ),
    onChanged: widget.onChanged,
  );
}

class _SliderSetting extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final IconData icon;
  final ValueChanged<double> onChanged;
  const _SliderSetting({required this.label, required this.value, required this.min,
    required this.max, required this.icon, required this.onChanged});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Icon(icon, size: 18, color: AppConstants.primaryColor),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value.toStringAsFixed(1), style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ]),
      Slider(value: value, min: min, max: max,
        divisions: ((max - min) * 10).round(),
        onChanged: onChanged, activeColor: AppConstants.primaryColor),
    ],
  );
}
