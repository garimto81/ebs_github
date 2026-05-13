/**
 * v02 — /next-hand Regression Strengthening (S7 Cycle 8 / Issue #341)
 *
 * S9 Cycle 6 PR #320 v02-multi-hand-flow.spec.ts 의 후속 — 점 검증(0→1→2→3)
 * 위에 **invariant 기반** property test 로 회귀 강화.
 *
 * 검증 invariants (POST /api/session/{id}/next-hand):
 *   INV-1: handNumber strict +1 per call (delta 검증, 누적 무관)
 *   INV-2: dealerSeat strict +1 mod seats per call (round-robin stride)
 *   INV-3: seats[dealerSeat].isDealer === true, others === false (uniqueness)
 *   INV-4: per-seat reset — currentBet === 0, status === active (folded→active 복귀)
 *   INV-5: community === [], pot.main === 0 (board/pot reset)
 *   INV-6: stack 보존 — /next-hand 가 stack 을 변경하지 않음
 *   INV-7: sessionId 불변 (identity preservation)
 *
 * Cycle 6 v02 가 검증한 specific values (0→1→2→3) 가 아닌, **N round 일반화**:
 *   - 6-seat 테이블에서 6회 호출하여 dealer 가 0→1→2→3→4→5→0 round-robin
 *   - handNumber 가 단조 증가 (1 → 7)
 *
 * 의존성:
 *   - S8 Cycle 5 PR #301 (#287) Engine harness POST /next-hand
 *   - S9 Cycle 6 PR #320 baseline (v02-multi-hand-flow.spec.ts)
 *   - admin@local / Admin!Local123 (BO tools/seed_admin.py SSOT)
 *
 * 본 시나리오 작성: 2026-05-12 S7 Cycle 8 Wave 1 (issue #341)
 */
import { expect, test, type APIRequestContext } from '@playwright/test';

const ENGINE_BASE_URL = process.env.ENGINE_BASE_URL ?? 'http://localhost:18080';

type SeatJson = {
  index: number;
  isDealer: boolean;
  stack: number;
  currentBet: number;
  status: string;
  holeCards?: string[];
};

type SessionJson = {
  sessionId: string;
  street: string;
  dealerSeat: number;
  handNumber: number;
  seats: SeatJson[];
  community: string[];
  pot: { main: number; total: number };
};

async function engineRequest(
  request: APIRequestContext,
  method: 'GET' | 'POST',
  pathSuffix: string,
  body?: Record<string, unknown>,
): Promise<SessionJson> {
  const url = `${ENGINE_BASE_URL}${pathSuffix}`;
  const res =
    method === 'GET'
      ? await request.get(url)
      : await request.post(url, body ? { data: body } : {});
  expect([200, 201], `${method} ${pathSuffix} status`).toContain(res.status());
  return (await res.json()) as SessionJson;
}

async function createSession(
  request: APIRequestContext,
  seats: number,
): Promise<SessionJson> {
  return engineRequest(request, 'POST', '/api/session', {
    variant: 'nlh',
    seats,
  });
}

async function nextHand(
  request: APIRequestContext,
  sessionId: string,
): Promise<SessionJson> {
  return engineRequest(request, 'POST', `/api/session/${sessionId}/next-hand`);
}

async function postEvent(
  request: APIRequestContext,
  sessionId: string,
  event: Record<string, unknown>,
): Promise<SessionJson> {
  return engineRequest(request, 'POST', `/api/session/${sessionId}/event`, event);
}

test.use({
  storageState: { cookies: [], origins: [] },
});

