// Preferences settings screen — ported from PreferencesPage.vue.
//
// Language/locale (ko/en/es), table password, diagnostics toggle,
// export folder, 2FA setup/disable section.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/preferences_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/setting_field.dart';
import '../widgets/setting_section.dart';

class PreferencesScreen extends ConsumerStatefulWidget {
  const PreferencesScreen({super.key});

  @override
  ConsumerState<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends ConsumerState<PreferencesScreen> {
  static const _languageOptions = [
    ('ko', 'Korean'),
    ('en', 'English'),
    ('es', 'Spanish'),
  ];

  bool _showPassword = false;
  bool _twoFactorLoading = false;

  // 2FA dialog state
  String? _qrCodeUrl;
  String? _twoFactorSecret;
  String? _twoFactorError;
  final _confirmCodeController = TextEditingController();
  final _disableCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchIfIdle();
  }

  @override
  void dispose() {
    _confirmCodeController.dispose();
    _disableCodeController.dispose();
    super.dispose();
  }

  void _fetchIfIdle() {
    final state =
        ref.read(settingsSectionProvider(SettingsSection.preferences));
    if (!state.isLoading &&
        state.committed.isEmpty &&
        state.error == null) {
      ref
          .read(settingsSectionProvider(SettingsSection.preferences).notifier)
          .fetch();
    }
  }

  SettingsSectionNotifier get _notifier =>
      ref.read(settingsSectionProvider(SettingsSection.preferences).notifier);

