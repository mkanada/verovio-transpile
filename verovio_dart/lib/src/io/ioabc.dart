/// Port of `ioabc.h/cpp` (`ABCInput`) — the ABC notation reader.
///
/// The parser walks the ABC file line by line: information fields (`X:`,
/// `T:`, `K:` …) are dispatched to dedicated parsers while music code is
/// consumed character by character ([AbcInput.readMusicCode]), building the
/// MEI object tree (mdiv > score > section > measure > staff > layer).
///
/// The MEI header is assembled as a raw [MeiXmlNode] tree stored in
/// `doc.header` (mirroring the pugixml document the C++ fills in
/// `CreateHeader` / `CreateWorkEntry`).
library;

import 'package:verovio_dart/src/core/attdef.dart'
    show MeiDuration, MeterCountSign;
import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/io/iobase.dart';
import 'package:verovio_dart/src/io/xml_node.dart';
import 'package:verovio_dart/src/model/atts/atts_conversion.dart'
    show strToPitchname;
import 'package:verovio_dart/src/model/atts/mei_enums.dart' hide Tie;
import 'package:verovio_dart/src/model/atts/mei_values.dart';
import 'package:verovio_dart/src/model/basic_elements.dart';
import 'package:verovio_dart/src/model/control_element.dart'
    show ControlElement;
import 'package:verovio_dart/src/model/control_elements_gen.dart';
import 'package:verovio_dart/src/model/doc.dart' show DocType;
import 'package:verovio_dart/src/model/editorial_element.dart';
import 'package:verovio_dart/src/model/layer_element.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart';
import 'package:verovio_dart/src/model/misc_elements_gen.dart';
import 'package:verovio_dart/src/model/scoredef.dart';

// ---------------------------------------------------------------------------
// Global variables (mirrors the file-scope helpers of ioabc.cpp)
// ---------------------------------------------------------------------------

/// Mirrors the `pitch` constant: order of pitches for key signatures.
const String _pitch = 'FCGDAEB';

/// Mirrors the `shorthandDecoration` constant.
const String _shorthandDecoration = '.~HLMOPSTuv';

/// Mirrors `GetVersion()` (the VERSION macro of the 6.2 release).
const String _verovioVersion = '6.2.0';

/// The pitch alteration introduced by the key signature (mirrors the
/// `keyPitchAlter` global).
String _keyPitchAlter = '';

/// The direction of [_keyPitchAlter]: -1 flats, 1 sharps (mirrors
/// `keyPitchAlterAmount`).
int _keyPitchAlterAmount = 0;

/// Mirrors `ABCInput::ElementType`.
enum AbcElementType { normal, tuplet }

/// Mirrors `ABCInput::ContainerElement`.
class AbcContainerElement {
  AbcElementType type = AbcElementType.normal;
  LayerElement? element;
  int count = 0;
}

/// This class is a file input stream for reading ABC files (mirrors
/// `vrv::ABCInput`).
class AbcInput extends Input {
  AbcInput(super.doc) {
    layoutInformation = LayoutInformation.encoded;
  }

  /// One line of the abc file (mirrors the `abcLine` global).
  String abcLine = '';

  /// The filename used for the header title (mirrors `m_filename`; unset by
  /// the C++ reader as well).
  String filename = '';

  // -------------------------------------------------------------------------
  // Members (mirrors m_xxx fields)
  // -------------------------------------------------------------------------

  /// The current mdiv (mirrors `m_mdiv`).
  Mdiv? mdiv;

  /// A pending clef waiting to be stacked (mirrors `m_clef`).
  Clef? clef;

  /// The key signature read from the K: field (mirrors `m_key`).
  KeySig? key;

  /// A pending meter signature (mirrors `m_meter`).
  MeterSig? meter;

  /// The current layer (mirrors `m_layer`).
  Layer? layer;

  /// The default duration (mirrors `m_durDefault`).
  MeiDuration durDefault = MeiDuration.none;

  /// The id of the last note-like element (mirrors `m_ID`).
  String id = '';

  /// The unit duration denominator (mirrors `m_unitDur`; uninitialized in
  /// the C++, sensible default here).
  int unitDur = 8;

  /// The left/right barline rendition of the measure being built (mirrors
  /// `m_barLines`).
  (Barrendition, Barrendition) barLines =
      (Barrendition.none, Barrendition.none);

  /*
   * ABC variables with default values
   */

  /// The decoration sign (mirrors `m_decoration`).
  String decoration = '!';

  /// The linebreak sign (mirrors `m_linebreak`; empty disables breaks).
  String linebreak = r'$';

  /// The current line number (mirrors `m_lineNum`).
  int lineNum = 1;

  /// Broken rhythm accumulator (> increases, < decreases; mirrors
  /// `m_broken`).
  int broken = 0;

  /// Grace note counter (mirrors `m_gracecount`).
  int gracecount = 0;

  /// Number of staff lines (mirrors `m_stafflines`).
  int stafflines = 5;

  /// Transposition in semitones (mirrors `m_transpose`).
  int transpose = 0;

  /// Pending tuplet container (mirrors `m_containerElement`).
  AbcContainerElement containerElement = AbcContainerElement();

  /*
   * ABC metadata stacks
   */

  /// Composer entries with their line numbers (mirrors `m_composer`). // C:
  final List<(String, int)> composer = [];

  /// History entries with their line numbers (mirrors `m_history`). // H:
  final List<(String, int)> history = [];

  /// Notes entries with their line numbers (mirrors `m_notes`). // N:
  final List<(String, int)> notes = [];

  /// Origin entries with their line numbers (mirrors `m_origin`). // O:
  final List<(String, int)> origin = [];

  /// Title entries with their line numbers (mirrors `m_title`). // T:
  final List<(String, int)> title = [];

  /// Generic information entries: value, line number and field key
  /// (mirrors `m_info`).
  final List<(String, int, String)> info = [];

  /// Tempi waiting for the next measure (mirrors `m_tempoStack`).
  final List<Tempo> tempoStack = [];

  /// Pending harmony / chord symbols (mirrors `m_harmStack`).
  final List<Harm> harmStack = [];

  /// Open slurs (mirrors `m_slurStack`).
  final List<Slur> slurStack = [];

  /// Open ties (mirrors `m_tieStack`).
  final List<Tie> tieStack = [];

  /// Elements stacked for beaming / tuplets (mirrors `m_noteStack`).
  ///
  /// (The C++ header also declares an unused `m_layerElements` vector; it
  /// is omitted here.)
  final List<LayerElement> noteStack = [];

  /// Added notes in one line of ABC file; used to track elements that might
  /// require adding a verse to (mirrors `m_lineNoteArray`).
  final List<LayerElement> lineNoteArray = [];

  /// The current verse number (mirrors `m_verseNumber`).
  int verseNumber = 1;

  /*
   * ABC decoration stacks
   */

  /// Pending articulations (mirrors `m_artic`).
  final List<Articulation> artic = [];

  /// Pending dynamics (mirrors `m_dynam`).
  final List<String> dynam = [];

  /// Pending ornaments (mirrors `m_ornam`).
  String ornam = '';

  /// Pending fermata placement (mirrors `m_fermata`).
  Staffrel fermata = Staffrel.none;

  /// Pending repeat mark function (mirrors `m_repeatMark`).
  RepeatmarklogFunc repeatMark = RepeatmarklogFunc.none;

  /*
   * The stack of control elements to be added at the end of each measure
   */

  /// Pairs of layer ids and control elements (mirrors `m_controlElements`).
  final List<(String, ControlElement)> controlElements = [];

  /*
   * container for work entries
   */

  /// The `<workList>` node of the header (mirrors `m_workList`).
  late MeiXmlNode workList;

  // -------------------------------------------------------------------------
  // Import
  // -------------------------------------------------------------------------

  @override
  bool import(String data) {
    parseABC(data);
    return true;
  }

