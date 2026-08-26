/// Port of `iomusxml.h/cpp` (`MusicXmlInput`) — the MusicXML reader.
///
/// The C++ reader walks a pugixml document; this port parses the input once
/// into the mutable [MeiXmlNode] tree (`xml_node.dart`) and walks it with a
/// small XPath-subset engine that reproduces every query used by the
/// original (absolute paths, child/ancestor/sibling/following axes,
/// attribute/text/position predicates, unions and `.//` descendants).
///
/// The reader supports `<score-partwise>` documents (the dominant MusicXML
/// flavour; the 6.x C++ reader no longer supports `<score-timewise>`).
library;

import 'dart:math' as math;
import 'dart:collection' show SplayTreeMap;

import 'package:verovio_dart/src/core/attdef.dart'
    show MeiDuration, MeterCountSign;
import 'package:verovio_dart/src/core/fraction.dart';
import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/io/iobase.dart';
import 'package:verovio_dart/src/io/xml_node.dart';
import 'package:verovio_dart/src/model/atts/atts_conversion.dart';
import 'package:verovio_dart/src/model/atts/mei_enums.dart' hide Tie;
import 'package:verovio_dart/src/model/atts/mei_values.dart'
    show
        HeadShape,
        MeasureBeat,
        MeterCountPair,
        MeasurementSigned,
        strToDuration,
        strToInt,
        strToHexnum,
        strToKeysignature,
        strToMetercountPair,
        strToPercent;
import 'package:verovio_dart/src/model/basic_elements.dart';
import 'package:verovio_dart/src/model/doc.dart' show DocType;
import 'package:verovio_dart/src/model/comparison.dart';
import 'package:verovio_dart/src/model/control_element.dart';
import 'package:verovio_dart/src/model/control_elements_gen.dart';
import 'package:verovio_dart/src/model/custom_tuning.dart' show CustomTuning;
import 'package:verovio_dart/src/model/interfaces/pitch_interface.dart';
import 'package:verovio_dart/src/model/layer_element.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart';
import 'package:verovio_dart/src/model/misc_elements_gen.dart';
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/model/scoredef.dart';

/// Using flags mordent can be easily visualized with the value. E.g.
/// 0x212 - approach and depart are both below and form is normal
/// APPR_Below | FORM_Normal | DEP_Below (mirrors `MordentExtSymbolFlags`).
class _MordentExtSymbolFlags {
  static const int apprAbove = 0x100;
  static const int apprBelow = 0x200;
  static const int formNormal = 0x10;
  static const int formInverted = 0x20;
  static const int depAbove = 0x1;
  static const int depBelow = 0x2;
}

enum _MetronomeElements { beatUnit, beatUnitDot, perMinute, separator }

/// Mirrors `musicxml::OpenSlur`.
class _OpenSlur {
  _OpenSlur(this.measureNum, this.number, this.curvedir);

  final String measureNum;
  final int number;
  final CurvatureCurvedir curvedir;
}

/// Mirrors `musicxml::CloseSlur`.
class _CloseSlur {
  _CloseSlur(this.measureNum, this.number, this.curvedir);

  final String measureNum;
  final int number;
  final CurvatureCurvedir curvedir;
}

/// Mirrors `musicxml::OpenSpanner`.
class _OpenSpanner {
  _OpenSpanner(this.dirN, this.lastMeasureCount);

  final int dirN;
  final int lastMeasureCount;
}

/// Mirrors `musicxml::OpenArpeggio`.
class _OpenArpeggio {
  _OpenArpeggio(this.arpegN, this.timeStamp);

  final int arpegN;
  final Fraction timeStamp;
}

/// Mirrors `musicxml::EndingInfo`.
class _EndingInfo {
  String number = '';
  String type = '';
  String text = '';
}

/// Mirrors `musicxml::RepeatInfo`.
class _RepeatInfo {
  _RepeatInfo([this.times = 1, this.afterJump = false]);

  int times;
  bool afterJump;
}

/// Mirrors `musicxml::JumpInfo::JUMPTYPE`.
enum _JumpType { none, dalsegno, dacapo, tocoda }

/// Mirrors `musicxml::JumpInfo`.
class _JumpInfo {
  String label = '';
  _JumpType jump = _JumpType.none;
  List<int> times = [];
}

/// Mirrors `musicxml::FineInfo`.
class _FineInfo {
  bool fine = false;
}

/// Mirrors `musicxml::SectionInfo`.
class _SectionInfo {
  _SectionInfo([this.repeatStart = false]);

  _SectionInfo.repeat(_RepeatInfo info)
      : repeatInfo = info,
        repeatStart = false;

  ClassId classId = ClassId.section;
  Object? target;
  String label = '';
  _EndingInfo endingInfo = _EndingInfo();
  _RepeatInfo repeatInfo = _RepeatInfo();
  bool repeatStart;
  _JumpInfo _jumpInfo = _JumpInfo();
  _FineInfo _fineInfo = _FineInfo();
  int visited = 0;

  void mergeEnding(_EndingInfo info) {
    classId = ClassId.ending;
    endingInfo = info;
  }
}

/// Mirrors `musicxml::ClefChange`.
class _ClefChange {
  _ClefChange(this.measureNum, this.staff, this.layer, this.clef,
      this.scoreOnset,
      [this.afterBarline = false]);

  String measureNum;
  Staff staff;
  Layer? layer;
  Clef clef;
  int scoreOnset; // the score position of clef change
  bool afterBarline; // musicXML attribute
}

/// Mirrors `musicxml::OpenDashes`.
class _OpenDashes {
  _OpenDashes(this.dirN, this.staffNum, this.measureCount);

  final int dirN; // direction number
  final int staffNum;
  final int measureCount; // measure number of dashes start
}

/// Mirrors `musicxml::OpenTie`.
class _OpenTie {
  Tie? tie;
  Note? note;
  int layerNum;

  _OpenTie(this.tie, this.note, this.layerNum);
}

/// Mirrors `musicxml::CloseTie`.
class _CloseTie {
  Note note;
  int layerNum;

  _CloseTie(this.note, this.layerNum);
}

/// Mirrors `musicxml::Accidental`.
class _XmlAccidental {
  _XmlAccidental(
      [AccidentalWritten? accid, this.glyphName = '', this.glyphAuth = ''])
      : accid = accid ?? AccidentalWritten.none;

  AccidentalWritten accid;
  String glyphName;
  String glyphAuth;
}

/// Sorted-multimap emulation for `std::multimap<int, LayerElement *>`
/// (`m_layerTimes`): entries are kept sorted by key; duplicate keys are
/// allowed and inserted after existing equal keys.
class _LayerTimeMultiMap {
  final List<MapEntry<int, LayerElement>> entries = [];

  bool get isEmpty => entries.isEmpty;
  bool get isNotEmpty => entries.isNotEmpty;
  int get length => entries.length;
  int get lastKey => entries.last.key;

  /// Insert keeping sort order (after equal keys).
  void emplace(int key, LayerElement element) {
    int i = entries.length;
    while (i > 0 && entries[i - 1].key > key) {
      i--;
    }
    entries.insert(i, MapEntry(key, element));
  }

  /// Index of the first entry with key >= [k] ([length] if none).
  int lowerBound(int k) {
    int i = 0;
    while (i < length && entries[i].key < k) {
      i++;
    }
    return i;
  }

  /// Index of the first entry with key > [k] ([length] if none).
  int upperBound(int k) {
    int i = 0;
    while (i < length && entries[i].key <= k) {
      i++;
    }
    return i;
  }

  MapEntry<int, LayerElement> entryAt(int index) => entries[index];
}

// ---------------------------------------------------------------------------
// MusicXmlInput
// ---------------------------------------------------------------------------

/// This class is a file input stream for reading MusicXML files (mirrors
/// `vrv::MusicXmlInput`).
class MusicXmlInput extends Input {
  MusicXmlInput(super.doc);

  /* octave offset */
  final List<int> octDis = [];
  /* measure repeats */
  bool mRpt = false;
  /* measure repeats (slashes) */
  bool slash = false;
  /* MIDI ticks */
  int ppq = -1;
  /* measure time */
  int durTotal = 0;
  /* figured bass time */
  int durFb = 0;
  /* meter signature */
  List<int> meterCount = [4];
  int meterUnit = 4;
  MeterCountSign meterSign = MeterCountSign.none;
  /* part information */
  Label? label;
  LabelAbbr? labelAbbr;
  InstrDef? instrdef;
  /* LastElementID */
  String id = '';
  /* A map of stacks for piling open LayerElements (beams, tuplets, chords,
   * btrem, ftrem) separately per layer */
  final Map<Layer, List<LayerElement>> elementStackMap = {};
  /* A map of time stamps (score time) to indicate write pointer of a layer */
  final Map<Layer, int> layerEndTimes = {};
  final Map<Layer, _LayerTimeMultiMap> _layerTimes = {};
  /* To remember layer of last element (note) to handle chords */
  Layer? prevLayer;
  /* To remember current layer to properly handle layers/staves/cross-staff
   * elements */
  Layer? currentLayer;
  bool isLayerInitialized = false;
  /* The stack for open slurs */
  final List<(Slur, _OpenSlur)> _slurStack = [];
  /* The stack for slur stops that might come before the slur has been opened */
  final List<(LayerElement, _CloseSlur)> _slurStopStack = [];
  /* The stack for open ties */
  final List<_OpenTie> _tieStack = [];
  /* The stack for tie stops that might come before the tie was opened */
  final List<_CloseTie> _tieStopStack = [];
  /* The stack for hairpins */
  final List<(Hairpin, _OpenSpanner)> _hairpinStack = [];
  /* The stack for hairpin stops that might occur before a hairpin was started:
   * staffNumber, tStamp2, (hairpinNumber, measureCount) */
  final List<(int, double, _OpenSpanner)> _hairpinStopStack = [];
  /* The stack for beamspans with staff/layer numbers of the starting element */
  final List<(BeamSpan, (int, int))> _beamspanStack = [];
  final List<(BracketSpan, _OpenSpanner)> _bracketStack = [];
  final List<(Trill, _OpenSpanner)> _trillStack = [];
  /* Current section/ending info for start/stop */
  _SectionInfo? _sectionStart;
  _SectionInfo? _sectionStop;
  _JumpInfo? _jumpInfo;
  _FineInfo? _fineInfo;
  /* The list of _sections/endings to be inserted at the end of XML import */
  final List<MapEntry<_SectionInfo, List<Measure>>> _sections = [];
  /* The stack of open dashes (direction-type) with ControlElement + OpenDashes */
  final List<(ControlElement, _OpenDashes)> _openDashesStack = [];
  /* The stacks for ControlElements */
  final List<Dir> dirStack = [];
  final List<Dynam> dynamStack = [];
  final List<Gliss> glissStack = [];
  final List<Harm> harmStack = [];
  final List<Octave> octaveStack = [];
  final List<Pedal> pedalStack = [];
  final List<Tempo> tempoStack = [];
  /*
   * The stack of floating elements (tie, slur, etc.) to be added at the
   * end of each measure
   */
  final List<(String, ControlElement)> controlElements = [];
  /* stack of clef changes to be inserted to all layers of a given staff */
  final List<_ClefChange> _clefChangeQueue = [];
  /* stack of new arpeggios that get more notes added. */
  final List<(Arpeg, _OpenArpeggio)> _arpeggioStack = [];
  /* a map for the measure counts storing the index of each measure created */
  final Map<Measure, int> measureCounts = {};
  /* measure rests */
  final Map<int, int> multiRests = {};
  /* a map of current accidental for each pitch class */
  final Map<Pitchname, List<_XmlAccidental>> _currentAccids = {};
  /* current key signature */
  KeySig? currentKeySig;
  /* A flag indicating we had a clef change */
  int clefChanged = 0;

  /// The verovio version written into the generated header (mirrors
  /// `GetVersion()`).
  static const String version = '6.2.0';

  // -------------------------------------------------------------------------

  /// Mirrors `MusicXmlInput::Import`.
  @override
  bool import(String musicxml) {
    doc.reset();
    doc.setType(DocType.raw);
    final MeiXmlNode? rootDoc = parseMeiXml(musicxml);
    if (rootDoc == null || rootDoc.childElements().isEmpty) {
      logError('The tree of the MusicXML data cannot be parsed');
      return false;
    }
    final MeiXmlNode root = rootDoc.childElements().first;
    try {
      return readMusicXml(root);
    } catch (e) {
      logError('MusicXML import failed: $e');
      return false;
    }
  }

  // =========================================================================
  // XML helpers
  // =========================================================================

  /// Mirrors `HasAttributeWithValue`.
  static bool hasAttributeWithValue(
      MeiXmlNode node, String attribute, String value) =>
      node.attr(attribute) == value;

  /// Mirrors `IsElement`.
  static bool isElement(MeiXmlNode? node, String name) =>
      node != null && node.name == name;

  /// Mirrors `HasContentWithValue`.
  static bool hasContentWithValue(MeiXmlNode? node, String value) =>
      getContent(node) == value;

  /// Mirrors `GetContent`.
  static String getContent(MeiXmlNode? node) {
    if (node == null) return '';
    return node.textValue() ?? '';
  }

  /// Mirrors `GetContentOfChild` (simple relative xpath lookup).
  String getContentOfChild(MeiXmlNode node, String child) {
    final MeiXmlNode? childNode = xpathFirst(node, child);
    if (childNode != null) {
      return getContent(childNode);
    }
    return '';
  }

  /// Mirrors `StringFormat("/score-partwise/part[@id='%s']...", partId)` —
  /// a minimal `%s` substitution helper.
  static String format(String pattern, List<String> args) {
    final StringBuffer out = StringBuffer();
    int argIdx = 0;
    for (int i = 0; i < pattern.length; ++i) {
      if (pattern[i] == '%' && i + 1 < pattern.length && pattern[i + 1] == 's') {
        out.write(argIdx < args.length ? args[argIdx++] : '');
        ++i;
      } else {
        out.write(pattern[i]);
      }
    }
    return out.toString();
  }

  // =========================================================================
  // XPath subset engine
  //
  // The C++ reader relies on pugixml xpath queries. This small evaluator
  // reproduces the exact subset of XPath used in iomusxml.cpp: absolute or
  // relative paths, child / descendant (`.//`) / self / parent / ancestor /
  // following-sibling / preceding-sibling / following axes, `*` wildcards,
  // unions (`a|b`), and predicates ([@attr], [@attr='v'], [@attr!='v'],
  // [not(...)], [text()='v'], [N], [path], [(path)], [contains(name(),'x')],
  // [self::x], [@a or @b], [@a='v' and ...]).
  // =========================================================================

  /// Mirrors `node.select_nodes(expr)` — returns matches in document order.
  List<MeiXmlNode> xpathNodes(MeiXmlNode ctx, String expr) {
    MeiXmlNode start = ctx;
    String e = expr.trim();
    if (e.startsWith('/')) {
      // Absolute path from the document root (#document wrapper).
      while (e.startsWith('/')) {
        e = e.substring(1);
      }
      MeiXmlNode top = ctx;
      while (top.parent != null) {
        top = top.parent!;
      }
      start = top;
    }
    final List<MeiXmlNode> result = [];
    for (final String part in splitTopLevel(e, '|')) {
      result.addAll(evalPath(start, part.trim()));
    }
    return result;
  }

  /// Mirrors `node.select_node(expr)` — the first match or null.
  MeiXmlNode? xpathFirst(MeiXmlNode? ctx, String expr) {
    if (ctx == null) return null;
    final List<MeiXmlNode> result = xpathNodes(ctx, expr);
    return result.isEmpty ? null : result.first;
  }

  /// True if the query has at least one match.
  bool xpathExists(MeiXmlNode? ctx, String expr) =>
      xpathFirst(ctx, expr) != null;

  /// Evaluate a path without unions against [start].
  static List<MeiXmlNode> evalPath(MeiXmlNode start, String path) {
    String p = path.trim();
    // ".//name" — descendants of the context.
    bool descendantOnly = false;
    if (p.startsWith('.//')) {
      descendantOnly = true;
      p = p.substring(3);
    } else if (p == '.') {
      return [start];
    } else if (p.startsWith('./')) {
      p = p.substring(2);
    }

    List<MeiXmlNode> current = [start];
    final List<String> steps = <String>[];
    for (final String step in splitTopLevel(p, '/')) {
      steps.add(step);
    }
    for (int s = 0; s < steps.length; ++s) {
      String step = steps[s].trim();
      if (step.isEmpty || step == '.') continue;
      if (descendantOnly && s == 0) {
        current = evalStep(current, 'descendant', step);
        descendantOnly = false;
        continue;
      }
      String axis = 'child';
      const axes = [
        'following-sibling',
        'preceding-sibling',
        'descendant-or-self',
        'ancestor-or-self',
        'following',
        'preceding',
        'ancestor',
        'descendant',
        'parent',
        'child',
        'self',
      ];
      for (final String a in axes) {
        if (step.startsWith('$a::')) {
          axis = a;
          step = step.substring(a.length + 2);
          break;
        }
      }
      current = evalStep(current, axis, step);
      if (current.isEmpty) return const [];
    }
    return current;
  }

  /// Evaluate one axis step with name test and predicates.
  static List<MeiXmlNode> evalStep(
      List<MeiXmlNode> candidates, String axis, String rawStep) {
    // Split off name test and predicate blocks.
    int bracket = rawStep.indexOf('[');
    final String name =
        (bracket == -1 ? rawStep : rawStep.substring(0, bracket)).trim();
    final List<String> predicates = [];
    while (bracket != -1) {
      int depth = 0;
      int end = -1;
      for (int i = bracket; i < rawStep.length; ++i) {
        final String ch = rawStep[i];
        if (ch == '[') depth++;
        if (ch == ']') {
          depth--;
          if (depth == 0) {
            end = i;
            break;
          }
        }
      }
      if (end == -1) break;
      predicates.add(rawStep.substring(bracket + 1, end));
      bracket = rawStep.indexOf('[', end + 1);
    }

    final List<MeiXmlNode> matched = [];
    bool nameMatches(MeiXmlNode n) => name == '*' || n.name == name;

    void addIfMatched(List<MeiXmlNode> nodes) {
      for (final MeiXmlNode n in nodes) {
        if (nameMatches(n)) matched.add(n);
      }
    }

    for (final MeiXmlNode node in candidates) {
      switch (axis) {
        case 'child':
          addIfMatched(node.childrenElements());
          break;
        case 'descendant':
        case 'descendant-or-self':
          if (axis == 'descendant-or-self' && nameMatches(node)) {
            matched.add(node);
          }
          final List<MeiXmlNode> allDescendants = [];
          void walk(MeiXmlNode n) {
            for (final MeiXmlNode c in n.childrenElements()) {
              allDescendants.add(c);
              walk(c);
            }
          }
          walk(node);
          addIfMatched(allDescendants);
          break;
        case 'self':
          if (nameMatches(node)) matched.add(node);
          break;
        case 'parent':
          if (node.parent != null && nameMatches(node.parent!)) {
            matched.add(node.parent!);
          }
          break;
        case 'ancestor':
        case 'ancestor-or-self':
          if (axis == 'ancestor-or-self' && nameMatches(node)) {
            matched.add(node);
          }
          MeiXmlNode? ancestor = node.parent;
          while (ancestor != null) {
            if (nameMatches(ancestor)) matched.add(ancestor);
            ancestor = ancestor.parent;
          }
          break;
        case 'following-sibling':
          final MeiXmlNode? parent = node.parent;
          if (parent != null) {
            final int idx = parent.children.indexOf(node);
            addIfMatched(parent.childrenElements().where((n) {
              final int i = parent.children.indexOf(n);
              return i > idx && nameMatches(n);
            }).toList());
          }
          break;
        case 'preceding-sibling':
          final MeiXmlNode? parent = node.parent;
          if (parent != null) {
            final int idx = parent.children.indexOf(node);
            for (final MeiXmlNode sibling in parent.childrenElements()) {
              final int i = parent.children.indexOf(sibling);
              if (i < idx && nameMatches(sibling)) matched.add(sibling);
            }
          }
          break;
        case 'following':
          // Collect everything after [node] in document order, excluding its
          // own subtree.
          final MeiXmlNode? root = documentRootOf(node);
          if (root != null) {
            final List<MeiXmlNode> flat = flatten(root);
            final int pos = flat.indexWhere((n) => identical(n, node));
            final Set<MeiXmlNode> subtree = flatten(node).toSet();
            for (int i = pos + 1; i < flat.length; ++i) {
              if (!subtree.contains(flat[i]) && nameMatches(flat[i])) {
                matched.add(flat[i]);
              }
            }
          }
          break;
        default:
          break;
      }
    }

    // Apply predicates sequentially (XPath semantics).
    List<MeiXmlNode> filtered = matched;
    for (final String pred in predicates) {
      final trimmed = pred.trim();
      final position = RegExp(r'^\d+$').firstMatch(trimmed);
      if (position != null) {
        final int index = int.parse(trimmed) - 1;
        filtered =
            (index >= 0 && index < filtered.length) ? [filtered[index]] : [];
      } else {
        filtered = filtered
            .where((n) => evalPredicate(n, trimmed))
            .toList(growable: false);
      }
    }
    return filtered;
  }

  /// Evaluate a boolean predicate expression on [node].
  static bool evalPredicate(MeiXmlNode node, String expr) {
    final String e = expr.trim();
    final List<String> orParts = splitTopLevel(e, ' or ');
    for (final String orPart in orParts) {
      bool allHold = true;
      for (final String andPart in splitTopLevel(orPart, ' and ')) {
        if (!evalAtom(node, andPart.trim())) {
          allHold = false;
          break;
        }
      }
      if (allHold) return true;
    }
    return false;
  }

  /// Evaluate one atom of a predicate.
  static bool evalAtom(MeiXmlNode node, String atom) {
    String a = atom.trim();
    // Strip fully wrapping parentheses: "(...)".
    while (a.startsWith('(') && a.endsWith(')') && wrapIsBalanced(a)) {
      a = a.substring(1, a.length - 1).trim();
    }
    if (a.startsWith('not(') && a.endsWith(')')) {
      return !evalPredicate(node, a.substring(4, a.length - 1));
    }
    // contains(name(), 'x')
    final containsMatch =
        RegExp(r"^contains\(\s*name\(\)\s*,\s*'([^']*)'\s*\)$").firstMatch(a);
    if (containsMatch != null) {
      return node.name.contains(containsMatch.group(1)!);
    }
    // self::name
    if (a.startsWith('self::')) {
      return node.name == a.substring(6);
    }
    // text()='value'
    final textMatch =
        RegExp(r"^text\(\)\s*=\s*'([^']*)'$").firstMatch(a) ??
            RegExp(r'^text\(\)\s*=\s*"([^"]*)"$').firstMatch(a);
    if (textMatch != null) {
      return (node.textValue() ?? '') == textMatch.group(1);
    }
    // @attr != 'value'
    final neqMatch = RegExp(
            r"^@([\w.\-:]+)\s*!=\s*'([^']*)'$")
        .firstMatch(a) ??
        RegExp(r'^@([\w.\-:]+)\s*!=\s*"([^"]*)"$').firstMatch(a);
    if (neqMatch != null) {
      return node.attr(neqMatch.group(1)!) != neqMatch.group(2);
    }
    // @attr = 'value'
    final eqMatch = RegExp(r"^@([\w.\-:]+)\s*=\s*'([^']*)'$").firstMatch(a) ??
        RegExp(r'^@([\w.\-:]+)\s*=\s*"([^"]*)"$').firstMatch(a);
    if (eqMatch != null) {
      return node.attr(eqMatch.group(1)!) == eqMatch.group(2);
    }
    // @attr existence
    final attrExist = RegExp(r'^@([\w.\-:]+)$').firstMatch(a);
    if (attrExist != null) {
      return node.hasAttr(attrExist.group(1)!);
    }
    // Otherwise treat it as an existence path test.
    return evalPath(node, a).isNotEmpty;
  }

  /// Split [input] by separator [sep] at bracket/paren depth zero and outside
  /// quotes. Supports multi-char separators (' or ', ' and ') and single char
  /// ones ('|', '/').
  static List<String> splitTopLevel(String input, String sep) {
    final List<String> parts = [];
    final StringBuffer current = StringBuffer();
    int depth = 0;
    String? quote;
    for (int i = 0; i < input.length; ++i) {
      final String ch = input[i];
      if (quote != null) {
        current.write(ch);
        if (ch == quote) quote = null;
        continue;
      }
      if (ch == "'" || ch == '"') {
        quote = ch;
        current.write(ch);
        continue;
      }
      if (ch == '[' || ch == '(') depth++;
      if (ch == ']' || ch == ')') depth--;
      if (depth == 0 &&
          ch == sep[0] &&
          _matchesAt(input, i, sep)) {
        parts.add(current.toString());
        current.clear();
        i += sep.length - 1;
        continue;
      }
      current.write(ch);
    }
    parts.add(current.toString());
    return parts;
  }

  static bool _matchesAt(String input, int pos, String sep) {
    if (pos + sep.length > input.length) return false;
    return input.substring(pos, pos + sep.length) == sep;
  }

  /// True when the outer parens of [a] are balanced within the string.
  static bool wrapIsBalanced(String a) {
    int depth = 0;
    for (int i = 0; i < a.length; ++i) {
      final String ch = a[i];
      if (ch == '(') depth++;
      if (ch == ')') {
        depth--;
        if (depth == 0 && i != a.length - 1) return false;
      }
    }
    return true;
  }

  /// Flatten [node] and its subtree in document order.
  static List<MeiXmlNode> flatten(MeiXmlNode node) {
    final List<MeiXmlNode> out = [node];
    for (final MeiXmlNode child in node.children) {
      out.addAll(flatten(child));
    }
    return out;
  }

  /// The topmost ancestor of [node].
  static MeiXmlNode? documentRootOf(MeiXmlNode node) {
    MeiXmlNode top = node;
    while (top.parent != null) {
      top = top.parent!;
    }
    return top.parent == null ? null : top;
  }

  /// Sort [nodes] into document order (mirrors `xpath_node_set::sort()`).
  void sortInDocumentOrder(List<MeiXmlNode> nodes) {
    if (nodes.isEmpty) return;
    final MeiXmlNode top = documentRootOf(nodes.first) ?? nodes.first;
    final List<MeiXmlNode> flat = flatten(top);
    final Map<int, int> order = {};
    for (int i = 0; i < flat.length; ++i) {
      order[identityHashCode(flat[i])] = i;
    }
    nodes.sort((a, b) =>
        (order[identityHashCode(a)] ?? 0) - (order[identityHashCode(b)] ?? 0));
  }

  /// The next element sibling with [name] (empty node when none, mirroring
  /// pugixml's null-node behaviour through a null return).
  static MeiXmlNode? nextSiblingNamed(MeiXmlNode node, String name) {
    MeiXmlNode? current = node.nextSibling();
    while (current != null) {
      if (current.isElement && current.name == name) return current;
      current = current.nextSibling();
    }
    return null;
  }

  /// Parse a string of comma separated ints with optional spaces (mirrors
  /// the file-local `parseInts`).
  static List<int> parseInts(String str) {
    final List<int> result = [];
    for (final String token in str.split(',')) {
      final String v = token.trim();
      if (v.isEmpty) continue;
      final int? num = int.tryParse(v);
      if (num != null) result.add(num);
    }
    return result;
  }

  // =========================================================================
  // Clef change queue processing
  // =========================================================================

  /// Mirrors `ProcessClefChangeQueue`.
  void processClefChangeQueue(Section section) {
    while (_clefChangeQueue.isNotEmpty) {
      final _ClefChange clefChange = _clefChangeQueue.removeAt(0);
      final comparison =
          AttNNumberLikeComparison(ClassId.measure, clefChange.measureNum);
      final Measure? currentMeasure =
          section.findDescendantByComparison(comparison) as Measure?;
      if (currentMeasure == null) {
        logWarning('MusicXML import: Clef change at measure '
            '${clefChange.measureNum}, staff ${clefChange.staff.n}, '
            'time ${clefChange.scoreOnset} not inserted');
        continue;
      }
      if (clefChange.scoreOnset == 0 && !clefChange.afterBarline) {
        // First try to check whether current measure already exists in the
        // section. Since *measure might not match with the one in the
        // section, comparison search should be done
        final Measure? previousMeasure = section
            .getPreviousSibling(currentMeasure, ClassId.measure) as Measure?;
        if (previousMeasure == null) {
          _addClefs(currentMeasure, clefChange);
          continue;
        }
        final comparisonStaff =
            AttNIntegerComparison(ClassId.staff, clefChange.staff.n ?? 0);
        final Staff? previousStaff =
            previousMeasure.findDescendantByComparison(comparisonStaff)
                as Staff?;
        if (previousStaff == null) {
          _addClefs(currentMeasure, clefChange);
          continue;
        }
        final Layer? previousLayer = previousStaff.findDescendantByType(
            ClassId.layer,
            direction: backward) as Layer?;
        if (previousLayer == null) {
          _addClefs(currentMeasure, clefChange);
        } else {
          // For previous measure we need to make sure that clef is set at the
          // end, so pass high duration value (since it won't matter there)
          // and set measureNum to empty, since it doesn't matter as well
          int steps = 1;
          for (final int num in meterCount) {
            steps += num;
          }
          final int endDuration = 4 * ppq * steps ~/ meterUnit;
          final _ClefChange previousClefChange = _ClefChange(
              '', previousStaff, previousLayer, clefChange.clef, endDuration);
          _addClefs(previousMeasure, previousClefChange);
        }
      } else {
        _addClefs(currentMeasure, clefChange);
      }
    }
  }

