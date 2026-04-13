// M-05 Seat Cell widget (BS-05-03 §시각 규격, CCR-032).
// Uses SeatColors SSOT from foundation/theme for CC-Overlay consistency.
//
// UI-02 변경 (2026-04-13):
// - 국기 추가 (country_code → Flag emoji/icon)
// - Equity: '%' 숫자만 (프로그레스 바 제거)
// - 인라인 편집: 각 요소 탭 → 수정 다이얼로그 (화면 2 좌석 상세 패널 대체)
// - 수동 편집 우선 원칙: 동기화 아이콘(🔄)으로 DB 값 수용/거부 제어
// - 좌석 번호: S1~S10 (기존 S0~S9에서 변경)

import 'package:flutter/material.dart';

import '../../../foundation/theme/seat_colors.dart';

class SeatCell extends StatelessWidget {
  const SeatCell({super.key, required this.seatNo});

  /// Seat number: 1~10 (D 왼쪽 S1=SB, D 오른쪽 S10).
  final int seatNo;

  @override
  Widget build(BuildContext context) => Container(
        color: SeatColors.vacant,
        child: Center(child: Text('S$seatNo')),
      );
}
