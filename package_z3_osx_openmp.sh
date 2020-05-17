#!/usr/bin/env bash
set -x
export BREW_GMP_PREFIX="$(brew --prefix gmp)"
export BREW_LLVM_PREFIX="$(brew --prefix llvm)"
export CC="${BREW_LLVM_PREFIX}/bin/clang"
export CXX="${BREW_LLVM_PREFIX}/bin/clang++"
export LD="${BREW_LLVM_PREFIX}/bin/llvm-ld"
export AR="${BREW_LLVM_PREFIX}/bin/llvm-ar"
export LDFLAGS="-L${BREW_LLVM_PREFIX}/lib -Wl,-rpath,${BREW_LLVM_PREFIX}/lib -L${BREW_GMP_PREFIX}/lib -Wl,-rpath,${BREW_GMP_PREFIX}/lib"
export EXTRA_LIB_SEARCH_PATH="-L${BREW_LLVM_PREFIX}/lib -L${BREW_GMP_PREFIX}/lib"
export CPPFLAGS="-I${BREW_LLVM_PREFIX}/include -I${BREW_LLVM_PREFIX}/include/c++/v1/ -I${BREW_GMP_PREFIX}/include"
set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE}")" && pwd)"
set -x
set -e
. "${REPO_ROOT}/common.sh"
Z3_GIT_VERSION="$(z3_git_version)"
if ! which python2.7; then
   echo Missing python2.7 1>&2
   exit 1
fi
if ! which java; then
   echo Missing java 1>&2
   exit 1
fi
if ! which javac; then
   echo Missing javac 1>&2
   exit 1
fi
OLD_PWD="${PWD}"
OLD_UMASK="$(umask)"
OSX_VERSION="$(sw_vers | grep ProductVersion | awk '{ print $2; }')"
Z3_VERSION="z3-${Z3_GIT_VERSION}-x64-osx-${OSX_VERSION}"
Z3_ZIP="${Z3_VERSION}.zip"
cd "${REPO_ROOT}"
rm -rf build
python scripts/mk_make.py --java -g USE_OPENMP=1
cd build
BUILD_DIR="${PWD}"
make -j$(sysctl -n hw.ncpu)
WORKING="$(mktemp -d)"
cd "${WORKING}"
umask 0022
mkdir -p "${Z3_VERSION}/bin" "${Z3_VERSION}/lib"
cp "${BUILD_DIR}/z3" "${Z3_VERSION}/bin/z3"
chmod 0755 "${Z3_VERSION}/bin/z3"
cp "${BUILD_DIR}/libz3.dylib" "${Z3_VERSION}/lib/libz3.dylib"
chmod 0644 "${Z3_VERSION}/lib/libz3.dylib"
cp "${BUILD_DIR}/libz3java.dylib" "${Z3_VERSION}/lib/libz3java.dylib"
chmod 0644 "${Z3_VERSION}/lib/libz3java.dylib"
cp "${BUILD_DIR}/../LICENSE.txt" "${Z3_VERSION}/LICENSE"
chmod 0644 "${Z3_VERSION}/LICENSE"
if [ -n "${BREW_LLVM_PREFIX}" ]; then
  for i in "${Z3_VERSION}"/{bin/z3,lib/libz3.dylib}; do
    install_name_tool -change "${BREW_LLVM_PREFIX}/lib/libc++.1.dylib" "/usr/lib/libc++.1.dylib" "$i"
    install_name_tool -change "${BREW_GMP_PREFIX}/lib/libgmp.10.dylib" "/usr/local/lib/libgmp.dylib" "$i"
  done
  install_name_tool -change "libz3.dylib" "/usr/local/lib/libz3.dylib" "${Z3_VERSION}/lib/libz3java.dylib"
  curl -L "https://www.gnu.org/licenses/lgpl-3.0.txt" > "${Z3_VERSION}/LICENSE.libgmp"
  chmod 0644 "${Z3_VERSION}/LICENSE.libgmp"
  cp "${BREW_GMP_PREFIX}/lib/libgmp.dylib" "${Z3_VERSION}/lib/libgmp.dylib"
  chmod 0644 "${Z3_VERSION}/lib/libgmp.dylib"
fi
mkdir -p "${BUILD_DIR}/generated-packages"
zip -r "${BUILD_DIR}/generated-packages/${Z3_ZIP}" "${Z3_VERSION}"
cd "${BUILD_DIR}"
rm -rf "${WORKING}"