  /// Mirrors `AddClefs`.
  void _addClefs(Measure measure, _ClefChange clefChange) {
    // For both measure and staff make sure that corresponding staff/layer is
    // actually a child of it
    int idx = measure.getChildIndex(clefChange.staff);
    if (idx != -1) {
      idx = clefChange.layer != null
          ? clefChange.staff.getChildIndex(clefChange.layer!)
          : -1;
      if (clefChange.layer == null) {
        final Layer? firstLayer =
            clefChange.staff.getChild(0, ClassId.layer) as Layer?;
        if (firstLayer != null) {
          insertClefToLayer(
              clefChange.staff, firstLayer, clefChange.clef, clefChange.scoreOnset);
        }
      } else if (idx != -1) {
        insertClefToLayer(
            clefChange.staff, clefChange.layer!, clefChange.clef, clefChange.scoreOnset);
      } else {
        // If staff doesn't have fitting layer for the clef but has layer with
        // mSpace - this should be a case with cross-staff clef. Remove mSpace
        // in this case and add clef to it instead, filling space if required
        final Object? mSpace =
            clefChange.staff.findDescendantByType(ClassId.mSpace);
        if (mSpace != null) {
          final Layer? parentLayer = mSpace.parent as Layer?;
          if (parentLayer != null) {
            parentLayer.deleteChild(mSpace);
            elementStackMap[parentLayer] = [];
            fillSpace(parentLayer, clefChange.scoreOnset);
            parentLayer.addChild(clefChange.clef);
          }
        } else {
          final Layer? firstLayer =
              clefChange.staff.getChild(0, ClassId.layer) as Layer?;
          if (firstLayer != null) {
            insertClefToLayer(clefChange.staff, firstLayer,
                clefChange.clef, clefChange.scoreOnset);
          }
        }
      }
    }
  }

  /// Mirrors `InsertClefToLayer`.
  void insertClefToLayer(Staff staff, Layer layer, Clef clef, int scoreOnset) {
    // Since AddClef handles #sameas clef only for the future layers, we need
    // to check any previous existing layers for the same staff to see if we
    // need to insert #sameas clef to them.
    final List<Object> staffLayers = staff.findAllDescendantsByType(
        ClassId.layer,
        continueDepthSearchForMatches: false);
    for (final Object listLayer in staffLayers) {
      final Layer otherLayer = listLayer as Layer;
      final _LayerTimeMultiMap? times = _layerTimes[otherLayer];
      if (times == null || times.isEmpty) continue;
      // Get first element for the same (or higher if same is not present)
      // duration
      final int startIndex = times.lowerBound(scoreOnset);
      // Add either clef or #sameas, depending on the layer we're adding to
      Clef? clefToAdd;
      if (identical(listLayer, layer)) {
        clefToAdd = clef;
      } else {
        clefToAdd = Clef();
        clefToAdd.sameas = '#${clef.id}';
      }

      // In case scoreOnset is 0 - add clef before the first element
      if (scoreOnset == 0) {
        insertClefIntoObject(times.entryAt(startIndex).value, clefToAdd,
            otherLayer, scoreOnset, false);
      } else {
        // If corresponding time couldn't be found (i.e. it's higher than any
        // other duration in the layer) - add clef to the end of the layer
        if (startIndex >= times.length) {
          otherLayer.addChild(clefToAdd);
          times.emplace(times.lastKey, clefToAdd);
        } else {
          // Always try to add clefs at the end of current duration, to honor
          // their order in the musicxml
          final int actualScoreOnSet = times.entryAt(startIndex).key;
          final int upper = times.upperBound(actualScoreOnSet);
          final LayerElement layerElement = times.entryAt(upper - 1).value;
          insertClefIntoObject(
              layerElement, clefToAdd, otherLayer, scoreOnset, true);
        }
      }
    }
  }

  /// Mirrors `InsertClefIntoObject(Object *layerElement, ...)`.
  void insertClefIntoObject(
      Object layerElement, Clef clef, Layer layer, int scoreOnset,
      bool insertAfter) {
    if (layerElement.parent?.classId == ClassId.layer) {
      insertClefIntoParent(layer, clef, layerElement, insertAfter);
      _layerTimes[layer]?.emplace(scoreOnset, clef);
    } else {
      final Object parent = layerElement.parent!;
      if (parent.classId == ClassId.chord ||
          parent.classId == ClassId.fTrem ||
          parent.classId == ClassId.tabGrp) {
        insertClefIntoParent(parent.parent!, clef, parent, insertAfter);
      } else {
        insertClefIntoParent(parent, clef, layerElement, insertAfter);
      }
    }
  }

  /// Mirrors `InsertClefIntoObject(Object *parent, ...)`.
  void insertClefIntoParent(
      Object parent, Clef clef, Object layerElement, bool insertAfter) {
    if (parent.getChildIndex(layerElement) == -1) return;
    if (insertAfter) {
      parent.insertAfter(layerElement, clef);
    } else {
      parent.insertBefore(layerElement, clef);
    }
  }

  // =========================================================================
  // Measures / layers
  // =========================================================================

  /// Mirrors `AddMeasure`.
  void addMeasure(Section section, Measure measure, int i) {
    Measure? contentMeasure;

    // we just need to add a measure
    if (section.getChildCount(ClassId.measure) <=
        i - getMrestMeasuresCountBeforeIndex(i)) {
      section.addChild(measure);
      contentMeasure = measure;
    }
    // otherwise copy the content to the corresponding existing measure
    else {
      Measure? existingMeasure;
      // Search by measure number first
      final comparison =
          AttNNumberLikeComparison(ClassId.measure, measure.n ?? '');
      final List<Object> matchingMeasures =
          section.findAllDescendantsMatching(comparison, deepness: 1);
      // For now take the first match
      if (matchingMeasures.isNotEmpty) {
        existingMeasure = matchingMeasures.first as Measure;
      }
      // Prefer any measure with matching index (measure numbers might be
      // non-unique)
      for (final Object object in matchingMeasures) {
        final Measure matchingMeasure = object as Measure;
        if (measureCounts[matchingMeasure] == i) {
          existingMeasure = matchingMeasure;
          break;
        }
      }
      if (existingMeasure != null) {
        for (final Object current in measure.children) {
          if (current.classId != ClassId.staff) continue;
          current.moveItselfTo(existingMeasure);
        }
        measure.clearRelinquishedChildren();
      } else {
        // The measure was not transferred and not added to the tree. Its
        // entire content will be deleted at the end.
        logError('MusicXML import: Mismatching measure number ${measure.n}');
      }
      contentMeasure = existingMeasure;

      measureCounts.remove(measure);
    }

    // Insert the measure in the section/ending structure that will be
    // expanded at the end.
    if (contentMeasure != null && !measureInExistingSection(contentMeasure)) {
      // starting a new section
      final _SectionInfo? start = _sectionStart;
      if (start != null) {
        _sections.add(MapEntry(_copySectionInfo(start), []));
      }
      // add current measure to current section
      if (_sections.isNotEmpty) {
        _sections.last.value.add(contentMeasure);
      }
      // jump and fine info
      if (_jumpInfo != null && _sections.isNotEmpty) {
        _sections.last.key._jumpInfo = _jumpInfo!;
      }
      if (_fineInfo != null && _sections.isNotEmpty) {
        _sections.last.key._fineInfo = _fineInfo!;
      }
      // closing a section: open a new one
      if (_sectionStop != null && _sections.isNotEmpty) {
        if (_sectionStop!.classId == ClassId.ending) {
          _sections.last.key.endingInfo = _sectionStop!.endingInfo;
        } else {
          _sections.last.key.repeatInfo = _sectionStop!.repeatInfo;
        }
        _sections.add(MapEntry(_SectionInfo(), []));
      }
    }
    _sectionStart = null;
    _sectionStop = null;
    _jumpInfo = null;
    _fineInfo = null;
  }

  /// Value copy of a `_SectionInfo` (mirrors `{*m_sectionStart, {}}`).
  static _SectionInfo _copySectionInfo(_SectionInfo info) {
    final copy = _SectionInfo();
    copy.classId = info.classId;
    copy.target = info.target;
    copy.label = info.label;
    copy.endingInfo = info.endingInfo;
    copy.repeatInfo = info.repeatInfo;
    copy.repeatStart = info.repeatStart;
    copy._jumpInfo = info._jumpInfo;
    copy._fineInfo = info._fineInfo;
    copy.visited = info.visited;
    return copy;
  }

  /// Mirrors `AddLayerElement`.
  void addLayerElement(Layer layer, LayerElement element, [int duration = 0]) {
    int currTime = 0;
    if (layerEndTimes.containsKey(layer)) currTime = layerEndTimes[layer]!;
    if ((layer.childCount == 0 && durTotal > 0) || currTime < durTotal) {
      fillSpace(layer, durTotal - currTime, true);
    }

    if (_stackFor(layer).isEmpty) {
      layer.addChild(element);
    } else {
      _stackFor(layer).last.addChild(element);
    }
    // Recheck if AddChild was successful
    if (element.parent == null) return;

    layerEndTimes[layer] = durTotal + duration;
    if (element.classId != ClassId.beam && element.classId != ClassId.tuplet) {
      _timesFor(layer).emplace(durTotal + duration, element);
    }
  }

  /// Stack accessor mirroring `m_elementStackMap.at(layer)` with auto-create.
  List<LayerElement> _stackFor(Layer layer) =>
      elementStackMap.putIfAbsent(layer, () => []);

  /// Time multimap accessor mirroring `m_layerTimes[layer]` with auto-create.
  _LayerTimeMultiMap _timesFor(Layer layer) =>
      _layerTimes.putIfAbsent(layer, _LayerTimeMultiMap.new);

  // =========================================================================
  // Layer selection
  // =========================================================================

  /// Mirrors `SelectLayer(pugi::xml_node node, Measure *measure)`.
  Layer selectLayerFromNode(MeiXmlNode node, Measure measure) {
    // If value is initialized - get current layer
    if (isLayerInitialized) return currentLayer!;

    // Find voice number of node
    final MeiXmlNode? voiceNode = node.child('voice');
    int layerNum = voiceNode != null ? strToInt(getContent(voiceNode)) : 1;
    if (layerNum < 1) {
      logWarning('MusicXML import: Layer $layerNum cannot be found');
      layerNum = 1;
    }

    // If not initialized and layer is not set - get first layer in the first
    // staff
    if (currentLayer == null) {
      final Staff staff = measure.getChild(0, ClassId.staff)! as Staff;
      currentLayer = selectLayerInStaff(layerNum, staff);
      isLayerInitialized = true;
      return currentLayer!;
    }

    // if not, take staff info of node element
    final MeiXmlNode? staffNode = node.child('staff');
    int staffNum = staffNode != null ? strToInt(getContent(staffNode)) : 1;
    if (staffNum < 1 || staffNum > measure.getChildCount(ClassId.staff)) {
      logWarning('MusicXML import: Staff $staffNum cannot be found');
      staffNum = 1;
    }
    staffNum--;
    final Staff staff = measure.getChild(staffNum, ClassId.staff)! as Staff;
    currentLayer = selectLayerInStaff(layerNum, staff);

    isLayerInitialized = true;
    return currentLayer!;
  }

  /// Mirrors `SelectLayer(short int staffNum, Measure *measure)`.
  Layer selectLayerOfStaff(int staffNum, Measure measure) {
    staffNum--;
    final Staff staff = measure.getChild(staffNum, ClassId.staff)! as Staff;
    // layer -1 means the first one
    return selectLayerInStaff(-1, staff);
  }

  /// Mirrors `SelectLayer(short int layerNb, Staff *staff)`.
  Layer selectLayerInStaff(int layerNum, Staff staff) {
    Layer? layer;
    // no layer specified, return the first one (if any)
    if (layerNum == -1) {
      if (staff.childCount > 0) {
        layer = staff.getChild(0) as Layer?;
      }
      // otherwise set @n to 1
      layerNum = 1;
    } else {
      final comparisonLayer = AttNIntegerComparison(ClassId.layer, layerNum);
      layer = staff.findDescendantByComparison(comparisonLayer, deepness: 1)
          as Layer?;
    }
    if (layer != null) return layer;
    // else add it
    // add at least one layer
    layer = Layer();
    layer.n = layerNum;
    staff.addChild(layer);
    elementStackMap[layer] = [];
    return layer;
  }

  // =========================================================================
  // Element stack helpers
  // =========================================================================

  /// Mirrors `RemoveLastFromStack`.
  void removeLastFromStack(ClassId classId, Layer layer) {
    final List<LayerElement> stack = _stackFor(layer);
    for (int i = stack.length - 1; i >= 0; --i) {
      if (stack[i].classId == classId) {
        stack.removeAt(i);
        return;
      }
    }
  }

  /// Mirrors `IsInStack`.
  bool isInStack(ClassId classId, Layer layer) =>
      _stackFor(layer).any((element) => element.classId == classId);

  /// Mirrors `FillSpace`.
  void fillSpace(Layer layer, int dur,
      [bool withClefs = false, int offset = 0]) {
    // Split spaces to take into account pending clef changes in that layer
    if (withClefs && _clefChangeQueue.isNotEmpty) {
      final List<int> durs = [];
      int processed = 0;
      for (final _ClefChange clefChange in _clefChangeQueue) {
        if (!identical(clefChange.layer, layer)) continue;
        if (clefChange.scoreOnset < dur) {
          durs.add(clefChange.scoreOnset - processed);
          processed = clefChange.scoreOnset;
        }
      }
      if (processed > 0 && processed < dur) {
        durs.add(dur - processed);
      }
      if (durs.isNotEmpty) {
        int processedList = 0;
        for (final int durList in durs) {
          // Call it recursively with split durations and the processed offset
          fillSpace(layer, durList, false, processedList);
          processedList += durList;
        }
        return;
      }
    }

    String durStr = '';
    while (dur > 0) {
      double quarters = dur / ppq;
      quarters =
          math.pow(2.0, (math.log(quarters) / math.ln2).floorToDouble())
              .toDouble();
      // limit space for now
      if (quarters > 2) quarters = 2;
      durStr = (4 ~/ quarters).toString();

      final Space space = Space();
      space.dur = strToDuration(durStr);
      space.durPpq = (ppq * quarters).truncate();
      if (_stackFor(layer).isEmpty) {
        layer.addChild(space);
      } else {
        _stackFor(layer).last.addChild(space);
      }
      dur -= (ppq * quarters).truncate();
      offset += (ppq * quarters).truncate();
      _timesFor(layer).emplace(offset, space);
    }
  }

  /// Mirrors `GenerateID`: append a generated xml:id attribute to [node].
  void generateID(MeiXmlNode node) {
    final String id = node.name.substring(0, 1) + Object.generateHashID();
    node.setAttribute('xml:id', id);
  }

  // =========================================================================
  // Tie and slur stack management
  // =========================================================================

  /// Mirrors `OpenTie(Note*, Tie*, int)`.
  void openTie(Note note, Tie tie, int layerNum) {
    tie.startid = '#${note.id}';
    _tieStack.add(_OpenTie(tie, note, layerNum));
  }

  /// Mirrors `CloseTie(Note*, int)`.
  void closeTie(Note note, int layerNum) {
    // add all notes with identical pitch/oct to _tieStopStack
    for (final _OpenTie tie in _tieStack) {
      if (tie.note != null && isEnharmonicWith(note, tie.note!)) {
        _tieStopStack.add(_CloseTie(note, layerNum));
      }
    }
  }

  /// Mirrors `OpenSlur`.
  void openSlur(Measure measure, int number, Slur slur, CurvatureCurvedir dir) {
    // try to match open slur with slur stops within that measure
    for (int i = 0; i < _slurStopStack.length; ++i) {
      final (_, _CloseSlur closeSlur) = _slurStopStack[i];
      if (closeSlur.number == number &&
          closeSlur.measureNum.compareTo(measure.n ?? '') == 0) {
        slur.endid = '#${_slurStopStack[i].$1.id}';
        slur.curvedir = combineCurvedir(dir, closeSlur.curvedir);
        _slurStopStack.removeAt(i);
        return;
      }
    }
    // create new slur otherwise
    final _OpenSlur openSlur = _OpenSlur(measure.n ?? '', number, dir);
    _slurStack.add((slur, openSlur));
  }

  /// Mirrors `CloseSlur`.
  void closeSlur(Measure measure, int number, LayerElement element,
      CurvatureCurvedir dir) {
    // try to match slur stop to open slurs by slur number
    for (int i = _slurStack.length - 1; i >= 0; --i) {
      if (_slurStack[i].$2.number == number) {
        _slurStack[i].$1.endid = '#${element.id}';
        _slurStack[i].$1.curvedir =
            combineCurvedir(_slurStack[i].$2.curvedir, dir);
        _slurStack.removeAt(i);
        return;
      }
    }
    // add to _slurStopStack, if not able to be closed
    final _CloseSlur closeSlur = _CloseSlur(measure.n ?? '', number, dir);
    _slurStopStack.add((element, closeSlur));
  }

  /// Mirrors `CloseBeamSpan`.
  void closeBeamSpan(Staff staff, Layer layer, LayerElement element) {
    for (int i = _beamspanStack.length - 1; i >= 0; --i) {
      if (_beamspanStack[i].$2.$1 == staff.n ||
          _beamspanStack[i].$2.$2 == layer.n) {
        _beamspanStack[i].$1.endid = '#${element.id}';
        _beamspanStack.removeAt(i);
        return;
      }
    }
  }

  /// Mirrors `CombineCurvedir`.
  static CurvatureCurvedir combineCurvedir(
      CurvatureCurvedir startDir, CurvatureCurvedir stopDir) {
    if (startDir == CurvatureCurvedir.none) {
      return stopDir;
    } else if ((startDir != stopDir) &&
        (stopDir != CurvatureCurvedir.none)) {
      return CurvatureCurvedir.mixed;
    } else {
      return startDir;
    }
  }

  // =========================================================================
  // Text rendering
  // =========================================================================

  /// Mirrors `GetWordsOrDynamicsText`.
  String getWordsOrDynamicsText(MeiXmlNode node) {
    if (isElement(node, 'words')) {
      return getContent(node);
    }
    if (isElement(node, 'dynamics')) {
      String dynamStr = '';
      final List<MeiXmlNode> children = node.children;
      for (int i = 0; i < children.length; ++i) {
        final MeiXmlNode xmlDynamPart = children[i];
        if (xmlDynamPart.name == 'other-dynamics') {
          if (!identical(xmlDynamPart, children.first)) dynamStr += ' ';
          dynamStr += getContent(xmlDynamPart);
          if (!identical(xmlDynamPart, children.last)) dynamStr += ' ';
        } else {
          dynamStr += xmlDynamPart.name;
        }
      }
      return dynamStr;
    }
    return '';
  }

  /// Mirrors `TextRendition`. [words] must be in document order.
  void textRendition(List<MeiXmlNode> words, ControlElement element) {
    for (final MeiXmlNode textNode in words) {
      final MeiXmlNode? soundNode =
          textNode.parent != null
              ? nextSiblingNamed(textNode.parent!, 'sound')
              : null;
      final String textStr = getWordsOrDynamicsText(textNode);
      final String textColor = textNode.attr('color') ?? '';
      Object textParent = element as Object;
      if (textNode.name.startsWith('symbol')) {
        final Symbol symbol = Symbol();
        symbol.glyphAuth = 'smufl';
        symbol.color = textColor;
        symbol.glyphName = getContent(textNode);
        element.addChild(symbol);
        continue;
      } else if (textNode.name.startsWith('coda') ||
          textNode.name.startsWith('segno')) {
        // for cases we have coda/segno and text in one direction
        final Symbol symbol = Symbol();
        symbol.glyphAuth = 'smufl';
        symbol.color = textColor;
        symbol.glyphName = textNode.name;
        element.addChild(symbol);
        continue;
      } else if (textNode.hasAttr('xml:lang') ||
          textNode.hasAttr('xml:space') ||
          textNode.hasAttr('color') ||
          textNode.hasAttr('halign') ||
          textNode.hasAttr('font-family') ||
          textNode.hasAttr('font-style') ||
          textNode.hasAttr('font-weight') ||
          textNode.hasAttr('enclosure')) {
        final Rend rend = Rend();
        rend.lang = textNode.attr('xml:lang') ?? '';
        rend.color = textColor;
        rend.halign = strToHorizontalalignment(textNode.attr('halign') ?? '');
        rend.space = textNode.attr('xml:space');
        rend.fontfam = textNode.attr('font-family');
        rend.fontstyle = strToFontstyle(textNode.attr('font-style') ?? '');
        rend.fontweight = strToFontweight(textNode.attr('font-weight') ?? '');
        rend.rend = convertEnclosure(textNode.attr('enclosure') ?? '');
        element.addChild(rend);
        textParent = rend;
      } else if (soundNode != null &&
          !(soundNode.hasAttr('dynamics') || soundNode.hasAttr('tempo'))) {
        final Rend rend = Rend();
        rend.halign = Horizontalalignment.right;
        element.addChild(rend);
        textParent = rend;
      }
      // Whitespace line breaks are significant in MusicXML => split into lines
      final List<String> lines = splitLines(textStr);
      bool firstLine = true;
      for (final String line in lines) {
        if (!firstLine) {
          (textParent as dynamic).addChild(Lb());
        }
        final Text text = Text();
        text.text = line;
        (textParent as dynamic).addChild(text);
        firstLine = false;
      }
    }
  }

  /// Split a string into lines on `\n` (mirrors `std::getline`).
  static List<String> splitLines(String s) => s.split('\n');

  // =========================================================================
  // Style part and group names
  // =========================================================================

  /// Mirrors `StyleLabel`.
  String styleLabel(MeiXmlNode display) {
    String displayText = '';
    for (final MeiXmlNode child in display.childrenElements()) {
      if (child.name.startsWith('display')) displayText += getContent(child);
      if (child.name.startsWith('accidental')) {
        displayText += convertFigureGlyph(getContent(child));
      }
    }
    return displayText;
  }

  // =========================================================================
  // Print Metronome
  // =========================================================================

  /// Mirrors `PrintMetronome`.
  void printMetronome(MeiXmlNode metronome, Tempo tempo) {
    // if there is a tempo text, insert a space
    final Text? tempoText = tempo.findDescendantByType(ClassId.text,
            deepness: 1) as Text?;
    if (tempoText != null) {
      final String tempoString = tempoText.text;
      if (tempoString.isNotEmpty && !_isSpace(tempoString[tempoString.length - 1])) {
        final Text text = Text();
        text.text = ' ';
        tempo.addChild(text);
      }
    }

    bool paren = false;
    // Mirrors pugixml `as_bool()`: the literal value "true" only.
    final bool parenAttr =
        metronome.attr('parentheses') == 'true';
    if (parenAttr) {
      final Text text = Text();
      text.text = '(';
      tempo.addChild(text);
      paren = true;
    }

    // build a sequence based on the elements present in the metronome
    final List<(_MetronomeElements, String)> metronomeElements = [];
    for (final MeiXmlNode child in metronome.childrenElements()) {
      if (child.name == 'beat-unit-dot') {
        metronomeElements.add((_MetronomeElements.beatUnitDot, ''));
      } else if (child.name == 'beat-unit') {
        if (metronomeElements.isNotEmpty) {
          metronomeElements.add((_MetronomeElements.separator, ' = '));
        }
        metronomeElements.add((_MetronomeElements.beatUnit, getContent(child)));
      } else if (child.name == 'per-minute') {
        if (metronomeElements.isNotEmpty) {
          metronomeElements.add((_MetronomeElements.separator, ' = '));
        }
        metronomeElements.add((_MetronomeElements.perMinute, getContent(child)));
      }
    }

    bool start = true;
    // process metronome element sequence
    for (int i = 0; i < metronomeElements.length; ++i) {
      switch (metronomeElements[i].$1) {
        case _MetronomeElements.beatUnit:
          {
            String verovioText = convertTypeToVerovioText(metronomeElements[i].$2);
            // find separator or use end() if there is no separator
            int separatorIdx = metronomeElements.indexWhere(
                (pair) => pair.$1 == _MetronomeElements.separator, i);
            if (separatorIdx == -1) separatorIdx = metronomeElements.length;
            final int dotCount = metronomeElements
                .sublist(i, separatorIdx)
                .where((pair) => pair.$1 == _MetronomeElements.beatUnitDot)
                .length;
            for (int d = 0; d < dotCount; ++d) {
              verovioText += ' ';
              verovioText += '\uECB7'; // SMuFL augmentation dot
            }
            // set @mmUnit and @mmDots attributes only based on the first
            // beat-unit in the sequence
            if (start) {
              tempo.mmUnit = convertTypeToDur(metronomeElements[i].$2);
              if (dotCount > 0) tempo.mmDots = dotCount;
              start = false;
            }
            if (verovioText.isNotEmpty) {
              final Rend rend = Rend();
              rend.glyphAuth = 'smufl';
              final Text text = Text();
              text.text = verovioText;
              rend.addChild(text);
              tempo.addChild(rend);
            }
            break;
          }
        case _MetronomeElements.beatUnitDot:
          {
            // don't do anything here; dots are counted in the BEAT_UNIT section
            break;
          }
        case _MetronomeElements.perMinute:
          {
            // Use the first floating-point number on the line to set @mm:
            const String matches = '0123456789';
            int offset = -1;
            for (int c = 0; c < metronomeElements[i].$2.length; ++c) {
              if (matches.contains(metronomeElements[i].$2[c])) {
                offset = c;
                break;
              }
            }
            if (offset >= 0 && offset < metronomeElements[i].$2.length) {
              final double mmval =
                  strToDblPrefix(metronomeElements[i].$2.substring(offset));
              tempo.mm = mmval;
            }
            if (metronomeElements[i].$2.isNotEmpty) {
              final Text text = Text();
              text.text = metronomeElements[i].$2;
              tempo.addChild(text);
            }
            break;
          }
        case _MetronomeElements.separator:
          {
            final Text text = Text();
            text.text = metronomeElements[i].$2;
            tempo.addChild(text);
            break;
          }
      }
    }

    if (paren) {
      final Text text = Text();
      text.text = ')';
      tempo.addChild(text);
    }
  }

  static bool _isSpace(String ch) => ch.trim().isEmpty;

  /// `std::stod` equivalent: parse the leading double or 0.0.
  static double strToDblPrefix(String value) {
    final m =
        RegExp(r'^\s*[+-]?(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?').firstMatch(value);
    return m == null ? 0.0 : (double.tryParse(m.group(0)!.trim()) ?? 0.0);
  }

  // =========================================================================
  // Parsing methods
  // =========================================================================

