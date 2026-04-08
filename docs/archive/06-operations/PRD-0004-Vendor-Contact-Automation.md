# PRD-0004: EBS 업체 컨택 자동화 시스템

> **BRACELET STUDIO** | EBS Project | Phase 0

---

## 1. 개요

### 1.1 배경

EBS 프로젝트 Phase 0 단계에서 RFID 업체 선정을 위해 여러 업체에 연락해야 합니다. 현재 6개 업체가 관리 대상이며, 이 중 4개 업체(카테고리 A 2개, 카테고리 B 2개)는 RFI 발송 대상입니다.

**업체 현황 (VENDOR-MANAGEMENT.md v8.1.0 기준):**

| 카테고리 | 업체 수 | 설명 | RFI 필요 |
|----------|:-------:|------|:--------:|
| **A: 통합 파트너 후보** | 2 | RFID 카드 + 리더 통합 공급 가능 | ✅ |
| **B: 부품/모듈 공급** | 2 | 개별 구매, 별도 RFI | ✅ |
| **C: 벤치마크/참조** | 2 | 장비 참조, 이메일 불필요 | ❌ |

### 1.2 목표

- 업체 컨택 프로세스 자동화
- 이메일 템플릿 기반 일괄 발송
- Follow-up 자동 추적 및 알림
- Slack List ↔ Gmail 상태 동기화

### 1.3 범위

| 포함 | 제외 |
|------|------|
| 이메일 템플릿 시스템 | 전화/화상 미팅 일정 |
| Gmail 자동 전송 | CRM 시스템 구축 |
| Follow-up 추적 | 계약서 관리 |
| Slack List 상태 연동 | 결제 프로세스 |

---

## 2. 상태 머신 (State Machine)

### 2.1 업체 상태 전이도

```
                                    ┌──────────────┐
                                    │   NEW        │
                                    │ (신규 등록)   │
                                    └──────┬───────┘
                                           │
                                           ▼
┌────────────────────────────────────────────────────────────────┐
│                        CONTACT PHASE                           │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  ┌──────────────┐    RFI 전송     ┌──────────────┐            │
│  │  IDENTIFIED  │───────────────▶│ RFI_SENT     │            │
│  │ (연락처 확보) │                │ (정보요청 발송)│            │
│  └──────────────┘                └──────┬───────┘            │
│                                         │                     │
│         ┌───────────────────────────────┼───────────────┐     │
│         │                               │               │     │
│         ▼                               ▼               ▼     │
│  ┌──────────────┐              ┌──────────────┐  ┌──────────┐│
│  │ NO_RESPONSE  │              │  RESPONDED   │  │ BOUNCED  ││
│  │ (무응답)      │◀─ 7일 경과 ─│  (응답 수신)  │  │ (반송)   ││
│  └──────┬───────┘              └──────┬───────┘  └──────────┘│
│         │                             │                       │
│         │ Follow-up                   │ 관심 표명              │
│         ▼                             ▼                       │
│  ┌──────────────┐              ┌──────────────┐              │
│  │ FOLLOWUP_1   │              │ INTERESTED   │              │
│  │ (1차 후속)    │              │ (관심 업체)   │              │
│  └──────┬───────┘              └──────┬───────┘              │
│         │                             │                       │
│         │ 7일 경과                     │ RFP 전송              │
│         ▼                             ▼                       │
│  ┌──────────────┐              ┌──────────────┐              │
│  │ FOLLOWUP_2   │              │  RFP_SENT    │              │
│  │ (2차 후속)    │              │ (견적요청 발송)│              │
│  └──────┬───────┘              └──────┬───────┘              │
│         │                             │                       │
│         │ 7일 경과                     │ 견적 수신              │
│         ▼                             ▼                       │
│  ┌──────────────┐              ┌──────────────┐              │
│  │   CLOSED     │              │QUOTE_RECEIVED│              │
│  │ (컨택 종료)   │              │ (견적 수신)   │              │
│  └──────────────┘              └──────┬───────┘              │
│                                       │                       │
└───────────────────────────────────────┼───────────────────────┘
                                        │
                                        ▼
                               ┌──────────────┐
                               │  EVALUATING  │
                               │ (검토 중)     │
                               └──────┬───────┘
                                      │
                      ┌───────────────┼───────────────┐
                      ▼               ▼               ▼
               ┌──────────┐   ┌──────────┐   ┌──────────┐
               │ SELECTED │   │ REJECTED │   │ ON_HOLD  │
               │ (선정)    │   │ (탈락)    │   │ (보류)   │
               └──────────┘   └──────────┘   └──────────┘
```

