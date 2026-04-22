#!/usr/bin/env python3
"""active_work_claim.py — v5.1 Pre-Work Contract CLI.

SSOT: docs/4. Operations/Active_Work.md
목적:
  작업 시작 전 의도 공유로 **proactive 충돌 회피**. v5.0 의 reactive merge
  gate 와 병렬 작동 (L0 pre-work contract + L1/L2/L3 worktree/PR/queue).

CCR (deprecated) 와 차이: governance 아니라 coordination. heavy review 없음.

Usage:
  # 현재 active claim 목록
  python tools/active_work_claim.py list
  python tools/active_work_claim.py list --team team2
  python tools/active_work_claim.py list --json

  # scope 충돌 확인 (작업 시작 전)
  python tools/active_work_claim.py check --scope "team2-backend/**,docs/2*/APIs/*"

  # claim 추가 (작업 시작)
  python tools/active_work_claim.py add \
      --team team2 --task "API-01 path rename" \
      --scope "team2-backend/src/routers/series.py,..." \
      --eta 2h --blocks team1

  # 작업 중 scope 추가
  python tools/active_work_claim.py update --id 3 --add-scope "new/path.py"

  # PR URL 갱신
  python tools/active_work_claim.py update --id 3 --pr "https://github.com/.../pull/123"

  # 작업 완료 (team_v5_merge.py 자동 호출)
  python tools/active_work_claim.py release --id 3

Exit:
  0 — 성공
  1 — scope 충돌 감지 (check 명령 또는 add 시 conflict)
  2 — 파일/구조 오류
  3 — CLI 인자 오류
"""
from __future__ import annotations

import argparse
import datetime
import fnmatch
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Any

try:
    import yaml  # PyYAML 6.x (tools/requirements.txt 에 이미 있음)
except ImportError:
    print("[error] PyYAML 필요. `pip install pyyaml>=6.0`", file=sys.stderr)
    sys.exit(2)

REPO = Path(__file__).resolve().parents[1]
SSOT = REPO / "docs" / "4. Operations" / "Active_Work.md"
CLAIMS_BEGIN = "<!-- CLAIMS_BEGIN -->"
CLAIMS_END = "<!-- CLAIMS_END -->"
RELEASED_BEGIN = "<!-- RELEASED_BEGIN -->"
RELEASED_END = "<!-- RELEASED_END -->"
RELEASED_TTL_HOURS = 24

# ---------------------------------------------------------------- I/O


def _now_iso() -> str:
    return datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _parse_iso(s: str) -> datetime.datetime | None:
    try:
        return datetime.datetime.strptime(s, "%Y-%m-%dT%H:%M:%SZ").replace(
            tzinfo=datetime.timezone.utc
        )
    except Exception:
        return None


def _load_md() -> str:
    if not SSOT.exists():
        print(f"[error] SSOT 없음: {SSOT}", file=sys.stderr)
        sys.exit(2)
    return SSOT.read_text(encoding="utf-8")


def _save_md(content: str) -> None:
    SSOT.write_text(content, encoding="utf-8", newline="\n")


def _extract_block(text: str, begin: str, end: str) -> tuple[int, int, str]:
    """marker 사이 내용 추출. (begin_pos, end_pos, inner_text) 반환."""
    b = text.find(begin)
    e = text.find(end)
    if b == -1 or e == -1 or e < b:
        print(f"[error] marker 파손: {begin}/{end}", file=sys.stderr)
        sys.exit(2)
    inner = text[b + len(begin):e]
    return b + len(begin), e, inner


def _parse_claims(inner: str) -> list[dict[str, Any]]:
    """``` ... ``` 펜스 블록의 YAML 들을 파싱."""
    claims: list[dict[str, Any]] = []
    for m in re.finditer(r"```yaml\n(.*?)\n```", inner, re.DOTALL):
        try:
            d = yaml.safe_load(m.group(1))
            if isinstance(d, dict):
                claims.append(d)
        except yaml.YAMLError as exc:
            print(f"[warn] YAML 파싱 실패, skip: {exc}", file=sys.stderr)
    return claims


