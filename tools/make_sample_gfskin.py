#!/usr/bin/env python3
"""SG-004 sample .gfskin 생성기 — 검증 통과용 최소 ZIP.

사용:
  python tools/make_sample_gfskin.py [출력경로]

입력:
  docs/examples/gfskin-manifest-example.json — 기준 manifest

출력 (기본):
  docs/examples/default.gfskin

구성:
  - manifest.json (example 에서 복사, audio 참조는 stub 파일로 일치시킴)
  - overlay.riv (플레이스홀더, "RIVE" magic + 빈 페이로드)
  - preview.png (512×288 투명 IDAT — Pillow 없이 생성)
  - assets/audio/*.ogg (manifest.audio_layers.file 참조분, stub 바이너리)

Exit:
  0 성공 / 1 실패
"""
from __future__ import annotations

import argparse
import json
import struct
import sys
import zipfile
import zlib
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
DEFAULT_MANIFEST = REPO / "docs" / "examples" / "gfskin-manifest-example.json"
DEFAULT_OUTPUT = REPO / "docs" / "examples" / "default.gfskin"


# ----------------------------------------------------------------- PNG

def make_minimal_png(width: int, height: int) -> bytes:
    """Pillow 없이 최소 PNG 바이너리 생성 (투명 RGBA).

    구조: signature(8) + IHDR(25) + IDAT(가변) + IEND(12)
    """

    def chunk(tag: bytes, data: bytes) -> bytes:
        length = struct.pack(">I", len(data))
        crc = struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
        return length + tag + data + crc

    signature = b"\x89PNG\r\n\x1a\n"
    # IHDR: width, height, bit_depth=8, color_type=6 (RGBA),
    # compression=0, filter=0, interlace=0
    ihdr_data = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    ihdr = chunk(b"IHDR", ihdr_data)

    # Raw image: 각 행마다 filter byte(0) + RGBA(4B) * width
    raw = bytearray()
    row = bytes(4 * width)  # all-zero pixels (transparent)
    for _ in range(height):
        raw.append(0)  # filter None
        raw.extend(row)
    idat_data = zlib.compress(bytes(raw), level=6)
    idat = chunk(b"IDAT", idat_data)

    iend = chunk(b"IEND", b"")
    return signature + ihdr + idat + iend


# ----------------------------------------------------------------- Rive placeholder

def make_placeholder_rive() -> bytes:
    """Rive 바이너리 placeholder.

    실제 Rive runtime v7+ magic 은 `b"RIVE"` 로 시작하므로 그대로 사용.
    페이로드는 최소 32 바이트의 zero filler.
    """
    return b"RIVE" + b"\x00" * 60


# ----------------------------------------------------------------- Main

def build_sample(manifest_path: Path, output: Path) -> int:
    if not manifest_path.exists():
        print(f"ERROR: manifest not found: {manifest_path}", file=sys.stderr)
        return 1
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except Exception as e:
        print(f"ERROR: manifest JSON parse fail: {e}", file=sys.stderr)
        return 1

    # 샘플에서는 manifest.rive_file 이름과 preview 이름을 정규화
    rive_name = manifest.get("rive_file") or "overlay.riv"
    manifest["rive_file"] = rive_name

    output.parent.mkdir(parents=True, exist_ok=True)
    if output.exists():
        output.unlink()

    audio_refs = []
    for layer in manifest.get("audio_layers") or []:
        if isinstance(layer, dict) and layer.get("file"):
            audio_refs.append(layer["file"])

    with zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED) as zf:
        # 1. manifest.json
        zf.writestr(
            "manifest.json",
            json.dumps(manifest, indent=2, ensure_ascii=False).encode("utf-8"),
        )
        # 2. overlay.riv
        zf.writestr(rive_name, make_placeholder_rive())
        # 3. preview.png (512×288)
        zf.writestr("preview.png", make_minimal_png(512, 288))
        # 4. audio_layers.file 참조 (stub 바이너리)
        stub_audio = b"OggS" + b"\x00" * 28  # 최소 Ogg 헤더 유사
        for ref in audio_refs:
            zf.writestr(ref, stub_audio)

    print(f"[OK] sample .gfskin written: {output}")
    print(f"  manifest entries: rive_file={rive_name}, audio={len(audio_refs)}")
    return 0


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument(
        "output",
        nargs="?",
        default=str(DEFAULT_OUTPUT),
        help=f"출력 경로 (기본: {DEFAULT_OUTPUT})",
    )
    ap.add_argument(
        "--manifest",
        default=str(DEFAULT_MANIFEST),
        help=f"manifest 입력 (기본: {DEFAULT_MANIFEST})",
    )
    args = ap.parse_args(argv)

    return build_sample(Path(args.manifest), Path(args.output))


if __name__ == "__main__":
    sys.exit(main())
