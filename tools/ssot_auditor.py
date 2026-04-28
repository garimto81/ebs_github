"""SSOT Auditor — SG-022 (단일 Desktop) → Multi-Service Docker 정합성 검증기.

2026-04-27 — Conductor SSOT alignment cascade.

목적:
    워크스페이스 전반에서 폐기된 SG-022 (단일 Desktop 바이너리) 인텐트를
    옹호(advocacy) 하는 잔재 문구를 검출. 정당한 historical/deprecation
    reference 는 allowlist 로 통과.

키워드 (legacy):
    "단일 데스크탑", "단일 데스크톱", "Single Desktop", "단일 앱",
    "단일 바이너리", "SG-022", "Lobby + CC 통합", "app_router.dart 통합"

Allowlist 원칙 (legitimate historical reference 보존):
    1. File-path allowlist — 이 파일은 본질적으로 "폐기 기록" 임:
        - docs/4. Operations/Conductor_Backlog/SG-022-deprecation.md
        - docs/4. Operations/MULTI_SESSION_DOCKER_HANDOFF.md
        - docs/4. Operations/GLOBAL_SSOT_SYNC_HANDOFF.md
        - tools/ssot_auditor.py (자기 자신)
    2. Line-context markers — 같은 줄에 deprecation 표지 등장 시 PASS:
        SUPERSEDED, 폐기, deprecat, REMOVED, supersedes, REACTIVATED,
        REVERTED, 역사, history, archive, 폐기 cascade, [구버전], [DEPRECATED]
    3. Adjacent-context markers — ±5 줄 내에 deprecation 표지 PASS

사용법:
    python tools/ssot_auditor.py --scan          # 인간 가독 보고
    python tools/ssot_auditor.py --scan --json   # 기계 가독 (JSON)
    python tools/ssot_auditor.py --scan --strict # allowlist 무시 (전수)
    python tools/ssot_auditor.py --scan --report report.json  # 파일 출력

종료 코드:
    0 — 위반 0건 (Gatekeeper PASS)
    1 — 위반 발견 (Gatekeeper FAIL)
    2 — 사용 오류 (인자 등)
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Iterator

# ─────────────────────────────────────────────────────────────────────────────
# 설정
# ─────────────────────────────────────────────────────────────────────────────

REPO_ROOT = Path(__file__).resolve().parent.parent

# 스캔 대상 디렉토리 (REPO_ROOT 기준 상대)
SCAN_DIRS = [
    "docs",
    "team1-frontend",
    "team2-backend",
    "team3-engine",
    "team4-cc",
]

# 스캔 대상 확장자
SCAN_EXTENSIONS = {".md", ".json", ".yaml", ".yml"}

# 항상 제외 (코드 빌드 산출물 / 의존성 / 아카이브 / venv)
EXCLUDE_DIRS = {
    "node_modules",
    ".dart_tool",
    "build",
    ".git",
    ".venv",
    "venv",
    "__pycache__",
    "_archive-quasar",
    "ebs-archive-backup",
    "_generated",          # CI 자동 생성 (수정 금지)
    ".claude",             # 세션 메타
}

# 키워드: (display_name, regex_pattern, ignorecase)
KEYWORDS: list[tuple[str, str, bool]] = [
    ("단일 데스크탑",      r"단일\s*데스크탑",     False),
    ("단일 데스크톱",      r"단일\s*데스크톱",     False),
    ("Single Desktop",    r"Single\s+Desktop",    True),
    ("단일 앱",           r"단일\s*앱",           False),
    ("단일 바이너리",      r"단일\s*바이너리",      False),
    ("SG-022",            r"SG-022",              False),
    ("Lobby + CC 통합",   r"Lobby\s*\+\s*CC\s*통합", False),
    ("app_router.dart 통합", r"app_router\.dart\s*통합", False),
]

# Allowlist 1a: 파일 경로 정확 일치 (REPO_ROOT 기준 forward-slash) — 본질적 폐기 기록
ALLOWLIST_PATHS = {
    "docs/4. Operations/Conductor_Backlog/SG-022-deprecation.md",
    "docs/4. Operations/MULTI_SESSION_DOCKER_HANDOFF.md",
    "docs/4. Operations/GLOBAL_SSOT_SYNC_HANDOFF.md",
    "docs/4. Operations/Active_Work.md",        # claim metadata (의미상 작업 ledger)
    "docs/4. Operations/Active_Work.md.lock",
    "tools/ssot_auditor.py",
}

# Allowlist 1b: 경로 substring (history/archive 폴더 — 능동 architecture 결정 아님)
ALLOWLIST_PATH_SUBSTRINGS = (
    "/archive/",
    "/done/",
    "/Plans/",                                  # 후행 계획 history
    "/_archive-quasar/",
    "Conductor_Backlog/B-Q",                    # 후속 task ledger (linked-sg refs)
    "Conductor_Backlog/NOTIFY-ALL-",            # cross-team 통지문
    "Conductor_Backlog/SESSION_",               # session init/handoff
    "Conductor_Backlog/V2_PURGE_REPORT",
    "Phase_1_Decision_Queue.md",                # 결정 추적 ledger
    "Spec_Gap_Registry.md",                     # SSOT registry (모든 SG-* row 보유)
)

# Allowlist 2: deprecation/history 표지 (line/context 내 발견 시 PASS)
DEPRECATION_MARKERS = re.compile(
    r"(SUPERSEDED|폐기|deprecat|REMOVED|supersedes|REACTIVATED|REVERTED|"
    r"역사|history|archive|cascade|\[구버전\]|\[DEPRECATED\]|"
    r"이전\s*인텐트|폐기됨|구\s*인텐트|예전|formerly|legacy|"
    r"linked-sg|linked-decision|gap-id|reversal|Multi-Service\s*Docker)",
    flags=re.IGNORECASE,
)

# Allowlist 3: 도메인 컨텍스트 (다른 도메인 — EBS 앱 아키텍처 무관)
# 예: skin-editor 의 .gfskin 컨테이너 비교 ("단일 바이너리" vs "ZIP 아카이브")
DOMAIN_CONTEXT_MARKERS = re.compile(
    r"(\.gfskin|ZIP\s*아카이브|ZIP\s*컨테이너|ZIP\s*archive|"
    r"binary\s*serialization|font\s*binary|protobuf|FlatBuffers)",
    flags=re.IGNORECASE,
)

# 컨텍스트 윈도우 (위반 줄 기준 위/아래 N 줄)
CONTEXT_WINDOW = 5

# ─────────────────────────────────────────────────────────────────────────────
# 데이터 모델
# ─────────────────────────────────────────────────────────────────────────────

@dataclass
class Finding:
    file: str
    line: int
    keyword: str
    text: str          # 위반 줄 원문 (strip)
    context: list[str] = field(default_factory=list)  # ±N 줄 (line# prefix)
    allowlisted: bool = False
    allowlist_reason: str = ""  # "path" | "line-marker" | "context-marker" | ""

# ─────────────────────────────────────────────────────────────────────────────
# 핵심 로직
# ─────────────────────────────────────────────────────────────────────────────

def iter_target_files() -> Iterator[Path]:
    """스캔 대상 파일을 yield."""
    for top in SCAN_DIRS:
        root = REPO_ROOT / top
        if not root.exists():
            continue
        for dirpath, dirnames, filenames in os.walk(root):
            # in-place prune (excluded dirs)
            dirnames[:] = [d for d in dirnames if d not in EXCLUDE_DIRS]
            for fn in filenames:
                if Path(fn).suffix.lower() in SCAN_EXTENSIONS:
                    yield Path(dirpath) / fn


def normalize_rel(path: Path) -> str:
    """REPO_ROOT 기준 forward-slash 정규형."""
    return path.resolve().relative_to(REPO_ROOT).as_posix()


# B-349 §4 (2026-04-28): deprecation shim 인식
# Behavioral_Specs deprecation rollout (PR #19) 후속 — 16 개 BS-06-XX 파일이
# frontmatter `tier: deprecated` + `redirect-to:` 형태로 교체됨. 본 stub 들은
# 키워드 매치 시 false positive 가능성이 있으므로 file-level 에서 통째 skip.
#
# 판정 기준 (AND):
#   1. 파일이 `---` 으로 시작 (frontmatter 존재)
#   2. frontmatter 에 `tier: deprecated` 라인
#   3. frontmatter 에 `redirect-to:` 라인 (도메인 마스터 cross-ref)
#
# strict 모드 (--strict) 에서는 본 우회 비활성화 (allowlist 전체 무시 정책).
def is_deprecation_shim(text: str) -> bool:
    """파일 frontmatter 가 deprecation shim 형태인지 판정.

    True 시 ssot_auditor 는 본 파일의 본문 키워드 검사를 통째로 skip 한다 (file-level).
    legacy-id-redirect.json 의 `audit_hints.deprecation_marker` 정의와 정합.
    """
    if not text.startswith("---"):
        return False
    # 두 번째 `---` 위치 찾기 (frontmatter 종료)
    end = text.find("\n---", 3)
    if end < 0:
        return False
    fm = text[3:end]
    return "tier: deprecated" in fm and "redirect-to:" in fm


def check_allowlist(rel_path: str, line_text: str, context_lines: list[str]) -> tuple[bool, str]:
    """이 violation 이 allowlist 에 해당하는지 판정. (allowed, reason)"""
    if rel_path in ALLOWLIST_PATHS:
        return True, "path"
    for sub in ALLOWLIST_PATH_SUBSTRINGS:
        if sub in rel_path:
            return True, f"path-substring:{sub}"
    if DEPRECATION_MARKERS.search(line_text):
        return True, "line-marker"
    if DOMAIN_CONTEXT_MARKERS.search(line_text):
        return True, "domain-context"
    for ctx in context_lines:
        if DEPRECATION_MARKERS.search(ctx):
            return True, "context-marker"
        if DOMAIN_CONTEXT_MARKERS.search(ctx):
            return True, "domain-context-window"
    return False, ""


def scan_file(path: Path, strict: bool) -> list[Finding]:
    """단일 파일에서 키워드 등장 줄을 수집."""
    rel = normalize_rel(path)
    findings: list[Finding] = []
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except Exception as exc:
        print(f"[WARN] read fail: {rel} — {exc}", file=sys.stderr)
        return findings

    # B-349 §4 (2026-04-28): Deprecation shim 인식 — file-level skip
    # frontmatter `tier: deprecated` + `redirect-to:` 가 있으면 본문 키워드 검사 통째 우회.
    # 16 BS-06-XX deprecation stub (PR #19) 의 false positive 방지.
    # strict 모드에서는 본 우회 비활성화 (allowlist 정책 일관).
    if not strict and is_deprecation_shim(text):
        return findings  # Empty list — 모든 키워드 매치를 통째 PASS

    lines = text.splitlines()
    for idx, line in enumerate(lines):
        for kw_name, pattern, ignorecase in KEYWORDS:
            flags = re.IGNORECASE if ignorecase else 0
            if not re.search(pattern, line, flags):
                continue
            # 컨텍스트 ±N 줄
            ctx_start = max(0, idx - CONTEXT_WINDOW)
            ctx_end = min(len(lines), idx + CONTEXT_WINDOW + 1)
            context = [
                f"{ctx_start + i + 1:5d}: {lines[ctx_start + i]}"
                for i in range(ctx_end - ctx_start)
            ]
            allowed, reason = (False, "") if strict else check_allowlist(rel, line, lines[ctx_start:ctx_end])
            findings.append(Finding(
                file=rel,
                line=idx + 1,
                keyword=kw_name,
                text=line.strip(),
                context=context,
                allowlisted=allowed,
                allowlist_reason=reason,
            ))
    return findings


def scan_all(strict: bool) -> list[Finding]:
    out: list[Finding] = []
    for f in iter_target_files():
        out.extend(scan_file(f, strict=strict))
    return out


# ─────────────────────────────────────────────────────────────────────────────
# 출력
# ─────────────────────────────────────────────────────────────────────────────

def print_human(findings: list[Finding], strict: bool) -> None:
    violations = [f for f in findings if not f.allowlisted]
    allowed = [f for f in findings if f.allowlisted]

    print("=" * 76)
    print(f"SSOT Auditor — strict={strict}, scan dirs={SCAN_DIRS}")
    print(f"  total matches:         {len(findings)}")
    print(f"  allowlisted (PASS):    {len(allowed)}")
    print(f"  violations  (FAIL):    {len(violations)}")
    print("=" * 76)

    if violations:
        print("\n--- VIOLATIONS (active SG-022 advocacy) ---")
        # 파일별 그룹
        by_file: dict[str, list[Finding]] = {}
        for v in violations:
            by_file.setdefault(v.file, []).append(v)
        for fname in sorted(by_file):
            print(f"\n[{fname}]  ({len(by_file[fname])}건)")
            for v in by_file[fname]:
                print(f"  L{v.line:5d}  [{v.keyword}]  {v.text}")
    if allowed and strict is False:
        print("\n--- ALLOWLISTED (historical / deprecation reference) ---")
        by_file: dict[str, list[Finding]] = {}
        for a in allowed:
            by_file.setdefault(a.file, []).append(a)
        for fname in sorted(by_file):
            reasons = {a.allowlist_reason for a in by_file[fname]}
            print(f"  {fname}  ({len(by_file[fname])}건, {','.join(reasons)})")


def print_json(findings: list[Finding], strict: bool, report_path: str | None) -> None:
    payload = {
        "strict": strict,
        "scan_dirs": SCAN_DIRS,
        "total_matches": len(findings),
        "violations": len([f for f in findings if not f.allowlisted]),
        "allowlisted": len([f for f in findings if f.allowlisted]),
        "findings": [asdict(f) for f in findings],
    }
    output = json.dumps(payload, ensure_ascii=False, indent=2)
    if report_path:
        Path(report_path).write_text(output, encoding="utf-8")
        print(f"[report] {report_path}")
    else:
        print(output)


# ─────────────────────────────────────────────────────────────────────────────
# CLI
# ─────────────────────────────────────────────────────────────────────────────

def main() -> int:
    parser = argparse.ArgumentParser(prog="ssot_auditor", description=__doc__)
    parser.add_argument("--scan", action="store_true", help="전수 스캔 실행")
    parser.add_argument("--strict", action="store_true", help="allowlist 무시 (모든 키워드 매치 = 위반)")
    parser.add_argument("--json", action="store_true", help="JSON 형식 출력")
    parser.add_argument("--report", metavar="PATH", help="JSON 리포트 파일 경로")
    args = parser.parse_args()

    if not args.scan:
        parser.print_help()
        return 2

    findings = scan_all(strict=args.strict)
    if args.json or args.report:
        print_json(findings, strict=args.strict, report_path=args.report)
    else:
        print_human(findings, strict=args.strict)

    violations = [f for f in findings if not f.allowlisted]
    return 0 if not violations else 1


if __name__ == "__main__":
    sys.exit(main())
