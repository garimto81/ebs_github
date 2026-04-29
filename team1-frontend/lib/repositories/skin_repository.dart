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

  /// Skin 생성 후 .gfskin 파일 업로드 (Backend_HTTP.md 명세 §Skins).
  ///
  /// 2-step upload per docs:
  ///   1) POST /skins          → skin 메타데이터 레코드 생성 (skin_id 획득)
  ///   2) POST /skins/:id/upload → 파일 바이너리 업로드
  ///
  /// 기존 단일-step `POST /skins/upload` 는 문서 위반으로 제거됨.
  Future<Skin> createSkin(Map<String, dynamic> metadata) async {
    return _client.post<Skin>(
      '/skins',
      data: metadata,
      fromJson: (json) => Skin.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Skin> uploadSkinFile(
    int skinId,
    List<int> bytes,
    String fileName, {
    void Function(int count, int total)? onProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    return _client.upload<Skin>(
      '/skins/$skinId/upload',
      formData: formData,
      onSendProgress: onProgress,
      fromJson: (json) => Skin.fromJson(json as Map<String, dynamic>),
    );
  }

  /// 편의 래퍼: create → upload 를 한 번에.
  Future<Skin> createAndUploadSkin(
    Map<String, dynamic> metadata,
    List<int> bytes,
    String fileName, {
    void Function(int count, int total)? onProgress,
  }) async {
    final skin = await createSkin(metadata);
    return uploadSkinFile(
      skin.skinId,
      bytes,
      fileName,
      onProgress: onProgress,
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