  /// Mirrors `ReadMusicXml`.
  bool readMusicXml(MeiXmlNode root) {
    // initialize accidentals map
    resetAccidentals();

    // check for multimetric music
    final bool multiMetric =
        xpathExists(root, "/score-partwise/part/measure[@non-controlling='yes']");
    if (multiMetric) {
      logError('MusicXML import: Multimetric music detected. Import cancelled.');
      return false;
    }

    readMusicXmlTitle(root);

    // the mdiv
    final Mdiv mdiv = Mdiv();
    mdiv.setVisibility(VisibilityType.visible);
    doc.addChild(mdiv);
    // the score
    final Score score = Score();
    mdiv.addChild(score);
    // The top-level scoreDef (owned by the score; mirrors
    // Score::Score(createScoreDef=true) with m_scoreDefSubtree = m_scoreDef).
    final ScoreDef scoreDef = ScoreDef();
    score.setScoreDefSubtree(scoreDef, scoreDef);
    // the section
    final Section section = Section();
    score.addChild(section);
    _sections.add(MapEntry(_SectionInfo(), []));
    // initialize layout
    if (xpathExists(
        root, '/score-partwise/part/measure/print[@new-system or @new-page]')) {
      layoutInformation = LayoutInformation.encoded;
      if (!xpathExists(root,
          '/score-partwise/part[1]/measure[1]/print[@new-system or @new-page]')) {
        // always start with a new page
        final Pb pb = Pb();
        section.addChild(pb);
      }
    }

    double bottom = 0.0;
    final MeiXmlNode? layout =
        xpathFirst(root, '/score-partwise/defaults/page-layout');
    if (layout != null) {
      bottom = strToDblPrefix(getContent(xpathFirst(layout,
          'page-margins/bottom-margin')));
    }

    // generate page head
    final List<MeiXmlNode> credits =
        xpathNodes(root, "/score-partwise/credit[@page='1']/credit-words");
    if (credits.isNotEmpty) {
      PgHead? head;
      PgFoot? foot;
      for (final MeiXmlNode words in credits) {
        final Rend rend = Rend();
        final Text text = Text();
        text.text = getContent(words);
        rend.color = words.attr('color');
        rend.halign = strToHorizontalalignment(words.attr('justify') ?? '');
        rend.valign = strToVerticalalignment(words.attr('valign') ?? '');
        rend.fontstyle = strToFontstyle(words.attr('font-style') ?? '');
        rend.fontweight = strToFontweight(words.attr('font-weight') ?? '');
        rend.addChild(text);
        if (strToDblPrefix(words.attr('default-y') ?? '') < 2 * bottom) {
          foot ??= PgFoot();
          foot.addChild(rend);
        } else {
          head ??= PgHead();
          head.func = Pgfunc.first;
          head.addChild(rend);
        }
      }
      if (head != null) {
        score.getScoreDef()!.addChild(head);
      }
      if (foot != null) {
        score.getScoreDef()!.addChild(foot);
      }
    }

    final StaffGrp staffGrp = StaffGrp();
    score.getScoreDef()!.addChild(staffGrp);
    final List<StaffGrp> staffGrpStack = [staffGrp];

    int staffOffset = 0;
    octDis.add(0);

    final MeiXmlNode? scoreMidiBpm = xpathFirst(
        root, '/score-partwise/part[1]/measure[1]/sound[@tempo][1]');
    if (scoreMidiBpm != null) {
      (score.getScoreDef() as ScoreDef).midiBpm =
          strToDblPrefix(scoreMidiBpm.attr('tempo') ?? '');
    }

    for (final MeiXmlNode xpathNode in childOfRoot(root, 'part-list')) {
      if (isElement(xpathNode, 'part-group')) {
        if (hasAttributeWithValue(xpathNode, 'type', 'start')) {
          final StaffGrp partGroupStaffGrp = StaffGrp();
          // read the group-symbol (MEI @symbol)
          final String groupSymbol =
              getContent(xpathNode.child('group-symbol'));
          if (groupSymbol.isNotEmpty) {
            final GrpSym grpSym = GrpSym();
            if (groupSymbol == 'brace') {
              grpSym.symbol = StaffgroupingsymSymbol.brace;
            } else if (groupSymbol == 'line') {
              grpSym.symbol = StaffgroupingsymSymbol.line;
            } else if (groupSymbol == 'bracket') {
              grpSym.symbol = StaffgroupingsymSymbol.bracket;
            } else if (groupSymbol == 'square') {
              grpSym.symbol = StaffgroupingsymSymbol.bracketsq;
            }
            partGroupStaffGrp.addChild(grpSym);
          }
          final String groupBarline =
              getContent(xpathNode.child('group-barline'));
          if (groupBarline.isNotEmpty) {
            partGroupStaffGrp.barThru = (groupBarline == 'no') ? false : true;
          }
          if (groupBarline == 'Mensurstrich') {
            partGroupStaffGrp.barMethod = Barmethod.mensur;
          }
          // now stack it
          final String groupName = getContentOfChild(
              xpathNode, "group-name[not(@print-object='no')]");
          final String groupAbbr = getContentOfChild(
              xpathNode, "group-abbreviation[not(@print-object='no')]");
          if (groupName.isNotEmpty && label == null) {
            label = Label();
            if (xpathExists(
                xpathNode, "group-name-display[not(@print-object='no')]")) {
              final String name =
                  styleLabel(xpathNode.child('group-name-display')!);
              final Text text = Text();
              text.text = name;
              label!.addChild(text);
            } else {
              final Text text = Text();
              text.text = groupName;
              label!.addChild(text);
            }
            partGroupStaffGrp.addChild(label!);
            label = null;
          }
          if (groupAbbr.isNotEmpty && labelAbbr == null) {
            labelAbbr = LabelAbbr();
            if (xpathExists(xpathNode,
                "group-abbreviation-display[not(@print-object='no')]")) {
              final String name =
                  styleLabel(xpathNode.child('group-abbreviation-display')!);
              final Text text = Text();
              text.text = name;
              labelAbbr!.addChild(text);
            } else {
              final Text text = Text();
              text.text = groupAbbr;
              labelAbbr!.addChild(text);
            }
            partGroupStaffGrp.addChild(labelAbbr!);
            labelAbbr = null;
          }
          staffGrpStack.last.addChild(partGroupStaffGrp);
          staffGrpStack.add(partGroupStaffGrp);
        }
        // this is the end of a part-group - assume each opened one is closed
        else {
          if (staffGrpStack.length > 1) staffGrpStack.removeLast();
        }
      } else if (isElement(xpathNode, 'score-part')) {
        // get the attributes element of the first measure of the part
        final String partId = xpathNode.attr('id') ?? '';
        final MeiXmlNode? partFirstMeasure = xpathFirst(
            root, format("/score-partwise/part[@id='%s']/measure[1]", [partId]));
        if (partFirstMeasure == null ||
            !xpathExists(partFirstMeasure, 'attributes')) {
          logWarning('MusicXML import: Could not find the \'attributes\' '
              "element in the first measure of part '$partId'");
          continue;
        }
        // part-name should be revised, as soon MEI can suppress labels
        final String partName = getContentOfChild(
            xpathNode, "part-name[not(@print-object='no')]");
        final String partAbbr = getContentOfChild(
            xpathNode, "part-abbreviation[not(@print-object='no')]");
        final MeiXmlNode? midiInstrument = xpathNode.child('midi-instrument');
        if (partName.isNotEmpty && label == null) {
          label = Label();
          if (xpathExists(
              xpathNode, "part-name-display[not(@print-object='no')]")) {
            final String name = styleLabel(xpathNode.child('part-name-display')!);
            final Text text = Text();
            text.text = name;
            label!.addChild(text);
          } else {
            bool firstLine = true;
            for (final String line in splitLines(partName)) {
              if (!firstLine) {
                label!.addChild(Lb());
              }
              final Text text = Text();
              text.text = line;
              label!.addChild(text);
              firstLine = false;
            }
          }
        }
        if (partAbbr.isNotEmpty && labelAbbr == null) {
          labelAbbr = LabelAbbr();
          if (xpathExists(xpathNode,
              "part-abbreviation-display[not(@print-object='no')]")) {
            final String name =
                styleLabel(xpathNode.child('part-abbreviation-display')!);
            final Text text = Text();
            text.text = name;
            labelAbbr!.addChild(text);
          } else {
            bool firstLine = true;
            for (final String line in splitLines(partAbbr)) {
              if (!firstLine) {
                labelAbbr!.addChild(Lb());
              }
              final Text text = Text();
              text.text = line;
              labelAbbr!.addChild(text);
              firstLine = false;
            }
          }
        }
        if (midiInstrument != null && instrdef == null) {
          instrdef = InstrDef();
          instrdef!.midiInstrname =
              strToMidinames(getContent(midiInstrument.child('midi-name')));
          final MeiXmlNode? midiChannel = midiInstrument.child('midi-channel');
          if (midiChannel != null) {
            instrdef!.midiChannel = strToInt(getContent(midiChannel)) - 1;
          }
          final MeiXmlNode? midiProgram = midiInstrument.child('midi-program');
          if (midiProgram != null) {
            instrdef!.midiInstrnum = strToInt(getContent(midiProgram)) - 1;
          }
          final MeiXmlNode? midiVolume = midiInstrument.child('volume');
          if (midiVolume != null) {
            instrdef!.midiVolume = strToInt(getContent(midiVolume)).toDouble();
          }
        }
        // create the staffDef(s)
        final StaffGrp partStaffGrp = StaffGrp();
        partStaffGrp.n = partId;
        final int nbStaves = readMusicXmlPartAttributesAsStaffDef(
            partFirstMeasure, partStaffGrp, staffOffset);
        // if we have more than one staff in the part we create a new staffGrp
        if (nbStaves > 1) {
          partStaffGrp.barThru = true;
          if (staffGrpStack.last.getChild(0, ClassId.grpSym) == null) {
            final GrpSym partGrpSym = GrpSym();
            partGrpSym.symbol = StaffgroupingsymSymbol.brace;
            partStaffGrp.addChild(partGrpSym);
          }
          staffGrpStack.last.addChild(partStaffGrp);
        } else {
          staffGrpStack.last.moveChildrenFrom(partStaffGrp);
        }

        // find the part and read it
        final MeiXmlNode? part =
            xpathFirst(root, format("/score-partwise/part[@id='%s']", [partId]));
        if (part == null) {
          logWarning("MusicXML import: Could not find the part '$partId'");
          continue;
        }
        readMusicXmlPart(part, section, nbStaves, staffOffset);
        // increment the staffOffset for reading the next part
        staffOffset += nbStaves;
      } else {
        // do nothing
      }
    }
    // here we could check that there is only one staffGrp left in stack

    processClefChangeQueue(section);

    Measure? measure;
    for (final (String measureNum, ControlElement element) in controlElements) {
      if (measure == null || (measure.n != measureNum)) {
        final comparison = AttNNumberLikeComparison(ClassId.measure, measureNum);
        measure =
            section.findDescendantByComparison(comparison, deepness: 1) as Measure?;
      }
      if (measure == null) {
        logWarning("MusicXML import: Element '${element.className}' could not "
            "be added to measure $measureNum");
        continue;
      }
      measure.addChild(element);
    }

    // manage _sections: create new <section>/<ending> elements and move the
    // corresponding measures into them
    for (int i = 0; i < _sections.length;) {
      final List<Measure> measures = _sections[i].value;
      if (measures.isEmpty) {
        _sections.removeAt(i);
        continue;
      }

      Object target;
      if (_sections[i].key.classId == ClassId.ending) {
        final Ending ending = Ending();
        // some musicXML exporters tend to ignore the <ending> text, so take
        // @number instead.
        if (_sections[i].key.endingInfo.text.isEmpty) {
          ending.n = _sections[i].key.endingInfo.number;
        } else {
          ending.n = _sections[i].key.endingInfo.text;
        }
        ending.lendsym = Linestartendsymbol.angledown; // default
        if (_sections[i].key.endingInfo.type == 'discontinue') {
          ending.lendsym = Linestartendsymbol.none0; // no ending symbol
        }
        target = ending;
      } else {
        target = Section();
      }

      // remember the target for expansion
      _sections[i].key.target = target;
      // insert <section> / <ending> element ahead of first <measure>
      section.insertBefore(measures.first, target);
      // go through measures and move them into <section> / <ending>
      for (final Measure moveMeasure in measures) {
        // also move preceding non-measure siblings: keep stacking them in
        // reverse order then transfer them in score order
        Object? sibling = moveMeasure;
        final List<Object> siblings = [];
        while (true) {
          sibling = section.getPreviousSibling(sibling!);
          if (sibling == null) break;
          if (sibling.classId == ClassId.section ||
              sibling.classId == ClassId.ending) {
            break;
          }
          siblings.insert(0, sibling);
        }
        for (final Object s in siblings) {
          final int idx = section.getChildIndex(s);
          section.detachChild(idx);
          target.addChild(s);
        }
        final int idx = section.getChildIndex(moveMeasure);
        section.detachChild(idx);
        target.addChild(moveMeasure); // add <measure> to sub-element
      }

      ++i;
    }
    createExpansion(section);
    _sections.clear();

    // The top staffGrp cannot remain empty - add at least one staffDef
    if (staffGrp.childCount == 0) {
      final StaffDef staffDef = StaffDef();
      staffDef.n = 1;
      staffDef.lines = 5;
      staffGrp.addChild(staffDef);
    }

    // finalize document
    doc.expandExpansions();
    doc.convertToPageBasedDoc();
    doc.convertMarkupDoc(true);

    // clean up stacks
    if (_beamspanStack.isNotEmpty) {
      logWarning('MusicXML import: There are ${_beamspanStack.length} beamspans '
          'left without ending');
      _beamspanStack.clear();
    }
    if (_tieStack.isNotEmpty) {
      logWarning(
          'MusicXML import: There are ${_tieStack.length} ties left open');
      _tieStack.clear();
    }
    if (_slurStack.isNotEmpty) {
      // There are slurs left open
      for (final (_, _OpenSlur openSlur) in _slurStack) {
        logWarning('MusicXML import: slur ${openSlur.number} from measure '
            '${openSlur.measureNum} could not be ended');
      }
      _slurStack.clear();
    }
    if (_slurStopStack.isNotEmpty) {
      // There are slur ends without opening
      for (final (LayerElement element, _) in _slurStopStack) {
        logWarning("MusicXML import: slur ending for element '${element.id}' "
            'could not be matched to a start element');
      }
      _slurStopStack.clear();
    }
    if (glissStack.isNotEmpty) {
      for (final Gliss gliss in glissStack) {
        logWarning(
            "MusicXML import: gliss for '${gliss.id}' could not be closed");
      }
      glissStack.clear();
    }
    if (_trillStack.isNotEmpty) {
      // open trills without ending
      for (final (Trill trill, _) in _trillStack) {
        logWarning("MusicXML import: trill extender for '${trill.id}' could "
            'not be ended');
      }
      _trillStack.clear();
    }

    return true;
  }

  /// Iterate over the children of [root].child([name]) (empty when missing).
  static List<MeiXmlNode> childOfRoot(MeiXmlNode root, String name) {
    final MeiXmlNode? node = root.child(name);
    return node?.childrenElements() ?? const [];
  }

  /// Mirrors `CreateExpansion`.
  void createExpansion(Section section) {
    final Expansion expansion = Expansion();
    section.insertChild(expansion, 0);

    // iterate on _sections to create expansion
    // prepopulate the labels map because there are forward jumps (tocoda)
    bool jumpBack = false;
    final Map<String, int> labels = {};
    for (int i = 0; i < _sections.length; ++i) {
      if (_sections[i].key.label.isNotEmpty &&
          !labels.containsKey(_sections[i].key.label)) {
        labels[_sections[i].key.label] = i;
      }
    }
    int iter = 0;
    int rptIter = 0;
    int secIter = 0;
    int endIter = 0;
    while (iter >= 0 && iter < _sections.length) {
      // increment visited count
      _sections[iter].key.visited++;

      // remember this repeat start
      if (_sections[iter].key.repeatStart) rptIter = iter;

      // handle section
      if (_sections[iter].key.classId == ClassId.section) {
        // add the section
        String ref = '#${_sections[iter].key.target!.id}';
        expansion.addRefAllowDuplicate(ref);

        // repeat the _sections, beginning with the repeat start
        final int times = (jumpBack && !_sections[iter].key.repeatInfo.afterJump)
            ? 1
            : _sections[iter].key.repeatInfo.times;
        for (int t = 2; t <= times; ++t) {
          for (int it = rptIter; it <= iter; ++it) {
            ref = '#${_sections[it].key.target!.id}';
            expansion.addRefAllowDuplicate(ref);
          }
        }

        // remember last section
        secIter = endIter = iter++;
      }
      // ending
      else {
        // gather all endings by creating a map from ending number to index
        final SplayTreeMap<int, int> endings = SplayTreeMap<int, int>();
        final int begIter = iter;
        int? rptNested;
        while (iter < _sections.length &&
            _sections[iter].key.classId == ClassId.ending) {
          for (final int i in parseInts(_sections[iter].key.endingInfo.number)) {
            if (!endings.containsKey(i)) endings[i] = iter;
          }
          endIter = iter++;

          // remember a nested repeat start
          if (endIter != begIter && _sections[endIter].key.repeatStart) {
            rptNested = endIter;
          }

          // increment visited count of subsequent _sections
          if (endIter != begIter) _sections[endIter].key.visited++;
        }

        // when jumping back, keep only last ending
        if (jumpBack && endings.isNotEmpty) {
          final keys = endings.keys.toList();
          for (int k = 0; k < keys.length - 1; ++k) {
            endings.remove(keys[k]);
          }
          endIter = endings.values.first;
        }

        // the map is sorted by key (ending number), so just add them to the
        // expansion in the same order; skip section first time because it was
        // already added in the SECTION block
        bool firstEnding = true;
        for (final MapEntry<int, int> ending in endings.entries) {
          if (!firstEnding) {
            for (int it = rptIter; it <= secIter; ++it) {
              final String ref = '#${_sections[it].key.target!.id}';
              expansion.addRefAllowDuplicate(ref);
            }
          }
          firstEnding = false;
          final String endref = '#${_sections[ending.value].key.target!.id}';
          expansion.addRefAllowDuplicate(endref);
        }

        // set the repetition to the (latest) nested one
        if (rptNested != null) rptIter = rptNested;
      }

      // fine
      if (jumpBack && _sections[endIter].key._fineInfo.fine) {
        break;
      }

      // dacapo
      if (_sections[endIter].key._jumpInfo.jump == _JumpType.dacapo &&
          _sections[endIter].key._jumpInfo.times
              .contains(_sections[endIter].key.visited)) {
        iter = 0;
        jumpBack = true;
      }

      // dalsegno / tocoda
      if ((_sections[endIter].key._jumpInfo.jump == _JumpType.dalsegno ||
              _sections[endIter].key._jumpInfo.jump == _JumpType.tocoda) &&
          _sections[endIter].key._jumpInfo.times
              .contains(_sections[endIter].key.visited)) {
        final String jumpLabel = _sections[endIter].key._jumpInfo.label;
        if (!labels.containsKey(jumpLabel)) {
          logWarning(
              "MusicXML import: Segno/Coda label '$jumpLabel' not found");
        } else {
          iter = labels[jumpLabel]!;
          jumpBack =
              _sections[endIter].key._jumpInfo.jump == _JumpType.dalsegno;
        }
      }
    }
  }

  /// Mirrors `ReadMusicXmlTitle`.
  void readMusicXmlTitle(MeiXmlNode root) {
    final MeiXmlNode? workTitle =
        xpathFirst(root, '/score-partwise/work/work-title');
    final MeiXmlNode? movementTitle =
        xpathFirst(root, '/score-partwise/movement-title');
    final MeiXmlNode? workNumber =
        xpathFirst(root, '/score-partwise/work/work-number');
    final MeiXmlNode? movementNumber =
        xpathFirst(root, '/score-partwise/movement-number');

    // Attach the generated meiHead to the document header.
    dynamic header = doc.header;
    if (header is! MeiXmlNode || header.name != '#document') {
      header = MeiXmlNode.element('#document');
      doc.header = header;
    }
    final MeiXmlNode meiHead = MeiXmlNode.element('meiHead');
    header.appendChild(meiHead);

    // <fileDesc> /////////////
    final MeiXmlNode fileDesc = MeiXmlNode.element('fileDesc');
    meiHead.appendChild(fileDesc);
    final MeiXmlNode titleStmt = MeiXmlNode.element('titleStmt');
    fileDesc.appendChild(titleStmt);
    final MeiXmlNode meiTitle = MeiXmlNode.element('title');
    titleStmt.appendChild(meiTitle);
    if (movementTitle != null) {
      meiTitle.setTextValue(getContent(movementTitle));
    } else if (workTitle != null) {
      meiTitle.setTextValue(getContent(workTitle));
    }

    if (movementNumber != null) {
      final MeiXmlNode meiSubtitle = MeiXmlNode.element('title');
      titleStmt.appendChild(meiSubtitle);
      meiSubtitle.setTextValue(getContent(movementNumber));
      meiSubtitle.setAttribute('type', 'subordinate');
    } else if (workNumber != null) {
      final MeiXmlNode meiSubtitle = MeiXmlNode.element('title');
      titleStmt.appendChild(meiSubtitle);
      meiSubtitle.setTextValue(getContent(workNumber));
      meiSubtitle.setAttribute('type', 'subordinate');
    }

    final MeiXmlNode pubStmt = MeiXmlNode.element('pubStmt');
    fileDesc.appendChild(pubStmt);

    final MeiXmlNode respStmt = MeiXmlNode.element('respStmt');
    titleStmt.appendChild(respStmt);

    final List<MeiXmlNode> creators =
        xpathNodes(root, '/score-partwise/identification/creator');
    for (final MeiXmlNode creator in creators) {
      final MeiXmlNode persName = MeiXmlNode.element('persName');
      respStmt.appendChild(persName);
      persName.setTextValue(getContent(creator));
      persName.setAttribute('role', creator.attr('type') ?? '');
    }

    final List<MeiXmlNode> dateSet = xpathNodes(
        root, '/score-partwise/identification/encoding/encoding-date');
    for (final MeiXmlNode encodingDate in dateSet) {
      final MeiXmlNode date = MeiXmlNode.element('date');
      pubStmt.appendChild(date);
      date.setTextValue(getContent(encodingDate));
      date.setAttribute('isodate', getContent(encodingDate));
      date.setAttribute('type', encodingDate.name);
    }

    // Convert rights into availability
    final List<MeiXmlNode> rightsSet =
        xpathNodes(root, '/score-partwise/identification/rights');
    if (rightsSet.isNotEmpty) {
      final MeiXmlNode availability = MeiXmlNode.element('availability');
      pubStmt.appendChild(availability);
      for (final MeiXmlNode rights in rightsSet) {
        final MeiXmlNode distributor = MeiXmlNode.element('distributor');
        availability.appendChild(distributor);
        distributor.setTextValue(getContent(rights));
      }
    }

    final MeiXmlNode encodingDesc = MeiXmlNode.element('encodingDesc');
    meiHead.appendChild(encodingDesc);
    final MeiXmlNode appInfo = MeiXmlNode.element('appInfo');
    encodingDesc.appendChild(appInfo);
    final MeiXmlNode app = MeiXmlNode.element('application');
    appInfo.appendChild(app);
    final MeiXmlNode appName = MeiXmlNode.element('name');
    app.appendChild(appName);
    appName.setTextValue('Verovio');
    final MeiXmlNode appText = MeiXmlNode.element('p');
    app.appendChild(appText);
    appText.setTextValue('Transcoded from MusicXML');

    if (!_removeIdsOption()) {
      generateID(meiHead);
      generateID(fileDesc);
      generateID(titleStmt);
      generateID(pubStmt);
      generateID(encodingDesc);
      generateID(appInfo);
      generateID(app);
      generateID(appName);
      generateID(appText);
    }

    // isodate and version
    final DateTime now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    final String dateStr = '${now.year}-${two(now.month)}-${two(now.day)}'
        'T${two(now.hour)}:${two(now.minute)}:${two(now.second)}';
    app.setAttribute('isodate', dateStr);
    app.setAttribute('version', version);
  }

  /// Look up the `removeIds` option when available (mirrors
  /// `m_doc->GetOptions()->m_removeIds.GetValue()`); defaults to false so IDs
  /// are generated as in the C++ default configuration.
  bool _removeIdsOption() {
    try {
      final dynamic opts = doc.getOptions();
      final dynamic removeIds = opts.removeIds;
      return removeIds.value == true;
    } on NoSuchMethodError {
      return false;
    }
  }

  // =========================================================================
  // Part attributes as staffDef / meter signatures
  // =========================================================================

  /// Mirrors `ReadMusicXmlPartAttributesAsStaffDef`. Returns the number of
  /// staves in the part.
  int readMusicXmlPartAttributesAsStaffDef(
      MeiXmlNode node, StaffGrp staffGrp, int staffOffset) {
    // First get the number of staves in the part
    int nbStaves = 1;
    final MeiXmlNode? staves =
        xpathFirst(node, 'attributes[1]/staves');
    if (staves != null) {
      nbStaves = strToInt(getContent(staves));
    }
    if (nbStaves > 1) {
      if (label != null) staffGrp.addChild(label!);
      if (labelAbbr != null) staffGrp.addChild(labelAbbr!);
      if (instrdef != null) staffGrp.addChild(instrdef!);
      label = null;
      labelAbbr = null;
      instrdef = null;
    }

    for (final MeiXmlNode child in node.childrenElements()) {
      // We read all attribute elements until we reach something else.
      // barline, direction, print, and sound elements may be present.
      if (!isElement(child, 'attributes') &&
          !isElement(child, 'barline') &&
          !isElement(child, 'direction') &&
          !isElement(child, 'print') &&
          !isElement(child, 'sound')) {
        break;
      }

      // we do not want to read it again, just change the name
      if (isElement(child, 'attributes')) {
        child.name = 'mei-read';
      } else {
        continue;
      }

      String xpath;
      // Create as many staffDefs as needed
      for (int i = 0; i < nbStaves; ++i) {
        // Find or create the staffDef
        final comparisonStaffDef =
            AttNIntegerComparison(ClassId.staffDef, i + 1 + staffOffset);
        StaffDef? staffDef = staffGrp.findDescendantByComparison(
            comparisonStaffDef,
            deepness: 1) as StaffDef?;
        if (staffDef == null) {
          staffDef = StaffDef();
          staffDef.n = i + 1 + staffOffset;
          if (nbStaves == 1) {
            // Mirrors staffDef->SetID(staffGrp->GetID()).
            staffDef.id = staffGrp.id;
            if (label != null) staffDef.addChild(label!);
            if (labelAbbr != null) staffDef.addChild(labelAbbr!);
            if (instrdef != null) staffDef.addChild(instrdef!);
            label = null;
            labelAbbr = null;
            instrdef = null;
          }
          staffGrp.addChild(staffDef);
          // set initial octave shift
          octDis.add(0);
        }

        // clef sign - first look if we have a clef-sign with the corresponding
        // staff @number
        xpath = "clef[@number='${i + 1}']";
        MeiXmlNode? clefNode = xpathFirst(child, xpath);
        // if not, look at a common one
        if (clefNode == null) {
          clefNode = xpathFirst(child, 'clef[not(@number)]');
          if (nbStaves > 1 && clefNode != null && clefNode.hasAttr('id')) {
            clefNode.removeAttribute('id');
          }
        }
        final Clef? meiClef = convertClef(clefNode);
        if (meiClef != null) {
          staffDef.addChild(meiClef);
          // if TAB assume guitar tablature until we examine <staff-details>
          if (meiClef.shape == Clefshape.tab) {
            staffDef.notationtype = Notationtype.tabGuitar;
          }
        }

        // key sig
        xpath = "key[@number='${i + 1}']";
        MeiXmlNode? keyNode = xpathFirst(child, xpath);
        if (keyNode == null) {
          keyNode = xpathFirst(child, 'key[not(@number)]');
          if (nbStaves > 1 && keyNode != null && keyNode.hasAttr('id')) {
            keyNode.removeAttribute('id');
          }
        }
        if (keyNode != null) {
          final KeySig meiKey = convertKey(keyNode);
          staffDef.addChild(meiKey);
          if (staffDef.notationtype == Notationtype.tabGuitar) {
            meiKey.isAttribute = true;
          }
        }

        // staff details
        xpath = "staff-details[@number='${i + 1}']";
        MeiXmlNode? staffDetails = xpathFirst(child, xpath);
        staffDetails ??= xpathFirst(child, 'staff-details[not(@number)]');
        final int staffLines = staffDetails == null
            ? 0
            : strToInt(getContent(staffDetails.child('staff-lines')));
        if (staffLines != 0) {
          staffDef.lines = staffLines;
        } else if (!staffDef.hasLines) {
          staffDef.lines = 5;
        }
        final String scaleStr =
            getContent(staffDetails?.child('staff-size'));
        if (scaleStr.isNotEmpty) {
          staffDef.scale = strToPercent('$scaleStr%');
        }
        // Tablature?
        if ((staffDetails != null && staffDetails.child('staff-tuning') != null) ||
            staffDef.notationtype == Notationtype.tabGuitar) {
          // tablature type. MusicXML does not support German tablature.
          if (staffDetails != null &&
              hasAttributeWithValue(staffDetails, 'show-frets', 'letters')) {
            staffDef.notationtype = Notationtype.tabLuteFrench;
          } else {
            // Frets are notated with numbers.
            // Italian tablature if the top staff line has a lower pitch than
            // the bottom line, else guitar tablature.
            MeiXmlNode? topLine;
            MeiXmlNode? botLine;
            if (staffDetails != null) {
              for (final MeiXmlNode tuning
                  in staffDetails.childrenElements()) {
                if (tuning.name == 'staff-tuning' &&
                    tuning.attr('line') == '$staffLines') {
                  topLine = tuning;
                }
                if (tuning.name == 'staff-tuning' &&
                    tuning.attr('line') == '1') {
                  botLine = tuning;
                }
              }
            }
            if (topLine != null &&
                botLine != null &&
                pitchToMidi(
                        getContent(topLine.child('tuning-step')),
                        strToInt(getContent(topLine.child('tuning-alter'))),
                        strToInt(getContent(topLine.child('tuning-octave')))) <
                    pitchToMidi(
                        getContent(botLine.child('tuning-step')),
                        strToInt(getContent(botLine.child('tuning-alter'))),
                        strToInt(getContent(botLine.child('tuning-octave'))))) {
              staffDef.notationtype = Notationtype.tabLuteItalian;
            } else {
              staffDef.notationtype = Notationtype.tabGuitar;
            }
          }

          // MusicXML specifies the tuning of the staff rather than the
          // instrument, but this will at least give the tuning of some of the
          // courses. For French tablature MusicXML ought to allow zero and
          // negative values of @line to give the tuning for diapasons:
          // 0 => 7, -1 => 8 etc. But it doesn't. However, we can add the
          // tuning of diapasons as we encounter them in <note>s.
          final Tuning tuning = Tuning();
          staffDef.addChild(tuning);

          if (staffDetails != null) {
            for (final MeiXmlNode staffTuning
                in staffDetails.childrenElements()) {
              if (staffTuning.name != 'staff-tuning') continue;
              final Course courseTuning = Course();
              tuning.addChild(courseTuning);

              final int line = strToInt(staffTuning.attr('line') ?? '');
              final String stepStr = getContent(staffTuning.child('tuning-step'));
              final int alterNum =
                  strToInt(getContent(staffTuning.child('tuning-alter')));
              final int octaveNum =
                  strToInt(getContent(staffTuning.child('tuning-octave')));

              if (staffDef.notationtype == Notationtype.tabLuteItalian) {
                // Italian tablature, line 1 is course 1
                courseTuning.n = '$line';
              } else {
                // guitar and French tablature, line 1 is course =
                // staffLines (typically 6)
                courseTuning.n = '${staffLines - line + 1}';
              }
              courseTuning.pname = convertStepToPitchName(stepStr);
              courseTuning.oct = octaveNum;

              if (alterNum != 0) {
                courseTuning.accid = convertAlterToAccidWritten(alterNum.toDouble());
              }
            }
          }
        }

        // time
        xpath = "time[@number='${i + 1}']";
        MeiXmlNode? time = xpathFirst(child, xpath);
        if (time == null) {
          time = xpathFirst(child, 'time[not(@number)]');
          if (nbStaves > 1 && time != null && time.hasAttr('id')) {
            time.removeAttribute('id');
          }
        }
        if (time != null) {
          readMusicXMLMeterSig(time, staffDef);
        }

        // transpose
        xpath = "transpose[@number='${i + 1}']";
        MeiXmlNode? transpose = xpathFirst(child, xpath);
        transpose ??= xpathFirst(child, 'transpose');
        if (transpose != null) {
          staffDef.transDiat =
              strToInt(getContent(transpose.child('diatonic')));
          staffDef.transSemi =
              strToInt(getContent(transpose.child('chromatic')));
          if (transpose.child('octave-change') != null) {
            staffDef.transDiat = strToInt(getContent(transpose.child('chromatic'))) +
                7 * strToInt(getContent(transpose.child('octave-change')));
            staffDef.transSemi = strToInt(getContent(transpose.child('chromatic'))) +
                12 * strToInt(getContent(transpose.child('octave-change')));
          }
        }
        // ppq
        final MeiXmlNode? divisions = child.child('divisions');
        if (divisions != null) {
          ppq = strToInt(getContent(divisions));
          staffDef.ppq = ppq;
        }
        // measure style
        final MeiXmlNode? measureSlash =
            xpathFirst(child, 'measure-style/slash');
        if (measureSlash != null) {
          slash = hasAttributeWithValue(measureSlash, 'type', 'start');
        }
      }
    }

    return nbStaves;
  }

