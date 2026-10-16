#!/usr/bin/env bash
# ============================================================
#  compile-linux.sh
#  Сборка solver (Linux) готовым сборочным каталогом.
#  Библиотеки SFML должны быть подготовлены заранее:
#      ./setup-linux.sh
#  Результат: build/solver (+ шрифты рядом).
# ============================================================
set -euo pipefail
cd "$(dirname "$0")"

command -v cmake >/dev/null 2>&1 || { echo "[ERROR] cmake not found. Install CMake >= 3.16."; exit 1; }

SFML_DIR="build/deps/SFML-2.5.1-install/lib/cmake/SFML"
if [ ! -f "$SFML_DIR/SFMLConfig.cmake" ]; then
    echo "[ERROR] SFML is not built yet. Run ./setup-linux.sh first."
    exit 1
fi

# Удаляем устаревшие каталоги сборки от прежних экспериментов.
for d in build-static build-262-static build-local build-win; do
    if [ -d "$d" ]; then
        echo "[..] Removing stale build dir $d"
        rm -rf "$d"
    fi
done

cmake -S . -B build -DCMAKE_BUILD_TYPE=Release \
      -DSFML_DIR="$(pwd)/$SFML_DIR" -DSFML_STATIC_LIBRARIES=TRUE
cmake --build build -j

echo "[OK] Built: $(pwd)/build/solver"