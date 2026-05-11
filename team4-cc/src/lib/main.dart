// ebs_cc entry point
//
// Bootstraps Sentry (CCR-016 WSOP org standard) and Riverpod ProviderScope.
// Launch identity (table_id, token, cc_instance_id, ws_url) sources:
//   - Desktop: command-line args (--table_id=1 ...)
//   - Web (SG-008-b11 v1.3): URL query (?table_id=1&token=...) via Uri.base
//
// per BS-05-00 §Launch 플로우 상세 (CCR-029).

import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'auto_demo.dart';
import 'features/auth/auth_provider.dart';
import 'foundation/configs/features.dart';
import 'foundation/error_reporting/sentry_init.dart';
import 'foundation/logging/debug_log.dart';
import 'models/launch_config.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Parse launch identity (BS-05-00 §7 Launch Flow, CCR-029, SG-008-b11 v1.3).
  // Desktop CLI args first; if empty AND web → fall back to URL query.
  LaunchConfig? config = LaunchConfig.tryFromArgs(args);
  if (config == null && kIsWeb) {
    // Uri.base on Flutter Web returns the page URL (works without dart:html).
    final query = Uri.base.queryParameters;
    if (query.isNotEmpty) {
      config = LaunchConfig.tryFromQuery(query);
    }
  }

  if (config?.demoMode == true) {
    Features.enableDemoMode = true;
  }

  // Boot diagnostic — visible via Ctrl+L debug panel.
  DebugLog.i('BOOT', 'ebs_cc starting', {
    'args': args,
    'webQuery': kIsWeb ? Uri.base.queryParameters.keys.toList() : 'n/a',
    'launchConfig': config == null
        ? 'null (dev standalone — no Lobby args/query)'
        : 'parsed (tableId=${config.tableId}, demo=${config.demoMode})',
  });

  await initSentry(
    appRunner: () async {
      runApp(
        ProviderScope(
          overrides: [
            if (config != null)
              launchConfigProvider.overrideWithValue(config),
          ],
          child: const EbsCcApp(),
        ),
      );

      // Cycle 2 Issue #237 — AUTO_DEMO 1-hand wire hook.
      // CC standalone에서 ADMIN_TOKEN + AUTO_DEMO=true 시 BO launch-cc →
      // WS connect → WriteGameInfo (CCR-024) → GameInfoAck e2e 시연.
      // 시연 결과는 console + DebugLog (Ctrl+L)로 노출.
      const autoDemo = bool.fromEnvironment('AUTO_DEMO', defaultValue: false);
      const adminToken = String.fromEnvironment('ADMIN_TOKEN', defaultValue: '');
      if (autoDemo && adminToken.isNotEmpty) {
        const tableId = int.fromEnvironment('AUTO_DEMO_TABLE_ID', defaultValue: 1);
        const boUrl =
            String.fromEnvironment('BO_URL', defaultValue: 'http://localhost:8000');
        // Fire-and-forget — UI는 정상 표시. 결과는 DebugLog에 누적.
        unawaited(runAutoDemo(
          adminToken: adminToken,
          tableId: tableId,
          boBaseUrl: boUrl,
          onReady: (handId) {
            DebugLog.i('AUTO_DEMO', 'cascade:cc-hand-ready candidate', {
              'hand_id': handId,
              'table_id': tableId,
            });
          },
          onError: (e, _) {
            DebugLog.e('AUTO_DEMO', 'wire failed', {'error': '$e'});
          },
        ));
      }
    },
  );
}
