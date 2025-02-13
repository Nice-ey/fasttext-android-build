#!/bin/bash

# 创建输出目录
mkdir -p output

# 设置目标架构（可修改为 arm64-v8a）
TARGET_ARCH="armeabi-v7a"
ANDROID_API=21

# 配置编译工具链
case $TARGET_ARCH in
    "armeabi-v7a")
        CLANG_PREFIX="armv7a-linux-androideabi$ANDROID_API"
        MESON_ARCH="armv7a"
        ;;
    "arm64-v8a")
        CLANG_PREFIX="aarch64-linux-android$ANDROID_API"
        MESON_ARCH="aarch64"
        ;;
    *)
        echo "Unsupported ABI: $TARGET_ARCH"
        exit 1
        ;;
esac

# 创建虚拟环境
python -m venv venv
source venv/bin/activate

# 安装核心构建工具
pip install --upgrade pip setuptools wheel
pip install meson ninja cmake==3.22.1

# 强制设置工具链环境变量
export CC="$CLANG_PREFIX-clang"
export CXX="$CLANG_PREFIX-clang++"
export AR="llvm-ar"
export STRIP="llvm-strip"
export CFLAGS="-fPIE -fPIC -I${NDK_HOME}/sysroot/usr/include"
export LDFLAGS="-pie -L${NDK_HOME}/sysroot/usr/lib"

# 生成动态交叉编译配置文件
sed -i "s|arch = '.*'|arch = '$MESON_ARCH'|" android-cross.ini
sed -i "s|api_level = .*|api_level = $ANDROID_API|" android-cross.ini

# 构建 fasttext 并显式传递交叉文件
pip wheel fasttext==0.9.2 \
    --global-option="build_ext" \
    --global-option="-DCMAKE_TOOLCHAIN_FILE=${NDK_HOME}/build/cmake/android.toolchain.cmake" \
    --global-option="-DANDROID_ABI=$TARGET_ARCH" \
    --global-option="-DANDROID_NATIVE_API_LEVEL=$ANDROID_API" \
    --config-settings="--cross-file=$(pwd)/android-cross.ini" \
    --no-build-isolation

# 处理产物
mkdir -p output
mv *.whl output/ 2>/dev/null || echo "No wheels generated, check build logs"
