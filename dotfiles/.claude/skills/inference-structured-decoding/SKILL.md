---
name: inference-structured-decoding
description: "Choose and configure a grammar backend for structured / constrained / guided decoding in vLLM or SGLang (XGrammar, llguidance/guidance, Outlines) by matching the constraint type, hardware, and startup-vs-per-token overhead profile, integrate it so masking overlaps GPU compute instead of stalling the batch, and validate against the known failure modes; use when enabling JSON-schema / regex / EBNF constrained output, picking or switching a grammar backend, diagnosing constrained-decoding slowdowns or a batch stall, or fixing structured output that breaks on reasoning models, tokenizer boundaries, or unsupported schema features"
when_to_use: "Triggers on: 'force JSON / JSON-schema / regex / EBNF output', 'guided decoding / structured outputs', 'which grammar backend (xgrammar vs llguidance/guidance vs outlines)', '--structured-outputs-config.backend / --grammar-backend', 'guided_json / guided_decoding_backend no longer works', 'constrained decoding is slow / stalls the batch', 'structured output disabled on a reasoning model', 'endless generation with a schema', or 'schema feature not supported'. Applies to selecting/configuring/debugging constrained decoding, not to speculative decoding or attention backends."
metadata:
  author: mattniedelman
  version: "1.0.0"
---

# Inference Structured Decoding

## Overview

Structured decoding enforces a grammar by masking grammar-invalid tokens to
zero probability at every step, so the model can never emit a token the grammar
forbids -- it guarantees structural correctness but adds a per-token mask
computation to the critical path. The recurring mistakes are: picking a backend
that does not support the needed constraint type, assuming a backend that wins
benchmarks on a datacenter GPU also wins on a workstation GPU (it can be
*slower*), running the old synchronous logit-processor path that stalls the
whole batch, and shipping without checking the specific failure modes
(reasoning models, tokenizer boundaries, unsupported JSON-schema keywords) that
silently break or slow constrained output.

**Core principle:** Match the backend to the constraint type and the hardware
first, integrate it so mask computation overlaps GPU compute (not a synchronous
per-request logit processor), and validate against the known failure modes --
"the JSON parsed once" is not proof it works.

**Announce at start:** "I'm using the Inference Structured Decoding skill."

## Step 0: Read the version -- the API changed recently (do not skip)

The request/serve API for structured outputs was reorganized in recent vLLM
releases. **Read the installed version before writing any flags or request
fields:**

```bash
python -c "import vllm; print(vllm.__version__)"     # or vllm --version
python -c "import sglang; print(sglang.__version__)"
```

vLLM-specific version gate: the flat `guided_*` request fields
(`guided_json`, `guided_regex`, `guided_choice`, `guided_grammar`,
`guided_decoding_backend`) were **removed in v0.12.0** and replaced by the
nested `structured_outputs` / `StructuredOutputsParams` API. On >= v0.12.0,
`guided_*` fields error -- use `structured_outputs` (with `json`, `regex`,
`choice`, `grammar`, `structural_tag`, `whitespace_pattern`) or the
OpenAI-style `response_format`. Verify the exact surface against the installed
version's docs.

## Step 1: Pick the backend by constraint type, then hardware

### Constraint-type support (the first filter)

| Backend | JSON schema | Regex | EBNF / CFG |
|---------|-------------|-------|------------|
| **XGrammar** | Yes | Yes | Yes |
| **llguidance** (vLLM calls it `guidance`) | Yes | Yes | Yes (Lark-variant) |
| **Outlines** | Yes | Yes | **No** |

If the constraint is a context-free grammar / EBNF, Outlines is out -- use
XGrammar or llguidance. Regex **dialect** also differs: XGrammar, guidance, and
Outlines use Rust-style regex; lm-format-enforcer uses Python's `re` -- a regex
that works on one backend can fail on another.

### Backend defaults and selection flags

- **vLLM:** select at **serve time** with `--structured-outputs-config.backend`
  (default `auto`). There is **no per-request backend field** in V1 -- `auto`
  tries XGrammar first and falls back to `guidance` (llguidance) when XGrammar
  cannot handle the request. (Do not expect a fallback to Outlines; the fallback
  target is guidance.)
