import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'foundation/error/error_boundary.dart';
import 'foundation/observability/logger.dart';

void main() {
  // Phase 3 — 모든 비동기/동기 에러를 단일 zone 에서 포착.
  runZonedGuarded<void>(() {
    WidgetsFlutterBinding.ensureInitialized();

    final ProviderContainer container = ProviderContainer();
    final logger = ConsoleLogger(minLevel: kDebugMode ? LogLevel.debug : LogLevel.info);

    // 1) Flutter framework 단계 에러 (build/render/layout)
    FlutterError.onError = (FlutterErrorDetails details) {
      logger.error(
        'FlutterError: ${details.exceptionAsString()}',
        error: details.exception,
        st: details.stack,
        context: {'library': details.library ?? 'unknown'},
      );
      FlutterError.presentError(details);
    };

    // 2) 동기/엔진 단계 에러 (Dart VM, isolate)
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      logger.error('PlatformDispatcher error', error: error, st: stack);
      return true; // handled
    };

    // 3) 빌드 실패 시 표시할 ErrorWidget 커스터마이즈
    ErrorWidget.builder = errorWidgetBuilder;

    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const EbsLobbyApp(),
      ),
    );
  }, (Object error, StackTrace stack) {
    // 4) Zone 단계 에러 (uncaught futures, stream errors)
    // ignore: avoid_print
    if (kDebugMode) print('[ZONE-ERROR] $error\n$stack');
  });
}
