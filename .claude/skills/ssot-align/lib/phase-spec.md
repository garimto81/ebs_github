# Phase spec — detailed behavior per pipeline phase

Expanded behavior description for each of the seven phases. See `SKILL.md` for the overview.

## Phase 0 — Config load and team detection

### Inputs
- cwd
- env vars
- git repo state (optional)

### Steps
1. Walk up from cwd until `.ssot-align.yaml` is found. If none, halt and suggest `init`.
2. Parse YAML. Validate against `references/config-schema.md`. Fail loud on unknown required
   fields (forward-compat: unknown optional fields are warned, not failed).
3. Detect owner:
   - If `team_detection.env_var` is set and present → that value.
   - Else if `team_detection.git_branch_prefix` is true and branch matches `<owner>/...` → that
     prefix.
   - Else if `team_detection.cwd_prefix` is true and cwd startswith `<project-root>/<owner>-*`
     → that prefix.
   - Else `team_detection.default`.
4. Load state file if present. If `--resume`, merge into the run plan.

### Outputs
- Parsed config object
- Detected owner
- Optional state-file snapshot

## Phase 1 — Target discovery and batch planning

### Inputs
- Parsed config
- Detected owner
- Positional arguments (path/glob/section), if any

### Steps
1. Expand `targets` globs. Filter to current owner when `scope_guard.enforce_team_ownership`
   is true.
2. For each file, parse Markdown. Enumerate H2 headings as sections. (H1 is the doc title by
   convention; H3+ are sub-sections not operated on directly.)
3. Classify each section:
   - already_aligned (all five template blocks present)
   - candidate (has upstream-reference text cues: configurable pattern list)
   - native (neither of the above)
4. Estimate tokens per section. Group into batches respecting `--chunk-size`.
5. Emit the plan to the user.

### Outputs
- Ordered section list, each with `{file, heading, classification, bucket}`
- Plan displayed to user

## Phase 2 — Section → SSOT mapping

### Inputs
- Section list from Phase 1
- Connector spec
- Prior state if resuming

### Steps
1. For each candidate section:
   - If explicit source flag provided (globally or in state) → use it.
   - Else run heuristics from `lib/section-mapper.md`.
   - If still ambiguous and not `--auto-accept` → ask the user (choose from top-N candidates
     via connector.search).
2. Native sections get a synthetic `source=native`; no fetch required.

### Outputs
- Section × source-id mapping table
- Persisted to state file

## Phase 3 — Connector dispatch

### Inputs
- Mapping table
- Connector

### Steps
1. Dedup source-ids across sections (cache key = id).
2. For each unique id, `connector.fetch(id)`. Capture `version`, `url`, `fetched_at`,
   `body_markdown`.
3. On failure, mark the dependent sections as FETCH_ERROR; they become DEFERRED in later phases.

### Outputs
- Fetch cache keyed by source-id
- FETCH_ERROR list

## Phase 4 — Verbatim extraction

### Inputs
- Fetch cache
- Section classification (what kind of values to extract — enum, fields, endpoints)

### Steps
1. Use heuristics from `lib/verbatim-extractor.md`.
2. Capture in block 2 shape: timestamp, query, version, raw code block.
3. On ambiguity, present bounded options to the user.

### Outputs
- Per-section verbatim payload

## Phase 5 — Mapping and verdict

### Inputs
- Verbatim payloads
- Target file contents
- Optional: related source files declared in config (for local existence probes)

### Steps
1. For each verbatim value, grep the target file for existing local representation.
2. Propose verdict per `references/verdict-guide.md`.
3. Propose phase bucket per `references/phase-guide.md`.
4. Propose adapter file path: `config.adapter_path_rules[owner]` + kebab-case slug of the
   value-set name.
5. Present proposals. Apply per `--auto-accept`, per-section confirmation, or per-row override.

### Outputs
- Mapping table rows with decisions locked in

## Phase 6 — Template application

### Inputs
- Mapping table (finalized)
- Template file (from config)

### Steps
1. Render the five-block section.
2. Determine placement (replace existing, or insert in-order).
3. Apply scope guard:
   - Allowed → write.
   - Disallowed → generate CCR draft at `scope_guard.ccr_draft_path` using the filename
     template. Do not touch the target.
4. Track all writes (and the pre-write content) in the state file.

### Outputs
- Updated target files, or CCR drafts
- Pre-write archive in state

## Phase 7 — Verification and reporting

### Inputs
- Set of modified files
- Mapping tables
- Pre-write archive

### Steps
1. Invoke `doc-critic` on each modified file.
2. Auto-check the verification checklist items that are mechanically verifiable.
3. Update roadmap at `config.roadmap.path`.
4. Persist state (completed rows removed from the pending set).
5. Emit final report.

### Outputs
- Roadmap update
- Final report
- Clean state file (or resume-ready state on partial failure)
