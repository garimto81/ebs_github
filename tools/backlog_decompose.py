#!/usr/bin/env python3
"""1회성 마이그레이션: Backlog.md / Spec_Gaps.md / Conductor_Backlog.md 를
디렉토리 + 항목별 파일 구조로 분해.

- `### [ID] Title` 블록을 단위로 분리
- 상위 `## STATUS` 섹션에서 status (PENDING/IN_PROGRESS/DONE) 추출
- 출력: 같은 폴더의 `Backlog/` (또는 `Spec_Gaps/`, `Conductor_Backlog/`) 디렉토리에
  `{ID}-{slug}.md` 파일 1건씩
- 원본 .md 는 stub 으로 교체 (디렉토리로 이동했음을 안내 + 자동 집계 뷰 위치)

idempotent: 이미 분해된 디렉토리가 있으면 스킵.

Usage:
    python tools/backlog_decompose.py            # dry-run, 변경 미리보기
    python tools/backlog_decompose.py --apply    # 실제 분해 + 원본 stub 교체
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

PROJECT = Path(__file__).resolve().parent.parent

# (원본 파일, 디렉토리명, 항목 ID 패턴)
TARGETS = [
    (PROJECT / "docs" / "2. Development" / "2.1 Frontend" / "Backlog.md",
     "Backlog", r"\[(B-\d+|NOTIFY-[A-Z0-9-]+)\]"),
    (PROJECT / "docs" / "2. Development" / "2.2 Backend" / "Backlog.md",
     "Backlog", r"\[(B-\d+|NOTIFY-[A-Z0-9-]+)\]"),
    (PROJECT / "docs" / "2. Development" / "2.2 Backend" / "Spec_Gaps.md",
     "Spec_Gaps", "GAP_H2"),  # 특수 패턴: ## GAP-XXX-NNN: 형식
    (PROJECT / "docs" / "2. Development" / "2.3 Game Engine" / "Backlog.md",
     "Backlog", r"\[(B-\d+|NOTIFY-[A-Z0-9-]+)\]"),
    (PROJECT / "docs" / "2. Development" / "2.4 Command Center" / "Backlog.md",
     "Backlog", r"\[(B-\d+|NOTIFY-[A-Z0-9-]+)\]"),
    (PROJECT / "docs" / "4. Operations" / "Conductor_Backlog.md",
     "Conductor_Backlog", r"\[(C-\d+|B-\d+|NOTIFY-[A-Z0-9-]+)\]"),
]

FRONTMATTER_RE = re.compile(r"^---\n(.*?)\n---\n", re.DOTALL)
STATUS_RE = re.compile(r"^##\s+(PENDING|IN_PROGRESS|DONE|ARCHIVE|TODO)\b", re.MULTILINE)


def slugify(text: str, max_len: int = 50) -> str:
    text = re.sub(r"[~`*\[\]()#:✅⚠✓✗]+", "", text)
    text = re.sub(r"[^\w가-힣\s-]+", "", text, flags=re.UNICODE)
    text = re.sub(r"\s+", "-", text.strip())
    text = text.strip("-")
    return text[:max_len] if text else "untitled"


def parse_blocks(text: str, id_pattern: str) -> list[dict]:
    """원본 텍스트를 항목 블록으로 분해.

    각 블록: {id, title, status, body, raw}
    - status: 직전 `## SECTION` 헤더 (없으면 'UNCATEGORIZED')
    - body: `### ...` 다음 줄부터 다음 `### ` 또는 `## ` 직전까지

    특수 패턴 'GAP_H2': `## GAP-XXX-NNN: title` 형식 (Spec_Gaps.md 용)
    """
    if id_pattern == "GAP_H2":
        return _parse_gap_h2(text)
    id_re = re.compile(rf"^###\s+~?~?{id_pattern}([^\n]*)\n", re.MULTILINE)

    blocks: list[dict] = []
    matches = list(id_re.finditer(text))
    status_marks = list(STATUS_RE.finditer(text))

    def status_at(pos: int) -> str:
        cur = "UNCATEGORIZED"
        for sm in status_marks:
            if sm.start() < pos:
                cur = sm.group(1)
            else:
                break
        return cur

    for i, m in enumerate(matches):
        item_id = m.group(1)
        title = m.group(2).strip()
        title = re.sub(r"~~$", "", title).strip()
        body_start = m.end()
        body_end = matches[i + 1].start() if i + 1 < len(matches) else len(text)
        # body 끝에 다음 ## 가 있으면 거기까지만
        next_section = STATUS_RE.search(text, body_start, body_end)
        if next_section:
            body_end = next_section.start()
        body = text[body_start:body_end].rstrip()
        blocks.append({
            "id": item_id,
            "title": title,
            "status": status_at(m.start()),
            "body": body,
            "raw": text[m.start():body_end],
        })
    return blocks


def _parse_gap_h2(text: str) -> list[dict]:
    """## GAP-XXX-NNN: title 패턴 파싱. status는 본문의 '**상태**:' 라인에서 추출."""
    gap_re = re.compile(r"^##\s+(GAP-[A-Z0-9-]+):\s*([^\n]*)\n", re.MULTILINE)
    matches = list(gap_re.finditer(text))
    blocks: list[dict] = []
    for i, m in enumerate(matches):
        gap_id = m.group(1)
        title = m.group(2).strip()
        body_start = m.end()
        body_end = matches[i + 1].start() if i + 1 < len(matches) else len(text)
        body = text[body_start:body_end].rstrip()
        # status 추출
        status = "OPEN"
        sm = re.search(r"\*\*상태\*\*:\s*\*?\*?([A-Z_]+)", body)
        if sm:
            status = sm.group(1).upper()
        blocks.append({
            "id": gap_id,
            "title": title,
            "status": status,
            "body": body,
            "raw": text[m.start():body_end],
        })
    return blocks


