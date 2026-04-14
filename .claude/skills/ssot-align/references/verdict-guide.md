# Verdict guide

Decision rules for the mapping table's Verdict column. Applied per row.

## The six verdicts

| Verdict | When to use | Adapter needed |
|---------|-------------|----------------|
| IDENTICAL | Local value exactly matches upstream: same name, same type, same semantics | No |
| RENAMED | Same semantics, different surface form (case, language, style) | Yes, both directions |
| SUBSET | Local keeps a proper subset of upstream values | Yes, plus explicit handling of unknown inputs |
| SUPERSET | Local adds values beyond upstream (project-specific extensions) | Yes, on outbound only (drop or guard extras) |
| DIVERGENT | Semantics differ enough that mapping by value alone is unsafe | Yes, structural adapter required |
| DEFERRED | Not mapped yet. Decision postponed to a later phase | Document the phase target |

## Decision tree

```
Is the local side missing this value?
  └─ yes → DEFERRED (and schedule in a phase bucket)
  └─ no  →  Does surface form match exactly (including case, separators, type)?
              └─ yes → IDENTICAL
              └─ no  →  Do semantics match?
                          ├─ yes → RENAMED
                          └─ no  →  Does local cover a strict subset of upstream?
                                      ├─ yes → SUBSET
                                      └─ no  →  Does local cover strictly more than upstream?
                                                  ├─ yes → SUPERSET
                                                  └─ no  → DIVERGENT
```

## Tie-breakers

- If upstream is a single integer code (e.g. `StartClock = 201`) and local uses a string label
  with the same meaning, classify as RENAMED. Write the adapter as a two-way map table.
- If upstream is a structured object and local decomposes it into several fields, classify as
  DIVERGENT, not RENAMED.
- A missing-on-purpose decision (explicit "we will never support this") is still DEFERRED with
  a Phase called `NEVER` (or project-defined) in the migration plan.

## Adapter expectations per verdict

- IDENTICAL: no adapter. Direct pass-through. A contract test is still recommended to catch
  silent upstream renames.
- RENAMED: bidirectional adapter. Both `upstream_to_local(x)` and `local_to_upstream(y)`
  required if the local side ever sends values outbound.
- SUBSET: inbound adapter must define behavior for every upstream value not in the subset.
  Typical options: drop with log, map to a sentinel, raise.
- SUPERSET: outbound adapter strips extras; inbound accepts anything upstream sends.
- DIVERGENT: structural adapter. Unit-test every non-trivial transformation.
- DEFERRED: no adapter yet. The migration plan references a phase target, not a file.

## Common traps

- Treating a language-style change (snake_case vs PascalCase) as IDENTICAL. It is RENAMED —
  an adapter is still required for wire-format compatibility.
- Treating a truncated enum as SUPERSET. If the local side has fewer values, it is SUBSET.
- Treating "we chose different field names that mean the same thing" as DIVERGENT. If there is
  a clean per-value mapping, it is RENAMED, not DIVERGENT.
