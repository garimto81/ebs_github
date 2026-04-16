import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/remote/bo_api_client.dart';
import '../models/models.dart';

// ---------------------------------------------------------------------------
// Response types
// ---------------------------------------------------------------------------

class TokenResponse {
  final String? accessToken;
  final bool requires2fa;
  final String? tempToken;

  const TokenResponse({
    this.accessToken,
    this.requires2fa = false,
    this.tempToken,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) => TokenResponse(
        accessToken: json['access_token'] as String?,
        requires2fa: json['requires_2fa'] as bool? ?? false,
        tempToken: json['temp_token'] as String?,
      );
}

class SessionResponse {
  final SessionUser user;

  const SessionResponse({required this.user});

  factory SessionResponse.fromJson(Map<String, dynamic> json) =>
      SessionResponse(
        user: SessionUser.fromJson(json['user'] as Map<String, dynamic>),
      );
}

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

class AuthRepository {
  AuthRepository(this._client);
  final BoApiClient _client;

  Future<TokenResponse> login(String email, String password) async {
    return _client.post<TokenResponse>(
      '/auth/login',
      data: {'email': email, 'password': password},
      fromJson: (json) => TokenResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<TokenResponse> verify2fa(String tempToken, String code) async {
    return _client.post<TokenResponse>(
      '/auth/verify-2fa',
      data: {'temp_token': tempToken, 'totp_code': code},
      fromJson: (json) => TokenResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<TokenResponse> refreshToken() async {
    return _client.post<TokenResponse>(
      '/auth/refresh',
      fromJson: (json) => TokenResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<SessionResponse> getSession() async {
    return _client.get<SessionResponse>(
      '/auth/session',
      fromJson: (json) =>
          SessionResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> logout() async {
    await _client.delete<dynamic>('/auth/session');
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    return _client.post<Map<String, dynamic>>(
      '/auth/forgot-password',
      data: {'email': email},
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(boApiClientProvider));
});
