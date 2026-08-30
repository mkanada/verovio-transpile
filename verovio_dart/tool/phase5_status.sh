#!/usr/bin/env bash
#
# phase5_status.sh — o placar da Fase 5 num comando. É o que o prompt `medium`
# roda para saber onde está e o que falta; não mede nada por conta própria,
# apenas reúne os medidores que já existem.
#
# Uso (a partir de verovio_dart/):
#   tool/phase5_status.sh            # rápido (~1 min): lê relatórios em disco
#   tool/phase5_status.sh --full     # regera compare_svg (~10 min) antes
#
# Sai 0 só quando a Fase 5 fechou por completo (portão 5.1..5.6 verde).
set -uo pipefail

[[ -f pubspec.yaml ]] || { echo "rode a partir de verovio_dart/"; exit 2; }

if [[ "${1:-}" == "--full" ]]; then
  echo "== regerando compare_svg --all (pode levar ~10 min) =="
  dart run tool/compare_svg.dart --all 2>&1 | tail -5
  echo ""
fi

echo "=================================================================="
echo " FASE 5 — placar"
echo "=================================================================="
echo ""
echo "-- 5.1 / 5.2 / 5.3  dívida de tipagem em lib/src/rendering --------"
dart run tool/debt_report.dart
DEBT_RC=$?
echo ""

echo "-- 5.6  fidelidade de SVG ----------------------------------------"
if [[ -f tool/SVG_VALIDATION.md ]]; then
  NEWEST_LIB=$(find lib -name '*.dart' -newer tool/SVG_VALIDATION.md 2>/dev/null | head -1)
  if [[ -n "$NEWEST_LIB" ]]; then
    echo "  AVISO: o relatório está mais velho que lib/ (ex.: $NEWEST_LIB)."
    echo "         Rode com --full antes de confiar nestes números."
  fi
  grep -E '^Estrutural:|^Numérico' tool/SVG_VALIDATION.md | sed 's/^/  /'
  grep -E '^- Falhas' tool/SVG_VALIDATION.md | sed 's/^/  /'
else
  echo "  AUSENTE — rode: dart run tool/compare_svg.dart --all"
fi
echo ""

echo "-- famílias ainda em zero estrutural (alvo do trabalho de 5.6) ----"
if [[ -f tool/SVG_VALIDATION.md ]]; then
  awk -F'|' '/^\| [a-z]/ && $3+0==0 && $8+0>0 {gsub(/ /,"",$2); gsub(/ /,"",$8);
             printf "  %-16s 0/%s\n", $2, $8}' tool/SVG_VALIDATION.md \
    | sort -t/ -k2 -rn | head -12
fi
echo ""

echo "-- portão oficial ------------------------------------------------"
dart run tool/verify_phases.dart --fase=5 2>&1 | tail -14
GATE_RC=${PIPESTATUS[0]}

echo ""
echo "=================================================================="
if (( GATE_RC == 0 )); then
  echo " FASE 5 FECHADA — o portão passou."
else
  echo " FASE 5 ABERTA. Próximo passo:"
  if (( DEBT_RC != 0 )); then
    echo "   1. Zerar a dívida de tipagem (5.1/5.2/5.3). Fatie com:"
    echo "        dart run tool/debt_report.dart --by-method"
  fi
  echo "   2. Fidelidade (5.6): use o pinpointing de chamadas de desenho"
  echo "        dart run tool/probe_diff.dart test/corpus/<fam>/<arq>.mei"
fi
echo "=================================================================="
exit $GATE_RC
