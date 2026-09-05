/// Port of the structural and layer element classes needed for the MEI
/// tree: Measure, Staff, Layer, Section, Score, Mdiv, Note, Rest, Clef,
/// BarLine. (Mirrors measure.h, staff.h, layer.h, section.h, score.h,
/// mdiv.h, note.h, rest.h, clef.h, barline.h.)
///
/// Only the attribute classes required by the applied interfaces are
/// attached so far; the remaining decorative atts are added together with
/// their features (drawing/MIDI) in the coming phases.
library;

import 'dart:math' as math;

import 'package:verovio_dart/src/core/attdef.dart' show meiUnset, MeiDuration;
import 'package:verovio_dart/src/core/fraction.dart';
import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/point.dart' show Point;
import 'package:verovio_dart/src/core/options_shell.dart' show Condense;
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/layout/adjust_x_overflow.dart'
    show AdjustXOverflowFunctor;
import 'package:verovio_dart/src/layout/find_layer_elements.dart'
    show LayersInTimeSpanFunctor, LayerElementsInTimeSpanFunctor;
import 'package:verovio_dart/src/layout/floating_positioner.dart'
    show FloatingPositioner;
import 'package:verovio_dart/src/layout/horizontal_aligner.dart'
    show Alignment, MeasureAligner, TimestampAligner, LayerElementAlignmentDuration;
import 'package:verovio_dart/src/layout/preparedata_functor.dart'
    show LayoutElementHelpers;
import 'package:verovio_dart/src/layout/vertical_aligner.dart'
    show StaffAlignment;
import 'package:verovio_dart/src/model/beam_segment.dart'
    show BeamElementCoord;
import 'package:verovio_dart/src/model/atts/atts_analytical.dart';
import 'package:verovio_dart/src/model/atts/atts_cmn.dart';
import 'package:verovio_dart/src/model/atts/atts_midi.dart';
import 'package:verovio_dart/src/model/atts/atts_stringtab.dart';
import 'package:verovio_dart/src/model/atts/atts_facsimile.dart';
import 'package:verovio_dart/src/model/atts/atts_gestural.dart';
import 'package:verovio_dart/src/model/atts/atts_mensural.dart';
import 'package:verovio_dart/src/model/atts/atts_usersymbols.dart';
import 'package:verovio_dart/src/model/atts/atts_externalsymbols.dart';
import 'package:verovio_dart/src/model/atts/atts_shared.dart';
import 'package:verovio_dart/src/model/atts/atts_visual.dart';
import 'package:verovio_dart/src/model/atts/mei_values.dart' show HeadShapeType;
import 'package:verovio_dart/src/model/atts/mei_enums.dart';
import 'package:verovio_dart/src/model/comparison.dart'
    show AttNIntegerComparison, Filters;
import 'package:verovio_dart/src/model/drawing_interfaces.dart';
import 'package:verovio_dart/src/model/interfaces/facsimile_interface.dart';
import 'package:verovio_dart/src/model/interfaces/pitch_interface.dart';
import 'package:verovio_dart/src/model/interfaces/position_interface.dart';
import 'package:verovio_dart/src/model/interfaces/simple_interfaces.dart';
import 'package:verovio_dart/src/model/interfaces/duration_interface.dart';
import 'package:verovio_dart/src/model/layer_element.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart'
    show Accid, Beam, Chord, Dots, KeySig, MeterSig, MeterSigGrp;
import 'package:verovio_dart/src/model/mensur.dart' show Mensur;
import 'package:verovio_dart/src/model/doc.dart' show Doc, Page, Pages;
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/model/zone.dart' show Zone;
import 'package:verovio_dart/src/model/text_elements.dart' show RunningElement;
import 'package:verovio_dart/src/model/scoredef.dart';
import 'package:verovio_dart/src/model/system_page_elements.dart';

/// Mirrors `vrv::TransPitch` (transposition.h:35) — the diatonic pitch class
/// (`pname`: C = 0 … B = 6), chromatic alteration (`accid`) and octave
/// (`oct`) carried through the transposer.
///
/// There is no Dart `TransposeFunctor` yet (transpose is outside
/// layout/rendering); `Note.getTransPitch`, `Note.updateFromTransPitch` and
/// `Rest.updateFromTransLoc` below are ported against this value class so
/// they are ready when the functor lands.
class TransPitch {
  TransPitch(this.pname, this.accid, this.oct);
  TransPitch.copy(TransPitch other)
      : pname = other.pname,
        accid = other.accid,
        oct = other.oct;

  /// Diatonic pitch class name: C = 0, D = 1, … B = 6 (mirrors `m_pname`).
  int pname;

  /// Chromatic alteration: 0 = natural, 1 = sharp, -1 = flat, … (mirrors
  /// `m_accid`).
  int accid;

  /// Octave number: 4 = middle-C octave (mirrors `m_oct`).
  int oct;

  /// Mirrors `TransPitch::GetAccidGes` (transposition.cpp:195).
  AccidentalGestural getAccidGes() {
    switch (accid) {
      case -3:
        return AccidentalGestural.tf;
      case -2:
        return AccidentalGestural.ff;
      case -1:
        return AccidentalGestural.f;
      case 0:
        return AccidentalGestural.n;
      case 1:
        return AccidentalGestural.s;
      case 2:
        return AccidentalGestural.ss;
      case 3:
        return AccidentalGestural.ts;
      default:
        break;
    }
    logWarning('Transposition: Could not get Gestural Accidental for $accid');
    return AccidentalGestural.none;
  }

  /// Mirrors `TransPitch::GetAccidWritten` (transposition.cpp:211).
  AccidentalWritten getAccidWritten() {
    switch (accid) {
      case -3:
        return AccidentalWritten.tf;
      case -2:
        return AccidentalWritten.ff;
      case -1:
        return AccidentalWritten.f;
      case 0:
        return AccidentalWritten.n;
      case 1:
        return AccidentalWritten.s;
      case 2:
        return AccidentalWritten.x;
      case 3:
        return AccidentalWritten.xs;
      default:
        break;
    }
    logWarning('Transposition: Could not get Written Accidental for $accid');
    return AccidentalWritten.none;
  }

  /// Mirrors `TransPitch::GetPitchName` (transposition.cpp:227).
  Pitchname getPitchName() => Pitchname.fromValue(pname + Pitchname.c.value);

  /// Mirrors `TransPitch::SetPitch` (transposition.cpp:371).
  void setPitch(int aPname, int anAccid, int anOct) {
    pname = aPname;
    accid = anAccid;
    oct = anOct;
  }
}

// ---------------------------------------------------------------------------
// Structure elements
// ---------------------------------------------------------------------------

/// Mirrors `vrv::Ossia`: alternative staves within a measure.
class Ossia extends Object with AttTyped {
  Ossia() : super(ClassId.ossia) {
    drawingStaffGrp.setParent(this);
    drawingLeftBarLine.form = Barrendition.single;
    reset();
  }

  @override
  ClassId get classId => ClassId.ossia;

  @override
  String get className => 'ossia';

  @override
  Object clone() {
    final copy = Ossia();
    copy.copyFrom(this);
    return copy;
  }

  @override
  bool isSupportedChild(ClassId classId) {
    if (classId == ClassId.staff) return true;
    if (Object.isEditorialElementId(classId)) return true;
    return false;
  }

  @override
  void reset() {
    super.reset();
    resetDrawingStaffGrp();
    resetAlignments();
  }

  /// The ossia staffGrp used for drawing (mirrors `m_drawingStaffGrp`);
  /// owned, not a tree child.
  final StaffGrp drawingStaffGrp = StaffGrp();

  /// A flag indicating that the ossia is the first / last of a series
  /// (mirrors `m_isFirst` / `m_isLast`).
  bool isFirstFlag = true;
  bool isLastFlag = true;

  /// Mirrors `Ossia::IsFirst` / `SetFirst`.
  bool isFirst() => isFirstFlag;
  void setFirst(bool isFirst) => isFirstFlag = isFirst;

  /// Mirrors `Ossia::IsLast` / `SetLast`.
  bool isLast() => isLastFlag;
  void setLast(bool isLast) => isLastFlag = isLast;

  /// The clef / keySig alignment set by `AdjustOssiaStaffDefFunctor` (mirrors
  /// `m_clefAlignment` / `m_keySigAlignment`).
  Alignment? clefAlignment;
  Alignment? keySigAlignment;

  /// The left bar line used for drawing when there is no measure left bar
  /// line (mirrors `m_drawingLeftBarLine`); owned, not a tree child.
  final BarLine drawingLeftBarLine = BarLine();

  /// Mirrors `Ossia::SetClefAlignment` / `SetKeySigAlignment`.
  void setClefAlignment(Alignment? alignment) => clefAlignment = alignment;
  void setKeySigAlignment(Alignment? alignment) => keySigAlignment = alignment;

  /// Mirrors `Ossia::AddDrawingStaffDef` / `ResetDrawingStaffGrp` /
  /// `GetDrawingStaffGrp`.
  void addDrawingStaffDef(StaffDef drawingStaffDef) {
    drawingStaffGrp.addChild(drawingStaffDef);
  }

  void resetDrawingStaffGrp() {
    drawingStaffGrp.reset();
    isFirstFlag = true;
    isLastFlag = true;
  }

  StaffGrp getDrawingStaffGrp() => drawingStaffGrp;

  /// Mirrors `Ossia::GetDrawingLeftBarLine`.
  BarLine getDrawingLeftBarLine() => drawingLeftBarLine;

  static final RegExp _showScoreDefRe =
      RegExp(r'\bshow\.scoredef\.(true|false)\b');
  static final RegExp _showScoreDefTrueRe = RegExp(r'\bshow\.scoredef\.true\b');
  static final RegExp _showScoreDefFalseRe =
      RegExp(r'\bshow\.scoredef\.false\b');

  /// Mirrors `Ossia::HasShowScoreDef`.
  bool get hasShowScoreDef => hasType && _showScoreDefRe.hasMatch(type!);

  /// Mirrors `Ossia::GetShowScoreDef`; `null` for `BOOLEAN_NONE`.
  bool? get showScoreDef {
    if (hasType && _showScoreDefTrueRe.hasMatch(type!)) return true;
    if (hasType && _showScoreDefFalseRe.hasMatch(type!)) return false;
    return null;
  }

  static final RegExp _showBarLinesRe =
      RegExp(r'\bshow\.barlines\.(true|false)\b');
  static final RegExp _showBarLinesTrueRe = RegExp(r'\bshow\.barlines\.true\b');
  static final RegExp _showBarLinesFalseRe =
      RegExp(r'\bshow\.barlines\.false\b');

  /// Mirrors `Ossia::HasShowBarLines`.
  bool get hasShowBarLines => hasType && _showBarLinesRe.hasMatch(type!);

  /// Mirrors `Ossia::GetShowBarLines`; `null` for `BOOLEAN_NONE`.
  bool? get showBarLines {
    if (hasType && _showBarLinesTrueRe.hasMatch(type!)) return true;
    if (hasType && _showBarLinesFalseRe.hasMatch(type!)) return false;
    return null;
  }

  /// Mirrors `Ossia::HasMultipleOStaves`.
  bool hasMultipleOStaves() {
    int count = 0;
    final List<Object> staves = findAllDescendantsByType(ClassId.staff);
    for (final Object object in staves) {
      final Staff staff = object as Staff;
      if (staff.isOssia() && !staff.isHidden) {
        count++;
        if (count > 1) return true;
      }
    }
    return false;
  }

  /// Mirrors `Ossia::DrawScoreDef`.
  bool drawScoreDef() {
    if (!hasShowScoreDef) return hasMultipleOStaves();
    return showScoreDef == true;
  }

  /// Mirrors `Ossia::GetOriginalStaffForOssia`.
  Staff? getOriginalStaffForOssia(Staff ossia) {
    final comparison =
        AttNIntegerComparison(ClassId.staff, ossia.getNFromOssia());
    final Staff? staff = findDescendantByComparison(comparison) as Staff?;
    if (staff == null) {
      logDebug(
          'Original staff ${ossia.getNFromOssia()} for ossia could not be found');
    }
    return staff;
  }

  /// Mirrors `Ossia::ResetAlignments`.
  void resetAlignments() {
    clefAlignment = null;
    keySigAlignment = null;
    drawingLeftBarLine.resetParent();
    drawingLeftBarLine.resetAlignment();
  }

  /// Mirrors `Ossia::GetScoreDefShift`: the clef is further apart, so it
  /// takes precedence; otherwise the key signature.
  int getScoreDefShift() {
    if (clefAlignment != null) return clefAlignment!.getXRel();
    if (keySigAlignment != null) return keySigAlignment!.getXRel();
    return 0;
  }

  /// Mirrors `Ossia::GetStavesAbove` / `GetStavesBelow`: fills [map] with,
  /// for each original staff `@n`, the ossia staff `@n`s stacked above /
  /// below it.
  void getStavesAbove(Map<int, List<int>> map) {
    final List<Object> staves = findAllDescendantsByType(ClassId.staff);
    _getStaves(map, staves.reversed.toList());
  }

  void getStavesBelow(Map<int, List<int>> map) {
    final List<Object> staves = findAllDescendantsByType(ClassId.staff);
    _getStaves(map, staves);
  }

  /// Mirrors `Ossia::GetStaves`.
  void _getStaves(Map<int, List<int>> map, List<Object> staves) {
    int staffN = meiUnset;
    for (final Object object in staves) {
      final Staff staff = object as Staff;
      if (!staff.isOssia()) {
        staffN = staff.n ?? meiUnset;
        continue;
      }
      if (staff.isHidden) continue;
      if (staffN != meiUnset) {
        final List<int> ossias = map.putIfAbsent(staffN, () => <int>[]);
        final int ossiaN = staff.n ?? 0;
        if (!ossias.contains(ossiaN)) ossias.add(ossiaN);
      }
    }
  }

  /// Mirrors `Ossia::GetDrawingTopOStaff`.
  Staff? getDrawingTopOStaff() {
    if (drawingStaffGrp.childCount == 0) return null;
    final StaffDef staffDef = drawingStaffGrp.getFirst() as StaffDef;
    final comparison = AttNIntegerComparison(ClassId.staff, staffDef.n ?? meiUnset);
    final Staff? staff = findDescendantByComparison(comparison) as Staff?;
    return (staff != null && !staff.isHidden) ? staff : null;
  }

  /// Mirrors `Ossia::GetDrawingBottopOStaff`.
  Staff? getDrawingBottopOStaff() {
    if (drawingStaffGrp.childCount == 0) return null;
    final StaffDef staffDef = drawingStaffGrp.getLast() as StaffDef;
    final comparison = AttNIntegerComparison(ClassId.staff, staffDef.n ?? meiUnset);
    final Staff? staff = findDescendantByComparison(comparison) as Staff?;
    return (staff != null && !staff.isHidden) ? staff : null;
  }

  /// Mirrors `Ossia::GetOStaffNs`.
  List<int> getOStaffNs() {
    final List<Object> staves = findAllDescendantsByType(ClassId.staff);
    final List<int> ns = [];
    for (final Object object in staves) {
      final Staff staff = object as Staff;
      if (staff.isOssia() && !staff.isHidden) ns.add(staff.n ?? 0);
    }
    return ns;
  }
}

