// ActionBadge — LAST action display pill for PlayerColumn (Cycle 19 Wave 3).
//
// 디자인 reference: claude-design-archive/2026-05-06/cc-react-extracted/PlayerColumn.jsx
//   §"ROW 7 — LAST ACTION"  + app.css `.row-action.{fold|check|call|bet|raise|allin}`
//
// 토큰 매핑 (Cycle 21 UI-quality-fix — HTML mockup SSOT 정합):
//   FOLD       → EbsOklch.fg2     (muted-gray, HTML #616161)
//   CHECK/CALL → EbsOklch.info    (blue, HTML #1976d2)
//   BET        → EbsOklch.accent  (broadcast amber, HTML #f9a825)
//   RAISE      → EbsOklch.err     (red, HTML #e53935)
//   ALL-IN     → EbsOklch.warn    (gold)
//   none       → fg-3 dashed placeholder
//
// 사용: SeatCell LAST 행에서 ActionBadge.fromActivity() 로 PlayerActivity 매핑.
// 기존 inline `_RowCell` 의 highlightColor 분기 제거 후 이 위젯으로 위임.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../foundation/theme/ebs_oklch.dart';
import '../../../models/enums/seat_status.dart';

// ── Test-visible keys ──────────────────────────────────────────────────
/// Key for the pulse bar inside CHECK [ActionBadge]. Used in widget tests.
const Key kActionBadgePulseBarKey = Key('action-badge-pulse-bar');

/// Key for the dashed-border [CustomPaint] wrapping the CALL [ActionBadge].
/// CALL uses visual_indicator=null (viewer: 미표시), dashed = operator signal.
const Key kActionBadgeCallDashedKey = Key('action-badge-call-dashed');


/// LAST action 종류. `none` = 미선택/대기 (placeholder 표시).
enum ActionBadgeType {
  none,
  fold,
  check,
  call,
  bet,
  raise,
  allIn,
}

extension ActionBadgeTypeX on ActionBadgeType {
  String get label => switch (this) {
        ActionBadgeType.none => '—',
        ActionBadgeType.fold => 'FOLD',
        ActionBadgeType.check => 'CHECK',
        ActionBadgeType.call => 'CALL',
        ActionBadgeType.bet => 'BET',
        ActionBadgeType.raise => 'RAISE',
        ActionBadgeType.allIn => 'ALL-IN',
      };

  /// 본문(label) 색 + 배경/테두리 tint 색의 기준이 되는 token.
  ///
  /// HTML mockup SSOT (docs/mockups/EBS Command Center/action-indicator-*.html):
  ///   BET   #f9a825 → accent  CHECK #1976d2 → info
  ///   RAISE #e53935 → err     CALL  #1976d2 → info (CC 운영자 뷰)
  ///   FOLD  #616161 → fg2     ALL-IN gold   → warn
  Color get tone => switch (this) {
        ActionBadgeType.none => EbsOklch.fg3,
        ActionBadgeType.fold => EbsOklch.fg2,    // HTML: #616161 → fg2 muted-gray
        ActionBadgeType.check => EbsOklch.info,  // HTML: #1976d2 → info blue
        ActionBadgeType.call => EbsOklch.info,   // HTML: CALL = CHECK color (CC 운영자)
        ActionBadgeType.bet => EbsOklch.accent,  // HTML: #f9a825 ≈ accent amber ✓
        ActionBadgeType.raise => EbsOklch.err,   // HTML: #e53935 → err red
        ActionBadgeType.allIn => EbsOklch.warn,  // gold ✓
      };
}

/// PlayerColumn LAST 행에 표시되는 액션 배지.
///
/// `label` 인자를 지정하면 enum 기본 라벨 대신 사용 (예: SIT OUT).
/// `onTap` 콜백을 받으면 GestureDetector 로 감싸 토글 인터랙션 허용.
class ActionBadge extends StatelessWidget {
  const ActionBadge({
    required this.type,
    this.label,
    this.onTap,
    super.key,
  });

  final ActionBadgeType type;
  final String? label;
  final VoidCallback? onTap;

