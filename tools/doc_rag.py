"""
doc_rag.py — Layer 2 RAG (Ollama + bge-m3, 100% 로컬, 카지노 LAN 호환)
======================================================================

Layer 1 (`doc_discovery.py`) 는 명시적 매칭 (frontmatter / 키워드) 만 검출.
Layer 2 RAG 는 의미적 유사도로 검출 — "Command Center 시각 변경 시 동기화 대상" 같은
자연어 쿼리에서 관련 문서 top-N 검색.

기술:
- Ollama (이미 설치됨, http://localhost:11434)
- bge-m3 모델 (이미 1.2GB pull 됨, 다국어 1024-dim)
- SQLite 저장 (외부 의존 0)

사용:
    python tools/doc_rag.py build               # 인덱스 빌드 (640 docs)
    python tools/doc_rag.py build --scope prd   # 1. Product/ + 4. Operations/ 만 (빠름)
    python tools/doc_rag.py "Command Center 시각 디자인 동기화"
    python tools/doc_rag.py --top 10 "RFID 카드 face-down 정책"
"""

from __future__ import annotations

import argparse
import json
import sqlite3
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
DOCS = REPO / "docs"
DB = REPO / ".cache" / "doc_rag.sqlite"

OLLAMA = "http://localhost:11434/api/embed"
MODEL = "bge-m3"
DIM = 1024
CHUNK_MIN = 200
CHUNK_MAX = 1800

# --------------------------------------------------------------------------
# Embed via Ollama
# --------------------------------------------------------------------------


def embed(text: str, *, retry: int = 3) -> list[float]:
    body = json.dumps({"model": MODEL, "input": text}).encode("utf-8")
    req = urllib.request.Request(
        OLLAMA, data=body, headers={"Content-Type": "application/json"}
    )
    for attempt in range(retry):
        try:
            with urllib.request.urlopen(req, timeout=30) as r:
                data = json.loads(r.read())
                return data["embeddings"][0]
        except (urllib.error.URLError, KeyError, TimeoutError) as e:
            if attempt == retry - 1:
                raise
            time.sleep(1.5 * (attempt + 1))
    raise RuntimeError("unreachable")


# --------------------------------------------------------------------------
# Chunking — H2/H3 split, length-bounded
# --------------------------------------------------------------------------


def split_chunks(text: str) -> list[tuple[str, str]]:
    """Return list of (heading, chunk_text). Frontmatter stripped."""
    if text.startswith("---"):
        end = text.find("\n---", 3)
        if end > 0:
            text = text[end + 4 :].lstrip()

    chunks: list[tuple[str, str]] = []
    cur_heading = "(intro)"
    cur_buf: list[str] = []

    def flush():
        if not cur_buf:
            return
        body = "\n".join(cur_buf).strip()
        if not body:
            return
        # length split
        if len(body) <= CHUNK_MAX:
            chunks.append((cur_heading, body))
        else:
            # split by paragraphs
            parts = body.split("\n\n")
            buf, length = [], 0
            for p in parts:
                if length + len(p) > CHUNK_MAX and buf:
                    chunks.append((cur_heading, "\n\n".join(buf).strip()))
                    buf, length = [], 0
                buf.append(p)
                length += len(p) + 2
            if buf:
                chunks.append((cur_heading, "\n\n".join(buf).strip()))

    for line in text.splitlines():
        if line.startswith("## ") or line.startswith("### "):
            flush()
            cur_heading = line.lstrip("#").strip()
            cur_buf = []
        else:
            cur_buf.append(line)
    flush()

    # merge tiny chunks
    merged: list[tuple[str, str]] = []
    for h, c in chunks:
        if merged and len(merged[-1][1]) + len(c) < CHUNK_MAX and len(c) < CHUNK_MIN:
            ph, pc = merged[-1]
            merged[-1] = (ph, pc + "\n\n" + c)
        else:
            merged.append((h, c))
    return merged


# --------------------------------------------------------------------------
# DB
# --------------------------------------------------------------------------


def init_db() -> sqlite3.Connection:
    DB.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(str(DB))
    conn.execute(
        """CREATE TABLE IF NOT EXISTS chunks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            doc_path TEXT NOT NULL,
            chunk_idx INTEGER NOT NULL,
            heading TEXT,
            text TEXT NOT NULL,
            vec BLOB NOT NULL
        )"""
    )
    conn.execute("CREATE INDEX IF NOT EXISTS idx_doc ON chunks(doc_path)")
    return conn


def vec_to_bytes(v: list[float]) -> bytes:
    import struct
    return struct.pack(f"{len(v)}f", *v)


def bytes_to_vec(b: bytes) -> list[float]:
    import struct
    return list(struct.unpack(f"{len(b) // 4}f", b))


# --------------------------------------------------------------------------
# Build
# --------------------------------------------------------------------------


def scan_targets(scope: str) -> list[Path]:
    if scope == "prd":
        roots = [DOCS / "1. Product", DOCS / "4. Operations"]
    elif scope == "memory":
        # NEW 2026-05-06 — case_studies + feedback memory 인덱스
        memory_root = Path.home() / ".claude" / "projects" / "C--claude-ebs" / "memory"
        roots = [memory_root] if memory_root.exists() else []
    elif scope == "all":
        # NEW 2026-05-06 — docs + memory 통합
        memory_root = Path.home() / ".claude" / "projects" / "C--claude-ebs" / "memory"
        roots = [DOCS]
        if memory_root.exists():
            roots.append(memory_root)
    else:
        roots = [DOCS / scope] if (DOCS / scope).exists() else [DOCS]
    files: list[Path] = []
    for r in roots:
        for md in r.rglob("*.md"):
            if "_generated" in md.parts and md.name != "full-index.md":
                continue
            if "archive" in [p.lower() for p in md.parts]:
                continue
            files.append(md)
    return sorted(files)