def _render_claims(claims: list[dict[str, Any]]) -> str:
    if not claims:
        return "\n_(현재 active claim 없음)_\n"
    parts = ["\n"]
    for c in sorted(claims, key=lambda x: x.get("id", 0)):
        parts.append(f"### Claim #{c.get('id','?')} — {c.get('team','?')}: {c.get('task','?')}\n")
        parts.append("```yaml\n")
        parts.append(yaml.safe_dump(c, sort_keys=False, allow_unicode=True).rstrip())
        parts.append("\n```\n\n")
    return "".join(parts)


def load_state() -> tuple[str, list[dict], list[dict]]:
    md = _load_md()
    _, _, active_inner = _extract_block(md, CLAIMS_BEGIN, CLAIMS_END)
    _, _, released_inner = _extract_block(md, RELEASED_BEGIN, RELEASED_END)
    return md, _parse_claims(active_inner), _parse_claims(released_inner)


def save_state(md: str, active: list[dict], released: list[dict]) -> None:
    # CLAIMS_BEGIN/END 교체
    a_start = md.find(CLAIMS_BEGIN) + len(CLAIMS_BEGIN)
    a_end = md.find(CLAIMS_END)
    r_start = md.find(RELEASED_BEGIN) + len(RELEASED_BEGIN)
    r_end = md.find(RELEASED_END)
    if a_start < len(CLAIMS_BEGIN) or a_end == -1 or r_start < len(RELEASED_BEGIN) or r_end == -1:
        print("[error] marker 찾기 실패", file=sys.stderr)
        sys.exit(2)

    # released 는 ttl 로 정리
    cutoff = datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(hours=RELEASED_TTL_HOURS)
    pruned = []
    for c in released:
        ts = _parse_iso(c.get("released", ""))
        if ts is None or ts >= cutoff:
            pruned.append(c)

    new_md = (
        md[:a_start]
        + _render_claims(active)
        + md[a_end:r_start]
        + _render_claims(pruned)
        + md[r_end:]
    )
    # last-updated frontmatter 갱신
    new_md = re.sub(
        r"last-updated: \d{4}-\d{2}-\d{2}",
        f"last-updated: {datetime.date.today().isoformat()}",
        new_md,
        count=1,
    )
    _save_md(new_md)


# ---------------------------------------------------------------- Scope matching


def _expand_globs(patterns: list[str]) -> set[str]:
    """glob 패턴 → 매칭 파일 경로 집합. filesystem 기반."""
    matched: set[str] = set()
    for pat in patterns:
        pat = pat.strip().replace("\\", "/")
        if not pat:
            continue
        # 절대 경로이거나 glob 문자 포함이면 glob 처리
        if any(c in pat for c in "*?[") or pat.endswith("/"):
            for p in REPO.glob(pat):
                matched.add(str(p.relative_to(REPO)).replace("\\", "/"))
        else:
            # 단일 파일/디렉토리
            p = (REPO / pat).resolve()
            if p.exists():
                matched.add(str(p.relative_to(REPO)).replace("\\", "/"))
            else:
                # 존재 안 하면 pattern 자체를 저장 (미래 파일 claim 가능)
                matched.add(pat)
    return matched


def _scope_overlap(scope_a: list[str], scope_b: list[str]) -> list[str]:
    """두 scope 의 glob 교집합 (실제 파일 경로 기준)."""
    a = _expand_globs(scope_a)
    b = _expand_globs(scope_b)
    direct = sorted(a & b)

    # glob 패턴 자체 비교 (glob-to-glob)
    for pat_a in scope_a:
        for pat_b in scope_b:
            pa = pat_a.strip().replace("\\", "/")
            pb = pat_b.strip().replace("\\", "/")
            if pa == pb and pa not in direct:
                direct.append(pa)
            # a 가 b 를 포괄하는 패턴인지
            elif pa.endswith("/**") and (pb.startswith(pa[:-3]) or fnmatch.fnmatch(pb, pa.replace("**", "*"))):
                if pb not in direct:
                    direct.append(pb)
            elif pb.endswith("/**") and (pa.startswith(pb[:-3]) or fnmatch.fnmatch(pa, pb.replace("**", "*"))):
                if pa not in direct:
                    direct.append(pa)
    return direct


