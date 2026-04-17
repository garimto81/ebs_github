// AuthNotifier unit tests — login, 2FA, logout, RBAC permission checks.

import 'package:ebs_common/ebs_common.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ebs_lobby/features/auth/auth_provider.dart';
import 'package:ebs_lobby/models/models.dart';
import 'package:ebs_lobby/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late ProviderContainer container;
  late MockAuthRepository mockRepo;

  const testUser = SessionUser(
    userId: 1,
    email: 'op@ebs.test',
    displayName: 'Operator',
    role: 'operator',
    permissions: {'series': 3, 'tables': 7}, // read+write / read+write+delete
    tableIds: [10, 20],
  );

  const adminUser = SessionUser(
    userId: 2,
    email: 'admin@ebs.test',
    displayName: 'Admin',
    role: 'admin',
    permissions: {},
    tableIds: [],
  );

  const sessionResponse = SessionResponse(user: testUser);
  const adminSessionResponse = SessionResponse(user: adminUser);

  setUp(() {
    mockRepo = MockAuthRepository();
    container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(mockRepo),
    ]);
  });

  tearDown(() => container.dispose());

  // -------------------------------------------------------------------------
  // login
  // -------------------------------------------------------------------------

  group('login', () {
    test('successful login sets authenticated state', () async {
      when(() => mockRepo.login('op@ebs.test', 'pass123'))
          .thenAnswer((_) async => const TokenResponse(accessToken: 'jwt-tok'));
      when(() => mockRepo.getSession())
          .thenAnswer((_) async => sessionResponse);

      final notifier = container.read(authProvider.notifier);
      final result = await notifier.login('op@ebs.test', 'pass123');

      expect(result.success, isTrue);
      final state = container.read(authProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.accessToken, 'jwt-tok');
      expect(state.user?.email, 'op@ebs.test');
      expect(state.permissions?['series'], 3);
    });

    test('2FA required sets tempToken and stays anonymous', () async {
      when(() => mockRepo.login('op@ebs.test', 'pass123')).thenAnswer(
        (_) async => const TokenResponse(
          requires2fa: true,
          tempToken: 'temp-2fa-tok',
        ),
      );

      final notifier = container.read(authProvider.notifier);
      final result = await notifier.login('op@ebs.test', 'pass123');

      expect(result.success, isFalse);
      expect(result.requires2fa, isTrue);
      expect(result.tempToken, 'temp-2fa-tok');
      final state = container.read(authProvider);
      expect(state.status, AuthStatus.anonymous);
      expect(state.tempToken, 'temp-2fa-tok');
      expect(state.accessToken, isNull);
    });

    test('failed login sets error state', () async {
      when(() => mockRepo.login('bad@ebs.test', 'wrong')).thenThrow(
        const ApiError(code: 'AUTH_FAILED', message: 'Invalid credentials'),
      );

      final notifier = container.read(authProvider.notifier);
      final result = await notifier.login('bad@ebs.test', 'wrong');

      expect(result.success, isFalse);
      expect(result.errorCode, 'AUTH_FAILED');
      expect(result.errorMessage, 'Invalid credentials');
      final state = container.read(authProvider);
      expect(state.status, AuthStatus.error);
      expect(state.error, 'Invalid credentials');
    });
  });

  // -------------------------------------------------------------------------
  // verify2fa
  // -------------------------------------------------------------------------

  group('verify2fa', () {
    test('valid code completes authentication', () async {
      // First get into 2FA pending state.
      when(() => mockRepo.login('op@ebs.test', 'pass123')).thenAnswer(
        (_) async => const TokenResponse(
          requires2fa: true,
          tempToken: 'temp-2fa-tok',
        ),
      );
      final notifier = container.read(authProvider.notifier);
      await notifier.login('op@ebs.test', 'pass123');

      // Now verify.
      when(() => mockRepo.verify2fa('temp-2fa-tok', '123456'))
          .thenAnswer((_) async => const TokenResponse(accessToken: 'jwt-2fa'));
      when(() => mockRepo.getSession())
          .thenAnswer((_) async => sessionResponse);

      final result = await notifier.verify2fa('123456');

      expect(result.success, isTrue);
      final state = container.read(authProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.accessToken, 'jwt-2fa');
      expect(state.tempToken, isNull);
    });

    test('invalid code sets error, preserves tempToken for retry', () async {
      // Get into 2FA pending state.
      when(() => mockRepo.login('op@ebs.test', 'pass123')).thenAnswer(
        (_) async => const TokenResponse(
          requires2fa: true,
          tempToken: 'temp-2fa-tok',
        ),
      );
      final notifier = container.read(authProvider.notifier);
      await notifier.login('op@ebs.test', 'pass123');

      when(() => mockRepo.verify2fa('temp-2fa-tok', '000000')).thenThrow(
        const ApiError(code: 'INVALID_TOTP', message: 'Invalid code'),
      );

      final result = await notifier.verify2fa('000000');

      expect(result.success, isFalse);
      expect(result.errorMessage, 'Invalid code');
      final state = container.read(authProvider);
      expect(state.status, AuthStatus.error);
      // tempToken preserved so user can retry.
      expect(state.tempToken, 'temp-2fa-tok');
    });

    test('returns failure when no pending 2FA session', () async {
      final notifier = container.read(authProvider.notifier);
      final result = await notifier.verify2fa('123456');

      expect(result.success, isFalse);
      expect(result.errorMessage, 'No pending 2FA session');
    });
  });

  // -------------------------------------------------------------------------
  // hasPermission (RBAC)
  // -------------------------------------------------------------------------

  group('hasPermission', () {
    test('delegates to Permission.checkResource', () async {
      when(() => mockRepo.login('op@ebs.test', 'pass123'))
          .thenAnswer((_) async => const TokenResponse(accessToken: 'jwt'));
      when(() => mockRepo.getSession())
          .thenAnswer((_) async => sessionResponse);

      final notifier = container.read(authProvider.notifier);
      await notifier.login('op@ebs.test', 'pass123');

      // series has bits 3 (read=1 + write=2).
      expect(notifier.hasPermission('series', PermissionAction.read), isTrue);
      expect(notifier.hasPermission('series', PermissionAction.write), isTrue);
      expect(
          notifier.hasPermission('series', PermissionAction.delete_), isFalse);

      // tables has bits 7 (read+write+delete).
      expect(
          notifier.hasPermission('tables', PermissionAction.delete_), isTrue);

      // Unknown resource.
      expect(
          notifier.hasPermission('unknown', PermissionAction.read), isFalse);
    });

    test('returns false when not authenticated', () {
      final notifier = container.read(authProvider.notifier);
      expect(notifier.hasPermission('series', PermissionAction.read), isFalse);
    });

    test('admin bypasses permission checks', () async {
      when(() => mockRepo.login('admin@ebs.test', 'pass'))
          .thenAnswer((_) async => const TokenResponse(accessToken: 'jwt-a'));
      when(() => mockRepo.getSession())
          .thenAnswer((_) async => adminSessionResponse);

      final notifier = container.read(authProvider.notifier);
      await notifier.login('admin@ebs.test', 'pass');

      // Admin has empty permissions map but role='admin' should bypass.
      expect(
          notifier.hasPermission('anything', PermissionAction.delete_), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // logout
  // -------------------------------------------------------------------------

  group('logout', () {
    test('resets to anonymous state', () async {
      // First authenticate.
      when(() => mockRepo.login('op@ebs.test', 'pass123'))
          .thenAnswer((_) async => const TokenResponse(accessToken: 'jwt'));
      when(() => mockRepo.getSession())
          .thenAnswer((_) async => sessionResponse);
      when(() => mockRepo.logout()).thenAnswer((_) async {});

      final notifier = container.read(authProvider.notifier);
      await notifier.login('op@ebs.test', 'pass123');
      expect(container.read(authProvider).status, AuthStatus.authenticated);

      await notifier.logout();
      final state = container.read(authProvider);
      expect(state.status, AuthStatus.anonymous);
      expect(state.accessToken, isNull);
      expect(state.user, isNull);
      expect(state.permissions, isNull);
    });

    test('clears state even when server call fails', () async {
      when(() => mockRepo.login('op@ebs.test', 'pass123'))
          .thenAnswer((_) async => const TokenResponse(accessToken: 'jwt'));
      when(() => mockRepo.getSession())
          .thenAnswer((_) async => sessionResponse);
      when(() => mockRepo.logout()).thenThrow(
        const ApiError(code: 'NETWORK', message: 'Server unreachable'),
      );

      final notifier = container.read(authProvider.notifier);
      await notifier.login('op@ebs.test', 'pass123');
      await notifier.logout();

      final state = container.read(authProvider);
      expect(state.status, AuthStatus.anonymous);
      expect(state.accessToken, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // tryRestoreSession
  // -------------------------------------------------------------------------

  group('tryRestoreSession', () {
    test('restores session from refresh token', () async {
      when(() => mockRepo.refreshToken())
          .thenAnswer((_) async => const TokenResponse(accessToken: 'fresh'));
      when(() => mockRepo.getSession())
          .thenAnswer((_) async => sessionResponse);

      final notifier = container.read(authProvider.notifier);
      final restored = await notifier.tryRestoreSession();

      expect(restored, isTrue);
      final state = container.read(authProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.accessToken, 'fresh');
    });

    test('resets to anonymous when refresh fails', () async {
      when(() => mockRepo.refreshToken()).thenThrow(
        const ApiError(code: 'EXPIRED', message: 'Refresh token expired'),
      );

      final notifier = container.read(authProvider.notifier);
      final restored = await notifier.tryRestoreSession();

      expect(restored, isFalse);
      expect(container.read(authProvider).status, AuthStatus.anonymous);
    });
  });
}
