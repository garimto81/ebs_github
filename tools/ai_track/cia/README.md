# CIA Engine — Change Impact Analysis (L3 + L4)

L3 LLM CIA verifier + L4 cascade orchestrator for the EBS doc cascade pipeline.

## Pipeline

```
diff/intent
   -> L0 intent classify  (Gemma 8B)
   -> L1 static graph     (doc_discovery.py — frontmatter + AST)
   -> L2 hybrid RAG       (doc_rag.py — bge-m3 embedding)
   -> L3 LLM CIA verify   (Gemma 8B/26B — intent x candidate -> {impact, conf, patch})
   -> L4 orchestrator     (markdown / JSON report; PR comment ready)
```

## Usage

```bash
# inline intent + git diff
python -m tools.ai_track.cia.engine --desc "..." --diff-from-git --json

# from a saved diff file
python -m tools.ai_track.cia.engine --desc "..." --diff diff.txt

# self-test
python -m tools.ai_track.cia.self_test

# fixture batch
python -m tools.ai_track.cia.run_fixtures
```

## 36 Edge Cases Covered

See `edge_cases.py:REGISTRY` and PRD `docs/2. Development/2.5 Shared/AI_Cascade_System.md` §5.

## Configuration (env vars)

| Var | Default | Purpose |
|-----|---------|---------|
| `CIA_OLLAMA_URL` | `http://localhost:11434` | Ollama base |
| `CIA_INTENT_MODEL` | `gemma4:latest` | fast intent classifier |
| `CIA_VERIFY_MODEL` | `gemma4:latest` | CIA verifier (use `gemma4:26b` for accuracy) |
| `CIA_EMBED_MODEL` | `bge-m3` | embedding model |
| `CIA_CONF_AUTO` | `0.90` | auto-apply threshold |
| `CIA_CONF_REVIEW` | `0.55` | needs-review lower bound |
| `CIA_LLM_TIMEOUT` | `120` | per-LLM-call timeout (s) |

See PRD `docs/2. Development/2.5 Shared/AI_Cascade_System.md` §6 for operations policy.
