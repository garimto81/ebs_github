// Stats settings screen — ported from StatsPage.vue.
//
// Equity, Outs, Leaderboard, Score Strip display toggles.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';
import '../widgets/setting_field.dart';
import '../widgets/setting_section.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

bool _readHudField(Map<String, dynamic> draft, String key) {
  final raw = draft['hud_fields'];
  if (raw is List) return raw.contains(key);
  return false;
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  @override
  void initState() {
    super.initState();
    _fetchIfIdle();
  }

  void _fetchIfIdle() {
    final state = ref.read(settingsSectionProvider(SettingsSection.stats));
    if (!state.isLoading && state.committed.isEmpty && state.error == null) {
      ref
          .read(settingsSectionProvider(SettingsSection.stats).notifier)
          .fetch();
    }
  }

  SettingsSectionNotifier get _notifier =>
      ref.read(settingsSectionProvider(SettingsSection.stats).notifier);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsSectionProvider(SettingsSection.stats));
    final draft = state.draft;

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Statistics Display',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Show Equity'),
          subtitle: const Text('Display win equity percentages'),
          value: (draft['showEquity'] as bool?) ?? true,
          onChanged: (v) => _notifier.updateField('showEquity', v),
        ),
        SwitchListTile(
          title: const Text('Show Outs'),
          subtitle: const Text('Display remaining outs count'),
          value: (draft['showOuts'] as bool?) ?? true,
          onChanged: (v) => _notifier.updateField('showOuts', v),
        ),
        SwitchListTile(
          title: const Text('Show Leaderboard'),
          subtitle: const Text('Display chip leader rankings'),
          value: (draft['showLeaderboard'] as bool?) ?? true,
          onChanged: (v) => _notifier.updateField('showLeaderboard', v),
        ),
        SwitchListTile(
          title: const Text('Show Score Strip'),
          subtitle: const Text('Display score strip overlay'),
          value: (draft['showScoreStrip'] as bool?) ?? true,
          onChanged: (v) => _notifier.updateField('showScoreStrip', v),
        ),

        const Divider(height: 40),

        // ── SG-003 Extended Fields ───────────────────────────────
        SettingSection(
          title: 'Equity & Outs',
          children: [
            SettingField(
              label: 'Equity Display Mode',
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'percent', label: Text('Percent')),
                  ButtonSegment(value: 'odds', label: Text('Odds')),
                  ButtonSegment(value: 'both', label: Text('Both')),
                ],
                selected: {
                  (draft['equity_display_mode'] as String?) ?? 'percent',
                },
                onSelectionChanged: (s) =>
                    _notifier.updateField('equity_display_mode', s.first),
              ),
            ),
            SettingField(
              label: 'History Window',
              helperText:
                  'Hands retained on Score Strip: ${(draft['history_window'] as int?) ?? 20}',
              child: Slider(
                value:
                    ((draft['history_window'] as num?)?.toDouble() ?? 20)
                        .clamp(5, 100),
                min: 5,
                max: 100,
                divisions: 19,
                onChanged: (v) =>
                    _notifier.updateField('history_window', v.toInt()),
              ),
            ),
          ],
        ),

        SettingSection(
          title: 'HUD',
          children: [
            SwitchListTile(
              title: const Text('HUD Enabled'),
              subtitle: const Text('Operator heads-up display'),
              value: (draft['hud_enabled'] as bool?) ?? false,
              onChanged: (v) => _notifier.updateField('hud_enabled', v),
            ),
            if ((draft['hud_enabled'] as bool?) ?? false)
              Column(
                children: [
                  for (final f in const [
                    'vpip',
                    'pfr',
                    'af',
                    'three_bet',
                    'cbet',
                    'wtsd',
                    'sample_size',
                  ])
                    CheckboxListTile(
                      dense: true,
                      title: Text(f.toUpperCase().replaceAll('_', ' ')),
                      value: _readHudField(draft, f),
                      onChanged: (v) {
                        final fields = List<String>.from(
                            (draft['hud_fields'] as List?)?.cast<String>() ??
                                const []);
                        if (v == true && !fields.contains(f)) {
                          fields.add(f);
                        } else if (v == false) {
                          fields.remove(f);
                        }
                        _notifier.updateField('hud_fields', fields);
                      },
                    ),
                ],
              ),
            SwitchListTile(
              title: const Text('Player Photo'),
              subtitle: const Text('Render photo avatar next to player name'),
              value: (draft['player_photo_enabled'] as bool?) ?? true,
              onChanged: (v) =>
                  _notifier.updateField('player_photo_enabled', v),
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
