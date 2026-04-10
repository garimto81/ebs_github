#!/usr/bin/env python3
"""
verify_ebs_drive.py -- EBS Drive 상태 검증 스크립트

MAPPING_ngd.json의 prd_registry와 실제 Drive 상태를 비교하여
불일치를 감지합니다.

실행:
    cd /c/claude && python ebs/verify_ebs_drive.py
"""
import sys
import json
import os

sys.path.insert(0, "C:/claude")

from lib.google_docs.drive_organizer import DriveOrganizer

EBS_ROOT = "1GlDqSgEDs9z8j5VY6iX3QndTLb6_8-PF"
MAPPING_FILE = r"C:\claude\ebs\docs\MAPPING_ngd.json"

GOOGLE_DOC_MIME = "application/vnd.google-apps.document"


def main():
    print("=== EBS Drive 상태 검증 ===\n")

    # MAPPING_ngd.json 로드
    with open(MAPPING_FILE, encoding="utf-8") as f:
        mapping = json.load(f)

    prd_registry = mapping.get("prd_registry", {})
    if not prd_registry:
        print("[ERR] MAPPING_ngd.json에 prd_registry가 없습니다.")
        return 1

    # Drive 조회 (DriveOrganizer가 내부에서 인증 처리)
    organizer = DriveOrganizer(root_folder_id=EBS_ROOT)
    drive_files = organizer.get_all_files(folder_id=EBS_ROOT, recursive=False)

    # ID -> name 맵 구성
    drive_map = {f.id: f.name for f in drive_files}

    errors = 0
    warnings = 0

    # prd_registry 항목 검증
    for prd_id, prd_info in prd_registry.items():
        doc_id = prd_info["doc_id"]
        expected_name = prd_info["display_name"]

        if doc_id not in drive_map:
            print(f"[ERR]  {prd_id}: Drive에 누락 ({doc_id[:16]}...)")
            errors += 1
        elif drive_map[doc_id] != expected_name:
            print(f"[WARN] {prd_id}: 이름 불일치")
            print(f"       기대값: {expected_name}")
            print(f"       실제값: {drive_map[doc_id]}")
            warnings += 1
        else:
            print(f"[OK]   {prd_id}: {expected_name} ({doc_id[:16]}...) -- 일치")

    # 미등록 문서 감지 (Google Docs 문서만)
    registered_ids = {info["doc_id"] for info in prd_registry.values()}
    for f in drive_files:
        if f.mime_type == GOOGLE_DOC_MIME and f.id not in registered_ids:
            print(f"[WARN] Drive에 미등록 파일 발견: \"{f.name}\" ({f.id[:16]}...)")
            warnings += 1

    print()
    total = len(prd_registry)
    if errors == 0 and warnings == 0:
        print(f"Drive 상태 정상 ({total}/{total} 일치)")
        return 0
    else:
        print(f"검증 완료: 오류 {errors}개, 경고 {warnings}개")
        return 1


if __name__ == "__main__":
    sys.exit(main())
