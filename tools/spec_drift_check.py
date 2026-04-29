#!/usr/bin/env python3
"""Spec Drift Check — 기획 ↔ 코드 불일치 자동 감지.

목적:
  EBS 를 외부 개발팀 인계용 완결 프로토타입으로 유지하려면, 기획서와 코드 사이
  drift 를 체계적으로 감지해야 한다. 이 스크립트는 7 계약 (api / events / fsm /
  schema / rfid / settings / websocket) 을 정규식 기반 best-effort 스캔으로
  비교한다.

Drift 분류:
  D1 — 기획 有 / 코드 有 / 값 불일치
  D2 — 기획 有 / 코드 無 (미구현, TODO skeleton 포함 시 D4)
  D3 — 기획 無 / 코드 有 (undocumented)
  D4 — 기획 ↔ 코드 PASS

Usage:
  python tools/spec_drift_check.py --api
  python tools/spec_drift_check.py --events
  python tools/spec_drift_check.py --fsm
  python tools/spec_drift_check.py --schema
  python tools/spec_drift_check.py --rfid
  python tools/spec_drift_check.py --settings
  python tools/spec_drift_check.py --websocket
  python tools/spec_drift_check.py --all
  python tools/spec_drift_check.py --all --format=json

한계:
  - 정규식 기반 — 주석 처리된 선언·동적 생성 엔드포인트 등은 누락 가능
  - D2 (기획만 有) 는 본 스캐너 범위 밖. TODO 마커는 코드 grep 병행 필요
  - 세밀한 필드 타입 일치는 각 detector 의 간이 구현 수준

Exit code:
  0 — 실행 성공 (drift 유무와 무관)
  1 — 파일 접근 오류, 파싱 실패 등 스캐너 자체 오류
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass, field, asdict
from pathlib import Path
from typing import Iterable

REPO = Path(__file__).resolve().parents[1]

# ------------------------------------------------------------------ Models


@dataclass
class DriftItem:
    """단일 drift 항목."""

    contract: str  # api / events / fsm / schema / rfid / settings / websocket
    drift_type: str  # D1 / D2 / D3 / D4
    identifier: str  # 엔드포인트명, 이벤트명, 상태명 등
    spec_value: str = ""  # 기획서 값
    code_value: str = ""  # 코드 값
    note: str = ""


@dataclass
class ContractReport:
    contract: str
    d1: list[DriftItem] = field(default_factory=list)
    d2: list[DriftItem] = field(default_factory=list)
    d3: list[DriftItem] = field(default_factory=list)
    d4_count: int = 0
    scanner_note: str = ""

    @property
    def total(self) -> int:
        return len(self.d1) + len(self.d2) + len(self.d3) + self.d4_count


# ------------------------------------------------------------------ Helpers


def _read(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8", errors="replace")
    except FileNotFoundError:
        return ""


# ------------------------------------------------------------------ Detectors


# EBS 고유 엔드포인트 prefix. WSOP LIVE 참조 경로(`/Series/...`)는 EBS 계약이 아니므로 scan 제외
EBS_API_PREFIXES = ("/api/v1", "/auth", "/health", "/metrics")


def _is_ebs_endpoint(path: str) -> bool:
    """EBS 엔드포인트 경로인지 판별. WSOP LIVE 참조 경로는 False."""
    return any(path.startswith(p) for p in EBS_API_PREFIXES)


def detect_api() -> ContractReport:
    """REST 엔드포인트 drift — Backend_HTTP.md / Auth_and_Session.md ↔ team2 routers."""
    rep = ContractReport(contract="api")
    api_dir = REPO / "docs" / "2. Development" / "2.2 Backend" / "APIs"
    routers_dir = REPO / "team2-backend" / "src" / "routers"

    if not api_dir.exists() or not routers_dir.exists():
        rep.scanner_note = "문서 또는 라우터 경로 없음"
        return rep

    # 기획 문서 통합: Backend_HTTP.md, Auth_and_Session.md, Backend_HTTP_Status.md
    spec_text = ""
    for md in api_dir.glob("*.md"):
        spec_text += _read(md) + "\n"

    # headings 또는 인라인 언급 모두 추출 (permissive).
    # (?<![A-Z]) — `POST` 가 다른 단어의 suffix 가 아니도록 (예: "POSTGRES" 제외)
    # `/` 로 시작하는 경로만 — 명세 중 대문자 메서드+공백+/path 패턴
    spec_pat = re.compile(
        r"(?:[^A-Za-z]|^)(GET|POST|PUT|PATCH|DELETE)\s+(/[A-Za-z0-9_\-/\{\}:\.]+)"
    )
    # 2026-04-20 SG-008 추가: Markdown table cell 포맷
    #   `| GET  | \`/api/v1/users\` | 용도 | RBAC | Status |`
    # 기존 regex 는 method 와 path 사이 `|` 때문에 매칭 실패. §5.17 의 CRUD 편입
    # 77건이 이 포맷으로 기재되어 D3 로 오보고되던 근본 원인.
    spec_pat_table = re.compile(
        r"\|\s*(GET|POST|PUT|PATCH|DELETE)\s*\|\s*`(/[A-Za-z0-9_\-/\{\}:\.]+)`"
    )
    spec_set_all: set[tuple[str, str]] = set()
    for m in spec_pat.finditer(spec_text):
        method = m.group(1).upper()
        raw_path = m.group(2)
        # 잡음: / 로만 끝나는 경로 또는 너무 짧은 경로
        if len(raw_path) < 2:
            continue
        spec_set_all.add((method, _normalize_path(raw_path)))
    for m in spec_pat_table.finditer(spec_text):
        method = m.group(1).upper()
        raw_path = m.group(2)
        if len(raw_path) < 2:
            continue
        spec_set_all.add((method, _normalize_path(raw_path)))

    # WSOP LIVE 참조 경로 필터 — EBS 엔드포인트 규약 외 경로는 기획 본문 서술용 차용
    wsop_native_skipped: list[tuple[str, str]] = []
    spec_set: set[tuple[str, str]] = set()
    for method, path in spec_set_all:
        # /api/v1 prefix 없는 경로지만 stripped 형태로 문서화된 경우(예: /events) 는
        # code_set 매칭 단계에서 D1 prefix 차이로 흡수되므로 유지.
        # /Series/, /EventFlights/ 같은 WSOP 원본 경로(PascalCase segment) 만 필터.
        # 휴리스틱: path segment 첫 글자가 대문자이고 /api/v1 prefix 가 아닌 경우
        segments = path.strip("/").split("/")
        first_seg = segments[0] if segments else ""
        if first_seg and first_seg[0].isupper() and not _is_ebs_endpoint(path):
            wsop_native_skipped.append((method, path))
            continue
        spec_set.add((method, path))

    # 코드: @router.get("/flights/{id}/clock")
    code_set: set[tuple[str, str]] = set()
    code_pat = re.compile(
        r'@router\.(get|post|put|patch|delete)\s*\(\s*["\']([^"\']+)["\']'
    )
    for py in routers_dir.glob("*.py"):
        text = _read(py)
        # router prefix
        prefix_m = re.search(
            r'APIRouter\s*\(\s*prefix\s*=\s*["\']([^"\']+)["\']', text
        )
        prefix = prefix_m.group(1) if prefix_m else ""
        for m in code_pat.finditer(text):
            method = m.group(1).upper()
            path = prefix + m.group(2)
            code_set.add((method, _normalize_path(path)))

    # Diff
    only_in_spec = spec_set - code_set  # D2 (미구현 또는 경로 mismatch)
    only_in_code = code_set - spec_set  # D3
    shared = spec_set & code_set

    # V9.5 P22: §1.1 prefix 생략 정책 — 정규식 false positive 제거.
    # Backend_HTTP.md §1.1 가 "POST /users 표기 = 실제 POST /api/v1/users" 로
    # prefix 생략을 공식 정책화. 따라서 (method, stripped) ∈ spec_set 이면
    # D1 으로 분류하던 항목은 정합 (D4) 으로 처리해야 한다.
    prefix_policy_matches: set[tuple[str, str]] = set()
    for method, path in sorted(only_in_code):
        # D3: code only, undocumented
        if path.startswith("/api/v1"):
            stripped = path.replace("/api/v1", "", 1)
            if (method, stripped) in spec_set:
                # §1.1 prefix 생략 정책 — D4 (정합) 처리
                prefix_policy_matches.add((method, stripped))
                continue
        rep.d3.append(
            DriftItem(
                contract="api",
                drift_type="D3",
                identifier=f"{method} {path}",
                code_value=f"{method} {path}",
                note="코드에만 존재",
            )
        )

    for method, path in sorted(only_in_spec):
        # D2: spec only (미구현 또는 prefix 차이)
        prefixed = ("/api/v1" + path) if not path.startswith("/api/v1") else path
        if (method, prefixed) in code_set:
            # §1.1 prefix 생략 정책 — D4 정합 (위 prefix_policy_matches 와 대응)
            continue
        if (method, path) in prefix_policy_matches:
            # 위에서 이미 D4 로 인식
            continue
        rep.d2.append(
            DriftItem(
                contract="api",
                drift_type="D2",
                identifier=f"{method} {path}",
                spec_value=f"{method} {path}",
                note="기획에만 존재 (미구현 또는 경로 drift)",
            )
        )

    # V9.5 P22: prefix 정책 매치도 D4 정합으로 카운트
    rep.d4_count = len(shared) + len(prefix_policy_matches)
    rep.scanner_note = (
        f"scanned {len(spec_set)} spec endpoints "
        f"(+ {len(wsop_native_skipped)} WSOP-native refs skipped) / "
        f"{len(code_set)} code endpoints. 정규식 기반 best-effort + §1.1 prefix policy."
    )
    return rep


def _normalize_path(path: str) -> str:
    """FastAPI `{id}` ↔ 문서 `:id` 차이 흡수 + placeholder 이름 통일 (J3 2026-04-20).

    - `:id` 형태 → `{id}`
    - `{user_id}` / `{table_id}` 등 모든 named placeholder → `{_}` (이름 무관 위치 매칭)
    - trailing slash 제거
    """
    path = re.sub(r":([A-Za-z_]+)", r"{\1}", path)
    # J3: placeholder 이름 차이 (spec {id} vs code {user_id}) 흡수 — 위치 기반 매칭만
    path = re.sub(r"\{[A-Za-z_][A-Za-z0-9_]*\}", "{_}", path)
    path = path.rstrip("/")
    if not path:
        path = "/"
    return path


def detect_events() -> ContractReport:
    """OutputEvent drift — Overlay_Output_Events.md §6.0 ↔ output_event.dart."""
    rep = ContractReport(contract="events")
    doc = (
        REPO
        / "docs"
        / "2. Development"
        / "2.3 Game Engine"
        / "APIs"
        / "Overlay_Output_Events.md"
    )
    code = (
        REPO
        / "team3-engine"
        / "ebs_game_engine"
        / "lib"
        / "core"
        / "actions"
        / "output_event.dart"
    )
    if not doc.exists() or not code.exists():
        rep.scanner_note = "경로 없음"
        return rep

    spec_text = _read(doc)
    code_text = _read(code)

    # 기획: | OE-01 | `StateChanged` | ...
    spec_set = set(
        re.findall(r"\|\s*OE-\d+\s*\|\s*`([A-Za-z_][A-Za-z0-9_]*)`", spec_text)
    )
    # 코드: class Foo extends OutputEvent
    code_set = set(
        re.findall(r"^class\s+([A-Za-z_][A-Za-z0-9_]*)\s+extends\s+OutputEvent",
                   code_text, re.MULTILINE)
    )

    for name in sorted(code_set - spec_set):
        rep.d3.append(
            DriftItem(
                contract="events",
                drift_type="D3",
                identifier=name,
                code_value=f"class {name} extends OutputEvent",
                note="§6.0 카탈로그에 누락",
            )
        )
    for name in sorted(spec_set - code_set):
        rep.d2.append(
            DriftItem(
                contract="events",
                drift_type="D2",
                identifier=name,
                spec_value=f"OutputEvent {name}",
                note="기획에만 존재 (미구현)",
            )
        )
    rep.d4_count = len(spec_set & code_set)
    rep.scanner_note = f"spec={len(spec_set)} code={len(code_set)}"
    return rep


def detect_fsm() -> ContractReport:
    """FSM 상태 drift — BS_Overview §3 ↔ 각 팀 enum."""
    rep = ContractReport(contract="fsm")
    doc = REPO / "docs" / "2. Development" / "2.5 Shared" / "BS_Overview.md"
    if not doc.exists():
        rep.scanner_note = "BS_Overview.md 없음"
        return rep

    spec_text = _read(doc)
    # 3.1 TableFSM / 3.2 HandFSM / 3.3 SeatFSM 를 개별 블록으로 추출
    sections = re.split(r"(?m)^### 3\.\d+\s+", spec_text)
    # sections[0] = 서두, sections[1..] = 각 FSM
    fsms: dict[str, set[str]] = {}
    for sec in sections[1:]:
        header = sec.splitlines()[0]
        names = re.findall(r"\*\*([A-Z_][A-Z0-9_]*)\*\*", sec)
        if names:
            fsms[header.strip()] = set(names)

    # 코드 비교는 팀마다 다르므로, 여기선 TableFSM 과 HandFSM 만 대표로 확인.
    # TableFSM enum in team2 DB schema (Schema.md §table_status).
    schema_doc = (
        REPO
        / "docs"
        / "2. Development"
        / "2.2 Backend"
        / "Database"
        / "Schema.md"
    )
    schema_text = _read(schema_doc) if schema_doc.exists() else ""

    # HandFSM enum — team3 engine: check state machine + rules + engine files
    # 2026-04-21 SG-010: 범위를 core/state + core/rules + lib/engine.dart 로 확장.
    # Street enum 사용처는 state/ 외에도 rules/street_machine.dart 및 engine.dart 에 있음.
    engine_lib = REPO / "team3-engine" / "ebs_game_engine" / "lib"
    engine_state_text = ""
    if engine_lib.exists():
        for f in engine_lib.rglob("*.dart"):
            engine_state_text += _read(f) + "\n"

    # TableFSM 검증 (init.sql / routers / services / models)
    #
    # 2026-04-21 SG-010 정밀화:
    #   - single-quote `'x'` (SQL) + double-quote `"x"` (Python) 둘 다 매칭
    #   - scan 범위: routers + services + models (init.sql 과 함께)
    #   - BS_Overview §3.1 의 "직렬화 규약 (UPPERCASE display, lowercase wire)"
    #     note 에 따라 case-insensitive D4 판정.
    init_sql = REPO / "team2-backend" / "src" / "db" / "init.sql"
    init_sql_text = _read(init_sql) if init_sql.exists() else ""

    def _collect_py(*relative: str) -> str:
        buf = ""
        for rel in relative:
            d = REPO / "team2-backend" / "src" / rel
            if d.exists():
                for f in d.glob("*.py"):
                    buf += _read(f) + "\n"
        return buf

    # 2026-04-21 SG-010: db/ 도 scan (enums.py 등 FSM 선언의 canonical 위치)
    py_text = _collect_py("routers", "services", "models", "db")

    # 직렬화 규약이 BS_Overview §3.1 에 명시되어 있는지 탐지 — 있으면 D1 억제
    serialization_note_declared = (
        "직렬화 규약" in spec_text and "lowercase" in spec_text
    )

    for fsm_name, spec_states in fsms.items():
        # TableFSM 은 스키마 / init.sql / python 코드에 나타남. 코드는 lowercase 사용.
        if "TableFSM" in fsm_name:
            haystack = init_sql_text + py_text
            # single-quote 와 double-quote 둘 다 매칭
            code_states_raw = set(
                re.findall(
                    r"['\"](empty|setup|live|paused|closed|"
                    r"EMPTY|SETUP|LIVE|PAUSED|CLOSED)['\"]",
                    haystack,
                )
            )
            code_states_upper = {s.upper() for s in code_states_raw}
            # D1 감지 — BS_Overview §3.1 직렬화 규약이 명시되어 있으면 D1 억제
            if (
                not serialization_note_declared
                and code_states_raw
                and code_states_raw
                != {s.upper() for s in code_states_raw}
            ):
                rep.d1.append(
                    DriftItem(
                        contract="fsm",
                        drift_type="D1",
                        identifier="TableFSM case",
                        spec_value="UPPERCASE (EMPTY/SETUP/LIVE/PAUSED/CLOSED)",
                        code_value="lowercase (empty/setup/live/paused/closed)",
                        note="init.sql 및 routers 의 status 값이 문서와 case 불일치",
                    )
                )
            _diff_states(
                rep, fsm_name, spec_states, code_states_upper, "table_status"
            )
        elif "HandFSM" in fsm_name:
            # engine GameState game_phase 열거. lowerCamelCase 사용 경향.
            # team2 backend 도 game_phase 컬럼에 enum 값을 저장하므로 함께 scan.
            code_states = set()
            for st in ("IDLE", "SETUP_HAND", "PRE_FLOP", "FLOP", "TURN",
                       "RIVER", "SHOWDOWN", "HAND_COMPLETE", "RUN_IT_MULTIPLE"):
                # 2026-04-21 SG-010: Dart 는 underscore 제거 형식 (preflop, handcomplete)
                # 도 자주 사용. _to_camel(setupHand) + underscore 제거형 모두 허용.
                compact = st.lower().replace("_", "")  # PRE_FLOP -> preflop
                aliases = [st, st.lower(), _to_camel(st), compact]
                hay = engine_state_text + init_sql_text + py_text
                if any(a in hay for a in aliases):
                    code_states.add(st)
            _diff_states(
                rep,
                fsm_name,
                spec_states,
                code_states,
                "engine lib/core/state + team2 (game_phase)",
            )
        elif "SeatFSM" in fsm_name:
            haystack = init_sql_text + py_text
            code_states_raw = set(
                re.findall(
                    r"['\"](empty|new|playing|moved|busted|reserved|"
                    r"occupied|waiting|hold)['\"]",
                    haystack,
                )
            )
            code_states_upper = {s.upper() for s in code_states_raw}
            _diff_states(
                rep,
                fsm_name,
                spec_states,
                code_states_upper,
                "seats CHECK + services",
            )
        else:
            # 그 외 FSM 은 CODE 참조 소유 팀이 불명확 — d4 로 간주하지 않고 noted
            continue

    rep.scanner_note = (
        f"checked {sum(1 for k in fsms if 'TableFSM' in k or 'HandFSM' in k or 'SeatFSM' in k)} "
        "of %d FSMs (TableFSM/HandFSM/SeatFSM 대표, "
        "직렬화 규약=%s)" % (len(fsms), "O" if serialization_note_declared else "X")
    )
    return rep


def _to_camel(snake: str) -> str:
    parts = snake.lower().split("_")
    return parts[0] + "".join(p.title() for p in parts[1:])


def _diff_states(
    rep: ContractReport,
    fsm_name: str,
    spec: set[str],
    code: set[str],
    code_ref: str,
) -> None:
    for s in sorted(code - spec):
        rep.d3.append(
            DriftItem(
                contract="fsm",
                drift_type="D3",
                identifier=f"{fsm_name}:{s}",
                code_value=f"{code_ref}: {s}",
                note="기획에 없음",
            )
        )
    for s in sorted(spec - code):
        rep.d2.append(
            DriftItem(
                contract="fsm",
                drift_type="D2",
                identifier=f"{fsm_name}:{s}",
                spec_value=s,
                note=f"{code_ref} 에 미구현 또는 scanner 누락",
            )
        )
    rep.d4_count += len(spec & code)


def _extract_sql_code_blocks(text: str) -> str:
    """Markdown 의 ```sql ... ``` fenced code block 만 추출. inline backtick 은 제외."""
    pattern = re.compile(r"```sql\s*\n(.*?)```", re.DOTALL | re.IGNORECASE)
    blocks = pattern.findall(text)
    return "\n".join(blocks)


def detect_schema() -> ContractReport:
    """DB 스키마 drift — Schema.md ↔ init.sql / migrations.

    R1-a 정제: inline backtick `table_name` 을 CREATE TABLE 로 오인하지 않도록
    - 문서측: ```sql fenced block 안의 실제 CREATE TABLE 문만 추출
    - 헤더 패턴(### 테이블 `foo`) 도 보조로 사용. CREATE TABLE 과 별개로 카운트 합집합.
    """
    rep = ContractReport(contract="schema")
    schema_doc = (
        REPO / "docs" / "2. Development" / "2.2 Backend" / "Database" / "Schema.md"
    )
    init_sql = REPO / "team2-backend" / "src" / "db" / "init.sql"
    if not schema_doc.exists() or not init_sql.exists():
        rep.scanner_note = "Schema.md 또는 init.sql 없음"
        return rep

    spec_text = _read(schema_doc)
    code_text = _read(init_sql)

    # 1) 문서측: SQL fenced block 안의 CREATE TABLE 문만
    sql_blocks = _extract_sql_code_blocks(spec_text)
    spec_tables_sql = set(
        re.findall(
            r"CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?`?([a-z_][a-z0-9_]*)`?",
            sql_blocks,
            re.IGNORECASE,
        )
    )
    # 2) 문서측: Python fenced block 안의 SQLModel `__tablename__ = "foo"` 패턴
    #    Schema.md 는 SQLModel 스타일로 작성되어 있음
    py_blocks_pat = re.compile(r"```python\s*\n(.*?)```", re.DOTALL | re.IGNORECASE)
    py_blocks = "\n".join(py_blocks_pat.findall(spec_text))
    spec_tables_sqlmodel = set(
        re.findall(
            r'__tablename__\s*=\s*["\']([a-z_][a-z0-9_]*)["\']',
            py_blocks,
        )
    )
    # 3) 문서측 보조: 헤더 패턴 `### 테이블 \`foo_bar\`` 또는 `### \`foo_bar\``
    spec_tables_header = set(
        re.findall(
            r"(?m)^#{2,4}\s+(?:테이블\s+)?`([a-z_][a-z0-9_]*)`",
            spec_text,
        )
    )
    spec_tables = spec_tables_sql | spec_tables_sqlmodel | spec_tables_header

    # 잡음 제거 (일반 단어 / SQL 예약어)
    _noise = {
        "string", "integer", "boolean", "timestamp", "id", "type", "status",
        "value", "bigint", "text", "varchar", "primary", "foreign", "default",
        "null", "cascade", "key", "exists", "table",
    }
    spec_tables = {t for t in spec_tables if t not in _noise and len(t) > 2}

    code_tables = set(
        re.findall(
            r"CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?([a-z_][a-z0-9_]*)",
            code_text,
            re.IGNORECASE,
        )
    )

    # migrations
    migrations_dir = REPO / "team2-backend" / "migrations" / "versions"
    if migrations_dir.exists():
        for mig in migrations_dir.glob("*.py"):
            txt = _read(mig)
            code_tables |= set(
                re.findall(
                    r"op\.create_table\s*\(\s*['\"]([a-z_][a-z0-9_]*)",
                    txt,
                )
            )

    for t in sorted(code_tables - spec_tables):
        rep.d3.append(
            DriftItem(
                contract="schema",
                drift_type="D3",
                identifier=t,
                code_value=f"CREATE TABLE {t}",
                note="Schema.md 문서에 없음",
            )
        )
    for t in sorted(spec_tables - code_tables):
        rep.d2.append(
            DriftItem(
                contract="schema",
                drift_type="D2",
                identifier=t,
                spec_value=f"table {t}",
                note="기획에만 존재 (미구현)",
            )
        )
    rep.d4_count = len(spec_tables & code_tables)
    rep.scanner_note = (
        f"spec tables={len(spec_tables)} "
        f"(sql={len(spec_tables_sql)} + sqlmodel={len(spec_tables_sqlmodel)} + header={len(spec_tables_header)}) "
        f"code tables={len(code_tables)}. SQL/Python fenced block + header 패턴만 매칭 (inline code 제외)."
    )
    return rep