  /// Mirrors `ReadMusicXMLMeterSig`.
  void readMusicXMLMeterSig(MeiXmlNode time, Object parent) {
    final bool invisible = hasAttributeWithValue(time, 'print-object', 'no');
    if (xpathNodes(time, 'beats').length > 1 || time.child('interchangeable') != null) {
      final MeterSigGrp meterSigGrp = MeterSigGrp();
      if (time.hasAttr('id')) {
        // Mirrors SetID on a scoreDef element.
        (meterSigGrp as dynamic).id = time.attr('id')!;
      }
      final MeiXmlNode? interchangeable = time.child('interchangeable');
      meterSigGrp.func = interchangeable != null
          ? MetersiggrplogFunc.interchanging
          : MetersiggrplogFunc.mixed;

      final (List<int>, int) values = getMeterSigGrpValues(time, meterSigGrp);
      meterCount = values.$1;
      meterUnit = values.$2;
      if (interchangeable != null) {
        getMeterSigGrpValues(interchangeable, meterSigGrp);
      }
      if (invisible) {
        meterSigGrp.visible = false;
      }
      parent.addChild(meterSigGrp);
    } else {
      final MeterSig meterSig = MeterSig();
      if (time.hasAttr('id')) {
        (meterSig as dynamic).id = time.attr('id')!;
      }
      final String symbol = time.attr('symbol') ?? '';
      if (symbol.isNotEmpty) {
        if (symbol == 'cut' || symbol == 'common') {
          meterSig.sym = strToMetersign(symbol);
        } else if (symbol == 'single-number') {
          meterSig.form = Meterform.num;
        } else {
          meterSig.form = Meterform.norm;
        }
      }
      final MeiXmlNode? beats = time.child('beats');
      final MeiXmlNode? beatType = time.child('beat-type');
      if (beats != null) {
        final MeterCountPair pair = strToMetercountPair(getContent(beats));
        meterCount = [...pair.counts];
        meterSign = pair.sign;
        meterSig.count = MeterCountPair([...pair.counts], pair.sign);
        meterUnit = strToInt(getContent(beatType));
        meterSig.unit = meterUnit;
      } else if (time.child('senza-misura') != null) {
        if ((time.child('senza-misura')!.textValue() ?? '').isNotEmpty) {
          meterSig.sym = Metersign.open;
        } else {
          meterSig.visible = false;
        }
      }
      if (invisible) {
        meterSig.visible = false;
      }
      parent.addChild(meterSig);
    }
  }

  /// Mirrors `GetMeterSigGrpValues`. Returns total meterCount and meterUnit
  /// for the group.
  (List<int>, int) getMeterSigGrpValues(MeiXmlNode node, MeterSigGrp parent) {
    final List<MeiXmlNode> beats = xpathNodes(node, 'beats');
    final List<MeiXmlNode> beatTypes = xpathNodes(node, 'beat-type');
    int maxUnit = 0;
    final List<int> meterCounts = [];
    for (int i = 0;
        i < beats.length && i < beatTypes.length;
        ++i) {
      // Process current beat/beat-type combination and add it to the group
      final MeterSig meterSig = MeterSig();
      final MeterCountPair countPair =
          strToMetercountPair(getContent(beats[i]));
      meterSig.count = MeterCountPair([...countPair.counts], countPair.sign);
      final int currentUnit = strToInt(getContent(beatTypes[i]));
      meterSig.unit = currentUnit;
      parent.addChild(meterSig);
      List<int> currentCount = [...countPair.counts];
      // Process meterCount and meterUnit based on current/previous beats
      if (maxUnit == 0) maxUnit = currentUnit;
      if (maxUnit == currentUnit) {
        meterCounts.addAll(currentCount);
      } else if (maxUnit > currentUnit) {
        final int ratio = maxUnit ~/ currentUnit;
        currentCount = currentCount.map((elem) => elem * ratio).toList();
        meterCounts.addAll(currentCount);
      } else if (maxUnit < currentUnit) {
        final int ratio = currentUnit ~/ maxUnit;
        for (int k = 0; k < meterCounts.length; ++k) {
          meterCounts[k] *= ratio;
        }
        meterCounts.addAll(currentCount);
        maxUnit = currentUnit;
      }
    }

    return (meterCounts, maxUnit);
  }

  // =========================================================================
  // Part / measure
  // =========================================================================

  /// Mirrors `ReadMusicXmlPart`.
  bool readMusicXmlPart(
      MeiXmlNode node, Section section, int nbStaves, int staffOffset) {
    final List<MeiXmlNode> measures = xpathNodes(node, 'measure');
    if (measures.isEmpty) {
      logWarning('MusicXML import: No measure to load');
      return false;
    }

    int i = 0;
    for (final MeiXmlNode xmlMeasure in measures) {
      if (!isMultirestMeasure(i)) {
        final Measure measure = Measure();
        measureCounts[measure] = i;
        readMusicXmlMeasure(xmlMeasure, section, measure, nbStaves, staffOffset, i);
        // Add the measure to the section - if already there from a previous
        // part we'll just merge the content
        addMeasure(section, measure, i);
      } else {
        // Handle barline parsing for the multirests (where barline would be
        // defined in last measure of the mRest). If this is last measure,
        // find starting measure of the mRest (based on the index) and add
        // barline to it.
        int? lastIndex;
        Measure? startMeasure;
        multiRests.forEach((key, value) {
          if (value == i) {
            lastIndex = key;
          }
        });
        if (lastIndex != null) {
          measureCounts.forEach((measure, index) {
            if (index == lastIndex) {
              startMeasure = measure;
            }
          });
          if (startMeasure != null) {
            for (final MeiXmlNode child in xmlMeasure.childrenElements()) {
              if (isElement(child, 'barline')) {
                readMusicXmlBarLine(
                    child, startMeasure!, '$lastIndex');
              }
            }
          }
        }
      }
      ++i;
    }

    // clean up part specific stacks
    if (_openDashesStack.isNotEmpty) {
      // open dashes without ending
      for (final (ControlElement element, _) in _openDashesStack) {
        logWarning(
            "MusicXML import: dashes/extender lines for '${element.id}' could "
            'not be closed');
      }
      _openDashesStack.clear();
    }
    if (_bracketStack.isNotEmpty) {
      // open brackets without ending
      for (final (BracketSpan bracketSpan, _) in _bracketStack) {
        logWarning(
            "MusicXML import: bracketSpan for '${bracketSpan.id}' could not be "
            'closed');
      }
      _bracketStack.clear();
    }
    if (_hairpinStack.isNotEmpty) {
      logWarning('MusicXML import: There are ${_hairpinStack.length} hairpins '
          'left open');
      _hairpinStack.clear();
    }

    return false;
  }

  /// Mirrors `ReadMusicXmlMeasure`.
  bool readMusicXmlMeasure(MeiXmlNode node, Section section, Measure measure,
      int nbStaves, int staffOffset, int index) {
    // re-initialize the accidentals to the current key signature.
    resetAccidentals(currentKeySig);

    final String measureNum = node.attr('number') ?? '';
    if (node.hasAttr('id')) measure.id = node.attr('id')!;
    measure.n = measureNum;

    final bool implicit = node.attr('implicit') == 'true';
    if (implicit) {
      final MNum mNum = MNum();
      // An empty mNum means that we like to render this measure number as
      // blank.
      measure.addChild(mNum);
    }

    for (int i = 0; i < nbStaves; ++i) {
      // the staff @n must take into account the staffOffset
      final Staff staff = Staff();
      staff.n = i + 1 + staffOffset;
      staff.visible = convertWordToBool(getContent(
          node.child('attributes')?.child('staff-details')).isEmpty
          ? ''
          : (node.child('attributes')?.child('staff-details'))
                  ?.attr('print-object') ??
              '');
      measure.addChild(staff);
      // layers will be added in selectLayerFromNode
    }

    // Normally the stack should be empty.
    elementStackMap.clear();

    // reset measure time
    durTotal = 0;

    // reset clef changed flag
    clefChanged = 0;

    final int? mrestPosition = multiRests[index];
    final bool isMRestInOtherSystem = mrestPosition != null;
    int multiRestStaffNumber = 1;

    // read the content of the measure
    for (final MeiXmlNode child in node.childrenElements()) {
      // first check if there is a multi measure rest
      final MeiXmlNode? multiRestNode = xpathFirst(child, './/multiple-rest');
      if (multiRestNode != null) {
        final int multiRestLength = strToInt(getContent(multiRestNode));
        final String symbols = multiRestNode.attr('use-symbols') ?? '';
        final MultiRest multiRest = MultiRest();
        if (symbols == 'no') {
          // default by MusicXML specification
          multiRest.block = true;
        } else if (symbols == 'yes') {
          multiRest.block = false;
        }
        multiRest.num = multiRestLength;
        final Layer layer = selectLayerOfStaff(1, measure);
        addLayerElement(layer, multiRest);
        multiRests[index] = index + multiRestLength - 1;
        readMusicXmlAttributes(child, section, measure, measureNum);
        break;
      } else if (isMRestInOtherSystem) {
        if ((multiRestStaffNumber > 1) && !isElement(child, 'backup')) continue;
        final MultiRest multiRest = MultiRest();
        multiRest.num = mrestPosition - index + 1;
        final Layer layer = selectLayerOfStaff(multiRestStaffNumber, measure);
        addLayerElement(layer, multiRest);
        if (multiRestStaffNumber < nbStaves) multiRestStaffNumber++;
        continue;
      }
      if (isElement(child, 'attributes')) {
        readMusicXmlAttributes(child, section, measure, measureNum);
      } else if (isElement(child, 'backup')) {
        readMusicXmlBackup(child, measure, measureNum);
      } else if (isElement(child, 'barline')) {
        readMusicXmlBarLine(child, measure, measureNum);
      } else if (isElement(child, 'direction')) {
        readMusicXmlDirection(child, measure, measureNum, staffOffset, section);
      } else if (isElement(child, 'sound')) {
        readMusicXmlSound(child, measure, section);
      } else if (isElement(child, 'figured-bass')) {
        readMusicXmlFigures(child, measure, measureNum);
      } else if (isElement(child, 'forward')) {
        readMusicXmlForward(child, measure, measureNum);
      } else if (isElement(child, 'harmony')) {
        readMusicXmlHarmony(child, measure, measureNum);
      } else if (isElement(child, 'note')) {
        readMusicXmlNote(child, measure, measureNum, staffOffset, section);
      }
      // for now only check first part
      else if (isElement(child, 'print') &&
          xpathExists(node, 'parent::part[not(preceding-sibling::part)]')) {
        readMusicXmlPrint(child, section);
      }
    }

    // set metcon to false for pickup measures
    int measureTotal = ppq * 4;
    for (final int num in meterCount) {
      measureTotal *= num;
    }
    measureTotal ~/= meterUnit;
    if (durTotal != 0 && durTotal != measureTotal) {
      measure.metcon = false;
    }

    matchTies(true);
    if (_tieStack.isNotEmpty) matchTies(false);
    for (final _OpenTie openTie in _tieStack) {
      openTie.note!.setScoreTimeOnset(Fraction(-1)); // make onset small
    }

    // clear stop stacks after each measure
    _hairpinStopStack.clear();
    _tieStopStack.clear();

    for (final Object staffObject in measure.children) {
      if (staffObject.classId != ClassId.staff) continue;
      final Staff staff = staffObject as Staff;
      if (staff.childCount == 0) {
        // add a default layer, if staff completely empty at the end of a
        // measure.
        final Layer emptyLayer = Layer();
        emptyLayer.addChild(MSpace());
        staff.addChild(emptyLayer);
      }
    }

    // clear arpeggio stack so no other notes may be added.
    if (_arpeggioStack.isNotEmpty) _arpeggioStack.clear();

    // clear prevLayer
    prevLayer = null;

    // clear current layer
    isLayerInitialized = false;
    currentLayer = null;

    return true;
  }

  /// Mirrors `MatchTies`.
  void matchTies(bool matchLayers) {
    // match open ties with close ties
    for (int i = 0; i < _tieStack.length;) {
      bool tieMatched = false;
      int jter = -1;
      for (int j = 0; j < _tieStopStack.length; ++j) {
        // match tie stop with pitch/oct identity, with start note earlier than
        // end note, and with earliest end note.
        if (_tieStack[i].note != null &&
            isEnharmonicWith(_tieStopStack[j].note, _tieStack[i].note!) &&
            (_tieStack[i].note!.scoreTimeOnset <
                _tieStopStack[j].note.scoreTimeOnset) &&
            (!matchLayers ||
                (_tieStack[i].layerNum == _tieStopStack[j].layerNum))) {
          jter = j;
          break;
        }
      }
      if (jter != -1) {
        _tieStack[i].tie!.endid = '#${_tieStopStack[jter].note.id}';
        tieMatched = true;
      }
      if (tieMatched) {
        _tieStack.removeAt(i);
        _tieStopStack.removeAt(jter);
      } else {
        ++i;
      }
    }
  }

  // =========================================================================
  // Measure content: attributes / backup / barline
  // =========================================================================

  /// Mirrors `ReadMusicXmlAttributes`.
  void readMusicXmlAttributes(MeiXmlNode node, Section section,
      Measure measure, String measureNum) {
    bool divisionChange = false;

    // check for changes in divisions
    final MeiXmlNode? divisions = node.child('divisions');
    if (divisions != null) {
      // we'll only convert this to MEI if it actually changes
      divisionChange = ppq != strToInt(getContent(divisions));
      ppq = strToInt(getContent(divisions));
    }

    // read clef changes as MEI clef and add them to the stack
    for (final MeiXmlNode clef in node.childrenElements()) {
      if (clef.name != 'clef') continue;
      // check if we have a staff number
      int staffNum = strToInt(clef.attr('number') ?? '');
      if (staffNum < 1) staffNum = 1;
      final Staff? staff = measure.getChild(staffNum - 1, ClassId.staff) as Staff?;
      assert(staff != null);
      final Clef? meiClef = convertClef(clef);
      if (meiClef != null) {
        final bool afterBarline = clef.attr('after-barline') == 'true';
        _clefChangeQueue.add(_ClefChange(
            measureNum, staff!, currentLayer, meiClef, durTotal, afterBarline));
        clefChanged++;
      }
    }

    // key and time change
    final MeiXmlNode? key = node.child('key');
    final MeiXmlNode? time = node.child('time');

    // for now only read first key change in first part and update scoreDef
    final bool isFirstPart =
        xpathExists(node, 'ancestor::part[not(preceding-sibling::part)]');
    final bool hasPrecedingKey =
        xpathExists(node, 'preceding-sibling::attributes/key');
    if ((key != null || time != null || divisionChange) &&
        isFirstPart &&
        !hasPrecedingKey) {
      final ScoreDef? scoreDef = getOrCreateLastScoreDef(section);
      assert(scoreDef != null);
      if (key != null) {
        final KeySig meiKey = convertKey(key);
        scoreDef!.addChild(meiKey);
      }

      if (time != null) {
        readMusicXMLMeterSig(time, scoreDef!);
      }

      if (divisions != null) {
        scoreDef!.ppq = strToInt(getContent(divisions));
      }
    } else if (time != null &&
        xpathExists(node, 'ancestor::part[(preceding-sibling::part)]')) {
      meterUnit = strToInt(getContent(time.child('beat-type')));
    }

    final MeiXmlNode? measureRepeat = xpathFirst(node, 'measure-style/measure-repeat');
    final MeiXmlNode? measureSlash = xpathFirst(node, 'measure-style/slash');
    if (measureRepeat != null) {
      mRpt = hasAttributeWithValue(measureRepeat, 'type', 'start');
    }
    if (measureSlash != null) {
      slash = hasAttributeWithValue(measureSlash, 'type', 'start');
    }
  }

  /// Mirrors `ReadMusicXmlBackup`.
  void readMusicXmlBackup(
      MeiXmlNode node, Measure measure, String measureNum) {
    durTotal -= strToInt(getContent(node.child('duration')));

    isLayerInitialized = false;
  }

  /// Mirrors `ReadMusicXmlBarLine`.
  void readMusicXmlBarLine(
      MeiXmlNode node, Measure measure, String measureNum) {
    final Staff staff = measure.getFirst(ClassId.staff) as Staff;

    final String barStyle = getContent(node.child('bar-style'));
    final MeiXmlNode? repeat = xpathFirst(node, 'repeat');
    int repeatTimes = 1;
    bool repeatAfterJump = false;
    if (repeat != null) {
      // Mirrors pugixml as_int(default): parse the leading integer, fall back
      // to the default when no conversion is possible.
      final String timesValue = repeat.attr('times') ?? '';
      repeatTimes = RegExp(r'^\s*[+-]?\d').hasMatch(timesValue)
          ? strToInt(timesValue)
          : 2;
      repeatAfterJump = repeat.attr('after-jump') == 'true';
    }
    if (barStyle.isNotEmpty) {
      final Barrendition barRendition = convertStyleToRend(barStyle, repeat != null);
      if (hasAttributeWithValue(node, 'location', 'left')) {
        measure.left = barRendition;
      } else if (hasAttributeWithValue(node, 'location', 'middle')) {
        final BarLine barLine = BarLine();
        barLine.color = node.child('bar-style')?.attr('color');
        barLine.form = barRendition;
        final Layer layer = selectLayerFromNode(node, measure);
        addLayerElement(layer, barLine);
      } else {
        measure.right = barRendition;
        if (barStyle == 'short' || barStyle == 'tick') {
          measure.barLen = 4;
          if (barStyle == 'short') {
            measure.barPlace = 2;
          } else {
            // bar.place counts in note order (high values are vertically
            // higher).
            measure.barPlace = 6;
          }
        }
      }
    }
    if (barStyle.isEmpty && repeat != null) {
      // add repeat information, also when bar-style is not provided
      if (hasAttributeWithValue(node, 'location', 'left')) {
        measure.left = Barrendition.rptstart;
      } else if (hasAttributeWithValue(node, 'location', 'middle')) {
        logWarning("MusicXML import: Unsupported barline location 'middle' "
            'in ${measure.n}');
      } else {
        measure.right = Barrendition.rptend;
      }
    }

    // start or end section
    if (measure.left == Barrendition.rptstart) {
      if (_sectionStart == null || !_sectionStart!.repeatStart) {
        _sectionStart = _SectionInfo(true);
      }
    }
    if (measure.right == Barrendition.rptend) {
      _sectionStop = _SectionInfo.repeat(_RepeatInfo(repeatTimes, repeatAfterJump));
    }

    // parse endings (prima volta, seconda volta...)
    final MeiXmlNode? ending = node.child('ending');
    if (ending != null) {
      final String endingNumber = ending.attr('number') ?? '';
      final String endingType = ending.attr('type') ?? '';
      final String endingText = getContent(ending);
      if (endingType == 'start') {
        // check for corresponding stop points
        final bool hasEndingEnd = xpathExists(
            rootOfNode(node),
            format(
                "/score-partwise/part/measure/barline/ending[@number='%s'][@type != 'start']",
                [endingNumber]));
        if (hasEndingEnd) {
          _sectionStart ??= _SectionInfo();
          _sectionStart!.mergeEnding(
              _EndingInfo()
                ..number = endingNumber
                ..type = endingType
                ..text = endingText);
        }
      } else if (endingType == 'stop' || endingType == 'discontinue') {
        if (_sections.isEmpty) {
          logWarning('MusicXML import: Dangling ending tag skipped');
        } else {
          _sectionStop ??= _SectionInfo();
          _sectionStop!.mergeEnding(_EndingInfo()
            ..number = endingNumber
            ..type = endingType
            ..text = endingText);
        }
      }
    }

    // fermatas
    int fermataCounter = 0;
    for (final MeiXmlNode xmlFermata in node.childrenElements()) {
      if (xmlFermata.name != 'fermata') continue;
      ++fermataCounter;
      final Fermata fermata = Fermata();
      controlElements.add((measureNum, fermata));
      if (hasAttributeWithValue(node, 'location', 'left')) {
        fermata.tstamp = 0.0;
      } else if (hasAttributeWithValue(node, 'location', 'middle')) {
        logWarning("MusicXML import: Unsupported barline location 'middle'");
      } else {
        fermata.tstamp = durTotal * meterUnit / (4 * ppq) + 1.0;
      }
      if (xmlFermata.hasAttr('id')) fermata.id = xmlFermata.attr('id')!;

      if (fermataCounter < 2) {
        fermata.staff = [staff.n ?? 0];
      } else {
        final Staff? lastStaff = measure.getLast() as Staff?;
        assert(lastStaff != null);
        fermata.staff = [lastStaff!.n ?? 0];
      }

      shapeFermata(fermata, xmlFermata);
    }
  }

  /// The document wrapper of a node (used for absolute ending searches).
  static MeiXmlNode rootOfNode(MeiXmlNode node) {
    MeiXmlNode top = node;
    while (top.parent != null) {
      top = top.parent!;
    }
    return top;
  }

  // =========================================================================
  // Direction
  // =========================================================================

