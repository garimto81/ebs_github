// Settings shell — 6-tab container with TabBar, dirty badge, save/discard.
//
// Ported from SettingsLayout.vue. Uses GoRouter :section param
// to sync the active tab. Each tab screen is a child widget
// that reads from settingsSectionProvider(section).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/settings_provider.dart';
import 'display_screen.dart';
import 'gfx_screen.dart';
import 'outputs_screen.dart';
import 'preferences_screen.dart';
import 'rules_screen.dart';
import 'stats_screen.dart';

/// Maps URL slug to [SettingsSection] enum.
SettingsSection _sectionFromSlug(String? slug) {
  return switch (slug) {
    'outputs' => SettingsSection.outputs,
    'gfx' => SettingsSection.gfx,
    'display' => SettingsSection.display,
    'rules' => SettingsSection.rules,
    'stats' => SettingsSection.stats,
    'preferences' => SettingsSection.preferences,
    _ => SettingsSection.outputs,
  };
}

String _slugFromSection(SettingsSection s) => s.name;

class SettingsLayout extends ConsumerStatefulWidget {
  final String section;
  const SettingsLayout({super.key, required this.section});

  @override
  ConsumerState<SettingsLayout> createState() => _SettingsLayoutState();
}

class _SettingsLayoutState extends ConsumerState<SettingsLayout>
    with SingleTickerProviderStateMixin {
  static const _tabs = SettingsSection.values;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final initial = _tabs.indexOf(_sectionFromSlug(widget.section));
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: initial >= 0 ? initial : 0,
    );
    _tabController.addListener(_onTabChanged);
  }

  @override
  void didUpdateWidget(covariant SettingsLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section != widget.section) {
      final idx = _tabs.indexOf(_sectionFromSlug(widget.section));
      if (idx >= 0 && _tabController.index != idx) {
        _tabController.index = idx;
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final slug = _slugFromSection(_tabs[_tabController.index]);
      context.go('/settings/$slug');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final anyDirty = ref.watch(isAnySettingsDirtyProvider);
    final currentSection = _sectionFromSlug(widget.section);
    final sectionState = ref.watch(settingsSectionProvider(currentSection));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          if (anyDirty) ...[
            TextButton(
              onPressed: () {
                ref
                    .read(settingsSectionProvider(currentSection).notifier)
                    .revert();
              },
              child: const Text('Discard'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: sectionState.isDirty && !sectionState.isSaving
                  ? () {
                      ref
                          .read(
                              settingsSectionProvider(currentSection).notifier)
                          .save();
                    }
                  : null,
              icon: sectionState.isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save, size: 18),
              label: const Text('Save'),
            ),
            const SizedBox(width: 16),
          ],
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _tabs.map((s) {
            final isDirty =
                ref.watch(settingsSectionProvider(s)).isDirty;
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_tabLabel(s)),
                  if (isDirty) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: _buildTabBody(currentSection),
    );
  }

  Widget _buildTabBody(SettingsSection section) {
    return switch (section) {
      SettingsSection.outputs => const OutputsScreen(),
      SettingsSection.gfx => const GfxScreen(),
      SettingsSection.display => const DisplayScreen(),
      SettingsSection.rules => const RulesScreen(),
      SettingsSection.stats => const StatsScreen(),
      SettingsSection.preferences => const PreferencesScreen(),
    };
  }

  String _tabLabel(SettingsSection s) {
    return switch (s) {
      SettingsSection.outputs => 'Outputs',
      SettingsSection.gfx => 'GFX',
      SettingsSection.display => 'Display',
      SettingsSection.rules => 'Rules',
      SettingsSection.stats => 'Stats',
      SettingsSection.preferences => 'Preferences',
    };
  }
}
