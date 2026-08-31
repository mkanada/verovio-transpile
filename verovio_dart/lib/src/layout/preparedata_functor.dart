/// Port of `preparedatafunctor.h/cpp` and of the headless subset of the Calc*
/// drawing functors that share its role (`calcstemfunctor.cpp`,
/// `calcarticfunctor.cpp`, `calcdotsfunctor.cpp`,
/// `calcchordnoteheadsfunctor.cpp`, `calcslurdirectionfunctor.cpp`).
///
/// The preparation functors resolve the encoded relationships (@startid /
/// @endid / @tstamp / @next / @plist / cross-staff …) and instantiate the
/// layer element parts (stem, flag, dots, tuplet bracket…). They are driven
/// by [Doc.prepareData] following the exact C++ order.
///
/// Deviations for the Calc* functors: the C++ runs them from
/// `Page::ResetAligners` during the rendering layout with glyph metrics and
/// staff drawing positions available. Since this port has no render pass,
/// they are driven at the end of `Doc.prepareData` and use a headless
/// equivalent of the geometry (staff-relative locations instead of absolute
/// Y positions; stem length without glyph-based shortening; beam segments
/// deferred to the horizontal layout phase).
library;

import 'package:verovio_dart/src/core/attdef.dart';
import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/utils.dart' show extractIDFragment;
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/layout/functor.dart';
import 'package:verovio_dart/src/model/atts/atts_cmn.dart';
import 'package:verovio_dart/src/model/atts/atts_shared.dart';
import 'package:verovio_dart/src/model/atts/atts_visual.dart';
import 'package:verovio_dart/src/model/atts/mei_enums.dart';
import 'package:verovio_dart/src/model/text_elements.dart'
    show TextElement, TextLayoutElement;
import 'package:verovio_dart/src/model/atts/mei_values.dart'
    show MeasureBeat, MeasurementSigned;
import 'package:verovio_dart/src/model/basic_elements.dart';
import 'package:verovio_dart/src/model/control_elements_gen.dart';
import 'package:verovio_dart/src/model/drawing_interfaces.dart'
    show StemmedDrawingInterface, SystemMilestoneInterface;
import 'package:verovio_dart/src/model/comparison.dart';
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/model/editorial_element.dart';
import 'package:verovio_dart/src/model/interfaces/duration_interface.dart';
import 'package:verovio_dart/src/model/interfaces/facsimile_interface.dart';
import 'package:verovio_dart/src/model/interfaces/linking_interface.dart';
import 'package:verovio_dart/src/model/interfaces/plist_interface.dart';
import 'package:verovio_dart/src/model/interfaces/pitch_interface.dart';
import 'package:verovio_dart/src/model/interfaces/position_interface.dart';
import 'package:verovio_dart/src/model/interfaces/simple_interfaces.dart';
import 'package:verovio_dart/src/model/interfaces/time_interface.dart';
import 'package:verovio_dart/src/model/layer_element.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart';
import 'package:verovio_dart/src/model/floating_object.dart';
import 'package:verovio_dart/src/model/misc_elements_gen.dart';
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/model/scoredef.dart';
import 'package:verovio_dart/src/model/system_page_elements.dart';
import 'package:verovio_dart/src/model/zone.dart' show Zone;

// ---------------------------------------------------------------------------
// PrepareDataInitializationFunctor
// ---------------------------------------------------------------------------

/// Initialization of the data at the beginning of the preparation (mirrors
/// `vrv::PrepareDataInitializationFunctor`).
class PrepareDataInitializationFunctor extends DocFunctor {
  PrepareDataInitializationFunctor(super.doc);

