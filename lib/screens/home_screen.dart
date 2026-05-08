import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import '../widgets/message_card.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

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
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'History'),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final latest = provider.latestMessage;
    final isListening = provider.isListening;
    final isDriving = provider.settings.drivingModeEnabled;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Modern gradient app bar
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1565C0), Color(0xFF2196F3)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.record_voice_over_rounded,
                              color: Colors.white, size: 26),
                            const SizedBox(width: 10),
                            const Text('TalkNotify',
                              style: TextStyle(fontSize: 22,
                                fontWeight: FontWeight.w800, color: Colors.white)),
                            const Spacer(),
                            // Status indicator
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(children: [
                                Container(width: 7, height: 7,
                                  decoration: const BoxDecoration(
                                    color: Colors.greenAccent,
                                    shape: BoxShape.circle)),
                                const SizedBox(width: 5),
                                const Text('Active',
                                  style: TextStyle(color: Colors.white,
                                    fontSize: 11, fontWeight: FontWeight.w500)),
                              ]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isDriving
                            ? '🚗 Driving mode — reading all messages'
                            : 'Say "Hey TalkNotify" to get started',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats row
                  _StatsRow(provider: provider),
                  const SizedBox(height: 20),

                  // Driving mode banner
                  if (isDriving) ...[
                    _DrivingModeBanner(provider: provider),
                    const SizedBox(height: 20),
                  ],

                  // Voice command bubble
                  if (provider.recognizedText.isNotEmpty) ...[
                    _RecognizedTextBubble(text: provider.recognizedText),
                    const SizedBox(height: 12),
                  ],

                  // Action buttons
                  _ActionGrid(isListening: isListening, isDriving: isDriving),
                  const SizedBox(height: 20),

                  // Latest message
                  _LatestMessageSection(latest: latest),
                  const SizedBox(height: 20),

                  // Summary button
                  _SummaryButton(),
                  const SizedBox(height: 20),

                  // Voice commands card
                  const _VoiceCommandsCard(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final AppProvider provider;
  const _StatsRow({required this.provider});

  @override
  Widget build(BuildContext context) {
    final total = provider.messageHistory.length;
    final unread = provider.messageHistory.where((m) => !m.isRead).length;
    final today = provider.messageHistory.where((m) {
      final now = DateTime.now();
      return m.timestamp.day == now.day && m.timestamp.month == now.month;
    }).length;

    return Row(children: [
      Expanded(child: _StatTile(label: 'Total', value: '$total',
        icon: Icons.inbox_rounded, color: AppConstants.primaryColor)),
      const SizedBox(width: 10),
      Expanded(child: _StatTile(label: 'Unread', value: '$unread',
        icon: Icons.mark_email_unread_rounded, color: Colors.orange)),
      const SizedBox(width: 10),
      Expanded(child: _StatTile(label: 'Today', value: '$today',
        icon: Icons.today_rounded, color: Colors.teal)),
    ]);
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatTile({required this.label, required this.value,
    required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 20,
          fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 11,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
      ]),
    );
  }
}