### 2.2 상태 정의

| 상태 | 설명 | 다음 액션 |
|------|------|----------|
| `NEW` | 리스트에 등록됨 | 연락처 확보 |
| `IDENTIFIED` | 연락처 확보 완료 | RFI 전송 |
| `RFI_SENT` | 정보요청 이메일 발송 | 응답 대기 |
| `RESPONDED` | 이메일 응답 수신 | 내용 검토 |
| `NO_RESPONSE` | 7일간 응답 없음 | Follow-up 발송 |
| `FOLLOWUP_1` | 1차 후속 이메일 발송 | 응답 대기 |
| `FOLLOWUP_2` | 2차 후속 이메일 발송 | 응답 대기 |
| `INTERESTED` | 관심 표명 | RFP 전송 |
| `RFP_SENT` | 견적요청 이메일 발송 | 견적 대기 |
| `QUOTE_RECEIVED` | 견적서 수신 | 검토 진행 |
| `EVALUATING` | 내부 검토 중 | 의사결정 |
| `SELECTED` | 최종 선정 | 계약 진행 |
| `REJECTED` | 탈락 | 감사 메일 |
| `ON_HOLD` | 보류 | 추후 재검토 |
| `BOUNCED` | 이메일 반송 | 대체 연락처 확보 |
| `CLOSED` | 컨택 종료 | - |

---

## 3. 이메일 템플릿 시스템

### 3.1 템플릿 구조

```
templates/
├── rfi/
│   ├── rfi_initial.md          # 초기 정보 요청
│   └── rfi_initial.html        # HTML 버전
├── rfp/
│   ├── rfp_request.md          # 견적 요청
│   └── rfp_request.html
├── followup/
│   ├── followup_1.md           # 1차 후속
│   ├── followup_2.md           # 2차 후속 (최종)
│   └── followup_response.md    # 응답 감사
├── closing/
│   ├── thank_you.md            # 감사 메일
│   ├── rejection.md            # 탈락 통보
│   └── hold.md                 # 보류 안내
└── _base.html                  # HTML 기본 레이아웃
```

### 3.2 템플릿 변수

| 변수 | 설명 | 예시 |
|------|------|------|
| `{{vendor_name}}` | 업체명 | Sun-Fly |
| `{{contact_name}}` | 담당자명 | Susie Su (확보 시) |
| `{{category}}` | 업체 카테고리 | RFID Card+Reader |
| `{{sender_name}}` | 발신자명 | Aiden Kim |
| `{{sender_title}}` | 발신자 직함 | Technical Director |
| `{{sent_date}}` | 발송일 | 2026-02-09 |
| `{{deadline}}` | 응답 기한 | 2026-02-23 |

> **⚠️ COMMUNICATION-RULES 준수**:
> - `{{our_company}}` 변수 사용 금지 (회사명 외부 노출 금지)
> - `{{project_name}}` 변수는 내부용만, 외부 노출 금지
> - 기술 스펙(주파수, 프로토콜, IC 칩명) 언급 금지

### 3.3 RFI 템플릿 (초기 정보 요청)

```markdown
Subject: Product Inquiry - RFID Solutions

Dear {{vendor_name}} Team,

I am interested in your RFID solutions for a broadcast project.

Could you please provide the following information:

1. Product catalog for RFID cards and readers
2. Technical specifications and documentation
3. Pricing information (unit price and volume discounts)
4. Lead time and minimum order quantity
5. Sample availability

We would appreciate a response by {{deadline}}.

Best regards,
{{sender_name}}
```

