// DualOutputManager — manages Backstage (instant) and Broadcast (delayed) streams.
// See BS-07-07-security-delay.md §principle (CCR-036).
//
// Architecture:
//   GameState event arrives →
//     1. Backstage: immediate push (no delay) → Flutter Widget render
//     2. Broadcast: enqueue to SecurityDelayBuffer → periodic tick drains
//
// Phase 1: render to Flutter Widget.
// Phase 2: NDI output (stub in OutputConfig).

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../models/output_config.dart';
import 'security_delay_buffer.dart';

final _log = Logger('DualOutputManager');

// ---------------------------------------------------------------------------
// Callback types
// ---------------------------------------------------------------------------

/// Called with game state to render (backstage or broadcast).
typedef RenderCallback = void Function(Map<String, dynamic> gameState);

// ---------------------------------------------------------------------------
// DualOutputManager
// ---------------------------------------------------------------------------

class DualOutputManager {
  DualOutputManager({
    required SecurityDelayBuffer delayBuffer,
    required this.onBackstageRender,
    required this.onBroadcastRender,
    Duration tickInterval = const Duration(milliseconds: 50),
  })  : _delayBuffer = delayBuffer,
        _tickInterval = tickInterval;

  final SecurityDelayBuffer _delayBuffer;
  final Duration _tickInterval;

  /// Callback for backstage (immediate, no delay) render.
  final RenderCallback onBackstageRender;

  /// Callback for broadcast (delayed) render.
  final RenderCallback onBroadcastRender;

  Timer? _broadcastTimer;
  bool _running = false;

  // -- Emit -----------------------------------------------------------------

  /// Emit a game state event.
  ///
  /// Backstage: pushes immediately to [onBackstageRender].
  /// Broadcast: enqueues to [SecurityDelayBuffer] with delay applied.
  /// Passthrough fields (player_name, blind_level) also go to broadcast
  /// immediately.
  void emit(Map<String, dynamic> gameState) {
    // Backstage: full state, immediate
    onBackstageRender(gameState);

    // Broadcast: delayed sensitive fields
    _delayBuffer.enqueue(gameState);

    // Broadcast: passthrough fields immediately
    final passthrough = SecurityDelayBuffer.extractPassthrough(gameState);
    if (passthrough.isNotEmpty) {
      onBroadcastRender(passthrough);
    }
  }

  // -- Broadcast tick -------------------------------------------------------

  /// Start the broadcast drain timer.
  void start() {
    if (_running) return;
    _running = true;
    _broadcastTimer = Timer.periodic(_tickInterval, (_) => _tickBroadcast());
    _log.info('DualOutput broadcast timer started '
        '(interval: ${_tickInterval.inMilliseconds}ms)');
  }

  /// Stop the broadcast drain timer.
  void stop() {
    _running = false;
    _broadcastTimer?.cancel();
    _broadcastTimer = null;
    _log.info('DualOutput broadcast timer stopped');
  }

  /// Single tick: drain ready events from buffer to broadcast output.
  void _tickBroadcast() {
    final ready = _delayBuffer.drainReady();
    for (final state in ready) {
      onBroadcastRender(state);
    }
  }

  // -- Metrics --------------------------------------------------------------

  int get bufferedCount => _delayBuffer.bufferedCount;
  bool get isRunning => _running;

  // -- Flush / Dispose ------------------------------------------------------

  /// Flush all buffered events (emergency clear).
  void flush() {
    _delayBuffer.flush();
  }

  /// Dispose timers.
  void dispose() {
    stop();
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final outputConfigProvider = StateProvider<OutputConfig>((ref) {
  return const OutputConfig();
});

final securityDelayBufferProvider = Provider<SecurityDelayBuffer>((ref) {
  return SecurityDelayBuffer(
    delay: const Duration(seconds: 30),
  );
});
