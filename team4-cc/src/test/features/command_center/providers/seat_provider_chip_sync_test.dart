// SeatNotifier.applyChipCountSync unit tests — Cycle 20 #437.
//
// Verifies the WSOP LIVE → CC chip_count_synced WS handler behavior:
//   • Stack updates on the provided seats
//   • lastChipUpdate timestamp is set on those seats
//   • Seats not mentioned in the event remain untouched
//   • Out-of-range seat_number values (< 1 or > 10) are ignored
//
// Spec: docs/2. Development/2.2 Backend/APIs/WSOP_LIVE_Chip_Count_Sync.md
//       docs/2. Development/2.2 Backend/APIs/WebSocket_Events.md §4.2.11
//       docs/2. Development/2.5 Shared/Chip_Count_State.md

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebs_cc/features/command_center/providers/seat_provider.dart';

void main() {
  late ProviderContainer container;
  late SeatNotifier notifier;

  PlayerInfo mkPlayer(int id, {int stack = 10000}) =>
      PlayerInfo(id: id, name: 'P$id', stack: stack, countryCode: 'US');

  setUp(() {
    container = ProviderContainer();
    notifier = container.read(seatsProvider.notifier);
    // Seat 3 players for the standard test fixture.
    notifier.seatPlayer(1, mkPlayer(101, stack: 10000));
    notifier.seatPlayer(2, mkPlayer(102, stack: 20000));
    notifier.seatPlayer(5, mkPlayer(105, stack: 50000));
  });

  tearDown(() {
    container.dispose();
  });

  test('chip_count_synced — stack updates for listed seats', () {
    notifier.applyChipCountSync(const [
      (seatNumber: 1, chipCount: 125000),
      (seatNumber: 2, chipCount: 87500),
      (seatNumber: 5, chipCount: 211000),
    ]);

    final seats = container.read(seatsProvider);
    expect(seats[0].player!.stack, 125000);
    expect(seats[1].player!.stack, 87500);
    expect(seats[4].player!.stack, 211000);
  });

  test('chip_count_synced — lastChipUpdate set for updated seats', () {
    final before = DateTime.now();
    notifier.applyChipCountSync(const [
      (seatNumber: 1, chipCount: 125000),
      (seatNumber: 5, chipCount: 211000),
    ]);
    final after = DateTime.now();

    final seats = container.read(seatsProvider);
    final lcuS1 = seats[0].lastChipUpdate;
    final lcuS5 = seats[4].lastChipUpdate;

    expect(lcuS1, isNotNull);
    expect(lcuS5, isNotNull);
    expect(
      !lcuS1!.isBefore(before) && !lcuS1.isAfter(after),
      isTrue,
      reason: 'S1 lastChipUpdate should fall within [before, after]',
    );
    expect(
      !lcuS5!.isBefore(before) && !lcuS5.isAfter(after),
      isTrue,
      reason: 'S5 lastChipUpdate should fall within [before, after]',
    );
  });

  test(
    'chip_count_synced — unchanged seats stay (no stack/lastChipUpdate touch)',
    () {
      notifier.applyChipCountSync(const [
        (seatNumber: 1, chipCount: 125000),
      ]);

      final seats = container.read(seatsProvider);
      // S2 was occupied but NOT in the event → must retain original state.
      expect(seats[1].player!.stack, 20000);
      expect(seats[1].lastChipUpdate, isNull);
      // S5 was occupied but NOT in the event → must retain original state.
      expect(seats[4].player!.stack, 50000);
      expect(seats[4].lastChipUpdate, isNull);
      // Empty seat S3 must remain empty + lastChipUpdate null.
      expect(seats[2].player, isNull);
      expect(seats[2].lastChipUpdate, isNull);
    },
  );

  test(
    'chip_count_synced — out-of-range seat_number ignored, valid seats still applied',
    () {
      notifier.applyChipCountSync(const [
        (seatNumber: 0, chipCount: 999999),
        (seatNumber: 11, chipCount: 999999),
        (seatNumber: 1, chipCount: 125000),
      ]);

      final seats = container.read(seatsProvider);
      // Only 10 seats exist; no extra seat materialized.
      expect(seats.length, 10);
      // Valid seat S1 got the update.
      expect(seats[0].player!.stack, 125000);
      expect(seats[0].lastChipUpdate, isNotNull);
      // Other seats untouched.
      expect(seats[1].player!.stack, 20000);
      expect(seats[1].lastChipUpdate, isNull);
    },
  );
}