> **⚠️ COMMUNICATION-RULES 준수**: 회사명, 기술 스펙(주파수, 프로토콜, IC), 시스템 구조 노출 금지. 상세: `docs/05_Operations_ngd/COMMUNICATION-RULES_ngd.md`

### 3.4 Follow-up 템플릿

**1차 Follow-up (7일 후):**

```markdown
Subject: Re: Product Inquiry - RFID Solutions

Dear {{vendor_name}} Team,

I am following up on my previous email sent on {{sent_date}} regarding RFID solutions for our broadcasting project.

We are actively evaluating vendors and would appreciate any information you can provide about your products.

If this inquiry should be directed to a different department or contact, please let me know.

Best regards,
{{sender_name}}
```

**2차 Follow-up (14일 후, 최종):**

```markdown
Subject: Final Follow-up: RFID Solution Inquiry

Dear {{vendor_name}} Team,

This is my final follow-up regarding our RFID solution inquiry.

If we do not hear back by {{deadline}}, we will assume you are unable to assist with our project at this time.

We remain interested in your products for future projects and welcome any response.

Best regards,
{{sender_name}}
```

> **⚠️ COMMUNICATION-RULES 수정**: Subject에서 `{{our_company}}` 제거 (회사명 노출 금지)

---

## 4. Follow-up 자동화 로직

### 4.1 타임라인

```
Day 0: RFI 전송
        │
Day 1-7: 응답 대기
        │
        ├─ 응답 수신 → RESPONDED 상태로 전환
        │
Day 7: 무응답 시 → FOLLOWUP_1 자동 전송
        │
Day 8-14: 응답 대기
        │
        ├─ 응답 수신 → RESPONDED 상태로 전환
        │
Day 14: 무응답 시 → FOLLOWUP_2 자동 전송
        │
Day 15-21: 응답 대기
        │
        ├─ 응답 수신 → RESPONDED 상태로 전환
        │
Day 21: 무응답 시 → CLOSED 상태로 전환
```

### 4.2 응답 감지 로직

```python
# Gmail 검색 쿼리
def check_response(vendor_email: str, sent_date: datetime) -> bool:
    query = f"from:{vendor_email} after:{sent_date.strftime('%Y/%m/%d')}"
    emails = gmail_client.list_emails(query=query, max_results=5)
    return len(emails) > 0
```

### 4.3 Morning Automation 연동

기존 `morning-automation` 시스템에 Follow-up 체크 추가:

```python
# collectors/followup_checker.py

class FollowupChecker:
    def check_pending_followups(self) -> list[dict]:
        """
        매일 아침 실행하여 Follow-up 필요한 업체 확인
        """
        vendors = self.get_vendors_with_status(['RFI_SENT', 'FOLLOWUP_1'])

        followups_needed = []
        for vendor in vendors:
            days_since_contact = (datetime.now() - vendor.last_contact_date).days

            if vendor.status == 'RFI_SENT' and days_since_contact >= 7:
                followups_needed.append({
                    'vendor': vendor,
                    'action': 'FOLLOWUP_1',
                    'template': 'followup/followup_1.md'
                })
            elif vendor.status == 'FOLLOWUP_1' and days_since_contact >= 7:
                followups_needed.append({
                    'vendor': vendor,
                    'action': 'FOLLOWUP_2',
                    'template': 'followup/followup_2.md'
                })

        return followups_needed
```

---

## 5. Slack List 연동

### 5.1 컬럼 매핑

현재 Slack List 컬럼을 상태 추적에 활용:

| 컬럼 | 용도 | 값 예시 |
|------|------|---------|
| 업체명 | 업체 식별 | Sun-Fly |
| 카테고리 | 분류 | 카테고리 A (통합 파트너) |
| 설명 | 업체 정보 | RFID 대량 생산, 협력 개발 |
| 연락처 | 이메일 | susie.su@sun-fly.com |
| **상태** | **컨택 상태** | RFI_SENT, FOLLOWUP_1 등 |

