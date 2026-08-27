#!/usr/bin/env bash
#
# run.sh — roda o binário instrumentado sobre um arquivo do corpus e grava o
# fixture JSON Lines, com o cabeçalho de proveniência `_meta` na primeira linha.
#
# Uso: cpp_probe/run.sh <id> <entrada.mei> <saida.jsonl> [--svg <saida.svg>]
#
#   <id>            id da tarefa (04a, EXEMPLO, …). Vai para `_meta.task` e
#                   determina a pilha de patches registrada em `_meta.patches`.
#   <entrada.mei>   caminho do arquivo de entrada. Aceita caminho absoluto, ou
#                   relativo à raiz do workspace, ou relativo a verovio_dart/
#                   (que é a forma usada nos fixtures: test/corpus/...).
#   <saida.jsonl>   arquivo a gravar.
#   --svg <path>    grava também o SVG produzido nesta mesma execução, para a
#                   verificação de que a instrumentação não mudou comportamento.
#
# A semente de ids XML é FIXA (ver PROBE_SEED abaixo): sem ela o C++ sorteia os
# @xml:id a cada execução e o fixture deixa de ser reproduzível.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="$ROOT/build-probe/build/verovio"
RESOURCES="$ROOT/verovio_dart/assets/data"
ORDER="$ROOT/cpp_probe/patches/ORDER"

# Semente fixa dos @xml:id. Documentada em cpp_probe/README.md; não mude sem
# regerar TODOS os fixtures.
PROBE_SEED="${PROBE_SEED:-12345}"

if [[ $# -lt 3 ]]; then
  echo "uso: cpp_probe/run.sh <id> <entrada.mei> <saida.jsonl> [--svg <saida.svg>]" >&2
  exit 2
fi
ID="$1"; INPUT="$2"; OUTPUT="$3"; shift 3

SVG_OUT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --svg) SVG_OUT="${2:?--svg exige um caminho}"; shift 2 ;;
    *) echo "cpp_probe/run.sh: argumento desconhecido: $1" >&2; exit 2 ;;
  esac
done

if [[ ! -x "$BIN" ]]; then
  echo "cpp_probe/run.sh: erro — $BIN não existe." >&2
  echo "  Rode antes: cpp_probe/build.sh $ID" >&2
  exit 1
fi

# Resolve a entrada nas três formas aceitas.
if   [[ -f "$INPUT" ]];                        then IN_ABS="$(cd "$(dirname "$INPUT")" && pwd)/$(basename "$INPUT")"
elif [[ -f "$ROOT/$INPUT" ]];                  then IN_ABS="$ROOT/$INPUT"
elif [[ -f "$ROOT/verovio_dart/$INPUT" ]];     then IN_ABS="$ROOT/verovio_dart/$INPUT"
else
  echo "cpp_probe/run.sh: erro — entrada não encontrada: $INPUT" >&2
  exit 1
fi

# `_meta.source` é sempre relativo a verovio_dart/, como nos prompts.
SOURCE_REL="${IN_ABS#"$ROOT"/verovio_dart/}"
SOURCE_REL="${SOURCE_REL#"$ROOT"/}"

TMPDIR_RUN="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_RUN"' EXIT
RECORDS="$TMPDIR_RUN/records.jsonl"
SVG="${SVG_OUT:-$TMPDIR_RUN/out.svg}"
: > "$RECORDS"

VRV_PROBE_OUT="$RECORDS" "$BIN" \
  -r "$RESOURCES" \
  -x "$PROBE_SEED" \
  -o "$SVG" \
  "$IN_ABS" >/dev/null

if [[ ! -s "$RECORDS" ]]; then
  echo "cpp_probe/run.sh: erro — o binário não emitiu nenhum registro." >&2
  echo "  Ou o patch '$ID' não instrumenta nada que este arquivo exercite," >&2
  echo "  ou build-probe/ está com a pilha de patches errada." >&2
  exit 1
fi

# Só o número da versão: o sufixo de commit que o cmake grava em git_commit.h
# muda com o HEAD do repositório e faria os fixtures mudarem sem que nenhum
# número tivesse mudado.
VERSION="$("$BIN" --version 2>&1 | head -1 | tr -d '\r' | sed -E 's/^Verovio //; s/-[0-9a-f]{7,}$//')"
PATCHES="$(sed -e 's/#.*//' -e 's/[[:space:]]//g' "$ORDER" | grep -v '^$' \
           | awk -v t="$ID" '{print} $0==t{exit}' | paste -sd, -)"

mkdir -p "$(dirname "$OUTPUT")"

# O cabeçalho `_meta` é montado aqui (o C++ não sabe de tarefa nem de corpus).
# `generated` só muda quando os *registros* mudam: assim regerar um fixture que
# não mudou produz o mesmo arquivo byte a byte, e a data continua significando
# "quando estes números foram medidos".
python3 - "$OUTPUT" "$RECORDS" "$ID" "$SOURCE_REL" "$PROBE_SEED" "$VERSION" "$PATCHES" <<'PY'
import datetime, json, os, sys

out, records, task, source, seed, version, patches = sys.argv[1:8]

with open(records, "r", encoding="utf-8") as fh:
    body = fh.read()

for lineno, line in enumerate(body.splitlines(), start=2):
    try:
        json.loads(line)
    except json.JSONDecodeError as exc:
        sys.exit("cpp_probe/run.sh: registro inválido na linha %d: %s" % (lineno, exc))

generated = datetime.date.today().isoformat()
if os.path.exists(out):
    with open(out, "r", encoding="utf-8") as fh:
        old = fh.read()
    head, _, old_body = old.partition("\n")
    if old_body == body:
        try:
            generated = json.loads(head)["_meta"].get("generated", generated)
        except Exception:
            pass

meta = {"_meta": {
    "task": task,
    "source": source,
    "xmlIdSeed": int(seed),
    "verovio": version,
    "patches": patches.split(",") if patches else [],
    "generated": generated,
}}

with open(out, "w", encoding="utf-8") as fh:
    fh.write(json.dumps(meta, separators=(",", ":"), sort_keys=False) + "\n")
    fh.write(body)
PY

echo "cpp_probe/run.sh: $OUTPUT ($(( $(wc -l < "$OUTPUT") - 1 )) registros, semente $PROBE_SEED)"
[[ -n "$SVG_OUT" ]] && echo "cpp_probe/run.sh: SVG desta mesma execução em $SVG_OUT"
exit 0
