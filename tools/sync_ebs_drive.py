#!/usr/bin/env python3
"""
sync_ebs_drive.py -- EBS 로컬->Drive 단방향 동기화

MAPPING_ngd.json의 prd_registry 기반으로 로컬 수정 시각과 Drive 수정 시각을
비교하여 변경된 파일만 업로드합니다.

실행:
    cd /c/claude && python ebs/sync_ebs_drive.py
    cd /c/claude && python ebs/sync_ebs_drive.py --dry-run
    cd /c/claude && python ebs/sync_ebs_drive.py --force
"""
import sys
import json
import os
import argparse
import subprocess
import logging
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, "C:/claude")

from lib.google_docs.auth import get_credentials
from googleapiclient.discovery import build

EBS_ROOT = "1GlDqSgEDs9z8j5VY6iX3QndTLb6_8-PF"
MAPPING_FILE = r"C:\claude\ebs\docs\MAPPING_ngd.json"
LOG_DIR = Path(r"C:\claude\ebs\logs")


def setup_logging(log_dir: Path) -> logging.Logger:
    log_dir.mkdir(parents=True, exist_ok=True)
    log_file = log_dir / f"sync-{datetime.now().strftime('%Y-%m-%d')}.log"

    logger = logging.getLogger("ebs_sync")
    logger.setLevel(logging.INFO)

    fmt = logging.Formatter("[%(asctime)s] %(message)s", datefmt="%Y-%m-%d %H:%M:%S")

    fh = logging.FileHandler(log_file, encoding="utf-8")
    fh.setFormatter(fmt)

    ch = logging.StreamHandler()
    ch.setFormatter(fmt)

    logger.addHandler(fh)
    logger.addHandler(ch)
    return logger


def get_drive_modified_time(service, file_id: str) -> datetime:
    """Drive 파일 수정 시각 조회 (UTC)"""
    result = service.files().get(fileId=file_id, fields="modifiedTime").execute()
    dt_str = result.get("modifiedTime", "1970-01-01T00:00:00Z")
    return datetime.fromisoformat(dt_str.replace("Z", "+00:00"))


def get_local_modified_time(local_path: str) -> datetime:
    """로컬 파일 수정 시각 조회 (UTC 변환)"""
    mtime = os.path.getmtime(local_path)
    return datetime.fromtimestamp(mtime, tz=timezone.utc)


def sync_prd(
    service,
    prd_id: str,
    prd_info: dict,
    dry_run: bool,
    force: bool,
    logger: logging.Logger,
) -> bool:
    """단일 PRD 동기화. True = 성공 또는 최신"""
    doc_id = prd_info["doc_id"]
    display_name = prd_info["display_name"]
    local_file = prd_info["local_file"]

    if not os.path.exists(local_file):
        logger.warning(f"{prd_id}: 로컬 파일 없음 -> {local_file}")
        return False

    local_mtime = get_local_modified_time(local_file)
    drive_mtime = get_drive_modified_time(service, doc_id)

    if not force and local_mtime <= drive_mtime:
        logger.info(f"{prd_id}: 최신 -> 스킵 ({display_name})")
        return True

    reason = "강제 업로드" if force else "로컬 수정 감지"

    if dry_run:
        logger.info(f"{prd_id}: {reason} -> [DRY-RUN] 업로드 예정 ({display_name})")
        return True

    logger.info(f"{prd_id}: {reason} -> 업로드 시작 ({display_name})")

    try:
        result = subprocess.run(
            [
                sys.executable, "-m", "lib.google_docs", "convert",
                local_file, "--doc-id", doc_id, "--project", "EBS",
            ],
            capture_output=True,
            text=True,
            cwd="C:/claude",
            timeout=120,
        )
        if result.returncode == 0:
            logger.info(f"{prd_id}: 업로드 완료")
            return True
        else:
            logger.error(f"{prd_id}: 업로드 실패 -- {result.stderr[:300]}")
            return False
    except subprocess.TimeoutExpired:
        logger.error(f"{prd_id}: 타임아웃 (120s)")
        return False
    except Exception as e:
        logger.error(f"{prd_id}: 오류 -- {e}")
        return False


def main():
    parser = argparse.ArgumentParser(description="EBS Drive 단방향 동기화")
    parser.add_argument("--dry-run", action="store_true", help="실제 업로드 없이 변경 대상 출력만")
    parser.add_argument("--force", action="store_true", help="타임스탬프 무관 강제 전체 업로드")
    args = parser.parse_args()

    logger = setup_logging(LOG_DIR)
    logger.info("=== EBS Drive 동기화 시작 ===")
    if args.dry_run:
        logger.info("[DRY-RUN 모드]")
    if args.force:
        logger.info("[FORCE 모드]")

    with open(MAPPING_FILE, encoding="utf-8") as f:
        mapping = json.load(f)

    prd_registry = mapping.get("prd_registry", {})
    if not prd_registry:
        logger.error("MAPPING_ngd.json에 prd_registry가 없습니다.")
        return 1

    creds = get_credentials()
    service = build("drive", "v3", credentials=creds)

    success = 0
    total = len(prd_registry)

    for prd_id, prd_info in prd_registry.items():
        if sync_prd(service, prd_id, prd_info, args.dry_run, args.force, logger):
            success += 1

    logger.info(f"=== 동기화 완료: {success}/{total} 성공 ===")
    return 0 if success == total else 1


if __name__ == "__main__":
    sys.exit(main())
