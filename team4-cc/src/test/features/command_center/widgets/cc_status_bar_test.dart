// CcStatusBar widget smoke tests — Cycle 19 U2 OKLCH realignment.
//
// 검증 범위:
//   - 위젯이 ProviderScope + MaterialApp 안에서 throw 없이 렌더링됨.
//   - 컨테이너 background 가 EbsOklch.bg1 와 일치.
//   - bottom border 가 EbsOklch.line 과 일치.
//   - phase pill / POT bar 등 동적 색은 분리 helper 테스트 (private impl 이라
//     finder 로 직접 검증은 어려움 — pumping smoke 만 강제).
//
// Note: CC StatusBar 는 1920px Operator 화면 가정. widget test 기본 surface
//       (800×600) 에서는 좌/중/우 3-group + Spacer 가 overflow. 모든 테스트는
//       `setSurfaceSize(1920×100)` 로 운영 환경 폭을 모사한다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebs_cc/features/command_center/widgets/cc_status_bar.dart';
import 'package:ebs_cc/foundation/theme/ebs_oklch.dart';

void main() {
  Widget wrap(Widget child, {ThemeData? theme}) => ProviderScope(
        child: MaterialApp(
          theme: theme,
          home: const Scaffold(body: CcStatusBar()),
        ),
      );

  // 운영 화면 폭 (1920) 을 모사. tearDown 으로 기본값 복원.
  Future<void> useOperatorViewport(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1920, 100));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
  }

  // CcStatusBar 의 root Container 를 찾는다 (Scaffold body 의 첫 자식).
  Container rootContainer(WidgetTester tester) {
    return tester
        .widgetList<Container>(
          find.descendant(
            of: find.byType(CcStatusBar),
            matching: find.byType(Container),
          ),
        )
        .first;
  }

  testWidgets('renders within a ProviderScope without throwing',
      (tester) async {
    await useOperatorViewport(tester);
    await tester.pumpWidget(wrap(const CcStatusBar()));
    expect(find.byType(CcStatusBar), findsOneWidget);
  });

  testWidgets('root container uses EbsOklch.bg1 background', (tester) async {
    await useOperatorViewport(tester);
    await tester.pumpWidget(wrap(const CcStatusBar()));

    final decoration = rootContainer(tester).decoration as BoxDecoration?;
    expect(decoration, isNotNull);
    expect(decoration!.color, equals(EbsOklch.bg1));
  });

  testWidgets('bottom border uses EbsOklch.line', (tester) async {
    await useOperatorViewport(tester);
    await tester.pumpWidget(wrap(const CcStatusBar()));

    final decoration = rootContainer(tester).decoration as BoxDecoration?;
    final border = decoration!.border as Border?;
    expect(border, isNotNull);
    expect(border!.bottom.color, equals(EbsOklch.line));
  });

  testWidgets('renders independently of Theme ColorScheme (OKLCH-locked)',
      (tester) async {
    // 회귀 가드 — 이전 V2 는 cs.primary / cs.surfaceContainerHigh 등에 강결합.
    // V3 부터는 EbsOklch.* 정적 상수만 사용해야 한다.
    await useOperatorViewport(tester);
    await tester.pumpWidget(
      wrap(
        const CcStatusBar(),
        theme: ThemeData(
          colorScheme: const ColorScheme.dark(
            primary: Colors.transparent,
            surfaceContainerHigh: Colors.transparent,
            outlineVariant: Colors.transparent,
            onSurface: Colors.transparent,
            onSurfaceVariant: Colors.transparent,
          ),
        ),
      ),
    );
    expect(find.byType(CcStatusBar), findsOneWidget);
    // bg1 이 Theme override 와 무관하게 살아 있어야 한다.
    final decoration = rootContainer(tester).decoration as BoxDecoration?;
    expect(decoration?.color, equals(EbsOklch.bg1));
  });
}