  /// Mirrors `ABCInput::ParseABC`.
  void parseABC(String infile) {
    // initialize doc
    doc.reset();
    doc.setType(DocType.raw);

    Score? score;
    Section? section;
    createHeader();

    final List<String> lines = infile.split('\n');
    int lineIndex = 0;
    while (lineIndex < lines.length) {
      abcLine = _stripCr(lines[lineIndex]);
      ++lineIndex;
      ++lineNum;
      if (abcLine.isNotEmpty && abcLine[0] == 'X') {
        bool hitEof = false;
        while (true) {
          if (abcLine.length >= 3) {
            readInformationField(abcLine[0], abcLine.substring(2));
            if (abcLine[0] == 'K') break;
          }
          if (lineIndex >= lines.length) {
            hitEof = true;
            break;
          }
          abcLine = _stripCr(lines[lineIndex]);
          ++lineIndex;
          ++lineNum;
        }
        if (hitEof) break;
        if (title.isEmpty) {
          logWarning('ABC import: Title field missing, creating empty title');
          title.add(('', 0));
        }
        // add work entry to meiHead
        createWorkEntry();

        (score, section) = initScoreAndSection();

        continue;
      } else if (mdiv == null || score == null || section == null) {
        // if m_div is not initialized - we didn't read X element, so
        // continue until we do
        continue;
      }
      if (abcLine.isEmpty || _allSpaces(abcLine)) {
        // abc tunes are separated from each other by empty lines
        flushControlElements(score, section);
        continue;
      } else if (abcLine[0] == '%') {
        // skipping comments and stylesheet directives
        continue;
      } else if ((abcLine.length >= 3) &&
          (abcLine[1] == ':') &&
          (abcLine[0] != '|')) {
        if (abcLine[0] != 'K') {
          readInformationField(abcLine[0], abcLine.substring(2));
        } else {
          logWarning('ABC import: Key changes not supported');
        }
      } else {
        verseNumber = 1;
        lineNoteArray.clear();
        readMusicCode(abcLine, section);
      }
    }
    flushControlElements(score, section);

    if (section != null && score != null && section.parent == null) {
      score.addChild(section);
    }

    composer.clear();
    info.clear();
    title.clear();

    doc.convertToPageBasedDoc();
  }

  //////////////////////////////
  //
  // setBarLine --
  // Translation from ABC to Verovio representation:
  //
  //  BARRENDITION_single     |
  //  BARRENDITION_end        |]
  //  BARRENDITION_rptboth    ::
  //  BARRENDITION_rptend     :|
  //  BARRENDITION_rptstart   |:
  //  BARRENDITION_dbl        ||
  //

  /// Mirrors `ABCInput::SetBarLine`.
  int setBarLine(String musicCode, int i) {
    Barrendition barLine = Barrendition.none;
    if (i >= 1 && musicCode[i - 1] == ':') {
      barLine = Barrendition.rptend;
    } else if (i + 1 < musicCode.length) {
      switch (musicCode[i + 1]) {
        case ':':
          barLine = Barrendition.rptstart;
          ++i;
        case '|':
          barLine = Barrendition.dbl;
          ++i;
        case ']':
          barLine = Barrendition.end;
          ++i;
        default:
          barLine = Barrendition.single;
      }
    } else {
      barLine = Barrendition.single;
    }
    // if the measure is still empty, put the bar line on the left
    if (layer!.childCount == 0) {
      barLines = (barLine, barLines.$2);
    } else {
      barLines = (barLines.$1, barLine);
    }
    return i;
  }

  /// Mirrors `ABCInput::CalcUnitNoteLength`.
  void calcUnitNoteLength() {
    final MeterSig? meterSig =
        doc.getFirstScoreDef()?.findDescendantByType(ClassId.meterSig)
            as MeterSig?;
    if (meterSig == null ||
        !meterSig.hasUnit ||
        meterSig.getTotalCount() / meterSig.unit! >= 0.75) {
      unitDur = 8;
      durDefault = MeiDuration.dur8;
    } else {
      unitDur = 16;
      durDefault = MeiDuration.dur16;
    }
  }

  /// Mirrors `ABCInput::AddLayerElement`.
  void addLayerElement() {
    // exit if there is nothing to add
    if (noteStack.isEmpty) return;
    // if just one note in the stack - add it to the layer directly
    if (noteStack.length == 1) {
      if (containerElement.element != null &&
          AbcElementType.tuplet == containerElement.type) {
        containerElement.element!.addChild(noteStack.last);
        if (--containerElement.count == 0) {
          layer!.addChild(containerElement.element!);
          containerElement = AbcContainerElement();
        }
      } else {
        layer!.addChild(noteStack.last);
      }
      noteStack.clear();
      return;
    }
    // otherwise we can have beam or tuplet (for now)
    Beam? beam = Beam();
    // add stacked notes to the current element
    for (final LayerElement element in noteStack) {
      beam.addChild(element);
    }
    if (beam.findDescendantByType(ClassId.note) != null) {
      LayerElement? element;
      if (containerElement.element != null &&
          AbcElementType.tuplet == containerElement.type) {
        element = containerElement.element!;
        element.addChild(beam);
        containerElement.element = null;
      }
      // otherwise default to it being beam
      else {
        element = beam;
      }
      layer!.addChild(element);
      beam = null;
    } else {
      for (final LayerElement element in noteStack) {
        layer!.addChild(element);
      }
    }
    // clean-up leftover data, if any (the C++ deletes the orphan objects;
    // unreferenced objects are collected by the GC here)

    containerElement = AbcContainerElement();
    noteStack.clear();
  }

  /// Mirrors `ABCInput::ParseTuplet`.
  int parseTuplet(String musicCode, int index) {
    const tupletElements = '(:0123456789 ';
    ++index;
    int tupletEnd = _indexOfNotOf(musicCode, tupletElements, index);
    if (tupletEnd == -1) tupletEnd = musicCode.length;
    final String tupletStr = musicCode.substring(index, tupletEnd);

    final Tuplet tuplet = Tuplet();
    int separator = tupletStr.indexOf(':');
    // Get tuplet number first 9:_:_
    int tupletNum = 0;
    if (separator != -1) {
      tupletNum = strToInt(tupletStr.substring(0, separator));
      ++separator;
    } else {
      tupletNum = strToInt(tupletStr);
    }
    // Get tuplet number base _:3:_
    int tupletNumbase = 0;
    if (separator != -1) {
      final int secondSeparator = tupletStr.indexOf(':', separator);
      if (secondSeparator != -1) {
        if (secondSeparator != separator) {
          tupletNumbase =
              strToInt(tupletStr.substring(separator, secondSeparator));
          separator = secondSeparator + 1;
        }
      } else {
        tupletNumbase = strToInt(tupletStr.substring(separator));
        separator = secondSeparator + 1;
      }
    }
    // List of tuplets with default base of 3
    const threeBase = {2, 4, 8, 9};
    if (tupletNumbase == 0) {
      tupletNumbase = threeBase.contains(tupletNum) ? 3 : 2;
    }
    // Get number of elements supposed to be in the tuplet _:_:9
    // Ignore this for the time being
    tuplet.num = tupletNum;
    tuplet.numbase = tupletNumbase;
    containerElement = AbcContainerElement()
      ..type = AbcElementType.tuplet
      ..element = tuplet
      ..count = tupletNum;

    // return index of the last element in tuplet, so that we point to the
    // actual notes when incrementing 'i'
    return tupletEnd - 1;
  }

  /// Mirrors `ABCInput::AddAnnot`.
  void addAnnot(String remark) {
    // remarks
    final Annot annot = Annot();
    final Text text = Text();
    text.text = remark;
    annot.addChild(text);
    // todo: add to correct place
    layer!.addChild(annot);
  }

  /// Mirrors `ABCInput::AddArticulation`.
  void addArticulation(LayerElement element) {
    assert(element.runtimeType != Null);

    final Artic art = Artic();
    art.artic = List<Articulation>.from(artic);
    element.addChild(art);

    artic.clear();
  }

  /// Mirrors `ABCInput::AddChordSymbol`.
  void addChordSymbol(LayerElement element) {
    assert(element.runtimeType != Null);

    // there should always only be one element in the harmony stack
    if (harmStack.isNotEmpty && !harmStack.last.hasStartid) {
      harmStack.last.startid = '#${element.id}';
      harmStack.clear();
    }

    harmStack.clear();
  }

  /// Mirrors `ABCInput::AddDynamic`.
  void addDynamic(LayerElement element) {
    assert(element.runtimeType != Null);

    for (final String str in dynam) {
      final Dynam dynamElement = Dynam();
      dynamElement.startid = '#${element.id}';
      final Text text = Text();
      text.text = str;
      dynamElement.addChild(text);
      controlElements.add((layer!.id, dynamElement));
    }

    dynam.clear();
  }

