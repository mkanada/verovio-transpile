/// Medidor da dívida de tipagem de `lib/src/rendering/` (loop de tipagem).
///
/// A dívida foi "paga" uma vez no papel (2026-08-29: 739 `as dynamic` e 820
/// `catch (_)` viraram 0 e 1) mas só trocou de grafia: `as dynamic` virou
/// `_dyn(objeto).membro` (o helper `dynamic _dyn(dynamic o) => o;` declarado
/// em `view_control.dart`, `view_element.dart` e `view_mensural.dart`) e
/// `catch (_)` virou `catch (e) { e.toString(); }`. Este medidor conta a
/// grafia ATUAL, não a antiga — ver `prompts/loop-tipagem-diario.md` (entrada
/// de abertura, 2026-09-05) para o censo por grep que este arquivo substitui
/// por análise mecânica (brace-matching real em vez de regex por linha para
/// os corpos de `catch`).
///
/// Três categorias, somadas em `D`:
///
///   A — Lavagem de tipo: chamadas `_dyn(...)` (excluindo as 3 linhas de
///       declaração do próprio helper) + `as dynamic` + declarações locais/
///       parâmetros `dynamic x` (idem, excluindo a declaração do helper).
///   B — Engolidores silenciosos: todo `catch` cujo corpo (com brace-matching
///       real, não regex de uma linha — corpos multilinha e catches
///       aninhados existem, ex. `view_element.dart:626-632`) não contém
///       `rethrow` nem uma chamada de log reconhecível.
///   C — Supressões de erro de tipo: `// ignore: regra` / `// ignore_for_file:
///       regra` cuja(s) regra(s) NÃO estejam na lista de exclusão deliberada
///       (`dead_code`, `unused*`) documentada em `view_mensural.dart:24` e
///       `view_control.dart:392`. Essas 8 ocorrências ficam de fora de propósito
///       — não suprimem erro de tipo, suprimem lint de código morto/não usado.
///
/// Este arquivo é código de apoio do port, não port de nenhum arquivo C++.
///
/// Uso (a partir de `verovio_dart/`):
/// ```
/// dart run tool/debt_report.dart                  # tabela por arquivo + grava TYPE_DEBT.md
/// dart run tool/debt_report.dart --by-method       # tabela por método (não grava o .md)
/// dart run tool/debt_report.dart --file=view_control.dart --by-method
/// dart run tool/debt_report.dart --json            # para o Sonnet fatiar (não grava o .md)
/// dart run tool/debt_report.dart --baseline=<f>    # falha se piorou vs <f>
/// dart run tool/debt_report.dart --write-baseline=<f>
/// dart run tool/debt_report.dart --report=<path>   # caminho alternativo do .md (default abaixo)
/// dart run tool/debt_report.dart --no-report       # não grava o .md (para uso em pipe/CI)
/// ```
///
/// Sai com código 0 só quando a dívida é zero (ou, com `--baseline`, quando
/// não piorou em nenhum arquivo).
library;

import 'dart:convert';
import 'dart:io';

const String kRenderingDir = 'lib/src/rendering';
const String kDefaultReportPath = 'tool/TYPE_DEBT.md';

/// A linha exata do helper de lavagem — declarada uma vez por arquivo, nunca
/// conta como ponto de dívida (ela É a definição do padrão, não um uso dele).
bool _isHelperDeclLine(String trimmed) =>
    trimmed == 'dynamic _dyn(dynamic o) => o;';

/// Regras de `// ignore:` deliberadamente fora de escopo (código morto/não
/// usado, documentado em `view_mensural.dart:24` e `view_control.dart:392`),
/// nunca supressão de erro de tipo.
const Set<String> kIgnoreAllowlist = {
  'dead_code',
  'unused_field',
  'unused',
  'unused_element',
  'unused_local_variable',
  'unused_import',
  'unused_shown_name',
};

/// Chamadas reconhecidas como "logar antes de engolir" — nenhuma existe hoje
/// em `rendering/` (censo 2026-09-05: 0 catches com rethrow ou log), mas o
/// detector precisa reconhecê-las para não recontar como dívida um catch que
/// uma rodada futura corrigir para logar em vez de portar o membro.
final RegExp _logCall = RegExp(
    r'\b(print|debugPrint|stderr\s*\.\s*write\w*|stdout\s*\.\s*write\w*|'
    r'log|logger|logError|logWarning|Logger)\s*\(');
