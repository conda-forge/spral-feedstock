#!/bin/sh

set "CC=clang-cl"
set "CXX=clang-cl"
set "FC=flang-new"

set PKG_CONFIG_PATH=%PKG_CONFIG_PATH%;%BUILD_PREFIX%\lib\pkgconfig
set PKG_CONFIG=%BUILD_PREFIX%\Library\bin\pkg-config

meson setup builddir %MESON_ARGS% -Dexamples=false -Dtests=true -Dmodules=false -Dgpu=false
if errorlevel 1 exit 1

# Required for tests to pass, see https://github.com/ralna/spral#usage-at-a-glance
# and https://github.com/ralna/spral/issues/7#issuecomment-288700497
set OMP_CANCELLATION=TRUE
set OMP_PROC_BIND=TRUE
meson test -C builddir
if errorlevel 1 exit 1

# Disable tests before install to avoid tests being installed
meson setup --reconfigure builddir ${MESON_ARGS} -Dtests=false
if errorlevel 1 exit 1

meson install -C builddir
if errorlevel 1 exit 1