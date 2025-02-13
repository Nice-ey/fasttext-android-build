#!/bin/bash

# 创建输出目录
mkdir -p output

# 设置目标架构（可修改为 arm64-v8a）
TARGET_ARCH="armeabi-v7a"
ANDROID_API=21

# 配置编译工具链
case $TARGET_ARCH in
    "armeabi-v7a")
        HOST_TAG="linux-x86_64"
        TOOLCHAIN_NAME="arm-linux-androideabi"
        CLANG_PREFIX="armv7a-linux-androideabi$ANDROID_API"
        ;;
    "arm64-v8a")
        HOST_TAG="linux-x86_64"
        TOOLCHAIN_NAME="aarch64-linux-android"
        CLANG_PREFIX="aarch64-linux-android$ANDROID_API"
        ;;
    *)
        echo "Unsupported ABI: $TARGET_ARCH"
        exit 1
        ;;
esac

# 导出编译参数
export CC="$CLANG_PREFIX-clang"
export CXX="$CLANG_PREFIX-clang++"
export AR="$TOOLCHAIN_NAME-ar"
export RANLIB="$TOOLCHAIN_NAME-ranlib"
export CFLAGS="-fPIE -fPIC"
export LDFLAGS="-pie"

# 编译 fasttext
pip wheel fasttext==0.9.2 \
    --global-option="build_ext" \
    --global-option="-DCMAKE_TOOLCHAIN_FILE=$NDK_HOME/build/cmake/android.toolchain.cmake" \
    --global-option="-DANDROID_ABI=$TARGET_ARCH" \
    --global-option="-DANDROID_NATIVE_API_LEVEL=$ANDROID_API"

# 移动生成的 Wheel 文件到输出目录
mv *.whl output/