#!/bin/sh

export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$BUILD_PREFIX/lib/pkgconfig
export PKG_CONFIG=$BUILD_PREFIX/bin/pkg-config

export LDFLAGS="${LDFLAGS} -lcblas"

if [[  "${CONDA_BUILD_CROSS_COMPILATION:-}" == "1" && "${CROSSCOMPILING_EMULATOR}" != "" ]]; then
  # Create a custom crosscompiling_emulator_meson_cross_file.txt to specify the emulator to use for tests
  # and avoid that meson test passes by skipping the tests, and add it to MESON_FLAGS to combine it with
  # the meson_cross_file.txt generated in
  # https://github.com/conda-forge/ctng-compiler-activation-feedstock/blob/main/recipe/activate-gcc.sh
  # https://github.com/conda-forge/clang-compiler-activation-feedstock/blob/main/recipe/activate-clang.sh
  echo "[binaries]" >> "$(pwd)/crosscompiling_emulator_meson_cross_file.txt"
  echo "exe_wrapper = '${CROSSCOMPILING_EMULATOR}'" >> "$(pwd)/crosscompiling_emulator_meson_cross_file.txt"
  export MESON_ARGS="${MESON_ARGS} --cross-file $(pwd)/crosscompiling_emulator_meson_cross_file.txt"
  # Tests last longer in emulation, so let's increase the timeouts
  export MESON_ARGS="${MESON_ARGS} --timeout-multiplier 2"
fi

meson setup builddir ${MESON_ARGS} -Dexamples=false -Dtests=true -Dmodules=false -Dgpu=false

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" != "1" || "${CROSSCOMPILING_EMULATOR}" != "" ]]; then
  # Required for tests to pass, see https://github.com/ralna/spral#usage-at-a-glance
  # and https://github.com/ralna/spral/issues/7#issuecomment-288700497
  export OMP_CANCELLATION=TRUE
  export OMP_PROC_BIND=TRUE
  meson test -C builddir
fi

# Disable tests before install to avoid tests being installed
meson setup --reconfigure builddir ${MESON_ARGS} -Dtests=false
meson install -C builddir
