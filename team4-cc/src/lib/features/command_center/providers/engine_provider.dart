// Engine Harness providers (Option A — HTTP client).
//
// Exposes EngineClient + session state + reactive game state via Riverpod.
// Maps to Team 3's GameState (BS-06-00-REF Ch.2).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/remote/engine_client.dart';
import '../../../features/auth/auth_provider.dart';

/// Engine client provider — creates EngineClient with configured base URL.
/// Reads engineUrl from LaunchConfig (default: http://localhost:8080).
final engineClientProvider = Provider<EngineClient>((ref) {
  final config = ref.watch(launchConfigProvider);
  return EngineClient(baseUrl: config?.engineUrl ?? 'http://localhost:8080');
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
