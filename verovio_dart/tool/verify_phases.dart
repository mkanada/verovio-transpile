/// Portão de verificação das Fases 1–5 do port Verovio → Dart.
///
/// Responde a **uma** pergunta, mecanicamente: as Fases 1 a 5 terminaram?
/// Cada critério é uma medição sobre a árvore, nunca a leitura de um checkbox
/// ou de um relatório escrito à mão. Sai com código 0 só se todas as fases
/// verificadas passarem.
///
/// Este arquivo é código de apoio do port, não port de nenhum arquivo C++.
///
/// Uso (a partir de `verovio_dart/`):
/// ```
/// dart run tool/verify_phases.dart            # tudo menos a varredura de SVG (~1 min)
/// dart run tool/verify_phases.dart --full     # inclui compare_svg --all e dart test (~15 min)
/// dart run tool/verify_phases.dart --fase=4   # só uma fase (1..5)
/// dart run tool/verify_phases.dart --verbose  # lista cada item medido, não só as falhas
/// ```
///
/// Sem `--full`, os critérios caros (varredura dos 623 arquivos, suíte de
/// testes) são lidos dos relatórios que as ferramentas gravam — e o portão
/// **reprova** se o relatório estiver mais velho que o código de `lib/`, para
/// que um número obsoleto nunca passe por medição fresca.
library;

import 'dart:io';

const String kOrigin = '../origin/src';
const int kAnalyzeBaseline = 8;

/// Resultado de um critério.
enum Nivel { pass, fail, info }

class Criterio {
  Criterio(this.fase, this.id, this.nivel, this.titulo, {this.detalhe = ''});
  final int fase;
  final String id;
  final Nivel nivel;
  final String titulo;
  final String detalhe;
}

final List<Criterio> resultados = [];

void ok(int fase, String id, String titulo, {String detalhe = ''}) =>
    resultados.add(Criterio(fase, id, Nivel.pass, titulo, detalhe: detalhe));

void falha(int fase, String id, String titulo, {String detalhe = ''}) =>
    resultados.add(Criterio(fase, id, Nivel.fail, titulo, detalhe: detalhe));

void info(int fase, String id, String titulo, {String detalhe = ''}) =>
    resultados.add(Criterio(fase, id, Nivel.info, titulo, detalhe: detalhe));

void checa(int fase, String id, String titulo, bool condicao,
        {String detalhe = ''}) =>
    condicao
        ? ok(fase, id, titulo, detalhe: detalhe)
        : falha(fase, id, titulo, detalhe: detalhe);

// ---------------------------------------------------------------------------
// Utilitários de leitura
// ---------------------------------------------------------------------------

String lerArquivo(String caminho) {
  final File f = File(caminho);
  return f.existsSync() ? f.readAsStringSync() : '';
}

/// Remove comentários C++ (`//` e `/* */`) antes de varrer código.
///
/// Sem isto o varredor confunde cabeçalho de licença com API (`Copyright(`) e
/// registro comentado com registro real — `genericlayerelement.cpp:25` tem um
/// `ClassRegistrar` comentado que o C++ deliberadamente não ativa.
String semComentarios(String cpp) => cpp
    .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '')
    .replaceAll(RegExp(r'//[^\n]*'), '');

/// Todos os `.dart` sob [dir], recursivo.
List<File> dartsEm(String dir) {
  final Directory d = Directory(dir);
  if (!d.existsSync()) return const [];
  return d
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}

/// Conta ocorrências de [padrao] em cada arquivo de [dir]; devolve só os que
/// têm pelo menos uma, ordenados do maior para o menor.
List<MapEntry<String, int>> contaPorArquivo(String dir, Pattern padrao) {
  final List<MapEntry<String, int>> saida = [];
  for (final File f in dartsEm(dir)) {
    final int n = padrao.allMatches(f.readAsStringSync()).length;
    if (n > 0) saida.add(MapEntry(f.path, n));
  }
  saida.sort((a, b) => b.value.compareTo(a.value));
  return saida;
}

