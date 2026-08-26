/// Port of `resetfunctor.h/cpp` — the functors that reset the drawing state
/// of a document before (re-)running the layout preparation.
///
/// This library contains the full [ResetDataFunctor] port. The horizontal /
/// vertical alignment reset functors of the C++ file arrive with the layout
/// orchestration phases that drive them.
///
/// The interface resets (`XxxInterface::InterfaceResetData`) are performed
/// inline in [ResetDataFunctor.visitObject] and in the typed visits, mirroring
/// the C++ dispatch through the interface pseudo functors.
library;

import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/layout/functor.dart';
import 'package:verovio_dart/src/model/atts/mei_enums.dart';
import 'package:verovio_dart/src/model/basic_elements.dart';
import 'package:verovio_dart/src/model/control_element.dart';
import 'package:verovio_dart/src/model/control_elements_gen.dart';
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/model/editorial_element.dart';
import 'package:verovio_dart/src/model/floating_object.dart';
import 'package:verovio_dart/src/model/interfaces/facsimile_interface.dart';
import 'package:verovio_dart/src/model/interfaces/linking_interface.dart';
import 'package:verovio_dart/src/model/interfaces/plist_interface.dart';
import 'package:verovio_dart/src/model/interfaces/position_interface.dart';
import 'package:verovio_dart/src/model/interfaces/simple_interfaces.dart';
import 'package:verovio_dart/src/model/interfaces/time_interface.dart';
import 'package:verovio_dart/src/model/layer_element.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart';
import 'package:verovio_dart/src/model/misc_elements_gen.dart';
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/model/scoredef.dart';
import 'package:verovio_dart/src/model/system_page_elements.dart';

