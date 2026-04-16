// Hand History provider — simple paginated list.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../models/models.dart';
import '../../../repositories/hand_repository.dart';

part 'hand_history_provider.freezed.dart';

// ---------------------------------------------------------------------------
// Paginated state
// ---------------------------------------------------------------------------

@freezed
class HandHistoryState with _$HandHistoryState {
  const factory HandHistoryState({
    @Default([]) List<Hand> items,
    @Default(false) bool isLoading,
    @Default(false) bool hasMore,
    @Default(0) int currentPage,
    @Default(50) int pageSize,
    String? error,
    int? filterTableId,
  }) = _HandHistoryState;
}

class HandHistoryNotifier extends StateNotifier<HandHistoryState> {
  HandHistoryNotifier(this._repo) : super(const HandHistoryState());

  final HandRepository _repo;

  /// Fetch the first page. Resets pagination.
  Future<void> fetchFirst({int? tableId}) async {
    state = HandHistoryState(
      isLoading: true,
      filterTableId: tableId,
      pageSize: state.pageSize,
    );
    try {
      final params = <String, dynamic>{
        'page': 0,
        'page_size': state.pageSize,
        if (tableId != null) 'table_id': tableId,
      };
      final items = await _repo.listHands(params: params);
      state = state.copyWith(
        items: items,
        isLoading: false,
        hasMore: items.length >= state.pageSize,
        currentPage: 0,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Fetch the next page and append results.
  Future<void> fetchNext() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    final nextPage = state.currentPage + 1;
    try {
      final params = <String, dynamic>{
        'page': nextPage,
        'page_size': state.pageSize,
        if (state.filterTableId != null) 'table_id': state.filterTableId,
      };
      final newItems = await _repo.listHands(params: params);
      state = state.copyWith(
        items: [...state.items, ...newItems],
        isLoading: false,
        hasMore: newItems.length >= state.pageSize,
        currentPage: nextPage,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

final handHistoryProvider =
    StateNotifierProvider<HandHistoryNotifier, HandHistoryState>(
  (ref) => HandHistoryNotifier(ref.read(handRepositoryProvider)),
);
