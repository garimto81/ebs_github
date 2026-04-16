import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'foundation/router/app_router.dart';
import 'foundation/theme/ebs_lobby_theme.dart';
import 'resources/l10n/app_localizations.dart';

class EbsLobbyApp extends ConsumerWidget {
  const EbsLobbyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'EBS Lobby',
      debugShowCheckedModeBanner: false,
      theme: EbsLobbyTheme.darkTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
