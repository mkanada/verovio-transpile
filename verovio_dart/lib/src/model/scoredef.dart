/// Port of `scoredef.h/cpp`, `staffdef.h/cpp`, `staffgrp.h/cpp` and
/// `layerdef.h/cpp` — the score definition classes of the MEI model.
///
/// The functor-based features (Accept/Process) arrive with the layout phase;
/// the drawing-value replacement methods replicate the semantics of the
/// corresponding pseudo functors with direct traversals.
library;

import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/model/atts/atts_cmn.dart';
import 'package:verovio_dart/src/model/atts/atts_mei.dart';
import 'package:verovio_dart/src/model/atts/atts_midi.dart';
import 'package:verovio_dart/src/model/atts/atts_shared.dart';
import 'package:verovio_dart/src/model/atts/atts_stringtab.dart';
import 'package:verovio_dart/src/model/atts/atts_visual.dart';
import 'package:verovio_dart/src/model/atts/mei_enums.dart';
import 'package:verovio_dart/src/model/basic_elements.dart' show Clef, Section;
import 'package:verovio_dart/src/model/drawing_interfaces.dart'
    show VisibilityDrawingInterface;
import 'package:verovio_dart/src/model/interfaces/simple_interfaces.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart'
    show KeySig, MeterSig, MeterSigGrp;
import 'package:verovio_dart/src/model/mensur.dart' show Mensur;
import 'package:verovio_dart/src/model/misc_elements_gen.dart'
    show GrpSym, Label, LabelAbbr, PgFoot, PgHead;
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/model/staffdef_drawing_interface.dart';

// ---------------------------------------------------------------------------
// StaffDefRedrawFlags (from setscoredeffunctor.h)
// ---------------------------------------------------------------------------

/// Flags for indicating whether staffDef values need to be redrawn.
class StaffDefRedrawFlags {
  static const int forceRedraw = 0x1;
  static const int redrawClef = 0x2;
  static const int redrawKeySig = 0x4;
  static const int redrawMensur = 0x8;
  static const int redrawMeterSig = 0x10;
  static const int redrawMeterSigGrp = 0x20;
  static const int redrawAll = redrawClef |
      redrawKeySig |
      redrawMensur |
      redrawMeterSig |
      redrawMeterSigGrp;
}

// ---------------------------------------------------------------------------
// ScoreDefElement
// ---------------------------------------------------------------------------

/// This class is a base class for MEI scoreDef or staffDef elements
/// (mirrors `vrv::ScoreDefElement`).
///
/// It implements the ScoreDefInterface that implements the attribute classes
/// for clef, key signature, mensur and meter signature.
class ScoreDefElement extends Object
    with
        // ScoreDefInterface atts
        AttBarring,
        AttDurationDefault,
        AttLyricStyle,
        AttMeasureNumbers,
        AttMidiTempo,
        AttMmTempo,
        AttMultinumMeasures,
        AttOctaveDefault,
        AttPianoPedals,
        AttSpacing,
        AttSystems,
        ScoreDefInterface,
        AttTyped {
  ScoreDefElement([ClassId classId = ClassId.scoreDefElement]) {
    assignClassId(classId);
    reset();
  }

  @override
  String get className => '[MISSING]';

  @override
  void reset() {
    super.reset();
    type = null;

    // ScoreDefInterface atts
    barLen = null;
    barMethod = null;
    barPlace = null;
    durDefault = null;
    numDefault = null;
    numbaseDefault = null;
    lyricAlign = null;
    lyricFam = null;
    lyricName = null;
    lyricSize = null;
    lyricStyle = null;
    lyricWeight = null;
    mnumVisible = null;
    midiBpm = null;
    midiMspb = null;
    mm = null;
    mmUnit = null;
    mmDots = null;
    multiNumber = null;
    octDefault = null;
    pedalStyle = null;
    spacingPackexp = null;
    spacingPackfact = null;
    spacingStaff = null;
    spacingSystem = null;
    systemLeftline = null;
    systemLeftmar = null;
    systemRightmar = null;
    systemTopmar = null;
  }

  @override
  bool get isScoreDefElement => true;

  /// Copy the content of [other] into this object (mirrors `operator=`;
  /// the attribute values are copied explicitly since the att classes hold
  /// the state).
  @override
  void copyFrom(covariant ScoreDefElement other) {
    if (identical(this, other)) return;
    super.copyFrom(other);
    // ScoreDefInterface atts
    copyAttBarring(other);
    copyAttDurationDefault(other);
    copyAttLyricStyle(other);
    copyAttMeasureNumbers(other);
    copyAttMidiTempo(other);
    copyAttMmTempo(other);
    copyAttMultinumMeasures(other);
    copyAttOctaveDefault(other);
    copyAttPianoPedals(other);
    copyAttSpacing(other);
    copyAttSystems(other);
    copyAttTyped(other);
  }

  // -------------------------------------------------------------------------
  // Presence / value accessors for clef, keySig, mensur and meterSig
  // -------------------------------------------------------------------------

  /// Return true if the scoreDef/staffDef has clef info (mirrors
  /// `HasClefInfo`). [depth] defaults to direct children only.
  bool hasClefInfo([int depth = 1]) =>
      findDescendantByType(ClassId.clef, deepness: depth) != null;

  /// Return true if the scoreDef/staffDef has keySig info (mirrors
  /// `HasKeySigInfo`).
  bool hasKeySigInfo([int depth = 1]) =>
      findDescendantByType(ClassId.keysig, deepness: depth) != null;

  /// Return true if the scoreDef/staffDef has mensur info (mirrors
  /// `HasMensurInfo`).
  bool hasMensurInfo([int depth = 1]) =>
      findDescendantByType(ClassId.mensur, deepness: depth) != null;

  /// Return true if the scoreDef/staffDef has meterSig info (mirrors
  /// `HasMeterSigInfo`).
  bool hasMeterSigInfo([int depth = 1]) =>
      findDescendantByType(ClassId.meterSig, deepness: depth) != null;

  /// Return true if the scoreDef/staffDef has meterSigGrp info (mirrors
  /// `HasMeterSigGrpInfo`).
  bool hasMeterSigGrpInfo([int depth = 1]) =>
      findDescendantByType(ClassId.meterSigGrp, deepness: depth) != null;

  Clef getClef() {
    assert(hasClefInfo());
    return findDescendantByType(ClassId.clef, deepness: 1) as Clef;
  }

  Clef getClefCopy() => ScoreDefElement._copyOf(getClef());

  KeySig getKeySig() {
    assert(hasKeySigInfo());
    return findDescendantByType(ClassId.keysig, deepness: 1) as KeySig;
  }

  KeySig getKeySigCopy() => ScoreDefElement._copyOf(getKeySig());

  Mensur getMensur() {
    assert(hasMensurInfo());
    return findDescendantByType(ClassId.mensur, deepness: 1) as Mensur;
  }

  Mensur getMensurCopy() => ScoreDefElement._copyOf(getMensur());

  MeterSig getMeterSig() {
    assert(hasMeterSigInfo());
    return findDescendantByType(ClassId.meterSig, deepness: 1) as MeterSig;
  }

  MeterSig getMeterSigCopy() => ScoreDefElement._copyOf(getMeterSig());

  MeterSigGrp getMeterSigGrp() {
    assert(hasMeterSigGrpInfo());
    return findDescendantByType(ClassId.meterSigGrp, deepness: 1)
        as MeterSigGrp;
  }

  MeterSigGrp getMeterSigGrpCopy() => ScoreDefElement._copyOf(getMeterSigGrp());

  static T _copyOf<T extends Object>(Object source) {
    final Object clone = source.clone();
    clone.cloneReset();
    return clone as T;
  }

  /// Clone [source] and reset its pointers; public variant of [_copyOf]
  /// used by the layer drawing staffDef preparation.
  static T cloneOf<T extends Object>(Object source) => _copyOf<T>(source);
}