/// Reset the drawing data of the tree (mirrors `vrv::ResetDataFunctor`).
///
/// The functor is run over the whole document when the preparation has to be
/// re-done (see `Doc::PrepareData`) or by `Doc::ResetData`.
class ResetDataFunctor extends Functor {
  @override
  FunctorCode visitAccid(Accid accid) {
    // Call parent one too.
    visitLayerElement(accid);
    // PositionInterface::InterfaceResetData.
    (accid as PositionInterface).drawingLoc = 0;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitArtic(Artic artic) {
    // Call parent one too.
    visitLayerElement(artic);

    artic.drawingPlace = Staffrel.none;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitBeam(Beam beam) {
    // Call parent one too.
    visitLayerElement(beam);
    // Drawing interface functor to be called explicitly.
    beam.resetDrawingInterface();

    beam.stemSameasBeam = null;

    // We want the list of the ObjectListInterface to be regenerated.
    beam.modify();

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitBeamSpan(BeamSpan beamSpan) {
    // Call parent one too.
    visitControlElement(beamSpan);
    // Drawing interface functor to be called explicitly.
    beamSpan.resetDrawingInterface();

    beamSpan.resetBeamedElements();
    beamSpan.clearBeamSegments();
    beamSpan.initBeamSegments();

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitChord(Chord chord) {
    // Call parent one too.
    visitLayerElement(chord);
    // Drawing interface functor to be called explicitly.
    chord.resetStemmedDrawingInterface();

    // We want the list of the ObjectListInterface to be regenerated.
    chord.modify();

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitControlElement(ControlElement controlElement) {
    // Call parent one too.
    visitFloatingObject(controlElement);

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitCustos(Custos custos) {
    // Call parent one too.
    visitLayerElement(custos);
    // PositionInterface::InterfaceResetData.
    (custos as PositionInterface).drawingLoc = 0;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitDiv(Div div) {
    // Call parent one too.
    visitObject(div);

    div.setDrawingInline(inline: false);

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitDot(Dot dot) {
    // Call parent one too.
    visitLayerElement(dot);
    // PositionInterface::InterfaceResetData.
    (dot as PositionInterface).drawingLoc = 0;

    dot.drawingPreviousElement = null;
    dot.drawingNextElement = null;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitDots(Dots dots) {
    // Call parent one too.
    visitLayerElement(dots);

    dots.resetMapOfDotLocs();
    dots.setIsAdjusted(adjusted: false);

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitEditorialElement(EditorialElement editorialElement) {
    // Call parent one too.
    visitObject(editorialElement);

    // SystemMilestoneInterface::InterfaceResetData.
    editorialElement.drawingMeasure = null;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitEnding(Ending ending) {
    visitFloatingObject(ending);
    ending.drawingMeasure = null;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitF(F f) {
    visitTextElement(f);
    // TimeSpanningInterface::InterfaceResetData.
    _resetTimeSpanning(f as TimeSpanningInterface);

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitFlag(Flag flag) {
    visitLayerElement(flag);

    flag.drawingNbFlags = 0;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitFloatingObject(FloatingObject floatingObject) {
    // Call parent one too.
    visitObject(floatingObject);

    floatingObject.resetDrawing();
    floatingObject.drawingGrpId = 0;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitFTrem(FTrem fTrem) {
    // Call parent one too.
    visitLayerElement(fTrem);
    // Drawing interface functor to be called explicitly.
    fTrem.resetDrawingInterface();

    // We want the list of the ObjectListInterface to be regenerated.
    fTrem.modify();

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitHairpin(Hairpin hairpin) {
    // Call parent one too.
    visitControlElement(hairpin);

    hairpin.setLeftLink(null);
    hairpin.setRightLink(null);
    hairpin.setDrawingLength(0);

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitKeySig(KeySig keySig) {
    visitLayerElement(keySig);

    keySig.resetDrawingClef();

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitLayer(Layer layer) {
    // Call parent one too.
    visitObject(layer);
    // DrawingListInterface::InterfaceResetData regenerates the drawing list
    // lazily; nothing explicit to do here.

    layer.setCrossStaffFromAbove(false);
    layer.setCrossStaffFromBelow(false);

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitLayerElement(LayerElement layerElement) {
    // Call parent one too.
    visitObject(layerElement);

    layerElement.isInBeamSpan = false;
    layerElement.drawingCueSize = false;
    layerElement.crossStaff = null;
    layerElement.crossLayer = null;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitLigature(Ligature ligature) {
    // Call parent one too.
    visitLayerElement(ligature);

    ligature.drawingShapes.clear();

    // We want the list of the ObjectListInterface to be regenerated.
    ligature.modify();

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitMeasure(Measure measure) {
    // Call parent one too.
    visitObject(measure);

    measure.timestampAligner.reset();
    measure.setDrawingEnding(null);

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitMRest(MRest mRest) {
    // Call parent one too.
    visitLayerElement(mRest);

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitNote(Note note) {
    // Call parent one too.
    visitLayerElement(note);
    // StemmedDrawingInterface::InterfaceResetData.
    note.resetStemmedDrawingInterface();

    (note as PositionInterface).drawingLoc = 0;
    note.flippedNotehead = false;
    note.stemSameasNote = null;
    note.stemSameasRole = StemSameasDrawingRole.none;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitNc(Nc nc) {
    // Call parent one too.
    visitLayerElement(nc);

    nc.drawingGlyphs.clear();

    // We want the list of the ObjectListInterface to be regenerated.
    nc.modify();

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitObject(Object object) {
    // Deviation note: the C++ looks the interfaces up through
    // HasInterface/GetXxxInterface pairs; here we rely on `is` checks since
    // some classes register interface ids without applying the mixin.
    // AltSymInterface::InterfaceResetData.
    if (object is AltSymInterface) {
      final AltSymInterface interface = object as AltSymInterface;
      interface.altSymbolDef = null;
      interface.altSymbolDefID = '';
    }
    // FacsimileInterface::InterfaceResetData.
    if (object is FacsimileInterface) {
      final FacsimileInterface interface = object as FacsimileInterface;
      interface.zone = null;
      interface.surface = null;
    }
    // LinkingInterface::InterfaceResetData (keeps the resolved links).
    if (object is LinkingInterface) {
      final LinkingInterface interface = object as LinkingInterface;
      interface.next = null;
      interface.nextID = '';
      interface.sameas = null;
      interface.sameasID = '';
    }
    // OffsetInterface / OffsetSpanningInterface::InterfaceResetData are
    // no-ops in the C++.
    // PlistInterface::InterfaceResetData.
    if (object is PlistInterface) {
      final PlistInterface interface = object as PlistInterface;
      interface.ids.clear();
      interface.references.clear();
    }
    // PositionInterface::InterfaceResetData is handled in the typed visits
    // for accid / custos / dot; do it here as well for the other position
    // holders (rest, mRest, nc, strophicus…).
    if (object is PositionInterface) {
      final PositionInterface interface = object as PositionInterface;
      interface.drawingLoc = 0;
    }
    // TimePointInterface / TimeSpanningInterface::InterfaceResetData.
    if (object is TimeSpanningInterface) {
      _resetTimeSpanning(object as TimeSpanningInterface);
    } else if (object is TimePointInterface) {
      final TimePointInterface timePoint = object as TimePointInterface;
      timePoint.start = null;
      timePoint.startID = '';
    }
    if (object.hasPlistReferences) object.resetPlistReferences();

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitPage(Page page) {
    // Call parent one too.
    visitObject(page);

    page.layoutDone = false;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitRepeatMark(RepeatMark repeatMark) {
    // Call parent one too.
    visitControlElement(repeatMark);

    // For now doing nothing, but we should eventually remove generated text
    // when the @func is not 'fine' anymore.

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitRest(Rest rest) {
    // Call parent one too.
    visitLayerElement(rest);

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitSection(Section section) {
    // Call parent one too.
    visitFloatingObject(section);

    if (section.isSystemMilestone()) {
      section.drawingMeasure = null;
    }

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitSlur(Slur slur) {
    // Call parent one too.
    visitControlElement(slur);

    slur.setDrawingCurveDir(SlurCurveDirection.none);

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitStaff(Staff staff) {
    // Call parent one too.
    visitObject(staff);

    staff.timeSpanningElements.clear();
    staff.clearLedgerLines();

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitStaffDef(StaffDef staffDef) {
    // Call parent one too.
    visitObject(staffDef);
    // StaffDefDrawingInterface::InterfaceResetData.
    staffDef.resetStaffDefDrawingInterface();

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitStem(Stem stem) {
    // Call parent one too.
    visitLayerElement(stem);

    stem.setDrawingStemDir(Stemdirection.none);
    stem.setDrawingStemLen(0);

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitSyl(Syl syl) {
    // Call parent one too.
    visitLayerElement(syl);

    syl.nextWordSyl = null;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitSystem(System system) {
    // Call parent one too.
    visitObject(system);
    // DrawingListInterface::InterfaceResetData.

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitSystemMilestone(SystemMilestoneEnd systemMilestoneEnd) {
    visitFloatingObject(systemMilestoneEnd);

    systemMilestoneEnd.measure = null;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitTabDurSym(TabDurSym tabDurSym) {
    // Call parent one too.
    visitLayerElement(tabDurSym);
    // StemmedDrawingInterface::InterfaceResetData.
    tabDurSym.resetStemmedDrawingInterface();

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitTempo(Tempo tempo) {
    // Call parent one too.
    visitControlElement(tempo);

    tempo.resetDrawingXRelative();

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitTuplet(Tuplet tuplet) {
    // Call parent one too.
    visitLayerElement(tuplet);

    // We want the list of the ObjectListInterface to be regenerated.
    tuplet.modify();

    tuplet.drawingLeft = null;
    tuplet.drawingRight = null;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitTurn(Turn turn) {
    // Call parent one too.
    visitControlElement(turn);

    turn.drawingEndElement = null;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitVerse(Verse verse) {
    // Call parent one too.
    visitLayerElement(verse);

    verse.drawingLabelAbbr = null;

    return FunctorCode.continue_;
  }

  /// Mirror of `TimeSpanningInterface::InterfaceResetData` including the
  /// base-class call.
  void _resetTimeSpanning(TimeSpanningInterface interface) {
    interface.end = null;
    interface.endID = '';
    interface.start = null;
    interface.startID = '';
  }
}
