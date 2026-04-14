#!/usr/bin/env python3
"""EBS Drive 정리 스크립트 — 두 핵심 문서만 EBS root에 유지"""
import sys
sys.path.insert(0, r"C:\claude")

from googleapiclient.discovery import build
from lib.google_docs.auth import get_credentials

EBS_ROOT = "1GlDqSgEDs9z8j5VY6iX3QndTLb6_8-PF"

trash_doc_ids = [
    "1SQ_cx83kGliBpFAxO9vDeltnc6EetwILFbuRGY8C384",  # README
    "17qt7bq4tvesEMub7Cfc-8QIIGUhkE6csqvmdOwskzIg",  # PRD-0003-EBS-RFID
    "1n50iyuiU0TNBjUWDKFW1-88ALwZ1ClYXBuw2dW_qKOY",  # VENDOR-SELECTION
    "1WmUxqvu18oVuVGWQSjLix54c-ye7mT17ZGRMM22rAio",  # PRD-0003-Phase1
    "1qXdPbUNBEmHNQzPvYlGJA2jgujAEs2qtdANUyVjrR2I",  # Feature-Checklist
    "1eHvgCWm5BxXut5iDyOQFzaIawmFAkFAJ1v2FRbIsbN4",  # 업무 대시보드
    "125VWBAHqkgm6Fx6oTLVa-M2hz48gTGAjAtmU_ci3-aw",  # 업체 관리
    "1d5kOEWgapVOkoo9LQol8MLSH0cPDVMu9HhUy98ZZhP0",  # Phase 진행 가이드
]

trash_folder_ids = [
    "1AKvKghcaorH5A-kg9pD4rHxF5ueQWJgS",  # 01_Phase00
    "18Oz-iP3JIEQgjG-x-3zhW1RJfODrnh5s",  # 02_Phase01
    "1d3R2gdhJrUKTEzxBKng8VTR9Dv3qxBi-",  # 03_Phase02_ngd
    "1-4o14wikrZcSYCH8Y0gMT5drXQ5h5V7k",  # 04_Phase03_ngd
    "1fKZLKl5K7xEPsD1lXntxWTHBTSbIJo8-",  # 05_Operations_ngd
]

POKERGFX_PRD_ID = "1PLJuD2BbT4Jp1p6smue9ezLAfbkOSTrfVxCOXTsrau4"
PRD_0004_ID = "1y_g_h-5aso4aQgw_C5YcE8g9c5kFXYB-78mfFd5aDdk"


def trash_file(drive, file_id, label=""):
    try:
        drive.files().update(
            fileId=file_id,
            body={"trashed": True}
        ).execute()
        print(f"  [OK] Trashed: {label} ({file_id})")
        return True
    except Exception as e:
        print(f"  [FAIL] {label} ({file_id}): {e}")
        return False


def move_file(drive, file_id, target_parent, label=""):
    try:
        # 현재 부모 확인
        meta = drive.files().get(
            fileId=file_id,
            fields="id, name, parents"
        ).execute()
        current_parents = meta.get("parents", [])
        name = meta.get("name", label)

        if target_parent in current_parents:
            print(f"  [SKIP] 이미 EBS root에 있음: {name} ({file_id})")
            return True

        # 이동
        drive.files().update(
            fileId=file_id,
            addParents=target_parent,
            removeParents=",".join(current_parents),
            fields="id, parents"
        ).execute()
        print(f"  [OK] Moved to EBS root: {name} ({file_id})")
        return True
    except Exception as e:
        print(f"  [FAIL] Move {label} ({file_id}): {e}")
        return False


def main():
    print("=== EBS Drive 정리 시작 ===\n")

    creds = get_credentials()
    drive = build("drive", "v3", credentials=creds)

    # Step 1: Docs Trash
    print("[Step 1] 문서 8개 → Trash")
    doc_labels = [
        "README", "PRD-0003-EBS-RFID", "VENDOR-SELECTION",
        "PRD-0003-Phase1", "Feature-Checklist", "업무 대시보드",
        "업체 관리", "Phase 진행 가이드"
    ]
    success_docs = 0
    for fid, label in zip(trash_doc_ids, doc_labels):
        if trash_file(drive, fid, label):
            success_docs += 1
    print(f"  결과: {success_docs}/{len(trash_doc_ids)} 성공\n")

    # Step 2: Folders Trash
    print("[Step 2] 폴더 5개 → Trash")
    folder_labels = [
        "01_Phase00", "02_Phase01", "03_Phase02_ngd",
        "04_Phase03_ngd", "05_Operations_ngd"
    ]
    success_folders = 0
    for fid, label in zip(trash_folder_ids, folder_labels):
        if trash_file(drive, fid, label):
            success_folders += 1
    print(f"  결과: {success_folders}/{len(trash_folder_ids)} 성공\n")

    # Step 3: pokergfx-prd-v2 → EBS root 이동
    print("[Step 3] pokergfx-prd-v2 → EBS root 이동")
    move_file(drive, POKERGFX_PRD_ID, EBS_ROOT, "pokergfx-prd-v2")
    print()

    # Step 4: PRD-0004-EBS-Server-UI-Design → EBS root 이동
    print("[Step 4] PRD-0004-EBS-Server-UI-Design → EBS root 이동")
    move_file(drive, PRD_0004_ID, EBS_ROOT, "PRD-0004-EBS-Server-UI-Design")
    print()

    print("=== EBS Drive 정리 완료 ===")
    print(f"삭제(Trash): 문서 {success_docs}/8, 폴더 {success_folders}/5")
    print(f"EBS root 유지 문서: pokergfx-prd-v2, PRD-0004-EBS-Server-UI-Design")


if __name__ == "__main__":
    main()