  /// Mirrors `ABCInput::AddFermata`.
  void addFermata(LayerElement element) {
    assert(element.runtimeType != Null);

    final Fermata fermataElement = Fermata();
    fermataElement.startid = '#${element.id}';
    fermataElement.place = fermata;
    controlElements.add((layer!.id, fermataElement));

    fermata = Staffrel.none;
  }

  /// Mirrors `ABCInput::AddOrnaments`.
  void addOrnaments(LayerElement element) {
    assert(element.runtimeType != Null);

    final String refId = '#${element.id}';
    // note->SetOrnam(m_ornam);
    if (ornam.contains('m')) {
      final Mordent mordent = Mordent();
      mordent.startid = refId;
      mordent.form = MordentlogForm.lower;
      controlElements.add((layer!.id, mordent));
    }
    if (ornam.contains('M')) {
      final Mordent mordent = Mordent();
      mordent.startid = refId;
      mordent.form = MordentlogForm.upper;
      controlElements.add((layer!.id, mordent));
    }
    if (ornam.contains('s')) {
      final Turn turn = Turn();
      turn.startid = refId;
      turn.form = TurnlogForm.lower;
      controlElements.add((layer!.id, turn));
    }
    if (ornam.contains('S')) {
      final Turn turn = Turn();
      turn.startid = refId;
      turn.form = TurnlogForm.upper;
      controlElements.add((layer!.id, turn));
    }
    if (ornam.contains('T')) {
      final Trill trill = Trill();
      trill.startid = refId;
      controlElements.add((layer!.id, trill));
    }

    ornam = '';
  }

  /// Mirrors `ABCInput::AddRepeatMark`.
  void addRepeatMark(LayerElement element) {
    assert(element.runtimeType != Null);

    final RepeatMark rm = RepeatMark();
    rm.startid = '#${element.id}';
    rm.func = repeatMark;
    controlElements.add((layer!.id, rm));

    repeatMark = RepeatmarklogFunc.none;
  }

  /// Mirrors `ABCInput::AddTie`.
  void addTie() {
    if (tieStack.isNotEmpty) {
      logWarning("ABC import: '$id' already tied");
      return;
    }
    if (id.isNotEmpty) {
      final Tie tie = Tie();
      tie.startid = id;
      tieStack.add(tie);
      controlElements.add((layer!.id, tie));
    }
  }

  /// Mirrors `ABCInput::StartSlur`.
  void startSlur() {
    final Slur openSlur = Slur();
    slurStack.add(openSlur);
    controlElements.add((layer!.id, openSlur));
  }

  /// Mirrors `ABCInput::EndSlur`.
  void endSlur() {
    if (slurStack.isNotEmpty) {
      if (!slurStack.last.hasStartid) {
        logError('ABC import: Empty slur found');
        slurStack.removeLast();
        return;
      }
      for (int riter = slurStack.length - 1; riter >= 0; --riter) {
        if (!(slurStack[riter].startid ?? '').contains(id)) {
          slurStack[riter].endid = '#$id';
          slurStack.removeAt(riter);
          break;
        }
      }
      return;
    }
    logWarning("ABC import: Closing slur for element '$id' could not be "
        'matched');
  }

  /// Mirrors `ABCInput::ParseDecoration`.
  void parseDecoration(String decorationString) {
    // shorthand decorations hard-coded !
    if (decorationString.isEmpty ||
        _isDigit(decorationString[0])) {
      logWarning('ABC import: Fingering not supported');
      return;
    }
    if (decorationString == '.') {
      artic.add(Articulation.stacc);
    } else if ((decorationString == '~') || (decorationString == 'roll')) {
      ornam += 'S';
    } else if ((decorationString == 'trill') || (decorationString == 'T')) {
      ornam += 'T';
    } else if ((decorationString == 'mordent') ||
        (decorationString == 'lowermordent') ||
        (decorationString == 'M')) {
      ornam += 'm';
    } else if ((decorationString == 'pralltriller') ||
        (decorationString == 'uppermordent') ||
        (decorationString == 'P')) {
      ornam += 'M';
    } else if (decorationString == 'turn') {
      ornam += 'S';
    } else if (decorationString == 'invertedturn') {
      ornam += 's';
    } else if ((decorationString == '>') ||
        (decorationString == 'accent') ||
        (decorationString == 'emphasis')) {
      artic.add(Articulation.acc);
    } else if ((decorationString == '^') || (decorationString == 'marcato')) {
      artic.add(Articulation.marc);
    } else if ((decorationString == 'fermata') || (decorationString == 'H')) {
      fermata = Staffrel.above;
    } else if (decorationString == 'invertedfermata') {
      fermata = Staffrel.below;
    } else if (decorationString == 'tenuto') {
      artic.add(Articulation.ten);
    } else if ((decorationString == '+') || (decorationString == 'plus')) {
      artic.add(Articulation.stop);
    } else if (decorationString == 'snap') {
      artic.add(Articulation.snap);
    } else if (decorationString == 'slide') {
      artic.add(Articulation.scoop);
    } else if (decorationString == 'wedge') {
      artic.add(Articulation.stacciss);
    } else if ((decorationString == 'upbow') || (decorationString == 'u')) {
      artic.add(Articulation.upbow);
    } else if ((decorationString == 'downbow') || (decorationString == 'v')) {
      artic.add(Articulation.dnbow);
    } else if (decorationString == 'open') {
      artic.add(Articulation.open);
    } else if ((decorationString == 'pppp') ||
        (decorationString == 'ppp') ||
        (decorationString == 'pp') ||
        (decorationString == 'p') ||
        (decorationString == 'mp') ||
        (decorationString == 'mf') ||
        (decorationString == 'f') ||
        (decorationString == 'ff') ||
        (decorationString == 'fff') ||
        (decorationString == 'ffff') ||
        (decorationString == 'sfz')) {
      dynam.add(decorationString);
    } else if (decorationString == 'segno') {
      repeatMark = RepeatmarklogFunc.segno;
    } else if (decorationString == 'coda') {
      repeatMark = RepeatmarklogFunc.coda;
    } else if (decorationString == 'D.S.') {
      repeatMark = RepeatmarklogFunc.dalsegno;
    } else if (decorationString == 'D.C.') {
      repeatMark = RepeatmarklogFunc.dacapo;
    } else {
      logWarning("ABC import: Decoration $decorationString not supported");
    }
  }

  //////////////////////////////
  //
  // parse information fields
  //

  /// Mirrors `ABCInput::ParseInstruction`.
  void parseInstruction(String instruction) {
    if (instruction.startsWith('abc-include')) {
      logWarning('ABC import: Include field is ignored');
    } else if (instruction.startsWith('linebreak')) {
      if (instruction.contains('<none>')) {
        linebreak = '';
        layoutInformation = LayoutInformation.none;
      } else {
        linebreak = r'$';
        layoutInformation = LayoutInformation.encoded;
        logWarning('ABC import: Default linebreaks are used for now.');
      }
    } else if (instruction.startsWith('decoration')) {
      decoration = instruction.length > 11 ? instruction[11] : '';
    }
  }

