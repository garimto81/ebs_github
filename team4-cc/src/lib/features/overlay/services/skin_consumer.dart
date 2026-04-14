// SkinConsumer — receives `skin_updated` WebSocket events (CCR-015) and
// reloads the Overlay Rive canvas. Replaces team4's earlier bs08 proposal
// after CCR-011 moved Graphic Editor ownership to team1.
//
// Flow:
//   1. WebSocket dispatch → reload(skinId)
//   2. BO GET /skins/{id}/bundle → .gfskin ZIP bytes
//   3. SkinRepository.loadFromBytes() → manifest + skin.riv (CCR-012)
//   4. JSON Schema validate manifest against DATA-07
//   5. Load Rive bytes into Overlay root
//   6. On failure: rollback (keep previous skin) + Sentry report
//
// Hot-swap: applies new skin without app restart (BS-07-03 §5 FSM).

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../data/remote/bo_api_client.dart';
import '../../../repositories/skin_repository.dart';

final _log = Logger('SkinConsumer');

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

enum SkinConsumerStatus { idle, loading, active, error }

class SkinConsumerState {
  const SkinConsumerState({
    this.status = SkinConsumerStatus.idle,
    this.activeSkinId,
    this.bundle,
    this.errorMessage,
  });

  final SkinConsumerStatus status;
  final String? activeSkinId;
  final SkinBundle? bundle;
  final String? errorMessage;

  SkinConsumerState copyWith({
    SkinConsumerStatus? status,
    String? activeSkinId,
    SkinBundle? bundle,
    String? errorMessage,
  }) =>
      SkinConsumerState(
        status: status ?? this.status,
        activeSkinId: activeSkinId ?? this.activeSkinId,
        bundle: bundle ?? this.bundle,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class SkinConsumerNotifier extends StateNotifier<SkinConsumerState> {
  SkinConsumerNotifier({
    required SkinRepository skinRepository,
    required BoApiClient boApiClient,
  })  : _skinRepository = skinRepository,
        _boApiClient = boApiClient,
        super(const SkinConsumerState());

  final SkinRepository _skinRepository;
  final BoApiClient _boApiClient;

  /// Reload skin from BO after a `skin_updated` WebSocket event.
  ///
  /// On failure, rolls back to the previous active skin (if any).
  Future<void> reload(String skinId) async {
    final previousBundle = state.bundle;
    final previousSkinId = state.activeSkinId;

    state = state.copyWith(
      status: SkinConsumerStatus.loading,
      errorMessage: null,
    );

    try {
      // Fetch .gfskin ZIP from BO
      final skinUrl = '${_boApiClient.raw.options.baseUrl}/skins/$skinId/bundle';
      final bundle = await _skinRepository.loadFromUrl(skinUrl);

      state = SkinConsumerState(
        status: SkinConsumerStatus.active,
        activeSkinId: skinId,
        bundle: bundle,
      );

      _log.info('Skin loaded successfully: $skinId');
    } catch (e) {
      _log.severe('Skin reload failed for $skinId: $e');

      // Rollback to previous skin
      state = SkinConsumerState(
        status: previousBundle != null
            ? SkinConsumerStatus.active
            : SkinConsumerStatus.error,
        activeSkinId: previousSkinId,
        bundle: previousBundle,
        errorMessage: 'Skin reload failed: $e',
      );
    }
  }

  /// Handle raw WebSocket `skin_updated` payload.
  ///
  /// Expected payload: `{ "type": "skin_updated", "skin_id": "..." }`
  void handleSkinUpdatedEvent(Map<String, dynamic> payload) {
    final skinId = payload['skin_id'] as String?;
    if (skinId == null || skinId.isEmpty) {
      _log.warning('skin_updated event missing skin_id');
      return;
    }
    reload(skinId);
  }

  /// Reset (logout / table close).
  void reset() {
    _skinRepository.reset();
    state = const SkinConsumerState();
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final skinRepositoryProvider = Provider<SkinRepository>((ref) {
  return SkinRepository();
});

final skinConsumerProvider =
    StateNotifierProvider<SkinConsumerNotifier, SkinConsumerState>((ref) {
  return SkinConsumerNotifier(
    skinRepository: ref.watch(skinRepositoryProvider),
    boApiClient: ref.watch(boApiClientProvider),
  );
});
