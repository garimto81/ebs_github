// GFX settings screen — ported from GfxPage.vue.
//
// Layout preset, card style, player display toggles (photo/flag/chip count),
// animation speed slider. Team 1 owns form + rive-js preview only.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';
import '../widgets/setting_field.dart';
import '../widgets/setting_section.dart';

class GfxScreen extends ConsumerStatefulWidget {
  const GfxScreen({super.key});

  @override
  ConsumerState<GfxScreen> createState() => _GfxScreenState();
}

String _humaniseElementKey(String key) {
  return key
      .split('_')
      .map((s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}')
      .join(' ');
}

bool _readVisibility(Map<String, dynamic> draft, String key) {
  final ev = draft['element_visibility'];
  if (ev is Map && ev[key] is bool) return ev[key] as bool;
  return true; // default visible
}

class _GfxScreenState extends ConsumerState<GfxScreen> {
  static const _layoutPresetOptions = [
    ('standard-9', 'Standard (9-max)'),
    ('standard-6', 'Standard (6-max)'),
    ('heads-up', 'Heads Up'),
    ('final-table', 'Final Table'),
  ];

  static const _cardStyleOptions = [
    ('classic', 'Classic'),
    ('four-color', 'Four-Color'),
    ('jumbo', 'Jumbo'),
  ];

  @override
  void initState() {
    super.initState();
    _fetchIfIdle();
  }

  void _fetchIfIdle() {
    final state = ref.read(settingsSectionProvider(SettingsSection.gfx));
    if (!state.isLoading && state.committed.isEmpty && state.error == null) {
      ref.read(settingsSectionProvider(SettingsSection.gfx).notifier).fetch();
    }
  }

  SettingsSectionNotifier get _notifier =>
      ref.read(settingsSectionProvider(SettingsSection.gfx).notifier);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsSectionProvider(SettingsSection.gfx));
    final draft = state.draft;

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final animSpeed = (draft['animationSpeed'] as num?)?.toDouble() ?? 1.0;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Layout Preset
        DropdownButtonFormField<String>(
          value: (draft['layoutPreset'] as String?) ?? 'standard-9',
          decoration: const InputDecoration(labelText: 'Layout Preset'),
          items: _layoutPresetOptions
              .map((o) => DropdownMenuItem(value: o.$1, child: Text(o.$2)))
              .toList(),
          onChanged: (v) => _notifier.updateField('layoutPreset', v),
        ),
        const SizedBox(height: 20),

        // Card Style
        DropdownButtonFormField<String>(
          value: (draft['cardStyle'] as String?) ?? 'classic',
          decoration: const InputDecoration(labelText: 'Card Style'),
          items: _cardStyleOptions
              .map((o) => DropdownMenuItem(value: o.$1, child: Text(o.$2)))
              .toList(),
          onChanged: (v) => _notifier.updateField('cardStyle', v),
        ),
        const SizedBox(height: 24),

        // Player Display Options
        Text(
          'Player Display Options',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('Show Player Photo'),
          value: (draft['showPlayerPhoto'] as bool?) ?? true,
          onChanged: (v) => _notifier.updateField('showPlayerPhoto', v),
        ),
        SwitchListTile(
          title: const Text('Show Player Flag'),
          value: (draft['showPlayerFlag'] as bool?) ?? true,
          onChanged: (v) => _notifier.updateField('showPlayerFlag', v),
        ),
        SwitchListTile(
          title: const Text('Show Chip Count'),
          value: (draft['showChipCount'] as bool?) ?? true,
          onChanged: (v) => _notifier.updateField('showChipCount', v),
        ),
        const SizedBox(height: 24),

        // Animation Speed
        Text(
          'Animation Speed: ${animSpeed.toStringAsFixed(2)}x',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Slider(
          value: animSpeed.clamp(0.5, 3.0),
          min: 0.5,
          max: 3.0,
          divisions: 10,
          label: '${animSpeed.toStringAsFixed(2)}x',
          onChanged: (v) => _notifier.updateField('animationSpeed', v),
        ),

        const Divider(height: 40),

        // ── SG-003 Extended Fields ───────────────────────────────
        SettingSection(
          title: 'Skin & Theme',
          children: [
            SettingField(
              label: 'Active Skin',
              child: DropdownButtonFormField<String>(
                value: (draft['active_skin_id'] as String?) ?? 'default',
                decoration: const InputDecoration(isDense: true),
                items: const [
                  DropdownMenuItem(value: 'default', child: Text('Default')),
                  DropdownMenuItem(value: 'wsop-live', child: Text('WSOP Live')),
                  DropdownMenuItem(value: 'heritage', child: Text('Heritage')),
                ],
                onChanged: (v) =>
                    _notifier.updateField('active_skin_id', v),
              ),
            ),
            SettingField(
              label: 'Color Theme',
              child: DropdownButtonFormField<String>(
                value: (draft['color_theme'] as String?) ?? 'dark',
                decoration: const InputDecoration(isDense: true),
                items: const [
                  DropdownMenuItem(value: 'dark', child: Text('Dark')),
                  DropdownMenuItem(value: 'light', child: Text('Light')),
                  DropdownMenuItem(value: 'high-contrast',
                      child: Text('High Contrast')),
                ],
                onChanged: (v) => _notifier.updateField('color_theme', v),
              ),
            ),
            SettingField(
              label: 'Language',
              child: DropdownButtonFormField<String>(
                value: (draft['language'] as String?) ?? 'auto',
                decoration: const InputDecoration(isDense: true),
                items: const [
                  DropdownMenuItem(value: 'auto', child: Text('Auto')),
                  DropdownMenuItem(value: 'ko', child: Text('Korean')),
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'es', child: Text('Spanish')),
                ],
                onChanged: (v) => _notifier.updateField('language', v),
              ),
            ),
          ],
        ),

        SettingSection(
          title: 'Element Visibility',
          subtitle: 'Toggle individual overlay elements.',
          children: [
            for (final key in const [
              'pot',
              'blinds',
              'hole_cards',
              'player_names',
              'player_stacks',
              'equity',
              'leaderboard',
              'timer',
            ])
              SwitchListTile(
                dense: true,
                title: Text(_humaniseElementKey(key)),
                value: _readVisibility(draft, key),
                onChanged: (v) {
                  final ev = Map<String, dynamic>.from(
                      (draft['element_visibility'] as Map?) ?? const {});
                  ev[key] = v;
                  _notifier.updateField('element_visibility', ev);
                },
              ),
          ],
        ),

        // Error banner
        if (state.error != null) ...[
          const SizedBox(height: 16),
          MaterialBanner(
            content: Text(state.error!),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            contentTextStyle: TextStyle(
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            actions: const [SizedBox.shrink()],
          ),
        ],
      ],
    );
  }
}
