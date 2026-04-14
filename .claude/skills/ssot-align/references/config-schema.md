# `.ssot-align.yaml` — full schema reference

Place at the project root. The skill searches upward from `cwd` until it finds this file.

## Top-level fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `version` | string | yes | Schema version. Current: `1.0`. |
| `source` | object | yes | Upstream SSOT descriptor. |
| `targets` | list | yes | What local files/folders to align. |
| `team_detection` | object | no | Owner detection rules. Default: `{ default: owner }`. |
| `template` | object | yes | Template path and block descriptors. |
| `verdict_enum` | list | no | Overrides the default verdict list. |
| `phase_buckets` | list | no | Named buckets for migration phases. |
| `adapter_path_rules` | object | no | Per-owner adapter directory mapping. |
| `scope_guard` | object | no | Ownership enforcement behavior. |
| `roadmap` | object | no | Roadmap file location and auto-update flag. |
| `state` | object | no | Resume state file location. |
| `scripts` | object | no | Paths to project-owned planner / renderer executables. Presence switches the skill to script-assisted mode (see `references/script-contract.md`). |
| `section_map` | list | no | Precomputed section → upstream-source pairings to bypass ambiguity resolution. |

## `source`

```yaml
source:
  type: confluence | notion | gdocs | custom
  connector: <skill-name>      # e.g. con-lookup
  options:                     # passed to the connector as-is
    <key>: <value>
```

The `options` block is connector-specific. See `connectors/<type>.md` for the keys each
connector expects.

## `targets`

```yaml
targets:
  - path: "<glob>"             # relative to project root
    owner: "<owner-label>"     # used by scope_guard
    description: "<optional>"  # shown in batch plan
```

Multiple entries form a union. Same owner label may appear in multiple entries.

## `team_detection`

```yaml
team_detection:
  env_var: "<ENV>"             # e.g. MY_PROJECT_TEAM
  git_branch_prefix: true      # pattern: <owner>/<anything>
  cwd_prefix: true             # pattern: <owner>-* directory name at project root
  default: "<owner-label>"     # fallback owner if none matched
```

Priority: env_var > git_branch_prefix > cwd_prefix > default.

## `template`

```yaml
template:
  path: "<relative-path>"
  blocks:                      # ordered list of visible section labels
    - "<label-1>"
    - "<label-2>"
  native_block: "<label>"      # used for project-native sections (no upstream source)
```

The block labels are display-only. Actual rendering rules live in `template-block-format.md`.

## `verdict_enum`

Default list (used when this field is omitted):

```yaml
verdict_enum:
  - IDENTICAL
  - RENAMED
  - SUBSET
  - SUPERSET
  - DIVERGENT
  - DEFERRED
```

Projects may extend, but the skill guarantees behavior only for the defaults.

## `phase_buckets`

```yaml
phase_buckets:
  - name: "<bucket-name>"
    window: "<human-readable-window>"
```

Order matters. Earlier entries mean "sooner". Values from this list are suggested during Phase 5.

## `adapter_path_rules`

```yaml
adapter_path_rules:
  "<owner-label>": "<directory-relative-to-project>"
```

When the skill proposes a new adapter for a row in the mapping table, it joins the owner's
directory with a kebab-cased derivative of the value set name. The skill does not enforce a
programming language; it only suggests a path.

## `scope_guard`

```yaml
scope_guard:
  enforce_team_ownership: true | false
  on_violation: ccr_draft | block | warn
  ccr_draft_path: "<directory-relative-to-project>"   # required if on_violation is ccr_draft
  ccr_draft_filename_template: "CCR-DRAFT-{owner}-{date}-ssot-align-{slug}.md"  # optional
```

Placeholders available in the filename template: `{owner}`, `{date}` (YYYYMMDD), `{slug}`
(kebab-cased section label), `{file}` (filename of the target).

## `roadmap`

```yaml
roadmap:
  path: "<relative-path>"
  auto_update: true | false
  columns:                     # optional, controls the roadmap table columns
    - file
    - section
    - source_id
    - verdict_summary
    - phase
    - status
    - last_checked
```

## `state`

```yaml
state:
  path: "<relative-path>"      # default: tools/.ssot-align-state.json
  format: json | yaml
  checkpoint_granularity: file | section | value
```

The state file captures: batch plan, per-section fetch cache, per-row verdict decisions,
unresolved DEFERRED items, and the position of the last processed item for `--resume`.

## `scripts`

```yaml
scripts:
  planner: "<project-relative path to planner executable>"
  renderer: "<project-relative path to renderer executable>"
  cache_dir: "<project-relative directory for cache files>"   # optional, default: tools/.ssot-align-cache/
  plan_path: "<project-relative path to plan artifact>"       # optional, default: tools/.ssot-align-plan.json
  diff_dir: "<project-relative directory for dry-run diffs>"  # optional, default: tools/.ssot-align-diff/
  report_path: "<project-relative path to report artifact>"   # optional, default: tools/.ssot-align-report.md
```

When `planner` and `renderer` both resolve to existing executables, the skill switches to
script-assisted mode for every invocation. Both entries must satisfy the contract in
`references/script-contract.md`. Missing either entry (or either file) ⇒ LLM-only mode.

The optional `cache_dir`, `plan_path`, `diff_dir`, `report_path` fields let projects relocate
ssot-align artifacts. They are passed to the scripts via CLI flags if declared.

## `section_map`

```yaml
section_map:
  - match:
      file: "<project-relative md path>"
      heading: "<heading text>" | "*"
    source_id: "<upstream identifier>"
```

Each entry declares that a given local heading (or all headings of a file when `"*"`) map to a
known upstream source id. The planner consults this list to bypass the connector-driven
resolution step. Useful for stable, manually verified mappings.

## Minimal valid config

```yaml
version: "1.0"
source:
  type: confluence
  connector: con-lookup
  options:
    cloud_id: "auto"
    space: "<space-key>"
targets:
  - path: "docs/**/*.md"
    owner: "maintainer"
template:
  path: "docs/_templates/aligned-spec.md"
  blocks:
    - "Upstream source"
    - "Verbatim extract"
    - "Mapping"
    - "Migration plan"
    - "Verification"
  native_block: "Project-native"
```

Anything beyond this is optional hardening.
