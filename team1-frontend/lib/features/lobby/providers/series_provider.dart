// Series list provider — ported from lobbyStore.ts series section.
//
// StateNotifier<AsyncValue<List<Series>>> with fetch + remote update methods.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/models.dart';
import '../../../repositories/series_repository.dart';

class SeriesListNotifier extends StateNotifier<AsyncValue<List<Series>>> {
  SeriesListNotifier(this._repo) : super(const AsyncValue.loading());

  final SeriesRepository _repo;

  /// Fetch all series from the backend.
  Future<void> fetch() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repo.listSeries();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Apply a full-replacement update pushed via WebSocket.
  void applyRemoteUpdate(Series updated) {
    state.whenData((list) {
      state = AsyncValue.data([
        for (final s in list)
          if (s.seriesId == updated.seriesId) updated else s,
      ]);
    });
  }

  /// Append a newly-created series from a WebSocket event.
  void applyRemoteAdd(Series added) {
    state.whenData((list) {
      state = AsyncValue.data([...list, added]);
    });
  }

  /// Remove a series by ID (WebSocket delete event).
  void applyRemoteDelete(int seriesId) {
    state.whenData((list) {
      state = AsyncValue.data(
        list.where((s) => s.seriesId != seriesId).toList(),
      );
    });
  }
}

final seriesListProvider =
    StateNotifierProvider<SeriesListNotifier, AsyncValue<List<Series>>>(
  (ref) => SeriesListNotifier(ref.read(seriesRepositoryProvider)),
);