- **SGLang:** default backend is **XGrammar** (the docs recommend it); override
  with `--grammar-backend <xgrammar|outlines|llguidance>` at launch, or
  `grammar_backend` in the offline engine API.

### Hardware caveat (easy to miss, changes the answer)

XGrammar's speedups are largest on datacenter GPUs where its mask computation
overlaps GPU compute. **On some workstation GPUs (e.g. RTX 4090) XGrammar can be
slower than Outlines** because CPU-GPU synchronization overhead dominates. Do
not port a datacenter backend choice to a workstation without measuring.

## Step 2: Understand the overhead profile you are choosing

The overhead splits into **startup/compilation** (paid once per grammar) and
**per-token mask** (paid every step). Backends optimize these differently:

- **XGrammar:** precomputes the context-independent portion of the token mask
  (>99% of the vocabulary) into an adaptive cache at compile time; only
  context-dependent tokens are checked at runtime via a pushdown automaton.
  Grammar compilation is moved out of Python into C (pthread). Result: near-zero
  steady-state overhead when it overlaps GPU compute. XGrammar-2 further cuts
  **compilation** cost (documented up to ~80x for many-tool schemas), which is
  the main startup mitigation for large/complex schemas.
- **llguidance:** computes masks on the fly (~50 us CPU/token on a 128k
  tokenizer) with negligible startup cost -- favorable when grammars change
  often (per-request unique schemas) so precompilation cannot amortize.

Decision criterion: **stable, reused schema on a datacenter GPU -> XGrammar**
(amortize precompute, overlap the tiny runtime mask). **Highly variable /
per-request schemas, or startup latency is the pain -> llguidance** (no heavy
precompile). Re-check on the actual hardware.

## Step 3: Integrate so masking overlaps compute (do not stall the batch)

The failure mode to avoid: the legacy **synchronous per-request logit-processor
path** compiles the FSM per request and computes the mask on the critical path,
which **blocks every request in the batch**, raising TTFT and cutting
throughput. The modern integration overlaps grammar/mask computation with GPU
model execution and reuses FSM/grammar preprocessing across the batch (skipping
batch-level reuse has been measured at ~2.4x lower throughput).

Practical implications:

- Prefer a backend + engine version whose structured-decoding path overlaps
  masking with compute (XGrammar's co-design, llguidance's cheap per-token
  mask). Avoid configurations that fall back to a synchronous logit processor.
- If constrained decoding tanks throughput, check whether it is running on the
  overlapped path or the synchronous one before blaming the grammar.

### SGLang: compressed FSM / jump-forward (a throughput win, SGLang-specific)

SGLang's compressed FSM finds deterministic (singular-transition) edges in the
schema's FSM, merges them into linear paths, and **decodes those multiple tokens
in a single forward pass (jump-forward)** instead of one token per step --
prefilling the deterministic segments. Documented gains: up to ~2x lower latency
and ~2.5x higher throughput (llama-7B on A10); ~1.6x on JSON decoding. It
interacts with **RadixAttention** by terminating the current request and
enqueuing a new one that reuses the KV cache, so the jumped-forward prefix is
not recomputed. (Jump-forward is not possible on a pure next-token
logit-processor design.)

## Step 4: Validate against the known failure modes (the gate)

Constrained decoding fails in specific, documented ways. Check each before
shipping:

1. **Reasoning models silently disable structure.** With reasoning-enabled
   models (e.g. Qwen3 Coder), structured outputs can be silently disabled if the
   reasoning content is not parsed into the reasoning field. Fix (vLLM
   v0.11.2+): `--structured-outputs-config.enable_in_reasoning=True`. SGLang
   documents a separate structured-outputs workflow for reasoning models.
2. **Tokenizer boundary / endless decoding.** The model may prefer a merged
   boundary token (e.g. `","`) over the grammar-permitted lone quote, causing
   endless decoding. SGLang mitigates by appending the string and re-tokenizing
   the whole text (~4% extra compute). If you see runaway generation under a
   grammar, suspect a tokenizer-boundary mismatch.
