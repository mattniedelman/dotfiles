# Attention Backend Reference (2026 primary-source snapshot)

> These tables reflect vLLM (`docs.vllm.ai/en/latest/design/attention_backends/`,
> repo README) and SGLang (`docs.sglang.io/docs/advanced_features/attention_backend`)
> as of mid-2026. Backend names, priority orders, and support flags change
> between minor releases -- **re-verify against the installed engine version**
> before relying on any row.

## vLLM auto-selection (standard MHA/GQA attention)

vLLM iterates a hardware-specific priority list and selects the **first
compatible** backend.

| GPU generation (SM) | Priority order (first compatible wins) |
|---------------------|----------------------------------------|
| Ampere / Ada / Hopper (SM 8.0-9.x) | FLASH_ATTN -> FLASHINFER -> TRITON_ATTN -> FLEX_ATTENTION -> TURBOQUANT |
| Blackwell (SM 10.x) | **FLASHINFER first**, then the others |

Note: this priority row spans three generations -- Ampere (SM 8.0-8.6), Ada
(SM 8.9), and Hopper (SM 9.0). The *order* is the same, but the FA version the
FLASH_ATTN backend then elects differs by generation (see next table): FA2 on
Ampere/Ada, FA3 on Hopper.

Override: `--attention-backend <NAME>` or env `VLLM_ATTENTION_BACKEND`.

### FlashAttention backend version defaults

The FLASH_ATTN backend itself picks an FA version by GPU:

| GPU | FA version | Notes |
|-----|-----------|-------|
| Blackwell (SM100+) | **FA4** | newest path |
| Hopper (SM90) | **FA3** | adds StreamingLLM **sink** support + **FP8 KV cache**; FA3 public build needs recent CUDA (SGLang requires CUDA 12.3+ for its `fa3`; expect a similar floor here) |
| Older (Ampere/Ada, etc.) | **FA2** | mainly FP16/BF16, head dim up to 256 |

FA2's CUDA path mainly supports Ampere/Ada/Hopper, FP16/BF16, head dims up to
256. FA3's public build targets Hopper with specific CUDA version requirements
-- on an older CUDA toolkit + Hopper, FA3 selection can fail at startup; verify
the CUDA floor for the installed vLLM version.

### vLLM per-backend KV-cache dtype support (partial)

| Backend | KV dtypes supported |
|---------|---------------------|
| FLASHINFER (trtllm-gen) | fp8, nvfp4 |
| TRITON_ATTN | int4, int8, fp8 (per-token-head) |
| FLASH_ATTN (FA3 on SM90) | fp8 KV cache |

vLLM FP8 KV cache formats (via `kv_cache_dtype`):
`fp8_e4m3` (CUDA 11.8+ and ROCm/AMD), `fp8_e5m2` (CUDA 11.8+).

vLLM also exposes FlashMLA and TRTLLM-GEN backends under
`vllm/v1/attention/backends/`.

## SGLang auto-selection

By hardware AND model attention type:

| Model type + GPU | Default backend | Condition |
|------------------|-----------------|-----------|
| MHA, Hopper (H100/H200) | `fa3` | CUDA 12.3+ |
| MHA, Blackwell (B200) | `trtllm_mha` | unless spec-decode topk>1 |
| MHA, Ampere/Ada | `flashinfer` | else falls back to `triton` |

Override: `--attention-backend <name>`.

### SGLang full backend matrix

Standard (MHA/GQA): FlashInfer, FA3/FA4, Triton, Torch SDPA, FlexAttention,
TRTLLM MHA.

**MLA family** (Multi-head Latent Attention, e.g. DeepSeek): FlashInfer MLA,
FlashMLA, Cutlass MLA, TRTLLM MLA, CuteDSL MLA.

GDN / DSA and other newer attention variants have their own routing -- check
the installed version's docs.

## Paging / prefix-reuse constraints (critical, easy to miss)

`page_size` sets KV paging granularity. **`page_size=1` = maximum token-level
prefix reuse.** But several backends impose a **fixed native page size that
cannot be reduced or emulated** -- setting a smaller page_size is ignored:

| Backend | Fixed native page size |
|---------|------------------------|
| FlashMLA | 64 |
| Cutlass MLA | 128 |
| TRTLLM MLA | 32 or 64 |
| Ascend | 128 |

Implication: if fine-grained prefix caching / high cache-hit rate matters,
choosing a large-fixed-page backend silently caps reuse granularity. Pick a
backend that supports small pages when prefix reuse is the priority.

## FlashInfer (the meta-backend)

FlashInfer provides unified attention/GEMM/MoE APIs over multiple pluggable
implementations -- FlashAttention-2/3, cuDNN, CUTLASS, TensorRT-LLM -- and
"automatically selects the best backend for the hardware and workload" (its own
description, not independently benchmarked). Uses block-sparse + composable KV
formats to handle KV-cache storage heterogeneity. Both vLLM and SGLang can
delegate to it.

## Decision quick-path

1. Standard MHA/GQA model + recent GPU + FP16/BF16 KV -> **accept the
   auto-selected default.**
2. Need FP8/FP4 KV cache -> confirm the backend's KV-dtype row supports it;
   FLASHINFER or FA3(SM90)/TRITON on vLLM are the usual answers.
3. MLA model (DeepSeek etc.) -> use the MLA backend family; do not force a
   standard-MHA backend.
4. Need maximum prefix-cache hit rate -> avoid fixed-large-page backends;
   target a small `page_size`.
5. Spec-decode with topk>1 -> exclude backends that disallow it (SGLang
   `trtllm_mha`).
