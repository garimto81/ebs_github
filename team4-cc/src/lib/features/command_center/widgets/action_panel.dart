// M-07 Action Panel widget (BS-05-02).
//
// 8 action buttons + amount keypad. Buttons are enabled/disabled
// based on ActionButtonState from action_button_provider.
// Dynamic labels: CHECK↔CALL, BET↔RAISE.
// Amount keypad visible only when BET or RAISE is selected.
//
// Cycle 19 Wave 3 U4 — surface tokens re-sourced from `EbsOklch`
// (Broadcast Dark Amber palette). Legacy hard-coded purple surfaces
// (0xFF1A1A2E / 0xFF2A2A3E / 0xFF0D0D1A / 0xFF444466) removed.
// Visual SSOT: `docs/mockups/EBS Command Center/app.css`
//   §.actionpanel, §.btn, §.numpad-overlay.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../foundation/theme/action_colors.dart';
import '../../../foundation/theme/ebs_oklch.dart';
import '../../../foundation/theme/ebs_shadows.dart';
import '../../../foundation/theme/ebs_spacing.dart';
import '../../../foundation/theme/ebs_typography.dart';
import '../../../models/enums/hand_fsm.dart';
import '../providers/action_button_provider.dart';
import '../providers/hand_fsm_provider.dart';
import '../providers/seat_provider.dart';

// ---------------------------------------------------------------------------
// Amount keypad state
// ---------------------------------------------------------------------------

/// Whether the amount keypad is currently visible (BET/RAISE selected).
final showKeypadProvider = StateProvider<bool>((ref) => false);

/// Current amount string being entered via keypad.
final amountInputProvider = StateProvider<String>((ref) => '');

/// Error message for amount validation (empty = no error).
final amountErrorProvider = StateProvider<String>((ref) => '');

// ---------------------------------------------------------------------------
// ActionPanel — root widget
// ---------------------------------------------------------------------------

/// CC bottom action panel: 8 action buttons + amount keypad (BS-05-02).
class ActionPanel extends ConsumerWidget {
  const ActionPanel({super.key, this.onAction});

  /// Called when an action button is pressed with optional amount.
  final void Function(CcAction action, {int? amount})? onAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buttonState = ref.watch(actionButtonProvider);
    final showKeypad = ref.watch(showKeypadProvider);

