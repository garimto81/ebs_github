// Event Sourcing Undo Stack (BS-05-05).
//
// Separate from LocalEventBuffer (reconnect) — CONSIST-06.
//
// - Unlimited undo within current hand (UI-02 redesign)
// - Reversible events: ActionPerformed, CardDetected, BoardCardDealt,
//   SeatStatusChanged, PlayerStackChanged, DealerMoved, BlindPosted (partial),
//   StraddlePosted
// - Irreversible: StartHand (initiator), BlindsPosted (atomic)
// - HandCompleted -> clear stack
// - Pagination: 10 items per page (AppConstants.undoPageSize)

import '../../../resources/constants.dart';

/// A single undoable event in the undo stack.
class UndoableEvent {
  const UndoableEvent({
    required this.eventType,
    required this.payload,
    required this.timestamp,
    required this.description,
  });

  /// Engine event type name (e.g. 'ActionPerformed', 'CardDetected').
  final String eventType;

  /// Full event payload for reverse application.
  final Map<String, dynamic> payload;

  /// When the event was originally applied.
  final DateTime timestamp;

  /// Human-readable description for the undo history UI.
  final String description;
}

/// Undo stack for the current hand.
///
/// Push reversible events as they occur; pop to undo in LIFO order.
/// Irreversible events (StartHand, BlindsPosted) are rejected by [push].
/// Call [clear] on HandCompleted to reset.
class UndoStack {
  final List<UndoableEvent> _stack = [];

  /// Event types that cannot be undone.
  static const _irreversibleTypes = {'StartHand', 'BlindsPosted'};

  /// Whether there are events to undo.
  bool get canUndo => _stack.isNotEmpty;

  /// Number of events in the stack.
  int get length => _stack.length;

  /// Unmodifiable view of all events (oldest first).
  List<UndoableEvent> get all => List.unmodifiable(_stack);

  /// Get paginated view of the stack.
  ///
  /// Page 0 = most recent events (stack top).
  /// Returns up to [pageSize] items (default: [AppConstants.undoPageSize]).
  List<UndoableEvent> getPage(int page,
      {int pageSize = AppConstants.undoPageSize}) {
    if (_stack.isEmpty || page < 0) return [];

    // Reverse order so page 0 = most recent.
    final reversed = _stack.reversed.toList();
    final start = page * pageSize;
    if (start >= reversed.length) return [];
    final end = (start + pageSize).clamp(0, reversed.length);
    return reversed.sublist(start, end);
  }

  /// Total number of pages.
  int get pageCount {
    if (_stack.isEmpty) return 0;
    return (_stack.length / AppConstants.undoPageSize).ceil();
  }

  /// Push a new event onto the stack.
  ///
  /// Returns `false` if the event is irreversible and was rejected.
  bool push(UndoableEvent event) {
    if (_irreversibleTypes.contains(event.eventType)) return false;
    _stack.add(event);
    return true;
  }

  /// Pop the most recent event for undo.
  ///
  /// Returns `null` if the stack is empty.
  UndoableEvent? pop() {
    if (_stack.isEmpty) return null;
    return _stack.removeLast();
  }

  /// Clear the entire stack (called on HandCompleted).
  void clear() => _stack.clear();
}