### 5.2 상태 업데이트 API

```python
def update_vendor_status(vendor_id: str, new_status: str) -> bool:
    """
    Slack List 업체 상태 업데이트
    """
    return lists_collector.update_item_text(
        item_id=vendor_id,
        name=vendor.name,
        url=vendor.url,
        info=f"{vendor.description} | {new_status}"
    )
```

---

## 6. Gmail 라벨 구조

### 6.1 라벨 계층

```
EBS/
├── Vendor/
│   ├── RFI-Sent/        # 정보요청 발송
│   ├── RFP-Sent/        # 견적요청 발송
│   ├── Responded/       # 응답 수신
│   ├── Follow-up/       # 후속 연락
│   └── Closed/          # 컨택 종료
├── Status/
│   ├── ⏳-Awaiting-Reply/   # 응답 대기
│   └── ✅-Replied/          # 응답 완료
└── Priority/
    ├── ⭐-High/         # 우선순위 높음
    └── 📌-Watch/        # 주시 대상
```

### 6.2 라벨 자동 적용

```python
def apply_vendor_labels(email_id: str, vendor: Vendor, action: str):
    """
    이메일 전송/수신 시 라벨 자동 적용
    """
    labels_to_add = []

    if action == 'RFI_SENT':
        labels_to_add = ['EBS/Vendor/RFI-Sent', 'EBS/Status/⏳-Awaiting-Reply']
    elif action == 'RESPONSE_RECEIVED':
        labels_to_add = ['EBS/Vendor/Responded', 'EBS/Status/✅-Replied']

    gmail_client.modify_labels(email_id, add_labels=labels_to_add)
```

---

## 7. 구현 계획

### 7.1 Phase 1: 템플릿 시스템 (Day 1-2)

- [ ] 템플릿 디렉토리 구조 생성
- [ ] RFI, Follow-up 템플릿 작성
- [ ] Jinja2 렌더링 엔진 구현
- [ ] 미리보기 기능

### 7.2 Phase 2: 이메일 발송 (Day 3-4)

- [ ] `contact_manager.py` 구현
- [ ] Gmail 전송 연동
- [ ] Slack List 상태 업데이트 연동
- [ ] Gmail 라벨 자동 적용

### 7.3 Phase 3: Follow-up 자동화 (Day 5-6)

- [ ] `followup_checker.py` 구현
- [ ] Morning Automation 연동
- [ ] 응답 감지 로직
- [ ] 상태 자동 전이

### 7.4 Phase 4: 대시보드 (Day 7)

- [ ] 컨택 현황 리포트
- [ ] Slack 알림 연동
- [ ] 일일 브리핑 포함

---

## 8. 성공 지표

| 지표 | 목표 |
|------|------|
| 초기 응답률 | 50% 이상 |
| Follow-up 후 응답률 | 30% 추가 |
| 견적 수신률 | 응답 업체 중 80% |
| 컨택 완료까지 평균 기간 | 14일 이내 |

---

## 9. 리스크 및 대응

| 리스크 | 영향 | 대응 방안 |
|--------|------|----------|
| 스팸 필터 | 이메일 미도달 | 개별 발송, SPF/DKIM 확인 |
| 언어 장벽 | 소통 어려움 | 영문 템플릿 기본 |
| 무응답 다수 | 후보 부족 | 추가 업체 발굴 |
| 견적 지연 | 일정 차질 | 조기 컨택 시작 |

---

## 10. 부록

### 10.1 RFI 대상 업체 (4개)

**카테고리 A: 통합 파트너 후보 (RFID 카드+리더)**

| 업체 | 이메일 | 국가 | 우선순위 |
|------|--------|------|:--------:|
| Sun-Fly | susie.su@sun-fly.com | 중국 | ⭐ |
| Angel Playing Cards | overseas@angel-group.co.jp | 일본 | ⭐ |

