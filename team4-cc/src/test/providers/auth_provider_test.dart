// AuthNotifier — JWT decode, auth lifecycle, logout.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebs_cc/features/auth/auth_provider.dart';
import 'package:ebs_cc/models/launch_config.dart';

/// Build a fake JWT with the given claims payload.
String _fakeJwt(Map<String, dynamic> claims) {
  final header = base64Url.encode(utf8.encode('{"alg":"HS256"}'));
  final payload = base64Url.encode(utf8.encode(jsonEncode(claims)));
  return '$header.$payload.fake-signature';
}

LaunchConfig _config({String? token}) => LaunchConfig(
      tableId: 1,
      token: token ?? _fakeJwt({'role': 'Operator', 'assigned_tables': [1, 2]}),
      ccInstanceId: 'test-uuid',
      wsUrl: 'ws://localhost/ws/cc',
    );

void main() {
  late ProviderContainer c;

  setUp(() => c = ProviderContainer());
  tearDown(() => c.dispose());

  group('AuthNotifier.authenticate', () {
    test('valid JWT → authenticated with role and tables', () async {
      await c.read(authProvider.notifier).authenticate(_config());

      final s = c.read(authProvider);
      expect(s.status, AuthStatus.authenticated);
      expect(s.role, 'Operator');
      expect(s.assignedTables, [1, 2]);
    });

    test('JWT without optional claims → authenticated, role null', () async {
      final token = _fakeJwt({});
      await c.read(authProvider.notifier).authenticate(_config(token: token));

      final s = c.read(authProvider);
      expect(s.status, AuthStatus.authenticated);
      expect(s.role, isNull);
      expect(s.assignedTables, isNull);
    });

    test('malformed JWT (not 3 parts) → error', () async {
      await c
          .read(authProvider.notifier)
          .authenticate(_config(token: 'bad-token'));

      final s = c.read(authProvider);
      expect(s.status, AuthStatus.error);
      expect(s.errorMessage, contains('Token decode failed'));
    });

    test('authenticating state is set before decode', () async {
      // Capture intermediate state via listener.
      AuthStatus? intermediate;
      c.listen<AuthState>(authProvider, (prev, next) {
        if (next.status == AuthStatus.authenticating) {
          intermediate = next.status;
        }
      });

      await c.read(authProvider.notifier).authenticate(_config());
      expect(intermediate, AuthStatus.authenticating);
    });
  });

  group('AuthNotifier.logout', () {
    test('resets to unauthenticated', () async {
      await c.read(authProvider.notifier).authenticate(_config());
      expect(c.read(authProvider).status, AuthStatus.authenticated);

      c.read(authProvider.notifier).logout();
      expect(c.read(authProvider).status, AuthStatus.unauthenticated);
      expect(c.read(authProvider).config, isNull);
    });
  });

  group('AuthState copyWith (Freezed)', () {
    test('default state is unauthenticated', () {
      const s = AuthState();
      expect(s.status, AuthStatus.unauthenticated);
      expect(s.config, isNull);
      expect(s.errorMessage, isNull);
    });

    test('copyWith preserves unchanged fields', () {
      const s = AuthState(status: AuthStatus.authenticated, role: 'Admin');
      final s2 = s.copyWith(errorMessage: 'test');
      expect(s2.status, AuthStatus.authenticated);
      expect(s2.role, 'Admin');
      expect(s2.errorMessage, 'test');
    });
  });
}
