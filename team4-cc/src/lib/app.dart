// Root widget for ebs_cc.
//
// Uses GoRouter for declarative routing with auth redirect.
// Routes defined in routing/app_router.dart.
//
// Modals (shown as Dialog, not route):
//   settings      → AT-06 Game Settings Modal
//   player-edit   → AT-07 Player Edit Modal

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/command_center/screens/at_06_game_settings_modal.dart';
import 'features/command_center/screens/at_07_player_edit_modal.dart';
import 'routing/app_router.dart';

// Re-export AppRoutes for backward compatibility.
export 'routing/app_router.dart' show AppRoutes;

// ---------------------------------------------------------------------------
// App Widget
// ---------------------------------------------------------------------------

class EbsCcApp extends ConsumerWidget {
  const EbsCcApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'EBS CC',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      routerConfig: router,
    );
  }
}

// ---------------------------------------------------------------------------
// Navigation helper (static, usable from any widget)
// ---------------------------------------------------------------------------

class AppNavigator {
  AppNavigator._();

  /// Navigate to a route (replaces current history entry).
  static void go(BuildContext context, String location) {
    context.go(location);
  }

  /// Push a route onto the navigation stack.
  static void push(BuildContext context, String location) {
    context.push(location);
  }

  /// Pop the current route.
  static void pop(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    }
  }

  /// Show Game Settings modal (AT-06).
  static Future<void> showSettingsModal(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const At06GameSettingsModal(),
    );
  }

  /// Show Player Edit modal (AT-07).
  ///
  /// [seatNo] is 1-based seat number.
  static Future<void> showPlayerEditModal(
    BuildContext context, {
    required int seatNo,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => At07PlayerEditModal(seatNo: seatNo),
    );
  }
}
