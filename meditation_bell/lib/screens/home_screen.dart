import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/meditation_provider.dart';
import '../providers/settings_provider.dart';
import 'meditation_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedDuration = 10;
  int _selectedInterval = 60;
  bool _customDuration = false;
  final _customController = TextEditingController();

  static const List<int> _durations = [5, 10, 15, 30];
  static const List<Map<String, dynamic>> _intervals = [
    {'label': '30 sec', 'value': 30},
    {'label': '1 min', 'value': 60},
    {'label': '2 min', 'value': 120},
    {'label': '5 min', 'value': 300},
  ];

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  Future<void> _startSession(BuildContext context) async {
    int duration = _selectedDuration;
    if (_customDuration) {
      final val = int.tryParse(_customController.text.trim());
      if (val == null || val <= 0) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid duration in minutes.')),
        );
        return;
      }
      duration = val;
    }
    if (duration < 1) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum session duration is 1 minute.')),
      );
      return;
    }

    final settings = context.read<SettingsProvider>();
    final meditation = context.read<MeditationProvider>();

    await meditation.start(
      durationMinutes: duration,
      intervalSeconds: _selectedInterval,
      bellSound: settings.bellSound,
      vibrate: settings.vibrationEnabled,
      backgroundSound: settings.backgroundSound,
      customSounds: settings.customSounds,
    );

    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MeditationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meditation Bell'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Statistics',
            onPressed: () => Navigator.of(context).pushNamed('/stats'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.circle_outlined, size: 72, color: colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                'Find your stillness',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 40),

              // Duration selector
              Text(
                'Session Duration',
                style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant, letterSpacing: 0.5),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ..._durations.map((d) => _Chip(
                        label: '$d min',
                        selected: !_customDuration && _selectedDuration == d,
                        onTap: () => setState(() {
                          _selectedDuration = d;
                          _customDuration = false;
                        }),
                      )),
                  _Chip(
                    label: 'Custom',
                    selected: _customDuration,
                    onTap: () => setState(() => _customDuration = true),
                  ),
                ],
              ),
              if (_customDuration) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _customController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Duration (minutes)',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    suffixText: 'min',
                  ),
                ),
              ],

              const SizedBox(height: 36),

              // Interval selector
              Text(
                'Bell Interval',
                style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant, letterSpacing: 0.5),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _intervals
                    .map((i) => _Chip(
                          label: i['label'] as String,
                          selected: _selectedInterval == i['value'],
                          onTap: () => setState(
                              () => _selectedInterval = i['value'] as int),
                        ))
                    .toList(),
              ),

              const SizedBox(height: 48),

              FilledButton.icon(
                onPressed: () => _startSession(context),
                icon: const Icon(Icons.play_arrow_rounded, size: 24),
                label: const Text('Begin Session',
                    style: TextStyle(fontSize: 18, letterSpacing: 0.5)),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary
              : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
