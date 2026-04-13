// AT-03 Card Selector — 합성 카드 선택 방식 (UI-02 화면 3, 2026-04-13 변경).
//
// 기존: 4×13 수트×랭크 분리 그리드 (수트 행 + 랭크 열 교차점 탭)
// 변경: **합성 카드 선택** — 셀 자체가 "A♠", "K♥" 등 카드 이미지/텍스트.
//       즉시 시각 식별 가능, 터치 정확도 향상 (셀 60×72px).
//
// - 1탭 선택, 파란 테두리 하이라이트
// - 사용된 카드: opacity 0.3 + ✕
// - [Confirm]으로 확정 → CardDetected 이벤트 합성
// - [Cancel]으로 취소
// - 560×auto 모달, 1회 진입에 1장만 선택

import 'package:flutter/material.dart';

class At03CardSelector extends StatelessWidget {
  const At03CardSelector({super.key});

  @override
  Widget build(BuildContext context) => const Placeholder();
}
