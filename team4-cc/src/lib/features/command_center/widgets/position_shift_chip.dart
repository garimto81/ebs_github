// PositionShiftChip — V4 of B-team4-011 visual uplift.
//
// 디자인 reference: claude-design-archive/2026-05-06/cc-react-extracted/PlayerColumn.jsx
//   §"PosBlock" (D/SB/BB/STR 3 sub-rows + ‹ › arrows).
//
// Position 종류:
//   D (BTN) / SB / BB / STRADDLE
//
// shift 권한 (Seat_Management.md §8.3):
//   D, STRADDLE — CC 운영자 (idle/handComplete 시만, §5.2 핸드 중 차단)
//   SB, BB      — Game Engine 자동 결정 (§2.3.3) — shift 비활성 + tooltip 안내
//
// D7 / 통신 / HandFSM 변경 없음 — 시각 + UX 보강만.

import 'package:flutter/material.dart';

import '../../../foundation/theme/seat_colors.dart';

enum PositionKind { dealer, sb, bb, straddle }

extension on PositionKind {
  String get displayLabel => switch (this) {
        PositionKind.dealer => 'BTN',
        PositionKind.sb => 'SB',
        PositionKind.bb => 'BB',
        PositionKind.straddle => 'STR',
      };

  String get fullName => switch (this) {
        PositionKind.dealer => 'Dealer',
        PositionKind.sb => 'Small Blind',
        PositionKind.bb => 'Big Blind',
        PositionKind.straddle => 'Straddle',
      };

  /// CC 운영자가 shift 가능한가 (HandFSM idle/handComplete 시만 의미).
  bool get isOperatorShiftable => switch (this) {
        PositionKind.dealer => true,
        PositionKind.straddle => true,
        PositionKind.sb => false, // Engine 결정
        PositionKind.bb => false, // Engine 결정
      };

  Color get color => switch (this) {
        PositionKind.dealer => SeatColors.dealer,
        PositionKind.sb => SeatColors.sb,
        PositionKind.bb => SeatColors.bb,
        PositionKind.straddle => const Color(0xFFFF7043),
      };
}

/// Position shift chip — 한 종류의 position 마커 + 좌/우 shift 화살표.
///
/// `present=true` 일 때 chip 본체 표시, shift 가능하면 ‹ › 활성.
/// `present=false` 일 때 placeholder ("—") 표시.
class PositionShiftChip extends StatelessWidget {
  const PositionShiftChip({
    required this.kind,
    required this.present,
    required this.handPhaseAllowsShift,
    this.onShiftPrev,
    this.onShiftNext,
    super.key,
  });

  /// 어느 position 인가.
  final PositionKind kind;

  /// 이 좌석에 해당 마커가 부착됐는가.
  final bool present;

  /// 현재 HandFSM 상태가 shift 를 허용하는가 (idle/handComplete 시 true).
  final bool handPhaseAllowsShift;

  /// 반시계 방향 (‹) shift 콜백 — 활성 시만 호출됨.
  final VoidCallback? onShiftPrev;

  /// 시계 방향 (›) shift 콜백.
  final VoidCallback? onShiftNext;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (!present) {
      return _PlaceholderRow(label: kind.displayLabel, cs: cs);
    }

    final canShift = kind.isOperatorShiftable && handPhaseAllowsShift;
    final color = kind.color;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Arrow(
          direction: _ArrowDir.prev,
          enabled: canShift,
          tooltip: canShift
              ? 'Shift ${kind.fullName} counter-clockwise'
              : !kind.isOperatorShiftable
                  ? '${kind.fullName} — Engine 자동 결정 (변경 불가)'
                  : '핸드 진행 중에는 변경 불가',
          onTap: canShift ? onShiftPrev : null,
          color: color,
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            border: Border.all(color: color, width: 1),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            kind.displayLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.6,
            ),
          ),
        ),
        _Arrow(
          direction: _ArrowDir.next,
          enabled: canShift,
          tooltip: canShift
              ? 'Shift ${kind.fullName} clockwise'
              : !kind.isOperatorShiftable
                  ? '${kind.fullName} — Engine 자동 결정 (변경 불가)'
                  : '핸드 진행 중에는 변경 불가',
          onTap: canShift ? onShiftNext : null,
          color: color,
        ),
      ],
    );
  }
}

class _PlaceholderRow extends StatelessWidget {
  const _PlaceholderRow({required this.label, required this.cs});

  final String label;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: cs.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '—',
            style: TextStyle(
              fontSize: 11,
              color: cs.onSurfaceVariant.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

enum _ArrowDir { prev, next }

class _Arrow extends StatelessWidget {
  const _Arrow({
    required this.direction,
    required this.enabled,
    required this.tooltip,
    required this.color,
    this.onTap,
  });

  final _ArrowDir direction;
  final bool enabled;
  final String tooltip;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final iconColor = enabled ? color : cs.onSurfaceVariant.withValues(alpha: 0.4);
    final char = direction == _ArrowDir.prev ? '‹' : '›';

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(3),
        child: Container(
          width: 16,
          height: 18,
          alignment: Alignment.center,
          child: Text(
            char,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: iconColor,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}
