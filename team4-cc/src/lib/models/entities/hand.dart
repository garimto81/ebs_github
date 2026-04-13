// Hand entity stub. See BS-05-01-hand-lifecycle.md and DATA-02 §Hand.

import '../enums/hand_fsm.dart';

class Hand {
  const Hand({
    required this.id,
    required this.handNumber,
    required this.fsm,
    this.biggestBetAmt = 0,
    this.potAmt = 0,
  });

  final int id;
  final int handNumber;
  final HandFsm fsm;
  final int biggestBetAmt;
  final int potAmt;
}
