// WebSocket event dispatch — ported from lobbyStore.ts applyRemoteChange()
// + settingsStore.ts + geStore.ts remote handlers.
//
// Central router that maps incoming WS event names to provider mutations.
// Follows team4's _dispatchIncomingEvent() pattern from ws_provider.dart.
//
// Wire this into the WS client's onEvent callback.
//
// **WSOP LIVE 규약 준수 (2026-04-21 B-088 PR-6)**:
// - event type = **PascalCase** (Naming_Conventions.md §3.1)
// - dot.case 금지 (`series.updated` ❌ → `SeriesUpdated` ✅)
// - 중복 case 제거 (`config_changed` ↔ `config.updated` → `ConfigChanged` 단일)
// - payload 필드 = **camelCase** (PR-5 Freezed 전환 반영, eventFlightId/tableId 등)
//
// Backend publisher (team2) 매핑 상태:
// - ✅ PascalCase emit: Ack, Error, AuthFailed, TableNotFound, PermissionDenied,
//                      InvalidMessage, CardConflict, DuplicateCard, RfidHardwareError,
//                      SlowConnection, TableAssigned, TokenExpiringSoon, PlayerUpdated,
//                      BlindStructureChanged (v2)
// - ⏳ snake → PascalCase (team2 PR-3 진행 중): clock_tick, clock_level_changed,
//   clock_detail_changed, clock_reload_requested, tournament_status_changed,
//   prize_pool_changed, stack_adjusted, skin_updated, event_flight_summary
//
// 본 파일은 **PascalCase 기준** 으로 case 를 선언. team2 PR-3 완료 전에는 snake emit
// 이벤트가 default 에 빠져 debugPrint 로 log-and-ignore. team2 완료 시 전부 정상 처리.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/graphic_editor/providers/ge_provider.dart';
import '../../features/lobby/providers/cc_session_provider.dart';
import '../../features/lobby/providers/event_provider.dart';
import '../../features/lobby/providers/flight_provider.dart';
import '../../features/lobby/providers/nav_provider.dart';
import '../../features/lobby/providers/player_provider.dart';
import '../../features/lobby/providers/series_provider.dart';
import '../../features/lobby/providers/table_provider.dart';
import '../../features/settings/providers/settings_provider.dart';
import '../../models/models.dart';

// ---------------------------------------------------------------------------
// Reader abstraction (same pattern as team4 ws_provider.dart)
// ---------------------------------------------------------------------------

/// Read closure so the dispatcher works with both WidgetRef and
/// ProviderContainer (unit tests).
typedef ProviderReadFn = T Function<T>(ProviderListenable<T> provider);

// ---------------------------------------------------------------------------
// WS envelope
// ---------------------------------------------------------------------------

/// Minimal envelope for incoming WebSocket events.
/// The backend sends `{ "type": "...", "payload": {...}, "seq": N }`.
class WsDispatchEnvelope {
  const WsDispatchEnvelope({
    required this.event,
    this.payload,
    this.seq,
  });

  /// Event type (PascalCase per WSOP LIVE SignalR convention).
  ///
  /// Accepts both `type` (primary per Naming_Conventions.md v2) and `event`
  /// (legacy envelope field) for backward compatibility during PR-3 migration.
  final String event;
  final Map<String, dynamic>? payload;
  final int? seq;

  factory WsDispatchEnvelope.fromJson(Map<String, dynamic> json) {
    return WsDispatchEnvelope(
      event: (json['type'] ?? json['event']) as String? ?? '',
      payload: json['payload'] as Map<String, dynamic>?,
      seq: json['seq'] as int?,
    );
  }
}

// ---------------------------------------------------------------------------
// Dispatch
// ---------------------------------------------------------------------------