def detect_rfid() -> ContractReport:
    """RFID HAL 시그니처 drift — RFID_HAL_Interface.md ↔ i_rfid_reader.dart.

    SG-010 정밀화 (2026-04-20):
      - 정방향: 코드 → 문서 (D3 감지) — 기존 동작
      - 역방향: 문서 → 코드 (D2 감지) — 문서 §2 `abstract class IRfidReader`
        dart fenced code block 의 stream/method 시그니처 추출 후 코드 대조
      - 문서 내 혼재한 다중 설계 (§2.1 단일 Stream<RfidEvent> vs §2.2+ 6-스트림)
        는 양쪽 모두 수집해 실제 code 기준으로 교집합 판단
    """
    rep = ContractReport(contract="rfid")
    doc = (
        REPO
        / "docs"
        / "2. Development"
        / "2.4 Command Center"
        / "APIs"
        / "RFID_HAL_Interface.md"
    )
    code = (
        REPO / "team4-cc" / "src" / "lib" / "rfid" / "abstract" / "i_rfid_reader.dart"
    )
    if not doc.exists() or not code.exists():
        rep.scanner_note = f"경로 없음 (doc={doc.exists()}, code={code.exists()})"
        return rep

    spec_text = _read(doc)
    code_text = _read(code)

    # Code side — authoritative source of truth per SG-010 note
    code_streams = set(
        re.findall(r"Stream<[^>]+>\s+get\s+(on\w+)", code_text)
    )
    code_methods = set(
        re.findall(r"Future<[^>]*>\s+(\w+)\s*\(", code_text)
    )

    # Spec side — extract from ```dart fenced blocks only (inline ref is noisy)
    dart_blocks = re.findall(
        r"```dart\s*\n(.*?)```", spec_text, re.DOTALL | re.IGNORECASE
    )
    spec_dart = "\n".join(dart_blocks)
    spec_streams_declared = set(
        re.findall(r"Stream<[^>]+>\s+get\s+(\w+)", spec_dart)
    )
    spec_methods_declared = set(
        re.findall(r"Future<[^>]*>\s+(\w+)\s*\(", spec_dart)
    )
    # Fallback: spec text mentions method/stream name outside fenced block
    spec_streams_mentioned = {s for s in code_streams if s in spec_text}
    spec_methods_mentioned = {m for m in code_methods if m in spec_text}
    spec_streams_all = spec_streams_declared | spec_streams_mentioned
    spec_methods_all = spec_methods_declared | spec_methods_mentioned

    # D3: 코드에만 존재 (문서에 언급조차 없음)
    for s in sorted(code_streams - spec_streams_all):
        rep.d3.append(
            DriftItem(
                contract="rfid",
                drift_type="D3",
                identifier=f"stream:{s}",
                code_value=f"Stream {s}",
                note="RFID_HAL_Interface.md 에 언급 없음",
            )
        )
    for m in sorted(code_methods - spec_methods_all):
        rep.d3.append(
            DriftItem(
                contract="rfid",
                drift_type="D3",
                identifier=f"method:{m}",
                code_value=f"Future {m}(...)",
                note="RFID_HAL_Interface.md 에 언급 없음",
            )
        )

    # M4 (2026-04-21): out_of_scope_prototype frontmatter 플래그 확인 — SG-011 상태면
    # spec 측 legacy 설계 잔존은 drift 가 아니라 의도적 보류. D2 수집 skip.
    out_of_scope = (
        "out_of_scope_prototype: true" in spec_text
        or "drift_ignore_rfid: true" in spec_text
    )
    if out_of_scope:
        rep.d4_count = len(code_streams & spec_streams_all) + len(
            code_methods & spec_methods_all
        )
        rep.scanner_note = (
            f"code streams={len(code_streams)} methods={len(code_methods)} / "
            f"spec dart-block streams={len(spec_streams_declared)} "
            f"methods={len(spec_methods_declared)}. "
            "**SG-011 out_of_scope_prototype — D2 수집 skip (legacy 설계 잔존은 drift 아님).**"
        )
        return rep

    # D2: 문서 fenced block 에 선언된 시그니처가 코드 구현에 없음
    # (§2.1 의 events 단일 스트림처럼 역사적 설계 잔존 포함)
    _noise_methods = {"initialize", "registerDeck"}  # §2.1 legacy, 향후 재통합
    for s in sorted(spec_streams_declared - code_streams):
        rep.d2.append(
            DriftItem(
                contract="rfid",
                drift_type="D2",
                identifier=f"stream:{s}",
                spec_value=f"Stream {s} (문서 §2 dart block)",
                note="코드 i_rfid_reader.dart 에 미구현 (legacy 설계 흔적 가능)",
            )
        )
    for m in sorted(spec_methods_declared - code_methods):
        if m in _noise_methods:
            # SG-011 통합 예정으로 이미 계획됨 — drift 로 재보고하지 않음
            continue
        rep.d2.append(
            DriftItem(
                contract="rfid",
                drift_type="D2",
                identifier=f"method:{m}",
                spec_value=f"Future {m}(...) (문서 §2 dart block)",
                note="코드 i_rfid_reader.dart 에 미구현",
            )
        )

    rep.d4_count = len(code_streams & spec_streams_all) + len(
        code_methods & spec_methods_all
    )
    rep.scanner_note = (
        f"code streams={len(code_streams)} methods={len(code_methods)} / "
        f"spec dart-block streams={len(spec_streams_declared)} "
        f"methods={len(spec_methods_declared)}. "
        "정방향 + 역방향 대칭 비교 (dart fenced block 전용)."
    )
    return rep


