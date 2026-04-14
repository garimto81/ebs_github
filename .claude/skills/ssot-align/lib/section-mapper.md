# Section mapper — heuristics for finding the upstream source for a section

Used in Phase 2 when no explicit `--source-id` or `--query` is provided.

## Inputs per section

- Target file path
- Section heading text
- Section body (first ~200 lines)
- Project config

## Heuristic stack (apply in order, stop at first confident match)

### 1. Inline upstream reference

Look in the section body for text cues matching any of these patterns (config-extensible):

- `source id: <id>`, `upstream id: <id>`, `page id: <id>`
- explicit URLs under the connector's base URL
- existing five-block templates where block 1 is present

Confidence: very high. Use the found id directly.

### 2. Prior state

If a state file exists, check whether this section was previously mapped. Match by
`(file_path, heading)`. Confidence: high, unless the file was substantially rewritten since.

### 3. Config-declared precomputed mapping

Projects may include a static `section_map` in their config:

```yaml
section_map:
  - match:
      file: "contracts/data/<file>.md"
      heading: "<heading-regex>"
    source_id: "<id>"
```

Confidence: high. Treat as explicit.

### 4. Keyword scan + connector search

Extract salient nouns from the heading and the first paragraph (drop common words). Pass the
result to `connector.search`. Take top-N candidates.

Confidence: medium. If the top score is substantially higher than the runner-up, auto-select.
Otherwise, present the top-5 to the user.

### 5. Fallback: ask the user

If all of the above fail or confidence is too low, prompt with:

- Options: top-5 candidate ids with titles
- Option: "provide an explicit id"
- Option: "classify as project-native"
- Option: "defer this section"

In `--auto-accept` mode, skipping to project-native is not automatic — the skill defers the
section instead, so the user can decide later.

## Output

For each section, one of:

- `{ kind: "source_mapped", source_id: "<id>", confidence: "high|medium|low" }`
- `{ kind: "native" }`
- `{ kind: "deferred", reason: "<string>" }`

The mapping is persisted to state so the next run can skip the lookup.
