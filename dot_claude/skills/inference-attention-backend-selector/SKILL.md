---
name: inference-attention-backend-selector
description: "Select the right attention backend for vLLM or SGLang given GPU generation, model attention type (MHA/GQA vs MLA), and required features, and flag how the choice constrains KV paging and prefix reuse; use when choosing or debugging an attention backend, deciding between FlashAttention/FlashInfer/Triton/TRTLLM, or when a backend is incompatible with FP8 KV cache, a page size, or a GPU"
when_to_use: "Triggers on: 'which attention backend', 'FlashInfer vs FA3 vs Triton', 'backend for H100/B200/A10G/L4', 'backend does not support fp8 kv cache', 'page_size error', 'MLA backend for DeepSeek', or an attention-backend startup/compat failure. Applies when picking a backend for a new deployment or diagnosing why the auto-selected one is wrong."
metadata:
  author: mattniedelman
  version: "1.0.0"
---

# Attention Backend Selector

## Overview

Both vLLM and SGLang auto-select an attention backend by GPU generation and
model type, and the default is usually right. This skill matters when the
default is wrong, incompatible with a required feature (FP8/FP4 KV cache, a
specific page size, speculative decoding), or being overridden for performance.
The critical, non-obvious fact: **the backend choice constrains KV paging and
prefix reuse** -- several backends impose a fixed native page size that cannot
be reduced, which caps token-level prefix-cache granularity.

**Core principle:** Let the engine auto-select unless a concrete constraint
forces an override. When overriding, verify the backend supports the GPU, the
model's attention type, AND the KV dtype -- all three -- for the installed
version.

**Announce at start:** "I'm using the Attention Backend Selector skill."

## Step 0: Read the version (backend matrices change fast)

Backend names, auto-selection priority, and per-backend support shift between
releases. Read the installed version and verify against its docs, not memory:

```bash
python -c "import vllm; print(vllm.__version__)"     # or vllm --version
python -c "import sglang; print(sglang.__version__)"
```

The tables in `reference.md` reflect the 2026 primary-source snapshot and must
be re-verified against the installed version before acting.

## Step 1: Gather the three inputs

A backend choice is only valid against all three:

1. **GPU generation / compute capability** -- Ampere (SM 8.0, A100/A10G),
   Ada (SM 8.9, L4/L40S), Hopper (SM 9.0, H100/H200), Blackwell (SM 10.x, B200).
2. **Model attention type** -- standard MHA/GQA, or **MLA** (Multi-head Latent
   Attention, e.g. DeepSeek). MLA has its own dedicated backend family.
3. **Required features** -- FP8/FP4 KV cache, speculative decoding (and its
   topk), the prefix-cache granularity you need.

## Step 2: Prefer the auto-selection, understand it

Both engines iterate a hardware-specific priority list and pick the first
compatible backend.

- **vLLM** (standard attention): on Ampere/Hopper the order is
  FLASH_ATTN -> FLASHINFER -> TRITON_ATTN -> FLEX_ATTENTION -> ...; on
  **Blackwell, FLASHINFER is tried first**. The FlashAttention backend itself
  defaults to **FA4 on SM100+ (Blackwell), FA3 on SM90 (Hopper)** -- FA3 adds
  StreamingLLM sink support and FP8 KV cache -- and **FA2 otherwise**.
  Override with `--attention-backend` (or `VLLM_ATTENTION_BACKEND`).

- **SGLang** (by GPU + model type): MHA Hopper -> `fa3` (CUDA 12.3+); MHA
  Blackwell -> `trtllm_mha` (unless spec-decode topk>1); Ampere/Ada ->
  `flashinfer`, else `triton`. Override with `--attention-backend`. MLA models
  route to the MLA backend family (FlashInfer MLA / FlashMLA / Cutlass MLA /
  TRTLLM MLA / CuteDSL MLA).

Read `reference.md` for the full per-GPU matrix, MLA family, and KV-dtype
support table before overriding.

## Step 3: Override only for a concrete reason

Legitimate reasons to override the default:

- **KV dtype requirement.** Not all backends support FP8/FP4 KV cache. On vLLM,
  FLASHINFER (trtllm-gen) supports fp8 and nvfp4; TRITON_ATTN supports
  int4/int8/fp8 per-token-head. If quantizing the KV cache (see
  `inference-oom-triage` / `inference-quantization-scheme-selector`), the backend MUST
  support that dtype or startup fails.
- **Prefix-cache granularity.** `page_size=1` gives maximum token-level prefix
  reuse. Several backends impose a **fixed native page size that cannot be
  reduced or emulated**: FlashMLA 64, Cutlass MLA 128, TRTLLM MLA 32/64,
  Ascend 128. If fine-grained prefix reuse matters, a large-fixed-page backend
  silently defeats it -- pick a backend that allows small pages.
- **Speculative decoding.** Some backends are excluded when spec-decode topk>1
  (e.g. SGLang skips `trtllm_mha` in that case). Verify compatibility with the
  spec-decode config.
- **Correctness/perf regression.** If the auto-selected backend produces wrong
  output or underperforms on the specific GPU+model, override to a known-good
  one and file it.

## Step 4: Verify the backend actually loaded

Overriding does not guarantee it took -- an incompatible backend may fall back
silently or fail at first attention call. After setting `--attention-backend`,
confirm the server logs the chosen backend at startup and runs a real
generation (not just boots). A backend that "boots" but errors on the first
long prompt or FP8-KV request is not selected.

## Verification Gate

Before claiming a backend choice is correct, confirm ALL:

1. Were all three inputs (GPU/CC, MHA-vs-MLA, required features) established?
2. Was the engine version read and the choice verified against that version's
   backend matrix (not memory / `reference.md` alone)?
3. If overriding, is there a concrete reason (KV dtype, page size, spec-decode,
   measured regression) -- not a guess?
4. Does the chosen backend support the required KV dtype AND the needed page
   size / prefix granularity?
5. Did logs confirm the backend loaded, and did a real generation succeed?

Any "no" = not done.

## Red Flags -- STOP if you think any of these

- "Just force FlashInfer/FA3 everywhere" -- wrong for the GPU generation or
  MLA models, and may not support the needed KV dtype.
- "Set `page_size=1` for max prefix reuse" on a backend with a fixed native
  page size -- it is ignored; you get the native page anyway.
- "The KV cache is FP8, any backend is fine" -- FP8/FP4 KV support is
  per-backend; the wrong one fails at startup or first request.
- "It booted with `--attention-backend X`" -- boot != selected != working on a
  real request.
- Trusting the 2026 matrix in `reference.md` without re-checking the installed
  version.

## Rationalization Table

| Excuse | Reality |
|--------|---------|
| "FlashInfer is fastest, use it always" | Backend fitness is per GPU + model + feature; auto-select already encodes this. Override needs a reason. |
| "Page size is just a perf tunable" | Fixed-native-page backends cap prefix-cache granularity -- it changes cache hit behavior, not just speed. |
| "Any backend supports FP8 KV" | KV-dtype support is a per-backend table; the wrong choice fails to start. |
| "MHA and MLA use the same backends" | MLA (DeepSeek et al.) has a dedicated backend family; a standard-MHA backend won't serve it. |
| "The matrix I remember is current" | Priority orders and support flip between minor releases -- read the installed version. |

## Reference

For the full per-GPU-generation backend priority lists (vLLM and SGLang), the
FA2/FA3/FA4 default table, the complete MLA backend family, the per-backend
KV-dtype support table, and the fixed native page sizes, read `reference.md`.