int somaDe(List<MapEntry<String, int>> xs) => xs.fold(0, (a, e) => a + e.value);

/// Mtime mais recente sob `lib/`. Um relatório mais velho que isto é obsoleto.
DateTime ultimaMudancaEmLib() {
  DateTime maior = DateTime.fromMillisecondsSinceEpoch(0);
  for (final File f in dartsEm('lib')) {
    final DateTime m = f.lastModifiedSync();
    if (m.isAfter(maior)) maior = m;
  }
  return maior;
}

/// Roda um comando e devolve (exitCode, stdout+stderr).
(int, String) roda(String exe, List<String> args) {
  final ProcessResult r = Process.runSync(exe, args);
  return (r.exitCode, '${r.stdout}${r.stderr}');
}

// ---------------------------------------------------------------------------
// Fase 1 — Fundações
// ---------------------------------------------------------------------------

/// Métodos de `resources.h` que existem em Dart com nome idiomático (campo
/// público ou getter). Cada entrada é uma dívida de nomenclatura assumida, não
/// uma lacuna: o valor é o identificador Dart que a cobre.
const Map<String, String> kResourcesEquivalentes = {
  'GetCurrentFont': 'currentFont',
  'GetDefaultPath': 'defaultPath',
  'SetDefaultPath': 'defaultPath',
  'GetPath': 'path',
  'SetPath': 'path',
  'GetGlyphTable': 'glyphTable',
  'GetGlyphTableForModification': 'glyphTable',
  'GetTextFont': 'textFont',
  'GetName': 'textFontName',
  'SetCSSFont': 'setCssFont',
  'UseLiberationTextFont': 'useLiberationTextFont',
  'GetFallbackFont': 'fallbackFontName',
};

void verificaFase1() {
  const int f = 1;

  // 1.1 — Resources: cobertura da API de resources.h.
  final String h =
      semComentarios(lerArquivo('$kOrigin/include/vrv/resources.h'));
  final String dart = lerArquivo('lib/src/rendering/resources.dart');
  if (h.isEmpty) {
    info(f, '1.1', 'resources.h não encontrado — cobertura não verificada');
  } else {
    final Set<String> metodosCpp = RegExp(r'\b([A-Z][A-Za-z0-9_]*)\s*\(')
        .allMatches(h)
        .map((m) => m.group(1)!)
        .toSet();
    final List<String> ausentes = [];
    for (final String m in metodosCpp) {
      final String idiomatico =
          kResourcesEquivalentes[m] ?? (m[0].toLowerCase() + m.substring(1));
      if (!dart.contains(idiomatico)) ausentes.add('$m → $idiomatico');
    }
    checa(f, '1.1', 'Resources cobre a API de resources.h', ausentes.isEmpty,
        detalhe: ausentes.isEmpty
            ? '${metodosCpp.length} métodos'
            : 'sem contraparte: ${ausentes.join(", ")}');
  }

  // 1.2 — BBoxDeviceContext completo (as duas lacunas medidas em 2026-08-26).
  final String bbox = lerArquivo('lib/src/rendering/bbox_device_context.dart');
  final List<String> faltam = ['getPenWidthOverlap', 'setUserScale']
      .where((m) => !bbox.contains(m))
      .toList();
  checa(f, '1.2', 'BBoxDeviceContext: getPenWidthOverlap + setUserScale',
      faltam.isEmpty,
      detalhe: faltam.isEmpty ? '' : 'faltam: ${faltam.join(", ")}');

  // 1.3 — devicecontextbase portado.
  checa(f, '1.3', 'core/devicecontextbase.dart existe',
      File('lib/src/core/devicecontextbase.dart').existsSync());
}

// ---------------------------------------------------------------------------
// Fase 2 — Modelo de dados MEI
// ---------------------------------------------------------------------------

