// Stats settings screen — ported from StatsPage.vue.
//
// Equity, Outs, Leaderboard, Score Strip display toggles.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
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
