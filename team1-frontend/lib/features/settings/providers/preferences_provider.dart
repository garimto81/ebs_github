// SG-003 §Tab 6 Preferences — user-scope personalization.
//
// Spec: docs/2. Development/2.1 Frontend/Settings/Preferences.md
// Scope: user (global per logged-in user, no Table/Event override).
//
// Fields (see BS-03-06 §1-7):
//   • shortcuts             Map<action, key_combo>
//   • notification           { enabled, sound_enabled, event_types, volume }
//   • default_view           { table_view, players_view, expanded_series }
//   • auto_logout           { enabled, idle_minutes, warn_before_seconds }
//   • ui_visibility         (auto, computed from role)
//   • locale                 enum(auto, ko, en, es)
//   • export_defaults       { format, include_headers, timezone_mode, filename_pattern }
//
// API:
//   GET  /api/v1/users/{me}/preferences
//   PUT  /api/v1/users/{me}/preferences  (partial update)
//
// team1 session TODO markers:
//   [TODO-T1-004] wire Dio API calls (currently returns defaults)
//   [TODO-T1-005] persist locale change to flutter_localizations (hot reload)
//   [TODO-T1-006] RBAC-aware auto_logout bounds (admin 15-240 / op 30-120 / viewer 60-240)
//   [TODO-T1-007] shortcut conflict validator

import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserPreferences {
  const UserPreferences({
    required this.shortcuts,
    required this.notification,
    required this.defaultView,
    required this.autoLogout,
    required this.locale,
    required this.exportDefaults,
  });

  factory UserPreferences.defaults() {
    return UserPreferences(
      shortcuts: const {
        'new_hand': 'Ctrl+N',
        'fold': 'F',
        'check_call': 'Space',
        'bet_raise': 'R',
        'all_in': 'Ctrl+A',
        'undo': 'Ctrl+Z',
        'reveal_holecards': 'H',
        'toggle_overlay': 'Ctrl+O',
      },
      notification: const NotificationPref(
        enabled: true,
        soundEnabled: true,
        eventTypes: {
          'hand_start': false,
          'rfid_error': true,
          'engine_offline': true,
          'sync_conflict': true,
          'new_hand_from_operator': false,
        },
        volume: 0.7,
      ),
      defaultView: const DefaultViewPref(
        tableView: 'grid',
        playersView: 'cards',
        expandedSeries: true,
      ),
      autoLogout: const AutoLogoutPref(
        enabled: true,
        idleMinutes: 60,
        warnBeforeSeconds: 30,
      ),
      locale: 'auto',
      exportDefaults: const ExportDefaults(
        format: 'csv',
        includeHeaders: true,
        timezoneMode: 'local',
        filenamePattern: '{type}_{date}_{user}',
      ),
    );
  }

  final Map<String, String> shortcuts;
  final NotificationPref notification;
  final DefaultViewPref defaultView;
  final AutoLogoutPref autoLogout;
  final String locale;
  final ExportDefaults exportDefaults;

  UserPreferences copyWith({
    Map<String, String>? shortcuts,
    NotificationPref? notification,
    DefaultViewPref? defaultView,
    AutoLogoutPref? autoLogout,
    String? locale,
    ExportDefaults? exportDefaults,
  }) {
    return UserPreferences(
      shortcuts: shortcuts ?? this.shortcuts,
      notification: notification ?? this.notification,
      defaultView: defaultView ?? this.defaultView,
      autoLogout: autoLogout ?? this.autoLogout,
      locale: locale ?? this.locale,
      exportDefaults: exportDefaults ?? this.exportDefaults,
    );
  }
}

class NotificationPref {
  const NotificationPref({
    required this.enabled,
    required this.soundEnabled,
    required this.eventTypes,
    required this.volume,
  });
  final bool enabled;
  final bool soundEnabled;
  final Map<String, bool> eventTypes;
  final double volume;
}

class DefaultViewPref {
  const DefaultViewPref({
    required this.tableView,
    required this.playersView,
    required this.expandedSeries,
  });
  final String tableView; // 'grid' | 'list'
  final String playersView; // 'cards' | 'table'
  final bool expandedSeries;
}

class AutoLogoutPref {
  const AutoLogoutPref({
    required this.enabled,
    required this.idleMinutes,
    required this.warnBeforeSeconds,
  });
  final bool enabled;
  final int idleMinutes;
  final int warnBeforeSeconds;
}

class ExportDefaults {
  const ExportDefaults({
    required this.format,
    required this.includeHeaders,
    required this.timezoneMode,
    required this.filenamePattern,
  });
  final String format; // 'csv' | 'json' | 'xlsx'
  final bool includeHeaders;
  final String timezoneMode; // 'local' | 'utc'
  final String filenamePattern;
}

class PreferencesController extends StateNotifier<UserPreferences> {
  PreferencesController() : super(UserPreferences.defaults());

  /// Load from BO — [TODO-T1-004] wire actual Dio call.
  Future<void> load() async {
    // Skeleton: currently keeps defaults.
  }

