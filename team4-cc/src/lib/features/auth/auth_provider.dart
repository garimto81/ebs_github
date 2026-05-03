// Auth state management (BS-05-00 §7 Launch Flow, CCR-029).
//
// Manages JWT-based authentication lifecycle:
//   unauthenticated → authenticating → authenticated | error
//
// JWT decoding is client-side only (base64 payload extraction).
// Server-side validation happens on WebSocket connect / REST calls.

import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../foundation/cc_settings_storage.dart';
import '../../models/launch_config.dart';

part 'auth_provider.freezed.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

enum AuthStatus { unauthenticated, authenticating, authenticated, error }

@freezed
class AuthState with _$AuthState {
  const factory AuthState({
    @Default(AuthStatus.unauthenticated) AuthStatus status,
    LaunchConfig? config,
    String? errorMessage,
    String? role, // Admin | Operator | Viewer
    List<int>? assignedTables,
  }) = _AuthState;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  /// Authenticate using a [LaunchConfig] (args or manual entry).
  ///
  /// Decodes the JWT payload to extract `role` and `assigned_tables` claims.
  /// No cryptographic verification — that is the server's responsibility.
  Future<void> authenticate(LaunchConfig config) async {
    state = state.copyWith(
      status: AuthStatus.authenticating,
      config: config,
      errorMessage: null,
    );

    try {
      final claims = _decodeJwtPayload(config.token);

      final role = claims['role'] as String?;
      final tablesRaw = claims['assigned_tables'];
      final assignedTables = tablesRaw is List
          ? tablesRaw.whereType<num>().map((e) => e.toInt()).toList()
          : null;
      final email = claims['email'] as String?;

      state = state.copyWith(
        status: AuthStatus.authenticated,
        role: role,
        assignedTables: assignedTables,
      );

      // SG-008-b11 v1.4 — last session 영속 (token 제외, password 제외).
      // Stand-alone 재진입 시 비번 1 field 만 표시 가능하도록.
      try {
        await CcSettingsStorage.saveLastSession(CcLastSession(
          email: email,
          boBaseUrl: config.boBaseUrl,
          tableId: config.tableId,
          wsUrl: config.wsUrl,
        ));
      } catch (_) {
        // localStorage 실패 시 silent (desktop stub 도 정상 흐름)
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Token decode failed: $e',
      );
    }
  }

  /// Reset to unauthenticated (logout / disconnect).
  void logout() {
    state = const AuthState();
  }

  /// Decode JWT payload (middle segment) from base64 → JSON map.
  static Map<String, dynamic> _decodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw FormatException('Invalid JWT: expected 3 parts, got ${parts.length}');
    }

    // Base64url decode with padding normalization.
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
// Providers
// ---------------------------------------------------------------------------

/// Optional launch config injected from main() when args are present.
final launchConfigProvider = Provider<LaunchConfig?>((ref) => null);

/// Auth state provider — consumed by app.dart for routing.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
