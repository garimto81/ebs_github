// lib/foundation/observability/logger_provider.dart
//
// Phase 3 — AppLogger 의 Riverpod 진입점.
//
// 운영 환경에서 Sentry 활성화 시:
//   ProviderScope(overrides: [
//     appLoggerProvider.overrideWithValue(SentryLoggerStub(...)),
//   ])

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'logger.dart';

/// 글로벌 logger.
/// - debug build → ConsoleLogger
/// - release build → NoopLogger (override 없을 시; SentryLogger 권장)
final appLoggerProvider = Provider<AppLogger>((ref) {
  if (kDebugMode) return ConsoleLogger();
  return const NoopLogger();
});
