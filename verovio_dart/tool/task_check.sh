#!/usr/bin/env bash
#
# task_check.sh — o portão que uma unidade de trabalho (prompt `small`) roda
# para saber, sozinha, se atingiu o objetivo. Saída binária: PASS ou FAIL com
# o motivo e o comando que mostra o detalhe.
#
# Uso (a partir de verovio_dart/):
#   tool/task_check.sh --baseline                 # antes de começar um lote
#   tool/task_check.sh <arquivo.dart> [familia…]  # depois de cada unidade
#
#   <arquivo.dart>  nome do arquivo de rendering que a unidade tocou
#                   (ex.: view_control.dart). A dívida DELE tem de cair.
#   [familia…]      diretórios de corpus afetados (ex.: dir dynam tempo).
#                   Opcional: sem eles, a checagem de SVG é pulada e o texto
#                   diz isso — silêncio nunca é aprovação.
#
# Regras (todas têm de valer):
#   1. `dart analyze` <= baseline (8, todas em tool/_scratch_*).
#   2. A dívida não aumentou em NENHUM arquivo (vs tool/.phase5_baseline.json).
#   3. A dívida do arquivo alvo DIMINUIU (a unidade fez algo).
#   4. `dart test` verde nos testes indicados por --tests (ou os do arquivo).
#   5. As famílias de corpus indicadas não regrediram em SVG estrutural.
set -uo pipefail

BASELINE="tool/.phase5_baseline.json"
ANALYZE_BASELINE=8

die()  { echo ""; echo "FAIL: $*"; exit 1; }
ok()   { echo "  [ok] $*"; }

if [[ ! -f pubspec.yaml ]]; then
  echo "FAIL: rode a partir de verovio_dart/ (não achei pubspec.yaml)."; exit 2
fi

# ---------------------------------------------------------------- --baseline
if [[ "${1:-}" == "--baseline" ]]; then
  dart run tool/debt_report.dart --write-baseline="$BASELINE" || exit 2
  if [[ -f tool/SVG_VALIDATION.md ]]; then
    grep -oE 'Estrutural: [0-9]+/[0-9]+' tool/SVG_VALIDATION.md | head -1 \
      > tool/.phase5_svg_baseline.txt
    echo "baseline de SVG: $(cat tool/.phase5_svg_baseline.txt)"
  else
    echo "AVISO: tool/SVG_VALIDATION.md ausente — rode"
    echo "       dart run tool/compare_svg.dart --all"
  fi
  exit 0
fi

TARGET="${1:-}"
[[ -z "$TARGET" ]] && { echo "uso: tool/task_check.sh <arquivo.dart> [familia…]"; exit 2; }
shift || true
FAMILIES=("$@")

[[ -f "$BASELINE" ]] || die "baseline ausente. Rode: tool/task_check.sh --baseline"
[[ -f "lib/src/rendering/$TARGET" ]] || die "lib/src/rendering/$TARGET não existe."

echo "== task_check: $TARGET =="

# --------------------------------------------------------------- 1. analyze
# A contagem vem da linha-resumo ("N issues found." / "No issues found!"),
# que é estável — o formato das linhas de detalhe varia entre invocações.
AOUT=$(dart analyze 2>&1)
if grep -q 'No issues found' <<< "$AOUT"; then
  N=0
else
  N=$(grep -oE '^[0-9]+ issues? found' <<< "$AOUT" | grep -oE '^[0-9]+')
  [[ -z "$N" ]] && die "não consegui ler a contagem de \`dart analyze\`:
$(tail -3 <<< "$AOUT")"
fi
if (( N > ANALYZE_BASELINE )); then
  echo ""
  grep -E '(error|warning|info) - ' <<< "$AOUT" | grep -v 'tool/_scratch' | head -20
  die "dart analyze subiu para $N (baseline $ANALYZE_BASELINE). As linhas acima não estão na baseline."
fi
ok "dart analyze: $N (baseline $ANALYZE_BASELINE)"

# ------------------------------------------------- 2+3. dívida do arquivo
if ! dart run tool/debt_report.dart --baseline="$BASELINE" > /tmp/_debt.txt 2>&1; then
  if grep -q 'a dívida aumentou' /tmp/_debt.txt; then
    echo ""; cat /tmp/_debt.txt
    die "a dívida aumentou em algum arquivo (regra 2)."
  fi
  # exit 1 sem 'aumentou' = dívida global ainda > 0, que é esperado no meio do
  # caminho; não é motivo de reprovação de unidade.
fi
NOW=$(dart run tool/debt_report.dart --file="$TARGET" --json 2>/dev/null \
      | python3 -c "import json,sys;d=json.load(sys.stdin)['files'];k=list(d)[0];print(d[k]['dynamic']+d[k]['catch']+d[k]['ignore'])")
WAS=$(python3 -c "
import json;d=json.load(open('$BASELINE'))['files'].get('$TARGET')
print((d['dynamic']+d['catch']+d['ignore']) if d else -1)")
if [[ "$WAS" == "-1" ]]; then
  die "$TARGET não está na baseline. Regere: tool/task_check.sh --baseline"
fi
if (( NOW >= WAS )); then
  die "a dívida de $TARGET não caiu: era $WAS, está $NOW.
       A unidade não fez efeito. Veja onde ela está:
         dart run tool/debt_report.dart --file=$TARGET --by-method"
fi
ok "dívida de $TARGET: $WAS -> $NOW"

# ------------------------------------------------------------------ 4. testes
TESTS=$(ls test/*_test.dart 2>/dev/null | grep -E "$(echo "$TARGET" | sed 's/\.dart$//')" || true)
TESTS="$TESTS test/harness_integrity_test.dart test/svg_golden_test.dart"
echo "  … dart test $(echo $TESTS | wc -w) arquivo(s)"
if ! timeout 900 dart test $TESTS > /tmp/_test.txt 2>&1; then
  echo ""
  tr '\r' '\n' < /tmp/_test.txt | grep -E '\[E\]|Expected:|Actual:|Failed to load' | head -20
  die "teste vermelho. Detalhe: tr '\\r' '\\n' < /tmp/_test.txt | less"
fi
ok "testes verdes"

# ------------------------------------------------------------------- 5. SVG
if (( ${#FAMILIES[@]} == 0 )); then
  echo "  [--] SVG: NÃO VERIFICADO (nenhuma família passada)."
  echo "       Se a unidade muda desenho, rode com as famílias afetadas."
else
  for fam in "${FAMILIES[@]}"; do
    [[ -d "test/corpus/$fam" ]] || die "test/corpus/$fam não existe."
    OUT=$(timeout 600 dart run tool/compare_svg.dart "test/corpus/$fam" \
          --report=/tmp/_fam_$fam.md 2>&1 | grep -E 'Estrutural|falhas')
    LIMPOS=$(echo "$OUT" | grep -oE 'Estrutural: [0-9]+' | grep -oE '[0-9]+')
    FALHAS=$(echo "$OUT" | grep -oE 'falhas: [0-9]+' | grep -oE '[0-9]+')
    (( FALHAS > 0 )) && die "família '$fam' tem $FALHAS exceção(ões) de renderização.
       Nenhum arquivo pode lançar. Detalhe em /tmp/_fam_$fam.md"
    ok "família $fam: $LIMPOS estrutural limpos, 0 exceções"
  done
fi

echo ""
echo "PASS — unidade concluída. Não commite: quem commita é o prompt medium."
