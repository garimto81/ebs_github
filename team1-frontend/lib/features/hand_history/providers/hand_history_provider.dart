// Hand History Providers — Cycle 21 W3 (Players_HandHistory_API.md).
//
// Riverpod StateNotifier 두 개:
//   - HandHistoryListNotifier: cursor 페이지 누적 + filter 변경 시 재로딩.
//   - HandHistoryDetailNotifier: 단일 hand 상세 조회 (family by handId).
//
// 새 cursor 가 null 이면 hasMore=false, 추가 요청 차단.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/hand_history_models.dart';
import '../repositories/hand_history_repository.dart';

/// 리스트 화면 상태 — items 누적 + cursor + isLoadingMore.
class HandHistoryListState {
  final List<HandHistoryItem> items;
  final String? nextCursor;
  final bool hasMore;
  final bool isLoadingMore;

  const HandHistoryListState({
    this.items = const [],
    this.nextCursor,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  HandHistoryListState copyWith({
    List<HandHistoryItem>? items,
    Object? nextCursor = _sentinel,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return HandHistoryListState(
      items: items ?? this.items,
      nextCursor: identical(nextCursor, _sentinel)
          ? this.nextCursor
          : nextCursor as String?,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

const Object _sentinel = Object();

class HandHistoryListNotifier
    extends StateNotifier<AsyncValue<HandHistoryListState>> {
  HandHistoryListNotifier(this._repo) : super(const AsyncValue.loading());

  final HandHistoryRepository _repo;
  HandHistoryFilter _filter = const HandHistoryFilter();

  HandHistoryFilter get filter => _filter;

  /// 필터 변경 또는 첫 진입 시 호출 — items 를 초기화하고 첫 페이지 로드.
  Future<void> refresh({HandHistoryFilter? filter}) async {
    if (filter != null) _filter = filter;
    state = const AsyncValue.loading();
    try {
      final page = await _repo.listHands(filter: _filter);
      state = AsyncValue.data(HandHistoryListState(
        items: page.items,
        nextCursor: page.nextCursor,
        hasMore: page.hasMore,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 무한 스크롤 — 다음 cursor 가 있으면 다음 페이지를 누적.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncValue.data(current.copyWith(isLoadingMore: true));
    try {
      final page = await _repo.listHands(
        filter: _filter,
        cursor: current.nextCursor,
      );
      state = AsyncValue.data(current.copyWith(
        items: [...current.items, ...page.items],
        nextCursor: page.nextCursor,
        hasMore: page.hasMore,
        isLoadingMore: false,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final handHistoryListProvider = StateNotifierProvider<HandHistoryListNotifier,
    AsyncValue<HandHistoryListState>>((ref) {
  return HandHistoryListNotifier(ref.watch(handHistoryRepositoryProvider));
});

/// 단일 hand 상세 — handId 기반 family. 자동 무효화는 ref.invalidate 로.
final handHistoryDetailProvider =
    FutureProvider.family<HandHistoryDetail, int>((ref, handId) async {
  final repo = ref.watch(handHistoryRepositoryProvider);
  return repo.getHand(handId);
});