def detect_settings() -> ContractReport:
    """Settings 필드 drift — 양방향 symmetric 비교 (SG-010 정밀화).

    기획 소스:
      - team1 Settings/*.md (6 탭: Outputs, Graphics, Display, Rules, Statistics,
        Preferences) — 파일명/필드명/저장 키
      - team4 Command_Center/Settings.md

    코드 소스:
      - team1 screens/*.dart — `draft['fieldName']` / `updateField('fieldName')` 호출
      - team1 providers/settings_provider.dart — SettingsSection enum
      - team2 migration 0005 — settings_kv 초기값
      - team2 init.sql — settings 관련 CheckConstraint

    이전 버전은 migration 0005 의 `dot.key` 형식만 검사해 spec=13 code=0
    편향이 있었다. 이번 버전은 카멜케이스 필드(code) ↔ 문서(spec) 를
    대칭 비교한다. false positive 감소 최우선.
    """
    rep = ContractReport(contract="settings")
    # 기획 문서들
    doc_dirs = [
        REPO / "docs" / "2. Development" / "2.1 Frontend" / "Settings",
        REPO / "docs" / "2. Development" / "2.4 Command Center",
    ]
    spec_text = ""
    spec_sources: list[str] = []
    for d in doc_dirs:
        if not d.exists():
            continue
        for md in d.glob("*.md"):
            # 파일명이 Settings 또는 6탭 + UI.md (legacy SG-003 consolidated spec) 경우만
            name = md.name
            if name in (
                "Outputs.md",
                "Graphics.md",
                "Display.md",
                "Rules.md",
                "Statistics.md",
                "Preferences.md",
                "Overview.md",
                "Settings.md",
                "UI.md",  # SG-003 통합 settings spec (dotted namespace: gfx.*/output.*/pref.* 등)
            ):
                spec_text += _read(md) + "\n"
                spec_sources.append(str(md.relative_to(REPO)))

    # 코드 소스들
    screens_dir = (
        REPO / "team1-frontend" / "lib" / "features" / "settings" / "screens"
    )
    providers_dir = (
        REPO / "team1-frontend" / "lib" / "features" / "settings" / "providers"
    )
    code_text_team1 = ""
    if screens_dir.exists():
        for f in screens_dir.glob("*.dart"):
            code_text_team1 += _read(f) + "\n"
    if providers_dir.exists():
        for f in providers_dir.glob("*.dart"):
            code_text_team1 += _read(f) + "\n"

    if not spec_text or not code_text_team1:
        rep.scanner_note = (
            f"입력 부족 (spec sources={len(spec_sources)}, "
            f"team1 code={bool(code_text_team1)})"
        )
        return rep

    # 코드: draft['fieldName'] 또는 updateField('fieldName') 추출
    code_keys = set()
    for m in re.finditer(r"draft\[\s*['\"]([a-zA-Z_][a-zA-Z0-9_]*)['\"]\s*\]", code_text_team1):
        code_keys.add(m.group(1))
    for m in re.finditer(
        r"updateField\s*\(\s*['\"]([a-zA-Z_][a-zA-Z0-9_]*)['\"]",
        code_text_team1,
    ):
        code_keys.add(m.group(1))

    # 기획: backtick-wrapped identifier — camelCase / snake_case / dotted 모두 가능
    # 문서는 주로 인간 설명 스타일이라 매우 noisy. 다음 휴리스틱으로 필터.
    # (a) plain identifier: `animation_speed`, `showLeaderboard`
    # (b) dotted namespace: `gfx.show_leaderboard`, `output.frame_rate`, `pref.table_password`
    #     → 네임스페이스 제거 후 마지막 segment 만 수집
    spec_candidates = set(
        re.findall(
            r"`([a-zA-Z_][a-zA-Z0-9_]{2,})`",
            spec_text,
        )
    )
    # 점/슬래시로 등장한 identifier 는 필터 없이 확정 spec key 로 사용 (whitelist)
    # 일반 산문의 명사 noise 와 구분하기 위해 구조적 맥락만 추출
    spec_whitelist: set[str] = set()

    # 점 구분 identifier 에서 마지막 segment 추출 (예: `gfx.show_leaderboard` → show_leaderboard)
    # dotted ref 는 명백한 setting key 이므로 whitelist 로 필터 bypass
    for m in re.finditer(
        r"`([a-zA-Z_][a-zA-Z0-9_]*(?:\.[a-zA-Z_][a-zA-Z0-9_]*)+)`",
        spec_text,
    ):
        dotted = m.group(1)
        last_segment = dotted.rsplit(".", 1)[-1]
        if len(last_segment) >= 3:
            spec_whitelist.add(last_segment)
    # YAML frontmatter 의 `reimplementability_notes` 값 안의 slash-separated list 에서
    # snake_case identifier 추출
    # (예: "active_skin_id/color_theme/animation_speed/..." → 각 token)
    # frontmatter key 자체(예: reimplementability_checked) 는 수집하지 않는다.

    for notes_m in re.finditer(
        r'reimplementability_notes:\s*"([^"]+)"',
        spec_text,
    ):
        notes_val = notes_m.group(1)
        # snake_case (multi-word) token
        for tok in re.findall(r"\b([a-z][a-z0-9]*(?:_[a-z0-9]+)+)\b", notes_val):
            spec_whitelist.add(tok)
        # 슬래시 구분 list 안의 단일 단어 token (예: "a/b/language" 끝의 language)
        for tok in re.findall(
            r"(?<=[/])([a-z][a-z0-9]{2,})(?=[/(\s,.]|$)",
            notes_val,
        ):
            spec_whitelist.add(tok)

    # 구조적 noise (데이터베이스 객체, 이벤트 이름, 모듈명 — 설정 키 아님)
    _structural_noise = {
        "settings_kv", "settingsStore", "audit_logs", "skin_updated",
        "user_preferences", "expanded_series", "activeConfig",
        "pendingConfigChanges", "toggle_overlay", "new_hand",
        "reveal_holecards", "event_types", "game_type",
        "players_view", "table_view",
    }

    def _looks_like_setting_key(name: str) -> bool:
        # 최소 길이·단어성 검사
        if len(name) < 4:
            return False
        # 공통 noise 단어
        _noise = {
            "true", "false", "null", "enum", "string", "int", "bool",
            "number", "object", "array", "json", "value", "text",
            "required", "optional", "default", "const", "type", "size",
            "input", "select", "switch", "dropdown", "checkbox",
            "admin", "user", "seat", "table", "event", "series", "global",
            "void", "Future", "Stream", "List", "Map", "dynamic",
            "this", "self", "other", "name", "mode", "key",
        }
        if name in _noise or name.lower() in _noise:
            return False
        if name in _structural_noise:
            return False
        # identifier 내부 구분자(. _ -) 가 있거나 camelCase 인 경우
        has_separator = "." in name or "_" in name
        is_camel = name[0].islower() and any(c.isupper() for c in name[1:])
        return has_separator or is_camel

    spec_keys = {k for k in spec_candidates if _looks_like_setting_key(k)}
    # whitelist (dotted/slash 컨텍스트로 명시적 setting 키) 는 filter bypass
    # 단 structural noise 는 계속 제외
    for k in spec_whitelist:
        if k not in _structural_noise and len(k) >= 3:
            spec_keys.add(k)

    # 대칭 D3: 코드에만 — 대소문자/언더스코어 정규화 후 매칭
    def _normalize(k: str) -> str:
        return k.lower().replace("_", "").replace(".", "")

    spec_norm = {_normalize(k): k for k in spec_keys}
    code_norm = {_normalize(k): k for k in code_keys}

    shared_norm = set(spec_norm.keys()) & set(code_norm.keys())

    for nk, orig in sorted(code_norm.items()):
        if nk in shared_norm:
            continue
        rep.d3.append(
            DriftItem(
                contract="settings",
                drift_type="D3",
                identifier=orig,
                code_value=f"draft['{orig}'] / updateField('{orig}')",
                note="Settings/*.md 에 언급 없음",
            )
        )
    for nk, orig in sorted(spec_norm.items()):
        if nk in shared_norm:
            continue
        rep.d2.append(
            DriftItem(
                contract="settings",
                drift_type="D2",
                identifier=orig,
                spec_value=f"`{orig}`",
                note="team1 settings screens/providers 에 미구현",
            )
        )

    rep.d4_count = len(shared_norm)
    rep.scanner_note = (
        f"spec keys={len(spec_keys)} (sources={len(spec_sources)}) / "
        f"code keys={len(code_keys)}. 대칭 비교 (대소문자/언더스코어 정규화). "
        "false positive 감소 위해 휴리스틱 필터 적용."
    )
    return rep


