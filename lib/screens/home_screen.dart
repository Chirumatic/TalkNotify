import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import '../widgets/message_card.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

/// Main home screen of TalkNotify
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    _DashboardTab(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

/// Dashboard tab — shows latest message and voice controls
class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final latest = provider.latestMessage;
    final isListening = provider.isListening;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.record_voice_over, color: Colors.white),
            const SizedBox(width: 8),
            const Text(
              AppConstants.appName,
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        actions: [
          // Notification listener status indicator
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(
              Icons.circle,
              size: 12,
              color: Colors.greenAccent,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Latest message card
            _LatestMessageSection(latest: latest),
            const SizedBox(height: 24),

            // Voice command display
            if (provider.recognizedText.isNotEmpty)
              _RecognizedTextBubble(text: provider.recognizedText),

            const SizedBox(height: 8),

            // Action buttons
            _ActionButtons(isListening: isListening),

            const SizedBox(height: 24),

            // Quick stats
            _QuickStats(provider: provider),

            const SizedBox(height: 24),

            // Voice commands help
            const _VoiceCommandsHelp(),
          ],
        ),
      ),
    );
  }
}

/// Shows the latest received message
class _LatestMessageSection extends StatelessWidget {
  final dynamic latest;
  const _LatestMessageSection({required this.latest});

  @override
  Widget build(BuildContext context) {
    if (latest == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        ),
        child: Column(
          children: [
            Icon(
              Icons.notifications_none,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'No messages yet',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Messages from WhatsApp, SMS, Telegram\nwill appear here',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Latest Message', style: AppConstants.subheadingStyle),
        const SizedBox(height: 8),
        MessageCard(
          message: latest,
          onRead: () => context.read<AppProvider>().readLatestMessage(),
        ),
      ],
    );
  }
}

/// Bubble showing recognized voice text
class _RecognizedTextBubble extends StatelessWidget {
  final String text;
  const _RecognizedTextBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppConstants.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.mic, color: AppConstants.primaryColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '"$text"',
              style: const TextStyle(
                color: AppConstants.primaryColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Main action buttons
class _ActionButtons extends StatelessWidget {
  final bool isListening;
  const _ActionButtons({required this.isListening});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();

    return Column(
      children: [
        // Read / Stop row
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.volume_up,
                label: 'Read Message',
                color: AppConstants.primaryColor,
                onTap: () => provider.readLatestMessage(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.stop_circle_outlined,
                label: 'Stop Reading',
                color: Colors.redAccent,
                onTap: () => provider.stopReading(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Listen toggle
        SizedBox(
          width: double.infinity,
          child: _ActionButton(
            icon: isListening ? Icons.mic_off : Icons.mic,
            label: isListening ? 'Stop Listening' : 'Start Listening',
            color: isListening ? Colors.orange : AppConstants.successColor,
            onTap: () {
              if (isListening) {
                provider.stopListening();
              } else {
                provider.startListening();
              }
            },
          ),
        ),
      ],
    );
  }
}

/// Reusable action button
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        ),
        elevation: 2,
      ),
    );
  }
}

/// Quick stats row
class _QuickStats extends StatelessWidget {
  final AppProvider provider;
  const _QuickStats({required this.provider});

  @override
  Widget build(BuildContext context) {
    final total = provider.messageHistory.length;
    final unread = provider.messageHistory.where((m) => !m.isRead).length;

    return Row(
      children: [
        Expanded(child: _StatCard(label: 'Total', value: '$total', icon: Icons.inbox)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(label: 'Unread', value: '$unread', icon: Icons.mark_email_unread)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Row(
          children: [
            Icon(icon, color: AppConstants.primaryColor, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Voice commands reference card
class _VoiceCommandsHelp extends StatelessWidget {
  const _VoiceCommandsHelp();

  @override
  Widget build(BuildContext context) {
    const commands = [
      '"Read my message"',
      '"Read latest message"',
      '"Who texted me?"',
      '"Read WhatsApp message"',
      '"Read Telegram message"',
      '"Stop reading"',
      '"Repeat message"',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.help_outline, color: AppConstants.primaryColor, size: 18),
                SizedBox(width: 8),
                Text('Voice Commands', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 10),
            ...commands.map((cmd) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  const Icon(Icons.chevron_right, size: 16, color: AppConstants.primaryColor),
                  const SizedBox(width: 4),
                  Text(cmd, style: const TextStyle(fontSize: 13)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
