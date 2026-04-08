import '../cards/card.dart';

enum SeatStatus { active, folded, allIn, sittingOut }

class Seat {
  final int index;
  final String label;
  int stack;
  int currentBet;
  List<Card> holeCards;
  SeatStatus status;
  bool isDealer;

  Seat({
    required this.index,
    required this.label,
    required this.stack,
    this.currentBet = 0,
    List<Card>? holeCards,
    this.status = SeatStatus.active,
    this.isDealer = false,
  }) : holeCards = holeCards ?? [];

  bool get isActive => status == SeatStatus.active;
  bool get isFolded => status == SeatStatus.folded;
  bool get isAllIn => status == SeatStatus.allIn;

  Seat copy() => Seat(
    index: index,
    label: label,
    stack: stack,
    currentBet: currentBet,
    holeCards: List.of(holeCards),
    status: status,
    isDealer: isDealer,
  );
}
