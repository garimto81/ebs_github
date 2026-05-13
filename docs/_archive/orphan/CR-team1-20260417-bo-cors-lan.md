---
title: "CR: Team2 BO CORS 기본값을 LAN 허용으로 변경"
author: team1
risk: LOW
affected_teams: [team2]
created: 2026-04-17
---

# CR: BO CORS 정책 LAN 지원

## 배경
Team2 BO의 CORS 기본값이 `["http://localhost:3000"]`로 제한되어 있어 Flutter Web 또는 브라우저 기반 접근 시 LAN에서 차단됨.

## 현재 상태
파일: `team2-backend/src/app/config.py`
```python
cors_origins: list[str] = ["http://localhost:3000"]
```

## 요청 변경
```python
cors_origins: list[str] = Field(
    default=["*"],  # dev 환경 기본값
    description="CORS allowed origins. Set explicitly for prod."
)
```

## 영향
- Flutter Desktop: CORS 무관 (브라우저 아님)
- Flutter Web: CORS 필수
- 보안: prod 환경에서는 `.env`로 명시적 Origin 설정 필수

## 리스크
LOW — 추가 전용, dev 환경 편의성 개선