# ---------------------------------------------------------------- Commands


def cmd_list(args) -> int:
    _, active, released = load_state()
    if args.team:
        active = [c for c in active if c.get("team") == args.team]
    if args.json:
        print(json.dumps({"active": active, "released": released}, indent=2, ensure_ascii=False))
        return 0
    if not active:
        print("(active claim 없음)")
        return 0
    print(f"=== Active Claims ({len(active)}) ===")
    for c in sorted(active, key=lambda x: x.get("id", 0)):
        scope_str = ", ".join(c.get("scope", [])[:3])
        if len(c.get("scope", [])) > 3:
            scope_str += f" (+{len(c['scope'])-3})"
        print(f"  #{c['id']} [{c['team']}] {c.get('task','?')}")
        print(f"      scope: {scope_str}")
        print(f"      started: {c.get('started','?')}, eta: {c.get('eta','?')}")
        if c.get("pr"):
            print(f"      pr: {c['pr']}")
    return 0


def cmd_check(args) -> int:
    _, active, _ = load_state()
    scope = [s.strip() for s in args.scope.split(",") if s.strip()]
    if not scope:
        print("[error] --scope 필요", file=sys.stderr)
        return 3

    conflicts = []
    for c in active:
        overlap = _scope_overlap(scope, c.get("scope", []))
        if overlap:
            conflicts.append({
                "claim_id": c.get("id"),
                "team": c.get("team"),
                "task": c.get("task"),
                "overlap": overlap,
            })

    if args.json:
        print(json.dumps({"scope": scope, "conflicts": conflicts}, indent=2, ensure_ascii=False))
    else:
        if not conflicts:
            print(f"✅ 충돌 없음 (scope: {scope})")
        else:
            print(f"⚠️ {len(conflicts)} 건 충돌:")
            for cf in conflicts:
                print(f"  #{cf['claim_id']} [{cf['team']}] {cf['task']}")
                for p in cf["overlap"][:5]:
                    print(f"      - {p}")
    return 1 if conflicts else 0


def cmd_add(args) -> int:
    md, active, released = load_state()

    # 충돌 사전 체크
    scope = [s.strip() for s in args.scope.split(",") if s.strip()]
    if not scope:
        print("[error] --scope 필요", file=sys.stderr)
        return 3

    for c in active:
        overlap = _scope_overlap(scope, c.get("scope", []))
        if overlap and not args.force:
            print(f"⚠️ 충돌: claim #{c['id']} [{c['team']}] scope 겹침:", file=sys.stderr)
            for p in overlap[:5]:
                print(f"      - {p}", file=sys.stderr)
            print("\n해결: scope 축소 or 조율 or --force", file=sys.stderr)
            return 1

    # 신규 id
    all_ids = [c.get("id", 0) for c in active + released]
    new_id = max(all_ids, default=0) + 1

    claim = {
        "id": new_id,
        "team": args.team,
        "task": args.task,
        "started": _now_iso(),
        "scope": scope,
        "status": "active",
    }
    if args.blocks:
        claim["blocks"] = [b.strip() for b in args.blocks.split(",") if b.strip()]
    if args.depends_on:
        claim["depends_on"] = [int(x) for x in args.depends_on.split(",") if x.strip()]
    if args.eta:
        claim["eta"] = args.eta
    if args.pr:
        claim["pr"] = args.pr

    active.append(claim)
    save_state(md, active, released)
    print(f"✅ claim #{new_id} added ({args.team}: {args.task})")
    print(f"   scope: {scope}")
    if args.commit:
        _auto_commit_push(f"chore(active-work): add claim #{new_id} [{args.team}]")
    return 0


def cmd_update(args) -> int:
    md, active, released = load_state()
    claim = next((c for c in active if c.get("id") == args.id), None)
    if not claim:
        print(f"[error] claim #{args.id} not found (active)", file=sys.stderr)
        return 3

    changed = False
    if args.add_scope:
        add = [s.strip() for s in args.add_scope.split(",") if s.strip()]
        claim["scope"] = sorted(set(claim.get("scope", []) + add))
        changed = True
    if args.pr:
        claim["pr"] = args.pr
        changed = True
    if args.status:
        claim["status"] = args.status
        changed = True
    if args.eta:
        claim["eta"] = args.eta
        changed = True

    if not changed:
        print("[warn] 변경사항 없음", file=sys.stderr)
        return 3

    save_state(md, active, released)
    print(f"✅ claim #{args.id} updated")
    if args.commit:
        _auto_commit_push(f"chore(active-work): update claim #{args.id}")
    return 0


