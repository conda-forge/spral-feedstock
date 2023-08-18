#!/bin/sh

# Required for tests to pass, see https://github.com/ralna/spral#usage-at-a-glance
# and https://github.com/ralna/spral/issues/7#issuecomment-288700497
export OMP_CANCELLATION=TRUE
export OMP_PROC_BIND=TRUE

if [[ ! -z "${cuda_compiler_version+x}" && "${cuda_compiler_version}" == "11.*" ]]
    if [[ -z "${CUDA_HOME+x}" ]]
    then
        echo "==> cuda_compiler_version=${cuda_compiler_version}, extract manually CUDA_HOME variable"
        CUDA_GDB_EXECUTABLE=$(which cuda-gdb || exit 0)
        if [[ -n "$CUDA_GDB_EXECUTABLE" ]]
        then
            CUDA_HOME=$(dirname $(dirname $CUDA_GDB_EXECUTABLE))
        else
            echo "Cannot determine CUDA_HOME: cuda-gdb not in PATH"
            return 1
        fi
    fi
    export NVCCFLAGS="${NVCCFLAGS} -shared -Xcompiler -fPIC"
    export CUDAOPTIONS="--enable-gpu"
then
    export CUDAOPTIONS="--disable-gpu"
fi

export LDFLAGS="${LDFLAGS} -L${PREFIX}/lib -Wl,-rpath,${PREFIX}/lib -lcblas"
export CFLAGS="$CFLAGS -fPIC"
export CPPFLAGS="$CPPFLAGS -fPIC"
export FCFLAGS="$FCFLAGS -fPIC"
./autogen.sh
mkdir build
cd build
../configure $CUDAOPTIONS --with-metis="-lmetis" --prefix=$PREFIX
make

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" != "1" || "${CROSSCOMPILING_EMULATOR}" != "" ]]; then
  make check
fi

# Produce shared library, see https://github.com/ralna/spral/tree/v2023.08.02#generate-shared-library
if [ "$(uname)" == "Linux" ]; then
  $FC -fPIC -shared -Wl,--whole-archive -L${PREFIX}/lib -Wl,-rpath,${PREFIX}/lib libspral.a -Wl,--no-whole-archive -lgomp -lblas -llapack -lhwloc -lmetis -lstdc++ -o libspral${SHLIB_EXT}
fi

# We manually install to only install headers and shared library
cp -r ../include/ $PREFIX
cp ./libspral${SHLIB_EXT} $PREFIX/lib/libspral${SHLIB_EXT}
