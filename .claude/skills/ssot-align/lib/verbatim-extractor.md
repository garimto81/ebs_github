# Verbatim extractor — how to pull values from the upstream body

Used in Phase 4. Input is the Markdown body returned by the connector. Output goes into block 2.

## Value kinds

Most aligned sections fall into one of these shapes:

| Kind | Example content | Extractor strategy |
|------|-----------------|-------------------|
| enum | `Active = 0, Inactive = 1, ...` | Grab the complete list, preserve numeric codes |
| field list | `name: string, email: string, ...` | Grab the list, preserve types and required markers |
| endpoint list | `GET /foo, POST /bar, ...` | Grab the method + path + parameter tables |
| status code map | `200 OK → {...}, 404 → {...}` | Grab the full mapping including error shapes |
| free-text spec | Narrative paragraphs | Grab the specific named sub-section, not the whole page |

The section heading and the local context usually indicate which shape applies.

## Rules

1. **No normalization.** Preserve case, punctuation, whitespace. PascalCase stays PascalCase.
   Integer codes are not reformatted.
2. **Minimum necessary context.** Include enough surrounding lines for a reader to verify the
   extraction, but no more.
3. **Cite the source location.** Note the upstream heading path (e.g. "Section 3.2 > Enums")
   in a comment above the code fence.
4. **No commentary inside the code fence.** Any explanatory notes go outside.

## Ambiguity handling

When multiple value sets in the page plausibly match the section, do not pick silently. Offer
the user the top-2 candidates with their heading paths, or let `--auto-accept` take the
highest-scoring one with a warning.

## Output shape

```markdown
> Fetched: YYYY-MM-DD HH:MM TZ (source version <version>)
> Source location: <heading-path-in-upstream>

```<lang>
<raw content>
```
```

## Edge cases

- Tables in the upstream rendered as Markdown tables — reproduce verbatim.
- Tables rendered as HTML (from services that don't emit clean Markdown) — keep the HTML as-is.
  Let downstream readers decide whether to normalize.
- Truncation — if the value set is very large (>200 lines), include all of it. Do not
  summarize. The block exists precisely to hold the whole thing.