  /// Mirrors `ABCInput::ParseKey`.
  void parseKey(String keyString) {
    int i = 0;
    id = '';
    int accidNum = 0;
    Mode mode = Mode.none;
    key = KeySig();
    key!.isAttribute = true;
    clef = Clef();
    while (_isSpace(_charAt(keyString, i))) {
      ++i;
    }

    // set key.pname
    if (_pitch.contains(_charAt(keyString, i))) {
      accidNum = _pitch.indexOf(_charAt(keyString, i)) - 1;
      keyString = keyString.substring(0, i) +
          _charAt(keyString, i).toLowerCase() +
          keyString.substring(i + 1);
      key!.pname = strToPitchname(_charAt(keyString, i));
      ++i;
    }
    while (_isSpace(_charAt(keyString, i))) {
      ++i;
    }

    // set key.accid
    switch (_charAt(keyString, i)) {
      case '#':
        key!.accid = AccidentalGesturalBasic.s;
        accidNum += 7;
        ++i;
      case 'b':
        key!.accid = AccidentalGesturalBasic.f;
        accidNum -= 7;
        ++i;
      default:
        break;
    }

    // set key.mode
    if (key!.hasPname) {
      // when no mode is indicated, major is assumed
      mode = Mode.major;
      while (_isSpace(_charAt(keyString, i))) {
        ++i;
      }

      if (_charAt(keyString, i).isNotEmpty) {
        String modeString = keyString.substring(i);
        // capitalization is ignored for the modes
        // and in fact only the first three letters of each mode are parsed
        if (modeString.length > 3) modeString = modeString.substring(0, 3);
        modeString = modeString.toLowerCase();

        if (modeString == 'min' ||
            (_charAt(modeString, 0) == 'm' &&
                !_isAlpha(_charAt(modeString, 1)))) {
          mode = Mode.minor;
          accidNum -= 3;
        } else if (modeString == 'ion') {
          mode = Mode.dorian;
        } else if (modeString == 'dor') {
          mode = Mode.dorian;
          accidNum -= 2;
        } else if (modeString == 'phr') {
          mode = Mode.phrygian;
          accidNum -= 4;
        } else if (modeString == 'lyd') {
          mode = Mode.lydian;
          accidNum += 1;
        } else if (modeString == 'mix') {
          mode = Mode.mixolydian;
          accidNum -= 1;
        } else if (modeString == 'aeo') {
          mode = Mode.aeolian;
          accidNum -= 3;
        } else if (modeString == 'loc') {
          mode = Mode.locrian;
          accidNum -= 5;
        }
      }
    }
    key!.mode = mode;

    // we need set @key.sig for correct rendering
    if (accidNum != 0) {
      String keySig;
      int posStart = 0;
      final int posEnd = accidNum.abs();

      if (accidNum < 0) {
        keySig = '${accidNum.abs()}f';
        posStart = _pitch.length - posEnd;
        _keyPitchAlterAmount = -1;
      } else {
        keySig = '${accidNum}s';
        _keyPitchAlterAmount = 1;
      }

      // m_doc->m_scoreDef.SetSig(keySig);
      key!.sig = strToKeysignature(keySig);
      _keyPitchAlter = _pitch.substring(
          posStart < 0 ? 0 : posStart,
          (posStart < 0 ? 0 : posStart) + posEnd > _pitch.length
              ? _pitch.length
              : (posStart < 0 ? 0 : posStart) + posEnd);
    }

    // set clef
    // <clef name> - may be treble, alto, tenor, bass, perc or none. perc
    // selects the drum clef. clef= may be omitted.
    // [<line number>] - indicates on which staff line the base clef is
    // written. Defaults are: treble: 2; alto: 3; tenor: 4; bass: 4.
    // [+8 | -8] - draws '8' above or below the staff. The player will
    // transpose the notes one octave higher or lower.
    if (keyString.contains('alto')) {
      clef!.shape = Clefshape.c;
      i += 4;
      clef!.line = 3;
    } else if (keyString.contains('tenor')) {
      clef!.shape = Clefshape.c;
      i += 5;
      clef!.line = 4;
    } else if (keyString.contains('bass')) {
      clef!.shape = Clefshape.f;
      i += 4;
      clef!.line = 4;
    } else if (keyString.contains('perc')) {
      logWarning('ABC Input: Drum clef is not supported');
    } else if (keyString.contains('none')) {
      i += 4;
      clef!.shape = Clefshape.none;
    } else {
      clef!.shape = Clefshape.g;
      clef!.line = 2;
    }

    if (keyString.indexOf('transpose=', i) != -1) {
      i = keyString.indexOf('transpose=', i) + 10;
      String transStr = '';
      while (_charAt(keyString, i) == '-' ||
          _isDigit(_charAt(keyString, i))) {
        transStr += _charAt(keyString, i);
        ++i;
      }
      transpose = strToInt(transStr);
    }

    // stafflines
    if (keyString.indexOf('stafflines=', i) != -1) {
      final int pos = keyString.indexOf('stafflines=', i) + 11;
      int end = _indexOfNotOf(keyString, '0123456789', pos);
      if (end == -1) end = keyString.length;
      stafflines = strToInt(keyString.substring(pos, end));
    }
  }

  /// Mirrors `ABCInput::ParseUnitNoteLength`.
  void parseUnitNoteLength(String unitNoteLength) {
    final int slashPos = unitNoteLength.indexOf('/');
    // Mirrors `if (unitNoteLength.find('/'))`: any non-zero find position
    // (including npos, where atoi restarts at the wrapped position 0).
    if (slashPos != 0) {
      unitDur =
          strToInt(unitNoteLength.substring(slashPos == -1 ? 0 : slashPos + 1));
    } else if (strToInt(unitNoteLength) == 1) {
      unitDur = 1;
    }
    switch (unitDur) {
      case 1:
        durDefault = MeiDuration.dur1;
      case 2:
        durDefault = MeiDuration.dur2;
      case 4:
        durDefault = MeiDuration.dur4;
      case 8:
        durDefault = MeiDuration.dur8;
      case 16:
        durDefault = MeiDuration.dur16;
      case 32:
        durDefault = MeiDuration.dur32;
      case 64:
        durDefault = MeiDuration.dur64;
      case 128:
        durDefault = MeiDuration.dur128;
      case 256:
        durDefault = MeiDuration.dur256;
      default:
        break;
    }
  }

  /// Mirrors `ABCInput::ParseMeter`.
  void parseMeter(String meterString) {
    meter = MeterSig();
    if (meterString.contains('C')) {
      final int cPos = meterString.indexOf('C');
      if (_charAt(meterString, cPos + 1) == '|') {
        meter!.sym = Metersign.cut;
        meter!.count = MeterCountPair([2], MeterCountSign.none);
        meter!.unit = 2;
      } else {
        meter!.sym = Metersign.common;
        meter!.count = MeterCountPair([4], MeterCountSign.none);
        meter!.unit = 4;
      }
    } else if (meterString.indexOf('/') > 0) {
      final int slashPos = meterString.indexOf('/');
      String meterCount = meterString.substring(0, slashPos);
      if (meterCount.isNotEmpty &&
          meterCount[0] == '(' &&
          meterCount[meterCount.length - 1] == ')') {
        meterCount = meterCount.substring(1, meterCount.length - 1);
      }
      // this is a little "hack", until libMEI is fixed
      meter!.count = MeterCountPair([strToInt(meterCount)], MeterCountSign.none);
      meter!.unit = strToInt(meterString.substring(slashPos + 1));
    }
  }

  /// Mirrors `ABCInput::ParseTempo`.
  void parseTempo(String tempoString) {
    final Tempo tempo = Tempo();
    if (tempoString.contains('=')) {
      final int numStart = tempoString.indexOf('=') + 1;
      tempo.mm = strToDbl(tempoString.substring(numStart));
    }
    if (tempoString.contains('"')) {
      String tempoWord = tempoString.substring(tempoString.indexOf('"') + 1);
      final int closePos = tempoWord.indexOf('"');
      if (closePos != -1) tempoWord = tempoWord.substring(0, closePos);
      if (tempoWord.isNotEmpty) {
        final Text text = Text();
        text.text = tempoWord;
        tempo.addChild(text);
      }
    }
    // this has to be fixed
    tempo.tstamp = 1;
    tempoStack.add(tempo);
    logWarning('ABC import: Tempo definitions are not fully supported yet');
  }

  /// Mirrors `ABCInput::ParseReferenceNumber`.
  void parseReferenceNumber(String referenceNumberString) {
    // The X: field is also used to indicate the start of the tune
    mdiv = Mdiv();
    mdiv!.setVisibility(VisibilityType.visible);
    if (referenceNumberString.isNotEmpty) {
      final int mdivNum = strToInt(referenceNumberString);
      if (mdivNum < 1) {
        logError('ABC import: reference number should be a positive integer');
      }
      mdiv!.n = '$mdivNum';
    }
    doc.addChild(mdiv!);

    // reset unit note length
    durDefault = MeiDuration.none;

    // reset information fields
    composer.clear();
    history.clear();
    info.clear();
    origin.clear();
    title.clear();
  }

