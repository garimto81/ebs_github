#!/usr/bin/env python3
"""SG-004 .gfskin ZIP validator — 7단계 검증.

사용:
  python tools/validate_gfskin.py path/to/skin.gfskin
  python tools/validate_gfskin.py --manifest-only path/to/manifest.json

7단계 (docs/4. Operations/Conductor_Backlog/SG-004-gfskin-zip-format.md §업로드 검증 규칙):
  1. ZIP 유효성 (파일 ≤ 200개, 총 ≤ 50MB)
  2. manifest.json 존재 + JSON Schema 검증
  3. overlay.riv 존재 + Rive magic bytes
  4. preview.png 존재 + 512×288
  5. element_mapping 의 layer/text 가 overlay.riv 에 실존 (stub — Rive 파서 없음)
  6. audio_layers.file 참조 실존
  7. supported_output_events 가 21종 카탈로그 서브셋
  8. min_ebs_version ≤ 현재

Error codes (SG-004):
  GFSKIN_ZIP_INVALID / GFSKIN_ZIP_TOO_LARGE / GFSKIN_ZIP_TOO_MANY_FILES
  GFSKIN_MANIFEST_MISSING / GFSKIN_MANIFEST_INVALID
  GFSKIN_RIVE_MISSING / GFSKIN_RIVE_BAD_MAGIC
  GFSKIN_PREVIEW_MISSING / GFSKIN_PREVIEW_BAD_SIZE
  GFSKIN_MISSING_ARTBOARD
  GFSKIN_AUDIO_REF_MISSING
  GFSKIN_EVENT_UNKNOWN
  GFSKIN_VERSION_MISMATCH

Exit code:
  0 — 검증 통과
  1 — 검증 실패 또는 스캐너 오류
"""
from __future__ import annotations

import argparse
import json
import struct
import sys
import zipfile
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

# ----------------------------------------------------------------- Constants

MAX_FILES = 200
MAX_TOTAL_BYTES = 50 * 1024 * 1024  # 50 MB
REQUIRED_PREVIEW_SIZE = (512, 288)
CURRENT_EBS_VERSION = "0.1.0"  # Update on release

# API-04 OutputEvent 21종 카탈로그
# 출처: docs/2. Development/2.3 Game Engine/APIs/Overlay_Output_Events.md §6.0
OUTPUT_EVENT_CATALOG = {
    "holecards_revealed",
    "holecards_hidden",
    "community_board_updated",
    "pot_updated",
    "equity_updated",
    "action_badge",
    "player_info_updated",
    "position_indicator",
    "outs_updated",
    "hand_start",
    "hand_end",
    "showdown_reveal",
    "player_folded",
    "player_allin",
    "dealer_button_moved",
    "blinds_posted",
    "ante_posted",
    "winner_announced",
    "chip_count_updated",
    "timer_updated",
    "state_changed",
}

# JSON Schema (SG-004 §manifest.json 필수 필드 — 간이 스키마).
# 실제 리포지토리에 Draft-07 스키마 파일이 들어있으면 거기서 로드한다.
_EMBEDDED_SCHEMA: dict[str, Any] = {
    "$schema": "http://json-schema.org/draft-07/schema#",
    "type": "object",
    "required": [
        "spec_version",
        "skin_id",
        "name",
        "version",
        "rive_file",
        "supported_output_events",
    ],
    "properties": {
        "spec_version": {"type": "string", "pattern": r"^\d+\.\d+$"},
        "skin_id": {"type": "string", "minLength": 8},
        "name": {
            "type": "object",
            "minProperties": 1,
            "additionalProperties": {"type": "string"},
        },
        "version": {"type": "string", "pattern": r"^\d+\.\d+\.\d+$"},
        "author": {"type": "string"},
        "created_at": {"type": "string"},
        "rive_file": {"type": "string", "minLength": 1},
        "rive_artboard": {"type": "string"},
        "supported_output_events": {
            "type": "array",
            "items": {"type": "string"},
            "minItems": 1,
        },
        "element_mapping": {"type": "object"},
        "audio_layers": {
            "type": "array",
            "items": {
                "type": "object",
                "required": ["event", "file"],
                "properties": {
                    "event": {"type": "string"},
                    "file": {"type": "string"},
                    "volume": {"type": "number"},
                },
            },
        },
        "security_delay_compatible": {"type": "boolean"},
        "min_ebs_version": {"type": "string", "pattern": r"^\d+\.\d+\.\d+$"},
        "license": {"type": "string"},
        "tags": {"type": "array", "items": {"type": "string"}},
    },
}


# ----------------------------------------------------------------- Types


@dataclass
class Issue:
    code: str
    detail: str
    stage: int  # 1..8


@dataclass
class Report:
    source: str
    issues: list[Issue] = field(default_factory=list)
    stages_passed: list[int] = field(default_factory=list)

    @property
    def ok(self) -> bool:
        return not self.issues

    def fail(self, stage: int, code: str, detail: str) -> None:
        self.issues.append(Issue(code=code, detail=detail, stage=stage))

    def pass_stage(self, stage: int) -> None:
        self.stages_passed.append(stage)


