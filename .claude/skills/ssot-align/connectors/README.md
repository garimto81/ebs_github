# Connector interface

A connector bridges `ssot-align` to a specific SSOT service (Confluence, Notion, Google Docs,
custom CLI, etc.). The core calls connectors through a small, uniform surface.

## Required operations

A connector must implement these operations. Each connector spec document (`<name>.md` in
this directory) describes how the operation is realized in that service.

### 1. search(query) -> [candidate]

Given a connector-specific query string or object, return a list of candidate references.
Each candidate is `{ id, title, url, score?, preview? }`. Used during Phase 2 when a section
has no explicit source id.

### 2. fetch(id) -> document

Given a connector-specific id, return the document body as Markdown (preferred) or plain text,
plus the source version string and a stable URL. Response shape:
`{ id, title, url, version, fetched_at, body_markdown }`.

### 3. version(id) -> version_string

Cheap version probe for drift detection. When unavailable, connectors may return the result of
`fetch(id).version` as a fallback.

## Optional operations

Connectors may implement more if the service supports them. The core calls them when present.

- `resolve_tiny_link(tiny_id)` — expand a short URL form to a full id.
- `list_children(id)` — pagination helper for tree navigation.
- `search_by_label(label)` — label-based lookups for services that support them.

## Authentication

Connectors are responsible for their own authentication. The core does not pass credentials.
Connectors should fail with a clear actionable error when not authenticated, ideally pointing
to the command the user runs to authenticate.

## Caching

The core caches `fetch` results within a single run (de-dup by id). Connectors may add their
own cross-run cache but must honor a `--no-cache` flag when the core passes it.

## Declaring a connector in config

```yaml
source:
  type: <service-type>         # informational only
  connector: <connector-skill-name>
  options:
    <connector-specific>: <value>
```

The connector reads its own `options` block. The core never interprets it.

## Reference implementations in this directory

- `confluence.md` — wrapper over a Confluence-specialized skill (delegates search/fetch/version).
- `custom.md` — shell command connector. Useful for testing or for services without a dedicated
  skill yet.

Stubs documented but not yet implemented:

- `notion.md`
- `gdocs.md`

## Adding a new connector

1. Copy `custom.md` or `confluence.md` as a starting point.
2. Name the file after the connector's canonical name.
3. Document `options` keys.
4. Describe how each required operation is realized.
5. Note any authentication requirement.
6. Add an entry to the summary at the bottom of this README.

## Summary

| File | Service | Status | Specialization |
|------|---------|--------|----------------|
| `confluence.md` | Confluence (Atlassian Cloud) | Implemented via wrapper | Delegates to a Confluence-specific skill |
| `custom.md` | Any CLI-scriptable source | Implemented | User-supplied commands |
| `notion.md` | Notion | Stub | — |
| `gdocs.md` | Google Docs | Stub | — |
