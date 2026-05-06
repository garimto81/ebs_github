// MiniTableDiagram — V3 of B-team4-011 visual uplift.
//
// 디자인 reference: claude-design-archive/2026-05-06/cc-react-extracted/MiniDiagram.jsx
//   §"MiniDiagram" (120×120 SVG oval + 10 dots + D/SB/BB tags + ACTING pulse).
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
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) => CustomPaint(
          painter: _MiniTablePainter(
            seats: seats,
            pulseT: _pulse.value,
            feltColor: cs.surfaceContainer,
            rimColor: cs.outlineVariant,
            occupiedColor: cs.onSurface,
            foldedColor: cs.onSurfaceVariant.withValues(alpha: 0.5),
            actionColor: cs.primary,
            dealerColor: const Color(0xFFFDD835),
            sbColor: const Color(0xFF42A5F5),
            bbColor: const Color(0xFFAB47BC),
            labelColor: cs.onSurface.withValues(alpha: 0.4),
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
    required this.feltColor,
    required this.rimColor,
    required this.occupiedColor,
    required this.foldedColor,
    required this.actionColor,
    required this.dealerColor,
    required this.sbColor,
    required this.bbColor,
    required this.labelColor,
  });

  final List<SeatState> seats;
  final double pulseT; // 0.0 ~ 1.0
  final Color feltColor;
  final Color rimColor;
  final Color occupiedColor;
  final Color foldedColor;
  final Color actionColor;
  final Color dealerColor;
  final Color sbColor;
  final Color bbColor;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rx = size.width * 0.42;
    final ry = size.height * 0.32;

    // Felt
    final feltPaint = Paint()..color = feltColor;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2),
      feltPaint,
    );

    // Rim
    final rimPaint = Paint()
      ..color = rimColor
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
          color: labelColor,
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
        fill = actionColor;
        radius = 5.5;
        // pulse ring
        final ringR = 5.5 + 6 * pulseT;
        final ringA = 0.5 * (1 - pulseT);
        final ring = Paint()
          ..color = actionColor.withValues(alpha: ringA)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
        canvas.drawCircle(Offset(dx, dy), ringR, ring);
      } else if (!seat.isOccupied) {
        fill = Colors.transparent;
      } else if (seat.activity == PlayerActivity.folded) {
        fill = foldedColor;
      } else {
        fill = occupiedColor;
      }

      final dotPaint = Paint()..color = fill;
      canvas.drawCircle(Offset(dx, dy), radius, dotPaint);

      if (!seat.isOccupied) {
        final outlinePaint = Paint()
          ..color = rimColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawCircle(Offset(dx, dy), radius, outlinePaint);
      }

      // seat number
      if (seat.isOccupied) {
        final numTp = TextPainter(
          text: TextSpan(
            text: '$seatNo',
            style: TextStyle(
              color: feltColor,
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

      // Position badge — D / SB / BB (R2 가드: 단일 source — 미니맵만)
      String? badgeText;
      Color badgeBg = dealerColor;
      if (seat.isDealer) {
        badgeText = 'D';
        badgeBg = dealerColor;
      } else if (seat.isSB) {
        badgeText = 'SB';
        badgeBg = sbColor;
      } else if (seat.isBB) {
        badgeText = 'BB';
        badgeBg = bbColor;
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
              color: Colors.black,
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