def cmd_release(args) -> int:
    md, active, released = load_state()
    idx = next((i for i, c in enumerate(active) if c.get("id") == args.id), None)
    if idx is None:
        print(f"[error] active claim #{args.id} not found", file=sys.stderr)
        return 3

    claim = active.pop(idx)
    claim["status"] = "released"
    claim["released"] = _now_iso()
    released.append(claim)
    save_state(md, active, released)
    print(f"✅ claim #{args.id} released ({claim.get('team')}: {claim.get('task')})")
    if args.commit:
        _auto_commit_push(f"chore(active-work): release claim #{args.id}")
    return 0


# ---------------------------------------------------------------- Git helpers


def _auto_commit_push(msg: str) -> None:
    """Active_Work.md 만 commit (최소 change)."""
    try:
        rel = str(SSOT.relative_to(REPO)).replace("\\", "/")
        subprocess.run(["git", "add", rel], cwd=REPO, check=True, capture_output=True)
        subprocess.run(
            ["git", "commit", "-m", msg + "\n\nCo-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"],
            cwd=REPO, check=True, capture_output=True,
        )
        # push 는 별도 (플랫폼 block 가능성). 경고만
        print(f"  commit: {msg}")
        print("  (push 는 수동. main push block 플랫폼 정책상)")
    except subprocess.CalledProcessError as e:
        print(f"[warn] auto-commit 실패: {e.stderr.decode('utf-8', errors='ignore')[:200]}", file=sys.stderr)


# ---------------------------------------------------------------- Main


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    sub = ap.add_subparsers(dest="cmd", required=True)

    # list
    p_list = sub.add_parser("list", help="현재 claim 목록")
    p_list.add_argument("--team", help="특정 팀 필터")
    p_list.add_argument("--json", action="store_true")
    p_list.set_defaults(func=cmd_list)

    # check
    p_check = sub.add_parser("check", help="scope 충돌 확인")
    p_check.add_argument("--scope", required=True, help="CSV glob 패턴")
    p_check.add_argument("--json", action="store_true")
    p_check.set_defaults(func=cmd_check)

    # add
    p_add = sub.add_parser("add", help="claim 추가")
    p_add.add_argument("--team", required=True,
                       choices=("conductor", "team1", "team2", "team3", "team4"))
    p_add.add_argument("--task", required=True, help="작업 제목 (≤80자)")
    p_add.add_argument("--scope", required=True, help="CSV glob")
    p_add.add_argument("--eta", help="예상 시간 (e.g. 2h, 30m)")
    p_add.add_argument("--blocks", help="block 되는 팀 (CSV)")
    p_add.add_argument("--depends-on", help="의존 claim id (CSV)")
    p_add.add_argument("--pr", help="PR URL (Phase 2 후)")
    p_add.add_argument("--force", action="store_true", help="충돌 무시")
    p_add.add_argument("--commit", action="store_true",
                       help="Active_Work.md 자동 commit (push 는 수동)")
    p_add.set_defaults(func=cmd_add)

    # update
    p_upd = sub.add_parser("update", help="claim 수정")
    p_upd.add_argument("--id", type=int, required=True)
    p_upd.add_argument("--add-scope", help="CSV glob 추가")
    p_upd.add_argument("--pr", help="PR URL 설정")
    p_upd.add_argument("--status", choices=("active", "paused", "released"))
    p_upd.add_argument("--eta")
    p_upd.add_argument("--commit", action="store_true")
    p_upd.set_defaults(func=cmd_update)

    # release
    p_rel = sub.add_parser("release", help="claim 해제")
    p_rel.add_argument("--id", type=int, required=True)
    p_rel.add_argument("--commit", action="store_true")
    p_rel.set_defaults(func=cmd_release)

    args = ap.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