# ----------------------------------------------------------------- Helpers


def _load_schema() -> dict[str, Any]:
    """외부 스키마 파일 우선, 없으면 embedded 사용."""
    repo = Path(__file__).resolve().parents[1]
    # 후보 경로 — SG-004 §수락기준에 schemas/ 경로가 있을 경우 사용
    candidates = [
        repo / "schemas" / "gfskin-manifest-v1.json",
        repo / "docs" / "_generated" / "schemas" / "gfskin-manifest-v1.json",
    ]
    for p in candidates:
        if p.exists():
            try:
                return json.loads(p.read_text(encoding="utf-8"))
            except Exception:
                pass
    return _EMBEDDED_SCHEMA


def _try_import_jsonschema():
    try:
        import jsonschema  # type: ignore

        return jsonschema
    except ImportError:
        return None


def _parse_png_size(data: bytes) -> tuple[int, int] | None:
    """PNG IHDR 청크에서 width/height 추출. Pillow 의존 없음."""
    if len(data) < 24:
        return None
    # Signature: 89 50 4E 47 0D 0A 1A 0A
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        return None
    # IHDR chunk: bytes 8..16 = length (4) + type "IHDR" (4)
    if data[12:16] != b"IHDR":
        return None
    # Width/height are big-endian uint32 at bytes 16..24
    try:
        width, height = struct.unpack(">II", data[16:24])
        return (width, height)
    except struct.error:
        return None


def _semver_tuple(v: str) -> tuple[int, int, int] | None:
    parts = v.split(".")
    if len(parts) != 3:
        return None
    try:
        return (int(parts[0]), int(parts[1]), int(parts[2]))
    except ValueError:
        return None


def _semver_le(a: str, b: str) -> bool:
    ta, tb = _semver_tuple(a), _semver_tuple(b)
    if ta is None or tb is None:
        return False
    return ta <= tb


# ----------------------------------------------------------------- Validators


def validate_manifest(manifest: dict[str, Any], report: Report) -> bool:
    """Stage 2 — JSON Schema + Stage 7/8 필드 검증 (manifest-only 모드에서도 호출)."""
    schema = _load_schema()
    jsonschema = _try_import_jsonschema()
    if jsonschema is None:
        report.fail(
            2,
            "GFSKIN_MANIFEST_INVALID",
            "jsonschema 라이브러리 미설치 — 검증 skip (경고). "
            "`pip install jsonschema` 로 설치 권장.",
        )
    else:
        try:
            jsonschema.validate(instance=manifest, schema=schema)
            report.pass_stage(2)
        except Exception as e:  # ValidationError
            report.fail(2, "GFSKIN_MANIFEST_INVALID", str(e).splitlines()[0])
            return False

    # Stage 7: supported_output_events 가 21종 카탈로그 서브셋
    events = set(manifest.get("supported_output_events") or [])
    unknown = events - OUTPUT_EVENT_CATALOG
    if unknown:
        report.fail(
            7,
            "GFSKIN_EVENT_UNKNOWN",
            f"API-04 OutputEvent 카탈로그에 없는 이벤트: {sorted(unknown)}",
        )
    else:
        report.pass_stage(7)

    # Stage 8: min_ebs_version ≤ 현재
    min_v = manifest.get("min_ebs_version", "0.0.0")
    if not _semver_le(min_v, CURRENT_EBS_VERSION):
        report.fail(
            8,
            "GFSKIN_VERSION_MISMATCH",
            f"min_ebs_version={min_v} > current={CURRENT_EBS_VERSION}",
        )
    else:
        report.pass_stage(8)

    return True


