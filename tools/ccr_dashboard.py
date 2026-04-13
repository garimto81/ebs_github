#!/usr/bin/env python3
"""CCR 현황 대시보드 — inbox/promoting/archived + NOTIFY 상태 표시.

Usage:
    python tools/ccr_dashboard.py
    python tools/ccr_dashboard.py --json
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import datetime
from pathlib import Path

PROJECT = Path(__file__).resolve().parent.parent
INBOX = PROJECT / "docs" / "05-plans" / "ccr-inbox"
PROMOTING = INBOX / "promoting"
ARCHIVED = INBOX / "archived"
BACKLOG_DIR = PROJECT / "docs" / "backlog"

TEAMS = ["team1", "team2", "team3", "team4"]


# ============================================================
# 폴더 카운트
# ============================================================

def count_inbox() -> int:
    """inbox/ 에서 CCR-DRAFT-*.md 파일 수."""
    if not INBOX.exists():
        return 0
    return len(list(INBOX.glob("CCR-DRAFT-*.md")))


def count_promoting() -> int:
    """promoting/ 에서 CCR-NNN-*.md 파일 수."""
    if not PROMOTING.exists():
        return 0
    return len(list(PROMOTING.glob("CCR-[0-9][0-9][0-9]-*.md")))


def count_archived() -> int:
    """archived/ 에서 CCR-DRAFT-*.md 파일 수."""
    if not ARCHIVED.exists():
        return 0
    return len(list(ARCHIVED.glob("CCR-DRAFT-*.md")))


# ============================================================
# NOTIFY 파싱
# ============================================================

def parse_notify_items(team: str) -> list[dict]:
    """팀 backlog에서 NOTIFY-CCR-NNN 항목 파싱.

    NOTIFY-LEGACY-CCR-NNN 도 포함한다.
    """
    path = BACKLOG_DIR / f"{team}.md"
    if not path.exists():
        return []

    text = path.read_text(encoding="utf-8")
    items = []

    # [NOTIFY-CCR-NNN] 또는 [NOTIFY-LEGACY-CCR-NNN] 패턴
    pattern = re.compile(
        r"###\s+\[NOTIFY-(?:LEGACY-)?CCR-(\d+)\]\s*(.*)",
        re.MULTILINE,
    )

    for m in pattern.finditer(text):
        ccr_num = int(m.group(1))
        title = m.group(2).strip()

        # 상태 파싱: 이후 라인에서 "- **상태**:" 찾기
        start = m.end()
        # 다음 ### 까지의 블록
        next_heading = re.search(r"\n###\s+", text[start:])
        block_end = start + next_heading.start() if next_heading else len(text)
        block = text[start:block_end]

        status = "PENDING"  # 기본값
        status_m = re.search(r"-\s*\*\*상태\*\*\s*:\s*(\S+)", block)
        if status_m:
            status = status_m.group(1).upper()

        items.append({
            "ccr_number": ccr_num,
            "title": title,
            "status": status,
            "legacy": "LEGACY" in text[m.start():m.end()],
        })

    return items


def aggregate_notify() -> dict[str, dict]:
    """팀별 NOTIFY 집계."""
    result = {}
    for team in TEAMS:
        items = parse_notify_items(team)
        counts = {"ACK": 0, "NACK": 0, "PENDING": 0, "RESOLVED": 0}
        for item in items:
            s = item["status"]
            if s in counts:
                counts[s] += 1
            else:
                counts["PENDING"] += 1  # 알 수 없는 상태는 PENDING 처리
        result[team] = {
            "total": len(items),
            "counts": counts,
            "items": items,
        }
    return result


# ============================================================
# Hotspot 분석
# ============================================================

def extract_target_files_from_promoting() -> dict[str, int]:
    """promoting/ 파일에서 변경 대상 필드를 추출하여 파일별 빈도수 집계."""
    hotspot: dict[str, int] = {}
    if not PROMOTING.exists():
        return hotspot

    for path in sorted(PROMOTING.glob("CCR-[0-9][0-9][0-9]-*.md")):
        text = path.read_text(encoding="utf-8")
        # 변경 대상 셀에서 backtick 안의 경로 추출
        for m in re.finditer(r"`(contracts/[^`]+)`", text):
            f = m.group(1).strip()
            hotspot[f] = hotspot.get(f, 0) + 1

    return hotspot


# ============================================================
# 터미널 렌더링
# ============================================================

def render_bar(value: int, max_value: int, width: int = 40) -> str:
    """값에 비례하는 bar 문자열."""
    if max_value == 0:
        return ""
    length = round(value / max_value * width)
    return "\u2588" * length


def render_terminal(data: dict) -> str:
    """터미널용 텍스트 대시보드."""
    today = datetime.now().strftime("%Y-%m-%d")
    lines = []
    lines.append(f"CCR Status Dashboard ({today})")
    lines.append("\u2550" * 55)

    # Phase counts
    phase = data["phases"]
    max_count = max(phase["inbox"], phase["promoting"], phase["archived"], 1)

    lines.append(f"{'Phase':<14} {'Count':>5}")
    lines.append("\u2500" * 55)
    for label, key in [
        ("INBOX", "inbox"),
        ("PROMOTING", "promoting"),
        ("ARCHIVED", "archived"),
    ]:
        c = phase[key]
        bar = render_bar(c, max_count)
        lines.append(f"  {label:<12} {c:>3}   {bar}")

    lines.append("")
    lines.append("NOTIFY Status by Team")
    lines.append("\u2500" * 55)

    notify = data["notify"]
    for team in TEAMS:
        info = notify.get(team, {"total": 0, "counts": {}})
        total = info["total"]
        c = info["counts"]
        ack = c.get("ACK", 0)
        nack = c.get("NACK", 0)
        pending = c.get("PENDING", 0)
        resolved = c.get("RESOLVED", 0)
        warn = " \u26a0\ufe0f" if pending >= 10 else ""
        lines.append(
            f"  {team}: {total:>2} total -> "
            f"{ack:>2} ACK / {nack:>2} NACK / {pending:>2} PENDING"
            f"{' / ' + str(resolved) + ' RESOLVED' if resolved else ''}"
            f"{warn}"
        )

    # Hotspot
    hotspot = data.get("hotspot", {})
    if hotspot:
        lines.append("")
        lines.append("Contract Hotspots (top 10)")
        lines.append("\u2500" * 55)
        sorted_hs = sorted(hotspot.items(), key=lambda x: -x[1])[:10]
        for path, count in sorted_hs:
            lines.append(f"  {count:>2}x  {path}")

    return "\n".join(lines)


# ============================================================
# 메인
# ============================================================

def collect_data() -> dict:
    """전체 데이터 수집."""
    return {
        "date": datetime.now().strftime("%Y-%m-%d"),
        "phases": {
            "inbox": count_inbox(),
            "promoting": count_promoting(),
            "archived": count_archived(),
        },
        "notify": aggregate_notify(),
        "hotspot": extract_target_files_from_promoting(),
    }


def main() -> int:
    parser = argparse.ArgumentParser(
        description="CCR 현황 대시보드",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="JSON 형식으로 출력",
    )
    args = parser.parse_args()

    data = collect_data()

    if args.json:
        print(json.dumps(data, ensure_ascii=False, indent=2))
    else:
        print(render_terminal(data))

    return 0


if __name__ == "__main__":
    sys.exit(main())
