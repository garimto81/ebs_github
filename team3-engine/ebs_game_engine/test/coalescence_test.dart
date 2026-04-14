import 'package:test/test.dart';
import 'package:ebs_game_engine/engine.dart';

void main() {
  group('CoalescenceWindow — Hold\'em defaults', () {
    test('100ms window collects 3-card burst into 1 batch', () {
      final cw = CoalescenceWindow(); // 100ms default
      expect(cw.windowMs, 100);

      // All within 100ms window
      final r1 = cw.addDetection(
        const CardDetection(seatIndex: 0, cardCode: 'As'),
        1000,
      );
      expect(r1, isNull);

      final r2 = cw.addDetection(
        const CardDetection(seatIndex: 0, cardCode: 'Kh'),
        1050,
      );
      expect(r2, isNull);

      final r3 = cw.addDetection(
        const CardDetection(seatIndex: 1, cardCode: 'Qd'),
        1080,
      );
      expect(r3, isNull);
      expect(cw.pendingCount, 3);

      // Flush to get batch
      final batch = cw.flush();
      expect(batch, isNotNull);
      expect(batch!.cardCount, 3);
      expect(batch.detections[0].cardCode, 'As');
      expect(batch.detections[2].cardCode, 'Qd');
    });

    test('window expiry emits batch and starts new window', () {
      final cw = CoalescenceWindow();

      cw.addDetection(
        const CardDetection(seatIndex: 0, cardCode: 'As'),
        1000,
      );
      cw.addDetection(
        const CardDetection(seatIndex: 1, cardCode: 'Kh'),
        1050,
      );

      // 150ms later — exceeds 100ms window
      final batch = cw.addDetection(
        const CardDetection(seatIndex: 2, cardCode: '2c'),
        1150,
      );
      expect(batch, isNotNull);
      expect(batch!.cardCount, 2);
      expect(batch.detections[0].cardCode, 'As');
      expect(batch.detections[1].cardCode, 'Kh');

      // New window started with '2c'
      expect(cw.pendingCount, 1);
      expect(cw.isActive, true);
    });
  });

  group('CoalescenceWindow — Draw (200ms)', () {
    test('200ms window collects discard+new_dealt burst', () {
      final cw = CoalescenceWindow.draw();
      expect(cw.windowMs, 200);
      expect(cw.maxBurstSize, 30);

      // Discards first (burn zone), then new dealt cards
      cw.addDetection(
        const CardDetection(seatIndex: 0, cardCode: '3h', source: 'burn'),
        2000,
      );
      cw.addDetection(
        const CardDetection(seatIndex: 0, cardCode: '7d', source: 'burn'),
        2050,
      );
      cw.addDetection(
        const CardDetection(seatIndex: 0, cardCode: 'Jc', source: 'seat'),
        2120,
      );
      cw.addDetection(
        const CardDetection(seatIndex: 0, cardCode: 'Td', source: 'seat'),
        2180,
      );

      final batch = cw.flush()!;
      expect(batch.cardCount, 4);
      expect(batch.burnDetections.length, 2);
    });

    test('Draw window validates discard-first ordering', () {
      // Valid order: burn first, then seat
      final validBatch = CoalescenceBatch(
        detections: const [
          CardDetection(seatIndex: 0, cardCode: '3h', source: 'burn'),
          CardDetection(seatIndex: 0, cardCode: '7d', source: 'burn'),
          CardDetection(seatIndex: 0, cardCode: 'Jc', source: 'seat'),
          CardDetection(seatIndex: 0, cardCode: 'Td', source: 'seat'),
        ],
        windowMs: 200,
      );
      expect(DrawCoalescenceValidator.validateDrawBatch(validBatch), isNull);
    });
  });

  group('DrawCoalescenceValidator — WRONG_SEQUENCE', () {
    test('detects discard after new_dealt card', () {
      final invalidBatch = CoalescenceBatch(
        detections: const [
          CardDetection(seatIndex: 0, cardCode: 'Jc', source: 'seat'),
          CardDetection(seatIndex: 0, cardCode: '3h', source: 'burn'),
        ],
        windowMs: 200,
      );
      final error =
          DrawCoalescenceValidator.validateDrawBatch(invalidBatch);
      expect(error, isNotNull);
      expect(error, contains('WRONG_SEQUENCE'));
    });
  });

  group('CoalescenceWindow — Stud 3rd street', () {
    test('18-card burst fits in single batch', () {
      final cw = CoalescenceWindow.stud3rd();
      expect(cw.maxBurstSize, 18);

      // Simulate 18 cards for 6 players x 3 cards each, all within 100ms
      final cards = [
        'As', 'Kh', 'Qd', 'Jc', 'Ts', '9h',
        '8d', '7c', '6s', '5h', '4d', '3c',
        '2s', 'Ah', 'Kd', 'Qc', 'Js', 'Th',
      ];
      for (var i = 0; i < 18; i++) {
        final result = cw.addDetection(
          CardDetection(seatIndex: i ~/ 3, cardCode: cards[i]),
          5000 + i * 5, // 5ms apart, all within 100ms
        );
        expect(result, isNull, reason: 'Card $i should not emit batch');
      }
      expect(cw.pendingCount, 18);

      final batch = cw.flush()!;
      expect(batch.cardCount, 18);
    });
  });

  group('CoalescenceWindow — overflow', () {
    test('maxBurstSize overflow emits batch and starts new window', () {
      final cw = CoalescenceWindow(windowMs: 500, maxBurstSize: 3);

      cw.addDetection(
        const CardDetection(seatIndex: 0, cardCode: 'As'),
        1000,
      );
      cw.addDetection(
        const CardDetection(seatIndex: 1, cardCode: 'Kh'),
        1010,
      );
      cw.addDetection(
        const CardDetection(seatIndex: 2, cardCode: 'Qd'),
        1020,
      );
      // Buffer is full (3), next detection triggers overflow
      final batch = cw.addDetection(
        const CardDetection(seatIndex: 3, cardCode: 'Jc'),
        1030,
      );

      expect(batch, isNotNull);
      expect(batch!.cardCount, 3);
      expect(batch.detections.map((d) => d.cardCode).toList(),
          ['As', 'Kh', 'Qd']);

      // New window has the overflow card
      expect(cw.pendingCount, 1);
    });

    test('overflow within same window emits correct batches', () {
      final cw = CoalescenceWindow(windowMs: 1000, maxBurstSize: 2);

      // First two cards fill the buffer
      cw.addDetection(
        const CardDetection(seatIndex: 0, cardCode: 'As'),
        1000,
      );
      cw.addDetection(
        const CardDetection(seatIndex: 1, cardCode: 'Kh'),
        1010,
      );

      // Third card triggers overflow
      final batch1 = cw.addDetection(
        const CardDetection(seatIndex: 2, cardCode: 'Qd'),
        1020,
      );
      expect(batch1, isNotNull);
      expect(batch1!.cardCount, 2);

      // Fourth card still within maxBurstSize of new window
      final r = cw.addDetection(
        const CardDetection(seatIndex: 3, cardCode: 'Jc'),
        1030,
      );
      expect(r, isNull);
      expect(cw.pendingCount, 2);

      // Fifth card triggers overflow again
      final batch2 = cw.addDetection(
        const CardDetection(seatIndex: 4, cardCode: 'Tc'),
        1040,
      );
      expect(batch2, isNotNull);
      expect(batch2!.cardCount, 2);
    });
  });

  group('CoalescenceWindow — flush', () {
    test('force-close window returns accumulated batch', () {
      final cw = CoalescenceWindow();
      cw.addDetection(
        const CardDetection(seatIndex: 0, cardCode: 'As'),
        1000,
      );
      cw.addDetection(
        const CardDetection(seatIndex: 1, cardCode: 'Kh'),
        1020,
      );
      expect(cw.isActive, true);

      final batch = cw.flush();
      expect(batch, isNotNull);
      expect(batch!.cardCount, 2);
      expect(cw.isActive, false);
      expect(cw.pendingCount, 0);
    });
  });

  group('CoalescenceBatch — bySeat grouping', () {
    test('groups detections by seat index', () {
      final batch = CoalescenceBatch(
        detections: const [
          CardDetection(seatIndex: 0, cardCode: 'As'),
          CardDetection(seatIndex: 1, cardCode: 'Kh'),
          CardDetection(seatIndex: 0, cardCode: 'Qd'),
          CardDetection(seatIndex: -1, cardCode: 'Jc', source: 'board'),
          CardDetection(seatIndex: 1, cardCode: 'Ts'),
        ],
        windowMs: 100,
      );

      final grouped = batch.bySeat;
      expect(grouped.keys.toSet(), {0, 1, -1});
      expect(grouped[0]!.length, 2);
      expect(grouped[1]!.length, 2);
      expect(grouped[-1]!.length, 1);

      expect(batch.boardDetections.length, 1);
      expect(batch.boardDetections.first.cardCode, 'Jc');
    });
  });

  group('CoalescenceWindow — edge cases', () {
    test('flush on empty window returns null', () {
      final cw = CoalescenceWindow();
      expect(cw.flush(), isNull);
      expect(cw.isActive, false);
      expect(cw.pendingCount, 0);
    });
  });

  group('DrawCoalescenceValidator — separateDrawBatch', () {
    test('separates discards and new cards', () {
      final batch = CoalescenceBatch(
        detections: const [
          CardDetection(seatIndex: 0, cardCode: '3h', source: 'burn'),
          CardDetection(seatIndex: 0, cardCode: '7d', source: 'burn'),
          CardDetection(seatIndex: 0, cardCode: 'Jc', source: 'seat'),
          CardDetection(seatIndex: 0, cardCode: 'Td', source: 'seat'),
          CardDetection(seatIndex: -1, cardCode: '2s', source: 'board'),
        ],
        windowMs: 200,
      );

      final separated = DrawCoalescenceValidator.separateDrawBatch(batch);
      expect(separated.discards.length, 2);
      expect(separated.newCards.length, 2);
      // Board cards are neither discard nor new_dealt (seat)
      expect(
        separated.discards.length + separated.newCards.length,
        lessThan(batch.cardCount),
      );
    });
  });
}
