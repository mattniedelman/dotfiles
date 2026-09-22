# Triton Kernel Authoring Reference (2026 primary-source snapshot)

> Reflects Triton (`triton-lang.org`), PyTorch custom-ops docs
> (`docs.pytorch.org/docs/stable/library.html` and the torch.compile +
> Triton integration guide), and vLLM/SGLang CustomOp dispatch patterns as of
> mid-2026. APIs (especially the compile-integration surface) change across
> versions -- **re-verify against the installed Triton/torch/engine versions.**

## Online softmax and the exp2 trick

Triton computes exponentials most efficiently in base 2 (`tl.exp2`) because the
hardware has fast `exp2`. To compute `exp(x)` via `exp2`, use the identity:

```
exp(x) == exp2(x * log2(e))     where log2(e) = 1.4426950408889634
```

So in a stable (max-subtracted) softmax the logits are scaled by `log2(e)`
before `exp2`. A numerically stable streaming softmax keeps a running max `m`
and running denominator `l`, rescaling the accumulator by
`exp2((m_old - m_new) * log2e)` when the max updates. Getting the `log2e` factor
wrong (or applying it inconsistently between the numerator and the rescale)
produces attention weights that look normalized but are wrong -- the failure is
invisible without a reference comparison.

## Atomic dtype support

`tl.atomic_add` (and other atomics) have dtype restrictions that depend on the
Triton version and target arch. On common targets **BF16 atomics are not
supported**. Patterns:

- Accumulate into an **FP32** scratch buffer, then cast to BF16/FP16 on the
  final store.
- Or restructure the reduction to avoid cross-block atomics entirely (e.g. a
  two-pass reduction with a fixed grid).

Never assume a BF16 atomic works because it compiled -- behavior varies by
version. Verify against the reference on a shape that exercises the atomic path.

## Boundary masking

Every `tl.load` / `tl.store` at a tensor edge needs a `mask=` derived from the
real dimension, plus an `other=` default for masked loads:

```python
offs = block_start + tl.arange(0, BLOCK_SIZE)
mask = offs < n_elements
x = tl.load(x_ptr + offs, mask=mask, other=0.0)
tl.store(out_ptr + offs, y, mask=mask)
```

Tail blocks on non-power-of-two shapes are where missing masks corrupt memory or
read garbage. Always include a non-power-of-two shape in the validation set.

## CustomOp + forward_native dispatch skeleton

The engine pattern: a module with an optimized (Triton) path and a correct
PyTorch fallback, dispatched per platform.

```python
class MyOp(CustomOp):          # engine-provided base
    def forward_native(self, *args):
        # REAL reference-equivalent PyTorch implementation.
        # NOT a stub, NOT zeros -- this runs on every unsupported arch.
        ...

    def forward_cuda(self, *args):
        if _triton_supported_on_current_arch():
            return _my_triton_launch(*args)
        return self.forward_native(*args)
```

The fallback must be genuinely correct: a stub fallback is a silent-wrong-output
bug (`no-fallback-code`). Dispatch chooses the Triton path only on arches it was
written and validated for.

## Surviving torch.compile: triton_op / wrap_triton

In compile mode Inductor may disable framework CustomOps and fuse the equivalent
math into its own generated kernels, so a hand-written kernel silently does not
execute. To make the compiler treat the kernel as an opaque op it calls (rather
than fusing past it), register it:

```python
from torch.library import triton_op, wrap_triton

@triton_op("mylib::my_op", mutates_args={})
def my_op(x: torch.Tensor) -> torch.Tensor:
    out = torch.empty_like(x)
    n = x.numel()
    grid = lambda meta: (triton.cdiv(n, meta["BLOCK_SIZE"]),)
    wrap_triton(my_triton_kernel)[grid](x, out, n, BLOCK_SIZE=1024)
    return out
```

`wrap_triton` wraps the raw Triton kernel launch so it is traceable; `triton_op`
registers the function as a custom op with a schema. The result: `torch.compile`
routes through `my_op` instead of fusing it away, and the kernel actually runs.

Detection: if profiler markers for the kernel disappear or numerics change when
compile is enabled (but are correct under `--enforce-eager`), the kernel is
being fused out -- fix the registration. See
`inference-cuda-graph-compile-tuning`.

## Autotune config template

```python
import triton

@triton.autotune(
    configs=[
        triton.Config({"BLOCK_SIZE": 64},  num_warps=4, num_stages=2),
        triton.Config({"BLOCK_SIZE": 128}, num_warps=4, num_stages=3),
        triton.Config({"BLOCK_SIZE": 256}, num_warps=8, num_stages=3),
        triton.Config({"BLOCK_SIZE": 512}, num_warps=8, num_stages=4),
    ],
    key=["n_elements"],   # re-autotune when this dimension changes
)
@triton.jit
def my_kernel(...):
    ...
```

- `key` lists the shape dims that change the optimal config; autotune caches the
  winning config per key value. First call per new key pays the search -- a
  cold-start cost for shape-diverse workloads.
- `num_warps` / `num_stages` (software pipelining depth) interact with occupancy
  and shared-memory pressure; the right values come from the profile, not
  guessing.

## Profiling workflow (Nsight Compute)

```bash
ncu --set full -o kernel_prof python run_kernel.py
```

Read for: achieved occupancy, memory throughput vs peak (memory-bound?),
compute throughput (compute-bound?), and warp stall reasons. The bottleneck
class dictates which knob to turn:

- Memory-bound -> improve coalescing / vectorized loads / block shape.
- Compute-bound -> `num_warps`, pipelining (`num_stages`), instruction mix.
- Low occupancy -> shared memory / register pressure per block.

Profile before autotuning (to know what to optimize) and after (to confirm the
chosen config moved the identified bottleneck, not just a timing artifact).

## Validation checklist (numbers, not vibes)

1. Reference parity vs plain-PyTorch impl across real + tail (non-pow2) shapes,
   within a stated tolerance.
2. Eager vs compiled parity (proves the kernel is not fused away).
3. forward_native vs Triton parity (proves transparent dispatch).
4. Correct arch selection (Triton on supported arch, fallback elsewhere).
