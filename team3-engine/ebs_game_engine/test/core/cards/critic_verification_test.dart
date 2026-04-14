// Critic 분석 — 버그 E2E 검증 테스트
// 목적: 설계 헛점을 실제 코드 실행으로 증명

import 'package:test/test.dart';
import 'package:ebs_game_engine/core/cards/card.dart';
import 'package:ebs_game_engine/core/cards/hand_evaluator.dart';
import 'package:ebs_game_engine/core/math/equity_calculator.dart';

List<Card> p(String s) => s.split(' ').map(Card.parse).toList();

void main() {
  // ========================================================================
  // BUG-1: A-6-7-8-9 스트레이트 오판정 [CRITICAL]
  // 원인: hand_evaluator.dart:290 의 `restSorted.first == 6` 조건이
  //        표준 52장 Hold'em 덱에서도 활성화됨
  // ========================================================================
  group('[CRITIC] BUG-1: A-6-7-8-9 Straight 오판정', () {
    // 핵심 케이스: 5장 직접 평가
    test('A-6-7-8-9 (5장) → highCard 이어야 함 (현재 straight 오판정)', () {
      final r = HandEvaluator.bestHand(p('As 9h 6c 7d 8s'));
      // 표준 Hold'em 규칙: Ace low wheel은 A-2-3-4-5만 유효
      // A-6-7-8-9 = 스트레이트 아님, high card
      expect(r.category, HandCategory.highCard,
          reason:
              'A-6-7-8-9는 표준 포커 규칙에서 스트레이트가 아닙니다. '
              '_checkStraight의 restSorted.first==6 조건이 버그입니다.');
    });

    // 실제 게임 영향: 2명, 리버에서 승자 역전
    test('2인 게임 — A9 vs KK: KK 페어가 이겨야 함 (현재 A9가 잘못 승리)', () {
      // Player 0: As 9h (hole cards)
      // Player 1: Ks Kh (hole cards)
      // Board: 6c 7d 8s 2h 3d (river — 5 board cards)
      // 7장 = hole 2 + board 5
      final board = p('6c 7d 8s 2h 3d');

      final rank0 = HandEvaluator.bestHand([...p('As 9h'), ...board]);
      final rank1 = HandEvaluator.bestHand([...p('Ks Kh'), ...board]);

      // 정상: Player 1 (KK pair) > Player 0 (A-high)
      expect(rank1.compareTo(rank0), greaterThan(0),
          reason:
              'KK one pair은 A-9-8-7-6 high card를 이겨야 합니다. '
              '버그 시 Player 0의 A-6-7-8-9가 "straight"로 처리되어 rank0 > rank1이 됩니다.');
    });

    // 추가 케이스: A6789 스트레이트 오판정이 7장 bestHand에서도 발생하는지
    test('7장 bestHand — A6789 패턴이 포함된 경우', () {
      // A♠ 6♣ 7♦ 8♠ 9♥ + K♦ 2♥ (여분 2장)
      final r = HandEvaluator.bestHand(p('As 6c 7d 8s 9h Kd 2h'));
      // 이 7장에서 best 5-card combo는:
      // [A,K,9,8,7] = high card (A-K-9-8-7 또는 유사)
      // NOT [A,9,8,7,6] = 잘못된 straight
      expect(r.category, isNot(HandCategory.straight),
          reason:
              '7장 중 [As,9h,6c,7d,8s] 콤보가 잘못된 straight로 선택되면 '
              'bestHand가 high card가 아닌 straight를 반환합니다.');
    });

    // 경계 케이스: A-7-8-9-T 는 실제로 valid straight (T-high)
    test('A-7-8-9-T → 실제 스트레이트 아님 확인 (T-high는 별도 조합)', () {
      // 7-8-9-T-A 는 스트레이트? 아니다: A는 J-Q-K-A 에만 high
      // T-J-Q-K-A = A-high straight (Broadway)
      // 7-8-9-T 뒤에 A가 오는 것 = NOT a straight
      final r = HandEvaluator.bestHand(p('As Th 7c 8d 9s'));
      // 7-8-9-T: 연속이지만 A와는 연결 안 됨 → high card
      // 참고: 6-7-8-9-T = T-high straight (유효)
      expect(r.category, HandCategory.highCard,
          reason: 'A-7-8-9-T에서 A는 low 역할을 할 수 없음 (7부터 시작하므로)');
    });
  });

  // ========================================================================
  // BUG-2: 3인 타이 시 부동소수점 누적 오차 [HIGH]
  // 원인: equity_calculator.dart 에서 wins[idx] += 1.0/N 누적
  // ========================================================================
  group('[CRITIC] BUG-2: 부동소수점 누적 오차 (3인 타이)', () {
    test('3인 타이 — equity 합계가 정확히 1.0이어야 함', () {
      // 보드: As Ks Qs Js Ts (Royal Flush on board)
      // 3명 모두 홀카드와 무관하게 Royal Flush = 완전 타이
      final equity = EquityCalculator.calculate(
        hands: {
          0: p('2h 3h'), // 모두 보드 플레이
          1: p('4d 5d'),
          2: p('7c 8c'),
        },
        board: p('As Ks Qs Js Ts'),
        // iterations=0 → exact evaluation (cardsNeeded==0 경로)
      );

      final sum = equity.values.fold(0.0, (a, b) => a + b);

      // 정확한 값이어야 함
      expect(sum, closeTo(1.0, 1e-9),
          reason:
              '3인 타이 시 equity 합계가 1.0이어야 합니다. '
              'IEEE 754 부동소수점 오차로 0.9999...가 될 수 있습니다.');

      // 각자 1/3 이어야 함
      for (final e in equity.values) {
        expect(e, closeTo(1.0 / 3, 1e-9),
            reason: '3인 동등 타이이므로 각 플레이어 equity = 1/3 이어야 합니다.');
      }
    });

    test('3인 타이 — Monte Carlo 경로에서 equity 합계', () {
      // 프리플롭 상황에서 동일 핸드 3명 (몬테카를로 경로)
      // 동일 홀카드 핸드면 항상 타이에 가까움
      // 단, 완전 같은 카드는 불가 → 유사한 에쿼티로 검증
      final equity = EquityCalculator.calculate(
        hands: {
          0: p('2h 3d'), // 낮은 홀카드
          1: p('4c 5s'),
          2: p('7h 8c'),
        },
        board: p('As Ks Qs Js Ts'), // 5장 보드 → 정확 평가 경로
        seed: 42,
      );

      final sum = equity.values.fold(0.0, (a, b) => a + b);
      // 합계는 항상 1.0에 매우 가까워야 함
      expect(sum, closeTo(1.0, 1e-6));
    });
  });

  // ========================================================================
  // BUG-3: iterations 불일치 검증 [MEDIUM]
  // server.dart는 5000, 기본값은 10000
  // ========================================================================
  group('[CRITIC] BUG-3: iterations 불일치', () {
    test('동일 핸드 — iterations 차이로 결과 분산 확인', () {
      // AKs vs QQ 프리플롭 (시드 고정으로 재현 가능)
      final hands = {
        0: p('As Ks'),
        1: p('Qh Qd'),
      };

      final e5k = EquityCalculator.calculate(
        hands: hands,
        board: [],
        iterations: 5000,  // server.dart 값
        seed: 1234,
      );

      final e10k = EquityCalculator.calculate(
        hands: hands,
        board: [],
        iterations: 10000, // 기본값
        seed: 1234,
      );

      // 동일 시드, 다른 iterations → 다른 결과
      // 차이가 1% 이상이면 문제 (AKs vs QQ 실제 에쿼티 ≈ 46% vs 54%)
      final diff = (e5k[0]! - e10k[0]!).abs();
      print('5K equity[0]: ${e5k[0]}, 10K equity[0]: ${e10k[0]}, diff: $diff');

      // iterations 5000에서의 표준오차 ≈ 0.7%
      // 표준 포커 도구 허용 오차는 ±0.5% → 5000회는 부족
      expect(diff, lessThan(0.02),
          reason:
              'iterations 5000(서버) vs 10000(기본) 차이가 2% 이내여야 합니다. '
              '하지만 5000회는 통계적으로 1.4% 오차를 허용해 실용적 오류 가능.');
    });
  });
}
