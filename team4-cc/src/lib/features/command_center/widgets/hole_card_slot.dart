// Hole card slot widget — 5-state FSM (BS-05-04 §6, CCR-032).
//
// EMPTY → DETECTING → DEALT / FALLBACK / WRONG_CARD
// Visual contract per Manual_Card_Input.md §6.2:
// - DETECTING: pulse at 600 ms interval (warn token)
// - WRONG_CARD: red border + 400 ms shake (err token)
// - FALLBACK: orange border + "TAP TO ENTER" label (modal opening is the
//   responsibility of at_01_main_screen.dart per §6.4.1)
//
// Tap behavior:
// - EMPTY / FALLBACK: invokes [onTap] so the host (AT-01) can request a
//   manual entry path (open AT-03 modal directly).
// - DETECTING / DEALT / WRONG_CARD: tap is forwarded to [onTap] for the
//   host's discretion (e.g. open AT-03 to re-enter a wrong card).
//
// Cycle 19 Wave 3 (U3) — OKLCH token 정합.
//   - Hardcoded #FFD600 / #DD0000 / #F57C00 / #616161 / Colors.white / black
//     모두 EbsOklch / CardColors 토큰으로 치환.
//   - DETECTING/FALLBACK warn 톤, WRONG_CARD err 톤, DEALT cardBg/cardBlack.

import 'package:flutter/material.dart';

import '../../../foundation/theme/card_colors.dart';
import '../../../foundation/theme/ebs_oklch.dart';
import '../../../foundation/theme/ebs_typography.dart';

enum HoleCardSlotState { empty, detecting, dealt, fallback, wrongCard }

class HoleCardSlot extends StatefulWidget {
  const HoleCardSlot({
    super.key,
    required this.state,
    this.cardLabel,
    this.suit,
    this.size = const Size(56, 80),
    this.onTap,
  });

  final HoleCardSlotState state;

  /// Display string for [HoleCardSlotState.dealt] (e.g. 'A♠'). Ignored
  /// in other states.
  final String? cardLabel;

  /// 카드 suit (H/D/S/C). null 이면 [cardLabel] 의 마지막 글자로 추론.
  /// HoleCard 색 결정 — H/D → cardRed, S/C → cardBlack.
  final String? suit;

  /// Slot dimensions. Default mirrors the AT-01 hole card cell.
  final Size size;

  /// Tap callback. See class doc comment for per-state semantics.
  final VoidCallback? onTap;

  @override
  State<HoleCardSlot> createState() => _HoleCardSlotState();
}

class _HoleCardSlotState extends State<HoleCardSlot>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _syncAnimations();
  }

  @override
  void didUpdateWidget(covariant HoleCardSlot old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state) _syncAnimations();
  }

  void _syncAnimations() {
    if (widget.state == HoleCardSlotState.detecting) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.value = 0;
    }
    if (widget.state == HoleCardSlotState.wrongCard) {
      _shakeController.forward(from: 0);
    } else {
      _shakeController.stop();
      _shakeController.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  // ── Visual specs (Manual_Card_Input.md §6.2, OKLCH-sourced) ─────────────
  /// DETECTING pulse — warn token (broadcast amber-gold).
  static const Color _detectingColor = EbsOklch.warn;

  /// WRONG_CARD border + shake — err token (broadcast red).
  static const Color _wrongColor = EbsOklch.err;

  /// FALLBACK border — warn token (same family as DETECTING, distinct via state).
  static const Color _fallbackColor = EbsOklch.warn;

  /// EMPTY border — fg-3 muted text/line token.
  static const Color _emptyBorder = EbsOklch.fg3;

  /// DEALT 카드 suit → 텍스트 색.
  Color _dealtTextColor() {
    final s = widget.suit ??
        (widget.cardLabel?.isNotEmpty == true
            ? widget.cardLabel!.substring(widget.cardLabel!.length - 1)
            : null);
    if (s == null) return CardColors.spade; // default black
    final normalized = s.toUpperCase();
    if (normalized == 'H' || normalized == '♥' || normalized == 'D' || normalized == '♦') {
      return CardColors.heart; // H/D → red
    }
    return CardColors.spade; // S/C → black
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _shakeController]),
      builder: (context, _) {
        final shake = _shakeController.value == 0
            ? 0.0
            : (4 * _shakeController.value *
                (1 - _shakeController.value)) *
                ((_shakeController.value * 4).floor().isEven ? 1 : -1) *
                6;
        return Transform.translate(
          offset: Offset(shake, 0),
          child: GestureDetector(
            onTap: widget.onTap,
            child: SizedBox(
              width: widget.size.width,
              height: widget.size.height,
              child: _buildBody(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    switch (widget.state) {
      case HoleCardSlotState.empty:
        return _decorated(
          border: const _Border(color: _emptyBorder, dashed: true),
          child: Center(
            child: Text(
              '—',
              style: EbsTypography.cardLabel.copyWith(
                color: _emptyBorder,
              ),
            ),
          ),
        );
      case HoleCardSlotState.detecting:
        final intensity = 0.4 + 0.6 * _pulseController.value;
        return _decorated(
          border: const _Border(color: _detectingColor, width: 2),
          fill: _detectingColor.withAlpha((255 * 0.15 * intensity).round()),
          child: const Center(
            child: Icon(
              Icons.contactless,
              color: _detectingColor,
              size: 22,
            ),
          ),
        );
      case HoleCardSlotState.dealt:
        return _decorated(
          border: const _Border(color: EbsOklch.line, width: 1),
          fill: CardColors.cardFaceUp,
          child: Center(
            child: Text(
              widget.cardLabel ?? '?',
              style: EbsTypography.cardLabel.copyWith(
                color: _dealtTextColor(),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      case HoleCardSlotState.fallback:
        return _decorated(
          border: const _Border(color: _fallbackColor, width: 2),
          fill: _fallbackColor.withAlpha(40),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Center(
              child: Text(
                'TAP TO\nENTER',
                textAlign: TextAlign.center,
                style: EbsTypography.cardLabel.copyWith(
                  color: _fallbackColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        );
      case HoleCardSlotState.wrongCard:
        return _decorated(
          border: const _Border(color: _wrongColor, width: 2),
          fill: _wrongColor.withAlpha(40),
          child: const Center(
            child: Icon(Icons.error_outline, color: _wrongColor, size: 22),
          ),
        );
    }
  }

  Widget _decorated({
    required _Border border,
    Color? fill,
    required Widget child,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: border.color,
          width: border.width,
          // Flutter has no native dashed border — we approximate with a
          // muted solid line + the "—" placeholder so the EMPTY state still
          // reads as 'no card here yet' without bringing in a third-party
          // package. Spec is preserved at the visual-language level.
        ),
      ),
      child: child,
    );
  }
}

class _Border {
  const _Border({required this.color, this.width = 1, this.dashed = false});
  final Color color;
  final double width;
  final bool dashed;
}
