# Template block format

Each aligned section renders five blocks for sections with an upstream source, or a single
native block for project-native sections.

## Block order

Blocks appear in a fixed order. Display labels come from `config.template.blocks`. The internal
semantics stay constant regardless of the labels chosen.

| # | Semantic role | Purpose |
|---|---------------|---------|
| 1 | upstream_source | Link and metadata for the live SSOT reference |
| 2 | verbatim_extract | Snapshot of values copied as-is from the source |
| 3 | mapping_table | Row-per-value crosswalk between source and local |
| 4 | migration_plan | Which phase, which adapter, what tests |
| 5 | verification_checklist | Auto-verifiable items for review |

Native sections render only block 6:

| # | Semantic role | Purpose |
|---|---------------|---------|
| 6 | project_native | Explicit marker that no upstream SSOT exists for this section |

## Block 1 — upstream_source

```markdown
### [block-1-label]

- Source page: [title]
- Source id: `<id>`
- URL: <url>
- Fetch command: `<connector-specific example>`
- Query used (if search-based): `<query string>`
- Last fetched: YYYY-MM-DD HH:MM TZ
- Source version: `<version-string-from-connector>`
```

All fields except `Query used` are required. The connector must supply `version` and the
ability to produce a stable URL.

## Block 2 — verbatim_extract

```markdown
### [block-2-label]

> Fetched: YYYY-MM-DD HH:MM TZ (source version <version>)

<code fence with the extracted raw values, preserving case and original notation>
```

Rules:

- No normalization. PascalCase stays PascalCase. Integer codes preserved.
- Keep the minimum necessary context for a human to verify the extraction.
- Do not editorialize. Comments inside the code fence must be quotes from the source, not
  commentary.

## Block 3 — mapping_table

Markdown table with one row per upstream value (enum entry, field, endpoint, etc.).

```markdown
### [block-3-label]

| Upstream | Upstream type | Local | Local type | Verdict | Phase | Adapter |
|----------|---------------|-------|------------|---------|-------|---------|
| `<raw-value>` | `<type>` | `<local-value or —>` | `<type or —>` | `<VERDICT>` | `<bucket>` | `<path-or—>` |
```

Rules:

- Every upstream value gets a row, even DEFERRED.
- `Verdict` cell is one of the enum labels from `config.verdict_enum`.
- `Phase` cell is one of `config.phase_buckets[].name`, or `—` for IDENTICAL rows.
- `Adapter` cell is a file path under `config.adapter_path_rules[owner]`, or `—` when not
  applicable.

## Block 4 — migration_plan

```markdown
### [block-4-label]

- Phase 1 targets: <bullet list of mapping rows scheduled now>
- Phase 2 targets: <list>
- Phase 3+ targets: <list>
- Adapter files to create or modify:
  - `<path>` — <function signature or brief purpose>
- Test files:
  - `<path>` — <coverage description>
```

Rules:

- Every DEFERRED row in the mapping table must appear under some phase target, or be explicitly
  called out as deferred indefinitely (with reason).
- Adapter function signatures are suggestions; the actual code lands in the adapter files and
  is validated during Phase 7.

## Block 5 — verification_checklist

```markdown
### [block-5-label]

- [ ] Re-fetched upstream within N days of this edit (last: YYYY-MM-DD)
- [ ] Upstream version matches the value in block 1
- [ ] Every row in the mapping table has a verdict
- [ ] Every DEFERRED row appears in the migration plan
- [ ] RENAMED rows have an adapter file path and test reference
- [ ] doc-critic run: no High findings
```

Checkbox state is tracked by the skill and updated on each invocation. The N-days freshness
window is configurable; default is 7.

## Block 6 — project_native

```markdown
### [block-6-label]

No upstream SSOT exists for this section. Owner: `<owner>`. Reason: <one line>.
```

This block is visually distinct so reviewers can tell at a glance that no external alignment
is expected.

## Placement in the target file

- If the target file has an "Edit History" heading at the top, insert aligned sections after it.
- If an existing section with the same heading exists, Edit-replace its body.
- Preserve heading levels. The skill does not rewrite headings above level 2.
