// MissDealModal — Cycle 19 Wave 4 U6 (Broadcast Dark Amber OKLCH).
//
// 현재 핸드 무효 선언 confirm 다이얼로그. 베팅 토큰/안테/블라인드는 핸드
// 시작 시점 stack 으로 복구되고, 핸드는 통계에서 제외된다.
//
// 디자인 reference:
//   - HTML SSOT  : `docs/mockups/EBS Command Center/MissDealModal.jsx`
//   - CSS SSOT   : `docs/mockups/EBS Command Center/app.css` §".md-modal"
//   - 토큰 적용  :
//       Border          : EbsOklch.err (1px solid)
//       Glow            : err withOpacity(0.4), blurRadius 20 (≈ `0 0 60px err/0.25`)
//       Surface         : EbsOklch.bg2 + EbsShadows.pop (drop)
//       Title icon      : EbsOklch.err, 48px
//       3-col stat grid : EbsOklch.bg3 카드, lbl=fg3 / val=fg0
//       Pot accent      : EbsOklch.accent
//       Warn band       : EbsOklch.warn text on warn-tinted bg
//       Confirm button  : EbsOklch.err background
//
// 기존 inline `_showMissDealConfirm` (action_panel.dart) 의 후속 SSOT.
// action_panel 와의 wiring 은 별도 Unit (U5/U7) 소관 — 이 widget 은
// 독립 호출 가능한 helper `showMissDealModal()` 를 노출.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../foundation/theme/ebs_oklch.dart';
import '../../../foundation/theme/ebs_shadows.dart';
import '../../../foundation/theme/ebs_spacing.dart';
import '../../../foundation/theme/ebs_typography.dart';

// ---------------------------------------------------------------------------
// Show helper
// ---------------------------------------------------------------------------

/// Show the Miss Deal confirm modal. Returns true if confirmed.
///
/// [handNumber] : 현재 핸드 번호 (예: 142)
/// [phase]      : 진행 단계 라벨 (예: "PRE_FLOP", "FLOP")
/// [potAmount]  : 환불될 pot 금액 (베팅 토큰 단위)
Future<bool?> showMissDealModal(
  BuildContext context, {
  required int handNumber,
  required String phase,
  required int potAmount,
}) {
  return showDialog<bool>(
    context: context,
    barrierColor: const Color(0x8C000000), // matches `.cp-backdrop` overlay
    builder: (_) => MissDealModal(
      handNumber: handNumber,
      phase: phase,
      potAmount: potAmount,
    ),
  );
}

// ---------------------------------------------------------------------------
// Format helper — match HTML mockup `window.fmt(n)` (locale-grouped integer)
// ---------------------------------------------------------------------------

