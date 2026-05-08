#!/usr/bin/env python3
"""Generate 6 .gfskin fixtures for integration-tests.

Output: 6 files + this script's siblings.

Usage:
    python integration-tests/fixtures/_generate.py

Notes:
- skin.riv는 minimal stub (RIVE magic + 헤더). 실제 Rive 파싱 통과는 보장 X.
  → Prototype_Build_Plan §7 Q6 follow-up.
- huge-51mb.gfskin은 51MB. 추후 .gitignore + on-demand 전환 검토.
"""
import json
import os
import zipfile
from pathlib import Path

FIX_DIR = Path(__file__).parent
RIVE_MAGIC = b"RIVE"  # ASCII 0x52 0x49 0x56 0x45
RIVE_STUB_HEADER = RIVE_MAGIC + b"\x07\x00\x00\x00" + b"\x00" * 32  # version=7 placeholder
INVALID_MAGIC_HEADER = b"FAKE" + b"\x00" * 36

# minimal valid skin.json
def make_skin_json(*, badge_check: str = "#00FF88") -> dict:
    return {
        "schema_version": 1,
        "name": "wsop-2026-test",
        "version": "1.0.0",
        "author": "S6 fixture generator",
        "rive_runtime_version": 7,
        "resolution": {"width": 1920, "height": 1080},
        "colors": {
            "badge_check": badge_check,
            "badge_fold": "#888888",
            "badge_bet": "#FFAA00",
            "badge_call": "#44AAFF",
            "badge_allin": "#FF3355",
        },
        "state_machines": [
            {"name": "TableSM", "inputs": []},
        ],
    }


def write_zip(path: Path, members: dict) -> None:
    """members: {filename: bytes}. None 값 = skip."""
    if path.exists():
        path.unlink()
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as z:
        for name, data in members.items():
            if data is None:
                continue
            z.writestr(name, data)


def gen_normal() -> None:
    skin_json = json.dumps(make_skin_json(), indent=2).encode("utf-8")
    write_zip(FIX_DIR / "wsop-2026-test.gfskin", {
        "skin.json": skin_json,
        "skin.riv": RIVE_STUB_HEADER,
    })


def gen_invalid_colors() -> None:
    bad = make_skin_json(badge_check="not-a-hex-color")
    skin_json = json.dumps(bad, indent=2).encode("utf-8")
    write_zip(FIX_DIR / "invalid-colors.gfskin", {
        "skin.json": skin_json,
        "skin.riv": RIVE_STUB_HEADER,
    })


def gen_huge_51mb() -> None:
    skin_json = json.dumps(make_skin_json(), indent=2).encode("utf-8")
    blob = os.urandom(51 * 1024 * 1024)  # 51 MiB
    write_zip(FIX_DIR / "huge-51mb.gfskin", {
        "skin.json": skin_json,
        "skin.riv": RIVE_STUB_HEADER,
        "assets/blob.bin": blob,
    })


def gen_missing_skin_json() -> None:
    write_zip(FIX_DIR / "missing-skin-json.gfskin", {
        "skin.riv": RIVE_STUB_HEADER,
    })


def gen_missing_skin_riv() -> None:
    skin_json = json.dumps(make_skin_json(), indent=2).encode("utf-8")
    write_zip(FIX_DIR / "missing-skin-riv.gfskin", {
        "skin.json": skin_json,
    })


def gen_invalid_rive_magic() -> None:
    skin_json = json.dumps(make_skin_json(), indent=2).encode("utf-8")
    write_zip(FIX_DIR / "invalid-rive-magic.gfskin", {
        "skin.json": skin_json,
        "skin.riv": INVALID_MAGIC_HEADER,
    })


def main() -> None:
    FIX_DIR.mkdir(parents=True, exist_ok=True)
    gen_normal()
    gen_invalid_colors()
    gen_missing_skin_json()
    gen_missing_skin_riv()
    gen_invalid_rive_magic()
    gen_huge_51mb()
    print("Generated:")
    for p in sorted(FIX_DIR.glob("*.gfskin")):
        print(f"  {p.name}: {p.stat().st_size:,} bytes")


if __name__ == "__main__":
    main()
