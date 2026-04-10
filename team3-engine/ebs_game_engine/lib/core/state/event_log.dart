import '../actions/event.dart';
import '../state/game_state.dart';

/// Maintains a log of events applied to a game session.
/// Supports undo by replaying from initial state minus last N events.
class EventLog {
  final GameState _initialState;
  final List<Event> _events = [];

  /// Maximum number of undo steps allowed.
  static const int maxUndoSteps = 5;

  EventLog(this._initialState);

  /// The initial state before any events.
  GameState get initialState => _initialState;

  /// All events in order.
  List<Event> get events => List.unmodifiable(_events);

  /// Number of events recorded.
  int get length => _events.length;

  /// Whether undo is possible (at least 1 event).
  bool get canUndo => _events.isNotEmpty;

  /// Record an event (call after Engine.apply succeeds).
  void record(Event event) {
    _events.add(event);
  }

  /// Remove the last [steps] events. Returns the number actually removed.
  /// Capped at maxUndoSteps and available events.
  int undo(int steps) {
    final actual = steps.clamp(0, _events.length).clamp(0, maxUndoSteps);
    for (var i = 0; i < actual; i++) {
      _events.removeLast();
    }
    return actual;
  }

  /// Clear all recorded events.
  void clear() {
    _events.clear();
  }
}
