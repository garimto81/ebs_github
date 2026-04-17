// BO REST API client with Idempotency-Key interceptor (CCR-019).
//
// Every mutation request (POST/PATCH/PUT/DELETE) automatically receives an
// `Idempotency-Key` header. API-05 edit history 2026-04-10 records CCR-003
// making this field required across API-01/API-05/API-06.
//
// Endpoint methods follow docs/2. Development/2.2 Backend/APIs/ :
// - Auth_and_Session.md (BO session + table REST, legacy API-01/API-06)
// - WebSocket_Events.md (REST complement for the WS channel, legacy API-05)

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

  /// Launch CC for a table. Returns { cc_instance_id, launch_token, ws_url }.
  Future<Map<String, dynamic>> launchTable(int tableId) async {
    final response = await _dio.post('/api/v1/tables/$tableId/launch-cc');
    return response.data as Map<String, dynamic>;
  }

  /// Get current table state.
  Future<Map<String, dynamic>> getTableState(int tableId) async {
    final response = await _dio.get('/api/v1/tables/$tableId');
    return response.data as Map<String, dynamic>;
  }

  /// Close (delete) a table.
  Future<void> closeTable(int tableId) async {
    await _dio.delete('/api/v1/tables/$tableId');
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
      '/api/v1/tables/$tableId/events/replay',
      data: {'events': events},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Get hand detail for a specific hand.
  Future<Map<String, dynamic>> getHandRecap(int handId) async {
    final response = await _dio.get('/api/v1/hands/$handId');
    return response.data as Map<String, dynamic>;
  }

  /// Get hand history (paginated).
  Future<List<dynamic>> getHandHistory(
    int tableId, {
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _dio.get(
      '/api/v1/hands',
      queryParameters: {
        'table_id': tableId,
        'page': page,
        'per_page': perPage,
      },
    );
    return response.data as List<dynamic>;
  }

  // =========================================================================
  // Player endpoints (API-01)
  // =========================================================================

  /// Search players by name or ID.
  Future<List<Map<String, dynamic>>> searchPlayers(String query) async {
    final response = await _dio.get(
      '/api/v1/players/search',
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
    final response = await _dio.get('/api/v1/players/$playerId/stats');
    return response.data as Map<String, dynamic>;
  }

  /// Push GFX stats for overlay display (per table or per player).
  Future<void> pushGfxStats(int tableId, {int? playerId}) async {
    await _dio.post(
      '/api/v1/tables/$tableId/gfx-stats',
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
      '/api/v1/tables/$tableId/seats/$seatNo/player',
      data: data,
    );
  }

  // =========================================================================
  // Deck endpoints (BS-04-01 Deck Registration)
  // =========================================================================

  /// Register a newly scanned deck with BO. Returns the server-assigned deck_id.
  /// Payload per `docs/2. Development/2.4 Command Center/RFID_Cards/Register_Screen.md §5`:
  ///   { "deck_name": "...", "cards": [{"uid": "...", "rank": "A", "suit": "s"}, ...] }
  Future<String> registerDeck({
    required String deckName,
    required List<Map<String, String>> cards,
  }) async {
    final response = await _dio.post(
      '/api/v1/decks',
      data: {
        'deck_name': deckName,
        'cards': cards,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return data['deck_id'] as String;
  }

  // =========================================================================
  // Config / Settings endpoints (API-06)
  // =========================================================================

  /// Get config for a section (Settings.md §6탭).
  Future<Map<String, dynamic>> getConfig(String section) async {
    final response = await _dio.get('/api/v1/configs/$section');
    return response.data as Map<String, dynamic>;
  }

  /// Update config for a section.
  Future<void> updateConfig(
    String section,
    Map<String, dynamic> values,
  ) async {
    await _dio.put('/api/v1/configs/$section', data: values);
  }

  // =========================================================================
  // Skin endpoints (CCR-015)
  // =========================================================================

  /// Get the active skin bundle URL for download.
  Future<Map<String, dynamic>> getSkinInfo(String skinId) async {
    final response = await _dio.get('/api/v1/skins/$skinId');
    return response.data as Map<String, dynamic>;
  }

  // =========================================================================
  // Event replay endpoints (API-05)
  // =========================================================================

  /// Fetch missing events for a seq gap range (inclusive).
  /// Used by BoWebSocketClient for CCR-021 gap replay.
  /// WebSocket_Events.md §6.4: GET /tables/:id/events?since={last_seq}
  Future<List<Map<String, dynamic>>> fetchReplayEvents(
    int tableId,
    int sinceSeq, {
    int limit = 100,
  }) async {
    final response = await _dio.get(
      '/api/v1/tables/$tableId/events',
      queryParameters: {'since': sinceSeq, 'limit': limit},
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
