import 'package:test/test.dart';
import 'package:ebs_game_engine/core/cards/card.dart';
import 'package:ebs_game_engine/core/variants/omaha_hilo.dart';

List<Card> p(String s) => s.split(' ').map(Card.parse).toList();

void main() {
  group('Omaha Hi-Lo', () {
    final hilo = OmahaHiLo();

    test('isHiLo is true', () => expect(hilo.isHiLo, true));

    test('evaluates lo hand when qualifying', () {
      final lo = hilo.evaluateLo(p('As 2h Kc Qs'), p('3d 4c 5h Jh Td'));
      expect(lo, isNotNull);
    });

    test('no lo when no qualifying combo exists', () {
      final lo = hilo.evaluateLo(p('As Kh Qc Js'), p('Td 9c 8h 7d 6s'));
      expect(lo, isNull);
    });
  });
}
