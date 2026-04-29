#!/usr/bin/env python3
"""
Lobby SSOT Path Alignment Script.

PR #72 — Backend_HTTP.md (SSOT) 기준으로 lobby 의 모든 PascalCase HTTP path 를
lowercase + kebab-case 로 일괄 변환.

규칙:
  1. PascalCase → lowercase + kebab-case
     예: '/Auth/Login' → '/auth/login'
         '/Verify2FA'   → '/verify-2fa'
         '/BlindStructures' → '/blind-structures'
         '/ForceLogout' → '/force-logout'
  2. Dart string interpolation (`$id`, `${seriesId}`) 은 그대로 보존
  3. _client.{verb}<...>('path', ...) 패턴만 매칭 (mock_dio_adapter.dart 도 동일 적용)
  4. auth_interceptor.dart 의 `endsWith('/Auth/Refresh')` 패턴도 변환

대상 파일:
  team1-frontend/lib/repositories/*.dart
  team1-frontend/lib/data/remote/auth_interceptor.dart
  team1-frontend/lib/data/local/mock_dio_adapter.dart
  team1-frontend/lib/data/local/mock_scenario_adapter.dart  (path 매칭 패턴)

dry-run:
  python tools/lobby_path_align.py --dry-run
실행:
  python tools/lobby_path_align.py
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]


def to_kebab_lower(segment: str) -> str:
    """PascalCase / camelCase / 숫자 혼합 → kebab-case lowercase.

    Verify2FA  → verify-2fa
    Login      → login
    BlindStructures → blind-structures
    ForceLogout    → force-logout
    Auth       → auth

    SSOT (Auth_and_Session.md): /auth/verify-2fa (not verify-2-fa).
    숫자+letter 경계는 분리하지 않고 그대로 둔다 (acronym 보존: 2FA, 3DS 등).
    """
    # 1. lowercase + Pascal 경계 분리:
    #    'Verify2FA' → 'Verify-2FA' → 'verify-2fa'
    #    'BlindStructures' → 'Blind-Structures' → 'blind-structures'
    s = re.sub(r"(?<=[a-z])(?=[A-Z0-9])", "-", segment)
    s = re.sub(r"(?<=[A-Z])(?=[A-Z][a-z])", "-", s)
    # 숫자 경계는 분리 안 함 (2FA → 2-FA 방지). 'Verify2FA' 의 경우 위에서
    # 'Verify-2FA' 로 1차 분리 됐고, 추가 분리 없이 lowercase 만 적용.
    s = s.lower()
    s = re.sub(r"-+", "-", s).strip("-")
    return s


def transform_path(path: str) -> str:
    """HTTP path 변환. Dart string interpolation 보존.

    '/Auth/Verify2FA' → '/auth/verify-2fa'
    '/Series/$id'     → '/series/$id'
    '/Tables/$tableId/Seats/$seatNo' → '/tables/$tableId/seats/$seatNo'
    """
    # Path 가 / 로 시작하지 않으면 그대로 (예외 케이스)
    if not path.startswith("/"):
        return path

    parts = path.split("/")
    out_parts = []
    for p in parts:
        if not p:
            out_parts.append("")
            continue
        # Dart string interpolation: $id, ${seriesId} → 그대로
        if p.startswith("$") or p.startswith("${"):
            out_parts.append(p)
            continue
        # query string (?) 분리
        if "?" in p:
            head, q = p.split("?", 1)
            out_parts.append(f"{to_kebab_lower(head)}?{q}")
            continue
        out_parts.append(to_kebab_lower(p))
    return "/".join(out_parts)


# ── 매뉴얼 override (semantic 차이) ─────────────────────────────
# 단순 kebab-case 변환만으로 부족한 경우 명시 매핑.
# audit 후 발견된 경우 추가.
MANUAL_OVERRIDES: dict[str, str] = {
    # SSOT 명시 endpoint (Auth_and_Session.md §8 Password Reset):
    "/auth/forgot-password": "/auth/password/reset/send",
    # 나머지는 자동 변환으로 SSOT 와 정합 검증
}


def apply_overrides(path: str) -> str:
    if path in MANUAL_OVERRIDES:
        return MANUAL_OVERRIDES[path]
    return path


# ── 파일 단위 처리 ─────────────────────────────────────────────────
# Nested generic 지원: <Map<String, dynamic>>, <List<XYZ>> 등.
# 핵심 아이디어: type param 영역 = '<' 로 시작, '>(' 로 끝.
# 중간에 임의 문자 (개행/공백/제너릭 nesting 포함) 허용.
PATH_PATTERN = re.compile(
    r"(_client\.(?:get|post|put|delete|patch|upload)\s*<.*?>\s*\(\s*['\"])"
    r"(/[^'\"]+)"
    r"(['\"])",
    re.DOTALL,
)
INTERCEPTOR_PATTERN = re.compile(
    r"(\.endsWith\(\s*['\"])"
    r"(/[^'\"]+)"
    r"(['\"]\s*\))"
)


def process_file(path: Path, dry_run: bool = False) -> int:
    """파일 1개의 path 들을 일괄 변환. 변환 횟수 반환."""
    text = path.read_text(encoding="utf-8")
    changes = 0

    def repl(m: re.Match) -> str:
        nonlocal changes
        prefix, http_path, suffix = m.group(1), m.group(2), m.group(3)
        new_path = apply_overrides(transform_path(http_path))
        if new_path != http_path:
            changes += 1
        return f"{prefix}{new_path}{suffix}"

    new_text = PATH_PATTERN.sub(repl, text)
    new_text = INTERCEPTOR_PATTERN.sub(repl, new_text)

    # mock_dio_adapter.dart 전용: regex/string literal 안의 PascalCase path segment
    # 변환. /Auth/Login → /auth/login, /Tables/(\d+)/Seats → /tables/(\d+)/seats.
    # path segment = 슬래시 다음에 [A-Z] 로 시작하는 alphanumeric (regex metachar 제외).
    if path.name == "mock_dio_adapter.dart":
        def seg_repl(m: re.Match) -> str:
            nonlocal changes
            seg = m.group(0)  # /Foo
            new_seg = "/" + to_kebab_lower(seg[1:])
            if new_seg != seg:
                changes += 1
            return new_seg

        new_text = re.sub(r"/[A-Z][a-zA-Z0-9]*", seg_repl, new_text)

    if changes > 0:
        if dry_run:
            print(f"[dry-run] {path.relative_to(REPO_ROOT)} — {changes} path(s) would change")
        else:
            path.write_text(new_text, encoding="utf-8")
            print(f"✓ {path.relative_to(REPO_ROOT)} — {changes} path(s) updated")

    return changes


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    targets: list[Path] = []
    targets.extend(sorted((REPO_ROOT / "team1-frontend" / "lib" / "repositories").rglob("*.dart")))
    for sub in [
        REPO_ROOT / "team1-frontend" / "lib" / "data" / "remote" / "auth_interceptor.dart",
        REPO_ROOT / "team1-frontend" / "lib" / "data" / "local" / "mock_dio_adapter.dart",
        REPO_ROOT / "team1-frontend" / "lib" / "data" / "local" / "mock_scenario_adapter.dart",
    ]:
        if sub.exists():
            targets.append(sub)

    # generated 파일 제외
    targets = [t for t in targets if ".g.dart" not in t.name and ".freezed.dart" not in t.name]

    total = 0
    for t in targets:
        total += process_file(t, dry_run=args.dry_run)

    print(f"\n{'[dry-run] would change' if args.dry_run else '✓ updated'}: {total} path(s) across {len(targets)} files")
    return 0


if __name__ == "__main__":
    sys.exit(main())
