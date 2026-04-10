# Design: PokerGFX 완전 분석 프레임워크

> **Plan Reference**: `docs/01-plan/pokergfx-analysis-framework.plan.md`

---

## 1. 5-Layer 아키텍처

```
┌───────────────────────────────────────────────────────────────┐
│  L5: CROSS-REFERENCE REGISTRY                                 │
│  feature-registry.json (149 ID x 5 소스)                      │
├───────────────────────────────────────────────────────────────┤
│  L4: BEHAVIORAL SPEC                                          │
│  game-state-machine.md, gametype-variants.md                  │
├───────────────────────────────────────────────────────────────┤
│  L3: PROTOCOL SPEC                                            │
│  actiontracker-messages.md (50+ 메시지 페이로드)               │
├───────────────────────────────────────────────────────────────┤
│  L2: CODE ARCHITECTURE (기존 완성)                             │
│  Binary Analysis, Beginner Guide                              │
├───────────────────────────────────────────────────────────────┤
│  L1: SURFACE ANALYSIS (기존 완성)                              │
│  UI Analysis (11화면), Feature Checklist (149개)               │
└───────────────────────────────────────────────────────────────┘
```

## 2. 디렉토리 구조

```
docs/01_PokerGFX_Analysis/
├── [기존] PokerGFX-UI-Analysis.md              # L1
├── [기존] PokerGFX-Feature-Checklist.md        # L1
├── [기존] PokerGFX-Server-Binary-Analysis.md   # L2
├── [기존] PokerGFX-Analysis-BeginnerGuide.md   # L2
├── [기존] 01_Mockups_ngd/                      # L1 시각 자료
├── [기존] 02_Annotated_ngd/                    # L1 주석 오버레이
├── [기존] 03_Reference_ngd/                    # 원본 PDF/이미지
│
├── [신규] 04_Protocol_Spec/                    # L3
│   └── actiontracker-messages.md
│
├── [신규] 05_Behavioral_Spec/                  # L4
│   └── game-state-machine.md
│
├── [신규] 06_Cross_Reference/                  # L5
│   ├── feature-registry.json
│   └── confidence-audit.md
│
└── [신규] 07_Decompiled_Archive/               # 소스 아카이브
    ├── README.md
    ├── Server/                                 # Server.exe 디컴파일
    ├── Common/                                 # Common.dll 디컴파일
    ├── ActionTracker/                          # ActionTracker.exe 디컴파일
    └── GFXUpdater/                             # GFXUpdater.exe 디컴파일
```

## 3. Feature Registry 스키마 (L5)

```json
{
  "$schema": "feature-registry-v1",
  "version": "1.0.0",
  "features": {
    "<FEATURE_ID>": {
      "name": "기능명",
      "category": "Action Tracker | Pre-Start | Viewer Overlay | ...",
      "priority": "P0 | P1 | P2",
      "sources": {
        "screenshot": {
          "ref": "<파일명>#box<N>",
          "confidence": "V | O | I"
        },
        "manual": {
          "ref": "user-manual_p<NNN>.pdf#p<N>",
          "confidence": "V | O | I"
        },
        "binary": {
          "files": ["<file.cs>:<method>"],
          "confidence": "V | O | I"
        },
        "live_app": {
          "ref": "<관찰 설명>",
          "confidence": "V | O | I"
        },
        "inference": {
          "basis": "<추론 근거>",
          "confidence": "I"
        }
      },
      "ebs_mapping": {
        "widget": "<Flutter Widget 이름 또는 null>",
        "protocol_message": "<메시지 타입 또는 null>",
        "db_table": "<테이블명 또는 null>"
      }
    }
  }
}
```

**출처 신뢰도 등급**:

| 등급 | 코드 | 정의 | 필수 첨부 |
|:----:|:----:|------|----------|
| Verified | `V` | 코드에서 직접 확인 | 파일:라인 번호 |
| Observed | `O` | 스크린샷/매뉴얼 육안 확인 | 이미지 파일명 + 위치 |
| Inferred | `I` | 추론 | 추론 근거 텍스트 |

## 4. ActionTracker 메시지 스키마 (L3)

각 메시지를 아래 형식으로 문서화:

```markdown
### SendPlayerBet

| 필드 | 타입 | 설명 |
|------|------|------|
| direction | - | Client → Server |
| player | int | 좌석 번호 (0-9) |
| amount | int | 베팅 금액 |
| ... | ... | ... |

**트리거**: AT-015 (베팅 금액 입력) 또는 AT-017 (Quick Bet)
**게임 상태 영향**: action_on 이동, pot 증가
**관련 Feature ID**: AT-015, AT-016, AT-017
```

## 5. 게임 상태 머신 (L4)

### 상태 전이 다이어그램

```
                    ┌──────────┐
                    │  IDLE    │
                    └────┬─────┘
                         │ StartHand
                    ┌────▼─────┐
                    │ PRE_FLOP │◄────────┐
                    └────┬─────┘         │
                         │ Deal Board    │ NextHand
                    ┌────▼─────┐         │
                    │  FLOP    │         │
                    └────┬─────┘         │
                         │               │
                    ┌────▼─────┐         │
                    │  TURN    │         │
                    └────┬─────┘         │
                         │               │
                    ┌────▼─────┐         │
                    │  RIVER   │         │
                    └────┬─────┘         │
                         │               │
                    ┌────▼─────┐         │
                    │ SHOWDOWN │─────────┘
                    └──────────┘
```

### 추출 방법

1. `core.cs`에서 `hand_in_progress`, `action_on`, `game_class` 정적 필드 추적
2. 각 `Send*()` 메서드 호출을 상태 전이 트리거로 매핑
3. enum 정의 (`bet_structure`, `ante_type`, `nit_game_enum`)로 변형 분기 식별

## 6. 디컴파일 아카이브 설계

### ILSpy 명령

```powershell
# 설치
dotnet tool install ilspycmd -g

# 디컴파일 (각 바이너리별)
$src = "C:\Program Files\PokerGFX\Server"
$dst = "C:\claude\ebs\docs\01_PokerGFX_Analysis\07_Decompiled_Archive"

ilspycmd "$src\PokerGFX-Server.exe" -p -o "$dst\Server"
ilspycmd "$src\PokerGFX.Common.dll" -p -o "$dst\Common"
ilspycmd "$src\ActionTracker.exe" -p -o "$dst\ActionTracker"
ilspycmd "$src\GFXUpdater.exe" -p -o "$dst\GFXUpdater"
```

### .gitignore 처리

`07_Decompiled_Archive/` 전체를 `.gitignore`에 추가 (저작권 보호).
README.md만 git 추적.

## 7. 검증 기준

| 기준 | 목표 | 측정 방법 |
|------|:----:|----------|
| 디컴파일 파일 수 | 2,877개 이상 | `find . -name "*.cs" \| wc -l` |
| ActionTracker 메시지 문서화 | 50개 이상 | 메시지 스키마 수 |
| 게임 상태 전이 노드 | 6개 이상 | 다이어그램 노드 수 |
| Feature Registry 항목 | 149개 | JSON key 수 |
| 소스 커버리지 | 전 항목 1개 이상 소스 | confidence-audit 결과 |

---

**Version**: 1.0.0 | **Updated**: 2026-02-12
