// Default Flutter test — ensures the project builds.

import 'package:flutter_test/flutter_test.dart';

import 'package:ebs_cc/foundation/theme/seat_colors.dart';
import 'package:ebs_cc/foundation/utils/seq_tracker.dart';

void main() {
  group('SeatColors SSOT', () {
    test('position markers have expected hex', () {
      // Use toARGB32() (Flutter 3.27+) — .value is deprecated.
      expect(SeatColors.dealer.toARGB32(), 0xFFE53935);
      expect(SeatColors.sb.toARGB32(), 0xFFFDD835);
      expect(SeatColors.bb.toARGB32(), 0xFF1E88E5);
      expect(SeatColors.utg.toARGB32(), 0xFF43A047);
    });

    test('action-glow duration is 800ms (BS-05-03)', () {
      expect(SeatColors.actionGlowDuration, const Duration(milliseconds: 800));
    });
  });

  group('SeqTracker (CCR-021)', () {
    test('in-order delivery returns no gaps', () {
      final t = SeqTracker();
      expect(t.apply(1), isEmpty);
      expect(t.apply(2), isEmpty);
      expect(t.apply(3), isEmpty);
      expect(t.lastSeq, 3);
    });

    test('gap detection returns replay range', () {
      final t = SeqTracker();
      t.apply(1);
      t.apply(2);
      final gaps = t.apply(5);
      expect(gaps, [(3, 4)]);
      expect(t.lastSeq, 5);
    });

    test('duplicate or out-of-order is ignored', () {
      final t = SeqTracker();
      t.apply(5);
      expect(t.apply(3), isEmpty);
      expect(t.lastSeq, 5);
    });
  });
}