void verificaFase2() {
  const int f = 2;

  final String reg = lerArquivo('lib/src/factory_registry.dart') +
      lerArquivo('lib/src/model/factory_registry_gen.dart');

  // 2.1 — Todo ClassRegistrar do C++ tem registro em Dart, com o mesmo nome.
  final Set<String> nomesCpp = {};
  final Directory srcDir = Directory('$kOrigin/src');
  if (srcDir.existsSync()) {
    final RegExp rx = RegExp(r'ClassRegistrar<\w+>\s+\w+\s*\(\s*"([^"]+)"');
    for (final File cpp in srcDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.cpp'))) {
      for (final m in rx.allMatches(semComentarios(cpp.readAsStringSync()))) {
        nomesCpp.add(m.group(1)!);
      }
    }
  }

  final Set<String> nomesDart = RegExp(r"""\.register\(\s*'([^']+)'""")
      .allMatches(reg)
      .map((m) => m.group(1)!)
      .toSet();

  if (nomesCpp.isEmpty) {
    info(f, '2.1', 'origin/ indisponível — registros não comparados',
        detalhe: '${nomesDart.length} registros em Dart');
  } else {
    final List<String> ausentes = (nomesCpp.difference(nomesDart).toList())
      ..sort();
    checa(f, '2.1', 'todo ClassRegistrar do C++ tem registro em Dart',
        ausentes.isEmpty,
        detalhe: ausentes.isEmpty
            ? '${nomesCpp.length} nomes'
            : 'sem registro: ${ausentes.join(", ")}');
  }

  // 2.2 — Nenhum nome registrado duas vezes (o defeito que a 04i fechou:
  // Dots/Flag/TupletBracket/TupletNum todos como 'dots', AnnotScore como
  // 'annot'). Um registro duplicado sobrescreve o anterior em silêncio.
  final List<String> todos = RegExp(r"""\.register\(\s*'([^']+)'""")
      .allMatches(reg)
      .map((m) => m.group(1)!)
      .toList();
  final Map<String, int> contagem = {};
  for (final String n in todos) {
    contagem[n] = (contagem[n] ?? 0) + 1;
  }
  final List<String> dup = contagem.entries
      .where((e) => e.value > 1)
      .map((e) => '${e.key}×${e.value}')
      .toList()
    ..sort();
  checa(f, '2.2', 'nenhum nome registrado em duplicidade', dup.isEmpty,
      detalhe: dup.isEmpty ? '${todos.length} registros' : dup.join(', '));

  // 2.3 — As cinco classes que a 04i identificou como não registradas.
  final List<String> esperados = ['f', 'fb', 'lv', 'ossia', 'phrase'];
  final List<String> semRegistro =
      esperados.where((n) => !nomesDart.contains(n)).toList();
  checa(f, '2.3', 'F/Fb/Lv/Ossia/Phrase registrados (defeito da 04i)',
      semRegistro.isEmpty,
      detalhe: semRegistro.isEmpty ? '' : 'faltam: ${semRegistro.join(", ")}');
}

// ---------------------------------------------------------------------------
// Fase 3 — Leitura de arquivos
// ---------------------------------------------------------------------------

/// Confere que todo `<Classe>::Read<X>` do C++ tem um `read<X>` no Dart.
void _coberturaLeitor(int fase, String id, String rotulo, String cppPath,
    String classe, String dartPath) {
  final String cpp = lerArquivo(cppPath);
  final String dart = lerArquivo(dartPath);
  if (cpp.isEmpty) {
    info(fase, id, '$rotulo — origin/ indisponível');
    return;
  }
  final Set<String> leitores = RegExp('\\b$classe::Read([A-Za-z0-9_]+)\\s*\\(')
      .allMatches(cpp)
      .map((m) => m.group(1)!)
      .toSet();
  final List<String> ausentes =
      leitores.where((n) => !dart.contains('read$n')).toList()..sort();
  checa(
      fase, id, '$rotulo: todo Read* do C++ tem contraparte', ausentes.isEmpty,
      detalhe: ausentes.isEmpty
          ? '${leitores.length} leitores'
          : 'sem contraparte (${ausentes.length}): ${ausentes.take(12).join(", ")}');
}