def build(scope: str = "all", verbose: bool = True) -> None:
    conn = init_db()
    files = scan_targets(scope)
    print(f"📚 Building index for {len(files)} docs (scope={scope}, model={MODEL}, dim={DIM})")

    # Clear existing rows for these doc_paths
    rels: list[str] = []
    for f in files:
        try:
            rel = str(f.relative_to(REPO)).replace("\\", "/")
        except ValueError:
            # Outside repo (e.g., ~/.claude/projects/.../memory/...)
            rel = str(f).replace("\\", "/")
        rels.append(rel)
    placeholders = ",".join("?" * len(rels))
    if rels:
        conn.execute(f"DELETE FROM chunks WHERE doc_path IN ({placeholders})", rels)

    total_chunks = 0
    t0 = time.time()
    for i, f in enumerate(files):
        try:
            text = f.read_text(encoding="utf-8", errors="ignore")
        except Exception as e:
            if verbose:
                print(f"  [{i+1}/{len(files)}] SKIP {f.name}: {e}")
            continue
        try:
            rel = str(f.relative_to(REPO)).replace("\\", "/")
        except ValueError:
            rel = str(f).replace("\\", "/")
        chunks = split_chunks(text)
        for ci, (heading, body) in enumerate(chunks):
            try:
                v = embed(body[:8000])  # bge-m3 8K context safe
            except Exception as e:
                print(f"  [{i+1}/{len(files)}] EMBED FAIL {f.name}#{ci}: {e}")
                continue
            conn.execute(
                "INSERT INTO chunks (doc_path, chunk_idx, heading, text, vec) VALUES (?,?,?,?,?)",
                (rel, ci, heading, body, vec_to_bytes(v)),
            )
            total_chunks += 1
        if verbose and (i + 1) % 25 == 0:
            elapsed = time.time() - t0
            rate = (i + 1) / max(elapsed, 0.01)
            eta = (len(files) - i - 1) / max(rate, 0.01)
            print(f"  [{i+1}/{len(files)}] {rel[:60]}  ETA {eta:.0f}s")
        conn.commit()
    conn.close()
    elapsed = time.time() - t0
    print(f"✅ Indexed {total_chunks} chunks from {len(files)} docs in {elapsed:.1f}s")
    print(f"   DB: {DB}")


# --------------------------------------------------------------------------
# Search
# --------------------------------------------------------------------------


def cosine(a: list[float], b: list[float]) -> float:
    s_ab = sum(x * y for x, y in zip(a, b))
    s_a2 = sum(x * x for x in a) ** 0.5
    s_b2 = sum(y * y for y in b) ** 0.5
    return s_ab / max(s_a2 * s_b2, 1e-12)


def search(query: str, top_n: int = 5, verbose: bool = True) -> list[dict]:
    if not DB.exists():
        print(f"❌ DB missing: {DB}\n   Run: python tools/doc_rag.py build")
        return []
    conn = init_db()
    qvec = embed(query)
    rows = list(conn.execute("SELECT id, doc_path, chunk_idx, heading, text, vec FROM chunks"))
    conn.close()
    if not rows:
        print("❌ Index empty. Run: python tools/doc_rag.py build")
        return []

    scored: list[tuple[float, dict]] = []
    for rid, dp, ci, h, txt, vb in rows:
        v = bytes_to_vec(vb)
        sc = cosine(qvec, v)
        scored.append((sc, {"path": dp, "chunk_idx": ci, "heading": h, "text": txt}))
    scored.sort(key=lambda x: -x[0])
    top = scored[:top_n]

    # group by doc — show best chunk per doc
    seen_docs: dict[str, tuple[float, dict]] = {}
    for sc, c in scored:
        if c["path"] not in seen_docs:
            seen_docs[c["path"]] = (sc, c)
    grouped = sorted(seen_docs.values(), key=lambda x: -x[0])[:top_n]

    if verbose:
        print(f"\n🔍 Query: {query}")
        print(f"📊 Top {top_n} (cosine, dedup by doc):\n")
        for sc, c in grouped:
            print(f"  [{sc:.3f}] {c['path']}")
            print(f"          §{c['heading']}")
            preview = c["text"].replace("\n", " ")[:140]
            print(f"          → {preview}...")
            print()

    return [c | {"score": sc} for sc, c in grouped]


# --------------------------------------------------------------------------
# CLI
# --------------------------------------------------------------------------


def main(argv: list[str]) -> int:
    # Manual sub-command dispatch (avoids argparse subparser conflict with
    # positional `query`).
    if argv and argv[0] == "build":
        sub_p = argparse.ArgumentParser(prog="doc_rag.py build")
        sub_p.add_argument("--scope", default="all")
        a = sub_p.parse_args(argv[1:])
        build(a.scope)
        return 0
    if argv and argv[0] == "info":
        if not DB.exists():
            print("DB not built")
            return 1
        conn = init_db()
        n_chunks = conn.execute("SELECT COUNT(*) FROM chunks").fetchone()[0]
        n_docs = conn.execute("SELECT COUNT(DISTINCT doc_path) FROM chunks").fetchone()[0]
        conn.close()
        print(f"📊 chunks={n_chunks}  docs={n_docs}  db={DB}")
        return 0

    p = argparse.ArgumentParser(description="doc_rag — Layer 2 semantic search")
    p.add_argument("query", nargs="+", help="자연어 쿼리 (sub-cmd: build, info)")
    p.add_argument("--top", type=int, default=5)
    args = p.parse_args(argv)
    query = " ".join(args.query)
    search(query, top_n=args.top)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
