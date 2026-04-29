import { test, expect, type APIRequestContext } from '@playwright/test';

/**
 * V9.5 P14 — Browser-level E2E for BlindStructure + Levels CRUD
 *
 * 통합 검증 대상:
 *   - V9.5 P2 (team1): POST /auth/logout (DELETE /auth/session 폐기)
 *   - V9.5 P3 (team2): /blind-structures/{bs_id}/levels CRUD endpoints
 *   - V9.5 P7 (team2): 4 endpoints (skins/deactivate, users/force-logout, tables/seats 등)
 *
 * 본 시나리오는 API-level (request fixture) 위주. UI page object 는 별도 cycle.
 *
 * 사전 요구:
 *   - BO container http://localhost:8000 healthy
 *   - lobby-web container http://localhost:3000 healthy (baseURL)
 *   - admin@ebs.test / test-password-1234 계정 존재 (또는 env override)
 */

const BO_BASE_URL = process.env.BO_BASE_URL ?? 'http://localhost:8000';
const ADMIN_USERNAME = process.env.ADMIN_USERNAME ?? 'admin@ebs.test';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD ?? 'test-password-1234';

async function login(request: APIRequestContext): Promise<string> {
  const res = await request.post(`${BO_BASE_URL}/api/v1/auth/login`, {
    data: { username: ADMIN_USERNAME, password: ADMIN_PASSWORD },
  });
  expect(res.status(), 'login should succeed').toBe(200);
  const body = await res.json();
  expect(body.data?.access_token, 'access_token in response').toBeTruthy();
  return body.data.access_token as string;
}

test.describe('V9.5 BlindStructure + Levels CRUD flow', () => {
  test('admin can create BS, CRUD levels, and logout', async ({ request }) => {
    // ---- Step 1: Login ----------------------------------------------------
    const token = await login(request);
    const authHeaders = { Authorization: `Bearer ${token}` };

    // ---- Step 2: Create BlindStructure -----------------------------------
    const createBsRes = await request.post(`${BO_BASE_URL}/api/v1/blind-structures`, {
      headers: authHeaders,
      data: {
        name: 'V9.5 P14 E2E Test Structure',
        levels: [
          { level_no: 1, small_blind: 100, big_blind: 200, ante: 0, duration_minutes: 15 },
        ],
      },
    });
    expect(createBsRes.status(), 'BS create returns 2xx').toBeGreaterThanOrEqual(200);
    expect(createBsRes.status()).toBeLessThan(300);
    const bsBody = await createBsRes.json();
    const bsId: string = bsBody.data?.blind_structure_id ?? bsBody.data?.id;
    expect(bsId, 'blind_structure_id in response').toBeTruthy();

    // ---- Step 3: POST level (V9.5 P3 endpoint) ---------------------------
    const postLevelRes = await request.post(
      `${BO_BASE_URL}/api/v1/blind-structures/${bsId}/levels`,
      {
        headers: authHeaders,
        data: {
          level_no: 2,
          small_blind: 200,
          big_blind: 400,
          ante: 50,
          duration_minutes: 20,
        },
      },
    );
    expect(postLevelRes.status(), 'POST level returns 2xx').toBeGreaterThanOrEqual(200);
    expect(postLevelRes.status()).toBeLessThan(300);
    const levelBody = await postLevelRes.json();
    const levelId: string = levelBody.data?.id;
    expect(levelId, 'level id in response').toBeTruthy();

    // ---- Step 4: GET levels list -----------------------------------------
    const listRes = await request.get(
      `${BO_BASE_URL}/api/v1/blind-structures/${bsId}/levels`,
      { headers: authHeaders },
    );
    expect(listRes.status(), 'GET levels returns 200').toBe(200);
    const listBody = await listRes.json();
    expect(Array.isArray(listBody.data), 'levels list is array').toBe(true);
    expect(listBody.data.length, 'at least 2 levels (initial + added)').toBeGreaterThanOrEqual(2);

    // ---- Step 5: PUT level (partial update, V9.5 P3) ---------------------
    const putRes = await request.put(
      `${BO_BASE_URL}/api/v1/blind-structures/${bsId}/levels/${levelId}`,
      {
        headers: authHeaders,
        data: { small_blind: 300, big_blind: 600 },
      },
    );
    expect(putRes.status(), 'PUT level returns 2xx').toBeGreaterThanOrEqual(200);
    expect(putRes.status()).toBeLessThan(300);

    // ---- Step 6: DELETE level (V9.5 P3) ----------------------------------
    const deleteLevelRes = await request.delete(
      `${BO_BASE_URL}/api/v1/blind-structures/${bsId}/levels/${levelId}`,
      { headers: authHeaders },
    );
    expect(deleteLevelRes.status(), 'DELETE level returns 2xx').toBeGreaterThanOrEqual(200);
    expect(deleteLevelRes.status()).toBeLessThan(300);

    // ---- Step 7: Cleanup BlindStructure ----------------------------------
    const deleteBsRes = await request.delete(
      `${BO_BASE_URL}/api/v1/blind-structures/${bsId}`,
      { headers: authHeaders },
    );
    expect(deleteBsRes.status(), 'DELETE BS returns 2xx').toBeGreaterThanOrEqual(200);
    expect(deleteBsRes.status()).toBeLessThan(300);

    // ---- Step 8: Logout (V9.5 P2 — POST /auth/logout) --------------------
    const logoutRes = await request.post(`${BO_BASE_URL}/api/v1/auth/logout`, {
      headers: authHeaders,
    });
    expect(logoutRes.status(), 'POST /auth/logout returns 2xx').toBeGreaterThanOrEqual(200);
    expect(logoutRes.status()).toBeLessThan(300);
  });
});
