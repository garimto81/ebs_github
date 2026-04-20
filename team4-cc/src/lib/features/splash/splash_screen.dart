// SG-002 Splash screen — initial engine-connection boot UI.
//
// Shown while EngineConnectionState.stage == connecting. Transitions to
// /main automatically when the stage advances to online / degraded /
// offline (the banner takes over afterwards).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../routing/app_router.dart';
import '../command_center/providers/engine_connection_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Kick off probe if still in the initial connecting state.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = ref.read(engineConnectionProvider.notifier);
      final state = ref.read(engineConnectionProvider);
      if (state.stage == EngineConnectionStage.connecting &&
          state.attemptCount == 0) {
        ctrl.probeAndConnect();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // When stage leaves "connecting" — navigate to main. Banner + stub
    // engine take over from there.
    ref.listen<EngineConnectionState>(engineConnectionProvider,
        (prev, next) {
      if (prev?.stage == EngineConnectionStage.connecting &&
          next.stage != EngineConnectionStage.connecting) {
        if (mounted) {
          context.go(AppRoutes.main);
        }
      }
    });

    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.casino_rounded,
                size: 72, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text('EBS Command Center',
                style: theme.textTheme.headlineSmall),
            const SizedBox(height: 32),
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 24),
            Text('엔진 연결 중...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
          ],
        ),
      ),
    );
  }
}
