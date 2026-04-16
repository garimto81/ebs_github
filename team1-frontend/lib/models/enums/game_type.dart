import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value')
enum GameType {
  noLimitHoldem(0, "No Limit Hold'em"),
  fixedLimitHoldem(1, "Fixed Limit Hold'em"),
  potLimitOmaha(2, 'Pot Limit Omaha'),
  omahaHiLo(3, 'Omaha Hi-Lo'),
  razz(4, 'Razz'),
  sevenCardStud(5, '7-Card Stud'),
  studHiLo(6, 'Stud Hi-Lo'),
  twoSevenTripleDraw(7, '2-7 Triple Draw'),
  twoSevenSingleDraw(8, '2-7 Single Draw'),
  badugi(9, 'Badugi'),
  fiveCardOmaha(10, '5-Card Omaha'),
  bigO(11, 'Big O'),
  shortDeck(12, 'Short Deck'),
  courchevel(13, 'Courchevel'),
  pineapple(14, 'Pineapple'),
  fiveCardDraw(15, '5-Card Draw'),
  aFiveTripleDraw(16, 'A-5 Triple Draw'),
  badeucy(17, 'Badeucy'),
  badeucey(18, 'Badeucey'),
  fiveCardOmahaHiLo(19, '5-Card Omaha Hi-Lo'),
  sixCardOmaha(20, '6-Card Omaha'),
  mixedGames(21, 'Mixed Games');

  const GameType(this.value, this.label);

  final int value;
  final String label;
}
