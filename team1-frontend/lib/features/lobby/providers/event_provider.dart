// Event list provider — ported from lobbyStore.ts events section.
//
// Family provider keyed by seriesId so each series panel holds its own
// async list independently.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/models.dart';
import '../../../repositories/event_repository.dart';

class EventListNotifier extends StateNotifier<AsyncValue<List<EbsEvent>>> {
  EventListNotifier({required this.seriesId, required EventRepository repo})
      : _repo = repo,
        super(const AsyncValue.loading());

  final int seriesId;
  final EventRepository _repo;

  /// Fetch events for [seriesId].
  ///
  /// Cycle 10 (S2 hierarchy wire): uses the nested route
  /// `/series/{id}/events`.  The flat `/events?seriesId=` route used the
  /// camelCase param `seriesId`, which real BO ignores (it expects
  /// `series_id`), so every series ended up showing the full event list.
  /// Switching to the path-variable form removes the dependency on
  /// query-param naming entirely.
  Future<void> fetch() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repo.listBySeries(seriesId);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void applyRemoteUpdate(EbsEvent updated) {
    state.whenData((list) {
      state = AsyncValue.data([
        for (final e in list)
          if (e.eventId == updated.eventId) updated else e,
      ]);
    });
  }

  void applyRemoteAdd(EbsEvent added) {
    state.whenData((list) {
      state = AsyncValue.data([...list, added]);
    });
  }

  void applyRemoteDelete(int eventId) {
    state.whenData((list) {
      state = AsyncValue.data(
        list.where((e) => e.eventId != eventId).toList(),
      );
    });
  }
}

final eventListProvider = StateNotifierProvider.family<EventListNotifier,
    AsyncValue<List<EbsEvent>>, int>(
  (ref, seriesId) => EventListNotifier(
    seriesId: seriesId,
    repo: ref.read(eventRepositoryProvider),
  ),
);
