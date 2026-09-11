#!/usr/bin/env bash
#
# snapshot.sh — a ferramenta do lado C++ do snapshot de estado: roda o binário
# instrumentado (patch `snapshot`) e despeja o estado da árvore de objetos depois
# de cada functor de nível 0 e de cada desenho de página, na profundidade pedida.
# O lado Dart é `verovio_dart/tool/snapshot.dart` (mesmas opções); o comparador é
# `verovio_dart/tool/snapshot_diff.dart`. Guia: cpp_probe/snapshot/README.md.
#
# Uso: cpp_probe/snapshot.sh [opções] <arquivo.mei | diretório>...
#
#   --nivel=N         atalho (default 1):
#                       0  só a sequência de checkpoints          (modo seq)
#                       1  hash por checkpoint, grupos bb,pos      (modo digest)
#                       2  linhas completas, grupos bb,pos         (modo full)
#                       3  linhas completas, bb,pos,link,layout    (modo full)
#                       4  linhas completas, todos os grupos       (modo full)
#   --modo=seq|digest|full       sobrepõe o modo do nível
#   --grupos=bb,pos,link,layout,cache|all   sobrepõe os grupos do nível
#   --at=<regex>      só despeja os checkpoints cujo "Nome#k" ou "@seq" casa
#                     inteiro (ex.: 'AdjustXPosFunctor#3', '@5[67]'); a linha de
#                     sequência de todos os outros continua saindo
#   --path=<texto>    só entidades cuja chave contém <texto>
#   --classe=a,b      só entidades dessas classes (note, staffAlignment, …)
#   --excluir=a,b     fora das linhas e do hash: `campo`, `classe.campo` ou
#                     `key:<texto>` (entidades cuja chave contém <texto>); soma-se
#                     às entradas de cpp_probe/snapshot/exclude.list
#   --sem-lista       não aplica cpp_probe/snapshot/exclude.list
#   --saida=<dir>     default tmp/snapshot/cpp (relativo à raiz do workspace)
#   --check-svg       confere o SVG, byte a byte, contra build/verovio -x 12345
#   --opt <flag>      flag extra do CLI do verovio (repetível)
#
# Saída: <saida>/<família>/<arquivo>.mei.jsonl (o caminho relativo a
# verovio_dart/test/corpus/, ou ao diretório do arquivo quando fora do corpus).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="$ROOT/build-probe/build/verovio"
CLEAN="$ROOT/build/verovio"
RESOURCES="$ROOT/verovio_dart/assets/data"
SNAPDIR="$ROOT/cpp_probe/snapshot"
CORPUS="$ROOT/verovio_dart/test/corpus"
SEED="${PROBE_SEED:-12345}"