def detect_websocket() -> ContractReport:
    """WebSocket event drift — WebSocket_Events.md ↔ team2 websocket handlers.

    F2 정밀화 (2026-04-20):
      - 이전 버전은 backtick identifier 전체에서 휴리스틱으로 event type 을 추출해
        payload 필드(`table_id`, `event_id`, `bb_amount` 등)까지 D2 로 보고하는
        false positive 가 심각 (D2=89).
      - 신 알고리즘은 **"이벤트 카탈로그" 구조** 만 신뢰 소스로 사용.

    Spec 측 추출 전략 (명시적 event type 만):
      1. Markdown 이벤트 카탈로그 테이블: 헤더가 `| 이벤트 |` 로 시작하는
         테이블의 첫 컬럼 값이 backtick-wrapped identifier 일 때만 수집.
      2. Envelope 예시의 `"type": "EventName"` JSON 리터럴.
      3. Subscribe 예시의 `event_types: [...]` 배열 원소.
      4. WSOP LIVE ↔ EBS 매핑 테이블 (CCR-054) 의 `EBS 이벤트` 컬럼.

    Code 측 추출 전략:
      1. 정적 `"type": "EventName"` 문자열 리터럴.
      2. 동적 forwarding: cc_handler.py `event_type_map` dict 의 key (PascalCase
         CC 이벤트) — publisher 가 `msg.get("type")` 로 그대로 포워딩.
      3. Write command dict `_WRITE_COMMANDS` 의 key + (ack_type, rejected_type).
    """
    rep = ContractReport(contract="websocket")
    doc = (
        REPO / "docs" / "2. Development" / "2.2 Backend" / "APIs" / "WebSocket_Events.md"
    )
    ws_dir = REPO / "team2-backend" / "src" / "websocket"
    backend_src = REPO / "team2-backend" / "src"

    if not doc.exists():
        rep.scanner_note = "WebSocket_Events.md 없음"
        return rep
    if not ws_dir.exists():
        rep.scanner_note = "team2 websocket/ 경로 없음 — code source not found"
        return rep

    spec_text = _read(doc)

    # ── Spec 추출: 명시적 event type source 4가지 ──
    spec_events: set[str] = set()

    # (1) 이벤트 카탈로그 테이블: 헤더 `| 이벤트 |` 로 시작하는 섹션의 첫 컬럼
    # 테이블 헤더 라인과 body 라인을 함께 스캔
    lines = spec_text.splitlines()
    in_event_table = False
    for i, line in enumerate(lines):
        # 헤더 감지: `| 이벤트 | ...` 또는 `| EBS 이벤트 | ...`
        if re.match(r"^\|\s*(이벤트|EBS 이벤트)\s*\|", line):
            in_event_table = True
            continue
        # 테이블 종료: 빈 줄 또는 non-table 라인
        if in_event_table:
            if not line.strip().startswith("|"):
                in_event_table = False
                continue
            # 구분자 라인 (`|---|---|`) skip
            if re.match(r"^\|\s*:?-+:?\s*\|", line):
                continue
            # 첫 컬럼 추출
            cols = [c.strip() for c in line.split("|")]
            if len(cols) >= 2:
                first = cols[1]
                # backtick-wrapped identifier?
                m = re.match(r"`([A-Za-z_][A-Za-z0-9_]*)`", first)
                if m:
                    spec_events.add(m.group(1))

    # (2) Envelope JSON 예시의 `"type": "EventName"` 리터럴
    for m in re.finditer(
        r'["\']type["\']\s*:\s*["\']([A-Za-z_][A-Za-z0-9_]*)["\']',
        spec_text,
    ):
        spec_events.add(m.group(1))

    # (3) Subscribe `event_types: [...]` 배열 원소
    for arr_m in re.finditer(r'"event_types"\s*:\s*\[([^\]]+)\]', spec_text):
        arr_body = arr_m.group(1)
        for e in re.findall(r'["\']([A-Za-z_][A-Za-z0-9_]*)["\']', arr_body):
            spec_events.add(e)

    # (4) CC → BO 커맨드 요약 테이블 (§12): `응답 Ack | 응답 Rejected` 컬럼
    #     헤더가 `| 커맨드 | ... | 응답 Ack | 응답 Rejected |` 인 테이블의
    #     모든 backtick identifier (command + ack + rejected).
    in_cmd_table = False
    for line in lines:
        if re.match(r"^\|\s*커맨드\s*\|.*응답\s*Ack", line):
            in_cmd_table = True
            continue
        if in_cmd_table:
            if not line.strip().startswith("|"):
                in_cmd_table = False
                continue
            if re.match(r"^\|\s*:?-+:?\s*\|", line):
                continue
            for m in re.finditer(r"`([A-Za-z_][A-Za-z0-9_]*)`", line):
                spec_events.add(m.group(1))

    # (5) Subsection 헤더 패턴: `#### N.N.N event_name (...)` — 4.2.N event_name
    # event_name 은 plain text 이므로 엄격한 snake_case 식별자만
    for m in re.finditer(
        r"(?m)^#{2,4}\s+\d+\.\d+(?:\.\d+)?\s+([a-z][a-z_]+[a-z])(?:\s|\(|$)",
        spec_text,
    ):
        name = m.group(1)
        if "_" in name:
            spec_events.add(name)

    # Spec 추출 공용 noise — envelope meta 필드 (event type 아님)
    _meta_noise = {
        "Auth",
        "Subscribe",
        "access",
        "refresh",
        "password_reset",
        "ok",
        "error",
        "ok_replayed",
    }
    spec_events -= _meta_noise

    # ── Code 추출 ──
    code_events: set[str] = set()
    type_pat = re.compile(r'["\']type["\']\s*:\s*["\']([A-Za-z_][A-Za-z0-9_]*)["\']')
    for py in ws_dir.glob("*.py"):
        text = _read(py)
        for m in type_pat.finditer(text):
            code_events.add(m.group(1))

    # main.py 의 OperatorConnected / OperatorDisconnected 등 직접 broadcast
    main_py = backend_src / "main.py"
    if main_py.exists():
        main_text = _read(main_py)
        for m in type_pat.finditer(main_text):
            # jwt/security 류 token type 은 제외 (access/refresh/password_reset)
            name = m.group(1)
            if name not in {"access", "refresh", "password_reset"}:
                code_events.add(name)

    # config_service.py 의 ConfigChanged broadcast
    cfg_svc = backend_src / "services" / "config_service.py"
    if cfg_svc.exists():
        cfg_text = _read(cfg_svc)
        for m in type_pat.finditer(cfg_text):
            code_events.add(m.group(1))

    # 동적 forwarding: cc_handler.py 의 event_type_map dict key (PascalCase CC 이벤트)
    cc_handler = ws_dir / "cc_handler.py"
    if cc_handler.exists():
        cc_text = _read(cc_handler)
        # event_type_map = { "HandStarted": "hand_started", ... } block
        map_m = re.search(
            r"event_type_map\s*=\s*\{([^}]+)\}",
            cc_text,
            re.DOTALL,
        )
        if map_m:
            for k in re.findall(
                r'["\']([A-Za-z_][A-Za-z0-9_]*)["\']\s*:\s*["\'][A-Za-z_]',
                map_m.group(1),
            ):
                code_events.add(k)
        # _WRITE_COMMANDS dict key + tuple ack/rejected types
        wc_m = re.search(
            r"_WRITE_COMMANDS[^=]*=\s*\{([^\}]+?)\}\s*\n\n",
            cc_text,
            re.DOTALL,
        )
        if wc_m:
            body = wc_m.group(1)
            # command name (key)
            for k in re.findall(
                r'^\s*["\']([A-Za-z_][A-Za-z0-9_]*)["\']\s*:\s*\(',
                body,
                re.MULTILINE,
            ):
                code_events.add(k)
            # ack/rejected type names — tuple 2nd/3rd string entries
            for ack_m in re.finditer(
                r'\(\s*\[[^\]]*\]\s*,\s*["\']([A-Za-z_][A-Za-z0-9_]*)["\']\s*,\s*["\']([A-Za-z_][A-Za-z0-9_]*)["\']',
                body,
            ):
                code_events.add(ack_m.group(1))
                code_events.add(ack_m.group(2))

    # Code 측 noise: envelope meta / JWT payload types
    _code_noise = {"access", "refresh", "password_reset"}
    code_events -= _code_noise

    if not code_events:
        rep.scanner_note = (
            "code source found but no event types extracted — "
            "detector returns empty (수동 확인 필요)"
        )
        return rep

    # Diff
    for e in sorted(code_events - spec_events):
        rep.d3.append(
            DriftItem(
                contract="websocket",
                drift_type="D3",
                identifier=e,
                code_value=f'"type": "{e}"',
                note="WebSocket_Events.md 에 언급 없음",
            )
        )
    for e in sorted(spec_events - code_events):
        rep.d2.append(
            DriftItem(
                contract="websocket",
                drift_type="D2",
                identifier=e,
                spec_value=e,
                note="기획에만 존재 (미구현 또는 발행자 미확인)",
            )
        )

    rep.d4_count = len(spec_events & code_events)
    rep.scanner_note = (
        f"spec events={len(spec_events)} code events={len(code_events)}. "
        "F2 정밀화: 이벤트 카탈로그 테이블 + JSON literal + event_types 배열만 수집, "
        "payload 필드 제외."
    )
    return rep


