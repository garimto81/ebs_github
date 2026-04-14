#!/usr/bin/env python3
"""Stage C — /ssot-align renderer.

tools/.ssot-align-plan.json + tools/.ssot-align-cache/ 를 읽어 각 섹션의
5-block 템플릿을 렌더하고, 실제 contracts/ 파일에 쓰거나 (--dry-run 시) diff 를 출력한다.

LLM 토큰 소모 0 — 결정론적 템플릿 렌더 + 바이트 동일성 assertion.

Usage:
    python tools/ssot_align_render.py --dry-run
    python tools/ssot_align_render.py --scope contracts/data/DATA-04-db-schema.md

출력:
    --dry-run  → tools/.ssot-align-diff/<file>.diff + tools/.ssot-align-report.md
    기본       → 대상 파일 in-place 수정 + report + roadmap + state 갱신
"""
from __future__ import annotations

import argparse
import difflib
import json
import re
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import yaml

PROJECT = Path(__file__).resolve().parent.parent
CONFIG_PATH = PROJECT / ".ssot-align.yaml"
PLAN_PATH = PROJECT / "tools" / ".ssot-align-plan.json"
CACHE_DIR = PROJECT / "tools" / ".ssot-align-cache"
DIFF_DIR = PROJECT / "tools" / ".ssot-align-diff"
STATE_PATH = PROJECT / "tools" / ".ssot-align-state.json"
REPORT_PATH = PROJECT / "tools" / ".ssot-align-report.md"

