// Engine Harness HTTP client (Option A).
//
// Communicates with Team 3's HarnessServer at localhost:8080.
// API surface: POST /sessions, GET /sessions/{id}/state,
// POST /sessions/{id}/event, POST /sessions/{id}/undo,
// DELETE /sessions/{id}.

import 'package:dio/dio.dart';

/// Event type constants matching Team 3's event catalog.
class EngineEvents {
  EngineEvents._();

  static const startHand = 'StartHand';
  static const deal = 'Deal';
  static const playerAction = 'PlayerAction';
  static const boardCard = 'BoardCard';
  static const showdown = 'Showdown';
  static const undo = 'Undo';
  static const runItMultiple = 'RunItMultiple';
  static const missDeal = 'MissDeal';
  static const seatPlayer = 'SeatPlayer';
  static const unseatPlayer = 'UnseatPlayer';
  static const updateBlind = 'UpdateBlind';
}

class EngineClient {
  EngineClient({String baseUrl = 'http://localhost:8080'})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 10),
        ));

  final Dio _dio;

  /// Create a new game session. Returns session ID.
  Future<String> createSession({
    required String gameType,
    required String betStructure,
    int tableSize = 10,
  }) async {
    final response = await _dio.post('/sessions', data: {
      'gameType': gameType,
      'betStructure': betStructure,
      'tableSize': tableSize,
    });
    return response.data['sessionId'] as String;
  }

  /// Get current game state for a session.
  Future<Map<String, dynamic>> getState(String sessionId) async {
    final response = await _dio.get('/sessions/$sessionId/state');
    return response.data as Map<String, dynamic>;
  }

  /// Send an event to the engine (action, card detection, etc.).
  /// Returns the engine's response (ReduceResult).
  Future<Map<String, dynamic>> sendEvent(
    String sessionId, {
    required String eventType,
    required Map<String, dynamic> payload,
  }) async {
    final response = await _dio.post('/sessions/$sessionId/event', data: {
      'type': eventType,
      ...payload,
    });
    return response.data as Map<String, dynamic>;
  }

  /// Undo the last event.
  Future<Map<String, dynamic>> undo(String sessionId) async {
    final response = await _dio.post('/sessions/$sessionId/undo');
    return response.data as Map<String, dynamic>;
  }

  /// Close a session.
  Future<void> closeSession(String sessionId) async {
    await _dio.delete('/sessions/$sessionId');
  }
}
