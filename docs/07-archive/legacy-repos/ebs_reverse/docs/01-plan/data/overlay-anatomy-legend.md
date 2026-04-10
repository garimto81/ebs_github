# Overlay Anatomy Legend

WSOP Paradise 2025 오버레이 해부도 — 요소 번호 범례

이미지: `docs/01-plan/images/prd/overlay-anatomy.png`
좌표 JSON: `docs/01-plan/data/overlay-anatomy-coords.json`

---

| # | 요소명 | GFX Type | Protocol CMD | 좌표 (x, y, w, h) |
|---|--------|----------|--------------|-------------------|
| 1 | Player Info Panel | Text + Image | SHOW_PANEL | 0, 0, 196, 291 |
| 2 | 홀카드 표시 | Image (pip) | DELAYED_FIELD_VISIBILITY | 68, 36, 92, 38 |
| 3 | Action Badge | Text + Border | FIELD_VISIBILITY | 66, 168, 86, 24 |
| 4 | 승률 바 | Border + Text | FIELD_VISIBILITY | 66, 82, 108, 10 |
| 5 | 커뮤니티 카드 | Image (pip) | SHOW_PIP | 218, 262, 168, 46 |
| 6 | Top Bar | Text + Image | SHOW_STRIP | 179, 0, 365, 46 |
| 7 | 이벤트 배지 | Text + Image | FIELD_VISIBILITY | 523, 24, 108, 62 |
| 8 | Bottom Info Strip | Text + Border | SHOW_STRIP | 0, 311, 640, 49 |
| 9 | 팟 카운터 | Text | FIELD_VISIBILITY | 238, 314, 138, 28 |
| 10 | FIELD / 스테이지 | Text | FIELD_VISIBILITY | 393, 318, 158, 30 |
| 11 | 스폰서 로고 | Image | GFX_ENABLE | 224, 340, 192, 20 |

---

## 좌표 기준

- 이미지 크기: 640 × 360 px
- 원점: 좌상단 (0, 0)
- 좌표 보정: OpenCV gradient/color 자동 검출 + Vision 시각 검증 (2026-02-23)
- 고신뢰 갱신 요소: player_panel, top_bar, bottom_strip, sponsor_logo

## 재생성 명령

```bash
# 배지 + 범례 없음 (기본)
python scripts/annotate_anatomy.py

# 배지 + 범례 포함
python scripts/annotate_anatomy.py --legend
```
