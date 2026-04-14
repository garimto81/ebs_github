# Confluence connector

Thin wrapper that delegates to a Confluence-specialized skill declared in config. The wrapper
does not hard-code any cloud id, space key, page map, or query patterns. All of that belongs
to the delegated skill.

## Config options

```yaml
source:
  type: confluence
  connector: <delegated-skill-name>
  options:
    cloud_id: "auto" | "<uuid or hostname>"
    space_key: "<space-key>"
    auth:
      method: browser_oauth | api_token    # connector-specific
```

- `cloud_id`: `auto` means the delegated skill resolves it via its own logic (for example by
  calling `getAccessibleAtlassianResources` when using Atlassian MCP).
- `space_key`: the Confluence space key. Connectors may support multiple spaces if the
  delegated skill does.
- `auth`: passed through; interpretation is the delegated skill's responsibility.

## Operation mapping

### search(query)

Delegates to the specialized skill's search operation (typically a CQL query or Rovo AI
natural-language search). The query string is passed through unchanged. The wrapper normalizes
the response to the candidate shape defined in `connectors/README.md`.

### fetch(id)

Delegates to the specialized skill's page-fetch operation. When the delegated skill supports
both ADF and Markdown, request Markdown. Capture the `version` field from the response as the
source version. Capture `last_modified` if present.

### version(id)

Optional cheap probe. When the delegated skill exposes a metadata-only call, use it. Otherwise,
fall back to `fetch(id).version`.

## Error handling

- Authentication failure: surface the delegated skill's auth error and its recommended
  remediation. Do not attempt silent retries.
- Page not found: return a structured error with the id that failed, so the core can mark the
  dependent section as DEFERRED.
- Rate limit: delegated skill handles backoff. The wrapper surfaces the final error to the core.

## Delegation rationale

All Confluence-specific knowledge — space keys, cloud ids, known page maps, preferred CQL
patterns, domain vocabulary — stays in the delegated skill. The wrapper contains none of this.
This keeps `ssot-align` project-agnostic while letting projects benefit from whatever
specialization already exists in the skill they delegate to.

If a project needs higher-fidelity search for a specific space, the fix is to improve the
delegated skill (or swap to a more specialized one), not to modify this wrapper.