**카테고리 B: 부품/모듈 공급 (개별 구매)**

| 업체 | 이메일 | 국가 | 우선순위 |
|------|--------|------|:--------:|
| GAO RFID | sales@gaorfid.com | 미국/캐나다 | - |
| Faded Spade | sales@fadedspade.com | 미국 | - |

### 10.2 벤치마크/참조 업체 (이메일 불필요)

**카테고리 C: 장비 표준 참조**

| 업체 | 국가 | 역할 |
|------|------|------|
| Abbiati Casino | 이탈리아 | 카지노 장비 표준 참조 |
| S.I.T. Korea | 한국 | 카지노 장비 참조 |

> **참고**: PokerGFX는 업체 관리 대상이 아닌 SW 벤치마크/복제 대상입니다.

---

## 11. 실시간 이메일 알림 시스템

### 11.1 아키텍처 옵션 비교

| 방식 | 지연 시간 | 복잡도 | 인프라 | 추천 |
|------|:--------:|:------:|:------:|:----:|
| **Option A: Gmail Push (Pub/Sub)** | ~1초 | 높음 | GCP 필요 | ⭐ |
| **Option B: Polling** | 1~5분 | 낮음 | 로컬만 | 초기 |
| **Option C: IMAP IDLE** | ~5초 | 중간 | 상시 연결 | - |

### 11.2 Option A: Gmail Pub/Sub Push (권장)

```
┌─────────────────────────────────────────────────────────────────┐
│                   Gmail Push Notification 아키텍처               │
└─────────────────────────────────────────────────────────────────┘

                    ┌──────────────┐
                    │    Gmail     │
                    │   Inbox      │
                    └──────┬───────┘
                           │ 새 메일 도착
                           ▼
                    ┌──────────────┐
                    │  Gmail API   │
                    │   Watch      │
                    └──────┬───────┘
                           │ Push 이벤트
                           ▼
                    ┌──────────────┐
                    │  GCP Pub/Sub │
                    │    Topic     │
                    └──────┬───────┘
                           │ HTTP Push
                           ▼
            ┌──────────────────────────────┐
            │      Webhook Handler          │
            │  (Tailscale Funnel / ngrok)   │
            └──────────────┬───────────────┘
                           │
         ┌─────────────────┼─────────────────┐
         ▼                 ▼                 ▼
  ┌────────────┐   ┌────────────┐   ┌────────────┐
  │   Slack    │   │ Slack List │   │  Morning   │
  │  알림 전송  │   │ 상태 업데이트│   │ Automation │
  └────────────┘   └────────────┘   └────────────┘
```

**필요 구성요소:**

| 구성요소 | 용도 | 상태 |
|----------|------|------|
| GCP Project | Pub/Sub 호스팅 | 이미 있음 (OAuth용) |
| Pub/Sub Topic | 메시지 라우팅 | 생성 필요 |
| Webhook Server | Push 수신 | 구현 필요 |
| Tailscale Funnel | Public HTTPS | 설정 필요 |

**설정 명령어:**

```bash
# 1. API 활성화
gcloud services enable gmail.googleapis.com pubsub.googleapis.com

# 2. Topic 생성
gcloud pubsub topics create ebs-gmail-watch

# 3. Gmail 권한 부여
gcloud pubsub topics add-iam-policy-binding ebs-gmail-watch \
  --member=serviceAccount:gmail-api-push@system.gserviceaccount.com \
  --role=roles/pubsub.publisher

# 4. Watch 시작 (Python)
from lib.gmail import GmailClient
client = GmailClient()
client.service.users().watch(
    userId='me',
    body={
        'topicName': 'projects/<project-id>/topics/ebs-gmail-watch',
        'labelIds': ['INBOX']
    }
).execute()
```

### 11.3 Option B: Polling (간단한 대안)

