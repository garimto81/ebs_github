// Outputs settings screen — ported from OutputsPage.vue.
//
// Resolution, frame rate, output protocol (NDI/RTMP/SRT/DIRECT),
// Fill & Key routing toggle.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';

class OutputsScreen extends ConsumerStatefulWidget {
  const OutputsScreen({super.key});

  @override
  ConsumerState<OutputsScreen> createState() => _OutputsScreenState();
}

class _OutputsScreenState extends ConsumerState<OutputsScreen> {
  static const _resolutionOptions = [
    ('1920x1080', '1920 x 1080 (Full HD)'),
    ('2560x1440', '2560 x 1440 (QHD)'),
    ('3840x2160', '3840 x 2160 (4K UHD)'),
  ];

  static const _frameRateOptions = [
    (30, '30 fps'),
    (60, '60 fps'),
  ];

  static const _protocolOptions = ['NDI', 'RTMP', 'SRT', 'DIRECT'];

  @override
  void initState() {
    super.initState();
    _fetchIfIdle();
  }

  void _fetchIfIdle() {
    final state = ref.read(settingsSectionProvider(SettingsSection.outputs));
    if (!state.isLoading &&
        state.committed.isEmpty &&
        state.error == null) {
      ref
          .read(settingsSectionProvider(SettingsSection.outputs).notifier)
          .fetch();
    }
  }

  SettingsSectionNotifier get _notifier =>
      ref.read(settingsSectionProvider(SettingsSection.outputs).notifier);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsSectionProvider(SettingsSection.outputs));
    final draft = state.draft;

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Resolution
        const _SectionLabel('Resolution'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: (draft['resolution'] as String?) ?? '1920x1080',
          decoration: const InputDecoration(labelText: 'Resolution'),
          items: _resolutionOptions
              .map((o) => DropdownMenuItem(value: o.$1, child: Text(o.$2)))
              .toList(),
          onChanged: (v) => _notifier.updateField('resolution', v),
        ),
        const SizedBox(height: 20),

        // Frame Rate
        const _SectionLabel('Frame Rate'),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: (draft['frameRate'] as int?) ?? 60,
          decoration: const InputDecoration(labelText: 'Frame Rate'),
          items: _frameRateOptions
              .map((o) => DropdownMenuItem(value: o.$1, child: Text(o.$2)))
              .toList(),
          onChanged: (v) => _notifier.updateField('frameRate', v),
        ),
        const SizedBox(height: 20),

        // Output Protocol
        const _SectionLabel('Output Protocol'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _protocolOptions.map((protocol) {
            final selected =
                (draft['outputProtocol'] as String?) == protocol ||
                    (draft['outputProtocol'] == null &&
                        protocol == 'NDI');
            return ChoiceChip(
              label: Text(protocol),
              selected: selected,
              onSelected: (_) =>
                  _notifier.updateField('outputProtocol', protocol),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Fill & Key Routing
        SwitchListTile(
          title: const Text('Fill & Key Routing'),
          subtitle:
              const Text('Enable separate fill and key output channels'),
          value: (draft['fillKeyRouting'] as bool?) ?? false,
          onChanged: (v) => _notifier.updateField('fillKeyRouting', v),
        ),

        // Error banner
        if (state.error != null) ...[
          const SizedBox(height: 16),
          _ErrorBanner(message: state.error!),
        ],
      ],
    );
  }
}

// ── Shared helpers (file-private) ────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .titleSmall
          ?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      content: Text(message),
      backgroundColor: Theme.of(context).colorScheme.errorContainer,
      contentTextStyle: TextStyle(
        color: Theme.of(context).colorScheme.onErrorContainer,
      ),
      actions: const [SizedBox.shrink()],
    );
  }
}
