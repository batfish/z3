#!/usr/bin/env bash
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE}")" && pwd)"
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
set -x
set -e
. "${REPO_ROOT}/linux_common.sh"
Z3_ZIP="$(linux_zip_name)"
if [ -z "${Z3_ZIP}" ]; then
  echo "Could not determine name of output zip" 1>&2
  exit 1
fi
cd "${REPO_ROOT}"
rm -rf build
python scripts/mk_make.py --java
cd build
BUILD_DIR="${PWD}"
make -j$(grep -i processor /proc/cpuinfo | wc -l)
WORKING="$(mktemp -d)"
cd "${WORKING}"
umask 0022
Z3_VERSION="$(z3_version)"
Z3_JAR="$(z3_jar_name)"
Z3_SRC_JAR="$(z3_src_jar_name)"
mkdir -p "${Z3_VERSION}/bin" "${Z3_VERSION}/lib"
cp "${BUILD_DIR}/z3" "${Z3_VERSION}/bin/z3"
chmod 0755 "${Z3_VERSION}/bin/z3"
cp "${BUILD_DIR}/libz3.so" "${Z3_VERSION}/lib/libz3.so"
chmod 0644 "${Z3_VERSION}/lib/libz3.so"
cp "${BUILD_DIR}/libz3java.so" "${Z3_VERSION}/lib/libz3java.so"
chmod 0644 "${Z3_VERSION}/lib/libz3java.so"
cp "${BUILD_DIR}/../LICENSE.txt" "${Z3_VERSION}/LICENSE"
chmod 0644 "${Z3_VERSION}/LICENSE"
mkdir -p "${BUILD_DIR}/generated-packages"
# java classes
cp "${BUILD_DIR}/com.microsoft.z3.jar" "${BUILD_DIR}/generated-packages/${Z3_JAR}"
# java source
mkdir -p "${BUILD_DIR}/java-src/com/microsoft/z3"
cp -r "${BUILD_DIR}/../src/api/java/." "${BUILD_DIR}/java-src/com/microsoft/z3"
pushd "${BUILD_DIR}/java-src"
zip -r "${BUILD_DIR}/generated-packages/${Z3_SRC_JAR}" com
popd
# platform-specific binary/libs
zip -r "${BUILD_DIR}/generated-packages/${Z3_ZIP}" "${Z3_VERSION}"
cd "${BUILD_DIR}"
rm -rf "${WORKING}"

