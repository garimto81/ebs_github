"""active-edits 레지스트리 공통 유틸.

- 저장소: meta/active-edits orphan branch. 디렉토리 active-edits/{session_id}.json
- 동기화: git worktree 또는 별도 clone 대신 stash/임시 체크아웃 회피를 위해
  **로컬 캐시 디렉토리** `.claude/.active-edits-cache/` 를 사용하고,
  fetch/push 는 별도 git 명령으로 처리한다.
- 캐시 디렉토리는 `.gitignore` 처리(별도 추가 필요).
"""
from __future__ import annotations

import datetime
import json
import os
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from _common import PROJECT  # noqa: E402

REGISTRY_BRANCH = "meta/active-edits"
CACHE_DIR = PROJECT / ".claude" / ".active-edits-cache"
SESSION_ID_FILE = PROJECT / ".claude" / ".session-id"
TTL_MINUTES = 120
GC_AGE_HOURS = 24


def _git(*args: str, check: bool = False) -> tuple[int, str]:
    try:
        r = subprocess.run(["git", *args], cwd=PROJECT, capture_output=True,
                           text=True, timeout=15)
        out = (r.stdout + r.stderr).strip()
        if check and r.returncode != 0:
            sys.stderr.write(f"[registry git {' '.join(args)}] {out}\n")
        return r.returncode, out
    except Exception as e:
        return 1, str(e)


def session_id(team: str) -> str:
    """세션당 안정된 ID. 캐시 파일에 보존."""
    if SESSION_ID_FILE.exists():
        sid = SESSION_ID_FILE.read_text(encoding="utf-8").strip()
        if sid:
            return sid
    pid = os.getpid()
    ts = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    sid = f"{team}-{ts}-{pid}"
    try:
        SESSION_ID_FILE.parent.mkdir(parents=True, exist_ok=True)
        SESSION_ID_FILE.write_text(sid, encoding="utf-8")
    except Exception:
        pass
    return sid


def now_iso() -> str:
    return datetime.datetime.now().isoformat(timespec="seconds")


def fetch_registry() -> bool:
    """원격 meta/active-edits 를 로컬 캐시로 fetch. 성공 여부 반환.
    원격에 브랜치가 없으면 빈 캐시를 보장하고 True."""
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    code, out = _git("ls-remote", "origin", REGISTRY_BRANCH)
    if code != 0 or not out.strip():
        # 원격 브랜치 없음 — 로컬 캐시만 사용
        return True
    code, _ = _git("fetch", "origin", REGISTRY_BRANCH)
    if code != 0:
        return False
    # archive 로 캐시 디렉토리에 펼치기
    import tarfile, io
    r = subprocess.run(
        ["git", "archive", "--format=tar", f"FETCH_HEAD"],
        cwd=PROJECT, capture_output=True, timeout=15,
    )
    if r.returncode != 0:
        return False
    # 기존 캐시 정리
    for f in CACHE_DIR.glob("*.json"):
        try:
            f.unlink()
        except Exception:
            pass
    try:
        with tarfile.open(fileobj=io.BytesIO(r.stdout)) as tar:
            for m in tar.getmembers():
                if m.name.startswith("active-edits/") and m.name.endswith(".json"):
                    f = tar.extractfile(m)
                    if f:
                        out_name = Path(m.name).name
                        (CACHE_DIR / out_name).write_bytes(f.read())
    except Exception as e:
        sys.stderr.write(f"[registry] archive extract failed: {e}\n")
        return False
    return True


def list_active() -> list[dict]:
    """캐시 디렉토리에서 활성 (TTL 내) claim 목록."""
    if not CACHE_DIR.exists():
        return []
    now = datetime.datetime.now()
    out = []
    for f in CACHE_DIR.glob("*.json"):
        try:
            data = json.loads(f.read_text(encoding="utf-8"))
            hb = data.get("heartbeat_at") or data.get("started_at")
            if hb:
                ts = datetime.datetime.fromisoformat(hb)
                if (now - ts).total_seconds() / 60 > TTL_MINUTES:
                    continue
            out.append(data)
        except Exception:
            continue
    return out


def my_claim_path(sid: str) -> Path:
    return CACHE_DIR / f"{sid}.json"


def write_claim(sid: str, data: dict) -> None:
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    my_claim_path(sid).write_text(json.dumps(data, ensure_ascii=False, indent=2),
                                  encoding="utf-8")


def _bot_env() -> dict:
    return {
        **os.environ,
        "GIT_AUTHOR_NAME": "active-edits-bot",
        "GIT_AUTHOR_EMAIL": "bot@local",
        "GIT_COMMITTER_NAME": "active-edits-bot",
        "GIT_COMMITTER_EMAIL": "bot@local",
        "GIT_INDEX_FILE": str(PROJECT / ".git" / "active-edits.index"),
    }


def _git_iso(*args: str) -> tuple[int, str]:
    """별도 인덱스 파일을 사용하여 메인 작업 인덱스 보호."""
    try:
        r = subprocess.run(["git", *args], cwd=PROJECT, capture_output=True,
                           text=True, timeout=15, env=_bot_env())
        return r.returncode, (r.stdout + r.stderr).strip()
    except Exception as e:
        return 1, str(e)


def _build_and_push(claim_files: list[Path], removed_names: list[str], message: str) -> bool:
    """isolated index 로 tree 빌드 → commit → push."""
    try:
        code, parent_sha = _git("rev-parse", f"refs/remotes/origin/{REGISTRY_BRANCH}")
        if code != 0:
            parent_sha = ""

        idx_path = PROJECT / ".git" / "active-edits.index"
        if idx_path.exists():
            try:
                idx_path.unlink()
            except Exception:
                pass

        if parent_sha:
            _git_iso("read-tree", parent_sha)

        for f in claim_files:
            r = subprocess.run(["git", "hash-object", "-w", str(f)],
                               cwd=PROJECT, capture_output=True, text=True, timeout=10)
            if r.returncode != 0:
                return False
            blob = r.stdout.strip()
            _git_iso("update-index", "--add", "--cacheinfo",
                     f"100644,{blob},active-edits/{f.name}")

        for name in removed_names:
            _git_iso("update-index", "--remove", f"active-edits/{name}")

        code, tree = _git_iso("write-tree")
        if code != 0:
            return False

        commit_args = ["commit-tree", tree, "-m", message]
        if parent_sha:
            commit_args += ["-p", parent_sha]
        r = subprocess.run(["git", *commit_args], cwd=PROJECT,
                           capture_output=True, text=True, timeout=10, env=_bot_env())
        if r.returncode != 0:
            return False
        commit_sha = r.stdout.strip()

        push_args = ["push"]
        if parent_sha:
            push_args.append(f"--force-with-lease=refs/heads/{REGISTRY_BRANCH}:{parent_sha}")
        push_args += ["origin", f"{commit_sha}:refs/heads/{REGISTRY_BRANCH}"]
        code, _ = _git(*push_args)
        return code == 0
    except Exception as e:
        sys.stderr.write(f"[registry _build_and_push] {e}\n")
        return False


def push_claim(sid: str) -> bool:
    claim = my_claim_path(sid)
    if not claim.exists():
        return False
    return _build_and_push([claim], [], f"active-edit: {sid}")


def remove_claim(sid: str) -> bool:
    claim = my_claim_path(sid)
    if claim.exists():
        try:
            claim.unlink()
        except Exception:
            pass
    return _build_and_push([], [f"{sid}.json"], f"active-edit: remove {sid}")
