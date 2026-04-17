// Engine Harness HTTP client (Option A).
//
// Communicates with Team 3's HarnessServer.
// API: Harness_REST_API.md §2 endpoints.
// Event types: §2.4 event catalog (fold/check/call/bet/raise/allin/...).

import 'package:dio/dio.dart';

/// Event type constants matching Team 3's Harness REST API §2.4.
class EngineEvents {
  EngineEvents._();

  // Player actions
  static const fold = 'fold';
  static const check = 'check';
  static const call = 'call';
  static const bet = 'bet';
  static const raise = 'raise';
  static const allin = 'allin';

  // Street/deal
  static const streetAdvance = 'street_advance';
  static const dealCommunity = 'deal_community';
  static const dealHole = 'deal_hole';

  // Hand lifecycle
  static const potAwarded = 'pot_awarded';
  static const handEnd = 'hand_end';
  static const misdeal = 'misdeal';

  // Other
  static const muck = 'muck';
  static const timeoutFold = 'timeout_fold';
  static const bombPotConfig = 'bomb_pot_config';
  static const runItChoice = 'run_it_choice';
  static const pineappleDiscard = 'pineapple_discard';
}

class EngineClient {
  EngineClient({String baseUrl = 'http://localhost:8080'})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 10),
        ));

  final Dio _dio;

  // ---------------------------------------------------------------------------
  // Session management
  // ---------------------------------------------------------------------------

  /// Create a new game session. Returns session ID.
  Future<String> createSession({
    required String gameType,
    required String betStructure,
    int tableSize = 10,
  }) async {
    final response = await _dio.post('/api/session', data: {
      'variant': gameType,
      'betStructure': betStructure,
      'tableSize': tableSize,
    });
    return response.data['sessionId'] as String;
  }

  /// Get current game state for a session.
  Future<Map<String, dynamic>> getState(String sessionId) async {
    final response = await _dio.get('/api/session/$sessionId');
    return response.data as Map<String, dynamic>;
  }

  /// Send a raw event to the engine.
  Future<Map<String, dynamic>> sendEvent(
    String sessionId, {
    required String eventType,
    required Map<String, dynamic> payload,
  }) async {
    final response = await _dio.post('/api/session/$sessionId/event', data: {
      'type': eventType,
      ...payload,
    });
    return response.data as Map<String, dynamic>;
  }

  /// Undo the last event.
  Future<Map<String, dynamic>> undo(String sessionId) async {
    final response = await _dio.post('/api/session/$sessionId/undo');
    return response.data as Map<String, dynamic>;
  }

  /// Close a session. Tolerates 404 (team3 harness may not implement DELETE).
  Future<void> closeSession(String sessionId) async {
    try {
      await _dio.delete('/api/session/$sessionId');
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Typed action builders (Harness_REST_API.md §2.4)
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> sendFold(String sessionId, int seatIndex) =>
      sendEvent(sessionId,
          eventType: EngineEvents.fold, payload: {'seatIndex': seatIndex});

  Future<Map<String, dynamic>> sendCheck(String sessionId, int seatIndex) =>
      sendEvent(sessionId,
          eventType: EngineEvents.check, payload: {'seatIndex': seatIndex});

  Future<Map<String, dynamic>> sendCall(
          String sessionId, int seatIndex, int amount) =>
      sendEvent(sessionId,
          eventType: EngineEvents.call,
          payload: {'seatIndex': seatIndex, 'amount': amount});

  Future<Map<String, dynamic>> sendBet(
          String sessionId, int seatIndex, int amount) =>
      sendEvent(sessionId,
          eventType: EngineEvents.bet,
          payload: {'seatIndex': seatIndex, 'amount': amount});

  Future<Map<String, dynamic>> sendRaise(
          String sessionId, int seatIndex, int amount) =>
      sendEvent(sessionId,
          eventType: EngineEvents.raise,
          payload: {'seatIndex': seatIndex, 'amount': amount});

  Future<Map<String, dynamic>> sendAllin(
          String sessionId, int seatIndex, int amount) =>
      sendEvent(sessionId,
          eventType: EngineEvents.allin,
          payload: {'seatIndex': seatIndex, 'amount': amount});

  Future<Map<String, dynamic>> sendStreetAdvance(
          String sessionId, String next) =>
      sendEvent(sessionId,
          eventType: EngineEvents.streetAdvance, payload: {'next': next});

  Future<Map<String, dynamic>> sendDealCommunity(
          String sessionId, List<String> cards) =>
      sendEvent(sessionId,
          eventType: EngineEvents.dealCommunity, payload: {'cards': cards});

  Future<Map<String, dynamic>> sendDealHole(
          String sessionId, Map<String, List<String>> cards) =>
      sendEvent(sessionId,
          eventType: EngineEvents.dealHole, payload: {'cards': cards});
}
