// Player Repository — Cycle 21 W3 (Players_HandHistory_API.md v1.0.0).
//
// Reports 폐기 + cursor pagination 채택에 따라 응답 shape 변경:
//   이전: GET /api/v1/players → bare List<Player>
//   현재: GET /api/v1/players → PlayerPage {items, nextCursor, hasMore}
//
// 후방 호환을 위한 fetchAll 헬퍼는 cursor 누적 호출 후 List<Player> 반환
// (UI 가 점진적 무한 스크롤 도입 전 단순 풀로딩 fallback 으로 사용).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/remote/bo_api_client.dart';
import '../models/models.dart';

/// cursor 페이지 응답 — Players_HandHistory_API.md §2.1.
class PlayerPage {
  final List<Player> items;
  final String? nextCursor;
  final bool hasMore;

  const PlayerPage({
    required this.items,
    this.nextCursor,
    this.hasMore = false,
  });

  factory PlayerPage.fromJson(Map<String, dynamic> json) {
    final raw = json['items'] as List? ?? const [];
    return PlayerPage(
      items: raw
          .map((e) => Player.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['nextCursor'] as String?,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }
}

class PlayerRepository {
  PlayerRepository(this._client);
  final BoApiClient _client;

  /// GET /api/v1/players — 단일 페이지 조회.
  Future<PlayerPage> listPlayers({
    int? eventId,
    String? nationality,
    String? playerStatus,
    String? cursor,
    int limit = 50,
  }) async {
    final params = <String, dynamic>{'limit': limit};
    if (eventId != null) params['event_id'] = eventId;
    if (nationality != null) params['nationality'] = nationality;
    if (playerStatus != null) params['player_status'] = playerStatus;
    if (cursor != null) params['cursor'] = cursor;
    return _client.get<PlayerPage>(
      '/players',
      queryParameters: params,
      fromJson: (json) => PlayerPage.fromJson(json as Map<String, dynamic>),
    );
  }

  /// GET /api/v1/players/{id} — 상세. include_stats 는 cycle 21 spec §2.2.
  Future<Player> getPlayer(int id, {bool includeStats = false}) async {
    return _client.get<Player>(
      '/players/$id',
      queryParameters: includeStats ? {'include_stats': true} : null,
      fromJson: (json) => Player.fromJson(json as Map<String, dynamic>),
    );
  }

  /// GET /api/v1/players/search?q= — backwards-compat.
  /// 단일 페이지 응답 반환 (cursor 진행은 listPlayers 와 동일 방식).
  Future<PlayerPage> searchPlayers(
    String query, {
    String? cursor,
    int limit = 50,
  }) async {
    final params = <String, dynamic>{'q': query, 'limit': limit};
    if (cursor != null) params['cursor'] = cursor;
    return _client.get<PlayerPage>(
      '/players/search',
      queryParameters: params,
      fromJson: (json) => PlayerPage.fromJson(json as Map<String, dynamic>),
    );
  }

  /// cursor 모두 순회하여 `List<Player>` 반환 — UI 가 단순 풀로딩 필요할 때 fallback.
  /// 무한 스크롤 도입 후 deprecated 예정.
  Future<List<Player>> fetchAll({
    int? eventId,
    String? playerStatus,
    int pageSize = 100,
  }) async {
    final all = <Player>[];
    String? cursor;
    var safety = 0;
    do {
      final page = await listPlayers(
        eventId: eventId,
        playerStatus: playerStatus,
        cursor: cursor,
        limit: pageSize,
      );
      all.addAll(page.items);
      cursor = page.hasMore ? page.nextCursor : null;
      safety++;
      if (safety > 100) break; // 안전장치: 10,000+ row 폭주 방지
    } while (cursor != null);
    return all;
  }

  /// query 기반 풀로딩 — UI 검색 입력 시 사용.
  Future<List<Player>> searchAll(String query, {int pageSize = 100}) async {
    final all = <Player>[];
    String? cursor;
    var safety = 0;
    do {
      final page = await searchPlayers(query, cursor: cursor, limit: pageSize);
      all.addAll(page.items);
      cursor = page.hasMore ? page.nextCursor : null;
      safety++;
      if (safety > 100) break;
    } while (cursor != null);
    return all;
  }
}

final playerRepositoryProvider = Provider<PlayerRepository>((ref) {
  return PlayerRepository(ref.watch(boApiClientProvider));
});
