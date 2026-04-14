// Security Delay Buffer (BS-07-07, CCR-036).
//
// FIFO queue with releaseAt timestamps for delayed broadcast output.
// Dual output architecture: Backstage receives immediately, Broadcast
// receives on releaseAt via this buffer.
//
// Delay targets (DELAYED):
//   hole_cards, community_cards, actions, pot_total,
//   win_probability, hand_rank, chip_stack
//
// NOT delayed (PASSTHROUGH):
//   player_name, blind_level, table_info, dealer_position
//
// Default delay: 30s. Buffer cap: 7200 snapshots (120s @ 60fps).

import 'dart:collection';

// ---------------------------------------------------------------------------
// Delayed snapshot value object
// ---------------------------------------------------------------------------

class DelayedSnapshot {
  const DelayedSnapshot({
    required this.gameState,
    required this.releaseAt,
    required this.enqueuedAt,
  });

  final Map<String, dynamic> gameState;
  final DateTime releaseAt;
  final DateTime enqueuedAt;
}

// ---------------------------------------------------------------------------
// Security Delay Buffer
// ---------------------------------------------------------------------------

class SecurityDelayBuffer {
  SecurityDelayBuffer({
    required this.delay,
    this.maxCapacity = 7200, // 120s @ 60fps
  });

  final Duration delay;
  final int maxCapacity;
  final Queue<DelayedSnapshot> _queue = Queue<DelayedSnapshot>();

  /// Fields that are delayed (security-sensitive).
  static const _delayedFields = {
    'hole_cards',
    'community_cards',
    'actions',
    'pot_total',
    'win_probability',
    'hand_rank',
    'chip_stack',
    'current_bet',
    'side_pots',
  };

  /// Fields that pass through immediately (not security-sensitive).
  static const _passthroughFields = {
    'player_name',
    'blind_level',
    'table_info',
    'dealer_position',
    'seat_status',
    'player_count',
  };

  // -- Enqueue --------------------------------------------------------------

  /// Enqueue a game state snapshot with delay applied.
  ///
  /// The snapshot is masked: delayed fields are included, passthrough
  /// fields are stripped (they are emitted immediately by DualOutputManager).
  void enqueue(Map<String, dynamic> state) {
    final now = DateTime.now();
    final snapshot = DelayedSnapshot(
      gameState: _applyDelayMask(state),
      releaseAt: now.add(delay),
      enqueuedAt: now,
    );
    _queue.add(snapshot);

    // Drop oldest on overflow
    while (_queue.length > maxCapacity) {
      _queue.removeFirst();
    }
  }

  // -- Release --------------------------------------------------------------

  /// Release the next snapshot if its releaseAt has passed.
  /// Returns null if no snapshot is ready.
  Map<String, dynamic>? releaseNext() {
    if (_queue.isEmpty) return null;
    if (_queue.first.releaseAt.isBefore(DateTime.now())) {
      return _queue.removeFirst().gameState;
    }
    return null;
  }

  /// Drain all snapshots whose releaseAt has passed.
  List<Map<String, dynamic>> drainReady() {
    final now = DateTime.now();
    final ready = <Map<String, dynamic>>[];
    while (_queue.isNotEmpty && !_queue.first.releaseAt.isAfter(now)) {
      ready.add(_queue.removeFirst().gameState);
    }
    return ready;
  }

  // -- Metrics --------------------------------------------------------------

  int get bufferedCount => _queue.length;
  bool get isEmpty => _queue.isEmpty;

  /// Time until the next snapshot is ready (null if empty).
  Duration? get timeToNextRelease {
    if (_queue.isEmpty) return null;
    final diff = _queue.first.releaseAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  // -- Flush / Reset --------------------------------------------------------

  /// Flush entire buffer (emergency clear, e.g. table close).
  void flush() => _queue.clear();

  // -- Delay mask -----------------------------------------------------------

  /// Apply delay mask: keep only security-sensitive fields.
  /// Passthrough fields are stripped because they are emitted immediately.
  Map<String, dynamic> _applyDelayMask(Map<String, dynamic> state) {
    final masked = <String, dynamic>{};
    for (final entry in state.entries) {
      if (_delayedFields.contains(entry.key)) {
        masked[entry.key] = entry.value;
      }
    }
    // Always include metadata for reconstruction
    if (state.containsKey('hand_id')) masked['hand_id'] = state['hand_id'];
    if (state.containsKey('seq')) masked['seq'] = state['seq'];
    if (state.containsKey('timestamp')) {
      masked['timestamp'] = state['timestamp'];
    }
    return masked;
  }

  /// Extract passthrough fields (emitted immediately, no delay).
  static Map<String, dynamic> extractPassthrough(Map<String, dynamic> state) {
    final passthrough = <String, dynamic>{};
    for (final entry in state.entries) {
      if (_passthroughFields.contains(entry.key)) {
        passthrough[entry.key] = entry.value;
      }
    }
    // Metadata always passes through
    if (state.containsKey('hand_id')) {
      passthrough['hand_id'] = state['hand_id'];
    }
    if (state.containsKey('seq')) passthrough['seq'] = state['seq'];
    return passthrough;
  }
}
