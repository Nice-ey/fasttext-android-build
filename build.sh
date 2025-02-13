#!/bin/bash

# 创建输出目录
mkdir -p output

# 设置目标架构（armeabi-v7a 或 arm64-v8a）
TARGET_ARCH="armeabi-v7a"
ANDROID_API=21

# 配置编译工具链
case $TARGET_ARCH in
    "armeabi-v7a")
        CLANG_PREFIX="armv7a-linux-androideabi$ANDROID_API"
        ;;
    "arm64-v8a")
        CLANG_PREFIX="aarch64-linux-android$ANDROID_API"
        ;;
    *)
        echo "Unsupported ABI: $TARGET_ARCH"
        exit 1
        ;;
esac

# 创建虚拟环境
python -m venv venv
source venv/bin/activate

# 安装预编译的 arm 架构 numpy
pip install numpy==2.2.2 \
    --target=/tmp/numpy-stubs \
    --only-binary=:all: \
    --platform=manylinux2014_armv7l \
    --python-version=3.8 \
    --implementation=cp

# 设置 Python 路径
export PYTHONPATH="/tmp/numpy-stubs/:$PYTHONPATH"

# 设置工具链
export CC="${CLANG_PREFIX}-clang"
export CXX="${CLANG_PREFIX}-clang++"
export CFLAGS="-fPIE -fPIC"
export LDFLAGS="-pie"

# 编译 FastText
pip wheel fasttext==0.9.2 \
    --no-deps \
    --global-option="build_ext" \
    --global-option="-DCMAKE_TOOLCHAIN_FILE=${NDK_HOME}/build/cmake/android.toolchain.cmake" \
    --global-option="-DANDROID_ABI=${TARGET_ARCH}" \
    --global-option="-DANDROID_NATIVE_API_LEVEL=${ANDROID_API}"

# 处理产物
mkdir -p output
mv *.whl output/ 2>/dev/null || echo "No wheels generated, check build logs"