/// Mirrors `vrv::Measure`.
class Measure extends Object
    with
        AttFacsimile,
        FacsimileInterface,
        AttNNumberLike,
        AttPointing,
        AttTyped,
        AttBarring,
        AttCoordX1,
        AttCoordX2,
        AttMeasureLog,
        AttMeterConformanceBar,
        AttMeasureNumbers,
        AttVisibility {
  /// Mirrors `Measure(MeasureType, int logMeasureNb)`.
  Measure([this.measureType = MeasureType.measured, this.logMeasureNb = -1])
      : super(ClassId.measure) {
    reset();
    // We set the parent because we want to access the parent doc / measure
    // from the embedded objects (mirrors the C++ constructor).
    measureAligner.setParent(this);
    timestampAligner.setParent(this);
    leftBarLine.setParent(this);
    rightBarLine.setParent(this);
    // Mirrors the barline positions set in the C++ constructor.
    leftBarLine.position = BarlinePosition.left;
    rightBarLine.position = BarlinePosition.right;
  }

  /// The measure type (mirrors `m_measureType`).
  MeasureType measureType = MeasureType.measured;

  /// The log measure number (mirrors `m_logMeasureNb`).
  int logMeasureNb;

  /// Facsimile X positions for transcription layout (mirrors
  /// `m_drawingFacsX1` / `m_drawingFacsX2`).
  int drawingFacsX1 = meiUnset;
  int drawingFacsX2 = meiUnset;

  /// The measure x position relative to the system, set by the horizontal
  /// layout (mirrors `m_drawingXRel`).
  int _drawingXRel = 0;

  /// The cached absolute x position (mirrors `m_cachedDrawingX`).
  int _cachedDrawingX = meiUnset;

  /// The cached values for caching the horizontal layout (mirrors
  /// `m_cachedXRel` / `m_cachedOverflow` / `m_cachedWidth`, measure.h:403-415).
  /// Written only by [cacheXRel] (task 04f's `CacheHorizontalLayoutFunctor`),
  /// not by [setDrawingXRel] — see that method's doc comment.
  int _cachedXRel = meiUnset;
  int _cachedOverflow = meiUnset;
  int _cachedWidth = meiUnset;

  /// The measure index (1-based; set by Doc::PrepareMeasureIndices; mirrors
  /// `m_index`).
  int index = 0;

  /// The measure aligner that holds the x positions of the content of the
  /// measure (mirrors the public `m_measureAligner`).
  final MeasureAligner measureAligner = MeasureAligner();

  /// The timestamp aligner of the measure (mirrors the public
  /// `m_timestampAligner`).
  final TimestampAligner timestampAligner = TimestampAligner();

  /// The drawing scoreDef of the measure (set by the scoreDef preparation;
  /// mirrors `m_drawingScoreDef`).
  ScoreDef? drawingScoreDef;

  /// The left and right barlines embedded in the measure (mirrors
  /// `m_leftBarLine` / `m_rightBarLine`). They are owned objects but not
  /// tree children, exactly like the C++ embedded members.
  final BarLine leftBarLine = BarLine();
  final BarLine rightBarLine = BarLine();

  /// The drawing rendition of the left / right barline (mirrors
  /// `m_drawingLeftBarLine` / `m_drawingRightBarLine`).
  Barrendition drawingLeftBarLine = Barrendition.none;
  Barrendition drawingRightBarLine = Barrendition.single;

  /// Per-staff barline renditions for measures with invisible staves
  /// (mirrors `m_invisibleStaffBarlines`): staff @n → (left, right).
  final Map<int, (Barrendition, Barrendition)> invisibleStaffBarlines = {};

  /// True when the measure has an alignment reference with multiple layers
  /// (set by the horizontal alignment functor; mirrors
  /// `m_hasAlignmentRefWithMultipleLayers`).
  bool hasAlignmentRefWithMultipleLayersFlag = false;

  /// The ending currently attached to the measure (set by the milestones
  /// preparation; mirrors `m_drawingEnding`).
  Object? drawingEnding;

  /// Start time state variables, meant to deal with measure repetition
  /// (mirrors `m_scoreTimeOnset`).
  final List<Fraction> scoreTimeOnsets = [];

  /// End time state variables (mirrors `m_scoreTimeOffset`).
  final List<Fraction> scoreTimeOffsets = [];

  /// Real (millisecond) onset state variables (mirrors
  /// `m_realTimeOnsetMilliseconds`).
  final List<double> realTimeOnsetMilliseconds = [];

  /// Real (millisecond) offset state variables (mirrors
  /// `m_realTimeOffsetMilliseconds`).
  final List<double> realTimeOffsetMilliseconds = [];

  /// The current tempo of the measure (mirrors `m_currentTempo`).
  double currentTempo = midiTempo.toDouble();

  @override
  ClassId get classId => ClassId.measure;

  @override
  String get className => 'measure';

  @override
  Object clone() {
    final copy = Measure();
    copy.copyFrom(this);
    return copy;
  }

  /// Check if the measure has measured music (mirrors `IsMeasuredMusic`).
  bool isMeasuredMusic() => measureType == MeasureType.measured;

  @override
  void reset() {
    super.reset();
    metcon = null;
    control = null;
    left = null;
    right = null;
    n = null;
    visible = null;
    // Mirrors Measure::Reset resetting the timestamp aligner and the
    // facsimile positions.
    timestampAligner.reset();
    drawingFacsX1 = meiUnset;
    drawingFacsX2 = meiUnset;
    resetDrawingScoreDef();
    drawingLeftBarLine = Barrendition.none;
    drawingRightBarLine = Barrendition.single;
    invisibleStaffBarlines.clear();
    hasAlignmentRefWithMultipleLayersFlag = false;
    drawingEnding = null;
    index = 0;
  }

  //----------------//
  // MIDI timing state (mirrors the measure.h setters / getters)
  //----------------//

  void clearScoreTimeOnset() => scoreTimeOnsets.clear();

  void addScoreTimeOnset(Fraction offset) => scoreTimeOnsets.add(offset);

  Fraction getScoreTimeOnset([int repeat = meiUnset]) =>
      scoreTimeOnsets.isEmpty ? Fraction(0) : scoreTimeOnsets.last;

  void clearRealTimeOnsetMilliseconds() => realTimeOnsetMilliseconds.clear();

  void addRealTimeOnsetMilliseconds(double milliseconds) =>
      realTimeOnsetMilliseconds.add(milliseconds);

  double getRealTimeOnsetMilliseconds([int repeat = meiUnset]) =>
      realTimeOnsetMilliseconds.isEmpty ? 0.0 : realTimeOnsetMilliseconds.last;

  void clearScoreTimeOffset() => scoreTimeOffsets.clear();

  void addScoreTimeOffset(Fraction offset) => scoreTimeOffsets.add(offset);

  Fraction getScoreTimeOffset([int repeat = meiUnset]) =>
      scoreTimeOffsets.isEmpty ? Fraction(0) : scoreTimeOffsets.last;

  void clearRealTimeOffsetMilliseconds() => realTimeOffsetMilliseconds.clear();

  void addRealTimeOffsetMilliseconds(double milliseconds) =>
      realTimeOffsetMilliseconds.add(milliseconds);

  double getRealTimeOffsetMilliseconds([int repeat = meiUnset]) =>
      realTimeOffsetMilliseconds.isEmpty
          ? 0.0
          : realTimeOffsetMilliseconds.last;

  /// Mirrors `SetCurrentTempo`.
  void setCurrentTempo(double tempo) => currentTempo = tempo;

  /// Mirrors `GetCurrentTempo`.
  double getCurrentTempo() => currentTempo;

  //----------------//
  // Drawing state (mirrors measure.h)
  //----------------//

  /// Mirrors `Measure::SetDrawingXRel`.
  void setDrawingXRel(int drawingXRel) {
    resetCachedDrawingX();
    _drawingXRel = drawingXRel;
  }

  /// Mirrors `GetDrawingXRel`.
  int getDrawingXRel() => _drawingXRel;

  /// Mirrors `Measure::ResetCachedDrawingX`.
  @override
  void resetCachedDrawingX() => _cachedDrawingX = meiUnset;

  /// Mirrors `GetCachedWidth` / `GetCachedOverflow` / `GetCachedXRel` /
  /// `HasCachedHorizontalLayout` (measure.h:115,134,247-248). Written only by
  /// [cacheXRel].
  int getCachedWidth() => _cachedWidth;
  int getCachedOverflow() => _cachedOverflow;
  int getCachedXRel() => _cachedXRel;
  bool hasCachedHorizontalLayout() => _cachedWidth != meiUnset;

  /// Mirrors `Measure::CacheXRel` (measure.cpp:249): with [restore] set,
  /// writes the cached xRel back into [_drawingXRel]; otherwise stores the
  /// current width / overflow / xRel into the cache. This is the only writer
  /// of the cache fields — task 04f's `CacheHorizontalLayoutFunctor`.
  void cacheXRel({bool restore = false}) {
    if (restore) {
      // Mirrors the C++ directly, which assigns `m_drawingXRel` without
      // going through `SetDrawingXRel` — the cached absolute-x
      // (`m_cachedDrawingX`) is deliberately left untouched here.
      _drawingXRel = _cachedXRel;
    } else {
      _cachedWidth = getWidth();
      _cachedOverflow = getDrawingOverflow();
      _cachedXRel = _drawingXRel;
    }
  }

  /// Mirrors `Measure::GetDrawingOverflow` (measure.cpp:375): the overflow of
  /// the widest right-overflowing control element (`<dir>`/`<dynam>`/…) past
  /// this measure's own right edge, computed by running a throwaway
  /// [AdjustXOverflowFunctor] over just this measure's subtree — exactly as
  /// the C++ does.
  int getDrawingOverflow() {
    final AdjustXOverflowFunctor adjustXOverflow = AdjustXOverflowFunctor(0);
    final Object? system = getFirstAncestor(ClassId.system);
    assert(system != null);
    adjustXOverflow.currentSystem = system as System?;
    adjustXOverflow.lastMeasure = this;
    process(adjustXOverflow);

    final FloatingPositioner? widestPositioner = adjustXOverflow.currentWidest;
    if (widestPositioner == null) return 0;

    final int measureRightX = getDrawingX() + getWidth();
    final int overflow = widestPositioner.getContentRight() - measureRightX;
    return overflow > 0 ? overflow : 0;
  }

  /// Mirrors `Measure::GetDrawingX` (the system x plus the relative one).
  @override
  int getDrawingX() {
    if (_cachedDrawingX != meiUnset) return _cachedDrawingX;
    final Object? system = getFirstAncestor(ClassId.system);
    final int systemX = system != null ? system.getDrawingX() : 0;
    return systemX + _drawingXRel;
  }

  /// Mirrors `GetWidth` (the right alignment xRel; facsimile measures use
  /// the facsimile span).
  int getWidth() {
    if (drawingFacsX2 != meiUnset) {
      return drawingFacsX2 - drawingFacsX1;
    }
    final Alignment? rightAlignment = measureAligner.getRightAlignment();
    assert(rightAlignment != null);
    return rightAlignment?.getXRel() ?? 0;
  }

  /// Mirrors `GetLeftBarLineXRel`.
  int getLeftBarLineXRel() =>
      measureAligner.getLeftBarLineAlignment()?.getXRel() ?? 0;

  /// Mirrors `GetRightBarLineXRel`.
  int getRightBarLineXRel() =>
      measureAligner.getRightBarLineAlignment()?.getXRel() ?? 0;

  /// Mirrors `GetLeftBarLineRight` (without a rendered bounding box this is
  /// the alignment position).
  int getLeftBarLineRight() {
    final int x = getLeftBarLineXRel();
    return leftBarLine.hasSelfBB() ? x + leftBarLine.getContentX2() : x;
  }

  /// Mirrors `GetRightBarLineLeft` (without a rendered bounding box this is
  /// the alignment position).
  int getRightBarLineLeft() {
    final int x = getRightBarLineXRel();
    return rightBarLine.hasSelfBB() ? x + rightBarLine.getContentX1() : x;
  }

  /// Mirrors `Measure::GetRightBarLineRight` (measure.cpp:348).
  int getRightBarLineRight() {
    final int x = getRightBarLineXRel();
    return rightBarLine.hasSelfBB() ? x + rightBarLine.getContentX2() : x;
  }

  /// Mirrors `Measure::GetInnerWidth` (measure.cpp:365).
  int getInnerWidth() => getRightBarLineLeft() - getLeftBarLineRight();

  /// Mirrors `Measure::GetInnerCenterX` (measure.cpp:370).
  int getInnerCenterX() =>
      getDrawingX() + getLeftBarLineRight() + getInnerWidth() ~/ 2;

  /// Mirrors `Measure::EnclosesTime` (measure.cpp:519): the repeat (1-based)
  /// whose real-time window contains [time] (milliseconds), or [meiUnset]
  /// when none does. The window is the measure's right-alignment time
  /// scaled by `SCORE_TIME_UNIT * 60 / currentTempo * 1000` ms.
  ///
  /// Called by the timemap export (toolkit.cpp:1940) and by
  /// `MeasureOnsetOffsetComparison` (comparison.h:492); the timemap path is
  /// not yet ported (`toolkit.dart` is load-only), so this is API parity.
  int enclosesTime(int time) {
    var repeat = 1;
    final Alignment? rightAlignment = measureAligner.getRightAlignment();
    final double timeDuration = (rightAlignment?.getTime().toDouble() ?? 0.0) *
            scoreTimeUnit *
            60.0 /
            currentTempo *
            1000.0 +
        0.5;
    for (final double onset in realTimeOnsetMilliseconds) {
      if (time >= onset && time <= onset + timeDuration) return repeat;
      repeat++;
    }
    return meiUnset;
  }

  /// Return the bottom (last) visible staff of the measure, if any
  /// (mirrors `Measure::GetBottomVisibleStaff`, measure.cpp:453).
  Staff? getBottomVisibleStaff() {
    Staff? bottomStaff;
    final List<Object> staves = findAllDescendantsByType(ClassId.staff,
        continueDepthSearchForMatches: false);
    for (final Object child in staves) {
      final Staff staff = child as Staff;
      if (!staff.drawingIsVisible()) continue;
      bottomStaff = staff;
    }
    return bottomStaff;
  }

  /// The staves of the first staffGrp of the drawing scoreDef, in the
  /// measure (mirrors `Measure::GetFirstStaffGrpStaves`, measure.cpp:418).
  List<Staff> getFirstStaffGrpStaves(ScoreDef scoreDef) {
    final List<Staff> staves = [];
    final Set<int> staffNs = {};

    // First get all the staffGrps.
    final List<Object> staffGrps =
        scoreDef.findAllDescendantsByType(ClassId.staffGrp);

    // Then the @n of each first staffDef.
    for (final Object staffGrp in staffGrps) {
      final StaffDef? staffDef =
          staffGrp.findDescendantByType(ClassId.staffDef) as StaffDef?;
      if (staffDef != null &&
          staffDef.getDrawingVisibility() != VisibilityOptimization.hidden) {
        staffNs.add(staffDef.n ?? meiUnset);
      }
    }

    // Get the corresponding staves in the measure.
    for (final int staffN in staffNs) {
      final Staff? staff = findDescendantByComparison(
              AttNIntegerComparison(ClassId.staff, staffN),
              deepness: 1) as Staff?;
      if (staff == null) continue;
      staves.add(staff);
    }
    return staves;
  }

  /// Return the first staff of the measure, skipping ossias when [excludeOStaves]
  /// (mirrors `Measure::GetFirstStaff`, measure.cpp:481).
  Staff? getFirstStaff([bool excludeOStaves = true]) {
    final List<Object> staves = findAllDescendantsByType(ClassId.staff,
        continueDepthSearchForMatches: false);
    for (final Object child in staves) {
      final Staff staff = child as Staff;
      if (staff.isOssia() && excludeOStaves) continue;
      return staff;
    }
    return null;
  }

  /// Return the last staff of the measure, skipping ossias when [excludeOStaves]
  /// (mirrors `Measure::GetLastStaff`, measure.cpp:498).
  Staff? getLastStaff([bool excludeOStaves = true]) {
    final List<Object> staves = findAllDescendantsByType(ClassId.staff,
        continueDepthSearchForMatches: false);
    for (final Object child in staves.reversed) {
      final Staff staff = child as Staff;
      if (staff.isOssia() && excludeOStaves) continue;
      return staff;
    }
    return null;
  }

  /// Return true if the measure is the first of its system (mirrors
  /// `IsFirstInSystem`).
  bool isFirstInSystem() {
    final Object? system = getFirstAncestor(ClassId.system);
    assert(system != null);
    return identical(system?.getFirst(ClassId.measure), this);
  }

  /// Return the left barline of the measure (mirrors `GetLeftBarLine`).
  BarLine getLeftBarLine() => leftBarLine;

  /// Mirrors `Measure::GetLeftBarLineLeft` (measure.cpp:281): the left
  /// barline position plus the content offset of its bounding box.
  ///
  /// Called by `Staff::GetOssiaDrawingShift` (staff.cpp:346); the Dart
  /// [Staff.getOssiaDrawingShift] already inlines the same computation and
  /// now delegates here.
  int getLeftBarLineLeft() {
    var x = getLeftBarLineXRel();
    if (leftBarLine.hasSelfBB()) {
      x += leftBarLine.getContentX1();
    }
    return x;
  }

  /// Return the right barline of the measure (mirrors `GetRightBarLine`).
  BarLine getRightBarLine() => rightBarLine;

  /// Mirrors `Measure::SetIndex` / `GetIndex`.
  void setIndex(int index) => this.index = index;
  int getIndex() => index;

  /// Store a copy of [drawingScoreDef] as the measure drawing scoreDef
  /// (mirrors `Measure::SetDrawingScoreDef`). The previous value (if any)
  /// must be reset first.
  void setDrawingScoreDef(ScoreDef drawingScoreDef) {
    assert(this.drawingScoreDef == null);
    final ScoreDef copy = ScoreDef();
    copy.replaceWithCopyOf(drawingScoreDef);
    this.drawingScoreDef = copy;
  }

  /// Delete the drawing scoreDef (mirrors `Measure::ResetDrawingScoreDef`).
  void resetDrawingScoreDef() {
    drawingScoreDef = null;
  }

  /// Getter for the drawing scoreDef (mirrors `GetDrawingScoreDef`).
  ScoreDef? getDrawingScoreDef() => drawingScoreDef;

  /// Set the drawing ending for all measures in between (mirrors
  /// `SetDrawingEnding` / `GetDrawingEnding`).
  void setDrawingEnding(Object? ending) => drawingEnding = ending;
  Object? getDrawingEnding() => drawingEnding;

  /// Mirrors `HasAlignmentRefWithMultipleLayers(bool)` /
  /// `HasAlignmentRefWithMultipleLayers()`.
  bool getHasAlignmentRefWithMultipleLayers() =>
      hasAlignmentRefWithMultipleLayersFlag;
  void setHasAlignmentRefWithMultipleLayers(bool hasRef) =>
      hasAlignmentRefWithMultipleLayersFlag = hasRef;

  /// Set the drawing rendition of the right barline (mirrors
  /// `SetDrawingRightBarLine` — `m_rightBarLine.SetForm(type)` in
  /// `measure.h:164`).
  void setDrawingRightBarLine(Barrendition rendition) {
    drawingRightBarLine = rendition;
    rightBarLine.form = rendition;
  }

  /// Set the drawing rendition of the left barline (mirrors
  /// `SetDrawingLeftBarLine` — `m_leftBarLine.SetForm(type)`).
  void setDrawingLeftBarLine(Barrendition rendition) {
    drawingLeftBarLine = rendition;
    leftBarLine.form = rendition;
  }

  /// Return true if the measure holds invisible staff barlines (mirrors
  /// `HasInvisibleStaffBarlines`).
  bool hasInvisibleStaffBarlines() => invisibleStaffBarlines.isNotEmpty;

  /// Mirrors `Measure::GetDrawingLeftBarLineByStaffN` (measure.cpp:363).
  Barrendition getDrawingLeftBarLineByStaffN(int staffN) {
    final entry = invisibleStaffBarlines[staffN];
    if (entry != null) return entry.$1;
    return Barrendition.none;
  }

  /// Mirrors `Measure::GetDrawingRightBarLineByStaffN` (measure.cpp:374).
  Barrendition getDrawingRightBarLineByStaffN(int staffN) {
    final entry = invisibleStaffBarlines[staffN];
    if (entry != null) return entry.$2;
    return Barrendition.none;
  }

  /// Mirrors `Measure::IsLastInSystem` (measure.cpp:440) — the last child of
  /// its system that is a measure.
  bool isLastInSystem() {
    final Object? system = getFirstAncestor(ClassId.system);
    if (system == null) return false;
    final Object? lastMeasure = system.getLast(ClassId.measure);
    return identical(lastMeasure, this);
  }

  /// Compute the drawing renditions of the left and right barlines from the
  /// encoded @left / @right values and the previous measure (mirrors
  /// `Measure::SetDrawingBarLines`).
  ///
  /// Deviation: the `SelectDrawingBarLines` interaction table is deferred to
  /// the horizontal layout phase; in the remaining case the encoded values
  /// are kept as-is.
  static const int barlineSystemBreak = 0x01;
  static const int barlineScoreDefInsert = 0x02;
  static const int barlineInvisibleMeasureCurrent = 0x04;
  static const int barlineInvisibleMeasurePrevious = 0x08;

  /// Mirrors `Measure::SelectDrawingBarLines` (measure.cpp:580-636): resolves
  /// the barline interaction at the boundary between the previous measure's
  /// right barline and the current measure's left one; returns the expected
  /// (previous right, current left) pair.
  (Barrendition, Barrendition) selectDrawingBarLines(Measure previous) {
    const Barrendition none = Barrendition.none;
    // Previous measure right -> current measure left -> expected barlines
    // (previous, current).
    final Map<Barrendition, Map<Barrendition, (Barrendition, Barrendition)>>
        drawingLines = {
      // Previous right barline is dotted.
      Barrendition.dotted: {
        Barrendition.dotted: (Barrendition.dotted, none),
        Barrendition.dashed: (Barrendition.dashed, none),
        Barrendition.single: (Barrendition.single, none),
        Barrendition.dbldotted: (Barrendition.dbldotted, none),
        Barrendition.dbldashed: (Barrendition.dbldashed, none),
        Barrendition.dbl: (Barrendition.dbl, none),
      },
      // Previous right barline is dashed.
      Barrendition.dashed: {
        Barrendition.dotted: (Barrendition.dashed, none),
        Barrendition.dashed: (Barrendition.dashed, none),
        Barrendition.single: (Barrendition.single, none),
        Barrendition.dbldotted: (Barrendition.dashed, Barrendition.dotted),
        Barrendition.dbldashed: (Barrendition.dbldashed, none),
        Barrendition.dbl: (Barrendition.dbl, none),
      },
      // Previous right barline is single.
      Barrendition.single: {
        Barrendition.dotted: (Barrendition.single, none),
        Barrendition.dashed: (Barrendition.single, none),
        Barrendition.single: (Barrendition.single, none),
        Barrendition.dbldotted: (Barrendition.single, Barrendition.dotted),
        Barrendition.dbldashed: (Barrendition.single, Barrendition.dashed),
        Barrendition.dbl: (Barrendition.dbl, none),
      },
      // Previous right barline is double dotted.
      Barrendition.dbldotted: {
        Barrendition.dotted: (Barrendition.dbldotted, none),
        Barrendition.dashed: (Barrendition.dotted, Barrendition.dashed),
        Barrendition.single: (Barrendition.dotted, Barrendition.single),
        Barrendition.dbldotted: (Barrendition.dbldotted, none),
        Barrendition.dbldashed: (Barrendition.dbldashed, none),
        Barrendition.dbl: (Barrendition.dbl, none),
      },
      // Previous right barline is double dashed.
      Barrendition.dbldashed: {
        Barrendition.dotted: (Barrendition.dbldashed, none),
        Barrendition.dashed: (Barrendition.dbldashed, none),
        Barrendition.single: (Barrendition.dashed, Barrendition.single),
        Barrendition.dbldotted: (Barrendition.dbldashed, none),
        Barrendition.dbldashed: (Barrendition.dbldashed, none),
        Barrendition.dbl: (Barrendition.dbl, none),
      },
      // Previous right barline is double.
      Barrendition.dbl: {
        Barrendition.dotted: (Barrendition.dbl, none),
        Barrendition.dashed: (Barrendition.dbl, none),
        Barrendition.single: (Barrendition.dbl, none),
        Barrendition.dbldotted: (Barrendition.dbl, none),
        Barrendition.dbldashed: (Barrendition.dbl, none),
        Barrendition.dbl: (Barrendition.dbl, none),
      },
    };

    final Barrendition previousRight = previous.right ?? none;
    final Barrendition currentLeft = left ?? none;
    final previousRightMap = drawingLines[previousRight];
    if (previousRightMap == null) return (previousRight, currentLeft);
    final currentLeftPair = previousRightMap[currentLeft];
    if (currentLeftPair == null) return (previousRight, currentLeft);
    return currentLeftPair;
  }

  void setDrawingBarLines(Measure? previous, int barlineDrawingFlags) {
    // First set the right barline. If none then set a single one.
    final Barrendition drawingRight =
        hasRight ? (right ?? Barrendition.single) : Barrendition.single;
    setDrawingRightBarLine(drawingRight);

    // Now adjust the right barline of the previous measure (if any) and the
    // left one.
    if (previous == null) {
      setDrawingLeftBarLine(left ?? Barrendition.none);
    } else if ((barlineDrawingFlags & barlineSystemBreak) != 0) {
      // We have rptboth on one of the two sides, split them (ignore any
      // other value).
      if ((previous.right == Barrendition.rptboth) ||
          (left == Barrendition.rptboth)) {
        previous.setDrawingRightBarLine(Barrendition.rptend);
        setDrawingLeftBarLine(Barrendition.rptstart);
      } else {
        // Nothing to do with any other value.
        setDrawingLeftBarLine(left ?? Barrendition.none);
      }
    } else if (!((barlineDrawingFlags & barlineScoreDefInsert) != 0 ||
        (barlineDrawingFlags & barlineInvisibleMeasureCurrent) != 0 ||
        (barlineDrawingFlags & barlineInvisibleMeasurePrevious) != 0)) {
      // We have rptboth split in the two measures, make them one rptboth
      // (mirrors `Measure::SetDrawingBarLines` 669-672, measure.cpp).
      if (previous.right == Barrendition.rptend &&
          left == Barrendition.rptstart) {
        previous.setDrawingRightBarLine(Barrendition.rptboth);
        setDrawingLeftBarLine(Barrendition.none);
      }
      // We have an rptend before, make sure there is none on the left.
      else if (previous.right == Barrendition.rptend) {
        setDrawingLeftBarLine(Barrendition.none);
      }
      // We have an rptstart coming, make sure there is none on the right
      // before.
      else if (left == Barrendition.rptstart) {
        // Always set the right barline to invis for spacing.
        previous.setDrawingRightBarLine(Barrendition.invis);
        setDrawingLeftBarLine(Barrendition.rptstart);
      }
      // We have an rptboth coming, make sure there is none on the right
      // before.
      else if (left == Barrendition.rptboth) {
        previous.setDrawingRightBarLine(Barrendition.invis);
        setDrawingLeftBarLine(Barrendition.rptboth);
      }
      // Handle other possible barline interactions (mirrors
      // `Measure::SelectDrawingBarLines`, measure.cpp:580-636).
      else {
        final (Barrendition previousRight, Barrendition currentLeft) =
            selectDrawingBarLines(previous);
        if (previousRight != currentLeft) {
          previous.setDrawingRightBarLine(previousRight);
          setDrawingLeftBarLine(currentLeft);
          if (hasInvisibleStaffBarlines()) {
            getLeftBarLine().position = BarlinePosition.none;
          }
        }
      }
    } else {
      if ((barlineDrawingFlags & barlineInvisibleMeasurePrevious) != 0 &&
          (barlineDrawingFlags & barlineInvisibleMeasureCurrent) == 0 &&
          (barlineDrawingFlags & barlineScoreDefInsert) == 0) {
        if (left == Barrendition.none) {
          left = Barrendition.single;
        }
      }
      setDrawingLeftBarLine(left ?? Barrendition.none);
    }
  }

  /// Store per-staff barlines for measures with invisible staves (mirrors
  /// `Measure::SetInvisibleStaffBarlines`).
  void setInvisibleStaffBarlines(
      Measure? previous,
      List<Object> currentInvisible,
      List<Object> previousInvisible,
      int barlineDrawingFlags) {
    if (previous == null) return;

    // Process invisible staves in the current measure and set right barline
    // values for previous measure.
    for (final Object object in currentInvisible) {
      final Staff staff = object as Staff;
      Barrendition rightRendition = previous.right ?? Barrendition.none;
      if (rightRendition == Barrendition.none) {
        rightRendition = Barrendition.single;
      }
      final existing = previous.invisibleStaffBarlines[staff.n ?? 0];
      if (existing == null) {
        previous.invisibleStaffBarlines[staff.n ?? 0] =
            (Barrendition.none, rightRendition);
      } else {
        previous.invisibleStaffBarlines[staff.n ?? 0] =
            (existing.$1, rightRendition);
      }
    }
    // Then process invisible staves in the previous measure and set left
    // barline values in the current measure.
    for (final Object object in previousInvisible) {
      final Staff staff = object as Staff;
      Barrendition leftRendition = left ?? Barrendition.none;
      if ((leftRendition == Barrendition.none) &&
          (barlineDrawingFlags & barlineScoreDefInsert) == 0) {
        leftRendition = Barrendition.single;
      }
      final existing = invisibleStaffBarlines[staff.n ?? 0];
      if (existing == null) {
        invisibleStaffBarlines[staff.n ?? 0] =
            (leftRendition, Barrendition.none);
      } else {
        invisibleStaffBarlines[staff.n ?? 0] = (leftRendition, existing.$2);
      }
    }
  }

  @override
  bool isSupportedChild(ClassId classId) {
    if (classId == ClassId.ossia || classId == ClassId.staff) return true;
    if (classId == ClassId.factoryStagedir) return true;
    if (Object.isControlElementId(classId)) return true;
    if (Object.isEditorialElementId(classId)) return true;
    return false;
  }

  /// Mirrors `Measure::AddChildBack` (measure.cpp:183): like [addChild] but
  /// a non-staff child is inserted before the first staff child so staves
  /// stay grouped at the back. The C++ callers are
  /// `ConvertToCmnFunctor::VisitMensuralStaff` (convertfunctor.cpp:758) and
  /// `HumdrumInput::addChildBackMeasureOrSection` (iohumdrum.cpp:10062) —
  /// both out of scope for this port (mensural conversion / Humdrum IO) —
  /// so this is API parity until those paths land.
  bool addChildBack(Object child) {
    if (!isSupportedChild(child.classId) ||
        !addChildAdditionalCheck(child)) {
      logError("Adding '${child.className}' to a '$className'");
      return false;
    }

    child.setParent(this);
    final List<Object> children = childrenForModification;
    if (children.isEmpty) {
      children.add(child);
    } else if (children.last.isClass(ClassId.staff)) {
      children.add(child);
    } else {
      for (var i = 0; i < children.length; i++) {
        if (!children[i].isClass(ClassId.staff)) {
          children.insert(i, child);
          break;
        }
      }
    }
    modify();

    return true;
  }
}

