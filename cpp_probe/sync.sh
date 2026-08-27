#!/usr/bin/env bash
#
# sync.sh — copia origin/src para build-probe/src sem destruir os objetos do ninja.
#
# Usa rsync (não `cp -r`) para que apenas os arquivos que mudaram tenham o mtime
# atualizado: assim o ninja recompila só o que o patch tocou. `--delete` remove do
# destino o que sumiu da origem, mas nunca toca em build-probe/build/, que fica
# fora de build-probe/src/.
#
# Uso: cpp_probe/sync.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/origin/src"
DST="$ROOT/build-probe/src"

if [[ ! -d "$SRC" ]]; then
  echo "cpp_probe/sync.sh: erro — $SRC não existe." >&2
  echo "  A árvore C++ de referência (Verovio 6.2.0) é obrigatória." >&2
  exit 1
fi

mkdir -p "$DST"
# include/vrv/git_commit.h é gerado pelo cmake dentro da árvore de fontes;
# sincronizá-lo faria o ninja recompilar meio mundo a cada sync e sujaria os
# patches com ruído de build.
rsync -a --delete \
  --exclude 'include/vrv/git_commit.h' \
  --exclude 'tools/get_git_commit.sh' \
  "$SRC/" "$DST/"

# O `tools/get_git_commit.sh` original carimba o SHA do repositório no binário
# ("Verovio 6.2.0-f997a93"), e esse texto sai no <desc> do SVG. O binário limpo
# em build/ foi compilado antes de o workspace virar um repositório git, então
# ele diz só "Verovio 6.2.0". Sem neutralizar isto, a comparação "o SVG do
# instrumentado é idêntico ao do limpo" acusaria uma diferença que não tem nada
# a ver com a instrumentação — e mudaria a cada commit.
#
# Substituímos o script por um que fixa GIT_COMMIT vazio, e o reescrevemos só
# quando o conteúdo muda, para não disparar recompilação a cada sync.
mkdir -p "$DST/tools"
cat > "$DST/tools/get_git_commit.sh.new" <<'STUB'
#!/usr/bin/env sh
# Substituído por cpp_probe/sync.sh: ver o comentário lá.
cd ..
output="./include/vrv/git_commit.h"
cat > "$output.new" <<'HDR'
////////////////////////////////////////////////////////
/// Git commit version file generated at compilation ///
////////////////////////////////////////////////////////

#define GIT_COMMIT ""

HDR
if [ ! -f "$output" ] || ! cmp -s "$output" "$output.new"; then mv "$output.new" "$output"; else rm -f "$output.new"; fi
STUB
if [ ! -f "$DST/tools/get_git_commit.sh" ] \
   || ! cmp -s "$DST/tools/get_git_commit.sh" "$DST/tools/get_git_commit.sh.new"; then
  mv "$DST/tools/get_git_commit.sh.new" "$DST/tools/get_git_commit.sh"
  chmod +x "$DST/tools/get_git_commit.sh"
else
  rm -f "$DST/tools/get_git_commit.sh.new"
fi

echo "cpp_probe/sync.sh: origin/src -> build-probe/src (limpo, sem patches)"
