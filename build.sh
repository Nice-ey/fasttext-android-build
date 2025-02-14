#!/bin/bash

# 创建输出目录
mkdir -p output

# 设置目标架构（armeabi-v7a）
TARGET_ARCH="armeabi-v7a"
ANDROID_API=21
NDK_HOME="$GITHUB_WORKSPACE/android-ndk-r21e"  # 显式定义 NDK 路径

# 配置工具链参数
case $TARGET_ARCH in
    "armeabi-v7a")
        CLANG_PREFIX="armv7a-linux-androideabi$ANDROID_API"
        TOOLCHAIN_DIR="$NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64"
        SYSROOT="$TOOLCHAIN_DIR/sysroot"
        ;;
    *)
        echo "Unsupported ABI: $TARGET_ARCH"
        exit 1
        ;;
esac

# 创建虚拟环境
python -m venv venv
source venv/bin/activate

# 安装基础构建工具
pip install --upgrade pip setuptools wheel
pip install meson ninja cmake==3.22.1

# 设置核心环境变量
export CC="$TOOLCHAIN_DIR/bin/$CLANG_PREFIX-clang"
export CXX="$TOOLCHAIN_DIR/bin/$CLANG_PREFIX-clang++"
export AR="$TOOLCHAIN_DIR/bin/llvm-ar"
export LD="$TOOLCHAIN_DIR/bin/ld"
export RANLIB="$TOOLCHAIN_DIR/bin/llvm-ranlib"
export STRIP="$TOOLCHAIN_DIR/bin/llvm-strip"
export CFLAGS="-fPIE -fPIC -I$SYSROOT/usr/include"
export CPPFLAGS="-I$SYSROOT/usr/include"
export LDFLAGS="-pie -L$SYSROOT/usr/lib"

# 生成 meson 交叉编译文件
cat > android-cross.ini <<EOF
[binaries]
c = '$CC'
cpp = '$CXX'
ar = '$AR'
strip = '$STRIP'

[properties]
sys_root = '$SYSROOT'
c_args = ['-I$SYSROOT/usr/include']
c_link_args = ['-L$SYSROOT/usr/lib']

[host_machine]
system = 'android'
cpu_family = 'arm'
cpu = 'armv7a'
endian = 'little'
EOF

# 编译 numpy 时强制使用交叉编译
pip install numpy \
    --no-binary numpy \
    --config-settings="--cross-file=$(pwd)/android-cross.ini"

# 编译 fasttext
pip wheel fasttext==0.9.2 \
    --no-deps \
    --global-option="build_ext" \
    --global-option="-DCMAKE_TOOLCHAIN_FILE=$NDK_HOME/build/cmake/android.toolchain.cmake" \
    --global-option="-DANDROID_ABI=$TARGET_ARCH" \
    --global-option="-DANDROID_NATIVE_API_LEVEL=$ANDROID_API" \
    --config-settings="--cross-file=$(pwd)/android-cross.ini"

# 处理产物
mkdir -p output
mv *.whl output/ 2>/dev/null || echo "No wheels generated"
