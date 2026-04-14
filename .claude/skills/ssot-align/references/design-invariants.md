# Design invariants — what keeps ssot-align generic

These rules prevent project-specific knowledge from leaking into the core skill. Violation
makes the skill unusable for other projects.

## Forbidden in the core (`SKILL.md`, `references/`, `lib/`, `commands/`)

- Names of specific services, organizations, or products (e.g. upstream service names, customer
  names, internal project codenames).
- Fixed cloud IDs, space keys, database IDs, workspace URLs, or any tenant-specific identifier.
- Named team labels or role labels tied to one project (e.g. `team1`, `frontend-squad`,
  `backend-team`).
- Hard-coded file paths beyond the skill's own directory layout. Target paths are always read
  from config.
- Language or framework choices (e.g. "adapters go under `src/adapters/` in Python"). Adapter
  paths are read from `config.adapter_path_rules`.
- Domain vocabulary from one project (e.g. poker, billing, healthcare terms).

## Allowed in the core

- Generic concepts: SSOT, connector, verbatim, mapping, verdict, phase bucket, adapter.
- Generic verdict enum values: IDENTICAL, RENAMED, SUBSET, SUPERSET, DIVERGENT, DEFERRED.
- Generic config schema keywords: `source`, `targets`, `owner`, `template`, `verdict_enum`,
  `phase_buckets`, `adapter_path_rules`, `scope_guard`, `roadmap`, `state`.
- Generic examples with placeholder names like `<project>`, `<connector>`, `<owner>`.

## Allowed specialization locations

- `connectors/<name>.md` — each connector may carry as much specialization as needed. A connector
  wrapping a service-specific skill (such as an existing Confluence skill that already knows a
  particular space and page map) preserves that specialization by delegation. The core never
  duplicates what the connector already knows.
- `templates/examples/<example-name>/` — full worked example for a real project. May mention the
  project by name. Listed in the table of contents but never referenced from core logic.
- Project-level `.ssot-align.yaml` — entirely project-owned.
- Project-local templates (path declared in config) — project-owned.

## Enforcement

- Before shipping changes to the core, run:
  `grep -rIn '<project-specific term>' skills/ssot-align/ --exclude-dir=templates/examples`
  Expect zero hits for any term tied to a single project.
- `doc-critic` invocation in Phase 7 includes an invariant scan that flags any project term
  appearing outside the examples directory.

## Quality of specialized connectors

The core makes **no promises** about search or extraction quality. That is the connector's
responsibility. If a project needs higher fidelity for a specific SSOT, the fix is to improve
the connector (or swap to a more specialized one), not to add special cases to the core.