  /// Mirrors `ReadMusicXmlDirection`.
  void readMusicXmlDirection(MeiXmlNode node, Measure measure,
      String measureNum, int staffOffset, Section section) {
    final String placeStr = node.attr('placement') ?? '';

    final MeiXmlNode? typeNode = node.child('direction-type');
    final MeiXmlNode? voice = xpathFirst(node, 'voice');
    final MeiXmlNode? offsetNode = node.child('offset');
    final int offset = offsetNode != null ? strToInt(getContent(offsetNode)) : 0;
    final MeiXmlNode? staffNode = node.child('staff');
    final MeiXmlNode? soundNode = node.child('sound');

    final double timeStamp = (durTotal + offset) * meterUnit / (4 * ppq) + 1.0;

    if (voice != null) prevLayer = selectLayerFromNode(node, measure);

    if (typeNode == null) return;

    // Bracket
    final MeiXmlNode? bracket = typeNode.child('bracket');
    if (bracket != null) {
      int voiceNumber = strToInt(bracket.attr('number') ?? '');
      if (voiceNumber < 1) voiceNumber = 1;
      if (hasAttributeWithValue(bracket, 'type', 'stop')) {
        if (_bracketStack.isEmpty) {
          // if this is empty, most likely we're dealing with an extender
        } else {
          final int measureDifference =
              measureCounts[measure]! - _bracketStack.first.$2.lastMeasureCount;
          _bracketStack.first.$1.lendsym =
              convertLineEndSymbol(bracket.attr('line-end') ?? '');
          if (measureDifference >= 0) {
            _bracketStack.first.$1.tstamp2 =
                MeasureBeat(measureDifference, timeStamp);
          }
          _bracketStack.removeAt(0);
        }
      } else {
        final BracketSpan bracketSpan = BracketSpan();
        final _OpenSpanner openBracket =
            _OpenSpanner(voiceNumber, measureCounts[measure]!);
        bracketSpan.color = bracket.attr('color');
        bracketSpan.lform = strToLineform(bracket.attr('line-type') ?? '');
        bracketSpan.func = BracketspanlogFunc.uspecified;
        bracketSpan.lstartsym = convertLineEndSymbol(bracket.attr('line-end') ?? '');
        bracketSpan.tstamp = timeStamp;
        controlElements.add((measureNum, bracketSpan));
        _bracketStack.add((bracketSpan, openBracket));
      }
    }

    // Dashes (to be connected with previous <dir> or <dynam> as @extender and
    // @tstamp2 attributes)
    final MeiXmlNode? dashes =
        xpathFirst(typeNode, 'bracket|dashes');
    if (dashes != null && !identical(dashes, bracket)) {
      int dashesNumber = strToInt(dashes.attr('number') ?? '');
      if (dashesNumber < 1) dashesNumber = 1;
      int staffNum = 1;
      if (staffNode != null) staffNum = strToInt(getContent(staffNode)) + staffOffset;
      if (hasAttributeWithValue(dashes, 'type', 'stop')) {
        for (int i = 0; i < _openDashesStack.length;) {
          final (ControlElement element, _OpenDashes openDashes) =
              _openDashesStack[i];
          if (openDashes.dirN == dashesNumber &&
              openDashes.staffNum == staffNum) {
            final int measureDifference =
                measureCounts[measure]! - openDashes.measureCount;
            if (measureDifference >= 0) {
              if (element.classId == ClassId.dynam) {
                (element as Dynam).tstamp2 = MeasureBeat(measureDifference, timeStamp);
              }
              if (element.classId == ClassId.dir) {
                (element as Dir).tstamp2 = MeasureBeat(measureDifference, timeStamp);
              }
            }
            _openDashesStack.removeAt(i);
          } else {
            ++i;
          }
        }
      } else if (dashes.name.startsWith('dashes')) {
        ControlElement? controlElement;
        // find last ControlElement of type dynam or dir and activate extender
        // this is bad MusicXML and shouldn't happen
        for (int i = controlElements.length - 1; i >= 0; --i) {
          final (String num, ControlElement candidate) = controlElements[i];
          if (candidate.classId == ClassId.dynam) {
            final Dynam dynam = candidate as Dynam;
            final List<int>? staffAttr = dynam.staff;
            if ((staffAttr?.contains(staffNum + staffOffset) ?? false) &&
                dynam.place == strToStaffrel(placeStr) &&
                num == measureNum) {
              dynam.extender = true;
              controlElement = dynam;
              break;
            }
          } else if (candidate.classId == ClassId.dir) {
            final Dir dir = candidate as Dir;
            final List<int>? staffAttr = dir.staff;
            if ((staffAttr?.contains(staffNum + staffOffset) ?? false) &&
                dir.place == strToStaffrel(placeStr) &&
                num == measureNum) {
              dir.extender = true;
              controlElement = dir;
              break;
            }
          }
        }
        if (controlElement != null) {
          final _OpenDashes openDashes =
              _OpenDashes(dashesNumber, staffNum, measureCounts[measure]!);
          _openDashesStack.add((controlElement, openDashes));
        } else {
          logInfo('MusicXmlImport: dashes could not be matched to <dir> or '
              '<dynam> in measure $measureNum.');
        }
      }
    }

    final List<MeiXmlNode> words = xpathNodes(node, 'direction-type/words');
    final bool containsWords = words.isNotEmpty;
    final MeiXmlNode? dynamicsNode = xpathFirst(node, 'direction-type/dynamics');
    bool containsDynamics = dynamicsNode != null ||
        (soundNode?.hasAttr('dynamics') ?? false);
    final bool metronomeVisible =
        xpathExists(node, "direction-type/metronome[not(@print-object='no')]");
    bool containsTempo = metronomeVisible ||
        (soundNode?.hasAttr('tempo') ?? false);

    // Directive
    int defaultY = 0; // y position attribute, only for directives and dynamics
    if (containsWords && !containsTempo && !containsDynamics) {
      final List<MeiXmlNode> wordNodes = xpathNodes(
          node, 'direction-type/*[self::words or self::symbol or self::coda or self::segno]');
      defaultY = strToInt(wordNodes.first.attr('default-y') ?? '');
      defaultY = (defaultY * 10) + strToInt(wordNodes.first.attr('relative-y') ?? '');
      final String wordStr = getContent(wordNodes.first);
      if (wordStr.startsWith('cresc') ||
          wordStr.startsWith('dim') ||
          wordStr.startsWith('decresc')) {
        containsDynamics = true;
      } else {
        final Dir dir = Dir();
        if (wordNodes.length == 1) {
          dir.lang = wordNodes.first.attr('xml:lang') ?? '';
        }
        dir.place = strToStaffrel(placeStr);
        dir.tstamp = timeStamp;
        if (soundNode != null && soundNode.attributes.isNotEmpty) {
          dir.type = soundNode.attributes.keys.first;
        }
        if (staffNode != null) {
          dir.staff =
              [strToInt(getContent(staffNode)) + staffOffset];
        } else if (prevLayer != null) {
          dir.staff = [(prevLayer!.parent as Staff).n ?? 0];
        } else {
          dir.staff = [1 + staffOffset];
        }

        textRendition(wordNodes, dir);
        if (defaultY != 0) {
          defaultY = (defaultY < 0) ? defaultY.abs() : defaultY + 2000;
          dir.vgrp = defaultY;
        }
        controlElements.add((measureNum, dir));
        dirStack.add(dir);

        final MeiXmlNode? nextType =
            nextSiblingNamed(wordNodes.last.parent ?? node, 'direction-type');
        final MeiXmlNode? extender = nextType?.firstChild();
        if (extender != null &&
            (extender.name == 'bracket' || extender.name == 'dashes')) {
          int extNumber = strToInt(extender.attr('number') ?? '');
          if (extNumber < 1) extNumber = 1;
          int staffNum = strToInt(getContent(staffNode)) + staffOffset;
          if (staffNum < 1) staffNum = 1;
          dir.extender = true;
          if (extender.name.startsWith('bracket')) {
            dir.lform = strToLineform(extender.attr('line-type') ?? '');
          } else {
            dir.lform = Lineform.dashed;
          }
          final _OpenDashes openDashes =
              _OpenDashes(extNumber, staffNum, measureCounts[measure]!);
          _openDashesStack.add((dir, openDashes));
        }
      }
    }

    // Coda & Segno
    final MeiXmlNode? xmlJump = xpathFirst(typeNode, 'coda|segno');
    if (xmlJump != null && !containsWords) {
      final RepeatMark mark = RepeatMark();
      mark.place = strToStaffrel(placeStr);
      mark.tstamp = timeStamp;
      mark.func = convertJumpType(xmlJump.name);
      mark.staff = const [1];
      if (xmlJump.hasAttr('smufl')) {
        mark.glyphAuth = 'smufl';
        mark.glyphName = xmlJump.attr('smufl')!;
      }
      if (xmlJump.hasAttr('id')) mark.id = xmlJump.attr('id')!;
      controlElements.add((measureNum, mark));
    }

    // Dynamics
    if (containsDynamics) {
      final List<MeiXmlNode> dynamicsNodes = xpathNodes(
          node,
          containsWords
              ? 'direction-type/dynamics|direction-type/words'
              : 'direction-type/dynamics');

      sortInDocumentOrder(dynamicsNodes);

      final Dynam dynam = Dynam();
      dynam.place = strToStaffrel(placeStr);
      dynam.tstamp = timeStamp;
      if (staffNode != null) {
        dynam.staff = [strToInt(getContent(staffNode)) + staffOffset];
      } else if (prevLayer != null) {
        dynam.staff = [(prevLayer!.parent as Staff).n ?? 0];
      } else {
        dynam.staff = [1 + staffOffset];
      }

      if (soundNode != null) {
        final double soundDynamics =
            strToDblPrefix(soundNode.attr('dynamics') ?? '-1');
        if (soundDynamics >= 0.0) {
          dynam.val = convertDynamicsToMidiVal(soundDynamics);
        }
      }

      textRendition(dynamicsNodes, dynam);
      if (defaultY == 0 && dynamicsNodes.isNotEmpty) {
        defaultY = strToInt(dynamicsNodes.first.attr('default-y') ?? '');
        defaultY = (defaultY * 10) + strToInt(dynamicsNodes.first.attr('relative-y') ?? '');
      }
      // parse the default_y attribute and transform to vgrp value, to
      // vertically align dynamics and directives
      defaultY = (defaultY < 0) ? defaultY.abs() : defaultY + 2000;
      dynam.vgrp = defaultY;
      controlElements.add((measureNum, dynam));
      dynamStack.add(dynam);

      if (dynamicsNodes.isNotEmpty) {
        final MeiXmlNode? nextType = nextSiblingNamed(
            dynamicsNodes.last.parent ?? dynamicsNodes.first, 'direction-type');
        final MeiXmlNode? extender = nextType?.firstChild();
        if (extender != null &&
            (extender.name == 'bracket' || extender.name == 'dashes')) {
          int extNumber = strToInt(extender.attr('number') ?? '');
          if (extNumber < 1) extNumber = 1;
          int staffNum = strToInt(getContent(staffNode)) + staffOffset;
          if (staffNum < 1) staffNum = 1;
          dynam.extender = true;
          if (extender.name.startsWith('bracket')) {
            dynam.lform = strToLineform(extender.attr('line-type') ?? '');
          } else {
            dynam.lform = Lineform.dashed;
          }
          final _OpenDashes openDashes =
              _OpenDashes(extNumber, staffNum, measureCounts[measure]!);
          _openDashesStack.add((dynam, openDashes));
        }
      }
    }

    // Hairpins
    final List<MeiXmlNode> wedges = xpathNodes(node, 'direction-type/wedge');
    for (final MeiXmlNode wedge in wedges) {
      int hairpinNumber = strToInt(wedge.attr('number') ?? '');
      if (hairpinNumber < 1) hairpinNumber = 1;
      bool matchedWedge = false;
      if (hasAttributeWithValue(wedge, 'type', 'stop')) {
        // match wedge type=stop to open hairpin
        for (int i = 0; i < _hairpinStack.length; ++i) {
          final (Hairpin hairpin, _OpenSpanner openHairpin) = _hairpinStack[i];
          if (openHairpin.dirN == hairpinNumber) {
            final int measureDifference =
                measureCounts[measure]! - openHairpin.lastMeasureCount;
            if (measureDifference >= 0) {
              hairpin.tstamp2 = MeasureBeat(measureDifference, timeStamp);
            }
            if (wedge.hasAttr('niente')) {
              hairpin.niente = convertWordToBool(wedge.attr('niente') ?? '');
            }
            if (hairpin.form == HairpinlogForm.cres) {
              if (wedge.hasAttr('spread')) {
                final MeasurementSigned opening = MeasurementSigned();
                opening.setVu(strToDblPrefix(wedge.attr('spread') ?? '') / 5);
                hairpin.opening = opening;
              }
            }
            matchedWedge = true;
            _hairpinStack.removeAt(i);
            break;
          }
        }
        if (!matchedWedge) {
          _hairpinStopStack.add((
            0,
            timeStamp,
            _OpenSpanner(hairpinNumber, measureCounts[measure]!)
          ));
        }
      } else {
        final Hairpin hairpin = Hairpin();
        final _OpenSpanner openHairpin =
            _OpenSpanner(hairpinNumber, measureCounts[measure]!);
        if (hasAttributeWithValue(wedge, 'type', 'crescendo')) {
          hairpin.form = HairpinlogForm.cres;
        } else if (hasAttributeWithValue(wedge, 'type', 'diminuendo')) {
          hairpin.form = HairpinlogForm.dim;
          if (wedge.hasAttr('spread')) {
            final MeasurementSigned opening = MeasurementSigned();
            opening.setVu(strToDblPrefix(wedge.attr('spread') ?? '') / 5);
            hairpin.opening = opening;
          }
        } else {
          continue;
        }
        hairpin.lform = strToLineform(wedge.attr('line-type') ?? '');
        if (wedge.hasAttr('niente')) {
          hairpin.niente = convertWordToBool(wedge.attr('niente') ?? '');
        }
        hairpin.color = wedge.attr('color');
        hairpin.place = strToStaffrel(placeStr);
        hairpin.tstamp = timeStamp;
        if (wedge.hasAttr('id')) hairpin.id = wedge.attr('id')!;
        if (staffNode != null) {
          hairpin.staff = [strToInt(getContent(staffNode)) + staffOffset];
        } else if (prevLayer != null) {
          hairpin.staff = [(prevLayer!.parent as Staff).n ?? 0];
        } else {
          hairpin.staff = [1 + staffOffset];
        }
        int defaultYWedge = strToInt(wedge.attr('default-y') ?? '');
        defaultYWedge =
            (defaultYWedge * 10) + strToInt(wedge.attr('relative-y') ?? '');
        // parse the default_y attribute and transform to vgrp value, to
        // vertically align hairpins
        defaultYWedge =
            (defaultYWedge < 0) ? defaultYWedge.abs() : defaultYWedge + 2000;
        hairpin.vgrp = defaultYWedge;
        // match new hairpin to existing hairpin stop
        for (int i = 0; i < _hairpinStopStack.length; ++i) {
          final (int _, double stopStamp, _OpenSpanner stopSpanner) =
              _hairpinStopStack[i];
          final int measureDifference =
              stopSpanner.lastMeasureCount - measureCounts[measure]!;
          if (stopSpanner.dirN == hairpinNumber && measureDifference == 0) {
            if (measureDifference >= 0) {
              hairpin.tstamp2 = MeasureBeat(measureDifference, stopStamp);
              controlElements.add((measureNum, hairpin));
            }
            matchedWedge = true;
            _hairpinStopStack.removeAt(i);
            break;
          }
        }
        if (!matchedWedge) {
          controlElements.add((measureNum, hairpin));
          _hairpinStack.add((hairpin, openHairpin));
        }
      }
    }

    // Ottava
    final MeiXmlNode? xmlShift = typeNode.child('octave-shift');
    if (xmlShift != null) {
      final int staffNum = (staffNode == null)
          ? 1
          : strToInt(getContent(staffNode)) + staffOffset;
      if (octDis.length <= staffNum) {
        octDis.length = staffNum + 1;
        for (int i = 0; i < octDis.length; ++i) {
          octDis[i] = 0;
        }
      }
      if (hasAttributeWithValue(xmlShift, 'type', 'stop')) {
        octDis[staffNum] = 0;
        for (final (String _, ControlElement iter) in controlElements) {
          if (iter.classId == ClassId.octave) {
            final Octave octave = iter as Octave;
            if (octave.endid != null) continue;
            final List<int>? staffAttr = octave.staff;
            if (staffAttr?.contains(staffNum) ?? false) {
              octave.endid = id;
            } else if (xmlShift.attr('number') == octave.n) {
              octave.endid = id;
            } else {
              logWarning(
                  "MusicXML import: octave for '${octave.id}' could not be closed");
            }
          }
        }
      } else {
        final Octave octave = Octave();
        octave.color = xmlShift.attr('color');
        octave.disPlace = strToStaffrelBasic(placeStr);
        octave.n = xmlShift.attr('number') ?? '';
        final int octDisNum = xmlShift.hasAttr('size')
            ? strToInt(xmlShift.attr('size') ?? '')
            : 8;
        octave.dis = strToOctaveDis('$octDisNum');
        octDis[staffNum] = (octDisNum + 2) ~/ 8;
        if (hasAttributeWithValue(xmlShift, 'type', 'up')) {
          octave.disPlace = StaffrelBasic.below;
          octDis[staffNum] *= -1;
        } else {
          octave.disPlace = StaffrelBasic.above;
        }
        controlElements.add((measureNum, octave));
        octaveStack.add(octave);
      }
    }

    // Pedal
    final MeiXmlNode? xmlPedal = typeNode.child('pedal');
    if (xmlPedal != null) {
      final String pedalType = xmlPedal.attr('type') ?? '';
      final bool pedalLine = xmlPedal.attr('line') == 'true';
      if (pedalType != 'continue') {
        final Pedal pedal = Pedal();
        pedal.color = xmlPedal.attr('color');
        if (placeStr.isNotEmpty) pedal.place = strToStaffrel(placeStr);
        pedal.dir = convertPedalTypeToDir(pedalType);
        if (pedalLine) pedal.form = Pedalstyle.line;
        if (xmlPedal.hasAttr('abbreviated')) {
          pedal.glyphAuth = 'smufl';
          setExternalSymbols(pedal, 'glyph.num', 'U+E651');
        }
        if (pedalType == 'sostenuto') {
          pedal.func = 'sostenuto';
          if (xmlPedal.hasAttr('abbreviated')) {
            pedal.glyphAuth = 'smufl';
            setExternalSymbols(pedal, 'glyph.num', 'U+E65A');
          }
        }
        if (staffNode != null) {
          pedal.staff = [strToInt(getContent(staffNode)) + staffOffset];
        } else if (prevLayer != null) {
          pedal.staff = [(prevLayer!.parent as Staff).n ?? 0];
        } else {
          pedal.staff = [1 + staffOffset];
        }
        pedal.tstamp = timeStamp;
        if (pedalType == 'stop') pedal.tstamp = timeStamp - 0.1;
        int defaultYPedal = strToInt(xmlPedal.attr('default-y') ?? '');
        defaultYPedal =
            (defaultYPedal * 10) + strToInt(xmlPedal.attr('relative-y') ?? '');
        // parse the default_y attribute and transform to vgrp value, to
        // vertically align pedal starts and stops
        defaultYPedal =
            (defaultYPedal < 0) ? defaultYPedal.abs() : defaultYPedal + 2000;
        pedal.vgrp = defaultYPedal;
        controlElements.add((measureNum, pedal));
        pedalStack.add(pedal);
      }
    }

    // Principal voice
    final MeiXmlNode? lead = typeNode.child('principal-voice');
    if (lead != null) {
      int voiceNumber = strToInt(lead.attr('number') ?? '');
      if (voiceNumber < 1) voiceNumber = 1;
      if (hasAttributeWithValue(lead, 'type', 'stop')) {
        if (_bracketStack.isNotEmpty) {
          final int measureDifference =
              measureCounts[measure]! - _bracketStack.first.$2.lastMeasureCount;
          if (measureDifference >= 0) {
            _bracketStack.first.$1.tstamp2 =
                MeasureBeat(measureDifference, timeStamp);
          }
          _bracketStack.removeAt(0);
        }
      } else {
        final BracketSpan bracketSpan = BracketSpan();
        final _OpenSpanner openBracket =
            _OpenSpanner(voiceNumber, measureCounts[measure]!);
        bracketSpan.color = lead.attr('color');
        bracketSpan.func = BracketspanlogFunc.analytical;
        bracketSpan.lstartsym = convertLineEndSymbol(lead.attr('symbol') ?? '');
        bracketSpan.tstamp = timeStamp;
        bracketSpan.type = 'principal-voice';
        controlElements.add((measureNum, bracketSpan));
        _bracketStack.add((bracketSpan, openBracket));
      }
    }

    // Rehearsal
    final MeiXmlNode? rehearsal = typeNode.child('rehearsal');
    if (rehearsal != null) {
      final Reh reh = Reh();
      reh.place = strToStaffrel(placeStr);
      final String halign = rehearsal.attr('halign') ?? '';
      final String lang =
          rehearsal.hasAttr('xml:lang') ? rehearsal.attr('xml:lang')! : 'it';
      final String textStr = getContent(rehearsal);
      reh.color = rehearsal.attr('color');
      int staffNum = strToInt(getContent(staffNode)) + staffOffset;
      if (staffNum < 1) staffNum = 1;
      reh.staff = [staffNum];
      reh.lang = lang;
      final Rend rend = Rend();
      rend.fontweight = strToFontweight(rehearsal.attr('font-weight') ?? '');
      rend.halign = strToHorizontalalignment(halign);
      final String enclosure = rehearsal.attr('enclosure') ?? '';
      rend.rend =
          enclosure.isEmpty ? Textrendition.box : convertEnclosure(enclosure);
      final Text text = Text();
      text.text = textStr;
      rend.addChild(text);
      reh.addChild(rend);
      controlElements.add((measureNum, reh));
    }

    // Tempo
    if (containsTempo) {
      final Tempo tempo = Tempo();
      if (words.isNotEmpty) {
        final String lang = words.first.hasAttr('xml:lang')
            ? words.first.attr('xml:lang')!
            : 'it';
        tempo.lang = lang;
      }
      tempo.place = strToStaffrel(placeStr);
      if (words.isNotEmpty) textRendition(words, tempo);
      final MeiXmlNode? metronome =
          xpathFirst(node, "direction-type/metronome[not(@print-object='no')]");
      if (metronome != null) printMetronome(metronome, tempo);
      if (soundNode?.hasAttr('tempo') ?? false) {
        tempo.midiBpm = strToDblPrefix(soundNode!.attr('tempo') ?? '');
      }
      tempo.tstamp = timeStamp;
      if (staffNode != null) {
        tempo.staff = [strToInt(getContent(staffNode)) + staffOffset];
      }
      controlElements.add((measureNum, tempo));
      tempoStack.add(tempo);
    }

    // other cases
    if (!containsDynamics &&
        !containsTempo &&
        !containsWords &&
        xmlJump == null &&
        bracket == null &&
        lead == null &&
        xmlShift == null &&
        xmlPedal == null &&
        wedges.isEmpty &&
        dashes == null &&
        rehearsal == null) {
      logWarning("MusicXML import: Unsupported direction-type "
          "'${typeNode.firstChild()?.name ?? ''}'");
    }

    // Sound
    final MeiXmlNode? xmlSound = node.child('sound');
    if (xmlSound != null) {
      readMusicXmlSound(xmlSound, measure, section);
    }
  }

  /// Mirrors `AttModule::SetExternalsymbols` restricted to glyph.num and
  /// glyph.auth usage of this reader.
  static void setExternalSymbols(Object object, String key, String value) {
    final dynamic dyn = object;
    if (key == 'glyph.num') {
      dyn.glyphNum = strToHexnum(value);
    } else if (key == 'glyph.auth') {
      dyn.glyphAuth = value;
    }
  }

  // =========================================================================
  // Figures / forward / harmony
  // =========================================================================

  /// Mirrors `ReadMusicXmlFigures`.
  void readMusicXmlFigures(MeiXmlNode node, Measure measure, String measureNum) {
    if (hasAttributeWithValue(node, 'print-object', 'no')) return;

    final List<F> figures = [];

    final bool paren = node.attr('parentheses') == 'true';

    for (final MeiXmlNode figure in node.childrenElements()) {
      if (figure.name != 'figure') continue;
      String textStr = '';
      if (paren) textStr += '(';
      textStr += convertFigureGlyph(getContent(figure.child('prefix')));
      textStr += getContent(figure.child('figure-number'));
      textStr += convertFigureGlyph(getContent(figure.child('suffix')));
      if (paren) textStr += ')';
      if (textStr.isEmpty) continue;
      final F f = F();
      final MeiXmlNode? extend = figure.child('extend');
      if (extend != null && !hasAttributeWithValue(extend, 'type', 'stop')) {
        f.extender = true;
      }
      final Text text = Text();
      text.text = textStr;
      f.addChild(text);
      figures.add(f);
    }
    if (figures.isEmpty) return;

    final Harm harm = Harm();
    final Fb fb = Fb();
    for (final F fig in figures) {
      fb.addChild(fig);
    }
    harm.addChild(fb);
    harm.tstamp = (durTotal + durFb) * meterUnit / (4 * ppq) + 1.0;
    durFb += strToInt(getContent(node.child('duration')));
    controlElements.add((measureNum, harm));
    harmStack.add(harm);
  }

  /// Mirrors `ReadMusicXmlForward`.
  void readMusicXmlForward(MeiXmlNode node, Measure measure, String measureNum) {
    if (node.nextSibling() == null) {
      // fill the layer, if forward element is last sibling
      fillSpace(selectLayerFromNode(node, measure),
          strToInt(getContent(node.child('duration'))));
    } else {
      durTotal += strToInt(getContent(node.child('duration')));
    }
  }

  /// Mirrors `ReadMusicXmlHarmony`.
  void readMusicXmlHarmony(
      MeiXmlNode node, Measure measure, String measureNum) {
    int durOffset = 0;

    String harmText = getContentOfChild(node, 'root/root-step');
    MeiXmlNode? alter = xpathFirst(node, 'root/root-alter');
    if (harmText.isEmpty) {
      final MeiXmlNode numeral = xpathFirst(node, 'numeral/numeral-root')!;
      harmText = numeral.hasAttr('text')
          ? numeral.attr('text')!
          : getContent(numeral);
      alter = xpathFirst(node, 'numeral/numeral-alter');
    }
    if (alter != null) harmText += convertAlterToSymbol(getContent(alter));
    final MeiXmlNode? kind = node.child('kind');
    if (kind != null) {
      if (hasAttributeWithValue(kind, 'use-symbols', 'yes')) {
        harmText += convertKindToSymbol(getContent(kind));
      } else if (kind.hasAttr('text') &&
          getContent(kind).compareTo('none') != 0) {
        harmText += kind.attr('text')!;
      } else {
        harmText += convertKindToText(getContent(kind));
      }
    }
    harmText += convertDegreeToText(node);
    final MeiXmlNode? bass = node.child('bass');
    if (bass != null) {
      harmText += '/';
      harmText += getContent(bass.child('bass-step'));
      harmText += convertAlterToSymbol(getContent(bass.child('bass-alter')));
    }
    final Harm harm = Harm();
    final Text text = Text();
    text.text = harmText;
    harm.place = strToStaffrel(node.attr('placement') ?? '');
    harm.type = node.attr('type');
    harm.addChild(text);
    final MeiXmlNode? offset = node.child('offset');
    if (offset != null) durOffset = strToInt(getContent(offset));
    harm.tstamp = (durTotal + durOffset) * meterUnit / (4 * ppq) + 1.0;
    controlElements.add((measureNum, harm));
    harmStack.add(harm);
  }

  // =========================================================================
  // Note
  // =========================================================================

