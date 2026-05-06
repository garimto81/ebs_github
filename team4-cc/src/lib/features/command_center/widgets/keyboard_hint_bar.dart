// Keyboard Hint Bar — V1 of B-team4-011 visual uplift.
//
// 디자인 reference: claude-design-archive/2026-05-06/cc-react-extracted/App.jsx
//   §"kbd-hint" (TopStrip 우측 단축키 시각 표시).
//
// 운영자 화면 하단 또는 상단 슬림 바 (높이 32px) 에 6개 단축키 칩 노출.
// 활성화 상태는 actionButtonProvider 매트릭스에 동기. 비활성 키는 dimmed.
//
// D7 / 통신 모델 / HandFSM 변경 없음 — 순수 시각 보강.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final cs = Theme.of(context).colorScheme;

    final hints = <_HintData>[
      _HintData(
        keyLabel: 'F',
        actionLabel: 'FOLD',
        active: btn.isEnabled(CcAction.fold),
        accent: cs.error,
      ),
      _HintData(
        keyLabel: 'C',
        actionLabel: btn.checkCallLabel,
        active: btn.isEnabled(CcAction.checkCall),
        accent: const Color(0xFF78909C),
      ),
      _HintData(
        keyLabel: 'B',
        actionLabel: btn.betRaiseLabel,
        active: btn.isEnabled(CcAction.betRaise),
        accent: const Color(0xFFFFA726),
      ),
      _HintData(
        keyLabel: 'A',
        actionLabel: 'ALL-IN',
        active: btn.isEnabled(CcAction.allIn),
        accent: const Color(0xFFEF5350),
      ),
      _HintData(
        keyLabel: 'N',
        actionLabel: btn.isEnabled(CcAction.newHand) ? 'NEW' : 'FINISH',
        active: btn.isEnabled(CcAction.newHand) ||
            btn.isEnabled(CcAction.deal),
        accent: const Color(0xFF66BB6A),
      ),
      _HintData(
        keyLabel: 'M',
        actionLabel: 'MISS DEAL',
        active: btn.isEnabled(CcAction.missDeal),
        accent: const Color(0xFFFFB74D),
      ),
    ];

    return Container(
      height: _heightPx,
      padding: const EdgeInsets.symmetric(horizontal: EbsSpacing.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
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
              accent: Color(0xFF9E9E9E),
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
    final cs = Theme.of(context).colorScheme;
    final keyColor = data.active ? data.accent : cs.outline;
    final textColor = data.active ? cs.onSurface : cs.onSurfaceVariant;

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
