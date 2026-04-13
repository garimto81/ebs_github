// DualOutputManager — manages Backstage (instant) and Broadcast (delayed) streams.
// See BS-07-07-security-delay.md §원리 (CCR-036).

import 'output_event_buffer.dart';

class DualOutputManager {
  DualOutputManager({required OutputEventBuffer buffer}) : _buffer = buffer;

  final OutputEventBuffer _buffer;

  /// Emit to Backstage immediately AND enqueue to Broadcast buffer.
  void emit(String type, Map<String, dynamic> payload) {
    // TODO(Phase C): push to backstage NDI/HDMI output
    _buffer.enqueue(type, payload);
  }

  /// Flush ready events from buffer to Broadcast output.
  /// Called by a periodic timer (e.g. 50ms tick).
  void tickBroadcast() {
    final ready = _buffer.drainReady();
    for (final _ in ready) {
      // TODO(Phase C): push to broadcast NDI/HDMI output
    }
  }
}