/// Route an incoming WS event to the appropriate provider mutation.
///
/// Called from the WS client's onEvent callback. The [read] function is
/// either `ref.read` (production) or `container.read` (tests).
void dispatchWsEvent(ProviderReadFn read, WsDispatchEnvelope envelope) {
  final payload = envelope.payload;
  if (payload == null && _requiresPayload(envelope.event)) {
    debugPrint('[WS] Event ${envelope.event} missing payload — ignored');
    return;
  }

  switch (envelope.event) {
    // ------------------------------------------------------------------
    // Entity full-replacement updates
    // ------------------------------------------------------------------
    case 'SeriesUpdated':
      if (payload == null) return;
      final s = Series.fromJson(payload);
      read(seriesListProvider.notifier).applyRemoteUpdate(s);

    case 'SeriesCreated':
      if (payload == null) return;
      final s = Series.fromJson(payload);
      read(seriesListProvider.notifier).applyRemoteAdd(s);

    case 'SeriesDeleted':
      if (payload == null) return;
      final id = payload['seriesId'] as int?;
      if (id != null) read(seriesListProvider.notifier).applyRemoteDelete(id);

    case 'EventUpdated':
      if (payload == null) return;
      final e = EbsEvent.fromJson(payload);
      final seriesId = read(currentSeriesIdProvider);
      if (seriesId != null) {
        read(eventListProvider(seriesId).notifier).applyRemoteUpdate(e);
      }

    case 'EventCreated':
      if (payload == null) return;
      final e = EbsEvent.fromJson(payload);
      final seriesId = read(currentSeriesIdProvider);
      if (seriesId != null && e.seriesId == seriesId) {
        read(eventListProvider(seriesId).notifier).applyRemoteAdd(e);
      }

    case 'FlightUpdated':
      if (payload == null) return;
      final f = EventFlight.fromJson(payload);
      final eventId = read(currentEventIdProvider);
      if (eventId != null) {
        read(flightListProvider(eventId).notifier).applyRemoteUpdate(f);
      }

    case 'FlightCreated':
      if (payload == null) return;
      final f = EventFlight.fromJson(payload);
      final eventId = read(currentEventIdProvider);
      if (eventId != null && f.eventId == eventId) {
        read(flightListProvider(eventId).notifier).applyRemoteAdd(f);
      }

    case 'TableUpdated':
      if (payload == null) return;
      final t = EbsTable.fromJson(payload);
      final flightId = read(currentFlightIdProvider);
      if (flightId != null) {
        read(tableListProvider(flightId).notifier).applyRemoteUpdate(t);
      }

    case 'TableCreated':
      if (payload == null) return;
      final t = EbsTable.fromJson(payload);
      final flightId = read(currentFlightIdProvider);
      if (flightId != null && t.eventFlightId == flightId) {
        read(tableListProvider(flightId).notifier).applyRemoteAdd(t);
      }

    case 'PlayerUpdated':
      if (payload == null) return;
      final p = Player.fromJson(payload);
      read(playerListProvider.notifier).applyRemoteUpdate(p);

    case 'PlayerCreated':
      if (payload == null) return;
      final p = Player.fromJson(payload);
      read(playerListProvider.notifier).applyRemoteAdd(p);

    // ------------------------------------------------------------------
    // Real-time operational events
    // ------------------------------------------------------------------
    case 'TableStatusChanged':
      if (payload == null) return;
      final tableId = payload['tableId'] as int?;
      final status = payload['status'] as String?;
      final flightId = read(currentFlightIdProvider);
      if (tableId != null && status != null && flightId != null) {
        read(tableListProvider(flightId).notifier)
            .updateStatus(tableId, status);
      }

    case 'PlayerMoved':
    case 'PlayerSeated':
      if (payload == null) return;
      final tableId = payload['tableId'] as int?;
      final playerId = payload['playerId'] as int?;
      final seatNo = payload['seatNo'] as int?;
      final action = payload['action'] as String?;
      final flightId = read(currentFlightIdProvider);
      if (tableId != null && flightId != null) {
        final isRemoval = action == 'removed' || action == 'busted';
        read(tableListProvider(flightId).notifier)
            .updateSeatedCount(tableId, increment: !isRemoval);
      }
      if (playerId != null) {
        read(playerListProvider.notifier)
            .updateSeat(playerId, seatIndex: seatNo);
      }

    case 'HandStarted':
      if (payload == null) return;
      final tableId = payload['tableId'] as int?;
      final handNumber = payload['handNumber'] as int?;
      final flightId = read(currentFlightIdProvider);
      if (tableId != null && flightId != null) {
        read(tableListProvider(flightId).notifier)
            .updateCurrentGame(tableId, handNumber);
      }

    case 'HandEnded':
      if (payload == null) return;
      final tableId = payload['tableId'] as int?;
      final flightId = read(currentFlightIdProvider);
      if (tableId != null && flightId != null) {
        read(tableListProvider(flightId).notifier)
            .updateCurrentGame(tableId, null);
      }

    // ------------------------------------------------------------------
    // Rebalance saga events
    // ------------------------------------------------------------------
    case 'RebalanceStarted':
    case 'RebalanceProgress':
    case 'RebalanceCompensated':
    case 'RebalanceCompensationFailed':
      // Page-level handlers will subscribe to these via a dedicated provider.
      debugPrint('[WS] Rebalance saga: ${envelope.event}');

    case 'RebalanceCompleted':
      if (payload != null) {
        final refFlightId = payload['flightId'] as int?;
        if (refFlightId != null) {
          read(tableListProvider(refFlightId).notifier).fetch();
        }
      }

    // ------------------------------------------------------------------
    // Settings (unified from legacy config.updated + config_changed)
    // ------------------------------------------------------------------
    case 'ConfigChanged':
      if (payload == null) return;
      final sectionName = payload['section'] as String?;
      final key = payload['key'] as String?;
      final value = payload['value'];
      if (sectionName == null || key == null) return;
      final section = _parseSettingsSection(sectionName);
      if (section != null) {
        read(settingsSectionProvider(section).notifier)
            .applyRemoteChange(key, value);
      }

    // ------------------------------------------------------------------
    // Skins / Graphic Editor (unified from skin.updated + skin_updated)
    // ------------------------------------------------------------------
    case 'SkinUpdated':
    case 'SkinActivated':
      if (payload == null) return;
      final skin = Skin.fromJson(payload);
      read(skinListProvider.notifier).applyRemoteUpdate(skin);
      if (skin.status == 'active') {
        read(activeSkinIdProvider.notifier).state = skin.skinId;
      }

    // ------------------------------------------------------------------
    // Tournament clock events (team2 publishers.py + lobby_handler.py)
    // ------------------------------------------------------------------
    case 'ClockTick':
    case 'ClockLevelChanged':
    case 'ClockDetailChanged':
    case 'ClockReloadRequested':
      // Clock state updates are consumed by a dedicated clock provider
      // (future: lib/features/lobby/providers/clock_provider.dart).
      // For now log-and-track so that E2E tests can assert receipt.
      debugPrint('[WS] Clock event: ${envelope.event}');

    // ------------------------------------------------------------------
    // Tournament meta events
    // ------------------------------------------------------------------
    case 'TournamentStatusChanged':
      // Tournament state changes (running/completed/canceled). Refresh
      // the active flight to pick up new status + remaining metadata.
      final eventId = read(currentEventIdProvider);
      if (eventId != null) {
        read(flightListProvider(eventId).notifier).fetch();
      }

    case 'BlindStructureChanged':
      // Settings-scoped event. Refresh settings section if currently
      // displayed; the dedicated blind_structure_provider also listens.
      debugPrint('[WS] BlindStructureChanged — settings refresh deferred');

    case 'PrizePoolChanged':
      // Lobby display of prize pool is computed from event.totalEntries.
      // Refresh events to pull latest snapshot.
      final seriesId = read(currentSeriesIdProvider);
      if (seriesId != null) {
        read(eventListProvider(seriesId).notifier).fetch();
      }

    case 'StackAdjusted':
      // Per-player stack change. PlayerMoved/PlayerUpdated covers most
      // UI needs. Dedicated stack provider is future work.
      debugPrint('[WS] StackAdjusted — player refresh deferred');

    case 'EventFlightSummary':
      // Aggregate summary snapshot (broadcast periodically by backend).
      // Refresh events+flights for the currently selected series/event.
      final seriesId = read(currentSeriesIdProvider);
      if (seriesId != null) {
        read(eventListProvider(seriesId).notifier).fetch();
      }

    // ------------------------------------------------------------------
    // Reply / error envelopes (command responses)
    // ------------------------------------------------------------------
    case 'Ack':
    case 'Error':
    case 'AuthFailed':
    case 'TableNotFound':
    case 'PermissionDenied':
    case 'InvalidMessage':
    case 'TokenExpiringSoon':
      // Lobby does not send commands (read-only subscriber), but these
      // may be received during the initial handshake. Log-and-ignore.
      debugPrint('[WS] Reply envelope: ${envelope.event}');

    // ------------------------------------------------------------------
    // Phase 3.C (2026-05-06) — TopBar Active CC pill live update
    // ------------------------------------------------------------------
    case 'cc_session_count':
      if (payload == null) return;
      final count = payload['count'];
      if (count is int) {
        read(activeCcCountProvider.notifier).state = count;
      } else if (count is num) {
        read(activeCcCountProvider.notifier).state = count.toInt();
      }

    // ------------------------------------------------------------------
    // Unknown — forward-compatible, log + ignore (Naming_Conventions §3 policy)
    // ------------------------------------------------------------------
    default:
      debugPrint('[WS] Unknown event (ignored): ${envelope.event}');
  }
}

