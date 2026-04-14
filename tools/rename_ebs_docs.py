#!/usr/bin/env python3
"""
rename_ebs_docs.py — Google Drive EBS 핵심 문서 이름을 PRD 번호 체계로 변경

실행:
    cd /c/claude && python ebs/rename_ebs_docs.py
"""

import sys
sys.path.insert(0, "C:/claude")

from lib.google_docs.auth import get_credentials
from googleapiclient.discovery import build


RENAMES = [
    {
        "file_id": "1PLJuD2BbT4Jp1p6smue9ezLAfbkOSTrfVxCOXTsrau4",
        "new_name": "PRD-0001: EBS 기초 기획서",
    },
    {
        "file_id": "1y_g_h-5aso4aQgw_C5YcE8g9c5kFXYB-78mfFd5aDdk",
        "new_name": "PRD-0002: EBS UI Design",
    },
]


def main():
    creds = get_credentials()
    service = build("drive", "v3", credentials=creds)

    for item in RENAMES:
        file_id = item["file_id"]
        new_name = item["new_name"]

        # 현재 이름 확인
        file_info = service.files().get(
            fileId=file_id,
            fields="id, name"
        ).execute()
        current_name = file_info.get("name", "(unknown)")

        print(f"[변경 전] {current_name}")

        # 이름 변경
        result = service.files().update(
            fileId=file_id,
            body={"name": new_name}
        ).execute()

        print(f"[변경 후] {result.get('name', '(unknown)')}")
        print(f"  Doc ID : {file_id}")
        print()

    print("✓ Google Docs 이름 변경 완료.")


if __name__ == "__main__":
    main()