  /// Mirrors `ReadMusicXmlNote`.
  void readMusicXmlNote(MeiXmlNode node, Measure measure, String measureNum,
      int staffOffset, Section section) {
    final Layer layer = selectLayerFromNode(node, measure);

    // If we just had a clef change, make sure it points to the correct layer
    if (clefChanged != 0 && _clefChangeQueue.isNotEmpty) {
      final int limit = math.min(clefChanged, _clefChangeQueue.length);
      // Adjust all clefs in the queue
      for (int i = 0; i < limit; ++i) {
        _clefChangeQueue[i].layer = layer;
      }
    }
    clefChanged = 0;

    prevLayer = layer;

    final Staff staff = layer.getFirstAncestor(ClassId.staff)! as Staff;
    // find staff's staffDef
    StaffDef? staffDef;
    Tuning? tuning;
    final Object? firstScoreDef = doc.getFirstScoreDef();
    if (firstScoreDef != null) {
      final cnc = AttNIntegerComparison(ClassId.staffDef, staff.n ?? 0);
      staffDef = firstScoreDef.findDescendantByComparison(cnc) as StaffDef?;
    }
    bool isTablature = false;

    if (staffDef != null) {
      tuning = staffDef.findDescendantByType(ClassId.tuning,
          deepness: unlimitedDepth) as Tuning?;
      final Notationtype? notationType = staffDef.notationtype;
      isTablature = notationType == Notationtype.tab ||
          notationType == Notationtype.tabGuitar ||
          notationType == Notationtype.tabLuteItalian ||
          notationType == Notationtype.tabLuteFrench ||
          notationType == Notationtype.tabLuteGerman;
    }

    final bool isChord = node.child('chord') != null;

    // reset figured bass offset
    durFb = 0;

    LayerElement element;
    Note? note;

    bool nextIsChord = false;
    Fraction onset = Fraction(durTotal); // keep note onsets for later

    // for measure repeats add a single <mRpt> and return
    if (mRpt) {
      MRpt? mRpt = layer.getFirst(ClassId.mRpt) as MRpt?;
      mRpt ??= MRpt();
      if (mRpt.parent == null) {
        addLayerElement(layer, mRpt);
      }
      return;
    }

    final MeiXmlNode? notations =
        xpathFirst(node, "notations[not(@print-object='no')]");

    final bool cue = node.child('cue') != null ||
        xpathExists(node, "type[@size='cue']");
    MeiXmlNode? grace = node.child('grace');

    // duration string and dots
    final String typeStr = getContent(node.child('type'));
    final int dots =
        node.childrenElements().where((n) => n.name == 'dot').length;

    int tremSlashNum = -1;

    final bool readBeamsAndTuplets =
        readMusicXmlBeamsAndTuplets(node, layer, isChord);

    // beam start
    bool beamStart = xpathExists(node, "beam[@number='1'][text()='begin']");
    // tremolos
    final MeiXmlNode? tremolo =
        xpathFirst(notations ?? node, 'ornaments/tremolo');
    final bool tremoloOnNotations = notations != null && tremolo != null;
    final MeiXmlNode? tremoloNode = tremoloOnNotations ? tremolo : null;

    if (tremoloNode != null) {
      if (hasAttributeWithValue(tremoloNode, 'type', 'start')) {
        if (!isChord) {
          final FTrem fTrem = FTrem();
          addLayerElement(layer, fTrem);
          _stackFor(layer).add(fTrem);
          final int beamFloatNum = strToInt(getContent(tremoloNode));
          int beamAttachedNum = 0; // number of attached beams
          while (beamStart && beamAttachedNum < 8) {
            // count number of (attached) beams, max 8
            beamStart = xpathExists(node,
                "beam[@number='${beamAttachedNum + 2}'][text()='begin']");
            ++beamAttachedNum;
          }
          fTrem.beams = beamFloatNum + beamAttachedNum;
          fTrem.beamsFloat = beamFloatNum;
        }
      } else if (!hasAttributeWithValue(tremoloNode, 'type', 'stop')) {
        // this is default tremolo type in MusicXML
        tremSlashNum = strToInt(getContent(tremoloNode));
        if (!isChord) {
          final BTrem bTrem = BTrem();
          addLayerElement(layer, bTrem);
          _stackFor(layer).add(bTrem);
          if (hasAttributeWithValue(tremoloNode, 'type', 'unmeasured')) {
            bTrem.form = TremformForm.unmeas;
            tremSlashNum = 0;
          } else {
            bTrem.form = TremformForm.meas;
          }
        }
      }
    }

    final String noteID = node.attr('id') ?? '';
    int duration = strToInt(getContent(node.child('duration')));
    // In chords, make sure a note does not extend first note's duration.
    if (isChord &&
        duration != 0 &&
        _stackFor(layer).isNotEmpty &&
        _stackFor(layer).last.classId == ClassId.chord) {
      final Chord chord = _stackFor(layer).last as Chord;
      duration = math.min(duration, chord.durPpq ?? 0);
    }
    final int noteStaffNum = strToInt(getContent(node.child('staff')));
    final MeiXmlNode? restNode = node.child('rest');
    if (ppq < 0 && duration != 0 && typeStr.isNotEmpty) {
      // if divisions are missing, try to calculate
      ppq = (duration * math.pow(2.0, convertTypeToDur(typeStr).value - 2) / 4)
          .truncate();
    }

    if (restNode != null) {
      final String stepStr = getContent(restNode.child('display-step'));
      final String octaveStr = getContent(restNode.child('display-octave'));
      if (hasAttributeWithValue(node, 'print-object', 'no')) {
        final Space space = Space();
        element = space;
        if (typeStr.isNotEmpty) {
          space.dur = convertTypeToDur(typeStr);
          space.durPpq = duration;
          if (dots > 0) space.dots = dots;
          if (noteID.isNotEmpty) {
            space.id = noteID;
          }
          // set @staff attribute, if existing and different from parent staff
          if (noteStaffNum > 0 && noteStaffNum + staffOffset != staff.n) {
            space.staff = [noteStaffNum + staffOffset];
          }
          addLayerElement(layer, space, duration);
        } else {
          final MSpace mSpace = MSpace();
          if (noteID.isNotEmpty) {
            mSpace.id = noteID;
          }
          addLayerElement(layer, mSpace);
        }
      }
      // we assume /note without /type or with duration of an entire bar to be
      // mRest
      else if (typeStr.isEmpty || restNode.attr('measure') == 'true') {
        if (slash) {
          final MeterSig tmpMeterSig = MeterSig();
          tmpMeterSig.count = MeterCountPair([...meterCount], meterSign);
          final int totalCount = tmpMeterSig.getTotalCount();
          for (int i = totalCount; i > 0; --i) {
            final BeatRpt slashRpt = BeatRpt();
            addLayerElement(layer, slashRpt, duration);
          }
          return;
        } else {
          final MRest mRest = MRest();
          element = mRest;
          if (cue) mRest.cue = true;
          if (stepStr.isNotEmpty) mRest.ploc = convertStepToPitchName(stepStr);
          if (octaveStr.isNotEmpty) mRest.oloc = int.parse(octaveStr);
          if (noteID.isNotEmpty) {
            mRest.id = noteID;
          }
          addLayerElement(layer, mRest, duration);
        }
      } else {
        if (isTablature) {
          // rest
          final TabGrp tabGrp = TabGrp();
          element = tabGrp;
          tabGrp.dur = convertTypeToDur(typeStr);
          tabGrp.durPpq = duration;
          if (dots > 0) tabGrp.dots = dots;
          tabGrp.addChild(TabDurSym());
          addLayerElement(layer, tabGrp, duration);
        } else {
          final Rest rest = Rest();
          element = rest;
          rest.color = node.attr('color');
          rest.dur = convertTypeToDur(typeStr);
          rest.durPpq = duration;
          if (dots > 0) rest.dots = dots;
          if (cue) rest.cue = true;
          if (stepStr.isNotEmpty) rest.ploc = convertStepToPitchName(stepStr);
          if (octaveStr.isNotEmpty) rest.oloc = int.parse(octaveStr);
          if (noteID.isNotEmpty) {
            rest.id = noteID;
          }
          // set @staff attribute, if existing and different from parent staff
          if (noteStaffNum > 0 && noteStaffNum + staffOffset != staff.n) {
            rest.staff = [noteStaffNum + staffOffset];
          }
          addLayerElement(layer, rest, duration);
        }
      }
    } else {
      note = Note();
      element = note;
      note.visible = convertWordToBool(node.attr('print-object') ?? '');
      note.color = node.attr('color');
      if (noteID.isNotEmpty) {
        note.id = noteID;
      }
      note.setScoreTimeOnset(onset); // remember the MIDI onset within measure
      // set @staff attribute, if existing and different from parent staff
      if (noteStaffNum > 0 && noteStaffNum + staffOffset != staff.n) {
        note.staff = [noteStaffNum + staffOffset];
      }

      // accidentals
      for (final MeiXmlNode accidental in node.childrenElements()) {
        if (accidental.name == 'accidental') addAccidental(accidental, note);
      }
      for (final MeiXmlNode accidental in xpathNodes(node, 'notations/accidental-mark')) {
        addAccidental(accidental, note);
      }

      // stem direction - taken into account below for the chord or the note
      Stemdirection stemDir = Stemdirection.none;
      final MeiXmlNode? stem = node.child('stem');
      final String stemText = getContent(stem);
      if (stemText == 'down') {
        stemDir = Stemdirection.down;
      } else if (stemText == 'up') {
        stemDir = Stemdirection.up;
      }

      // pitch and octave, optional, not needed for tablature
      final MeiXmlNode? pitch = node.child('pitch');
      if (pitch != null && !isTablature) {
        final String stepStr = getContent(pitch.child('step'));
        final int octaveNum = strToInt(getContent(pitch.child('octave')));
        if (stepStr.isNotEmpty) note.pname = convertStepToPitchName(stepStr);
        final int staffN = staff.n ?? 0;
        final int octShift =
            (staffN >= 0 && staffN < octDis.length) ? octDis[staffN] : 0;
        if (octShift != 0) {
          note.oct = octaveNum - octShift;
          note.octGes = octaveNum;
        } else {
          note.oct = octaveNum;
        }

        // adjust accidental (including glyph) based on carried-over
        // accidentals or update the carried-over accidentals with current
        // accidental value.
        if (note.hasPname) {
          final List<Object> accids = note.findAllDescendantsByType(ClassId.accid);
          if (accids.isEmpty) {
            final List<_XmlAccidental>? carried = _currentAccids[note.pname];
            if (carried != null) {
              for (final _XmlAccidental current in carried) {
                final Accid accid = Accid();
                note.addChild(accid);
                accid.isAttribute = false;

                // to make sure the new *gestural* accidental conforms to the
                // carried-over *written* accidental, we translate the latter
                // to a SMuFL glyph and set the gestural accidental to the MEI
                // equivalent of the written accidental.
                accid.accidGes = accidentalWrittenToGestural(current.accid);
                if (current.glyphName.isNotEmpty) {
                  accid.glyphName = current.glyphName;
                  accid.glyphAuth = current.glyphAuth;
                } else if (current.accid != AccidentalWritten.none) {
                  final int glyph = Accid.getAccidGlyph(current.accid);
                  accid.glyphName = CustomTuning.getGlyphName(glyph);
                  accid.glyphAuth = 'smufl';
                }
              }
            } else {
              logWarning(
                  'MusicXML import: Unexpected pitch ${note.pname!.value}');
            }
          } else {
            _currentAccids[note.pname]!.clear();
            for (final Object object in accids) {
              final Accid accid = object as Accid;
              accid.accidGes =
                  accidentalWrittenToGestural(accid.accid ?? AccidentalWritten.none);
              _currentAccids[note.pname]!.add(_XmlAccidental(
                  accid.accid ?? AccidentalWritten.none,
                  accid.glyphName ?? '',
                  accid.glyphAuth ?? ''));
            }
          }
        }
      } else if (node.child('unpitched') != null) {
        final MeiXmlNode unpitched = node.child('unpitched')!;
        final String stepStr = getContent(unpitched.child('display-step'));
        final int octaveNum = strToInt(getContent(unpitched.child('display-octave')));
        final int loc = PitchInterface.calcLoc(
            convertStepToPitchName(stepStr), octaveNum, -2);
        note.loc = loc;
      }

      // dynamics (MIDI velocity)
      final double dynamics = strToDblPrefix(node.attr('dynamics') ?? '-1');
      if (dynamics >= 0.0) {
        note.vel = convertDynamicsToMidiVal(dynamics);
      }

      // notehead
      final MeiXmlNode? notehead = node.child('notehead');
      if (notehead != null) {
        note.headColor = notehead.attr('color');
        note.headShape = HeadShape()
          ..setHeadShapeList(convertNotehead(getContent(notehead)));
        if (notehead.attr('parentheses') == 'true') {
          note.headMod = Noteheadmodifier.paren;
        }
        note.glyphName = notehead.attr('smufl');
        if (notehead.hasAttr('filled')) {
          note.headFill = notehead.attr('filled') == 'true'
              ? Fill.solid
              : Fill.voidValue;
        }
        if (getContent(notehead).startsWith('none')) {
          note.headVisible = false;
        }
      }
      if (node.child('notehead-text') != null) {
        logWarning('MusicXML import: notehead-text is not supported');
      }

      // look at the next note to see if we are starting or ending a chord
      final List<MeiXmlNode> followingNotes = xpathNodes(node, 'following-sibling::note');
      if (followingNotes.isNotEmpty &&
          followingNotes.first.child('chord') != null) {
        nextIsChord = true;
      }
      Chord? chord;
      TabGrp? tabGrp;
      if (isTablature) {
        // create the tabGrp if we are starting a new tabGrp
        if (_stackFor(layer).isEmpty ||
            _stackFor(layer).last.classId != ClassId.tabGrp) {
          tabGrp = TabGrp();
          tabGrp.dur = convertTypeToDur(typeStr);
          tabGrp.durPpq = duration;
          if (dots > 0) tabGrp.dots = dots;
          tabGrp.addChild(TabDurSym());
          addLayerElement(layer, tabGrp, duration);
          _stackFor(layer).add(tabGrp);
          element = tabGrp;
        }
      } else if (nextIsChord) {
        // create the chord if we are starting a new chord
        if (_stackFor(layer).isEmpty ||
            _stackFor(layer).last.classId != ClassId.chord) {
          chord = Chord();
          chord.dur = convertTypeToDur(typeStr);
          chord.durPpq = duration;
          if (dots > 0) chord.dots = dots;
          chord.stemDir = stemDir;
          if (getContent(notehead) == 'cluster') {
            chord.cluster = Cluster.white;
          }
          if (stemText == 'none') chord.stemVisible = false;
          if (tremSlashNum > 0) {
            chord.stemMod = strToStemmodifier('${tremSlashNum}slash');
          } else if (tremSlashNum == 0) {
            chord.stemMod = Stemmodifier.z;
          }
          addLayerElement(layer, chord, duration);
          _stackFor(layer).add(chord);
          element = chord;
          if (cue) chord.cue = true;
          if (grace != null) {
            if (grace.hasAttr('slash')) {
              chord.grace = Grace.unacc;
              chord.stemMod = Stemmodifier.n1slash;
            } else {
              chord.grace = Grace.acc;
            }
          }
        }
      }
      // If the current note is part of a chord.
      if (!isTablature && (nextIsChord || isChord)) {
        if (chord == null &&
            _stackFor(layer).isNotEmpty &&
            _stackFor(layer).last.classId == ClassId.chord) {
          chord = _stackFor(layer).last as Chord;
        }
        if (chord == null) {
          logError('MusicXML import: Chord starting point has not been found');
          return;
        }
        // Mark a chord as cue=true if and only if all its child notes are cue.
        if (!cue) {
          chord.cue = null;
        } else if (chord.cue != null) {
          chord.cue = true;
        }
        grace = null;
      }

      // single grace note
      if (grace != null) {
        if (grace.hasAttr('slash')) {
          note.grace = Grace.unacc;
          note.stemMod = Stemmodifier.n1slash;
        } else {
          note.grace = Grace.acc;
        }
      }
      if (cue) note.cue = true;

      // set attributes to the note if we are not in a chord
      if (!isTablature &&
          (_stackFor(layer).isEmpty ||
              _stackFor(layer).last.classId != ClassId.chord)) {
        if (typeStr.isNotEmpty) note.dur = convertTypeToDur(typeStr);
        note.durPpq = duration;
        if (dots > 0) note.dots = dots;
        note.stemDir = stemDir;
        if (node.hasAttr('default-y') && stem?.hasAttr('default-y') == true) {
          final double stemLen = (strToDblPrefix(node.attr('default-y') ?? '') -
                      strToDblPrefix(stem!.attr('default-y') ?? ''))
              .abs() /
              5;
          note.stemLen = stemLen;
        }
        if (stemText == 'none') note.stemVisible = false;
        if (tremSlashNum > 0) {
          note.stemMod = strToStemmodifier('${tremSlashNum}slash');
        } else if (tremSlashNum == 0) {
          note.stemMod = Stemmodifier.z;
        }
      }

      // beamspan
      if (!readBeamsAndTuplets) {
        final BeamSpan meiBeamSpan = BeamSpan();
        meiBeamSpan.startid = '#${element.id}';
        controlElements.add((measureNum, meiBeamSpan));
        _beamspanStack.add((meiBeamSpan, (staff.n ?? 0, layer.n ?? 0)));
      }

      // verse / syl
      for (final MeiXmlNode lyric in node.childrenElements()) {
        if (lyric.name != 'lyric') continue;
        if (lyric.child('text') == null) continue; // Dorico non-valid export
        int lyricNumber = strToInt(lyric.attr('number') ?? '');
        if (lyricNumber < 1) lyricNumber = 1;
        final Verse verse = Verse();
        verse.color = lyric.attr('color');
        verse.label = lyric.attr('name');
        verse.n = lyricNumber;
        String syllabic = 'single';
        for (final MeiXmlNode childNode in lyric.childrenElements()) {
          if (childNode.name == 'syllabic') syllabic = getContent(childNode);
          if (childNode.name == 'text' &&
              !hasAttributeWithValue(lyric, 'print-object', 'no')) {
            final String textStyle = childNode.attr('font-style') ?? '';
            final String textWeight = childNode.attr('font-weight') ?? '';
            final int lineThrough = strToInt(childNode.attr('line-through') ?? '');
            final String lang = childNode.attr('xml:lang') ?? '';
            String textStr = getContent(childNode);

            // convert verse numbers to labels
            final RegExp labelSearch = RegExp(r'^([^a-zA-Z]*\d[^a-zA-Z]*)$');
            final RegExp labelPrefixSearch =
                RegExp(r'^([^a-zA-Z]*\d[^a-zA-Z]*)[\s\u00A0]+');
            if (textStr.isNotEmpty &&
                labelSearch.hasMatch(textStr) &&
                nextSiblingNamed(childNode, 'elision') != null) {
              // entire textStr is a label (MusicXML from Finale)
              final Label verseLabel = Label();

              final Text labelText = Text();
              labelText.text = textStr;
              verseLabel.addChild(labelText);
              verse.addChild(verseLabel);

              continue;
            } else if (textStr.isNotEmpty &&
                labelPrefixSearch.hasMatch(textStr)) {
              // first part of textStr is a label (Sibelius, MuseScore)
              final Label prefixLabel = Label();

              final Match match = labelPrefixSearch.firstMatch(textStr)!;
              final String prefix =
                  match.group(0)!.replaceAll(RegExp(r'[ \f\n\r\t\v\u00A0]+$'), '');
              final Text prefixText = Text();
              prefixText.text = prefix;
              prefixLabel.addChild(prefixText);
              verse.addChild(prefixLabel);

              textStr = textStr.substring(match.group(0)!.length);
            }

            final Syl syl = Syl();
            syl.lang = lang;
            if (syllabic == 'single') {
              syl.wordpos = SyllogWordpos.s;
              syl.con = SyllogCon.s;
            } else if (syllabic == 'begin') {
              syl.wordpos = SyllogWordpos.i;
              syl.con = SyllogCon.d;
            } else if (syllabic == 'middle') {
              syl.wordpos = SyllogWordpos.m;
              syl.con = SyllogCon.d;
            } else if (syllabic == 'end') {
              syl.wordpos = SyllogWordpos.t;
              syl.con = SyllogCon.s;
            }

            // override @con if we have elisions or extensions
            if (nextSiblingNamed(childNode, 'elision') != null) {
              syl.con = SyllogCon.b;
            } else if (lyric.child('extend') != null) {
              syl.con = SyllogCon.u;
            }

            if (textStyle.isNotEmpty) {
              syl.fontstyle = strToFontstyle(textStyle);
            }
            if (textWeight.isNotEmpty) {
              syl.fontweight = strToFontweight(textWeight);
            }

            final Text text = Text();
            text.text = textStr;
            if (lineThrough != 0) {
              final Rend rend = Rend();
              rend.addChild(text);
              rend.rend = Textrendition.lineThrough;
              syl.addChild(rend);
            } else {
              syl.addChild(text);
            }
            verse.addChild(syl);
          }
        }
        // TODO(tablature): <tabGrp> does not support child <verse>
        if (element.classId == ClassId.chord ||
            element.classId == ClassId.note) {
          element.addChild(verse);
        } else {
          // this should not happen
        }
      }

      // slurs
      final List<MeiXmlNode> slurs = xpathNodes(node, 'notations/slur');
      for (final MeiXmlNode slur in slurs) {
        int slurNumber = strToInt(slur.attr('number') ?? '');
        slurNumber = slurNumber < 1 ? 1 : slurNumber;
        final CurvatureCurvedir dir = inferCurvedir(slur);
        if (hasAttributeWithValue(slur, 'type', 'stop')) {
          closeSlur(measure, slurNumber, note, dir);
        } else if (hasAttributeWithValue(slur, 'type', 'start')) {
          final Slur meiSlur = Slur();
          meiSlur.color = slur.attr('color');
          meiSlur.lform = strToLineform(slur.attr('line-type') ?? '');
          if (slur.hasAttr('id')) meiSlur.id = slur.attr('id')!;
          meiSlur.startid = '#${note.id}';
          // add it to the stack
          controlElements.add((measureNum, meiSlur));
          openSlur(measure, slurNumber, meiSlur, dir);
        }
      }

      // ties
      readMusicXmlTies(node, layer, note, measureNum);

      // articulation
      final List<Artic> artics = [];
      final List<MeiXmlNode> articulationGroups = [];
      if (notations != null) {
        for (final MeiXmlNode n in notations.childrenElements()) {
          if (n.name == 'articulations') articulationGroups.add(n);
        }
      }
      for (final MeiXmlNode articulations in articulationGroups) {
        for (final MeiXmlNode articulation in articulations.childrenElements()) {
          Artic artic = Artic();
          Articulation articVal = convertArticulations(articulation.name);
          if (articulation.name == 'detached-legato') {
            // we need to split up this one
            artic.artic = [articVal];
            artic.color = articulation.attr('color');
            artic.place = strToStaffrel(articulation.attr('placement') ?? '');
            artics.add(artic);
            artic = Artic();
            articVal = Articulation.ten;
          }
          if (articVal == Articulation.none) {
            continue;
          }
          artic.artic = [articVal];
          artic.color = articulation.attr('color');
          artic.place = strToStaffrel(articulation.attr('placement') ?? '');
          // Always put stacc at the front of the list
          if ((artic.artic?.first ?? Articulation.none) == Articulation.stacc) {
            artics.insert(0, artic);
          } else {
            artics.add(artic);
          }
        }
      }
      for (final Artic artic in artics) {
        element.addChild(artic);
      }

      // technical
      final List<MeiXmlNode> technicalGroups = [];
      if (notations != null) {
        for (final MeiXmlNode n in notations.childrenElements()) {
          if (n.name == 'technical') technicalGroups.add(n);
        }
      }
      for (final MeiXmlNode technical in technicalGroups) {
        for (final MeiXmlNode technicalChild in technical.childrenElements()) {
          final String technicalChildName = technicalChild.name;

          // fingering
          if (technicalChildName == 'fingering') {
            final String fingText = getContent(technicalChild);
            final Fing fing = Fing();
            final Text text = Text();
            text.text = fingText;
            controlElements.add((measureNum, fing));
            fing.startid = id;
            fing.staff = [staff.n ?? 0];
            fing.place =
                strToStaffrel(technicalChild.attr('placement') ?? '');
            fing.addChild(text);
          } else if (technicalChildName == 'thumb-position') {
            continue;
          } else if (technicalChildName == 'string') {
            continue; // handled with fret
          } else if (technicalChildName == 'fret') {
            assert(isTablature);

            // set @tab.string and @tab.fret
            final int fret = strToInt(getContent(technicalChild));
            final int course = strToInt(getContent(technical.child('string')));
            note.tabFret = fret;
            note.tabCourse = course;

            // Do we have the pitch for this note, if so do we have the tuning
            // for this course?
            final MeiXmlNode? pitchNode = node.child('pitch');
            if (tuning != null && pitchNode != null) {
              Course? courseTuning;
              for (final Object childObject in tuning.children) {
                if (childObject is Course &&
                    childObject.n == '$course') {
                  courseTuning = childObject;
                  break;
                }
              }

              if (courseTuning == null) {
                // we have the note's pitch, but not the course's tuning, set it

                final int midiN = pitchToMidi(
                    getContent(pitchNode.child('step')),
                    strToInt(getContent(pitchNode.child('alter'))),
                    getContent(pitchNode.child('octave')).isEmpty
                        ? 0
                        : strToInt(getContent(pitchNode.child('octave'))));

                // course's pitch
                String stepStr;
                int alterNum = 0;
                int octaveNum = 0;
                (stepStr, alterNum, octaveNum) = midiToPitch(midiN - fret);

                courseTuning = Course();
                tuning.addChild(courseTuning);

                courseTuning.n = '$course';
                courseTuning.pname = convertStepToPitchName(stepStr);
                courseTuning.oct = octaveNum;

                if (alterNum != 0) {
                  courseTuning.accid =
                      convertAlterToAccidWritten(alterNum.toDouble());
                }
              }
            }
          } else {
            final MeiXmlNode articulation = technicalChild;
            final Artic artic = Artic();
            final Articulation articVal =
                convertArticulations(articulation.name);
            if (articVal != Articulation.none) artic.artic = [articVal];
            artic.color = articulation.attr('color');
            artic.glyphName = articulation.attr('smufl');
            artic.place =
                strToStaffrel(articulation.attr('placement') ?? '');
            artic.type = 'technical';
            element.addChild(artic);
          }
        }
      }

      // add the note to the layer or to the current container
      addLayerElement(layer, note, duration);

      // if we are ending a chord or tabGrp remove it from the stack
      if (!nextIsChord) {
        final ClassId classId = isTablature ? ClassId.tabGrp : ClassId.chord;
        if (_stackFor(layer).isNotEmpty &&
            _stackFor(layer).last.classId == classId) {
          setChordStaff(layer);

          removeLastFromStack(classId, layer);
        }
      }
    }

    // add duration to measure time
    if (!nextIsChord) durTotal += duration;

    id = '#${element.id}';

    // breath marks
    final MeiXmlNode? xmlBreath =
        xpathFirst(notations ?? node, 'articulations/breath-mark');
    if (xmlBreath != null && notations != null) {
      final Breath breath = Breath();
      controlElements.add((measureNum, breath));
      breath.staff = [staff.n ?? 0];
      breath.place = strToStaffrel(xmlBreath.attr('placement') ?? '');
      breath.color = xmlBreath.attr('color');
      breath.tstamp = durTotal * meterUnit / (4 * ppq) + 0.5;
    }

    // caesura
    final MeiXmlNode? xmlCaesura =
        xpathFirst(notations ?? node, 'articulations/caesura');
    if (xmlCaesura != null && notations != null) {
      final Caesura caesura = Caesura();
      controlElements.add((measureNum, caesura));
      caesura.staff = [staff.n ?? 0];
      caesura.place = strToStaffrel(xmlCaesura.attr('placement') ?? '');
      caesura.color = xmlCaesura.attr('color');
      caesura.tstamp = durTotal * meterUnit / (4 * ppq) + 0.5;
    }

    // dynamics
    final MeiXmlNode? xmlDynam = notations?.child('dynamics');
    if (xmlDynam != null) {
      final Dynam dynam = Dynam();
      controlElements.add((measureNum, dynam));
      dynam.staff = [staff.n ?? 0];
      dynam.startid = id;
      if (xmlDynam.hasAttr('id')) dynam.id = xmlDynam.attr('id')!;
      dynam.place = strToStaffrel(xmlDynam.attr('placement') ?? '');
      int defaultY = strToInt(xmlDynam.attr('default-y') ?? '');
      defaultY = (defaultY * 10) + strToInt(xmlDynam.attr('relative-y') ?? '');
      defaultY = (defaultY < 0) ? defaultY.abs() : defaultY + 2000;
      dynam.vgrp = defaultY;
      String dynamStr = '';
      final List<MeiXmlNode> children = xmlDynam.childrenElements();
      for (int i = 0; i < children.length; ++i) {
        final MeiXmlNode xmlDynamPart = children[i];
        if (xmlDynamPart.name == 'other-dynamics') {
          dynamStr += getContent(xmlDynamPart);
        } else {
          dynamStr += xmlDynamPart.name;
        }
        if (!(identical(xmlDynamPart, children.last))) dynamStr += ' ';
      }
      final Text text = Text();
      text.text = dynamStr;
      dynam.addChild(text);
    }

    // fermatas
    final MeiXmlNode? xmlFermata = notations?.child('fermata');
    if (xmlFermata != null) {
      final Fermata fermata = Fermata();
      controlElements.add((measureNum, fermata));
      fermata.startid = id;
      fermata.staff = [staff.n ?? 0];
      if (xmlFermata.hasAttr('id')) fermata.id = xmlFermata.attr('id')!;
      shapeFermata(fermata, xmlFermata);
    }

    // glissando and slide
    final List<MeiXmlNode> glissandi =
        xpathNodes(notations ?? node, 'glissando|slide');
    for (final MeiXmlNode xmlGlissando in glissandi) {
      if (notations == null) break;
      String noteIDGliss = id;
      // prevent from using chords or tabGrps
      if (element.classId == ClassId.chord ||
          element.classId == ClassId.tabGrp) {
        noteIDGliss = '#${element.getChild(0)!.id}';
      }
      if (hasAttributeWithValue(xmlGlissando, 'type', 'start')) {
        final Gliss gliss = Gliss();
        controlElements.add((measureNum, gliss));
        gliss.color = xmlGlissando.attr('color');
        gliss.lform = strToLineform(xmlGlissando.attr('line-type') ?? '');
        gliss.n = xmlGlissando.attr('number') ?? '';
        gliss.startid = noteIDGliss;
        gliss.staff = [staff.n ?? 0];
        gliss.type = xmlGlissando.name;
        if (xmlGlissando.hasAttr('id')) gliss.id = xmlGlissando.attr('id')!;
        glissStack.add(gliss);
      } else if (glissStack.isNotEmpty) {
        final int extNumber = strToInt(xmlGlissando.attr('number') ?? '');
        for (int i = 0; i < glissStack.length;) {
          final Gliss glissIter = glissStack[i];
          if ((int.tryParse(glissIter.n ?? '') ?? -1) == extNumber &&
              glissIter.type == xmlGlissando.name) {
            glissIter.endid = noteIDGliss;
            glissStack.removeAt(i);
          } else {
            ++i;
          }
        }
      }
    }

    // mordents
    final MeiXmlNode? xmlMordent =
        xpathFirst(notations ?? node, "ornaments/*[contains(name(), 'mordent')]");
    if (xmlMordent != null && notations != null) {
      final Mordent mordent = Mordent();
      controlElements.add((measureNum, mordent));
      mordent.staff = [staff.n ?? 0];
      mordent.startid = id;
      // color
      mordent.color = xmlMordent.attr('color');
      // long
      mordent.long = convertWordToBool(xmlMordent.attr('long') ?? '');
      // place
      mordent.place = strToStaffrel(xmlMordent.attr('placement') ?? '');
      // form
      mordent.form = MordentlogForm.lower;
      if (xmlMordent.name.startsWith('inverted')) {
        mordent.form = MordentlogForm.upper;
      }
      for (final MeiXmlNode xmlAccidMark in notations.childrenElements()) {
        if (xmlAccidMark.name != 'accidental-mark') continue;
        final AccidentalWritten accid =
            convertAccidentalToAccid(getContent(xmlAccidMark));
        if (hasAttributeWithValue(xmlAccidMark, 'placement', 'above')) {
          mordent.accidupper = accid;
        } else if (hasAttributeWithValue(xmlAccidMark, 'placement', 'below')) {
          mordent.accidlower = accid;
        } else {
          if (mordent.form == MordentlogForm.upper) {
            mordent.accidupper = accid;
          }
          if (mordent.form == MordentlogForm.lower) {
            mordent.accidlower = accid;
          }
        }
      }
      if (mordent.long == true) {
        int mordentFlags =
            (mordent.form == MordentlogForm.upper)
                ? _MordentExtSymbolFlags.formInverted
                : _MordentExtSymbolFlags.formNormal;
        if (xmlMordent.hasAttr('approach')) {
          mordentFlags |= (xmlMordent.attr('approach') == 'above')
              ? _MordentExtSymbolFlags.apprAbove
              : _MordentExtSymbolFlags.apprBelow;
        }
        if (xmlMordent.hasAttr('departure')) {
          mordentFlags |= (xmlMordent.attr('departure') == 'above')
              ? _MordentExtSymbolFlags.depAbove
              : _MordentExtSymbolFlags.depBelow;
        }
        final String smuflCode = getOrnamentGlyphNumber(mordentFlags);
        if (smuflCode.isNotEmpty) {
          setExternalSymbols(mordent, 'glyph.num', smuflCode);
          setExternalSymbols(mordent, 'glyph.auth', 'smufl');
        }
      }
    }

    // schleifer/haydn (counts as mordent with different glyph)
    final MeiXmlNode? xmlExtOrnament = xpathFirst(notations ?? node,
        "ornaments/*[contains(name(), 'schleifer') or contains(name(), 'haydn')]");
    if (xmlExtOrnament != null && notations != null) {
      final Mordent mordent = Mordent();
      controlElements.add((measureNum, mordent));
      mordent.staff = [staff.n ?? 0];
      mordent.startid = id;
      // color
      mordent.color = xmlExtOrnament.attr('color');
      // place
      mordent.place = strToStaffrel(xmlExtOrnament.attr('placement') ?? '');
      final bool isHaydn = xmlExtOrnament.name == 'haydn';
      setExternalSymbols(mordent, 'glyph.num', isHaydn ? 'U+E56F' : 'U+E587');
      setExternalSymbols(mordent, 'glyph.auth', 'smufl');
    }

    // trill
    final MeiXmlNode? xmlTrill =
        xpathFirst(notations ?? node, 'ornaments/trill-mark');
    final MeiXmlNode? xmlTrillLine =
        xpathFirst(notations ?? node, "ornaments/wavy-line[@type='start']");
    if ((xmlTrill != null || xmlTrillLine != null) && notations != null) {
      final Trill trill = Trill();
      controlElements.add((measureNum, trill));
      trill.staff = [staff.n ?? 0];
      trill.startid = id;
      // color
      trill.color = xmlTrill?.attr('color');
      // place
      trill.place = strToStaffrel(xmlTrill?.attr('placement') ?? '');
      if (xmlTrillLine != null) {
        trill.extender = true;
        trill.n = xmlTrillLine.attr('number') ?? '';
        if (xmlTrill == null) {
          trill.lstartsym = Linestartendsymbol.none0;
          trill.color = xmlTrillLine.attr('color');
          trill.place = strToStaffrel(xmlTrillLine.attr('placement') ?? '');
        }
        final _OpenSpanner openTrill =
            _OpenSpanner(1, measureCounts[measure]!);
        _trillStack.add((trill, openTrill));
      }
      MeiXmlNode? accidMark = nextSiblingNamed(xmlTrill ?? notations, 'accidental-mark');
      while (accidMark != null) {
        if (hasAttributeWithValue(accidMark, 'placement', 'below')) {
          trill.accidlower = convertAccidentalToAccid(getContent(accidMark));
        } else {
          trill.accidupper = convertAccidentalToAccid(getContent(accidMark));
        }
        accidMark = nextSiblingNamed(accidMark, 'accidental-mark');
      }
    }
    if (_trillStack.isNotEmpty &&
        xpathExists(notations ?? node, "ornaments/wavy-line[@type='stop']")) {
      final MeiXmlNode? stopNode =
          xpathFirst(notations!, "ornaments/wavy-line[@type='stop']");
      final int extNumber = strToInt(stopNode?.attr('number') ?? '');
      for (int i = 0; i < _trillStack.length;) {
        final (Trill trillIter, _OpenSpanner openTrill) = _trillStack[i];
        final int measureDifference =
            measureCounts[measure]! - openTrill.lastMeasureCount;
        if ((int.tryParse(trillIter.n ?? '') ?? -1) == extNumber) {
          trillIter.tstamp2 = MeasureBeat(
              measureDifference, durTotal * meterUnit / (4 * ppq) + 1);
          _trillStack.removeAt(i);
        } else {
          ++i;
        }
      }
    }

    // turns
    final MeiXmlNode? xmlTurn =
        xpathFirst(notations ?? node, "ornaments/*[contains(name(), 'turn')]");
    if (xmlTurn != null && notations != null) {
      final Turn turn = Turn();
      controlElements.add((measureNum, turn));
      turn.staff = [staff.n ?? 0];
      turn.startid = id;
      turn.color = xmlTurn.attr('color');
      turn.place = strToStaffrel(xmlTurn.attr('placement') ?? '');
      turn.form = TurnlogForm.upper;
      MeiXmlNode? accidMark = nextSiblingNamed(xmlTurn, 'accidental-mark');
      while (accidMark != null) {
        if (hasAttributeWithValue(accidMark, 'placement', 'above')) {
          turn.accidupper = convertAccidentalToAccid(getContent(accidMark));
        } else if (hasAttributeWithValue(accidMark, 'placement', 'below')) {
          turn.accidlower = convertAccidentalToAccid(getContent(accidMark));
        } else {
          logWarning(
              'MusicXML import: Cannot add an accidental to a turn without placement');
        }
        accidMark = nextSiblingNamed(accidMark, 'accidental-mark');
      }
      if (xmlTurn.attr('slash') == 'true') {
        setExternalSymbols(turn, 'glyph.auth', 'smufl');
        setExternalSymbols(turn, 'glyph.num', 'U+E569');
      }
      if (xmlTurn.name.startsWith('inverted')) {
        turn.form = TurnlogForm.lower;
        if (xmlTurn.name.contains('vertical')) {
          turn.type = 'vertical';
          setExternalSymbols(turn, 'glyph.auth', 'smufl');
          setExternalSymbols(turn, 'glyph.num', 'U+E56B');
        }
      }
      if (xmlTurn.name.startsWith('delayed')) {
        turn.delayed = true;
      }
      if (xmlTurn.name.startsWith('vertical')) {
        turn.type = 'vertical';
        setExternalSymbols(turn, 'glyph.auth', 'smufl');
        setExternalSymbols(turn, 'glyph.num', 'U+E56A');
      }
    }

    // arpeggio
    final MeiXmlNode? xmlArpeggiate =
        xpathFirst(notations ?? node, "*[contains(name(), 'arpeggiate')]");
    if (xmlArpeggiate != null && notations != null) {
      int arpegN = strToInt(xmlArpeggiate.attr('number') ?? '');
      arpegN = arpegN < 1 ? 1 : arpegN;
      final String direction = xmlArpeggiate.attr('direction') ?? '';
      bool added = false;
      if (_arpeggioStack.isNotEmpty) {
        // check existing arpeggios
        for (final (Arpeg iterArpeg, _OpenArpeggio iterOpen) in _arpeggioStack) {
          if (iterOpen.arpegN == arpegN && onset == iterOpen.timeStamp) {
            // don't add other chord notes, because the chord is referenced.
            if (!isChord) iterArpeg.addRef('#${element.id}');
            added = true; // so that no new Arpeg gets created below
            break;
          }
        }
      }
      if (!added) {
        final Arpeg arpeggio = Arpeg();
        arpeggio.addRef('#${element.id}');
        // color
        arpeggio.color = xmlArpeggiate.attr('color');
        // direction (up/down) and in MEI arrow
        if (direction.isNotEmpty) {
          arpeggio.arrow = true;
          if (direction == 'up') {
            arpeggio.order = ArpeglogOrder.up;
          } else if (direction == 'down') {
            arpeggio.order = ArpeglogOrder.down;
          } else {
            arpeggio.order = ArpeglogOrder.none;
          }
        }
        if (xmlArpeggiate.name.startsWith('non')) {
          arpeggio.order = ArpeglogOrder.nonarp;
        }
        _arpeggioStack.add((arpeggio, _OpenArpeggio(arpegN, onset)));
        controlElements.add((measureNum, arpeggio));
      }
    }

    // tremolo end
    if (tremoloOnNotations) {
      if (hasAttributeWithValue(tremoloNode!, 'type', 'stop')) {
        removeLastFromStack(ClassId.fTrem, layer);
      } else if (!hasAttributeWithValue(tremoloNode, 'type', 'start') &&
          !isChord) {
        removeLastFromStack(ClassId.bTrem, layer);
      }
    }

    // tuplet end
    final bool tupletEnd =
        xpathExists(node, "notations/tuplet[@type='stop']");
    if (tupletEnd) {
      removeLastFromStack(ClassId.tuplet, layer);
    }

    // beam end
    final bool beamEnd = xpathExists(node, "beam[text()='end']");
    if (beamEnd) {
      final int breakSec =
          xpathNodes(node, "beam[text()='continue']").length;
      if (breakSec != 0) {
        if (element.classId == ClassId.note) {
          (element as Note).breaksec = breakSec;
        } else if (element.classId == ClassId.chord) {
          (element as Chord).breaksec = breakSec;
        } else if (element.classId == ClassId.tabGrp) {
          (element as TabGrp).breaksec = breakSec;
        }
        if (element.classId == ClassId.rest) {
          (element as Rest).breaksec = breakSec;
        }
      } else {
        if (isInStack(ClassId.beam, layer)) {
          removeLastFromStack(ClassId.beam, layer);
        } else {
          closeBeamSpan(staff, layer, element);
        }
      }
    }

    // add StartIDs to dir, dynam, and pedal
    if (dirStack.isNotEmpty) {
      for (final Dir dir in dirStack) {
        if (!dir.hasStaff) {
          dir.staff = [staff.n ?? 0];
        }
      }
      dirStack.clear();
    }
    if (dynamStack.isNotEmpty) {
      for (final Dynam dynam in dynamStack) {
        if (!dynam.hasStaff) {
          dynam.staff = [staff.n ?? 0];
        }
      }
      dynamStack.clear();
    }
    if (harmStack.isNotEmpty) {
      for (final Harm harm in harmStack) {
        harm.staff = [staff.n ?? 0];
      }
      harmStack.clear();
    }
    if (octaveStack.isNotEmpty) {
      for (final Octave oct in octaveStack) {
        oct.staff = [staff.n ?? 0];
        oct.startid = id;
      }
      octaveStack.clear();
    }
    if (pedalStack.isNotEmpty) {
      for (final Pedal ped in pedalStack) {
        if (!ped.hasStaff) {
          ped.staff = [staff.n ?? 0];
        }
      }
      pedalStack.clear();
    }
    if (_bracketStack.isNotEmpty) {
      for (final (BracketSpan bracketSpan, _) in _bracketStack) {
        if (!bracketSpan.hasStaff) {
          bracketSpan.staff = [staff.n ?? 0];
        }
      }
    }
    if (tempoStack.isNotEmpty) {
      for (final Tempo tempo in tempoStack) {
        if (!tempo.hasStaff) {
          tempo.staff = [staff.n ?? 0];
        }
      }
      tempoStack.clear();
    }
  }