  /// Mirrors `ABCInput::PrintInformationFields`.
  void printInformationFields(Score score) {
    final PgHead pgHead = PgHead();
    pgHead.func = Pgfunc.first;
    for (final (value, line) in title) {
      final Rend titleRend = Rend();
      titleRend.halign = Horizontalalignment.center;
      titleRend.valign = Verticalalignment.middle;
      if ((value, line) != title.first) {
        final FontSize fontsize = FontSize();
        fontsize.setTerm(Fontsizeterm.small);
        titleRend.fontsize = fontsize;
      }
      final Text text = Text();
      text.text = value;
      titleRend.addChild(text);
      pgHead.addChild(titleRend);
    }
    for (final (value, line) in composer) {
      final Rend compRend = Rend();
      compRend.halign = Horizontalalignment.right;
      compRend.valign = Verticalalignment.bottom;
      final Text composerText = Text();
      composerText.text = value;
      compRend.addChild(composerText);
      if (origin.isNotEmpty) {
        final Text originText = Text();
        originText.text = ' (${origin.first.$1})';
        compRend.addChild(originText);
      }
      pgHead.addChild(compRend);
      // (the line number is kept in the pair only for the header xml:id)
      assert(line >= 0);
    }
    if (composer.isEmpty && origin.isNotEmpty) {
      final Rend originRend = Rend();
      originRend.halign = Horizontalalignment.right;
      originRend.valign = Verticalalignment.bottom;
      final Text originText = Text();
      originText.text = '(${origin.first.$1})';
      originRend.addChild(originText);
      pgHead.addChild(originRend);
    }
    assert(score.getScoreDef() != null);
    score.getScoreDef()!.addChild(pgHead);
  }

  /// Mirrors `ABCInput::CreateHeader`.
  void createHeader() {
    final MeiXmlNode meiHead = MeiXmlNode.element('meiHead');
    doc.header = meiHead;

    // <fileDesc> //
    final MeiXmlNode fileDesc = MeiXmlNode.element('fileDesc');
    meiHead.appendChild(fileDesc);
    final MeiXmlNode fileTitleStmt = MeiXmlNode.element('titleStmt');
    fileDesc.appendChild(fileTitleStmt);
    final MeiXmlNode fileTitle = MeiXmlNode.element('title');
    fileTitleStmt.appendChild(fileTitle);
    fileTitle.setTextValue(filename);
    for (final (value, line) in composer) {
      final MeiXmlNode composerNode = MeiXmlNode.element('composer');
      fileTitleStmt.appendChild(composerNode);
      composerNode.setTextValue(value);
      composerNode.setAttribute('xml:id', 'abcLine${_fmt02(line)}');
      composerNode.setAttribute('analog', 'abc:C');
    }

    final MeiXmlNode pubStmt = MeiXmlNode.element('pubStmt');
    fileDesc.appendChild(pubStmt);
    pubStmt.appendChild(MeiXmlNode.text(''));

    // <notesStmt> //
    if (notes.isNotEmpty) {
      final MeiXmlNode notesStmt = MeiXmlNode.element('notesStmt');
      fileDesc.appendChild(notesStmt);
      for (final (value, line) in notes) {
        final MeiXmlNode annotNode = MeiXmlNode.element('annot');
        notesStmt.appendChild(annotNode);
        annotNode.setTextValue(value);
        annotNode.setAttribute('xml:id', 'abcLine${_fmt02(line)}');
        annotNode.setAttribute('analog', 'abc:N');
      }
    }

    // <encodingDesc> //
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
    appText.setTextValue('Transcoded from abc music');

    // isodate and version //
    final DateTime now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    final String dateStr =
        '${now.year}-${two(now.month)}-${two(now.day)}T${two(now.hour)}:'
        '${two(now.minute)}:${two(now.second)}';
    app.setAttribute('isodate', dateStr);
    app.setAttribute('version', _verovioVersion);

    workList = MeiXmlNode.element('workList');
    meiHead.appendChild(workList);
  }

  /// Mirrors `ABCInput::CreateWorkEntry`.
  void createWorkEntry() {
    // <work> //
    final MeiXmlNode work = MeiXmlNode.element('work');
    workList.appendChild(work);
    work.setAttribute('n', mdiv?.n ?? '');
    work.setAttribute('data', '#${mdiv?.id ?? ''}');
    for (final (value, line) in title) {
      final MeiXmlNode titleNode = MeiXmlNode.element('title');
      work.appendChild(titleNode);
      titleNode.setTextValue(value);
      if (line != 0) {
        titleNode.setAttribute('xml:id', 'abcLine${_fmt02(line)}');
      }
      titleNode.setAttribute('analog', 'abc:T');
      if ((value, line) == title.first) {
        titleNode.setAttribute('type', 'main');
      } else {
        titleNode.setAttribute('type', 'alternative');
      }
    }
    if (composer.isNotEmpty) {
      for (final (value, line) in composer) {
        final MeiXmlNode composerNode = MeiXmlNode.element('composer');
        work.appendChild(composerNode);
        composerNode.setTextValue(value);
        composerNode.setAttribute('xml:id', 'abcLine${_fmt02(line)}');
        composerNode.setAttribute('analog', 'abc:C');
      }
    }
    if (history.isNotEmpty) {
      final MeiXmlNode historyNode = MeiXmlNode.element('history');
      work.appendChild(historyNode);
      historyNode.setAttribute('analog', 'abc:H');
      for (final (value, line) in history) {
        final MeiXmlNode histLine = MeiXmlNode.element('p');
        historyNode.appendChild(histLine);
        histLine.setTextValue(value);
        histLine.setAttribute('xml:id', 'abcLine${_fmt02(line)}');
      }
    }
    if (info.isNotEmpty) {
      final MeiXmlNode notesNode = MeiXmlNode.element('notesStmt');
      work.appendChild(notesNode);
      for (final (value, line, fieldKey) in info) {
        final MeiXmlNode annotNode = MeiXmlNode.element('annot');
        notesNode.appendChild(annotNode);
        annotNode.setTextValue(value);
        annotNode.setAttribute('xml:id', 'abcLine${_fmt02(line)}');
        annotNode.setAttribute('analog', 'abc:$fieldKey');
      }
    }
  }

  /// Mirrors `ABCInput::FlushControlElements`.
  void flushControlElements(Score? score, Section? section) {
    Layer? flushLayer;
    Measure? measure;
    for (final (layerId, element) in controlElements) {
      if (measure == null ||
          (flushLayer != null && flushLayer.id != layerId)) {
        flushLayer = section?.findDescendantByID(layerId) as Layer?;
      }
      if (flushLayer == null) {
        logWarning("ABC import: Element '${element.className}' could not be "
            "assigned to layer '$layerId'");
        continue;
      }
      measure = flushLayer.getFirstAncestor(ClassId.measure) as Measure?;
      assert(measure != null);
      measure!.addChild(element);
    }
    if (section != null && score != null && section.parent == null) {
      score.addChild(section);
    }

    controlElements.clear();
  }

  /// Mirrors `ABCInput::InitScoreAndSection`.
  ///
  /// Returns the freshly created (score, section) pair.
  (Score, Section) initScoreAndSection() {
    // create score
    assert(mdiv != null);
    final Score score = Score();
    mdiv!.addChild(score);

    // The C++ Score constructor owns its scoreDef (and uses it as its own
    // subtree); reproduce that wiring here.
    final ScoreDef scoreDef = ScoreDef();
    score.setScoreDefSubtree(scoreDef, scoreDef);

    final StaffGrp staffGrp = StaffGrp();
    // create staff
    final StaffDef staffDef = StaffDef();
    staffDef.n = 1;
    staffDef.lines = stafflines;
    staffDef.transSemi = transpose;
    if (clef != null) {
      staffDef.addChild(clef!);
      clef = null;
    }
    if (meter != null) {
      staffDef.addChild(meter!);
      meter = null;
    }
    staffGrp.addChild(staffDef);
    // create page head
    printInformationFields(score);
    assert(score.getScoreDef() != null);
    score.getScoreDef()!.addChild(staffGrp);
    if (key != null) {
      score.getScoreDef()!.addChild(key!);
      key = null;
    }

    // create section
    final Section section = Section();
    // start with a new page
    if (linebreak.isNotEmpty) {
      final Pb pb = Pb();
      pb.id = 'abcLine${_fmt02(lineNum + 1)}';
      section.addChild(pb);
    }
    // calculate default unit note length
    if (durDefault == MeiDuration.none) {
      calcUnitNoteLength();
    }
    assert(score.getScoreDef() != null);
    (score.getScoreDef() as ScoreDef).durDefault = durDefault;
    durDefault = MeiDuration.none;

    // read music code
    layer = Layer();
    layer!.n = 1;

    return (score, section);
  }

