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
}

final preferencesProvider =
    StateNotifierProvider<PreferencesController, UserPreferences>((ref) {
  return PreferencesController();
});
