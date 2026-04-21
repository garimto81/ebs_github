#!/usr/bin/env python3
"""Naming Convention Check — WSOP LIVE 규약 자동 검증 (B-088 PR-9).

목적:
  `docs/2. Development/2.5 Shared/Naming_Conventions.md` v2 가 선언한 4개 표면
  (WS event type / JSON field / REST path / Path variable) 이 코드 전반에서
  지켜지는지 정규식 기반 best-effort 스캔으로 검증한다.

검사 대상:
  1. WS event type        — PascalCase  — team2 `"type": "..."` literal
  2. JSON field (Freezed) — camelCase   — team1/team4 `@JsonKey(name: '...')`
  3. REST path            — PascalCase  — team2 `@router.<method>("/...")` decorator
  4. Path variable        — camelCase   — REST path `{...}` placeholder

예외:
  `tools/naming_check.exceptions.yaml` 를 읽어 allow-list 로 스킵.
  파일 없으면 빈 allow-list 로 동작.

Usage:
  python tools/naming_check.py                    # 전 범위, warning 모드
  python tools/naming_check.py --team team2
  python tools/naming_check.py --ws
  python tools/naming_check.py --json-field
  python tools/naming_check.py --rest
  python tools/naming_check.py --pathvar
  python tools/naming_check.py --all --format=json
  python tools/naming_check.py --strict          # 위반 1개라도 있으면 exit 1 (CI gate)

CI 게이트 활성화 시점:
  B-088 PR 1-8 전수 마이그레이션 완료 후. 그 전에는 warning (exit 0) 으로 유지.

한계:
  - 정규식 기반 — 동적 생성 이벤트/경로, 주석 처리된 선언은 누락 가능
  - `.freezed.dart` 생성물은 제외 (source `.dart` 만 검사)
  - 테스트 fixture (`tests/`, `test/`, `_test.dart`, `mock_*`) 는 별도 처리

Exit code:
  0 — 실행 성공 (warning 모드는 violation 있어도 0)
  1 — --strict 모드에서 violation 존재
  2 — 스캐너 자체 오류 (파일 접근, 파싱 실패 등)
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass, field, asdict
from pathlib import Path
from typing import Iterable

try:
    import yaml  # PyYAML 6.x (tools/requirements.txt 에 추가)
except ImportError:
    yaml = None  # type: ignore

REPO = Path(__file__).resolve().parents[1]
EXCEPTIONS_FILE = REPO / "tools" / "naming_check.exceptions.yaml"

# ---------------------------------------------------------------- Models


@dataclass
class Violation:
    """단일 네이밍 위반 항목."""

    rule: str        # ws_event | json_field | rest_path | path_variable
    team: str        # team1 | team2 | team3 | team4 | conductor
    file: str        # repo-relative path
    line: int
    identifier: str  # 위반된 실제 값
    expected: str    # 기대 형식 예시
    suggestion: str = ""  # 교정 제안


@dataclass
class Report:
    rule: str
    violations: list[Violation] = field(default_factory=list)
    scanned_files: int = 0
    scanner_note: str = ""

    @property
    def count(self) -> int:
        return len(self.violations)


# ---------------------------------------------------------------- Casing helpers


_SNAKE_RE = re.compile(r"^[a-z][a-z0-9_]*$")
_KEBAB_RE = re.compile(r"^[a-z][a-z0-9]*(-[a-z0-9]+)+$")
_CAMEL_RE = re.compile(r"^[a-z][a-zA-Z0-9]*$")
_PASCAL_RE = re.compile(r"^[A-Z][a-zA-Z0-9]*$")


def is_snake_case(s: str) -> bool:
    return bool(_SNAKE_RE.match(s)) and "_" in s


def is_kebab_case(s: str) -> bool:
    return bool(_KEBAB_RE.match(s))


def is_camel_case(s: str) -> bool:
    return bool(_CAMEL_RE.match(s)) and not s.islower()  # 최소 1개 대문자 (camelHump)


def is_pure_lower(s: str) -> bool:
    """단일 단어 소문자 (예: 'access', 'health') — 예외 판정용."""
    return s.islower() and "_" not in s and "-" not in s


def is_pascal_case(s: str) -> bool:
    return bool(_PASCAL_RE.match(s)) and any(c.isupper() for c in s[1:] + s[0])


def snake_to_camel(s: str) -> str:
    parts = s.split("_")
    return parts[0] + "".join(p.capitalize() for p in parts[1:])


def snake_to_pascal(s: str) -> str:
    return "".join(p.capitalize() for p in s.split("_"))


def kebab_to_pascal(s: str) -> str:
    return "".join(p.capitalize() for p in s.split("-"))


# ---------------------------------------------------------------- Exceptions


def load_exceptions() -> dict:
    """allow-list 로드. yaml 모듈 없거나 파일 없으면 빈 dict."""
    if yaml is None or not EXCEPTIONS_FILE.exists():
        return {}
    try:
        data = yaml.safe_load(EXCEPTIONS_FILE.read_text(encoding="utf-8")) or {}
        # 기본 키 보장
        return {
            "allow_ws_events": set(data.get("allow_ws_events", [])),
            "allow_json_keys": set(data.get("allow_json_keys", [])),
            "allow_rest_paths": set(data.get("allow_rest_paths", [])),
            "allow_path_variables": set(data.get("allow_path_variables", [])),
            "skip_files": set(data.get("skip_files", [])),
        }
    except Exception as e:  # pragma: no cover
        print(f"[warn] exceptions 파일 파싱 실패: {e}", file=sys.stderr)
        return {}


# ---------------------------------------------------------------- Detectors


def _team_from_path(path: Path) -> str:
    parts = path.parts
    for p in parts:
        if p.startswith("team1"):
            return "team1"
        if p.startswith("team2"):
            return "team2"
        if p.startswith("team3"):
            return "team3"
        if p.startswith("team4"):
            return "team4"
    return "conductor"


def _iter_source_files(base: Path, patterns: tuple[str, ...], skip: set[str]) -> Iterable[Path]:
    for pat in patterns:
        for path in base.rglob(pat):
            rel = str(path.relative_to(REPO)).replace("\\", "/")
            if any(rel.startswith(s) or s in rel for s in skip):
                continue
            # generated Freezed / mock / build artifacts 제외
            if path.name.endswith(".freezed.dart"):
                continue
            if path.name.endswith(".g.dart"):
                continue
            if "/build/" in rel or "\\build\\" in rel:
                continue
            if "__pycache__" in rel:
                continue
            yield path


# ----- Rule 1: WS event type (PascalCase)

_WS_TYPE_LITERAL = re.compile(r'"type"\s*:\s*"([A-Za-z_][A-Za-z0-9_]*)"')


def detect_ws_events(exc: dict) -> Report:
    """team2 Python 에서 `"type": "..."` WebSocket envelope literal 검출."""
    rep = Report(rule="ws_event")
    allow = exc.get("allow_ws_events", set())
    skip = exc.get("skip_files", set())

    base = REPO / "team2-backend" / "src"
    if not base.exists():
        rep.scanner_note = "team2-backend/src 없음"
        return rep

    for path in _iter_source_files(base, ("*.py",), skip):
        # 테스트/security/jwt 는 JWT 타입 (access/refresh) 이라 allow 해야 함 — exceptions 로
        text = path.read_text(encoding="utf-8", errors="replace")
        rep.scanned_files += 1
        for lineno, line in enumerate(text.splitlines(), 1):
            for m in _WS_TYPE_LITERAL.finditer(line):
                val = m.group(1)
                if val in allow:
                    continue
                # 단일 소문자 단어 (access/refresh/password_reset 등)는 JWT 관행이라 exception
                # 하지만 exception 에 명시되지 않으면 여전히 위반 — 사용자가 allow 로 등록해야 함
                if is_pascal_case(val):
                    continue
                expected = "PascalCase (예: HandStarted, ClockTick)"
                if is_snake_case(val):
                    suggestion = snake_to_pascal(val)
                elif is_pure_lower(val):
                    suggestion = val.capitalize()
                else:
                    suggestion = ""
                rep.violations.append(Violation(
                    rule="ws_event",
                    team=_team_from_path(path),
                    file=str(path.relative_to(REPO)).replace("\\", "/"),
                    line=lineno,
                    identifier=val,
                    expected=expected,
                    suggestion=suggestion,
                ))
    return rep


# ----- Rule 2: JSON field via Freezed @JsonKey(name: '...')

_JSON_KEY_RE = re.compile(r"""@JsonKey\(\s*name\s*:\s*['"]([^'"]+)['"]""")


def detect_json_fields(exc: dict) -> Report:
    """team1/team4 Freezed `@JsonKey(name: '...')` — camelCase 만 허용."""
    rep = Report(rule="json_field")
    allow = exc.get("allow_json_keys", set())
    skip = exc.get("skip_files", set())

    targets = [
        REPO / "team1-frontend" / "lib",
        REPO / "team4-cc" / "lib",
    ]
    for base in targets:
        if not base.exists():
            continue
        for path in _iter_source_files(base, ("*.dart",), skip):
            text = path.read_text(encoding="utf-8", errors="replace")
            rep.scanned_files += 1
            for lineno, line in enumerate(text.splitlines(), 1):
                for m in _JSON_KEY_RE.finditer(line):
                    val = m.group(1)
                    if val in allow:
                        continue
                    # camelCase 또는 단일 소문자 (ex. 'id', 'key') 허용
                    if is_camel_case(val) or (is_pure_lower(val) and val.isalpha()):
                        continue
                    expected = "camelCase (예: eventFlightId, tableCount)"
                    suggestion = snake_to_camel(val) if is_snake_case(val) else ""
                    rep.violations.append(Violation(
                        rule="json_field",
                        team=_team_from_path(path),
                        file=str(path.relative_to(REPO)).replace("\\", "/"),
                        line=lineno,
                        identifier=val,
                        expected=expected,
                        suggestion=suggestion,
                    ))
    return rep


# ----- Rule 3 & 4: REST path + path variable

_ROUTER_DECOR_RE = re.compile(
    r"""@(?:\w+\.)?router\.(?:get|post|put|patch|delete|head|options)\(\s*['"]([^'"]+)['"]"""
)


def detect_rest_paths(exc: dict) -> tuple[Report, Report]:
    """team2 FastAPI router decorator 에서 REST path + path variable 검출."""
    rep_path = Report(rule="rest_path")
    rep_var = Report(rule="path_variable")
    allow_path = exc.get("allow_rest_paths", set())
    allow_var = exc.get("allow_path_variables", set())
    skip = exc.get("skip_files", set())

    base = REPO / "team2-backend" / "src" / "routers"
    if not base.exists():
        rep_path.scanner_note = "team2-backend/src/routers 없음"
        rep_var.scanner_note = rep_path.scanner_note
        return rep_path, rep_var

    for path in _iter_source_files(base, ("*.py",), skip):
        text = path.read_text(encoding="utf-8", errors="replace")
        rep_path.scanned_files += 1
        rep_var.scanned_files += 1
        for lineno, line in enumerate(text.splitlines(), 1):
            for m in _ROUTER_DECOR_RE.finditer(line):
                full_path = m.group(1)
                if full_path in allow_path:
                    continue
                # segment 단위로 검사. path variable `{...}` 은 별도 검사
                segments = [s for s in full_path.split("/") if s]
                bad_segments = []
                for seg in segments:
                    if seg.startswith("{") and seg.endswith("}"):
                        var = seg[1:-1]
                        if var in allow_var:
                            continue
                        if not is_camel_case(var) and not (is_pure_lower(var) and var.isalpha()):
                            suggestion = snake_to_camel(var) if is_snake_case(var) else ""
                            rep_var.violations.append(Violation(
                                rule="path_variable",
                                team="team2",
                                file=str(path.relative_to(REPO)).replace("\\", "/"),
                                line=lineno,
                                identifier=var,
                                expected="camelCase (예: eventFlightId)",
                                suggestion=suggestion,
                            ))
                        continue
                    # path segment 자체 검사
                    # 허용: PascalCase, 또는 단일 소문자 (health, metrics, api, v1 등)
                    if is_pascal_case(seg):
                        continue
                    if is_pure_lower(seg) and seg.isalnum():
                        continue  # 'api', 'v1', 'health' 등
                    bad_segments.append(seg)
                if bad_segments:
                    expected = "PascalCase segment (예: /HandHistory, /BlindStructures)"
                    hints = []
                    for bs in bad_segments:
                        if is_kebab_case(bs):
                            hints.append(f"{bs}→{kebab_to_pascal(bs)}")
                        elif is_snake_case(bs):
                            hints.append(f"{bs}→{snake_to_pascal(bs)}")
                    suggestion = ", ".join(hints)
                    rep_path.violations.append(Violation(
                        rule="rest_path",
                        team="team2",
                        file=str(path.relative_to(REPO)).replace("\\", "/"),
                        line=lineno,
                        identifier=full_path,
                        expected=expected,
                        suggestion=suggestion,
                    ))
    return rep_path, rep_var


# ---------------------------------------------------------------- Output


def _print_human(reports: list[Report]) -> None:
    print("=" * 70)
    print("EBS Naming Convention Check (B-088 PR-9)")
    print(f"SSOT: docs/2. Development/2.5 Shared/Naming_Conventions.md v2")
    print("=" * 70)
    total = 0
    for rep in reports:
        if rep.scanner_note:
            print(f"\n[{rep.rule}] (스캔 불가) {rep.scanner_note}")
            continue
        icon = "✅" if rep.count == 0 else "❌"
        print(f"\n{icon} [{rep.rule}] scanned={rep.scanned_files} files, violations={rep.count}")
        total += rep.count
        # 파일별 그룹핑
        by_file: dict[str, list[Violation]] = {}
        for v in rep.violations:
            by_file.setdefault(v.file, []).append(v)
        for file, vs in sorted(by_file.items()):
            print(f"\n  {file}")
            for v in vs[:10]:  # 파일당 최대 10건
                arrow = f" → {v.suggestion}" if v.suggestion else ""
                print(f"    L{v.line}: '{v.identifier}'{arrow}")
                print(f"           expected: {v.expected}")
            if len(vs) > 10:
                print(f"    ... (+ {len(vs) - 10} 건)")
    print()
    print("=" * 70)
    print(f"총 위반: {total}")
    print("=" * 70)
    if total > 0:
        print("\n[Hint] 교정 방법:")
        print("  - WS event: team2 publisher + team1 ws_dispatch.dart 동시 수정 (B-088 PR-3/6)")
        print("  - JSON field: Pydantic alias_generator=to_camel 전역 (team2 PR-2) + Freezed @JsonKey (team1/4 PR-5/7)")
        print("  - REST path: router decorator + Frontend Repository 경로 동시 수정 (PR-4/6)")
        print("  - 예외: tools/naming_check.exceptions.yaml 에 allow 등록")


def _to_json(reports: list[Report]) -> str:
    out = []
    for rep in reports:
        out.append({
            "rule": rep.rule,
            "scanned_files": rep.scanned_files,
            "violations": [asdict(v) for v in rep.violations],
            "count": rep.count,
            "scanner_note": rep.scanner_note,
        })
    return json.dumps({"reports": out, "total": sum(r.count for r in reports)}, indent=2, ensure_ascii=False)


# ---------------------------------------------------------------- CLI


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    p.add_argument("--ws", action="store_true", help="WS event type 만 검사")
    p.add_argument("--json-field", action="store_true", help="JSON field (@JsonKey) 만 검사")
    p.add_argument("--rest", action="store_true", help="REST path + path variable 검사")
    p.add_argument("--pathvar", action="store_true", help="path variable 만 (REST 와 함께 동작)")
    p.add_argument("--all", action="store_true", help="전 범위 (기본값)")
    p.add_argument("--team", choices=("team1", "team2", "team3", "team4", "conductor", "all"),
                   default="all", help="특정 팀으로 violation 필터")
    p.add_argument("--format", choices=("human", "json"), default="human")
    p.add_argument("--strict", action="store_true", help="violation > 0 이면 exit 1 (CI gate)")
    args = p.parse_args(argv)

    # 기본: 전 범위. 개별 flag 지정 시 해당만
    run_ws = args.ws or args.all or (not any((args.ws, args.json_field, args.rest, args.pathvar)))
    run_json = args.json_field or args.all or (not any((args.ws, args.json_field, args.rest, args.pathvar)))
    run_rest = args.rest or args.pathvar or args.all or (not any((args.ws, args.json_field, args.rest, args.pathvar)))

    exc = load_exceptions()
    reports: list[Report] = []

    if run_ws:
        reports.append(detect_ws_events(exc))
    if run_json:
        reports.append(detect_json_fields(exc))
    if run_rest:
        rep_path, rep_var = detect_rest_paths(exc)
        reports.append(rep_path)
        reports.append(rep_var)

    # team 필터
    if args.team != "all":
        for rep in reports:
            rep.violations = [v for v in rep.violations if v.team == args.team]

    if args.format == "json":
        print(_to_json(reports))
    else:
        _print_human(reports)

    total = sum(r.count for r in reports)
    if args.strict and total > 0:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