class _DrivingModeBanner extends StatelessWidget {
  final AppProvider provider;
  const _DrivingModeBanner({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6F00), Color(0xFFFF8F00)]),
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      ),
      child: Row(children: [
        const Icon(Icons.directions_car_rounded, color: Colors.white, size: 28),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Driving Mode Active', style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            Text('All messages read aloud automatically',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        ),
        TextButton(
          onPressed: () => provider.saveSettings(
            provider.settings.copyWith(drivingModeEnabled: false)),
          child: const Text('Turn Off',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }
}

class _RecognizedTextBubble extends StatelessWidget {
  final String text;
  const _RecognizedTextBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppConstants.primaryColor.withOpacity(0.25)),
      ),
      child: Row(children: [
        const Icon(Icons.mic_rounded, color: AppConstants.primaryColor, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text('"$text"',
          style: const TextStyle(color: AppConstants.primaryColor,
            fontStyle: FontStyle.italic, fontSize: 13))),
      ]),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  final bool isListening;
  final bool isDriving;
  const _ActionGrid({required this.isListening, required this.isDriving});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();

    return Column(children: [
      Row(children: [
        Expanded(child: _ActionBtn(
          icon: Icons.volume_up_rounded,
          label: 'Read Message',
          color: AppConstants.primaryColor,
          onTap: () => provider.readLatestMessage(),
        )),
        const SizedBox(width: 10),
        Expanded(child: _ActionBtn(
          icon: Icons.stop_circle_rounded,
          label: 'Stop',
          color: Colors.redAccent,
          onTap: () => provider.stopReading(),
        )),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _ActionBtn(
          icon: isListening ? Icons.mic_off_rounded : Icons.mic_rounded,
          label: isListening ? 'Stop Listening' : 'Listen',
          color: isListening ? Colors.orange : AppConstants.successColor,
          onTap: () => isListening
            ? provider.stopListening()
            : provider.startListening(),
        )),
        const SizedBox(width: 10),
        Expanded(child: _ActionBtn(
          icon: Icons.directions_car_rounded,
          label: isDriving ? 'Driving ON' : 'Drive Mode',
          color: isDriving ? Colors.orange : Colors.blueGrey,
          onTap: () => provider.saveSettings(
            provider.settings.copyWith(drivingModeEnabled: !isDriving)),
        )),
      ]),
    ]);
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label,
    required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium)),
        elevation: 0,
      ),
    );
  }
}

class _LatestMessageSection extends StatelessWidget {
  final dynamic latest;
  const _LatestMessageSection({required this.latest});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('Latest Message',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const Spacer(),
        if (latest != null)
          Text(DateFormat('hh:mm a').format(latest.timestamp),
            style: TextStyle(fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4))),
      ]),
      const SizedBox(height: 10),
      if (latest == null)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          ),
          child: Column(children: [
            Icon(Icons.notifications_none_rounded, size: 44,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.25)),
            const SizedBox(height: 10),
            Text('No messages yet',
              style: TextStyle(fontSize: 15,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4))),
            const SizedBox(height: 4),
            Text('WhatsApp, SMS, Telegram messages\nwill appear here',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3))),
          ]),
        )
      else
        MessageCard(
          message: latest,
          onRead: () => context.read<AppProvider>().readLatestMessage(),
        ),
    ]);
  }
}

class _SummaryButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    final unread = context.watch<AppProvider>()
      .messageHistory.where((m) => !m.isRead).length;

    return OutlinedButton.icon(
      onPressed: () => provider.speakMessageSummary(),
      icon: const Icon(Icons.summarize_rounded),
      label: Text('Summarize Messages ($unread unread)'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium)),
      ),
    );
  }
}

class _VoiceCommandsCard extends StatefulWidget {
  const _VoiceCommandsCard();

  @override
  State<_VoiceCommandsCard> createState() => _VoiceCommandsCardState();
}

class _VoiceCommandsCardState extends State<_VoiceCommandsCard> {
  bool _expanded = false;

  static const _commands = [
    (Icons.volume_up_rounded, '"Read my message"'),
    (Icons.person_rounded, '"Who texted me?"'),
    (Icons.chat_rounded, '"Read WhatsApp message"'),
    (Icons.send_rounded, '"Read Telegram message"'),
    (Icons.sms_rounded, '"Read SMS"'),
    (Icons.stop_rounded, '"Stop reading"'),
    (Icons.replay_rounded, '"Repeat message"'),
    (Icons.bar_chart_rounded, '"Summarize my messages"'),
    (Icons.directions_car_rounded, '"Driving mode on/off"'),
    (Icons.mic_rounded, '"Hey TalkNotify"'),
  ];

  @override
  Widget build(BuildContext context) {
    final shown = _expanded ? _commands : _commands.take(4).toList();

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge)),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.mic_rounded,
                color: AppConstants.primaryColor, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('Voice Commands',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const Spacer(),
            TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(_expanded ? 'Less' : 'More',
                style: const TextStyle(fontSize: 12)),
            ),
          ]),
          const SizedBox(height: 8),
          ...shown.map((cmd) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(children: [
              Icon(cmd.$1, size: 15,
                color: AppConstants.primaryColor.withOpacity(0.7)),
              const SizedBox(width: 8),
              Text(cmd.$2, style: const TextStyle(fontSize: 13)),
            ]),
          )),
        ]),
      ),
    );
  }
}
