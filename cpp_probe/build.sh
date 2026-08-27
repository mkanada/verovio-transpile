#!/usr/bin/env bash
#
# build.sh — sync + patch até <id> + cmake/ninja incremental.
#
# Uso: cpp_probe/build.sh <id>
#
# Produz build-probe/build/verovio, o binário instrumentado. As flags são as
# mesmas do binário limpo em build/ (Release, NO_HUMDRUM_SUPPORT=ON), inclusive
# CMAKE_CXX_FLAGS — sobrescreva com a variável de ambiente PROBE_CXX_FLAGS se a
# sua máquina precisar de outra coisa.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DST="$ROOT/build-probe/src"
BUILD="$ROOT/build-probe/build"

if [[ $# -ne 1 ]]; then
  echo "uso: cpp_probe/build.sh <id>" >&2
  exit 2
fi
ID="$1"

for tool in cmake ninja rsync patch; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "cpp_probe/build.sh: erro — '$tool' não está no PATH." >&2
    exit 1
  }
done

# Mesmas flags do build/CMakeCache.txt do binário limpo.
: "${PROBE_CXX_FLAGS:=-I/usr/include/c++/13/ -I/usr/include/x86_64-linux-gnu/c++/13/}"

"$ROOT/cpp_probe/sync.sh"
"$ROOT/cpp_probe/patch.sh" "$ID"

cmake -S "$DST/cmake" -B "$BUILD" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DNO_HUMDRUM_SUPPORT=ON \
  -DCMAKE_CXX_FLAGS="$PROBE_CXX_FLAGS" >/dev/null

if ! ninja -C "$BUILD"; then
  echo "cpp_probe/build.sh: erro — a compilação do binário instrumentado falhou." >&2
  exit 1
fi

echo "cpp_probe/build.sh: $BUILD/verovio pronto (patches até $ID)"
