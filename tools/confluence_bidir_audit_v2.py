#!/usr/bin/env python3
from __future__ import annotations
import json, os, re, sys, time
from pathlib import Path
from collections import defaultdict
import requests

EBS_ROOT = Path(os.environ.get("EBS_ROOT", "/c/claude/ebs"))
DOCS_ROOT = EBS_ROOT / "docs"
sys.path.insert(0, "C:/claude")
from lib.confluence.md2confluence import get_config, api_get

WSOPLIVE_SPACE = "WSOPLive"
BASE_URL = "https://ggnetwork.atlassian.net/wiki"
REPORT_PATH = None  # set in main
JSON_PATH   = None  # set in main

def parse_frontmatter(md_path):
    text = md_path.read_text(encoding="utf-8", errors="replace")
    if not text.startswith("---
"): return {}
    end = text.find("
---
", 4)
    if end == -1: return {}
    out = {}
    for line in text[4:end].splitlines():
        m = re.match(r"^([\w-]+):\s*(.*?)\s*$", line)
        if m: out[m.group(1)] = m.group(2)
    return out

def collect_git_pages(docs_root, ebs_root):
    results = []
    for md in sorted(docs_root.rglob("*.md")):
        fm = parse_frontmatter(md)
        pid = fm.get("confluence-page-id", "")
        if not pid or pid in ("null", "none", ""): continue
        if fm.get("mirror", "") == "none": continue
        space_url = ""
        conf_url = fm.get("confluence-url", "")
        if conf_url:
            mm = re.search(r"spaces/([^/]+)/", conf_url)
            if mm: space_url = mm.group(1)
        results.append({"file": str(md.relative_to(ebs_root)), "page_id": pid,
                        "mirror": fm.get("mirror",""), "title": fm.get("title",""),
                        "space_from_url": space_url, "confluence_url": conf_url})
    return results
