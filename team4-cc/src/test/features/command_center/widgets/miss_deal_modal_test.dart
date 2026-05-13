// MissDealModal widget tests — Cycle 19 Wave 4 U6 OKLCH realignment.
//
// 검증 범위:
//   1) 다이얼로그가 ProviderScope + MaterialApp 안에서 throw 없이 렌더링
//   2) 핸드/페이즈/팟 stat grid 가 입력값을 그대로 노출
//   3) 'aborted' 강조 / warn band / 두 액션 버튼이 모두 present
//   4) `Confirm` 클릭 → Future<bool?> 가 `true` 로 resolve
//   5) `Cancel` 클릭 → Future<bool?> 가 `false` 로 resolve
//   6) root container background = EbsOklch.bg2, border = EbsOklch.err
//   7) confirm 버튼 background = EbsOklch.err
//
// 키보드 단축키 (Esc/Enter) 는 Focus 트리 의존성으로 widget test 환경에서
// 결정적으로 재현하기 까다로워, 본 스위트는 사용자 mouse-click 경로만
// 강제한다. Esc/Enter 는 e2e (Playwright) 에서 검증.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebs_cc/features/command_center/widgets/miss_deal_modal.dart';
import 'package:ebs_cc/foundation/theme/ebs_oklch.dart';

void main() {
  Widget wrap(Widget home) => ProviderScope(
        child: MaterialApp(home: Scaffold(body: home)),
      );

  /// Modal 은 480px 고정 폭 + 18px insetPadding 좌우. 기본 widget test surface
  /// (800×600) 에서는 confirm 버튼 라벨("CONFIRM MISS DEAL · ENTER")이
  /// 액션 Row 를 overflow. 운영 환경(1920) 대비 합리적인 1200×900 로 모사.
  Future<void> useDesktopViewport(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
  }

  /// `showMissDealModal` 을 trigger 하는 launcher button. 테스트 헬퍼.
  Widget launcher({
    int handNumber = 142,
    String phase = 'PRE_FLOP',
    int potAmount = 12345,
    void Function(bool?)? onClosed,
  }) {
    return Builder(
      builder: (ctx) => Center(
        child: ElevatedButton(
          onPressed: () async {
            final r = await showMissDealModal(
              ctx,
              handNumber: handNumber,
              phase: phase,
              potAmount: potAmount,
            );
            onClosed?.call(r);
          },
          child: const Text('open'),
        ),
      ),
    );
  }

  testWidgets('renders within a Dialog without throwing', (tester) async {
    await useDesktopViewport(tester);
    await tester.pumpWidget(wrap(launcher()));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(MissDealModal), findsOneWidget);
    expect(find.text('Declare Miss Deal?'), findsOneWidget);
  });

  testWidgets('stat grid surfaces handNumber / phase / potAmount',
      (tester) async {
    await useDesktopViewport(tester);
    await tester.pumpWidget(wrap(launcher(
      handNumber: 142,
      phase: 'TURN',
      potAmount: 12345,
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('HAND'), findsOneWidget);
    expect(find.text('#142'), findsOneWidget);
    expect(find.text('PHASE'), findsOneWidget);
    expect(find.text('TURN'), findsOneWidget);
    expect(find.text('POT TO REFUND'), findsOneWidget);
    // _fmt(12345) → '12,345'
    expect(find.text('12,345'), findsOneWidget);
  });

  testWidgets('phase underscore is converted to space (PRE_FLOP → PRE FLOP)',
      (tester) async {
    await useDesktopViewport(tester);
    await tester.pumpWidget(wrap(launcher(phase: 'PRE_FLOP')));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('PRE FLOP'), findsOneWidget);
  });

  testWidgets('renders aborted emphasis + warn band', (tester) async {
    await useDesktopViewport(tester);
    await tester.pumpWidget(wrap(launcher(handNumber: 7)));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // body 'aborted' substring (rendered as TextSpan within Text.rich)
    expect(
      find.byWidgetPredicate((w) =>
          w is RichText &&
          w.text.toPlainText().contains('aborted')),
      findsWidgets,
    );
    // warn band references hand number
    expect(
      find.byWidgetPredicate((w) =>
          w is RichText &&
          w.text.toPlainText().contains('Hand #7') &&
          w.text.toPlainText().contains('logged')),
      findsWidgets,
    );
  });

  testWidgets('confirm button resolves with true; cancel with false',
      (tester) async {
    await useDesktopViewport(tester);

    bool? result1;
    await tester.pumpWidget(wrap(launcher(onClosed: (v) => result1 = v)));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('CONFIRM MISS DEAL · ENTER'));
    await tester.pumpAndSettle();
    expect(result1, isTrue);

    bool? result2;
    await tester.pumpWidget(wrap(launcher(onClosed: (v) => result2 = v)));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel · Esc'));
    await tester.pumpAndSettle();
    expect(result2, isFalse);
  });

  testWidgets('root surface uses EbsOklch.bg2 + EbsOklch.err border',
      (tester) async {
    await useDesktopViewport(tester);
    await tester.pumpWidget(wrap(launcher()));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final container = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byType(MissDealModal),
            matching: find.byType(Container),
          ),
        )
        .firstWhere(
          (c) {
            final d = c.decoration;
            return d is BoxDecoration && d.border != null;
          },
        );

    final deco = container.decoration as BoxDecoration;
    expect(deco.color, EbsOklch.bg2);
    final side = (deco.border as Border).top;
    expect(side.color, EbsOklch.err);
    // glow + drop shadow ≥ 2 entries
    expect((deco.boxShadow ?? const []).length, greaterThanOrEqualTo(2));
  });

  testWidgets('confirm ElevatedButton background = EbsOklch.err',
      (tester) async {
    await useDesktopViewport(tester);
    await tester.pumpWidget(wrap(launcher()));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final btn = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('CONFIRM MISS DEAL · ENTER'),
        matching: find.byType(ElevatedButton),
      ),
    );
    final bg = btn.style?.backgroundColor?.resolve(<WidgetState>{});
    expect(bg, EbsOklch.err);
  });
}