NIVEL=1; MODO=""; GRUPOS=""; AT=""; PATHF=""; CLASSE=""; EXCLUIR=""
SAIDA="$ROOT/tmp/snapshot/cpp"; CHECK=0; SEMLISTA=0; EXTRA_OPTS=(); INPUTS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --nivel=*|--level=*) NIVEL="${1#*=}" ;;
    --modo=*|--mode=*) MODO="${1#*=}" ;;
    --grupos=*|--groups=*) GRUPOS="${1#*=}" ;;
    --at=*) AT="${1#*=}" ;;
    --path=*) PATHF="${1#*=}" ;;
    --classe=*|--class=*) CLASSE="${1#*=}" ;;
    --excluir=*|--exclude=*) EXCLUIR="${1#*=}" ;;
    --saida=*|--out=*) SAIDA="${1#*=}"; [[ "$SAIDA" = /* ]] || SAIDA="$ROOT/$SAIDA" ;;
    --check-svg) CHECK=1 ;;
    --sem-lista) SEMLISTA=1 ;;
    --opt) EXTRA_OPTS+=("${2:?--opt exige uma flag}"); shift ;;
    -h|--help) sed -n '2,37p' "$0"; exit 0 ;;
    -*) echo "cpp_probe/snapshot.sh: opção desconhecida: $1" >&2; exit 2 ;;
    *) INPUTS+=("$1") ;;
  esac
  shift
done
[[ ${#INPUTS[@]} -gt 0 ]] || { sed -n '2,37p' "$0" >&2; exit 2; }

case "$NIVEL" in
  0) DMODO=seq;    DGRUPOS=bb,pos ;;
  1) DMODO=digest; DGRUPOS=bb,pos ;;
  2) DMODO=full;   DGRUPOS=bb,pos ;;
  3) DMODO=full;   DGRUPOS=bb,pos,link,layout ;;
  4) DMODO=full;   DGRUPOS=all ;;
  *) echo "cpp_probe/snapshot.sh: --nivel vai de 0 a 4" >&2; exit 2 ;;
esac
MODO="${MODO:-$DMODO}"; GRUPOS="${GRUPOS:-$DGRUPOS}"
[[ "$MODO" =~ ^(seq|digest|full)$ ]] || { echo "cpp_probe/snapshot.sh: --modo inválido: $MODO" >&2; exit 2; }
for g in ${GRUPOS//,/ }; do
  [[ "$g" =~ ^(bb|pos|link|layout|cache|all)$ ]] || { echo "cpp_probe/snapshot.sh: grupo desconhecido: $g" >&2; exit 2; }
done

# Exclusões: a lista padrão (a mesma que o lado Dart lê) + as da linha de comando.
if [[ $SEMLISTA -eq 0 && -f "$SNAPDIR/exclude.list" ]]; then
  LISTA="$(sed -e 's/#.*//' -e 's/[[:space:]]//g' "$SNAPDIR/exclude.list" | grep -v '^$' | paste -sd, - || true)"
  EXCLUIR="$(printf '%s,%s' "$LISTA" "$EXCLUIR" | sed -e 's/^,*//' -e 's/,*$//')"
fi

# O binário tem de ser o da pilha com o patch `snapshot`.
if [[ ! -x "$BIN" ]] || ! grep -q VRV_SNAPSHOT_OUT "$BIN"; then
  echo "cpp_probe/snapshot.sh: $BIN não tem o snapshot compilado." >&2
  echo "  Rode antes: cpp_probe/build.sh snapshot" >&2
  exit 1
fi
# O runtime e o código gerado não podem estar mais novos que o binário (o
# binário é derivado e local, então aqui mtime serve). Se o manifesto mudou sem
# regenerar, os dois lados continuam gerados da mesma versão — consistentes
# entre si; é o lado Dart que confere o conteúdo e manda regenerar.
for src in "$SNAPDIR"/*.cpp "$SNAPDIR"/*.h "$SNAPDIR"/*.inc; do
  if [[ "$src" -nt "$BIN" ]]; then
    echo "cpp_probe/snapshot.sh: $(basename "$src") mais novo que o binário — ninja incremental…" >&2
    ninja -C "$ROOT/build-probe/build" >/dev/null
    break
  fi
done

# Expande diretórios em arquivos .mei.
FILES=()
for in in "${INPUTS[@]}"; do
  for cand in "$in" "$ROOT/$in" "$ROOT/verovio_dart/$in"; do
    if [[ -d "$cand" ]]; then
      while IFS= read -r f; do FILES+=("$f"); done < <(find "$cand" -name '*.mei' | sort)
      continue 2
    elif [[ -f "$cand" ]]; then
      FILES+=("$(cd "$(dirname "$cand")" && pwd)/$(basename "$cand")")
      continue 2
    fi
  done
  echo "cpp_probe/snapshot.sh: entrada não encontrada: $in" >&2
  exit 1
done

TMPD="$(mktemp -d)"
trap 'rm -rf "$TMPD"' EXIT
FAILS=0
for f in "${FILES[@]}"; do
  rel="${f#"$CORPUS"/}"
  [[ "$rel" == "$f" ]] && rel="$(basename "$f")"
  out="$SAIDA/$rel.jsonl"
  mkdir -p "$(dirname "$out")"
  if ! VRV_SNAPSHOT_OUT="$out" VRV_SNAPSHOT_MODE="$MODO" VRV_SNAPSHOT_GROUPS="$GRUPOS" \
       VRV_SNAPSHOT_AT="$AT" VRV_SNAPSHOT_PATH="$PATHF" VRV_SNAPSHOT_CLASS="$CLASSE" \
       VRV_SNAPSHOT_EXCLUDE="$EXCLUIR" VRV_SNAPSHOT_SOURCE="test/corpus/$rel" \
       "$BIN" -r "$RESOURCES" -x "$SEED" "${EXTRA_OPTS[@]}" -o "$TMPD/probe.svg" "$f" >/dev/null 2>&1; then
    echo "FALHOU  $rel (o binário instrumentado saiu com erro)"
    FAILS=$((FAILS + 1))
    continue
  fi
  status=""
  if [[ $CHECK -eq 1 ]]; then
    "$CLEAN" -r "$RESOURCES" -x "$SEED" "${EXTRA_OPTS[@]}" -o "$TMPD/clean.svg" "$f" >/dev/null 2>&1 || true
    if cmp -s "$TMPD/probe.svg" "$TMPD/clean.svg"; then
      status="  svg idêntico"
    else
      status="  SVG DIFERENTE do binário limpo — a instrumentação mudou o comportamento"
      FAILS=$((FAILS + 1))
    fi
  fi
  echo "$(( $(grep -c '"fn"' "$out") )) checkpoints  ${out#"$ROOT"/}$status"
done
[[ $FAILS -eq 0 ]] || { echo "cpp_probe/snapshot.sh: $FAILS falha(s)" >&2; exit 1; }
