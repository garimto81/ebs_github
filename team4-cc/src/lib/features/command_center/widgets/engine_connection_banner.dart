// SG-002 Engine Connection Banner (3-stage).
//
// Rendered at the top of the Command Center scaffold. Visible only when the
// engine is Degraded (warning colour) or Offline (error colour). Offline
// stage exposes a manual "재연결" action that re-triggers probeAndConnect.
//
// Connecting/Online stages return SizedBox.shrink() so the banner has zero
// layout impact on normal operation.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/engine_connection_provider.dart';

class EngineConnectionBanner extends ConsumerWidget {
  const EngineConnectionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(engineConnectionProvider);
    if (state.stage == EngineConnectionStage.online ||
        state.stage == EngineConnectionStage.connecting) {
      return const SizedBox.shrink();
    }
    final isOffline = state.stage == EngineConnectionStage.offline;
    return Material(
      color: isOffline ? Colors.red.shade700 : Colors.orange.shade700,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.warning_amber, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isOffline
                      ? 'ENGINE_URL 확인 필요 — Demo Mode 유지'
                      : '엔진 응답 없음 — 로컬 Mock 모드로 전환',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              if (isOffline)
                TextButton(
                  onPressed: () => ref
                      .read(engineConnectionProvider.notifier)
                      .manualReconnect(),
                  style: TextButton.styleFrom(
                      foregroundColor: Colors.white),
                  child: const Text('재연결'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
