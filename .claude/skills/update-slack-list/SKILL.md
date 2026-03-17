---
name: update-slack-list
description: >
  This skill should be used when the user needs to update Slack Lists vendor management system including add/modify/delete vendors and status changes.
version: 2.0.0
triggers:
  keywords:
    - "update slack list"
    - "update slacklist"
    - "slack list"
    - "slacklist"
    - "slack-list"
    - "업체 리스트"
    - "vendor list"
    - "업체 목록"
  patterns:
    - "--update\\s+(slack\\s*list|slacklist)"
    - "slack\\s*list.*(update|sync|add|remove)"
    - "업체.*(추가|수정|삭제|동기화)"
  file_patterns:
    - "**/slack_lists.json"
    - "**/lists_collector.py"
auto_trigger: true
---

# Update Slack List

EBS 프로젝트의 Slack Lists 업체 관리 시스템을 업데이트합니다.

## 호출 방법

```bash
/auto --update slacklist
/auto --update slack list
/auto --update slack-list
/update-slack-list
```

## 기능

| 명령 | 설명 |
|------|------|
| `sync` | Slack에서 최신 데이터 동기화 |
| `sync post` | 동기화 후 채널 포스팅까지 |
| `add <name> <url> <info>` | 새 업체 추가 |
| `update <id> <field> <value>` | 업체 정보 수정 (multi-field 지원) |
| `status <id> <status>` | 상태 변경 (후보→견적요청→계약 등) |
| `post` | 채널에 요약 메시지 업데이트 |
| `report` | 현재 상태 리포트 출력 |

## 강제 실행 규칙 (MANDATORY)

**이 스킬이 활성화되면 반드시 다음을 실행합니다.**

### Step 1: 현재 상태 확인

```powershell
python "C:/claude/ebs/tools/morning-automation/main.py"
```

### Step 2: 요청별 실행

| 사용자 요청 | 실행할 명령 |
|-------------|-------------|
| "동기화", "sync", "최신화" | `python "C:/claude/ebs/tools/morning-automation/main.py" --full --no-report` |
| "채널 업데이트", "post" | `python "C:/claude/ebs/tools/morning-automation/main.py" --post` |
| "리포트", "상태 확인" | `python "C:/claude/ebs/tools/morning-automation/main.py"` (incremental) |
| "업체 추가" | `ListsCollector().add_vendor(name, url, info, category, contact, status)` |
| "상태 변경" | `ListsCollector().update_item_status(item_id, status)` |
| "필드 수정" | `ListsCollector().update_item_fields(item_id, {"field": "value"})` |

### Step 3: 결과 확인 및 보고

```powershell
python -c "
import sys; sys.path.insert(0, 'C:/claude/ebs/tools/morning-automation')
from collectors import ListsCollector
c = ListsCollector()
s = c.get_summary()
print(f'총 {s[\"total\"]}개 업체')
print(f'  Category A (통합 파트너): {s[\"A\"]}')
print(f'  Category B (부품 공급): {s[\"B\"]}')
print(f'  Category C (벤치마크): {s[\"C\"]}')
"
```

## 업체 카테고리 (A/B/C)

| 카테고리 | 설명 | 기준 | 업체 |
|----------|------|------|------|
| **A** | 통합 파트너 후보 | RFID 카드 + 리더 통합 공급 가능 | Sun-Fly, Angel, 엠포플러스 |
| **B** | 부품 공급업체 | 카드 또는 리더 한쪽만 가능 | FEIG, GAO, Identiv, PONGEE, Waveshare, SparkFun, Adafruit, Faded Spade, ST Micro |
| **C** | 벤치마크/참조 | 이메일 불필요, 경쟁사 참조용 | PokerGFX, RF Poker, Abbiati, Matsui, S.I.T. Korea |

## 상태 값

| 상태 | 설명 |
|------|------|
| `후보` | 초기 상태 |
| `견적요청` | RFI/RFQ 전송됨 |
| `견적수신` | 견적서 받음 |
| `협상중` | 가격/조건 협상 |
| `계약` | 계약 완료 |
| `보류` | 일시 보류 |
| `제외` | 후보에서 제외 |

## 업데이트 가능한 필드

| 필드 | column_id | 설명 |
|------|-----------|------|
| `name` | Col0ACQP79Y1J | 업체명 (primary) |
| `category` | Col0ACEPEKNRZ | 카테고리 |
| `description` | Col0ACM5EBF1Q | 설명 |
| `contact` | Col0ACHNF1G93 | 연락처 |
| `status` | Col0AC5MSUPPZ | 상태 |

## 채널 포스팅 형식

`post` 실행 시 #ggpnotice 채널의 기존 메시지를 업데이트합니다:

```
*EBS 업체 관리 - 통합 파트너 선정*

📋 업체 리스트 보기 (17개 업체)
카테고리 A: 3개 | B: 9개 | C: 5개

*RFI 현황:*
• Sun-Fly: 견적요청 📤 RFI 발송
• Angel Playing Cards: 견적요청 📤 RFI 발송
• 엠포플러스: 견적요청 📤 RFI 발송

_업데이트: 2026-02-05 12:00_
```

- Category A 업체의 RFI 발송/회신 상태를 자동 감지
- Gmail 수신 데이터에서 회신 여부 확인
- Slack List 상태에서 발송 여부 확인

## 파일 위치

| 파일 | 용도 |
|------|------|
| `C:\claude\ebs\tools\morning-automation\main.py` | 메인 스크립트 |
| `C:\claude\ebs\tools\morning-automation\collectors\lists_collector.py` | Lists API 클라이언트 |
| `C:\claude\ebs\tools\morning-automation\reporters\slack_poster.py` | 채널 포스팅 |
| `C:\claude\ebs\tools\morning-automation\data\slack_lists.json` | 캐시된 데이터 |
| `C:\claude\json\slack_credentials.json` | 인증 정보 (user_token 필요) |

## 인증 요구사항

Slack Lists API는 **User Token** (`xoxp-...`)이 필요합니다.

## 예시

### 전체 동기화 + 채널 업데이트
```
/auto --update slacklist sync post
```

### 업체 추가
```
/auto --update slacklist add "NewVendor" "https://example.com" "RFID 모듈 제조사"
```

### 상태 변경
```
/auto --update slacklist status Rec0ACEPH1DSP 견적요청
```

### 필드 수정
```
/auto --update slacklist update Rec0ACEPH1DSP contact info@vendor.com
```

### 채널 업데이트
```
/auto --update slacklist post
```

## 자동 트리거

다음 키워드 감지 시 자동 활성화:
- "update slack list"
- "슬랙 리스트 업데이트"
- "업체 목록 동기화"
- "vendor list sync"
