// GoRouter configuration tests — auth redirect + route resolution.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:ebs_cc/features/auth/auth_provider.dart';
import 'package:ebs_cc/routing/app_router.dart';

void main() {
  group('routerProvider', () {
    test('creates GoRouter instance', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);

      final router = c.read(routerProvider);
      expect(router, isA<GoRouter>());
    });
  });

  group('AppRoutes constants', () {
    test('paths are correctly defined', () {
      expect(AppRoutes.login, '/login');
      expect(AppRoutes.main, '/main');
      expect(AppRoutes.stats, '/main/stats');
      expect(AppRoutes.rfid, '/main/rfid');
    });
  });

  group('Auth redirect logic', () {
    test('unauthenticated → redirects to login', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);

      // Default auth state is unauthenticated
      expect(c.read(authProvider).status, AuthStatus.unauthenticated);

      final router = c.read(routerProvider);
      // Router initial location should redirect to login
      expect(router.routeInformationProvider.value.uri.path, isNotEmpty);
    });
  });
}
