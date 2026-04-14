// Overlay root widget — hosts Rive Canvas and composes Layer 1 elements.
//
// 1080p base resolution. Background: configurable chroma key color.
// Reads seat data from seatsProvider (shared with CC) for visual consistency.
// Layer 1 elements are positioned using Stack + Positioned.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/entities/card_model.dart';
import '../../../models/enums/seat_status.dart';
import '../../command_center/providers/seat_provider.dart';
import '../layer1/action_badge.dart';
import '../layer1/board.dart';
import '../layer1/equity_bar.dart';
import '../layer1/hole_cards.dart';
import '../layer1/outs.dart';
import '../layer1/player_info.dart';
import '../layer1/player_position.dart';
import '../layer1/pot_display.dart';

/// Default chroma key green for broadcast keying.
const _defaultChromaKey = Color(0xFF00B140);

/// Base overlay resolution (1080p).
const _baseWidth = 1920.0;
const _baseHeight = 1080.0;

/// Maximum seats in a poker table.
const _maxSeats = 10;

/// Seat layout positions (normalized 0-1 for 1080p).
/// 10-seat oval arrangement, clockwise from seat 1 (bottom-left).
const _seatPositions = <int, ({double x, double y})>{
  1: (x: 0.12, y: 0.75),
  2: (x: 0.04, y: 0.50),
  3: (x: 0.12, y: 0.25),
  4: (x: 0.30, y: 0.10),
  5: (x: 0.50, y: 0.05),
  6: (x: 0.70, y: 0.10),
  7: (x: 0.88, y: 0.25),
  8: (x: 0.96, y: 0.50),
  9: (x: 0.88, y: 0.75),
  10: (x: 0.50, y: 0.85),
};

/// Composes all 8 Layer 1 overlay elements in a Stack layout.
///
/// Background is a chroma key color (configurable) for broadcast keying.
/// Elements are positioned relative to 1080p base resolution.
///
/// Reads from:
/// - [seatsProvider] — player info, holecards, positions
/// - Props: [communityCards], [mainPot], [sidePots], [equities], [outs],
///          [lastActions]
class OverlayRoot extends ConsumerWidget {
  const OverlayRoot({
    super.key,
    this.chromaKeyColor = _defaultChromaKey,
    this.communityCards = const [],
    this.mainPot = 0,
    this.sidePots = const [],
    this.equities = const {},
    this.outsMap = const {},
    this.lastActions = const {},
    this.revealedSeats = const {},
  });

  /// Background chroma key color.
  final Color chromaKeyColor;

  /// Community cards (0-5).
  final List<CardModel> communityCards;

  /// Main pot amount.
  final int mainPot;

  /// Side pot amounts.
  final List<int> sidePots;

  /// Per-seat equity (seatNo → 0.0-1.0).
  final Map<int, double> equities;

  /// Per-seat outs count (seatNo → outs).
  final Map<int, int> outsMap;

  /// Per-seat last action text (seatNo → "FOLD", "BET $500", etc.).
  final Map<int, String> lastActions;

  /// Seats whose holecards are face-up (revealed).
  final Set<int> revealedSeats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seats = ref.watch(seatsProvider);

    return Container(
      width: _baseWidth,
      height: _baseHeight,
      color: chromaKeyColor,
      child: Stack(
        children: [
          // ── Board (community cards) — center top ──────────────────
          Positioned(
            left: _baseWidth * 0.35,
            top: _baseHeight * 0.38,
            child: BoardLayer(communityCards: communityCards),
          ),

          // ── Pot display — center ─────────────────────────────────
          Positioned(
            left: _baseWidth * 0.42,
            top: _baseHeight * 0.52,
            child: PotDisplayLayer(
              mainPot: mainPot,
              sidePots: sidePots,
            ),
          ),

          // ── Per-seat elements ────────────────────────────────────
          for (int i = 0; i < seats.length && i < _maxSeats; i++)
            if (seats[i].player != null)
              ..._buildSeatElements(seats[i]),
        ],
      ),
    );
  }

  /// Build all overlay elements for a single occupied seat.
  List<Widget> _buildSeatElements(SeatState seat) {
    final pos = _seatPositions[seat.seatNo];
    if (pos == null) return [];

    final baseX = pos.x * _baseWidth;
    final baseY = pos.y * _baseHeight;
    final player = seat.player!;

    // Determine position label.
    String? positionLabel;
    if (seat.isDealer) positionLabel = 'BTN';
    if (seat.isSB) positionLabel = 'SB';
    if (seat.isBB) positionLabel = 'BB';

    // Convert HoleCard list to CardModel list for the overlay widget.
    final holeCardModels = seat.holeCards
        .map((hc) => CardModel(suit: hc.suit, rank: hc.rank))
        .toList();

    final seatNo = seat.seatNo;

    return [
      // Player info (name + stack + flag)
      Positioned(
        left: baseX - 60,
        top: baseY,
        child: PlayerInfoLayer(
          name: player.name,
          stack: player.stack,
          countryCode: player.countryCode,
          isActive: seat.activity != PlayerActivity.sittingOut,
        ),
      ),

      // Hole cards (above player info)
      Positioned(
        left: baseX - 50,
        top: baseY - 78,
        child: HoleCardsLayer(
          cards: holeCardModels.isNotEmpty ? holeCardModels : null,
          faceUp: revealedSeats.contains(seatNo),
        ),
      ),

      // Position marker (left of player info)
      Positioned(
        left: baseX - 90,
        top: baseY + 8,
        child: PlayerPositionLayer(position: positionLabel),
      ),

      // Equity (below player info)
      if (equities.containsKey(seatNo))
        Positioned(
          left: baseX - 10,
          top: baseY + 56,
          child: EquityBarLayer(equity: equities[seatNo]),
        ),

      // Outs (next to equity)
      if (outsMap.containsKey(seatNo))
        Positioned(
          left: baseX + 30,
          top: baseY + 56,
          child: OutsLayer(outsCount: outsMap[seatNo]),
        ),

      // Action badge (above holecards)
      if (lastActions.containsKey(seatNo))
        Positioned(
          left: baseX - 40,
          top: baseY - 108,
          child: ActionBadgeLayer(actionText: lastActions[seatNo]),
        ),
    ];
  }
}
