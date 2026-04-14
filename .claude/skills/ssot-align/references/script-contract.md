# Script contract — planner + renderer + cache

This document specifies the data contract between `ssot-align` and project-declared scripts.
Any project whose `.ssot-align.yaml` sets `scripts.planner` and `scripts.renderer` must provide
executables that accept the CLI surface below and produce artifacts conforming to the schemas
below. The LLM orchestration layer depends on these contracts; drift will break script-assisted
mode silently.

This contract is **generic**. It does not reference any specific SSOT service, filesystem layout,
programming language, or project. Any implementation language is acceptable as long as the
executable is runnable from the project root and produces compliant artifacts.

---

## 1. Planner CLI

Invoked by the LLM at the start of Stage B.

```
<config.scripts.planner> [<scope>...] [--team <owner>] [--resume] [--heading <text>] \
                         [--out <path>] [--stdout]
```

| Argument | Meaning |
|----------|---------|
| positional `<scope>` | Zero or more file/dir paths (relative to project root) to restrict the scope. Empty ⇒ full declared scope. |
| `--team <owner>` | Override the team-detection rules. |
| `--resume` | Preserve previously patched fields (e.g. `source_id`, `flagged`) from an existing plan artifact; only refresh entries whose file changed. Without the flag, the plan is regenerated from scratch. |
| `--heading <text>` | Restrict to sections whose `##` heading text equals this string. Case-sensitive exact match. |
| `--out <path>` | Override default plan artifact path. |
| `--stdout` | Also print the plan JSON to stdout. |

Exit codes: `0` on success, non-zero on config/parse errors. The LLM must not proceed to the
connector stage if the planner exited non-zero.

## 2. Plan artifact — `plan.json`

A single JSON document. Default path: declared by the project (the default example uses
`tools/.ssot-align-plan.json`, but the path is not part of this contract).

### Top-level shape

```json
{
  "schema": "ssot-align-plan/v1",
  "generated_at": "<ISO-8601 UTC>",
  "team": "<owner-label>",
  "scope_files": <int>,
  "scope_sections": <int>,
  "config_path": "<relative path>",
  "space_key": "<string or null>",
  "files": [ <FileEntry>, ... ],
  "rovo_batches": [ <RovoBatch>, ... ],
  "fetch_manifest": [ <FetchEntry>, ... ],
  "summary": { "aligned": <int>, "cached": <int>, "unmapped": <int>,
               "native": <int>, "unique_pages": <int>, "fetch_needed": <int> }
}
```

- `schema` — fixed string. Bump when incompatible changes are made.
- `team` — the owner under which the scope was computed.
- `space_key` — optional pointer to the upstream namespace (e.g. Confluence space key). The LLM
  may embed this in connector queries; the skill does not interpret it.

### `FileEntry`

```json
{
  "path": "<project-relative path>",
  "owner": "<owner-label>",
  "sections": [ <SectionEntry>, ... ]
}
```

### `SectionEntry`

```json
{
  "heading": "<markdown ## heading text, no numbering prefix>",
  "anchor": "<slugified heading>",
  "line_start": <int>,
  "line_end": <int>,
  "status": "aligned" | "cached" | "unmapped" | "native",
  "source_id": "<string or null>",
  "confluence_hints": [ "<page_id>", ... ],
  "cache_hit": <bool>,
  "cache_version": "<string or null>",
  "flagged": <bool>
}
```

- `status`:
  - `aligned` — section already has the 5-block template applied. Audit-only target.
  - `cached` — a source mapping is known (from config or inline hints). Ready for fetch/render.
  - `unmapped` — no source mapping known. Must be resolved in the connector search step.
  - `native` — no upstream source expected; will receive the native block.
- `source_id` — upstream identifier (e.g. Confluence page id). `null` for unmapped and native.
- `cache_hit` — true iff a cache file for `source_id` exists with a recognized version.
- `flagged` — true iff human review is required (low confidence from the connector, contested
  mapping, etc.). Stage B3 must resolve these before the renderer runs.

### `RovoBatch`

```json
{
  "file": "<relative path>",
  "sections": [ "<file>#<heading>", ... ],
  "query": "<pre-composed natural-language query>"
}
```

The LLM passes `query` verbatim to the connector's search operation. The connector (not this
skill) is responsible for response interpretation.

### `FetchEntry`

