# ADR-003: Skin Editor v2.0 Defer

## 상태
확정

## 맥락

PokerGFX의 Skin Editor와 Graphic Editor는 방송 그래픽 테마를 사전에 편집하는 도구다. Skin Editor는 색상, 폰트, 카드 이미지, 레이아웃 등 전체 테마를 편집하고(37개 요소, SK-01~SK-26), Graphic Editor는 Skin Editor에서 특정 요소를 클릭했을 때 픽셀 단위 편집 창으로 진입한다(87개 요소 → EBS 18개로 통합 감축).

Skin/Graphic Editor는 본방송 중에는 사용하지 않는 사전 준비 작업 도구다. 운영자의 하루 흐름에서 방송 전날 스킨을 편집하고 Export한 뒤, 본방송 중에는 AT 조작(85%)과 GFX 모니터링에 집중하며 Skin Editor에 접근하지 않는다.

EBS v1.0 설계에서 Skin Editor를 포함할지를 결정해야 했다. GFX 1 탭의 Skin 그룹에 있는 G-14s(Skin Editor 버튼)와 G-15s(Media Folder 버튼)가 진입점이다. 포함 여부에 따라 SK-01~SK-26 전체(26개)와 GFX Graphic Editor 관련 요소들의 구현 범위가 결정된다.

## 결정

Skin Editor(SV-027)와 Graphic Editor(SV-028)를 v2.0 Defer로 결정한다. v1.0은 기본 스킨 1종으로 방송을 운영한다. G-14s(Skin Editor 버튼)는 v1.0 UI에서 비활성(회색) 상태로 표시하여 v2.0에서 활성화할 기능임을 운영자에게 시각적으로 안내한다.

## 근거

| 근거 | 내용 |
|------|------|
| 방송 필수성 부재 | 기본 스킨 1종으로 방송 운영이 가능하다. 스킨 커스터마이징은 방송 품질에 기여하지만 필수 조건이 아님 |
| 구현 복잡도 | Skin Editor는 독립된 GUI 창(SK-01~SK-26), Graphic Editor 연계, 스킨 파일 Export/Import 파이프라인을 포함한다. 87개 원본 요소를 18개로 통합하더라도 상당한 구현 비용 |
| v1.0 범위 기준 | v1.0 우선순위는 RFID 실시간 추적, AT 연동, GFX 오버레이 방송이다. Skin Editor는 이 세 목표에 직접 기여하지 않음 |
| 비활성 노출 전략 | 완전히 숨기지 않고 회색 버튼으로 노출하여 운영자가 v2.0 기능 계획을 인지하게 한다 |

## 영향

- **Defer (v2.0)**: SK-01~SK-26 전체 (26개 Skin Editor 요소)
- **Defer (v2.0)**: GFX Graphic Editor 18개 요소 (87개 원본 → 18개 통합)
- **비활성 표시**: G-14s(Skin Editor 버튼) v1.0에서 회색(disabled) 노출
- **Defer**: G-15s(Media Folder 버튼) v1.0 비활성
- **v1.0 운영**: 기본 스킨 1종 번들 제공. 스킨 선택 드롭다운은 단일 항목으로 고정
- **감축 기여**: Graphic Editor 87→18 통합은 289→180 감축에서 -69 기여 (최대 단일 감축 요인)

## 관련 요소

- SV-027 (Skin Editor) — v2.0 Defer
- SV-028 (Graphic Editor) — v2.0 Defer
- SK-01~SK-26 (Skin Editor 요소 전체) — v2.0 Defer
- G-13s (Skin Info Label) — v1.0 Keep (현재 스킨명 표시)
- G-14s (Skin Editor 버튼) — v1.0 비활성(회색) 노출
- G-15s (Media Folder 버튼) — v1.0 Defer
- GE-01~GE-18 (Graphic Editor 통합 요소) — v2.0 Defer
