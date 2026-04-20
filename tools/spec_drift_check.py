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
    spec_set_all: set[tuple[str, str]] = set()
    for m in spec_pat.finditer(spec_text):
        method = m.group(1).upper()
        raw_path = m.group(2)
        # 잡음: / 로만 끝나는 경로 또는 너무 짧은 경로
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

    for method, path in sorted(only_in_code):
        # D3: code only, undocumented
        if path.startswith("/api/v1"):
            stripped = path.replace("/api/v1", "", 1)
            if (method, stripped) in spec_set:
                # 경로 prefix만 빠진 문서 — D1 (값 불일치)
                rep.d1.append(
                    DriftItem(
                        contract="api",
                        drift_type="D1",
                        identifier=f"{method} {path}",
                        spec_value=f"{method} {stripped}",
                        code_value=f"{method} {path}",
                        note="문서에 /api/v1 prefix 누락",
                    )
                )
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
            # 이미 D1으로 처리됨 — skip
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

    rep.d4_count = len(shared)
    rep.scanner_note = (
        f"scanned {len(spec_set)} spec endpoints "
        f"(+ {len(wsop_native_skipped)} WSOP-native refs skipped) / "
        f"{len(code_set)} code endpoints. 정규식 기반 best-effort."
    )
    return rep


def _normalize_path(path: str) -> str:
    """FastAPI `{id}` ↔ 문서 `:id` 차이 흡수."""
    path = re.sub(r":([A-Za-z_]+)", r"{\1}", path)
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

    # HandFSM enum — team3 engine: check state machine files
    engine_state = (
        REPO / "team3-engine" / "ebs_game_engine" / "lib" / "core" / "state"
    )
    engine_state_text = ""
    if engine_state.exists():
        for f in engine_state.rglob("*.dart"):
            engine_state_text += _read(f) + "\n"

    # TableFSM 검증 (init.sql / routers)
    init_sql = REPO / "team2-backend" / "src" / "db" / "init.sql"
    init_sql_text = _read(init_sql) if init_sql.exists() else ""
    routers_text = ""
    routers_dir = REPO / "team2-backend" / "src" / "routers"
    if routers_dir.exists():
        for f in routers_dir.glob("*.py"):
            routers_text += _read(f) + "\n"

    for fsm_name, spec_states in fsms.items():
        # TableFSM 은 스키마 / init.sql 에 나타남. 코드는 lowercase 사용.
        if "TableFSM" in fsm_name:
            # case-insensitive 비교 — 코드가 lowercase 이면 D1 (값 불일치)
            code_states_raw = set(
                re.findall(
                    r"'(empty|setup|live|paused|closed|EMPTY|SETUP|LIVE|PAUSED|CLOSED)'",
                    init_sql_text + routers_text,
                )
            )
            code_states_upper = {s.upper() for s in code_states_raw}
            # D1 감지 — 값은 존재하지만 case 가 다름
            if code_states_raw and code_states_raw != {s.upper() for s in code_states_raw}:
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
            _diff_states(rep, fsm_name, spec_states, code_states_upper, "table_status")
        elif "HandFSM" in fsm_name:
            # engine GameState game_phase 열거. lowerCamelCase 사용 경향
            code_states = set()
            for st in ("IDLE", "SETUP_HAND", "PRE_FLOP", "FLOP", "TURN",
                       "RIVER", "SHOWDOWN", "HAND_COMPLETE", "RUN_IT_MULTIPLE"):
                aliases = [st, st.lower(), _to_camel(st)]
                if any(a in engine_state_text for a in aliases):
                    code_states.add(st)
            _diff_states(rep, fsm_name, spec_states, code_states,
                         "engine lib/core/state")
        elif "SeatFSM" in fsm_name:
            code_states_raw = set(
                re.findall(
                    r"'(empty|new|playing|moved|busted|reserved|occupied|waiting|hold)'",
                    init_sql_text,
                )
            )
            code_states_upper = {s.upper() for s in code_states_raw}
            _diff_states(rep, fsm_name, spec_states, code_states_upper, "seats CHECK")
        else:
            # 그 외 FSM 은 CODE 참조 소유 팀이 불명확 — d4 로 간주하지 않고 noted
            continue

    rep.scanner_note = (
        f"checked {sum(1 for k in fsms if 'TableFSM' in k or 'HandFSM' in k)} "
        "of %d FSMs (TableFSM/HandFSM 대표)" % len(fsms)
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
            # 파일명이 Settings 또는 6탭 중 하나인 경우만
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

    # 기획: backtick-wrapped identifier — camelCase / snake_case 모두 가능
    # 문서는 주로 인간 설명 스타일이라 매우 noisy. 다음 휴리스틱으로 필터.
    spec_candidates = set(
        re.findall(
            r"`([a-zA-Z_][a-zA-Z0-9_]{2,})`",
            spec_text,
        )
    )

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
    """WebSocket event drift — WebSocket_Events.md §event catalog ↔ team2 websocket handlers.

    R1-b 구현: 문서 §4 이벤트 카탈로그에서 event type 이름 추출.
    코드측은 `{ "type": "EventName", ... }` 패턴 추출.
    """
    rep = ContractReport(contract="websocket")
    doc = (
        REPO / "docs" / "2. Development" / "2.2 Backend" / "APIs" / "WebSocket_Events.md"
    )
    ws_dir = REPO / "team2-backend" / "src" / "websocket"

    if not doc.exists():
        rep.scanner_note = "WebSocket_Events.md 없음"
        return rep
    if not ws_dir.exists():
        rep.scanner_note = "team2 websocket/ 경로 없음 — code source not found"
        return rep

    spec_text = _read(doc)
    # 기획: backtick-wrapped event type 이름 — `event_flight_summary`, `clock_tick` 등
    # snake_case 또는 PascalCase 둘 다 등장 (Ack, Error, HandStarted, clock_tick)
    # 테이블 형태 `| event_name | ...` 와 인라인 참조 모두 포착
    spec_events = set(
        re.findall(
            r"`([A-Za-z][A-Za-z0-9_]{2,})`",
            spec_text,
        )
    )
    # 이벤트형 이름 휴리스틱: 소문자_snake 또는 PascalCase 로 시작
    def _looks_like_event(name: str) -> bool:
        if len(name) < 3:
            return False
        # 제외: SQL 예약어, 일반 단어
        _noise = {
            "type", "name", "value", "status", "token", "key", "id", "data",
            "role", "true", "false", "null", "seq", "version", "envelope",
            "ts", "timestamp", "payload", "from", "to", "this", "that",
            "string", "int", "bool", "event", "message", "table",
            "API-04", "API-05",
        }
        if name.lower() in {n.lower() for n in _noise}:
            return False
        # snake_case: 2어 이상 또는 이름 끝이 event 류
        if "_" in name and name.islower():
            return True
        # PascalCase: 첫 글자 대문자 + 다른 대문자 또는 길이 8+
        if name[0].isupper() and any(c.isupper() for c in name[1:]):
            return True
        if name[0].isupper() and len(name) >= 8:
            return True
        return False

    spec_events = {e for e in spec_events if _looks_like_event(e)}

    # 코드: "type": "EventName" 패턴
    code_events: set[str] = set()
    type_pat = re.compile(r'["\']type["\']\s*:\s*["\']([A-Za-z_][A-Za-z0-9_]*)["\']')
    for py in ws_dir.glob("*.py"):
        text = _read(py)
        for m in type_pat.finditer(text):
            code_events.add(m.group(1))

    if not code_events:
        rep.scanner_note = (
            "code source found but no event types extracted — "
            "detector returns empty (수동 확인 필요)"
        )
        return rep

    # Diff — spec 기준 후보군에서 code 와 비교
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
    # spec-only 는 후보군이 noisy 할 수 있어 "관심 리스트" 만 표시
    # (backtick snake_case 이면서 code 에 없는 것)
    for e in sorted(spec_events - code_events):
        # snake_case 만 D2 로. PascalCase 는 후보가 너무 많음
        if "_" in e and e.islower():
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
        f"spec candidates={len(spec_events)} code events={len(code_events)}. "
        "spec 측 backtick 휴리스틱이라 false positive 가능."
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
