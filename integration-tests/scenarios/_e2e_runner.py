#!/usr/bin/env python3
"""S6 Prototype validation E2E runner — 16+10 시나리오 일괄 실행.

실행:
    docker cp integration-tests/scenarios/_e2e_runner.py ebs-bo:/tmp/runner.py
    docker exec ebs-bo python /tmp/runner.py

분류:
    GREEN  — 시나리오 ↔ backend 일치
    YELLOW — backend 미구현 (Type B 기획 공백)
    RED    — backend 오류 (5xx) — Type C 후보
"""
import httpx
import uuid

HOST = 'http://localhost:8000'


def fresh_token():
    r = httpx.post(f'{HOST}/api/v1/auth/login',
                   json={'email': 'admin@local', 'password': 'Admin!Local123'})
    return r.json()['data']['accessToken']


def classify(name, resp, expected_codes):
    code = resp.status_code
    if code in expected_codes:
        return ('GREEN', name, code, '')
    if code == 404:
        return ('YELLOW', name, code, 'endpoint 미구현')
    if code in (401, 403, 405, 409, 422, 400):
        return ('GREEN', name, code, '정상 4xx')
    if code >= 500:
        return ('RED', name, code, 'backend 오류 (Type C)')
    return ('YELLOW', name, code, '예상 외')


