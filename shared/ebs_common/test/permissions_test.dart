import 'package:test/test.dart';
import 'package:ebs_common/ebs_common.dart';

void main() {
  group('Permission', () {
    test('hasPermission checks bit flag', () {
      expect(Permission.hasPermission(3, PermissionAction.read), isTrue);
      expect(Permission.hasPermission(3, PermissionAction.write), isTrue);
      expect(Permission.hasPermission(3, PermissionAction.delete_), isFalse);
    });

    test('hasPermission returns false for null', () {
      expect(Permission.hasPermission(null, PermissionAction.read), isFalse);
    });

    test('checkResource looks up resource key', () {
      final perms = {'Lobby': 3, 'Settings': 7};
      expect(Permission.checkResource(perms, 'Lobby', PermissionAction.write), isTrue);
      expect(Permission.checkResource(perms, 'Lobby', PermissionAction.delete_), isFalse);
      expect(Permission.checkResource(perms, 'Settings', PermissionAction.delete_), isTrue);
    });

    test('checkResource returns false for null map', () {
      expect(Permission.checkResource(null, 'Lobby', PermissionAction.read), isFalse);
    });
  });

  group('SeqTracker', () {
    test('normal in-order delivery returns empty gaps', () {
      final tracker = SeqTracker();
      expect(tracker.apply(1), isEmpty);
      expect(tracker.apply(2), isEmpty);
      expect(tracker.lastSeq, 2);
    });

    test('gap detection returns range', () {
      final tracker = SeqTracker();
      tracker.apply(1);
      final gaps = tracker.apply(5);
      expect(gaps, [(2, 4)]);
      expect(tracker.lastSeq, 5);
    });

    test('duplicate seq returns empty', () {
      final tracker = SeqTracker();
      tracker.apply(3);
      expect(tracker.apply(2), isEmpty);
      expect(tracker.apply(3), isEmpty);
    });

    test('reset updates lastSeq', () {
      final tracker = SeqTracker();
      tracker.reset(10);
      expect(tracker.lastSeq, 10);
      expect(tracker.apply(11), isEmpty);
    });
  });
}
