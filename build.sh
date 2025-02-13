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

# 设置 CMake 工具链
export CMAKE_TOOLCHAIN_FILE=$NDK_HOME/build/cmake/android.toolchain.cmake
export ANDROID_ABI=$TARGET_ARCH
export ANDROID_NATIVE_API_LEVEL=$ANDROID_API
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

# 安装 CMake
pip install cmake==3.22.1
pip install meson-python ninja pyproject-hooks

# 编译 fasttext
pip wheel fasttext==0.9.2 \
    --global-option="build_ext" \
    --global-option="-DCMAKE_TOOLCHAIN_FILE=$CMAKE_TOOLCHAIN_FILE" \
    --global-option="-DANDROID_ABI=$ANDROID_ABI" \
    --global-option="-DANDROID_NATIVE_API_LEVEL=$ANDROID_NATIVE_API_LEVEL" \
    --no-build-isolation

# 移动生成的 Wheel 文件到输出目录
mv *.whl output/