def detect_auth() -> ContractReport:
    """인증 정책 drift — BS-01 Authentication.md SSOT ↔ team2-backend src.

    M1 D+0 scope: 1 rule (MAX_FAILED_ATTEMPTS, CCR-048).

    M1 D+1+ scope (계획되어 있으나 미구현):
      - LOCK_MODE permanent vs timed (auth_service.py _LOCK_DURATION_MIN 폐기)
      - blacklist 모듈 존재 (src/security/blacklist.py + middleware/rbac.py 통합)
      - user_sessions 복합 PK (UNIQUE(user_id) → (user_id, device_id))
      - refresh_token_delivery 환경별 매트릭스 (live=cookie, dev/staging/prod=body)

    각 룰 추가는 대응 코드 fix PR 와 동시 진행. Drift Gate 가 fail 모드일 때
    rule을 추가하면서 fix 가 누락되면 즉시 PR 차단.
    """
    rep = ContractReport(contract="auth")
    spec_path = (
        REPO / "docs" / "2. Development" / "2.5 Shared" / "Authentication.md"
    )
    code_path = (
        REPO / "team2-backend" / "src" / "services" / "auth_service.py"
    )
    if not spec_path.exists() or not code_path.exists():
        rep.scanner_note = (
            f"입력 부족 (spec={spec_path.exists()}, code={code_path.exists()})"
        )
        return rep

    spec_text = _read(spec_path)
    code_text = _read(code_path)

    # Rule 1: MAX_FAILED_ATTEMPTS — BS-01 §자동 잠금 정책 (CCR-048)
    # Spec: "**비밀번호 실패 N회 연속**" 패턴 (line 648 anchor)
    # Code: "_MAX_FAILED_ATTEMPTS = N" (auth_service.py:16 anchor)
    spec_max: int | None = None
    m = re.search(r"비밀번호\s*실패\s*\*{0,2}(\d+)회\s*연속", spec_text)
    if m:
        spec_max = int(m.group(1))

    code_max: int | None = None
    m = re.search(r"_MAX_FAILED_ATTEMPTS\s*=\s*(\d+)", code_text)
    if m:
        code_max = int(m.group(1))

    if spec_max is not None and code_max is not None:
        if spec_max != code_max:
            rep.d1.append(
                DriftItem(
                    contract="auth",
                    drift_type="D1",
                    identifier="MAX_FAILED_ATTEMPTS",
                    spec_value=str(spec_max),
                    code_value=str(code_max),
                    note=(
                        "BS-01 §자동 잠금 정책 (CCR-048) ↔ "
                        "auth_service.py:_MAX_FAILED_ATTEMPTS"
                    ),
                )
            )
    elif spec_max is None:
        rep.d2.append(
            DriftItem(
                contract="auth",
                drift_type="D2",
                identifier="MAX_FAILED_ATTEMPTS (spec missing)",
                spec_value="—",
                code_value=str(code_max) if code_max else "—",
                note="BS-01 §자동 잠금 정책에서 'N회 연속' 패턴을 찾지 못함",
            )
        )
    elif code_max is None:
        rep.d2.append(
            DriftItem(
                contract="auth",
                drift_type="D2",
                identifier="MAX_FAILED_ATTEMPTS (code missing)",
                spec_value=str(spec_max),
                code_value="—",
                note="auth_service.py 에서 _MAX_FAILED_ATTEMPTS 정수 상수를 찾지 못함",
            )
        )

    # Rule 3 — Blacklist module 존재 (M1 Item 2 / BS-01 §강제 무효화)
    # Spec: BS-01 가 "blacklist:jti" 또는 "blacklist 추가" 패턴을 언급하면 모듈 필수
    # Code: src/security/blacklist.py 파일 존재 + middleware/rbac.py 가 import + use
    blacklist_in_spec = bool(
        re.search(r"blacklist[:\s]*jti|blacklist\s*추가|Refresh\s*Token\s*blacklist", spec_text)
    )
    blacklist_module_path = REPO / "team2-backend" / "src" / "security" / "blacklist.py"
    blacklist_module_exists = blacklist_module_path.exists()
    middleware_path = REPO / "team2-backend" / "src" / "middleware" / "rbac.py"
    middleware_uses_blacklist = False
    if middleware_path.exists():
        mw_text = _read(middleware_path)
        middleware_uses_blacklist = bool(
            re.search(r"from\s+src\.security\.blacklist\s+import|is_revoked\s*\(", mw_text)
        )

    if blacklist_in_spec and not blacklist_module_exists:
        rep.d2.append(
            DriftItem(
                contract="auth",
                drift_type="D2",
                identifier="blacklist module",
                spec_value="present (BS-01 §강제 무효화)",
                code_value="missing (src/security/blacklist.py)",
                note="기획은 blacklist 운영 명시 / 코드 모듈 부재 — M1 Item 2 미해소",
            )
        )
    elif blacklist_in_spec and blacklist_module_exists and not middleware_uses_blacklist:
        rep.d2.append(
            DriftItem(
                contract="auth",
                drift_type="D2",
                identifier="blacklist middleware integration",
                spec_value="enforced (모든 access token 검증)",
                code_value="module exists but middleware/rbac.py 가 사용 안 함",
                note="모듈은 있으나 통합 안 됨 — get_current_user 가 is_revoked 호출 필요",
            )
        )

    # Rule 4 — Composite session PK (M1 Item 3 / BS-01 §A-25 다중 세션)
    # Spec: '최대 동시 세션 2' 또는 'Lobby + CC' 또는 'device_id' 패턴
    # Code: src/models/user.py 에 device_id 필드 + init.sql 에 UNIQUE(user_id, device_id)
    multi_session_in_spec = bool(
        re.search(
            r"최대\s*동시\s*세션\s*[\|\s:]*\s*2|Lobby\s*\+\s*CC|device_id",
            spec_text,
        )
    )
    model_path = REPO / "team2-backend" / "src" / "models" / "user.py"
    ddl_path = REPO / "team2-backend" / "src" / "db" / "init.sql"
    has_device_id_in_model = False
    if model_path.exists():
        model_text = _read(model_path)
        has_device_id_in_model = bool(
            re.search(r"device_id\s*:\s*str", model_text)
        )
    has_composite_unique = False
    if ddl_path.exists():
        ddl_text = _read(ddl_path)
        has_composite_unique = bool(
            re.search(r"UNIQUE\s*\(\s*user_id\s*,\s*device_id\s*\)", ddl_text)
        )

    if multi_session_in_spec and not (has_device_id_in_model and has_composite_unique):
        missing = []
        if not has_device_id_in_model:
            missing.append("UserSession.device_id field")
        if not has_composite_unique:
            missing.append("init.sql UNIQUE(user_id, device_id)")
        rep.d2.append(
            DriftItem(
                contract="auth",
                drift_type="D2",
                identifier="user_sessions composite PK",
                spec_value="UNIQUE(user_id, device_id) for multi-session",
                code_value=f"missing: {', '.join(missing)}",
                note="BS-01 §A-25 'Lobby+CC 동시 2개' 정책 미구현 — M1 Item 3 미해소",
            )
        )

    # Rule 1b — Lock mode permanent (M1 Item 1b / BS-01 §자동 잠금 정책)
    # Spec: "영구 잠금" / "Admin 수동 해제"
    # Code: timed lock 상수 (_LOCK_DURATION_MIN = N) 부재 + permanent marker 존재
    permanent_in_spec = bool(
        re.search(r"영구\s*잠금|Admin\s*수동\s*해제", spec_text)
    )
    has_timed_lock_constant = bool(
        re.search(r"_LOCK_DURATION_MIN\s*=\s*\d+", code_text)
    )
    has_permanent_marker = bool(
        re.search(
            r"_PERMANENT_LOCK_SENTINEL|9999-12-31|is_locked\s*:\s*bool",
            code_text,
        )
    )
    if permanent_in_spec and (has_timed_lock_constant or not has_permanent_marker):
        violations = []
        if has_timed_lock_constant:
            violations.append("_LOCK_DURATION_MIN (timed) 잔존")
        if not has_permanent_marker:
            violations.append("_PERMANENT_LOCK_SENTINEL 미사용")
        rep.d2.append(
            DriftItem(
                contract="auth",
                drift_type="D2",
                identifier="LOCK_MODE permanent",
                spec_value="permanent (Admin manual unlock)",
                code_value=", ".join(violations),
                note="BS-01 §자동 잠금 정책: '영구' — timed lock 폐기 + sentinel/boolean 사용",
            )
        )

    # Rule 5 — refresh_token_delivery matrix (M1 Item 4 / BS-01 §Session & Token Lifecycle)
    # Spec: 'refresh_token_delivery' 또는 'HttpOnly Cookie' 또는 '환경별 차등'
    # Code: src/routers/auth.py 에 cookie helper (_set_refresh_cookie / REFRESH_COOKIE_NAME) 존재
    delivery_in_spec = bool(
        re.search(
            r"refresh_token_delivery|HttpOnly\s*Cookie|환경별\s*(?:차등|조건부)",
            spec_text,
        )
    )
    router_path = REPO / "team2-backend" / "src" / "routers" / "auth.py"
    has_cookie_helper = False
    if router_path.exists():
        rt = _read(router_path)
        has_cookie_helper = bool(
            re.search(r"_set_refresh_cookie|REFRESH_COOKIE_NAME", rt)
        )
    if delivery_in_spec and not has_cookie_helper:
        rep.d2.append(
            DriftItem(
                contract="auth",
                drift_type="D2",
                identifier="refresh_token_delivery cookie helper",
                spec_value="live profile = HttpOnly Cookie (BS-01 SSOT)",
                code_value="auth.py 에 _set_refresh_cookie / REFRESH_COOKIE_NAME 부재",
                note="BS-01 §Session & Token Lifecycle 환경별 차등 미구현",
            )
        )

    rep.scanner_note = (
        "M1 D+1 완결: 5 rules (MAX_FAILED, lock_permanent, blacklist, composite_PK, refresh_delivery). "
        "M2~M10 = 문서 IA 신설 + 슬림화 (별 PR)."
    )
    return rep


