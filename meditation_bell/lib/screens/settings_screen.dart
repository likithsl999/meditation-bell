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
            // ── Bell Sound (built-in) ──────────────────────────────────────
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

            // ── Custom sounds in selection ─────────────────────────────────
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

            // ── Haptics ───────────────────────────────────────────────────
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

            // ── Custom sounds management ──────────────────────────────────
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

            // Import button
            OutlinedButton.icon(
              onPressed: settings.importing ? null : () => settings.importSound(),
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

            // Imported sounds list
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
              ...settings.customSounds
                  .map((s) => _CustomSoundRow(sound: s))
                  .toList(),
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

// ── Reusable widgets ──────────────────────────────────────────────────────────

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
              isCustom ? Icons.audio_file_rounded : Icons.music_note_rounded,
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

class _CustomSoundRow extends StatelessWidget {
  final CustomSound sound;
  const _CustomSoundRow({required this.sound});

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsProvider>();
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
          // Play preview
          IconButton(
            icon: Icon(Icons.play_circle_outline_rounded,
                color: colorScheme.primary),
            tooltip: 'Preview',
            onPressed: () => settings.previewSound(sound),
          ),

          // Name
          Expanded(
            child: Text(
              sound.name,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: colorScheme.onSurface),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Rename
          IconButton(
            icon: Icon(Icons.edit_outlined,
                size: 20, color: colorScheme.onSurfaceVariant),
            tooltip: 'Rename',
            onPressed: () => _showRenameDialog(context, settings),
          ),

          // Delete
          IconButton(
            icon: Icon(Icons.delete_outline_rounded,
                size: 20, color: colorScheme.error),
            tooltip: 'Delete',
            onPressed: () => _showDeleteDialog(context, settings),
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
