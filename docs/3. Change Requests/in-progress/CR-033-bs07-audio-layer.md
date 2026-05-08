---
title: CR-033-bs07-audio-layer
owner: conductor
tier: internal
legacy-id: CCR-033
last-updated: 2026-04-15
confluence-page-id: 3819275484
confluence-parent-id: 3818521542
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3819275484/EBS+CR-033-bs07-audio-layer
---

# CCR-033: BS-07 Overlay 오디오 레이어 추가 (WSOP 1 BGM + 2 Effect 채널)

| 필드 | 값 |
|------|-----|
| **상태** | APPLIED (2026-04-10) |
| **제안팀** | team4 |
| **제안일** | 2026-04-10 |
| **처리일** | 2026-04-10 |
| **영향팀** | team3 |
| **변경 대상** | `contracts/specs/BS-07-overlay/BS-07-05-audio.md`<br/>`contracts/specs/BS-07-overlay/BS-07-02-animations.md` |
| **변경 유형** | add |

## 변경 근거

현재 BS-07 Overlay는 시각 요소(8종)와 Rive 애니메이션만 정의하며 **오디오 레이어가 전무**하다. WSOP LIVE Fatima.app의 Audio Player Provider는 **1 BGM Channel + 2 Effect Channels + 임시 Channel 동적 생성** 패턴으로 프로덕션 운영 중이며(출처: `wsoplive/.../Mobile-Dev/Refactoring/Audio Player Provider (2023.md`), 이 자산을 EBS에 재사용하면 방송 사운드(카드 딜 효과음, 승자 등장, 올인 경고, Run It 전환 BGM 등) 구현 비용이 크게 감소한다. 또한 Rive 애니메이션 내부의 사운드 트리거와 Flutter AudioPlayer의 통합 경계가 필요하다.

## 적용된 파일

- `contracts/specs/BS-07-overlay/BS-07-05-audio.md`
- `contracts/specs/BS-07-overlay/BS-07-02-animations.md`

## 원본 Draft

`docs/05-plans/ccr-inbox/archived/CCR-DRAFT-team4-20260410-bs07-audio-layer.md` 참조

## 체크리스트

- [x] contracts/ 편집 완료
- [ ] 영향팀(team3) 개별 확인
- [ ] 통합 테스트 업데이트 (`integration-tests/`)
- [ ] git commit `[CCR-033] BS-07 Overlay 오디오 레이어 추가 (WSOP 1 BGM + 2 Effect 채널)`
