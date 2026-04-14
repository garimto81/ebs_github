// ebs_cc entry point
//
// Bootstraps Sentry (CCR-016 WSOP org standard) and Riverpod ProviderScope.
// Command-line args (table_id, token, cc_instance_id, ws_url) are parsed
// per BS-05-00 §Launch 플로우 상세 (CCR-029).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'features/auth/auth_provider.dart';
import 'foundation/error_reporting/sentry_init.dart';
import 'models/launch_config.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Parse launch args (BS-05-00 §7 Launch Flow, CCR-029).
  // Lobby passes --table_id, --token, --cc_instance_id, --ws_url.
  final config = LaunchConfig.tryFromArgs(args);

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
    },
  );
}
