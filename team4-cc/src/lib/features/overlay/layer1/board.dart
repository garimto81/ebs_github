// Layer 1: Board (community cards). Auto-generated on RFID CardDetected (board slots).
//
// Horizontal row of 5 card slots: Flop (3) → Turn (+1) → River (+1).
// Empty slots rendered as subtle border outline.

import 'package:flutter/material.dart';

import '../../../foundation/theme/card_colors.dart';
import '../../../foundation/theme/ebs_typography.dart';
import '../../../models/entities/card_model.dart';

/// Suit symbol mapping (shared with hole_cards — extracted if needed later).
const _suitSymbols = {
  's': '\u2660',
  'h': '\u2665',
  'd': '\u2666',
  'c': '\u2663',
};

Color _suitColor(String suit) {
  switch (suit) {
    case 's':
      return CardColors.spade;
    case 'h':
      return CardColors.heart;
    case 'd':
      return CardColors.diamond;
    case 'c':
      return CardColors.club;
    default:
      return CardColors.spade;
  }
}

/// Renders 5 community card slots in a horizontal row.
///
/// Cards are filled left-to-right as dealt:
/// - Flop: indices 0-2
/// - Turn: index 3
/// - River: index 4
class BoardLayer extends StatelessWidget {
  const BoardLayer({
    super.key,
    this.communityCards = const [],
    this.cardWidth = 52,
    this.cardHeight = 72,
  });

  /// 0-5 community cards dealt so far.
  final List<CardModel> communityCards;

  final double cardWidth;
  final double cardHeight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final hasCard = index < communityCards.length;
        return Padding(
          padding: EdgeInsets.only(left: index > 0 ? 6 : 0),
          child: hasCard
              ? _BoardCard(
                  card: communityCards[index],
                  width: cardWidth,
                  height: cardHeight,
                )
              : _EmptySlot(width: cardWidth, height: cardHeight),
        );
      }),
    );
  }
}

/// Empty card slot — subtle border outline.
class _EmptySlot extends StatelessWidget {
  const _EmptySlot({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white12, width: 1),
      ),
    );
  }
}

/// Face-up community card.
class _BoardCard extends StatelessWidget {
  const _BoardCard({
    required this.card,
    required this.width,
    required this.height,
  });

  final CardModel card;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final suitSymbol = _suitSymbols[card.suit] ?? '?';
    final color = _suitColor(card.suit);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: CardColors.cardFaceUp,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white24, width: 1),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(1, 2)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            card.rank.toUpperCase(),
            style: EbsTypography.cardLabel.copyWith(color: color),
          ),
          Text(
            suitSymbol,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