def build_item_md(block: dict, source_relpath: str) -> str:
    fm = (
        "---\n"
        f"id: {block['id']}\n"
        f"title: {json_escape(block['title'])}\n"
        f"status: {block['status']}\n"
        f"source: {source_relpath}\n"
        "---\n\n"
    )
    title = block["title"] or block["id"]
    return f"{fm}# [{block['id']}] {title}\n{block['body']}\n"


def json_escape(s: str) -> str:
    return s.replace('"', '\\"')


def stub_text(dir_name: str, count: int, original_name: str) -> str:
    return (
        "---\n"
        f"title: {original_name.replace('.md', '')}\n"
        "tier: internal\n"
        "decomposed: true\n"
        "---\n\n"
        f"# {original_name.replace('.md', '')} (디렉토리화됨)\n\n"
        f"이 파일은 멀티 세션 충돌 방지를 위해 **항목별 파일**로 분해되었습니다.\n\n"
        f"- 항목 위치: `./{dir_name}/` ({count}개 항목)\n"
        f"- 신규 항목 추가: `./{dir_name}/{{ID}}-{{slug}}.md` 작성 (frontmatter 필수)\n"
        f"- 통합 읽기 뷰: `tools/backlog_aggregate.py` 가 `_generated/` 에 자동 생성\n\n"
        f"신규 항목 frontmatter 예시:\n\n"
        f"```yaml\n"
        f"---\n"
        f"id: B-XXX\n"
        f"title: \"항목 제목\"\n"
        f"status: PENDING  # PENDING | IN_PROGRESS | DONE\n"
        f"source: (이 파일 경로)\n"
        f"---\n"
        f"```\n"
    )


def process(target: tuple, apply: bool) -> dict:
    src_path, dir_name, id_pat = target
    if not src_path.exists():
        return {"src": str(src_path), "skipped": "source missing"}

    out_dir = src_path.parent / dir_name
    if out_dir.exists() and any(out_dir.iterdir()):
        return {"src": str(src_path), "skipped": "already decomposed"}

    text = src_path.read_text(encoding="utf-8")
    blocks = parse_blocks(text, id_pat)
    if not blocks:
        return {"src": str(src_path), "skipped": "no items parsed"}

    files: list[str] = []
    seen: set[str] = set()
    src_rel = src_path.relative_to(PROJECT).as_posix()
    for b in blocks:
        slug = slugify(b["title"]) or b["id"].lower()
        fname = f"{b['id']}-{slug}.md"
        # 중복 ID 처리 (NOTIFY 가 PENDING/DONE 양쪽에 같은 ID 로 존재할 수 있음)
        if fname in seen:
            fname = f"{b['id']}-{slug}-{b['status'].lower()}.md"
        seen.add(fname)
        files.append(fname)
        if apply:
            out_dir.mkdir(parents=True, exist_ok=True)
            (out_dir / fname).write_text(build_item_md(b, src_rel), encoding="utf-8")

    if apply:
        src_path.write_text(stub_text(dir_name, len(blocks), src_path.name), encoding="utf-8")

    return {
        "src": src_rel,
        "out_dir": out_dir.relative_to(PROJECT).as_posix(),
        "items": len(blocks),
        "sample": files[:3],
    }


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--apply", action="store_true", help="실제 파일 생성 + 원본 stub 교체")
    args = ap.parse_args()

    print(f"=== backlog_decompose ({'APPLY' if args.apply else 'DRY-RUN'}) ===\n")
    summary = []
    for t in TARGETS:
        r = process(t, args.apply)
        summary.append(r)
        if "skipped" in r:
            print(f"[SKIP] {r['src']} — {r['skipped']}")
        else:
            print(f"[OK]   {r['src']} → {r['out_dir']} ({r['items']} items)")
            for s in r["sample"]:
                print(f"         · {s}")

    if not args.apply:
        print("\n--apply 옵션 없이 실행됨. 실제 적용하려면 `--apply` 추가.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
