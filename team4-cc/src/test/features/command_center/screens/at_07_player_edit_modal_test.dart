// AT-07 Player Edit modal — Cycle 19 Wave 4 U6 OKLCH realignment smoke tests.
//
// 검증 범위:
//   1) 다이얼로그가 Operator 권한일 때 throw 없이 렌더링
//   2) Viewer 권한일 때 안내 다이얼로그 (no permission) 가 OKLCH 톤으로 렌더
//   3) 7개 필드 라벨이 표준 라벨 셋과 일치 (Name / Player ID / Nationality /
//      Stack / Avatar URL / VIP Level / Seat Status)
//   4) 루트 컨테이너 background = EbsOklch.bg3, border = EbsOklch.line
//   5) Save (ElevatedButton) background = EbsOklch.accent

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebs_cc/features/auth/auth_provider.dart';
import 'package:ebs_cc/features/command_center/providers/seat_provider.dart';
import 'package:ebs_cc/features/command_center/screens/at_07_player_edit_modal.dart';
import 'package:ebs_cc/foundation/theme/ebs_oklch.dart';

void main() {
  /// Build a ProviderScope override list that:
  ///   - replaces `authProvider` with a seeded auth state for [role]
  ///   - seats a PlayerInfo at seat 5 so the modal has data
  List<Override> overrides({String role = 'Operator'}) {
    final seatNotifier = SeatNotifier()
      ..seatPlayer(
        5,
        const PlayerInfo(id: 12345, name: 'Daniel Park', stack: 50000),
      );

    return [
      authProvider.overrideWith((ref) {
        final n = AuthNotifier()
          ..state = AuthState(
            status: AuthStatus.authenticated,
            role: role,
            assignedTables: const [1],
          );
        return n;
      }),
      seatsProvider.overrideWith((ref) => seatNotifier),
    ];
  }

  Widget wrap(List<Override> ov, Widget home) => ProviderScope(
        overrides: ov,
        child: MaterialApp(home: Scaffold(body: home)),
      );

  Widget launcher({int seatNo = 5}) => Builder(
        builder: (ctx) => Center(
          child: ElevatedButton(
            onPressed: () => showPlayerEditModal(ctx, seatNo),
            child: const Text('open'),
          ),
        ),
      );

  testWidgets('Operator role: modal renders all 7 field labels',
      (tester) async {
    await tester.pumpWidget(wrap(overrides(), launcher()));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('NAME'), findsOneWidget);
    expect(find.text('PLAYER ID'), findsOneWidget);
    expect(find.text('NATIONALITY'), findsOneWidget);
    expect(find.text('STACK'), findsOneWidget);
    expect(find.text('AVATAR URL'), findsOneWidget);
    expect(find.text('VIP LEVEL'), findsOneWidget);
    expect(find.text('SEAT STATUS'), findsOneWidget);
  });

  testWidgets('Viewer role: no-permission dialog renders with EbsOklch tokens',
      (tester) async {
    await tester.pumpWidget(wrap(overrides(role: 'Viewer'), launcher()));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.textContaining('do not have permission'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
  });

  testWidgets('root container uses EbsOklch.bg3 + line border', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(wrap(overrides(), launcher()));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // 루트 popover Container 를 찾는다 (border + bg3 일치).
    final containers = tester
        .widgetList<Container>(find.byType(Container))
        .where((c) {
      final d = c.decoration;
      return d is BoxDecoration && d.color == EbsOklch.bg3;
    });

    expect(containers, isNotEmpty,
        reason: 'Player edit popover should use EbsOklch.bg3 surface.');

    // border = EbsOklch.line
    final popover = containers.first;
    final deco = popover.decoration as BoxDecoration;
    final borderSide = (deco.border as Border).top;
    expect(borderSide.color, EbsOklch.line);
  });

  testWidgets('Save button background = EbsOklch.accent', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(wrap(overrides(), launcher()));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final saveBtn = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('Save'),
        matching: find.byType(ElevatedButton),
      ),
    );
    final bg = saveBtn.style?.backgroundColor?.resolve(<WidgetState>{});
    expect(bg, EbsOklch.accent);
  });
}