  // =========================================================================
  // Accidentals / print / sound
  // =========================================================================

  /// Mirrors `AddAccidental`.
  void addAccidental(MeiXmlNode accidental, Note note) {
    final Accid accid = Accid();
    accid.accid = convertAccidentalToAccid(getContent(accidental));
    accid.color = accidental.attr('color');
    accid.glyphName = accidental.attr('smufl');
    if (accid.hasGlyphName) {
      accid.glyphAuth = 'smufl';
      if (!accid.hasAccid) {
        accid.accid = AccidentalWritten.n;
      }
    }
    accid.place = strToStaffrel(accidental.attr('placement') ?? '');
    if (accidental.hasAttr('id')) accid.id = accidental.attr('id')!;
    if (hasAttributeWithValue(accidental, 'cautionary', 'yes')) {
      accid.func = AccidlogFunc.caution;
    }
    if (hasAttributeWithValue(accidental, 'editorial', 'yes')) {
      accid.func = AccidlogFunc.edit;
    }
    if (hasAttributeWithValue(accidental, 'bracket', 'yes')) {
      accid.enclose = Enclosure.brack;
    }
    if (hasAttributeWithValue(accidental, 'parentheses', 'yes')) {
      accid.enclose = Enclosure.paren;
    }
    if (accidental.name == 'accidental-mark') accid.onstaff = false;
    note.addChild(accid);
  }

  /// Mirrors `ReadMusicXmlPrint`.
  void readMusicXmlPrint(MeiXmlNode node, Section section) {
    if (node.attr('new-page') == 'true') {
      final int pageBreaks =
          strToInt(node.attr('blank-page') ?? '') + 1;
      for (int i = 0; i < pageBreaks; ++i) {
        final Pb pb = Pb();
        section.addChild(pb);
      }
    }

    if (node.attr('new-system') == 'true') {
      final Sb sb = Sb();
      section.addChild(sb);
    }

    if (getContent(node.child('measure-numbering')) == 'none') {
      final Object? scoreDef = doc.getFirstScoreDef();
      if (scoreDef != null) {
        (scoreDef as dynamic).mnumVisible = false;
      }
    }
  }

  /// Mirrors `ReadMusicXmlSound`.
  void readMusicXmlSound(MeiXmlNode node, Measure measure, Section section) {
    // get MEI tuning
    final MeiXmlNode? meiTuning =
        xpathFirst(node, "play/other-play[@type='tuning-mei']");
    if (meiTuning != null) {
      final String value = getContent(meiTuning).trim();
      Temperament temperament = Temperament.none;
      if (value == 'none' || value == '') {
        temperament = Temperament.none;
      } else if (value == 'equal') {
        temperament = Temperament.equal;
      } else if (value == 'just') {
        temperament = Temperament.just;
      } else if (value == 'mean') {
        temperament = Temperament.mean;
      } else if (value == 'pythagorean') {
        temperament = Temperament.pythagorean;
      } else {
        logWarning("MusicXML import: Invalid MEI temperament '$value'");
      }
      final ScoreDef? scoreDef = getOrCreateLastScoreDef(section);
      assert(scoreDef != null);
      scoreDef!.tuneTemper = temperament;
    }

    // get custom (Ableton) tuning
    final MeiXmlNode? abletonTuning =
        xpathFirst(node, "play/other-play[@type='tuning-ableton']");
    if (abletonTuning != null) {
      // The ScoreDef model does not carry custom tunings yet; the definition
      // parsing itself is available through CustomTuning.fromDefinition but
      // cannot be attached until then.
      logWarning('MusicXML import: Custom (Ableton) tuning definitions are '
          'not supported yet');
    }

    // segno
    if (node.hasAttr('segno')) {
      _sectionStart ??= _SectionInfo();
      _sectionStart!.label = node.attr('segno')!;
      if (_sectionStart!.label.isEmpty) _sectionStart!.label = 'segno';
    }

    // coda
    if (node.hasAttr('coda')) {
      _sectionStart ??= _SectionInfo();
      _sectionStart!.label = node.attr('coda')!;
      if (_sectionStart!.label.isEmpty) _sectionStart!.label = 'coda';
    }

    // forward-repeat
    if (hasAttributeWithValue(node, 'forward-repeat', 'yes')) {
      _sectionStart ??= _SectionInfo();
    }

    // dacapo
    if (hasAttributeWithValue(node, 'dacapo', 'yes')) {
      _sectionStop ??= _SectionInfo();
      _jumpInfo = (_JumpInfo()
            ..jump = _JumpType.dacapo
            ..times =
                parseInts(node.attr('time-only') ?? '1'));
    }

    // dalsegno
    if (node.hasAttr('dalsegno')) {
      _sectionStop ??= _SectionInfo();
      String labelName = node.attr('dalsegno')!;
      if (labelName.isEmpty) labelName = 'segno';
      _jumpInfo = (_JumpInfo()
            ..jump = _JumpType.dalsegno
            ..label = labelName
            ..times = parseInts(node.attr('time-only') ?? '1'));
    }

    // tocoda
    if (node.hasAttr('tocoda')) {
      _sectionStop ??= _SectionInfo();
      String labelName = node.attr('tocoda')!;
      if (labelName.isEmpty) labelName = 'coda';
      _jumpInfo = (_JumpInfo()
            ..jump = _JumpType.tocoda
            ..label = labelName
            ..times = parseInts(node.attr('time-only') ?? '2'));
    }

    // fine
    if (node.hasAttr('fine')) {
      _sectionStop ??= _SectionInfo();
      _fineInfo = _FineInfo()..fine = true;
    }
  }

  // =========================================================================
  // Beams / tuplets / ties
  // =========================================================================

  /// Mirrors `ReadMusicXmlBeamsAndTuplets`. Returns false when the beam has
  /// no end within the measure (a `<beamSpan>` will be created instead).
  bool readMusicXmlBeamsAndTuplets(MeiXmlNode node, Layer layer, bool isChord) {
    final MeiXmlNode? beamStart =
        xpathFirst(node, "beam[@number='1' and text()='begin']");
    final MeiXmlNode? tupletStart =
        xpathFirst(node, "notations/tuplet[@type='start']");
    final MeiXmlNode? currentMeasure = xpathFirst(node, 'ancestor::measure');

    final MeiXmlNode? beamEndNode = xpathFirst(
        node,
        "./following-sibling::note[beam[@number='1' and text()='end']]");
    final MeiXmlNode? tupletEnd = xpathFirst(node,
        "./following-sibling::note[notations/tuplet[@type='stop']]");

    final List<MeiXmlNode> currentMeasureNodes =
        currentMeasure?.childrenElements() ?? const [];
    // in case note is a start of both beam and tuplet - figure out which one
    // is longer
    if (beamStart != null && tupletStart != null) {
      final int beamEndIndex = currentMeasureNodes
          .indexWhere((n) => identical(n, beamEndNode));
      final int tupletEndIndex = currentMeasureNodes
          .indexWhere((n) => identical(n, tupletEnd));

      // find distance between iterators, i.e. whether beam or tuplet ends
      // first. Negative number - beam ends first, positive - tuplet, zero -
      // both are of the same length.
      final int distance = (beamEndIndex == -1 || tupletEndIndex == -1)
          ? 0
          : tupletEndIndex - beamEndIndex;
      if (distance > 0) {
        if (!isChord) readMusicXmlTupletStart(node, tupletStart, layer);
        readMusicXmlBeamStart(node, beamStart, layer);
      } else {
        readMusicXmlBeamStart(node, beamStart, layer);
        if (!isChord) readMusicXmlTupletStart(node, tupletStart, layer);
      }
    }
    // If note is a start of the beam only - check if there is a tuplet
    // starting/ending in the span of the whole duration of this beam
    else if (beamStart != null) {
      // find whether there is a tuplet that starts during the span of the
      // beam
      final MeiXmlNode? nextTupletStart =
          xpathFirst(node, "./following-sibling::note[notations/tuplet[@type='start']]");

      // find start and end of the beam
      final int beamStartIndex = currentMeasureNodes
          .indexWhere((n) => identical(n, node));
      int beamEndIterator = currentMeasureNodes
          .indexWhere((n) => identical(n, beamEndNode));
      if (beamEndIterator < beamStartIndex) beamEndIterator = -1;

      // find staff numbers for the corresponding elements - we do not want to
      // match beam start on one staff with beam end on another
      final int? nodeStaffNum =
          strToIntOrNull(getContent(node.child('staff')));
      final int? endBeamStaffNum =
          beamEndNode == null ? null : strToIntOrNull(getContent(beamEndNode.child('staff')));

      if (beamEndIterator == -1 ||
          ((nodeStaffNum != null) &&
              (endBeamStaffNum != null) &&
              nodeStaffNum != endBeamStaffNum)) {
        final String measureName = currentMeasure?.hasAttr('id') ?? false
            ? currentMeasure!.attr('id')!
            : (currentMeasure?.attr('number') ?? '');
        logDebug('MusicXML import: Beam without end in measure $measureName '
            'treated as <beamSpan>');
        return false;
      }
      // form vector of the beam nodes and find whether there are tuplets that
      // start or end within the beam
      final List<MeiXmlNode> beamNodes = (beamStartIndex >= 0 &&
              beamEndIterator >= beamStartIndex)
          ? currentMeasureNodes.sublist(beamStartIndex, beamEndIterator + 1)
          : <MeiXmlNode>[];
      final bool isTupletStartInBeam = nextTupletStart != null &&
          beamNodes.any((n) => identical(n, nextTupletStart));
      final bool isTupletEndInBeam =
          tupletEnd != null && beamNodes.any((n) => identical(n, tupletEnd));
      // In case there is only start/end of the tuplet in the beam, then we
      // would need to use beamSpan instead. Proper beamSpan support needs to
      // be implemented before this case can be handled correctly (see the
      // C++ TODO): for now the beam is read as-is in every case.
      if (isTupletStartInBeam != isTupletEndInBeam) {
        logDebug('MusicXML import: Tuplet partially overlapping beam treated '
            'as plain beam');
      }
      readMusicXmlBeamStart(node, beamStart, layer);
    }
    // no special logic needed if we have just tupletStart - just read as is
    else if (tupletStart != null) {
      if (!isChord) readMusicXmlTupletStart(node, tupletStart, layer);
    }

    return true;
  }

  /// Mirrors `ReadMusicXmlTupletStart`.
  void readMusicXmlTupletStart(
      MeiXmlNode node, MeiXmlNode? tupletStart, Layer layer) {
    if (tupletStart == null) return;

    final Tuplet tuplet = Tuplet();
    addLayerElement(layer, tuplet);
    _stackFor(layer).add(tuplet);
    int num = strToInt(
        getContent(xpathFirst(node, 'time-modification/actual-notes')));
    int numbase = strToInt(
        getContent(xpathFirst(node, 'time-modification/normal-notes')));
    if (tupletStart.firstChild() != null) {
      num = strToInt(
          getContent(xpathFirst(tupletStart, 'tuplet-actual/tuplet-number')));
      numbase = strToInt(
          getContent(xpathFirst(tupletStart, 'tuplet-normal/tuplet-number')));
    }
    if (num != 0) tuplet.num = num;
    if (numbase != 0) tuplet.numbase = numbase;
    tuplet.numPlace =
        strToStaffrelBasic(tupletStart.attr('placement') ?? '');
    tuplet.bracketPlace =
        strToStaffrelBasic(tupletStart.attr('placement') ?? '');
    tuplet.numFormat =
        convertTupletNumberValue(tupletStart.attr('show-number') ?? '');
    if (hasAttributeWithValue(tupletStart, 'show-number', 'none')) {
      tuplet.numVisible = false;
    }
    tuplet.bracketVisible =
        convertWordToBool(tupletStart.attr('bracket') ?? '') ?? false;
  }

  /// Mirrors `ReadMusicXmlBeamStart`.
  void readMusicXmlBeamStart(
      MeiXmlNode node, MeiXmlNode? beamStart, Layer layer) {
    if (beamStart == null ||
        xpathExists(node, "notations/ornaments/tremolo[@type='start']")) {
      return;
    }
    if (_stackFor(layer).isNotEmpty &&
        _stackFor(layer).last.classId == ClassId.beam) {
      logDebug('MusicXML import: Adding a beam to a beam');
      if (node.child('grace') == null) return;
    }

    final Beam beam = Beam();
    if (beamStart.hasAttr('id')) beam.id = beamStart.attr('id')!;
    if (beamStart.hasAttr('fan')) {
      beam.form = convertBeamFanToForm(beamStart.attr('fan') ?? '');
    }
    addLayerElement(layer, beam);
    _stackFor(layer).add(beam);
  }

  /// Mirrors `ReadMusicXmlTies`.
  void readMusicXmlTies(
      MeiXmlNode node, Layer layer, Note note, String measureNum) {
    final List<MeiXmlNode> xmlTies = xpathNodes(node, 'notations/tied');
    for (final MeiXmlNode xmlTie in xmlTies) {
      final String tieType = xmlTie.attr('type') ?? '';

      if (tieType.isEmpty) {
        continue;
      } else if (tieType == 'stop') {
        // add to stack if (endTie) or if pitch/oct match to open tie on stack
        if (_tieStack.isNotEmpty &&
            _tieStack.last.note != null &&
            isEnharmonicWith(note, _tieStack.last.note!) &&
            _tieStack.last.layerNum == layer.n) {
          _tieStack.last.tie!.endid = '#${note.id}';
          _tieStack.removeLast();
        } else {
          closeTie(note, layer.n ?? 0);
        }
      }
      // if we have start attribute - start new tie
      else if (tieType == 'start') {
        final Tie tie = Tie();
        tie.color = xmlTie.attr('color');
        tie.curvedir = inferCurvedir(xmlTie);
        tie.lform = strToLineform(xmlTie.attr('line-type') ?? '');
        if (xmlTie.hasAttr('id')) tie.id = xmlTie.attr('id')!;
        // add it to the stack
        controlElements.add((measureNum, tie));
        openTie(note, tie, layer.n ?? 0);
      }
      // or add lv element if let-ring attribute present
      else if (tieType == 'let-ring') {
        final Lv lv = Lv();
        lv.color = xmlTie.attr('color');
        lv.curvedir = inferCurvedir(xmlTie);
        lv.lform = strToLineform(xmlTie.attr('line-type') ?? '');
        if (xmlTie.hasAttr('id')) lv.id = xmlTie.attr('id')!;
        controlElements.add((measureNum, lv));
        // set startid to the current note and set second timestamp (endpoint)
        // right away, since we're going to link <lv> not to another element,
        // but to timestamp
        lv.startid = '#${note.id}';
        double tstamp = math.min(
            (layerEndTimes[layer] ?? 0).toDouble(), durTotal + 2.0);
        tstamp = math.max(tstamp, durTotal + 1.25);
        lv.tstamp2 = MeasureBeat(
            0, tstamp * meterUnit / (4.0 * ppq) + 1);
      }
    }
  }

  // =========================================================================
  // Clef / key / scoreDef conversion
  // =========================================================================

  /// Mirrors `ConvertClef`.
  Clef? convertClef(MeiXmlNode? clef) {
    final MeiXmlNode? clefSign = clef?.child('sign');
    if (clefSign != null && getContent(clefSign) != 'none') {
      final Clef meiClef = Clef();
      meiClef.color = clef!.attr('color');
      meiClef.visible = convertWordToBool(clef.attr('print-object') ?? '');
      if (clef.hasAttr('id')) {
        meiClef.id = clef.attr('id')!;
      }
      meiClef.shape =
          strToClefshape(getContent(clefSign).substring(0, math.min(4, getContent(clefSign).length)));

      // clef line
      final MeiXmlNode? clefLine = clef.child('line');
      if (clefLine != null && clefLine.textValue() != null) {
        if (meiClef.shape != Clefshape.perc) {
          meiClef.line = strToInt(getContent(clefLine));
        }
      } else {
        switch (meiClef.shape) {
          case Clefshape.c:
            meiClef.line = 3;
            break;
          case Clefshape.f:
            meiClef.line = 4;
            break;
          case Clefshape.g:
            meiClef.line = 2;
            break;
          case Clefshape.tab:
            meiClef.line = 5;
            break;
          default:
            break;
        }
      }

      // clef octave change
      final MeiXmlNode? clefOctaveChange = clef.child('clef-octave-change');
      if (clefOctaveChange != null) {
        final int change = strToInt(getContent(clefOctaveChange));
        switch (change.abs()) {
          case 1:
            meiClef.dis = OctaveDis.n8;
            break;
          case 2:
            meiClef.dis = OctaveDis.n15;
            break;
          case 3:
            meiClef.dis = OctaveDis.n22;
            break;
          default:
            break;
        }
        if (change < 0) {
          meiClef.disPlace = StaffrelBasic.below;
        } else if (change > 0) {
          meiClef.disPlace = StaffrelBasic.above;
        }
      }
      return meiClef;
    }

    return null;
  }

  /// Mirrors `ConvertKey`.
  KeySig convertKey(MeiXmlNode key) {
    final KeySig keySig = KeySig();
    keySig.visible = convertWordToBool(key.attr('print-object') ?? '');
    if (key.hasAttr('id')) {
      keySig.id = key.attr('id')!;
    }
    if (key.child('fifths') != null) {
      final int fifths = strToInt(getContent(key.child('fifths')));
      String keySigStr;
      if (fifths < 0) {
        keySigStr = '${fifths.abs()}f';
      } else if (fifths > 0) {
        keySigStr = '${fifths}s';
      } else {
        keySigStr = '0';
      }
      keySig.sig = strToKeysignature(keySigStr);

      if (key.child('cancel') != null) {
        keySig.cancelaccid = Cancelaccid.before;
      }
      if (key.child('mode') != null) {
        final String xmlMode = getContent(key.child('mode'));
        if (!xmlMode.startsWith('none')) {
          keySig.mode = strToMode(xmlMode);
        }
      }
    } else if (key.child('key-step') != null) {
      for (final MeiXmlNode keyStep in key.childrenElements()) {
        if (keyStep.name != 'key-step') continue;
        final KeyAccid keyAccid = KeyAccid();
        keyAccid.pname = convertStepToPitchName(getContent(keyStep));
        final MeiXmlNode? nextSiblingElement =
            _nextSiblingElementOf(keyStep);
        if (nextSiblingElement != null &&
            nextSiblingElement.name.startsWith('key-alter')) {
          final AccidentalGestural accidValue =
              convertAlterToAccid(strToDblPrefix(getContent(nextSiblingElement)));
          keyAccid.accid = accidentalGesturalToWritten(accidValue);
          final MeiXmlNode? nextNext =
              _nextSiblingElementOf(nextSiblingElement);
          if (nextNext != null && nextNext.name.startsWith('key-accidental')) {
            keyAccid.accid = convertAccidentalToAccid(getContent(nextNext));
            keyAccid.glyphName = nextNext.attr('smufl');
          } else if (!keyAccid.hasAccid) {
            logWarning('MusicXML import: Could not properly set keyAccid');
          }
        }
        keySig.addChild(keyAccid);
      }
    }

    // adjust the accidentals map to this key signature
    resetAccidentals(keySig);
    currentKeySig = keySig;

    return keySig;
  }

  /// The next element sibling of [node] (null when none).
  static MeiXmlNode? _nextSiblingElementOf(MeiXmlNode node) {
    MeiXmlNode? current = node.nextSibling();
    while (current != null && !current.isElement) {
      current = current.nextSibling();
    }
    return current;
  }

  /// Mirrors `GetOrCreateLastScoreDef`.
  ScoreDef? getOrCreateLastScoreDef(Section section) {
    // return the ScoreDef that's after last measure in the section
    // if not found, create it
    ScoreDef? scoreDef = section.getLast(ClassId.scoreDef) as ScoreDef?;
    final Measure? measure = section.getLast(ClassId.measure) as Measure?;
    if (measure == null ||
        scoreDef == null ||
        (scoreDef.idx ?? -1) < (measure.idx ?? -1)) {
      scoreDef = ScoreDef();
      section.addChild(scoreDef);
    }
    return scoreDef;
  }

  /// Mirrors `ResetAccidentals` — inspired by KeySig::FillMap() but without
  /// the octave repetitions.
  void resetAccidentals([KeySig? keySig]) {
    _currentAccids.clear();
    for (int i = Pitchname.c.value; i <= Pitchname.b.value; i++) {
      _currentAccids[Pitchname.fromValue(i)] = [_XmlAccidental()];
    }

    if (keySig == null) return;

    final List<Object> childList =
        keySig.getList(); // make sure it's initialized
    if (childList.isNotEmpty) {
      for (final Object child in childList) {
        final KeyAccid keyAccid = child as KeyAccid;
        _currentAccids[keyAccid.pname!] = [
          _XmlAccidental(
              keyAccid.accid ?? AccidentalWritten.none,
              keyAccid.glyphName ?? '',
              keyAccid.glyphAuth ?? '')
        ];
      }
      return;
    }

    final AccidentalWritten accidType = keySig.getAccidType();
    for (int i = 0; i < keySig.getAccidCount(fromAttribute: true); ++i) {
      _currentAccids[KeySig.getAccidPnameAt(accidType, i)] = [
        _XmlAccidental(accidType, '', '')
      ];
    }
  }

  /// Mirrors `MeasureInExistingSection`.
  bool measureInExistingSection(Measure measure) {
    for (final MapEntry<_SectionInfo, List<Measure>> section in _sections) {
      for (final Measure sectionMeasure in section.value) {
        if (sectionMeasure.id == measure.id) return true;
      }
    }
    return false;
  }

  /// Mirrors `IsMultirestMeasure`.
  bool isMultirestMeasure(int index) {
    for (final MapEntry<int, int> multiRest in multiRests.entries) {
      if (index <= multiRest.key) return false;
      if (index <= multiRest.value) return true;
    }
    return false;
  }

  /// Mirrors `GetMrestMeasuresCountBeforeIndex`.
  int getMrestMeasuresCountBeforeIndex(int index) {
    int count = 0;
    for (final MapEntry<int, int> multiRest in multiRests.entries) {
      if (index <= multiRest.key) break;
      count += multiRest.value - multiRest.key;
    }
    return count;
  }

  /// Mirrors `GetOrnamentGlyphNumber`.
  String getOrnamentGlyphNumber(int attributes) {
    const Map<int, String> precomposedNames = {
      _MordentExtSymbolFlags.apprAbove | _MordentExtSymbolFlags.formInverted:
          'U+E5C6',
      _MordentExtSymbolFlags.apprBelow | _MordentExtSymbolFlags.formInverted:
          'U+E5B5',
      _MordentExtSymbolFlags.apprAbove | _MordentExtSymbolFlags.formNormal:
          'U+E5C7',
      _MordentExtSymbolFlags.apprBelow | _MordentExtSymbolFlags.formNormal:
          'U+E5B8',
      _MordentExtSymbolFlags.formInverted | _MordentExtSymbolFlags.depAbove:
          'U+E5BB',
      _MordentExtSymbolFlags.formInverted | _MordentExtSymbolFlags.depBelow:
          'U+E5C8',
      // these values need to be matched with proper SMuFL codes first
    };

    return precomposedNames[attributes] ?? '';
  }

  /// Mirrors `SetChordStaff`.
  void setChordStaff(Layer layer) {
    // if all notes in the chord have @staff attribute set one for the chord
    if (_stackFor(layer).isEmpty ||
        _stackFor(layer).last.classId != ClassId.chord) {
      return;
    }
    final Chord chord = _stackFor(layer).last as Chord;

    final List<Object> children = chord.children;
    bool noteWithoutStaff = false;
    for (final Object object in children) {
      if (object.classId != ClassId.note) continue;
      if (!(object as Note).hasStaff) noteWithoutStaff = true;
    }
    if (noteWithoutStaff) return;

    // if all notes have @staff attribute, but it's not the same staff of at
    // least one note - leave it as is
    final Note firstNote = chord.getFirst(ClassId.note)! as Note;
    final List<int>? chordStaff = firstNote.staff;
    bool differingStaff = false;
    for (final Object object in children) {
      if (object.classId != ClassId.note) continue;
      final Note n = object as Note;
      if (!_listEquals(chordStaff, n.staff)) differingStaff = true;
    }
    if (differingStaff) return;

    // Now that we're sure cross-staff is the same for all notes, we can set
    // it to the chord and clear it from notes.
    chord.staff = chordStaff == null ? null : [...chordStaff];
    for (final Object object in children) {
      if (object.classId != ClassId.note) continue;
      (object as Note).staff = null;
    }
  }

