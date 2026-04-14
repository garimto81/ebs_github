# /ssot-align — command reference

Orchestrates the ssot-align pipeline over the current project scope. Reads `.ssot-align.yaml`
at the project root and dispatches to one of two execution modes based on `config.scripts`
presence.

## Mode selection

At every invocation, first detect the mode:

1. Load `.ssot-align.yaml` from the nearest ancestor of cwd.
2. If `config.scripts.planner` and `config.scripts.renderer` both resolve to existing
   executables → **script-assisted mode**.
3. Otherwise → **LLM-only mode**.

Announce the selected mode to the user before any connector or file work.

## Usage

```
/ssot-align                           # full declared scope
/ssot-align <path-or-glob>            # restrict scope
/ssot-align <file> <section>          # single section (file + exact heading text)
/ssot-align --dry-run                 # emit diffs; no target-file writes
/ssot-align --audit                   # drift report only; no writes, no diffs
/ssot-align --resume                  # preserve previous Stage B patches (script mode)
/ssot-align --source-id <id>          # skip mapping for the target section
/ssot-align --query <query>           # run a connector search manually, then prompt
/ssot-align --auto-accept             # apply default verdicts without per-row prompt
/ssot-align --chunk-size <n>          # split large batches into n-file chunks
/ssot-align --no-cache                # bypass connector cache (force refetch)
/ssot-align init                      # wizard: create .ssot-align.yaml
/ssot-align init --from-example <id>  # copy a templates/examples/<id> config
```

## Script-assisted mode — fixed 3-Stage execution

When `config.scripts` is active, run the following sequence **without adding reasoning** outside
Stage B. Arguments thread through consistently across stages.

### Stage A — shell (planner)

```
python <config.scripts.planner> [<scope>...] [--team <owner>] [--resume] [--heading <text>] \
                                [--out <config.scripts.plan_path>]
```

- Writes plan artifact per `references/script-contract.md`.
- `--resume` preserves Stage B patches (source_id, flagged) from an existing plan; without it
  the plan is regenerated from scratch.
- `--heading` restricts discovery to that exact `##` heading.
- Exit ≠ 0 → abort the whole command. Do not attempt Stage B.

### Stage B — LLM (connector orchestration)

Perform these three steps strictly in order. Do not reorder, skip, or inject extra reasoning.

**B1. Resolve unmapped sections via the connector's search operation**

For each entry in `plan.rovo_batches`:
1. Call the connector search tool with `query = batch.query` verbatim.
2. Parse the response into `{section, page_id, title, confidence}` records.
3. Patch `plan.files[*].sections[*]` where `status == "unmapped"` and the `heading` matches:
   set `source_id`, change `status` to `cached`. If `confidence < 0.7`, also set
   `flagged: true`.
4. Append any new `page_id`s to `plan.fetch_manifest` with `cached: false`.

Persist the patched plan back to `config.scripts.plan_path`.

**B2. Fetch verbatim pages via the connector's fetch operation**

For each entry in `plan.fetch_manifest` where `cached == false`:
1. Call the connector fetch tool with the declared cloud/space identifiers and
   `page_id = entry.page_id`. Request markdown body format.
2. Write the response body, version, title, and a fresh `fetched_at` timestamp to
   `config.scripts.cache_dir / page-<page_id>.json` following the contract cache schema.
   **Never retain the body in the LLM context window.**
3. Update `entry.cached = true` and `entry.cached_version = <version>` in the plan.

**B3. Flagged review fallback**

For any section still `flagged: true` after B1, use `AskUserQuestion` with up to 3 candidate
`source_id` values (from the connector response's top-K). Do not silently pick. Patch the plan
with the user's choice.

### Stage C — shell (renderer)

```
python <config.scripts.renderer> [--dry-run | --audit] [--scope <path>...] [--heading <text>] \
                                 [--plan <config.scripts.plan_path>]
```

- Default mode → writes target files in place, updates roadmap, state, report.
- `--dry-run` → writes unified diffs under `config.scripts.diff_dir`; no target-file changes.
- `--audit` → emits a drift report only; no writes, no diffs.
- Enforces byte-level verbatim equality between cache and rendered 📋 block. On mismatch it
  aborts the run; do not attempt to paper over the error.

## LLM-only mode

If `config.scripts` is not configured, the LLM walks the seven phases itself (see `SKILL.md`
"Phases — logical contract"). Appropriate for ad-hoc single-section work and for projects that
have not yet implemented compliant scripts.

## Cost notes

- **`--dry-run` and `--audit` still perform Stage B.** Connector search + page fetch run
  regardless of whether writes will occur, because drift comparison needs the upstream body.
  Only `--audit` skips the subsequent diff writes; `--dry-run` emits them.
- Cache hits skip fetches. Re-running after a successful Stage B is cheap.

## Exit conditions

| Exit | Meaning |
|------|---------|
| clean | Every in-scope section processed or intentionally skipped. |
| partial | Some connector fetches failed; the rest completed. See the final report. |
| blocked | Scope guard blocked all writes. Review CCR drafts. |
| aborted | Verbatim integrity failure or user cancellation. State file preserved for `--resume`. |

## Examples

Full sweep, dry run (see what would change):
```
/ssot-align --dry-run
```

Drift audit before a sprint:
```
/ssot-align --audit
```

Single file, single section, known source:
```
/ssot-align contracts/data/DATA-04-db-schema.md "참조 Confluence 원본" --source-id 1652949021
```

Resume after an interrupted batch:
```
/ssot-align --resume
```

Narrow scope with full write:
```
/ssot-align contracts/data/
```
