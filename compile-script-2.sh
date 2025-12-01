#!/bin/bash

set -euo pipefail

iree-compile /home/rdhar/export_mlir/iree/model.mlir \
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
             --mlir-print-ir-after-all \
             --mlir-print-ir-before-all \
             -o "punet.vmfb" \
             2> without-matmul.mlir