  @override
  Widget build(BuildContext context) {
    final state =
        ref.watch(settingsSectionProvider(SettingsSection.preferences));
    final draft = state.draft;
    final theme = Theme.of(context);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 2FA status from draft (server would populate this)
    final twoFactorEnabled =
        (draft['twoFactorEnabled'] as bool?) ?? false;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // ── General Preferences ────────────────────────────────────
        // Language
        DropdownButtonFormField<String>(
          value: (draft['language'] as String?) ?? 'ko',
          decoration: const InputDecoration(labelText: 'Language'),
          items: _languageOptions
              .map((o) => DropdownMenuItem(value: o.$1, child: Text(o.$2)))
              .toList(),
          onChanged: (v) {
            _notifier.updateField('language', v);
            // TODO: wire locale change via l10n provider
          },
        ),
        const SizedBox(height: 20),

        // Table Password
        TextFormField(
          initialValue: (draft['tablePassword'] as String?) ?? '',
          decoration: InputDecoration(
            labelText: 'Table Password',
            suffixIcon: IconButton(
              icon: Icon(
                _showPassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
          ),
          obscureText: !_showPassword,
          onChanged: (v) => _notifier.updateField('tablePassword', v),
        ),
        const SizedBox(height: 20),

        // Diagnostics
        SwitchListTile(
          title: const Text('Enable Diagnostics'),
          subtitle: const Text('Collect performance and error telemetry'),
          value: (draft['diagnosticsEnabled'] as bool?) ?? false,
          onChanged: (v) =>
              _notifier.updateField('diagnosticsEnabled', v),
        ),
        const SizedBox(height: 12),

        // Export Folder
        TextFormField(
          initialValue: (draft['exportFolder'] as String?) ?? '',
          decoration: const InputDecoration(
            labelText: 'Export Folder',
            hintText: '/path/to/export',
          ),
          onChanged: (v) => _notifier.updateField('exportFolder', v),
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

        const Divider(height: 48),

        // ── 2FA Section ────────────────────────────────────────────
        Text(
          'Two-Factor Authentication',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: twoFactorEnabled
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                twoFactorEnabled ? 'Enabled' : 'Disabled',
                style: TextStyle(
                  color: twoFactorEnabled ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        const Divider(height: 48),

        // ── SG-003 Extended Fields (user-scope) ──────────────────
        _SG003PrefsBlock(),

        const Divider(height: 48),

        if (!twoFactorEnabled)
          ElevatedButton(
            onPressed: _twoFactorLoading ? null : () => _showSetup2faDialog(),
            child: _twoFactorLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enable 2FA'),
          )
        else
          OutlinedButton(
            onPressed: () => _showDisable2faDialog(),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(color: theme.colorScheme.error),
            ),
            child: const Text('Disable 2FA'),
          ),
      ],
    );
  }

  // ── 2FA Dialogs ──────────────────────────────────────────────────

  void _showSetup2faDialog() {
    setState(() {
      _twoFactorLoading = true;
      _twoFactorError = null;
      _confirmCodeController.clear();
    });

    // TODO: wire authApi.setup2fa() — populate _qrCodeUrl & _twoFactorSecret
    // For now, show dialog with placeholder
    setState(() {
      _twoFactorLoading = false;
      _qrCodeUrl = null;
      _twoFactorSecret = 'PLACEHOLDER_SECRET';
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Up 2FA'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // QR Code
              if (_qrCodeUrl != null)
                Image.network(_qrCodeUrl!, width: 200, height: 200)
              else
                Container(
                  width: 200,
                  height: 200,
                  color: Colors.grey.withValues(alpha: 0.2),
                  alignment: Alignment.center,
                  child: const Text('QR Code'),
                ),
              const SizedBox(height: 12),
              if (_twoFactorSecret != null)
                SelectableText(
                  'Manual entry: $_twoFactorSecret',
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmCodeController,
                decoration: const InputDecoration(
                  labelText: 'Confirmation Code',
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
              if (_twoFactorError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _twoFactorError!,
                  style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // TODO: wire authApi.confirm2fa(_confirmCodeController.text)
              Navigator.of(ctx).pop();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showDisable2faDialog() {
    _disableCodeController.clear();
    _twoFactorError = null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Disable 2FA'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Disabling two-factor authentication will reduce the '
                'security of your account. Enter your 2FA code to confirm.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _disableCodeController,
                decoration: const InputDecoration(
                  labelText: 'Confirmation Code',
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
              if (_twoFactorError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _twoFactorError!,
                  style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // TODO: wire authApi.disable2fa(_disableCodeController.text)
              Navigator.of(ctx).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Disable'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// SG-003 user-scope preferences block (consumes PreferencesProvider).
// ─────────────────────────────────────────────────────────────────

class _SG003PrefsBlock extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesProvider);
    final notifier = ref.read(preferencesProvider.notifier);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Advanced Preferences',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),

        SettingSection(
          title: 'Shortcuts',
          subtitle: 'Keyboard bindings for frequent operator actions.',
          children: [
            _ShortcutTable(shortcuts: prefs.shortcuts, notifier: notifier),
          ],
        ),

        SettingSection(
          title: 'Notifications',
          children: [
            SwitchListTile(
              title: const Text('Enable notifications'),
              value: prefs.notification.enabled,
              onChanged: (v) =>
                  notifier.updateNotificationEnabled(v),
            ),
            SwitchListTile(
              title: const Text('Sound alerts'),
              value: prefs.notification.soundEnabled,
              onChanged: (v) =>
                  notifier.updateNotificationSoundEnabled(v),
            ),
            SettingField(
              label: 'Volume',
              helperText: '${(prefs.notification.volume * 100).toInt()}%',
              child: Slider(
                value: prefs.notification.volume.clamp(0.0, 1.0),
                min: 0,
                max: 1,
                onChanged: (v) => notifier.updateNotificationVolume(v),
              ),
            ),
          ],
        ),

        SettingSection(
          title: 'Default View',
          children: [
            SettingField(
              label: 'Table view',
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'grid', label: Text('Grid')),
                  ButtonSegment(value: 'list', label: Text('List')),
                ],
                selected: {prefs.defaultView.tableView},
                onSelectionChanged: (s) =>
                    notifier.updateDefaultTableView(s.first),
              ),
            ),
          ],
        ),

        SettingSection(
          title: 'Auto Logout',
          children: [
            SwitchListTile(
              title: const Text('Enable idle auto-logout'),
              value: prefs.autoLogout.enabled,
              onChanged: (v) => notifier.updateAutoLogoutEnabled(v),
            ),
            SettingField(
              label: 'Idle minutes',
              helperText: '${prefs.autoLogout.idleMinutes} minutes',
              child: Slider(
                value: prefs.autoLogout.idleMinutes
                    .clamp(15, 240)
                    .toDouble(),
                min: 15,
                max: 240,
                divisions: 15,
                onChanged: (v) =>
                    notifier.updateAutoLogoutIdleMinutes(v.toInt()),
              ),
            ),
          ],
        ),

        SettingSection(
          title: 'Locale',
          children: [
            SettingField(
              label: 'Language',
              child: DropdownButtonFormField<String>(
                value: prefs.locale,
                decoration: const InputDecoration(isDense: true),
                items: const [
                  DropdownMenuItem(value: 'auto', child: Text('Auto')),
                  DropdownMenuItem(value: 'ko', child: Text('한국어')),
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'es', child: Text('Español')),
                ],
                onChanged: (v) {
                  if (v != null) notifier.updateLocale(v);
                },
              ),
            ),
          ],
        ),

        SettingSection(
          title: 'Export Defaults',
          children: [
            SettingField(
              label: 'Format',
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'csv', label: Text('CSV')),
                  ButtonSegment(value: 'json', label: Text('JSON')),
                  ButtonSegment(value: 'xlsx', label: Text('XLSX')),
                ],
                selected: {prefs.exportDefaults.format},
                onSelectionChanged: (s) =>
                    notifier.updateExportFormat(s.first),
              ),
            ),
            SwitchListTile(
              title: const Text('Include headers'),
              value: prefs.exportDefaults.includeHeaders,
              onChanged: (v) =>
                  notifier.updateExportIncludeHeaders(v),
            ),
          ],
        ),
      ],
    );
  }
}

class _ShortcutTable extends StatelessWidget {
  const _ShortcutTable({required this.shortcuts, required this.notifier});

  final Map<String, String> shortcuts;
  final PreferencesController notifier;

  @override
  Widget build(BuildContext context) {
    if (shortcuts.isEmpty) {
      return const Text('No shortcuts configured.');
    }
    return DataTable(
      columnSpacing: 16,
      columns: const [
        DataColumn(label: Text('Action')),
        DataColumn(label: Text('Binding')),
      ],
      rows: shortcuts.entries.map((e) {
        return DataRow(cells: [
          DataCell(Text(e.key)),
          DataCell(
            SizedBox(
              width: 160,
              child: TextFormField(
                initialValue: e.value,
                decoration: const InputDecoration(isDense: true),
                onFieldSubmitted: (v) {
                  final next = Map<String, String>.from(shortcuts);
                  next[e.key] = v;
                  try {
                    notifier.updateShortcuts(next);
                  } catch (_) {
                    // validator error — silently ignore in skeleton.
                  }
                },
              ),
            ),
          ),
        ]);
      }).toList(),
    );
  }
}
