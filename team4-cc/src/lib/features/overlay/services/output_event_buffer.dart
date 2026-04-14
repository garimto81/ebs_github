// OutputEventBuffer — DEPRECATED, replaced by SecurityDelayBuffer.
//
// This file is kept for backward compatibility. New code should use
// SecurityDelayBuffer from security_delay_buffer.dart directly.
//
// Original: Security Delay FIFO (BS-07-07, CCR-036).

import 'dart:collection';

/// @deprecated Use [DelayedSnapshot] from security_delay_buffer.dart.
class DelayedOutputEvent {
  const DelayedOutputEvent({
    required this.type,
    required this.payload,
    required this.releaseAt,
  });

  final String type;
  final Map<String, dynamic> payload;
  final DateTime releaseAt;
}

/// @deprecated Use [SecurityDelayBuffer] from security_delay_buffer.dart.
class OutputEventBuffer {
  OutputEventBuffer({
    required this.delay,
    this.capacity = 1000,
  });

  final Duration delay;
  final int capacity;
  final Queue<DelayedOutputEvent> _buffer = Queue();

  void enqueue(String type, Map<String, dynamic> payload) {
    if (_buffer.length >= capacity) {
      _buffer.removeFirst(); // drop oldest on overflow
    }
    _buffer.add(DelayedOutputEvent(
      type: type,
      payload: payload,
      releaseAt: DateTime.now().add(delay),
    ));
  }

  /// Drain events whose releaseAt has passed.
  List<DelayedOutputEvent> drainReady() {
    final now = DateTime.now();
    final ready = <DelayedOutputEvent>[];
    while (_buffer.isNotEmpty && !_buffer.first.releaseAt.isAfter(now)) {
      ready.add(_buffer.removeFirst());
    }
    return ready;
  }

  int get bufferedCount => _buffer.length;
}
