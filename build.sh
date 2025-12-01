#! /bin/bash

set -e
readonly IREE_DIR="$PWD"
readonly BUILD_DIR="$PWD/../iree-build"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

readonly COMMON_FLAGS="-fno-omit-frame-pointer"
export PATH=${HOME}/.local/bin:${PATH}
export IREE_HIP_TARGET=$(rocm_agent_enumerator | sed -n '2 p')
readonly CXX="clang++-18"
readonly CC="clang-18"
source "$IREE_DIR/venv/bin/activate"
cmake "$IREE_DIR" -GNinja -DCMAKE_BUILD_TYPE=RelWithDebInfo \
      -DPython3_EXECUTABLE="$(which python)" \
      -DIREE_BUILD_PYTHON_BINDINGS=1 \
      -DIREE_HAL_DRIVER_HIP=1 \
      -DIREE_TARGET_BACKEND_ROCM=1 \
      -DIREE_HIP_TEST_TARGET_CHIP=gfx942 \
      -DIREE_TARGET_BACKEND_ROCM=ON \
      -DIREE_ENABLE_ASSERTIONS=1 \
      -DIREE_BUILD_TRACY=0 \
      -DIREE_ENABLE_COMPILER_TRACING=0 \
      -DIREE_ENABLE_RUNTIME_TRACING=0 \
      -DIREE_ENABLE_LLD=1 \
      -DIREE_ENABLE_SPLIT_DWARF=1 \
      -DIREE_ENABLE_THIN_ARCHIVES=1 \
      -DLLVM_INSTALL_UTILS=1 \
      -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
      -DCMAKE_C_COMPILER_LAUNCHER=ccache \
      -DCMAKE_CXX_COMPILER="$CXX" -DCMAKE_C_COMPILER="$CC" \
      -DCMAKE_CXX_FLAGS="${COMMON_FLAGS}" -DCMAKE_C_FLAGS="${COMMON_FLAGS}" \
      -DCMAKE_EXPORT_COMPILE_COMMANDS=1 \
      -DCMAKE_INSTALL_PREFIX=run
cmake --build ../iree-build/ --clean-first
echo "Done building."
echo "Copy and run the following:"
echo "source venv/bin/activate &&"
echo "export PATH=$HOME/export_mlir/iree/iree-build/tools:\$PATH"
echo "export IREE_HIP_TARGET=$(rocm_agent_enumerator | sed -n '2 p')"
