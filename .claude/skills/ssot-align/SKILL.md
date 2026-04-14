---
name: ssot-align
description: >
  Align project documentation to an external Source-of-Truth (Confluence, Notion, Google Docs, or custom).
  Project-agnostic orchestration: read config → fetch SSOT via connector → extract verbatim values → build
  mapping table → generate migration plan → insert section with verification checklist. Runs per-section,
  per-file, or across an entire project scope. Team-aware via config-declared ownership.
version: 1.0.0

triggers:
  keywords:
    - "ssot-align"
    - "ssot 정렬"
    - "source of truth 정렬"
    - "외부 원본 매핑"
    - "upstream align"
  file_patterns:
    - ".ssot-align.yaml"
  context:
    - "documentation needs alignment with external live source"
    - "API compatibility mapping with upstream service"
    - "spec drift audit against Confluence/Notion/GDocs"

capabilities:
  - config_driven_discovery
  - connector_dispatch
  - verbatim_extraction
  - mapping_table_generation
  - migration_plan_scaffolding
  - scope_guard_aware
  - resume_support
  - audit_mode
  - script_assisted_execution    # delegates deterministic phases to project-declared scripts

model_preference: sonnet
phase: [1, 2]
auto_trigger: false
dependencies:
  - con-lookup       # reference Confluence connector (specialized — preserved as-is)
  - doc-critic       # Phase 6 self-check
  - skill-creator    # config wizard fallback
token_budget: 2500
---

# ssot-align — Project-agnostic SSOT alignment orchestrator

Aligns project documentation to an external live Source-of-Truth (SSOT) by reading a project-level
config, dispatching to a declared connector for SSOT lookup, and rewriting target document sections
with a standard five-block template that preserves verbatim source values plus a mapping table,
migration plan, and verification checklist.

This skill is **project-agnostic**. It knows nothing about any specific SSOT service, organization,
or team naming. All project-specific knowledge lives in:

- `.ssot-align.yaml` at the project root (what to align, which connector to use, ownership rules)
- The declared connector (e.g. `con-lookup` is a Confluence connector specialized for a given space)
- Local templates (`<project>/<template_path>`)

For the invariant list that keeps the core generic, see `references/design-invariants.md`.

## When to use

Invoke when any of these is true:

- You maintain local specs that must stay consistent with a live external source (Confluence pages,
  Notion DB, Google Docs, an upstream OpenAPI spec, etc.)
- A previous alignment exists but may have drifted and needs audit
- A new section is being authored that should preserve upstream verbatim values
- A batch refresh across many files/sections is needed at the start of a sprint

Do **not** invoke for free-form writing unrelated to an external source, or for code generation.

## Required input

One of:

1. No arguments → use `.ssot-align.yaml` at project root, process full declared scope for the
   current team owner.
2. A glob/path → restrict to that subset (still loads config for connector + ownership rules).
3. A file + section name → single-section operation. Optionally with `--source-id` or `--query` to
   skip auto-mapping.

If no config exists, invoke the init wizard: `ssot-align init` (creates `.ssot-align.yaml` from
an example template or interactive prompts).

## Execution modes

The skill supports two execution modes selected by `config.scripts` presence. Both satisfy the
same 7-Phase logical contract (next section); they differ only in which work is delegated to
external scripts vs. performed by the LLM.

### Mode detection

At invocation start, load `.ssot-align.yaml`. If `config.scripts.planner` and
`config.scripts.renderer` both resolve to existing executable files, enter **script-assisted
mode**. Otherwise, enter **LLM-only mode**.

Report the chosen mode to the user before any work begins.

### Script-assisted mode (preferred for large scopes)

Phases 0, 1, 4, 5, 6, and 7 are delegated to project-owned scripts declared in
`config.scripts`. Phases 2 and 3 remain on the LLM because they require connector tool calls
(Rovo search / MCP page fetch) that cannot run from pure Python.

Fixed three-step orchestration:

1. **Shell — planner** (Phases 0, 1, and the cached portion of Phase 2):
   ```
   <planner> [<scope>...] [--team <owner>] [--resume] [--heading <text>]
   ```
   Emits a plan artifact per `references/script-contract.md`. The LLM must not read target files
   itself — the planner extracts every fact needed.

