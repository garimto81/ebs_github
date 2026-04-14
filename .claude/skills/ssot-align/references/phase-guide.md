# Phase assignment guide

How to distribute mapping rows across `config.phase_buckets`.

## Default bucket order

Projects choose their own names and windows. The skill treats the list order as priority:
earlier entries are sooner. A common shape:

| Order | Typical name | Typical window | Meaning |
|-------|--------------|----------------|---------|
| 1 | Phase 1 | Next quarter | Must ship for baseline compatibility |
| 2 | Phase 2 | Next 2 quarters | Adds coverage; non-blocking for MVP |
| 3 | Phase 3+ | After GA | Long-tail; may never ship |

## Heuristic

For each row in the mapping table:

1. If verdict is IDENTICAL → no phase (`—`).
2. If verdict is RENAMED → Phase 1 by default, unless the row is already covered by an existing
   adapter — in that case skip the bucket and move to audit-only.
3. If verdict is SUBSET or SUPERSET → Phase 1 if the value is used in Phase 1 code paths,
   Phase 2 otherwise.
4. If verdict is DIVERGENT → Phase 1 only if a structural adapter is already planned; Phase 2
   otherwise.
5. If verdict is DEFERRED → either Phase 2 or Phase 3+. Never leave DEFERRED unassigned.

## Guardrails

- No row lands in a bucket later than the bucket hosting its direct dependencies. The skill
  surfaces a warning when a row's adapter references another row scheduled later.
- Phase 1 must remain small enough to fit the bucket's window. If the skill proposes too many
  Phase 1 items, it emits a resize warning. The user decides which rows to push to Phase 2.
- "NEVER" is not a bucket by default. Add it explicitly in `config.phase_buckets` if the project
  needs to mark values as out of scope forever.

## Batch behavior

During Phase 5 of the pipeline, the skill proposes an initial assignment for every row. In
`--auto-accept` mode it applies the heuristic above. Otherwise it asks the user to confirm per
section (not per row — one question per section with a per-row summary).
