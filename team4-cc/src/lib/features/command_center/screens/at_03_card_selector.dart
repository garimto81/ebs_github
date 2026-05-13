// AT-03 Card Selector — Broadcast Dark Amber OKLCH centered modal.
//
// Cycle 19 Wave 4 U5 — re-skinned to the Command Center HTML SSOT
// (`docs/mockups/EBS Command Center/CardPicker.jsx` + `app.css` §CARD PICKER).
//
// Layout:
//   ┌──────────────────────── backdrop (bg0 / 0.65 + blur σ=4) ────────────────────────┐
//   │                                                                                  │
//   │            ┌────────────────────────── modal (bg2 + shadow-pop) ──────────┐      │
//   │            │  Select card / target subtitle                       [✕]    │      │
//   │            │  ────────────────────────────────────────────────────────── │      │
//   │            │  ♠  A K Q J 10 9 8 7 6 5 4 3 2                               │      │
//   │            │  ♥  ... 13 cells per row × 4 suit rows = 52 cards            │      │
//   │            │  ♦  ...                                                      │      │
//   │            │  ♣  ...                                                      │      │
//   │            │  ────────────────────────────────────────────────────────── │      │
//   │            │  ■ Avail   ■ Dealt   ■ Current               Esc to close   │      │
//   │            └─────────────────────────────────────────────────────────────┘      │
//   └──────────────────────────────────────────────────────────────────────────────────┘
//
// Tokens (this file → SSOT):
//   - Backdrop:    `EbsOklch.bg0.withOpacity(0.65)` + `BackdropFilter(blur σ=4)`
//   - Modal:       `EbsOklch.bg2` + `EbsShadows.pop` + 1px `EbsOklch.line`
//   - Card cell:   `EbsOklch.cardBg` base, `EbsOklch.cardRed` (H,D), `EbsOklch.cardBlack` (S,C)
//   - Dealt cell:  `EbsOklch.fg3` muted background, content opacity 0.5
//   - Focus ring:  1.5px `EbsOklch.accent` + `EbsShadows.glowAction`-style ring
//
// Keyboard:
//   - Suit keys: s/h/d/c  → set pending suit (row highlighted)
//   - Rank keys: A/2-9/T/J/Q/K/0 → commit when pending suit set
//   - Esc → cancel

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../foundation/theme/ebs_oklch.dart';
import '../../../foundation/theme/ebs_shadows.dart';
import '../../../models/enums/card.dart';
import '../providers/card_input_provider.dart';

// ---------------------------------------------------------------------------
// Suit / Rank display helpers
// ---------------------------------------------------------------------------

const _suitSymbols = {
  Suit.spade: '♠',
  Suit.heart: '♥',
  Suit.diamond: '♦',
  Suit.club: '♣',
};

/// 2-color broadcast convention (HTML SSOT `app.css` §CARD PICKER):
/// Hearts & Diamonds → red, Spades & Clubs → black.
///
/// This is a picker-local mapping — does NOT replace the 4-color
/// `CardColors` convention used by seat displays.
const _pickerSuitColors = {
  Suit.spade: EbsOklch.cardBlack,
  Suit.heart: EbsOklch.cardRed,
  Suit.diamond: EbsOklch.cardRed,
  Suit.club: EbsOklch.cardBlack,
};

const _suitOrder = [Suit.spade, Suit.heart, Suit.diamond, Suit.club];

const _rankOrder = [
  Rank.ace,
  Rank.king,
  Rank.queen,
  Rank.jack,
  Rank.ten,
  Rank.nine,
  Rank.eight,
  Rank.seven,
  Rank.six,
  Rank.five,
  Rank.four,
  Rank.three,
  Rank.two,
];

String _rankLabel(Rank rank) => switch (rank) {
      Rank.ace => 'A',
      Rank.two => '2',
      Rank.three => '3',
      Rank.four => '4',
      Rank.five => '5',
      Rank.six => '6',
      Rank.seven => '7',
      Rank.eight => '8',
      Rank.nine => '9',
      Rank.ten => 'T',
      Rank.jack => 'J',
      Rank.queen => 'Q',
      Rank.king => 'K',
    };

// ---------------------------------------------------------------------------
// Keyboard mapping
// ---------------------------------------------------------------------------

Suit? _suitFromKey(String char) => switch (char.toLowerCase()) {
      's' => Suit.spade,
      'h' => Suit.heart,
      'd' => Suit.diamond,
      'c' => Suit.club,
      _ => null,
    };

Rank? _rankFromKey(String char) => switch (char.toUpperCase()) {
      'A' => Rank.ace,
      '2' => Rank.two,
      '3' => Rank.three,
      '4' => Rank.four,
      '5' => Rank.five,
      '6' => Rank.six,
      '7' => Rank.seven,
      '8' => Rank.eight,
      '9' => Rank.nine,
      'T' || '0' => Rank.ten,
      'J' => Rank.jack,
      'Q' => Rank.queen,
      'K' => Rank.king,
      _ => null,
    };

