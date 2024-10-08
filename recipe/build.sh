#!/usr/bin/env bash

set -ex

# There's a TAB in CMakeLists.txt that fails conda patches mechanism
patch -p0 --ignore-whitespace < "${RECIPE_DIR}"/patches/xxxx-find-toolbox-package.patch

build_dir="${SRC_DIR}"/build-release
test_release_dir="${SRC_DIR}"/test-release

mkdir -p "${build_dir}"
cd "${SRC_DIR}"/build-release
  # Downloads and install toolbox as a static lib, make sure to remove it
  cmake -S "${SRC_DIR}" -B . \
  -D CMAKE_INSTALL_PREFIX="${PREFIX}" \
  -D CMAKE_BUILD_TYPE=Release \
  -D bip3x_BUILD_SHARED_LIBS=ON \
  -D bip3x_BUILD_JNI_BINDINGS=ON \
  -D bip3x_BUILD_C_BINDINGS=ON \
  -D bip3x_USE_OPENSSL_RANDOM=ON \
  -D bip3x_BUILD_TESTS=ON \
  -G Ninja
  cmake --build . -- -j"${CPU_COUNT}"
  cmake --install .
cd "${SRC_DIR}"

# Post-install toolbox removal
find "${PREFIX}" -name '*toolbox*' -print0 | while IFS= read -r -d '' file; do
  rm -rf "${file}"
done

# Prepare test area
mkdir -p "${test_release_dir}"
cp -r "${build_dir}"/bin "${test_release_dir}"
cd "${PREFIX}"
  find . -name '*[Gg][Tt]est*' -print0 | while IFS= read -r -d '' file; do
    tar cf - "${file}" | (cd "${test_release_dir}" && tar xf -)
    rm -rf "${file}"
  done
cd "${SRC_DIR}"
