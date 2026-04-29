#!/usr/bin/env python3
"""
Contract Drift Audit — bo OpenAPI ↔ lobby Flutter 호출 path 정합성 검사.

2026-04-29 (PR #71, Contract Alignment Plan).

배경:
    PR #11~#69 기간 동안 인프라 자산은 cascade 검증되었으나 lobby 의 실제
    HTTP 호출 path 와 bo 의 실제 라우터 path 정합성은 검증되지 않음. 사용자
    LAN 검증 시도 (2026-04-29) 에서 `404 /api/v1/Auth/Login` 발견:

        lobby (PascalCase + /api/v1 prefix) ↔ bo (lowercase + auth root)
        /api/v1/Auth/Login                  ↔ /auth/login
        /api/v1/Auth/Verify2FA              ↔ /auth/verify-2fa
        /Series                             ↔ /api/v1/series
        ...

본 도구가 두 source 의 path 를 자동 추출하여 mismatch 매트릭스 생성.

사용:
    python tools/contract_drift_audit.py
        → bo 가 localhost:8000 에 떠있어야 OpenAPI 자동 fetch
        → lobby/repositories/*.dart 에서 path 자동 grep

    python tools/contract_drift_audit.py --bo-url http://api.ebs.local
        → 다른 bo 인스턴스 (LAN domain 등) 사용

출력:
    - stdout: 요약 통계 + 매트릭스
    - docs/4. Operations/_generated/CONTRACT_DRIFT_AUDIT.md (markdown report)
    - tools/_generated/contract_drift.json (machine-readable)

Exit:
    0 — drift 0건 (정합)
    1 — drift > 0
    2 — bo unreachable / 도구 오류
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Optional

import requests

REPO_ROOT = Path(__file__).resolve().parents[1]
LOBBY_REPOS_DIR = REPO_ROOT / "team1-frontend" / "lib" / "repositories"
LOBBY_REMOTE_DIR = REPO_ROOT / "team1-frontend" / "lib" / "data" / "remote"
OUTPUT_MD = REPO_ROOT / "docs" / "4. Operations" / "_generated" / "CONTRACT_DRIFT_AUDIT.md"
OUTPUT_JSON = REPO_ROOT / "tools" / "_generated" / "contract_drift.json"


@dataclass
class LobbyCall:
    file: str
    line: int
    method: str   # GET/POST/PUT/DELETE/PATCH
    path: str     # 호출 path 그대로 (e.g., '/Auth/Login')


@dataclass
class BoEndpoint:
    method: str   # uppercase
    path: str     # OpenAPI path (e.g., '/auth/login', '/api/v1/series')


@dataclass
class DriftReport:
    bo_paths: list[BoEndpoint] = field(default_factory=list)
    lobby_calls: list[LobbyCall] = field(default_factory=list)
    matched: list[dict] = field(default_factory=list)
    drift_lobby_unknown: list[LobbyCall] = field(default_factory=list)  # lobby uses, bo missing
    drift_bo_unused: list[BoEndpoint] = field(default_factory=list)     # bo provides, lobby ignores

    @property
    def has_drift(self) -> bool:
        return len(self.drift_lobby_unknown) > 0


def fetch_bo_openapi(bo_url: str) -> list[BoEndpoint]:
    """bo OpenAPI fetch + flatten paths × methods."""
    r = requests.get(f"{bo_url}/openapi.json", timeout=10)
    r.raise_for_status()
    spec = r.json()
    out: list[BoEndpoint] = []
    for path, ops in spec.get("paths", {}).items():
        for method in ops.keys():
            if method.lower() in {"get", "post", "put", "delete", "patch"}:
                out.append(BoEndpoint(method=method.upper(), path=path))
    return out


def grep_lobby_calls() -> list[LobbyCall]:
    """lobby 의 모든 _client.{verb}<...>('path', ...) 호출 추출."""
    out: list[LobbyCall] = []
    pattern = re.compile(
        r"_client\.(get|post|put|delete|patch)\s*<[^>]*>\s*\(\s*['\"]([^'\"]+)['\"]",
        re.MULTILINE,
    )
    for d in [LOBBY_REPOS_DIR, LOBBY_REMOTE_DIR]:
        if not d.exists():
            continue
        for f in d.rglob("*.dart"):
            if ".g.dart" in f.name or ".freezed.dart" in f.name:
                continue
            try:
                text = f.read_text(encoding="utf-8")
            except Exception:
                continue
            for m in pattern.finditer(text):
                line_no = text.count("\n", 0, m.start()) + 1
                out.append(LobbyCall(
                    file=str(f.relative_to(REPO_ROOT)).replace("\\", "/"),
                    line=line_no,
                    method=m.group(1).upper(),
                    path=m.group(2),
                ))
    return out


def normalize_path(path: str) -> str:
    """매칭용 정규화 — Dart `$id` → `{id}`, leading/trailing 슬래시 정렬."""
    # Dart string interpolation: $id, ${tableId} → {id}, {tableId}
    p = re.sub(r"\$\{(\w+)\}", r"{\1}", path)
    p = re.sub(r"\$(\w+)", r"{\1}", p)
    # case 보존 (matching strategy 가 결정)
    return p.rstrip("/")


def placeholder_normalize(path: str) -> str:
    """Placeholder 이름 무시 정규화: `{xxx}` → `{}`.

    lobby `$id` 와 bo `{competition_id}` 같은 naming convention 차이는 SSOT
    drift 가 아니므로 placeholder 이름을 익명화해서 매칭. PR #73 SSOT 정합 검증
    이후 false-positive 25건이 진짜 drift 가 아닌 placeholder 이름 차이로
    오분류된 것을 발견 (2026-04-29).
    """
    return re.sub(r"\{[^}]+\}", "{}", path)


def attempt_match(call: LobbyCall, bo_endpoints: list[BoEndpoint]) -> Optional[BoEndpoint]:
    """lobby call → bo endpoint 후보 매칭.

    매칭 전략 (점진적):
      1. exact (case + prefix)
      2. case-insensitive
      3. case-insensitive + /api/v1 prefix 추가 시도
      4. PascalCase → kebab-case 변환 후 재시도
      5. placeholder 이름 익명화 (lobby `$id` ≈ bo `{competition_id}`)
    """
    target = normalize_path(call.path)
    target_lower = target.lower()
    target_kebab = re.sub(r"(?<!^)(?=[A-Z])", "-", target).lower()
    target_ph = placeholder_normalize(target_lower)

    for ep in bo_endpoints:
        if ep.method != call.method:
            continue
        ep_path = normalize_path(ep.path)
        ep_lower = ep_path.lower()
        ep_ph = placeholder_normalize(ep_lower)

        # 1. exact
        if ep_path == target:
            return ep
        # 2. case-insensitive
        if ep_lower == target_lower:
            return ep
        # 3. /api/v1 prefix added on bo side
        if ep_lower == ("/api/v1" + target_lower):
            return ep
        # 4. PascalCase split: /Auth/Verify2FA → /auth/verify-2-f-a (rough)
        if ep_lower == target_kebab.lower():
            return ep
        if ep_lower == ("/api/v1" + target_kebab.lower()):
            return ep
        # 5. placeholder naming 차이만 (lobby `$id` vs bo `{competition_id}`)
        if ep_ph == target_ph:
            return ep
        if ep_ph == placeholder_normalize("/api/v1" + target_lower):
            return ep

    return None


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--bo-url", default=os.environ.get("BO_URL", "http://localhost:8000"))
    parser.add_argument("--no-write", action="store_true",
                        help="report 파일 미저장 (stdout only)")
    args = parser.parse_args()

    print(f"[audit] bo OpenAPI: {args.bo_url}/openapi.json")
    try:
        bo_eps = fetch_bo_openapi(args.bo_url)
    except Exception as e:
        print(f"[audit] ❌ bo fetch 실패: {e}", file=sys.stderr)
        print(f"        bo container 가 떠있는지 확인 (docker ps)", file=sys.stderr)
        return 2
    print(f"[audit] bo: {len(bo_eps)} endpoints")

    print(f"[audit] lobby grep: {LOBBY_REPOS_DIR.relative_to(REPO_ROOT)}")
    lobby_calls = grep_lobby_calls()
    print(f"[audit] lobby: {len(lobby_calls)} HTTP calls")

    report = DriftReport(bo_paths=bo_eps, lobby_calls=lobby_calls)

    matched_eps: set[str] = set()
    for call in lobby_calls:
        ep = attempt_match(call, bo_eps)
        if ep:
            report.matched.append({
                "lobby": asdict(call),
                "bo": asdict(ep),
            })
            matched_eps.add(f"{ep.method} {ep.path}")
        else:
            report.drift_lobby_unknown.append(call)

    for ep in bo_eps:
        if f"{ep.method} {ep.path}" not in matched_eps:
            report.drift_bo_unused.append(ep)

    # ─── stdout summary ──────────────────────────────────────────────
    print()
    print("═" * 76)
    print(" Contract Drift Audit Summary")
    print("═" * 76)
    print(f" bo endpoints       : {len(bo_eps)}")
    print(f" lobby HTTP calls   : {len(lobby_calls)}")
    print(f" matched            : {len(report.matched)}")
    print(f" lobby paths unknown: {len(report.drift_lobby_unknown)}  ⚠ 호출 fail 가능")
    print(f" bo unused          : {len(report.drift_bo_unused)}      (lobby 가 사용 안 함)")
    print("═" * 76)

    if report.drift_lobby_unknown:
        print("\n[Top 10] lobby paths bo 가 모름 (404 위험):")
        for c in report.drift_lobby_unknown[:10]:
            print(f"  {c.method:6s} {c.path:50s}  ← {c.file}:{c.line}")

    # ─── 파일 저장 ───────────────────────────────────────────────────
    if not args.no_write:
        OUTPUT_MD.parent.mkdir(parents=True, exist_ok=True)
        OUTPUT_JSON.parent.mkdir(parents=True, exist_ok=True)

        with OUTPUT_JSON.open("w", encoding="utf-8") as f:
            json.dump({
                "bo_paths_count": len(bo_eps),
                "lobby_calls_count": len(lobby_calls),
                "matched_count": len(report.matched),
                "drift_lobby_unknown_count": len(report.drift_lobby_unknown),
                "drift_bo_unused_count": len(report.drift_bo_unused),
                "matched": report.matched,
                "drift_lobby_unknown": [asdict(c) for c in report.drift_lobby_unknown],
                "drift_bo_unused": [asdict(e) for e in report.drift_bo_unused],
            }, f, indent=2, ensure_ascii=False)

        with OUTPUT_MD.open("w", encoding="utf-8") as f:
            f.write("---\n")
            f.write("title: Contract Drift Audit Report (auto-generated)\n")
            f.write("owner: conductor\n")
            f.write("tier: internal\n")
            f.write("auto_generated_by: tools/contract_drift_audit.py\n")
            f.write("---\n\n")
            f.write("# Contract Drift Audit (bo ↔ lobby)\n\n")
            f.write("> ⚠ 본 문서는 자동 생성. 수정하지 마세요. 갱신은 audit 도구 재실행.\n\n")
            f.write("## 요약\n\n")
            f.write(f"| 항목 | 값 |\n|------|----|\n")
            f.write(f"| bo endpoints | {len(bo_eps)} |\n")
            f.write(f"| lobby HTTP calls | {len(lobby_calls)} |\n")
            f.write(f"| matched | {len(report.matched)} |\n")
            f.write(f"| **lobby paths unknown (404 risk)** | **{len(report.drift_lobby_unknown)}** |\n")
            f.write(f"| bo unused | {len(report.drift_bo_unused)} |\n\n")

            if report.drift_lobby_unknown:
                f.write("## Drift A — lobby 가 호출하지만 bo 가 모름 (404 위험)\n\n")
                f.write("| method | lobby path | 파일:줄 |\n|--------|-----------|--------|\n")
                for c in report.drift_lobby_unknown:
                    f.write(f"| `{c.method}` | `{c.path}` | `{c.file}:{c.line}` |\n")
                f.write("\n")

            if report.drift_bo_unused:
                f.write("## Drift B — bo 가 제공하지만 lobby 가 호출 안 함 (정보)\n\n")
                f.write("| method | bo path |\n|--------|--------|\n")
                for e in report.drift_bo_unused[:50]:
                    f.write(f"| `{e.method}` | `{e.path}` |\n")
                if len(report.drift_bo_unused) > 50:
                    f.write(f"| ... | ({len(report.drift_bo_unused) - 50} more) |\n")
                f.write("\n")

            if report.matched:
                f.write("## Matched (정합 통과 — 매칭 매트릭스)\n\n")
                f.write("| method | lobby path | → | bo path | 파일 |\n|--------|-----------|---|---------|------|\n")
                for m in report.matched[:50]:
                    f.write(f"| `{m['lobby']['method']}` | `{m['lobby']['path']}` | → | `{m['bo']['path']}` | `{m['lobby']['file']}` |\n")
                if len(report.matched) > 50:
                    f.write(f"| ... | ({len(report.matched) - 50} more) | | | |\n")
                f.write("\n")

        print(f"\n📄 reports written:")
        print(f"  {OUTPUT_MD.relative_to(REPO_ROOT)}")
        print(f"  {OUTPUT_JSON.relative_to(REPO_ROOT)}")

    return 1 if report.has_drift else 0


if __name__ == "__main__":
    sys.exit(main())