// ---------------------------------------------------------------------------
// AT-03 Card Selector Modal entry
// ---------------------------------------------------------------------------

/// Shows the card selector as a centered modal with blurred backdrop.
///
/// [targetSeatNo] and [targetSlotIndex] identify which slot receives the card.
/// [usedCards] is the set of already-dealt card keys for graying out.
/// Returns the selected (Suit, Rank) or null if cancelled.
Future<(Suit, Rank)?> showCardSelectorModal(
  BuildContext context, {
  required int targetSeatNo,
  required int targetSlotIndex,
  required Set<String> usedCards,
}) {
  return showGeneralDialog<(Suit, Rank)?>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Card selector backdrop',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 160),
    pageBuilder: (_, __, ___) => _CardSelectorScaffold(
      targetSeatNo: targetSeatNo,
      targetSlotIndex: targetSlotIndex,
      usedCards: usedCards,
    ),
    transitionBuilder: (_, animation, __, child) {
      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      final scale = Tween<double>(begin: 0.96, end: 1).animate(
        CurvedAnimation(
          parent: animation,
          curve: const Cubic(0.2, 0.9, 0.25, 1),
        ),
      );
      return FadeTransition(
        opacity: fade,
        child: ScaleTransition(
          scale: scale,
          child: child,
        ),
      );
    },
  );
}

// ---------------------------------------------------------------------------
// Scaffold: backdrop + centered modal
// ---------------------------------------------------------------------------

class _CardSelectorScaffold extends StatelessWidget {
  const _CardSelectorScaffold({
    required this.targetSeatNo,
    required this.targetSlotIndex,
    required this.usedCards,
  });

  final int targetSeatNo;
  final int targetSlotIndex;
  final Set<String> usedCards;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Backdrop: blur + bg0 / 0.65 overlay. Tap dismisses.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: ColoredBox(
                color: EbsOklch.bg0.withValues(alpha: 0.65),
              ),
            ),
          ),
        ),
        // Centered modal.
        Center(
          child: _CardSelectorModal(
            targetSeatNo: targetSeatNo,
            targetSlotIndex: targetSlotIndex,
            usedCards: usedCards,
          ),
        ),
      ],
    );
  }
}

class _CardSelectorModal extends StatelessWidget {
  const _CardSelectorModal({
    required this.targetSeatNo,
    required this.targetSlotIndex,
    required this.usedCards,
  });