    return Container(
      // §13 panel height = 124 (top-rail 56 inset). HTML uses bg-1 surface.
      height: EbsSpacing.actionPanelHeight + EbsSpacing.xs,
      decoration: const BoxDecoration(
        color: EbsOklch.bg1,
        border: Border(top: BorderSide(color: EbsOklch.line)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: EbsSpacing.sm,
        vertical: EbsSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: _UtilityZone(buttonState: buttonState, onAction: _handleAction(context, ref))),
          const SizedBox(width: 8),
          Expanded(flex: 6, child: _MainZone(buttonState: buttonState, onAction: _handleAction(context, ref))),
          const SizedBox(width: 8),
          Expanded(flex: 3, child: _LifecycleZone(buttonState: buttonState, onAction: _handleAction(context, ref))),
          // Right: amount keypad (conditionally visible)
          if (showKeypad)
            Padding(
              padding: const EdgeInsets.only(left: EbsSpacing.sm),
              child: _AmountKeypad(
                onConfirm: () => _confirmAmount(ref),
              ),
            ),
        ],
      ),
    );
  }

  void Function(CcAction) _handleAction(BuildContext context, WidgetRef ref) {
    return (CcAction action) {
      if (action == CcAction.missDeal) {
        _showMissDealConfirm(context, ref, action);
        return;
      }

      if (action == CcAction.betRaise) {
        // Toggle keypad visibility
        final current = ref.read(showKeypadProvider);
        ref.read(showKeypadProvider.notifier).state = !current;
        if (!current) {
          // Reset amount on open
          ref.read(amountInputProvider.notifier).state = '';
          ref.read(amountErrorProvider.notifier).state = '';
        }
        return;
      }

      // Close keypad for non-bet actions
      ref.read(showKeypadProvider.notifier).state = false;
      onAction?.call(action);
    };
  }

  void _confirmAmount(WidgetRef ref) {
    final input = ref.read(amountInputProvider);
    final amount = int.tryParse(input);
    if (amount == null || amount <= 0) {
      ref.read(amountErrorProvider.notifier).state = '0 베팅 불가';
      return;
    }
    // Amount validation is done by the parent/provider layer
    // (min/max checks per BS-05-02 §5).
    ref.read(showKeypadProvider.notifier).state = false;
    ref.read(amountInputProvider.notifier).state = '';
    ref.read(amountErrorProvider.notifier).state = '';
    onAction?.call(CcAction.betRaise, amount: amount);
  }

  void _showMissDealConfirm(
    BuildContext context,
    WidgetRef ref,
    CcAction action,
  ) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EbsOklch.bg2,
        title: Text(
          'MISS DEAL',
          style: EbsTypography.modalTitle.copyWith(color: ActionColors.missDeal),
        ),
        content: const Text(
          'Miss Deal을 선언하시겠습니까?\n현재 핸드가 취소됩니다.',
          style: TextStyle(color: EbsOklch.fg1),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ActionColors.missDeal,
            ),
            onPressed: () {
              Navigator.of(ctx).pop(true);
              onAction?.call(action);
            },
            child: const Text('확인', style: TextStyle(color: EbsOklch.fg0)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ActionBtn — single action button with shortcut hint
//
// Note: the legacy 8-button `_ActionButtons` grid was replaced by the
// zone-decomposed layout (`_UtilityZone` + `_MainZone` + `_LifecycleZone`)
// during Cycle 18. Dead-code class removed in Cycle 19 U4 cleanup.
// ---------------------------------------------------------------------------

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.shortcut,
    required this.color,
    required this.enabled,
    required this.onPressed,
    this.borderColor,
    this.compact = false,
    this.big = false,
    this.subText,
  });
  final String label;
  final String shortcut;
  final Color color;
  final Color? borderColor;
  final bool enabled;
  final VoidCallback onPressed;
  final bool compact;
  final bool big;
  final String? subText;

  @override
  Widget build(BuildContext context) {
    final bgColor = enabled ? color : ActionColors.disabled;
    final fgColor = enabled ? EbsOklch.fg0 : ActionColors.disabledText;

    // Cycle 19 U4 — _ActionBtn no longer wraps itself in `Expanded`.
    // Callers (_UtilityZone / _MainZone / _LifecycleZone) are responsible
    // for the surrounding Expanded so that one `Expanded` writes
    // FlexParentData per layout slot (Flutter rejects competing parents).
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: SizedBox(
        height: compact ? 36 : EbsSpacing.actionButtonHeight,
        child: Material(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              decoration: borderColor != null && enabled
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: borderColor!, width: 2),
                    )
                  : null,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: (compact
                            ? EbsTypography.infoBar
                            : EbsTypography.actionButton)
                        .copyWith(color: fgColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (shortcut.isNotEmpty && !compact)
                    Text(
                      shortcut,
                      style: EbsTypography.shortcutHint,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _AmountKeypad — numeric keypad for BET/RAISE amount entry
// ---------------------------------------------------------------------------

class _AmountKeypad extends ConsumerWidget {
  const _AmountKeypad({required this.onConfirm});

  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amount = ref.watch(amountInputProvider);
    final error = ref.watch(amountErrorProvider);

    return Container(
      width: 200,
      // Numpad overlay surface — HTML §.numpad-overlay uses bg-1 + shadow-pop.
      decoration: const BoxDecoration(
        color: EbsOklch.bg1,
        boxShadow: EbsShadows.pop,
      ),
      child: Column(
        children: [
          // Amount display — HTML §.np-amount .display uses bg-0 frame + accent text.
          Container(
            height: 28,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: EbsSpacing.sm),
            decoration: BoxDecoration(
              color: EbsOklch.bg0,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: error.isNotEmpty ? EbsOklch.err : EbsOklch.line,
              ),
            ),
            alignment: Alignment.centerRight,
            child: Text(
              amount.isEmpty ? '0' : _formatAmount(amount),
              style: EbsTypography.stackAmount.copyWith(
                color: error.isNotEmpty ? EbsOklch.err : EbsOklch.accent,
              ),
            ),
          ),
          if (error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                error,
                style: const TextStyle(color: EbsOklch.err, fontSize: 9),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const SizedBox(height: EbsSpacing.xs),
          // Keypad grid
          Expanded(
            child: Column(
              children: [
                _keypadRow(['7', '8', '9'], ref),
                const SizedBox(height: 2),
                _keypadRow(['4', '5', '6'], ref),
                const SizedBox(height: 2),
                _keypadRow(['1', '2', '3'], ref),
                const SizedBox(height: 2),
                _keypadRow(['C', '0', '←', '000'], ref),
              ],
            ),
          ),
          // Enter button
          SizedBox(
            width: double.infinity,
            height: 24,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ActionColors.check,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              onPressed: onConfirm,
              child: const Text(
                'ENTER',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: EbsOklch.fg0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _keypadRow(List<String> keys, WidgetRef ref) {
    return Expanded(
      child: Row(
        children: keys
            .map((key) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: _KeypadButton(
                      label: key,
                      onPressed: () => _onKeyPress(key, ref),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  void _onKeyPress(String key, WidgetRef ref) {
    final current = ref.read(amountInputProvider);
    ref.read(amountErrorProvider.notifier).state = '';

    switch (key) {
      case 'C':
        ref.read(amountInputProvider.notifier).state = '';
      case '←':
        if (current.isNotEmpty) {
          ref.read(amountInputProvider.notifier).state =
              current.substring(0, current.length - 1);
        }
      case '000':
        // Append three zeros for thousand rapid entry
        ref.read(amountInputProvider.notifier).state = '${current}000';
      default:
        // Digit 0-9
        ref.read(amountInputProvider.notifier).state = '$current$key';
    }
  }

  String _formatAmount(String raw) {
    final n = int.tryParse(raw);
    if (n == null) return raw;
    // Simple thousand separator
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ---------------------------------------------------------------------------
// _KeypadButton — single keypad key
// ---------------------------------------------------------------------------

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // HTML §.np-key uses bg-2 surface + line border + fg-0 text.
    return Material(
      color: EbsOklch.bg2,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: EbsOklch.line),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: EbsOklch.fg0,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class _UtilityZone extends StatelessWidget {
  const _UtilityZone({required this.buttonState, required this.onAction});
  final ActionButtonState buttonState;
  final void Function(CcAction) onAction;
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(child: _ActionBtn(label: 'UNDO', shortcut: 'Ctrl+Z',
        color: ActionColors.undo,
        enabled: buttonState.isEnabled(CcAction.undo),
        onPressed: () => onAction(CcAction.undo), compact: true)),
      const SizedBox(height: 4),
      Expanded(child: _ActionBtn(label: 'MISS DEAL', shortcut: 'M',
        color: ActionColors.missDeal,
        enabled: buttonState.isEnabled(CcAction.missDeal),
        onPressed: () => onAction(CcAction.missDeal), compact: true)),
    ]);
  }
}

class _MainZone extends ConsumerWidget {
  const _MainZone({required this.buttonState, required this.onAction});
  final ActionButtonState buttonState;
  final void Function(CcAction) onAction;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seats = ref.watch(seatsProvider);
    final actionSeat = seats.where((s) => s.actionOn).firstOrNull;
    final biggestBet =
        seats.fold<int>(0, (m, s) => s.currentBet > m ? s.currentBet : m);
    final myBet = actionSeat?.currentBet ?? 0;
    final callAmount = (biggestBet - myBet).clamp(0, 1 << 30);
    final stack = actionSeat?.player?.stack ?? 0;
    final isCall = buttonState.checkCallLabel == 'CALL';
    final isRaise = buttonState.betRaiseLabel == 'RAISE';
    return Row(children: [
      Expanded(
        child: _ActionBtn(
          label: 'FOLD',
          shortcut: 'F',
          color: ActionColors.fold,
          enabled: buttonState.isEnabled(CcAction.fold),
          onPressed: () => onAction(CcAction.fold),
        ),
      ),
      Expanded(
        child: _ActionBtn(
          label: buttonState.checkCallLabel,
          shortcut: 'C',
          color: ActionColors.check,
          enabled: buttonState.isEnabled(CcAction.checkCall),
          subText: isCall && callAmount > 0 ? '\$${_apFmt(callAmount)}' : null,
          onPressed: () => onAction(CcAction.checkCall),
        ),
      ),
      Expanded(
        child: _ActionBtn(
          label: buttonState.betRaiseLabel,
          shortcut: isRaise ? 'R' : 'B',
          color: isRaise ? ActionColors.raise_ : ActionColors.bet,
          enabled: buttonState.isEnabled(CcAction.betRaise),
          onPressed: () => onAction(CcAction.betRaise),
        ),
      ),
      Expanded(
        child: _ActionBtn(
          label: 'ALL-IN',
          shortcut: 'A',
          color: ActionColors.allIn,
          borderColor: ActionColors.allInBorder,
          enabled: buttonState.isEnabled(CcAction.allIn),
          subText: stack > 0 ? '\$${_apFmt(stack)}' : null,
          onPressed: () => onAction(CcAction.allIn),
        ),
      ),
    ]);
  }
}

class _LifecycleZone extends ConsumerWidget {
  const _LifecycleZone({required this.buttonState, required this.onAction});
  final ActionButtonState buttonState;
  final void Function(CcAction) onAction;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fsm = ref.watch(handFsmProvider);
    final isIdle = fsm == HandFsm.idle || fsm == HandFsm.handComplete;
    final isShowdown = fsm == HandFsm.showdown;
    final canStart = buttonState.isEnabled(CcAction.newHand);
    final label =
        isIdle ? 'START HAND' : (isShowdown ? 'FINISH HAND' : 'IN PROGRESS');
    final sub = isIdle
        ? 'Ready to deal'
        : isShowdown
            ? 'Tap to reset'
            : fsm.name.toUpperCase();
    final color = isIdle ? ActionColors.newHand : ActionColors.deal;
    return Column(children: [
      Expanded(
        flex: 3,
        child: _ActionBtn(
          label: label,
          shortcut: '',
          subText: sub,
          color: color,
          enabled: canStart,
          big: true,
          onPressed: () => onAction(CcAction.newHand),
        ),
      ),
      const SizedBox(height: 4),
      SizedBox(
        height: 32,
        child: _ActionBtn(
          label: 'DEAL',
          shortcut: 'D',
          color: ActionColors.deal,
          enabled: buttonState.isEnabled(CcAction.deal),
          onPressed: () => onAction(CcAction.deal),
          compact: true,
        ),
      ),
    ]);
  }
}

String _apFmt(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}
