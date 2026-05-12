"""Extract HTTP method + path from integration-tests/scenarios/*.http

Outputs JSON: list of {file, method, path_raw, path_normalized}
- path_normalized: {variable_name} → {} placeholders normalized
- Skips comment lines and request bodies
"""
from __future__ import annotations
import json
import re
import sys
from pathlib import Path

# Method + path on its own line (HTTP 1.1 standard formats inside .http)
LINE_RE = re.compile(
    r"^\s*(GET|POST|PUT|PATCH|DELETE|HEAD|OPTIONS)\s+(\S+)",
    re.IGNORECASE,
)
# {{var}} → handlebars; {var} → path param
VAR_RE = re.compile(r"\{\{[^}]+\}\}")
PARAM_RE = re.compile(r"\{[^}]+\}")


def normalize(path: str) -> str:
    # strip query string
    p = path.split("?", 1)[0]
    # remove {{baseUrl}} prefix
    p = VAR_RE.sub("", p).strip()
    # collapse path params to {}
    p = PARAM_RE.sub("{}", p)
    # ensure leading slash
    if not p.startswith("/"):
        p = "/" + p
    # strip trailing slash for normalization (except root)
    if len(p) > 1 and p.endswith("/"):
        p = p[:-1]
    return p


def extract(http_root: Path) -> list[dict]:
    rows: list[dict] = []
    for fp in sorted(http_root.glob("*.http")):
        for line in fp.read_text(encoding="utf-8", errors="ignore").splitlines():
            stripped = line.strip()
            if stripped.startswith("#") or not stripped:
                continue
            m = LINE_RE.match(line)
            if not m:
                continue
            method = m.group(1).upper()
            path_raw = m.group(2)
            rows.append({
                "file": fp.name,
                "method": method,
                "path_raw": path_raw,
                "path_norm": normalize(path_raw),
            })
    return rows


def main() -> None:
    http_root = Path("C:/claude/ebs-qa/integration-tests/scenarios")
    rows = extract(http_root)
    print(json.dumps(rows, ensure_ascii=False, indent=2))
    # Also print summary to stderr
    methods = {}
    for r in rows:
        methods[r["method"]] = methods.get(r["method"], 0) + 1
    print(f"\nTotal: {len(rows)} endpoints", file=sys.stderr)
    print(f"By method: {methods}", file=sys.stderr)
    unique = {(r["method"], r["path_norm"]) for r in rows}
    print(f"Unique (method,path_norm): {len(unique)}", file=sys.stderr)


if __name__ == "__main__":
    main()
