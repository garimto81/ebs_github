// LocalEventBuffer — BO 연결 상실 시 로컬 액션 기록 (CCR-031 BS-05-00 §BO 복구).
//
// 핸드 진행 중 BO WebSocket 연결이 끊기면 CC는 최대 20 이벤트까지 로컬에
// 버퍼링한다. 재연결 시 `ReplayEvents` 프로토콜로 일괄 전송한다.
// 21번째 이벤트는 거부되며 운영자에게 "핸드 Reset 필요" 경고 발생.

import 'dart:collection';

class LocalEvent {
  const LocalEvent({
    required this.type,
    required this.payload,
    required this.localTimestamp,
  });

  final String type;
  final Map<String, dynamic> payload;
  final DateTime localTimestamp;
}

class LocalEventBuffer {
  LocalEventBuffer({this.capacity = 20});

  final int capacity;
  final Queue<LocalEvent> _events = Queue();

  int get length => _events.length;
  bool get isFull => _events.length >= capacity;
  List<LocalEvent> get snapshot => List.unmodifiable(_events);

  /// Append an event. Returns false if the buffer is full.
  bool tryAppend(LocalEvent event) {
    if (isFull) return false;
    _events.add(event);
    return true;
  }

  /// Drain all buffered events (called on successful reconnect).
  List<LocalEvent> drain() {
    final drained = _events.toList(growable: false);
    _events.clear();
    return drained;
  }

  void clear() => _events.clear();
}