final RegExp _rethrow = RegExp(r'\brethrow\b');

/// Ver `debt_report.dart` (medidor de `as dynamic`/`catch (_)` original) para
/// a explicação da heurística de assinatura de método — reaproveitada aqui.
final RegExp _methodSignature = RegExp(
    r'^  (?=\S)(?:static\s+)?(?:[\w<>,\?\s\.\(\)]+?\s+)?([_a-zA-Z][\w]*)\s*\(');

bool _looksLikeCall(String line) {
  final String t = line.trimLeft();
  return t.startsWith('//') ||
      t.startsWith('return ') ||
      t.startsWith('assert(') ||
      t.startsWith('super.') ||
      t.startsWith('this.') ||
      t.startsWith('final ') ||
      t.startsWith('const ') ||
      t.startsWith('var ') ||
      t.startsWith('if ') ||
      t.startsWith('for ') ||
      t.startsWith('while ') ||
      t.startsWith('switch ') ||
      t.startsWith('} ') ||
      t.startsWith('}');
}

class MethodDebt {
  MethodDebt(this.file, this.method, this.line);
  final String file;
  final String method;
  final int line;

  // A
  int dynCalls = 0;
  int asDynamic = 0;
  int dynamicDecl = 0;
  int get a => dynCalls + asDynamic + dynamicDecl;

  // B
  int catchTotal = 0;
  int catchSilent = 0;
  int get b => catchSilent;

  // C
  int suppressions = 0;
  int get c => suppressions;

  int get total => a + b + c;

  Map<String, dynamic> toJson() => {
        'file': file,
        'method': method,
        'line': line,
        'A': a,
        'dynCalls': dynCalls,
        'asDynamic': asDynamic,
        'dynamicDecl': dynamicDecl,
        'B': b,
        'catchTotal': catchTotal,
        'catchSilent': catchSilent,
        'C': c,
        'total': total,
      };
}

class CatchSite {
  CatchSite(this.file, this.line, this.silent);
  final String file;
  final int line;
  final bool silent;
}

class FileDebt {
  FileDebt(this.path);
  final String path;
  String get name => path.split('/').last;
  int lines = 0;

  int dynCalls = 0;
  int asDynamic = 0;
  int dynamicDecl = 0;
  int get a => dynCalls + asDynamic + dynamicDecl;

  int catchTotal = 0;
  int catchSilent = 0;
  int get b => catchSilent;

  int suppressions = 0;
  int get c => suppressions;

  int get total => a + b + c;

  final List<MethodDebt> methods = [];
  final List<CatchSite> catchSites = [];

  Map<String, dynamic> toJson() => {
        'file': name,
        'path': path,
        'lines': lines,
        'A': a,
        'dynCalls': dynCalls,
        'asDynamic': asDynamic,
        'dynamicDecl': dynamicDecl,
        'B': b,
        'catchTotal': catchTotal,
        'catchSilent': catchSilent,
        'C': c,
        'total': total,
        'methods':
            methods.where((m) => m.total > 0).map((m) => m.toJson()).toList(),
      };
}

/// Varre o corpo de um `catch` a partir do `{` de abertura (posição
/// `(startLine, openCol)`, onde `lines[startLine][openCol] == '{'`) com
/// brace-matching real — não regex de uma linha — porque corpos multilinha e
/// `catch` aninhados dentro de `catch` existem de fato (ex.
/// `view_element.dart:626-632`, um `catch` cujo corpo tem um `try`/`catch`
/// próprio). Retorna o texto do corpo e a linha onde o `}` de fechamento
/// ocorre. Heurística deliberada (não ignora `{`/`}` dentro de strings ou
/// comentários), na mesma linha do resto deste arquivo — o código-fonte real
/// não usa chaves literais em string dentro de corpo de catch.
({String body, int endLine}) _scanCatchBody(
    List<String> lines, int startLine, int openCol) {
  final StringBuffer body = StringBuffer();
  int depth = 1;
  int curLine = startLine;
  int curCol = openCol + 1;
  while (curLine < lines.length) {
    final String text = lines[curLine];
    while (curCol < text.length) {
      final String ch = text[curCol];
      if (ch == '{') {
        depth++;
      } else if (ch == '}') {
        depth--;
        if (depth == 0) {
          return (body: body.toString(), endLine: curLine);
        }
      }
      body.write(ch);
      curCol++;
    }
    body.write('\n');
    curLine++;
    curCol = 0;
  }
  // Malformado (chave sem par) — não deveria acontecer em código que compila;
  // devolve o que foi acumulado para não travar o medidor.
  return (body: body.toString(), endLine: lines.length - 1);
}