void verificaFase3() {
  const int f = 3;

  _coberturaLeitor(f, '3.1', 'MEIInput', '$kOrigin/src/iomei.cpp', 'MEIInput',
      'lib/src/io/mei_input.dart');
  _coberturaLeitor(f, '3.2', 'MusicXmlInput', '$kOrigin/src/iomusxml.cpp',
      'MusicXmlInput', 'lib/src/io/iomusxml.dart');

  // 3.3 — os três leitores existem e estão ligados na detecção de formato.
  final String fmt = lerArquivo('lib/src/io/format.dart');
  final bool tresFormatos = File('lib/src/io/mei_input.dart').existsSync() &&
      File('lib/src/io/iomusxml.dart').existsSync() &&
      File('lib/src/io/ioabc.dart').existsSync() &&
      fmt.contains('identifyInputFrom');
  checa(f, '3.3', 'MEI + MusicXML + ABC ligados em identifyInputFrom',
      tresFormatos);

  // 3.4 — MEIOutput é da Fase 6 por decisão de 2026-08-29 (reescopo).
  // Registrado aqui como INFO para que a ausência nunca seja lida como
  // esquecimento — e para reprovar se alguém remarcar o checkbox na Fase 3.
  final bool escritaPortada = dartsEm('lib/src/io')
      .any((f) => f.readAsStringSync().contains('class MeiOutput'));
  info(
      f,
      '3.4',
      escritaPortada
          ? 'MEIOutput portado (adiantado da Fase 6)'
          : 'MEIOutput não portado — Fase 6 (06-08..06-11), por decisão de 2026-08-29',
      detalhe: 'a Fase 3 cobre leitura; a escrita é da Fase 6');
}

// ---------------------------------------------------------------------------
// Fase 4 — Motor de layout
// ---------------------------------------------------------------------------

/// Os quatro functors que a medição de 2026-08-29 achou genuinamente ausentes
/// e que são o último item aberto da Fase 4.
const List<String> kFunctorsFase4Abertos = [
  'AdjustXRelForTranscriptionFunctor',
  'AdjustYRelForTranscriptionFunctor',
  'ApplyPPUFactorFunctor',
  'ReorderByXPosFunctor',
];