  /// `SeatState.activity` + `currentBet` 으로 ActionBadge 를 구성하는 헬퍼.
  ///
  /// SeatCell LAST 행 이관 시 사용. `activity` 만으로는 BET/RAISE/CALL/CHECK
  /// 를 구분할 수 없으므로 SeatCell 측에서 외부 결정 후 `type` 직접 주입을
  /// 권장. 현재는 PlayerActivity.{folded,allIn,sittingOut,active} 만 매핑.
  factory ActionBadge.fromActivity(
    PlayerActivity activity, {
    VoidCallback? onTap,
  }) {
    return switch (activity) {
      PlayerActivity.folded => ActionBadge(type: ActionBadgeType.fold, onTap: onTap),
      PlayerActivity.allIn => ActionBadge(type: ActionBadgeType.allIn, onTap: onTap),
      PlayerActivity.sittingOut => ActionBadge(
          type: ActionBadgeType.none,
          label: 'SIT OUT',
          onTap: onTap,
        ),
      PlayerActivity.active => ActionBadge(type: ActionBadgeType.none, onTap: onTap),
    };
  }

  @override
  Widget build(BuildContext context) {
    final tone = type.tone;
    final isPlaceholder = type == ActionBadgeType.none;
    final isCall = type == ActionBadgeType.call;
    final isCheck = type == ActionBadgeType.check;

    // ── Content row ──────────────────────────────────────────────────
    final contentRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // LBL — 9px / w700 / fg-3 (app.css `.row-lbl`)
        const Text(
          'LAST',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: EbsOklch.fg3,
            letterSpacing: 0.10 * 9,
          ),
        ),
        // VAL — mono 13px / w900 / tone color
        Flexible(
          child: Text(
            label ?? type.label,
            style: TextStyle(
              fontSize: isPlaceholder ? 12 : 13,
              fontWeight: isPlaceholder ? FontWeight.w600 : FontWeight.w900,
              color: isPlaceholder ? EbsOklch.fg3 : tone,
              fontFamily: isPlaceholder ? null : 'monospace',
              letterSpacing: isPlaceholder ? 0 : 1.3,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );

    // ── CHECK: pulse bar (HTML SSOT: .pulse { height:2px } 1.4s) ────
    final Widget innerChild = isCheck
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              contentRow,
              _PulseBar(key: kActionBadgePulseBarKey, color: tone),
            ],
          )
        : contentRow;

    // ── CALL: dashed border (visual_indicator=null — CC only) ────────
    // HTML SSOT: .indicator.call { border-style: dashed } (action-indicator-bet.html)
    final Widget pill;
    if (isCall) {
      pill = CustomPaint(
        key: kActionBadgeCallDashedKey,
        painter: _DashedBorderPainter(color: tone.withValues(alpha: 0.5)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: tone.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(3),
          ),
          child: innerChild,
        ),
      );
    } else {
      pill = Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: isPlaceholder ? Colors.transparent : tone.withValues(alpha: 0.18),
          border: Border.all(
            color: isPlaceholder ? EbsOklch.line : tone.withValues(alpha: 0.5),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(3),
        ),
        child: innerChild,
      );
    }

    if (onTap == null) return pill;
    return GestureDetector(onTap: onTap, child: pill);
  }
}

// ── _PulseBar ──────────────────────────────────────────────────────────

/// CHECK 표식 하단 2px 펄스 바.
/// HTML SSOT: .pulse { height:2px; opacity:0.4 } + 1.4s 반복.
class _PulseBar extends StatefulWidget {
  const _PulseBar({required this.color, super.key});
  final Color color;

  @override
  State<_PulseBar> createState() => _PulseBarState();
}

class _PulseBarState extends State<_PulseBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400), // HTML: pulse 1.4s
    )..repeat(reverse: true);
    // opacity oscillates: 0.15 ↔ 0.55 (HTML .pulse opacity 0.4 base)
    _anim = Tween<double>(begin: 0.15, end: 0.55).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: 2,
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: _anim.value),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}

// ── _DashedBorderPainter ───────────────────────────────────────────────

/// CALL 배지용 대시 둥근 테두리 페인터.
/// HTML SSOT: .indicator.call { border-style: dashed } (action-indicator-bet.html).
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  final Color color;
  static const double _radius = 3.0;
  static const double _dashLen = 4.0;
  static const double _gapLen = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
      const Radius.circular(_radius),
    );

    canvas.drawPath(_buildDashedPath(Path()..addRRect(rrect)), paint);
  }

  Path _buildDashedPath(Path source) {
    final result = Path();
    for (final metric in source.computeMetrics()) {
      var dist = 0.0;
      final total = metric.length;
      while (dist < total) {
        final end = math.min(dist + _dashLen, total);
        result.addPath(metric.extractPath(dist, end), Offset.zero);
        dist += _dashLen + _gapLen;
      }
    }
    return result;
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) => old.color != color;
}