List<FileDebt> measure({String? onlyFile}) {
  final Directory dir = Directory(kRenderingDir);
  if (!dir.existsSync()) {
    stderr.writeln('ERRO: $kRenderingDir não existe — rode a partir de '
        'verovio_dart/.');
    exit(2);
  }
  final List<File> files = dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  final List<FileDebt> out = [];
  for (final File f in files) {
    final String name = f.path.split('/').last;
    if (onlyFile != null && name != onlyFile) continue;
    final FileDebt fd = FileDebt(f.path);
    final List<String> src = f.readAsLinesSync();
    fd.lines = src.length;
    MethodDebt current = MethodDebt(name, '<file scope>', 1);
    fd.methods.add(current);

    for (int i = 0; i < src.length; i++) {
      final String line = src[i];
      final String trimmed = line.trim();

      final Match? sig = _methodSignature.firstMatch(line);
      if (sig != null && !_looksLikeCall(line)) {
        current = MethodDebt(name, sig.group(1)!, i + 1);
        fd.methods.add(current);
      }

      final bool helperLine = _isHelperDeclLine(trimmed);

      // A.1 — chamadas _dyn(...), excluindo a própria declaração do helper.
      if (!helperLine) {
        final int dyn = '_dyn('.allMatches(line).length;
        fd.dynCalls += dyn;
        current.dynCalls += dyn;
      }

      // A.2 — as dynamic.
      final int asDyn = 'as dynamic'.allMatches(line).length;
      fd.asDynamic += asDyn;
      current.asDynamic += asDyn;

      // A.3 — declarações/parâmetros `dynamic x`, excluindo o helper.
      if (!helperLine) {
        final int decl =
            RegExp(r'dynamic [a-zA-Z_][a-zA-Z0-9_]*').allMatches(line).length;
        fd.dynamicDecl += decl;
        current.dynamicDecl += decl;
      }

      // B — catch: brace-matching real a partir de cada ocorrência de
      // "catch (" na linha (quase sempre uma; o loop suporta mais de uma).
      int searchFrom = 0;
      while (true) {
        final int idx = line.indexOf('catch (', searchFrom);
        if (idx == -1) break;
        final int braceIdx = line.indexOf('{', idx);
        if (braceIdx == -1) {
          // Não deveria acontecer (censo 2026-09-05: toda ocorrência de
          // "catch (" no diretório tem o "{" de abertura na mesma linha).
          searchFrom = idx + 7;
          continue;
        }
        final ({String body, int endLine}) scan =
            _scanCatchBody(src, i, braceIdx);
        final bool silent =
            !_rethrow.hasMatch(scan.body) && !_logCall.hasMatch(scan.body);
        fd.catchTotal++;
        current.catchTotal++;
        if (silent) {
          fd.catchSilent++;
          current.catchSilent++;
        }
        fd.catchSites.add(CatchSite(fd.path, i + 1, silent));
        searchFrom = idx + 7;
      }

      // C — supressões de erro de tipo: `// ignore: regra[, regra...]` ou
      // `// ignore_for_file: regra[, regra...]`, exceto a allowlist de
      // dead_code/unused* documentada (view_mensural.dart:24,
      // view_control.dart:392).
      final Match? ign =
          RegExp(r'^//\s*ignore(_for_file)?:\s*(.+)$').firstMatch(trimmed);
      if (ign != null) {
        final List<String> rules =
            ign.group(2)!.split(',').map((r) => r.trim()).toList();
        final bool allSuppressed =
            rules.every((r) => kIgnoreAllowlist.contains(r));
        if (!allSuppressed) {
          fd.suppressions++;
          current.suppressions++;
        }
      }
    }
    out.add(fd);
  }
  return out;
}

