// lib/foundation/error/error_boundary.dart
//
// Phase 3 — UI 빌드 실패 시 앱 크래시를 차단하는 ErrorWidget 커스터마이즈.
// E2E 테스트(Phase 4)에서 화면 식별이 가능하도록 ValueKey 를 명시한다.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// E2E 테스트가 hook 할 수 있는 표준 키들.
class ErrorBoundaryKeys {
  ErrorBoundaryKeys._();

  static const root = ValueKey('error-boundary-root');
  static const title = ValueKey('error-boundary-title');
  static const detail = ValueKey('error-boundary-detail');
  static const reloadButton = ValueKey('error-boundary-reload');
}

/// `ErrorWidget.builder` 에 등록하는 커스텀 빌더.
///
/// Debug 모드: 스택트레이스 + 메시지 노출
/// Release 모드: 일반 안내 + 재시도 버튼만 노출 (sensitive info 차단)
Widget errorWidgetBuilder(FlutterErrorDetails details) {
  return _ErrorBoundaryFallback(details: details);
}

class _ErrorBoundaryFallback extends StatelessWidget {
  final FlutterErrorDetails details;
  const _ErrorBoundaryFallback({required this.details});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      key: ErrorBoundaryKeys.root,
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text(
                '화면 표시 중 오류가 발생했습니다',
                key: ErrorBoundaryKeys.title,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              if (kDebugMode)
                Expanded(
                  child: SingleChildScrollView(
                    child: SelectableText(
                      '${details.exceptionAsString()}\n\n${details.stack}',
                      key: ErrorBoundaryKeys.detail,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                )
              else
                Text(
                  '잠시 후 다시 시도해 주세요. 문제가 계속되면 운영팀에 문의해 주세요.',
                  key: ErrorBoundaryKeys.detail,
                  style: theme.textTheme.bodyMedium,
                ),
              const SizedBox(height: 16),
              FilledButton.icon(
                key: ErrorBoundaryKeys.reloadButton,
                onPressed: () {
                  // 스킨 리빌드 — `ErrorWidget` 가 표시될 때 부모는 이미 build
                  // 실패 상태이므로 가장 안전한 회복은 root 위젯의 markNeedsBuild.
                  // 화면 단위 재시도는 화면 측 ErrorBanner 가 담당.
                  WidgetsBinding.instance.scheduleForcedFrame();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