# ------------------------------------------------------------------ Output


def render_markdown(reports: list[ContractReport]) -> str:
    lines: list[str] = []
    lines.append("# Spec Drift Report")
    lines.append("")
    lines.append("| Contract | D1 | D2 | D3 | D4 | Total | Note |")
    lines.append("|---|---:|---:|---:|---:|---:|---|")
    for r in reports:
        lines.append(
            f"| {r.contract} | {len(r.d1)} | {len(r.d2)} | {len(r.d3)} | "
            f"{r.d4_count} | {r.total} | {r.scanner_note} |"
        )
    lines.append("")
    for r in reports:
        if not (r.d1 or r.d2 or r.d3):
            continue
        lines.append(f"## {r.contract}")
        lines.append("")
        for group_name, items in (
            ("D1 (값 불일치)", r.d1),
            ("D2 (기획 有 / 코드 無)", r.d2),
            ("D3 (기획 無 / 코드 有)", r.d3),
        ):
            if not items:
                continue
            lines.append(f"### {group_name}")
            lines.append("")
            lines.append("| ID | 기획 | 코드 | 비고 |")
            lines.append("|---|---|---|---|")
            for it in items:
                lines.append(
                    f"| `{it.identifier}` | {it.spec_value or '—'} | "
                    f"{it.code_value or '—'} | {it.note} |"
                )
            lines.append("")
    return "\n".join(lines)


