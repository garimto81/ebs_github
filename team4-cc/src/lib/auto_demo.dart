// Auto Demo Hook — 1 hand 자동 시연 (Cycle 2 Issue #237).
//
// CC를 Lobby 없이 standalone으로 띄울 때, AUTO_DEMO=true 플래그가 설정되면
// 다음 e2e 흐름을 자동 수행한다:
//
//   1. ADMIN_TOKEN (dart-define) 사용해 BO REST 호출:
//      POST /api/v1/tables/{TABLE_ID}/launch-cc
//   2. 응답에서 launch_token / cc_instance_id / ws_url 추출.
//   3. WebSocket 연결 (BoWebSocketClient).
//   4. WriteGameInfo (24 필드, API-05 §9 / CCR-024) 메시지 1회 전송.
//   5. GameInfoAck 수신 시 onReady 콜백 호출.
//
// 검증 시나리오 정합:
//   - integration-tests/scenarios/30-cc-launch-flow.http (BO launch-cc 검증)
//   - integration-tests/scenarios/32-cc-write-game-info.http (WriteGameInfo 24필드)
//
// 후속: cascade:cc-hand-ready broker publish는 호출자(main.dart)가 onReady에서 수행.

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/remote/bo_api_client.dart';
import 'data/remote/bo_websocket_client.dart';
import 'foundation/logging/debug_log.dart';
import 'foundation/utils/uuid_idempotency.dart';

