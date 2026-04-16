// SeqTracker integration smoke test — verifies ebs_common import works
// and gap detection behaves as expected.

import 'package:ebs_common/ebs_common.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SeqTracker', () {
    late SeqTracker tracker;

    setUp(() {
      tracker = SeqTracker();
    });

    test('consecutive seq returns no gaps', () {
      expect(tracker.apply(1), isEmpty);
      expect(tracker.apply(2), isEmpty);
      expect(tracker.apply(3), isEmpty);
      expect(tracker.lastSeq, 3);
    });

    test('detects gap when seq jumps', () {
      tracker.apply(1);
      final gaps = tracker.apply(5);

      expect(gaps.length, 1);
      expect(gaps.first, (2, 4));
      expect(tracker.lastSeq, 5);
    });

    test('detects multiple gaps', () {
      tracker.apply(1);
      final gap1 = tracker.apply(5);
      expect(gap1, [(2, 4)]);

      final gap2 = tracker.apply(10);
      expect(gap2, [(6, 9)]);
      expect(tracker.lastSeq, 10);
    });

    test('ignores duplicate or old seq', () {
      tracker.apply(1);
      tracker.apply(2);
      tracker.apply(3);

      // Re-send seq 2 — should be ignored.
      expect(tracker.apply(2), isEmpty);
      expect(tracker.lastSeq, 3);
    });

    test('reset sets lastSeq', () {
      tracker.apply(1);
      tracker.apply(2);
      tracker.reset(10);

      expect(tracker.lastSeq, 10);
      // Next seq after reset.
      expect(tracker.apply(11), isEmpty);
    });
  });
}