void verificaFase4() {
  const int f = 4;

  final String layout =
      dartsEm('lib/src').map((f) => f.readAsStringSync()).join('\n');

  // 4.1 — os quatro functors abertos.
  final List<String> ausentes =
      kFunctorsFase4Abertos.where((n) => !layout.contains('class $n')).toList();
  checa(f, '4.1', 'functors de transcrição + ReorderByXPos portados',
      ausentes.isEmpty,
      detalhe: ausentes.isEmpty ? '' : 'faltam: ${ausentes.join(", ")}');

  // 4.2 — o stand-in headless foi mesmo deletado (a virada da 05-30).
  final bool semFallback =
      !File('lib/src/rendering/bbox_fallback.dart').existsSync() &&
          !File('lib/src/rendering/headless_extents.dart').existsSync();
  checa(f, '4.2', 'bbox_fallback/headless_extents deletados', semFallback);

  // 4.3 — nenhuma aproximação declarada sobrou.
  final int aprox = somaDe(contaPorArquivo('lib/src', 'Approximation:'));
  checa(f, '4.3', 'nenhum comentário `Approximation:` em lib/', aprox == 0,
      detalhe: aprox == 0 ? '' : '$aprox ocorrências');

  // 4.4 — inventário de functors, como INFO: os ausentes legítimos são da
  // Fase 6 (MIDI, transpose, convert, find, save, scoringup, facsimile) e
  // dois não são portados de propósito (ConstFunctor/DocConstFunctor).
  final Directory inc = Directory('$kOrigin/include/vrv');
  if (inc.existsSync()) {
    final Set<String> cpp = {};
    for (final File h in inc
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.h'))) {
      for (final m in RegExp(r'class\s+([A-Za-z]+Functor)\b')
          .allMatches(h.readAsStringSync())) {
        cpp.add(m.group(1)!);
      }
    }
    final Set<String> dart = RegExp(r'class\s+([A-Za-z]+Functor)\b')
        .allMatches(layout)
        .map((m) => m.group(1)!)
        .toSet();
    final int faltando = cpp.difference(dart).length;
    info(f, '4.4',
        'inventário de functors: ${dart.length} Dart / ${cpp.length} C++',
        detalhe: '$faltando ausentes (esperado: Fase 6 + 2 const propositais)');
  }

  // 4.5 — o relatório do layout, se existir e estiver fresco.
  _leRelatorio(
    fase: f,
    id: '4.5',
    caminho: 'tool/LAYOUT_VALIDATION.md',
    rotulo: 'validate_layout',
    comando: 'dart run tool/validate_layout.dart',
    extrai: (txt) {
      final m =
          RegExp(r'Layout OK \|\s*\*\*(\d+)\*\*\s*/\s*(\d+)').firstMatch(txt);
      if (m == null) return null;
      final int okN = int.parse(m.group(1)!);
      final int total = int.parse(m.group(2)!);
      return (okN == total, '$okN/$total arquivos com layout OK');
    },
  );
}

// ---------------------------------------------------------------------------
// Fase 5 — Renderização SVG
// ---------------------------------------------------------------------------

void verificaFase5() {
  const int f = 5;

  // 5.1/5.2/5.3 — a dívida de tipagem. Enquanto ela existir, um número de
  // divergências não distingue "algoritmo errado" de "código nunca executado".
  final List<MapEntry<String, int>> dyn =
      contaPorArquivo('lib/src/rendering', 'as dynamic');
  checa(f, '5.1', 'nenhum `as dynamic` em lib/src/rendering', dyn.isEmpty,
      detalhe: dyn.isEmpty
          ? ''
          : '${somaDe(dyn)} em ${dyn.length} arquivos — pior: ${_top(dyn)}');

  final List<MapEntry<String, int>> cat =
      contaPorArquivo('lib/src/rendering', 'catch (_)');
  checa(f, '5.2', 'nenhum `catch (_)` em lib/src/rendering', cat.isEmpty,
      detalhe: cat.isEmpty
          ? ''
          : '${somaDe(cat)} em ${cat.length} arquivos — pior: ${_top(cat)}');

  final List<MapEntry<String, int>> ign =
      contaPorArquivo('lib/src/rendering', 'ignore_for_file');
  checa(f, '5.3', 'nenhum `ignore_for_file` em lib/src/rendering', ign.isEmpty,
      detalhe: ign.isEmpty ? '' : '${ign.length} arquivos — ${_top(ign)}');

  // 5.4 — a mesma dívida fora de rendering/ (beam_segment, drawing_interfaces,
  // doc, adjust_tuplets…), como INFO: não bloqueia a Fase 5, mas é a mesma
  // classe de defeito e some junto se o trabalho for feito direito.
  final int dynFora = somaDe(contaPorArquivo('lib/src/model', 'as dynamic')) +
      somaDe(contaPorArquivo('lib/src/layout', 'as dynamic'));
  final int catFora = somaDe(contaPorArquivo('lib/src/model', 'catch (_)')) +
      somaDe(contaPorArquivo('lib/src/layout', 'catch (_)'));
  info(f, '5.4', 'mesma dívida em model/ + layout/',
      detalhe: '$dynFora `as dynamic`, $catFora `catch (_)`');

  // 5.5 — o guarda contra bridges no harness (o episódio da 05-26).
  checa(f, '5.5', 'test/harness_integrity_test.dart existe',
      File('test/harness_integrity_test.dart').existsSync(),
      detalhe: 'guarda contra o harness devolver os próprios goldens');

  // 5.6 — o número que fecha a fase.
  _leRelatorio(
    fase: f,
    id: '5.6',
    caminho: 'tool/SVG_VALIDATION.md',
    rotulo: 'compare_svg',
    comando: 'dart run tool/compare_svg.dart --all',
    extrai: (txt) {
      final e = RegExp(r'Estrutural:\s*(\d+)/(\d+)').firstMatch(txt);
      final n = RegExp(r'Numérico[^:]*:\s*(\d+)/(\d+)').firstMatch(txt);
      final x = RegExp(r'Falhas \(exceção[^)]*\):\s*(\d+)').firstMatch(txt);
      if (e == null || n == null) return null;
      final int est = int.parse(e.group(1)!);
      final int total = int.parse(e.group(2)!);
      final int num = int.parse(n.group(1)!);
      final int exc = x == null ? -1 : int.parse(x.group(1)!);
      // 2 arquivos do corpus são não-UTF-8 por decisão e ficam fora.
      const int pulados = 2;
      final int alvo = total - pulados;
      final bool passou = est >= alvo && num >= alvo && exc == 0;
      return (
        passou,
        'estrutural $est/$total, numérico $num/$total, $exc exceções '
            '(alvo: $alvo/$total nos dois, 0 exceções)'
      );
    },
  );
}

