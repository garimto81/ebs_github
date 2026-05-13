// Keyboard Hint Bar — V2 (Cycle 19 U2 OKLCH realignment).
//
// 디자인 reference:
//   - HTML SSOT: `docs/mockups/EBS Command Center/app.css` §".kbd-hint" + ".kbd"
//   - Spec: `docs/2. Development/2.4 Command Center/Command_Center_UI/Overview.md` §13
//
// V2 변경 — Broadcast Dark Amber OKLCH 정합:
//   * `cs.surfaceContainerLow`  → `EbsOklch.bg2`   (`.kbd { background: var(--bg-2) }`)
//   * `cs.outlineVariant`       → `EbsOklch.line`  (`.kbd { border: 1px solid var(--line) }`)
//   * Material 6종 accent 하드코딩 → 의미 보존 OKLCH 매핑
//     (FOLD = err / CHECK·CALL = info / BET·RAISE = accent / ALL-IN = err /
//      NEW·FINISH = ok / MISS DEAL = warn / DEBUG = fg3)
//   * `cs.onSurface` / `cs.onSurfaceVariant` → `EbsOklch.fg0` / `EbsOklch.fg3`
//
// 운영자 화면 하단 또는 상단 슬림 바 (높이 32px) 에 6개 단축키 칩 노출.
// 활성화 상태는 actionButtonProvider 매트릭스에 동기. 비활성 키는 dimmed.
//
// D7 / 통신 모델 / HandFSM 변경 없음 — 순수 시각 보강.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../foundation/theme/ebs_oklch.dart';
import '../../../foundation/theme/ebs_spacing.dart';
import '../../../foundation/theme/ebs_typography.dart';
import '../providers/action_button_provider.dart';

/// 단축키 시각 힌트 바 (높이 32px).
///
/// at_01_main_screen 의 InfoBar 와 SeatArea 사이에 삽입 권장.
class KeyboardHintBar extends ConsumerWidget {
  const KeyboardHintBar({super.key});

  static const double _heightPx = 32.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final btn = ref.watch(actionButtonProvider);

    final hints = <_HintData>[
      _HintData(
        keyLabel: 'F',
        actionLabel: 'FOLD',
        active: btn.isEnabled(CcAction.fold),
        accent: EbsOklch.err,
      ),
      _HintData(
        keyLabel: 'C',
        actionLabel: btn.checkCallLabel,
        active: btn.isEnabled(CcAction.checkCall),
        accent: EbsOklch.info,
      ),
      _HintData(
        keyLabel: 'B',
        actionLabel: btn.betRaiseLabel,
        active: btn.isEnabled(CcAction.betRaise),
        accent: EbsOklch.accent,
      ),
      _HintData(
        keyLabel: 'A',
        actionLabel: 'ALL-IN',
        active: btn.isEnabled(CcAction.allIn),
        accent: EbsOklch.err,
      ),
      _HintData(
        keyLabel: 'N',
        actionLabel: btn.isEnabled(CcAction.newHand) ? 'NEW' : 'FINISH',
        active: btn.isEnabled(CcAction.newHand) ||
            btn.isEnabled(CcAction.deal),
        accent: EbsOklch.ok,
      ),
      _HintData(
        keyLabel: 'M',
        actionLabel: 'MISS DEAL',
        active: btn.isEnabled(CcAction.missDeal),
        accent: EbsOklch.warn,
      ),
    ];

    return Container(
      height: _heightPx,
      padding: const EdgeInsets.symmetric(horizontal: EbsSpacing.md),
      decoration: const BoxDecoration(
        color: EbsOklch.bg2,
        border: Border(bottom: BorderSide(color: EbsOklch.line)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < hints.length; i++) ...[
            _HintChip(data: hints[i]),
            if (i < hints.length - 1) const SizedBox(width: EbsSpacing.sm),
          ],
          const Spacer(),
          const _HintChip(
            data: _HintData(
              keyLabel: 'Ctrl+L',
              actionLabel: 'DEBUG',
              active: true,
              accent: EbsOklch.fg3,
            ),
          ),
        ],
      ),
    );
  }
}

class _HintData {
  const _HintData({
    required this.keyLabel,
    required this.actionLabel,
    required this.active,
    required this.accent,
  });

  final String keyLabel;
  final String actionLabel;
  final bool active;
  final Color accent;
}

class _HintChip extends StatelessWidget {
  const _HintChip({required this.data});

  final _HintData data;

  @override
  Widget build(BuildContext context) {
    // HTML SSOT — active 칩: 액션 의미색 + bg-2 / inactive: line(border) + fg3(text).
    final keyColor = data.active ? data.accent : EbsOklch.line;
    final textColor = data.active ? EbsOklch.fg0 : EbsOklch.fg3;

    return Tooltip(
      message: data.active
          ? 'Press ${data.keyLabel} → ${data.actionLabel}'
          : '${data.actionLabel} (disabled)',
      waitDuration: const Duration(milliseconds: 600),
      child: Opacity(
        opacity: data.active ? 1.0 : 0.45,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: keyColor.withValues(alpha: 0.18),
                border: Border.all(color: keyColor, width: 1),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                data.keyLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                  color: keyColor,
                  height: 1.0,
                ),
              ),
            ),
            const SizedBox(width: EbsSpacing.xs),
            Text(
              data.actionLabel,
              style: EbsTypography.shortcutHint.copyWith(
                fontSize: 11,
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
