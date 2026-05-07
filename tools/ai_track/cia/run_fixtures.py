"""Run all fixtures through the pipeline and report match rate."""
from __future__ import annotations

import json
import sys
from pathlib import Path

from .engine import run_pipeline


FIXTURE_DIR = Path(__file__).parent / "fixtures"


def run_one(fx: dict) -> tuple[bool, list[str]]:
    issues: list[str] = []
    rep = run_pipeline(fx.get("description", ""), fx.get("diff", ""))
    expected_ec = set(fx.get("expected_edge_cases") or [])
    actual_ec = set(rep.edge_cases_triggered)
    if not expected_ec.issubset(actual_ec):
        missing = expected_ec - actual_ec
        issues.append(f"missing edge_cases: {missing} (got {actual_ec})")

    expected_cas = fx.get("expected_cascades") or []
    if expected_cas:
        verified_paths = {v.path for v in rep.verified}
        l1_paths = {c.path for c in rep.candidates_l1}
        l2_paths = {c.path for c in rep.candidates_l2}
        all_paths = verified_paths | l1_paths | l2_paths
        for path in expected_cas:
            if path not in all_paths:
                issues.append(f"missing cascade: {path}")

    return (len(issues) == 0), issues


def main():
    fixtures = sorted(FIXTURE_DIR.glob("*.json"))
    if not fixtures:
        print("(no fixtures)")
        return 1

    passed = 0
    print(f"Running {len(fixtures)} fixtures...")
    print("=" * 60)
    for fx_path in fixtures:
        try:
            fx = json.loads(fx_path.read_text(encoding="utf-8"))
        except Exception as e:
            print(f"[SKIP] {fx_path.name}: invalid JSON: {e}")
            continue
        name = fx.get("name", fx_path.stem)
        ok, issues = run_one(fx)
        status = "PASS" if ok else "FAIL"
        print(f"[{status}] {fx_path.name} -- {name}")
        for issue in issues:
            print(f"   - {issue}")
        if ok:
            passed += 1

    print("=" * 60)
    rate = passed / len(fixtures) if fixtures else 0
    print(f"TOTAL: {passed}/{len(fixtures)} ({rate * 100:.1f}%)")
    return 0 if rate >= 0.85 else 1


if __name__ == "__main__":
    sys.exit(main())