2. **LLM — connector turns** (Phases 2 remaining + Phase 3):
   - For each unresolved batch in the plan, call the configured connector's search operation with
     the pre-composed query, then patch `source_id` into the plan per the contract. Confidence
     below threshold → mark `flagged: true`.
   - For each uncached `page_id` in the plan's fetch manifest, call the connector's fetch
     operation and write the response directly to the cache directory declared by the contract.
     Response bodies must stream to files, never remain in the LLM context.
   - For any section still `flagged: true`, use `AskUserQuestion` with bounded candidates.

3. **Shell — renderer** (Phases 4, 5, 6, 7):
   ```
   <renderer> [--dry-run | --audit] [--scope <path>...] [--heading <text>]
   ```
   Consumes plan + cache, emits the template blocks per `references/template-block-format.md`,
   applies writes (or diffs for `--dry-run`, or drift report only for `--audit`), and updates
   roadmap/state/report artifacts. Verbatim extraction is byte-identical to the cache payload —
   the renderer enforces this with an integrity assertion.

Script contract: `references/script-contract.md`. Any project shipping compatible scripts inherits
this mode automatically.

### LLM-only mode (default, no scripts declared)

The LLM walks all seven phases itself, reading target files and rendering the template inline.
Appropriate for small scopes (single file or single section). Scales poorly — expect a rough
budget of ~5 KB tokens per section across read + map + fetch + extract + verdict + render.

### Dry-run and audit cost notes

`--dry-run` and `--audit` skip local file writes but **still perform Phase 3 (connector fetch)**
because verdict comparison needs the upstream body. Budget the connector cost regardless of
write intent.

---

## Phases (execution order) — logical contract

The full pipeline has seven phases. Skip or short-circuit phases per flags (`--audit` stops after
Phase 5; `--dry-run` stops before writes in Phase 6). Detailed spec for each phase lives in
`lib/phase-spec.md`.

### Phase 0 — Config load and team detection

1. Resolve project root (walk up from cwd until `.ssot-align.yaml` is found).
2. Parse config against `references/config-schema.md`. Validate required fields.
3. Detect current team owner using `team_detection` rules in the config, in priority order:
   env var → git branch prefix → cwd prefix → default.
4. Load the state file if present (`config.state.path`) for resume support.
5. Compute the working scope: intersect declared `targets` with the detected owner's ownership
   (unless `scope_guard.enforce_team_ownership` is false).

### Phase 1 — Target discovery and batch planning

1. Glob each `targets[].path` in scope, yielding concrete file list.
2. For each file, parse Markdown headings to enumerate sections.
3. Classify each section:
   - **Already aligned**: has the five-block template already applied. Mark for audit only.
   - **Candidate for SSOT mapping**: section content mentions external concepts or existing
     inline references (e.g. "준거", "see upstream", "per spec").
   - **Project-native**: no external SSOT. Will get the native marker block.
4. Estimate token cost. If over `--chunk-size` or default budget, split into sub-batches.
5. Emit a batch plan to the user (file count, section count, connector calls expected).

### Phase 2 — Section → SSOT source mapping

For each candidate section:

1. If explicit source provided (`--source-id`, `--query`, or prior state), use it.
2. Else, propose a mapping using heuristics from `lib/section-mapper.md` (keyword scan, prior
   session state, any precomputed mapping table in the config).
3. For ambiguous or missing mappings, either:
   - Ask the user (default), or
   - With `--auto-accept`, issue a connector search and take the top hit above a confidence
     threshold; below threshold → defer the section to a DEFERRED bucket.
4. Output a file × section × source-id mapping table, cached for Phase 3.

### Phase 3 — Connector dispatch (SSOT fetch)

1. Load the connector declared by `source.connector`. If missing, fall back to `source.type`
   default (`confluence` → `connectors/confluence.md`, etc.).
2. For each unique source id, issue a single fetch. Reuse results across sections mapping to the
   same source (de-dup).
3. Capture at minimum: the document body, the upstream version string, the timestamp of the
   fetch. These are required inputs for the 📎 block.
4. Errors bubble up with section context. A failed fetch blocks only its dependent sections;
   other sections proceed.

