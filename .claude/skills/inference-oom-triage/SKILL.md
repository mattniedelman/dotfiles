---
name: inference-oom-triage
description: "Diagnose and fix out-of-memory failures in vLLM and SGLang LLM inference servers by classifying the OOM phase (load-time, prefill, or decode) and applying the engine-appropriate knob; use when an inference server crashes with CUDA out of memory, KV cache OOM, fails to start, or dies under concurrent load"
when_to_use: "Triggers on any vLLM or SGLang OOM: 'CUDA out of memory', 'KV cache is full', 'No available memory for the cache blocks', server crashes at startup / model load, or crashes only under load or with long prompts. Applies whether the goal is to get it to boot, survive load, or maximize concurrency."
metadata:
  author: mattniedelman
  version: "1.0.0"
---

# Inference OOM Triage

## Overview

Most inference OOMs are misdiagnosed and mis-fixed: an operator lowers a
throughput knob to solve a load-time OOM (which does nothing), or raises the
memory fraction to solve a decode OOM (which makes it worse). The fix depends
entirely on **which phase ran out of memory**, and the phases have opposite
remedies.

**Core principle:** Classify the phase first, then turn exactly one knob and
re-measure. GPU memory is split into three competing pools -- model weights,
the KV-cache pool, and transient activations -- and each OOM phase is a
different pool overflowing.

**Announce at start:** "I'm using the Inference OOM Triage skill."

## Step 0: Establish the version and defaults (do not skip)

Defaults, scheduler behavior, and knob names shift between minor releases (e.g.
vLLM V0 vs V1 scheduling, RECOMPUTE-vs-SWAP preemption default, chunked-prefill
default). **Never assume a default -- read it from the installed version.**

```bash
# vLLM
python -c "import vllm; print(vllm.__version__)"    # or: vllm --version
# SGLang
python -c "import sglang; print(sglang.__version__)"
```

Then confirm the current default for any knob to be changed against the docs
for that exact version (`docs.vllm.ai/en/v<X.Y.Z>/...`, or the matching SGLang
release). State the version in the diagnosis so the fix is reproducible.

## Step 1: Classify the OOM phase

Read the full traceback and the log lines *before* the crash -- not just the
final line. Match the signal to a phase:

| Phase | When it happens | Signature in logs |
|-------|-----------------|-------------------|
| **Load-time** | During weight load / cache profiling, before serving any request | OOM during `load_model`, `determine_num_available_blocks`, "No available memory for the cache blocks", or the process never reaches "ready" |
| **Prefill** | When a long prompt or a large prefill batch is processed | OOM correlated with a big input; spikes with long context or many prompts admitted at once |
| **Decode** | After serving starts, under concurrency, as sequences generate | OOM (or KV-cache-full preemption thrash) that grows with concurrent request count and generation length |

If unsure between prefill and decode: prefill OOM tracks **input length**;
decode OOM tracks **number of concurrent running requests x sequence length**.

## Step 2: Apply the phase-appropriate fix

Turn **one** knob, restart, re-test. Do not stack changes -- they mask which
one worked and can trade one OOM for another.

### Load-time OOM (the weights + minimum KV do not fit)

The model plus a minimal cache does not fit in the memory ceiling. Lowering
throughput knobs does **nothing** here. Options, in order of preference:

1. **Reduce weight footprint** -- quantize the model (see
   `inference-quantization-scheme-selector`) or load a smaller variant. This is usually
   the real fix.
2. **Shard across GPUs** -- raise tensor-parallel size (`--tensor-parallel-size`
   / `tp_size`) and/or pipeline-parallel size so weights split across devices.
3. **Cap the KV reservation** -- lower `--max-model-len` (vLLM) /
   `--context-length` (SGLang) so the profiled cache is smaller.
4. **vLLM `gpu_memory_utilization`** (default ~0.9): this is a *ceiling*, not a
   target. If other processes share the GPU, the real budget is smaller than it
   thinks -- lower it. If weights fit but cache profiling fails for headroom,
   raising it can help. It cannot make weights that exceed physical VRAM fit.
