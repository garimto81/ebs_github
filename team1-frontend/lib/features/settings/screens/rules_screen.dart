// Rules settings screen — ported from RulesPage.vue.
//
// Game rules (Bomb Pot, Straddle, Sleeper) and player display
// (seat number, player order, highlight active).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';
import '../widgets/setting_field.dart';
import '../widgets/setting_section.dart';

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

        const Divider(height: 40),

        // ── SG-003 Extended Fields ───────────────────────────────
        SettingSection(
          title: 'Game Variant',
          children: [
            SettingField(
              label: 'Game Variant',
              child: DropdownButtonFormField<String>(
                value:
                    (draft['game_variant'] as String?) ?? 'NLHE',
                decoration: const InputDecoration(isDense: true),
                items: const [
                  // 22 variants (NLHE + Omaha family + Stud + Mix)
                  DropdownMenuItem(value: 'NLHE', child: Text("NL Hold'em")),
                  DropdownMenuItem(value: 'LHE', child: Text("Limit Hold'em")),
                  DropdownMenuItem(value: 'PLHE', child: Text("PL Hold'em")),
                  DropdownMenuItem(value: 'PLO4', child: Text('PL Omaha 4')),
                  DropdownMenuItem(value: 'PLO5', child: Text('PL Omaha 5')),
                  DropdownMenuItem(value: 'PLO6', child: Text('PL Omaha 6')),
                  DropdownMenuItem(value: 'PLO8', child: Text('PLO Hi/Lo 8')),
                  DropdownMenuItem(value: 'LOMAHA', child: Text('Limit Omaha')),
                  DropdownMenuItem(value: 'COURCHEVEL', child: Text('Courchevel')),
                  DropdownMenuItem(value: 'BIGO', child: Text('Big O')),
                  DropdownMenuItem(value: 'SHORTDECK', child: Text('Short Deck')),
                  DropdownMenuItem(value: 'STUD', child: Text('7-Card Stud')),
                  DropdownMenuItem(value: 'STUD8', child: Text('Stud Hi/Lo')),
                  DropdownMenuItem(value: 'RAZZ', child: Text('Razz')),
                  DropdownMenuItem(value: 'DRAW5', child: Text('5-Card Draw')),
                  DropdownMenuItem(value: 'LOWBALL', child: Text('2-7 Lowball')),
                  DropdownMenuItem(value: 'BADUGI', child: Text('Badugi')),
                  DropdownMenuItem(value: 'HORSE', child: Text('HORSE')),
                  DropdownMenuItem(value: '8GAME', child: Text('8-Game')),
                  DropdownMenuItem(value: 'PPC', child: Text('PPC')),
                  DropdownMenuItem(
                      value: 'DEALERS_CHOICE', child: Text("Dealer's Choice")),
                  DropdownMenuItem(value: 'MIXED', child: Text('Mixed')),
                ],
                onChanged: (v) =>
                    _notifier.updateField('game_variant', v),
              ),
            ),
            SettingField(
              label: 'Blind Structure',
              child: DropdownButtonFormField<String>(
                value:
                    (draft['blind_structure_id'] as String?) ?? 'standard',
                decoration: const InputDecoration(isDense: true),
                items: const [
                  DropdownMenuItem(value: 'standard', child: Text('Standard')),
                  DropdownMenuItem(value: 'turbo', child: Text('Turbo')),
                  DropdownMenuItem(value: 'hyper', child: Text('Hyper')),
                  DropdownMenuItem(value: 'deep', child: Text('Deep Stack')),
                ],
                onChanged: (v) =>
                    _notifier.updateField('blind_structure_id', v),
              ),
            ),
            SettingField(
              label: 'Ante Schedule',
              child: DropdownButtonFormField<String>(
                value:
                    (draft['ante_schedule_id'] as String?) ?? 'bb-ante',
                decoration: const InputDecoration(isDense: true),
                items: const [
                  DropdownMenuItem(value: 'none', child: Text('No ante')),
                  DropdownMenuItem(value: 'bb-ante', child: Text('Big Blind Ante')),
                  DropdownMenuItem(value: 'classic', child: Text('Classic ante')),
                ],
                onChanged: (v) =>
                    _notifier.updateField('ante_schedule_id', v),
              ),
            ),
            SettingField(
              label: 'Time Bank (seconds)',
              child: TextFormField(
                initialValue:
                    '${(draft['time_bank_seconds'] as int?) ?? 30}',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(isDense: true),
                onChanged: (v) {
                  final parsed = int.tryParse(v);
                  if (parsed != null && parsed >= 0 && parsed <= 600) {
                    _notifier.updateField('time_bank_seconds', parsed);
                  }
                },
              ),
            ),
          ],
        ),

        SettingSection(
          title: 'House Rules',
          children: [
            SettingField(
              label: 'Showdown Order',
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'clockwise', label: Text('Clockwise')),
                  ButtonSegment(value: 'last-aggressor', label: Text('Aggressor')),
                ],
                selected: {
                  (draft['showdown_order'] as String?) ?? 'last-aggressor',
                },
                onSelectionChanged: (s) =>
                    _notifier.updateField('showdown_order', s.first),
              ),
            ),
            SettingField(
              label: 'Under-Raise Rule',
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'reopen', label: Text('Reopen')),
                  ButtonSegment(value: 'no-reopen', label: Text('No reopen')),
                ],
                selected: {
                  (draft['under_raise_rule'] as String?) ?? 'no-reopen',
                },
                onSelectionChanged: (s) =>
                    _notifier.updateField('under_raise_rule', s.first),
              ),
            ),
            SettingField(
              label: 'Short All-In Rule',
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'full-reopen', label: Text('Full reopen')),
                  ButtonSegment(value: 'partial', label: Text('Partial')),
                ],
                selected: {
                  (draft['short_all_in_rule'] as String?) ?? 'full-reopen',
                },
                onSelectionChanged: (s) =>
                    _notifier.updateField('short_all_in_rule', s.first),
              ),
            ),
            SettingField(
              label: 'Dead Button Rule',
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'dead-button', label: Text('Dead button')),
                  ButtonSegment(value: 'moving-button', label: Text('Moving button')),
                ],
                selected: {
                  (draft['dead_button_rule'] as String?) ?? 'dead-button',
                },
                onSelectionChanged: (s) =>
                    _notifier.updateField('dead_button_rule', s.first),
              ),
            ),
          ],
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
