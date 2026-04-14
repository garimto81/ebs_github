// Engine Harness providers (Option A — HTTP client).
//
// Exposes EngineClient + session state + reactive game state via Riverpod.
// Maps to Team 3's GameState (BS-06-00-REF Ch.2).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/remote/engine_client.dart';

/// Engine client provider — creates EngineClient with configured base URL.
final engineClientProvider = Provider<EngineClient>((ref) {
  return EngineClient();
});

/// Current engine session ID.
final engineSessionProvider = StateProvider<String?>((ref) => null);

/// Engine game state — refreshed on every event.
final engineStateProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final client = ref.watch(engineClientProvider);
  final sessionId = ref.watch(engineSessionProvider);
  if (sessionId == null) return null;
  return client.getState(sessionId);
});