// ---------------------------------------------------------------------------
// Test-friendly entry point (uses ProviderContainer)
// ---------------------------------------------------------------------------

/// Dispatch a raw JSON event using a [ProviderContainer] (unit tests).
void dispatchWsEventForTest(
  ProviderContainer container,
  Map<String, dynamic> rawEvent,
) {
  final envelope = WsDispatchEnvelope.fromJson(rawEvent);
  dispatchWsEvent(<T>(p) => container.read(p), envelope);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

bool _requiresPayload(String event) {
  // Saga + simple state events may have empty payloads.
  if (event.startsWith('Rebalance')) return false;
  // Clock + reply envelopes may be minimal.
  const payloadOptional = <String>{
    'ClockTick',
    'ClockLevelChanged',
    'ClockDetailChanged',
    'ClockReloadRequested',
    'TournamentStatusChanged',
    'BlindStructureChanged',
    'StackAdjusted',
    'Ack',
    'Error',
    'AuthFailed',
    'TableNotFound',
    'PermissionDenied',
    'InvalidMessage',
    'TokenExpiringSoon',
  };
  if (payloadOptional.contains(event)) return false;
  return true;
}

SettingsSection? _parseSettingsSection(String name) {
  for (final s in SettingsSection.values) {
    if (s.name == name) return s;
  }
  return null;
}