String _fmt(int v) {
  final s = v.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

// ---------------------------------------------------------------------------
// MissDealModal — destructive confirm dialog
// ---------------------------------------------------------------------------

class MissDealModal extends StatelessWidget {
  const MissDealModal({
    super.key,
    required this.handNumber,
    required this.phase,
    required this.potAmount,
  });

  final int handNumber;
  final String phase;
  final int potAmount;

  @override
  Widget build(BuildContext context) {
    // Esc → cancel, Enter → confirm (matches HTML mockup keyboard contract).
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).pop(false),
        const SingleActivator(LogicalKeyboardKey.enter): () =>
            Navigator.of(context).pop(true),
        const SingleActivator(LogicalKeyboardKey.numpadEnter): () =>
            Navigator.of(context).pop(true),
      },
      child: Focus(
        autofocus: true,
        child: Dialog(
          // Surface tokens come from the inner Container; Dialog itself is
          // transparent so the err-border + glow render correctly outside the
          // body without rounded-corner clipping.
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: EbsSpacing.lg,
            vertical: EbsSpacing.xl,
          ),
          child: Container(
            width: EbsSpacing.modalWidthSm, // 480 ≈ `.md-modal { width: min(480px) }`
            decoration: BoxDecoration(
              color: EbsOklch.bg2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: EbsOklch.err, width: 1),
              boxShadow: [
                // Drop shadow (matches `var(--shadow-pop)`).
                ...EbsShadows.pop,
                // Outer red glow (matches `0 0 60px oklch(err / 0.25)`).
                BoxShadow(
                  color: EbsOklch.err.withValues(alpha: 0.40),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(
              EbsSpacing.lg + EbsSpacing.xs, // 28
              EbsSpacing.lg + EbsSpacing.xs, // 28
              EbsSpacing.lg + EbsSpacing.xs, // 28
              EbsSpacing.lg - 2,              // 22
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // -- Icon (⊘) --
                const Center(
                  child: Text(
                    '⊘',
                    style: TextStyle(
                      fontSize: 48,
                      color: EbsOklch.err,
                      height: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: EbsSpacing.sm + 4), // 12

                // -- Title --
                Center(
                  child: Text(
                    'Declare Miss Deal?',
                    style: EbsTypography.modalTitle.copyWith(
                      fontSize: 22,
                      color: EbsOklch.fg0,
                      letterSpacing: -0.22, // ≈ -0.01em at 22px
                    ),
                  ),
                ),
                const SizedBox(height: EbsSpacing.md),

                // -- Body paragraph (with `aborted` emphasis) --
                Text.rich(
                  TextSpan(
                    style: EbsTypography.infoBar.copyWith(
                      color: EbsOklch.fg1,
                      fontSize: 13,
                      height: 1.55,
                    ),
                    children: const [
                      TextSpan(text: 'The current hand will be '),
                      TextSpan(
                        text: 'aborted',
                        style: TextStyle(
                          color: EbsOklch.err,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: '. All blinds, antes, and bets will be '
                            'returned to player stacks.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: EbsSpacing.md),

                // -- 3-col stat grid (Hand / Phase / Pot to refund) --
                _StatGrid(
                  handNumber: handNumber,
                  phase: phase,
                  potAmount: potAmount,
                ),
                const SizedBox(height: EbsSpacing.sm + 6), // 14

                // -- Warn band --
                _WarnBand(handNumber: handNumber),
                const SizedBox(height: EbsSpacing.md + 2), // 18

                // -- Actions (Wrap → 좁은 폭에서 안전하게 2-line fallback) --
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: EbsSpacing.sm + 2, // 10
                  runSpacing: EbsSpacing.sm,
                  children: [
                    _SecondaryButton(
                      label: 'Cancel · Esc',
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                    _ConfirmButton(
                      label: 'Confirm Miss Deal · Enter',
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _StatGrid — 3-col grid (lbl uppercase / val mono)
// ---------------------------------------------------------------------------

class _StatGrid extends StatelessWidget {
  const _StatGrid({
    required this.handNumber,
    required this.phase,
    required this.potAmount,
  });

  final int handNumber;
  final String phase;
  final int potAmount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EbsOklch.bg3,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: EbsOklch.line),
      ),
      padding: const EdgeInsets.all(EbsSpacing.sm + 4), // 12
      child: Row(
        children: [
          Expanded(
            child: _StatCell(label: 'Hand', value: '#$handNumber'),
          ),
          Expanded(
            child: _StatCell(
              label: 'Phase',
              value: phase.replaceAll('_', ' '),
            ),
          ),
          Expanded(
            child: _StatCell(
              label: 'Pot to refund',
              value: _fmt(potAmount),
              accent: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    this.accent = false,
  });

  final String label;
  final String value;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0, // 0.10em
            color: EbsOklch.fg3,
          ),
        ),
        const SizedBox(height: EbsSpacing.xs),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: accent ? EbsOklch.accent : EbsOklch.fg0,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _WarnBand — yellow-tinted advisory banner
// ---------------------------------------------------------------------------

class _WarnBand extends StatelessWidget {
  const _WarnBand({required this.handNumber});

  final int handNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EbsOklch.warn.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: EbsOklch.warn.withValues(alpha: 0.40)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: EbsSpacing.sm + 4, // 12
        vertical: EbsSpacing.sm,
      ),
      child: Text(
        '⚠ This action is logged. Hand #$handNumber will not be counted '
        'in statistics.',
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          color: EbsOklch.warn,
          height: 1.4,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _SecondaryButton / _ConfirmButton — destructive confirm pair
// ---------------------------------------------------------------------------

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: EbsOklch.fg1,
        backgroundColor: EbsOklch.bg3,
        padding: const EdgeInsets.symmetric(
          horizontal: EbsSpacing.md,
          vertical: EbsSpacing.sm + 2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: EbsOklch.line),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: EbsOklch.err,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: EbsSpacing.md + 2,
          vertical: EbsSpacing.sm + 2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.72, // 0.06em
        ),
      ),
    );
  }
}