String _top(List<MapEntry<String, int>> xs) =>
    xs.take(3).map((e) => '${e.key.split('/').last} ${e.value}').join(', ');

/// Lê um critério de um relatório gerado por ferramenta, **reprovando se o
/// relatório for mais velho que o código de `lib/`** — um número obsoleto não
/// pode passar por medição.
void _leRelatorio({
  required int fase,
  required String id,
  required String caminho,
  required String rotulo,
  required String comando,
  required (bool, String)? Function(String) extrai,
}) {
  final File rel = File(caminho);
  if (!rel.existsSync()) {
    falha(fase, id, '$rotulo: relatório ausente', detalhe: 'rode `$comando`');
    return;
  }
  if (rel.lastModifiedSync().isBefore(ultimaMudancaEmLib())) {
    falha(fase, id, '$rotulo: relatório mais velho que lib/ — obsoleto',
        detalhe: 'rode `$comando` de novo antes de confiar no número');
    return;
  }
  final (bool, String)? r = extrai(rel.readAsStringSync());
  if (r == null) {
    falha(fase, id, '$rotulo: não consegui ler o número do relatório',
        detalhe: 'formato de $caminho mudou?');
    return;
  }
  checa(fase, id, rotulo, r.$1, detalhe: r.$2);
}

// ---------------------------------------------------------------------------
// Critérios transversais (rodam com --full)
// ---------------------------------------------------------------------------

void verificaTransversais({required bool full}) {
  const int f = 0;

  final (int codigo, String saida) =
      roda('dart', ['analyze', '--no-fatal-warnings']);
  final RegExpMatch? m = RegExp(r'(\d+) issues? found').firstMatch(saida);
  final int issues =
      m == null ? (codigo == 0 ? 0 : -1) : int.parse(m.group(1)!);
  checa(f, '0.1', 'dart analyze ≤ baseline ($kAnalyzeBaseline)',
      issues >= 0 && issues <= kAnalyzeBaseline,
      detalhe: '$issues issues');

  if (!full) {
    info(f, '0.2', 'dart test — não rodado (use --full)');
    return;
  }

  stderr.writeln('  … rodando dart test (pode levar ~7 min)');
  final (int codTest, String saidaTest) = roda('dart', ['test']);
  final RegExpMatch? mt =
      RegExp(r'\+(\d+)(?:\s+-(\d+))?').allMatches(saidaTest).lastOrNull;
  final String contagem = mt == null
      ? 'não consegui ler a contagem'
      : '${mt.group(1)} passaram, ${mt.group(2) ?? "0"} falharam';
  checa(f, '0.2', 'dart test verde', codTest == 0, detalhe: contagem);
}

