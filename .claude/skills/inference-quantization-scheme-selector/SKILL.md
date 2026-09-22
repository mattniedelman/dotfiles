---
name: inference-quantization-scheme-selector
description: "Choose a viable quantization scheme for a model + GPU by matching the required compute capability, weighing accuracy vs throughput, and picking the right toolchain (LLM Compressor, AutoAWQ, GPTQ, ModelOpt); use when deciding how to quantize a model for vLLM or SGLang, choosing between FP8/INT8/AWQ/GPTQ/INT4-W4A16/NVFP4, adding KV-cache quantization, or when a quant format fails to load on a GPU"
when_to_use: "Triggers on: 'quantize this model', 'FP8 vs AWQ vs GPTQ vs INT4', 'W4A16 / W8A8 / W4A8', 'NVFP4 / MXFP4', 'quantize the KV cache', 'which quant for Ampere/Hopper/Blackwell', 'quant format not supported on this GPU', or fitting a model that won't otherwise load. Applies to picking a scheme, not to authoring the quantization kernels."
metadata:
  author: mattniedelman
  version: "1.0.0"
---

# Quantization Scheme Selector

## Overview

Quantization choice is gated first by hardware -- a scheme the GPU cannot
execute is a non-starter regardless of its accuracy -- and only then by the
accuracy/throughput tradeoff. Practitioners routinely pick a format that "looks
best on paper" (NVFP4, MXFP4) only to find it needs a Blackwell GPU they do not
have, or apply weight-only INT4 expecting a compute speedup that only
weight+activation schemes deliver. Get the compute-capability gate right first.

**Core principle:** Filter by GPU compute capability, then choose among the
survivors by accuracy vs throughput and by what the model's format ecosystem
supports. A scheme the GPU can't run is off the table no matter how good it
looks.

**Announce at start:** "I'm using the Quantization Scheme Selector skill."

## Step 0: Read the version (support matrices move)

Supported formats, toolchains, and CC gates change between releases. Read the
installed version and verify against its docs:

```bash
python -c "import vllm; print(vllm.__version__)"     # or vllm --version
python -c "import sglang; print(sglang.__version__)"
```

The tables in `reference.md` are a 2026 snapshot -- re-verify against the
installed version.

## Step 1: Establish the GPU compute-capability gate

This is the first filter. From the LLM Compressor requirements (vLLM):

| Scheme | Min compute capability |
|--------|------------------------|
| W4A16 / W8A16 (weight-only) | **8.0** (Ampere and up) |
| W8A8-INT8 | **7.5** (Turing and up) |
| W8A8-FP8 | **8.9** (Ada/Hopper and up) |
| NVFP4 / MXFP4 | **10.0** (Blackwell only) |

CC 8.9 is Ada Lovelace (L4, L40S, RTX 4090); Hopper is SM 9.0 (H100/H200).
Ada has FP8 tensor cores, so FP8 W8A8 runs on CC 8.9 and up -- do not restrict
it to Hopper. Identify the target GPU's CC before considering any scheme --
**NVFP4/MXFP4 on anything below Blackwell (CC 10.0) is impossible**, and FP8
compute below CC 8.9 is unsupported.

## Step 2: Pick by goal among the GPU-viable schemes

### What each axis buys you

- **Weight-only (W4A16, W8A16, AWQ, GPTQ):** shrinks *weights* -> fits bigger
  models / frees KV memory, and speeds **memory-bound decode**. Activations stay
  high-precision, so **compute-bound prefill sees little speedup**. Best when
  the goal is "fit the model" or "faster decode."
- **Weight + activation (W8A8-FP8, W8A8-INT8, W4A8, NVFP4):** quantizes both ->
  speeds **compute-bound prefill/GEMMs** too, on hardware with native low-precision
  tensor cores (FP8 on Hopper+, NVFP4 on Blackwell). Best for **throughput** on
  supported GPUs.
- **KV-cache quantization** (orthogonal): `kv_cache_dtype=fp8_e4m3`/`fp8_e5m2`
  stores ~2x more tokens in the same memory -> more concurrency / longer context.
  Verify the attention backend supports the KV dtype (see
  `inference-attention-backend-selector`). Helps decode-OOM (see `inference-oom-triage`).

