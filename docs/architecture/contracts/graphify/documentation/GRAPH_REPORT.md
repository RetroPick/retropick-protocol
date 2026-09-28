# Architecture Documentation Knowledge Graph

**Status:** `NOT_PRODUCED`

This report is not a Solidity AST graph, not a V1 contract source graph, and not a V2 contract source graph.

**Tool:** Graphify 0.9.46

**Input:** a Markdown-only copy of `docs/architecture/contracts` at the time of the attempt:

- `README.md`
- `SOURCE_MAP.md`
- `V1_ARCHITECTURE.md`
- `V2_ARCHITECTURE.md`
- `V1_V2_COMPARISON.md`
- `graphify/v1/GRAPH_REPORT.md`
- `graphify/v2/GRAPH_REPORT.md`

**Attempted command:** `graphify extract <markdown-only copy> --no-cluster --out <staging-dir>`

## Result

Graphify detected the corpus and then exited 1 before writing `graph.json` or `graph.html`:

```text
[graphify extract] found 0 code, 7 docs, 0 papers, 0 images
error: no LLM API key found (7 doc/paper/image file(s) need semantic extraction).
```

Graphify 0.9.46 classifies Markdown as documents. Document indexing uses semantic LLM extraction. No Gemini, Google, Moonshot, Anthropic, OpenAI, or DeepSeek API key was set, and no Ollama endpoint was configured. `--code-only` would skip these files instead of indexing them.

No Architecture Documentation Knowledge Graph artifact was created.