```json
{
  "page_id": "<string>",
  "cached": <bool>,
  "cached_version": "<string or null>"
}
```

The LLM iterates entries with `cached == false`, calls the connector's fetch operation per
`page_id`, writes the response to the cache directory, and updates `cached`/`cached_version` in
the plan. Entries where `cached == true` are skipped.

## 3. Cache file — `page-<page_id>.json`

Default directory: project-declared (example default: `tools/.ssot-align-cache/`). The planner
detects cache hits by checking for files at this path. The renderer reads from the same path.

Exact shape:

```json
{
  "page_id": "<string>",
  "title": "<upstream title>",
  "version": "<upstream version string>",
  "fetched_at": "<ISO-8601 UTC>",
  "body": "<raw markdown, byte-preserved from the connector response>"
}
```

**Byte preservation rule**: the LLM must not normalize, trim, re-encode, or otherwise modify
`body` before writing. The renderer enforces byte-level equality between the cache `body` and
the rendered verbatim block.

## 4. Renderer CLI

Invoked by the LLM at the end of Stage B.

```
<config.scripts.renderer> [--dry-run | --audit] [--scope <path>...] [--heading <text>] \
                          [--plan <path>]
```

| Argument | Meaning |
|----------|---------|
| `--dry-run` | No target-file writes. Emit per-file unified diffs to a diff directory. Mutually exclusive with `--audit`. |
| `--audit` | No writes at all. Compute drift report only. Mutually exclusive with `--dry-run`. |
| `--scope <path>` | Restrict rendering to files matching these project-relative paths. |
| `--heading <text>` | Restrict rendering to sections whose heading matches exactly. |
| `--plan <path>` | Override plan artifact path. |

### Required behaviors

1. Load the plan and the cache directory.
2. For each `SectionEntry` with `status ∈ {aligned, cached}` and a valid cache hit, render the
   5-block template (📎 / 📋 / 🔀 / 🚀 / ✅). For `status == native`, render the single native
   block. Skip `unmapped` sections with an explicit "needs Stage B" note.
3. Byte-preserve the cache `body` into the 📋 block. Assert equality between the captured bytes
   in the rendered output and the cache body; abort the whole run on mismatch.
4. Respect `config.scope_guard.enforce_team_ownership`. On violation emit a CCR draft per
   `config.scope_guard.on_violation`.
5. Update `config.roadmap.path` (if `auto_update: true`) and `config.state.path` with
   section-level checkpoints.
6. Emit a machine-readable report artifact (default path declared by project) summarizing
   per-section outcomes: `rendered | aligned-refreshed | native | skipped-unmapped |
   skipped-nocache | skipped-missing`.

Exit codes: `0` on completion (with or without skipped sections), non-zero on integrity
violations or write failures.

## 5. Minimum viable compliance checklist

Projects implementing custom scripts should self-verify with this list before trusting
script-assisted mode:

- [ ] Planner accepts the documented CLI surface (including `--resume` and `--heading`).
- [ ] `plan.json` validates against the shape above, including the `schema` field.
- [ ] Cache file shape matches exactly. `body` is byte-identical to the connector response.
- [ ] Renderer enforces byte-level verbatim equality and aborts on mismatch.
- [ ] `--audit` produces a non-empty report without modifying any target file.
- [ ] `--dry-run` produces a diff per changed file without modifying any target file.
- [ ] `--scope` and `--heading` filters are honored consistently by planner and renderer.
- [ ] Scope guard violations produce CCR drafts or blocks per config; never silent skips.

## 6. Versioning

The `schema` field on the plan artifact is `ssot-align-plan/v1`. Any breaking change to this
contract bumps the major suffix. The skill refuses to orchestrate scripts whose output declares
a schema version newer or older than the one it supports.

## 7. Failure disposition

| Failure | Planner | Renderer |
|---------|---------|----------|
| Config missing/invalid | exit non-zero | exit non-zero |
| No targets in scope | exit 0 with empty `files` | exit 0 with empty report |
| Cache missing for a `cached` section | planner still emits the entry; renderer reports `skipped-nocache` | — |
| Verbatim byte mismatch | — | abort run, exit non-zero |
| Scope guard violation | N/A | emit CCR draft or block per config |
| Invalid `--heading` (no match) | exit 0 with empty sections | exit 0 with empty report |
