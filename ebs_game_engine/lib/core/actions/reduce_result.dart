import '../state/game_state.dart';
import 'output_event.dart';

/// Result of Engine.applyFull() -- contains new state plus output events.
class ReduceResult {
  final GameState state;
  final List<OutputEvent> outputs;

  const ReduceResult({required this.state, this.outputs = const []});

  /// Convenience: create with single output event.
  factory ReduceResult.withEvent(GameState state, OutputEvent event) {
    return ReduceResult(state: state, outputs: [event]);
  }

  /// Convenience: create with multiple output events.
  factory ReduceResult.withEvents(GameState state, List<OutputEvent> events) {
    return ReduceResult(state: state, outputs: events);
  }
}