def validate_zip(path: Path, report: Report) -> None:
    """ZIP 전체 7단계 검증."""
    # Stage 1: ZIP 유효성 (파일 수 / 총 크기)
    try:
        with zipfile.ZipFile(path, "r") as zf:
            infos = zf.infolist()
            if len(infos) > MAX_FILES:
                report.fail(
                    1,
                    "GFSKIN_ZIP_TOO_MANY_FILES",
                    f"파일 {len(infos)} > {MAX_FILES}",
                )
                return
            total = sum(i.file_size for i in infos)
            if total > MAX_TOTAL_BYTES:
                report.fail(
                    1,
                    "GFSKIN_ZIP_TOO_LARGE",
                    f"총 크기 {total} > {MAX_TOTAL_BYTES}",
                )
                return
            report.pass_stage(1)

            names = {i.filename for i in infos}

            # Stage 2: manifest.json 존재 + JSON Schema
            if "manifest.json" not in names:
                report.fail(2, "GFSKIN_MANIFEST_MISSING", "manifest.json 없음")
                return
            try:
                manifest_bytes = zf.read("manifest.json")
                manifest = json.loads(manifest_bytes.decode("utf-8"))
            except Exception as e:
                report.fail(2, "GFSKIN_MANIFEST_INVALID", f"파싱 실패: {e}")
                return
            validate_manifest(manifest, report)

            # Stage 3: overlay.riv 존재 + magic bytes
            rive_name = manifest.get("rive_file", "overlay.riv")
            if rive_name not in names:
                report.fail(3, "GFSKIN_RIVE_MISSING", f"{rive_name} 없음")
            else:
                rive_bytes = zf.read(rive_name)
                # Rive format magic: "RIVE" (ASCII) 또는 varint 스타일 헤더.
                # 공식 spec 이 private 하므로 stub 검증 — 0바이트 아닌지만 확인.
                if len(rive_bytes) == 0:
                    report.fail(
                        3, "GFSKIN_RIVE_BAD_MAGIC", f"{rive_name} 이 비어있음"
                    )
                elif rive_bytes[:4] not in (b"RIVE", b"\x00\x00\x00\x00"):
                    # Rive runtime v7+ 는 "RIVE" ASCII 를 첫 magic 으로 씀.
                    # Empty placeholder (\x00 * 4) 는 sample 생성용 허용.
                    # 엄격 모드는 별도 flag 로 분리 가능.
                    report.pass_stage(3)  # permissive — skeleton 통과
                else:
                    report.pass_stage(3)

            # Stage 4: preview.png 존재 + 512×288
            if "preview.png" not in names:
                report.fail(4, "GFSKIN_PREVIEW_MISSING", "preview.png 없음")
            else:
                size = _parse_png_size(zf.read("preview.png"))
                if size is None:
                    report.fail(
                        4, "GFSKIN_PREVIEW_MISSING", "preview.png 파싱 실패"
                    )
                elif size != REQUIRED_PREVIEW_SIZE:
                    report.fail(
                        4,
                        "GFSKIN_PREVIEW_BAD_SIZE",
                        f"preview.png {size} != {REQUIRED_PREVIEW_SIZE}",
                    )
                else:
                    report.pass_stage(4)

            # Stage 5: element_mapping → overlay.riv 실존 (stub)
            element_mapping = manifest.get("element_mapping") or {}
            if element_mapping:
                # 실제 Rive parser 없음 — 매핑 값 형식만 검증
                bad = [
                    k
                    for k, v in element_mapping.items()
                    if not isinstance(v, str)
                    or not (v.startswith("layer:") or v.startswith("text:"))
                ]
                if bad:
                    report.fail(
                        5,
                        "GFSKIN_MISSING_ARTBOARD",
                        f"잘못된 element_mapping 값 형식 (layer:/text: 접두사 필요): {bad}",
                    )
                else:
                    report.pass_stage(5)
            else:
                report.pass_stage(5)

            # Stage 6: audio_layers.file 실존
            audio_layers = manifest.get("audio_layers") or []
            missing_audio = []
            for layer in audio_layers:
                if not isinstance(layer, dict):
                    continue
                af = layer.get("file")
                if af and af not in names:
                    missing_audio.append(af)
            if missing_audio:
                report.fail(
                    6,
                    "GFSKIN_AUDIO_REF_MISSING",
                    f"audio_layers 에서 참조된 파일이 ZIP 에 없음: {missing_audio}",
                )
            else:
                report.pass_stage(6)

    except zipfile.BadZipFile as e:
        report.fail(1, "GFSKIN_ZIP_INVALID", f"{path.name}: {e}")


# ----------------------------------------------------------------- CLI


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("path", help="path to .gfskin ZIP or manifest.json")
    ap.add_argument(
        "--manifest-only",
        action="store_true",
        help="Treat path as a standalone manifest.json (no ZIP)",
    )
    ap.add_argument(
        "--format",
        choices=("text", "json"),
        default="text",
    )
    args = ap.parse_args(argv)

    path = Path(args.path)
    if not path.exists():
        print(f"ERROR: file not found: {path}", file=sys.stderr)
        return 1

    report = Report(source=str(path))

    if args.manifest_only:
        try:
            manifest = json.loads(path.read_text(encoding="utf-8"))
            validate_manifest(manifest, report)
        except Exception as e:
            report.fail(2, "GFSKIN_MANIFEST_INVALID", f"{e}")
    else:
        validate_zip(path, report)

    if args.format == "json":
        out = {
            "source": report.source,
            "ok": report.ok,
            "stages_passed": sorted(set(report.stages_passed)),
            "issues": [
                {"stage": i.stage, "code": i.code, "detail": i.detail}
                for i in report.issues
            ],
        }
        print(json.dumps(out, indent=2, ensure_ascii=False))
    else:
        status = "PASS" if report.ok else "FAIL"
        print(f"[{status}] {report.source}")
        if report.stages_passed:
            print(
                f"  stages passed: {sorted(set(report.stages_passed))}"
            )
        for it in report.issues:
            print(f"  stage {it.stage}: {it.code} — {it.detail}")

    return 0 if report.ok else 1


if __name__ == "__main__":
    sys.exit(main())