// ---------------------------------------------------------------------------
// ScoreDef
// ---------------------------------------------------------------------------

/// This class represents a MEI scoreDef (mirrors `vrv::ScoreDef`).
///
/// It contains StaffGrp objects.
class ScoreDef extends ScoreDefElement
    with
        ObjectListInterface,
        AttDistances,
        AttEndings,
        AttOptimization,
        AttTimeBase,
        AttTuning {
  ScoreDef() : super(ClassId.scoreDef) {
    reset();
  }

  /// Public flag used by the IO / layout pipeline (mirrors `m_setAsDrawing`).
  bool setAsDrawing = false;

  /// Public flag used by the layout pipeline (mirrors `m_insertScoreDef`).
  bool insertScoreDef = false;

  /// Flag indicating whether labels need to be drawn (mirrors
  /// `m_drawLabels`).
  bool drawLabelsFlag = false;

  /// The drawing width (clef and key sig) of the scoreDef.
  int drawingWidth = 0;

  /// The label drawing width of the scoreDef.
  int drawingLabelsWidth = 0;

  @override
  ClassId get classId => ClassId.scoreDef;

  @override
  String get className => 'scoreDef';

  @override
  Object clone() {
    final copy = ScoreDef();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant ScoreDef other) {
    if (identical(this, other)) return;
    super.copyFrom(other);
    setAsDrawing = other.setAsDrawing;
    insertScoreDef = other.insertScoreDef;
    drawLabelsFlag = other.drawLabelsFlag;
    drawingWidth = other.drawingWidth;
    drawingLabelsWidth = other.drawingLabelsWidth;

    // ScoreDef atts
    copyAttDistances(other);
    copyAttEndings(other);
    copyAttOptimization(other);
    copyAttTimeBase(other);
    copyAttTuning(other);
  }

  @override
  void reset() {
    super.reset();

    // AttDistances
    dirDist = null;
    dynamDist = null;
    harmDist = null;
    rehDist = null;
    tempoDist = null;
    // AttEndings
    endingRend = null;
    // AttOptimization
    optimize = null;
    // AttTimeBase
    ppq = null;
    // AttTuning
    tuneHz = null;
    tunePname = null;
    tuneTemper = null;

    setAsDrawing = false;
    insertScoreDef = false;
    drawLabelsFlag = false;
    drawingWidth = 0;
    drawingLabelsWidth = 0;
  }

  @override
  bool isSupportedChild(ClassId classId) {
    const supported = {
      ClassId.clef,
      ClassId.grpSym,
      ClassId.keysig,
      ClassId.mensur,
      ClassId.meterSig,
      ClassId.meterSigGrp,
      ClassId.staffGrp,
      ClassId.symbolTable,
    };
    if (supported.contains(classId)) return true;
    if (Object.isRunningElementId(classId)) return true;
    return false;
  }

  @override
  bool addChildAdditionalCheck(Object child) {
    // Clef and mensur are actually not allowed as children of scoreDef in
    // MEI. Left as a warning for now.
    if (child.classId == ClassId.clef && !child.isAttribute) {
      logWarning('Having <clef> as child of <scoreDef> is not valid MEI');
    } else if (child.classId == ClassId.mensur && !child.isAttribute) {
      logWarning('Having <mensur> as child of <scoreDef> is not valid MEI');
    }
    return super.addChildAdditionalCheck(child);
  }

  @override
  int getInsertOrderFor(ClassId classId) {
    const order = [
      ClassId.symbolTable,
      ClassId.clef,
      ClassId.keysig,
      ClassId.meterSigGrp,
      ClassId.meterSig,
      ClassId.mensur,
      ClassId.pgHead,
      ClassId.pgFoot,
      ClassId.staffGrp,
      ClassId.grpSym,
    ];
    return getInsertOrderForIn(classId, order);
  }

  @override
  void filterList(List<Object> childList) {
    // We want to keep only staffDef children.
    childList
        .removeWhere((Object object) => object.classId != ClassId.staffDef);
  }

  // -------------------------------------------------------------------------
  // Drawing value replacement
  // -------------------------------------------------------------------------

  /// Replace the scoreDef drawing values with the content of [newScoreDef]
  /// (mirrors `ReplaceDrawingValues(const ScoreDef *)`).
  void replaceDrawingValues(ScoreDef newScoreDef) {
    insertScoreDef = false;
    setAsDrawing = true;

    int redrawFlags = 0;
    Clef? clef;
    KeySig? keySig;
    Mensur? mensur;
    MeterSig? meterSig;
    MeterSigGrp? meterSigGrp;

    if (newScoreDef.hasClefInfo()) {
      redrawFlags |= StaffDefRedrawFlags.redrawClef;
      clef = newScoreDef.getClef();
    }
    if (newScoreDef.hasKeySigInfo()) {
      final KeySig newKeySig = newScoreDef.getKeySig();
      if (!newKeySig.hasCancelaccid ||
          (newKeySig.cancelaccid != Cancelaccid.none0)) {
        keySig = newKeySig;
        redrawFlags |= StaffDefRedrawFlags.redrawKeySig;
      }
    }
    if (newScoreDef.hasMensurInfo()) {
      redrawFlags |= StaffDefRedrawFlags.redrawMensur;
      mensur = newScoreDef.getMensurCopy();
    }
    if (newScoreDef.hasMeterSigGrpInfo()) {
      redrawFlags &= ~StaffDefRedrawFlags.redrawMensur;
      redrawFlags |= StaffDefRedrawFlags.redrawMeterSigGrp;
      meterSigGrp = newScoreDef.getMeterSigGrp();
      meterSig = meterSigGrp.getSimplifiedMeterSig();
    } else if (newScoreDef.hasMeterSigInfo()) {
      redrawFlags |= StaffDefRedrawFlags.redrawMeterSig;
      meterSig = newScoreDef.getMeterSigCopy();
    }

    // Equivalent of ReplaceDrawingValuesInStaffDefFunctor applied to each
    // staffDef of the flat list.
    for (final Object object in getList()) {
      final staffDef = object as StaffDef;
      final StaffDef? newStaffDef = newScoreDef.getStaffDef(staffDef.n ?? 0);

      if (clef != null) {
        staffDef.setCurrentClef(clef);
      }
      // Look at staffDef only for keySig.
      if (newStaffDef != null && newStaffDef.hasKeySigInfo()) {
        final KeySig ks = newStaffDef.getKeySig();
        if (!ks.hasCancelaccid || (ks.cancelaccid != Cancelaccid.none0)) {
          staffDef.setCurrentKeySig(newStaffDef.getKeySig());
          redrawFlags |= StaffDefRedrawFlags.redrawKeySig;
        }
      } else if (keySig != null) {
        staffDef.setCurrentKeySig(keySig);
      }
      if (mensur != null) {
        staffDef.setCurrentMensur(mensur);
      }
      if (meterSig != null) {
        staffDef.setCurrentMeterSig(meterSig);
      }
      if (meterSigGrp != null) {
        staffDef.setCurrentMeterSigGrp(meterSigGrp);
      }
    }

    setRedrawFlags(redrawFlags);
  }

  /// Replace the corresponding staffDef with the content of [newStaffDef]
  /// (mirrors `ReplaceDrawingValues(const StaffDef *)`).
  void replaceDrawingValuesFromStaffDef(StaffDef newStaffDef) {
    // First find the staffDef with the same @n.
    final StaffDef? staffDef = getStaffDef(newStaffDef.n ?? 0);

    // If found, replace attributes.
    if (staffDef != null) {
      if (newStaffDef.hasClefInfo()) {
        staffDef.setDrawClef(true);
        staffDef.setCurrentClef(newStaffDef.getClef());
      }
      if (newStaffDef.hasKeySigInfo()) {
        staffDef.setDrawKeySig(true);
        staffDef.setCurrentKeySig(newStaffDef.getKeySig());
      }
      if (newStaffDef.hasMensurInfo()) {
        staffDef.setDrawMensur(true);
        // Never draw a mensur AND a meterSig.
        staffDef.setDrawMeterSig(false);
        staffDef.setCurrentMensur(newStaffDef.getMensurCopy());
      }
      if (newStaffDef.hasMeterSigGrpInfo()) {
        staffDef.setDrawMeterSigGrp(true);
        // Never draw a meterSig AND a mensur.
        staffDef.setDrawMeterSig(false);
        staffDef.setDrawMensur(false);
        final MeterSigGrp meterSigGrp = newStaffDef.getMeterSigGrpCopy();
        final MeterSig? meterSig = meterSigGrp.getSimplifiedMeterSig();
        staffDef.setCurrentMeterSigGrp(meterSigGrp);
        staffDef.setCurrentMeterSig(meterSig);
      } else if (newStaffDef.hasMeterSigInfo()) {
        final MeterSig meterSig = newStaffDef.getMeterSigCopy();
        if (newStaffDef.hasMensurInfo()) {
          // If there is a mensur and the meterSig is invisible, then print
          // mensur instead.
          if (meterSig.visible == false) {
            staffDef.setDrawMeterSig(false);
            staffDef.setDrawMensur(true);
            staffDef.setCurrentMensur(newStaffDef.getMensurCopy());
            // Invisible meterSig is still needed for mRest.
            staffDef.setCurrentMeterSig(meterSig);
          } else {
            staffDef.setDrawMeterSig(true);
            staffDef.setDrawMensur(false);
            staffDef.setCurrentMeterSig(meterSig);
          }
        } else {
          staffDef.setDrawMeterSig(true);
          staffDef.setDrawMensur(false);
          staffDef.setCurrentMeterSig(meterSig);
        }
      }
      // Copy other attributes if present.
      final Label? newLabel =
          newStaffDef.findDescendantByType(ClassId.label) as Label?;
      if (newLabel != null) {
        final Label? currentLabel =
            staffDef.findDescendantByType(ClassId.label) as Label?;
        if (currentLabel != null) {
          staffDef.replaceChild(
              currentLabel, ScoreDefElement._copyOf<Label>(newLabel));
        } else {
          staffDef.addChild(ScoreDefElement._copyOf<Label>(newLabel));
        }
      }
    } else {
      logWarning("StaffDef with xml:id '${newStaffDef.id}' could not be found");
    }
  }

  /// Replace the corresponding staffGrp labels (mirrors
  /// `ReplaceDrawingLabels`).
  void replaceDrawingLabels(StaffGrp newStaffGrp) {
    // First find the staffGrp with the same @n.
    final StaffGrp? staffGrp = getStaffGrp(newStaffGrp.n ?? '');
    if (staffGrp == null) return;

    if (newStaffGrp.hasLabelInfo()) {
      final Label label =
          ScoreDefElement._copyOf<Label>(newStaffGrp.getLabel());
      // Check if we previously had one, and replace it if yes.
      if (staffGrp.hasLabelInfo()) {
        final Label oldLabel = staffGrp.getLabel();
        staffGrp.replaceChild(oldLabel, label);
      }
      // Otherwise simply add it.
      else {
        staffGrp.addChild(label);
      }
    }
    if (newStaffGrp.hasLabelAbbrInfo()) {
      final LabelAbbr labelAbbr =
          ScoreDefElement._copyOf<LabelAbbr>(newStaffGrp.getLabelAbbr());
      if (staffGrp.hasLabelAbbrInfo()) {
        final LabelAbbr oldLabelAbbr = staffGrp.getLabelAbbr();
        staffGrp.replaceChild(oldLabelAbbr, labelAbbr);
      } else {
        staffGrp.addChild(labelAbbr);
      }
    }
  }

  /// Replace the staffDef score attributes with the ones currently set as
  /// drawing values (mirrors `ResetFromDrawingValues`).
  void resetFromDrawingValues() {
    for (final Object object in getList()) {
      final staffDef = object as StaffDef;

      final Clef? clef = staffDef.findDescendantByType(ClassId.clef) as Clef?;
      if (clef != null) {
        clef.replaceWithCopyOf(staffDef.getCurrentClef());
      }

      final KeySig? keySig =
          staffDef.findDescendantByType(ClassId.keysig) as KeySig?;
      if (keySig != null) {
        keySig.replaceWithCopyOf(staffDef.getCurrentKeySig());
      }

      final Mensur? mensur =
          staffDef.findDescendantByType(ClassId.mensur) as Mensur?;
      if (mensur != null) {
        mensur.replaceWithCopyOf(staffDef.getCurrentMensur());
      }

      final MeterSigGrp? meterSigGrp =
          staffDef.findDescendantByType(ClassId.meterSigGrp) as MeterSigGrp?;
      final MeterSig? meterSig =
          staffDef.findDescendantByType(ClassId.meterSig) as MeterSig?;
      if (meterSigGrp != null) {
        meterSigGrp.replaceWithCopyOf(staffDef.getCurrentMeterSigGrp());
      } else if (meterSig != null) {
        meterSig.replaceWithCopyOf(staffDef.getCurrentMeterSig());
      }
    }
  }

  // -------------------------------------------------------------------------
  // Lookups
  // -------------------------------------------------------------------------

  /// Get the staffDef with number [n] (null if not found; mirrors
  /// `GetStaffDef`).
  StaffDef? getStaffDef(int n) {
    for (final Object child in getList()) {
      if (child is! StaffDef) continue;
      if (child.n == n) {
        return child;
      }
      // Also check if we are looking for an ossia staffDef.
      final Object? ossia = child.getOssiaStaffDef(n);
      if (ossia != null) return ossia as StaffDef;
    }

    // Nothing found, something broken in the data...
    return null;
  }

  /// Get the staffGrp with number [n] (null if not found; mirrors
  /// `GetStaffGrp`).
  StaffGrp? getStaffGrp(String? n) {
    // First get all the staffGrps, then match the @n.
    final List<Object> staffGrps = findAllDescendantsByType(ClassId.staffGrp);
    for (final Object object in staffGrps) {
      final staffGrp = object as StaffGrp;
      if (staffGrp.n == n) return staffGrp;
    }
    return null;
  }

  /// Return all the @n values of the staffDefs in the scoreDef (mirrors
  /// `GetStaffNs`, including ossias above/below).
  List<int> getStaffNs() {
    final List<int> ns = [];
    for (final Object child in getList()) {
      // It should be staffDef only, but double check.
      if (child is! StaffDef) continue;
      child.getOssiaAboveNs(ns);
      ns.add(child.n ?? 0);
      child.getOssiaBelowNs(ns);
    }
    return ns;
  }

  /// Set the redraw flags to all staffDefs (mirrors `SetRedrawFlags`).
  ///
  /// Equivalent of SetStaffDefRedrawFlagsFunctor applied to each staffDef.
  void setRedrawFlags(int redrawFlags) {
    setAsDrawing = true;
    final bool forceRedraw = redrawFlags & StaffDefRedrawFlags.forceRedraw != 0;
    final bool redrawClef = redrawFlags & StaffDefRedrawFlags.redrawClef != 0;
    final bool redrawKeySig =
        redrawFlags & StaffDefRedrawFlags.redrawKeySig != 0;
    final bool redrawMensur =
        redrawFlags & StaffDefRedrawFlags.redrawMensur != 0;
    final bool redrawMeterSig =
        redrawFlags & StaffDefRedrawFlags.redrawMeterSig != 0;
    final bool redrawMeterSigGrp =
        redrawFlags & StaffDefRedrawFlags.redrawMeterSigGrp != 0;

    void apply(Object? object) {
      if (object is! StaffDef) return;
      if (redrawClef || forceRedraw) object.setDrawClef(redrawClef);
      if (redrawKeySig || forceRedraw) object.setDrawKeySig(redrawKeySig);
      if (redrawMensur || forceRedraw) object.setDrawMensur(redrawMensur);
      if (redrawMeterSig || forceRedraw) {
        object.setDrawMeterSig(redrawMeterSig);
      }
      if (redrawMeterSigGrp || forceRedraw) {
        object.setDrawMeterSigGrp(redrawMeterSigGrp);
      }
    }

    // The C++ runs SetStaffDefRedrawFlagsFunctor over the whole scoreDef;
    // staffDefs are nested in staffGrps so use the flat staffDef list.
    for (final Object child in getList()) {
      apply(child);
    }
  }

  // -------------------------------------------------------------------------
  // Drawing widths and running elements
  // -------------------------------------------------------------------------

  bool get drawLabels => drawLabelsFlag;
  void setDrawLabels(bool drawLabels) => drawLabelsFlag = drawLabels;

  void setDrawingWidth(int width) => drawingWidth = width;

  void setDrawingLabelsWidth(int width) {
    if (drawingLabelsWidth < width) {
      drawingLabelsWidth = width;
    }
  }

  void resetDrawingLabelsWidth() => drawingLabelsWidth = 0;

  /// Get the pgFoot with the given @func (null if not found; mirrors
  /// `GetPgFoot`).
  PgFoot? getPgFoot(Pgfunc? func) =>
      _findRunningElement<PgFoot>(ClassId.pgFoot, func ?? Pgfunc.none);

  /// Get the pgHead with the given @func (null if not found; mirrors
  /// `GetPgHead`).
  PgHead? getPgHead(Pgfunc? func) =>
      _findRunningElement<PgHead>(ClassId.pgHead, func ?? Pgfunc.none);

  T? _findRunningElement<T extends Object>(ClassId classId, Pgfunc func) {
    final List<Object> candidates =
        findAllDescendantsByType(classId, deepness: unlimitedDepth);
    for (final Object candidate in candidates) {
      final Pgfunc? elementFunc = (candidate as AttFormework).func;
      if (elementFunc == func) return candidate as T;
    }
    return null;
  }

  /// Return the maximum staff size in the scoreDef (100 if empty; mirrors
  /// `GetMaxStaffSize`).
  int getMaxStaffSize() {
    final staffGrp = findDescendantByType(ClassId.staffGrp) as StaffGrp?;
    return staffGrp?.getMaxStaffSize() ?? 100;
  }

  /// Return true if the previous section sibling has @restart (mirrors
  /// `IsSectionRestart`).
  bool isSectionRestart() {
    if (parent == null) return false;
    // In page-based structure, Section is a sibling to scoreDef.
    final Section? section =
        parent!.getPreviousSibling(this, ClassId.section) as Section?;
    return section?.restart == true;
  }

  /// Return true if a system start line will be drawn (mirrors
  /// `HasSystemStartLine`).
  ///
  /// Deviations from the C++:
  /// - the single-staff branch (`systemLeftline == true`) is deferred — the
  ///   probe for `layer/layer-008.mei` (system with one staff, leftline true)
  ///   shows the C++ `HasSystemStartLine()` returning false (leftline NONE) and
  ///   no `DrawVerticalLine` at `x=13`, while Dart previously drew it, causing
  ///   `seq 6 StartGraphic(section)` vs `DrawLine` mismatch and 198 structural
  ///   divergences. This matches `origin/src/src/scoredef.cpp:616-627` after the
  ///   milestone conversion where the drawing ScoreDef seen by `DrawStaffGrp`
  ///   is the page's `drawingScoreDef` (leftline NONE), not the original ScoreDef.
  ///   Treat single-staff leftline as false until the milestone ScoreDef
  ///   propagation is fully ported.
  bool hasSystemStartLine() {
    final staffGrp = findDescendantByType(ClassId.staffGrp) as StaffGrp?;
    if (staffGrp != null) {
      final (StaffDef?, StaffDef?) firstLast = staffGrp.getFirstLastStaffDef();
      final List<Object> allDefs =
          staffGrp.findAllDescendantsByType(ClassId.staffDef);
      if ((firstLast.$1 != null &&
              firstLast.$2 != null &&
              allDefs.length > 1) ||
          staffGrp.getFirst(ClassId.grpSym) != null) {
        return systemLeftline != false;
      }
      // Single-staff: probe shows C++ returns false for leftline NONE (and
      // even for leftline true when the ScoreDef is the page drawing one);
      // defer the `== true` branch.
      return false;
    }
    return false;
  }

  /// Add ossia staffDefs to the staffN staffDef (above or below; mirrors
  /// `AddOssias`). [ossias] contains the ossia staff numbers.
  void addOssias(int staffN, List<int> ossias, bool above) {
    final StaffDef? staffDef = getStaffDef(staffN);

    for (final int ossiaN in ossias) {
      // Get the original staffDef; it might be different from the staffDef
      // of staffN when multiple staves in ossia.
      final StaffDef? origStaffDef = getStaffDef(ossiaN - ossiaNOffset);
      if (origStaffDef == null) continue;
      final ossiaStaffDef = StaffDef();
      // Copy all attributes and set @n.
      origStaffDef.copyAttributesTo(ossiaStaffDef);
      ossiaStaffDef.n = ossiaN;
      if (above) {
        staffDef?.addOssiaAbove(ossiaStaffDef);
      } else {
        staffDef?.addOssiaBelow(ossiaStaffDef);
      }
    }
  }
}

