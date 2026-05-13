// PlayerRepository.fetchAll cursor 누적 검증 — Cycle 21 W3.
//
// mockup data 제거 + cursor 페이지를 자동 누적하여 List<Player> 로 반환
// 하는 fetchAll 의 동작이 PlayerListNotifier 의 fetch() 와 호환되는지 확인.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebs_lobby/features/lobby/providers/player_provider.dart';
import 'package:ebs_lobby/models/entities/player.dart';
import 'package:ebs_lobby/repositories/player_repository.dart';

class _CursorRepo implements PlayerRepository {
  _CursorRepo(this._pages);
  final List<PlayerPage> _pages;
  int _callCount = 0;
  String? lastCursor;

  @override
  Future<PlayerPage> listPlayers({
    int? eventId,
    String? nationality,
    String? playerStatus,
    String? cursor,
    int limit = 50,
  }) async {
    lastCursor = cursor;
    final idx = _callCount < _pages.length ? _callCount : _pages.length - 1;
    _callCount++;
    return _pages[idx];
  }

  @override
  Future<PlayerPage> searchPlayers(
    String query, {
    String? cursor,
    int limit = 50,
  }) async {
    // Search 는 본 테스트 범위 밖 — 단일 페이지 fallback.
    return _pages.first;
  }

  @override
  Future<Player> getPlayer(int id, {bool includeStats = false}) {
    throw UnimplementedError();
  }

  @override
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
      if (safety > 100) break;
    } while (cursor != null);
    return all;
  }

  @override
  Future<List<Player>> searchAll(String query, {int pageSize = 100}) async {
    return _pages.first.items;
  }
}

Player _mkPlayer(int id, String name) {
  const ts = '2026-05-13T00:00:00Z';
  return Player(
    playerId: id,
    firstName: name,
    lastName: 'Test',
    playerStatus: 'active',
    source: 'wsop-live',
    createdAt: ts,
    updatedAt: ts,
  );
}

void main() {
  test('PlayerListNotifier.fetch → cursor 페이지 누적', () async {
    final repo = _CursorRepo([
      PlayerPage(
        items: [_mkPlayer(1, 'Alice'), _mkPlayer(2, 'Bob')],
        nextCursor: 'cur-1',
        hasMore: true,
      ),
      PlayerPage(
        items: [_mkPlayer(3, 'Charlie')],
        hasMore: false,
      ),
    ]);
    final container = ProviderContainer(overrides: [
      playerRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);

    await container.read(playerListProvider.notifier).fetch();
    final list = container.read(playerListProvider).value!;

    expect(list.length, 3);
    expect(list.map((p) => p.firstName), ['Alice', 'Bob', 'Charlie']);
    expect(repo.lastCursor, 'cur-1');
  });

  test('mockup 데이터 비-주입 보장 — PlayerListNotifier 는 repo 호출 결과만 사용',
      () async {
    // 빈 응답 → state.value 는 빈 리스트 (mockup 데이터 fallback 없음).
    final repo = _CursorRepo([
      const PlayerPage(items: [], hasMore: false),
    ]);
    final container = ProviderContainer(overrides: [
      playerRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);

    await container.read(playerListProvider.notifier).fetch();
    final list = container.read(playerListProvider).value!;

    expect(list, isEmpty,
        reason:
            'Cycle 21 — mockup 데이터 의존 제거. 빈 응답은 빈 리스트로 표시되어야 함');
  });
}
