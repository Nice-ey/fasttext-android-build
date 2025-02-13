#!/bin/bash

# 创建虚拟环境
python -m venv venv
source venv/bin/activate

# 安装必要依赖
pip install --upgrade pip setuptools wheel
pip install meson-python ninja cmake==3.22.1

# 设置编译环境
export CC="$CLANG_PREFIX-clang"
export CXX="$CLANG_PREFIX-clang++"
export AR="$TOOLCHAIN_NAME-ar"
export RANLIB="$TOOLCHAIN_NAME-ranlib"
export CFLAGS="-fPIE -fPIC"
export LDFLAGS="-pie"

# 设置 CMake 参数
export CMAKE_TOOLCHAIN_FILE=$NDK_HOME/build/cmake/android.toolchain.cmake
export ANDROID_ABI=$TARGET_ARCH
export ANDROID_NATIVE_API_LEVEL=$ANDROID_API

# 编译命令
pip wheel fasttext==0.9.2 \
    --global-option="build_ext" \
    --global-option="-DCMAKE_TOOLCHAIN_FILE=$CMAKE_TOOLCHAIN_FILE" \
    --global-option="-DANDROID_ABI=$ANDROID_ABI" \
    --global-option="-DANDROID_NATIVE_API_LEVEL=$ANDROID_NATIVE_API_LEVEL" \
    --no-build-isolation

# 处理产物
mkdir -p output
mv *.whl output/ || echo "No wheel files generated"  # 防止 mv 失败终止脚本
