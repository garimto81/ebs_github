# Default aligned-spec template

Generic fallback template. Projects typically override by supplying their own at
`config.template.path`. This default is safe to use when a project has no opinion yet.

---

## §<N>. <Section title>

### Upstream source

- Source page: <title>
- Source id: `<id>`
- URL: <url>
- Fetch command: `<connector example>`
- Query used: `<query or n/a>`
- Last fetched: YYYY-MM-DD HH:MM TZ
- Source version: `<version>`

### Verbatim extract

> Fetched: YYYY-MM-DD HH:MM TZ (source version <version>)

```
<raw values copied from the source, preserving case and notation>
```

### Mapping

| Upstream | Upstream type | Local | Local type | Verdict | Phase | Adapter |
|----------|---------------|-------|------------|---------|-------|---------|
| `<value>` | `<type>` | `<local>` | `<type>` | `<VERDICT>` | `<bucket>` | `<path>` |

### Migration plan

- Phase 1 targets:
  -
- Phase 2 targets:
  -
- Phase 3+ targets:
  -
- Adapter files:
  -
- Test files:
  -

### Verification

- [ ] Re-fetched upstream within 7 days of this edit (last: YYYY-MM-DD)
- [ ] Upstream version in block 1 matches the version in block 2
- [ ] Every mapping row has a verdict
- [ ] Every DEFERRED row appears in the migration plan
- [ ] RENAMED rows have an adapter file path and test reference
- [ ] doc-critic: no High findings

---

## §<N>. <Project-native section title>

No upstream SSOT for this section. Owner: `<owner>`. Reason: <one line>.
