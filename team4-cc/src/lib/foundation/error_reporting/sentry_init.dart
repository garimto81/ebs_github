// Sentry initialization (CCR-016 WSOP org standard).
//
// WSOP Fatima.app uses Sentry as the organization-wide error reporting
// standard with Slack integration. Reuse the same pattern here.
// DSN is read from an environment variable (`EBS_SENTRY_DSN`) at build time.

import 'package:sentry_flutter/sentry_flutter.dart';

const _sentryDsn = String.fromEnvironment('EBS_SENTRY_DSN');

Future<void> initSentry({required Future<void> Function() appRunner}) async {
  if (_sentryDsn.isEmpty) {
    // No DSN configured: run app without Sentry (dev mode).
    await appRunner();
    return;
  }

  await SentryFlutter.init(
    (options) {
      options.dsn = _sentryDsn;
      options.tracesSampleRate = 0.1;
      options.environment = const String.fromEnvironment(
        'EBS_ENV',
        defaultValue: 'development',
      );
    },
    appRunner: appRunner,
  );
}
