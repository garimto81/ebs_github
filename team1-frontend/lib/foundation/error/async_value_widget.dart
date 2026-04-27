// lib/foundation/error/async_value_widget.dart
//
// Phase 3 — AsyncValue<T> 의 loading/error/data 분기를 표준화한 wrapper.
//
// 사용:
//   ref.watch(seriesProvider).widget(
//     data: (list) => SeriesList(list),
//   );
//
// 또는 직접:
//   AsyncValueWidget<List<Series>>(
//     value: ref.watch(seriesProvider),
//     data: (list) => SeriesList(list),
//   );

import 'package:ebs_common/ebs_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/error_banner.dart';
import '../widgets/loading_state.dart';

/// 위젯 트리에서 사용할 표준 키 (E2E 에서 hook).
class AsyncWidgetKeys {
  AsyncWidgetKeys._();

  static const loading = ValueKey('async-loading');
  static const error = ValueKey('async-error');
  static const errorRetry = ValueKey('async-error-retry');
}

class AsyncValueWidget<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) data;

  /// 커스텀 loading. 미제공 시 기본 LoadingState.
  final Widget? loading;

  /// 커스텀 error. 미제공 시 ErrorBanner + 재시도 버튼.
  final Widget Function(Object error, StackTrace? stack, VoidCallback? retry)?
      error;

  /// 재시도 콜백 (보통 ref.invalidate(provider)).
  final VoidCallback? onRetry;

  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.data,
    this.loading,
    this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      data: data,
      loading: () =>
          loading ?? const LoadingState(key: AsyncWidgetKeys.loading),
      error: (e, st) =>
          error?.call(e, st, onRetry) ??
          _DefaultError(error: e, retry: onRetry),
    );
  }
}

class _DefaultError extends StatelessWidget {
  final Object error;
  final VoidCallback? retry;
  const _DefaultError({required this.error, this.retry});

  @override
  Widget build(BuildContext context) {
    final msg = error is ApiError
        ? (error as ApiError).message
        : error.toString();

    return Center(
      key: AsyncWidgetKeys.error,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ErrorBanner(message: msg),
            if (retry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: AsyncWidgetKeys.errorRetry,
                onPressed: retry,
                icon: const Icon(Icons.refresh),
                label: const Text('다시 시도'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Extension — 호출 측 코드를 한 줄로 줄인다.
// ---------------------------------------------------------------------------

extension AsyncValueX<T> on AsyncValue<T> {
  /// `ref.watch(p).widget(data: (v) => ...)` 형태로 사용.
  Widget widget({
    required Widget Function(T data) data,
    Widget? loading,
    Widget Function(Object error, StackTrace? stack, VoidCallback? retry)?
        error,
    VoidCallback? onRetry,
    Key? key,
  }) {
    return AsyncValueWidget<T>(
      key: key,
      value: this,
      data: data,
      loading: loading,
      error: error,
      onRetry: onRetry,
    );
  }

  /// 비-위젯 컨텍스트(이벤트 핸들러 등)에서 에러를 SnackBar 로 노출.
  void showErrorIfPresent(
    BuildContext context, {
    String? prefix,
  }) {
    whenOrNull(
      error: (e, _) {
        final msg = e is ApiError ? e.message : e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            key: const ValueKey('async-snackbar-error'),
            content: Text(prefix != null ? '$prefix: $msg' : msg),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }
}