### Format ecosystem / accuracy notes

- **AWQ** and **GPTQ** are mature INT4 weight-only formats with wide
  pre-quantized checkpoint availability on model hubs -- often the fastest path
  if a good checkpoint already exists. Accuracy is calibration-dependent.
- **FP8 (W8A8)** typically has the smallest accuracy hit of the aggressive
  schemes and is the default "throughput on Hopper" choice.
- **NVFP4** (Blackwell) is 4-bit float (E2M1) with two-level micro-block scaling
  (E4M3 scale per 16-value block + per-tensor FP32) -- better accuracy than naive
  INT4 at 4-bit, but Blackwell-only.
- Aggressive 4-bit (INT4/W4A16) maximizes memory savings with the largest
  accuracy risk -- always validate quality on a real eval, not just that it loads.

## Step 3: Match the scheme to a toolchain

| Scheme | Produce with |
|--------|--------------|
| FP8, INT8, INT4 (W4A16), W4A8, W8A8 | **LLM Compressor** (compressed-tensors) |
| AWQ | AutoAWQ / AutoAWQ-compatible |
| GPTQ | GPTQModel |
| NVFP4 / MXFP4 | NVIDIA Model Optimizer (ModelOpt) |
| Others | bitsandbytes, TorchAO, Intel Neural Compressor, AMD Quark, GGUF |

Prefer an existing high-quality pre-quantized checkpoint over re-quantizing when
one exists and matches the target format + GPU.

## Step 4: Validate accuracy, not just loading

A model that loads quantized is not a model that still answers correctly.
Quantization can silently degrade quality (this is a `no-fallback-code`-style
trap: it "works" but the output is worse). Run a representative eval or a
side-by-side spot-check against the unquantized (or FP8-reference) model on the
actual task before shipping -- especially for 4-bit weight-only schemes.

## Verification Gate

Before recommending / shipping a quantization scheme, confirm ALL:

1. Was the target GPU's compute capability established, and does it meet the
   scheme's minimum (from the installed version's matrix)?
2. Does the scheme match the goal (weight-only for fit/decode; weight+activation
   for prefill throughput; KV-quant for concurrency)?
3. Was the engine version read and the format's support verified against it?
4. If KV-cache quant is used, does the attention backend support that KV dtype?
5. Was accuracy validated on a real eval/spot-check -- not just "it loaded"?

Any "no" = not done.

## Red Flags -- STOP if you think any of these

- "Use NVFP4/MXFP4, it's the newest and best" -- Blackwell-only; impossible
  below CC 10.0.
- "INT4 weight-only will speed up prefill" -- weight-only barely helps
  compute-bound prefill; it helps decode and memory footprint.
- "It loaded, so accuracy is fine" -- quantization degrades quality silently;
  loading proves nothing.
- "FP8 works everywhere" -- FP8 *compute* needs CC 8.9+ (Ada/Hopper and up);
  below that it is unsupported.
- "Any backend serves the FP8 KV cache" -- KV-dtype support is per-backend
  (see `inference-attention-backend-selector`).

## Rationalization Table

| Excuse | Reality |
|--------|---------|
| "Pick the lowest bits for max savings" | Lowest bits = highest accuracy risk; validate on a real eval first. |
| "4-bit weights speed everything up" | Weight-only speeds decode + saves memory; prefill throughput needs activation quant on supported HW. |
| "NVFP4 is strictly better than FP8" | Only on Blackwell; on Hopper it can't run at all -- FP8 is the throughput answer there. |
| "The checkpoint says quantized, ship it" | Format + GPU-CC + engine-version compatibility all have to line up, and quality must be checked. |
| "KV quant is free concurrency" | Only if the attention backend supports the dtype; otherwise it fails to start. |

## Reference

For the full vLLM quantization format list, the complete compute-capability
gate table, NVFP4 format details, KV-cache-quant dtype specifics, and the
toolchain-to-format mapping, read `reference.md`.