def render_json(reports: list[ContractReport]) -> str:
    out = []
    for r in reports:
        out.append({
            "contract": r.contract,
            "d1": [asdict(x) for x in r.d1],
            "d2": [asdict(x) for x in r.d2],
            "d3": [asdict(x) for x in r.d3],
            "d4_count": r.d4_count,
            "total": r.total,
            "scanner_note": r.scanner_note,
        })
    return json.dumps(out, indent=2, ensure_ascii=False)


# ------------------------------------------------------------------ Main


DETECTORS = {
    "api": detect_api,
    "events": detect_events,
    "fsm": detect_fsm,
    "schema": detect_schema,
    "rfid": detect_rfid,
    "settings": detect_settings,
    "websocket": detect_websocket,
    "auth": detect_auth,
}


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--api", action="store_true")
    ap.add_argument("--events", action="store_true")
    ap.add_argument("--fsm", action="store_true")
    ap.add_argument("--schema", action="store_true")
    ap.add_argument("--rfid", action="store_true")
    ap.add_argument("--settings", action="store_true")
    ap.add_argument("--websocket", action="store_true")
    ap.add_argument("--auth", action="store_true")
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--format", choices=("markdown", "json"), default="markdown")
    args = ap.parse_args(argv)

    selected: list[str] = []
    if args.all:
        selected = list(DETECTORS.keys())
    else:
        for k in DETECTORS:
            if getattr(args, k, False):
                selected.append(k)
    if not selected:
        ap.print_help()
        return 1

    reports = [DETECTORS[k]() for k in selected]

    if args.format == "json":
        print(render_json(reports))
    else:
        print(render_markdown(reports))
    return 0


if __name__ == "__main__":
    sys.exit(main())