  /// Validate shortcut uniqueness + reserved keys.
  /// [TODO-T1-007] expand with Ctrl+F1-F12 blacklist.
  String? validateShortcuts(Map<String, String> sc) {
    final seen = <String>{};
    for (final combo in sc.values) {
      if (!seen.add(combo)) {
        return 'Duplicate shortcut: $combo';
      }
    }
    return null;
  }

  Future<void> updateShortcuts(Map<String, String> sc) async {
    final err = validateShortcuts(sc);
    if (err != null) throw ArgumentError(err);
    state = state.copyWith(shortcuts: sc);
    // [TODO-T1-004] persist via PUT /api/v1/users/me/preferences
  }

  Future<void> updateLocale(String locale) async {
    assert(['auto', 'ko', 'en', 'es'].contains(locale),
        'locale must be auto/ko/en/es');
    state = state.copyWith(locale: locale);
    // [TODO-T1-005] trigger flutter_localizations reload
  }

  // ───────────────────────────────────────────────────────────────
  // SG-003 field-level updaters (partial PUT /preferences payloads).
  // ───────────────────────────────────────────────────────────────

  /// Generic field updater keyed by dotted path (`notification.volume`,
  /// `auto_logout.idle_minutes`, …). Mirrors the backend payload so callers
  /// can stay declarative.
  ///
  /// [TODO-T1-004] once Dio is wired, dispatch a partial PUT with the same
  /// key used here.
  Future<void> updateField(String key, dynamic value) async {
    switch (key) {
      case 'notification.enabled':
        updateNotificationEnabled(value as bool);
      case 'notification.sound_enabled':
        updateNotificationSoundEnabled(value as bool);
      case 'notification.volume':
        updateNotificationVolume((value as num).toDouble());
      case 'default_view.table_view':
        updateDefaultTableView(value as String);
      case 'default_view.players_view':
        updateDefaultPlayersView(value as String);
      case 'auto_logout.enabled':
        updateAutoLogoutEnabled(value as bool);
      case 'auto_logout.idle_minutes':
        updateAutoLogoutIdleMinutes((value as num).toInt());
      case 'locale':
        await updateLocale(value as String);
      case 'export_defaults.format':
        updateExportFormat(value as String);
      case 'export_defaults.include_headers':
        updateExportIncludeHeaders(value as bool);
      default:
        throw ArgumentError('Unknown preferences field: $key');
    }
  }

  void updateNotificationEnabled(bool v) {
    state = state.copyWith(
      notification: NotificationPref(
        enabled: v,
        soundEnabled: state.notification.soundEnabled,
        eventTypes: state.notification.eventTypes,
        volume: state.notification.volume,
      ),
    );
  }

  void updateNotificationSoundEnabled(bool v) {
    state = state.copyWith(
      notification: NotificationPref(
        enabled: state.notification.enabled,
        soundEnabled: v,
        eventTypes: state.notification.eventTypes,
        volume: state.notification.volume,
      ),
    );
  }

  void updateNotificationVolume(double v) {
    state = state.copyWith(
      notification: NotificationPref(
        enabled: state.notification.enabled,
        soundEnabled: state.notification.soundEnabled,
        eventTypes: state.notification.eventTypes,
        volume: v.clamp(0.0, 1.0),
      ),
    );
  }

  void updateDefaultTableView(String v) {
    state = state.copyWith(
      defaultView: DefaultViewPref(
        tableView: v,
        playersView: state.defaultView.playersView,
        expandedSeries: state.defaultView.expandedSeries,
      ),
    );
  }

  void updateDefaultPlayersView(String v) {
    state = state.copyWith(
      defaultView: DefaultViewPref(
        tableView: state.defaultView.tableView,
        playersView: v,
        expandedSeries: state.defaultView.expandedSeries,
      ),
    );
  }

  void updateAutoLogoutEnabled(bool v) {
    state = state.copyWith(
      autoLogout: AutoLogoutPref(
        enabled: v,
        idleMinutes: state.autoLogout.idleMinutes,
        warnBeforeSeconds: state.autoLogout.warnBeforeSeconds,
      ),
    );
  }

  void updateAutoLogoutIdleMinutes(int v) {
    state = state.copyWith(
      autoLogout: AutoLogoutPref(
        enabled: state.autoLogout.enabled,
        idleMinutes: v,
        warnBeforeSeconds: state.autoLogout.warnBeforeSeconds,
      ),
    );
  }

  void updateExportFormat(String v) {
    state = state.copyWith(
      exportDefaults: ExportDefaults(
        format: v,
        includeHeaders: state.exportDefaults.includeHeaders,
        timezoneMode: state.exportDefaults.timezoneMode,
        filenamePattern: state.exportDefaults.filenamePattern,
      ),
    );
  }

  void updateExportIncludeHeaders(bool v) {
    state = state.copyWith(
      exportDefaults: ExportDefaults(
        format: state.exportDefaults.format,
        includeHeaders: v,
        timezoneMode: state.exportDefaults.timezoneMode,
        filenamePattern: state.exportDefaults.filenamePattern,
      ),
    );
  }
}

final preferencesProvider =
    StateNotifierProvider<PreferencesController, UserPreferences>((ref) {
  return PreferencesController();
});
