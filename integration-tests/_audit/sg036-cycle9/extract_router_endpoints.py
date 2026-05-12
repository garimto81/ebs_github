"""Extract FastAPI route decorator method + path from team2-backend/src/routers/*.py

Outputs JSON: list of {file, method, path_raw, path_normalized, line, prefix}
- Resolves router prefix from `APIRouter(prefix=...)` declaration
- path_normalized: {var} → {} placeholders
"""
from __future__ import annotations
import ast
import json
import re
import sys
from pathlib import Path

PARAM_RE = re.compile(r"\{[^}]+\}")


def normalize(path: str) -> str:
    p = path.split("?", 1)[0]
    p = PARAM_RE.sub("{}", p)
    if not p.startswith("/"):
        p = "/" + p
    if len(p) > 1 and p.endswith("/"):
        p = p[:-1]
    return p


def find_prefix(tree: ast.Module) -> str:
    """Search for `router = APIRouter(prefix='/...')` at module level."""
    for node in tree.body:
        if isinstance(node, ast.Assign):
            for target in node.targets:
                if isinstance(target, ast.Name) and target.id == "router":
                    if isinstance(node.value, ast.Call):
                        for kw in node.value.keywords:
                            if kw.arg == "prefix":
                                if isinstance(kw.value, ast.Constant):
                                    return str(kw.value.value)
    return ""


HTTP_METHODS = {"get", "post", "put", "patch", "delete", "head", "options"}


def extract_from_file(fp: Path) -> list[dict]:
    rows: list[dict] = []
    src = fp.read_text(encoding="utf-8", errors="ignore")
    try:
        tree = ast.parse(src, filename=str(fp))
    except SyntaxError:
        return rows
    prefix = find_prefix(tree)

    for node in ast.walk(tree):
        if not isinstance(node, (ast.AsyncFunctionDef, ast.FunctionDef)):
            continue
        for deco in node.decorator_list:
            # decorator forms:
            #   @router.get("/path")
            #   @router.post("/path", ...)
            if not isinstance(deco, ast.Call):
                continue
            func = deco.func
            method = None
            if isinstance(func, ast.Attribute) and func.attr in HTTP_METHODS:
                # ensure base is `router`
                if isinstance(func.value, ast.Name) and func.value.id == "router":
                    method = func.attr.upper()
            if method is None:
                continue
            if not deco.args:
                continue
            arg0 = deco.args[0]
            if not isinstance(arg0, ast.Constant) or not isinstance(arg0.value, str):
                continue
            path_raw = arg0.value
            full_path = (prefix or "") + path_raw
            rows.append({
                "file": fp.name,
                "method": method,
                "prefix": prefix,
                "path_raw": path_raw,
                "path_norm": normalize(full_path),
                "line": deco.lineno,
                "func": node.name,
            })
    return rows


def main() -> None:
    routers_root = Path("C:/claude/ebs-qa/team2-backend/src/routers")
    rows: list[dict] = []
    for fp in sorted(routers_root.glob("*.py")):
        if fp.name == "__init__.py":
            continue
        rows.extend(extract_from_file(fp))
    print(json.dumps(rows, ensure_ascii=False, indent=2))

    # summary
    methods: dict[str, int] = {}
    by_file: dict[str, int] = {}
    for r in rows:
        methods[r["method"]] = methods.get(r["method"], 0) + 1
        by_file[r["file"]] = by_file.get(r["file"], 0) + 1
    print(f"\nTotal: {len(rows)} endpoints", file=sys.stderr)
    print(f"By method: {methods}", file=sys.stderr)
    print(f"\nBy file:", file=sys.stderr)
    for f, c in sorted(by_file.items(), key=lambda kv: -kv[1]):
        print(f"  {f}: {c}", file=sys.stderr)
    unique = {(r["method"], r["path_norm"]) for r in rows}
    print(f"\nUnique (method,path_norm): {len(unique)}", file=sys.stderr)


if __name__ == "__main__":
    main()
