// HandHistoryListNotifier 동작 검증 — cursor 누적 + filter 재로드.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebs_lobby/features/hand_history/models/hand_history_models.dart';
import 'package:ebs_lobby/features/hand_history/providers/hand_history_provider.dart';
import 'package:ebs_lobby/features/hand_history/repositories/hand_history_repository.dart';

class _FakeRepo implements HandHistoryRepository {
  _FakeRepo({required this.pages});

  /// listHands 호출 횟수마다 반환할 페이지 (cursor → 인덱스).
  final List<HandHistoryPage> pages;
  HandHistoryDetail? detail;

  int listCalls = 0;
  HandHistoryFilter? lastFilter;
  String? lastCursor;

  @override
  Future<HandHistoryPage> listHands({
    HandHistoryFilter filter = const HandHistoryFilter(),
    String? cursor,
    int limit = 50,
  }) async {
    lastFilter = filter;
    lastCursor = cursor;
    final idx = listCalls < pages.length ? listCalls : pages.length - 1;
    listCalls++;
    return pages[idx];
  }

  @override
  Future<HandHistoryDetail> getHand(int handId) async {
    return detail ??
        HandHistoryDetail(
          handId: handId,
          tableId: 1,
          handNumber: 1,
          gameType: 0,
          betStructure: 0,
          dealerSeat: 1,
          boardCards: '[]',
          potTotal: 0,
          sidePots: '[]',
          startedAt: '2026-05-13T07:00:00Z',
          durationSec: 0,
          handPlayers: const [],
          handActions: const [],
        );
  }
}

HandHistoryItem _mkItem(int id) => HandHistoryItem(
      handId: id,
      tableId: 1,
      handNumber: id,
      gameType: 0,
      betStructure: 0,
      dealerSeat: 1,
      boardCards: '[]',
      potTotal: 1000,
      sidePots: '[]',
      startedAt: '2026-05-13T07:00:00Z',
      durationSec: 60,
    );

void main() {
  test('refresh — 첫 페이지 로딩 → items 채워짐', () async {
    final repo = _FakeRepo(pages: [
      HandHistoryPage(
        items: [_mkItem(1), _mkItem(2)],
        nextCursor: 'cur-1',
        hasMore: true,
      ),
    ]);
    final container = ProviderContainer(overrides: [
      handHistoryRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);

    await container.read(handHistoryListProvider.notifier).refresh();
    final state = container.read(handHistoryListProvider).value!;

    expect(state.items.length, 2);
    expect(state.hasMore, isTrue);
    expect(state.nextCursor, 'cur-1');
    expect(repo.listCalls, 1);
    expect(repo.lastCursor, isNull);
  });

  test('loadMore — cursor 전달 + items 누적', () async {
    final repo = _FakeRepo(pages: [
      HandHistoryPage(
        items: [_mkItem(1)],
        nextCursor: 'cur-1',
        hasMore: true,
      ),
      HandHistoryPage(
        items: [_mkItem(2), _mkItem(3)],
        nextCursor: null,
        hasMore: false,
      ),
    ]);
    final container = ProviderContainer(overrides: [
      handHistoryRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);

    await container.read(handHistoryListProvider.notifier).refresh();
    await container.read(handHistoryListProvider.notifier).loadMore();

    final state = container.read(handHistoryListProvider).value!;
    expect(state.items.map((i) => i.handId), [1, 2, 3]);
    expect(state.hasMore, isFalse);
    expect(state.nextCursor, isNull);
    expect(repo.listCalls, 2);
    expect(repo.lastCursor, 'cur-1');
  });

  test('loadMore — hasMore=false 시 추가 호출 차단', () async {
    final repo = _FakeRepo(pages: [
      HandHistoryPage(items: [_mkItem(1)], hasMore: false),
    ]);
    final container = ProviderContainer(overrides: [
      handHistoryRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);

    await container.read(handHistoryListProvider.notifier).refresh();
    await container.read(handHistoryListProvider.notifier).loadMore();
    await container.read(handHistoryListProvider.notifier).loadMore();

    expect(repo.listCalls, 1, reason: 'hasMore=false 이므로 추가 호출 없음');
  });

  test('refresh(filter:) — 필터 전달', () async {
    final repo = _FakeRepo(pages: [
      const HandHistoryPage(items: [], hasMore: false),
    ]);
    final container = ProviderContainer(overrides: [
      handHistoryRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);

    await container
        .read(handHistoryListProvider.notifier)
        .refresh(filter: const HandHistoryFilter(tableId: 42, showdownOnly: true));

    expect(repo.lastFilter?.tableId, 42);
    expect(repo.lastFilter?.showdownOnly, isTrue);
  });
}
