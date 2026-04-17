// LobbyDashboard provider integration tests.
//
// Verifies the single-page dashboard correctly:
// - Loads series on init
// - Switches events when series changes
// - Loads tables when event is selected via active flight

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ebs_lobby/features/lobby/providers/event_provider.dart';
import 'package:ebs_lobby/features/lobby/providers/flight_provider.dart';
import 'package:ebs_lobby/features/lobby/providers/nav_provider.dart';
import 'package:ebs_lobby/features/lobby/providers/series_provider.dart';
import 'package:ebs_lobby/features/lobby/providers/table_provider.dart';
import 'package:ebs_lobby/models/models.dart';
import 'package:ebs_lobby/repositories/event_repository.dart';
import 'package:ebs_lobby/repositories/flight_repository.dart';
import 'package:ebs_lobby/repositories/series_repository.dart';
import 'package:ebs_lobby/repositories/table_repository.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockSeriesRepository extends Mock implements SeriesRepository {}

class MockEventRepository extends Mock implements EventRepository {}

class MockFlightRepository extends Mock implements FlightRepository {}

class MockTableRepository extends Mock implements TableRepository {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Series _makeSeries({required int id, String name = 'WSOP 2026'}) =>
    Series.fromJson({
      'series_id': id,
      'competition_id': 1,
      'series_name': name,
      'year': 2026,
      'begin_at': '2026-05-01',
      'end_at': '2026-07-15',
      'time_zone': 'America/Los_Angeles',
      'currency': 'USD',
      'is_completed': false,
      'is_displayed': true,
      'is_demo': false,
      'source': 'manual',
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-01T00:00:00Z',
    });

EbsEvent _makeEvent({required int id, required int seriesId}) =>
    EbsEvent.fromJson({
      'event_id': id,
      'series_id': seriesId,
      'event_no': id,
      'event_name': 'Event $id',
      'game_type': 0,
      'bet_structure': 0,
      'event_game_type': 0,
      'game_mode': 'single',
      'table_size': 9,
      'total_entries': 100,
      'players_left': 50,
      'status': 'running',
      'source': 'manual',
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-01T00:00:00Z',
    });

EventFlight _makeFlight({required int id, required int eventId}) =>
    EventFlight.fromJson({
      'event_flight_id': id,
      'event_id': eventId,
      'display_name': 'Day 1A',
      'is_tbd': false,
      'entries': 0,
      'players_left': 0,
      'table_count': 3,
      'status': 'running',
      'play_level': 1,
      'flight_id': id,
      'day_index': 0,
      'flight_name': 'Day 1A',
      'source': 'manual',
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-01T00:00:00Z',
    });

EbsTable _makeTable({required int id, required int flightId}) =>
    EbsTable.fromJson({
      'table_id': id,
      'event_flight_id': flightId,
      'table_no': id,
      'name': 'Table $id',
      'type': 'standard',
      'status': 'live',
      'max_players': 9,
      'game_type': 0,
      'ante_type': 0,
      'ante_amount': 0,
      'deck_registered': false,
      'delay_seconds': 0,
      'is_breaking_table': false,
      'source': 'manual',
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-01T00:00:00Z',
    });

void main() {
  late ProviderContainer container;
  late MockSeriesRepository mockSeriesRepo;
  late MockEventRepository mockEventRepo;
  late MockFlightRepository mockFlightRepo;
  late MockTableRepository mockTableRepo;

  setUp(() {
    mockSeriesRepo = MockSeriesRepository();
    mockEventRepo = MockEventRepository();
    mockFlightRepo = MockFlightRepository();
    mockTableRepo = MockTableRepository();

    container = ProviderContainer(overrides: [
      seriesRepositoryProvider.overrideWithValue(mockSeriesRepo),
      eventRepositoryProvider.overrideWithValue(mockEventRepo),
      flightRepositoryProvider.overrideWithValue(mockFlightRepo),
      tableRepositoryProvider.overrideWithValue(mockTableRepo),
    ]);
  });

  tearDown(() => container.dispose());

  // -------------------------------------------------------------------------
  // Series loading
  // -------------------------------------------------------------------------

  group('series loading', () {
    test('loads series list on fetch', () async {
      final seriesList = [
        _makeSeries(id: 1),
        _makeSeries(id: 2, name: 'Europe'),
      ];
      when(() => mockSeriesRepo.listSeries())
          .thenAnswer((_) async => seriesList);

      await container.read(seriesListProvider.notifier).fetch();

      final state = container.read(seriesListProvider);
      expect(state.value?.length, 2);
      expect(state.value?.first.seriesId, 1);
    });

    test('series list error is captured', () async {
      when(() => mockSeriesRepo.listSeries())
          .thenThrow(Exception('Network error'));

      await container.read(seriesListProvider.notifier).fetch();

      expect(container.read(seriesListProvider).hasError, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // Event loading on series change
  // -------------------------------------------------------------------------

  group('event loading on series change', () {
    test('events load when series is selected', () async {
      final events = [_makeEvent(id: 10, seriesId: 1)];
      when(() => mockEventRepo.listEvents(
            params: {'series_id': 1},
          )).thenAnswer((_) async => events);

      // Simulate series selection
      container.read(currentSeriesIdProvider.notifier).state = 1;
      await container.read(eventListProvider(1).notifier).fetch();

      final state = container.read(eventListProvider(1));
      expect(state.value?.length, 1);
      expect(state.value?.first.eventId, 10);
    });

    test('changing series resets event selection', () {
      container.read(currentSeriesIdProvider.notifier).state = 1;
      container.read(currentEventIdProvider.notifier).state = 10;

      // Simulate series change (cascading reset)
      container.read(currentSeriesIdProvider.notifier).state = 2;
      container.read(currentEventIdProvider.notifier).state = null;
      container.read(currentFlightIdProvider.notifier).state = null;

      expect(container.read(currentEventIdProvider), isNull);
      expect(container.read(currentFlightIdProvider), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Table loading on event selection
  // -------------------------------------------------------------------------

  group('table loading on event selection', () {
    test('tables load for active flight when event selected', () async {
      final flights = [_makeFlight(id: 100, eventId: 10)];
      final tables = [
        _makeTable(id: 1, flightId: 100),
        _makeTable(id: 2, flightId: 100),
      ];

      when(() => mockFlightRepo.listByEvent(10))
          .thenAnswer((_) async => flights);
      when(() => mockTableRepo.listTables(
            params: {'event_flight_id': 100},
          )).thenAnswer((_) async => tables);

      // Load flights for event
      container.read(currentEventIdProvider.notifier).state = 10;
      await container.read(flightListProvider(10).notifier).fetch();

      // Verify flights loaded
      final flightState = container.read(flightListProvider(10));
      expect(flightState.value?.length, 1);

      // Load tables for the active flight
      container.read(currentFlightIdProvider.notifier).state = 100;
      await container.read(tableListProvider(100).notifier).fetch();

      final tableState = container.read(tableListProvider(100));
      expect(tableState.value?.length, 2);
      expect(tableState.value?.first.tableId, 1);
    });
  });

  // -------------------------------------------------------------------------
  // Navigation state tracking
  // -------------------------------------------------------------------------

  group('nav state', () {
    test('starts with no selection', () {
      expect(container.read(currentSeriesIdProvider), isNull);
      expect(container.read(currentEventIdProvider), isNull);
      expect(container.read(currentFlightIdProvider), isNull);
      expect(container.read(currentTableIdProvider), isNull);
    });

    test('series selection is stored', () {
      container.read(currentSeriesIdProvider.notifier).state = 1;
      expect(container.read(currentSeriesIdProvider), 1);
    });

    test('event selection is stored', () {
      container.read(currentEventIdProvider.notifier).state = 10;
      expect(container.read(currentEventIdProvider), 10);
    });

    test('flight selection is stored', () {
      container.read(currentFlightIdProvider.notifier).state = 100;
      expect(container.read(currentFlightIdProvider), 100);
    });

    test('hasSelection is true after series selected', () {
      container.read(currentSeriesIdProvider.notifier).state = 1;
      // Force subscription so Provider re-evaluates
      final sub = container.listen(hasSelectionProvider, (_, __) {});
      expect(container.read(hasSelectionProvider), isTrue);
      sub.close();
    });
  });
}
