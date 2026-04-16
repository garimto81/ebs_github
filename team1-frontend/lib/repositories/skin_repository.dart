import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/remote/bo_api_client.dart';
import '../models/models.dart';

class SkinRepository {
  SkinRepository(this._client);
  final BoApiClient _client;

  Future<List<Skin>> listSkins() async {
    return _client.get<List<Skin>>(
      '/skins',
      fromJson: (json) => (json as List)
          .map((e) => Skin.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<Skin> getSkin(int id) async {
    return _client.get<Skin>(
      '/skins/$id',
      fromJson: (json) => Skin.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Skin> uploadSkin(
    List<int> bytes,
    String fileName, {
    void Function(int count, int total)? onProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    return _client.upload<Skin>(
      '/skins/upload',
      formData: formData,
      onSendProgress: onProgress,
      fromJson: (json) => Skin.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Skin> activateSkin(int id) async {
    return _client.post<Skin>(
      '/skins/$id/activate',
      fromJson: (json) => Skin.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Skin> deactivateSkin(int id) async {
    return _client.post<Skin>(
      '/skins/$id/deactivate',
      fromJson: (json) => Skin.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> deleteSkin(int id) async {
    await _client.delete<dynamic>('/skins/$id');
  }
}

final skinRepositoryProvider = Provider<SkinRepository>((ref) {
  return SkinRepository(ref.watch(boApiClientProvider));
});
