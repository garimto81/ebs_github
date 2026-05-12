---
title: Inter-Session Chat — Manual Verification (Phase L1)
owner: conductor
tier: internal
status: PENDING
plan: ~/.claude/plans/serene-greeting-pretzel.md
spec: docs/4. Operations/Inter_Session_Chat_Design.md
last-updated: 2026-05-12
---

# Inter-Session Chat — Manual Verification

> **목적**: B-222 구현 (PR #260) 의 Web UI 4분할 + @ autocomplete + SSE push + 합의 모델을 사용자가 직접 체험. UX 인사이트 + 미발견 이슈 도출.
>
> **Phase**: L1 (verification plan §2.1). 자동화는 L2~L4.

## 0. 진입점 (사용자 직접 실행)

```powershell
# 1) broker 살아있는지 확인
python tools/orchestrator/start_message_bus.py --probe
# alive=true 면 skip. 죽었으면 :
python tools/orchestrator/start_message_bus.py --detach

# 2) chat-server 컨테이너 기동
docker compose -f tools/chat_server/docker-compose.yml up -d

# 3) 헬스 확인
curl http://localhost:7390/health
# 기대: {"status":"ok","broker_alive":true,...}

# 4) 브라우저
start http://localhost:7390/
```

종료 시 (테스트 마치고):

```powershell
docker compose -f tools/chat_server/docker-compose.yml down
```

## 1. 검증 시나리오 (7개)

각 시나리오 끝에 ☑ 또는 ☒ 표시 + 메모 + 스크린샷 경로 (있으면).

### S1. UI 4 분할 표시

- [ ] 브라우저 진입 시 4 패널 (#design / #blocker / #handoff / LIVE TRACE) 모두 표시
- [ ] 상단 헤더 `broker: online` (녹색)
- [ ] 우측 헤더에 `active: ...` (peers 없으면 빈 문자열 OK)

**메모**:

**스크린샷**: `docs/4. Operations/screenshots/chat-l1-s1-fourpanel.png` (있으면)

---

### S2. 직접 발화 (CLI → SSE → UI)

별도 PowerShell 터미널에서:

```powershell
python -m tools.chat_server.cli send --channel room:design "@S2 test from user"
```

- [ ] 브라우저 `#design` 패널에 메시지 즉시 등장 (1초 이내)
- [ ] `[user]` 발신자 빨간색 + 굵게 표시
- [ ] `@S2` 노란 강조 (mention class)
- [ ] 메시지 본문 `test from user` 가독성 OK

**메모**:

---

### S3. @ Autocomplete

- [ ] `#design` 입력창 클릭 → 포커스
- [ ] `@` 입력 → 드롭다운 표시 (active peers + user + all)
- [ ] ↓ 화살표 → 다음 항목 활성화 (파란 배경)
- [ ] Enter → `@<선택>` + 공백 자동 삽입, 드롭다운 사라짐
- [ ] 메시지 본문 추가 입력 + Enter → 발신
- [ ] 발신 메시지가 본인 UI 에도 즉시 등장
- [ ] Esc 로 드롭다운 닫기 OK

**메모**:

---

### S4. Reply 미리보기 + 클릭 점프

선행: 첫 메시지 (seq=N) publish 후, 두 번째 메시지를 reply 로 발행:

```powershell
python -m tools.chat_server.cli send --channel room:design --reply-to <seq> "agreed"
```

- [ ] reply 메시지 위에 `↪ re: <원본 본문 60자>` 표시
- [ ] 들여쓰기 + 파란 좌측 border
- [ ] `↪ re:` 클릭 → 원본 메시지로 스크롤 + 1.5초 노란색 강조
- [ ] 캐시 미스 (history 50건 밖) 시 `↪ re: seq=N` fallback 표시

**메모**:

---

### S5. LIVE TRACE 분할 + 필터

전제: broker 가 다른 event (예: 다른 worktree 의 stream publish) 받고 있어야 trace 표시.

직접 trace event 발생:
```powershell
# 가짜 stream event (S2 가 stream:S2 에 publish)
python -c "
import asyncio
from tools.chat_server.broker_client import BrokerClient
async def main():
    r = await BrokerClient(url='http://127.0.0.1:7383/mcp').publish(
        topic='stream:S2',
        payload={'status': 'IN_PROGRESS', 'note': 'manual test'},
        source='S2'
    )
    print(r)
asyncio.run(main())
"
```

- [ ] LIVE TRACE 분할에 `stream:S2 (S2) status=IN_PROGRESS` 한 줄 표시
- [ ] 카테고리 색상: stream = 녹색, cascade = 파란색, pipeline = 주황, audit = 회색
- [ ] 헤더 체크박스 `[stream]` toggle off → stream:* 메시지 숨김
- [ ] 다시 toggle on → 표시 복귀

**메모**:

---

### S6. Broker offline / 복구

```powershell
# broker stop
python tools/orchestrator/stop_message_bus.py
```

- [ ] 30초 이내 브라우저 상단 헤더 빨간색 `broker: offline (retrying...)` 변경
- [ ] 채팅 발신 시 503 또는 timeout (chat-server 가 broker 호출 실패)

```powershell
# broker 재기동
python tools/orchestrator/start_message_bus.py --detach
```

- [ ] 30초 이내 헤더 녹색 `broker: online` 복귀
- [ ] missed event (다른 publisher 가 보낸 것 있으면) catch-up 표시

**메모**:

---

### S7. 합의 모델 silent_ok_30s (선택, 깊은 검증)

별도 터미널에서:

```powershell
python -c "
import asyncio
from tools.chat_server.broker_client import BrokerClient
from tools.chat_server.hook_integration import consensus_silent_ok

async def main():
    client = BrokerClient(url='http://127.0.0.1:7383/mcp')
    r = await client.publish(
        topic='chat:room:design',
        payload={'kind':'msg','from':'S2','to':[],'body':'silent test','mentions':[],'ts':'2026-05-12T10:00:00Z'},
        source='S2'
    )
    print('question seq:', r['seq'])
    outcome, replies = await consensus_silent_ok(
        question_seq=r['seq'], topic='chat:room:design',
        from_team='S2', ttl_sec=10
    )
    print('outcome:', outcome, 'replies:', len(replies))
asyncio.run(main())
"
```

- [ ] 10초 후 outcome = `silent_ok`
- [ ] 브라우저 #design 에 system message `[ASSUMED] proceeding...` 등장 (kind=decision)
- [ ] reply_to 가 원본 seq 가리킴

**메모**:

---

## 2. 발견 이슈 (사용자 작성)

| ID | 시나리오 | 이슈 | 심각도 |
|----|---------|------|:------:|
|    |         |      |        |
|    |         |      |        |

각 이슈는 별도 backlog 항목 등록 권장:
- `docs/4. Operations/Conductor_Backlog/B-XXX-chat-ui-issue-...md`
- frontmatter `parent: B-222`

## 3. UX 개선 후보 (사용자 추천)

- [ ] (예) #design 패널에 "이번 세션이 보낸 메시지만" 필터 chip
- [ ] (예) 본인 mention 받을 때 알림음 (선택 toggle)
- [ ] (예) 메시지 검색 (`Ctrl+F`)
- [ ] (예) 채널 swap (4번째 분할에 다른 chat channel 선택 가능)

## 4. 결론

- [ ] 핵심 기능 동작 (S1~S6) PASS
- [ ] S7 합의 모델 동작
- [ ] L2 (Playwright 자동화) 진입 가능
- [ ] 또는 추가 개선 필요 (이슈 list 우선 해결)

**작성일**: ____  
**작성자**: ____

---

## 부록: 빠른 명령 cheat sheet

```powershell
# 헬스
curl http://localhost:7390/health

# 채널 history
curl "http://localhost:7390/chat/history?channel=room:design&limit=20"

# 활성 peers
curl "http://localhost:7390/chat/peers?active=true"

# CLI watch (모든 채널 tail)
python -m tools.chat_server.cli watch

# CLI history
python -m tools.chat_server.cli history room:design --last 50

# 컨테이너 로그
docker compose -f tools/chat_server/docker-compose.yml logs -f chat-server

# broker 로그
type .claude\message_bus\broker.log
```