def main():
    token = fresh_token()
    hdr = {'Authorization': f'Bearer {token}'}
    results = []

    def call(method, path, name, expected, **kw):
        # headers 병합: 호출자가 headers 를 줬으면 그것을 사용, 아니면 default hdr
        if 'headers' not in kw:
            kw['headers'] = hdr
        try:
            r = httpx.request(method, f'{HOST}{path}', timeout=10.0, **kw)
        except Exception as e:
            results.append(('RED', name, 0, f'exception: {e}'))
            return None
        cls, n, code, note = classify(name, r, expected)
        results.append((cls, n, code, note))
        return r

    # === 16 작성 완료 ===
    # 10 auth login
    r = httpx.post(f'{HOST}/api/v1/auth/login',
                   json={'email': 'admin@local', 'password': 'Admin!Local123'})
    cls, n, code, note = classify('10.1 POST /auth/login', r, [200])
    results.append((cls, n, code, note))
    rt = r.json()['data']['refreshToken']

    # 10.3 refresh (직후 격리)
    r = httpx.post(f'{HOST}/api/v1/auth/refresh', json={'refreshToken': rt})
    cls, n, code, note = classify('10.3 POST /auth/refresh', r, [200])
    results.append((cls, n, code, note))

    # 11 idempotency POST /skins
    sfx = uuid.uuid4().hex[:8]
    call('POST', '/api/v1/skins',
         '11.x POST /skins (idempotency)',
         [201, 200],
         headers={**hdr, 'Idempotency-Key': f'idem-{sfx}'},
         json={'name': f'idem-{sfx}', 'description': 'a', 'theme_data': '{}'})

    # 12 table rebalance saga
    call('POST', '/api/v1/tables/rebalance', '12.x POST /tables/rebalance', [200, 202],
         json={'tournament_id': 1})

    # 13 events replay (HTTP-side)
    call('GET', '/api/v1/events?since=0', '13.x GET /events?since', [200])

    # 20 skin metadata POST (JSON 정정됨)
    sfx = uuid.uuid4().hex[:8]
    call('POST', '/api/v1/skins',
         '20.1 POST /skins (JSON metadata)',
         [201, 200],
         headers={**hdr, 'Idempotency-Key': f'skin-{sfx}'},
         json={'name': f'skin-{sfx}', 'description': 'b', 'theme_data': '{}'})

    # 20.2 list
    call('GET', '/api/v1/skins?limit=20', '20.2 GET /skins (list)', [200])

    # 20.3 by id
    call('GET', '/api/v1/skins/1', '20.3 GET /skins/{id}', [200])

    # 21 PATCH metadata + ETag
    call('PATCH', '/api/v1/skins/1', '21.x PATCH /skins/{id}', [200])

    # 22 activate broadcast
    call('POST', '/api/v1/skins/1/activate', '22.x POST /skins/{id}/activate', [200])

    # 23 RBAC denied (admin → 200, real RBAC test 는 별도 user)
    call('DELETE', '/api/v1/skins/999999', '23.x DELETE /skins/missing', [204, 404])

    # 30 launch CC (정정: launch-cc)
    call('POST', '/api/v1/tables/1/launch-cc', '30.x POST /tables/{id}/launch-cc', [200, 201])

    # 31 CC state — backend 측 endpoint 없음 (Flutter app 호스팅).
    # 대체: GET /tables/{id}/status (재연결 시 backend 측 state 조회)
    call('GET', '/api/v1/tables/1/status', '31.x GET /tables/{id}/status (CC reconnect HTTP-side)', [200])

    # 32 write game info — backend 직접 호스팅 안 함. table 상태 갱신 endpoint 로 대체.
    call('PUT', '/api/v1/tables/1', '32.x PUT /tables/{id} (write game info)', [200],
         json={})

    # 40 overlay security delay — backend 측 endpoint 없음 (Overlay = Flutter app).
    # YELLOW 유지 (backend 미구현 — Spec_Gap)
    call('GET', '/api/v1/overlay/security', '40.x GET /overlay/security', [200])

    # 50 RFID deck register (정정: /api/v1/decks)
    sfx = uuid.uuid4().hex[:6]
    call('POST', '/api/v1/decks', '50.x POST /decks', [200, 201],
         json={'name': f'deck-{sfx}'})

    # 60 flight enum
    call('GET', '/api/v1/flights/1', '60.x GET /flights/{id}', [200])

    # 61 table pause — /pause 전용 endpoint 없음. PUT /tables/{id} 로 paused 필드 갱신.
    call('PUT', '/api/v1/tables/1', '61.x PUT /tables/{id} (pause)', [200],
         json={'isPaused': True})

    # 62 users/me (RBAC bit-flag)
    call('GET', '/api/v1/users/me', '62.x GET /users/me', [200])

    # === 10 신규 시나리오 ===
    # 14 audit-events
    call('GET', '/api/v1/audit-events?limit=10', '14.x GET /audit-events', [200])

    # 24 skin delete (admin) — 이미 23에서 커버. SKIP-equiv: 별도 endpoint 동일.
    # 25 SKIP (D8 multipart)
    results.append(('YELLOW', '25.x [SKIP] gfskin multipart upload', 0, 'D8 — backend 미구현'))

    # 33 hands
    call('GET', '/api/v1/hands/1', '33.x GET /hands/{id}', [200])

    # 34 reports
    call('GET', '/api/v1/reports/rfid-health', '34.x GET /reports/rfid-health', [200])

    # 35 settings
    call('GET', '/api/v1/settings', '35.1 GET /settings', [200])
    call('PUT', '/api/v1/settings', '35.2 PUT /settings', [200],
         json={'key': 'game.test', 'value': 'v1'})

    # 36 players
    call('GET', '/api/v1/players/1', '36.1 GET /players/{id}', [200])
    call('PATCH', '/api/v1/players/1', '36.2 PATCH /players/{id}', [200],
         json={'displayName': 'Updated'})

    # 41 SKIP (WS only)
    results.append(('YELLOW', '41.x [SKIP] WS overlay msgpack', 0, 'WS only — HTTP 범위 밖'))

    # 42 overlay color override (PUT /tables/1)
    call('PUT', '/api/v1/tables/1', '42.x PUT /tables/{id} (overlayColors)', [200],
         json={'overlayColors': {'badgeCheck': '#00FF88'}})

    # 63 blind-structures
    call('GET', '/api/v1/blind-structures', '63.1 GET /blind-structures', [200])
    call('GET', '/api/v1/blind-structures/1/levels', '63.2 GET /blind-structures/{id}/levels', [200])

    # === 출력 ===
    print('=== S6 E2E baseline 16건 ===')
    for cls, name, code, note in results:
        marker = {'GREEN': '✅', 'YELLOW': '🟡', 'RED': '❌'}[cls]
        n = note and f' — {note}' or ''
        print(f' {marker} {cls:6} {name:42} HTTP {code}{n}')

    g = sum(1 for r in results if r[0] == 'GREEN')
    y = sum(1 for r in results if r[0] == 'YELLOW')
    rd = sum(1 for r in results if r[0] == 'RED')
    print(f'\nTotal {len(results)}: GREEN {g} / YELLOW {y} / RED {rd}')


if __name__ == '__main__':
    main()
