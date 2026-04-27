// AT-03 Card Selector — composite card grid modal (UI-02 screen 3, BS-05-04).
//
// 4x13 grid where each cell is a complete card (e.g. "A spade", "K heart").
// Cell size: 60x72px (AppConstants.cardCellWidth/cardCellHeight).
// Used cards: grayed-out + X overlay (CardColors.cardUsed, opacity 0.3).
// Tap a cell -> assign card to target slot.
// Keyboard: suit keys (s/h/d/c) + rank keys (A/2-9/T/J/Q/K).
// Slides up from bottom as a modal overlay.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../foundation/theme/card_colors.dart';
import '../../../models/enums/card.dart';
import '../../../resources/constants.dart';
import '../providers/card_input_provider.dart';

// ---------------------------------------------------------------------------
// Suit / Rank display helpers
// ---------------------------------------------------------------------------

const _suitSymbols = {
  Suit.spade: '\u2660',
  Suit.heart: '\u2665',
  Suit.diamond: '\u2666',
  Suit.club: '\u2663',
};

const _suitColors = {
  Suit.spade: CardColors.spade,
  Suit.heart: CardColors.heart,
  Suit.diamond: CardColors.diamond,
  Suit.club: CardColors.club,
};

const _suitOrder = [Suit.spade, Suit.heart, Suit.diamond, Suit.club];

const _rankOrder = [
  Rank.ace,
  Rank.two,
  Rank.three,
  Rank.four,
  Rank.five,
  Rank.six,
  Rank.seven,
  Rank.eight,
  Rank.nine,
  Rank.ten,
  Rank.jack,
  Rank.queen,
  Rank.king,
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
// AT-03 Card Selector Modal
// ---------------------------------------------------------------------------

/// Shows the card selector as a bottom-sheet modal overlay.
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
  return showModalBottomSheet<(Suit, Rank)?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CardSelectorSheet(
      targetSeatNo: targetSeatNo,
      targetSlotIndex: targetSlotIndex,
      usedCards: usedCards,
    ),
  );
}

class _CardSelectorSheet extends StatelessWidget {
  const _CardSelectorSheet({
    required this.targetSeatNo,
    required this.targetSlotIndex,
    required this.usedCards,
  });

  final int targetSeatNo;
  final int targetSlotIndex;
  final Set<String> usedCards;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          const SizedBox(height: 8),
          _buildTargetLabel(),
          const SizedBox(height: 12),
          _CardGrid(
            usedCards: usedCards,
            onCardSelected: (suit, rank) {
              Navigator.of(context).pop((suit, rank));
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'CARD INPUT MODE',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white54, size: 20),
          onPressed: () => Navigator.of(context).pop(),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildTargetLabel() {
    final slotLabel = targetSlotIndex == 0 ? 'Hole Card 1' : 'Hole Card 2';
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'Target: Seat $targetSeatNo \u2014 $slotLabel',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card Grid (4 rows x 13 cols) with keyboard support
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
    // Auto-focus for keyboard input.
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
      // Waiting for suit key.
      final suit = _suitFromKey(char);
      if (suit != null) {
        setState(() => _pendingSuit = suit);
      }
    } else {
      // Waiting for rank key.
      final rank = _rankFromKey(char);
      if (rank != null) {
        if (!_isUsed(_pendingSuit!, rank)) {
          widget.onCardSelected(_pendingSuit!, rank);
        }
        setState(() => _pendingSuit = null);
      } else {
        // Maybe they pressed a different suit key — switch suit.
        final suit = _suitFromKey(char);
        if (suit != null) {
          setState(() => _pendingSuit = suit);
        } else {
          // Invalid key — reset.
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
        children: [
          if (_pendingSuit != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Suit: ${_suitSymbols[_pendingSuit]} — press rank key',
                style: TextStyle(
                  color: _suitColors[_pendingSuit]!,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          for (final suit in _suitOrder) _buildSuitRow(suit),
        ],
      ),
    );
  }

  Widget _buildSuitRow(Suit suit) {
    final isHighlighted = _pendingSuit == suit;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final rank in _rankOrder)
            _CardCell(
              suit: suit,
              rank: rank,
              isUsed: _isUsed(suit, rank),
              isRowHighlighted: isHighlighted,
              onTap: _isUsed(suit, rank)
                  ? null
                  : () => widget.onCardSelected(suit, rank),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Individual card cell
// ---------------------------------------------------------------------------

class _CardCell extends StatelessWidget {
  const _CardCell({
    required this.suit,
    required this.rank,
    required this.isUsed,
    required this.isRowHighlighted,
    this.onTap,
  });

  final Suit suit;
  final Rank rank;
  final bool isUsed;
  final bool isRowHighlighted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final suitColor = _suitColors[suit]!;
    final label = '${_rankLabel(rank)}${_suitSymbols[suit]}';

    return Padding(
      padding: const EdgeInsets.all(1),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: AppConstants.cardCellWidth,
          height: AppConstants.cardCellHeight,
          decoration: BoxDecoration(
            color: isUsed
                ? CardColors.cardUsed.withOpacity(0.3)
                : CardColors.cardFaceUp,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isRowHighlighted && !isUsed
                  ? suitColor.withOpacity(0.8)
                  : Colors.grey.shade700,
              width: isRowHighlighted && !isUsed ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: isUsed
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      Icons.close,
                      color: Colors.red.shade300,
                      size: 28,
                    ),
                  ],
                )
              : Text(
                  label,
                  style: TextStyle(
                    color: suitColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Legacy widget kept for backward compatibility
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

    // Find first empty slot index.
    var targetSlot = 0;
    for (var i = 0; i < cardState.slots.length; i++) {
      if (!cardState.slots[i].hasCard) {
        targetSlot = i;
        break;
      }
    }

    return _CardSelectorSheet(
      targetSeatNo: seatNo,
      targetSlotIndex: targetSlot,
      usedCards: usedCards,
    );
  }
}
