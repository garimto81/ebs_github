import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/remote/bo_api_client.dart';
import '../models/models.dart';

// TODO(B-088 PR-6): REST path kebab-case → WSOP LIVE PascalCase 일괄 전환.
// 현재: /tables, /hand-history, /blind-structures, /payout-structures 등 kebab-case.
// 목표: /Tables, /HandHistory, /BlindStructures, /PayoutStructures (WSOP LIVE 직접 준수).
// 전환 시점: team2 PR-4 (Backend router rename) 완료 후 일괄 교체.
// 상세: docs/2. Development/2.5 Shared/Naming_Conventions.md §1 + B-088 PR-4/6
//
// 본 session(B-088 PR-5) 에서는 @JsonKey(name: 'camelCase') Freezed 전환만 수행.
// Backend 가 PR-2 (Pydantic alias_generator) 전까지 snake_case 응답 → 실 BO 연결 시
// API 파싱 실패 예상됨 (의도적 breakage — cut-over 전제). Mock 환경은 동시 전환 완료.

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
      data: {'player_id': playerId, 'seat_no': seatNo},
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
        'event_flight_id': eventFlightId,
        'strategy': strategy,
        'target_players_per_table': targetPlayersPerTable,
        'dry_run': dryRun,
      },
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }
}

final tableRepositoryProvider = Provider<TableRepository>((ref) {
  return TableRepository(ref.watch(boApiClientProvider));
});
