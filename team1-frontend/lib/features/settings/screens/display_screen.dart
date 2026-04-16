// Display settings screen — ported from DisplayPage.vue.
//
// Blinds display format, precision digits, display mode (standard/compact).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';

class DisplayScreen extends ConsumerStatefulWidget {
  const DisplayScreen({super.key});

  @override
  ConsumerState<DisplayScreen> createState() => _DisplayScreenState();
}

class _DisplayScreenState extends ConsumerState<DisplayScreen> {
  static const _blindsFormatOptions = [
    ('sb_bb', '100/200'),
    ('sb_bb_ante', '100/200/25 (with ante)'),
  ];

  static const _displayModeOptions = [
    ('standard', 'Standard'),
    ('compact', 'Compact'),
  ];

  @override
  void initState() {
    super.initState();
    _fetchIfIdle();
  }

  void _fetchIfIdle() {
    final state = ref.read(settingsSectionProvider(SettingsSection.display));
    if (!state.isLoading &&
        state.committed.isEmpty &&
        state.error == null) {
      ref
          .read(settingsSectionProvider(SettingsSection.display).notifier)
          .fetch();
    }
  }

  SettingsSectionNotifier get _notifier =>
      ref.read(settingsSectionProvider(SettingsSection.display).notifier);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsSectionProvider(SettingsSection.display));
    final draft = state.draft;

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final blindsFormat = (draft['blindsFormat'] as String?) ?? 'sb_bb';
    final displayMode = (draft['displayMode'] as String?) ?? 'standard';
    final precision = (draft['precisionDigits'] as int?) ?? 0;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Blinds Display Format
        Text(
          'Blinds Display Format',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...List.generate(_blindsFormatOptions.length, (i) {
          final opt = _blindsFormatOptions[i];
          return RadioListTile<String>(
            title: Text(opt.$2),
            value: opt.$1,
            groupValue: blindsFormat,
            onChanged: (v) => _notifier.updateField('blindsFormat', v),
          );
        }),
        const SizedBox(height: 20),

        // Precision Digits
        Text(
          'Precision Digits',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 240,
          child: DropdownButtonFormField<int>(
            value: precision.clamp(0, 4),
            decoration: const InputDecoration(labelText: 'Decimal places'),
            items: List.generate(
              5,
              (i) => DropdownMenuItem(value: i, child: Text('$i')),
            ),
            onChanged: (v) => _notifier.updateField('precisionDigits', v),
          ),
        ),
        const SizedBox(height: 20),

        // Display Mode
        Text(
          'Display Mode',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _displayModeOptions.map((opt) {
            return ChoiceChip(
              label: Text(opt.$2),
              selected: displayMode == opt.$1,
              onSelected: (_) =>
                  _notifier.updateField('displayMode', opt.$1),
            );
          }).toList(),
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