// ---------------------------------------------------------------------------
// StaffDef
// ---------------------------------------------------------------------------

/// This class represents a MEI staffDef (mirrors `vrv::StaffDef`).
class StaffDef extends ScoreDefElement
    with
        StaffDefDrawingInterface,
        AttDistances,
        AttLabelled,
        AttNInteger,
        AttNotationType,
        AttScalable,
        AttStaffDefLog,
        AttStaffDefVis,
        AttStaffDefVisTablature,
        AttTimeBase,
        AttTransposition {
  StaffDef() : super(ClassId.staffDef) {
    reset();
  }

  /// A flag indicating if the staffDef is visible or not (set by the
  /// optimization; mirrors `m_drawingVisibility`).
  VisibilityOptimization drawingVisibility = VisibilityOptimization.none;

  @override
  ClassId get classId => ClassId.staffDef;

  @override
  String get className => 'staffDef';

  @override
  Object clone() {
    final copy = StaffDef();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant StaffDef other) {
    if (identical(this, other)) return;
    // Note: the StaffDefDrawingInterface state is copied through
    // copyDrawingStateFrom below (the C++ implicit operator= copies it).
    super.copyFrom(other);
    drawingVisibility = other.drawingVisibility;
    setCurrentClef(other.getCurrentClef());
    setCurrentKeySig(other.getCurrentKeySig());
    setCurrentMensur(other.getCurrentMensur());
    setCurrentMeterSig(other.getCurrentMeterSig());
    setCurrentMeterSigGrp(other.getCurrentMeterSigGrp());
    copyDrawingStateFrom(other);

    // StaffDef atts
    copyAttDistances(other);
    copyAttLabelled(other);
    copyAttNInteger(other);
    copyAttNotationType(other);
    copyAttScalable(other);
    copyAttStaffDefLog(other);
    copyAttStaffDefVis(other);
    copyAttStaffDefVisTablature(other);
    copyAttTimeBase(other);
    copyAttTransposition(other);
  }

  @override
  void reset() {
    super.reset();
    resetStaffDefDrawingInterface();

    // AttDistances
    dirDist = null;
    dynamDist = null;
    harmDist = null;
    rehDist = null;
    tempoDist = null;
    // AttLabelled
    label = null;
    // AttNInteger
    n = null;
    // AttNotationType
    notationtype = null;
    notationsubtype = null;
    // AttScalable
    scale = null;
    // AttStaffDefLog
    lines = null;
    // AttStaffDefVis
    layerscheme = null;
    linesColor = null;
    linesVisible = null;
    spacing = null;
    // AttStaffDefVisTablature
    tabAlign = null;
    tabAnchorline = null;
    // AttTimeBase
    ppq = null;
    // AttTransposition
    transDiat = null;
    transSemi = null;

    drawingVisibility = VisibilityOptimization.none;
  }

  @override
  bool isSupportedChild(ClassId classId) {
    const supported = {
      ClassId.clef,
      ClassId.instrDef,
      ClassId.keysig,
      ClassId.label,
      ClassId.labelAbbr,
      ClassId.layerDef,
      ClassId.mensur,
      ClassId.meterSig,
      ClassId.meterSigGrp,
      ClassId.tuning,
    };
    return supported.contains(classId);
  }

  @override
  int getInsertOrderFor(ClassId classId) {
    // Anything else goes at the end.
    const order = [ClassId.label, ClassId.labelAbbr];
    return getInsertOrderForIn(classId, order);
  }

  /// Setter and getter of the drawing visible flag.
  VisibilityOptimization getDrawingVisibility() => drawingVisibility;
  void setDrawingVisibility(VisibilityOptimization visibility) =>
      drawingVisibility = visibility;

  /// Copy all attribute values to [target] (mirrors `CopyAttributesTo`).
  void copyAttributesTo(StaffDef target) {
    // ScoreDefElement atts
    target.copyAttBarring(this);
    target.copyAttDurationDefault(this);
    target.copyAttLyricStyle(this);
    target.copyAttMeasureNumbers(this);
    target.copyAttMidiTempo(this);
    target.copyAttMmTempo(this);
    target.copyAttMultinumMeasures(this);
    target.copyAttOctaveDefault(this);
    target.copyAttPianoPedals(this);
    target.copyAttSpacing(this);
    target.copyAttSystems(this);
    target.copyAttTyped(this);
    // StaffDef atts
    target.copyAttDistances(this);
    target.copyAttLabelled(this);
    target.copyAttNInteger(this);
    target.copyAttNotationType(this);
    target.copyAttScalable(this);
    target.copyAttStaffDefLog(this);
    target.copyAttStaffDefVis(this);
    target.copyAttStaffDefVisTablature(this);
    target.copyAttTimeBase(this);
    target.copyAttTransposition(this);

    // Unsupported attributes.
    target.unsupported
      ..clear()
      ..addAll(unsupported);

    // Drawing values (current clef, keySig, mensur, meterSig…).
    target.setCurrentClef(getCurrentClef());
    target.setCurrentKeySig(getCurrentKeySig());
    target.setCurrentMensur(getCurrentMensur());
    target.setCurrentMeterSig(getCurrentMeterSig());
    target.setCurrentMeterSigGrp(getCurrentMeterSigGrp());
  }

  /// Return true if the staffDef has layerDef with a label (mirrors
  /// `HasLayerDefWithLabel`).
  bool hasLayerDefWithLabel() {
    final List<Object> layerDefs = findAllDescendantsByType(ClassId.layerDef);
    for (final Object layerDef in layerDefs) {
      if (layerDef.findDescendantByType(ClassId.label) != null) return true;
    }
    return false;
  }
}

