import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/remote/bo_api_client.dart';
import '../models/models.dart';

// ---------------------------------------------------------------------------
// Response types
// ---------------------------------------------------------------------------

class TokenResponse {
  final String? accessToken;
  final String? refreshToken;
  final bool requires2fa;
  final String? tempToken;

  const TokenResponse({
    this.accessToken,
    this.refreshToken,
    this.requires2fa = false,
    this.tempToken,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) => TokenResponse(
        accessToken: json['access_token'] as String?,
        refreshToken: json['refreshToken'] as String?,
        requires2fa: json['requires_2fa'] as bool? ?? false,
        tempToken: json['tempToken'] as String?,
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

  /// Client에 access token 주입 (후속 요청의 Authorization 헤더에 반영).
  /// auth_provider.AuthNotifier가 login/verify2fa/refresh 성공 시 호출.
  void setToken(String? token) => _client.setToken(token);

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
      data: {'tempToken': tempToken, 'totpCode': code},
      fromJson: (json) => TokenResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<TokenResponse> refreshToken({String? refreshToken}) async {
    return _client.post<TokenResponse>(
      '/auth/refresh',
      data: refreshToken != null ? {'refreshToken': refreshToken} : null,
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
    // V9.5 SSOT 정합: BO 가 POST /auth/logout 제공 (DELETE /auth/session 미제공).
    await _client.post<dynamic>('/auth/logout');
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    return _client.post<Map<String, dynamic>>(
      '/auth/password/reset/send',
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