/// A ledger line: no MEI equivalent, a list of dashes represented as pairs of
/// points (left, right), mirrors `vrv::LedgerLine` (staff.h).
class LedgerLine {
  /// One dash of the ledger line (mirrors the nested `LedgerLine::Dash`).
  final List<Dash> dashes = [];

  /// Add a dash to the ledger line, merging with overlapping neighbors
  /// (mirrors `LedgerLine::AddDash`).
  void addDash(int left, int right, int extension, Object? event) {
    int insertAt = dashes.length;
    for (int i = 0; i < dashes.length; i++) {
      if (dashes[i].x1 > left) {
        insertAt = i;
        break;
      }
    }
    dashes.insert(insertAt, Dash(left, right, event));

    // Merge dashes which overlap by more than 1.5 extensions: dashes
    // belonging to the same chord overlap by at least two extensions and get
    // merged; overlapping dashes of adjacent notes do not.
    int previous = 0;
    int current = 1;
    while (current < dashes.length) {
      if (dashes[previous].x2 > dashes[current].x1 + 1.5 * extension) {
        dashes[previous].mergeWith(dashes[current]);
        dashes.removeAt(current);
      } else {
        previous = current;
        current++;
      }
    }
  }
}

/// One dash of a [LedgerLine]: a pair of points plus the events that
/// contributed to it (mirrors `vrv::LedgerLine::Dash`).
class Dash {
  Dash(this.x1, this.x2, Object? event) : events = event == null ? [] : [event];

