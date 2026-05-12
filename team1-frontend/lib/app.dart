import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/remote/bo_api_client.dart' show appConfigProvider;
import 'features/lobby/widgets/hand_demo_overlay.dart';
import 'foundation/bootstrap_provider.dart';
import 'foundation/error/error_messenger.dart';
import 'foundation/router/app_router.dart';
import 'foundation/theme/ebs_lobby_theme.dart';
import 'resources/l10n/app_localizations.dart';

class EbsLobbyApp extends ConsumerWidget {
  const EbsLobbyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Phase 2 + 3 — 부팅 wiring 트리거 (G-3 + G-4 + logger).
    ref.watch(bootstrapProvider);

    final appCfg = ref.watch(appConfigProvider);
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'EBS Lobby',
      debugShowCheckedModeBanner: false,
      theme: EbsLobbyTheme.darkTheme,
      // Phase 3 — 비-위젯 레이어에서 SnackBar/Banner 토출 가능하도록 글로벌 키 부착.
      scaffoldMessengerKey: ErrorMessenger.scaffoldMessengerKey,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
      // Cycle 6 (#312) — overlay HUD when HAND_AUTO_SETUP=true.
      // Renders above every route incl. login screen so demo evidence
      // capture works even with backend unreachable (Cycle 4 partial).
      builder: appCfg.handAutoSetup
          ? (context, child) => Stack(
                children: [
                  if (child != null) child,
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(child: HandDemoOverlay()),
                  ),
                ],
              )
          : null,
    );
  }
}
