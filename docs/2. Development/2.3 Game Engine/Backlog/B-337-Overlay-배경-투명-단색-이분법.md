---
id: B-337
title: "Overlay §5 크로마키 — Foundation §7.1 '투명(방송) vs 단색(디자이너 QA)' 이분법 정렬"
status: PENDING
priority: P2
created: 2026-04-22
source: docs/2. Development/2.3 Game Engine/Backlog.md
related-foundation: "docs/1. Product/Foundation.md §7.1 (배경 투명/단색 config flag)"
---

# [B-337] Overlay 배경 모드 이분법 정렬 (P2)

## 배경

Foundation §7.1 이 배경 config flag 를 명시:

> Overlay 앱은 런타임 설정으로 배경을 (a) **완전 투명** (스위처 합성용 **기본값**) 또는 (b) **단색 배경** 중 선택. 단색 모드는 **아트 디자이너가 외부 Rive Editor 에서 디자인 확인 / QA 스크린샷 촬영** 용도이며, 방송 송출 시에는 반드시 (a) 완전 투명 을 사용합니다.

즉 **2 모드 (투명 방송용 기본 / 단색 QA용)** 이분법. 그러나 `Overlay_Output_Events.md §5.2` 는 4 모드 (OFF / Green / Blue / NDI 알파) 로 서술되어 Foundation 의 이분법과 concept 레벨에서 어긋난다.

## 수정 대상

### `APIs/Overlay_Output_Events.md` §5

현 §5.2 표를 Foundation §7.1 이분법 + 구현 세부 2 레이어로 재구성:

1. **개념 레이어 (Foundation §7.1 준수)**:
   - 완전 투명 = 방송 송출 기본 (SDI/NDI 합성용)
   - 단색 배경 = 디자이너 QA / 스크린샷 촬영

2. **구현 레이어 (기존 §5.2 유지)**:
   - Green/Blue 크로마키는 단색 모드의 **2 프리셋**
   - NDI 알파는 투명 모드의 **전송 방식**

§5.1 "목적" 문구를 "방송 = 투명 기본 / QA = 단색" 프레임으로 재작성.

### 수락 기준

- [ ] §5.1 에 "완전 투명 = 방송 기본" / "단색 = QA" 이분법 명시
- [ ] 4 모드 구현 세부는 유지하되 이분법 하위 범주로 재구조화
- [ ] Foundation §7.1 참조 링크
- [ ] team4 Overlay config 와 정합 (team4 notify 커밋)

## 관련

- Foundation §7.1
- team4 소비: `docs/2. Development/2.4 Command Center/Overlay/`
