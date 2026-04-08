# Design: PokerGFX Feature Registry 갭 메우기

> **Plan Reference**: `docs/01-plan/pokergfx-gap-fill.plan.md`

---

## 1. 아키텍처 개요

기존 5-Layer 프레임워크의 L5 (Cross-Reference Registry) 데이터 채움 작업.

```
┌───────────────────────────────────────────────────────────┐
│  L5: CROSS-REFERENCE REGISTRY                              │
│  feature-registry.json (149 ID × 5 소스) ← 이번 작업       │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  sources: binary(V) + screenshot(O) + inference(I)  │   │
│  │  ebs_mapping: protocol_message 연결                  │   │
│  └─────────────────────────────────────────────────────┘   │
├───────────────────────────────────────────────────────────┤
│  L3: PROTOCOL SPEC ← Feature ID 역매핑 추가                │
│  actiontracker-messages.md (68개 메시지)                    │
├───────────────────────────────────────────────────────────┤
│  L1~L4: 기존 완성 (변경 없음)                               │
└───────────────────────────────────────────────────────────┘
```

## 2. 중간 산출물 스키마

### 2.1 매핑 JSON 형식 (T1/T2/T3 출력)

각 병렬 Task가 생성하는 중간 파일의 스키마:

```json
{
  "$intermediate": "feature-mapping-v1",
  "task": "T1",
  "categories": ["AT"],
  "mappings": {
    "AT-001": {
      "sources": {
        "binary": {
          "files": ["ClientNetworkService.cs:ConnectToServer", "ClientNetworkService.cs:IsConnected"],
          "confidence": "V"
        },
        "screenshot": {
          "ref": "01-main-window.png#status-bar",
          "confidence": "O"
        },
        "manual": null,
        "live_app": null,
        "inference": null
      },
      "ebs_mapping": {
        "protocol_message": "ConnectToServer",
        "widget": null,
        "db_table": null
      }
    }
  }
}
```

### 2.2 null → 구조화 객체 변환 규칙

| 현재 값 | 매핑 있음 | 매핑 없음 |
|---------|----------|----------|
| `null` | `{"files": [...], "confidence": "V"}` (binary) | `null` 유지 |
| `null` | `{"ref": "...", "confidence": "O"}` (screenshot) | `null` 유지 |
| `null` | `{"basis": "...", "confidence": "I"}` (inference) | `null` 유지 |

### 2.3 파일 경로

| Task | 출력 경로 |
|:----:|----------|
| T1 | `docs/01_PokerGFX_Analysis/06_Cross_Reference/mappings/at-mappings.json` |
| T2 | `docs/01_PokerGFX_Analysis/06_Cross_Reference/mappings/vo-gc-ps-mappings.json` |
| T3 | `docs/01_PokerGFX_Analysis/06_Cross_Reference/mappings/remaining-mappings.json` |

## 3. 소스 매핑 전략 (카테고리별)

### 3.1 AT-001~026 (T1, executor-high)

**주요 소스**: `07_Decompiled_Archive/ActionTracker/`

| 파일 | LOC | 매핑 대상 |
|------|:---:|----------|
| `vpt_remote/core.cs` | 25,643 | AT-005~011 (게임 상태), AT-019 (보드) |
| `vpt_remote.Services/ClientNetworkService.cs` | ~6,400 | AT-001 (연결), AT-012~013 (액션), AT-020~026 |
| `vpt_remote.Services.Helper/CoreNetworkListener.cs` | - | AT-002 (테이블 연결) |
| `vpt_remote/comm.cs` | - | AT-014~018 (베팅 입력, 키보드) |

**Confidence 목표**: V 20개 이상, O 6개 (스크린샷)

### 3.2 VO-001~014, GC-001~025, PS-001~013 (T2, executor)

**주요 소스**: 스크린샷 11개 + `07_Decompiled_Archive/Server/`

| 카테고리 | 스크린샷 | Confidence |
|---------|----------|:----------:|
| VO (14) | 01-main, 04-gfx1, 05-gfx2 | O (14개) |
| GC (25) | 04-gfx1~08-system | O (20개), I (5개) |
| PS (13) | 01-main, 09-skin | O (8개), I (5개) |

### 3.3 SEC/SV/EQ/ST/HH (T3, executor)

**주요 소스**: Server.exe 디컴파일 (ConfuserEx 난독화) + inference

| 카테고리 | 전략 | Confidence 분포 |
|---------|------|:--------------:|
| SEC (11) | Server/ 보안 관련 파일 검색 | V:3, I:8 |
| SV (30) | 스크린샷 + Server/ | O:20, I:10 |
| EQ (19) | Server/ equity 모듈 + inference | V:2, I:17 |
| HH (11) | Server/ history + inference | V:1, I:10 |

## 4. Feature ID 역매핑 형식 (T4)

각 메시지 스키마 끝에 추가:

```markdown
### 1.1 ConnectToServer
...
**관련 Feature ID**: AT-001

---
```

### 양방향 Coverage Matrix (Architect 조건 #2)

T4 완료 후 `actiontracker-messages.md` 말미에 추가:

```markdown
## 12. Feature-Message Coverage Matrix

### Feature → Message
| Feature ID | 관련 메시지 |
|-----------|-----------|
| AT-001 | ConnectToServer, SendAuth, SendHeartBeat |
| AT-002 | SendReaderStatus, OnReaderStatusReceived |
| ... | ... |

### Unmapped Features (메시지 없음)
| Feature ID | 사유 |
|-----------|------|
| AT-003 | OBS 연동은 Server 내부 처리, AT 프로토콜 메시지 없음 |
```

## 5. Design 문서 수정 (GAP 3 해소)

gametype-variants.md를 별도 파일로 분리하지 않고, game-state-machine.md Section 5 통합을 공식화.

**수정 내용**: Design 문서 L4 행에서 `gametype-variants.md` 제거, `game-state-machine.md (Section 5: Variant Matrix 포함)` 으로 변경.

## 6. 검증 기준

| 기준 | 목표 | 측정 방법 |
|------|:----:|----------|
| non-null source Feature 수 | 134+ / 149 | Python 스크립트 |
| V등급 매핑 수 | 30+ | JSON 파싱 |
| O등급 매핑 수 | 40+ | JSON 파싱 |
| 메시지 Feature ID 수 | 68/68 | grep 카운트 |
| JSON 유효성 | PASS | python -m json.tool |
| gap-detector Match Rate | 90%+ | bkit:gap-detector 재실행 |

---

**Version**: 1.0.0 | **Updated**: 2026-02-13
