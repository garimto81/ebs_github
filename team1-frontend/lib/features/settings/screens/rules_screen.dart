// Rules settings screen — ported from RulesPage.vue.
//
// Game rules (Bomb Pot, Straddle, Sleeper) and player display
// (seat number, player order, highlight active).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';

class RulesScreen extends ConsumerStatefulWidget {
  const RulesScreen({super.key});

  @override
  ConsumerState<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends ConsumerState<RulesScreen> {
  static const _straddleTypeOptions = [
    ('utg', 'UTG Only'),
    ('mississippi', 'Mississippi'),
    ('sleeper', 'Sleeper Straddle'),
    ('any', 'Any Position'),
  ];

  @override
  void initState() {
    super.initState();
    _fetchIfIdle();
  }

  void _fetchIfIdle() {
    final state = ref.read(settingsSectionProvider(SettingsSection.rules));
    if (!state.isLoading && state.committed.isEmpty && state.error == null) {
      ref
          .read(settingsSectionProvider(SettingsSection.rules).notifier)
          .fetch();
    }
  }

  SettingsSectionNotifier get _notifier =>
      ref.read(settingsSectionProvider(SettingsSection.rules).notifier);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsSectionProvider(SettingsSection.rules));
    final draft = state.draft;
    final theme = Theme.of(context);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final bombPotEnabled = (draft['bombPotEnabled'] as bool?) ?? false;
    final straddleEnabled = (draft['straddleEnabled'] as bool?) ?? false;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // ── Game Rules ─────────────────────────────────────────────
        Text(
          'Game Rules',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        // Bomb Pot
        SwitchListTile(
          title: const Text('Bomb Pot'),
          value: bombPotEnabled,
          onChanged: (v) => _notifier.updateField('bombPotEnabled', v),
        ),
        if (bombPotEnabled)
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: SizedBox(
              width: 240,
              child: TextFormField(
                initialValue:
                    '${(draft['bombPotFrequency'] as int?) ?? 10}',
                decoration: const InputDecoration(
                  labelText: 'Frequency (every N hands)',
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  final parsed = int.tryParse(v);
                  if (parsed != null && parsed >= 1 && parsed <= 100) {
                    _notifier.updateField('bombPotFrequency', parsed);
                  }
                },
              ),
            ),
          ),
        const SizedBox(height: 8),

        // Straddle
        SwitchListTile(
          title: const Text('Straddle'),
          value: straddleEnabled,
          onChanged: (v) => _notifier.updateField('straddleEnabled', v),
        ),
        if (straddleEnabled)
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: SizedBox(
              width: 240,
              child: DropdownButtonFormField<String>(
                value: (draft['straddleType'] as String?) ?? 'utg',
                decoration:
                    const InputDecoration(labelText: 'Straddle Type'),
                items: _straddleTypeOptions
                    .map((o) =>
                        DropdownMenuItem(value: o.$1, child: Text(o.$2)))
                    .toList(),
                onChanged: (v) =>
                    _notifier.updateField('straddleType', v),
              ),
            ),
          ),
        const SizedBox(height: 8),

        // Sleeper
        SwitchListTile(
          title: const Text('Sleeper'),
          value: (draft['sleeperEnabled'] as bool?) ?? false,
          onChanged: (v) => _notifier.updateField('sleeperEnabled', v),
        ),

        const Divider(height: 40),

        // ── Player Display ─────────────────────────────────────────
        Text(
          'Player Display',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        SwitchListTile(
          title: const Text('Show Seat Number'),
          value: (draft['showSeatNumber'] as bool?) ?? true,
          onChanged: (v) => _notifier.updateField('showSeatNumber', v),
        ),
        SwitchListTile(
          title: const Text('Show Player Order'),
          value: (draft['showPlayerOrder'] as bool?) ?? true,
          onChanged: (v) => _notifier.updateField('showPlayerOrder', v),
        ),
        SwitchListTile(
          title: const Text('Highlight Active Player'),
          value: (draft['highlightActivePlayer'] as bool?) ?? true,
          onChanged: (v) =>
              _notifier.updateField('highlightActivePlayer', v),
        ),

        // Error banner
        if (state.error != null) ...[
          const SizedBox(height: 16),
          MaterialBanner(
            content: Text(state.error!),
            backgroundColor: theme.colorScheme.errorContainer,
            contentTextStyle: TextStyle(
              color: theme.colorScheme.onErrorContainer,
            ),
            actions: const [SizedBox.shrink()],
          ),
        ],
      ],
    );
  }
}
