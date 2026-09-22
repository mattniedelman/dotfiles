# Structured Decoding Reference (2026 primary-source snapshot)

> Reflects vLLM structured-outputs docs
> (`docs.vllm.ai/en/latest/features/structured_outputs.html`), SGLang
> structured-outputs docs (`docs.sglang.io/advanced_features/structured_outputs`),
> XGrammar (`github.com/mlc-ai/xgrammar`, blog.mlc.ai), llguidance
> (`github.com/guidance-ai/llguidance`), and Outlines, as of mid-2026 (vLLM
> ~v0.25.x). Backend defaults, flags, and the request API change between
> releases -- **re-verify against the installed engine version.**

## Backend feature / constraint matrix

| Backend | JSON schema | Regex | EBNF / CFG | Regex dialect | Notes |
|---------|-------------|-------|------------|---------------|-------|
| **XGrammar** | Yes | Yes | Yes | Rust-style | Default in SGLang; first choice in vLLM `auto`. Pushdown-automaton + precomputed mask cache. |
| **llguidance** (vLLM: `guidance`) | Yes | Yes | Yes (Lark-variant) | Rust-style | On-the-fly masks, negligible startup. Earley parser + derivative regex. |
| **Outlines** | Yes | Yes | **No** | Rust-style | No CFG/EBNF. |
| **lm-format-enforcer** | Yes | Yes | -- | Python `re` | Different regex engine -> portability risk. Underperforms in vLLM testing. |

## vLLM API migration (version gate)

- **Backend selection:** serve-time flag `--structured-outputs-config.backend`
  (default `auto`). **No per-request backend field** in V1. `auto` tries
  XGrammar first, falls back to `guidance` (llguidance) when XGrammar cannot
  handle the request (logic in `_validate_structured_output`,
  `vllm/v1/engine/processor.py`).
- **v0.12.0 removed the flat `guided_*` request fields:** `guided_json`,
  `guided_regex`, `guided_choice`, `guided_grammar`, `guided_decoding_backend`.
  Replaced by nested `structured_outputs` / `StructuredOutputsParams` with
  fields `json`, `regex`, `choice`, `grammar`, `structural_tag`,
  `whitespace_pattern`. OpenAI-style `response_format` with `type: json_schema`
  is also supported.
- On >= v0.12.0 the old fields error. On older versions they still work -- read
  the version.

## SGLang API

- **Backend selection:** launch flag `--grammar-backend <xgrammar|outlines|llguidance>`
  (default **XGrammar**; docs recommend it). Offline engine: `grammar_backend`
  parameter.
- **Constraint fields:** a request specifies exactly one of `json_schema`,
  `regex`, or `ebnf` (mutually exclusive); `structural_tag` is a separate
  constraint type.
- Dedicated structured-outputs workflow documented separately for reasoning
  models.

## How constrained decoding works (and the batch-stall trap)

Constrained decoding assigns **zero probability to grammar-invalid tokens** via
a per-step token mask, so a forbidden token can never be emitted. It enforces
*format*, not semantics.

The performance trap is *where* the mask is computed:

- **Synchronous logit-processor path (legacy / vLLM v0 style):** the FSM is
  compiled per request and the mask computed on the critical path, which blocks
  every request in the batch -- raises TTFT, lowers throughput. Outlines in vLLM
  v0 ran this way.
- **Overlapped path (modern):** grammar/mask computation overlaps GPU model
  execution and FSM/grammar preprocessing is reused across the batch. Skipping
  batch-level FSM-preprocessing reuse has been measured at **2.4x lower
  throughput**.

## XGrammar internals

- Splits the vocabulary into **context-independent tokens** (validity
  precomputed into an adaptive token-mask cache at compile time -- >99% of the
  mask) and **context-dependent tokens** (checked at runtime via a pushdown
  automaton).
- Grammar compilation moved out of Python into C (pthread). Overlaps grammar/
  mask processing with GPU compute; supports rollback (for speculative decoding)
  and jump-forward.
- Documented speedups: up to 3.5x faster mask gen on JSON schema, up to 10x on
  CFG (Llama-3-8B, RTX 4090); end-to-end engine up to 14x (JSON) / 80x (CFG)
  on H100. Up to 5x TPOT-under-load improvement vs Outlines in vLLM.
- **XGrammar-2** (2026-05): up to 80x grammar-compilation speedup scaling 10->500
  tools; `BatchGrammarMatcher` (C++, processes multiple grammar states per pass);
  speculative-decoding mask overlap via `traverse_draft_tree`. Selected at the
  request level via OpenAI-compatible `response_format` (e.g.
  `{"type": "structural_tag", ...}`).
