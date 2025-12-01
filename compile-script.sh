#!/bin/bash

set -xeuo pipefail

iree-compile /home/rdhar/export_mlir/iree/with-matmul-reproducer.mlir \
    --iree-hal-target-device=hip \
    --iree-hip-target=gfx942 \
    --iree-opt-level=O3 \
    --iree-opt-const-eval=false \
    --iree-hip-waves-per-eu=2 \
    --iree-llvmgpu-enable-prefetch \
    --iree-dispatch-creation-enable-fuse-horizontal-contractions=true \
    --iree-execution-model=async-external \
    --iree-preprocessing-pass-pipeline="builtin.module(iree-preprocessing-transpose-convolution-pipeline,iree-preprocessing-pad-to-intrinsics{pad-target-type=conv})" \
    --mlir-disable-threading \
    --debug-only="iree-global-opt-propagate-linalg-transpose" \
    -o "punet.vmfb"

# Old commented flags (kept, but FIXED to remove trailing backslashes)
# --iree-opt-generalize-matmul=false
# 2>&1 > with-matmul-debug-only.mlir
# --mlir-print-ir-after-all
# --mlir-print-ir-before-all