String _renderMarkdown(List<FileDebt> debts) {
  final int totalDynCalls = debts.fold(0, (a, d) => a + d.dynCalls);
  final int totalAsDynamic = debts.fold(0, (a, d) => a + d.asDynamic);
  final int totalDynamicDecl = debts.fold(0, (a, d) => a + d.dynamicDecl);
  final int totalA = totalDynCalls + totalAsDynamic + totalDynamicDecl;

  final int totalCatch = debts.fold(0, (a, d) => a + d.catchTotal);
  final int totalCatchSilent = debts.fold(0, (a, d) => a + d.catchSilent);
  final int totalB = totalCatchSilent;

  final int totalC = debts.fold(0, (a, d) => a + d.suppressions);

  final int totalD = totalA + totalB + totalC;

  final StringBuffer out = StringBuffer();
  out.writeln('# TYPE_DEBT — dívida de tipagem de `lib/src/rendering/` '
      '(loop de tipagem)');
  out.writeln();
  out.writeln('Lavagem de tipo (_dyn + as dynamic + declarações dynamic): '
      '$totalA');
  out.writeln('Engolidores silenciosos (catch sem rethrow nem log): '
      '$totalB');
  out.writeln('Supressões de erro de tipo: $totalC');
  out.writeln('Dívida total (D = A + B + C): $totalD');
  out.writeln();
  out.writeln('Gerado em ${DateTime.now().toIso8601String().split('T')[0]} '
      'por `dart run tool/debt_report.dart`.');
  out.writeln();
  out.writeln('- A.1 chamadas `_dyn(...)` (exclui as 3 linhas de declaração '
      'do helper): $totalDynCalls');
  out.writeln('- A.2 `as dynamic`: $totalAsDynamic');
  out.writeln('- A.3 declarações/parâmetros `dynamic x` (exclui o helper): '
      '$totalDynamicDecl');
  out.writeln('- B.1 total de `catch` no diretório: $totalCatch');
  out.writeln('- B.2 dos quais sem `rethrow` nem log (contam para B): '
      '$totalCatchSilent');
  out.writeln('- C — supressões de erro de tipo fora da allowlist '
      '(`dead_code`/`unused*`, ver `view_mensural.dart:24` e '
      '`view_control.dart:392`): $totalC');
  out.writeln();
  out.writeln('## Por arquivo');
  out.writeln();
  out.writeln('| arquivo | linhas | A (_dyn/as dynamic/dynamic decl) | '
      'B (catch silencioso / total) | C | D |');
  out.writeln('|---|---|---|---|---|---|');
  for (final FileDebt d in debts) {
    out.writeln('| ${d.name} | ${d.lines} | ${d.a} '
        '(${d.dynCalls}/${d.asDynamic}/${d.dynamicDecl}) | '
        '${d.b} / ${d.catchTotal} | ${d.c} | ${d.total} |');
  }
  out.writeln();
  out.writeln('Escopo: apenas `$kRenderingDir/`. Fora de escopo (não '
      'contados aqui, ver `prompts/loop-tipagem-prompt-supervisor.md`): os '
      '3 `as dynamic` de `model/` (`comparison.dart:319`, '
      '`interfaces/simple_interfaces.dart:160`, `doc.dart:1823`), o '
      '`catch (_)` de `testing/svg_compare.dart:114`, e os `// ignore:` de '
      'código morto/não usado (allowlist acima).');
  return out.toString();
}

