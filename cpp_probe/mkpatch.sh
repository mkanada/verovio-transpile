#!/usr/bin/env bash
#
# mkpatch.sh — grava cpp_probe/patches/<id>.patch a partir do que você editou em
# build-probe/src.
#
# Uso: cpp_probe/mkpatch.sh <id>
#
# O patch é o diff entre:
#   a/  = origin/src com os patches ANTERIORES a <id> aplicados
#   b/  = build-probe/src, do jeito que está agora
# ou seja: exatamente a sua contribuição, empilhável sobre as anteriores.
#
# <id> precisa já estar listado em cpp_probe/patches/ORDER, na posição certa.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PATCHDIR="$ROOT/cpp_probe/patches"
ORDER="$PATCHDIR/ORDER"

if [[ $# -ne 1 ]]; then
  echo "uso: cpp_probe/mkpatch.sh <id>" >&2
  exit 2
fi
ID="$1"

mapfile -t IDS < <(sed -e 's/#.*//' -e 's/[[:space:]]//g' "$ORDER" | grep -v '^$')
if ! printf '%s\n' "${IDS[@]}" | grep -qx -- "$ID"; then
  echo "cpp_probe/mkpatch.sh: erro — id '$ID' não está em $ORDER." >&2
  echo "  Acrescente-o lá primeiro, na posição de execução da tarefa." >&2
  exit 1
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# a/ = origin limpo + patches anteriores a <id>
rsync -a --exclude 'include/vrv/git_commit.h' --exclude 'tools/get_git_commit.sh' "$ROOT/origin/src/" "$WORK/a/"
for id in "${IDS[@]}"; do
  [[ "$id" == "$ID" ]] && break
  P="$PATCHDIR/$id.patch"
  [[ -f "$P" ]] || { echo "cpp_probe/mkpatch.sh: erro — patch ausente: $P" >&2; exit 1; }
  patch -p1 -d "$WORK/a" --batch --forward -i "$P" >/dev/null
done

# b/ = a árvore instrumentada como está
rsync -a --exclude 'include/vrv/git_commit.h' --exclude 'tools/get_git_commit.sh' "$ROOT/build-probe/src/" "$WORK/b/"

OUT="$PATCHDIR/$ID.patch"
( cd "$WORK" && diff -ruN a b ) > "$OUT" || true

if [[ ! -s "$OUT" ]]; then
  echo "cpp_probe/mkpatch.sh: erro — o diff saiu vazio. Você editou build-probe/src?" >&2
  rm -f "$OUT"
  exit 1
fi

REMOVED="$(grep -c '^-[^-]' "$OUT" || true)"
if [[ "$REMOVED" != "0" ]]; then
  echo "cpp_probe/mkpatch.sh: AVISO — o patch remove $REMOVED linha(s) do C++." >&2
  echo "  Instrumentação é só acrescentar. Reveja: um patch que apaga lógica corrompe" >&2
  echo "  silenciosamente todos os fixtures que dele derivarem." >&2
fi

echo "cpp_probe/mkpatch.sh: $OUT ($(grep -c '^+++' "$OUT") arquivos, $(grep -c '^+[^+]' "$OUT") linhas acrescentadas, $REMOVED removidas)"
