// In-memory debug log with ring buffer + broadcast stream.
//
// Usage:
//   DebugLog.d('NEW_HAND', 'button pressed', {'activePlayers': 3});
//   DebugLog.w('WS', 'null — falling back to local handFsm');
//
// 프로토타입 진단 도구. UI 표시: [lib/features/debug/debug_log_panel.dart].
// 기능은 최소: 500 entries ring buffer + broadcast. 파일 저장/검색/필터 없음.

import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

enum DebugLogLevel { d, i, w, e }

class DebugLogEntry {
  DebugLogEntry({
    required this.timestamp,
    required this.level,
    required this.category,
    required this.message,
    this.data,
  });

  final DateTime timestamp;
  final DebugLogLevel level;
  final String category;
  final String message;
  final Map<String, dynamic>? data;

  String get levelChar {
    switch (level) {
      case DebugLogLevel.d:
        return 'D';
      case DebugLogLevel.i:
        return 'I';
      case DebugLogLevel.w:
        return 'W';
      case DebugLogLevel.e:
        return 'E';
    }
  }

  String formatTerminal() {
    final ts = timestamp.toIso8601String().substring(11, 23); // HH:mm:ss.SSS
    final dataStr = data == null ? '' : ' $data';
    return '[$ts] [$levelChar] $category: $message$dataStr';
  }
}

class DebugLog {
  DebugLog._();

  static const int _maxEntries = 500;
  static final Queue<DebugLogEntry> _buffer = Queue<DebugLogEntry>();
  static final StreamController<DebugLogEntry> _controller =
      StreamController<DebugLogEntry>.broadcast();

  static Stream<DebugLogEntry> get stream => _controller.stream;

  /// Returns a snapshot (not live) of buffered entries, oldest first.
  static List<DebugLogEntry> snapshot() => List.unmodifiable(_buffer);

  static void clear() {
    _buffer.clear();
  }

  static void _log(
    DebugLogLevel level,
    String category,
    String message, [
    Map<String, dynamic>? data,
  ]) {
    final entry = DebugLogEntry(
      timestamp: DateTime.now(),
      level: level,
      category: category,
      message: message,
      data: data,
    );
    _buffer.addLast(entry);
    if (_buffer.length > _maxEntries) {
      _buffer.removeFirst();
    }
    if (!_controller.isClosed) {
      _controller.add(entry);
    }
    if (kDebugMode) {
      debugPrint(entry.formatTerminal());
    }
  }

  static void d(String category, String message, [Map<String, dynamic>? data]) =>
      _log(DebugLogLevel.d, category, message, data);
  static void i(String category, String message, [Map<String, dynamic>? data]) =>
      _log(DebugLogLevel.i, category, message, data);
  static void w(String category, String message, [Map<String, dynamic>? data]) =>
      _log(DebugLogLevel.w, category, message, data);
  static void e(String category, String message, [Map<String, dynamic>? data]) =>
      _log(DebugLogLevel.e, category, message, data);
}