/// AUTO_DEMO=true 일 때 main.dart에서 호출되는 entry.
///
/// [adminToken]은 cascade:auth-seeded 후 S7가 시드한 admin 사용자 JWT.
/// [tableId]는 launch 대상. 미지정 시 1.
/// [boBaseUrl]은 BO REST base. 기본 http://localhost:8000.
/// [onReady]는 GameInfoAck 수신 시 호출되는 콜백 (broker publish 책임은 호출자).
/// [onError]는 어느 단계에서든 실패 시 호출되는 콜백.
Future<AutoDemoResult> runAutoDemo({
  required String adminToken,
  int tableId = 1,
  String boBaseUrl = 'http://localhost:8000',
  Duration ackTimeout = const Duration(seconds: 10),
  void Function(int handId)? onReady,
  void Function(Object error, StackTrace stack)? onError,
}) async {
  DebugLog.i('AUTO_DEMO', 'starting 1-hand wire', {
    'tableId': tableId,
    'boBaseUrl': boBaseUrl,
  });

  // Step 1: BO REST — launch-cc (30-cc-launch-flow.http §30.1).
  final api = BoApiClient(baseUrl: boBaseUrl, token: adminToken);
  Map<String, dynamic> launchResponse;
  try {
    launchResponse = await api.launchTable(tableId);
  } on DioException catch (e, st) {
    DebugLog.e('AUTO_DEMO', 'launch-cc failed', {
      'status': e.response?.statusCode,
      'data': e.response?.data,
    });
    onError?.call(e, st);
    return AutoDemoResult.failure(stage: 'launch-cc', error: e);
  }

  // launchResponse envelope: {"data": {...}, "error": null}
  final data = launchResponse['data'] as Map<String, dynamic>? ?? launchResponse;
  final launchToken = data['launch_token'] as String?;
  final ccInstanceId = data['cc_instance_id'] as String?;
  final wsUrl = data['ws_url'] as String?;

  if (launchToken == null || ccInstanceId == null || wsUrl == null) {
    DebugLog.e('AUTO_DEMO', 'launch response missing fields', data);
    return AutoDemoResult.failure(
      stage: 'launch-cc-parse',
      error: StateError('launch_token / cc_instance_id / ws_url null'),
    );
  }

  DebugLog.i('AUTO_DEMO', 'launch-cc OK', {
    'cc_instance_id': ccInstanceId,
    'ws_url': wsUrl,
  });

  // Step 2: WebSocket — connect with launch_token (32-cc-write-game-info.http).
  // wsUrl already contains ?table_id=N. BoWebSocketClient takes base + appends.
  final wsBase = _stripQuery(wsUrl);
  final ws = BoWebSocketClient(
    wsUrl: wsBase,
    tableId: tableId,
    token: launchToken,
    onEvent: (_) {},
    fetchReplay: (_, __) async => const <Map<String, dynamic>>[],
  );

  // GameInfoAck waiter — wired before connect to avoid race.
  final ackCompleter = Completer<int>();
  ws.on('GameInfoAck', (payload) {
    if (ackCompleter.isCompleted) return;
    final handId = (payload['payload'] as Map?)?['hand_id'] as int? ?? -1;
    ackCompleter.complete(handId);
  });
  ws.on('GameInfoRejected', (payload) {
    if (ackCompleter.isCompleted) return;
    ackCompleter.completeError(
      StateError('GameInfoRejected: ${payload['payload']}'),
    );
  });

  try {
    await ws.connect();
  } catch (e, st) {
    DebugLog.e('AUTO_DEMO', 'ws connect failed', {'error': '$e'});
    onError?.call(e, st);
    return AutoDemoResult.failure(stage: 'ws-connect', error: e);
  }

  // Step 3: WriteGameInfo (CCR-024, 24 fields).
  final nowUtc = DateTime.now().toUtc();
  final payload = _sampleGameInfoPayload(tableId: tableId, nowUtc: nowUtc);
  final idemKey = UuidIdempotency.generate();
  final sent = ws.sendCommand(
    'WriteGameInfo',
    payload,
    idempotencyKey: idemKey,
  );
  if (!sent) {
    return AutoDemoResult.failure(
      stage: 'write-game-info-send',
      error: StateError('sendCommand returned false (offline buffer full)'),
    );
  }

  DebugLog.i('AUTO_DEMO', 'WriteGameInfo sent', {
    'hand_id': payload['hand_id'],
    'idempotency_key': idemKey,
  });

  // Step 3.5 (Cycle 4 #268): REST mirror — POST /api/v1/cc/games/{id}/info.
  // BO 측 cc.py router (team2-backend) 가 추가되면 REST + WS 둘 다 200 OK 가 KPI.
  // 부재 시 404/501 graceful catch — WS path만으로도 1-hand 시연은 유효.
  final restGameId = tableId;
  try {
    final restResp = await api.raw.post(
      '/api/v1/cc/games/$restGameId/info',
      data: payload,
      options: Options(
        headers: {'Idempotency-Key': idemKey},
        validateStatus: (s) => s != null && s < 500, // 4xx도 catch (404 endpoint 부재 포함)
      ),
    );
    DebugLog.i('AUTO_DEMO', 'REST cc/games/info response', {
      'status': restResp.statusCode,
      'data_keys': (restResp.data is Map)
          ? (restResp.data as Map).keys.toList()
          : restResp.data.runtimeType.toString(),
    });
  } catch (e) {
    DebugLog.w('AUTO_DEMO', 'REST cc/games/info error (non-fatal)', {'error': '$e'});
  }

  // Step 4: await GameInfoAck.
  try {
    final handId = await ackCompleter.future.timeout(ackTimeout);
    DebugLog.i('AUTO_DEMO', '1-hand wire OK', {'hand_id': handId});
    onReady?.call(handId);
    return AutoDemoResult.success(
      handId: handId,
      ccInstanceId: ccInstanceId,
      tableId: tableId,
    );
  } on TimeoutException catch (e, st) {
    DebugLog.e('AUTO_DEMO', 'ack timeout', {'after': ackTimeout.inSeconds});
    onError?.call(e, st);
    return AutoDemoResult.failure(stage: 'ack-timeout', error: e);
  } catch (e, st) {
    onError?.call(e, st);
    return AutoDemoResult.failure(stage: 'ack-error', error: e);
  }
}

String _stripQuery(String url) {
  final qIndex = url.indexOf('?');
  return qIndex < 0 ? url : url.substring(0, qIndex);
}

