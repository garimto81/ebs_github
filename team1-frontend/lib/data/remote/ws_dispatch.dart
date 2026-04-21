// WebSocket event dispatch — ported from lobbyStore.ts applyRemoteChange()
// + settingsStore.ts + geStore.ts remote handlers.
//
// Central router that maps incoming WS event names to provider mutations.
// Follows team4's _dispatchIncomingEvent() pattern from ws_provider.dart.
//
// Wire this into the WS client's onEvent callback.
//
// TODO(B-088 PR-6): WSOP LIVE 직접 준수 — event type PascalCase 통일.
// 현재 switch case 는 snake_case (hand_started) + dot.case (series.updated) 혼재.
// team2 publisher (PR-3) 에서 PascalCase 로 migrate 완료 후 본 파일도 일괄 전환:
//   'hand_started' → 'HandStarted'
//   'table_status_changed' → 'TableStatusChanged'
//   'series.updated' → 'SeriesUpdated'  (도트 계층 제거)
//   'skin.updated' + 'skin_updated' 중복 → 'SkinUpdated' 단일
// 상세: docs/2. Development/2.5 Shared/Naming_Conventions.md §3 + B-088 PR-3/6

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/graphic_editor/providers/ge_provider.dart';
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
/// The backend sends `{ "event": "...", "payload": {...}, "seq": N }`.
class WsDispatchEnvelope {
  const WsDispatchEnvelope({
    required this.event,
    this.payload,
    this.seq,
  });

  factory WsDispatchEnvelope.fromJson(Map<String, dynamic> json) {
    return WsDispatchEnvelope(
      event: json['event'] as String? ?? '',
      payload: json['payload'] as Map<String, dynamic>?,
      seq: json['seq'] as int?,
    );
  }

  final String event;
  final Map<String, dynamic>? payload;
  final int? seq;
}

// ---------------------------------------------------------------------------
// Main dispatcher
// ---------------------------------------------------------------------------

/// Route an incoming WS event to the appropriate providers.
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
    // Entity full-replacement updates (lobbyStore.ts §WS remote updates)
    // ------------------------------------------------------------------
    case 'series.updated':
      if (payload == null) return;
      final s = Series.fromJson(payload);
      read(seriesListProvider.notifier).applyRemoteUpdate(s);

    case 'series.created':
      if (payload == null) return;
      final s = Series.fromJson(payload);
      read(seriesListProvider.notifier).applyRemoteAdd(s);

    case 'series.deleted':
      if (payload == null) return;
      final id = payload['series_id'] as int?;
      if (id != null) read(seriesListProvider.notifier).applyRemoteDelete(id);

    case 'event.updated':
      if (payload == null) return;
      final e = EbsEvent.fromJson(payload);
      final seriesId = read(currentSeriesIdProvider);
      if (seriesId != null) {
        read(eventListProvider(seriesId).notifier).applyRemoteUpdate(e);
      }

    case 'event.created':
      if (payload == null) return;
      final e = EbsEvent.fromJson(payload);
      final seriesId = read(currentSeriesIdProvider);
      if (seriesId != null && e.seriesId == seriesId) {
        read(eventListProvider(seriesId).notifier).applyRemoteAdd(e);
      }

    case 'flight.updated':
      if (payload == null) return;
      final f = EventFlight.fromJson(payload);
      final eventId = read(currentEventIdProvider);
      if (eventId != null) {
        read(flightListProvider(eventId).notifier).applyRemoteUpdate(f);
      }

    case 'flight.created':
      if (payload == null) return;
      final f = EventFlight.fromJson(payload);
      final eventId = read(currentEventIdProvider);
      if (eventId != null && f.eventId == eventId) {
        read(flightListProvider(eventId).notifier).applyRemoteAdd(f);
      }

    case 'table.updated':
      if (payload == null) return;
      final t = EbsTable.fromJson(payload);
      final flightId = read(currentFlightIdProvider);
      if (flightId != null) {
        read(tableListProvider(flightId).notifier).applyRemoteUpdate(t);
      }

    case 'table.created':
      if (payload == null) return;
      final t = EbsTable.fromJson(payload);
      final flightId = read(currentFlightIdProvider);
      if (flightId != null && t.eventFlightId == flightId) {
        read(tableListProvider(flightId).notifier).applyRemoteAdd(t);
      }

    case 'player.updated':
      if (payload == null) return;
      final p = Player.fromJson(payload);
      read(playerListProvider.notifier).applyRemoteUpdate(p);

    case 'player.created':
      if (payload == null) return;
      final p = Player.fromJson(payload);
      read(playerListProvider.notifier).applyRemoteAdd(p);

    // ------------------------------------------------------------------
    // Real-time operational events (lobbyStore.ts §operational)
    // ------------------------------------------------------------------
    case 'table_status_changed':
      if (payload == null) return;
      final tableId = payload['table_id'] as int?;
      final status = payload['status'] as String?;
      final flightId = read(currentFlightIdProvider);
      if (tableId != null && status != null && flightId != null) {
        read(tableListProvider(flightId).notifier)
            .updateStatus(tableId, status);
      }

    case 'player_moved':
    case 'player_seated':
      if (payload == null) return;
      final tableId = payload['table_id'] as int?;
      final playerId = payload['player_id'] as int?;
      final seatNo = payload['seat_no'] as int?;
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

    case 'hand_started':
      if (payload == null) return;
      final tableId = payload['table_id'] as int?;
      final handNumber = payload['hand_number'] as int?;
      final flightId = read(currentFlightIdProvider);
      if (tableId != null && flightId != null) {
        read(tableListProvider(flightId).notifier)
            .updateCurrentGame(tableId, handNumber);
      }

    case 'hand_ended':
      if (payload == null) return;
      final tableId = payload['table_id'] as int?;
      final flightId = read(currentFlightIdProvider);
      if (tableId != null && flightId != null) {
        read(tableListProvider(flightId).notifier)
            .updateCurrentGame(tableId, null);
      }

    // ------------------------------------------------------------------
    // Rebalance saga events (page-level listeners handle UI; we refresh)
    // ------------------------------------------------------------------
    case 'rebalance_started':
    case 'rebalance_progress':
    case 'rebalance_compensated':
    case 'rebalance_compensation_failed':
      // Page-level handlers will subscribe to these via a dedicated provider.
      debugPrint('[WS] Rebalance saga: ${envelope.event}');

    case 'rebalance_completed':
      if (payload != null) {
        final refFlightId = payload['flight_id'] as int?;
        if (refFlightId != null) {
          read(tableListProvider(refFlightId).notifier).fetch();
        }
      }

    // ------------------------------------------------------------------
    // Settings (settingsStore.ts)
    // ------------------------------------------------------------------
    case 'config.updated':
    case 'config_changed':
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
    // Skins / Graphic Editor (geStore.ts)
    // ------------------------------------------------------------------
    case 'skin.updated':
    case 'skin.activated':
    case 'skin_updated':
      if (payload == null) return;
      final skin = Skin.fromJson(payload);
      read(skinListProvider.notifier).applyRemoteUpdate(skin);
      if (skin.status == 'active') {
        read(activeSkinIdProvider.notifier).state = skin.skinId;
      }

    // ------------------------------------------------------------------
    // Unknown — forward-compatible, log + ignore
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
  // Saga events may have empty payloads for progress-only notifications.
  return !event.startsWith('rebalance_');
}

SettingsSection? _parseSettingsSection(String name) {
  for (final s in SettingsSection.values) {
    if (s.name == name) return s;
  }
  return null;
}
