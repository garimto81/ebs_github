// SeqTracker unit tests (CCR-021).

import 'package:flutter_test/flutter_test.dart';

import 'package:ebs_cc/foundation/utils/seq_tracker.dart';

void main() {
  late SeqTracker tracker;

  setUp(() {
    tracker = SeqTracker();
  });

  group('SeqTracker', () {
    test('initial lastSeq is 0', () {
      expect(tracker.lastSeq, 0);
    });

    test('normal sequential delivery returns no gaps', () {
      expect(tracker.apply(1), isEmpty);
      expect(tracker.apply(2), isEmpty);
      expect(tracker.apply(3), isEmpty);
      expect(tracker.lastSeq, 3);
    });

    test('gap detection returns replay range', () {
      tracker.apply(1);
      tracker.apply(2);
      final gaps = tracker.apply(5);
      expect(gaps, [(3, 4)]);
      expect(tracker.lastSeq, 5);
    });

    test('multiple gaps in sequence', () {
      tracker.apply(1);
      final gap1 = tracker.apply(4); // gap 2-3
      expect(gap1, [(2, 3)]);

      final gap2 = tracker.apply(8); // gap 5-7
      expect(gap2, [(5, 7)]);
      expect(tracker.lastSeq, 8);
    });

    test('single-element gap', () {
      tracker.apply(1);
      final gaps = tracker.apply(3); // gap 2-2
      expect(gaps, [(2, 2)]);
      expect(tracker.lastSeq, 3);
    });

    test('duplicate seq is ignored', () {
      tracker.apply(1);
      tracker.apply(2);
      tracker.apply(3);
      final gaps = tracker.apply(3); // duplicate
      expect(gaps, isEmpty);
      expect(tracker.lastSeq, 3);
    });

    test('out-of-order (lower seq) is ignored', () {
      tracker.apply(5);
      final gaps = tracker.apply(3); // lower
      expect(gaps, isEmpty);
      expect(tracker.lastSeq, 5);
    });

    test('reset sets lastSeq to given value', () {
      tracker.apply(1);
      tracker.apply(2);
      tracker.apply(3);
      tracker.reset(10);
      expect(tracker.lastSeq, 10);

      // After reset, next expected is 11
      expect(tracker.apply(11), isEmpty);
      expect(tracker.lastSeq, 11);
    });

    test('reset to 0 restarts tracking', () {
      tracker.apply(5);
      tracker.reset(0);
      expect(tracker.lastSeq, 0);
      expect(tracker.apply(1), isEmpty);
    });

    test('first seq > 1 produces gap from 1', () {
      final gaps = tracker.apply(5);
      expect(gaps, [(1, 4)]);
      expect(tracker.lastSeq, 5);
    });
  });
}
