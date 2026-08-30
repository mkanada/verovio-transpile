#!/usr/bin/env bash
# gen_probe_fixtures.sh — gera fixtures do probe 05-38 e verifica invariante SVG
#
# Uso (a partir de verovio_dart/):
#   tool/gen_probe_fixtures.sh                # todo o corpus
#   tool/gen_probe_fixtures.sh note beam      # só famílias pedidas
#   tool/gen_probe_fixtures.sh clef           # uma família
#
# Para cada .mei em test/corpus/<fam>/*.mei:
#   cpp_probe/run.sh 05-38 test/corpus/<fam>/<arq>.mei \
#       test/fixtures/cpp/05-38/<fam>/<arq>.mei.jsonl --svg /tmp/probe.svg
#   build/verovio -r verovio_dart/assets/data -x 12345 -o /tmp/clean.svg <arq>
#   diff /tmp/clean.svg /tmp/probe.svg  # aborta no primeiro que divergir
#
# Fixtures são gerados sob demanda, por família, e não commitados em massa
# (Parte 4 do prompt 05-38).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DART_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE_ROOT="$(cd "$DART_ROOT/.." && pwd)"

TASK="05-38"
FIXTURE_ROOT="$DART_ROOT/test/fixtures/cpp/$TASK"
CORPUS_ROOT="$DART_ROOT/test/corpus"
CLEAN_BIN="$WORKSPACE_ROOT/build/verovio"
PROBE_RUN="$WORKSPACE_ROOT/cpp_probe/run.sh"

if [[ ! -x "$CLEAN_BIN" ]]; then
  echo "gen_probe_fixtures.sh: erro — binário limpo não encontrado: $CLEAN_BIN" >&2
  echo "  Compile com: cmake -S origin/src/cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DNO_HUMDRUM_SUPPORT=ON && ninja -C build" >&2
  exit 1
fi
if [[ ! -x "$PROBE_RUN" ]]; then
  echo "gen_probe_fixtures.sh: erro — $PROBE_RUN não encontrado" >&2
  exit 1
fi

# Famílias a processar: argumentos ou todo o corpus
FAMILIES=()
if [[ $# -gt 0 ]]; then
  for arg in "$@"; do
    # Aceita tanto "note" quanto "test/corpus/note"
    fam="${arg##*/}"
    fam="${fam%/}"
    FAMILIES+=("$fam")
  done
else
  # Todas as subpastas de test/corpus que contêm .mei
  while IFS= read -r -d '' dir; do
    fam="$(basename "$dir")"
    FAMILIES+=("$fam")
  done < <(find "$CORPUS_ROOT" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)
fi

TOTAL=0
OK=0
for fam in "${FAMILIES[@]}"; do
  corpus_dir="$CORPUS_ROOT/$fam"
  if [[ ! -d "$corpus_dir" ]]; then
    echo "gen_probe_fixtures.sh: aviso — família não encontrada: $corpus_dir (pulando)" >&2
    continue
  fi
  # Ordena para determinismo
  while IFS= read -r -d '' mei; do
    rel="${mei#$CORPUS_ROOT/}" # clef/clef-001.mei
    # Saída espelhada: test/fixtures/cpp/05-38/<rel>.jsonl  => test/fixtures/cpp/05-38/clef/clef-001.mei.jsonl
    out="$FIXTURE_ROOT/$rel.jsonl"
    flat="$FIXTURE_ROOT/$(basename "$rel").jsonl"
    mkdir -p "$(dirname "$out")"
    echo "[$fam] $rel -> ${out#$DART_ROOT/}"
    # Gera fixture + SVG do probe
    tmp_probe_svg="$(mktemp)"
    # run.sh já verifica VRV_PROBE_OUT e escreve o SVG da mesma execução
    "$PROBE_RUN" "$TASK" "$mei" "$out" --svg "$tmp_probe_svg"
    # Também mantém cópia plana (ex.: note-001.mei.jsonl) para compat com o exemplo do prompt (§1)
    cp "$out" "$flat"
    # Gera SVG limpo e compara
    tmp_clean_svg="$(mktemp)"
    "$CLEAN_BIN" -r "$DART_ROOT/assets/data" -x 12345 -o "$tmp_clean_svg" "$mei" >/dev/null 2>&1
    if ! diff -q "$tmp_clean_svg" "$tmp_probe_svg" >/dev/null 2>&1; then
      echo "gen_probe_fixtures.sh: ERRO — SVG divergiu para $rel" >&2
      echo "  diff $tmp_clean_svg $tmp_probe_svg mostrou diferença — a instrumentação alterou lógica!" >&2
      diff "$tmp_clean_svg" "$tmp_probe_svg" | head -n 40 >&2
      rm -f "$tmp_clean_svg" "$tmp_probe_svg"
      exit 1
    fi
    rm -f "$tmp_clean_svg" "$tmp_probe_svg"
    TOTAL=$((TOTAL+1))
    OK=$((OK+1))
  done < <(find "$corpus_dir" -maxdepth 1 -name '*.mei' -type f -print0 | sort -z)
done

echo "gen_probe_fixtures.sh: $OK/$TOTAL arquivo(s) gerados em $FIXTURE_ROOT (invariante SVG ok)"