  int x1;
  int x2;
  final List<Object> events;

  /// Merge [other] into this dash (mirrors `LedgerLine::Dash::MergeWith`).
  void mergeWith(Dash other) {
    x1 = math.min(other.x1, x1);
    x2 = math.max(other.x2, x2);
    events.addAll(other.events);
  }
}

/// Mirrors `vrv::Staff` (atts subset; the full set arrives with layout).
class Staff extends Object
    with
        VisibilityDrawingInterface,
        AttFacsimile,
        FacsimileInterface,
        AttCoordY1,
        AttNInteger,
        AttTyped,
        AttVisibility {
  Staff() : super(ClassId.staff) {
    reset();
  }

  /// The drawing n (set by the layout functors).
  int drawingN = 0;

  /// Indicates if the staff is an ossia staff (mirrors `m_isOssia`).
  bool isOssiaFlag = false;

  /// The number of lines of the drawing staff (mirrors `m_drawingLines`).
  int drawingLines = 5;

  /// The notation type of the drawing staffDef (mirrors
  /// `m_drawingNotationType`).
  Notationtype? drawingNotationtype;

  /// The tuning of the drawing staffDef (mirrors `m_drawingTuning`). Typed
  /// as [Object] to avoid an import cycle.
  Object? drawingTuning;

  /// The ledger lines above / below the staff, cue and non-cue (filled by
  /// `CalcLedgerLinesFunctor`; mirrors `m_ledgerLinesAbove` /
  /// `m_ledgerLinesBelow` / `m_ledgerLinesAboveCue` / `m_ledgerLinesBelowCue`).
  final List<LedgerLine> ledgerLinesAbove = [];
  final List<LedgerLine> ledgerLinesBelow = [];
  final List<LedgerLine> ledgerLinesAboveCue = [];
  final List<LedgerLine> ledgerLinesBelowCue = [];

  /// Facsimile Y position of the staff (mirrors `m_drawingFacsY`).
  int drawingFacsY = meiUnset;

  /// The size of the drawing staff (mirrors `m_drawingStaffSize`).
  int drawingStaffSize = 100;

  /// The drawing staffDef of the staff (mirrors `m_drawingStaffDef`), set by
  /// the scoreDef preparation. Typed as [Object] until the scoreDef phase
  /// wires the StaffDef type.
  Object? drawingStaffDef;

  /// A pointer to the StaffAlignment for aligning the staves (mirrors
  /// `m_staffAlignment`).
  StaffAlignment? staffAlignment;

  /// The time-spanning elements currently running over this staff (mirrors
  /// `m_timeSpanningElements`).
  final List<Object> timeSpanningElements = [];

  /// The drawing rotation for facsimile rendering (mirrors
  /// `m_drawingRotation`).
  double drawingRotation = 0.0;

  /// Mirrors `SetAlignment`.
  void setAlignment(StaffAlignment? alignment) => staffAlignment = alignment;

  /// Mirrors `GetAlignment`.
  StaffAlignment? getAlignment() => staffAlignment;

  /// Mirrors `Staff::GetDrawingY`: the system y plus the staff alignment
  /// yRel (0 without an alignment).
  @override
  int getDrawingY() {
    if (drawingFacsY != meiUnset) return drawingFacsY;

    if (staffAlignment == null) return 0;

    if (cachedDrawingY != meiUnset) return cachedDrawingY;

    final Object? system = getFirstAncestor(ClassId.system);

    cachedDrawingY = (system?.getDrawingY() ?? 0) + staffAlignment!.getYRel();
    return cachedDrawingY;
  }

  /// Mirrors `Staff::SetDrawingRotation` / `GetDrawingRotation` /
  /// `HasDrawingRotation` (staff.h:172-174).
  void setDrawingRotation(double rotation) => drawingRotation = rotation;
  double getDrawingRotation() => drawingRotation;
  bool hasDrawingRotation() => drawingRotation != 0.0;

  /// Mirrors `Staff::GetDrawingRotationOffsetFor` (staff.cpp:137).
  int getDrawingRotationOffsetFor(int x) {
    final int xDiff = x - getDrawingX();
    return (xDiff * math.tan(getDrawingRotation() * math.pi / 180.0)).toInt();
  }

  /// Mirrors `Staff::GetDrawingRotate` (staff.cpp:208): the facsimile
  /// rotation when the staff has a `@facs` in a facsimile/transcription
  /// document, 0 otherwise.
  ///
  /// Deviation from the C++: `FacsimileInterface::GetDrawingRotate`
  /// (facsimileinterface.cpp:74) asserts a resolved zone (`m_zone`); the
  /// zone is attached by `PrepareFacsimileFunctor`, which never runs in
  /// this port outside facsimile documents (`Doc.prepareData` skips it —
  /// see `doc.cpp:973`), so a missing zone returns 0 instead of asserting.
  double getDrawingRotate() {
    if (hasFacs) {
      final Object? doc = getFirstAncestor(ClassId.doc);
      if (doc is Doc &&
          (doc.isFacs() || doc.isTranscription())) {
        final Zone? resolved = zone;
        if (resolved?.rotate != null) return resolved!.rotate!;
        return 0;
      }
    }
    return 0;
  }

  /// Mirrors `Staff::AdjustDrawingStaffSize` (staff.cpp:220): recompute the
  /// drawing staff size from the facsimile zone height (corrected for the
  /// zone rotation) in facsimile / neume-lines documents.
  ///
  /// Deviation: the C++ asserts a resolved zone; a missing zone (or missing
  /// coordinates) is a no-op here since `PrepareFacsimileFunctor` never runs
  /// outside facsimile documents in this port (see [getDrawingRotate]).
  void adjustDrawingStaffSize() {
    if (hasFacs) {
      final Object? ancestor = getFirstAncestor(ClassId.doc);
      if (ancestor is Doc &&
          (ancestor.isFacs() || ancestor.isNeumeLines())) {
        final double rotate = getDrawingRotate();
        final Zone? resolved = zone;
        if (resolved == null ||
            resolved.ulx == null ||
            resolved.uly == null ||
            resolved.lrx == null ||
            resolved.lry == null) {
          return;
        }
        final int yDiff = resolved.lry! -
            resolved.uly! -
            ((resolved.lrx! - resolved.ulx!) *
                    math.tan(rotate.abs() * math.pi / 180.0))
                .toInt();
        drawingStaffSize = 100 *
            yDiff ~/
            (ancestor.getOptions().unit.value * 2 * (drawingLines - 1));
      }
    }
  }

  /// Mirrors `Staff::SetFromFacsimile` (staff.cpp:318).
  ///
  /// Approximations: facsimile zones are resolved during MEI import; this port
  /// does not yet wire `Doc.facsimile` zones into the layout, so the call is a
  /// no-op outside facsimile documents. Documented as `Note:` in
  /// `view_page.dart`.
  void setFromFacsimile(dynamic doc) {
    // No-op for non-facsimile documents; the transcription branch of this task
    // does not exercise facsimile zones.
  }

  /// Mirrors `SetOssia` / `IsOssia`.
  void setOssia(bool isOssia) => isOssiaFlag = isOssia;
  bool isOssia() => isOssiaFlag;

  /// Mirrors `Staff::GetNForOssia`: the staff `@n` shifted so an ossia
  /// staff never collides with a regular staff `@n` (see
  /// [attributesToInternal]). Verified against origin: `GetNForOssia` /
  /// `GetNFromOssia` have no direct C++ callers (only `Ossia` /
  /// `ScoreDef::AddOssias` use the offset arithmetic inline); the Dart
  /// callers are `ScoreDef.addOssias` and `Ossia.getOriginalStaffForOssia`
  /// (via [getNFromOssia]).
  int getNForOssia() {
    assert(!isOssia());
    return (n ?? 0) + ossiaNOffset;
  }

  /// Mirrors `Staff::GetNFromOssia`: the `oStaff/@n` shifted back to the
  /// original staff number (see [attributesToInternal]).
  int getNFromOssia() {
    assert(isOssia());
    return (n ?? 0) - ossiaNOffset;
  }

  /// Mirrors `Staff::AttributesToInternal`: shifts `@n` by [ossiaNOffset] for
  /// an ossia staff so it never collides with a regular staff `@n`.
  ///
  /// Deviation: `Staff::AttributesToExternal` (the inverse, used by MEI
  /// output) is not ported — MEI writing is a later phase.
  void attributesToInternal() {
    if (isOssia() && n != null) n = n! + ossiaNOffset;
  }

  /// Mirrors `Staff::IsNeume`.
  bool isNeume() => drawingNotationtype == Notationtype.neume;

  /// Mirrors `Staff::IsTablature` (staff.cpp:270) — `tabStaffLike` is
  /// excluded on purpose, as in the C++ (neither tablature nor CMN, a
  /// hybrid, always tested for explicitly).
  bool isTablature() =>
      drawingNotationtype == Notationtype.tab ||
      drawingNotationtype == Notationtype.tabGuitar ||
      drawingNotationtype == Notationtype.tabLuteItalian ||
      drawingNotationtype == Notationtype.tabLuteFrench ||
      drawingNotationtype == Notationtype.tabLuteGerman;

  /// Mirrors `Staff::IsTabLuteGerman` (staff.h:230).
  bool isTabLuteGerman() => drawingNotationtype == Notationtype.tabLuteGerman;

  /// Mirrors `Staff::IsTabLuteFrench` (staff.h:229).
  bool isTabLuteFrench() => drawingNotationtype == Notationtype.tabLuteFrench;

  /// Mirrors `Staff::IsTabLuteItalian` (staff.h:231).
  bool isTabLuteItalian() => drawingNotationtype == Notationtype.tabLuteItalian;

  /// Mirrors `Staff::IsTabWithStemsOutside` (staff.cpp:281).
  ///
  /// Deviation: the C++ reads `m_drawingStaffDef` directly; here it is the
  /// nullable [drawingStaffDef] field, so a missing staffDef answers false.
  bool isTabWithStemsOutside() {
    final Object? staffDef = drawingStaffDef;
    if (staffDef is! StaffDef) return false;
    return (!isTabGuitar() || !staffDef.hasType || staffDef.type != 'stems.within');
  }

  /// Mirrors `Staff::IsTabGuitar` (staff.h:228).
  bool isTabGuitar() => drawingNotationtype == Notationtype.tabGuitar;

  /// Mirrors `Staff::IsTabStaffLike` (staff.h:227).
  bool isTabStaffLike() => drawingNotationtype == Notationtype.tabStaffLike;

  /// Mirrors `Staff::GetDrawingStaffNotationSize` (staff.cpp:236).
  int getDrawingStaffNotationSize() {
    if (isTabLuteGerman()) {
      return (drawingStaffSize / germanTabStaffRatio).round();
    }
    return isTablature()
        ? (drawingStaffSize / tablatureStaffRatio).round()
        : drawingStaffSize;
  }

  /// Mirrors `Staff::DrawingIsVisible`: false when the staff itself is
  /// hidden, or when the *current system's* scoreDef (looked up fresh, not
  /// through [drawingStaffDef]) marks its staffDef `OPTIMIZATION_HIDDEN`
  /// (set by `ScoreDefOptimizeFunctor`).
  bool drawingIsVisible() {
    if (isHidden) return false;

    final System system = getFirstAncestor(ClassId.system) as System;
    final StaffDef? staffDef = system.drawingScoreDef?.getStaffDef(n ?? 0);
    return staffDef?.getDrawingVisibility() != VisibilityOptimization.hidden;
  }

  /// Mirrors `Staff::CalcPitchPosYRel` (staff.cpp:288).
  int calcPitchPosYRel(dynamic doc, int loc) {
    final int staffLocOffset = (drawingLines - 1) * 2;
    return (loc - staffLocOffset) *
        (doc.getDrawingUnit(drawingStaffSize) as int);
  }

  /// Mirrors `Staff::GetLedgerLinesAbove` / `Below` / `AboveCue` / `BelowCue`.
  List<LedgerLine> getLedgerLinesAbove() => ledgerLinesAbove;
  List<LedgerLine> getLedgerLinesBelow() => ledgerLinesBelow;
  List<LedgerLine> getLedgerLinesAboveCue() => ledgerLinesAboveCue;
  List<LedgerLine> getLedgerLinesBelowCue() => ledgerLinesBelowCue;

  /// Mirrors `Staff::AddLedgerLineAbove` / `AddLedgerLineBelow`.
  void addLedgerLineAbove(int count, int left, int right, int extension,
      bool cueSize, Object? event) {
    _addLedgerLines(cueSize ? ledgerLinesAboveCue : ledgerLinesAbove, count,
        left, right, extension, event);
  }

  void addLedgerLineBelow(int count, int left, int right, int extension,
      bool cueSize, Object? event) {
    _addLedgerLines(cueSize ? ledgerLinesBelowCue : ledgerLinesBelow, count,
        left, right, extension, event);
  }

  /// Mirrors `Staff::AddLedgerLines`.
  void _addLedgerLines(List<LedgerLine> lines, int count, int left, int right,
      int extension, Object? event) {
    while (lines.length < count) {
      lines.add(LedgerLine());
    }
    for (int i = 0; i < count; i++) {
      lines[i].addDash(left, right, extension, event);
    }
  }

  /// Mirrors `Staff::GetOssiaDrawingShift` (staff.cpp:330).
  int getOssiaDrawingShift(Measure measure, dynamic doc) {
    final Ossia? ossia = getFirstAncestor(ClassId.ossia) as Ossia?;
    final Layer? layer = findDescendantByType(ClassId.layer) as Layer?;
    if (ossia == null && layer == null) return 0;
    if (layer != null && layer.drawOssiaStaffDef) {
      int shift = ossia!.getScoreDefShift();
      shift -= (1.5 * doc.getDrawingUnit(drawingStaffSize)).toInt();
      return shift;
    } else if ((ossia != null && ossia.drawScoreDef()) ||
        (ossia != null && !ossia.isFirst())) {
      return 0;
    }
    int shift = measure.getLeftBarLineLeft();
    if (measure.getLeftBarLine().form == Barrendition.none) {
      shift -= (doc.getDrawingBarLineWidth(100) as int) ~/ 2;
    }
    return shift;
  }

  /// Clear the ledger lines (mirrors `Staff::ClearLedgerLines`).
  void clearLedgerLines() {
    ledgerLinesAbove.clear();
    ledgerLinesBelow.clear();
    ledgerLinesAboveCue.clear();
    ledgerLinesBelowCue.clear();
  }

  @override
  ClassId get classId => ClassId.staff;

  /// Mirrors `Staff::GetClassName`: an ossia staff reports as `oStaff` (used
  /// by the `probe::Path` / `cppPath` structural key, among others).
  @override
  String get className => isOssia() ? 'oStaff' : 'staff';

  @override
  Object clone() {
    final copy = Staff();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void reset() {
    super.reset();
    drawingN = 0;
    isOssiaFlag = false;
    // Mirrors Staff::Reset.
    drawingFacsY = meiUnset;
    drawingStaffSize = 100;
    drawingLines = 5;
    drawingNotationtype = null;
    drawingTuning = null;
    clearLedgerLines();
    staffAlignment = null;
    timeSpanningElements.clear();
    drawingStaffDef = null;
    drawingRotation = 0.0;
    n = null;
    type = null;
    visible = null;
  }

  @override
  bool isSupportedChild(ClassId classId) {
    if (classId == ClassId.layer) return true;
    if (Object.isEditorialElementId(classId)) return true;
    return false;
  }
}

/// Mirrors `vrv::Layer`.
class Layer extends Object
    with
        DrawingListInterface,
        ObjectListInterface,
        AttCue,
        AttNInteger,
        AttTyped,
        AttVisibility {
  Layer() : super(ClassId.layer) {
    reset();
  }

  /// The drawing stem direction of the layer (multi-layer / cross-staff
  /// situations; mirrors `m_drawingStemDir`).
  Stemdirection drawingStemDir = Stemdirection.none;

  /// Cross-staff flags (mirrors `m_crossStaffFromAbove` /
  /// `m_crossStaffFromBelow`).
  bool crossStaffFromAbove = false;
  bool crossStaffFromBelow = false;

  /// Whether the ossia staffDef (clef / keySig) must be drawn for this layer
  /// (mirrors `m_drawOssiaStaffDef`; set by `ScoreDefSetOssiaFunctor`).
  bool drawOssiaStaffDef = false;

  /// The scoreDef drawing values attached to the layer (owned; mirrors
  /// `m_staffDefClef` …).
  Clef? staffDefClef;
  KeySig? staffDefKeySig;
  Mensur? staffDefMensur;
  MeterSig? staffDefMeterSig;
  MeterSigGrp? staffDefMeterSigGrp;

  /// The cautionary scoreDef drawing values (owned; mirrors
  /// `m_cautionStaffDefClef` …).
  Clef? cautionStaffDefClef;
  KeySig? cautionStaffDefKeySig;
  Mensur? cautionStaffDefMensur;
  MeterSig? cautionStaffDefMeterSig;

  //----------------//
  // Drawing staffDef values (mirrors layer.cpp)
  //----------------//

  /// Mirrors the trivial `Get*` accessors of `layer.h:188-197` and
  /// `HasStaffDef` (layer.h:199-202).
  Clef? getStaffDefClef() => staffDefClef;
  KeySig? getStaffDefKeySig() => staffDefKeySig;
  Mensur? getStaffDefMensur() => staffDefMensur;
  MeterSig? getStaffDefMeterSig() => staffDefMeterSig;
  MeterSigGrp? getStaffDefMeterSigGrp() => staffDefMeterSigGrp;
  bool hasStaffDef() => hasStaffDefObjects;

  /// Mirrors the trivial `GetCaution*` accessors of `layer.h:217-224` and
  /// `HasCautionStaffDef` (layer.h:226-230).
  Clef? getCautionStaffDefClef() => cautionStaffDefClef;
  KeySig? getCautionStaffDefKeySig() => cautionStaffDefKeySig;
  Mensur? getCautionStaffDefMensur() => cautionStaffDefMensur;
  MeterSig? getCautionStaffDefMeterSig() => cautionStaffDefMeterSig;
  bool hasCautionStaffDef() =>
      cautionStaffDefClef != null ||
      cautionStaffDefKeySig != null ||
      cautionStaffDefMensur != null ||
      cautionStaffDefMeterSig != null;

  /// Delete the current drawing staffDef objects (mirrors
  /// `Layer::ResetStaffDefObjects`).
  void resetStaffDefObjects() {
    staffDefClef = null;
    staffDefKeySig = null;
    staffDefMensur = null;
    staffDefMeterSig = null;
    staffDefMeterSigGrp = null;
    cautionStaffDefClef = null;
    cautionStaffDefKeySig = null;
    cautionStaffDefMensur = null;
    cautionStaffDefMeterSig = null;
    drawOssiaStaffDef = false;
  }

  /// Return true when the layer holds any drawing staffDef object (mirrors
  /// `HasStaffDefDrawClef` etc. combined check).
  bool get hasStaffDefObjects =>
      staffDefClef != null ||
      staffDefKeySig != null ||
      staffDefMensur != null ||
      staffDefMeterSig != null ||
      staffDefMeterSigGrp != null;

  /// Copy the current drawing values of [currentStaffDef] into the layer
  /// objects to draw at this position (mirrors
  /// `Layer::SetDrawingStaffDefValues`).
  void setDrawingStaffDefValues(StaffDef? currentStaffDef) {
    if (currentStaffDef == null) {
      logDebug('staffDef not found');
      return;
    }

    // Remove any previous value in the Layer.
    resetStaffDefObjects();

    if (currentStaffDef.drawClef()) {
      final Clef copy =
          ScoreDefElement.cloneOf<Clef>(currentStaffDef.getCurrentClef());
      copy.setParent(this);
      staffDefClef = copy;
    }
    if (currentStaffDef.drawKeySig()) {
      final KeySig copy =
          ScoreDefElement.cloneOf<KeySig>(currentStaffDef.getCurrentKeySig());
      copy.setParent(this);
      staffDefKeySig = copy;
    }
    if (currentStaffDef.drawMensur()) {
      final Mensur copy =
          ScoreDefElement.cloneOf<Mensur>(currentStaffDef.getCurrentMensur());
      copy.setParent(this);
      staffDefMensur = copy;
    }
    if (currentStaffDef.drawMeterSigGrp()) {
      final MeterSigGrp copy = ScoreDefElement.cloneOf<MeterSigGrp>(
          currentStaffDef.getCurrentMeterSigGrp());
      copy.setParent(this);
      staffDefMeterSigGrp = copy;
    } else if (currentStaffDef.drawMeterSig()) {
      final MeterSig copy = ScoreDefElement.cloneOf<MeterSig>(
          currentStaffDef.getCurrentMeterSig());
      copy.setParent(this);
      staffDefMeterSig = copy;
    }

    // Don't draw on the next one.
    currentStaffDef.setDrawClef(false);
    currentStaffDef.setDrawKeySig(false);
    currentStaffDef.setDrawMensur(false);
    currentStaffDef.setDrawMeterSig(false);
    currentStaffDef.setDrawMeterSigGrp(false);
  }

  /// Check whether the layer holds drawing staffDef values and transfer the
  /// draw flags to [staffDef] (mirrors `Layer::GetDrawingStaffDefValues`).
  bool getDrawingStaffDefValues(StaffDef staffDef) {
    bool hasValue = false;
    if (staffDefClef != null) {
      staffDef.setDrawClef(true);
      hasValue = true;
    }
    if (staffDefKeySig != null) {
      staffDef.setDrawKeySig(true);
      hasValue = true;
    }
    if (staffDefMensur != null) {
      staffDef.setDrawMensur(true);
      hasValue = true;
    }
    if (staffDefMeterSig != null) {
      staffDef.setDrawMeterSig(true);
      hasValue = true;
    }
    if (staffDefMeterSigGrp != null) {
      staffDef.setDrawMeterSigGrp(true);
      hasValue = true;
    }
    return hasValue;
  }

  /// Copy the cautionary drawing values of [currentStaffDef] (mirrors
  /// `Layer::SetDrawingCautionValues`).
  void setDrawingCautionValues(StaffDef? currentStaffDef) {
    if (currentStaffDef == null) {
      logDebug('staffDef not found');
      return;
    }

    if (currentStaffDef.drawClef()) {
      final Clef copy =
          ScoreDefElement.cloneOf<Clef>(currentStaffDef.getCurrentClef());
      copy.setParent(this);
      cautionStaffDefClef = copy;
    }
    // Special case: the keySig keeps a reference to the drawing clef.
    if (currentStaffDef.drawKeySig()) {
      final KeySig copy =
          ScoreDefElement.cloneOf<KeySig>(currentStaffDef.getCurrentKeySig());
      copy.setDrawingClef(currentStaffDef.getCurrentClef());
      copy.setParent(this);
      cautionStaffDefKeySig = copy;
    }
    if (currentStaffDef.drawMensur()) {
      final Mensur copy =
          ScoreDefElement.cloneOf<Mensur>(currentStaffDef.getCurrentMensur());
      copy.setParent(this);
      cautionStaffDefMensur = copy;
    }
    if (currentStaffDef.drawMeterSig()) {
      final MeterSig copy = ScoreDefElement.cloneOf<MeterSig>(
          currentStaffDef.getCurrentMeterSig());
      copy.setParent(this);
      cautionStaffDefMeterSig = copy;
    }

    // Don't draw on the next one.
    currentStaffDef.setDrawClef(false);
    currentStaffDef.setDrawKeySig(false);
    currentStaffDef.setDrawMensur(false);
    currentStaffDef.setDrawMeterSig(false);
  }

  /// Mirrors `SetCrossStaffFromAbove` / `HasCrossStaffFromAbove`.
  void setCrossStaffFromAbove(bool crossStaff) =>
      crossStaffFromAbove = crossStaff;
  bool hasCrossStaffFromAbove() => crossStaffFromAbove;

  /// Mirrors `SetCrossStaffFromBelow` / `HasCrossStaffFromBelow`.
  void setCrossStaffFromBelow(bool crossStaff) =>
      crossStaffFromBelow = crossStaff;
  bool hasCrossStaffFromBelow() => crossStaffFromBelow;

  /// Mirrors `SetDrawingStemDir` / `GetDrawingStemDir()` (the element-aware
  /// overload is provided by the layout functors for now).
  void setDrawingStemDir(Stemdirection stemDirection) =>
      drawingStemDir = stemDirection;
  Stemdirection getDrawingStemDir() => drawingStemDir;

  /// Mirrors `Layer::GetDrawingStemDir(const LayerElement *element)`
  /// (layer.cpp:301) — the element-aware overload used by CalcArtic.
  Stemdirection getDrawingStemDirFor(LayerElement element) {
    if (getLayerCountForTimeSpanOf(element) < 2) {
      return Stemdirection.none;
    } else {
      if (crossStaffFromBelow) {
        return element.crossStaff != null
            ? Stemdirection.down
            : Stemdirection.up;
      } else if (crossStaffFromAbove) {
        return element.crossStaff != null
            ? Stemdirection.up
            : Stemdirection.down;
      } else {
        return drawingStemDir;
      }
    }
  }

  /// Mirrors `Layer::GetDrawingStemDir(const ArrayOfBeamElementCoords *)`
  /// (layer.cpp:321) — the beam-coords overload used by
  /// `BeamSegment::CalcBeamPlace`.
  Stemdirection getDrawingStemDirForBeamCoords(List<BeamElementCoord> coords) {
    // The C++ asserts a non-empty array (layer.cpp:323).
    if (coords.isEmpty) return drawingStemDir;

    final LayerElement? first =
        coords.first.element is LayerElement ? coords.first.element as LayerElement : null;
    final LayerElement? last =
        coords.last.element is LayerElement ? coords.last.element as LayerElement : null;
    if (first == null || last == null) return drawingStemDir;

    final Measure? measure = first.getFirstAncestor(ClassId.measure) as Measure?;
    // The C++ asserts the measure (layer.cpp:334).
    if (measure == null) return drawingStemDir;

    final Alignment? alignmentFirst = first.getAlignment();
    final Alignment? alignmentLast = last.getAlignment();
    // Alignments only exist after AlignHorizontally; degrade to
    // STEMDIRECTION_NONE (as GetLayersNForTimeSpanOf does) when this runs
    // before the horizontal alignment.
    if (alignmentFirst == null || alignmentLast == null) {
      return Stemdirection.none;
    }

    // We are ignoring cross-staff situations here because this should not be
    // called if we have one (layer.cpp:341-342).
    final Staff? staff = first.getFirstAncestor(ClassId.staff) as Staff?;

    final Fraction time = alignmentFirst.getTime();
    Fraction duration;
    // For the sake of counting number of layers consider only current
    // measure. If first and last elements' layers are different, take only
    // time within current measure to run GetLayerCountInTimeSpan
    // (layer.cpp:348-354).
    final Measure? lastMeasure = last.getFirstAncestor(ClassId.measure) as Measure?;
    if (lastMeasure == measure) {
      duration = alignmentLast.getTime() - time + last.getAlignmentDuration();
    } else {
      duration =
          measure.measureAligner.getRightAlignment()!.getTime() - time;
    }

    if (getLayerCountInTimeSpan(time, duration, measure, staff?.n ?? meiUnset) <
        2) {
      return Stemdirection.none;
    } else {
      return drawingStemDir;
    }
  }

  /// Mirrors `Layer::GetCurrentMensur` (layer.cpp:516).
  Mensur? getCurrentMensur() {
    final staff = getFirstAncestor(ClassId.staff) as Staff?;
    final StaffDef? staffDef =
        staff?.drawingStaffDef is StaffDef ? staff!.drawingStaffDef as StaffDef : null;
    return staffDef?.getCurrentMensur();
  }

  /// Mirrors `Layer::GetCurrentMeterSig` (layer.cpp:528).
  MeterSig? getCurrentMeterSig() {
    final staff = getFirstAncestor(ClassId.staff) as Staff?;
    final StaffDef? staffDef =
        staff?.drawingStaffDef is StaffDef ? staff!.drawingStaffDef as StaffDef : null;
    return staffDef?.getCurrentMeterSig();
  }

  /// Mirrors `Layer::GetLayersNInTimeSpan` (layer.cpp:384).
  Set<int> getLayersNInTimeSpan(
      Fraction time, Fraction duration, Measure measure, int staff) {
    final layersInTimeSpan = LayersInTimeSpanFunctor(
        getCurrentMeterSig(), getCurrentMensur());
    layersInTimeSpan.setEvent(time, duration);

    final filters = Filters();
    filters.add(AttNIntegerComparison(ClassId.alignmentReference, staff));
    layersInTimeSpan.setFilters(filters);

    measure.measureAligner.process(layersInTimeSpan);

    return layersInTimeSpan.layers;
  }

  /// Mirrors `Layer::GetLayersNForTimeSpanOf` (layer.cpp:364).
  Set<int> getLayersNForTimeSpanOf(LayerElement element) {
    final measure = getFirstAncestor(ClassId.measure) as Measure;

    final Alignment? alignment = element.getAlignment();
    // The C++ asserts the alignment (layer.cpp:371) because this only runs
    // after AlignHorizontally. The Dart port also runs the Calc* chain at
    // prepareData time (documented deviation), before any alignment exists;
    // degrade to "no layers in span" so callers fall back to the note's own
    // stem direction.
    if (alignment == null) return <int>{};

    final staff = element.getAncestorStaffResolveCrossStaff();

    return getLayersNInTimeSpan(alignment.getTime(),
        element.getAlignmentDuration(), measure, staff?.n ?? meiUnset);
  }

  /// Mirrors `Layer::GetLayerCountForTimeSpanOf` (layer.cpp:379).
  int getLayerCountForTimeSpanOf(LayerElement element) =>
      getLayersNForTimeSpanOf(element).length;

  /// Mirrors `Layer::GetLayerCountInTimeSpan` (layer.h:135) — the count of
  /// layers spanning [time] + [duration] in [measure].
  int getLayerCountInTimeSpan(
          Fraction time, Fraction duration, Measure measure, int staff) =>
      getLayersNInTimeSpan(time, duration, measure, staff).length;

  /// Mirrors `Layer::GetLayerElementsInTimeSpan` (layer.cpp:466) — the layer
  /// elements spanning [time] + [duration] in [measure], restricted to this
  /// layer (or, with [excludeCurrent], to every layer but this one).
  List<Object> getLayerElementsInTimeSpan(
      Fraction time, Fraction duration, Measure measure, int staff,
      {bool excludeCurrent = false}) {
    final layerElementsInTimeSpan =
        LayerElementsInTimeSpanFunctor(getCurrentMeterSig(), getCurrentMensur(), this);
    layerElementsInTimeSpan.setEvent(time, duration);
    if (excludeCurrent) layerElementsInTimeSpan.considerAllLayersButCurrent();

    final filters = Filters();
    filters.add(AttNIntegerComparison(ClassId.alignmentReference, staff));
    layerElementsInTimeSpan.setFilters(filters);

    measure.measureAligner.process(layerElementsInTimeSpan);

    return layerElementsInTimeSpan.elements;
  }

  /// Mirrors `Layer::GetLayerElementsForTimeSpanOf` (layer.cpp:417) — the
  /// layer elements occurring in the same time span as [element], restricted
  /// to this layer (or, with [excludeCurrent], to every layer but this one).
  ///
  /// Deviation: when [element] has no alignment and is not a `Beam` (the two
  /// cases the C++ handles), an empty list is returned instead of asserting —
  /// mirrors the same degradation already documented for
  /// `adjust_beams.dart`'s `_layerElementsForTimeSpanOf` stub.
  List<Object> getLayerElementsForTimeSpanOf(LayerElement element,
      {bool excludeCurrent = false}) {
    final measure = getFirstAncestor(ClassId.measure) as Measure;

    Fraction time = Fraction(0);
    Fraction duration = Fraction(0);
    final Alignment? alignment = element.getAlignment();
    if (alignment != null) {
      time = alignment.getTime();
      duration = element.getAlignmentDuration();
    } else if (element is Beam) {
      final LayerElement? first = element.getListFront() as LayerElement?;
      final LayerElement? last = element.getListBack() as LayerElement?;
      if (first == null || last == null) return const [];
      final Alignment? firstAlignment = first.getAlignment();
      final Alignment? lastAlignment = last.getAlignment();
      if (firstAlignment == null || lastAlignment == null) return const [];
      time = firstAlignment.getTime();
      final Fraction lastTime = lastAlignment.getTime();
      duration = lastTime - time + last.getAlignmentDuration();
    } else {
      return const [];
    }

    final staff = element.getAncestorStaffResolveCrossStaff();

    return getLayerElementsInTimeSpan(
        time, duration, measure, staff?.n ?? meiUnset,
        excludeCurrent: excludeCurrent);
  }

  /// Mirrors `Layer::GetAtPos` (layer.cpp:190) — the last LayerElement whose
  /// drawing X is ≤ [x]. Editorial wrappers are skipped; `null` when the first
  /// element is already beyond [x] or the layer is empty.
  ///
  /// Note: the C++ walks the internal `GetList` structure (which
  /// flattens editorial elements like `GetClef` does); this port walks the
  /// direct children and their LayerElement descendants.
  LayerElement? getAtPos(int x) {
    final List<LayerElement> flat = _flattenLayerElements();
    if (flat.isEmpty) return null;
    if (flat.first.getDrawingX() > x) return null;
    LayerElement? element = flat.first;
    for (final LayerElement next in flat.skip(1)) {
      if (next.getDrawingX() > x) return element;
      element = next;
    }
    return element;
  }

  /// Mirrors `Layer::GetPrevious` (layer.cpp:177) — the LayerElement
  /// immediately before [element] in document order, or `null`.
  LayerElement? getPrevious(LayerElement? element) {
    if (element == null) return null;
    final List<LayerElement> flat = _flattenLayerElements();
    final int idx = flat.indexOf(element);
    if (idx <= 0) return null;
    return flat[idx - 1];
  }

  /// Flatten the layer's LayerElements in document order, descending into
  /// editorial elements (mirrors the `IsLayerElement` / `IsEditorialElement`
  /// branches of `Layer::GetAtPos` / `GetClef`).
  List<LayerElement> _flattenLayerElements() {
    final List<LayerElement> out = [];
    for (final Object child in children) {
      if (child is LayerElement) {
        out.add(child);
      } else if (child.isEditorialElement) {
        out.addAll(child
            .findAllDescendantsByType(ClassId.layerElement)
            .whereType<LayerElement>());
        // Also include direct editorial-contained LayerElements that are not
        // caught via findAll? Already covered.
      }
    }
    return out;
  }

  /// Mirrors `Layer::GetClef` (layer.cpp:234) — the clef active at [test].
  ///
  /// Deviation fixed 2026-09-02: this used to walk a hand-rolled
  /// `_flattenLayerElements()` list that only descended one level into
  /// container `LayerElement`s (`Beam`, `Tuplet`, `Chord`, …) — a clef
  /// nested inside one of those (e.g. a mid-tuplet clef change) was never
  /// added to the list at all, so the backward search silently skipped it
  /// and fell through to the layer's *stale* current clef. The C++ instead
  /// walks `ObjectListInterface::m_list`, built by `FillFlatList` as a full
  /// recursive pre-order flatten of *every* descendant `Object` (Layer's
  /// `FilterList` override is a no-op) — so a clef at any nesting depth is
  /// found. `Layer` now mixes in [ObjectListInterface] and this uses
  /// [resetList]/[getListIndex]/[getListFirstBackward] directly, matching
  /// the C++ list mechanics (`getListFirstBackward` excludes `test` itself,
  /// mirroring the C++ reverse-iterator construction from `test`'s forward
  /// position).
  Clef? getClef(LayerElement? test) {
    if (test == null) return getCurrentClef();

    Object? testObject = test;

    // Make sure the list is up to date.
    resetList();
    if (!test.isClass(ClassId.clef)) {
      testObject = getListFirstBackward(test, ClassId.clef);
    }

    if (testObject != null && testObject.isClass(ClassId.clef)) {
      return testObject as Clef;
    }
    // `GetClefFacs` (facsimile-anchored clef lookup) is not ported — a
    // no-op for the non-facsimile majority of documents, matching the
    // pre-existing gap.
    return getCurrentClef();
  }

  /// Mirrors `Layer::GetCurrentClef` (layer.cpp:490) — the clef currently in
  /// effect for the ancestor staff's drawing staffDef.
  ///
  /// Deviation fixed 2026-08-31: this used to return [staffDefClef] (the
  /// *transient* clone created by [setDrawingStaffDefValues] only while the
  /// clef needs to be *redrawn*, and reset to `null` right after — mirrors
  /// `Layer::m_staffDefClef`, not `Layer::GetCurrentClef`). The C++ getter
  /// instead reads `staff->m_drawingStaffDef->GetCurrentClef()`, which stays
  /// valid across the whole staff regardless of whether a redraw is due this
  /// measure. The bug made every clef lookup for a `KeySig`/`Accid`/etc that
  /// falls back to `GetClef`/`GetCurrentClef` return `null` outside of a
  /// measure that also redraws the clef, so e.g. a keySig or accidental at a
  /// mid-piece scoreDef change (clef not redrawn there) silently skipped
  /// drawing entirely instead of using the staff's ongoing clef.
  Clef? getCurrentClef() {
    final staff = getFirstAncestor(ClassId.staff) as Staff?;
    final StaffDef? staffDef =
        staff?.drawingStaffDef is StaffDef ? staff!.drawingStaffDef as StaffDef : null;
    return staffDef?.getCurrentClef();
  }

  /// Mirrors `Layer::GetClefLocOffset` (layer.cpp:280).
  int getClefLocOffset(LayerElement? test) {
    final Clef? clef = getClef(test);
    return clef?.getClefLocOffset() ?? 0;
  }

  @override
  ClassId get classId => ClassId.layer;

  @override
  String get className => 'layer';

  @override
  Object clone() {
    final copy = Layer();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void reset() {
    super.reset();
    // Mirrors `Layer::Reset` calling `DrawingListInterface::Reset`
    // (layer.cpp:78 / drawinginterface.cpp:39).
    resetDrawingList();
    cue = null;
    n = null;
    type = null;
    visible = null;
    drawingStemDir = Stemdirection.none;
    crossStaffFromAbove = false;
    crossStaffFromBelow = false;
    resetStaffDefObjects();
  }

  @override
  bool isSupportedChild(ClassId classId) {
    if (Object.isLayerElementId(classId)) return true;
    if (Object.isEditorialElementId(classId)) return true;
    return false;
  }
}

/// Mirrors `vrv::Section`.
class Section extends SystemElement
    with SystemMilestoneInterface, AttNNumberLike, AttSectionVis {
  Section() : super(ClassId.section) {
    reset();
  }

  @override
  ClassId get classId => ClassId.section;

  @override
  String get className => 'section';

  @override
  Object clone() {
    final copy = Section();
    copy.copyFrom(this);
    return copy;
  }

  @override
  bool isSupportedChild(ClassId classId) {
    const supported = {ClassId.div, ClassId.measure, ClassId.scoreDef};
    if (supported.contains(classId)) return true;
    if (Object.isSystemElementId(classId)) return true;
    if (Object.isEditorialElementId(classId)) return true;
    return false;
  }
}

/// Mirrors `vrv::Score`.
class Score extends PageElement
    with PageMilestoneInterface, AttLabelled, AttNNumberLike {
  Score() : super(ClassId.score) {
    reset();
  }

  /// The scoreDef of the score (mirrors `m_scoreDef`); not a child of the
  /// tree but owned by the score. Set by the IO when reading `<score>`.
  Object? scoreDef;

  /// The (editorial) subtree holding the selected scoreDef (mirrors
  /// `m_scoreDefSubtree`). Owned by the score as a child.
  Object? scoreDefSubtree;

  /// Heights of the running elements for the first and following pages
  /// (mirrors `m_drawingPgHeadHeight` etc., score.h:108-111).
  int drawingPgHeadHeight = 0;
  int drawingPgFootHeight = 0;
  int drawingPgHead2Height = 0;
  int drawingPgFoot2Height = 0;

  /// Return the scoreDef (mirrors `Score::GetScoreDef`).
  Object? getScoreDef() => scoreDef;

  /// Mirrors `Score::SetScoreDefSubtree`: stores the (editorial) subtree
  /// holding the selected scoreDef. The subtree is owned by the Score via
  /// [scoreDefSubtree] (not a tree child, mirroring the C++ owned pointer).
  void setScoreDefSubtree(Object? subtree, Object? scoreScoreDef) {
    assert(scoreDef == null);
    assert(scoreDefSubtree == null);
    scoreDefSubtree = subtree;
    scoreDef = scoreScoreDef;
  }

  /// Whether the score needs the condensed-layout optimization (mirrors
  /// `Score::ScoreDefNeedsOptimization`).
  bool scoreDefNeedsOptimization(Condense optionCondense) {
    final ScoreDef scoreDef = getScoreDef() as ScoreDef;

    if (optionCondense == Condense.none) return false;
    // Optimize scores only if encoded.
    bool optimize = scoreDef.hasOptimize && scoreDef.optimize == true;
    // If nothing specified, do not if there is only one grpSym.
    if (optionCondense == Condense.auto && !scoreDef.hasOptimize) {
      final List<Object> symbols =
          scoreDef.findAllDescendantsByType(ClassId.grpSym);
      optimize = symbols.length > 1;
    }

    return optimize;
  }

  /// Calculate the height of `pgHead` / `pgHead2` and `pgFoot` / `pgFoot2`
  /// (mirrors `Score::CalcRunningElementHeight`, score.cpp:104).
  ///
  /// Requires the [Doc] to have an empty [Pages] when called (the method
  /// creates two temporary pages, lays them out vertically and measures the
  /// running elements). The pages are deleted upon exit (score.cpp:138-139).
  void calcRunningElementHeight(Doc doc) {
    assert(doc.getPages() != null);
    final Pages pages = doc.getPages()!;
    assert(pages.childCount == 0);

    final Page page1 = Page();
    page1.score = this;
    page1.scoreEnd = this;
    pages.addChild(page1);
    doc.setDrawingPage(0);
    page1.layOutVertically();

    final Object? page1Header = page1.getHeader();
    final Object? page1Footer = page1.getFooter();

    drawingPgHeadHeight = page1Header != null
        ? (page1Header as RunningElement).getTotalHeight(doc)
        : 0;
    drawingPgFootHeight = page1Footer != null
        ? (page1Footer as RunningElement).getTotalHeight(doc)
        : 0;

    final Page page2 = Page();
    page2.score = this;
    page2.scoreEnd = this;
    pages.addChild(page2);
    doc.setDrawingPage(1);
    page2.layOutVertically();

    final Object? page2Header = page2.getHeader();
    final Object? page2Footer = page2.getFooter();

    drawingPgHead2Height = page2Header != null
        ? (page2Header as RunningElement).getTotalHeight(doc)
        : 0;
    drawingPgFoot2Height = page2Footer != null
        ? (page2Footer as RunningElement).getTotalHeight(doc)
        : 0;

    pages.deleteChild(page1);
    pages.deleteChild(page2);

    doc.resetDataPage();
  }

  @override
  ClassId get classId => ClassId.score;

  @override
  String get className => 'score';

  @override
  Object clone() {
    final copy = Score();
    copy.copyFrom(this);
    return copy;
  }

  @override
  bool isSupportedChild(ClassId classId) {
    const supported = {
      ClassId.ending,
      ClassId.pb,
      ClassId.scoreDef,
      ClassId.sb,
      ClassId.section,
    };
    if (supported.contains(classId)) return true;
    if (Object.isEditorialElementId(classId)) return true;
    return false;
  }
}

/// Mirrors `vrv::Mdiv`.
class Mdiv extends PageElement
    with
        VisibilityDrawingInterface,
        PageMilestoneInterface,
        AttLabelled,
        AttNNumberLike {
  Mdiv() : super(ClassId.mdiv) {
    reset();
  }

  /// Mirrors `Mdiv::Reset` (mdiv.cpp:42): unlike the generic
  /// `VisibilityDrawingInterface` default (Visible), an `<mdiv>` defaults to
  /// Hidden — only the selected mdiv (and its mdiv ancestors) are made
  /// visible via [makeVisible] during MEI reading (`mei_input.dart`'s
  /// `readMdiv`/`readMdivChildren`, mirroring `MEIInput::ReadMdiv`). Every
  /// functor's `visibleOnly` traversal (default `true`, `functor.dart`)
  /// then skips a hidden mdiv's whole subtree (`Object.skipChildren`,
  /// mirroring `Object::SkipChildren`), so a non-selected `<mdiv>`'s
  /// `<score>` never reaches layout or drawing.
  @override
  void reset() {
    super.reset();
    setVisibility(VisibilityType.hidden);
  }

  /// Mirrors `Mdiv::MakeVisible`: make this mdiv and its mdiv ancestors
  /// visible.
  void makeVisible() {
    setVisibility(VisibilityType.visible);
    final Object? parent = this.parent;
    if (parent != null && parent.classId == ClassId.mdiv) {
      (parent as Mdiv).makeVisible();
    }
  }

  @override
  ClassId get classId => ClassId.mdiv;

  @override
  String get className => 'mdiv';

  @override
  Object clone() {
    final copy = Mdiv();
    copy.copyFrom(this);
    return copy;
  }

  @override
  bool isSupportedChild(ClassId classId) {
    const supported = {ClassId.mdiv, ClassId.score};
    if (supported.contains(classId)) return true;
    logDebug('Adding unsupported child $classId to $className');
    return false;
  }
}

// ---------------------------------------------------------------------------
// Layer elements
// ---------------------------------------------------------------------------

/// Mirrors `vrv::Note` (subset of atts; the drawing interfaces arrive later).
class Note extends LayerElement
    with
        AttAltSym,
        AttAugmentDots,
        AttBeamSecondary,
        AttDurationGes,
        AttDurationLog,
        AttDurationQuality,
        AttDurationRatio,
        AttFermataPresent,
        AttStaffIdent,
        DurationInterface,
        AttNoteGes,
        AttOctave,
        AttPitch,
        AttPitchGes,
        PitchInterface,
        AttStaffLoc,
        AttStaffLocPitched,
        PositionInterface,
        AttVisualOffsetHo,
        AttVisualOffsetVo,
        OffsetInterface,
        StemmedDrawingInterface,
        AttArticulation,
        AttArticulationGes,
        AttColor,
        AttColoration,
        AttCue,
        AttExtSymAuth,
        AttExtSymNames,
        AttGraced,
        AttHarmonicFunction,
        AttMidiVelocity,
        AttNoteHeads,
        AttNoteVisMensural,
        AttStems,
        AttStemsCmn,
        AttStringtab,
        AttTiePresent,
        AttVisibility {
  Note() : super(ClassId.note) {
    reset();
  }

  /// The flipped notehead flag (set by the chord noteheads calculation;
  /// mirrors `m_flippedNotehead`).
  bool flippedNotehead = false;

  /// The other note sharing the same stem (mirrors `m_stemSameas`).
  Object? stemSameasNote;

  /// The role of this note in a shared-stem pair (mirrors
  /// `m_stemSameasRole`).
  StemSameasDrawingRole stemSameasRole = StemSameasDrawingRole.none;

  /// The chord note group this note belongs to, if any (mirrors
  /// `m_noteGroup` in note.h:333, an element of the chord's `m_noteGroups`).
  List<Note>? noteGroup;

  /// The 1-indexed position of this note in its group (mirrors
  /// `m_noteGroupPosition` in note.h; 0 when groupless).
  int noteGroupPosition = 0;

  /// Mirrors `Note::SetNoteGroup` (note.cpp:463).
  void setNoteGroup(List<Note>? group, int position) {
    noteGroup = group;
    noteGroupPosition = position;
  }

  /// Mirrors `Note::GetNoteGroup` (note.h:175).
  List<Note>? getNoteGroup() => noteGroup;

  /// Mirrors `Note::IsNoteGroupExtreme` (note.cpp:242): true when this note
  /// is the first or the last element of its group.
  ///
  /// Deviation: the C++ dereferences `m_noteGroup` unconditionally (a
  /// groupless call is undefined behavior there); here a null group
  /// answers false.
  bool isNoteGroupExtreme() {
    final List<Note>? group = noteGroup;
    if (group == null || group.isEmpty) return false;
    if (identical(this, group.first)) return true;
    return identical(this, group.last);
  }

  @override
  ClassId get classId => ClassId.note;

  @override
  String get className => 'note';

  @override
  Object clone() {
    final copy = Note();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Note other) {
    if (identical(this, other)) return;

    // DurationInterface atts
    dots = other.dots;
    breaksec = other.breaksec;
    durGes = other.durGes;
    dotsGes = other.dotsGes;
    durMetrical = other.durMetrical;
    durPpq = other.durPpq;
    durReal = other.durReal;
    dur = other.dur;
    durQuality = other.durQuality;
    this.num = other.num;
    numbase = other.numbase;
    fermata = other.fermata;
    staff = other.staff == null ? null : [...other.staff!];
    durDefault = other.durDefault;

    // PitchInterface atts
    pnameGes = other.pnameGes;
    octGes = other.octGes;
    pname = other.pname;
    oct = other.oct;
    octDefault = other.octDefault;

    // PositionInterface atts
    loc = other.loc;
    oloc = other.oloc;
    ploc = other.ploc;
    drawingLoc = other.drawingLoc;

    // OffsetInterface atts
    ho = other.ho;
    vo = other.vo;

    super.copyFrom(other);
  }

  @override
  void reset() {
    super.reset();
    // Register the interfaces for `hasInterface` lookups.
    registerInterfaces([
      InterfaceId.altSym,
      InterfaceId.duration,
      InterfaceId.pitch,
      InterfaceId.position,
      InterfaceId.offset,
      InterfaceId.facsimile,
      InterfaceId.linking,
    ]);

    // Drawing state (mirrors Note::Reset).
    flippedNotehead = false;
    stemSameasNote = null;
    stemSameasRole = StemSameasDrawingRole.none;
    noteGroup = null;
    noteGroupPosition = 0;
    resetStemmedDrawingInterface();
  }

  /// Mirrors `HasStemSameasNote` / `GetStemSameasRole` /
  /// `SetStemSameasRole`.
  bool hasStemSameasNote() => stemSameasNote != null;

  /// Mirrors `Note::CalcNoteHeadShiftForSameasNote` (note.cpp:786): when the
  /// two `stem.sameas` notes are a step apart or closer (their noteheads
  /// would otherwise overlap), flags whichever one sits on the "wrong" side
  /// of [stemDir] so `View.drawNote` draws it with a flipped/offset
  /// notehead. The correction is a rendering-only flag — the note's own
  /// position (and its children's, including the shared stem) is left
  /// untouched.
  void calcNoteHeadShiftForSameasNote(Note stemSameas, Stemdirection stemDir) {
    if ((getDiatonicPitch() - stemSameas.getDiatonicPitch()).abs() > 1) return;

    Note noteToShift = this;
    if (stemDir == Stemdirection.up) {
      if (getDrawingY() < stemSameas.getDrawingY()) noteToShift = stemSameas;
    } else {
      if (getDrawingY() > stemSameas.getDrawingY()) noteToShift = stemSameas;
    }
    noteToShift.flippedNotehead = true;
  }

  @override
  bool get hasToBeAligned => true;

  @override
  bool isSupportedChild(ClassId classId) {
    const supported = {
      ClassId.accid,
      ClassId.artic,
      ClassId.dots,
      ClassId.plica,
      ClassId.stem,
      ClassId.syl,
      ClassId.verse,
    };
    if (supported.contains(classId)) return true;
    if (Object.isEditorialElementId(classId)) return true;
    return false;
  }

  @override
  bool addChild(Object child) {
    if (!isSupportedChild(child.classId) || !addChildAdditionalCheck(child)) {
      // Mirrors Note::AddChild error handling
      return false;
    }
    child.setParent(this);
    final List<Object> children = childrenForModification;
    if (child.classId == ClassId.dots || child.classId == ClassId.stem) {
      children.insert(0, child);
    } else {
      children.add(child);
    }
    modify();
    return true;
  }

  @override
  bool addChildAdditionalCheck(Object child) {
    // Mirrors Note::AddChildAdditionalCheck (warning only, return true)
    return super.addChildAdditionalCheck(child);
  }

  /// Return the parent chord if the note is a chord tone (null otherwise;
  /// mirrors `IsChordTone`).
  Object? isChordTone() => getFirstAncestor(ClassId.chord, maxChordDepth);

  /// Mirrors `Note::AlignDotsShift` (note.cpp:193): when the other note's
  /// dots carry a flag shift (flag / stem collision), copy it onto this
  /// note's own dots. Called from `LayerElement::CalcOptimalDotLocations`
  /// for unison notes (layerelement.cpp:953-959).
  void alignDotsShift(Note otherNote) {
    final Dots? dots = findDescendantByType(ClassId.dots, deepness: 1) as Dots?;
    final Dots? otherDots =
        otherNote.findDescendantByType(ClassId.dots, deepness: 1) as Dots?;
    if (dots == null || otherDots == null) return;
    if (otherDots.flagShift != 0) {
      dots.flagShift = otherDots.flagShift;
    }
  }

  @override
  bool isGraceNote() {
    if (getFirstAncestor(ClassId.graceGrp) != null) return true;
    final Object? chord = isChordTone();
    if (chord is Chord) {
      return chord.hasGrace;
    }
    return hasGrace;
  }

  /// Return the diatonic pitch of the note (mirrors `GetDiatonicPitch`).
  int getDiatonicPitch() {
    if (hasOct) {
      final int pitch = hasPname ? pname!.value - 1 : 0;
      return oct! * 7 + pitch;
    } else if (hasLoc) {
      // WARNING: Getting the correct clef loc offset does not work at an
      // early stage of the processing. It requires that the drawingStaffDef
      // be set on staff and that crossStaff/crossLayer are calculated.
      // However, in many cases we are only interested in a relative pitch
      // value. Then this is still fine.
      // TODO(layout): resolve clef-based loc offset once Layer/Staff hold
      // their drawingStaffDef (Phase 4).
      return loc ?? 0;
    }
    return 0;
  }

  /// Return the accidental child of the note, if any (mirrors
  /// `Note::GetDrawingAccid`).
  Accid? getDrawingAccid() => findDescendantByType(ClassId.accid) as Accid?;

  /// Mirrors `Note::GetStemUpSE` (note.cpp:494): the SE point of the
  /// notehead when the stem points up.
  Point getStemUpSE(dynamic doc, int staffSize, bool isCueSize) {
    int defaultYShift = doc.getDrawingUnit(staffSize) ~/ 4;
    if (isCueSize) defaultYShift = doc.getCueSize(defaultYShift);
    // x default is always set to the right for now
    final int defaultXShift =
        doc.getGlyphWidth(getNoteheadGlyph(getActualDur()), staffSize, isCueSize);
    final Point p = Point(defaultXShift, defaultYShift);

    final int code = getNoteheadGlyph(getDrawingDur());

    // This is never called for now because mensural notes do not have
    // stem/flag children (mirrors the C++ guard).
    if (isMensuralDur) {
      final int mensuralGlyph = getMensuralNoteheadGlyph();
      p.y = doc.getGlyphHeight(mensuralGlyph, staffSize, isCueSize) ~/ 2;
      p.x = doc.getGlyphWidth(mensuralGlyph, staffSize, isCueSize);
    }

    // The glyph table may be empty in headless runs (fonts not loaded); the
    // default point then mirrors the C++ defaults computed from the fallback
    // glyph metrics.
    final dynamic glyph = doc.resources.getGlyphByCode(code);
    if (glyph != null && glyph.hasAnchor(SMuFLGlyphAnchor.stemUpSE)) {
      return doc.convertFontPoint(
          glyph, glyph.getAnchor(SMuFLGlyphAnchor.stemUpSE), staffSize, isCueSize);
    }
    return p;
  }

  /// Mirrors `Note::GetStemDownNW` (note.cpp:527): the NW point of the
  /// notehead when the stem points down.
  Point getStemDownNW(dynamic doc, int staffSize, bool isCueSize) {
    int defaultYShift = doc.getDrawingUnit(staffSize) ~/ 4;
    if (isCueSize) defaultYShift = doc.getCueSize(defaultYShift);
    // x default is always set to the left for now
    final Point p = Point(0, -defaultYShift);

    final int code = getNoteheadGlyph(getDrawingDur());

    // See the comment in [getStemUpSE] (mirrors the C++ guard).
    if (isMensuralDur) {
      final int mensuralGlyph = getMensuralNoteheadGlyph();
      p.y = -doc.getGlyphHeight(mensuralGlyph, staffSize, isCueSize) ~/ 2;
      p.x = doc.getGlyphWidth(mensuralGlyph, staffSize, isCueSize);
    }

    final dynamic glyph = doc.resources.getGlyphByCode(code);
    if (glyph != null && glyph.hasAnchor(SMuFLGlyphAnchor.stemDownNW)) {
      return doc.convertFontPoint(
          glyph, glyph.getAnchor(SMuFLGlyphAnchor.stemDownNW), staffSize, isCueSize);
    }
    return p;
  }

  /// Mirrors `Note::CalcStemLenInThirdUnits` (note.cpp:559) — the real
  /// (post-layout) stem-length calculation used by the beam engine, in
  /// contrast to [preparedata_functor.dart]'s `calcStemLenInThirdUnitsHeadless`
  /// which runs before drawing positions/loc are settled.
  int calcStemLenInThirdUnits(Staff staff, Stemdirection stemDir) {
    if (stemDir != Stemdirection.down && stemDir != Stemdirection.up) return 0;

    int baseStem = (staff.isTablature() || staff.isTabStaffLike())
        ? standardStemLengthTab
        : standardStemLength;
    baseStem *= 3;

    int shortening = 0;

    final int unitToLine = (stemDir == Stemdirection.up)
        ? -drawingLoc + (staff.drawingLines - 1) * 2
        : drawingLoc;
    if (unitToLine < 5) {
      switch (unitToLine) {
        case 4:
          shortening = 1;
          break;
        case 3:
          shortening = 2;
          break;
        case 2:
          shortening = 3;
          break;
        case 1:
          shortening = 4;
          break;
        case 0:
          shortening = 5;
          break;
        default:
          shortening = 6;
      }
    }

    // Limit shortening with duration shorter than quarter not when not in a
    // beam.
    if (getDrawingDur().value > MeiDuration.dur4.value && !isInBeam()) {
      if (getDrawingStemDir() == Stemdirection.up) {
        shortening = shortening < 4 ? shortening : 4;
      } else {
        shortening = shortening < 3 ? shortening : 3;
      }
    }

    baseStem -= shortening;

    return baseStem;
  }

  /// Return the effective drawing duration, inheriting from the parent chord
  /// when the note has none of its own (mirrors `Note::GetDrawingDur`).
  ///
  /// Deviations from the C++: the tablature branch (`Staff::IsTabStaffLike`)
  /// is not ported — tablature notation is not implemented elsewhere in this
  /// port, so it never applies to any corpus file exercised so far.
  MeiDuration getDrawingDur() {
    final Object? chordParent = isChordTone();
    if (chordParent is Chord && !hasDur) {
      return chordParent.getActualDur();
    }
    return getActualDur();
  }

  /// Mirrors `Note::GetMensuralNoteheadGlyph` (note.cpp:601).
  int getMensuralNoteheadGlyph() {
    assert(isMensuralDur);

    final MeiDuration drawingDur = getDrawingDur();

    // No SMuFL code used for these values
    if (drawingDur.value < MeiDuration.dur1.value) return 0;

    final Staff? staff = getFirstAncestor(ClassId.staff) as Staff?;
    final bool mensuralBlack =
        staff?.drawingNotationtype == Notationtype.mensuralBlack;

    if (mensuralBlack) return 0xE938; // mensuralNoteheadSemibrevisBlack
    if (colored == true) {
      return (drawingDur.value > MeiDuration.dur2.value) ? 0xE93C : 0xE93D;
    }
    return (drawingDur.value > MeiDuration.dur2.value) ? 0xE93D : 0xE93C;
  }

  /// Mirrors `Note::GetNoteheadGlyph` (note.cpp:640).
  int getNoteheadGlyph(MeiDuration duration) {
    const Map<String, int> additionalNoteheadSymbols = <String, int>{
      'noteheadDiamondBlackWide': 0xE0DC,
      'noteheadDiamondWhiteWide': 0xE0DE,
      'noteheadNull': 0xE0A5,
    };

    if (hasGlyphName) {
      return additionalNoteheadSymbols[glyphName!] ?? 0xE0A4;
    }

    if (hasHeadShape) {
      final hs = headShape!;
      if (hs.type == HeadShapeType.headShapeList) {
        switch (hs.headShapeList) {
          case HeadshapeList.quarter:
            return 0xE0A4; // noteheadBlack
          case HeadshapeList.half:
            return 0xE0A3; // noteheadHalf
          case HeadshapeList.whole:
            return 0xE0A2; // noteheadWhole
          case HeadshapeList.plus:
            return 0xE0AF; // noteheadPlusBlack
          case HeadshapeList.diamond:
            if (duration.value < MeiDuration.dur4.value) {
              return (headFill == Fill.solid) ? 0xE0DB : 0xE0D9;
            } else {
              return (headFill == Fill.voidValue) ? 0xE0D9 : 0xE0DB;
            }
          case HeadshapeList.rectangle:
            if (duration.value < MeiDuration.dur4.value) {
              return (headFill == Fill.solid) ? 0xE0B9 : 0xE0B8;
            } else {
              return (headFill == Fill.voidValue) ? 0xE0B8 : 0xE0B9;
            }
          case HeadshapeList.slash:
            if (MeiDuration.dur1.value >= duration.value) return 0xE102;
            if (MeiDuration.dur2 == duration) return 0xE103;
            return 0xE101;
          case HeadshapeList.x:
            if (MeiDuration.dur1 == duration) return 0xE0B5;
            if (MeiDuration.dur2 == duration) return 0xE0B6;
            return 0xE0A9;
          default:
            break;
        }
      } else if (hs.type == HeadShapeType.hexnum) {
        return hs.hexnum;
      }
    }

    if (headMod == Noteheadmodifier.fences) return 0xE0A0;

    // tab.staff-like uses solid note heads, unless overridden by @head.fill,
    // regardless of the note's duration
    if (!hasHeadFill) {
      // Mirrors `LayerElement::GetAncestorStaff()` (layerelement.cpp:517).
      final Staff? staff = getFirstAncestor(ClassId.staff) as Staff?;
      if (staff != null && staff.isTabStaffLike()) return 0xE0A4;
    }

    if (MeiDuration.breve == duration) return 0xE0A1;
    // We support solid on whole and half notes or void on quarter and shorter
    if (MeiDuration.dur1 == duration) {
      return (headFill == Fill.solid) ? 0xE0FA : 0xE0A2;
    }
    if (MeiDuration.dur2 == duration) {
      return (headFill == Fill.solid) ? 0xE0FB : 0xE0A3;
    }
    return (headFill == Fill.voidValue) ? 0xE0A3 : 0xE0A4;
  }

  /// Mirrors `Note::PnameToPclass`.
  static int pnameToPclass(Pitchname? pitchName) =>
      _pclassFromValue(pitchName?.value ?? 0);

  static int _pclassFromValue(int value) {
    switch (value) {
      case 1: // c
        return 0;
      case 2: // d
        return 2;
      case 3: // e
        return 4;
      case 4: // f
        return 5;
      case 5: // g
        return 7;
      case 6: // a
        return 9;
      case 7: // b
        return 11;
      default:
        return 0;
    }
  }

  /// Mirrors `Note::GetChromaticAlteration`.
  int getChromaticAlteration() {
    final Accid? accid = getDrawingAccid();
    if (accid == null) return 0;
    return _chromaticAlterationOf(accid.accidGes, accid.accid);
  }

  /// Mirrors `TransPitch::GetChromaticAlteration(data_ACCIDENTAL_GESTURAL,
  /// data_ACCIDENTAL_WRITTEN)`.
  static int _chromaticAlterationOf(
      AccidentalGestural? accidG, AccidentalWritten? accidW) {
    switch (accidG) {
      case AccidentalGestural.tf:
        return -3;
      case AccidentalGestural.ff:
        return -2;
      case AccidentalGestural.f:
        return -1;
      case AccidentalGestural.n:
        return 0;
      case AccidentalGestural.s:
        return 1;
      case AccidentalGestural.ss:
        return 2;
      case AccidentalGestural.ts:
        return 3;
      default:
        break;
    }
    switch (accidW) {
      case AccidentalWritten.tf:
        return -3;
      case AccidentalWritten.ff:
        return -2;
      case AccidentalWritten.f:
        return -1;
      case AccidentalWritten.nf:
        return -1;
      case AccidentalWritten.n:
        return 0;
      case AccidentalWritten.ns:
        return 1;
      case AccidentalWritten.s:
        return 1;
      case AccidentalWritten.ss:
        return 2;
      case AccidentalWritten.x:
        return 2;
      case AccidentalWritten.xs:
        return 3;
      case AccidentalWritten.sx:
        return 3;
      case AccidentalWritten.ts:
        return 3;
      default:
        return 0;
    }
  }

  /// Mirrors `Note::GetPitchClass`.
  ///
  /// Deviations from the C++: `@pname.ges` is typed `PitchnameGes` here
  /// (rather than reusing `Pitchname` as the C++ `data_PITCHNAME` typedef
  /// does), so the two are bridged through their shared numeric `value`
  /// instead of a single variable holding either.
  int getPitchClass() {
    final int pnameValue =
        hasPnameGes ? (pnameGes?.value ?? 0) : (pname?.value ?? 0);
    return _pclassFromValue(pnameValue) + getChromaticAlteration();
  }

  /// Mirrors `Note::GetMIDIPitch`.
  ///
  /// Deviations from the C++: the tablature branch (`HasTabCourse`) is not
  /// ported — tablature tuning (`Staff::m_drawingTuning`) is not implemented
  /// elsewhere in this port.
  int getMidiPitch({int shift = 0, int octaveShift = 0}) {
    int pitch = 0;
    if (hasPnum) {
      pitch = pnum!;
    } else if (hasPname || hasPnameGes) {
      final int pclass = getPitchClass();
      int oct = (this.oct ?? 0) + octaveShift;
      if (hasOctGes) oct = octGes!;
      pitch = pclass + (oct + 1) * 12;
    }
    return pitch + shift;
  }

  /// Mirrors `Note::IsEnharmonicWith`.
  bool isEnharmonicWith(Note note) => getMidiPitch() == note.getMidiPitch();

  /// Mirrors `Note::IsUnisonWith`.
  bool isUnisonWith(Note note, [bool ignoreAccid = false]) {
    if (!ignoreAccid && !isEnharmonicWith(note)) return false;
    return (pname == note.pname) && (oct == note.oct);
  }

  /// Mirrors `Note::IsVisible`.
  bool isVisible() {
    if (hasVisible) return visible == true;
    final Object? p = parent;
    if (p is Chord) return p.isVisible();
    return true;
  }

  /// Mirrors `Note::GetTransPitch` (note.cpp:863).
  ///
  /// No active caller yet — the C++ caller is `TransposeFunctor::VisitNote`
  /// (transposefunctor.cpp:100), and transpose is out of scope for
  /// layout/rendering; ported against [TransPitch] so it is ready when the
  /// functor lands.
  TransPitch getTransPitch() {
    final int pnameValue = (pname?.value ?? Pitchname.c.value) - Pitchname.c.value;
    return TransPitch(pnameValue, getChromaticAlteration(), oct ?? 4);
  }

  /// Mirrors `Note::UpdateFromTransPitch` (note.cpp:869).
  ///
  /// No active caller yet — see [getTransPitch].
  void updateFromTransPitch(TransPitch tp, bool hasKeySig) {
    pname = tp.getPitchName();

    Accid? accid = getDrawingAccid();
    if (accid == null) {
      accid = Accid();
      addChild(accid);
    }

    bool transposeGesturalAccid = accid.hasAccidGes;
    bool transposeWrittenAccid = accid.hasAccid;
    // TODO: Check the case of both existing but having unequal values.
    if (!accid.hasAccidGes && !accid.hasAccid) {
      transposeGesturalAccid = true;
    }

    // Without key signature prefer written accidentals.
    if (!hasKeySig && transposeGesturalAccid) {
      accid.accidGes = null;
      transposeGesturalAccid = false;
      if (tp.accid != 0) transposeWrittenAccid = true;
    }

    if (transposeGesturalAccid) {
      accid.accidGes = tp.getAccidGes();
    }
    if (transposeWrittenAccid) {
      accid.accid = tp.getAccidWritten();
    }

    if ((oct ?? 4) != tp.oct) {
      if (hasOctGes) {
        octGes = (octGes ?? 0) + tp.oct - (oct ?? 4);
      }
      oct = tp.oct;
    }
  }
}

/// Mirrors `Chord::IsVisible`. Defined as an extension — `Chord` is a
/// generated class (`layer_elements_gen.dart`), never hand-edited.
extension ChordVisibility on Chord {
  bool isVisible() {
    if (hasVisible) return visible == true;
    // If the chord doesn't have it, see if all the children are invisible.
    for (final Object child in getList()) {
      final Note note = child as Note;
      if (!note.hasVisible || note.visible == true) return true;
    }
    return false;
  }
}

/// Mirrors `vrv::Rest`.
class Rest extends LayerElement
    with
        AttAltSym,
        AttAugmentDots,
        AttBeamSecondary,
        AttColor,
        AttCue,
        AttDurationGes,
        AttDurationLog,
        AttDurationQuality,
        AttDurationRatio,
        AttEnclosingChars,
        AttExtSymAuth,
        AttExtSymNames,
        AttFermataPresent,
        AttRestVisMensural,
        AttStaffIdent,
        DurationInterface,
        AttStaffLoc,
        AttStaffLocPitched,
        PositionInterface,
        AttVisualOffsetHo,
        AttVisualOffsetVo,
        OffsetInterface {
  Rest() : super(ClassId.rest) {
    reset();
  }

  @override
  ClassId get classId => ClassId.rest;

  @override
  String get className => 'rest';

  @override
  Object clone() {
    final copy = Rest();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void reset() {
    super.reset();
    // Register the interfaces of `vrv::Rest` (`AltSymInterface`,
    // `DurationInterface`, `OffsetInterface` and `PositionInterface`) for the
    // `hasInterface` lookups. Without the duration registration
    // GetAlignmentDuration fell through to zero and every rest collapsed to a
    // duration of 0 in the aligner.
    registerInterfaces([
      InterfaceId.altSym,
      InterfaceId.duration,
      InterfaceId.offset,
      InterfaceId.position,
    ]);
  }

  @override
  bool get hasToBeAligned => true;

  /// Mirrors `Rest::UpdateFromTransLoc` (rest.cpp:340).
  ///
  /// No active caller yet — the C++ caller is `TransposeFunctor::VisitRest`
  /// (transposefunctor.cpp:148); ported against [TransPitch] so it is ready
  /// when transpose lands.
  void updateFromTransLoc(TransPitch tp) {
    if (hasOloc && hasPloc) {
      ploc = tp.getPitchName();

      if (oloc != tp.oct) {
        oloc = tp.oct;
      }
    }
  }

  @override
  bool isSupportedChild(ClassId classId) {
    if (classId == ClassId.dots) return true;
    if (Object.isEditorialElementId(classId)) return true;
    return false;
  }
}

/// Mirrors `vrv::Clef` (scoreDef/staffDef clefs are handled by the attr
/// variants; this is the layer element).
class Clef extends LayerElement
    with
        AttVisualOffsetHo,
        AttVisualOffsetVo,
        OffsetInterface,
        AttClefLog,
        AttClefShape,
        AttColor,
        AttEnclosingChars,
        AttExtSymAuth,
        AttExtSymNames,
        AttLineLoc,
        AttOctave,
        AttOctaveDisplacement,
        AttStaffIdent,
        AttTypography,
        AttVisibility {
  Clef() : super(ClassId.clef) {
    reset();
  }

  @override
  ClassId get classId => ClassId.clef;

  @override
  String get className => 'clef';

  @override
  Object clone() {
    final copy = Clef();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Clef other) {
    if (identical(this, other)) return;

    // OffsetInterface atts
    ho = other.ho;
    vo = other.vo;
    // AttClefLog
    cautionary = other.cautionary;
    // AttClefShape
    shape = other.shape;
    // AttColor
    color = other.color;
    // AttEnclosingChars
    enclose = other.enclose;
    // AttExtSymAuth
    glyphAuth = other.glyphAuth;
    // AttExtSymNames
    glyphName = other.glyphName;
    // AttLineLoc
    line = other.line;
    // AttOctave
    oct = other.oct;
    // AttOctaveDisplacement
    dis = other.dis;
    disPlace = other.disPlace;
    // AttStaffIdent
    staff = other.staff == null ? null : [...other.staff!];
    // AttTypography
    fontsize = other.fontsize;
    // AttVisibility — was missing, so `Clef::operator=`'s implicit copy of
    // every base class (including AttVisibility) was not mirrored: cloning
    // a hidden staffDef clef (`<clef visible="false">`, materialized into
    // the layer as the system's initial clef) silently lost the flag and
    // drew a visible gClef the C++ never emits, e.g. artic/artic-016.mei,
    // chord/chord-007.mei (extra `E050` in `<defs>`).
    visible = other.visible;

    super.copyFrom(other);
  }

  @override
  void reset() {
    super.reset();
    // OffsetInterface
    ho = null;
    vo = null;
    // AttClefLog
    cautionary = null;
    // AttClefShape
    shape = null;
    // AttColor
    color = null;
    // AttEnclosingChars
    enclose = null;
    // AttExtSymAuth / AttExtSymNames
    glyphAuth = null;
    glyphName = null;
    // AttLineLoc
    line = null;
    // AttOctave
    oct = null;
    // AttOctaveDisplacement
    dis = null;
    disPlace = null;
    // AttStaffIdent
    staff = null;
    // AttTypography
    fontsize = null;
    // AttVisibility
    visible = null;

    type = null;
    label = null;
  }

  /// Return the pitch offset of the clef (mirrors `GetClefLocOffset`).
  int getClefLocOffset() {
    // Only resolve simple sameas links to avoid infinite recursion
    // (mirrors clef.cpp:87-90).
    final Object? link = sameasLink;
    if (link is Clef && !link.hasSameasLink) {
      return link.getClefLocOffset();
    }
    int offset = 0;
    int defaultOct = 4; // C clef
    if (shape == Clefshape.g) {
      defaultOct = 4;
      offset = -4;
    } else if (shape == Clefshape.gg) {
      defaultOct = 3;
      offset = 3;
    } else if (shape == Clefshape.f) {
      defaultOct = 3;
      offset = 4;
    }

    if (hasOct) {
      final int octDifference = oct! - defaultOct;
      offset -= octDifference * 7;
    }

    offset += ((line ?? 0) - 1) * 2;

    int disPlaceOffset = 0;
    if (hasDisPlace) {
      disPlaceOffset = (disPlace == StaffrelBasic.above) ? -1 : 1;
    }

    if ((disPlaceOffset != 0) && hasDis) {
      offset += disPlaceOffset * (dis!.value - 1);
    }

    return offset;
  }

  @override
  bool get isScoreDefElement =>
      parent != null && getFirstAncestor(ClassId.scoreDef) != null;

  @override
  bool get hasToBeAligned => !isScoreDefElement;
}

/// Mirrors `BarLinePosition` (barline.h).
enum BarlinePosition { none, left, right }

/// Mirrors `vrv::BarLine`.
class BarLine extends LayerElement
    with
        AttBarLineLog,
        AttBarLineVis,
        AttColor,
        AttNNumberLike,
        AttTyped,
        AttVisibility {
  BarLine() : super(ClassId.barLine) {
    reset();
  }

  /// The position of the barline within the measure (mirrors `m_position`).
  BarlinePosition position = BarlinePosition.none;

  @override
  ClassId get classId => ClassId.barLine;

  @override
  String get className => 'barLine';

  @override
  Object clone() {
    final copy = BarLine();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void reset() {
    super.reset();
    color = null;
    type = null;
    position = BarlinePosition.none;
  }

  /// Mirrors `GetPosition` / `SetPosition`.
  BarlinePosition getPosition() => position;
  void setPosition(BarlinePosition position) => this.position = position;

  /// Mirrors `BarLine::HasRepetitionDots` (barline.cpp:78).
  bool hasRepetitionDots() =>
      form == Barrendition.rptstart ||
      form == Barrendition.rptend ||
      form == Barrendition.rptboth;

  /// Mirrors `BarLine::IsDrawnThrough` (barline.cpp:87) — walks the
  /// [StaffGrp] parent chain until a `bar.thru` is found.
  bool isDrawnThrough(StaffGrp? staffGrp) {
    StaffGrp? grp = staffGrp;
    while (grp != null) {
      if (grp.hasBarThru) return grp.barThru == true;
      final Object? parent = grp.parent;
      grp = parent is StaffGrp ? parent : null;
    }
    return false;
  }

  /// Mirrors `BarLine::GetLengthFromContext` (barline.cpp:98).
  (bool, double) getLengthFromContext(StaffDef? staffDef) {
    final Object? parentMeasure = parent;
    if (parentMeasure is Measure && parentMeasure.hasBarLen) {
      return (true, parentMeasure.barLen!);
    }
    Object? object = staffDef;
    while (object != null) {
      if (object is AttBarring) {
        final AttBarring att = object as AttBarring;
        if (att.hasBarLen) return (true, att.barLen!);
      }
      if (object is ScoreDef) break;
      object = object.parent;
    }
    return (false, 0.0);
  }

  /// Mirrors `BarLine::GetMethodFromContext` (barline.cpp:126).
  (bool, Barmethod) getMethodFromContext(StaffDef? staffDef) {
    final Object? parentMeasure = parent;
    if (parentMeasure is Measure && parentMeasure.hasBarMethod) {
      return (true, parentMeasure.barMethod!);
    }
    Object? object = staffDef;
    while (object != null) {
      if (object is AttBarring) {
        final AttBarring att = object as AttBarring;
        if (att.hasBarMethod) return (true, att.barMethod!);
      }
      if (object is ScoreDef) break;
      object = object.parent;
    }
    return (false, Barmethod.none);
  }

  /// Mirrors `BarLine::GetPlaceFromContext` (barline.cpp:154).
  (bool, int) getPlaceFromContext(StaffDef? staffDef) {
    final Object? parentMeasure = parent;
    if (parentMeasure is Measure && parentMeasure.hasBarPlace) {
      return (true, parentMeasure.barPlace!);
    }
    Object? object = staffDef;
    while (object != null) {
      if (object is AttBarring) {
        final AttBarring att = object as AttBarring;
        if (att.hasBarPlace) return (true, att.barPlace!);
      }
      if (object is ScoreDef) break;
      object = object.parent;
    }
    return (false, 0);
  }

  @override
  bool get hasToBeAligned => true;
}