5. **Free CUDA-graph memory** -- graph capture reserves extra memory at load.
   `--enforce-eager` (vLLM) disables capture (also useful to isolate CUDA
   errors near `graph.replay()`); the SGLang analog reduces
   `--cuda-graph-max-bs` or disables capture. Costs decode latency.

### Prefill OOM (activation spike on long / batched prompts)

A large prefill batch spikes transient activation memory. Shrink the prefill
chunk so long prompts are processed in smaller pieces:

- **SGLang:** lower `--chunked-prefill-size` (try 4096, then 2048). Cost: slower
  prefill on long prompts.
- **vLLM:** lower `--max-num-batched-tokens` (chunked prefill is on by default
  in V1). Also cap `--max-model-len` if prompts exceed what the deployment
  actually needs.

### Decode OOM (KV cache exhausted by concurrency)

Too many sequences are generating at once for the KV pool. Reduce concurrency
or shrink per-token KV cost:

- **SGLang:** lower `--max-running-requests`.
- **vLLM:** lower `--max-num-seqs` (max concurrent sequences). Note V1 defaults
  to RECOMPUTE preemption -- if you see preemption/recompute thrash rather than
  a hard OOM, the pool is marginally too small; either raise the KV pool or
  lower concurrency.
- **Shrink per-token KV:** quantize the KV cache (`kv_cache_dtype=fp8_e4m3` or
  `fp8_e5m2` on vLLM; SGLang KV-quant equivalent) to store ~2x more tokens in
  the same memory. Verify the attention backend supports the chosen KV dtype
  (see `inference-attention-backend-selector`).

### Growing the KV pool (when weights fit and you want more headroom)

If load and prefill are fine and the goal is more concurrency, grow the KV pool
deliberately:

- **SGLang:** raise `--mem-fraction-static` = (weights + KV pool) / GPU capacity.
  Reserve **5-8 GB for activations**; raise in **0.01 increments until it OOMs**,
  then back off one step. This is the canonical SGLang concurrency-tuning loop.
- **vLLM:** raise `gpu_memory_utilization` toward (but not to) 1.0, leaving
  headroom for activations and fragmentation.

## Verification Gate

Before claiming the OOM is fixed, confirm ALL:

1. Was the phase (load / prefill / decode) explicitly identified from logs, not
   guessed?
2. Was the installed engine version read, and the changed knob's default
   verified against that version's docs?
3. Was exactly one knob changed per iteration?
4. Did the server reach "ready" AND survive a representative load test (long
   prompt for prefill; concurrent requests for decode) -- not just boot?
5. Is the fix the right *kind* for the phase (not a throughput knob applied to a
   load-time OOM)?

Any "no" = not done.

## Red Flags -- STOP if you think any of these

- "Just lower the batch size" -- for a *load-time* OOM this changes nothing;
  the weights still do not fit.
- "Raise `gpu_memory_utilization` to 0.98" -- for a *decode* OOM this shrinks
  the activation headroom and makes it crash sooner.
- "Set it to whatever made the last model work" -- the fix is model-,
  GPU-, and version-specific.
- Stacking three knob changes at once and declaring victory.
- Trusting a default from memory instead of the installed version.

## Rationalization Table

| Excuse | Reality |
|--------|---------|
| "OOM is OOM, the fix is always smaller batches" | Load-time OOM ignores batch size entirely; the fix is quant / TP / smaller model. |
| "Just crank the memory fraction" | Higher fraction starves activations -- turns a boot OOM into a decode OOM under load. |
| "The default is X" | Defaults change between minor releases; V0->V1 changed scheduling and preemption. Read the installed version. |
| "It booted, it's fixed" | Load OOM and decode OOM are different pools -- booting proves nothing about behavior under concurrent load. |
| "Change everything, one will work" | Then you own an un-diagnosed server whose margins you cannot reason about. One knob, re-measure. |
