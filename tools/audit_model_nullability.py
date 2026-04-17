#!/usr/bin/env python3
"""Flutter entity required 필드를 **BO 실제 응답 JSON 샘플**과 교차 검증.

OpenAPI 스키마 매칭 실패가 많아 실제 응답을 샘플링하여 검증.

사용:
    python tools/audit_model_nullability.py  # BO localhost:8000 + seed 필요
"""
from __future__ import annotations

import json
import os
import re
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ENTITIES = ROOT / "team1-frontend" / "lib" / "models" / "entities"
BO_URL = os.environ.get("EBS_BO_URL", "http://localhost:8000")

ADMIN_EMAIL = os.environ.get("EBS_ADMIN_EMAIL", "admin@ebs.local")
ADMIN_PASSWORD = os.environ.get("EBS_ADMIN_PASSWORD", "admin123")

# 파일명 → (BO 샘플 엔드포인트, 단일 or 리스트 래퍼)
# 리스트인 경우 첫 요소만 검사
SAMPLE_ENDPOINTS: dict[str, tuple[str, str]] = {
    "series.dart": ("/api/v1/series", "list"),
    "ebs_event.dart": ("/api/v1/events", "list"),
    "event_flight.dart": ("/api/v1/events/1/flights", "list"),
    "player.dart": ("/api/v1/players", "list"),
    "table.dart": ("/api/v1/tables/1", "single"),
    "table_seat.dart": ("/api/v1/tables/1/seats", "list"),
    "user.dart": ("/api/v1/users", "list"),
    "session_user.dart": ("/api/v1/auth/session", "nested:user"),
    "competition.dart": ("/api/v1/competitions", "list"),
    "blind_structure.dart": ("/api/v1/series/1/blind-structures", "list"),
    "skin.dart": ("/api/v1/skins", "list"),
    "hand.dart": ("/api/v1/hands", "list"),
    "audit_log.dart": ("/api/v1/audit-logs", "list"),
    "output_preset.dart": ("/api/v1/configs/outputs", "single"),
    "config.dart": ("/api/v1/configs/outputs", "single"),
}


def login() -> str | None:
    req = urllib.request.Request(
        f"{BO_URL}/api/v1/auth/login",
        data=json.dumps({"email": ADMIN_EMAIL, "password": ADMIN_PASSWORD}).encode(),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=5) as r:
            body = json.loads(r.read().decode())
            return body.get("data", {}).get("access_token")
    except Exception as e:
        print(f"[ERROR] login 실패: {e}")
        return None


def fetch_sample(path: str, wrapper: str, token: str) -> dict | None:
    req = urllib.request.Request(
        f"{BO_URL}{path}",
        headers={"Authorization": f"Bearer {token}"},
    )
    try:
        with urllib.request.urlopen(req, timeout=5) as r:
            body = json.loads(r.read().decode())
    except Exception as e:
        return None
    data = body.get("data", body) if isinstance(body, dict) else body
    if wrapper == "list":
        if isinstance(data, list) and data:
            return data[0]
        if isinstance(data, dict) and "items" in data and data["items"]:
            return data["items"][0]
        return None
    if wrapper == "single":
        return data if isinstance(data, dict) else None
    if wrapper.startswith("nested:"):
        key = wrapper.split(":", 1)[1]
        return data.get(key) if isinstance(data, dict) else None
    return None


def extract_required_fields(dart_src: str) -> list[dict]:
    fields = []
    factory_match = re.search(
        r"const factory \w+\(\{(.*?)\}\)\s*=\s*_\w+",
        dart_src,
        re.DOTALL,
    )
    if not factory_match:
        return fields
    body = factory_match.group(1)
    for line in body.split(","):
        line = line.strip()
        if not line or line.startswith("//"):
            continue
        has_default = "@Default" in line
        is_required = "required " in line
        if has_default or not is_required:
            continue
        jsonkey = re.search(r"@JsonKey\(name:\s*['\"]([^'\"]+)['\"]\)", line)
        json_name = jsonkey.group(1) if jsonkey else None
        type_match = re.search(
            r"required\s+([A-Za-z_][\w<>,\s?]*?)\s+(\w+)\s*$",
            line.strip(),
        )
        if not type_match:
            continue
        dart_type = type_match.group(1).strip()
        dart_name = type_match.group(2).strip()
        if not json_name:
            json_name = re.sub(r"([A-Z])", r"_\1", dart_name).lower()
        fields.append(
            {
                "dart_name": dart_name,
                "json_name": json_name,
                "type": dart_type,
            }
        )
    return fields


def main() -> int:
    if not ENTITIES.exists():
        print(f"[ERROR] {ENTITIES} 없음")
        return 2
    token = login()
    if not token:
        print("[ERROR] 로그인 토큰 획득 실패. BO 기동 + seed 확인 필요")
        return 2

    issues: list[str] = []
    total = 0

    for dart_file in sorted(ENTITIES.glob("*.dart")):
        if dart_file.name.endswith(".freezed.dart") or dart_file.name.endswith(".g.dart"):
            continue
        if dart_file.name not in SAMPLE_ENDPOINTS:
            continue
        src = dart_file.read_text(encoding="utf-8")
        fields = extract_required_fields(src)
        if not fields:
            continue
        total += len(fields)

        path, wrapper = SAMPLE_ENDPOINTS[dart_file.name]
        sample = fetch_sample(path, wrapper, token)

        print(f"\n== {dart_file.name} ({len(fields)} required) — {path} ==")
        if sample is None:
            print(f"  [WARN] 샘플 응답 없음 (seed 부족 or 엔드포인트 오류)")
            continue

        for f in fields:
            key = f["json_name"]
            if key not in sample:
                issues.append(
                    f"{dart_file.name}:{f['dart_name']} ({key}) — 응답에 **없음**"
                )
                print(f"  ❌ {f['dart_name']:25} ({key}) — MISSING")
            elif sample[key] is None:
                issues.append(
                    f"{dart_file.name}:{f['dart_name']} ({key}) — **null** 값"
                )
                print(f"  ⚠️  {f['dart_name']:25} ({key}) — NULL in sample")
            else:
                print(f"  ✓  {f['dart_name']:25} ({key}) = {type(sample[key]).__name__}")

    print("\n" + "=" * 60)
    print(f"총 required 필드: {total}")
    print(f"위험 이슈: {len(issues)}")
    if issues:
        print("\n=== 조치 필요 (@Default 또는 nullable 전환) ===")
        for i in issues:
            print(f"  - {i}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