```python
# tools/morning-automation/services/email_poller.py

import schedule
import time
from datetime import datetime
from lib.gmail import GmailClient

class EmailPoller:
    def __init__(self, check_interval_minutes: int = 5):
        self.client = GmailClient()
        self.last_check = datetime.now()
        self.check_interval = check_interval_minutes
        self.vendor_emails = self._load_vendor_emails()

    def check_new_emails(self):
        """주기적으로 새 이메일 확인"""
        query = f"is:unread after:{self.last_check.strftime('%Y/%m/%d')}"

        for vendor_email in self.vendor_emails:
            emails = self.client.list_emails(
                query=f"from:{vendor_email} {query}",
                max_results=10
            )

            for email in emails:
                self._handle_vendor_response(email)

        self.last_check = datetime.now()

    def _handle_vendor_response(self, email):
        """업체 응답 처리"""
        # 1. Slack 알림
        self._notify_slack(email)

        # 2. Slack List 상태 업데이트
        self._update_vendor_status(email.sender, 'RESPONDED')

        # 3. Gmail 라벨 적용
        self.client.modify_labels(
            email.id,
            add_labels=['EBS/Vendor/Responded']
        )

    def run(self):
        """Polling 시작"""
        schedule.every(self.check_interval).minutes.do(self.check_new_emails)
        while True:
            schedule.run_pending()
            time.sleep(60)
```

### 11.4 Option C: IMAP IDLE (실시간, 간단)

```python
# IMAP IDLE 프로토콜로 실시간 이메일 감지
# 연결 유지 필요 (29분마다 재연결)

import imaplib
from lib.gmail import get_credentials

class IMAPWatcher:
    def __init__(self):
        self.imap = imaplib.IMAP4_SSL('imap.gmail.com')
        self._login_oauth()

    def watch(self, callback):
        self.imap.select('INBOX')
        while True:
            self.imap.send(b'IDLE\r\n')
            response = self.imap.readline()
            if b'EXISTS' in response:
                self.imap.send(b'DONE\r\n')
                callback()
```

### 11.5 권장 구현 전략

| Phase | 방식 | 시기 | 이유 |
|:-----:|------|------|------|
| **1** | Polling (5분) | 즉시 | 빠른 구현, 검증 |
| **2** | Gmail Pub/Sub | 필요 시 | 실시간 필요할 때 |

### 11.6 Slack 알림 형식

```
🔔 *EBS 업체 응답 도착*

*From:* Sun-Fly <susie.su@sun-fly.com>
*Subject:* Re: Product Inquiry - RFID Solutions
*Time:* 2026-02-09 14:32 KST

> Thank you for your inquiry. Please find attached...

*Actions:*
• <view_email|Gmail에서 보기>
• <update_status|상태 업데이트>
```

### 11.7 구현 체크리스트

**Phase 1 (Polling):**
- [ ] `email_poller.py` 구현
- [ ] 업체 이메일 목록 연동
- [ ] Slack 알림 전송
- [ ] Slack List 상태 자동 업데이트
- [ ] Windows Task Scheduler 등록

**Phase 2 (Push - 선택):**
- [ ] GCP Pub/Sub Topic 생성
- [ ] Gmail Watch 설정
- [ ] Webhook Handler 구현
- [ ] Tailscale Funnel 설정

---

## 변경 이력

| 날짜 | 버전 | 변경 내용 |
|------|------|----------|
| 2026-02-03 | 1.0.0 | 초기 작성 - 상태 머신, 이메일 템플릿, Follow-up 자동화 설계 |
| 2026-02-04 | 1.0.1 | 문서 헤더 형식 통일 |
| 2026-02-09 | 2.0.0 | COMMUNICATION-RULES 준수: RFI 템플릿 보안 수정(사명/기술스펙 제거), Phase-Pre→Phase 0 용어 통일, 미확보 업체 상태 갱신 |
| 2026-02-09 | 3.0.0 | 현행 6개 업체 기준 전면 재작성: 제거 업체 정리, 예시 업데이트(Sun-Fly 중심), 부록 현행화, AI 티 제거 규칙 적용 |

---

**Version**: 3.0.0 | **Updated**: 2026-02-09 | **BRACELET STUDIO**