3. **Unsupported / partially supported JSON-schema keywords.** Documented gaps:
   `oneOf` is converted to `anyOf` only when provably equivalent; `allOf`
   intersection of certain schemas is unsupported; external/remote `$ref` is
   unsupported; `pattern` does not support lookarounds. llguidance additionally
   fixes object property order, does not enforce unique keys for
   `additionalProperties`/`patternProperties`, and resolves `additionalProperties`
   positionally. Confirm the schema features you rely on are actually enforced.
4. **Compilation errors vs silent degradation.** Prefer a backend that **errors
   on an unsupported schema** rather than silently ignoring the constraint.
   llguidance targets JSON Schema Draft 2020-12 and returns an error rather than
   degrading. Beware "lenient" modes that ignore unsupported keywords -- they
   trade a loud error for a silently weaker constraint (a `no-fallback-code`
   trap).
5. **Distorted probabilities on choice constraints.** For constrained choices
   the runtime may map a partial token to the wrong full choice; this is a known
   unsolved edge. Spot-check choice outputs, do not assume the mask makes them
   correct.

## Verification Gate

Before claiming structured decoding is correctly configured, confirm ALL:

1. Was the engine version read, and the request/serve API (`structured_outputs`
   vs removed `guided_*`) verified against it?
2. Does the chosen backend support the constraint type (JSON/regex/EBNF) AND the
   specific schema keywords in use?
3. Was the backend choice validated on the **actual target hardware** (not
   assumed from datacenter benchmarks -- workstation GPUs can invert the
   ranking)?
4. Is masking on the overlapped path (not a synchronous per-request logit
   processor stalling the batch)?
5. Were the failure modes checked -- reasoning-model flag, tokenizer-boundary
   runaway, unsupported keywords, choice distortion?
6. On an unsupported schema, does the config **error** rather than silently drop
   the constraint?

Any "no" = not done.

## Red Flags -- STOP if you think any of these

- "Set `guided_json` in the request" -- removed in vLLM v0.12.0; use
  `structured_outputs`. Verify the version.
- "XGrammar is fastest, always use it" -- on some workstation GPUs it is slower
  than Outlines due to CPU-GPU sync; measure on the real hardware.
- "Use Outlines for my EBNF grammar" -- Outlines does not support CFG/EBNF; use
  XGrammar or llguidance.
- "The batch got slow but the grammar is fine" -- a synchronous logit-processor
  path stalls the whole batch; check the integration path, not just the grammar.
- "It emitted valid JSON once, structure is enforced" -- reasoning models,
  tokenizer boundaries, and unsupported keywords break it silently; run the
  failure-mode checks.
- "Lenient mode fixed the schema error" -- it dropped the unsupported constraint
  silently; the output is now less constrained than you think.

## Rationalization Table

| Excuse | Reality |
|--------|---------|
| "Constrained decoding is free correctness" | It guarantees structure but adds per-token mask cost; the win depends on overlapping it with compute. |
| "Any backend enforces my schema" | Backends differ on JSON/regex/EBNF support, regex dialect, and which schema keywords they actually enforce. |
| "The benchmark says XGrammar wins" | On the benchmarked datacenter GPU; workstation CPU-GPU sync can make it lose to Outlines. |
| "Structured output works on this model" | Reasoning models silently disable it without the reasoning flag; verify on the actual model. |
| "The old `guided_*` fields are fine" | Removed in vLLM v0.12.0 -- they error; the API is now `structured_outputs`. |
| "Lenient mode is more robust" | It ignores unsupported keywords, silently weakening the constraint -- prefer a hard error. |

## Reference

For the full backend feature/constraint matrix, the vLLM v0.12.0 API migration
(`guided_*` -> `structured_outputs`), XGrammar / llguidance / compressed-FSM
internals, measured overhead numbers with their hardware context, and the
detailed JSON-schema keyword-support table, read `reference.md`.
