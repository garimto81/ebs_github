// BO REST API client with Idempotency-Key interceptor (CCR-019).
//
// Every mutation request (POST/PATCH/PUT/DELETE) automatically receives an
// `Idempotency-Key` header. API-05 edit history 2026-04-10 records CCR-003
// making this field required across API-01/API-05/API-06.
//
// Endpoint methods follow contracts/api/API-01 (Table), API-05 (WebSocket
// complement REST), and API-06 (Settings) specifications.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../foundation/utils/uuid_idempotency.dart';

// ---------------------------------------------------------------------------
// Client
// ---------------------------------------------------------------------------

class BoApiClient {
  BoApiClient({required String baseUrl, String? token})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        )) {
    _dio.interceptors.add(_IdempotencyInterceptor());
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  final Dio _dio;

  Dio get raw => _dio;

  /// Update auth token (after re-authentication).
  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // =========================================================================
  // Table endpoints (API-01)
  // =========================================================================

  /// Launch (activate) a table. Returns table state.
  Future<Map<String, dynamic>> launchTable(int tableId) async {
    final response = await _dio.post('/api/tables/$tableId/launch');
    return response.data as Map<String, dynamic>;
  }

  /// Get current table state.
  Future<Map<String, dynamic>> getTableState(int tableId) async {
    final response = await _dio.get('/api/tables/$tableId/state');
    return response.data as Map<String, dynamic>;
  }

  /// Close a table.
  Future<void> closeTable(int tableId) async {
    await _dio.post('/api/tables/$tableId/close');
  }

  // =========================================================================
  // Hand endpoints (API-01 / API-05)
  // =========================================================================

  /// Replay a list of events to the server (offline buffer drain).
  Future<Map<String, dynamic>> replayEvents(
    int tableId,
    List<Map<String, dynamic>> events,
  ) async {
    final response = await _dio.post(
      '/api/tables/$tableId/events/replay',
      data: {'events': events},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Get hand recap/history for a specific hand.
  Future<Map<String, dynamic>> getHandRecap(int handId) async {
    final response = await _dio.get('/api/hands/$handId/recap');
    return response.data as Map<String, dynamic>;
  }

  /// Get hand history for a table (paginated).
  Future<List<dynamic>> getHandHistory(
    int tableId, {
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _dio.get(
      '/api/tables/$tableId/hands',
      queryParameters: {'page': page, 'per_page': perPage},
    );
    return response.data as List<dynamic>;
  }

  // =========================================================================
  // Player endpoints (API-01)
  // =========================================================================

  /// Search players by name or ID.
  Future<List<Map<String, dynamic>>> searchPlayers(String query) async {
    final response = await _dio.get(
      '/api/players/search',
      queryParameters: {'q': query},
    );
    final data = response.data;
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Get player stats (chip count history, hands played, etc.).
  Future<Map<String, dynamic>> getPlayerStats(int playerId) async {
    final response = await _dio.get('/api/players/$playerId/stats');
    return response.data as Map<String, dynamic>;
  }

  /// Push GFX stats for overlay display (per table or per player).
  Future<void> pushGfxStats(int tableId, {int? playerId}) async {
    await _dio.post(
      '/api/tables/$tableId/gfx-stats',
      data: {
        if (playerId != null) 'player_id': playerId,
      },
    );
  }

  /// Update player info at a seat.
  Future<void> updatePlayer(
    int tableId,
    int seatNo,
    Map<String, dynamic> data,
  ) async {
    await _dio.patch(
      '/api/tables/$tableId/seats/$seatNo/player',
      data: data,
    );
  }

  // =========================================================================
  // Config / Settings endpoints (API-06)
  // =========================================================================

  /// Get game settings for a table.
  Future<Map<String, dynamic>> getGameSettings(int tableId) async {
    final response = await _dio.get('/api/tables/$tableId/settings');
    return response.data as Map<String, dynamic>;
  }

  /// Update game settings for a table.
  Future<void> updateGameSettings(
    int tableId,
    Map<String, dynamic> settings,
  ) async {
    await _dio.patch(
      '/api/tables/$tableId/settings',
      data: settings,
    );
  }

  // =========================================================================
  // Skin endpoints (CCR-015)
  // =========================================================================

  /// Get the active skin bundle URL for download.
  Future<Map<String, dynamic>> getSkinInfo(String skinId) async {
    final response = await _dio.get('/api/skins/$skinId');
    return response.data as Map<String, dynamic>;
  }

  // =========================================================================
  // Event replay endpoints (API-05)
  // =========================================================================

  /// Fetch missing events for a seq gap range (inclusive).
  /// Used by BoWebSocketClient for CCR-021 gap replay.
  Future<List<Map<String, dynamic>>> fetchReplayEvents(
    int fromSeq,
    int toSeq,
  ) async {
    final response = await _dio.get(
      '/api/events/replay',
      queryParameters: {'from_seq': fromSeq, 'to_seq': toSeq},
    );
    final data = response.data;
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }
}

// ---------------------------------------------------------------------------
// Idempotency-Key interceptor (CCR-019)
// ---------------------------------------------------------------------------

class _IdempotencyInterceptor extends Interceptor {
  static const _mutationMethods = {'POST', 'PUT', 'PATCH', 'DELETE'};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_mutationMethods.contains(options.method.toUpperCase())) {
      // Only generate if caller did not provide one explicitly.
      options.headers.putIfAbsent(
        UuidIdempotency.headerName,
        UuidIdempotency.generate,
      );
    }
    handler.next(options);
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final boApiClientProvider = Provider<BoApiClient>((ref) {
  return BoApiClient(baseUrl: 'http://localhost:8000');
});
