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
    spec_set: set[tuple[str, str]] = set()
    for m in spec_pat.finditer(spec_text):
        method = m.group(1).upper()
        raw_path = m.group(2)
        # 잡음: / 로만 끝나는 경로 또는 너무 짧은 경로
        if len(raw_path) < 2:
            continue
        spec_set.add((method, _normalize_path(raw_path)))

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
        f"scanned {len(spec_set)} spec endpoints / {len(code_set)} code endpoints. "
        "정규식 기반 best-effort."
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


def detect_schema() -> ContractReport:
    """DB 스키마 drift — Schema.md ↔ init.sql / migrations."""
    rep = ContractReport(contract="schema")
    schema_doc = (
        REPO / "docs" / "2. Development" / "2.2 Backend" / "Database" / "Schema.md"
    )
    init_sql = REPO / "team2-backend" / "src" / "db" / "init.sql"
    if not schema_doc.exists() or not init_sql.exists():
        rep.scanner_note = "Schema.md 또는 init.sql 없음"
        return rep

    # 기획: ### 테이블 `foo_bar` 패턴 또는 CREATE TABLE
    spec_text = _read(schema_doc)
    code_text = _read(init_sql)

    spec_tables = set(
        re.findall(r"(?:###?\s+(?:테이블\s+)?|CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?)`?([a-z_][a-z0-9_]*)`?",
                   spec_text)
    )
    # 잡음 제거 (일반 단어)
    _noise = {
        "string", "integer", "boolean", "timestamp", "id", "type", "status",
        "value", "bigint", "text", "varchar", "primary", "foreign", "default",
        "null", "cascade",
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
        # 그러나 Schema.md 에는 staff, operator 등 미구현 테이블도 포함될 수 있음
        rep.d2.append(
            DriftItem(
                contract="schema",
                drift_type="D2",
                identifier=t,
                spec_value=f"table {t}",
                note="기획에만 존재 (미구현 또는 정규식 false positive)",
            )
        )
    rep.d4_count = len(spec_tables & code_tables)
    rep.scanner_note = (
        f"spec tables={len(spec_tables)} code tables={len(code_tables)}. "
        "정규식이 본문 inline code (`table_name`) 도 추출하므로 false positive 가능."
    )
    return rep


def detect_rfid() -> ContractReport:
    """RFID HAL 시그니처 drift — RFID_HAL_Interface.md ↔ i_rfid_reader.dart."""
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

    # 코드에서 onXxx stream 과 Future 메서드 추출
    code_streams = set(
        re.findall(r"Stream<[^>]+>\s+get\s+(on\w+)", code_text)
    )
    code_methods = set(
        re.findall(r"Future<[^>]*>\s+(\w+)\s*\(", code_text)
    )
    # 기획에서 같은 이름 grep
    spec_streams = {s for s in code_streams if s in spec_text}
    spec_methods = {m for m in code_methods if m in spec_text}

    for s in sorted(code_streams - spec_streams):
        rep.d3.append(
            DriftItem(
                contract="rfid",
                drift_type="D3",
                identifier=f"stream:{s}",
                code_value=f"Stream {s}",
                note="RFID_HAL_Interface.md 에 언급 없음",
            )
        )
    for m in sorted(code_methods - spec_methods):
        rep.d3.append(
            DriftItem(
                contract="rfid",
                drift_type="D3",
                identifier=f"method:{m}",
                code_value=f"Future {m}(...)",
                note="RFID_HAL_Interface.md 에 언급 없음",
            )
        )
    rep.d4_count = len(spec_streams) + len(spec_methods)
    rep.scanner_note = (
        f"code streams={len(code_streams)} methods={len(code_methods)}. "
        "정방향 (코드→문서) 매치만 — 반대 방향 (문서 설명된 미구현 API) 은 미커버."
    )
    return rep


def detect_settings() -> ContractReport:
    """Settings 필드 drift — Settings.md ↔ migration 0005."""
    rep = ContractReport(contract="settings")
    doc = (
        REPO
        / "docs"
        / "2. Development"
        / "2.4 Command Center"
        / "Settings.md"
    )
    migration = (
        REPO
        / "team2-backend"
        / "migrations"
        / "versions"
        / "0005_decks_and_settings_kv.py"
    )
    if not doc.exists() or not migration.exists():
        rep.scanner_note = "경로 없음"
        return rep
    spec_text = _read(doc)
    code_text = _read(migration)

    # 기획: ### 탭명 아래 | 필드명 | 타입 | 형식 테이블
    spec_keys = set(
        re.findall(
            r"\|\s*`([a-z][a-z_0-9\.]*)`",
            spec_text,
        )
    )
    # 코드: CheckConstraint("key IN ('foo', 'bar')") 또는 settings_kv 초기값
    code_keys = set(re.findall(r"'([a-z][a-z_0-9\.]*)'", code_text))
    # scope 제약 필터
    _noise = {
        "global", "series", "event", "table", "string", "int", "json", "bool",
        "hand", "op", "sa",
    }
    spec_keys = {k for k in spec_keys if k not in _noise and "." in k or len(k) > 4}
    code_keys = {k for k in code_keys if "." in k}

    for k in sorted(code_keys - spec_keys):
        rep.d3.append(
            DriftItem(
                contract="settings",
                drift_type="D3",
                identifier=k,
                code_value=k,
                note="Settings.md 에 언급 없음",
            )
        )
    for k in sorted(spec_keys - code_keys):
        rep.d2.append(
            DriftItem(
                contract="settings",
                drift_type="D2",
                identifier=k,
                spec_value=k,
                note="migration 에 미반영",
            )
        )
    rep.d4_count = len(spec_keys & code_keys)
    rep.scanner_note = (
        f"spec keys={len(spec_keys)} code keys={len(code_keys)}. "
        "후속 개선: 탭별 스코프 분리 + CheckConstraint 파싱."
    )
    return rep


def detect_websocket() -> ContractReport:
    """WebSocket event drift — WebSocket_Events.md ↔ team2 websocket handlers.

    간이 스캐너: stub. 후속 구현 예정.
    """
    rep = ContractReport(contract="websocket")
    rep.scanner_note = "stub — 후속 구현. WebSocket_Events.md §4 event catalog ↔ websocket/*.py 비교 예정."
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
