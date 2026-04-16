import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/remote/bo_api_client.dart';
import '../models/models.dart';

class StaffRepository {
  StaffRepository(this._client);
  final BoApiClient _client;

  Future<List<User>> listUsers({
    Map<String, dynamic>? params,
  }) async {
    return _client.get<List<User>>(
      '/users',
      queryParameters: params,
      fromJson: (json) => (json as List)
          .map((e) => User.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<User> getUser(int id) async {
    return _client.get<User>(
      '/users/$id',
      fromJson: (json) => User.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<User> createUser(Map<String, dynamic> data) async {
    return _client.post<User>(
      '/users',
      data: data,
      fromJson: (json) => User.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<User> updateUser(int id, Map<String, dynamic> data) async {
    return _client.put<User>(
      '/users/$id',
      data: data,
      fromJson: (json) => User.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> deleteUser(int id) async {
    await _client.delete<dynamic>('/users/$id');
  }

  Future<void> forceLogout(int id) async {
    await _client.post<dynamic>('/users/$id/force-logout');
  }
}

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  return StaffRepository(ref.watch(boApiClientProvider));
});
