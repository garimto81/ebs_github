// ActionBadge — LAST action display pill for PlayerColumn (Cycle 19 Wave 3).
//
// 디자인 reference: claude-design-archive/2026-05-06/cc-react-extracted/PlayerColumn.jsx
//   §"ROW 7 — LAST ACTION"  + app.css `.row-action.{fold|check|call|bet|raise|allin}`
//
// 토큰 매핑 (cycle-19 U3 spec):
//   FOLD       → EbsOklch.err     (red)
//   CHECK/CALL → EbsOklch.ok      (green)
//   BET/RAISE  → EbsOklch.accent  (broadcast amber)
//   ALL-IN     → EbsOklch.warn    (gold)
//   none       → fg-3 dashed placeholder
//
// 사용: SeatCell LAST 행에서 ActionBadge.fromActivity() 로 PlayerActivity 매핑.
// 기존 inline `_RowCell` 의 highlightColor 분기 제거 후 이 위젯으로 위임.

import 'package:flutter/material.dart';

import '../../../foundation/theme/ebs_oklch.dart';
import '../../../models/enums/seat_status.dart';

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
  Color get tone => switch (this) {
        ActionBadgeType.none => EbsOklch.fg3,
        ActionBadgeType.fold => EbsOklch.err,
        ActionBadgeType.check => EbsOklch.ok,
        ActionBadgeType.call => EbsOklch.ok,
        ActionBadgeType.bet => EbsOklch.accent,
        ActionBadgeType.raise => EbsOklch.accent,
        ActionBadgeType.allIn => EbsOklch.warn,
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

    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        // `.row-action.<state>` background + border (app.css L733-744).
        color: isPlaceholder ? Colors.transparent : tone.withValues(alpha: 0.18),
        border: Border.all(
          color: isPlaceholder
              ? EbsOklch.line
              : tone.withValues(alpha: 0.5),
          width: 1,
          style: isPlaceholder ? BorderStyle.solid : BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
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
          // VAL — mono 13px / w900 / tone color (app.css `.row-action.active`)
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
      ),
    );

    if (onTap == null) return pill;
    return GestureDetector(onTap: onTap, child: pill);
  }
}
