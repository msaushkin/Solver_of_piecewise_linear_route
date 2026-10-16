#!/usr/bin/env bash
# ============================================================
#  setup-linux.sh
#  Однократная подготовка зависимостей (SFML 2.5.1) под Linux.
#  Скачивает исходники SFML и собирает статические библиотеки
#  текущим компилятором. Повторный запуск ничего не перекачивает
#  и не пересобирает, если установка готова.
#
#  Требуется: cmake (>= 3.16), g++ (>= 12), make в PATH.
#  Пакеты (Ubuntu/Debian): sudo apt install build-essential cmake
# ============================================================
set -euo pipefail
cd "$(dirname "$0")"

VERSION="2.5.1"
DEPS_DIR="build/deps"
SRC_DIR="$DEPS_DIR/SFML-$VERSION"
BUILD_DIR="$DEPS_DIR/SFML-$VERSION-build"
INSTALL_DIR="$DEPS_DIR/SFML-$VERSION-install"
ARCHIVE="$DEPS_DIR/SFML-$VERSION-sources.zip"
URL="https://www.sfml-dev.org/files/SFML-$VERSION-sources.zip"

command -v cmake >/dev/null 2>&1 || { echo "[ERROR] cmake not found. Install CMake >= 3.16."; exit 1; }
command -v g++ >/dev/null 2>&1 || { echo "[ERROR] g++ not found. Install GCC g++ >= 12 (e.g. build-essential)."; exit 1; }

GXX_MAJOR=$(g++ -dumpversion | cut -d. -f1)
if [ "$GXX_MAJOR" -lt 12 ]; then
    echo "[ERROR] g++ 12+ is required, found g++ $GXX_MAJOR."
    exit 1
fi

if [ -f "$INSTALL_DIR/lib/cmake/SFML/SFMLConfig.cmake" ]; then
    echo "[OK] SFML $VERSION is already built: $INSTALL_DIR"
    exit 0
fi

if [ ! -f "$SRC_DIR/CMakeLists.txt" ]; then
    echo "[..] Downloading SFML $VERSION sources..."
    mkdir -p "$DEPS_DIR"
    if command -v curl >/dev/null 2>&1; then
        curl -fL "$URL" -o "$ARCHIVE"
    elif command -v wget >/dev/null 2>&1; then
        wget -O "$ARCHIVE" "$URL"
    else
        echo "[ERROR] Neither curl nor wget found."; exit 1
    fi
    echo "[..] Extracting SFML $VERSION sources..."
    unzip -qo "$ARCHIVE" -d "$DEPS_DIR" || { echo "[ERROR] Failed to extract $ARCHIVE"; exit 1; }
fi

echo "[..] Configuring static SFML $VERSION build..."
cmake -S "$SRC_DIR" -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
      -DBUILD_SHARED_LIBS=OFF \
      -DSFML_BUILD_AUDIO=OFF -DSFML_BUILD_NETWORK=OFF \
      -DSFML_BUILD_EXAMPLES=OFF -DSFML_BUILD_DOC=OFF \
      -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR"

echo "[..] Building static SFML $VERSION (first run only, it may take a while)..."
cmake --build "$BUILD_DIR" --config Release --target install -j

echo "[OK] SFML $VERSION is ready: $INSTALL_DIR"
echo "     Now run ./compile-linux.sh to build the solver."