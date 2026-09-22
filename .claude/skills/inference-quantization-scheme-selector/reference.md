# Quantization Reference (2026 primary-source snapshot)

> Reflects vLLM quantization docs
> (`docs.vllm.ai/en/latest/features/quantization/`), LLM Compressor
> (`docs.vllm.ai/projects/llm-compressor/`), the vLLM quantized-KV-cache page,
> and NVIDIA's NVFP4 announcement, as of mid-2026. Support flags and CC gates
> change between releases -- **re-verify against the installed version.**

## Compute-capability gate (LLM Compressor)

| Scheme | Min CC | GPU family |
|--------|--------|------------|
| W4A16 / W8A16 (weight-only) | 8.0 | Ampere and up |
| W8A8-INT8 | 7.5 | Turing and up |
| W8A8-FP8 | 8.9 | Ada/Hopper and up (CC 8.9 = Ada L4/L40S; SM 9.0 = Hopper) |
| NVFP4 / MXFP4 | 10.0 | Blackwell only |

## vLLM supported quantization formats

Broad matrix, per README + quantization docs:

- **FP8** (W8A8)
- **MXFP8 / MXFP4**, **NVFP4** (Blackwell micro-scaled formats)
- **INT8** (W8A8), **INT4** (W4A16), **W4A8**
- **AWQ**, **GPTQ**, **Marlin** (Marlin kernels cover GPTQ/AWQ/FP8/FP4)
- **GGUF**, **compressed-tensors**, **ModelOpt**, **TorchAO**
- **bitsandbytes**, **DeepSpeedFP**, Intel Neural Compressor, AMD Quark

## Toolchain -> format

| Toolchain | Produces |
|-----------|----------|
| LLM Compressor (compressed-tensors) | FP8 W8A8, INT4 W4A16, W4A8 (INT4 weights / INT8 activations), INT8 W8A8 |
| AutoAWQ | AWQ (INT4 weight-only) |
| GPTQModel | GPTQ (INT4 weight-only) |
| NVIDIA Model Optimizer (ModelOpt) | NVFP4 / MXFP4 |
| bitsandbytes / TorchAO / Quark / INC | various (see docs) |

## KV-cache quantization

vLLM FP8 KV-cache formats via `kv_cache_dtype`:

| Value | Supported on |
|-------|--------------|
| `fp8_e4m3` | CUDA 11.8+ and ROCm (AMD) |
| `fp8_e5m2` | CUDA 11.8+ |

Effect: FP8 KV cache halves KV memory footprint -> ~2x more stored tokens ->
more concurrency / longer context in the same VRAM. **The attention backend
must support the KV dtype** (see the `inference-attention-backend-selector` KV-dtype
table) or the server fails to start.

## NVFP4 format details

- 4-bit floating point, **E2M1** (1 sign, 2 exponent, 1 mantissa bit).
- Introduced with NVIDIA Blackwell.
- **Two-level micro-block scaling:** an E4M3 (FP8) scale factor per 16-value
  micro-block, plus a per-tensor FP32 scalar.
- Higher accuracy than naive INT4 at the same 4-bit budget, but Blackwell-only.

## Weight-only vs weight+activation (why it matters)

| | Weight-only (W4A16, AWQ, GPTQ, W8A16) | Weight+activation (W8A8-FP8/INT8, W4A8, NVFP4) |
|---|---|---|
| Shrinks weights | Yes | Yes |
| Speeds memory-bound **decode** | Yes | Yes |
| Speeds compute-bound **prefill/GEMM** | Little | Yes (on HW with native low-precision tensor cores) |
| Needs low-precision compute HW | No | Yes (FP8->Hopper+, NVFP4->Blackwell) |
| Accuracy risk | Higher at 4-bit | Lower (esp. FP8) |

## Decision quick-path

1. Determine target GPU CC -> drop every scheme it can't run.
2. Goal = "fit the model" / faster decode -> weight-only (AWQ/GPTQ INT4, or
   W4A16). Prefer an existing good checkpoint.
3. Goal = throughput on Hopper+ -> **FP8 W8A8** (smallest accuracy hit).
4. Goal = throughput on Blackwell -> NVFP4.
5. Goal = more concurrency / longer context -> add **FP8 KV-cache quant**
   (check backend support).
6. Always validate quality on a real eval before shipping 4-bit.
