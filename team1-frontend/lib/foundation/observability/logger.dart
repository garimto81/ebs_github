// lib/foundation/observability/logger.dart
//
// Phase 3 — Sentry / 원격 로그 수집기 부착을 위한 추상화 레이어.
//
// SSOT: dart:developer + 표준 로그 레벨.
// 향후 Sentry 부착 시 [SentryLogger] 만 구현하고 provider override.

import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

/// 로그 1건의 컨텍스트.
class LogEvent {
  final LogLevel level;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;
  final Map<String, Object?>? context;
  final DateTime timestamp;

  LogEvent({
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
    this.context,
  }) : timestamp = DateTime.now();
}

abstract class AppLogger {
  void log(LogEvent event);

  void debug(String msg, {Map<String, Object?>? context}) =>
      log(LogEvent(level: LogLevel.debug, message: msg, context: context));

  void info(String msg, {Map<String, Object?>? context}) =>
      log(LogEvent(level: LogLevel.info, message: msg, context: context));

  void warning(
    String msg, {
    Object? error,
    StackTrace? st,
    Map<String, Object?>? context,
  }) =>
      log(LogEvent(
        level: LogLevel.warning,
        message: msg,
        error: error,
        stackTrace: st,
        context: context,
      ));

  void error(
    String msg, {
    required Object error,
    StackTrace? st,
    Map<String, Object?>? context,
  }) =>
      log(LogEvent(
        level: LogLevel.error,
        message: msg,
        error: error,
        stackTrace: st,
        context: context,
      ));

  /// 추적 카테고리 / breadcrumb (네비게이션, 네트워크 등).
  /// Sentry 부착 시 Sentry.addBreadcrumb 로 매핑.
  void breadcrumb(String category, String message, {Map<String, Object?>? data});
}

// ---------------------------------------------------------------------------
// Implementations
// ---------------------------------------------------------------------------

/// Release 모드 default — 모든 호출 무시.
class NoopLogger implements AppLogger {
  const NoopLogger();
  @override
  void log(LogEvent event) {}
  @override
  void debug(String msg, {Map<String, Object?>? context}) {}
  @override
  void info(String msg, {Map<String, Object?>? context}) {}
  @override
  void warning(String msg,
      {Object? error, StackTrace? st, Map<String, Object?>? context}) {}
  @override
  void error(String msg,
      {required Object error,
      StackTrace? st,
      Map<String, Object?>? context}) {}
  @override
  void breadcrumb(String category, String message,
      {Map<String, Object?>? data}) {}
}

/// Debug 모드 default — dart:developer 콘솔 출력.
class ConsoleLogger implements AppLogger {
  ConsoleLogger({this.minLevel = LogLevel.debug});

  final LogLevel minLevel;
  final List<String> _breadcrumbs = [];

  @override
  void log(LogEvent event) {
    if (event.level.index < minLevel.index) return;

    final tag = '[${event.level.name.toUpperCase()}]';
    developer.log(
      '$tag ${event.message}',
      name: 'EBS',
      error: event.error,
      stackTrace: event.stackTrace,
      level: _levelToInt(event.level),
    );

    if (event.context != null && event.context!.isNotEmpty) {
      developer.log('  context: ${event.context}', name: 'EBS');
    }
  }

  @override
  void debug(String msg, {Map<String, Object?>? context}) =>
      log(LogEvent(level: LogLevel.debug, message: msg, context: context));
  @override
  void info(String msg, {Map<String, Object?>? context}) =>
      log(LogEvent(level: LogLevel.info, message: msg, context: context));
  @override
  void warning(String msg,
          {Object? error, StackTrace? st, Map<String, Object?>? context}) =>
      log(LogEvent(
          level: LogLevel.warning,
          message: msg,
          error: error,
          stackTrace: st,
          context: context));
  @override
  void error(String msg,
          {required Object error,
          StackTrace? st,
          Map<String, Object?>? context}) =>
      log(LogEvent(
          level: LogLevel.error,
          message: msg,
          error: error,
          stackTrace: st,
          context: context));

  @override
  void breadcrumb(String category, String message,
      {Map<String, Object?>? data}) {
    final crumb = '[$category] $message ${data ?? ''}';
    _breadcrumbs.add(crumb);
    if (_breadcrumbs.length > 50) _breadcrumbs.removeAt(0);
    if (kDebugMode) developer.log('breadcrumb: $crumb', name: 'EBS');
  }

  /// 디버깅 시점에 마지막 N 건 breadcrumb 조회 (Sentry crash report 와 유사).
  List<String> get recentBreadcrumbs => List.unmodifiable(_breadcrumbs);

  static int _levelToInt(LogLevel l) => switch (l) {
        LogLevel.debug => 500,
        LogLevel.info => 800,
        LogLevel.warning => 900,
        LogLevel.error => 1000,
      };
}

/// Sentry 부착 시 이 클래스 본체를 sentry_flutter 호출로 채움.
/// 현재는 ConsoleLogger 위임 stub.
class SentryLoggerStub implements AppLogger {
  SentryLoggerStub({AppLogger? fallback})
      : _fallback = fallback ?? ConsoleLogger();
  final AppLogger _fallback;

  @override
  void log(LogEvent event) {
    // TODO: Sentry.captureMessage / captureException 매핑.
    //   if (event.level == LogLevel.error && event.error != null) {
    //     Sentry.captureException(event.error!, stackTrace: event.stackTrace);
    //   } else {
    //     Sentry.captureMessage(event.message, level: ...);
    //   }
    _fallback.log(event);
  }

  @override
  void debug(String msg, {Map<String, Object?>? context}) =>
      _fallback.debug(msg, context: context);
  @override
  void info(String msg, {Map<String, Object?>? context}) =>
      _fallback.info(msg, context: context);
  @override
  void warning(String msg,
          {Object? error, StackTrace? st, Map<String, Object?>? context}) =>
      _fallback.warning(msg, error: error, st: st, context: context);
  @override
  void error(String msg,
          {required Object error,
          StackTrace? st,
          Map<String, Object?>? context}) =>
      _fallback.error(msg, error: error, st: st, context: context);

  @override
  void breadcrumb(String category, String message,
      {Map<String, Object?>? data}) {
    // TODO: Sentry.addBreadcrumb(Breadcrumb(category: category, message: message, data: data))
    _fallback.breadcrumb(category, message, data: data);
  }
}