  @override
  FunctorCode visitChord(Chord chord) {
    // Call parent one too.
    visitObject(chord);

    if (chord.hasEmptyList()) {
      logWarning(
          "Chord '${chord.id}' has no child note - a default note is added");
      final Note rescueNote = Note();
      chord.addChild(rescueNote);
    }
    chord.modify();

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitDiv(Div div) {
    // Call parent one too.
    visitTextLayoutElement(div);

    // Deviation: the breaks option is not part of the option shell yet; the
    // C++ sets the inline drawing only for breaks='none'.

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitKeySig(KeySig keySig) {
    // Call parent one too.
    visitObject(keySig);

    // Clear and regenerate attribute children.
    keySig.generateKeyAccidAttribChildren();

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitRepeatMark(RepeatMark repeatMark) {
    // Call parent one too.
    visitControlElement(repeatMark);

    if (repeatMark.childCount == 0 &&
        repeatMark.hasFunc &&
        repeatMark.func == RepeatmarklogFunc.fine) {
      final Text fine = Text();
      fine.isGenerated = true;
      fine.text = 'Fine';
      repeatMark.addChild(fine);
    }

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitScore(Score score) {
    // Call parent one too.
    visitPageElement(score);

    assert(score.getScoreDef() != null);

    // Evaluate functor on scoreDef.
    score.getScoreDef()?.process(this);

    return FunctorCode.continue_;
  }

  /// Port of `PrepareDataInitializationFunctor::VisitTextLayoutElement`
  /// (preparedatafunctor.cpp:149).
  @override
  FunctorCode visitTextLayoutElement(TextLayoutElement textLayoutElement) {
    visitObject(textLayoutElement);

    textLayoutElement.resetCells();
    textLayoutElement.resetDrawingScaling();

    final childList = textLayoutElement.getList();
    for (final child in childList) {
      final AreaPosInterface areaPos = child as AreaPosInterface;
      final Horizontalalignment halign =
          areaPos.halign ?? Horizontalalignment.none;
      final Verticalalignment valign =
          areaPos.valign ?? Verticalalignment.none;
      final int pos = textLayoutElement.getAlignmentPos(halign, valign);
      final TextElement text = child as TextElement;
      textLayoutElement.appendTextToCell(pos, text);
    }

    return FunctorCode.continue_;
  }
}

// ---------------------------------------------------------------------------
// PrepareCueSizeFunctor
// ---------------------------------------------------------------------------

/// Resolve the cue size of each layer element (mirrors
/// `vrv::PrepareCueSizeFunctor`).
class PrepareCueSizeFunctor extends Functor {
  @override
  FunctorCode visitLayerElement(LayerElement layerElement) {
    if (layerElement.isScoreDefElement) return FunctorCode.siblings;

    final Layer? currentLayer =
        layerElement.getFirstAncestor(ClassId.layer) as Layer?;
    assert(currentLayer != null);
    if (currentLayer?.cue == true) {
      layerElement.drawingCueSize = true;
      return FunctorCode.continue_;
    }

    if (layerElement.isGraceNote()) {
      layerElement.drawingCueSize = true;
    }
    // This covers the case when the @size is given on the element.
    else if (layerElement is AttCue) {
      final AttCue att = layerElement as AttCue;
      if (att.hasCue) layerElement.drawingCueSize = att.cue == true;
    }
    // For note, we also need to look at the parent chord.
    else if (layerElement.classId == ClassId.note) {
      final Note note = layerElement as Note;
      final Chord? chord = note.isChordTone() as Chord?;
      if (chord != null) note.drawingCueSize = chord.drawingCueSize;
    }
    // For tuplet, we also need to look at the first note or chord.
    else if (layerElement.classId == ClassId.tuplet) {
      final matchType = ClassIdsComparison([ClassId.note, ClassId.chord]);
      final Object? child =
          (layerElement as Tuplet).findDescendantByComparison(matchType);
      if (child is LayerElement) {
        layerElement.drawingCueSize = child.drawingCueSize;
      }
    }
    // For accid, look at the parent if @func="edit" or otherwise to the
    // parent note.
    else if (layerElement.classId == ClassId.accid) {
      final Accid accid = layerElement as Accid;
      if (accid.func == AccidlogFunc.edit) {
        accid.drawingCueSize = true;
      } else {
        final Note? note = accid.getFirstAncestor(ClassId.note) as Note?;
        if (note != null) accid.drawingCueSize = note.drawingCueSize;
      }
    } else if (layerElement
        .isAny({ClassId.artic, ClassId.dots, ClassId.flag, ClassId.stem})) {
      final Note? note =
          layerElement.getFirstAncestor(ClassId.note, maxNoteDepth) as Note?;
      if (note != null) {
        layerElement.drawingCueSize = note.drawingCueSize;
      } else {
        final Chord? chord =
            layerElement.getFirstAncestor(ClassId.chord) as Chord?;
        if (chord != null) layerElement.drawingCueSize = chord.drawingCueSize;
      }
    }

    return FunctorCode.continue_;
  }
}

// ---------------------------------------------------------------------------
// PrepareCrossStaffFunctor
// ---------------------------------------------------------------------------

/// Set the cross-staff / cross-layer pointers of the layer elements (mirrors
/// `vrv::PrepareCrossStaffFunctor`).
class PrepareCrossStaffFunctor extends Functor {
  Measure? currentMeasure;
  Staff? currentCrossStaff;
  Layer? currentCrossLayer;

  @override
  FunctorCode visitLayerElement(LayerElement layerElement) {
    if (layerElement.isScoreDefElement) return FunctorCode.siblings;

    layerElement.crossStaff = null;
    layerElement.crossLayer = null;

    // Look for cross-staff situations. If we have one, make it available in
    // m_crossStaff.
    final AttStaffIdent? crossElement =
        layerElement is AttStaffIdent ? layerElement as AttStaffIdent : null;
    if (crossElement == null) return FunctorCode.continue_;

    // If we have not @staff, set to what we had before (quite likely NULL
    // for all non cross-staff cases).
    if (!crossElement.hasStaff) {
      layerElement.crossStaff = currentCrossStaff;
      layerElement.crossLayer = currentCrossLayer;
      return FunctorCode.continue_;
    }

    // We have a @staff, set the current pointers to NULL before assigning
    // them.
    currentCrossStaff = null;
    currentCrossLayer = null;

    final comparisonFirst =
        AttNIntegerComparison(ClassId.staff, crossElement.staff!.first);
    layerElement.crossStaff = currentMeasure!
        .findDescendantByComparison(comparisonFirst, deepness: 1) as Staff?;
    if (layerElement.crossStaff == null) {
      logWarning("Could not get the cross staff reference "
          "'${crossElement.staff!.first}' for element '${layerElement.id}'");
      return FunctorCode.continue_;
    }

    final Staff parentStaff = _getAncestorStaff(layerElement);
    // Check if we have a cross-staff to itself...
    if (identical(layerElement.crossStaff, parentStaff)) {
      logWarning("The cross staff reference '${crossElement.staff!.first}' for "
          "element '${layerElement.id}' seems to be identical to the parent "
          'staff');
      layerElement.crossStaff = null;
      return FunctorCode.continue_;
    }

    final Layer? parentLayer =
        layerElement.getFirstAncestor(ClassId.layer) as Layer?;
    assert(parentLayer != null);
    // Now try to get the corresponding layer - for now look for the same
    // layer @n.
    final int layerN = parentLayer?.n ?? 0;
    final comparisonFirstLayer = AttNIntegerComparison(ClassId.layer, layerN);
    final bool direction =
        ((parentStaff.n ?? 0) < ((layerElement.crossStaff as Staff).n ?? 0))
            ? forward
            : backward;
    Layer? crossLayer = (layerElement.crossStaff as Staff)
            .findDescendantByComparison(comparisonFirstLayer, deepness: 1)
        as Layer?;
    crossLayer ??= (layerElement.crossStaff as Staff)
        .findDescendantByType(ClassId.layer, direction: direction) as Layer?;
    if (crossLayer == null) {
      // Nothing we can do.
      logWarning("Could not get the layer with cross-staff reference "
          "'${crossElement.staff!.first}' for element '${layerElement.id}'");
      layerElement.crossStaff = null;
    } else {
      if (direction == forward) {
        crossLayer.setCrossStaffFromAbove(true);
      } else {
        crossLayer.setCrossStaffFromBelow(true);
      }
    }
    layerElement.crossLayer = crossLayer;

    currentCrossStaff = layerElement.crossStaff;
    currentCrossLayer = layerElement.crossLayer;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitLayerElementEnd(LayerElement layerElement) {
    if (layerElement.isScoreDefElement) return FunctorCode.siblings;

    final DurationInterface? durInterface = layerElement is DurationInterface
        ? layerElement as DurationInterface
        : null;
    if (durInterface != null) {
      // If we have @staff, reset it to NULL - this can be problematic if we
      // have different @staff attributes in the children of one element. We
      // do not consider this now because it seems over the top.
      if (durInterface.hasStaff) {
        currentCrossStaff = null;
        currentCrossLayer = null;
      }
    } else if (layerElement.isAny({
      ClassId.beam,
      ClassId.bTrem,
      ClassId.fTrem,
      ClassId.tuplet,
    })) {
      // For other elements (e.g., beams, tuplets) check if all their child
      // duration elements are cross-staff. If yes, make them cross-staff
      // themselves.
      final durations = InterfaceComparison(InterfaceId.duration);
      final List<Object> objects =
          layerElement.findAllDescendantsMatching(durations);
      Staff? crossStaff;
      Layer? crossLayer;
      for (final Object object in objects) {
        final LayerElement durElement = object as LayerElement;
        // The duration element is not cross-staff or the cross-staff is not
        // the same staff (very rare).
        if (durElement.crossStaff == null ||
            (crossStaff != null &&
                !identical(durElement.crossStaff, crossStaff))) {
          crossStaff = null;
          break;
        } else {
          crossStaff = durElement.crossStaff;
          crossLayer = durElement.crossLayer;
        }
      }
      if (crossStaff != null) {
        layerElement.crossStaff = crossStaff;
        layerElement.crossLayer = crossLayer;
      }
    }

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitMeasure(Measure measure) {
    currentMeasure = measure;

    return FunctorCode.continue_;
  }

  /// Mirrors `LayerElement::GetAncestorStaff` (ANCESTOR_ONLY).
  static Staff _getAncestorStaff(LayerElement element) =>
      element.getFirstAncestor(ClassId.staff) as Staff;
}

// ---------------------------------------------------------------------------
// PrepareAltSymFunctor
// ---------------------------------------------------------------------------

/// Resolve the @altsym references against the symbol table (mirrors
/// `vrv::PrepareAltSymFunctor`).
class PrepareAltSymFunctor extends Functor {
  SymbolTable? symbolTable;

  @override
  FunctorCode visitObject(Object object) {
    if (object.classId == ClassId.score) {
      final Score score = object as Score;
      assert(score.getScoreDef() != null);
      symbolTable = score
          .getScoreDef()!
          .findDescendantByType(ClassId.symbolTable) as SymbolTable?;
    }

    if (object is AltSymInterface) {
      final AltSymInterface interface = object as AltSymInterface;
      _interfacePrepareAltSym(interface, object);
    }

    return FunctorCode.continue_;
  }

  /// Mirrors `AltSymInterface::InterfacePrepareAltSym`.
  void _interfacePrepareAltSym(AltSymInterface interface, Object object) {
    interface.altSymbolDefID = extractIDFragment(interface.altsym ?? '');
    if (interface.altSymbolDefID.isEmpty) return;
    final Object? symbolDef =
        symbolTable?.findDescendantByID(interface.altSymbolDefID);
    if (symbolDef is! SymbolDef) {
      logWarning('Reference to the symbolDef '
          '`${interface.altSymbolDefID}` could not be resolved');
      return;
    }
    interface.altSymbolDef = symbolDef;
  }
}

// ---------------------------------------------------------------------------
// PrepareFacsimileFunctor
// ---------------------------------------------------------------------------

/// Associate zones with elements having a @facs attribute (mirrors
/// `vrv::PrepareFacsimileFunctor`).
class PrepareFacsimileFunctor extends Functor {
  PrepareFacsimileFunctor(this.facsimile);

  /// The facsimile of the document (mirrors `m_facsimile`).
  final Facsimile? facsimile;

  /// Zoneless syls for which a default zone has to be created (mirrors
  /// `m_zonelessSyls`).
  final List<Object> zonelessSyls = [];

  @override
  FunctorCode visitObject(Object object) {
    if (object is FacsimileInterface) {
      final FacsimileInterface interface = object as FacsimileInterface;
      if (interface.hasFacsimile) {
        _interfacePrepareFacsimile(interface, object);
      }
      // Zoneless syl.
      else if (object.classId == ClassId.syl) {
        zonelessSyls.add(object);
      }
    }

    return FunctorCode.continue_;
  }

  /// Mirrors `FacsimileInterface::InterfacePrepareFacsimile`.
  void _interfacePrepareFacsimile(FacsimileInterface interface, Object object) {
    if (facsimile == null) return;
    final String id = extractIDFragment(interface.facs ?? '');
    if (id.isEmpty) return;
    final Zone? zone = facsimile!.findDescendantByID(id) as Zone?;
    if (zone == null) {
      logWarning("Zone with id '$id' not found");
      return;
    }
    interface.zone = zone;
    interface.surface =
        zone.parent is FacsSurface ? zone.parent as FacsSurface? : null;
  }
}

// ---------------------------------------------------------------------------
// PrepareLinkingFunctor
// ---------------------------------------------------------------------------

/// Match all pointing elements using @next, @sameas and @stem.sameas
/// (mirrors `vrv::PrepareLinkingFunctor`).
class PrepareLinkingFunctor extends Functor with CollectAndProcess {
  /// Pairs of next ids and interfaces to be resolved (mirrors
  /// `m_nextIDPairs`, kept as a list of pairs since Dart has no multimap).
  final List<(String, LinkingInterface)> nextIDPairs = [];

  /// Pairs of sameas ids and interfaces to be resolved (mirrors
  /// `m_sameasIDPairs`).
  final List<(String, LinkingInterface)> sameasIDPairs = [];

  /// Pairs of stem.sameas target ids and notes (mirrors
  /// `m_stemSameasIDPairs`).
  final Map<String, Note> stemSameasIDPairs = {};

  void insertNextIDPair(String nextID, LinkingInterface interface) =>
      nextIDPairs.add((nextID, interface));

  void insertSameasIDPair(String sameasID, LinkingInterface interface) =>
      sameasIDPairs.add((sameasID, interface));

  @override
  FunctorCode visitObject(Object object) {
    if (isCollectingData && object is LinkingInterface) {
      final LinkingInterface interface = object as LinkingInterface;
      interface.setIDStr();
      if (interface.nextID.isNotEmpty) {
        insertNextIDPair(interface.nextID, interface);
      }
      if (interface.sameasID.isNotEmpty) {
        insertSameasIDPair(interface.sameasID, interface);
      }
    }

    if (object.classId == ClassId.note) {
      resolveStemSameas(object as Note);
    }

    // @next
    for (int i = nextIDPairs.length - 1; i >= 0; --i) {
      if (nextIDPairs[i].$1 == object.id) {
        nextIDPairs[i].$2.setNextLink(object);
        nextIDPairs.removeAt(i);
      }
    }

    // @sameas
    for (int i = sameasIDPairs.length - 1; i >= 0; --i) {
      final (String id, LinkingInterface interface) = sameasIDPairs[i];
      if (id == object.id) {
        interface.setSameasLink(object);
        // Issue a warning if classes of object and sameas do not match.
        final Object owner = interface as Object;
        if (owner.classId != object.classId) {
          logWarning(
              '${owner.className} with xml:id ${owner.id} has @sameas to an '
              'element of class ${object.className}.');
        }
        sameasIDPairs.removeAt(i);
      }
    }
    return FunctorCode.continue_;
  }

  /// Mirrors `PrepareLinkingFunctor::ResolveStemSameas`.
  void resolveStemSameas(Note note) {
    // First pass we fill m_stemSameasIDPairs.
    if (isCollectingData) {
      if (note.hasStemSameas) {
        final String idTarget = extractIDFragment(note.stemSameas!);
        stemSameasIDPairs[idTarget] = note;
      }
    }
    // Second pass we resolve links.
    else {
      final String id = note.id;
      if (stemSameasIDPairs.containsKey(id)) {
        final Note noteStemSameas = stemSameasIDPairs[id]!;
        // Instanciate the bi-directional references and mark the roles as
        // unset.
        note.stemSameasNote = noteStemSameas;
        note.stemSameasRole = StemSameasDrawingRole.unset;
        noteStemSameas.stemSameasNote = note;
        noteStemSameas.stemSameasRole = StemSameasDrawingRole.unset;
        // Also resolve beams and instanciate the bi-directional references.
        final Beam? beamStemSameas =
            noteStemSameas.getFirstAncestor(ClassId.beam) as Beam?;
        if (beamStemSameas != null) {
          final Beam? beam = note.getFirstAncestor(ClassId.beam) as Beam?;
          if (beam == null) {
            logError('Notes with @stem.sameas in a beam should refer only to a '
                'note also in beam.');
          } else {
            beam.setStemSameasBeam(beamStemSameas);
            beamStemSameas.setStemSameasBeam(beam);
          }
        }
        stemSameasIDPairs.remove(id);
      }
    }
  }
}

// ---------------------------------------------------------------------------
// PreparePlistFunctor
// ---------------------------------------------------------------------------

/// Match all pointing elements using @plist (mirrors
/// `vrv::PreparePlistFunctor`).
class PreparePlistFunctor extends Functor with CollectAndProcess {
  /// Pairs of plist holders and element ids (mirrors `m_plistObjectIDPairs`).
  final List<(Object, String)> plistObjectIDPairs = [];

  void insertInterfaceObjectIDPair(Object objectWithPlist, String elementID) =>
      plistObjectIDPairs.add((objectWithPlist, elementID));

  @override
  FunctorCode visitObject(Object object) {
    if (isCollectingData) {
      if (object is PlistInterface) {
        final PlistInterface interface = object as PlistInterface;
        interface.setIDStrs();
        for (final String id in interface.ids) {
          insertInterfaceObjectIDPair(object, id);
        }
      }
    } else {
      if (!object.isLayerElement &&
          !object.isAny({ClassId.ending, ClassId.expansion, ClassId.section})) {
        return FunctorCode.continue_;
      }

      final String id = object.id;
      for (int i = plistObjectIDPairs.length - 1; i >= 0; --i) {
        if (plistObjectIDPairs[i].$2 == id) {
          final Object holder = plistObjectIDPairs[i].$1;
          (holder as PlistInterface).setRef(object);
          // Add back link to the object referred in the plist - for now only
          // for Annot.
          if (holder.classId == ClassId.annotScore) {
            object.addPlistReference(holder);
          }
          plistObjectIDPairs.removeAt(i);
        }
      }
    }

    return FunctorCode.continue_;
  }
}

// ---------------------------------------------------------------------------
// PrepareDurationFunctor
// ---------------------------------------------------------------------------

/// Store the default duration values of the scoreDef / staffDefs into the
/// duration interfaces (mirrors `vrv::PrepareDurationFunctor`).
class PrepareDurationFunctor extends Functor {
  MeiDuration _durDefault = MeiDuration.none;

  final Map<int, MeiDuration> _durDefaultForStaffN = {};

  @override
  FunctorCode visitLayerElement(LayerElement layerElement) {
    if (layerElement is DurationInterface) {
      final DurationInterface durInterface = layerElement as DurationInterface;
      durInterface.setDurDefault(_durDefault);
      // Check if there is a duration default for the staff.
      if (_durDefaultForStaffN.isNotEmpty) {
        final Staff staff = _getAncestorStaff(layerElement);
        final MeiDuration? forStaff = _durDefaultForStaffN[staff.n ?? 0];
        if (forStaff != null) {
          durInterface.setDurDefault(forStaff);
        }
      }
    }

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitScore(Score score) {
    final ScoreDef? scoreDef = score.getScoreDef() as ScoreDef?;
    scoreDef?.process(this);

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitScoreDef(ScoreDef scoreDef) {
    _durDefaultForStaffN.clear();
    _durDefault = scoreDef.hasDurDefault
        ? scoreDef.durDefault ?? MeiDuration.none
        : MeiDuration.none;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitStaffDef(StaffDef staffDef) {
    if (staffDef.hasDurDefault && staffDef.hasN) {
      _durDefaultForStaffN[staffDef.n ?? 0] =
          staffDef.durDefault ?? MeiDuration.none;
    }

    return FunctorCode.continue_;
  }

  static Staff _getAncestorStaff(LayerElement element) =>
      element.getFirstAncestor(ClassId.staff) as Staff;
}

// ---------------------------------------------------------------------------
// PrepareTimePointingFunctor
// ---------------------------------------------------------------------------

typedef PointingInterClassIdPair = (TimePointInterface, ClassId);

/// Match all time pointing elements by processing backwards (mirrors
/// `vrv::PrepareTimePointingFunctor`).
class PrepareTimePointingFunctor extends Functor {
  final List<PointingInterClassIdPair> timePointingInterfaces = [];

  void insertInterfaceIDTuple(ClassId classID, TimePointInterface interface) =>
      timePointingInterfaces.add((interface, classID));

  @override
  FunctorCode visitF(F f) {
    // At this stage we require <f> to have a @startid - eventually we can
    // modify this method and set as start the parent <harm> so @startid
    // would not be required anymore.
    final TimePointInterface interface = f as TimePointInterface;
    return _interfacePrepareTimePointing(interface, f);
  }

  @override
  FunctorCode visitFloatingObject(FloatingObject floatingObject) {
    if (floatingObject.hasInterface(InterfaceId.timePoint) &&
        floatingObject is TimePointInterface) {
      final TimePointInterface interface = floatingObject as TimePointInterface;
      return _interfacePrepareTimePointing(interface, floatingObject);
    }
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitLayerElement(LayerElement layerElement) {
    if (layerElement.isScoreDefElement) return FunctorCode.siblings;

    // Do not look for tstamp pointing to these.
    if (layerElement.isAny({
      ClassId.artic,
      ClassId.beam,
      ClassId.flag,
      ClassId.tuplet,
      ClassId.stem,
      ClassId.verse
    })) {
      return FunctorCode.continue_;
    }

    for (int i = timePointingInterfaces.length - 1; i >= 0; --i) {
      if (_setStartOnly(timePointingInterfaces[i].$1, layerElement)) {
        // We have both the start and the end that are matched.
        timePointingInterfaces.removeAt(i);
      }
    }

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitMeasureEnd(Measure measure) {
    if (timePointingInterfaces.isNotEmpty) {
      logWarning(
          '${timePointingInterfaces.length} time pointing element(s) could '
          'not be matched in measure ${measure.id}');
    }

    timePointingInterfaces.clear();

    return FunctorCode.continue_;
  }

  /// Mirrors `TimePointInterface::SetStartOnly`.
  static bool _setStartOnly(
      TimePointInterface interface, LayerElement element) {
    if (interface.start == null &&
        interface.startID.isNotEmpty &&
        element.id == interface.startID) {
      interface.setStart(element);
      return true;
    }
    return false;
  }

  /// Mirrors `TimePointInterface::InterfacePrepareTimePointing`.
  FunctorCode _interfacePrepareTimePointing(
      TimePointInterface interface, Object object) {
    if (!interface.hasStartid) return FunctorCode.continue_;

    interface.setIDStr();
    insertInterfaceIDTuple(object.classId, interface);

    return FunctorCode.continue_;
  }
}

// ---------------------------------------------------------------------------
// PrepareTimeSpanningFunctor
// ---------------------------------------------------------------------------

typedef SpanningInterOwnerPair = (TimeSpanningInterface, Object);

/// Match all spanning elements by processing the doc twice (mirrors
/// `vrv::PrepareTimeSpanningFunctor`).
class PrepareTimeSpanningFunctor extends Functor with CollectAndProcess {
  bool _insideMeasure = false;

  final List<SpanningInterOwnerPair> timeSpanningInterfaces = [];

  List<SpanningInterOwnerPair> getInterfaceOwnerPairs() =>
      timeSpanningInterfaces;

  void insertInterfaceOwnerPair(Object owner, TimeSpanningInterface interface) {
    timeSpanningInterfaces.add((interface, owner));
  }

  @override
  FunctorCode visitF(F f) {
    if (!_insideMeasure) {
      return callPseudoFunctor(f);
    }
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitFloatingObject(FloatingObject floatingObject) {
    if (!_insideMeasure &&
        floatingObject.hasInterface(InterfaceId.timeSpanning) &&
        floatingObject is TimeSpanningInterface) {
      return callPseudoFunctor(floatingObject as TimeSpanningInterface);
    }
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitLayerElement(LayerElement layerElement) {
    if (layerElement.isScoreDefElement) return FunctorCode.siblings;

    // Do not look for tstamp pointing to these.
    if (layerElement.isAny({
      ClassId.artic,
      ClassId.beam,
      ClassId.flag,
      ClassId.tuplet,
      ClassId.stem,
      ClassId.verse
    })) {
      return FunctorCode.continue_;
    }

    for (int i = timeSpanningInterfaces.length - 1; i >= 0; --i) {
      final TimeSpanningInterface interface = timeSpanningInterfaces[i].$1;
      if (_setStartAndEnd(interface, layerElement)) {
        // Verify that the interface owner is encoded in the measure of its
        // start.
        verifyMeasure(timeSpanningInterfaces[i].$2, interface);
        // We have both the start and the end that are matched.
        timeSpanningInterfaces.removeAt(i);
      }
    }

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitMeasure(Measure measure) {
    if (isCollectingData) {
      final ic = InterfaceComparison(InterfaceId.timeSpanning);
      final List<Object> timeSpanningObjects =
          measure.findAllDescendantsMatching(ic);
      for (final Object object in timeSpanningObjects) {
        if (object is TimeSpanningInterface) {
          callPseudoFunctor(object as TimeSpanningInterface);
        }
      }
    }
    _insideMeasure = true;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitMeasureEnd(Measure measure) {
    if (isCollectingData) {
      for (int i = timeSpanningInterfaces.length - 1; i >= 0; --i) {
        // At the end of the measure we remove elements for which we do not
        // need to match the end (for now).
        if (timeSpanningInterfaces[i].$2.classId == ClassId.harm) {
          timeSpanningInterfaces.removeAt(i);
        }
      }
    }
    _insideMeasure = false;

    return FunctorCode.continue_;
  }

  /// Mirrors `PrepareTimeSpanningFunctor::CallPseudoFunctor`.
  FunctorCode callPseudoFunctor(TimeSpanningInterface timeSpanningObject) {
    if (!timeSpanningObject.hasStartid && !timeSpanningObject.hasEndid) {
      return FunctorCode.continue_;
    }
    if (isProcessingData) {
      return FunctorCode.continue_;
    }
    timeSpanningObject.setIDStr();
    final Object owner = timeSpanningObject as Object;
    insertInterfaceOwnerPair(owner, timeSpanningObject);
    return FunctorCode.continue_;
  }

  /// Mirrors `TimeSpanningInterface::SetStartAndEnd`.
  static bool _setStartAndEnd(
      TimeSpanningInterface interface, LayerElement element) {
    if (interface.start == null &&
        interface.startID.isNotEmpty &&
        element.id == interface.startID) {
      interface.setStart(element);
    } else if (interface.end == null &&
        interface.endID.isNotEmpty &&
        element.id == interface.endID) {
      interface.setEnd(element);
    }
    return interface.start != null && interface.end != null;
  }

  /// Mirrors `TimePointInterface::VerifyMeasure`.
  static void verifyMeasure(Object owner, TimeSpanningInterface interface) {
    if (interface.start != null) {
      final Object? ownerMeasure = owner.getFirstAncestor(ClassId.measure);
      if (!identical(ownerMeasure, interface.getStartMeasure())) {
        logWarning(
            "${owner.className} '${owner.id}' is not encoded in the measure "
            "of its start '${interface.start!.id}'. This may cause improper "
            'rendering.');
      }
    }
  }
}

// ---------------------------------------------------------------------------
// PrepareTimestampsFunctor
// ---------------------------------------------------------------------------

typedef ObjectBeatPair = (Object, MeasureBeat);

/// Match the @tstamp / @tstamp2 attributes (mirrors
/// `vrv::PrepareTimestampsFunctor`).
class PrepareTimestampsFunctor extends Functor {
  final List<(TimeSpanningInterface, ClassId)> timeSpanningInterfaces = [];
  final List<ObjectBeatPair> tstamps = [];

  void insertInterfaceIDPair(ClassId classID, TimeSpanningInterface interface) {
    timeSpanningInterfaces.add((interface, classID));
  }

  void insertObjectBeatPair(Object object, MeasureBeat beat) {
    tstamps.add((object, beat));
  }

  @override
  FunctorCode visitDocEnd(Doc doc) {
    // Open control events option is not exposed yet; keep the behaviour of
    // the default option (false).
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitF(F f) {
    // Using @tstamp on <f> will work only if @staff is also given on <f>.
    final TimeSpanningInterface interface = f as TimeSpanningInterface;
    return _interfacePrepareTimestamps(interface, f);
  }

  @override
  FunctorCode visitFloatingObject(FloatingObject floatingObject) {
    if (floatingObject.hasInterface(InterfaceId.timePoint) &&
        floatingObject is TimePointInterface) {
      final TimePointInterface interface = floatingObject as TimePointInterface;
      return _interfacePrepareTimestamps(interface, floatingObject);
    }
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitMeasureEnd(Measure measure) {
    // Loop through the object/beat pairs and create the TimestampAttr when
    // necessary.
    for (int i = 0; i < tstamps.length;) {
      final Object object = tstamps[i].$1;
      MeasureBeat beat = tstamps[i].$2;
      // -1 means that we have a @tstamp (start) to add to the current
      // measure.
      if (beat.measures == -1) {
        final TimePointInterface interface = object as TimePointInterface;
        final TimestampAttr timestampAttr =
            measure.timestampAligner.getTimestampAtTime(beat.beat);
        interface.setStart(timestampAttr);
        // Purge the list of unmatched elements if this is a
        // TimeSpanningInterface element.
        if (object.hasInterface(InterfaceId.timeSpanning) &&
            object is TimeSpanningInterface) {
          final TimeSpanningInterface tsInterface =
              object as TimeSpanningInterface;
          if (tsInterface.hasStartAndEnd) {
            timeSpanningInterfaces
                .removeWhere((pair) => identical(pair.$1, tsInterface));
          }
        }
        // Remove it.
        tstamps.removeAt(i);
      }
      // 0 means that we have a @tstamp2 (end) to add to the current measure.
      else if (beat.measures == 0) {
        final TimeSpanningInterface interface = object as TimeSpanningInterface;
        final TimestampAttr timestampAttr =
            measure.timestampAligner.getTimestampAtTime(beat.beat);
        interface.setEnd(timestampAttr);
        // We can check if the interface is now fully mapped (start / end)
        // and purge the list of unmatched elements.
        if (interface.hasStartAndEnd) {
          timeSpanningInterfaces
              .removeWhere((pair) => identical(pair.$1, interface));
        }
        tstamps.removeAt(i);
      }
      // We have not reached the correct end measure yet.
      else {
        tstamps[i] = (object, MeasureBeat(beat.measures - 1, beat.beat));
        ++i;
      }
    }

    // Here we can also set the start for F within Harm that have no
    // @startid or @tstamp but might have an extender.
    final List<Object> fs = measure.findAllDescendantsByType(ClassId.f);
    for (final Object object in fs) {
      final F f = object as F;
      // Nothing to do if the f has a start or has no end.
      if (f.hasStart || f.end == null) continue;

      final Harm? harm = f.getFirstAncestor(ClassId.harm) as Harm?;
      if (harm != null && harm.getStart() != null) {
        f.setStart(harm.getStart()!);
        // We should also remove the f from the list because we can consider
        // it as being mapped now.
        timeSpanningInterfaces.removeWhere((pair) => identical(pair.$1, f));
      }
    }

    return FunctorCode.continue_;
  }

  /// Combined port of `TimePointInterface::InterfacePrepareTimestamps` and
  /// `TimeSpanningInterface::InterfacePrepareTimestamps`.
  FunctorCode _interfacePrepareTimestamps(
      TimePointInterface interface, Object object) {
    final TimeSpanningInterface? spanning =
        interface is TimeSpanningInterface ? interface : null;

    if (spanning != null && spanning.hasEndid) {
      if (spanning.hasTstamp2) {
        logWarning(
            "${object.className} with xml:id ${object.id} has both a @endid "
            'and an @tstamp2; @tstamp2 is ignored');
      }
      if ((spanning.startid == spanning.endid) &&
          object.classId != ClassId.octave) {
        logWarning("${object.className} with xml:id ${object.id} will not get "
            'rendered as it has identical values in @startid and @endid');
      }
      return _interfacePrepareTimestampsPointOnly(interface, object);
    } else if (spanning == null || !spanning.hasTstamp2) {
      // We won't be able to do anything, just try to prepare the tstamp
      // (start).
      return _interfacePrepareTimestampsPointOnly(interface, object);
    }

    // We can now add the pair to our stack.
    insertInterfaceIDPair(object.classId, spanning);
    insertObjectBeatPair(object, spanning.tstamp2!);

    return _interfacePrepareTimestampsPointOnly(interface, object);
  }

  /// Mirrors `TimePointInterface::InterfacePrepareTimestamps`.
  FunctorCode _interfacePrepareTimestampsPointOnly(
      TimePointInterface interface, Object object) {
    // First we check if the object has already a mapped @startid (it should
    // not).
    if (interface.hasStart) {
      if (interface.hasTstamp) {
        logWarning('${object.className} with xml:id ${object.id} has both a '
            '@startid and an @tstamp; @tstamp is ignored');
      }
      return FunctorCode.continue_;
    } else if (!interface.hasTstamp || interface.tstamp == null) {
      return FunctorCode.continue_; // This file is quite likely invalid?
    }

    // We set -1 to the data_MEASUREBEAT for @tstamp.
    insertObjectBeatPair(object, MeasureBeat(-1, interface.tstamp!));

    return FunctorCode.continue_;
  }
}

// ---------------------------------------------------------------------------
// PreparePedalsFunctor
// ---------------------------------------------------------------------------

/// Match down and up pedal lines (mirrors `vrv::PreparePedalsFunctor`).
///
/// Deviation: `Pedal::GetPedalForm` needs the rendering options; here the
/// pedal form defaults to line when no @dir-resolved value says otherwise,
/// mirroring the default option value.
class PreparePedalsFunctor extends DocFunctor {
  PreparePedalsFunctor(super.doc);

  final List<Pedal> pedalLines = [];

  static bool _sameStaff(List<int>? first, List<int>? second) {
    if (first == null || second == null) return false;
    return first.isNotEmpty && second.isNotEmpty && first.first == second.first;
  }

  @override
  FunctorCode visitMeasureEnd(Measure measure) {
    // Match down and up pedal lines.
    for (int i = 0; i < pedalLines.length;) {
      if (pedalLines[i].dir != PedallogDir.down) {
        ++i;
        continue;
      }
      final int upIdx = pedalLines.indexWhere((pedal) =>
          _sameStaff(pedalLines[i].staff, pedal.staff) &&
          pedal.dir != PedallogDir.down);
      if (upIdx != -1) {
        final Pedal up = pedalLines[upIdx];
        if (up.getStart() != null) pedalLines[i].setEnd(up.getStart()!);
        if (up.dir == PedallogDir.bounce) {
          pedalLines[i].setEndsWithBounce();
        }
        if (upIdx > i) {
          pedalLines.removeAt(upIdx);
          pedalLines.removeAt(i);
        } else {
          pedalLines.removeAt(i);
          pedalLines.removeAt(upIdx);
          i = i > 0 ? i - 1 : 0;
          continue;
        }
      } else {
        ++i;
      }
    }

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitPedal(Pedal pedal) {
    if (!pedal.hasDir) return FunctorCode.continue_;

    final dynamic form = pedal.form;
    if (form == Pedalstyle.line || form == Pedalstyle.pedline) {
      pedalLines.add(pedal);
    } else if (form == null || form == Pedalstyle.none) {
      // Default option value ('auto'): draw a line.
      pedalLines.add(pedal);
    }

    return FunctorCode.continue_;
  }
}

// ---------------------------------------------------------------------------
// PreparePointersByLayerFunctor
// ---------------------------------------------------------------------------

/// Set the previous / next pointers of the dots within each layer (mirrors
/// `vrv::PreparePointersByLayerFunctor`).
class PreparePointersByLayerFunctor extends Functor {
  LayerElement? currentElement;
  Dot? lastDot;

  @override
  FunctorCode visitDot(Dot dot) {
    dot.drawingPreviousElement = currentElement;
    lastDot = dot;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitLayerElement(LayerElement layerElement) {
    if (layerElement.isScoreDefElement) return FunctorCode.siblings;

    // Skip ligatures because we want it attached to the first note in it.
    if (lastDot != null && layerElement.classId != ClassId.ligature) {
      lastDot!.drawingNextElement = layerElement;
      lastDot = null;
    }
    if (layerElement.classId == ClassId.barLine) {
      // Do not attach a note when a barline is passed.
      currentElement = null;
    } else if (layerElement.isAny({ClassId.note, ClassId.rest})) {
      currentElement = layerElement;
    }

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitMeasureEnd(Measure measure) {
    if (lastDot != null) {
      lastDot!.drawingNextElement = measure.getRightBarLine();
      lastDot = null;
    }

    return FunctorCode.continue_;
  }
}

// ---------------------------------------------------------------------------
// PrepareLyricsFunctor
// ---------------------------------------------------------------------------

/// Set the start / end notes of each syllable connector (mirrors
/// `vrv::PrepareLyricsFunctor`). Run verse by verse with filters.
class PrepareLyricsFunctor extends Functor {
  Syl? currentSyl;
  LayerElement? lastNoteOrChord;
  LayerElement? penultimateNoteOrChord;

  @override
  FunctorCode visitChord(Chord chord) {
    penultimateNoteOrChord = lastNoteOrChord;
    lastNoteOrChord = chord;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitDocEnd(Doc doc) {
    if (currentSyl == null) {
      return FunctorCode.stop; // early return
    }
    if (lastNoteOrChord != null &&
        !identical(currentSyl!.start, lastNoteOrChord)) {
      currentSyl!.setEnd(lastNoteOrChord!);
    }
    // Open control events are not enabled; nothing else to do.

    return FunctorCode.stop;
  }

  @override
  FunctorCode visitNote(Note note) {
    if (note.isChordTone() == null) {
      penultimateNoteOrChord = lastNoteOrChord;
      lastNoteOrChord = note;
    }

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitSyl(Syl syl) {
    final Verse? verse = syl.getFirstAncestor(ClassId.verse) as Verse?;
    if (verse != null) {
      syl.drawingVerseN = (verse.n ?? 0) < 1 ? 1 : verse.n!;
      syl.drawingVersePlace = verse.place;
    }

    final LayerElement? start =
        (syl.getFirstAncestor(ClassId.note) ??
            syl.getFirstAncestor(ClassId.chord)) as LayerElement?;
    if (start != null) syl.setStart(start);

    // At this stage currentSyl is actually the previous one that is ending
    // here.
    if (currentSyl != null) {
      // The previous syl was an initial or median -> The note we just parsed
      // is the end.
      if (currentSyl!.wordpos == SyllogWordpos.i ||
          currentSyl!.wordpos == SyllogWordpos.m) {
        if (lastNoteOrChord != null) currentSyl!.setEnd(lastNoteOrChord!);
        currentSyl!.nextWordSyl = syl;
      }
      // The previous syl was an underscore -> the previous but one was the
      // end.
      else if (currentSyl!.con == SyllogCon.u) {
        if (!identical(currentSyl!.start, penultimateNoteOrChord)) {
          if (penultimateNoteOrChord != null) {
            currentSyl!.setEnd(penultimateNoteOrChord!);
          }
        } else {
          logWarning("Syllable with underline extender under one single note "
              "'${currentSyl!.start?.id}'");
        }
      }
    }

    // Now decide what to do with the starting syl and check if it has a
    // forward connector.
    if (syl.wordpos == SyllogWordpos.i || syl.wordpos == SyllogWordpos.m) {
      currentSyl = syl;
      return FunctorCode.continue_;
    } else if (syl.con == SyllogCon.u) {
      currentSyl = syl;
      return FunctorCode.continue_;
    } else {
      currentSyl = null;
    }

    return FunctorCode.continue_;
  }
}

// ---------------------------------------------------------------------------
// PrepareLayerElementPartsFunctor
// ---------------------------------------------------------------------------

/// Instantiate the layer element parts (stem, flag, dots…) (mirrors
/// `vrv::PrepareLayerElementPartsFunctor`).
class PrepareLayerElementPartsFunctor extends Functor {
  @override
  FunctorCode visitChord(Chord chord) {
    Stem? currentStem =
        chord.findDescendantByType(ClassId.stem, deepness: 1) as Stem?;
    Flag? currentFlag;
    if (currentStem != null) {
      currentFlag = currentStem.getFirst(ClassId.flag) as Flag?;
    }

    currentStem = ensureStemExists(currentStem, chord);
    fillStemAttributes(currentStem, chord);

    final MeiDuration duration = chord.getActualDur();
    if (duration.value < MeiDuration.dur2.value || chord.stemVisible == false) {
      currentStem.setIsVirtual(true);
    }

    final bool shouldHaveFlag = duration.value > MeiDuration.dur4.value &&
        !_isInBeam(chord) &&
        chord.getFirstAncestor(ClassId.fTrem) == null;
    currentFlag = processFlag(currentFlag, currentStem, shouldHaveFlag);

    chord.setDrawingStem(currentStem);

    // Also set the drawing stem object (or NULL) to all child notes.
    final List<Object> childList = chord.getList();
    for (final Object child in childList) {
      assert(child.classId == ClassId.note);
      final Note note = child as Note;
      note.setDrawingStem(currentStem);
    }

    /************ dots ***********/

    Dots? currentDots =
        chord.findDescendantByType(ClassId.dots, deepness: 1) as Dots?;

    final bool shouldHaveDots = (chord.dots ?? 0) > 0;
    currentDots = processDots(currentDots, chord, shouldHaveDots);

    /************ Prepare the drawing cue size ************/

    final prepareCueSize = PrepareCueSizeFunctor();
    chord.process(prepareCueSize);

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitNote(Note note) {
    Stem? currentStem =
        note.findDescendantByType(ClassId.stem, deepness: 1) as Stem?;
    Flag? currentFlag;
    final Chord? chord = note.isChordTone() as Chord?;
    if (currentStem != null) {
      currentFlag = currentStem.getFirst(ClassId.flag) as Flag?;
    }

    if (chord == null && !_isTabGrpNote(note)) {
      currentStem = ensureStemExists(currentStem, note);
      fillStemAttributes(currentStem, note);

      if (note.getActualDur().value < MeiDuration.dur2.value ||
          note.stemVisible == false) {
        currentStem.setIsVirtual(true);
      }
    }
    // This will happen only if the duration has changed.
    else if (currentStem != null) {
      if (note.deleteChild(currentStem)) {
        currentStem = null;
        // The currentFlag (if any) will have been deleted above.
        currentFlag = null;
      }
    }

    /************ dots ***********/

    Dots? currentDots =
        note.findDescendantByType(ClassId.dots, deepness: 1) as Dots?;

    final bool shouldHaveDots = (note.dots ?? 0) > 0;
    if (shouldHaveDots && chord != null && chord.dots == note.dots) {
      logWarning(
          "Note '${note.id}' with a @dots attribute with the same value as "
          'its chord parent');
    }
    currentDots = processDots(currentDots, note, shouldHaveDots);

    // We don't care about flags in mensural notes.
    if (note.isMensuralDur) return FunctorCode.continue_;

    if (currentStem != null) {
      final bool shouldHaveFlag =
          note.getActualDur().value > MeiDuration.dur4.value &&
              !_isInBeam(note) &&
              note.getFirstAncestor(ClassId.fTrem) == null &&
              chord == null &&
              !_isTabGrpNote(note);
      currentFlag = processFlag(currentFlag, currentStem, shouldHaveFlag);

      if (chord == null) note.setDrawingStem(currentStem);
    }

    /************ Prepare the drawing cue size ************/

    final prepareCueSize = PrepareCueSizeFunctor();
    note.process(prepareCueSize);

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitRest(Rest rest) {
    Dots? currentDots =
        rest.findDescendantByType(ClassId.dots, deepness: 1) as Dots?;

    final bool shouldHaveDots =
        (rest.dur?.value ?? MeiDuration.none.value) > MeiDuration.breve.value &&
            (rest.dots ?? 0) > 0;
    currentDots = processDots(currentDots, rest, shouldHaveDots);

    /************ Prepare the drawing cue size ************/

    final prepareCueSize = PrepareCueSizeFunctor();
    rest.process(prepareCueSize);

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitTabDurSym(TabDurSym tabDurSym) {
    Stem? currentStem =
        tabDurSym.findDescendantByType(ClassId.stem, deepness: 1) as Stem?;

    currentStem = ensureStemExists(currentStem, tabDurSym);
    tabDurSym.setDrawingStem(currentStem);

    /************ flags ***********/

    final TabGrp? tabGrp =
        tabDurSym.getFirstAncestor(ClassId.tabGrp) as TabGrp?;
    assert(tabGrp != null);

    // No flag within beam for durations longer than 8th notes.
    final bool shouldHaveFlag = !_isInBeam(tabDurSym) &&
        (tabGrp!.getActualDur().value > MeiDuration.dur4.value);
    processFlag(null, currentStem, shouldHaveFlag);

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitTuplet(Tuplet tuplet) {
    TupletBracket? currentBracket =
        tuplet.getFirst(ClassId.tupletBracket) as TupletBracket?;
    TupletNum? currentNum = tuplet.getFirst(ClassId.tupletNum) as TupletNum?;

    bool beamed = false;
    // Are we contained in a beam?
    final Beam? ancestorBeam = tuplet.getFirstAncestor(ClassId.beam) as Beam?;
    if (ancestorBeam != null) {
      // Is only the tuplet beamed? (will not work with nested tuplets)
      if (ancestorBeam.childCount == 1) {
        beamed = true;
      }
    }
    // Is a beam or bTrem the only child? (will not work with editorial
    // elements)
    if (tuplet.childCount == 1) {
      if (tuplet.getChildCount(ClassId.beam) == 1 ||
          tuplet.getChildCount(ClassId.bTrem) == 1) {
        beamed = true;
      }
    }

    if ((!tuplet.hasBracketVisible || (tuplet.bracketVisible == true)) &&
        !(tuplet.bracketVisible == false)) {
      if (!(tuplet.hasBracketVisible && tuplet.bracketVisible == false) &&
          (!beamed || tuplet.bracketVisible == true)) {
        if (currentBracket == null) {
          currentBracket = TupletBracket();
          tuplet.addChild(currentBracket);
        }
        copyTupletVis(currentBracket, tuplet);
      }
    }
    if (tuplet.bracketVisible == false ||
        (tuplet.bracketVisible == null && beamed)) {
      if (currentBracket != null) {
        if (tuplet.deleteChild(currentBracket)) {
          currentBracket = null;
        }
      }
    }

    if (tuplet.hasNum &&
        (!tuplet.hasNumVisible || (tuplet.numVisible == true))) {
      if (currentNum == null) {
        currentNum = TupletNum();
        tuplet.addChild(currentNum);
      }
      copyTupletVis(currentNum, tuplet);
    }
    // This will happen only if the @num.visible value has changed.
    else if (currentNum != null) {
      if (tuplet.deleteChild(currentNum)) {
        currentNum = null;
      }
    }

    /************ Prepare the drawing cue size ************/

    final prepareCueSize = PrepareCueSizeFunctor();
    tuplet.process(prepareCueSize);

    /*********** Set the left and right element ***********/

    final comparison =
        ClassIdsComparison(const [ClassId.chord, ClassId.note, ClassId.rest]);
    tuplet.drawingLeft =
        tuplet.findDescendantByComparison(comparison) as LayerElement?;
    tuplet.drawingRight = tuplet.findDescendantByComparison(comparison,
        direction: backward) as LayerElement?;

    return FunctorCode.continue_;
  }

  /// Mirrors `PrepareLayerElementPartsFunctor::EnsureStemExists`.
  static Stem ensureStemExists(Stem? stem, Object parent) {
    if (stem == null) {
      stem = Stem();
      stem.isAttribute = true;
      parent.addChild(stem);
    }
    return stem;
  }

  /// Mirrors `AttGraced::operator=` + `Stem::FillAttributes`.
  static void fillStemAttributes(Stem stem, Object source) {
    if (source is AttGraced) {
      final AttGraced graced = source as AttGraced;
      stem.grace = graced.grace;
      stem.graceTime = graced.graceTime;
    }
    if (source is AttStems) {
      final AttStems stems = source as AttStems;
      if (stems.hasStemDir) stem.dir = stems.stemDir;
      if (stems.hasStemLen) {
        final MeasurementSigned len = MeasurementSigned();
        len.setVu(stems.stemLen ?? 0);
        stem.len = len;
      }
      if (stems.hasStemMod) {
        stem.setDrawingStemMod(stems.stemMod!);
      }
    }
    if (source is AttStemVis) {
      final AttStemVis vis = source as AttStemVis;
      if (vis.hasPos) stem.pos = vis.pos;
    }
    // Removed AttVisibility branch — Stem::FillAttributes (stem.cpp:72-91)
    // only reads AttStems / AttStemVis, never @visible of the parent. A
    // note with @visible="false" must not hide its stem; the C++ only sets
    // the note's own visibility. Mirrors `AttStems::GetStemVisible` vs
    // `AttVisibility::GetVisible` distinction.
  }

  /// Mirrors `PrepareLayerElementPartsFunctor::ProcessDots`.
  static Dots? processDots(Dots? dots, Object parent, bool shouldExist) {
    assert(parent is DurationInterface);

    if (shouldExist) {
      if (dots == null) {
        dots = Dots();
        parent.addChild(dots);
      }
      // Mirrors AttAugmentDots::operator= (dots.ges is not ported).
      final DurationInterface durInterface = parent as DurationInterface;
      dots.dots = durInterface.dots;
    } else if (dots != null) {
      if (parent.deleteChild(dots)) {
        dots = null;
      }
    }
    return dots;
  }

  /// Mirrors `PrepareLayerElementPartsFunctor::ProcessFlag`.
  static Flag? processFlag(Flag? flag, Object parent, bool shouldExist) {
    if (shouldExist) {
      if (flag == null) {
        flag = Flag();
        parent.addChild(flag);
      }
    } else if (flag != null) {
      if (parent.deleteChild(flag)) {
        flag = null;
      }
    }
    return flag;
  }

  /// Copy the AttTupletVis values (mirrors `AttTupletVis::operator=`).
  static void copyTupletVis(Object target, Tuplet tuplet) {
    if (target is AttTupletVis) {
      final AttTupletVis vis = target as AttTupletVis;
      vis.bracketVisible = tuplet.bracketVisible;
      vis.numFormat = tuplet.numFormat;
    }
    // The Dart att classes split num.place / num.visible into
    // AttNumberPlacement while the C++ groups them in AttTupletVis.
    if (target is AttNumberPlacement) {
      final AttNumberPlacement numberPlacement = target as AttNumberPlacement;
      numberPlacement.numPlace = tuplet.numPlace;
      numberPlacement.numVisible = tuplet.numVisible;
    }
  }

  /// Mirrors `LayerElement::IsInBeam` without beam span segments.
  static bool _isInBeam(LayerElement element) =>
      element.getFirstAncestor(ClassId.beam) != null || element.isInBeamSpan;

  /// Mirrors `Note::IsTabGrpNote`.
  static bool _isTabGrpNote(LayerElement element) =>
      element.getFirstAncestor(ClassId.tabGrp) != null;
}

// ---------------------------------------------------------------------------
// PrepareRptFunctor
// ---------------------------------------------------------------------------

/// Set the drawing number of mRpt elements (mirrors
/// `vrv::PrepareRptFunctor`). Processed staff/layer by staff/layer with
/// filters.
class PrepareRptFunctor extends DocFunctor {
  PrepareRptFunctor(super.doc);

  MRpt? currentMRpt;

  /// `BOOLEAN_NONE` mirrors the unset state ([null] in Dart).
  bool? multiNumber;

  @override
  FunctorCode visitLayer(Layer layer) {
    // If we have encountered a mRpt before and there is none in this layer,
    // reset it to NULL.
    if (currentMRpt != null &&
        layer.findDescendantByType(ClassId.mRpt) == null) {
      currentMRpt = null;
    }
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitMRpt(MRpt mRpt) {
    // If multiNumber is not true, nothing needs to be done.
    if (multiNumber != true) {
      return FunctorCode.continue_;
    }

    // If this is the first one, number has to be 2.
    if (currentMRpt == null) {
      mRpt.drawingMeasureCount = 2;
    } else {
      // Otherwise increment it.
      mRpt.drawingMeasureCount = currentMRpt!.drawingMeasureCount + 1;
    }
    currentMRpt = mRpt;
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitStaff(Staff staff) {
    // If multiNumber is set, we already know that nothing needs to be done.
    if (multiNumber != null) {
      return FunctorCode.continue_;
    }

    // This is happening only for the first staff element of the staff @n.
    final Score? score = doc.getCorrespondingScore(staff);
    final ScoreDef? scoreDef = score?.getScoreDef() as ScoreDef?;
    assert(scoreDef != null);
    final StaffDef? staffDef = scoreDef?.getStaffDef(staff.n ?? 0);
    if (staffDef != null) {
      final bool hideNumber = (staffDef.multiNumber == false) ||
          ((staffDef.multiNumber != true) && (scoreDef!.multiNumber == false));
      if (hideNumber) {
        // Set it just in case, but stopping the functor should do it for this
        // staff @n.
        multiNumber = false;
        return FunctorCode.stop;
      }
    }
    multiNumber = true;
    return FunctorCode.continue_;
  }
}

// ---------------------------------------------------------------------------
// PrepareDelayedTurnsFunctor
// ---------------------------------------------------------------------------

/// Set the drawing end element of delayed turns (mirrors
/// `vrv::PrepareDelayedTurnsFunctor`).
class PrepareDelayedTurnsFunctor extends Functor with CollectAndProcess {
  final Map<LayerElement, Turn> delayedTurns = {};

  Turn? currentTurn;
  LayerElement? previousElement;
  Chord? currentChord;

  Map<LayerElement, Turn> getDelayedTurns() => delayedTurns;

  void resetCurrent() {
    previousElement = null;
    currentChord = null;
    currentTurn = null;
  }

  @override
  FunctorCode visitLayerElement(LayerElement layerElement) {
    // We are initializing the m_delayedTurns map.
    if (isCollectingData) return FunctorCode.continue_;

    if (!layerElement.hasInterface(InterfaceId.duration)) {
      return FunctorCode.continue_;
    }

    if (previousElement != null) {
      assert(currentTurn != null);
      if (layerElement.classId == ClassId.note && currentChord != null) {
        final Note note = layerElement as Note;
        if (identical(note.isChordTone(), currentChord)) {
          return FunctorCode.continue_;
        }
      }
      currentTurn!.drawingEndElement = layerElement;
      resetCurrent();
    }

    if (delayedTurns.containsKey(layerElement)) {
      previousElement = layerElement;
      currentTurn = delayedTurns[layerElement];
      if (layerElement.classId == ClassId.chord) {
        return FunctorCode.siblings;
      } else if (layerElement.classId == ClassId.note) {
        final Note note = layerElement as Note;
        final Chord? chord = note.isChordTone() as Chord?;
        if (chord != null) currentChord = chord;
      }
    }

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitTurn(Turn turn) {
    // We already initialized the m_delayedTurns map.
    if (isProcessingData) return FunctorCode.continue_;

    // Map only delayed turns.
    if (turn.delayed != true) return FunctorCode.continue_;

    // Map only delayed turn pointing to a LayerElement (i.e., not using
    // @tstamp).
    if (turn.getStart() != null && turn.getStart() is! TimestampAttr) {
      delayedTurns[turn.getStart() as LayerElement] = turn;
    }

    return FunctorCode.continue_;
  }
}

// ---------------------------------------------------------------------------
// PrepareMilestonesFunctor
// ---------------------------------------------------------------------------

/// Set the pointers to the measures for the system milestones (mirrors
/// `vrv::PrepareMilestonesFunctor`).
class PrepareMilestonesFunctor extends Functor {
  Measure? lastMeasure;
  Ending? currentEnding;

  final List<SystemMilestoneInterface> startMilestones = [];

  void insertStartMilestone(SystemMilestoneInterface interface) {
    startMilestones.add(interface);
  }

  @override
  FunctorCode visitEditorialElement(EditorialElement editorialElement) {
    _interfacePrepareMilestones(editorialElement);

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitEnding(Ending ending) {
    // Endings should always have a SystemMilestoneEnd.
    assert(ending.isSystemMilestone());

    _interfacePrepareMilestones(ending);

    currentEnding = ending;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitMeasure(Measure measure) {
    for (final SystemMilestoneInterface interface in startMilestones) {
      interface.drawingMeasure = measure;
    }
    startMilestones.clear();

    if (currentEnding != null) {
      // Set the ending to each measure in between.
      measure.setDrawingEnding(currentEnding);
    }

    // Keep a pointer to the measure for when we are reaching the end.
    lastMeasure = measure;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitSection(Section section) {
    if (section.isSystemMilestone()) {
      _interfacePrepareMilestones(section);
    }

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitSystemMilestone(SystemMilestoneEnd systemMilestoneEnd) {
    // We set its pointer to the last measure we have encountered - this can
    // be NULL in case no measure exists before the end milestone.
    systemMilestoneEnd.measure = lastMeasure;

    // Endings are also set as Measure::m_drawingEnding for all measures in
    // between - when we reach the end milestone of an ending we need to set
    // the current ending to NULL.
    if (currentEnding != null &&
        identical(systemMilestoneEnd.start, currentEnding)) {
      currentEnding = null;
      assert(systemMilestoneEnd.measure != null);
    }

    return FunctorCode.continue_;
  }

  /// Mirrors
  /// `SystemMilestoneInterface::InterfacePrepareMilestones`.
  void _interfacePrepareMilestones(SystemMilestoneInterface interface) {
    insertStartMilestone(interface);
  }
}

// ---------------------------------------------------------------------------
// PrepareFloatingGrpsFunctor
// ---------------------------------------------------------------------------

/// Group the floating elements for the vertical alignment (mirrors
/// `vrv::PrepareFloatingGrpsFunctor`).
class PrepareFloatingGrpsFunctor extends Functor {
  Ending? previousEnding;

  static bool _sameStaff(List<int>? first, List<int>? second) {
    if (first == null || second == null) return false;
    return first.isNotEmpty && second.isNotEmpty && first.first == second.first;
  }

  final List<Dynam> dynams = [];
  final List<Hairpin> hairpins = [];
  final List<(String, Harm)> harms = [];

  @override
  FunctorCode visitDir(Dir dir) {
    if (dir.hasVgrp) {
      dir.drawingGrpId = -(dir.vgrp ?? 0);
    }

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitDynam(Dynam dynam) {
    if (dynam.hasVgrp) {
      dynam.drawingGrpId = -(dynam.vgrp ?? 0);
    }

    // Keep it for linking only if start is resolved.
    if (dynam.getStart() == null) return FunctorCode.continue_;

    dynams.add(dynam);

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitEnding(Ending ending) {
    if (previousEnding != null) {
      // We need to group the previous and this ending.
      if (previousEnding!.drawingGrpId == 0) {
        logDebug('Something went wrong with the grouping of the endings');
      }
      ending.drawingGrpId = previousEnding!.drawingGrpId;
      previousEnding = null;
    }

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitHairpin(Hairpin hairpin) {
    if (hairpin.hasVgrp) {
      hairpin.drawingGrpId = -(hairpin.vgrp ?? 0);
    }

    // Only try to link them if start and end are resolved.
    if (hairpin.getStart() == null || hairpin.getEnd() == null) {
      return FunctorCode.continue_;
    }

    hairpins.add(hairpin);

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitHarm(Harm harm) {
    String n = harm.n ?? '';
    // If there is no @n on harm we use the first @staff value as negative.
    if (n.isEmpty && harm.hasStaff) {
      n = '${-harm.staff!.first}';
    }

    for (final (String key, Harm value) in harms) {
      if (key == n) {
        harm.drawingGrpId = value.drawingGrpId;
        return FunctorCode.continue_;
      }
    }

    // First harm@n: create a new group. If @n is a digit string, use it as
    // group id - otherwise order them as they appear.
    final int? parsed = int.tryParse(n);
    if (parsed != null && n.isNotEmpty) {
      harm.drawingGrpId = parsed;
    } else {
      harm.setDrawingGrpObject(harm);
    }
    harms.add((n, harm));

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitMeasure(Measure measure) {
    if (previousEnding != null) {
      // We have a measure in between endings and the previous one was
      // grouped, just reset pointer to NULL.
      previousEnding = null;
    }

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitMeasureEnd(Measure measure) {
    // Link dynamics and hairpins at the end of the measure to make sure that
    // the order of elements in MEI does not dictate their linkage.
    for (final Dynam dynam in dynams) {
      for (final Hairpin hairpin in hairpins) {
        if (identical(hairpin.getEnd(), dynam.getStart()) &&
            _sameStaff(hairpin.staff, dynam.staff)) {
          if (hairpin.getRightLink() == null) hairpin.setRightLink(dynam);
        }
      }
    }

    for (final Hairpin hairpin in hairpins) {
      for (final Dynam dynam in dynams) {
        if (identical(dynam.getStart(), hairpin.getStart()) &&
            _sameStaff(hairpin.staff, dynam.staff)) {
          if (hairpin.getLeftLink() == null) hairpin.setLeftLink(dynam);
        } else if (identical(dynam.getStart(), hairpin.getEnd()) &&
            _sameStaff(hairpin.staff, dynam.staff)) {
          if (hairpin.getRightLink() == null) hairpin.setRightLink(dynam);
        }
      }

      for (final Hairpin hairpin2 in hairpins) {
        if (identical(hairpin, hairpin2)) continue;
        if (identical(hairpin2.getEnd(), hairpin.getStart()) &&
            _sameStaff(hairpin2.staff, hairpin.staff)) {
          if (hairpin.getLeftLink() == null &&
              hairpin2.getRightLink() == null) {
            hairpin.setLeftLink(hairpin2);
            hairpin2.setRightLink(hairpin);
          }
        }
        if (identical(hairpin2.getStart(), hairpin.getEnd()) &&
            _sameStaff(hairpin2.staff, hairpin.staff)) {
          if (hairpin2.getLeftLink() == null &&
              hairpin.getRightLink() == null) {
            hairpin2.setLeftLink(hairpin);
            hairpin.setRightLink(hairpin2);
          }
        }
      }
    }

    dynams.clear();

    hairpins.removeWhere((hairpin) {
      final Measure? measureEnd =
          hairpin.getEnd()?.getFirstAncestor(ClassId.measure) as Measure?;
      return identical(measureEnd, measure);
    });

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitPedal(Pedal pedal) {
    if (pedal.hasVgrp) {
      pedal.drawingGrpId = -(pedal.vgrp ?? 0);
    }

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitSystemMilestone(SystemMilestoneEnd systemMilestoneEnd) {
    // We are reaching the end of an ending - store it and it will be grouped
    // with the next one if there is no measure in between.
    if (systemMilestoneEnd.start.classId == ClassId.ending) {
      previousEnding = systemMilestoneEnd.start as Ending;
      assert(previousEnding != null);
      // This is the end of the first ending - generate a grpId.
      if (previousEnding!.drawingGrpId == 0) {
        previousEnding!.setDrawingGrpObject(previousEnding!);
      }
    }

    return FunctorCode.continue_;
  }
}

// ---------------------------------------------------------------------------
// PrepareRehPositionFunctor
// ---------------------------------------------------------------------------

/// Set the start of reh elements without @startid / @tstamp (mirrors
/// `vrv::PrepareRehPositionFunctor`).
class PrepareRehPositionFunctor extends Functor {
  @override
  FunctorCode visitReh(Reh reh) {
    if (!reh.hasStartid && !reh.hasTstamp) {
      final Measure? measure =
          reh.getFirstAncestor(ClassId.measure) as Measure?;
      if (measure != null) reh.setStart(measure.getLeftBarLine());
    }

    return FunctorCode.siblings;
  }
}

// ---------------------------------------------------------------------------
// PrepareBeamSpanElementsFunctor
// ---------------------------------------------------------------------------

/// Collect the beamed elements of beamSpans (mirrors
/// `vrv::PrepareBeamSpanElementsFunctor`).
class PrepareBeamSpanElementsFunctor extends Functor {
  @override
  FunctorCode visitBeamSpan(BeamSpan beamSpan) {
    if (beamSpan.beamedElements.isNotEmpty ||
        beamSpan.getStart() == null ||
        beamSpan.getEnd() == null) {
      return FunctorCode.continue_;
    }

    final Layer? layer =
        beamSpan.getStart()?.getFirstAncestor(ClassId.layer) as Layer?;
    final Staff? staff =
        beamSpan.getStart()?.getFirstAncestor(ClassId.staff) as Staff?;
    if (layer == null || staff == null) return FunctorCode.siblings;

    final List<Object> beamedElements = beamSpan.hasPlist
        ? beamSpan.getRefs()
        : _getBeamSpanElementList(beamSpan, layer, staff);

    beamSpan.setBeamedElements(beamedElements);

    if (beamedElements.isEmpty) return FunctorCode.siblings;

    // Mark referenced elements as contained in beam span.
    for (final Object element in beamedElements) {
      final LayerElement? layerElem = element is LayerElement ? element : null;
      if (layerElem == null) continue;

      final Measure? measure =
          layerElem.getFirstAncestor(ClassId.measure) as Measure?;
      if (measure == null) continue;
      layerElem.isInBeamSpan = true;

      final Staff? elementStaff =
          layerElem.getFirstAncestor(ClassId.staff) as Staff?;
      if (elementStaff == null) continue;
      if (elementStaff.n != staff.n) {
        final Layer? elementLayer =
            layerElem.getFirstAncestor(ClassId.layer) as Layer?;
        if (elementLayer == null) continue;
        layerElem.crossStaff = elementStaff;
        layerElem.crossLayer = elementLayer;
      }
    }

    return FunctorCode.continue_;
  }

  /// Simplified port of `GetBeamSpanElementList`: collects the notes /
  /// chords of the layer between the start and the end of the beamSpan.
  /// Cross-measure beam spans are deferred to the horizontal layout phase.
  List<Object> _getBeamSpanElementList(
      BeamSpan beamSpan, Layer layer, Staff staff) {
    final classIds = ClassIdsComparison(const [ClassId.note, ClassId.chord]);
    final List<Object> objects = [];
    layer.fillFlatList(objects);
    bool started = false;
    objects.retainWhere((Object object) {
      if (!classIds(object)) return false;
      if (identical(object, beamSpan.getStart())) started = true;
      final bool take = started;
      if (identical(object, beamSpan.getEnd())) started = false;
      return take;
    });
    // Remove chord tones.
    objects.removeWhere((object) =>
        object.classId == ClassId.note &&
        (object as Note).isChordTone() != null);
    return objects;
  }
}

// ---------------------------------------------------------------------------
// InitProcessingListsFunctor (from initprocessinglists functor)
// ---------------------------------------------------------------------------

/// Fill the trees of staff/layer(/verse) numbers used to process the document
/// by layer or verse (mirrors `vrv::InitProcessingListsFunctor` and its
/// `IntTree` structure).
class InitProcessingListsFunctor extends Functor {
  /// staff @n → layer @n values (mirrors `m_layerTree`).
  final Map<int, Set<int>> layerTree = {};

  /// staff @n → layer @n → verse @n values (mirrors `m_verseTree`).
  final Map<int, Map<int, Set<int>>> verseTree = {};

  @override
  FunctorCode visitStaff(Staff staff) {
    final int staffN = staff.n ?? 0;
    for (final Object child in staff.children) {
      if (child.classId != ClassId.layer) continue;
      final Layer layer = child as Layer;
      layerTree.putIfAbsent(staffN, () => <int>{}).add(layer.n ?? 0);
      for (final Object layerChild in layer.children) {
        if (layerChild.classId != ClassId.verse) continue;
        final Verse verse = layerChild as Verse;
        verseTree
            .putIfAbsent(staffN, () => {})
            .putIfAbsent(layer.n ?? 0, () => <int>{})
            .add(verse.n ?? 0);
      }
    }
    // Do not process the children again.
    return FunctorCode.siblings;
  }
}

// ---------------------------------------------------------------------------
// Helpers shared with the Calc* functors
// ---------------------------------------------------------------------------

extension LayoutElementHelpers on LayerElement {
  /// Mirrors `LayerElement::GetAncestorStaff` (ANCESTOR_ONLY).
  Staff getAncestorStaffLayout() => getFirstAncestor(ClassId.staff) as Staff;

  /// Headless variant returning null when there is no ancestor staff.
  Staff? getAncestorStaffLayoutOrNull() =>
      getFirstAncestor(ClassId.staff) as Staff?;

  /// Mirrors `LayerElement::GetAncestorStaff(RESOLVE_CROSS_STAFF)`.
  Staff? getAncestorStaffResolveCrossStaff() {
    final Object? cross = crossStaff;
    if (cross is Staff) return cross;
    return getAncestorStaffLayoutOrNull();
  }

  /// Mirrors `Object::IsVisible` reduced to the encoded @visible attribute
  /// (the editorial visibility checks arrive with the rendering phase).
  bool layoutIsVisible() {
    if (this is AttVisibility) {
      final AttVisibility visibility = this as AttVisibility;
      if (visibility.hasVisible && visibility.visible == false) return false;
    }
    return true;
  }

  /// Return the clef loc offset of the layer (headless equivalent of
  /// `Layer::GetClefLocOffset` based on the drawing staffDef clef).
  int getClefLocOffsetHeadless() {
    final Staff staff = getAncestorStaffLayout();
    final StaffDef? staffDef = staff.drawingStaffDef is StaffDef
        ? staff.drawingStaffDef as StaffDef
        : null;
    Clef? clef;
    final Layer? layer = getFirstAncestor(ClassId.layer) as Layer?;
    if (layer?.staffDefClef != null) {
      clef = layer!.staffDefClef;
    } else if (staffDef != null) {
      clef = staffDef.getCurrentClef();
    }
    return clef?.getClefLocOffset() ?? 0;
  }

  /// Compute and store the drawing loc of the note (headless equivalent of
  /// `PitchInterface::CalcLoc` driven by CalcAlignmentPitchPosFunctor).
  int calcDrawingLocHeadless() {
    if (this is PositionInterface) {
      final PositionInterface position = this as PositionInterface;
      if (position.hasLoc) return position.loc ?? 0;
    }
    if (this is PitchInterface) {
      final PitchInterface pitch = this as PitchInterface;
      final Pitchname pname = pitch.pname ?? Pitchname.none;
      final int oct = pitch.oct ?? pitch.octDefault;
      final int loc =
          PitchInterface.calcLoc(pname, oct, getClefLocOffsetHeadless());
      if (this is PositionInterface) {
        (this as PositionInterface).drawingLoc = loc;
      }
      return loc;
    }
    return 0;
  }

  /// Return the stem length in third units (mirrors
  /// `Note::CalcStemLenInThirdUnits`; chords delegate to their top/bottom
  /// note before calling this).
  int calcStemLenInThirdUnitsHeadless(Staff staff, Stemdirection stemDir) {
    if (stemDir != Stemdirection.down && stemDir != Stemdirection.up) {
      return 0;
    }

    int baseStem = standardStemLength * 3;

    int shortening = 0;
    final int loc =
        this is PositionInterface ? (this as PositionInterface).drawingLoc : 0;
    final int unitToLine = (stemDir == Stemdirection.up)
        ? -loc + (staff.drawingLines - 1) * 2
        : loc;
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
          break;
      }
    }

    // Limit shortening with duration shorter than quarter note when not in a
    // beam.
    final DurationInterface? durInterface =
        this is DurationInterface ? this as DurationInterface : null;
    final bool inBeam = getFirstAncestor(ClassId.beam) != null || isInBeamSpan;
    if (durInterface != null &&
        (durInterface.getActualDur().value > MeiDuration.dur4.value) &&
        !inBeam) {
      final Stemdirection dir = getDrawingStemDirHeadless();
      if (dir == Stemdirection.up) {
        shortening = shortening > 4 ? 4 : shortening;
      } else {
        shortening = shortening > 3 ? 3 : shortening;
      }
    }

    baseStem -= shortening;

    return baseStem;
  }

  /// Headless drawing stem direction lookup (delegates to the managed stem).
  Stemdirection getDrawingStemDirHeadless() {
    if (this is StemmedDrawingInterface) {
      return (this as StemmedDrawingInterface).getDrawingStemDir();
    }
    return Stemdirection.none;
  }

  /// Mirrors `LayerElement::GetAncestorBeam`.
  Beam? getAncestorBeam() {
    if (!isAny({
      ClassId.chord,
      ClassId.note,
      ClassId.rest,
      ClassId.tabGrp,
      ClassId.tabDurSym,
      ClassId.stem,
    })) {
      return null;
    }
    final Beam? beamParent = getFirstAncestor(ClassId.beam) as Beam?;
    if (classId == ClassId.rest) return beamParent;

    if (beamParent != null) {
      if (!isGraceNote()) return beamParent;
      // This note is beamed and cue-sized.
      LayerElement? graceElement = this;
      if (classId == ClassId.stem) {
        graceElement = (getFirstAncestor(ClassId.note) ??
            getFirstAncestor(ClassId.chord)) as LayerElement?;
      }
      // Make sure the object list is set.
      beamParent.getList();
      if (graceElement != null && beamParent.getListIndex(graceElement) > -1) {
        return beamParent;
      }
      // Otherwise it is a non-beamed grace note within a beam.
    }
    return null;
  }

  /// Mirrors `LayerElement::GetDrawingArticulationTopOrBottom`. [type] is
  /// unused, matching the C++ (kept for signature parity).
  int getDrawingArticulationTopOrBottom(Staffrel place,
      [ArticType type = ArticType.inside]) {
    // Process backward: we want the farthest away artic.
    final List<Object> artics =
        findAllDescendantsByType(ClassId.artic).reversed.toList();

    Artic? artic;
    for (final Object child in artics) {
      final Artic candidate = child as Artic;
      if (candidate.drawingPlace == place) {
        artic = candidate;
        break;
      }
    }

    if (artic == null) return place == Staffrel.above ? meiUnset : -meiUnset;
    return place == Staffrel.above ? artic.getSelfTop() : artic.getSelfBottom();
  }

  /// Mirrors `LayerElement::GetDrawingTop`.
  int getDrawingTop(Doc doc, int staffSize,
      {bool withArtic = true, ArticType type = ArticType.inside}) {
    if (isAny({ClassId.note, ClassId.chord}) && withArtic) {
      final int articY =
          getDrawingArticulationTopOrBottom(Staffrel.above, type);
      if (articY != meiUnset) return articY;
    }

    Note? note;
    if (classId == ClassId.chord) {
      note = (this as Chord).getTopNote();
    } else if (classId == ClassId.note) {
      note = this as Note;
    }

    if (note != null) {
      if (_noteOrChordDur(this).value < MeiDuration.dur2.value) {
        return note.getDrawingY() + doc.getDrawingUnit(staffSize);
      }
      // We should also take into account the stem shift to the right.
      final StemmedDrawingInterface stemInterface =
          this as StemmedDrawingInterface;
      if (stemInterface.getDrawingStemDir() == Stemdirection.up) {
        return stemInterface.getDrawingStemEnd(this).y;
      } else {
        // This does not take into account the glyph's actual size.
        return note.getDrawingY() + doc.getDrawingUnit(staffSize);
      }
    }
    return getDrawingY();
  }

  /// Mirrors `LayerElement::GetDrawingBottom`.
  int getDrawingBottom(Doc doc, int staffSize,
      {bool withArtic = true, ArticType type = ArticType.inside}) {
    if (isAny({ClassId.note, ClassId.chord}) && withArtic) {
      final int articY =
          getDrawingArticulationTopOrBottom(Staffrel.below, type);
      if (articY != -meiUnset) return articY;
    }

    Note? note;
    if (classId == ClassId.chord) {
      note = (this as Chord).getBottomNote();
    } else if (classId == ClassId.note) {
      note = this as Note;
    }

    if (note != null) {
      if (_noteOrChordDur(this).value < MeiDuration.dur2.value) {
        return note.getDrawingY() - doc.getDrawingUnit(staffSize);
      }
      // We should also take into account the stem shift to the right.
      final StemmedDrawingInterface stemInterface =
          this as StemmedDrawingInterface;
      if (stemInterface.getDrawingStemDir() == Stemdirection.up) {
        // This does not take into account the glyph's actual size.
        return note.getDrawingY() - doc.getDrawingUnit(staffSize);
      } else {
        return stemInterface.getDrawingStemEnd(this).y;
      }
    }
    return getDrawingY();
  }
}

/// Mirrors `DurationInterface::GetNoteOrChordDur(const LayerElement*)`: `this`
/// (the DurationInterface) and `element` are always the same object in this
/// port (Note/Chord implement the interface directly), so [element] alone
/// carries both roles.
MeiDuration _noteOrChordDur(LayerElement element) {
  final DurationInterface durationInterface = element as DurationInterface;
  if (element.classId == ClassId.chord) {
    final MeiDuration duration = durationInterface.getActualDur();
    if (duration != MeiDuration.none) return duration;
    final Chord chord = element as Chord;
    for (final Note? note in [chord.getTopNote(), chord.getBottomNote()]) {
      if (note == null) continue;
      final MeiDuration noteDur = note.getActualDur();
      if (noteDur != MeiDuration.none) return noteDur;
    }
  } else if (element.classId == ClassId.note) {
    final Note note = element as Note;
    final Object? chord = note.isChordTone();
    if (chord is Chord && !note.hasDur) {
      return (chord as DurationInterface).getActualDur();
    }
  }
  return durationInterface.getActualDur();
}

/// Headless layout helpers on [Staff] requiring [Doc] (kept out of
/// `basic_elements.dart` to avoid a `Doc` <-> `Staff` import cycle).
extension StaffLayoutHelpers on Staff {
  /// Mirrors `Staff::IsOnStaffLine`.
  bool isOnStaffLine(int y, Doc doc) {
    return (y - getDrawingY())
            .remainder(2 * doc.getDrawingUnit(drawingStaffSize)) ==
        0;
  }

  /// Mirrors `Staff::GetNearestInterStaffPosition`.
  int getNearestInterStaffPosition(int y, Doc doc, Staffrel place) {
    final int unit = doc.getDrawingUnit(drawingStaffSize);
    final int yPos = y - getDrawingY();
    int distance = yPos.remainder(unit);
    if (place == Staffrel.above) {
      if (distance > 0) distance = unit - distance;
      return y - distance + unit;
    } else {
      if (distance < 0) distance = unit + distance;
      return y - distance - unit;
    }
  }
}
