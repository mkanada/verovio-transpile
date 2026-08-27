#!/usr/bin/env bash
#
# patch.sh — aplica, sobre build-probe/src, a pilha de patches de instrumentação
# listada em cpp_probe/patches/ORDER, de cima para baixo, até o id pedido.
#
# Uso: cpp_probe/patch.sh <id>
#      cpp_probe/patch.sh --list
#
# Cada patch é `diff -ruN`-compatível e é aplicado com `patch -p1`. Um patch que
# não aplica é erro fatal: não existe aplicação parcial silenciosa.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PATCHDIR="$ROOT/cpp_probe/patches"
DST="$ROOT/build-probe/src"
ORDER="$PATCHDIR/ORDER"

if [[ ! -f "$ORDER" ]]; then
  echo "cpp_probe/patch.sh: erro — $ORDER não existe." >&2
  exit 1
fi

# Lê ORDER ignorando comentários e linhas em branco.
mapfile -t IDS < <(sed -e 's/#.*//' -e 's/[[:space:]]//g' "$ORDER" | grep -v '^$')

if [[ "${1:-}" == "--list" ]]; then
  printf '%s\n' "${IDS[@]}"
  exit 0
fi

if [[ $# -ne 1 ]]; then
  echo "uso: cpp_probe/patch.sh <id>   (ids conhecidos: ${IDS[*]})" >&2
  exit 2
fi
TARGET="$1"

if ! printf '%s\n' "${IDS[@]}" | grep -qx -- "$TARGET"; then
  echo "cpp_probe/patch.sh: erro — id '$TARGET' não está em $ORDER." >&2
  echo "  ids conhecidos: ${IDS[*]}" >&2
  exit 1
fi

if [[ ! -d "$DST" ]]; then
  echo "cpp_probe/patch.sh: erro — $DST não existe. Rode cpp_probe/sync.sh antes." >&2
  exit 1
fi

APPLIED=()
for id in "${IDS[@]}"; do
  P="$PATCHDIR/$id.patch"
  if [[ ! -f "$P" ]]; then
    echo "cpp_probe/patch.sh: erro — patch ausente: $P" >&2
    exit 1
  fi
  if ! patch -p1 -d "$DST" --batch --forward -i "$P" >/tmp/cpp_probe_patch.log 2>&1; then
    echo "cpp_probe/patch.sh: erro — $id.patch não aplicou sobre build-probe/src:" >&2
    sed 's/^/    /' /tmp/cpp_probe_patch.log >&2
    exit 1
  fi
  APPLIED+=("$id")
  [[ "$id" == "$TARGET" ]] && break
done

echo "cpp_probe/patch.sh: aplicados ${APPLIED[*]}"
