import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stats_provider.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatsProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final hours = stats.totalMinutes ~/ 60;
    final minutes = stats.totalMinutes % 60;
    final timeLabel = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Your practice',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              _StatCard(
                icon: Icons.timer_outlined,
                label: 'Total Time',
                value: timeLabel,
                subtitle: 'mindful minutes',
                color: colorScheme.primaryContainer,
                iconColor: colorScheme.onPrimaryContainer,
              ),
              const SizedBox(height: 16),
              _StatCard(
                icon: Icons.check_circle_outline_rounded,
                label: 'Sessions',
                value: stats.totalSessions.toString(),
                subtitle: 'completed sessions',
                color: colorScheme.secondaryContainer,
                iconColor: colorScheme.onSecondaryContainer,
              ),
              const SizedBox(height: 16),
              _StatCard(
                icon: Icons.local_fire_department_outlined,
                label: 'Current Streak',
                value: stats.currentStreak.toString(),
                subtitle: stats.currentStreak == 1 ? 'day in a row' : 'days in a row',
                color: colorScheme.tertiaryContainer,
                iconColor: colorScheme.onTertiaryContainer,
              ),
              const Spacer(),
              if (stats.totalSessions == 0) ...[
                Text(
                  'Complete your first session to begin tracking your journey.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color color;
  final Color iconColor;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 28, color: iconColor),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
