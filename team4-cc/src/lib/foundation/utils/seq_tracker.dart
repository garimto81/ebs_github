// Monotonic WebSocket sequence tracker for CCR-021.
//
// Every inbound WebSocket event carries a monotonically increasing `seq`
// field (API-05 edit history 2026-04-10). This tracker detects gaps caused
// by reconnection or lost frames and yields replay ranges.
//
// Consumer (bo_websocket_client.dart) calls `apply(seq)` on each event and,
// for any non-empty returned gap list, invokes the replay endpoint
// `GET /events/replay?from_seq=X&to_seq=Y` before applying the triggering
// event to the GameState.

class SeqTracker {
  int _lastSeq = 0;

  int get lastSeq => _lastSeq;

  /// Process an incoming sequence number.
  ///
  /// Returns the list of `[from, to]` inclusive gaps that must be replayed
  /// before applying this event. Empty list means in-order delivery.
  ///
  /// - `incomingSeq == lastSeq + 1` → normal, no gap
  /// - `incomingSeq > lastSeq + 1` → gap from `lastSeq + 1` to `incomingSeq - 1`
  /// - `incomingSeq <= lastSeq` → duplicate or out-of-order, ignore (returns [])
  List<(int from, int to)> apply(int incomingSeq) {
    if (incomingSeq <= _lastSeq) {
      // duplicate or out-of-order; upstream deduplication responsibility
      return const [];
    }
    if (incomingSeq == _lastSeq + 1) {
      _lastSeq = incomingSeq;
      return const [];
    }
    // gap detected
    final gap = (_lastSeq + 1, incomingSeq - 1);
    _lastSeq = incomingSeq;
    return [gap];
  }

  /// Reset after explicit resync (e.g. full state snapshot received).
  void reset(int toSeq) {
    _lastSeq = toSeq;
  }
}
