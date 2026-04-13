// ebs_cc entry point
//
// Bootstraps Sentry (CCR-016 WSOP org standard) and Riverpod ProviderScope.
// Command-line args (table_id, token, cc_instance_id, ws_url) are parsed
// per BS-05-00 §Launch 플로우 상세 (CCR-029).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'foundation/error_reporting/sentry_init.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO(CCR-029): parse args for --table_id, --token, --cc_instance_id, --ws_url
  // See BS-05-00-overview §7 Launch 플로우 상세.

  await initSentry(
    appRunner: () async {
      runApp(
        const ProviderScope(
          child: EbsCcApp(),
        ),
      );
    },
  );
}