test.describe('v02 — /next-hand Regression (S7 Cycle 8 #341)', () => {
  test.setTimeout(60_000);

  test('INV-1/2: handNumber +1 + dealer +1 stride (6-seat round-robin)', async ({
    request,
  }) => {
    // 6-seat 테이블 → 6회 호출하여 round-robin 완주
    const SEATS = 6;
    const ROUNDS = 6;

    const initial = await createSession(request, SEATS);
    expect(initial.dealerSeat, 'initial dealer === 0').toBe(0);
    expect(initial.handNumber, 'initial handNumber === 0').toBe(0);

    // hand 1 종료 (hand_end auto-rotate: dealer 0→1, handNumber 0→1)
    const ended = await postEvent(request, initial.sessionId, {
      type: 'hand_end',
    });
    expect(ended.handNumber, 'hand_end: handNumber 0→1').toBe(1);
    expect(ended.dealerSeat, 'hand_end: dealer 0→1').toBe(1);

    let prev = ended;
    for (let i = 1; i <= ROUNDS; i++) {
      const after = await nextHand(request, initial.sessionId);

      // INV-1: handNumber strict +1
      expect(
        after.handNumber - prev.handNumber,
        `round ${i}: handNumber +1 invariant`,
      ).toBe(1);

      // INV-2: dealerSeat strict +1 mod SEATS
      const expectedDealer = (prev.dealerSeat + 1) % SEATS;
      expect(
        after.dealerSeat,
        `round ${i}: dealer ${prev.dealerSeat}→${expectedDealer} stride invariant`,
      ).toBe(expectedDealer);

      // INV-7: sessionId 불변
      expect(after.sessionId, `round ${i}: sessionId 불변`).toBe(
        initial.sessionId,
      );

      prev = after;
    }

    // 누적 검증: hand_end(+1) + nextHand × 6 (+6) = handNumber 7
    expect(prev.handNumber, '누적 handNumber === 7').toBe(7);
    // dealer: hand_end 후 1, +6 = 7 mod 6 = 1 (round-robin 1바퀴 + 1)
    expect(prev.dealerSeat, '누적 dealer === 1 (round-robin 완주)').toBe(1);
  });

  test('INV-3/4/5: state reset (isDealer uniqueness + per-seat reset)', async ({
    request,
  }) => {
    const SEATS = 6;
    const initial = await createSession(request, SEATS);

    // Hand 1: 모두 fold-to-BB → pot_awarded → hand_end
    for (const seatIndex of [3, 4, 5, 0, 1]) {
      await postEvent(request, initial.sessionId, {
        type: 'fold',
        seatIndex,
      });
    }
    await postEvent(request, initial.sessionId, {
      type: 'pot_awarded',
      awards: { '2': 15 },
    });
    const ended = await postEvent(request, initial.sessionId, {
      type: 'hand_end',
    });

    // Hand 1 종료 상태: 5 folded + 1 active (BB winner)
    const foldedAtEnd = ended.seats.filter((s) => s.status === 'folded').length;
    expect(foldedAtEnd, '5 seats folded after hand_end').toBe(5);

    // KEY: /next-hand 호출 → state reset 검증
    const after = await nextHand(request, initial.sessionId);

    // INV-3: dealer isDealer uniqueness (정확히 1명)
    const dealerCount = after.seats.filter((s) => s.isDealer).length;
    expect(dealerCount, 'isDealer === true 가 정확히 1명').toBe(1);
    expect(
      after.seats[after.dealerSeat].isDealer,
      'dealerSeat 의 seat 만 isDealer === true',
    ).toBe(true);

    // INV-4: per-seat reset
    for (const seat of after.seats) {
      expect(seat.currentBet, `seat[${seat.index}].currentBet === 0`).toBe(0);
      expect(
        seat.status,
        `seat[${seat.index}].status === active (folded→active 복귀)`,
      ).toBe('active');
    }

    // INV-5: community + pot reset
    expect(after.community, 'community === []').toEqual([]);
    expect(after.pot.main, 'pot.main === 0').toBe(0);
  });

  test('INV-6: stack 보존 across /next-hand (no stack mutation)', async ({
    request,
  }) => {
    const SEATS = 6;
    const initial = await createSession(request, SEATS);

    // Hand 1 종료까지만 진행 (stack 의미 있는 변화 발생: SB=995, BB=1005)
    for (const seatIndex of [3, 4, 5, 0, 1]) {
      await postEvent(request, initial.sessionId, {
        type: 'fold',
        seatIndex,
      });
    }
    await postEvent(request, initial.sessionId, {
      type: 'pot_awarded',
      awards: { '2': 15 },
    });
    const beforeEnd = await postEvent(request, initial.sessionId, {
      type: 'hand_end',
    });

    const stacksBefore = beforeEnd.seats.map((s) => s.stack);

    // /next-hand 호출 후 stack 이 변하지 않는지 검증
    const afterNext1 = await nextHand(request, initial.sessionId);
    const stacksAfter1 = afterNext1.seats.map((s) => s.stack);
    expect(stacksAfter1, 'INV-6: stack 보존 (1st /next-hand)').toEqual(
      stacksBefore,
    );

    // 2nd /next-hand 도 stack 보존 (Hand 2 가 actual play 없이 setup 만)
    const afterNext2 = await nextHand(request, initial.sessionId);
    const stacksAfter2 = afterNext2.seats.map((s) => s.stack);
    expect(stacksAfter2, 'INV-6: stack 보존 (2nd /next-hand)').toEqual(
      stacksBefore,
    );
  });

  test('Edge: GET 멱등성 — /next-hand 결과가 GET 으로 재현', async ({
    request,
  }) => {
    const SEATS = 6;
    const initial = await createSession(request, SEATS);
    await postEvent(request, initial.sessionId, { type: 'hand_end' });

    const afterPost = await nextHand(request, initial.sessionId);
    const afterGet = await engineRequest(
      request,
      'GET',
      `/api/session/${initial.sessionId}`,
    );

    expect(afterGet.handNumber, 'POST 응답과 GET 응답 handNumber 일치').toBe(
      afterPost.handNumber,
    );
    expect(afterGet.dealerSeat, 'POST 응답과 GET 응답 dealerSeat 일치').toBe(
      afterPost.dealerSeat,
    );
    expect(afterGet.sessionId).toBe(afterPost.sessionId);
  });
});