void main(List<String> args) {
  String? onlyFile;
  String? baselinePath;
  bool byMethod = false;
  bool asJson = false;
  bool writeBaseline = false;
  String reportPath = kDefaultReportPath;
  bool writeReport = true;

  for (final String a in args) {
    if (a == '--by-method') {
      byMethod = true;
    } else if (a == '--json') {
      asJson = true;
    } else if (a == '--no-report') {
      writeReport = false;
    } else if (a.startsWith('--file=')) {
      onlyFile = a.substring('--file='.length);
    } else if (a.startsWith('--report=')) {
      reportPath = a.substring('--report='.length);
    } else if (a.startsWith('--baseline=')) {
      baselinePath = a.substring('--baseline='.length);
    } else if (a.startsWith('--write-baseline=')) {
      baselinePath = a.substring('--write-baseline='.length);
      writeBaseline = true;
    } else {
      stderr.writeln('Argumento desconhecido: $a');
      exit(2);
    }
  }

  final List<FileDebt> debts = measure(onlyFile: onlyFile);

  final int totalDynCalls = debts.fold(0, (a, d) => a + d.dynCalls);
  final int totalAsDynamic = debts.fold(0, (a, d) => a + d.asDynamic);
  final int totalDynamicDecl = debts.fold(0, (a, d) => a + d.dynamicDecl);
  final int totalA = totalDynCalls + totalAsDynamic + totalDynamicDecl;
  final int totalCatch = debts.fold(0, (a, d) => a + d.catchTotal);
  final int totalCatchSilent = debts.fold(0, (a, d) => a + d.catchSilent);
  final int totalB = totalCatchSilent;
  final int totalC = debts.fold(0, (a, d) => a + d.suppressions);
  final int totalD = totalA + totalB + totalC;

  final Map<String, dynamic> payload = {
    'totals': {
      'A': totalA,
      'dynCalls': totalDynCalls,
      'asDynamic': totalAsDynamic,
      'dynamicDecl': totalDynamicDecl,
      'B': totalB,
      'catchTotal': totalCatch,
      'catchSilent': totalCatchSilent,
      'C': totalC,
      'D': totalD,
    },
    'files': {for (final d in debts) d.name: d.toJson()},
  };

  if (writeBaseline) {
    File(baselinePath!).writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(payload)}\n');
    stdout.writeln('baseline gravada em $baselinePath '
        '(A=$totalA B=$totalB C=$totalC D=$totalD)');
    exit(0);
  }

  if (asJson) {
    stdout.writeln(const JsonEncoder.withIndent('  ').convert(payload));
  } else if (byMethod) {
    stdout.writeln('Dívida por método (só métodos com dívida > 0), '
        'maior primeiro:');
    stdout.writeln('');
    final List<MethodDebt> all = [
      for (final d in debts) ...d.methods.where((m) => m.total > 0)
    ]..sort((a, b) => b.total.compareTo(a.total));
    stdout.writeln('| arquivo | método | linha | A | B (silent/total) | C | '
        'total |');
    stdout.writeln('|---|---|---|---|---|---|---|');
    for (final MethodDebt m in all) {
      stdout.writeln('| ${m.file} | ${m.method} | ${m.line} | ${m.a} | '
          '${m.b}/${m.catchTotal} | ${m.c} | ${m.total} |');
    }
    stdout.writeln('');
    stdout.writeln('${all.length} método(s) com dívida.');
  } else {
    stdout.writeln('| arquivo | linhas | A (_dyn/as dynamic/dyn decl) | '
        'B (silent/total) | C | D |');
    stdout.writeln('|---|---|---|---|---|---|');
    for (final FileDebt d in debts) {
      if (d.total == 0) continue;
      stdout.writeln('| ${d.name} | ${d.lines} | '
          '${d.a} (${d.dynCalls}/${d.asDynamic}/${d.dynamicDecl}) | '
          '${d.b}/${d.catchTotal} | ${d.c} | ${d.total} |');
    }
  }

  if (!asJson) {
    stdout.writeln('');
    stdout.writeln('TOTAIS  A (lavagem de tipo): $totalA   '
        'B (engolidores silenciosos): $totalB   '
        'C (supressões de tipo): $totalC   D (total): $totalD');
  }

  // Comparação com a baseline: reprova se QUALQUER arquivo piorou em A, B, C
  // ou D.
  if (baselinePath != null) {
    final File bf = File(baselinePath);
    if (!bf.existsSync()) {
      stderr.writeln('ERRO: baseline $baselinePath não existe. '
          'Gere com --write-baseline=$baselinePath');
      exit(2);
    }
    final Map<String, dynamic> base =
        jsonDecode(bf.readAsStringSync()) as Map<String, dynamic>;
    final Map<String, dynamic> baseFiles =
        base['files'] as Map<String, dynamic>;
    final List<String> pioras = [];
    for (final FileDebt d in debts) {
      final Map<String, dynamic>? b =
          baseFiles[d.name] as Map<String, dynamic>?;
      if (b == null) continue;
      for (final (String key, int now) in [
        ('A', d.a),
        ('B', d.b),
        ('C', d.c),
        ('total', d.total),
      ]) {
        final int? was = b[key] as int?;
        if (was != null && now > was) {
          pioras.add('${d.name}: $key $was -> $now');
        }
      }
    }
    if (pioras.isNotEmpty) {
      stderr.writeln('');
      stderr.writeln('REPROVADO — a dívida aumentou:');
      for (final String p in pioras) {
        stderr.writeln('  $p');
      }
      exit(1);
    }
    stdout.writeln('Sem piora em relação à baseline $baselinePath.');
  }

  if (writeReport && onlyFile == null) {
    File(reportPath).writeAsStringSync(_renderMarkdown(debts));
    stdout.writeln('');
    stdout.writeln('Relatório gravado em $reportPath');
  }

  exit(totalD == 0 ? 0 : 1);
}
