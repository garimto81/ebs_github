// MiniTableDiagram — V4 (Cycle 19 U2 OKLCH realignment).
//
// 디자인 reference:
//   - HTML SSOT: `docs/mockups/EBS Command Center/MiniDiagram.jsx` +
//                `docs/mockups/EBS Command Center/app.css` §".mini-diagram"
//   - Spec: `docs/2. Development/2.4 Command Center/Command_Center_UI/Overview.md` §13
//
// V4 변경 — Broadcast Dark Amber OKLCH 정합:
//   * `cs.surfaceContainer`           → `EbsOklch.bgFelt` (felt)
//   * `cs.outlineVariant`             → `EbsOklch.line`   (rim)
//   * `cs.primary` (ACTING ring)      → `EbsOklch.accent` (`.pcol.action-on` ring)
//   * Material `0xFFFDD835` (dealer)  → `EbsOklch.posD`   (`--pos-d` bone white)
//   * Material `0xFF42A5F5` (SB)      → `EbsOklch.posSb`  (`--pos-sb` blue)
//   * Material `0xFFAB47BC` (BB)      → `EbsOklch.posBb`  (`--pos-bb` magenta)
//   * Badge text 대비 → `EbsOklch.cardBlack` (`oklch(0.18 0.04 60)` 대응)
//
// Flutter 구현: CustomPaint 기반. SVG 의존 없음.
//
// V10 결합 — POT 표시는 별도 위젯 (CcStatusBar 의 중앙 그룹) 으로 옮김.
// 본 위젯은 순수 oval + 10 dot 시각만 담당.
//
// R2 가드 — SB·BB 표시는 본 미니맵에만. 좌석 컬럼은 PositionShiftChip 사용.
//   (이중 표시 정보 중복 회피, Seat_Management.md §8 정합)
//
// D7 / 통신 / HandFSM 변경 없음.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../foundation/theme/ebs_oklch.dart';
import '../../../models/enums/seat_status.dart';
import '../providers/seat_provider.dart';

/// Mini oval table diagram (default 120×120).
class MiniTableDiagram extends ConsumerStatefulWidget {
  const MiniTableDiagram({
    this.size = 120,
    super.key,
  });

  final double size;

  @override
  ConsumerState<MiniTableDiagram> createState() => _MiniTableDiagramState();
}

class _MiniTableDiagramState extends ConsumerState<MiniTableDiagram>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seats = ref.watch(seatsProvider);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) => CustomPaint(
          painter: _MiniTablePainter(
            seats: seats,
            pulseT: _pulse.value,
          ),
        ),
      ),
    );
  }
}

class _MiniTablePainter extends CustomPainter {
  _MiniTablePainter({
    required this.seats,
    required this.pulseT,
  });

  final List<SeatState> seats;
  final double pulseT; // 0.0 ~ 1.0

  // OKLCH-aligned color slots. Centralized here so the painter is pure
  // const-Color-driven (no Theme.of lookup in paint loop).
  static const Color _felt = EbsOklch.bgFelt;
  static const Color _rim = EbsOklch.line;
  static const Color _occupied = EbsOklch.fg0;
  static const Color _action = EbsOklch.accent;
  static const Color _dealer = EbsOklch.posD;
  static const Color _sb = EbsOklch.posSb;
  static const Color _bb = EbsOklch.posBb;
  // `.pcol.folded { opacity: 0.42; filter: saturate(0.6) }` → fg3 (muted) 으로 환원.
  static const Color _folded = EbsOklch.fg3;
  // `TABLE` center label — muted to felt overlay (alpha ≈ 0.55 / fg2).
  static final Color _label = EbsOklch.fg2.withValues(alpha: 0.55);
  // Badge text 대비 — HTML 의 `oklch(0.18 0.04 60)` 와 동등 (card-black 근사).
  static const Color _badgeText = EbsOklch.cardBlack;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rx = size.width * 0.42;
    final ry = size.height * 0.32;

    // Felt
    final feltPaint = Paint()..color = _felt;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2),
      feltPaint,
    );

    // Rim
    final rimPaint = Paint()
      ..color = _rim
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2),
      rimPaint,
    );

    // Center label
    final tp = TextPainter(
      text: TextSpan(
        text: 'TABLE',
        style: TextStyle(
          color: _label,
          fontSize: 7,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));

    // 10 seat dots — clockwise from bottom (S1 at bottom-right of dealer)
    for (var i = 0; i < 10; i++) {
      final seatNo = i + 1;
      final seat = seats.firstWhere(
        (s) => s.seatNo == seatNo,
        orElse: () => SeatState(seatNo: seatNo),
      );
      final angle = math.pi / 2 - (2 * math.pi * i / 10);
      final dx = cx + rx * math.cos(angle);
      final dy = cy - ry * math.sin(angle);

      Color fill;
      double radius = 4;
      if (seat.actionOn) {
        fill = _action;
        radius = 5.5;
        // pulse ring — `.pcol.action-on::before { animation: action-pulse }`
        final ringR = 5.5 + 6 * pulseT;
        final ringA = 0.5 * (1 - pulseT);
        final ring = Paint()
          ..color = _action.withValues(alpha: ringA)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
        canvas.drawCircle(Offset(dx, dy), ringR, ring);
      } else if (!seat.isOccupied) {
        fill = Colors.transparent;
      } else if (seat.activity == PlayerActivity.folded) {
        fill = _folded;
      } else {
        fill = _occupied;
      }

      final dotPaint = Paint()..color = fill;
      canvas.drawCircle(Offset(dx, dy), radius, dotPaint);

      if (!seat.isOccupied) {
        final outlinePaint = Paint()
          ..color = _rim
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawCircle(Offset(dx, dy), radius, outlinePaint);
      }

      // seat number
      if (seat.isOccupied) {
        final numTp = TextPainter(
          text: TextSpan(
            text: '$seatNo',
            style: const TextStyle(
              color: _felt,
              fontSize: 6,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        numTp.paint(
          canvas,
          Offset(dx - numTp.width / 2, dy - numTp.height / 2),
        );
      }

      // Position badge — D / SB / BB (R2 가드: 단일 source — 미니맵만).
      // 색 → `.pb-row.pos-D | pos-SB | pos-BB` 의 border-color.
      String? badgeText;
      Color badgeBg = _dealer;
      if (seat.isDealer) {
        badgeText = 'D';
        badgeBg = _dealer;
      } else if (seat.isSB) {
        badgeText = 'SB';
        badgeBg = _sb;
      } else if (seat.isBB) {
        badgeText = 'BB';
        badgeBg = _bb;
      }
      if (badgeText != null) {
        // Badge offset toward outside
        final ox = (dx - cx) * 0.30;
        final oy = (dy - cy) * 0.30;
        final bx = dx + ox;
        final by = dy + oy;
        final badgeW = badgeText.length == 1 ? 8.0 : 11.0;
        final badgeRect = Rect.fromCenter(
          center: Offset(bx, by),
          width: badgeW,
          height: 7,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(badgeRect, const Radius.circular(2)),
          Paint()..color = badgeBg,
        );
        final badgeTp = TextPainter(
          text: TextSpan(
            text: badgeText,
            style: const TextStyle(
              color: _badgeText,
              fontSize: 5.5,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        badgeTp.paint(
          canvas,
          Offset(bx - badgeTp.width / 2, by - badgeTp.height / 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MiniTablePainter old) =>
      old.seats != seats || old.pulseT != pulseT;
}
