---
title: Communication Rules
owner: conductor
tier: internal
last-updated: 2026-04-15
---

# 외부 커뮤니케이션 규칙 (CRITICAL)

외부(업체/파트너) 대상 이메일·문서·채팅에 적용되는 규칙.

## 핵심 규칙

| 규칙 | 내용 |
|------|------|
| 회사명 노출 금지 | "BRACELET STUDIO" 외부 이메일에 절대 사용 안 함 |
| 기술 스펙 노출 금지 | 주파수, 프로토콜, IC 칩명 언급 안 함 |
| 서명 | 이름만, 회사명 없음 |
| 이메일 구조 | 상대방 제품 정보만 요청하는 형태 |

## 용어 규칙

| 금지 | 사용 | 이유 |
|------|------|------|
| chips (카지노 맥락) | 베팅 토큰 (betting tokens) | 반도체 칩과 혼동 |
| chips (반도체 맥락) | IC, 반도체 | 위와 구분 |

## 자동화 규칙 (Slack/Gmail)

| 규칙 | 내용 |
|------|------|
| `--notify` 사용 금지 | `chat:write:bot` scope 없음 |
| `--post`만 사용 | 채널 메시지 갱신만 가능 |
| DM 발송 안 함 | Slack API 제한 |

## 출처

원본 백업: `C:/claude/ebs-archive-backup/07-archive/06-operations/COMMUNICATION-RULES_ngd.md` (2026-04-14 아카이브).
이 문서는 SSOT.
