import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../models/app_settings.dart';
import '../models/custom_sound.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          children: [
            // ── Volume ─────────────────────────────────────────────────────
            _SectionLabel('Volume'),
            const SizedBox(height: 16),
            _VolumeRow(
              icon: Icons.notifications_rounded,
              label: 'Bell',
              value: settings.bellVolume,
              onChanged: (v) => settings.setBellVolume(v),
              onChangeEnd: (_) => settings.previewBuiltIn(settings.bellSound),
            ),
            const SizedBox(height: 8),
            _VolumeRow(
              icon: Icons.water_drop_rounded,
              label: 'Ambient',
              value: settings.backgroundVolume,
              onChanged: (v) => settings.setBackgroundVolume(v),
            ),

            const SizedBox(height: 32),

            // ── Background Sound ───────────────────────────────────────────
            _SectionLabel('Background Sound'),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Plays in a loop throughout your session.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ),
            ...AppSettings.backgroundSoundOptions.map((key) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _BackgroundSoundTile(
                    soundKey: key,
                    selected: settings.backgroundSound == key,
                    onTap: () => settings.setBackgroundSound(key),
                  ),
                )),

            const SizedBox(height: 32),

            // ── Bell Sound ─────────────────────────────────────────────────
            _SectionLabel('Bell Sound'),
            const SizedBox(height: 12),
            ...AppSettings.bellSoundOptions.map((key) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SoundTile(
                    label: AppSettings.bellSoundLabel(key),
                    selected: settings.bellSound == key,
                    onTap: () async {
                      await settings.setBellSound(key);
                      await settings.previewBuiltIn(key);
                    },
                  ),
                )),

            if (settings.customSounds.isNotEmpty) ...[
              const SizedBox(height: 8),
              Divider(color: colorScheme.outlineVariant),
              const SizedBox(height: 8),
              ...settings.customSounds.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SoundTile(
                      label: s.name,
                      selected: settings.bellSound == s.id,
                      isCustom: true,
                      onTap: () async {
                        await settings.setBellSound(s.id);
                        await settings.previewSound(s);
                      },
                    ),
                  )),
            ],

            const SizedBox(height: 32),

            // ── Haptics ────────────────────────────────────────────────────
            _SectionLabel('Haptics'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SwitchListTile(
                title: const Text('Vibration'),
                subtitle: Text(
                  'Vibrate when the bell rings',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                value: settings.vibrationEnabled,
                onChanged: (v) => settings.setVibrationEnabled(v),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),

            const SizedBox(height: 32),

            // ── Custom Sounds ──────────────────────────────────────────────
            Row(
              children: [
                Expanded(child: _SectionLabel('Custom Sounds')),
                if (settings.importing)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed:
                  settings.importing ? null : () => settings.importSound(),
              icon: const Icon(Icons.audio_file_rounded),
              label: const Text('Import MP3'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            if (settings.importError != null) ...[
              const SizedBox(height: 8),
              Text(
                settings.importError!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: colorScheme.error),
              ),
            ],
            if (settings.customSounds.isEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'No custom sounds yet.\nTap "Import MP3" to add your own.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ] else ...[
              const SizedBox(height: 16),
              ...settings.customSounds.map((s) => _CustomSoundRow(sound: s)),
            ],

            const SizedBox(height: 32),
            Text(
              'Tap a sound name to select it and hear a preview.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Background sound tile ─────────────────────────────────────────────────────

class _BackgroundSoundTile extends StatelessWidget {
  final String? soundKey;
  final bool selected;
  final VoidCallback onTap;

  const _BackgroundSoundTile({
    required this.soundKey,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final label = AppSettings.backgroundSoundLabel(soundKey);
    final icon = soundKey == null
        ? Icons.block_rounded
        : Icons.water_drop_rounded;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? colorScheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurface,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 15,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check_rounded,
                  size: 20, color: colorScheme.onPrimaryContainer),
          ],
        ),
      ),
    );
  }
}

// ── Volume row ────────────────────────────────────────────────────────────────

class _VolumeRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;

  const _VolumeRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final pct = (value * 100).round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: 12),
          SizedBox(
            width: 52,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: colorScheme.onSurface),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 16),
                activeTrackColor: colorScheme.primary,
                inactiveTrackColor:
                    colorScheme.primary.withValues(alpha: 0.2),
                thumbColor: colorScheme.primary,
                overlayColor: colorScheme.primary.withValues(alpha: 0.15),
              ),
              child: Slider(
                value: value,
                min: 0.0,
                max: 1.0,
                divisions: 20,
                onChanged: onChanged,
                onChangeEnd: onChangeEnd,
              ),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              '$pct%',
              textAlign: TextAlign.right,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

// ── Bell sound tile ───────────────────────────────────────────────────────────

class _SoundTile extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isCustom;
  final VoidCallback onTap;

  const _SoundTile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.isCustom = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? colorScheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isCustom
                  ? Icons.audio_file_rounded
                  : Icons.music_note_rounded,
              size: 20,
              color: selected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurface,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 15,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (selected)
              Icon(Icons.check_rounded,
                  size: 20, color: colorScheme.onPrimaryContainer),
          ],
        ),
      ),
    );
  }
}

// ── Custom sound row ──────────────────────────────────────────────────────────

class _CustomSoundRow extends StatelessWidget {
  final CustomSound sound;
  const _CustomSoundRow({required this.sound});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.play_circle_outline_rounded,
                color: colorScheme.primary),
            tooltip: 'Preview',
            onPressed: () => context.read<SettingsProvider>().previewSound(sound),
          ),
          Expanded(
            child: Text(
              sound.name,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: colorScheme.onSurface),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined,
                size: 20, color: colorScheme.onSurfaceVariant),
            tooltip: 'Rename',
            onPressed: () => _showRenameDialog(context, context.read<SettingsProvider>()),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded,
                size: 20, color: colorScheme.error),
            tooltip: 'Delete',
            onPressed: () => _showDeleteDialog(context, context.read<SettingsProvider>()),
          ),
        ],
      ),
    );
  }

  Future<void> _showRenameDialog(
      BuildContext context, SettingsProvider settings) async {
    final controller = TextEditingController(text: sound.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename sound'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Sound name'),
          textCapitalization: TextCapitalization.words,
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Save')),
        ],
      ),
    );
    controller.dispose();
    if (newName != null && newName.trim().isNotEmpty) {
      await settings.renameSound(sound.id, newName);
    }
  }

  Future<void> _showDeleteDialog(
      BuildContext context, SettingsProvider settings) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete sound?'),
        content: Text('"${sound.name}" will be permanently removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await settings.deleteSound(sound.id);
    }
  }
}
