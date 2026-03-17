# EBS Google Drive 문서 구조

> **BRACELET STUDIO** | EBS (Event Broadcasting System)

## 개요

EBS Drive 폴더에는 두 핵심 문서만 유지한다. 하위 폴더 없음.

---

## 폴더 ID

| 폴더 | Google Drive ID | URL |
|------|-----------------|-----|
| **EBS/** (root) | `1GlDqSgEDs9z8j5VY6iX3QndTLb6_8-PF` | [열기](https://drive.google.com/drive/folders/1GlDqSgEDs9z8j5VY6iX3QndTLb6_8-PF) |

---

## 폴더 구조

```
EBS/                                         1GlDqSgEDs9z8j5VY6iX3QndTLb6_8-PF
├── PRD-0001: EBS 기초 기획서                [Google Doc]
└── PRD-0002: EBS UI Design                  [Google Doc]
```

---

## 문서 매핑

| 로컬 파일 | Google Docs | 위치 |
|----------|-------------|------|
| `C:/claude/ebs_reverse/docs/01-plan/pokergfx-prd-v2.md` | [PRD-0001: EBS 기초 기획서](https://docs.google.com/document/d/1PLJuD2BbT4Jp1p6smue9ezLAfbkOSTrfVxCOXTsrau4/edit) | EBS/ |
| `C:/claude/ebs/docs/00-prd/EBS-UI-Design-v3.prd.md` | [PRD-0002: EBS UI Design](https://docs.google.com/document/d/1y_g_h-5aso4aQgw_C5YcE8g9c5kFXYB-78mfFd5aDdk/edit) | EBS/ |

---

## 관리 규칙

| 규칙 | 내용 |
|------|------|
| **단일 계층** | 하위 폴더 없음, EBS root에 직접 배치 |
| **문서 수** | 항상 2개 유지 |
| **동기화 도구** | `python -m lib.google_docs convert` |
| **이름 변경 도구** | `python ebs/rename_ebs_docs.py` (Drive 표시 이름 PRD 번호 체계 적용) |
| **매핑 파일** | `docs/MAPPING_ngd.json` v9.0.0 |
| **_ngd 접미사** | 이 파일 자체는 Drive 비공유 메타 문서 |

---

## 변경 이력

| 날짜 | 버전 | 내용 |
|------|------|------|
| **2026-02-24** | **9.0.0** | **PRD 번호 통일 — 두 문서에 PRD-0001/PRD-0002 표시 이름 부여, prd_registry 도입, rename_ebs_docs.py Drive 이름 변경 스크립트 추가** |
| 2026-02-24 | 8.0.0 | EBS Drive 전면 정리 — 하위 폴더 5개·문서 8개 Trash, 두 핵심 문서만 EBS root 유지 |
| 2026-02-10 | 7.0.0 | 로컬 01_Phase00→01_PokerGFX_Analysis 리네임, local_to_drive_folder 매핑 도입 |
| 2026-02-10 | 6.0.0 | _ngd 접미사 도입, 디렉토리 명명 규칙 적용 |
| 2026-02-05 | 5.0.0 | gdrive/ 미러 폴더 제거, docs/ 직접 동기화 전환 |

---

**Version**: 9.0.0 | **Updated**: 2026-02-24 | **BRACELET STUDIO**
