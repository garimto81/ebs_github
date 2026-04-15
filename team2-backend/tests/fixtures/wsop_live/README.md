# WSOP LIVE API Response Fixtures

**Gap-Final-4 (2026-04-15)**: WSOP LIVE API 실 응답 기대 스키마 fixture.

## 목적

WSOP LIVE 실 API 통합 전까지 **기대 응답 shape** 을 고정해 mock 데이터 흐름과 adapter 회귀 방지에 사용. 실 통합 시점에 실제 sample 로 교체 가능.

## Fixture 목록

| 파일 | 출처 Confluence Page | EBS 연계 |
|------|---------------------|----------|
| `series_list.json` | `1599537917` Tournament | `GET /Series` 응답 — `Series.competition_type`, `competition_tag`, `currency` 등 |
| `events_list.json` | `1599537917` Tournament | `GET /Series/{id}/Events` — `game_type` (9종 enum), `bet_structure` |
| `seat_player_info.json` | `1912668498` Player App Table Tab / `1653833763` Staff Tables API | SeatPlayerInfo — `PlayerMoveStatus` 0/1/2 포함 |
| `blind_structure.json` | `1603666061` | BlindStructureDetail — `BlindDetailType` 0~4 모두 포함 |

## 규칙

1. **PascalCase 필드명**: WSOP LIVE 원문 그대로 (adapter 가 snake_case 변환 담당).
2. **Enum 원시값**: 정수값 사용. EBS adapter 가 문자열 변환 (예: `map_to_ebs`).
3. **버전 추적**: 각 JSON 파일 최상단 `_metadata` 에 원본 Page ID + 수집일.

## 사용 예

```python
import json
from pathlib import Path

def load_fixture(name: str) -> dict:
    path = Path(__file__).parent / "fixtures" / "wsop_live" / name
    return json.loads(path.read_text(encoding="utf-8"))

events = load_fixture("events_list.json")["events"]
```

## 확장

실 API 연동 후 실제 응답 샘플 수집 시:
1. 본 디렉토리에 `v1_actual/` 서브디렉토리 추가
2. 기대 스키마 vs 실제 응답 diff 기록
3. Adapter 수정 필요 시 `tests/test_wsop_sync_fixtures.py` 회귀로 포착
