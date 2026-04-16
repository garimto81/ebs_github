// Flight list provider — ported from lobbyStore.ts flights section.
//
// Family provider keyed by eventId.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/models.dart';
import '../../../repositories/flight_repository.dart';

class FlightListNotifier extends StateNotifier<AsyncValue<List<EventFlight>>> {
  FlightListNotifier({required this.eventId, required FlightRepository repo})
      : _repo = repo,
        super(const AsyncValue.loading());

  final int eventId;
  final FlightRepository _repo;

  Future<void> fetch() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repo.listByEvent(eventId);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void applyRemoteUpdate(EventFlight updated) {
    state.whenData((list) {
      state = AsyncValue.data([
        for (final f in list)
          if (f.eventFlightId == updated.eventFlightId) updated else f,
      ]);
    });
  }

  void applyRemoteAdd(EventFlight added) {
    state.whenData((list) {
      state = AsyncValue.data([...list, added]);
    });
  }

  void applyRemoteDelete(int flightId) {
    state.whenData((list) {
      state = AsyncValue.data(
        list.where((f) => f.eventFlightId != flightId).toList(),
      );
    });
  }
}

final flightListProvider = StateNotifierProvider.family<FlightListNotifier,
    AsyncValue<List<EventFlight>>, int>(
  (ref, eventId) => FlightListNotifier(
    eventId: eventId,
    repo: ref.read(flightRepositoryProvider),
  ),
);
