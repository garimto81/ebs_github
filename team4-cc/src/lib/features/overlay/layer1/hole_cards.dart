// Layer 1: HoleCards (BS-07-00 §3, CCR-035).
// Auto-generated on RFID CardDetected. Full automation, <100ms target.
//
// Renders 2 cards per seat: face-down (blue back) or face-up (rank + suit).
// Rive flip animation placeholder for Phase 2 (BS-07-02).

import 'package:flutter/material.dart';

import '../../../foundation/theme/card_colors.dart';
import '../../../foundation/theme/ebs_typography.dart';
import '../../../models/entities/card_model.dart';

/// Suit symbol/color mapping (4-color broadcast standard).
const _suitSymbols = {
  's': '\u2660', // Spade
  'h': '\u2665', // Heart
  'd': '\u2666', // Diamond
  'c': '\u2663', // Club
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

/// Renders a player's 2 hole cards.
///
/// - [cards] == null  → face down (blue card back)
/// - [cards] is empty → no cards (nothing rendered)
/// - [cards] has 1-2  → face-up card display
class HoleCardsLayer extends StatelessWidget {
  const HoleCardsLayer({
    super.key,
    this.cards,
    this.faceUp = false,
    this.cardWidth = 48,
    this.cardHeight = 68,
  });

  /// Hole cards. null = face down, empty = no cards shown.
  final List<CardModel>? cards;

  /// Whether cards are revealed (face up).
  final bool faceUp;

  /// Card dimensions (scaled for overlay resolution).
  final double cardWidth;
  final double cardHeight;

  @override
  Widget build(BuildContext context) {
    // No cards dealt — render nothing.
    if (cards != null && cards!.isEmpty) {
      return const SizedBox.shrink();
    }

    // Face down: show 2 card backs.
    if (cards == null || !faceUp) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CardBack(width: cardWidth, height: cardHeight),
          const SizedBox(width: 4),
          _CardBack(width: cardWidth, height: cardHeight),
        ],
      );
    }

    // Face up: show actual cards.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < cards!.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          _CardFace(
            card: cards![i],
            width: cardWidth,
            height: cardHeight,
          ),
        ],
      ],
    );
  }
}

/// Blue card back (face-down state).
class _CardBack extends StatelessWidget {
  const _CardBack({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: CardColors.cardFaceDown,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Center(
        child: Container(
          width: width * 0.6,
          height: height * 0.6,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white30, width: 1),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

/// Face-up card: white background with rank (large) + suit symbol (colored).
class _CardFace extends StatelessWidget {
  const _CardFace({
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
          // Rank (large)
          Text(
            card.rank.toUpperCase(),
            style: EbsTypography.cardLabel.copyWith(color: color),
          ),
          // Suit symbol
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