// ---------------------------------------------------------------------------
// Relatório
// ---------------------------------------------------------------------------

const Map<int, String> kNomeFase = {
  0: 'Transversal',
  1: 'Fase 1 — Fundações',
  2: 'Fase 2 — Modelo de dados MEI',
  3: 'Fase 3 — Leitura de arquivos',
  4: 'Fase 4 — Motor de layout',
  5: 'Fase 5 — Renderização SVG',
};

int imprime({required bool verbose}) {
  final Set<int> fases =
      resultados.map((r) => r.fase).toSet().toList().reversed.toSet();
  final List<int> ordenadas = fases.toList()..sort();

  int falhasTotais = 0;
  for (final int fase in ordenadas) {
    final List<Criterio> doGrupo =
        resultados.where((r) => r.fase == fase).toList();
    final int nFalhas = doGrupo.where((r) => r.nivel == Nivel.fail).length;
    falhasTotais += nFalhas;

    final String veredito = nFalhas == 0 ? 'PASS' : 'FAIL ($nFalhas)';
    stdout.writeln('\n${kNomeFase[fase]} — $veredito');
    stdout.writeln('-' * 66);
    for (final Criterio c in doGrupo) {
      if (!verbose && c.nivel == Nivel.pass) continue;
      final String marca = switch (c.nivel) {
        Nivel.pass => ' ok ',
        Nivel.fail => 'FALHA',
        Nivel.info => 'info',
      };
      stdout.writeln('  [$marca] ${c.id}  ${c.titulo}');
      if (c.detalhe.isNotEmpty) stdout.writeln('           ${c.detalhe}');
    }
    if (!verbose && nFalhas == 0) {
      final int n = doGrupo.where((r) => r.nivel == Nivel.pass).length;
      stdout.writeln('  $n critério(s) passaram (use --verbose para listar)');
    }
  }

  stdout.writeln('\n${'=' * 66}');
  if (falhasTotais == 0) {
    stdout.writeln('VEREDITO: todas as fases verificadas passaram.');
  } else {
    stdout.writeln('VEREDITO: $falhasTotais critério(s) reprovado(s). '
        'As fases acima marcadas FAIL não terminaram.');
  }
  stdout.writeln('=' * 66);
  return falhasTotais == 0 ? 0 : 1;
}

// ---------------------------------------------------------------------------

void main(List<String> args) {
  final bool full = args.contains('--full');
  final bool verbose = args.contains('--verbose');
  final RegExpMatch? faseArg = args
      .map((a) => RegExp(r'^--fase=(\d)$').firstMatch(a))
      .nonNulls
      .firstOrNull;
  final int? apenas = faseArg == null ? null : int.parse(faseArg.group(1)!);

  if (!File('pubspec.yaml').existsSync()) {
    stderr.writeln('Rode a partir de verovio_dart/.');
    exit(2);
  }

  if (full) {
    stderr.writeln('Modo --full: regerando as medições caras primeiro.');
    stderr.writeln('  … rodando compare_svg --all (pode levar ~10 min)');
    roda('dart', ['run', 'tool/compare_svg.dart', '--all']);
    stderr.writeln('  … rodando validate_layout');
    roda('dart', ['run', 'tool/validate_layout.dart']);
  }

  if (apenas == null) verificaTransversais(full: full);
  if (apenas == null || apenas == 1) verificaFase1();
  if (apenas == null || apenas == 2) verificaFase2();
  if (apenas == null || apenas == 3) verificaFase3();
  if (apenas == null || apenas == 4) verificaFase4();
  if (apenas == null || apenas == 5) verificaFase5();

  exit(imprime(verbose: verbose));
}
