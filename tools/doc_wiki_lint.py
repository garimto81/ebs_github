"""
doc_wiki_lint.py — mtime vs last_ingest_at drift 감지 도구

사용법:
    python tools/doc_wiki_lint.py                     # 기본 경로 (docs/_meta/doc-wiki/)
    python tools/doc_wiki_lint.py --wiki-dir <path>   # 커스텀 경로
    python tools/doc_wiki_lint.py --warn-only          # WARN 항목만 출력

drift > 24h 면 WARN. last_ingest_at 누락도 WARN.
"""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass, field
from datetime import datetime, timezone, timedelta
from pathlib import Path
from typing import Optional


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

DRIFT_THRESHOLD_HOURS = 24
REPO = Path(__file__).resolve().parent.parent
DEFAULT_WIKI_DIR = REPO / "docs" / "_meta" / "doc-wiki"

# lint 대상에서 제외할 파일명 (정확 일치)
SKIP_FILES = {"_schema.md", "Log.md", "Index.md"}


# ---------------------------------------------------------------------------
# Data structures
# ---------------------------------------------------------------------------

@dataclass
class LintResult:
    """topic wiki 파일 lint 결과."""
    topic: str              # wiki slug (예: lobby, back-office)
    status: str             # "OK" | "WARN"
    reason: str             # 사유 (OK 는 "", WARN 은 상세)
    drift_hours: float      # last_ingest_at 으로부터 경과 시간 (시간 단위)
    path: str = ""          # wiki 파일 경로


# ---------------------------------------------------------------------------
# Frontmatter parser (외부 의존성 없음)
# ---------------------------------------------------------------------------

def _parse_frontmatter(text: str) -> dict[str, str]:
    """YAML frontmatter 단순 파싱 (스칼라 값만)."""
    if not text.startswith("---"):
        return {}
    end = text.find("\n---", 3)
    if end < 0:
        return {}
    block = text[3:end].strip()
    out: dict[str, str] = {}
    for raw in block.splitlines():
        line = raw.rstrip()
        if not line or line.startswith("#") or line.startswith(" ") or line.startswith("-"):
            continue
        m = re.match(r"^([\w-]+):\s*(.+)$", line)
        if m:
            out[m.group(1).strip()] = m.group(2).strip().strip('"').strip("'")
    return out


# ---------------------------------------------------------------------------
# Core logic
# ---------------------------------------------------------------------------

def _parse_iso_utc(ts: str) -> Optional[datetime]:
    """ISO 8601 UTC 타임스탬프 파싱. 실패 시 None."""
    ts = ts.strip()
    # 지원 형식: 2026-05-14T09:30:00Z / 2026-05-14T09:30:00+00:00
    for fmt in ("%Y-%m-%dT%H:%M:%SZ", "%Y-%m-%dT%H:%M:%S+00:00", "%Y-%m-%dT%H:%M:%S"):
        try:
            dt = datetime.strptime(ts, fmt)
            return dt.replace(tzinfo=timezone.utc)
        except ValueError:
            continue
    return None


def check_wiki_file(path: Path) -> LintResult:
    """단일 topic wiki 파일을 lint.

    Returns:
        LintResult with status OK or WARN.
    """
    slug = path.stem  # 파일명에서 .md 제거

    try:
        text = path.read_text(encoding="utf-8", errors="ignore")
    except OSError:
        return LintResult(
            topic=slug,
            status="WARN",
            reason="파일 읽기 실패",
            drift_hours=-1.0,
            path=str(path),
        )

    fm = _parse_frontmatter(text)
    last_ingest_str = fm.get("last_ingest_at", "").strip()

    # ── last_ingest_at 누락 ──
    if not last_ingest_str:
        return LintResult(
            topic=slug,
            status="WARN",
            reason="last_ingest_at missing — wiki 가 한 번도 ingest 되지 않음",
            drift_hours=-1.0,
            path=str(path),
        )

    # ── 타임스탬프 파싱 ──
    last_ingest_dt = _parse_iso_utc(last_ingest_str)
    if last_ingest_dt is None:
        return LintResult(
            topic=slug,
            status="WARN",
            reason=f"last_ingest_at 파싱 실패: {last_ingest_str!r}",
            drift_hours=-1.0,
            path=str(path),
        )

    # ── drift 계산 ──
    now = datetime.now(timezone.utc)
    drift = now - last_ingest_dt
    drift_hours = drift.total_seconds() / 3600.0

    if drift_hours > DRIFT_THRESHOLD_HOURS:
        return LintResult(
            topic=slug,
            status="WARN",
            reason=f"drift {drift_hours:.1f}h > {DRIFT_THRESHOLD_HOURS}h — wiki 갱신 필요",
            drift_hours=drift_hours,
            path=str(path),
        )

    return LintResult(
        topic=slug,
        status="OK",
        reason="",
        drift_hours=drift_hours,
        path=str(path),
    )


def scan_wiki_dir(wiki_dir: Path) -> list[LintResult]:
    """wiki_dir 내 모든 topic .md 파일을 lint.

    _schema.md / Log.md / Index.md / candidates/ 는 제외.
    """
    results: list[LintResult] = []
    for md in sorted(wiki_dir.glob("*.md")):
        if md.name in SKIP_FILES:
            continue
        results.append(check_wiki_file(md))
    return results


def build_summary(results: list[LintResult]) -> dict[str, int]:
    """lint 결과를 집계.

    Returns:
        {"ok_count": int, "warn_count": int, "total": int}
    """
    ok = sum(1 for r in results if r.status == "OK")
    warn = sum(1 for r in results if r.status == "WARN")
    return {"ok_count": ok, "warn_count": warn, "total": len(results)}


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main(argv: list[str]) -> int:
    p = argparse.ArgumentParser(description="doc_wiki_lint — drift 감지")
    p.add_argument("--wiki-dir", default=str(DEFAULT_WIKI_DIR), help="doc-wiki 디렉토리 경로")
    p.add_argument("--warn-only", action="store_true", help="WARN 항목만 출력")
    args = p.parse_args(argv)

    wiki_dir = Path(args.wiki_dir)
    if not wiki_dir.exists():
        print(f"[INFO] wiki-dir 없음 (아직 생성 전): {wiki_dir}", file=sys.stderr)
        return 0

    results = scan_wiki_dir(wiki_dir)
    summary = build_summary(results)

    for r in results:
        if args.warn_only and r.status == "OK":
            continue
        prefix = "✅" if r.status == "OK" else "⚠️ "
        drift_str = f" ({r.drift_hours:.1f}h)" if r.drift_hours >= 0 else ""
        reason_str = f" — {r.reason}" if r.reason else ""
        print(f"{prefix} [{r.status}] {r.topic}{drift_str}{reason_str}")

    print(
        f"\n요약: OK={summary['ok_count']}  WARN={summary['warn_count']}  "
        f"합계={summary['total']}"
    )

    return 1 if summary["warn_count"] > 0 else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