  static bool _listEquals(List<int>? a, List<int>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; ++i) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // =========================================================================
  // Pitch conversions
  // =========================================================================

  /// Mirrors `PitchToMidi`.
  static int pitchToMidi(String step, int alter, int octave) {
    if (step.isEmpty || step.codeUnitAt(0) < 0x41 || step.codeUnitAt(0) > 0x47) {
      return 0;
    }

    // Distance in semitones from the octave's starting C to the given step
    //                                 A   B  C  D  E  F  G
    const List<int> octaveStart = [9, 11, 0, 2, 4, 5, 7];
    final int semitones = octave * 12 +
        octaveStart[step.codeUnitAt(0) - 0x41] +
        alter; // semitones from C0
    return semitones + 12; // MIDI note C4 = 60
  }

  /// Mirrors `MidiToPitch`. Returns `(step, alter, octave)`.
  static (String, int, int) midiToPitch(int midi) {
    final int semitones = midi - 12; // C0 = 0

    // 12 notes in an octave. Ignore enharmonics, prefer B flat over A sharp.
    const List<(String, int)> octaveNotes = [
      ('C', 0), ('C', 1), ('D', 0), ('D', 1), //
      ('E', 0), ('F', 0), ('F', 1), ('G', 0), //
      ('G', 1), ('A', 0), ('B', -1), ('B', 0),
    ];

    final int octave = semitones ~/ 12;
    final (String, int) note = octaveNotes[semitones % 12];
    return (note.$1, note.$2, octave);
  }

  /// Mirrors `Note::IsEnharmonicWith` (MIDI pitch equality).
  static bool isEnharmonicWith(Note a, Note b) =>
      _midiPitchOf(a) == _midiPitchOf(b);

  /// Simplified port of `Note::GetMIDIPitch` for tie matching.
  static int _midiPitchOf(Note note) {
    if (note.hasPname || note.hasPnameGes) {
      Pitchname pname = note.pname ?? Pitchname.none;
      if (pname == Pitchname.none && note.hasPnameGes) {
        pname = note.pnameGes!;
      }
      if (pname == Pitchname.none) return 0;

      int oct = note.oct ?? 0;
      if (note.hasOctGes) oct = note.octGes!;

      return _pnameToPclass(pname) + _chromaticAlteration(note) + (oct + 1) * 12;
    }
    return 0;
  }

  static int _pnameToPclass(Pitchname pname) {
    switch (pname) {
      case Pitchname.c:
        return 0;
      case Pitchname.d:
        return 2;
      case Pitchname.e:
        return 4;
      case Pitchname.f:
        return 5;
      case Pitchname.g:
        return 7;
      case Pitchname.a:
        return 9;
      case Pitchname.b:
        return 11;
      default:
        return 0;
    }
  }

  /// Port of `Note::GetChromaticAlteration` restricted to accid children.
  static int _chromaticAlteration(Note note) {
    final Accid? accid =
        note.findDescendantByType(ClassId.accid, deepness: 1) as Accid?;
    if (accid == null) return 0;
    return chromaticAlteration(accid.accidGes, accid.accid);
  }

  /// Mirrors `TransPitch::GetChromaticAlteration` for basic values.
  static int chromaticAlteration(
      AccidentalGestural? ges, AccidentalWritten? written) {
    if (ges != null) {
      switch (ges) {
        case AccidentalGestural.s:
          return 1;
        case AccidentalGestural.f:
          return -1;
        case AccidentalGestural.ss:
          return 2;
        case AccidentalGestural.ff:
          return -2;
        case AccidentalGestural.ts:
          return 3;
        case AccidentalGestural.tf:
          return -3;
        case AccidentalGestural.n:
          return 0;
        case AccidentalGestural.xu:
          return 2;
        case AccidentalGestural.su:
          return 1;
        case AccidentalGestural.sd:
          return 1;
        case AccidentalGestural.fu:
          return -1;
        case AccidentalGestural.fd:
          return -1;
        default:
          return 0;
      }
    }
    if (written != null) {
      switch (written) {
        case AccidentalWritten.s:
        case AccidentalWritten.su:
        case AccidentalWritten.sd:
          return 1;
        case AccidentalWritten.f:
        case AccidentalWritten.fu:
        case AccidentalWritten.fd:
          return -1;
        case AccidentalWritten.ss:
        case AccidentalWritten.x:
        case AccidentalWritten.sx:
        case AccidentalWritten.xs:
        case AccidentalWritten.ts:
        case AccidentalWritten.xu:
        case AccidentalWritten.xd:
          return 2;
        case AccidentalWritten.ff:
        case AccidentalWritten.tf:
        case AccidentalWritten.ffu:
        case AccidentalWritten.ffd:
          return -2;
        default:
          return 0;
      }
    }
    return 0;
  }

  /// Mirrors `Att::AccidentalWrittenToGestural`.
  static AccidentalGestural accidentalWrittenToGestural(
      AccidentalWritten accid) {
    switch (accid) {
      case AccidentalWritten.s:
        return AccidentalGestural.s;
      case AccidentalWritten.f:
        return AccidentalGestural.f;
      case AccidentalWritten.ss:
      case AccidentalWritten.x:
        return AccidentalGestural.ss;
      case AccidentalWritten.ff:
        return AccidentalGestural.ff;
      case AccidentalWritten.xs:
      case AccidentalWritten.sx:
      case AccidentalWritten.ts:
        return AccidentalGestural.ss;
      case AccidentalWritten.tf:
        return AccidentalGestural.ff;
      case AccidentalWritten.n:
        return AccidentalGestural.n;
      case AccidentalWritten.nf:
        return AccidentalGestural.f;
      case AccidentalWritten.ns:
        return AccidentalGestural.s;
      case AccidentalWritten.su:
        return AccidentalGestural.su;
      case AccidentalWritten.sd:
        return AccidentalGestural.sd;
      case AccidentalWritten.fu:
        return AccidentalGestural.fu;
      case AccidentalWritten.fd:
        return AccidentalGestural.fd;
      case AccidentalWritten.nu:
      case AccidentalWritten.nd:
        return AccidentalGestural.n;
      case AccidentalWritten.n1qf:
        return AccidentalGestural.fu;
      case AccidentalWritten.n3qf:
        return AccidentalGestural.fd;
      case AccidentalWritten.n1qs:
        return AccidentalGestural.su;
      case AccidentalWritten.n3qs:
        return AccidentalGestural.sd;
      default:
        return AccidentalGestural.none;
    }
  }

  /// Mirrors `Att::AccidentalGesturalToWritten`.
  static AccidentalWritten accidentalGesturalToWritten(
      AccidentalGestural accidGes) {
    switch (accidGes) {
      case AccidentalGestural.s:
        return AccidentalWritten.s;
      case AccidentalGestural.f:
        return AccidentalWritten.f;
      case AccidentalGestural.ss:
        return AccidentalWritten.ss;
      case AccidentalGestural.ff:
        return AccidentalWritten.ff;
      case AccidentalGestural.n:
        return AccidentalWritten.n;
      case AccidentalGestural.su:
        return AccidentalWritten.su;
      case AccidentalGestural.sd:
        return AccidentalWritten.sd;
      case AccidentalGestural.fu:
        return AccidentalWritten.fu;
      case AccidentalGestural.fd:
        return AccidentalWritten.fd;
      default:
        return AccidentalWritten.none;
    }
  }

  /// Convert gestural alteration to its written counterpart for course
  /// tunings (mirrors the C++ static_cast with identical enum values).
  static AccidentalWritten convertAlterToAccidWritten(double value) {
    final AccidentalGestural ges = convertAlterToAccid(value);
    // ACCIDENTAL_GESTURAL_f/s share their numeric value with the written ones.
    switch (ges) {
      case AccidentalGestural.f:
        return AccidentalWritten.f;
      case AccidentalGestural.s:
        return AccidentalWritten.s;
      case AccidentalGestural.ss:
        return AccidentalWritten.ss;
      case AccidentalGestural.tf:
        return AccidentalWritten.tf;
      case AccidentalGestural.ffd:
        return AccidentalWritten.ffd;
      case AccidentalGestural.fd:
        return AccidentalWritten.fd;
      case AccidentalGestural.fu:
        return AccidentalWritten.fu;
      case AccidentalGestural.n:
        return AccidentalWritten.n;
      case AccidentalGestural.sd:
        return AccidentalWritten.sd;
      case AccidentalGestural.su:
        return AccidentalWritten.su;
      case AccidentalGestural.xu:
        return AccidentalWritten.xu;
      case AccidentalGestural.ts:
        return AccidentalWritten.ts;
      default:
        return AccidentalWritten.none;
    }
  }

  // =========================================================================
  // String to attribute converters
  // =========================================================================

  /// Mirrors `ConvertAccidentalToAccid`.
  static AccidentalWritten convertAccidentalToAccid(String value) {
    const Map<String, AccidentalWritten> accidental2Accid = {
      'sharp': AccidentalWritten.s,
      'natural': AccidentalWritten.n,
      'flat': AccidentalWritten.f,
      'double-sharp': AccidentalWritten.x,
      'sharp-sharp': AccidentalWritten.ss,
      'flat-flat': AccidentalWritten.ff,
      'natural-sharp': AccidentalWritten.ns,
      'natural-flat': AccidentalWritten.nf,
      'quarter-flat': AccidentalWritten.n1qf,
      'quarter-sharp': AccidentalWritten.n1qs,
      'three-quarters-flat': AccidentalWritten.n3qf,
      'three-quarters-sharp': AccidentalWritten.n3qs,
      'sharp-down': AccidentalWritten.sd,
      'sharp-up': AccidentalWritten.su,
      'natural-down': AccidentalWritten.nd,
      'natural-up': AccidentalWritten.nu,
      'flat-down': AccidentalWritten.fd,
      'flat-up': AccidentalWritten.fu,
      'double-sharp-down': AccidentalWritten.xd,
      'double-sharp-up': AccidentalWritten.xu,
      'flat-flat-down': AccidentalWritten.ffd,
      'flat-flat-up': AccidentalWritten.ffu,
      'triple-sharp': AccidentalWritten.ts,
      'triple-flat': AccidentalWritten.tf,
      'slash-quarter-sharp': AccidentalWritten.bms,
      'slash-sharp': AccidentalWritten.ks,
      'slash-flat': AccidentalWritten.bf,
      'double-slash-flat': AccidentalWritten.bmf,
      'sori': AccidentalWritten.sori,
      'koron': AccidentalWritten.koron,
      'other': AccidentalWritten.none,
    };

    final result = accidental2Accid[value];
    if (result != null) return result;

    logWarning("MusicXML import: Unsupported accidental value '$value'");
    return AccidentalWritten.none;
  }

  /// Mirrors `ConvertAlterToAccid`.
  static AccidentalGestural convertAlterToAccid(double value) {
    final Map<double, AccidentalGestural> alter2Accid = {
      -3: AccidentalGestural.tf,
      -2.5: AccidentalGestural.ffd,
      -2: AccidentalGestural.ff,
      -1.5: AccidentalGestural.fd,
      -1: AccidentalGestural.f,
      -0.5: AccidentalGestural.fu,
      0: AccidentalGestural.n,
      0.5: AccidentalGestural.sd,
      1: AccidentalGestural.s,
      1.5: AccidentalGestural.su,
      2: AccidentalGestural.ss,
      2.5: AccidentalGestural.xu,
    };

    final result = alter2Accid[value];
    if (result != null) return result;

    return AccidentalGestural.none;
  }

  /// Mirrors `ConvertArticulations`.
  static Articulation convertArticulations(String value) {
    const Map<String, Articulation> articulations2Id = {
      // articulations
      'accent': Articulation.acc,
      'detached-legato': Articulation.stacc,
      'doit': Articulation.doit,
      'falloff': Articulation.fall,
      'plop': Articulation.plop,
      'scoop': Articulation.scoop,
      'soft-accent': Articulation.accSoft,
      'spiccato': Articulation.spicc,
      'staccatissimo': Articulation.stacciss,
      'staccato': Articulation.stacc,
      'strong-accent': Articulation.marc,
      'tenuto': Articulation.ten,
      // technical
      'bend': Articulation.bend,
      'double-tongue': Articulation.dbltongue,
      'down-bow': Articulation.dnbow,
      'fingernails': Articulation.fingernail,
      'harmonic': Articulation.harm,
      'heel': Articulation.heel,
      'open-string': Articulation.open,
      'snap-pizzicato': Articulation.snap,
      'stopped': Articulation.stop,
      'toe': Articulation.toe,
      'triple-tongue': Articulation.trpltongue,
      'up-bow': Articulation.upbow,
    };

    final result = articulations2Id[value];
    if (result != null) return result;

    return Articulation.none;
  }

  /// Mirrors `ConvertStyleToRend`.
  static Barrendition convertStyleToRend(String value, bool repeat) {
    if (value == 'dashed') return Barrendition.dashed;
    if (value == 'dotted') return Barrendition.dotted;
    if (value == 'light-light') return Barrendition.dbl;
    if (value == 'heavy-heavy') return Barrendition.dblheavy;
    if ((value == 'light-heavy') && !repeat) return Barrendition.end;
    if (value == 'heavy') return Barrendition.heavy;
    if (value == 'none') return Barrendition.invis;
    if ((value == 'heavy-light') && repeat) return Barrendition.rptstart;
    // if (value == '') return BARRENDITION_rptboth;
    if ((value == 'light-heavy') && repeat) return Barrendition.rptend;
    if (value == 'regular') return Barrendition.single;
    if (value == 'short') return Barrendition.single;
    if (value == 'tick') return Barrendition.single;
    logWarning("MusicXML import: Unsupported bar-style '$value'");
    return Barrendition.none;
  }

  /// Mirrors `ConvertWordToBool`.
  static bool? convertWordToBool(String value) {
    if (value == 'yes') return true;
    if (value == 'no') return false;

    return null;
  }

  /// Mirrors `ConvertTypeToDur`.
  static MeiDuration convertTypeToDur(String value) {
    const Map<String, MeiDuration> type2Dur = {
      'maxima': MeiDuration.maxima, // this is a mensural MEI value
      'long': MeiDuration.long, // mensural MEI value longa isn't supported
      'breve': MeiDuration.breve,
      'whole': MeiDuration.dur1,
      'half': MeiDuration.dur2,
      'quarter': MeiDuration.dur4,
      'eighth': MeiDuration.dur8,
      '16th': MeiDuration.dur16,
      '32nd': MeiDuration.dur32,
      '64th': MeiDuration.dur64,
      '128th': MeiDuration.dur128,
      '256th': MeiDuration.dur256,
      '512th': MeiDuration.dur512,
      '1024th': MeiDuration.dur1024,
    };

    final result = type2Dur[value];
    if (result != null) return result;

    logWarning("MusicXML import: Unsupported note-type-value '$value'");
    return MeiDuration.none;
  }

  /// Mirrors `ConvertJumpType`.
  static RepeatmarklogFunc convertJumpType(String value) {
    const Map<String, RepeatmarklogFunc> name2Jump = {
      'coda': RepeatmarklogFunc.coda,
      'segno': RepeatmarklogFunc.segno,
    };

    final result = name2Jump[value];
    if (result != null) return result;

    return RepeatmarklogFunc.none;
  }

  /// Mirrors `ConvertEnclosure`.
  static Textrendition convertEnclosure(String value) {
    const Map<String, Textrendition> enclosure2Id = {
      'rectangle': Textrendition.box,
      'square': Textrendition.box,
      'oval': Textrendition.circle,
      'circle': Textrendition.circle,
      'triangle': Textrendition.tbox,
      'diamond': Textrendition.dbox,
      'none': Textrendition.none0,
    };

    final result = enclosure2Id[value];
    if (result != null) return result;

    return Textrendition.none;
  }

  /// Mirrors `ConvertTypeToVerovioText`.
  static String convertTypeToVerovioText(String value) {
    const Map<String, String> type2VerovioText = {
      'breve': '\uECA0',
      'whole': '\uECA2',
      'half': '\uECA3',
      'quarter': '\uECA5',
      'eighth': '\uECA7',
      '16th': '\uECA9',
      '32nd': '\uECAB',
      '64th': '\uECAD',
      '128th': '\uECAF',
      '256th': '\uECB1',
      '512th': '\uECB3',
      '1024th': '\uECB5',
    };

    final result = type2VerovioText[value];
    if (result != null) return result;

    logWarning("MusicXML import: Unsupported type '$value'");
    return '';
  }

  /// Mirrors `ConvertNotehead`.
  static HeadshapeList convertNotehead(String value) {
    const Map<String, HeadshapeList> notehead2Id = {
      'slash': HeadshapeList.slash,
      'triangle': HeadshapeList.rtriangle,
      'diamond': HeadshapeList.diamond,
      'square': HeadshapeList.square,
      'cross': HeadshapeList.plus,
      'x': HeadshapeList.x,
      'circle-x': HeadshapeList.slash,
      'inverted triangle': HeadshapeList.slash,
      'arrow down': HeadshapeList.slash,
      'arrow up': HeadshapeList.slash,
      'circle dot': HeadshapeList.circle,
    };

    final result = notehead2Id[value];
    if (result != null) return result;

    return HeadshapeList.none;
  }

  /// Mirrors `ConvertLineEndSymbol`.
  static Linestartendsymbol convertLineEndSymbol(String value) {
    const Map<String, Linestartendsymbol> lineEndSymbol2Id = {
      'up': Linestartendsymbol.angleup,
      'down': Linestartendsymbol.angledown,
      'arrow': Linestartendsymbol.arrow,
      'Hauptstimme': Linestartendsymbol.h,
      'Nebenstimme': Linestartendsymbol.n,
      'none': Linestartendsymbol.none0,
      'plain': Linestartendsymbol.none,
    };

    final result = lineEndSymbol2Id[value];
    if (result != null) return result;

    return Linestartendsymbol.none;
  }

  /// Mirrors `ConvertDynamicsToMidiVal`.
  static int convertDynamicsToMidiVal(double dynamics) {
    if (dynamics > 0.0) {
      final int mididynam = (dynamics * 90.0 / 100.0 + 0.5).truncate();
      return math.max(1, math.min(127, mididynam));
    }
    return 0;
  }

  /// Mirrors `ConvertStepToPitchName`.
  static Pitchname convertStepToPitchName(String value) {
    const Map<String, Pitchname> step2PitchName = {
      'C': Pitchname.c,
      'D': Pitchname.d,
      'E': Pitchname.e,
      'F': Pitchname.f,
      'G': Pitchname.g,
      'A': Pitchname.a,
      'B': Pitchname.b,
    };

    final result = step2PitchName[value];
    if (result != null) return result;

    logWarning("MusicXML import: Unsupported step value '$value'");
    return Pitchname.none;
  }

  /// Mirrors `InferCurvedir`.
  static CurvatureCurvedir inferCurvedir(MeiXmlNode slurOrTie) {
    final String orientation = slurOrTie.attr('orientation') ?? '';
    if (orientation == 'over') return CurvatureCurvedir.above;
    if (orientation == 'under') return CurvatureCurvedir.below;

    final String placement = slurOrTie.attr('placement') ?? '';
    if (placement == 'above') return CurvatureCurvedir.above;
    if (placement == 'below') return CurvatureCurvedir.below;

    return CurvatureCurvedir.none;
  }

  /// Mirrors `ConvertFermataShape`.
  static FermatavisShape convertFermataShape(String value) {
    const Map<String, FermatavisShape> fermataShape2Id = {
      'normal': FermatavisShape.curved,
      'angled': FermatavisShape.angular,
      'square': FermatavisShape.square,
      'double-angled': FermatavisShape.angular,
      'double-square': FermatavisShape.square,
    };

    final result = fermataShape2Id[value];
    if (result != null) return result;

    return FermatavisShape.none;
  }

  /// Mirrors `ConvertPedalTypeToDir`.
  static PedallogDir convertPedalTypeToDir(String value) {
    const Map<String, PedallogDir> pedalType2Dir = {
      'start': PedallogDir.down,
      'stop': PedallogDir.up,
      'sostenuto': PedallogDir.down,
      'change': PedallogDir.bounce,
    };

    final result = pedalType2Dir[value];
    if (result != null) return result;

    logWarning("MusicXML import: Unsupported type '$value' for pedal");
    return PedallogDir.none;
  }

  /// Mirrors `ConvertTupletNumberValue`.
  static TupletvisNumformat convertTupletNumberValue(String value) {
    if (value == 'actual') return TupletvisNumformat.count;
    if (value == 'both') return TupletvisNumformat.ratio;
    return TupletvisNumformat.none;
  }

  /// Mirrors `ConvertBeamFanToForm`.
  static BeamrendForm convertBeamFanToForm(String value) {
    if (value == 'accel') return BeamrendForm.acc;
    if (value == 'none') return BeamrendForm.norm;
    if (value == 'rit') return BeamrendForm.rit;

    return BeamrendForm.none;
  }

  /// Mirrors `ConvertAlterToSymbol`.
  static String convertAlterToSymbol(String value, [bool plusMinus = false]) {
    const Map<String, String> alter2Symbol = {
      '-2': '\u{1D12B}',
      '-1': '\u266D',
      '0': '\u266E',
      '1': '\u266F',
      '2': '\u{1D12A}',
    };

    const Map<String, String> alter2PlusMinus = {
      '-2': '--',
      '-1': '-',
      '0': '',
      '1': '+',
      '2': '++',
    };

    if (plusMinus) {
      final result = alter2PlusMinus[value];
      if (result != null) return result;
    } else {
      final result = alter2Symbol[value];
      if (result != null) return result;
    }

    return '';
  }

  /// Mirrors `ConvertKindToSymbol`.
  static String convertKindToSymbol(String value) {
    const Map<String, String> kind2Symbol = {
      'major': '', // Use no symbol to avoid ambiguity of "C△".
      'minor': '-',
      'augmented': '+',
      'diminished': '\u00B0',
      'dominant': '7',
      'major-seventh': '\u25B37',
      'minor-seventh': '-7',
      'diminished-seventh': '\u00B07',
      'augmented-seventh': '+7',
      'half-diminished': '\u00F8',
      'major-minor': '-\u25B37',
      'major-sixth': '6',
      'minor-sixth': '-6',
      'dominant-ninth': '9',
      'major-ninth': '\u25B39',
      'minor-ninth': '-9',
      'dominant-11th': '11',
      'major-11th': '\u25B311',
      'minor-11th': '-11',
      'dominant-13th': '13',
      'major-13th': '\u25B313',
      'minor-13th': '-13',
      'suspended-second': 'sus2',
      'suspended-fourth': 'sus4',
      // Skipping "functional sixths": Neapolitan, Italian, French, German.
      // Skipping pedal (pedal-point bass)
      'power': '5',
      // Skipping Tristan
    };

    return kind2Symbol[value] ?? '';
  }

  /// Mirrors `ConvertKindToText`.
  static String convertKindToText(String value) {
    const Map<String, String> kind2Text = {
      'major': '',
      'minor': 'm',
      'augmented': 'aug',
      'diminished': 'dim',
      'dominant': '7',
      'major-seventh': 'Maj7',
      'minor-seventh': 'm7',
      'diminished-seventh': 'dim7',
      'augmented-seventh': 'aug7',
      'half-diminished': 'm7\u266D5',
      'major-minor': 'mMaj7',
      'major-sixth': '6',
      'minor-sixth': 'm6',
      'dominant-ninth': '9',
      'major-ninth': 'Maj9',
      'minor-ninth': 'm9',
      'dominant-11th': '11',
      'major-11th': 'Maj11',
      'minor-11th': 'm11',
      'dominant-13th': '13',
      'major-13th': 'Maj13',
      'minor-13th': 'm13',
      'suspended-second': 'sus2',
      'suspended-fourth': 'sus4',
      // Skipping "functional sixths": Neapolitan, Italian, French, German.
      // Skipping pedal (pedal-point bass)
      'power': '5',
      // Skipping Tristan
    };

    return kind2Text[value] ?? '';
  }

  /// Maps `<kind>` values to the first interval that can get an "add" prefix
  /// (mirrors the Kind2FirstAddable map of `ConvertDegreeToText`).
  static const Map<String, int> _kind2FirstAddable = {
    'major': 9,
    'minor': 9,
    'augmented': 9,
    'diminished': 9,
    'dominant': 11,
    'major-seventh': 11,
    'minor-seventh': 11,
    'diminished-seventh': 11,
    'augmented-seventh': 11,
    'half-diminished': 11,
    'major-minor': 11,
    'major-sixth': 11,
    'minor-sixth': 11,

    // Skipping "dominant-ninth", "major-ninth" and "minor-ninth". An
    // additional 13 would not get an "add", implying to omit the 11, as the
    // 11 is regularly omitted anyway.

    // Skipping "dominant-11th", "major-11th" and "minor-11th".
    // 13 would no longer get an "add".

    // Skipping "dominant-13th", "major-13th" and "minor-13th". Nothing to
    // add anyway.

    'suspended-second': 11,
    'suspended-fourth': 9,

    // Skipping "functional sixths": Neapolitan, Italian, French, German.
    // Skipping pedal (pedal-point bass)

    'power': 7,

    // Skipping Tristan
  };

  /// Mirrors `ConvertDegreeToText`.
  static String convertDegreeToText(MeiXmlNode harmony) {
    String degreeText = '';

    for (final MeiXmlNode degree in harmony.childrenElements()) {
      if (degree.name != 'degree') continue;
      if (degreeText == '') {
        degreeText = '(';
      }

      final MeiXmlNode typeNode = degree.child('degree-type')!;
      final String type = getContent(typeNode);
      final MeiXmlNode? valueNode = degree.child('degree-value');
      if (valueNode == null) {
        // <degree-value> is required. Signal something is missing.
        degreeText += '?';
        continue;
      }
      final String degreeValue = getContent(valueNode);

      if (typeNode.hasAttr('text')) {
        degreeText += typeNode.attr('text')!;
      } else {
        if (type == 'subtract') {
          degreeText += 'no';
        } else if (type == 'add') {
          final String kind = getContent(harmony.child('kind'));
          final int? firstAddable = _kind2FirstAddable[kind];

          if (firstAddable != null &&
              (int.tryParse(degreeValue) ?? 0) >= firstAddable) {
            degreeText += 'add';
          }
        }
      }

      final MeiXmlNode alterNode = degree.child('degree-alter')!;
      final String alter = getContent(alterNode);
      // A degree-alter value of 0 is not rendered as a natural; it's omitted.
      if (alter != '0') {
        final String plusMinus = alterNode.attr('plus-minus') ?? '';
        degreeText += convertAlterToSymbol(alter, plusMinus == 'yes');
      }
      degreeText += degreeValue;
    }

    if (degreeText != '') {
      degreeText += ')';
    }

    return degreeText;
  }

  /// Mirrors `ConvertFigureGlyph`.
  static String convertFigureGlyph(String value) {
    const Map<String, String> figureGlyphMap = {
      'sharp': '\u266F',
      'flat': '\u266D',
      'natural': '\u266E',
      'double-sharp': '\u{1D12A}',
      'flat-flat': '\u{1D12B}',
      'sharp-sharp': '\u266F\u266F',
      'backslash': '\u20E5', // non-spacing backslash U+20E5
      'slash': '\u0338', // non-spacing slash U+0338
      'cross': '+',
    };

    return figureGlyphMap[value] ?? '';
  }

  /// Mirrors `SetFermataExternalSymbols` / `ShapeFermata` helpers.

  /// Mirrors `SetFermataExternalSymbols`.
  void setFermataExternalSymbols(Fermata fermata, String shape) {
    // When MEI adds support for all of these shapes, this can be merged with
    // ConvertFermataShape()
    const Map<String, String> fermataExtSymbolsAbove = {
      'double-angled': 'U+E4C2',
      'double-square': 'U+E4C8',
      'double-dot': 'U+E4CA',
      'half-curve': 'U+E4CC',
      'curlew': 'U+E4D6',
    };
    const Map<String, String> fermataExtSymbolsBelow = {
      'double-angled': 'U+E4C3',
      'double-square': 'U+E4C9',
      'double-dot': 'U+E4CB',
      'half-curve': 'U+E4CD',
      'curlew': 'U+E4D6',
    };

    if (fermata.form == FermatavisForm.inv &&
        fermataExtSymbolsBelow.containsKey(shape)) {
      setExternalSymbols(fermata, 'glyph.num', fermataExtSymbolsBelow[shape]!);
      setExternalSymbols(fermata, 'glyph.auth', 'smufl');
    } else if (fermataExtSymbolsAbove.containsKey(shape)) {
      setExternalSymbols(fermata, 'glyph.num', fermataExtSymbolsAbove[shape]!);
      setExternalSymbols(fermata, 'glyph.auth', 'smufl');
    }
  }

  /// Mirrors `ShapeFermata`.
  void shapeFermata(Fermata fermata, MeiXmlNode node) {
    // color
    fermata.color = node.attr('color');
    // shape
    fermata.shape = convertFermataShape(getContent(node));
    // form and place
    if (hasAttributeWithValue(node, 'type', 'inverted')) {
      fermata.form = FermatavisForm.inv;
      fermata.place = Staffrel.below;
    } else if (hasAttributeWithValue(node, 'type', 'upright')) {
      fermata.form = FermatavisForm.norm;
      fermata.place = Staffrel.above;
    }
    setFermataExternalSymbols(fermata, getContent(node));
  }

  /// Parse an int attribute or text value with a fallback (mirrors pugixml
  /// `as_int(default)`).
  static int? strToIntOrNull(String value) {
    final v = value.trim();
    if (v.isEmpty) return null;
    return int.tryParse(v);
  }
}
