---
id: NOTIFY-team4-B088-PR7
title: "B-088 PR-7 — CC consumer camelCase 전환 (ws + REST + Freezed)"
status: OPEN
created: 2026-04-21
from: team1 (B-088 PR-5 선행 알림)
target: team4
priority: P1 (team2 Backend 전환 후 즉시 필요)
mirror: none
tier: internal
backlog-status: open
---

# NOTIFY → team4: B-088 CC consumer 전환

team1 이 B-088 PR-5 (Freezed @JsonKey camelCase + Mock 전환) 선행 완료. team4 CC 는 동일 패턴으로 전환 필요.

## team1 참고 구현

아래 3 작업을 team1 과 동일 방식으로 수행:

### 1. Freezed @JsonKey snake → camelCase

**team1 전환 스크립트** (참고):
```python
# /tmp/convert_jsonkey.py
import re
from pathlib import Path

def snake_to_camel(s): 
    p = s.split('_')
    return p[0] + ''.join(x.capitalize() for x in p[1:])

pattern = re.compile(r"@JsonKey\(name:\s*'([a-z][a-z0-9_]*)'\)")

for f in Path("team4-cc/src/lib/models").rglob("*.dart"):
    if '.freezed.' in f.name or '.g.dart' in f.name: continue
    text = f.read_text(encoding='utf-8')
    new = pattern.sub(lambda m: f"@JsonKey(name: '{snake_to_camel(m.group(1))}')", text)
    if new != text:
        f.write_text(new, encoding='utf-8', newline='\n')
```

이후 `dart run build_runner build --delete-conflicting-outputs` + `flutter analyze`.

### 2. WS consumer event type PascalCase

team4 `src/lib/data/remote/bo_websocket_client.dart` / `ws_provider.dart` 의 switch case:
- snake_case 이벤트 명 → PascalCase (team2 publisher PR-3 전환된 이벤트명과 매칭)
- CC 전용 이벤트 (`HandStarted`, `ActionPerformed`, `CardDetected` 등) 는 이미 PascalCase

### 3. REST path kebab → PascalCase

Repository 내 모든 kebab-case path 를 PascalCase 로 교체:
- `/hand-history` → `/HandHistory`
- `/audit-logs` → `/AuditLogs`
- 등

### 4. Mock/fixture 전환

team4 에 mock server 가 있다면 동일하게 camelCase 로 전환:
- Mock JSON fixture
- 단위 테스트 JSON fixture

## 선행 의존

- **team2 PR-2** (Pydantic alias_generator) — 완료 전에는 실 BO 연결 시 API 파싱 실패
- **team2 PR-3** (WS publisher PascalCase) — 완료 전에는 WS 이벤트 dispatch 미스매치
- **team2 PR-4** (REST path PascalCase) — 완료 전에는 실 BO 호출 404

team2 의 3 PR 완료 후 team4 작업 진입 권장.

## 수락 기준

- [ ] `@JsonKey` camelCase 전수 교체 + build_runner 재생성
- [ ] WS switch case PascalCase 통일
- [ ] REST path kebab → PascalCase (Repository 전수)
- [ ] Mock/fixture camelCase
- [ ] `dart analyze` 0 errors
- [ ] CC 앱 실 BO 연결 E2E 검증

## 관련

- SSOT: `docs/2. Development/2.5 Shared/Naming_Conventions.md` v2
- team1 참고: 본 session commit (해시 TBD) — Freezed 전환 완료 선례
- Master: `docs/4. Operations/Conductor_Backlog/B-088-naming-convention-camelcase-migration.md`
