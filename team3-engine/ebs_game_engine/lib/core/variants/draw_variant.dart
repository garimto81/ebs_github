import 'variant.dart';

/// Abstract base class for Draw poker variants.
///
/// Draw games have no community cards. Players draw/discard cards
/// across one or more draw rounds.
abstract class DrawVariant extends Variant {
  @override
  int get communityCardCount => 0;

  /// Number of draw rounds (1 for single draw, 3 for triple draw).
  int get drawRounds;

  /// Maximum cards a player can discard per draw round.
  int get maxDiscard => holeCardCount;

  /// Whether the deck should reshuffle discards when empty.
  bool get reshuffleDiscards => true;
}
