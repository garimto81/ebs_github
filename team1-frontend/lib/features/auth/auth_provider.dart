// Auth state management — Riverpod StateNotifier.
//
// Ported from _archive-quasar/src/stores/authStore.ts (171 LOC).
// Manages JWT-based login, 2FA, session restore, and RBAC permission checks.

import 'dart:convert';

import 'package:ebs_common/ebs_common.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/models.dart';
import '../../repositories/auth_repository.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

enum AuthStatus { anonymous, authenticating, authenticated, error }

class AuthState {
  const AuthState({
    this.status = AuthStatus.anonymous,
    this.user,
    this.accessToken,
    this.refreshToken,
    this.tempToken,
    this.permissions,
    this.error,
  });

  final AuthStatus status;
  final SessionUser? user;
  final String? accessToken;
  final String? refreshToken;
  final String? tempToken;
  final Map<String, int>? permissions;
  final String? error;

  AuthState copyWith({
    AuthStatus? status,
    SessionUser? user,
    String? accessToken,
    String? refreshToken,
    String? tempToken,
    Map<String, int>? permissions,
    String? error,
    bool clearUser = false,
    bool clearAccessToken = false,
    bool clearRefreshToken = false,
    bool clearTempToken = false,
    bool clearPermissions = false,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      accessToken:
          clearAccessToken ? null : (accessToken ?? this.accessToken),
      refreshToken:
          clearRefreshToken ? null : (refreshToken ?? this.refreshToken),
      tempToken: clearTempToken ? null : (tempToken ?? this.tempToken),
      permissions:
          clearPermissions ? null : (permissions ?? this.permissions),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// Login result
// ---------------------------------------------------------------------------

class LoginResult {
  const LoginResult({
    required this.success,
    this.requires2fa = false,
    this.tempToken,
    this.errorCode,
    this.errorMessage,
  });

  final bool success;
  final bool requires2fa;
  final String? tempToken;
  final String? errorCode;
  final String? errorMessage;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo) : super(const AuthState());

  final AuthRepository _repo;

  // -- Login ---------------------------------------------------------------

  Future<LoginResult> login(String email, String password) async {
    state = state.copyWith(
      status: AuthStatus.authenticating,
      clearError: true,
    );
    try {
      final res = await _repo.login(email, password);

      if (res.requires2fa) {
        state = state.copyWith(
          status: AuthStatus.anonymous,
          tempToken: res.tempToken,
        );
        return LoginResult(
          success: false,
          requires2fa: true,
          tempToken: res.tempToken,
        );
      }

      state = state.copyWith(
        accessToken: res.accessToken,
        refreshToken: res.refreshToken,
      );
      _repo.setToken(res.accessToken);        // ← Dio interceptor가 Bearer 헤더 붙이도록
      await _loadSession();
      state = state.copyWith(status: AuthStatus.authenticated);
      return const LoginResult(success: true);
    } catch (e) {
      final msg = e is ApiError ? e.message : e.toString();
      final code = e is ApiError ? e.code : null;
      state = state.copyWith(status: AuthStatus.error, error: msg);
      return LoginResult(
        success: false,
        errorCode: code,
        errorMessage: msg,
      );
    }
  }

  // -- 2FA -----------------------------------------------------------------

  Future<LoginResult> verify2fa(String code) async {
    final temp = state.tempToken;
    if (temp == null) {
      return const LoginResult(
        success: false,
        errorMessage: 'No pending 2FA session',
      );
    }
    state = state.copyWith(status: AuthStatus.authenticating);
    try {
      final res = await _repo.verify2fa(temp, code);
      state = state.copyWith(
        accessToken: res.accessToken,
        clearTempToken: true,
      );
      _repo.setToken(res.accessToken);
      await _loadSession();
      state = state.copyWith(status: AuthStatus.authenticated);
      return const LoginResult(success: true);
    } catch (e) {
      final msg = e is ApiError ? e.message : e.toString();
      state = state.copyWith(status: AuthStatus.error, error: msg);
      return LoginResult(success: false, errorMessage: msg);
    }
  }

  // -- Session -------------------------------------------------------------

  Future<void> _loadSession() async {
    final session = await _repo.getSession();
    state = state.copyWith(
      user: session.user,
      permissions: session.user.permissions,
    );
  }

  /// Decode JWT payload to extract user info without server call.
  void loadSessionFromToken() {
    final token = state.accessToken;
    if (token == null) return;
    try {
      final claims = _decodeJwtPayload(token);
      final role = claims['role'] as String?;
      final perms = claims['permissions'];
      if (perms is Map) {
        state = state.copyWith(
          permissions: perms.map(
            (key, value) => MapEntry(key.toString(), value as int),
          ),
        );
      }
      if (role != null && state.user != null) {
        // Role from token takes precedence if different.
      }
    } catch (_) {
      // Token decode is best-effort; server validates on API calls.
    }
  }

  /// Attempt to restore a session using a previously stored refresh token.
  /// Called on app boot and on 401 responses.
  ///
  /// 현재 refresh_token은 인메모리 state에만 저장되므로 페이지 새로고침 후에는 null.
  /// null이면 /auth/refresh 호출을 skip하여 422 console noise 제거.
  /// (TODO: localStorage persistence는 별도 이슈)
  Future<bool> tryRestoreSession() async {
    final storedRefresh = state.refreshToken;
    if (storedRefresh == null || storedRefresh.isEmpty) {
      // 저장된 refresh token 없음 → refresh 호출 skip, 조용히 anonymous 상태.
      _repo.setToken(null);
      state = const AuthState();
      return false;
    }
    try {
      final res = await _repo.refreshToken(refreshToken: storedRefresh);
      if (res.accessToken != null) {
        state = state.copyWith(accessToken: res.accessToken);
        _repo.setToken(res.accessToken);
        try {
          await _loadSession();
          state = state.copyWith(status: AuthStatus.authenticated);
          return true;
        } catch (_) {
          // Fall through.
        }
      }
    } catch (_) {
      // Treat as unauthenticated.
    }
    _repo.setToken(null);
    state = const AuthState();
    return false;
  }

  /// Refresh access token (used by _AuthInterceptor).
  Future<String?> refreshAccessToken() async {
    try {
      final res = await _repo.refreshToken();
      if (res.accessToken != null) {
        state = state.copyWith(accessToken: res.accessToken);
        _repo.setToken(res.accessToken);
        return res.accessToken;
      }
    } catch (_) {}
    return null;
  }

  // -- Logout --------------------------------------------------------------

  Future<void> logout() async {
    try {
      await _repo.logout();
    } catch (_) {
      // Server may be unreachable; clear state anyway.
    }
    _repo.setToken(null);
    state = const AuthState();
  }

  // -- RBAC ----------------------------------------------------------------

  /// Bit Flag permission check (CCR-017).
  bool hasPermission(String resource, PermissionAction action) {
    // Admin bypass.
    if (state.user?.role == 'admin') return true;
    return Permission.checkResource(state.permissions, resource, action);
  }

  // -- JWT helpers ---------------------------------------------------------

  static Map<String, dynamic> _decodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw FormatException(
          'Invalid JWT: expected 3 parts, got ${parts.length}');
    }
    var payload = parts[1];
    final rem = payload.length % 4;
    if (rem > 0) {
      payload += '=' * (4 - rem);
    }
    final bytes = base64Url.decode(payload);
    final json = utf8.decode(bytes);
    final map = jsonDecode(json);
    if (map is! Map<String, dynamic>) {
      throw const FormatException('JWT payload is not a JSON object');
    }
    return map;
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});