The connector interface is defined in `connectors/README.md`. Any connector that satisfies it
can be declared in config. See `connectors/confluence.md` for a wrapper over `con-lookup`.

### Phase 4 — Verbatim value extraction

For each section with a successful fetch:

1. Extract the relevant values from the source body without altering case, ordering, or semantics.
   Heuristics per content shape (enums, field lists, endpoint tables) live in
   `lib/verbatim-extractor.md`.
2. Compose the 📋 block with: timestamp, query used, source version, and the verbatim snapshot.
3. If extraction is ambiguous (multiple candidate value sets in the source page), defer to the
   user with bounded options.

### Phase 5 — Mapping table and verdict

For each extracted value set:

1. Scan the target file and related code (via project-declared globs, optional) for the existing
   local-side representation, if any.
2. Propose a verdict per row using `references/verdict-guide.md`:
   IDENTICAL / RENAMED / SUBSET / SUPERSET / DIVERGENT / DEFERRED.
3. Propose an adapter file path from `config.adapter_path_rules[owner]` plus a kebab-cased
   derivative of the value set name.
4. Present the proposed mapping table. User confirms (default), bulk-accepts (`--auto-accept`),
   or overrides per row.

Audit mode stops here and emits a drift report without modifying files.

### Phase 6 — Write section (template application)

1. Compose the five-block section (📎 source / 📋 verbatim / 🔀 mapping / 🚀 migration /
   ✅ checklist) or the single-block native marker per template rules in
   `references/template-block-format.md`.
2. Phase assignment per `references/phase-guide.md` and the buckets in
   `config.phase_buckets`.
3. Apply to the target file:
   - Existing section → Edit replace (old content archived in state).
   - Missing section → insert at appropriate position (after the Edit History table if present,
     otherwise after the last existing §N. heading).
4. Respect `scope_guard.enforce_team_ownership`:
   - Allowed target for current owner → write in place.
   - Disallowed → write to a CCR draft per `scope_guard.on_violation`:
     `ccr_draft` (recommended), `block`, or `warn`.

Dry-run mode stops before the actual write and prints the would-be diff.

### Phase 7 — Verification, logging, report

1. Run `doc-critic` on each modified file, capturing findings.
2. Walk the ✅ checklist auto-verifiable items. Unchecked items are flagged in the report.
3. Update the roadmap at `config.roadmap.path` with completion status per file × section.
4. Persist the state file so `--resume` can pick up mid-batch next time.
5. Emit a final report: counts per verdict, CCR drafts created, doc-critic findings, unresolved
   DEFERRED items.

## Usage

See `commands/ssot-align.md` for the full command reference and examples. Quick forms:

```
/ssot-align                         # full scope, default mode
/ssot-align --dry-run               # preview writes
/ssot-align --audit                 # drift report only
/ssot-align <glob>                  # restrict scope
/ssot-align <file> <section>        # single section
/ssot-align init                    # wizard: create .ssot-align.yaml
```

## Design invariants

Do not add project-specific strings to `SKILL.md` or `references/`. All project-specific knowledge
goes in `.ssot-align.yaml`, the declared connector, and `templates/examples/<project>/` (examples
only). See `references/design-invariants.md` for the full list.

## Failure modes

- Missing config → prompt `init`.
- Connector unavailable → surface auth/URL error; do not fall through to a different connector
  silently.
- Source fetch failure for a subset of sections → emit partial report; do not roll back completed
  writes.
- Scope guard violation → CCR draft (never silent skip).

## Related skills and contracts

- `con-lookup` — an example of a specialized Confluence connector. Any service-specific
  knowledge (space, cloud ID, page map, query patterns) lives inside the connector, never in
  `ssot-align`. Projects that use a different space or service wire up their own connector via
  config.
- `doc-critic` — used in Phase 7 for self-check.
- `skill-creator` — used by `init` wizard to scaffold `.ssot-align.yaml`.
- `prd-sync` — reference implementation of the Google Docs connector pattern.
- `references/script-contract.md` — JSON schema + cache file format that project-declared
  planner/renderer scripts must implement for script-assisted mode.
- `templates/examples/<project>/` — worked example configs. Projects may copy one as a starting
  point via `/ssot-align init --from-example=<name>`.
