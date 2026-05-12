import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/remote/bo_api_client.dart';
import '../models/models.dart';

// B-088 PR-6b (2026-04-21): REST path WSOP LIVE PascalCase 100% 준수.
// /Tables, /HandHistory, /BlindStructures, /PayoutStructures, /AuditLogs, /Auth/Login 등.
// team2 PR-4 (Backend router rename) 전이지만 cut-over 방식으로 선제 전환.
// Mock adapter 동시 전환 필수 (USE_MOCK=true 환경에서 정상 동작 유지).
// 실 Backend 연결 시 team2 PR-4 merge 될 때까지 일시적 404 발생 — 예상된 breakage.
// 상세: docs/2. Development/2.5 Shared/Naming_Conventions.md §1

class TableRepository {
  TableRepository(this._client);
  final BoApiClient _client;

  Future<List<EbsTable>> listTables({
    Map<String, dynamic>? params,
  }) async {
    return _client.get<List<EbsTable>>(
      '/tables',
      queryParameters: params,
      fromJson: (json) => (json as List)
          .map((e) => EbsTable.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  // Cycle 10 (S2 hierarchy wire): nested route uses a path variable so the
  // Lobby drill-down does not depend on the `?flightId=` vs `?flight_id=`
  // query-param naming divergence (BO routers/tables.py L61 expects
  // snake_case; SSOT Naming_Conventions.md §1 mandates camelCase JSON).
  // BO endpoint: routers/tables.py L90 `/flights/{flight_id}/tables`.
  Future<List<EbsTable>> listByFlight(int flightId) async {
    return _client.get<List<EbsTable>>(
      '/flights/$flightId/tables',
      fromJson: (json) => (json as List)
          .map((e) => EbsTable.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<EbsTable> getTable(int id) async {
    return _client.get<EbsTable>(
      '/tables/$id',
      fromJson: (json) => EbsTable.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<EbsTable> createTable(Map<String, dynamic> data) async {
    return _client.post<EbsTable>(
      '/tables',
      data: data,
      fromJson: (json) => EbsTable.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<EbsTable> updateTable(int id, Map<String, dynamic> data) async {
    return _client.put<EbsTable>(
      '/tables/$id',
      data: data,
      fromJson: (json) => EbsTable.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> deleteTable(int id) async {
    await _client.delete<dynamic>('/tables/$id');
  }

  Future<Map<String, dynamic>> launchCc(int id) async {
    return _client.post<Map<String, dynamic>>(
      '/tables/$id/launch-cc',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  Future<Map<String, dynamic>> getStatus(int id) async {
    return _client.get<Map<String, dynamic>>(
      '/tables/$id/status',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  // -- Seats ---------------------------------------------------------------

  Future<List<TableSeat>> listSeats(int tableId) async {
    return _client.get<List<TableSeat>>(
      '/tables/$tableId/seats',
      fromJson: (json) => (json as List)
          .map((e) => TableSeat.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<TableSeat> addPlayer(
    int tableId, {
    required int playerId,
    required int seatNo,
  }) async {
    return _client.post<TableSeat>(
      '/tables/$tableId/seats',
      data: {'playerId': playerId, 'seatNo': seatNo},
      fromJson: (json) => TableSeat.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<TableSeat> updateSeat(
    int tableId,
    int seatNo,
    Map<String, dynamic> data,
  ) async {
    return _client.put<TableSeat>(
      '/tables/$tableId/seats/$seatNo',
      data: data,
      fromJson: (json) => TableSeat.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> removePlayer(int tableId, int seatNo) async {
    await _client.delete<dynamic>('/tables/$tableId/seats/$seatNo');
  }

  // -- Rebalance (Backend_HTTP.md §Table.POST /tables/rebalance — Saga) ----
  // 다중 테이블 플레이어 재배치. body 로 event_flight_id + 전략 전달.
  // Idempotency-Key 헤더는 Dio interceptor 가 자동 주입.

  Future<Map<String, dynamic>> rebalance(
    int eventFlightId, {
    String strategy = 'balanced',
    int targetPlayersPerTable = 9,
    bool dryRun = false,
  }) async {
    return _client.post<Map<String, dynamic>>(
      '/tables/rebalance',
      data: {
        'eventFlightId': eventFlightId,
        'strategy': strategy,
        'targetPlayersPerTable': targetPlayersPerTable,
        'dryRun': dryRun,
      },
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }
}

final tableRepositoryProvider = Provider<TableRepository>((ref) {
  return TableRepository(ref.watch(boApiClientProvider));
});
