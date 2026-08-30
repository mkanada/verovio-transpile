/// Medidor da dívida de tipagem da Fase 5 (critérios 5.1, 5.2 e 5.3 do portão).
///
/// Responde, mecanicamente: quanto `as dynamic`, `catch (_)` e
/// `ignore_for_file` ainda existe em `lib/src/rendering/`, **e em qual método**
/// — que é o recorte que a fatia de trabalho precisa para caber num prompt
/// pequeno.
///
/// Este arquivo é código de apoio do port, não port de nenhum arquivo C++.
///
/// Uso (a partir de `verovio_dart/`):
/// ```
/// dart run tool/debt_report.dart                  # tabela por arquivo
/// dart run tool/debt_report.dart --by-method      # tabela por método
/// dart run tool/debt_report.dart --file=view_control.dart --by-method
/// dart run tool/debt_report.dart --json           # para o Sonnet fatiar
/// dart run tool/debt_report.dart --baseline=<f>   # falha se piorou vs <f>
/// ```
///
/// Sai com código 0 só quando a dívida é zero (ou, com `--baseline`, quando
/// não piorou em nenhum arquivo).
library;

import 'dart:convert';
import 'dart:io';

const String kRenderingDir = 'lib/src/rendering';

/// Os três padrões que os critérios 5.1/5.2/5.3 contam.
const Map<String, String> kPatterns = {
  'dynamic': 'as dynamic',
  'catch': 'catch (_)',
  'ignore': 'ignore_for_file',
};

class MethodDebt {
  MethodDebt(this.file, this.method, this.line);
  final String file;
  final String method;
  final int line;
  int dynamicCount = 0;
  int catchCount = 0;
  int get total => dynamicCount + catchCount;

  Map<String, dynamic> toJson() => {
        'file': file,
        'method': method,
        'line': line,
        'dynamic': dynamicCount,
        'catch': catchCount,
        'total': total,
      };
}

class FileDebt {
  FileDebt(this.path);
  final String path;
  String get name => path.split('/').last;
  int dynamicCount = 0;
  int catchCount = 0;
  int ignoreCount = 0;
  int lines = 0;
  final List<MethodDebt> methods = [];

  int get total => dynamicCount + catchCount + ignoreCount;

  Map<String, dynamic> toJson() => {
        'file': name,
        'path': path,
        'lines': lines,
        'dynamic': dynamicCount,
        'catch': catchCount,
        'ignore': ignoreCount,
        'total': total,
        'methods': methods
            .where((m) => m.total > 0)
            .map((m) => m.toJson())
            .toList(),
      };
}

/// Reconhece a assinatura de um membro no corpo de uma `extension`/`class`:
/// dois espaços de indentação, um identificador, e um parêntese de parâmetros
/// na mesma linha. É heurística deliberada — serve para rotular a fatia, não
/// para analisar Dart.
/// `^  (?=\S)` — exatamente dois espaços seguidos de não-espaço. A âncora
/// estrita é o que separa a declaração de um membro (indentação 2 dentro de
/// `class`/`extension`) de uma chamada no corpo de um método (indentação 4+):
/// sem ela, `dc.startText(toDeviceContextY(...))` numa linha indentada era
/// contada como declaração de `toDeviceContextY`.
final RegExp _methodSignature = RegExp(
    r'^  (?=\S)(?:static\s+)?(?:[\w<>,\?\s\.\(\)]+?\s+)?([_a-zA-Z][\w]*)\s*\(');

/// Linhas que parecem assinatura mas não são (continuação de argumentos,
/// chamada encadeada, comentário).
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
      final Match? sig = _methodSignature.firstMatch(line);
      if (sig != null && !_looksLikeCall(line)) {
        current = MethodDebt(name, sig.group(1)!, i + 1);
        fd.methods.add(current);
      }
      final int dyn = kPatterns['dynamic']!.allMatches(line).length;
      final int cat = kPatterns['catch']!.allMatches(line).length;
      final int ign = kPatterns['ignore']!.allMatches(line).length;
      fd.dynamicCount += dyn;
      fd.catchCount += cat;
      fd.ignoreCount += ign;
      current.dynamicCount += dyn;
      current.catchCount += cat;
    }
    out.add(fd);
  }
  return out;
}

void main(List<String> args) {
  String? onlyFile;
  String? baselinePath;
  bool byMethod = false;
  bool asJson = false;
  bool writeBaseline = false;

  for (final String a in args) {
    if (a == '--by-method') {
      byMethod = true;
    } else if (a == '--json') {
      asJson = true;
    } else if (a.startsWith('--file=')) {
      onlyFile = a.substring('--file='.length);
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
  final int totalDyn = debts.fold(0, (a, d) => a + d.dynamicCount);
  final int totalCatch = debts.fold(0, (a, d) => a + d.catchCount);
  final int totalIgnore = debts.fold(0, (a, d) => a + d.ignoreCount);

  final Map<String, dynamic> payload = {
    'totals': {
      'dynamic': totalDyn,
      'catch': totalCatch,
      'ignore': totalIgnore,
    },
    'files': {for (final d in debts) d.name: d.toJson()},
  };

  if (writeBaseline) {
    File(baselinePath!)
        .writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(payload)}\n');
    stdout.writeln('baseline gravada em $baselinePath '
        '(dynamic=$totalDyn catch=$totalCatch ignore=$totalIgnore)');
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
    stdout.writeln('| arquivo | método | linha | dynamic | catch | total |');
    stdout.writeln('|---|---|---|---|---|---|');
    for (final MethodDebt m in all) {
      stdout.writeln('| ${m.file} | ${m.method} | ${m.line} | '
          '${m.dynamicCount} | ${m.catchCount} | ${m.total} |');
    }
    stdout.writeln('');
    stdout.writeln('${all.length} método(s) com dívida.');
  } else {
    stdout.writeln('| arquivo | linhas | as dynamic | catch (_) | '
        'ignore_for_file |');
    stdout.writeln('|---|---|---|---|---|');
    for (final FileDebt d in debts) {
      if (d.total == 0) continue;
      stdout.writeln('| ${d.name} | ${d.lines} | ${d.dynamicCount} | '
          '${d.catchCount} | ${d.ignoreCount} |');
    }
  }

  if (!asJson) {
    stdout.writeln('');
    stdout.writeln('TOTAIS  5.1 as dynamic: $totalDyn   '
        '5.2 catch (_): $totalCatch   5.3 ignore_for_file: $totalIgnore');
  }

  // Comparação com a baseline: reprova se QUALQUER arquivo piorou.
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
        ('dynamic', d.dynamicCount),
        ('catch', d.catchCount),
        ('ignore', d.ignoreCount),
      ]) {
        final int was = b[key] as int;
        if (now > was) {
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

  exit(totalDyn + totalCatch + totalIgnore == 0 ? 0 : 1);
}
