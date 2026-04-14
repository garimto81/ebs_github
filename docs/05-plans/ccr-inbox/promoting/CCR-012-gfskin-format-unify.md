# CCR-012: .gfskin ZIP 포맷 단일화 및 DATA-07 신설

| 필드 | 값 |
|------|-----|
| **상태** | APPLIED (2026-04-10) |
| **제안팀** | conductor |
| **제안일** | 2026-04-10 |
| **처리일** | 2026-04-10 |
| **영향팀** | team1, team2, team4 |
| **변경 대상** | `contracts/data/DATA-07-gfskin-schema.md`<br/>`contracts/specs/BS-07-overlay/BS-07-03-skin-loading.md` |
| **변경 유형** | add + modify |

## 변경 근거

`BS-07-03-skin-loading.md §2.1`은 스킨을 "디렉토리 기반 (skin.riv + skin.skin.json + cards/ + assets/)"으로 정의하지만, `team4-cc/ui-design/UI-06-skin-editor.md:89`는 `.gfskin (ZIP)` 포맷을 가정. 두 포맷은 호환되지 않아 Overlay 런타임(디렉토리 로드)과 GE 산출물(ZIP 업로드)이 불일치. 본 CCR은 `.gfskin` = ZIP 컨테이너로 단일화하고, Overlay가 로드 시점에 압축 해제 또는 in-memory 스트리밍으로 처리하도록 정렬한다. JSON Schema를 DATA-07에 최상위 계약으로 신설한다.

## 적용된 파일

- `contracts/data/DATA-07-gfskin-schema.md`
- `contracts/specs/BS-07-overlay/BS-07-03-skin-loading.md`

## 원본 Draft

`docs/05-plans/ccr-inbox/archived/CCR-DRAFT-conductor-20260410-gfskin-format-unify.md` 참조

## 체크리스트

- [x] contracts/ 편집 완료
- [ ] 영향팀(team1, team2, team4) 개별 확인
- [x] 통합 테스트 업데이트 (`integration-tests/scenarios/20-ge-upload-download.http`)
- [ ] git commit `[CCR-012] .gfskin ZIP 포맷 단일화 및 DATA-07 신설`
