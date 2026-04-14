# Custom connector

Shell-command-based connector. Useful when the SSOT has no dedicated skill yet, or for
testing with fixtures.

## Config options

```yaml
source:
  type: custom
  connector: custom
  options:
    search_command: "<shell-command>"        # must echo JSON array of candidates
    fetch_command: "<shell-command>"         # must echo JSON object for a single document
    version_command: "<shell-command>"       # optional; echoes a version string
    timeout_seconds: 30
```

Placeholders available in all command strings:

- `{query}` — substituted with the query in search
- `{id}` — substituted with the id in fetch and version

## Output contracts

### search output (stdout JSON)

```json
[
  { "id": "<string>", "title": "<string>", "url": "<string>", "score": 0.95 },
  ...
]
```

### fetch output (stdout JSON)

```json
{
  "id": "<string>",
  "title": "<string>",
  "url": "<string>",
  "version": "<string>",
  "fetched_at": "<ISO-8601 timestamp>",
  "body_markdown": "<string>"
}
```

### version output (stdout plain text)

Single line with the version string.

## Security

The custom connector runs arbitrary shell commands declared in the project config. Review the
config carefully before running `/ssot-align`. Prefer fixture commands or a dedicated read-only
helper script over embedding credentials inline.
