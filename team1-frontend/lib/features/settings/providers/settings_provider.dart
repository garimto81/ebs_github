// Settings provider — ported from settingsStore.ts.
//
// Family provider keyed by SettingsSection. Each section tracks committed
// (server-confirmed) vs draft (local edits) with dirty detection.
//
// Per feedback_settings_global.md + WSOP LIVE alignment: Settings has
// Series/Event/Table scope separation. The scope is determined by the
// caller context, not by this provider.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../repositories/settings_repository.dart';

part 'settings_provider.freezed.dart';

// ---------------------------------------------------------------------------
// Section enum
// ---------------------------------------------------------------------------

enum SettingsSection {
  blindStructure,
  prizeStructure,
  outputs,
  gfx,
  display,
  rules,
  stats,
  preferences,
}

// ---------------------------------------------------------------------------
// Section state (Freezed)
// ---------------------------------------------------------------------------

@freezed
class SettingsSectionState with _$SettingsSectionState {
  const factory SettingsSectionState({
    required SettingsSection section,
    @Default({}) Map<String, dynamic> committed,
    @Default({}) Map<String, dynamic> draft,
    @Default(false) bool isDirty,
    @Default(false) bool isSaving,
    @Default(false) bool isLoading,
    String? error,
  }) = _SettingsSectionState;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class SettingsSectionNotifier extends StateNotifier<SettingsSectionState> {
  SettingsSectionNotifier({
    required SettingsSection section,
    required SettingsRepository repo,
  })  : _repo = repo,
        super(SettingsSectionState(section: section));

  final SettingsRepository _repo;

  /// Fetch section config from the backend.
  Future<void> fetch() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repo.getConfig(state.section.name);
      state = state.copyWith(
        committed: data,
        draft: Map<String, dynamic>.from(data),
        isDirty: false,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Update a single field in the draft. Recalculates dirty flag.
  void updateField(String key, dynamic value) {
    final newDraft = Map<String, dynamic>.from(state.draft)..[key] = value;
    state = state.copyWith(
      draft: newDraft,
      isDirty: !mapEquals(newDraft, state.committed),
    );
  }

  /// Save the draft to the backend. On success, committed = draft.
  Future<void> save() async {
    if (!state.isDirty) return;
    state = state.copyWith(isSaving: true, error: null);
    try {
      final updated = await _repo.updateConfig(
        state.section.name,
        state.draft,
      );
      state = state.copyWith(
        committed: updated,
        draft: Map<String, dynamic>.from(updated),
        isDirty: false,
        isSaving: false,
      );
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: e.toString(),
      );
    }
  }

  /// Revert draft to last committed state.
  void revert() {
    state = state.copyWith(
      draft: Map<String, dynamic>.from(state.committed),
      isDirty: false,
    );
  }

  /// Apply a remote config change (another operator saved).
  /// Only overwrites draft if the section is not dirty (avoid trampling edits).
  void applyRemoteChange(String key, dynamic value) {
    final newCommitted = Map<String, dynamic>.from(state.committed)
      ..[key] = value;
    if (!state.isDirty) {
      final newDraft = Map<String, dynamic>.from(state.draft)..[key] = value;
      state = state.copyWith(committed: newCommitted, draft: newDraft);
    } else {
      state = state.copyWith(committed: newCommitted);
    }
  }

  /// Bulk replace committed + draft (e.g. after a full fetch).
  void replaceAll(Map<String, dynamic> data) {
    state = state.copyWith(
      committed: Map<String, dynamic>.from(data),
      draft: Map<String, dynamic>.from(data),
      isDirty: false,
      isLoading: false,
    );
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final settingsSectionProvider = StateNotifierProvider.family<
    SettingsSectionNotifier, SettingsSectionState, SettingsSection>(
  (ref, section) => SettingsSectionNotifier(
    section: section,
    repo: ref.read(settingsRepositoryProvider),
  ),
);

/// True if any section has unsaved changes.
final isAnySettingsDirtyProvider = Provider<bool>((ref) {
  return SettingsSection.values.any(
    (s) => ref.watch(settingsSectionProvider(s)).isDirty,
  );
});