WIKI_BASE = "https://ggnetwork.atlassian.net/wiki/spaces/{space}/pages/{pid}"


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def load_yaml(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def load_cache(page_id: str) -> dict[str, Any] | None:
    path = CACHE_DIR / f"page-{page_id}.json"
    if not path.exists():
        return None
    return load_json(path)


@dataclass
class RenderResult:
    file: str
    heading: str
    status: str           # rendered | skipped-unmapped | skipped-nocache | aligned-refreshed | native
    verdict_hint: str | None = None
    note: str = ""


def render_aligned_block(
    heading: str,
    source_id: str,
    cache: dict[str, Any],
    space: str,
    phase_buckets: list[dict[str, str]],
) -> str:
    """5-block 섹션 렌더. verbatim 은 cache body 를 바이트 동일하게 복사."""
    title = cache.get("title", "") or ""
    version = cache.get("version", "") or ""
    fetched_at = cache.get("fetched_at", "") or datetime.now(timezone.utc).isoformat()
    body = cache.get("body", "") or ""

    url = WIKI_BASE.format(space=space, pid=source_id)

    phase_lines = []
    for bucket in phase_buckets:
        phase_lines.append(f"- **{bucket['name']} ({bucket['window']})**: <target rows>")

    lines: list[str] = [
        f"## {heading}",
        "",
        "### 📎 원본 SSOT",
        "",
        f"- Confluence 페이지: {title}",
        f"- Page ID: `{source_id}`",
        f"- URL: {url}",
        f"- 조회 명령: `/con-lookup page {source_id}`",
        f"- 마지막 SSOT 확인: {fetched_at}",
        f"- Confluence version: `{version}`",
        "",
        "### 📋 Verbatim 추출",
        "",
        f"> 추출 시각: {fetched_at} (source version `{version}`)",
        f"> Source: {title}",
        "",
        "````",
        body,
        "````",
        "",
        "### 🔀 매핑표",
        "",
        "| WSOP 원본 | 원본 타입 | EBS 반영 | EBS 타입 | 판정 | Phase | Adapter |",
        "|----------|---------|---------|---------|------|-------|---------|",
        "| _자동 생성 대기_ | — | — | — | `DEFERRED` | Phase 1 | — |",
        "",
        "판정: IDENTICAL / RENAMED / SUBSET / SUPERSET / DIVERGENT / DEFERRED",
        "",
        "### 🚀 마이그레이션 계획",
        "",
        *phase_lines,
        "- Adapter: _미지정_",
        "- Test: _미지정_",
        "",
        "### ✅ 검증 체크리스트",
        "",
        f"- [ ] 최근 7일 이내 `/con-lookup page {source_id}` 재조회 완료 (last: {fetched_at[:10]})",
        f"- [ ] Confluence 최신 version 과 본 섹션의 SSOT version(`{version}`) 일치",
        "- [ ] 매핑표 모든 행에 판정 존재",
        "- [ ] DEFERRED 행 모두 Phase 계획에 배정됨",
        "- [ ] RENAMED 행에 Adapter 경로 + 테스트 참조 존재",
        "- [ ] doc-critic: High 지적 0건",
        "",
    ]
    return "\n".join(lines)


def render_native_block(heading: str, owner: str) -> str:
    return "\n".join([
        f"## {heading}",
        "",
        "### 🏷️ 프로젝트 고유 (No SSOT)",
        "",
        f"외부 SSOT 없음 (EBS 고유 영역). Owner: `{owner}`. 사유: _기재 필요_.",
        "",
    ])


SECTION_HEADING_RE = re.compile(r"^##\s+", re.MULTILINE)


def replace_section_in_file(original: str, heading: str, new_block: str) -> tuple[str, bool]:
    """## heading 섹션을 new_block 으로 교체. 존재하지 않으면 파일 끝에 append.

    return (new_content, replaced_bool).
    """
    lines = original.splitlines(keepends=True)
    start_idx = None
    for i, line in enumerate(lines):
        m = re.match(r"^##\s+(?:§[\d.]+\.?\s*)?(.+?)\s*$", line)
        if m and m.group(1).strip() == heading:
            start_idx = i
            break

    if start_idx is None:
        # append at EOF (ensure trailing newline)
        end = original if original.endswith("\n") else original + "\n"
        return end + "\n" + new_block.rstrip() + "\n", False

    # find next ## heading
    end_idx = len(lines)
    for j in range(start_idx + 1, len(lines)):
        if re.match(r"^##\s+", lines[j]):
            end_idx = j
            break

    new_lines = lines[:start_idx] + [new_block.rstrip() + "\n"]
    # preserve a blank line separator if next section exists
    if end_idx < len(lines):
        new_lines.append("\n")
        new_lines.extend(lines[end_idx:])
    return "".join(new_lines), True


def assert_verbatim_integrity(rendered: str, cache_body: str) -> None:
    """렌더 결과 내 ``` verbatim ``` 블록 중 하나가 cache_body 와 바이트 동일한지 검증."""
    # find first triple-backtick fenced block
    m = re.search(r"````\s*\n(.*?)\n````", rendered, re.DOTALL)
    if not m:
        raise AssertionError("verbatim block not found in rendered output")
    captured = m.group(1)
    if captured != cache_body:
        raise AssertionError(
            f"verbatim integrity violation: cached body len={len(cache_body)} "
            f"vs rendered captured len={len(captured)}"
        )


def write_diff(rel_path: str, before: str, after: str) -> Path:
    DIFF_DIR.mkdir(parents=True, exist_ok=True)
    diff = difflib.unified_diff(
        before.splitlines(keepends=True),
        after.splitlines(keepends=True),
        fromfile=f"a/{rel_path}",
        tofile=f"b/{rel_path}",
        n=3,
    )
    out_path = DIFF_DIR / (rel_path.replace("/", "__") + ".diff")
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text("".join(diff), encoding="utf-8")
    return out_path


def render_file(
    file_entry: dict[str, Any],
    cfg: dict[str, Any],
    dry_run: bool,
    audit: bool,
    scope_filter: set[str] | None,
    heading_filter: str | None,
) -> list[RenderResult]:
    rel = file_entry["path"]
    if scope_filter and rel not in scope_filter:
        return []
    abspath = PROJECT / rel
    if not abspath.exists():
        return [RenderResult(rel, "<file>", "skipped-missing", note="file not found")]

    original = abspath.read_text(encoding="utf-8")
    current = original
    results: list[RenderResult] = []
    space = cfg.get("source", {}).get("options", {}).get("space_key", "WSOPLive")
    phase_buckets = cfg.get("phase_buckets", [])
    owner = file_entry.get("owner", "unknown")

    for section in file_entry["sections"]:
        heading = section["heading"]
        if heading_filter and heading != heading_filter:
            continue
        status = section["status"]
        source_id = section.get("source_id")

        if status == "unmapped":
            results.append(RenderResult(rel, heading, "skipped-unmapped",
                                        note="Stage B Rovo resolve 필요"))
            continue

        if status == "native":
            block = render_native_block(heading, owner)
            current, _ = replace_section_in_file(current, heading, block)
            results.append(RenderResult(rel, heading, "native"))
            continue

        # aligned / cached — require source_id + cache
        if not source_id:
            results.append(RenderResult(rel, heading, "skipped-nocache",
                                        note="source_id 없음"))
            continue
        cache = load_cache(source_id)
        if not cache:
            results.append(RenderResult(rel, heading, "skipped-nocache",
                                        note=f"page-{source_id}.json 캐시 없음 (Stage B fetch 필요)"))
            continue

        block = render_aligned_block(heading, source_id, cache, space, phase_buckets)
        assert_verbatim_integrity(block, cache.get("body", ""))
        current, replaced = replace_section_in_file(current, heading, block)
        note = "replaced" if replaced else "appended"
        out_status = "aligned-refreshed" if status == "aligned" else "rendered"
        results.append(RenderResult(rel, heading, out_status, note=note))

    if current == original:
        return results

    if audit:
        # audit: no writes at all. Rewrite the outcome status to reflect drift detection only.
        drift_lines = current.count("\n") - original.count("\n")
        for r in results:
            if r.status in ("rendered", "aligned-refreshed"):
                r.status = "drift-detected"
                r.note = f"{abs(drift_lines)}-line diff pending alignment"
            elif r.status == "native":
                r.status = "native-drift" if r.note == "replaced" else "native"
    elif dry_run:
        diff_path = write_diff(rel, original, current)
        for r in results:
            if r.status in ("rendered", "aligned-refreshed", "native"):
                r.note = f"diff: {diff_path.relative_to(PROJECT)}"
    else:
        abspath.write_text(current, encoding="utf-8")
        for r in results:
            if r.status in ("rendered", "aligned-refreshed", "native"):
                r.note = f"wrote {rel}"

    return results


def write_report(all_results: list[RenderResult], mode: str) -> None:
    counts: dict[str, int] = {}
    for r in all_results:
        counts[r.status] = counts.get(r.status, 0) + 1

    lines = [
        "# /ssot-align — Stage C 렌더 리포트",
        "",
        f"- 생성: {datetime.now(timezone.utc).isoformat()}",
        f"- 모드: {mode}",
        f"- 총 섹션: {len(all_results)}",
        "",
        "## 요약",
        "",
        "| 상태 | 개수 |",
        "|------|------|",
    ]
    for status, n in sorted(counts.items()):
        lines.append(f"| `{status}` | {n} |")
    lines += ["", "## 상세", "", "| 파일 | 섹션 | 상태 | 비고 |", "|------|------|------|------|"]
    for r in all_results:
        note = r.note.replace("|", "\\|")
        lines.append(f"| `{r.file}` | {r.heading} | `{r.status}` | {note} |")
    lines.append("")
    REPORT_PATH.write_text("\n".join(lines), encoding="utf-8")


def update_state(all_results: list[RenderResult], mode: str) -> None:
    state: dict[str, Any] = {}
    if STATE_PATH.exists():
        try:
            state = load_json(STATE_PATH)
        except Exception:
            state = {}
    state["last_run"] = {
        "at": datetime.now(timezone.utc).isoformat(),
        "mode": mode,
        "section_count": len(all_results),
    }
    # section-level checkpoints
    ck = state.setdefault("checkpoints", {})
    for r in all_results:
        ck[f"{r.file}#{r.heading}"] = {"status": r.status, "note": r.note}
    STATE_PATH.write_text(
        json.dumps(state, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )


def update_roadmap(cfg: dict[str, Any], all_results: list[RenderResult]) -> None:
    roadmap_cfg = cfg.get("roadmap", {})
    if not roadmap_cfg.get("auto_update"):
        return
    rp = roadmap_cfg.get("path")
    if not rp:
        return
    path = PROJECT / rp
    if not path.exists():
        return
    # append a dated summary block at end (non-destructive)
    stamp = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    summary: dict[str, int] = {}
    for r in all_results:
        summary[r.status] = summary.get(r.status, 0) + 1
    block = [
        "",
        f"<!-- ssot-align auto-update {stamp} -->",
        f"- **{stamp}** — " + ", ".join(f"{k}={v}" for k, v in sorted(summary.items())),
    ]
    with path.open("a", encoding="utf-8") as f:
        f.write("\n".join(block) + "\n")


def main() -> None:
    ap = argparse.ArgumentParser(description="Stage C renderer for /ssot-align")
    mode = ap.add_mutually_exclusive_group()
    mode.add_argument("--dry-run", action="store_true",
                      help="no file writes; emit unified diffs to diff dir")
    mode.add_argument("--audit", action="store_true",
                      help="no writes, no diffs; drift report only")
    ap.add_argument("--scope", nargs="*", help="restrict to these relative paths")
    ap.add_argument("--heading", help="restrict to sections whose ## heading matches exactly")
    ap.add_argument("--plan", default=str(PLAN_PATH), help="plan.json path")
    args = ap.parse_args()

    run_mode = "audit" if args.audit else ("dry-run" if args.dry_run else "write")

    plan_path = Path(args.plan)
    if not plan_path.exists():
        print(f"[ssot-align-render] plan not found: {plan_path}", file=sys.stderr)
        print("  run `python tools/ssot_align_plan.py` first", file=sys.stderr)
        sys.exit(2)

    plan = load_json(plan_path)
    cfg = load_yaml(CONFIG_PATH)
    scope_filter = set(args.scope) if args.scope else None

    all_results: list[RenderResult] = []
    for fe in plan["files"]:
        results = render_file(fe, cfg, args.dry_run, args.audit, scope_filter, args.heading)
        all_results.extend(results)

    write_report(all_results, run_mode)
    update_state(all_results, run_mode)
    if run_mode == "write":
        update_roadmap(cfg, all_results)

    counts: dict[str, int] = {}
    for r in all_results:
        counts[r.status] = counts.get(r.status, 0) + 1
    summary = " ".join(f"{k}={v}" for k, v in sorted(counts.items()))
    print(f"[ssot-align-render] mode={run_mode} total={len(all_results)} {summary} "
          f"→ {REPORT_PATH.relative_to(PROJECT)}")


if __name__ == "__main__":
    main()
