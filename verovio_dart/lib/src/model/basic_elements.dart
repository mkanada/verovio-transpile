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
import 'package:verovio_dart/src/core/options_shell.dart' show Condense;
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/layout/adjust_x_overflow.dart'
    show AdjustXOverflowFunctor;
import 'package:verovio_dart/src/layout/floating_positioner.dart'
    show FloatingPositioner;
import 'package:verovio_dart/src/layout/horizontal_aligner.dart'
    show Alignment, MeasureAligner, TimestampAligner;
import 'package:verovio_dart/src/layout/vertical_aligner.dart'
    show StaffAlignment;
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
import 'package:verovio_dart/src/model/atts/mei_enums.dart';
import 'package:verovio_dart/src/model/comparison.dart'
    show AttNIntegerComparison;
import 'package:verovio_dart/src/model/drawing_interfaces.dart';
import 'package:verovio_dart/src/model/interfaces/facsimile_interface.dart';
import 'package:verovio_dart/src/model/interfaces/pitch_interface.dart';
import 'package:verovio_dart/src/model/interfaces/position_interface.dart';
import 'package:verovio_dart/src/model/interfaces/simple_interfaces.dart';
import 'package:verovio_dart/src/model/interfaces/duration_interface.dart';
import 'package:verovio_dart/src/model/layer_element.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart'
    show Accid, Chord, KeySig, MeterSig, MeterSigGrp;
import 'package:verovio_dart/src/model/mensur.dart' show Mensur;
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/model/scoredef.dart';
import 'package:verovio_dart/src/model/system_page_elements.dart';

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
    final comparison = AttNIntegerComparison(ClassId.staff, staffDef.n ?? 0);
    final Staff? staff = findDescendantByComparison(comparison) as Staff?;
    return (staff != null && !staff.isHidden) ? staff : null;
  }

  /// Mirrors `Ossia::GetDrawingBottopOStaff`.
  Staff? getDrawingBottopOStaff() {
    if (drawingStaffGrp.childCount == 0) return null;
    final StaffDef staffDef = drawingStaffGrp.getLast() as StaffDef;
    final comparison = AttNIntegerComparison(ClassId.staff, staffDef.n ?? 0);
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

  /// Return true if the measure is the first of its system (mirrors
  /// `IsFirstInSystem`).
  bool isFirstInSystem() {
    final Object? system = getFirstAncestor(ClassId.system);
    assert(system != null);
    return identical(system?.getFirst(ClassId.measure), this);
  }

  /// Return the left barline of the measure (mirrors `GetLeftBarLine`).
  BarLine getLeftBarLine() => leftBarLine;

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
  /// `SetDrawingRightBarLine`).
  void setDrawingRightBarLine(Barrendition rendition) =>
      drawingRightBarLine = rendition;

  /// Set the drawing rendition of the left barline (mirrors
  /// `SetDrawingLeftBarLine`).
  void setDrawingLeftBarLine(Barrendition rendition) =>
      drawingLeftBarLine = rendition;

  /// Return true if the measure holds invisible staff barlines (mirrors
  /// `HasInvisibleStaffBarlines`).
  bool hasInvisibleStaffBarlines() => invisibleStaffBarlines.isNotEmpty;

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
      // We have an rptend before, make sure there is none on the left.
      if (previous.right == Barrendition.rptend &&
          left != Barrendition.rptstart &&
          left != Barrendition.rptboth) {
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
      } else {
        setDrawingLeftBarLine(left ?? previous.drawingRightBarLine);
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
      final existing = invisibleStaffBarlines[staff.n ?? 0];
      if (existing == null) {
        invisibleStaffBarlines[staff.n ?? 0] =
            (Barrendition.none, rightRendition);
      } else {
        invisibleStaffBarlines[staff.n ?? 0] = (existing.$1, rightRendition);
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
    if (Object.isControlElementId(classId)) return true;
    if (Object.isEditorialElementId(classId)) return true;
    return false;
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

  /// Mirrors `SetOssia` / `IsOssia`.
  void setOssia(bool isOssia) => isOssiaFlag = isOssia;
  bool isOssia() => isOssiaFlag;

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
    with DrawingListInterface, AttCue, AttNInteger, AttTyped, AttVisibility {
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
    with VisibilityDrawingInterface, PageMilestoneInterface, AttNNumberLike {
  Mdiv() : super(ClassId.mdiv) {
    reset();
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
    resetStemmedDrawingInterface();
  }

  /// Mirrors `HasStemSameasNote` / `GetStemSameasRole` /
  /// `SetStemSameasRole`.
  bool hasStemSameasNote() => stemSameasNote != null;

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

  /// Return the parent chord if the note is a chord tone (null otherwise;
  /// mirrors `IsChordTone`).
  Object? isChordTone() => getFirstAncestor(ClassId.chord, maxChordDepth);

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

    type = null;
    label = null;
  }

  /// Return the pitch offset of the clef (mirrors `GetClefLocOffset`).
  int getClefLocOffset() {
    // Only resolve simple sameas links to avoid infinite recursion.
    // (The sameas resolution arrives with LinkingInterface lookups; for now
    // only direct clefs are resolved.)
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

  @override
  bool get hasToBeAligned => true;
}