/// WriteGameInfo payload — BO 실제 schema (cc_handler.py _WRITE_COMMANDS) 와
/// 32-cc-write-game-info.http §32.1 의 24-필드 spec 양쪽을 동시 만족.
///
/// **BO required (4 필드)** [`team2-backend/src/websocket/cc_handler.py:23-28`]:
///   `gameType` / `betStructure` / `smallBlind` / `bigBlind`
///   (camelCase/snake_case alias 모두 허용 — `populate_by_name`)
///
/// **Spec 24 필드** (CCR-024 / API-05 §9): 모두 포함하되, BO는 미사용 필드를
/// 무시함. Type D drift 보존 — 정본 spec 갱신 또는 BO required 확장은
/// 별도 NOTIFY-S2/S7 이슈로 escalate.
Map<String, dynamic> _sampleGameInfoPayload({
  required int tableId,
  required DateTime nowUtc,
}) {
  final levelStart = nowUtc;
  final nextLevel = nowUtc.add(const Duration(minutes: 20));
  const sbAmount = 500;
  const bbAmount = 1000;
  const gameType = 'no_limit_holdem';
  const betStructure = 'wsop-ft-2026-lv42';
  return <String, dynamic>{
    // ── BO required (4 필드, camelCase canonical) ───────────────────────
    'gameType': gameType,
    'betStructure': betStructure,
    'smallBlind': sbAmount,
    'bigBlind': bbAmount,
    // ── Spec 24 필드 (snake_case) — BO 무시 / consumer 측에서 활용 ─────
    'table_id': tableId,
    'hand_id': nowUtc.millisecondsSinceEpoch ~/ 1000,
    'dealer_seat': 3,
    'sb_seat': 4,
    'bb_seat': 5,
    'sb_amount': sbAmount,
    'bb_amount': bbAmount,
    'ante_amount': 100,
    'big_blind_ante': false,
    'straddle_seats': <int>[6],
    'straddle_amount': 2000,
    'blind_structure_id': betStructure,
    'blind_level': 42,
    'current_level_start_ts': levelStart.toIso8601String(),
    'next_level_start_ts': nextLevel.toIso8601String(),
    'game_type': gameType,
    'allowed_games': <String>['nlhe'],
    'rotation_order': null,
    'chip_denominations': <int>[100, 500, 1000, 5000, 25000, 100000],
    'active_seats': <int>[1, 2, 3, 4, 5, 6, 7, 8],
    'dead_button_mode': true,
    'run_it_multiple_allowed': true,
    'bomb_pot_enabled': false,
    'cap_bb_multiplier': null,
  };
}

class AutoDemoResult {
  const AutoDemoResult._({
    required this.ok,
    this.handId,
    this.ccInstanceId,
    this.tableId,
    this.stage,
    this.error,
  });

  final bool ok;
  final int? handId;
  final String? ccInstanceId;
  final int? tableId;
  final String? stage;
  final Object? error;

  factory AutoDemoResult.success({
    required int handId,
    required String ccInstanceId,
    required int tableId,
  }) =>
      AutoDemoResult._(
        ok: true,
        handId: handId,
        ccInstanceId: ccInstanceId,
        tableId: tableId,
      );

  factory AutoDemoResult.failure({
    required String stage,
    required Object error,
  }) =>
      AutoDemoResult._(ok: false, stage: stage, error: error);
}

/// Riverpod provider — read AUTO_DEMO / ADMIN_TOKEN / TABLE_ID from --dart-define.
final autoDemoConfigProvider = Provider<AutoDemoConfig>((ref) {
  return const AutoDemoConfig();
});

class AutoDemoConfig {
  const AutoDemoConfig();

  bool get enabled => const bool.fromEnvironment('AUTO_DEMO', defaultValue: false);

  String get adminToken =>
      const String.fromEnvironment('ADMIN_TOKEN', defaultValue: '');

  int get tableId =>
      int.fromEnvironment('AUTO_DEMO_TABLE_ID', defaultValue: 1);

  String get boBaseUrl => const String.fromEnvironment(
        'BO_URL',
        defaultValue: 'http://localhost:8000',
      );
}