- **Hardware caveat:** on some GPUs (e.g. RTX 4090) XGrammar can be *slower* than
  Outlines because CPU-GPU synchronization overhead dominates. Measure on target
  HW.

## llguidance internals

- On-the-fly token masks: ~50 us CPU/token on a 128k tokenizer, negligible
  startup. Slicer optimization keeps average < 50 us with < 1% of masks
  exceeding 1 ms; the slicer's regex-containment check is a **sound but
  incomplete under-approximation** (conservatively skips the optimization rather
  than ever producing a wrong mask).
- Derivative-based lazy regex engine (`derivre`) + optimized Earley parser over
  a regex-defined lexer; CFG parser invoked for < 0.5% of trie nodes.
- Targets **JSON Schema Draft 2020-12**; **produces a conformant grammar or
  returns an error** (does not silently degrade). Tested on schemas up to 4 MB.
- Deliberate departures from strict JSON Schema: object property order fixed;
  unique keys not enforced for `additionalProperties`/`patternProperties`;
  `additionalProperties` precedence resolved positionally.
- Integrated in vLLM (merged v0.8.2, 2025-03-25) and SGLang (v0.4.4,
  2025-02-26); also backs llama.cpp and OpenAI Structured Output (JSON Schema
  only).

## SGLang compressed FSM / jump-forward

- Analyzes the regex FSM (built from the JSON schema) to find singular
  (deterministic) transition edges, merges them into linear paths, and **decodes
  multiple tokens per forward pass (jump-forward)** by prefilling those
  segments rather than generating token-by-token.
- **RadixAttention interaction:** jump-forward terminates the current request and
  enqueues a new one that reuses the KV cache, so the jumped-forward prefix is
  not recomputed.
- Not possible on a pure next-token logit-processor design (logit processors act
  only on the next token).
- Documented gains: up to 2x lower latency and 2.5x higher throughput (llama-7B,
  A10 24GB, vs vllm v0.2.7 / guidance v0.1.0 / outlines v0.2.5); ~1.6x on JSON
  decoding.

## JSON-schema keyword support (partial support is common)

Documented restrictions (verify per backend/version):

- `oneOf` converted to `anyOf` only when provably equivalent.
- `allOf` intersection of certain schemas unsupported.
- External / remote `$ref` unsupported.
- `pattern` does not support lookarounds.
- Whitespace/escape handling configurable: `whitespace_flexible` enables the
  pattern `[\x20\x0A\x0D\x09]+`; removing `u` from `json_allowed_escapes` makes
  control characters without named escapes unrepresentable.
- **Lenient mode** ignores unsupported keywords/formats (and implies
  `coerce_one_of: true`) -- it silently weakens the constraint. Prefer the
  default error-on-unsupported behavior.

## Failure modes checklist

1. **Reasoning models:** structured output silently disabled if reasoning
   content is not parsed into the reasoning field. vLLM fix (v0.11.2+):
   `--structured-outputs-config.enable_in_reasoning=True`. SGLang: separate
   reasoning-model workflow.
2. **Tokenizer boundary / endless decoding:** model prefers a merged boundary
   token (e.g. `","`) over the grammar-permitted lone quote. SGLang mitigates by
   appending the string and re-tokenizing the whole text (~4% extra compute).
3. **Distorted choice probabilities:** for constrained choices the runtime may
   map a partial token to the wrong full choice -- flagged as an unsolved edge.
   Spot-check choice outputs.
4. **Unsupported schema features:** see the keyword table above -- confirm the
   features you rely on are actually enforced, not silently dropped.

## Decision quick-path

1. Need CFG/EBNF -> XGrammar or llguidance (not Outlines).
2. Stable/reused schema on a datacenter GPU -> XGrammar (amortize precompile,
   overlap runtime mask).
3. Highly variable / per-request schemas, or startup latency is the pain ->
   llguidance (no heavy precompile).
4. Workstation GPU (e.g. RTX 4090) -> benchmark XGrammar vs Outlines; do not
   assume XGrammar wins.
5. SGLang + JSON/regex schema with long deterministic runs -> XGrammar default
   already gets jump-forward via the compressed FSM.
6. vLLM >= v0.12.0 -> use `structured_outputs` fields, not `guided_*`.
7. Any schema -> verify it errors (not silently degrades) on unsupported
   features; avoid lenient mode unless you accept a weaker constraint.
