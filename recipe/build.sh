#!/bin/sh

export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$BUILD_PREFIX/lib/pkgconfig
export PKG_CONFIG=$BUILD_PREFIX/bin/pkg-config

meson setup builddir ${MESON_ARGS} -Dexamples=false -Dtests=true -Dmodules=false -Dgpu=false

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" != "1" || "${CROSSCOMPILING_EMULATOR}" != "" ]]; then
  # Required for tests to pass, see https://github.com/ralna/spral#usage-at-a-glance
  # and https://github.com/ralna/spral/issues/7#issuecomment-288700497
  export OMP_CANCELLATION=TRUE
  export OMP_PROC_BIND=TRUE
  meson test -C builddir
fi

# Disable tests before install to avoid tests being installed
meson setup --reconfigure builddir ${MESON_ARGS} --Dtests=false
meson install -C builddir
