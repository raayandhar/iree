+ iree-compile /home/rdhar/export_mlir/iree/with-matmul-reproducer.mlir --iree-hal-target-device=hip --iree-hip-target=gfx942 --iree-opt-level=O3 --iree-opt-const-eval=false --iree-hip-waves-per-eu=2 --iree-llvmgpu-enable-prefetch --iree-dispatch-creation-enable-fuse-horizontal-contractions=true --iree-execution-model=async-external '--iree-preprocessing-pass-pipeline=builtin.module(iree-preprocessing-transpose-convolution-pipeline,iree-preprocessing-pad-to-intrinsics{pad-target-type=conv})' --mlir-disable-threading --debug-only=iree-global-opt-propagate-linalg-transpose --iree-opt-generalize-matmul=false -o punet.vmfb
/home/rdhar/export_mlir/iree/with-matmul-reproducer.mlir:12:14: warning: reads uninitialized values from an operand produced by a tensor.empty op. To disable this warning, pass --iree-global-opt-enable-warn-on-uninitialized-values=false .
  %matmul1 = linalg.matmul ins(%lhs1, %transposed_rhs : tensor<64x768xf16>, tensor<768x768xf16>)
             ^
/home/rdhar/export_mlir/iree/with-matmul-reproducer.mlir:1:1: note: called from
util.func public @two_matmuls_same_transpose_rhs(
^
/home/rdhar/export_mlir/iree/with-matmul-reproducer.mlir:12:14: note: see current operation: %5 = linalg.matmul ins(%0, %transposed : tensor<64x768xf16>, tensor<768x768xf16>) outs(%4 : tensor<64x768xf32>) -> tensor<64x768xf32>
  %matmul1 = linalg.matmul ins(%lhs1, %transposed_rhs : tensor<64x768xf16>, tensor<768x768xf16>)
             ^
/home/rdhar/export_mlir/iree/with-matmul-reproducer.mlir:17:14: warning: reads uninitialized values from an operand produced by a tensor.empty op. To disable this warning, pass --iree-global-opt-enable-warn-on-uninitialized-values=false .
  %matmul2 = linalg.matmul ins(%lhs2, %transposed_rhs : tensor<64x768xf16>, tensor<768x768xf16>)
             ^
/home/rdhar/export_mlir/iree/with-matmul-reproducer.mlir:1:1: note: called from
util.func public @two_matmuls_same_transpose_rhs(
^
/home/rdhar/export_mlir/iree/with-matmul-reproducer.mlir:17:14: note: see current operation: %6 = linalg.matmul ins(%1, %transposed : tensor<64x768xf16>, tensor<768x768xf16>) outs(%4 : tensor<64x768xf32>) -> tensor<64x768xf32>
  %matmul2 = linalg.matmul ins(%lhs2, %transposed_rhs : tensor<64x768xf16>, tensor<768x768xf16>)
             ^

--- After specializing transpose ops ---
util.func public @two_matmuls_same_transpose_rhs(%arg0: !hal.buffer_view, %arg1: !hal.buffer_view, %arg2: !hal.buffer_view, %arg3: !hal.fence, %arg4: !hal.fence) -> (!hal.buffer_view, !hal.buffer_view) attributes {iree.abi.stub, iree.reflection = {iree.abi.declaration = "async func @two_matmuls_same_transpose_rhs(%input0: tensor<64x768xf16>, %input1: tensor<64x768xf16>, %input2: tensor<768x768xf16>) -> (%output0: tensor<64x768xf32>, %output1: tensor<64x768xf32>)", iree.abi.model = "coarse-fences"}} {
  %0 = hal.tensor.import wait(%arg3) => %arg0 "input0" : !hal.buffer_view -> tensor<64x768xf16>
  %1 = hal.tensor.import wait(%arg3) => %arg1 "input1" : !hal.buffer_view -> tensor<64x768xf16>
  %2 = hal.tensor.import wait(%arg3) => %arg2 "input2" : !hal.buffer_view -> tensor<768x768xf16>
  %3 = tensor.empty() : tensor<768x768xf16>
  %transposed = linalg.transpose ins(%2 : tensor<768x768xf16>) outs(%3 : tensor<768x768xf16>) permutation = [1, 0] 
  %4 = tensor.empty() : tensor<64x768xf32>
  %5 = linalg.matmul ins(%0, %transposed : tensor<64x768xf16>, tensor<768x768xf16>) outs(%4 : tensor<64x768xf32>) -> tensor<64x768xf32>
  %6 = linalg.matmul ins(%1, %transposed : tensor<64x768xf16>, tensor<768x768xf16>) outs(%4 : tensor<64x768xf32>) -> tensor<64x768xf32>
  %7:2 = hal.tensor.barrier join(%5, %6 : tensor<64x768xf32>, tensor<64x768xf32>) => %arg4 : !hal.fence
  %8 = hal.tensor.export %7#0 "output0" : tensor<64x768xf32> -> !hal.buffer_view
  %9 = hal.tensor.export %7#1 "output1" : tensor<64x768xf32> -> !hal.buffer_view
  util.return %8, %9 : !hal.buffer_view, !hal.buffer_view
}


--- After canonicalizing transpose in place ---
util.func public @two_matmuls_same_transpose_rhs(%arg0: !hal.buffer_view, %arg1: !hal.buffer_view, %arg2: !hal.buffer_view, %arg3: !hal.fence, %arg4: !hal.fence) -> (!hal.buffer_view, !hal.buffer_view) attributes {iree.abi.stub, iree.reflection = {iree.abi.declaration = "async func @two_matmuls_same_transpose_rhs(%input0: tensor<64x768xf16>, %input1: tensor<64x768xf16>, %input2: tensor<768x768xf16>) -> (%output0: tensor<64x768xf32>, %output1: tensor<64x768xf32>)", iree.abi.model = "coarse-fences"}} {
  %0 = hal.tensor.import wait(%arg3) => %arg0 "input0" : !hal.buffer_view -> tensor<64x768xf16>
  %1 = hal.tensor.import wait(%arg3) => %arg1 "input1" : !hal.buffer_view -> tensor<64x768xf16>
  %2 = hal.tensor.import wait(%arg3) => %arg2 "input2" : !hal.buffer_view -> tensor<768x768xf16>
  %3 = tensor.empty() : tensor<64x768xf32>
  %4 = linalg.matmul indexing_maps = [affine_map<(d0, d1, d2) -> (d0, d2)>, affine_map<(d0, d1, d2) -> (d1, d2)>, affine_map<(d0, d1, d2) -> (d0, d1)>] ins(%0, %2 : tensor<64x768xf16>, tensor<768x768xf16>) outs(%3 : tensor<64x768xf32>) -> tensor<64x768xf32>
  %5 = linalg.matmul indexing_maps = [affine_map<(d0, d1, d2) -> (d0, d2)>, affine_map<(d0, d1, d2) -> (d1, d2)>, affine_map<(d0, d1, d2) -> (d0, d1)>] ins(%1, %2 : tensor<64x768xf16>, tensor<768x768xf16>) outs(%3 : tensor<64x768xf32>) -> tensor<64x768xf32>
  %6:2 = hal.tensor.barrier join(%4, %5 : tensor<64x768xf32>, tensor<64x768xf32>) => %arg4 : !hal.fence
  %7 = hal.tensor.export %6#0 "output0" : tensor<64x768xf32> -> !hal.buffer_view
  %8 = hal.tensor.export %6#1 "output1" : tensor<64x768xf32> -> !hal.buffer_view
  util.return %7, %8 : !hal.buffer_view, !hal.buffer_view
}


--- After bubbling transpose ops up ---
util.func public @two_matmuls_same_transpose_rhs(%arg0: !hal.buffer_view, %arg1: !hal.buffer_view, %arg2: !hal.buffer_view, %arg3: !hal.fence, %arg4: !hal.fence) -> (!hal.buffer_view, !hal.buffer_view) attributes {iree.abi.stub, iree.reflection = {iree.abi.declaration = "async func @two_matmuls_same_transpose_rhs(%input0: tensor<64x768xf16>, %input1: tensor<64x768xf16>, %input2: tensor<768x768xf16>) -> (%output0: tensor<64x768xf32>, %output1: tensor<64x768xf32>)", iree.abi.model = "coarse-fences"}} {
  %0 = hal.tensor.import wait(%arg3) => %arg0 "input0" : !hal.buffer_view -> tensor<64x768xf16>
  %1 = hal.tensor.import wait(%arg3) => %arg1 "input1" : !hal.buffer_view -> tensor<64x768xf16>
  %2 = hal.tensor.import wait(%arg3) => %arg2 "input2" : !hal.buffer_view -> tensor<768x768xf16>
  %3 = tensor.empty() : tensor<64x768xf32>
  %4 = linalg.matmul indexing_maps = [affine_map<(d0, d1, d2) -> (d0, d2)>, affine_map<(d0, d1, d2) -> (d1, d2)>, affine_map<(d0, d1, d2) -> (d0, d1)>] ins(%0, %2 : tensor<64x768xf16>, tensor<768x768xf16>) outs(%3 : tensor<64x768xf32>) -> tensor<64x768xf32>
  %5 = linalg.matmul indexing_maps = [affine_map<(d0, d1, d2) -> (d0, d2)>, affine_map<(d0, d1, d2) -> (d1, d2)>, affine_map<(d0, d1, d2) -> (d0, d1)>] ins(%1, %2 : tensor<64x768xf16>, tensor<768x768xf16>) outs(%3 : tensor<64x768xf32>) -> tensor<64x768xf32>
  %6:2 = hal.tensor.barrier join(%4, %5 : tensor<64x768xf32>, tensor<64x768xf32>) => %arg4 : !hal.fence
  %7 = hal.tensor.export %6#0 "output0" : tensor<64x768xf32> -> !hal.buffer_view
  %8 = hal.tensor.export %6#1 "output1" : tensor<64x768xf32> -> !hal.buffer_view
  util.return %7, %8 : !hal.buffer_view, !hal.buffer_view
}


--- After sinking transpose ops down ---
util.func public @two_matmuls_same_transpose_rhs(%arg0: !hal.buffer_view, %arg1: !hal.buffer_view, %arg2: !hal.buffer_view, %arg3: !hal.fence, %arg4: !hal.fence) -> (!hal.buffer_view, !hal.buffer_view) attributes {iree.abi.stub, iree.reflection = {iree.abi.declaration = "async func @two_matmuls_same_transpose_rhs(%input0: tensor<64x768xf16>, %input1: tensor<64x768xf16>, %input2: tensor<768x768xf16>) -> (%output0: tensor<64x768xf32>, %output1: tensor<64x768xf32>)", iree.abi.model = "coarse-fences"}} {
  %0 = hal.tensor.import wait(%arg3) => %arg0 "input0" : !hal.buffer_view -> tensor<64x768xf16>
  %1 = hal.tensor.import wait(%arg3) => %arg1 "input1" : !hal.buffer_view -> tensor<64x768xf16>
  %2 = hal.tensor.import wait(%arg3) => %arg2 "input2" : !hal.buffer_view -> tensor<768x768xf16>
  %3 = tensor.empty() : tensor<64x768xf32>
  %4 = linalg.matmul indexing_maps = [affine_map<(d0, d1, d2) -> (d0, d2)>, affine_map<(d0, d1, d2) -> (d1, d2)>, affine_map<(d0, d1, d2) -> (d0, d1)>] ins(%0, %2 : tensor<64x768xf16>, tensor<768x768xf16>) outs(%3 : tensor<64x768xf32>) -> tensor<64x768xf32>
  %5 = linalg.matmul indexing_maps = [affine_map<(d0, d1, d2) -> (d0, d2)>, affine_map<(d0, d1, d2) -> (d1, d2)>, affine_map<(d0, d1, d2) -> (d0, d1)>] ins(%1, %2 : tensor<64x768xf16>, tensor<768x768xf16>) outs(%3 : tensor<64x768xf32>) -> tensor<64x768xf32>
  %6:2 = hal.tensor.barrier join(%4, %5 : tensor<64x768xf32>, tensor<64x768xf32>) => %arg4 : !hal.fence
  %7 = hal.tensor.export %6#0 "output0" : tensor<64x768xf32> -> !hal.buffer_view
  %8 = hal.tensor.export %6#1 "output1" : tensor<64x768xf32> -> !hal.buffer_view
  util.return %7, %8 : !hal.buffer_view, !hal.buffer_view
}

warning: <unknown>:0:0: failed to meet occupancy target given by 'amdgpu-waves-per-eu' in 'two_matmuls_same_transpose_rhs_dispatch_0_matmul_64x768x768_f16xf16xf32': desired occupancy was 2, final occupancy is 1
