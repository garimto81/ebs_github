// Cycle 20 (#439, S2 Wave 3c) — TableListNotifier chipTotal aggregation tests.
//
// Verifies the lobby's local chipTotal state plumbed from the
// `chip_count_synced` WS event (S7 publisher, #435/#436).
//
// Three required scenarios:
//   1. sum + update — payload with multiple seats sums chipCount and
//      updates the target table's chipTotal.
//   2. default 0 — a freshly fetched table has chipTotal == 0 (model default).
//   3. multi-table independent — an event for table A leaves table B intact.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ebs_lobby/data/remote/ws_dispatch.dart';
import 'package:ebs_lobby/features/lobby/providers/nav_provider.dart';
import 'package:ebs_lobby/features/lobby/providers/table_provider.dart';
import 'package:ebs_lobby/models/models.dart';
import 'package:ebs_lobby/repositories/table_repository.dart';

class _MockTableRepository extends Mock implements TableRepository {}

EbsTable _table({required int id, required int flightId, int chipTotal = 0}) =>
    EbsTable.fromJson({
      'tableId': id,
      'eventFlightId': flightId,
      'tableNo': id,
      'name': 'Table $id',
      'type': 'standard',
      'status': 'live',
      'maxPlayers': 9,
      'gameType': 0,
      'anteType': 0,
      'anteAmount': 0,
      'deckRegistered': false,
      'delaySeconds': 0,
      'isBreakingTable': false,
      'source': 'manual',
      'createdAt': '2026-01-01T00:00:00Z',
      'updatedAt': '2026-01-01T00:00:00Z',
      'chipTotal': chipTotal,
    });

void main() {
  group('chipTotal — TableListNotifier + chip_count_synced dispatch', () {
    late ProviderContainer container;
    late _MockTableRepository repo;
    const flightId = 100;

    setUp(() {
      repo = _MockTableRepository();
      container = ProviderContainer(overrides: [
        tableRepositoryProvider.overrideWithValue(repo),
      ]);
      container.read(currentFlightIdProvider.notifier).state = flightId;
    });

    tearDown(() => container.dispose());

    // -----------------------------------------------------------------------
    // Case 1: sum + update
    // -----------------------------------------------------------------------
    test('chip_count_synced sums seats[].chipCount and replaces chipTotal',
        () async {
      final tables = [_table(id: 1, flightId: flightId)];
      when(() => repo.listByFlight(flightId)).thenAnswer((_) async => tables);
      await container.read(tableListProvider(flightId).notifier).fetch();

      // Sanity: before any WS event, chipTotal is 0.
      expect(
        container.read(tableListProvider(flightId)).value!.first.chipTotal,
        0,
      );

      dispatchWsEventForTest(container, {
        'type': 'chip_count_synced',
        'payload': {
          'tableId': 1,
          'seats': [
            {'seatNo': 1, 'chipCount': 50000},
            {'seatNo': 2, 'chipCount': 75000},
            {'seatNo': 3, 'chipCount': 123456},
          ],
        },
      });

      final updated =
          container.read(tableListProvider(flightId)).value!.first;
      expect(updated.tableId, 1);
      expect(updated.chipTotal, 50000 + 75000 + 123456);
    });

    // -----------------------------------------------------------------------
    // Case 2: default 0
    // -----------------------------------------------------------------------
    test('a freshly fetched table defaults chipTotal to 0', () async {
      // Use raw fromJson WITHOUT chipTotal — mimics the REST schema which
      // does not carry the aggregate (backend persists chip_count per seat).
      final t = EbsTable.fromJson({
        'tableId': 7,
        'eventFlightId': flightId,
        'tableNo': 7,
        'name': 'Table 7',
        'type': 'standard',
        'status': 'live',
        'maxPlayers': 9,
        'gameType': 0,
        'anteType': 0,
        'anteAmount': 0,
        'deckRegistered': false,
        'delaySeconds': 0,
        'isBreakingTable': false,
        'source': 'manual',
        'createdAt': '2026-01-01T00:00:00Z',
        'updatedAt': '2026-01-01T00:00:00Z',
      });
      expect(t.chipTotal, 0,
          reason:
              'EbsTable.chipTotal must default to 0 when REST omits the field');

      when(() => repo.listByFlight(flightId)).thenAnswer((_) async => [t]);
      await container.read(tableListProvider(flightId).notifier).fetch();

      expect(
        container.read(tableListProvider(flightId)).value!.first.chipTotal,
        0,
      );
    });

    // -----------------------------------------------------------------------
    // Case 3: multi-table independence
    // -----------------------------------------------------------------------
    test('chip_count_synced for table A leaves table B unaffected', () async {
      final tables = [
        _table(id: 1, flightId: flightId),
        _table(id: 2, flightId: flightId),
      ];
      when(() => repo.listByFlight(flightId)).thenAnswer((_) async => tables);
      await container.read(tableListProvider(flightId).notifier).fetch();

      dispatchWsEventForTest(container, {
        'type': 'chip_count_synced',
        'payload': {
          'tableId': 1,
          'seats': [
            {'seatNo': 1, 'chipCount': 10000},
            {'seatNo': 2, 'chipCount': 20000},
          ],
        },
      });

      final list = container.read(tableListProvider(flightId)).value!;
      final a = list.firstWhere((t) => t.tableId == 1);
      final b = list.firstWhere((t) => t.tableId == 2);
      expect(a.chipTotal, 30000);
      expect(b.chipTotal, 0,
          reason:
              'Multi-table isolation: event for table 1 must not mutate table 2');
    });
  });
}
