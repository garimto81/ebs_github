// Hand History Repository — Cycle 21 W3 (Players_HandHistory_API.md v1.0.0).
//
// BoApiClient 위에 얇은 wrapper. 응답은 EbsBaseModel alias_generator=to_camel
// 로 직렬화된 camelCase JSON. cursor 페이징은 nextCursor 를 다음 요청에 전달.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/remote/bo_api_client.dart';
import '../models/hand_history_models.dart';

class HandHistoryRepository {
  HandHistoryRepository(this._client);

  final BoApiClient _client;

  /// GET /api/v1/hands — cursor 페이지 단위 조회.
  /// [filter] 의 query param 을 직렬화하여 호출.
  Future<HandHistoryPage> listHands({
    HandHistoryFilter filter = const HandHistoryFilter(),
    String? cursor,
    int limit = 50,
  }) async {
    return _client.get<HandHistoryPage>(
      '/hands',
      queryParameters: filter.toQueryParams(cursor: cursor, limit: limit),
      fromJson: (json) =>
          HandHistoryPage.fromJson(json as Map<String, dynamic>),
    );
  }

  /// GET /api/v1/hands/{id} — nested hand_players + hand_actions 포함.
  Future<HandHistoryDetail> getHand(int handId) async {
    return _client.get<HandHistoryDetail>(
      '/hands/$handId',
      fromJson: (json) =>
          HandHistoryDetail.fromJson(json as Map<String, dynamic>),
    );
  }
}

final handHistoryRepositoryProvider = Provider<HandHistoryRepository>((ref) {
  return HandHistoryRepository(ref.watch(boApiClientProvider));
});
