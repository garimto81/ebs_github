// Outputs settings screen — ported from OutputsPage.vue.
//
// Resolution, frame rate, output protocol (NDI/RTMP/SRT/DIRECT),
// Fill & Key routing toggle.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';
import '../widgets/setting_field.dart';
import '../widgets/setting_section.dart';

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

        const Divider(height: 40),

        // ── SG-003 Extended Fields ───────────────────────────────
        SettingSection(
          title: 'Output Targets',
          subtitle: 'Distinct sinks (SDI / NDI / Preview) — add as needed.',
          children: [
            _OutputTargetsList(draft: draft, notifier: _notifier),
          ],
        ),

        SettingField(
          label: 'Active Overlay Preset',
          child: DropdownButtonFormField<String>(
            value: (draft['active_overlay_preset_id'] as String?) ??
                'default-overlay',
            decoration: const InputDecoration(isDense: true),
            items: const [
              DropdownMenuItem(
                  value: 'default-overlay', child: Text('Default')),
              DropdownMenuItem(
                  value: 'featured-table', child: Text('Featured Table')),
              DropdownMenuItem(
                  value: 'final-table', child: Text('Final Table')),
            ],
            onChanged: (v) =>
                _notifier.updateField('active_overlay_preset_id', v),
          ),
        ),

        SettingField(
          label: 'Security Delay',
          helperText:
              '${(draft['security_delay_ms'] as num?)?.toInt() ?? 0} ms '
              '(0 – 10000)',
          child: Slider(
            value:
                ((draft['security_delay_ms'] as num?)?.toDouble() ?? 0)
                    .clamp(0, 10000),
            min: 0,
            max: 10000,
            divisions: 20,
            onChanged: (v) =>
                _notifier.updateField('security_delay_ms', v.toInt()),
          ),
        ),

        SwitchListTile(
          title: const Text('Watermark'),
          subtitle: const Text('Overlay a text watermark on all outputs'),
          value: (draft['watermark_enabled'] as bool?) ?? false,
          onChanged: (v) =>
              _notifier.updateField('watermark_enabled', v),
        ),
        if ((draft['watermark_enabled'] as bool?) ?? false)
          Padding(
            padding: const EdgeInsets.only(left: 24, top: 4, bottom: 8),
            child: TextFormField(
              initialValue: (draft['watermark_text'] as String?) ?? '',
              decoration: const InputDecoration(
                labelText: 'Watermark text',
                hintText: 'e.g. PREVIEW',
              ),
              onChanged: (v) =>
                  _notifier.updateField('watermark_text', v),
            ),
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

class _OutputTargetsList extends StatelessWidget {
  const _OutputTargetsList({
    required this.draft,
    required this.notifier,
  });

  final Map<String, dynamic> draft;
  final SettingsSectionNotifier notifier;

  List<Map<String, dynamic>> get _targets {
    final raw = draft['output_targets'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final targets = _targets;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (targets.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No output targets yet. Tap ADD to create one.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: targets.length,
            itemBuilder: (ctx, i) {
              final t = targets[i];
              return ListTile(
                dense: true,
                leading: const Icon(Icons.outbound_rounded),
                title: Text('${t['kind'] ?? 'SDI'} — ${t['label'] ?? ''}'),
                subtitle: Text('${t['endpoint'] ?? ''}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    final next = List<Map<String, dynamic>>.from(targets)
                      ..removeAt(i);
                    notifier.updateField('output_targets', next);
                  },
                ),
              );
            },
          ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('ADD'),
            onPressed: () {
              final next = List<Map<String, dynamic>>.from(targets)
                ..add({
                  'kind': 'SDI',
                  'label': 'Output ${targets.length + 1}',
                  'endpoint': '',
                });
              notifier.updateField('output_targets', next);
            },
          ),
        ),
      ],
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
