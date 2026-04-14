// Auth state management (BS-05-00 §7 Launch Flow, CCR-029).
//
// Manages JWT-based authentication lifecycle:
//   unauthenticated → authenticating → authenticated | error
//
// JWT decoding is client-side only (base64 payload extraction).
// Server-side validation happens on WebSocket connect / REST calls.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/launch_config.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

enum AuthStatus { unauthenticated, authenticating, authenticated, error }

class AuthState {
  const AuthState({
    this.status = AuthStatus.unauthenticated,
    this.config,
    this.errorMessage,
    this.role,
    this.assignedTables,
  });

  final AuthStatus status;
  final LaunchConfig? config;
  final String? errorMessage;
  final String? role; // Admin | Operator | Viewer
  final List<int>? assignedTables;

  AuthState copyWith({
    AuthStatus? status,
    LaunchConfig? config,
    String? errorMessage,
    String? role,
    List<int>? assignedTables,
  }) =>
      AuthState(
        status: status ?? this.status,
        config: config ?? this.config,
        errorMessage: errorMessage ?? this.errorMessage,
        role: role ?? this.role,
        assignedTables: assignedTables ?? this.assignedTables,
      );
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

      state = state.copyWith(
        status: AuthStatus.authenticated,
        role: role,
        assignedTables: assignedTables,
      );
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
