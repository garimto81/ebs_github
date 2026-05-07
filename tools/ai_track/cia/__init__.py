"""CIA Engine — Change Impact Analysis (L3 LLM verification + L4 cascade orchestrator).

Pipeline:
    diff/intent
      -> L0 intent classify  (Gemma 8B, fast)
      -> L1 static graph     (doc_discovery.py, frontmatter + AST)
      -> L2 hybrid RAG       (doc_rag.py, BM25 + bge-m3 embedding)
      -> L3 LLM CIA verify   (Gemma 26B, intent x candidate -> {impact, confidence, patch})
      -> L4 orchestrator     (PR comment + optional auto-patch)

Local-only: Ollama (localhost:11434), zero cloud dependency.
"""

__version__ = "0.1.0"