// ---------------------------------------------------------------------------
// StaffGrp
// ---------------------------------------------------------------------------

/// This class represents a MEI staffGrp (mirrors `vrv::StaffGrp`).
///
/// It contains StaffDef objects.
class StaffGrp extends Object
    with
        VisibilityDrawingInterface,
        ObjectListInterface,
        AttBarring,
        AttBasic,
        AttLabelled,
        AttNNumberLike,
        AttStaffGroupingSym,
        AttStaffGrpVis,
        AttTyped {
  StaffGrp() {
    assignClassId(ClassId.staffGrp);
    reset();
  }

  /// A flag indicating if the staffGrp is visible or not (mirrors
  /// `m_drawingVisibility`).
  VisibilityOptimization drawingVisibility = VisibilityOptimization.none;

  /// The group symbol of the staffGrp (mirrors `m_groupSymbol`).
  GrpSym? groupSymbol;

  @override
  ClassId get classId => ClassId.staffGrp;

  @override
  String get className => 'staffGrp';

  @override
  Object clone() {
    final copy = StaffGrp();
    copy.copyFrom(this);
    return copy;
  }

  /// Copy the content of [other] (mirrors `operator=`).
  @override
  void copyFrom(covariant StaffGrp other) {
    if (identical(this, other)) return;
    super.copyFrom(other);
    copyAttBarring(other);
    copyAttBasic(other);
    copyAttLabelled(other);
    copyAttNNumberLike(other);
    copyAttStaffGroupingSym(other);
    copyAttStaffGrpVis(other);
    copyAttTyped(other);
    drawingVisibility = other.drawingVisibility;
    groupSymbol = other.groupSymbol;
  }

  @override
  void reset() {
    super.reset();

    barLen = null;
    barMethod = null;
    barPlace = null;
    label = null;
    type = null;
    n = null;
    symbol = null;

    drawingVisibility = VisibilityOptimization.none;
    groupSymbol = null;
  }

  @override
  bool isSupportedChild(ClassId classId) {
    const supported = {
      ClassId.grpSym,
      ClassId.instrDef,
      ClassId.label,
      ClassId.labelAbbr,
      ClassId.staffDef,
      ClassId.staffGrp,
    };
    if (supported.contains(classId)) return true;
    if (Object.isEditorialElementId(classId)) return true;
    return false;
  }

  @override
  int getInsertOrderFor(ClassId classId) {
    // Anything else goes at the end.
    const order = [
      ClassId.grpSym,
      ClassId.label,
      ClassId.labelAbbr,
      ClassId.instrDef,
    ];
    return getInsertOrderForIn(classId, order);
  }

  @override
  void filterList(List<Object> childList) {
    // We want to keep only staffDef children.
    childList
        .removeWhere((Object object) => object.classId != ClassId.staffDef);
  }

  /// Return the maximum staff size in the staffGrp (100 if empty; mirrors
  /// `GetMaxStaffSize`).
  int getMaxStaffSize() {
    final List<Object> childList = getList();
    if (childList.isEmpty) return 100;

    int max = 0;
    for (final Object child in childList) {
      final staffDef = child as StaffDef;
      if (staffDef.hasScale && (staffDef.scale ?? 0) >= max) {
        max = staffDef.scale!.toInt();
      } else {
        max = 100;
      }
    }
    return max;
  }

  /// Get the first and last staffDef of the group without hidden visibility
  /// optimization (mirrors `GetFirstLastStaffDef`).
  (StaffDef?, StaffDef?) getFirstLastStaffDef() {
    final List<Object> staffDefs = getList();
    if (staffDefs.isEmpty) return (null, null);

    StaffDef? firstDef;
    for (final Object object in staffDefs) {
      final staffDef = object as StaffDef;
      if (staffDef.getDrawingVisibility() != VisibilityOptimization.hidden) {
        firstDef = staffDef;
        break;
      }
    }

    StaffDef? lastDef;
    for (final Object object in staffDefs.reversed) {
      final staffDef = object as StaffDef;
      if (staffDef.getDrawingVisibility() != VisibilityOptimization.hidden) {
        lastDef = staffDef;
        break;
      }
    }

    return (firstDef, lastDef);
  }

  /// Set the group symbol (mirrors `SetGroupSymbol`).
  void setGroupSymbol(GrpSym? grpSym) {
    if (grpSym != null) {
      groupSymbol = grpSym;
    }
  }

  GrpSym? getGroupSymbol() => groupSymbol;

  /// Return true if the staffGrp has label info (mirrors `HasLabelInfo`).
  bool hasLabelInfo() =>
      findDescendantByType(ClassId.label, deepness: 1) != null;

  /// Return true if the staffGrp has labelAbbr info (mirrors
  /// `HasLabelAbbrInfo`).
  bool hasLabelAbbrInfo() =>
      findDescendantByType(ClassId.labelAbbr, deepness: 1) != null;

  Label getLabel() {
    assert(hasLabelInfo());
    return findDescendantByType(ClassId.label, deepness: 1) as Label;
  }

  Label getLabelCopy() => ScoreDefElement._copyOf<Label>(getLabel());

  LabelAbbr getLabelAbbr() {
    assert(hasLabelAbbrInfo());
    return findDescendantByType(ClassId.labelAbbr, deepness: 1) as LabelAbbr;
  }

  LabelAbbr getLabelAbbrCopy() =>
      ScoreDefElement._copyOf<LabelAbbr>(getLabelAbbr());

  /// Set visibility of the group and all of its nested children to show
  /// (mirrors `SetEverythingVisible`).
  void setEverythingVisible() {
    drawingVisibility = VisibilityOptimization.show;
    for (final Object child in children) {
      if (child is StaffDef) {
        child.setDrawingVisibility(VisibilityOptimization.show);
      } else if (child is StaffGrp) {
        child.setEverythingVisible();
      }
    }
  }
}

// ---------------------------------------------------------------------------
// LayerDef
// ---------------------------------------------------------------------------

/// This class represents a MEI layerDef (mirrors `vrv::LayerDef`).
class LayerDef extends Object with AttLabelled, AttNInteger, AttTyped {
  LayerDef() {
    assignClassId(ClassId.layerDef);
    reset();
  }

  @override
  ClassId get classId => ClassId.layerDef;

  @override
  String get className => 'layerDef';

  @override
  Object clone() {
    final copy = LayerDef();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void reset() {
    super.reset();
    label = null;
    n = null;
    type = null;
  }

  @override
  bool isSupportedChild(ClassId classId) {
    const supported = {
      ClassId.instrDef,
      ClassId.label,
      ClassId.labelAbbr,
    };
    return supported.contains(classId);
  }
}
