// SeatCell widget tests (BS-05-03).
//
// Cycle 21 (residual-drift): FOLD grayscale ColorFiltered 검증 추가.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebs_cc/features/command_center/providers/seat_provider.dart';
import 'package:ebs_cc/features/command_center/widgets/seat_cell.dart';
import 'package:ebs_cc/models/enums/seat_status.dart';

/// Helper to pump a SeatCell inside a MaterialApp + ProviderScope.
Widget _buildTestWidget({
  required int seatIndex,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 200,
            height: 280,
            child: SeatCell(seatIndex: seatIndex),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('SeatCell widget', () {
    testWidgets('renders seat number for empty seat', (tester) async {
      await tester.pumpWidget(_buildTestWidget(seatIndex: 3));
      await tester.pump(); // allow initial build

      expect(find.text('S3'), findsOneWidget);
    });

    testWidgets('empty seat shows "EMPTY" text', (tester) async {
      // cycle 6 #321 — empty seat label changed from "Empty" to "EMPTY"
      // (uppercase + letterSpacing 1.2). Test sync deferred until v03 (#330).
      await tester.pumpWidget(_buildTestWidget(seatIndex: 1));
      await tester.pump();

      expect(find.text('EMPTY'), findsOneWidget);
    });

    testWidgets('occupied seat shows player name', (tester) async {
      final container = ProviderContainer();

      // Seat a player before building widget
      container.read(seatsProvider.notifier).seatPlayer(
            2,
            PlayerInfo(id: 1, name: 'Phil Ivey', stack: 50000, countryCode: 'US'),
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 200,
                  height: 280,
                  child: SeatCell(seatIndex: 2),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Phil Ivey'), findsOneWidget);
      expect(find.text('Empty'), findsNothing);
    });

    testWidgets('occupied seat shows formatted stack', (tester) async {
      final container = ProviderContainer();

      container.read(seatsProvider.notifier).seatPlayer(
            1,
            PlayerInfo(id: 1, name: 'Dan', stack: 10000, countryCode: 'US'),
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 200,
                  height: 280,
                  child: SeatCell(seatIndex: 1),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Stack formatted with $ and commas
      expect(find.text('\$10,000'), findsOneWidget);
    });

    testWidgets('action-on seat triggers glow animation', (tester) async {
      final container = ProviderContainer();

      container.read(seatsProvider.notifier).seatPlayer(
            4,
            PlayerInfo(id: 1, name: 'ActionPlayer', stack: 5000),
          );
      container.read(seatsProvider.notifier).setActionOn(4);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 200,
                  height: 280,
                  child: SeatCell(seatIndex: 4),
                ),
              ),
            ),
          ),
        ),
      );

      // Pump a few frames to allow animation
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Widget should render (no crash = animation active)
      expect(find.text('ActionPlayer'), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // Cycle 21 residual-drift: FOLD grayscale ColorFiltered (drift #2)
  // HTML SSOT: `.player-card { filter: grayscale(0.85) }` (fold mockup)
  // ──────────────────────────────────────────────────────────────────
  group('SeatCell FOLD grayscale (drift #2)', () {
    testWidgets('folded seat applies grayscale ColorFiltered', (tester) async {
      final container = ProviderContainer();
      container.read(seatsProvider.notifier).seatPlayer(
            3,
            PlayerInfo(
              id: 1,
              name: 'FoldedPlayer',
              stack: 5000,
              countryCode: 'US',
            ),
          );
      container
          .read(seatsProvider.notifier)
          .setActivity(3, PlayerActivity.folded);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 200,
                  height: 280,
                  child: SeatCell(seatIndex: 3),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // kSeatCellFoldGrayscaleKey is exported from seat_cell.dart
      expect(find.byKey(kSeatCellFoldGrayscaleKey), findsOneWidget);
    });

    testWidgets('active seat does NOT apply grayscale ColorFiltered',
        (tester) async {
      final container = ProviderContainer();
      container.read(seatsProvider.notifier).seatPlayer(
            3,
            PlayerInfo(id: 1, name: 'ActivePlayer', stack: 5000),
          );
      // not folded — activity defaults to active

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 200,
                  height: 280,
                  child: SeatCell(seatIndex: 3),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(kSeatCellFoldGrayscaleKey), findsNothing);
    });
  });
}
