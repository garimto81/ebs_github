// lib/foundation/error/error_messenger.dart
//
// Phase 3 — BuildContext 없이 SnackBar/Banner 를 띄울 수 있는 글로벌 채널.
// 인터셉터/Provider 등 비-위젯 레이어에서 사용자에게 즉시 피드백 필요할 때 사용.
//
// 사용:
//   ErrorMessenger.show('네트워크 연결을 확인해 주세요');
//
// app.dart 에서 ScaffoldMessenger 에 [ErrorMessenger.scaffoldMessengerKey] 를
// 부여해야 동작.

import 'package:flutter/material.dart';

class ErrorMessenger {
  ErrorMessenger._();

  /// MaterialApp.scaffoldMessengerKey 에 연결할 글로벌 키.
  static final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  /// 일반 에러 메시지 (SnackBar, 4초).
  static void show(
    String message, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 4),
    Key? key,
  }) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return; // app 부팅 전 호출 등
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          key: key ?? const ValueKey('global-error-snackbar'),
          content: Text(message),
          duration: duration,
          behavior: SnackBarBehavior.floating,
          action: action,
        ),
      );
  }

  /// 강조 배너 (MaterialBanner, dismiss 전까지 유지).
  static void banner(String message, {VoidCallback? onDismiss}) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;
    messenger
      ..clearMaterialBanners()
      ..showMaterialBanner(
        MaterialBanner(
          key: const ValueKey('global-error-banner'),
          content: Text(message),
          actions: [
            TextButton(
              key: const ValueKey('global-error-banner-dismiss'),
              onPressed: () {
                scaffoldMessengerKey.currentState?.hideCurrentMaterialBanner();
                onDismiss?.call();
              },
              child: const Text('확인'),
            ),
          ],
        ),
      );
  }
}
