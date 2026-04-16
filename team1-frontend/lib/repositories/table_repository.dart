import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/remote/bo_api_client.dart';
import '../models/models.dart';

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

  // -- Rebalance -----------------------------------------------------------

  Future<Map<String, dynamic>> rebalance(int flightId) async {
    return _client.post<Map<String, dynamic>>(
      '/flights/$flightId/rebalance',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }
}

final tableRepositoryProvider = Provider<TableRepository>((ref) {
  return TableRepository(ref.watch(boApiClientProvider));
});
