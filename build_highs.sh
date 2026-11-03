# delete UnoUtils' HiGHS
rm -rf lib/libhighs* include/highs include/Highs*.h bin/highs*

# fetch HiGHS source
BUILD_ROOT="$(mktemp -d)"
mkdir "${BUILD_ROOT}/HiGHS"
VERSION="v1.15.0"
ASSET_URL="https://github.com/ERGO-Code/HiGHS/archive/refs/tags/${VERSION}.tar.gz"
echo "Downloading: ${ASSET_URL}"
curl -fL -o "${BUILD_ROOT}/HiGHS-src.tar.gz" "$ASSET_URL"
tar -xzf "${BUILD_ROOT}/HiGHS-src.tar.gz" -C "${BUILD_ROOT}/HiGHS" --strip-components=1

# Patch v1.15.1 (see https://github.com/JuliaPackaging/Yggdrasil/tree/master/H/HiGHS/bundled/patches)
# fix-cli11.patch
sed -i 's/(*opt)/opt->count() > 0/' "${BUILD_ROOT}/HiGHS/extern/cli11/CLI11.hpp"
# fix-destroy.patch
sed -i 's/Highs::resetGlobalScheduler(true);//' "${BUILD_ROOT}/HiGHS/highs/interfaces/highs_c_api.cpp"
    
# native cmake needs Windows paths, not MSYS ones
SRC_W="${BUILD_ROOT}/HiGHS"
BLD_W="${BUILD_ROOT}/build"
PREFIX_W="${BUILD_ROOT}/install"
BLAS_W="${PWD}/lib/libblas.a"

# build
cmake -S "$SRC_W" -B "$BLD_W" \
    -DCMAKE_INSTALL_PREFIX="$PREFIX_W" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DZLIB=OFF \
    -DHIPO=ON \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_TESTING=OFF \
    -DBUILD_CXX_EXE=OFF \
    -DBLA_VENDOR=Generic \
    -DBLAS_LIBRARIES="$BLAS_W" \
    -DBUILD_SHARED_EXTRAS_LIB=OFF \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DCMAKE_UNITY_BUILD=ON \
    -DCMAKE_UNITY_BUILD_BATCH_SIZE=16

cmake --build "$BLD_W" --config Release --parallel
cmake --install "$BLD_W" --config Release

cp -a "${BUILD_ROOT}/install/lib64/."     lib
cp -a "${BUILD_ROOT}/install/include/." include
rm -rf "${BUILD_ROOT}"