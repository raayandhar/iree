util.func public @two_matmuls_same_transpose_rhs(
    %lhs1: tensor<64x768xf16>,
    %lhs2: tensor<64x768xf16>,
    %rhs: tensor<768x768xf16>) -> (tensor<64x768xf32>, tensor<64x768xf32>) {
  // Create transpose of RHS
  %empty_transpose = tensor.empty() : tensor<768x768xf16>
  %transposed_rhs = linalg.transpose ins(%rhs : tensor<768x768xf16>)
      outs(%empty_transpose : tensor<768x768xf16>) permutation = [1, 0]
  
  // First matmul using the transposed RHS
  %empty1 = tensor.empty() : tensor<64x768xf32>
  %matmul1 = linalg.matmul ins(%lhs1, %transposed_rhs : tensor<64x768xf16>, tensor<768x768xf16>)
      outs(%empty1 : tensor<64x768xf32>) -> tensor<64x768xf32>
  
  // Second matmul using the same transposed RHS
  %empty2 = tensor.empty() : tensor<64x768xf32>
  %matmul2 = linalg.matmul ins(%lhs2, %transposed_rhs : tensor<64x768xf16>, tensor<768x768xf16>)
      outs(%empty2 : tensor<64x768xf32>) -> tensor<64x768xf32>
  
  util.return %matmul1, %matmul2 : tensor<64x768xf32>, tensor<64x768xf32>
}