  /// Mirrors `ABCInput::ParseLyrics`.
  void parseLyrics() {
    final List<(Syl, int)> syllables = [];
    const delimiters = '-_*~ ';
    // skipping w:, so start from third element
    int start = 2;
    int found = _indexOfAny(abcLine, delimiters, 2);
    while (found != -1) {
      // Counter indicates for how many notes verse should be held. This
      // defaults to 1, unless '_' is found
      int counter = 1;
      String syllable = '';
      SyllogCon sylType = SyllogCon.none;
      if (_charAt(abcLine, found) == '_') {
        while (found < abcLine.length && _charAt(abcLine, found) == '_') {
          ++counter;
          ++found;
        }
        --found;
        sylType = SyllogCon.u;
      } else if (_charAt(abcLine, found) == '~') {
        counter = 0;
        sylType = SyllogCon.s;
      } else if (_charAt(abcLine, found) == '-') {
        if (found >= 1 && abcLine[found - 1] == r'\') {
          counter = 0;
        }
        sylType = SyllogCon.d;
      } else if (_charAt(abcLine, found) == '*') {
        // skip one note
        ++counter;
      }
      // separate syllable from delimiters to form syl that we want to add
      syllable = abcLine.substring(
          start, found < start ? start : (found > abcLine.length ? abcLine.length : found));
      syllable = syllable.replaceAll('_', '').replaceAll(r'\', '');
      if (syllable.isNotEmpty) {
        final Text sylText = Text();
        sylText.text = syllable;
        final Syl syl = Syl();
        syl.addChild(sylText);
        syl.con = sylType;
        if (sylType == SyllogCon.d) {
          syl.wordpos = SyllogWordpos.m;
        }
        syllables.add((syl, counter));
      }

      // find next delimiter in the string
      start = found + 1;
      found = _indexOfAny(abcLine, delimiters, start);
      // if none found, the rest of the string is going to serve as last syl
      if ((found == -1) && (start < abcLine.length)) {
        String lastSyllable = abcLine.substring(start);
        if (lastSyllable.isNotEmpty &&
            lastSyllable[lastSyllable.length - 1] == '\r') {
          lastSyllable = lastSyllable.substring(0, lastSyllable.length - 1);
        }
        final Text sylText = Text();
        sylText.text = lastSyllable;
        final Syl syl = Syl();
        syl.addChild(sylText);
        syl.con = sylType;
        syllables.add((syl, counter));
      }
    }

    // Iterate over notes and syllables simultaneously. Move through note
    // array using counters for each syllable, moving for several notes if
    // syllable needs to be held
    for (int i = 0, j = 0;
        (i < lineNoteArray.length) && (j < syllables.length);
        ++j) {
      while ((i < lineNoteArray.length) && lineNoteArray[i].isGraceNote()) {
        ++i;
      }
      if (i >= lineNoteArray.length) break;
      Verse? verse = lineNoteArray[i].getChild(0, ClassId.verse) as Verse?;
      if (verse == null) {
        verse = Verse();
        verse.n = verseNumber;
        lineNoteArray[i].addChild(verse);
      }
      verse.addChild(syllables[j].$1);
      i += syllables[j].$2;
    }
    // clean up syllables that were not added to any of the layer elements
    // (the C++ deletes them; unreferenced objects are collected by the GC)

    // increment verse number, in case next line in file is also w:
    ++verseNumber;
  }

  //////////////////////////////
  //
  // readInformationField --
  // information fields always
  // start with a letter
  // followed by a single colon
  //

  /// Mirrors `ABCInput::ReadInformationField`.
  void readInformationField(String dataKey, String value) {
    // remove comments and trim
    if (dataKey == '%' || dataKey == '') {
      return;
    }
    final int comment = value.indexOf('%');
    if (comment != -1) {
      value = value.substring(0, comment);
    }
    while (value.isNotEmpty && _isSpace(value[value.length - 1])) {
      value = value.substring(0, value.length - 1);
    }
    if (value.isEmpty) return;
    while (value.isNotEmpty && _isSpace(value[0])) {
      value = value.substring(1);
    }

    if (dataKey == '+') {
      logWarning('ABC import: Field continuation (+) is not supported');
      return;
    }

    switch (dataKey) {
      case 'B':
        info.add((value, lineNum, dataKey));
      case 'C':
        composer.add((value, lineNum));
      case 'D':
        info.add((value, lineNum, dataKey));
      case 'F':
        info.add((value, lineNum, dataKey));
      case 'H':
        history.add((value, lineNum));
      case 'I':
        parseInstruction(value);
      case 'K':
        parseKey(value);
      case 'L':
        parseUnitNoteLength(value);
      case 'M':
        parseMeter(value);
      case 'N':
        info.add((value, lineNum, dataKey));
      case 'O':
        origin.add((value, lineNum));
      case 'Q':
        parseTempo(value);
      case 'S':
        info.add((value, lineNum, dataKey));
      case 'T':
        title.add((value, lineNum));
      case 'U':
        logWarning('ABC import: User defined sympols are not supported');
      case 'V':
        logWarning('ABC import: Multi-voice music is not supported');
      case 'w':
        parseLyrics();
      case 'W':
        logWarning('ABC import: Lyrics are not supported yet');
      case 'X':
        parseReferenceNumber(value);
      case 'Z':
        info.add((value, lineNum, dataKey));
      default:
        logWarning('ABC import: Information field $dataKey is ignored');
    }
  }

  //////////////////////////////
  //
  // readMusicCode --
  // parse abc music code
  //

  /// Mirrors `ABCInput::ReadMusicCode`.
  void readMusicCode(String musicCode, Section section) {
    assert(section.runtimeType != Null);

    int i = 0;
    bool sysBreak = true;

    Grace grace = Grace.none;
    Chord? chord;

    while (i < musicCode.length) {
      // eat the input...

      if (musicCode[i] == '`') {
        // keeps a beam
      }
      if (_isSpace(musicCode[i])) {
        // always ends a beam
        addLayerElement();
      }

      // comments
      else if (musicCode[i] == '%') {
        break;
      }

      // endings
      else if ((i + 2 < musicCode.length) &&
          musicCode[i] == '[' &&
          _isDigit(musicCode[i + 1])) {
        ++i;
        // Ending *ending = new Ending;
        // ending->SetN(musicCode.at(i));
        ++i;
      }

      // inline fields
      else if ((i + 2 < musicCode.length) &&
          musicCode[i] == '[' &&
          musicCode[i + 2] == ':') {
        ++i;
        final String inlineDataKey = musicCode[i];
        ++i;
        ++i;
        final StringBuffer information = StringBuffer();
        while (i < musicCode.length && musicCode[i] != ']') {
          information.write(musicCode[i]);
          ++i;
        }
        if (inlineDataKey == 'r') {
          addAnnot(information.toString());
        } else {
          readInformationField(inlineDataKey, information.toString());
        }
      }

      // linebreaks
      else if (musicCode[i] == linebreak && linebreak.isNotEmpty) {
        addLayerElement();
        final Sb sb = Sb();
        section.addChild(sb);
      }

      // decorations
      else if (_shorthandDecoration.contains(musicCode[i])) {
        parseDecoration(musicCode[i]);
      } else if (musicCode[i] == decoration) {
        ++i;
        if (!_isSpace(_charAt(musicCode, i))) {
          final StringBuffer decorationString = StringBuffer();
          while (_charAt(musicCode, i) != decoration &&
              _charAt(musicCode, i).isNotEmpty) {
            decorationString.write(_charAt(musicCode, i));
            ++i;
          }
          parseDecoration(decorationString.toString());
        }
      }

      // tuplets
      else if ((i + 2 < musicCode.length) &&
          musicCode[i] == '(' &&
          _isDigit(musicCode[i + 1])) {
        i = parseTuplet(musicCode, i);
      }

      // slurs and ties
      else if (musicCode[i] == '(') {
        startSlur();
      } else if (musicCode[i] == ')') {
        endSlur();
      } else if (musicCode[i] == '-') {
        addTie();
      }

      // chords
      else if ((i + 2 < musicCode.length) &&
          musicCode[i] == '[' &&
          musicCode[i + 1] != '|') {
        // start chord
        chord = Chord();

        // add articulation
        if (artic.isNotEmpty) {
          addArticulation(chord);
        }

        // add chord symbols
        if (harmStack.isNotEmpty) {
          addChordSymbol(chord);
        }

        // add dynamics
        if (dynam.isNotEmpty) {
          addDynamic(chord);
        }

        // add fermata
        if (fermata != Staffrel.none) {
          addFermata(chord);
        }

        // add repeat mark
        if (repeatMark != RepeatmarklogFunc.none) {
          addRepeatMark(chord);
        }
      } else if (i >= 1 &&
          musicCode[i] == ']' &&
          musicCode[i - 1] != '|') {
        // end chord
        if (chord != null) {
          if ((chord.dur ?? MeiDuration.none).value <
              MeiDuration.dur8.value) {
            // if chord cannot be beamed, write it directly to the layer
            if (noteStack.isNotEmpty) addLayerElement();
            layer!.addChild(chord);
            lineNoteArray.add(chord);
          } else {
            noteStack.add(chord);
            lineNoteArray.add(chord);
          }
          chord = null;
        } else {
          logDebug('ABC import: closing "]" without a chord');
        }
      }

      // grace notes
      else if ((i + 2 < musicCode.length) &&
          ((musicCode[i] == '{') || (musicCode[i] == '}'))) {
        // !to be refined when graceGrp is added!
        // start grace group
        if (musicCode[i] == '{') {
          grace = Grace.acc;
          if (musicCode[i + 1] == '/') {
            grace = Grace.unacc;
            ++i;
          }
        }
        // end grace group
        else {
          if ((gracecount > 1) || (grace == Grace.unacc)) addLayerElement();
          grace = Grace.none;
          gracecount = 0;
        }
      }

      // note
      else if (_pitch.contains(musicCode[i].toUpperCase())) {
        int oct = 0;
        final Note note = Note();
        id = note.id;

        // accidentals
        if (i >= 1) {
          AccidentalWritten abcAccid = AccidentalWritten.none;
          switch (musicCode[i - 1]) {
            case '^':
              abcAccid = (i > 1 && musicCode[i - 2] == '^')
                  ? AccidentalWritten.x
                  : AccidentalWritten.s;
            case '=':
              abcAccid = AccidentalWritten.n;
            case '_':
              abcAccid = (i > 1 && musicCode[i - 2] == '_')
                  ? AccidentalWritten.ff
                  : AccidentalWritten.f;
            default:
              break;
          }
          if (abcAccid != AccidentalWritten.none) {
            final Accid accid = Accid();
            accid.accid = abcAccid;
            note.addChild(accid);
          }
        }

        if (_keyPitchAlter.toUpperCase().contains(musicCode[i].toUpperCase()) &&
            _keyPitchAlter.isNotEmpty) {
          Accid? accid = note.getFirst(ClassId.accid) as Accid?;
          if (accid == null) {
            accid = Accid();
            note.addChild(accid);
            accid.isAttribute = true;
            accid.accidGes = (_keyPitchAlterAmount < 0)
                ? AccidentalGestural.f
                : AccidentalGestural.s;
          }
        }

        // set pitch name
        if (_isUpper(musicCode[i])) {
          oct = 4;
        } else {
          oct = 5;
        }
        note.pname = strToPitchname(musicCode[i].toLowerCase());

        // set octave
        while (i + 1 < musicCode.length &&
            (musicCode[i + 1] == "'" || musicCode[i + 1] == ',')) {
          if (musicCode[i + 1] == ',') {
            oct -= 1;
          } else {
            oct += 1;
          }
          ++i;
        }
        note.oct = oct;

        // set duration
        String numStr = '', numbaseStr = '';
        int dots = 0;
        int numbase = 1;
        if ((broken < 0) && (grace == Grace.none)) {
          dots = -broken;
          broken = 0;
        }
        while (i + 1 < musicCode.length && _isDigit(musicCode[i + 1])) {
          ++i;
          numStr += musicCode[i];
        }
        while (i + 1 < musicCode.length && musicCode[i + 1] == '/') {
          ++i;
          numbase *= 2;
        }
        while (i + 1 < musicCode.length && _isDigit(musicCode[i + 1])) {
          ++i;
          numbaseStr += musicCode[i];
        }
        while (i + 1 < musicCode.length && musicCode[i + 1] == '>') {
          ++i;
          ++broken;
          ++dots;
        }
        while (i + 1 < musicCode.length && musicCode[i + 1] == '<') {
          ++i;
          --broken;
        }
        int num = numStr.isEmpty ? 1 : strToInt(numStr);
        numbase = numbaseStr.isEmpty ? numbase : strToInt(numbaseStr);
        while ((num & (num - 1)) != 0) {
          ++dots;
          // won't work for num > 12
          num = num - num ~/ 3;
        }
        if ((numbase & (numbase - 1)) != 0) {
          logError('ABC import: note length divider must be power of 2');
        }
        int dur = (num == 0) ? 4 : unitDur * numbase ~/ num;

        // set grace
        if (grace != Grace.none) {
          ++gracecount;
          note.grace = grace;
          // "The unit duration to use for gracenotes is not specified by the
          // abc file"
          // setting it to an eighth by default for now
          note.dur = MeiDuration.dur8;
          if (grace == Grace.unacc) note.stemMod = Stemmodifier.n1slash;
        }

        // add articulation
        if (artic.isNotEmpty) {
          addArticulation(note);
        }

        // add chord symbols
        if (harmStack.isNotEmpty) {
          addChordSymbol(note);
        }

        // add dynamics
        if (dynam.isNotEmpty) {
          addDynamic(note);
        }

        // add fermata
        if (fermata != Staffrel.none) {
          addFermata(note);
        }

        // add ornaments
        if (ornam.isNotEmpty) {
          addOrnaments(note);
        }

        // add repeat mark
        if (repeatMark != RepeatmarklogFunc.none) {
          addRepeatMark(note);
        }

        if ((broken < 0) && (grace == Grace.none)) {
          for (int k = 0; k != -broken; ++k) {
            dur = dur * 2;
          }
        } else if ((dots == 0) && (broken > 0) && (grace == Grace.none)) {
          for (; broken != 0; --broken) {
            dur = dur * 2;
          }
        }
        final MeiDuration meiDur =
            (dur == 0) ? MeiDuration.breve : strToDuration('$dur');

        if (chord != null) {
          chord.addChild(note);
          if (!chord.hasDur) {
            if (dots > 0) chord.dots = dots;
            if (num == 0) chord.stemVisible = false;
            chord.dur = meiDur;
          }
        } else {
          if (dots > 0) note.dots = dots;
          if (num == 0) note.stemVisible = false;
          note.dur = meiDur;
          if ((note.dur ?? MeiDuration.none).value <
              MeiDuration.dur8.value) {
            // if note cannot be beamed, write it directly to the layer
            if (noteStack.isNotEmpty) addLayerElement();
            layer!.addChild(note);
            lineNoteArray.add(note);
          } else {
            noteStack.add(note);
            lineNoteArray.add(note);
          }
        }

        if (tieStack.isNotEmpty) {
          tieStack.last.endid = '#$id';
          tieStack.clear();
        }
        for (final Slur slur in slurStack) {
          if (!slur.hasStartid) {
            slur.startid = '#$id';
          }
        }
      }

      // spaces
      else if (musicCode[i] == 'x') {
        final Space space = Space();
        id = space.id;

        // add chord symbols
        if (harmStack.isNotEmpty) {
          addChordSymbol(space);
        }

        // set duration
        String numStr = '', numbaseStr = '';
        int dots = 0;
        int numbase = 1;
        if ((broken < 0) && (grace == Grace.none)) {
          dots = -broken;
          broken = 0;
        }
        while (i + 1 < musicCode.length && _isDigit(musicCode[i + 1])) {
          ++i;
          numStr += musicCode[i];
        }
        while (i + 1 < musicCode.length && musicCode[i + 1] == '/') {
          ++i;
          numbase *= 2;
        }
        while (i + 1 < musicCode.length && _isDigit(musicCode[i + 1])) {
          ++i;
          numbaseStr += musicCode[i];
        }
        while (i + 1 < musicCode.length && musicCode[i + 1] == '>') {
          ++i;
          ++broken;
          ++dots;
        }
        while (i + 1 < musicCode.length && musicCode[i + 1] == '<') {
          ++i;
          --broken;
        }
        int num = numStr.isEmpty ? 1 : strToInt(numStr);
        numbase = numbaseStr.isEmpty ? numbase : strToInt(numbaseStr);
        while ((num & (num - 1)) != 0) {
          ++dots;
          // won't work for num > 12
          num = num - num ~/ 3;
        }
        if ((numbase & (numbase - 1)) != 0) {
          logError('ABC import: note length divider must be power of 2');
        }
        int dur = unitDur * numbase ~/ num;

        if (broken < 0) {
          for (int k = 0; k != -broken; ++k) {
            dur = dur * 2;
          }
        } else if ((dots == 0) && (broken > 0)) {
          for (; broken != 0; --broken) {
            dur = dur * 2;
          }
        }
        final MeiDuration meiDur =
            (dur == 0) ? MeiDuration.breve : strToDuration('$dur');

        if (dots > 0) space.dots = dots;
        space.dur = meiDur;

        // spaces cannot be beamed
        addLayerElement();
        layer!.addChild(space);
      }

      // padding
      else if (musicCode[i] == 'y') {
        // Pad *pad = new Pad;
        logWarning('ABC import: Extra space not supported');
      }

      // rests
      else if (musicCode[i] == 'z') {
        final Rest rest = Rest();
        id = rest.id;

        // add chord symbols
        if (harmStack.isNotEmpty) {
          addChordSymbol(rest);
        }

        // add fermata
        if (fermata != Staffrel.none) {
          addFermata(rest);
        }

        // add repeat mark
        if (repeatMark != RepeatmarklogFunc.none) {
          addRepeatMark(rest);
        }

        // set duration
        String numStr = '', numbaseStr = '';
        int dots = 0;
        int numbase = 1;
        if ((broken < 0) && (grace == Grace.none)) {
          dots = -broken;
          broken = 0;
        }
        while (i + 1 < musicCode.length && _isDigit(musicCode[i + 1])) {
          ++i;
          numStr += musicCode[i];
        }
        while (i + 1 < musicCode.length && musicCode[i + 1] == '/') {
          ++i;
          numbase *= 2;
        }
        while (i + 1 < musicCode.length && _isDigit(musicCode[i + 1])) {
          ++i;
          numbaseStr += musicCode[i];
        }
        while (i + 1 < musicCode.length && musicCode[i + 1] == '>') {
          ++i;
          ++broken;
          ++dots;
        }
        while (i + 1 < musicCode.length && musicCode[i + 1] == '<') {
          ++i;
          --broken;
        }
        int num = numStr.isEmpty ? 1 : strToInt(numStr);
        numbase = numbaseStr.isEmpty ? numbase : strToInt(numbaseStr);
        while ((num & (num - 1)) != 0) {
          ++dots;
          // won't work for num > 12
          num = num - num ~/ 3;
        }
        if ((numbase & (numbase - 1)) != 0) {
          logError('ABC import: note length divider must be power of 2');
        }
        int dur = unitDur * numbase ~/ num;

        if (broken < 0) {
          for (int k = 0; k != -broken; ++k) {
            dur = dur * 2;
          }
        } else if ((dots == 0) && (broken > 0)) {
          for (; broken != 0; --broken) {
            dur = dur * 2;
          }
        }
        final MeiDuration meiDur =
            (dur == 0) ? MeiDuration.breve : strToDuration('$dur');

        if (dots > 0) rest.dots = dots;
        rest.dur = meiDur;

        // rests cannot be beamed
        addLayerElement();
        layer!.addChild(rest);
      }

      // multi-measure rests
      else if (musicCode[i] == 'Z') {
        final MultiRest multiRest = MultiRest();
        final StringBuffer numString = StringBuffer();
        while (i + 1 < musicCode.length && _isDigit(musicCode[i + 1])) {
          numString.write(musicCode[i + 1]);
          ++i;
        }
        multiRest.num = strToInt(numString.toString());
        layer!.addChild(multiRest);
      }

      // text elements
      else if (musicCode[i] == '"') {
        ++i;
        if (_charAt(musicCode, i) == '^' ||
            _charAt(musicCode, i) == '_' ||
            _charAt(musicCode, i) == '<' ||
            _charAt(musicCode, i) == '>' ||
            _charAt(musicCode, i) == '@') {
          logWarning('ABC import: Annotations are not fully support yet');
          ++i;
        }
        final StringBuffer chordSymbol = StringBuffer();
        while (i < musicCode.length && musicCode[i] != '"') {
          chordSymbol.write(musicCode[i]);
          ++i;
        }
        final Harm harm = Harm();
        final Text text = Text();
        text.text = chordSymbol.toString();
        harm.addChild(text);
        harmStack.add(harm);
        controlElements.add((layer!.id, harm));
      }

      // suppressing score line-breaks
      else if (musicCode[i] == r'\') {
        sysBreak = false;
      }

      // barLine
      else if (musicCode[i] == '|') {
        // add stacked elements to layer
        addLayerElement();
        i = setBarLine(musicCode, i);

        if (barLines.$2 != Barrendition.none) {
          final Measure measure = Measure();
          measure.left = barLines.$1;
          measure.right = barLines.$2;
          barLines = (Barrendition.none, Barrendition.none);
          final Staff staff = Staff();

          staff.addChild(layer!);
          measure.addChild(staff);
          section.addChild(measure);
          layer = Layer();
          layer!.n = 1;
          for (final Tempo tempo in tempoStack) {
            measure.addChild(tempo);
          }
          tempoStack.clear();
        }
      }

      ++i;

      // check if there is a clef change
      if (clef != null) {
        noteStack.add(clef!);
        clef = null;
      }

      // check if there is a change in meter
      if (meter != null) {
        // todo: apply meter changes to staves
        final ScoreDef scoreDef = ScoreDef();
        meter!.isAttribute = true;
        scoreDef.addChild(meter!);
        section.addChild(scoreDef);
        meter = null;
      }

      if (durDefault != MeiDuration.none) {
        final ScoreDef scoreDef = ScoreDef();
        scoreDef.durDefault = durDefault;
        section.addChild(scoreDef);
        durDefault = MeiDuration.none;
      }
    }

    // by default, line-breaks in the code generate line-breaks in the score
    // Verovio does not support line-breaks within a layer
    // has to be refined later
    if (sysBreak &&
        linebreak.isNotEmpty &&
        !(section.children.isNotEmpty &&
            section.children.last.classId == ClassId.sb)) {
      addLayerElement();
      final Sb sb = Sb();
      sb.id = 'abcLine${_fmt02(lineNum + 1)}';
      section.addChild(sb);
    }
  }
}

// ---------------------------------------------------------------------------
// Small character helpers mirroring ctype.h / std::string lookups
// ---------------------------------------------------------------------------

/// `std::string::at` with the C++ out-of-range behaviour mapped to ''
/// instead of an exception (the C++ reader relies on operator[] returning
/// '\0' past the end in several places).
String _charAt(String s, int i) => (i >= 0 && i < s.length) ? s[i] : '';

bool _isSpace(String c) =>
    c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '\x0B' || c == '\x0C';

bool _isDigit(String c) =>
    c.isNotEmpty && c.codeUnitAt(0) >= 0x30 && c.codeUnitAt(0) <= 0x39;

bool _isAlpha(String c) {
  if (c.isEmpty) return false;
  final int lower = c.codeUnitAt(0) | 0x20;
  return lower >= 0x61 && lower <= 0x7A;
}

bool _isUpper(String c) =>
    c.isNotEmpty && c.codeUnitAt(0) >= 0x41 && c.codeUnitAt(0) <= 0x5A;

/// True when [s] is empty or consists only of spaces (mirrors
/// `find_first_not_of(' ') == std::string::npos`).
bool _allSpaces(String s) {
  for (int i = 0; i < s.length; ++i) {
    if (s[i] != ' ') return false;
  }
  return true;
}

/// `find_first_of(chars, from)`.
int _indexOfAny(String s, String chars, int from) {
  for (int i = from; i < s.length; ++i) {
    if (chars.contains(s[i])) return i;
  }
  return -1;
}

/// `find_first_not_of(chars, from)`.
int _indexOfNotOf(String s, String chars, int from) {
  for (int i = from; i < s.length; ++i) {
    if (!chars.contains(s[i])) return i;
  }
  return -1;
}

/// Removes a single trailing '\r' (getline keeps it; ParseLyrics strips it).
String _stripCr(String line) {
  if (line.isNotEmpty && line[line.length - 1] == '\r') {
    return line.substring(0, line.length - 1);
  }
  return line;
}

/// `%02d` formatting.
String _fmt02(int value) => value.toString().padLeft(2, '0');
