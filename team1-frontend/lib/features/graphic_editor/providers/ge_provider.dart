// Graphic Editor providers — ported from geStore.ts (CCR-011, UI-04).
//
// Skin list + selection, metadata draft, upload progress, preview, activation.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../models/models.dart';
import '../../../repositories/skin_repository.dart';

part 'ge_provider.freezed.dart';

// ---------------------------------------------------------------------------
// Skin list
// ---------------------------------------------------------------------------

class SkinListNotifier extends StateNotifier<AsyncValue<List<Skin>>> {
  SkinListNotifier(this._repo) : super(const AsyncValue.loading());

  final SkinRepository _repo;

  Future<void> fetch() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repo.listSkins();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void applyRemoteUpdate(Skin updated) {
    state.whenData((list) {
      state = AsyncValue.data([
        for (final s in list)
          if (s.skinId == updated.skinId) updated else s,
      ]);
    });
  }

  void applyRemoteAdd(Skin added) {
    state.whenData((list) {
      state = AsyncValue.data([...list, added]);
    });
  }

  void applyRemoteDelete(int skinId) {
    state.whenData((list) {
      state = AsyncValue.data(
        list.where((s) => s.skinId != skinId).toList(),
      );
    });
  }

  /// Mark a skin as active, deactivating the previous active skin.
  void setActive(int skinId) {
    state.whenData((list) {
      state = AsyncValue.data([
        for (final s in list)
          if (s.skinId == skinId)
            s.copyWith(status: 'active')
          else if (s.status == 'active')
            s.copyWith(status: 'validated')
          else
            s,
      ]);
    });
  }
}

final skinListProvider =
    StateNotifierProvider<SkinListNotifier, AsyncValue<List<Skin>>>(
  (ref) => SkinListNotifier(ref.read(skinRepositoryProvider)),
);

// ---------------------------------------------------------------------------
// Selection + activation
// ---------------------------------------------------------------------------

final selectedSkinIdProvider = StateProvider<int?>((ref) => null);
final activeSkinIdProvider = StateProvider<int?>((ref) => null);

/// Derived: the currently selected Skin object.
final selectedSkinProvider = Provider<Skin?>((ref) {
  final id = ref.watch(selectedSkinIdProvider);
  if (id == null) return null;
  return ref.watch(skinListProvider).whenOrNull(
    data: (list) {
      for (final s in list) {
        if (s.skinId == id) return s;
      }
      return null;
    },
  );
});

// ---------------------------------------------------------------------------
// Metadata draft
// ---------------------------------------------------------------------------

final metadataDraftProvider = StateProvider<SkinMetadata?>((ref) => null);
final metadataDirtyProvider = StateProvider<bool>((ref) => false);

// ---------------------------------------------------------------------------
// Upload state (Freezed)
// ---------------------------------------------------------------------------

enum SkinUploadStatus { idle, selecting, uploading, validating, ready, error }

@freezed
class SkinUploadState with _$SkinUploadState {
  const factory SkinUploadState({
    @Default(SkinUploadStatus.idle) SkinUploadStatus status,
    @Default(0) double progress,
    @Default([]) List<String> validationErrors,
    String? error,
  }) = _SkinUploadState;
}

class SkinUploadNotifier extends StateNotifier<SkinUploadState> {
  SkinUploadNotifier() : super(const SkinUploadState());

  void startUpload() {
    state = const SkinUploadState(status: SkinUploadStatus.uploading);
  }

  void updateProgress(double pct) {
    state = state.copyWith(progress: pct);
  }

  void setValidating() {
    state = state.copyWith(status: SkinUploadStatus.validating);
  }

  void setReady() {
    state = state.copyWith(status: SkinUploadStatus.ready, progress: 100);
  }

  void setError(String message, {List<String> validationErrors = const []}) {
    state = SkinUploadState(
      status: SkinUploadStatus.error,
      error: message,
      validationErrors: validationErrors,
    );
  }

  void reset() {
    state = const SkinUploadState();
  }
}

final skinUploadProvider =
    StateNotifierProvider<SkinUploadNotifier, SkinUploadState>(
  (ref) => SkinUploadNotifier(),
);

// ---------------------------------------------------------------------------
// Preview state
// ---------------------------------------------------------------------------

final previewUrlProvider = StateProvider<String?>((ref) => null);
final previewPausedProvider = StateProvider<bool>((ref) => false);

// ---------------------------------------------------------------------------
// Activation pending
// ---------------------------------------------------------------------------

final activationPendingProvider = StateProvider<bool>((ref) => false);
