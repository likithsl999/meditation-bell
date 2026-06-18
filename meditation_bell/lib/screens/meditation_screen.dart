import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/meditation_provider.dart';

class MeditationScreen extends StatelessWidget {
  const MeditationScreen({super.key});

  String _intervalLabel(int seconds) {
    if (seconds < 60) return '$seconds sec';
    final m = seconds ~/ 60;
    return '$m min';
  }

  @override
  Widget build(BuildContext context) {
    final meditation = context.watch<MeditationProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (meditation.isFinished) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session complete. Well done.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      });
    }

    final session = meditation.session;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final confirm = await _confirmStop(context);
        if (confirm && context.mounted) {
          await meditation.stop();
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: _BreathingRing(isRunning: meditation.isRunning),
                ),
                const SizedBox(height: 48),

                // Countdown
                Text(
                  meditation.remainingFormatted,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontSize: 72,
                    fontWeight: FontWeight.w200,
                    letterSpacing: -2,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),

                if (session != null) ...[
                  Text(
                    'remaining',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none_rounded,
                          size: 16, color: colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Bell every ${_intervalLabel(session.intervalSeconds)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 64),

                // Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (meditation.isRunning)
                      _CircleButton(
                        icon: Icons.pause_rounded,
                        label: 'Pause',
                        onTap: meditation.pause,
                        color: colorScheme.primaryContainer,
                        iconColor: colorScheme.onPrimaryContainer,
                        size: 72,
                      )
                    else if (meditation.isPaused)
                      _CircleButton(
                        icon: Icons.play_arrow_rounded,
                        label: 'Resume',
                        onTap: meditation.resume,
                        color: colorScheme.primaryContainer,
                        iconColor: colorScheme.onPrimaryContainer,
                        size: 72,
                      ),
                    const SizedBox(width: 32),
                    _CircleButton(
                      icon: Icons.stop_rounded,
                      label: 'Stop',
                      onTap: () async {
                        final confirm = await _confirmStop(context);
                        if (confirm && context.mounted) {
                          await meditation.stop();
                          Navigator.of(context).pop();
                        }
                      },
                      color: colorScheme.errorContainer,
                      iconColor: colorScheme.onErrorContainer,
                      size: 56,
                    ),
                  ],
                ),

                if (meditation.isPaused) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Paused',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        letterSpacing: 1.2),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmStop(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End session?'),
        content: const Text(
            'Your current meditation session will be stopped.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Continue')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Stop')),
        ],
      ),
    );
    return result == true;
  }
}

// ── Breathing ring ────────────────────────────────────────────────────────────

class _BreathingRing extends StatefulWidget {
  final bool isRunning;
  const _BreathingRing({required this.isRunning});

  @override
  State<_BreathingRing> createState() => _BreathingRingState();
}

class _BreathingRingState extends State<_BreathingRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(seconds: 4));
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    if (widget.isRunning) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_BreathingRing old) {
    super.didUpdateWidget(old);
    if (widget.isRunning && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isRunning && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
              color: colorScheme.primary.withOpacity(0.4), width: 2),
        ),
        child: Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary.withOpacity(0.12),
              border: Border.all(
                  color: colorScheme.primary.withOpacity(0.6), width: 1.5),
            ),
            child: Icon(Icons.self_improvement_rounded,
                size: 40, color: colorScheme.primary),
          ),
        ),
      ),
    );
  }
}

// ── Circle button ─────────────────────────────────────────────────────────────

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color iconColor;
  final double size;

  const _CircleButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    required this.iconColor,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration:
                BoxDecoration(shape: BoxShape.circle, color: color),
            child: Icon(icon, size: size * 0.45, color: iconColor),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color:
                  Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