  final int targetSeatNo;
  final int targetSlotIndex;
  final Set<String> usedCards;

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    final modalWidth = viewport.width * 0.92 < 820 ? viewport.width * 0.92 : 820.0;
    final modalMaxHeight = viewport.height * 0.86;

    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: modalWidth,
          maxHeight: modalMaxHeight,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: EbsOklch.bg2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: EbsOklch.line),
            boxShadow: EbsShadows.pop,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Header(
                  targetSeatNo: targetSeatNo,
                  targetSlotIndex: targetSlotIndex,
                  onClose: () => Navigator.of(context).pop(),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                    child: _CardGrid(
                      usedCards: usedCards,
                      onCardSelected: (suit, rank) =>
                          Navigator.of(context).pop((suit, rank)),
                    ),
                  ),
                ),
                const _Legend(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({
    required this.targetSeatNo,
    required this.targetSlotIndex,
    required this.onClose,
  });

  final int targetSeatNo;
  final int targetSlotIndex;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final slotLabel = targetSlotIndex == 0 ? 'Hole 1' : 'Hole 2';
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: EbsOklch.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select card',
                  style: TextStyle(
                    color: EbsOklch.fg0,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'S$targetSeatNo · $slotLabel',
                  style: const TextStyle(
                    color: EbsOklch.fg2,
                    fontSize: 12,
                    letterSpacing: 0.48,
                  ),
                ),
              ],
            ),
          ),
          _CloseButton(onTap: onClose),
        ],
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Close',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            border: Border.all(color: EbsOklch.line),
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: const Text(
            '✕',
            style: TextStyle(
              color: EbsOklch.fg1,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card grid (4 suit rows × 13 rank cols)
// ---------------------------------------------------------------------------

class _CardGrid extends StatefulWidget {
  const _CardGrid({
    required this.usedCards,
    required this.onCardSelected,
  });

  final Set<String> usedCards;
  final void Function(Suit suit, Rank rank) onCardSelected;

  @override
  State<_CardGrid> createState() => _CardGridState();
}

class _CardGridState extends State<_CardGrid> {
  final _focusNode = FocusNode();

  // Two-step keyboard selection: first suit, then rank.
  Suit? _pendingSuit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  String _cardKey(Suit suit, Rank rank) => '${rank.name}${suit.name}';

  bool _isUsed(Suit suit, Rank rank) =>
      widget.usedCards.contains(_cardKey(suit, rank));

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final char = event.character;
    if (char == null || char.isEmpty) return;

    if (_pendingSuit == null) {
      final suit = _suitFromKey(char);
      if (suit != null) {
        setState(() => _pendingSuit = suit);
      }
    } else {
      final rank = _rankFromKey(char);
      if (rank != null) {
        if (!_isUsed(_pendingSuit!, rank)) {
          widget.onCardSelected(_pendingSuit!, rank);
        }
        setState(() => _pendingSuit = null);
      } else {
        final suit = _suitFromKey(char);
        if (suit != null) {
          setState(() => _pendingSuit = suit);
        } else {
          setState(() => _pendingSuit = null);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_pendingSuit != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Suit ${_suitSymbols[_pendingSuit]}  — press rank key',
                style: TextStyle(
                  color: _pickerSuitColors[_pendingSuit]!,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          for (var i = 0; i < _suitOrder.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            _buildSuitRow(_suitOrder[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildSuitRow(Suit suit) {
    final highlighted = _pendingSuit == suit;
    final color = _pickerSuitColors[suit]!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Suit label column — 32px fixed.
        SizedBox(
          width: 32,
          child: Text(
            _suitSymbols[suit]!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 5),
        // 13 rank cells — equal flex.
        for (var i = 0; i < _rankOrder.length; i++) ...[
          if (i > 0) const SizedBox(width: 5),
          Expanded(
            child: _CardCell(
              suit: suit,
              rank: _rankOrder[i],
              suitColor: color,
              isUsed: _isUsed(suit, _rankOrder[i]),
              isHighlighted: highlighted,
              onTap: _isUsed(suit, _rankOrder[i])
                  ? null
                  : () => widget.onCardSelected(suit, _rankOrder[i]),
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Card cell — 5:7 aspect ratio with rank glyph + suit symbol
// ---------------------------------------------------------------------------

class _CardCell extends StatefulWidget {
  const _CardCell({
    required this.suit,
    required this.rank,
    required this.suitColor,
    required this.isUsed,
    required this.isHighlighted,
    this.onTap,
  });

  final Suit suit;
  final Rank rank;
  final Color suitColor;
  final bool isUsed;
  final bool isHighlighted;
  final VoidCallback? onTap;

  @override
  State<_CardCell> createState() => _CardCellState();
}

class _CardCellState extends State<_CardCell> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final rankLabel = _rankLabel(widget.rank);
    final suitGlyph = _suitSymbols[widget.suit]!;
    final ringActive =
        !widget.isUsed && (widget.isHighlighted || _hovered);

    final background = widget.isUsed ? EbsOklch.fg3 : EbsOklch.cardBg;
    final borderColor =
        ringActive ? EbsOklch.accent : Colors.transparent;
    final shadow = ringActive
        ? const [
            BoxShadow(
              color: EbsOklch.accentSoft,
              blurRadius: 14,
            ),
          ]
        : const <BoxShadow>[];

    return MouseRegion(
      onEnter: (_) {
        if (!widget.isUsed) setState(() => _hovered = true);
      },
      onExit: (_) {
        if (_hovered) setState(() => _hovered = false);
      },
      cursor: widget.isUsed
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AspectRatio(
          aspectRatio: 5 / 7,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: borderColor, width: 1.5),
              boxShadow: shadow,
            ),
            alignment: Alignment.center,
            child: Opacity(
              opacity: widget.isUsed ? 0.5 : 1.0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    rankLabel,
                    style: TextStyle(
                      color: widget.suitColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    suitGlyph,
                    style: TextStyle(
                      color: widget.suitColor,
                      fontSize: 14,
                      height: 1,
                    ),
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
// Legend footer
// ---------------------------------------------------------------------------

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: EbsOklch.line)),
      ),
      child: const Row(
        children: [
          _Swatch(color: EbsOklch.cardBg, label: 'Available'),
          SizedBox(width: 18),
          _Swatch(color: EbsOklch.fg3, label: 'Dealt'),
          SizedBox(width: 18),
          _Swatch(color: EbsOklch.accent, label: 'Current'),
          Spacer(),
          Text(
            'Esc to close',
            style: TextStyle(
              color: EbsOklch.fg3,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: EbsOklch.line),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: EbsOklch.fg2,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Legacy widget entry point (preserved for router/back-compat)
// ---------------------------------------------------------------------------

/// Stateless entry point (original stub signature).
///
/// For full-featured usage, call [showCardSelectorModal] directly.
class At03CardSelector extends ConsumerWidget {
  const At03CardSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardState = ref.watch(cardInputProvider);
    final seatNo = cardState.targetSeatNo ?? 0;
    final usedCards = cardState.dealtCards;

    var targetSlot = 0;
    for (var i = 0; i < cardState.slots.length; i++) {
      if (!cardState.slots[i].hasCard) {
        targetSlot = i;
        break;
      }
    }

    return _CardSelectorScaffold(
      targetSeatNo: seatNo,
      targetSlotIndex: targetSlot,
      usedCards: usedCards,
    );
  }
}
