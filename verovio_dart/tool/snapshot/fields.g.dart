// GENERATED FILE — do not edit.
// Source: cpp_probe/snapshot/fields.manifest
// Regenerate: dart run tool/gen_snapshot_fields.dart
//
// The C++ twin is cpp_probe/snapshot/vrvsnapshot_fields.inc.
// ignore_for_file: unnecessary_cast, unnecessary_parenthesis

import 'package:verovio_dart/src/core/bounding_box.dart' show BoundingBox;
import 'package:verovio_dart/src/core/point.dart' show Point;
import 'package:verovio_dart/src/layout/floating_positioner.dart' show FloatingCurvePositioner, FloatingPositioner;
import 'package:verovio_dart/src/layout/horizontal_aligner.dart' show Alignment, AlignmentReference, GraceAligner, MeasureAligner;
import 'package:verovio_dart/src/layout/vertical_aligner.dart' show StaffAlignment, SystemAligner;
import 'package:verovio_dart/src/model/basic_elements.dart' show BarLine, Layer, Measure, Note, Staff;
import 'package:verovio_dart/src/model/control_elements_gen.dart' show Slur;
import 'package:verovio_dart/src/model/doc.dart' show Doc, Page;
import 'package:verovio_dart/src/model/drawing_interfaces.dart' show BeamDrawingInterface, StemmedDrawingInterface;
import 'package:verovio_dart/src/model/floating_object.dart' show FloatingObject;
import 'package:verovio_dart/src/model/interfaces/position_interface.dart' show PositionInterface;
import 'package:verovio_dart/src/model/interfaces/time_interface.dart' show TimePointInterface, TimeSpanningInterface;
import 'package:verovio_dart/src/model/layer_element.dart' show LayerElement;
import 'package:verovio_dart/src/model/layer_elements_gen.dart' show Accid, Artic, Beam, Dots, Flag, KeySig, Stem, Syl, Tuplet, TupletBracket;
import 'package:verovio_dart/src/model/staffdef_drawing_interface.dart' show StaffDefDrawingInterface;
import 'package:verovio_dart/src/model/system_page_elements.dart' show System;

import 'recorder.dart' show Row, dotLocs, priv;

/// Functors whose checkpoints are skipped (the manifest's `@skip-functors`).
final RegExp kSkipFunctors = RegExp(r'^(Find.*|AddToFlatListFunctor|_?GetAlignmentLeftRightFunctor|CountFunctor)$');

/// C++ classes deriving from ConstFunctor / DocConstFunctor: the C++ side never
/// hooks the const `Object::Process`, so their Dart runs are not checkpoints.
const Set<String> kCppConstFunctors = {
  'AddToFlatListFunctor',
  'AdjustTupletNumOverlapFunctor',
  'DocConstFunctor',
  'FindAllBetweenFunctor',
  'FindAllConstByComparisonFunctor',
  'FindAllReferencedObjectsFunctor',
  'FindAllReferringObjectsFunctor',
  'FindByComparisonFunctor',
  'FindByIDFunctor',
  'FindElementInLayerStaffDefFunctor',
  'FindExtremeByComparisonFunctor',
  'FindNextChildByComparisonFunctor',
  'FindPreviousChildByComparisonFunctor',
  'FindSpannedLayerElementsFunctor',
  'GenerateFeaturesFunctor',
  'GenerateMIDIFunctor',
  'GenerateTimemapFunctor',
  'GetAlignmentLeftRightFunctor',
  'GetRelativeLayerElementFunctor',
  'InitMIDIFunctor',
  'InitProcessingListsFunctor',
  'LayerElementsInTimeSpanFunctor',
  'LayersInTimeSpanFunctor',
};

/// Group bits, as in the C++ runtime.
const Map<String, int> kGroups = {
  'bb': 1,
  'pos': 2,
  'link': 4,
  'layout': 8,
  'cache': 16,
};

/// Field name -> (group, C++ class, C++ expression), for reports.
const Map<String, (String, String, String)> kFieldOrigins = {
  'sx1': ('bb', 'BoundingBox', 'o->GetSelfX1()'),
  'sy1': ('bb', 'BoundingBox', 'o->GetSelfY1()'),
  'sx2': ('bb', 'BoundingBox', 'o->GetSelfX2()'),
  'sy2': ('bb', 'BoundingBox', 'o->GetSelfY2()'),
  'cx1': ('bb', 'BoundingBox', 'o->GetContentX1()'),
  'cy1': ('bb', 'BoundingBox', 'o->GetContentY1()'),
  'cx2': ('bb', 'BoundingBox', 'o->GetContentX2()'),
  'cy2': ('bb', 'BoundingBox', 'o->GetContentY2()'),
  'cdx': ('cache', 'BoundingBox', 'o->m_cachedDrawingX'),
  'cdy': ('cache', 'BoundingBox', 'o->m_cachedDrawingY'),
  'dPageW': ('layout', 'Doc', 'o->m_drawingPageWidth'),
  'dPageH': ('layout', 'Doc', 'o->m_drawingPageHeight'),
  'dContentW': ('layout', 'Doc', 'o->m_drawingPageContentWidth'),
  'dContentH': ('layout', 'Doc', 'o->m_drawingPageContentHeight'),
  'dMarginB': ('layout', 'Doc', 'o->m_drawingPageMarginBottom'),
  'dMarginL': ('layout', 'Doc', 'o->m_drawingPageMarginLeft'),
  'dMarginR': ('layout', 'Doc', 'o->m_drawingPageMarginRight'),
  'dMarginT': ('layout', 'Doc', 'o->m_drawingPageMarginTop'),
  'dBeamMaxSlope': ('layout', 'Doc', 'IF(o->m_drawingPageWidth != -1: o->m_drawingBeamMaxSlope)'),
  'dBeamW': ('layout', 'Doc', 'IF(o->m_drawingPageWidth != -1: o->m_drawingBeamWidth)'),
  'dBeamWhiteW': ('layout', 'Doc', 'IF(o->m_drawingPageWidth != -1: o->m_drawingBeamWhiteWidth)'),
  'dSmuflSize': ('layout', 'Doc', 'o->m_drawingSmuflFontSize'),
  'dLyricSize': ('layout', 'Doc', 'o->m_drawingLyricFontSize'),
  'dCastOff': ('layout', 'Doc', 'o->m_isCastOff'),
  'pW': ('layout', 'Page', 'o->m_pageWidth'),
  'pH': ('layout', 'Page', 'o->m_pageHeight'),
  'pMarginB': ('layout', 'Page', 'o->m_pageMarginBottom'),
  'pMarginL': ('layout', 'Page', 'o->m_pageMarginLeft'),
  'pMarginR': ('layout', 'Page', 'o->m_pageMarginRight'),
  'pMarginT': ('layout', 'Page', 'o->m_pageMarginTop'),
  'pPPU': ('layout', 'Page', 'o->m_PPUFactor'),
  'pJustH': ('layout', 'Page', 'o->m_drawingJustifiableHeight'),
  'pJustSum': ('layout', 'Page', 'o->m_justificationSum'),
  'pLayoutDone': ('layout', 'Page', 'o->m_layoutDone'),
  'sysXRel': ('pos', 'System', 'o->m_drawingXRel'),
  'sysYRel': ('pos', 'System', 'o->m_drawingYRel'),
  'sysLeftMar': ('layout', 'System', 'o->m_systemLeftMar'),
  'sysRightMar': ('layout', 'System', 'o->m_systemRightMar'),
  'sysAbbrLabelsW': ('layout', 'System', 'o->m_drawingAbbrLabelsWidth'),
  'sysTotalW': ('layout', 'System', 'o->m_drawingTotalWidth'),
  'sysJustW': ('layout', 'System', 'o->m_drawingJustifiableWidth'),
  'sysCastOffTotalW': ('layout', 'System', 'o->m_castOffTotalWidth'),
  'sysCastOffJustW': ('layout', 'System', 'o->m_castOffJustifiableWidth'),
  'sysOptimized': ('layout', 'System', 'o->m_drawingIsOptimized'),
  'mXRel': ('pos', 'Measure', 'o->m_drawingXRel'),
  'mType': ('layout', 'Measure', 'o->m_measureType'),
  'mIndex': ('layout', 'Measure', 'o->m_index'),
  'mScoreDef': ('link', 'Measure', 'o->m_drawingScoreDef'),
  'mEnding': ('link', 'Measure', 'o->m_drawingEnding'),
  'mCachedXRel': ('cache', 'Measure', 'o->m_cachedXRel'),
  'mCachedWidth': ('cache', 'Measure', 'o->m_cachedWidth'),
  'mCachedOverflow': ('cache', 'Measure', 'o->m_cachedOverflow'),
  'maNonJustLeft': ('layout', 'MeasureAligner', 'o->m_nonJustifiableLeftMargin'),
  'alXRel': ('pos', 'Alignment', 'o->m_xRel'),
  'alTime': ('layout', 'Alignment', 'o->m_time'),
  'alType': ('layout', 'Alignment', 'o->m_type'),
  'refLayerCount': ('layout', 'AlignmentReference', 'o->m_layerCount'),
  'refElements': ('link', 'AlignmentReference', 'EACH(c in o->GetChildren(): c)'),
  'gaWidth': ('layout', 'GraceAligner', 'o->m_totalWidth'),
  'saBottom': ('link', 'SystemAligner', 'o->m_bottomAlignment'),
  'stYRel': ('pos', 'StaffAlignment', 'o->m_yRel'),
  'stOverflowAbove': ('layout', 'StaffAlignment', 'o->m_overflowAbove'),
  'stOverflowBelow': ('layout', 'StaffAlignment', 'o->m_overflowBelow'),
  'stOverlap': ('layout', 'StaffAlignment', 'o->m_overlap'),
  'stReqAbove': ('layout', 'StaffAlignment', 'o->m_requestedSpaceAbove'),
  'stReqBelow': ('layout', 'StaffAlignment', 'o->m_requestedSpaceBelow'),
  'stReqSpacing': ('layout', 'StaffAlignment', 'o->m_requestedSpacing'),
  'stStaffHeight': ('layout', 'StaffAlignment', 'o->m_staffHeight'),
  'stClefOverflowAbove': ('layout', 'StaffAlignment', 'o->m_scoreDefClefOverflowAbove'),
  'stClefOverflowBelow': ('layout', 'StaffAlignment', 'o->m_scoreDefClefOverflowBelow'),
  'stSpacingType': ('layout', 'StaffAlignment', 'o->m_spacingType'),
  'stVersesAbove': ('layout', 'StaffAlignment', 'SORTED(o->m_verseAboveNs)'),
  'stVersesBelow': ('layout', 'StaffAlignment', 'SORTED(o->m_verseBelowNs)'),
  'stStaff': ('link', 'StaffAlignment', 'o->m_staff'),
  'stOverflowAboveBBs': ('cache', 'StaffAlignment', 'EACH(b in o->m_overflowAboveBBoxes: b)'),
  'stOverflowBelowBBs': ('cache', 'StaffAlignment', 'EACH(b in o->m_overflowBelowBBoxes: b)'),
  'foCurrentPositioner': ('link', 'FloatingObject', 'o->m_currentPositioner'),
  'foGrpId': ('layout', 'FloatingObject', 'o->m_drawingGrpId'),
  'foMaxYRel': ('layout', 'FloatingObject', 'o->m_maxDrawingYRel'),
  'fpXRel': ('pos', 'FloatingPositioner', 'o->m_drawingXRel'),
  'fpYRel': ('pos', 'FloatingPositioner', 'o->m_drawingYRel'),
  'fpExtenderW': ('layout', 'FloatingPositioner', 'o->m_drawingExtenderWidth'),
  'fpPlace': ('layout', 'FloatingPositioner', 'o->m_place'),
  'fpSpanningType': ('layout', 'FloatingPositioner', 'o->m_spanningType'),
  'fpObject': ('link', 'FloatingPositioner', 'o->m_object'),
  'fpObjectX': ('link', 'FloatingPositioner', 'o->m_objectX'),
  'fpObjectY': ('link', 'FloatingPositioner', 'o->m_objectY'),
  'fpAlignment': ('link', 'FloatingPositioner', 'o->m_alignment'),
  'cvPoints': ('layout', 'FloatingCurvePositioner', 'EACH(p in o->m_points: p.x, p.y)'),
  'cvThickness': ('layout', 'FloatingCurvePositioner', 'o->m_thickness'),
  'cvDir': ('layout', 'FloatingCurvePositioner', 'o->m_dir'),
  'cvReqStaffSpace': ('layout', 'FloatingCurvePositioner', 'o->m_requestedStaffSpace'),
  'cvDiscarded': ('layout', 'FloatingCurvePositioner', 'EACH(s in o->m_spannedElements: s->m_discarded)'),
  'cvCrossStaff': ('link', 'FloatingCurvePositioner', 'o->m_crossStaff'),
  'cvSpanned': ('link', 'FloatingCurvePositioner', 'EACH(s in o->m_spannedElements: s->m_boundingBox)'),
  'cvCachedMinMaxY': ('cache', 'FloatingCurvePositioner', 'o->m_cachedMinMaxY'),
  'cvCachedX12': ('cache', 'FloatingCurvePositioner', 'std::vector<int>{o->m_cachedX12.first, o->m_cachedX12.second}'),
  'staffLines': ('layout', 'Staff', 'o->m_drawingLines'),
  'staffNotationType': ('layout', 'Staff', 'o->m_drawingNotationType'),
  'staffSize': ('layout', 'Staff', 'o->m_drawingStaffSize'),
  'staffRotation': ('layout', 'Staff', 'o->m_drawingRotation'),
  'staffIsOssia': ('layout', 'Staff', 'o->m_isOssia'),
  'ledgerAbove': ('layout', 'Staff', 'EACH(l in o->m_ledgerLinesAbove: (int)l.m_dashes.size(), EACH(d in l.m_dashes: d.m_x1, d.m_x2))'),
  'ledgerBelow': ('layout', 'Staff', 'EACH(l in o->m_ledgerLinesBelow: (int)l.m_dashes.size(), EACH(d in l.m_dashes: d.m_x1, d.m_x2))'),
  'ledgerAboveCue': ('layout', 'Staff', 'EACH(l in o->m_ledgerLinesAboveCue: (int)l.m_dashes.size(), EACH(d in l.m_dashes: d.m_x1, d.m_x2))'),
  'ledgerBelowCue': ('layout', 'Staff', 'EACH(l in o->m_ledgerLinesBelowCue: (int)l.m_dashes.size(), EACH(d in l.m_dashes: d.m_x1, d.m_x2))'),
  'staffAlignment': ('link', 'Staff', 'o->m_staffAlignment'),
  'staffDrawingStaffDef': ('link', 'Staff', 'o->m_drawingStaffDef'),
  'layerStemDir': ('layout', 'Layer', 'o->m_drawingStemDir'),
  'layerCrossFromAbove': ('layout', 'Layer', 'o->m_crossStaffFromAbove'),
  'layerCrossFromBelow': ('layout', 'Layer', 'o->m_crossStaffFromBelow'),
  'sdDrawClef': ('layout', 'StaffDefDrawingInterface', 'o->m_drawClef'),
  'sdDrawKeySig': ('layout', 'StaffDefDrawingInterface', 'o->m_drawKeySig'),
  'sdDrawMensur': ('layout', 'StaffDefDrawingInterface', 'o->m_drawMensur'),
  'sdDrawMeterSig': ('layout', 'StaffDefDrawingInterface', 'o->m_drawMeterSig'),
  'sdDrawMeterSigGrp': ('layout', 'StaffDefDrawingInterface', 'o->m_drawMeterSigGrp'),
  'xRel': ('pos', 'LayerElement', 'o->m_drawingXRel'),
  'yRel': ('pos', 'LayerElement', 'o->m_drawingYRel'),
  'alignment': ('link', 'LayerElement', 'o->m_alignment'),
  'graceAlignment': ('link', 'LayerElement', 'o->m_graceAlignment'),
  'alignmentLayerN': ('link', 'LayerElement', 'o->m_alignmentLayerN'),
  'crossStaff': ('link', 'LayerElement', 'o->m_crossStaff'),
  'crossLayer': ('link', 'LayerElement', 'o->m_crossLayer'),
  'cueSize': ('layout', 'LayerElement', 'o->m_drawingCueSize'),
  'scoreDefRole': ('layout', 'LayerElement', 'o->m_scoreDefRole'),
  'inBeamSpan': ('layout', 'LayerElement', 'o->m_isInBeamspan'),
  'facsX': ('layout', 'LayerElement', 'o->m_drawingFacsX'),
  'facsY': ('layout', 'LayerElement', 'o->m_drawingFacsY'),
  'cachedXRel': ('cache', 'LayerElement', 'o->m_cachedXRel'),
  'cachedYRel': ('cache', 'LayerElement', 'o->m_cachedYRel'),
  'loc': ('pos', 'PositionInterface', 'o->m_drawingLoc'),
  'stem': ('link', 'StemmedDrawingInterface', 'o->m_drawingStem'),
  'tStart': ('link', 'TimePointInterface', 'o->m_start'),
  'tEnd': ('link', 'TimeSpanningInterface', 'o->m_end'),
  'stemDir': ('layout', 'Stem', 'o->m_drawingStemDir'),
  'stemLen': ('layout', 'Stem', 'o->m_drawingStemLen'),
  'stemMod': ('layout', 'Stem', 'o->m_drawingStemMod'),
  'stemModRelY': ('layout', 'Stem', 'o->m_stemModRelY'),
  'stemAdjust': ('layout', 'Stem', 'o->m_drawingStemAdjust'),
  'stemVirtual': ('layout', 'Stem', 'o->m_isVirtual'),
  'noteFlipped': ('layout', 'Note', 'o->m_flippedNotehead'),
  'noteGroupPos': ('layout', 'Note', 'o->m_noteGroupPosition'),
  'noteSameasRole': ('layout', 'Note', 'o->m_stemSameasRole'),
  'accidSameLayer': ('layout', 'Accid', 'o->m_alignedWithSameLayer'),
  'accidUnison': ('link', 'Accid', 'o->m_drawingUnison'),
  'dotLocs': ('layout', 'Dots', 'DotLocs(o)'),
  'dotsAdjusted': ('layout', 'Dots', 'o->m_isAdjusted'),
  'dotsFlagShift': ('layout', 'Dots', 'o->m_flagShift'),
  'flagCount': ('layout', 'Flag', 'o->m_drawingNbFlags'),
  'tbXRelLeft': ('pos', 'TupletBracket', 'o->m_drawingXRelLeft'),
  'tbXRelRight': ('pos', 'TupletBracket', 'o->m_drawingXRelRight'),
  'tbYRelLeft': ('pos', 'TupletBracket', 'o->m_drawingYRelLeft'),
  'tbYRelRight': ('pos', 'TupletBracket', 'o->m_drawingYRelRight'),
  'tupletBracketPos': ('layout', 'Tuplet', 'o->m_drawingBracketPos'),
  'tupletLeft': ('link', 'Tuplet', 'o->m_drawingLeft'),
  'tupletRight': ('link', 'Tuplet', 'o->m_drawingRight'),
  'tupletBracketBeam': ('link', 'Tuplet', 'o->m_bracketAlignedBeam'),
  'tupletNumBeam': ('link', 'Tuplet', 'o->m_numAlignedBeam'),
  'articPlace': ('layout', 'Artic', 'o->m_drawingPlace'),
  'sylVerseN': ('layout', 'Syl', 'o->m_drawingVerseN'),
  'sylVersePlace': ('layout', 'Syl', 'o->m_drawingVersePlace'),
  'ksSkipCancel': ('layout', 'KeySig', 'o->m_skipCancellation'),
  'ksCancelType': ('layout', 'KeySig', 'o->m_drawingCancelAccidType'),
  'ksCancelCount': ('layout', 'KeySig', 'o->m_drawingCancelAccidCount'),
  'barLinePosition': ('layout', 'BarLine', 'o->m_position'),
  'slurCurveDir': ('layout', 'Slur', 'o->m_drawingCurveDir'),
  'bdPlace': ('layout', 'BeamDrawingInterface', 'o->m_drawingPlace'),
  'bdWidth': ('layout', 'BeamDrawingInterface', 'o->m_beamWidth'),
  'bdWidthBlack': ('layout', 'BeamDrawingInterface', 'o->m_beamWidthBlack'),
  'bdWidthWhite': ('layout', 'BeamDrawingInterface', 'o->m_beamWidthWhite'),
  'bdFractionSize': ('layout', 'BeamDrawingInterface', 'o->m_fractionSize'),
  'bdChangingDur': ('layout', 'BeamDrawingInterface', 'o->m_changingDur'),
  'bdHasChord': ('layout', 'BeamDrawingInterface', 'o->m_beamHasChord'),
  'bdMultipleStemDir': ('layout', 'BeamDrawingInterface', 'o->m_hasMultipleStemDir'),
  'bdCueSize': ('layout', 'BeamDrawingInterface', 'o->m_cueSize'),
  'bdSpanning': ('layout', 'BeamDrawingInterface', 'o->m_isSpanningElement'),
  'bdShortestDur': ('layout', 'BeamDrawingInterface', 'o->m_shortestDur'),
  'bdNotesStemDir': ('layout', 'BeamDrawingInterface', 'o->m_notesStemDir'),
  'bdCrossStaffRel': ('layout', 'BeamDrawingInterface', 'o->m_crossStaffRel'),
  'bdCoordMisc': ('layout', 'BeamDrawingInterface', 'EACH(c in o->m_beamElementCoords: c->m_dur, c->m_breaksec, c->m_overlapMargin, c->m_beamRelativePlace, c->m_partialFlagPlace)'),
  'bdCoordElements': ('link', 'BeamDrawingInterface', 'EACH(c in o->m_beamElementCoords: c->m_element)'),
  'bdCrossStaffContent': ('link', 'BeamDrawingInterface', 'o->m_crossStaffContent'),
  'bdBeamStaff': ('link', 'BeamDrawingInterface', 'o->m_beamStaff'),
  'bsSlope': ('layout', 'Beam', 'o->m_beamSegment.m_beamSlope'),
  'bsVerticalCenter': ('layout', 'Beam', 'o->m_beamSegment.m_verticalCenter'),
  'bsLedgerAbove': ('layout', 'Beam', 'o->m_beamSegment.m_ledgerLinesAbove'),
  'bsLedgerBelow': ('layout', 'Beam', 'o->m_beamSegment.m_ledgerLinesBelow'),
  'bsUniformStemLen': ('layout', 'Beam', 'o->m_beamSegment.m_uniformStemLength'),
  'bsWeightedPlace': ('layout', 'Beam', 'o->m_beamSegment.m_weightedPlace'),
  'bsSameasRole': ('layout', 'Beam', 'o->m_beamSegment.m_stemSameasRole'),
  'bsCoordX': ('layout', 'Beam', 'IF(o->m_beamSegment.m_firstNoteOrChord != NULL: EACH(c in o->m_beamSegment.m_beamElementCoordRefs: c->m_x))'),
  'bsCoordYBeam': ('layout', 'Beam', 'IF(o->m_beamSegment.m_firstNoteOrChord != NULL: EACH(c in o->m_beamSegment.m_beamElementCoordRefs: c->m_yBeam))'),
  'beamStemSameas': ('link', 'Beam', 'o->m_stemSameas'),
};

/// Emits the manifest fields of [bb] into [row] (mirrors `EmitFields` in the C++).
void emitFields(BoundingBox bb, Row row) {
  {
    final BoundingBox o = bb;
    if (row.wants(1 /* bb */)) row.i('sx1', o.getSelfX1());
    if (row.wants(1 /* bb */)) row.i('sy1', o.getSelfY1());
    if (row.wants(1 /* bb */)) row.i('sx2', o.getSelfX2());
    if (row.wants(1 /* bb */)) row.i('sy2', o.getSelfY2());
    if (row.wants(1 /* bb */)) row.i('cx1', o.getContentX1());
    if (row.wants(1 /* bb */)) row.i('cy1', o.getContentY1());
    if (row.wants(1 /* bb */)) row.i('cx2', o.getContentX2());
    if (row.wants(1 /* bb */)) row.i('cy2', o.getContentY2());
    if (row.wants(16 /* cache */)) row.i('cdx', o.cachedDrawingX);
    if (row.wants(16 /* cache */)) row.i('cdy', o.cachedDrawingY);
  }
  if (bb is Doc) {
    final Doc o = bb as Doc;
    if (row.wants(8 /* layout */)) row.i('dPageW', o.drawingPageWidth);
    if (row.wants(8 /* layout */)) row.i('dPageH', o.drawingPageHeight);
    if (row.wants(8 /* layout */)) row.i('dContentW', o.drawingPageContentWidth);
    if (row.wants(8 /* layout */)) row.i('dContentH', o.drawingPageContentHeight);
    if (row.wants(8 /* layout */)) row.i('dMarginB', o.drawingPageMarginBottom);
    if (row.wants(8 /* layout */)) row.i('dMarginL', o.drawingPageMarginLeft);
    if (row.wants(8 /* layout */)) row.i('dMarginR', o.drawingPageMarginRight);
    if (row.wants(8 /* layout */)) row.i('dMarginT', o.drawingPageMarginTop);
    if (row.wants(8 /* layout */) && (o.drawingPageWidth != -1)) row.d('dBeamMaxSlope', o.drawingBeamMaxSlope);
    if (row.wants(8 /* layout */) && (o.drawingPageWidth != -1)) row.i('dBeamW', o.drawingBeamWidth);
    if (row.wants(8 /* layout */) && (o.drawingPageWidth != -1)) row.i('dBeamWhiteW', o.drawingBeamWhiteWidth);
    if (row.wants(8 /* layout */)) row.i('dSmuflSize', o.drawingSmuflFontSize);
    if (row.wants(8 /* layout */)) row.i('dLyricSize', o.drawingLyricFontSize);
    if (row.wants(8 /* layout */)) row.b('dCastOff', o.isCastOff());
  }
  if (bb is Page) {
    final Page o = bb as Page;
    if (row.wants(8 /* layout */)) row.i('pW', o.pageWidth);
    if (row.wants(8 /* layout */)) row.i('pH', o.pageHeight);
    if (row.wants(8 /* layout */)) row.i('pMarginB', o.pageMarginBottom);
    if (row.wants(8 /* layout */)) row.i('pMarginL', o.pageMarginLeft);
    if (row.wants(8 /* layout */)) row.i('pMarginR', o.pageMarginRight);
    if (row.wants(8 /* layout */)) row.i('pMarginT', o.pageMarginTop);
    if (row.wants(8 /* layout */)) row.d('pPPU', o.ppufactor);
    if (row.wants(8 /* layout */)) row.i('pJustH', o.drawingJustifiableHeight);
    if (row.wants(8 /* layout */)) row.d('pJustSum', o.justificationSum);
    if (row.wants(8 /* layout */)) row.b('pLayoutDone', o.layoutDone);
  }
  if (bb is System) {
    final System o = bb as System;
    if (row.wants(2 /* pos */)) row.i('sysXRel', o.getDrawingXRel());
    if (row.wants(2 /* pos */)) row.i('sysYRel', o.getDrawingYRel());
    if (row.wants(8 /* layout */)) row.i('sysLeftMar', o.systemLeftMar);
    if (row.wants(8 /* layout */)) row.i('sysRightMar', o.systemRightMar);
    if (row.wants(8 /* layout */)) row.i('sysAbbrLabelsW', o.drawingAbbrLabelsWidth);
    if (row.wants(8 /* layout */)) row.i('sysTotalW', o.drawingTotalWidth);
    if (row.wants(8 /* layout */)) row.i('sysJustW', o.drawingJustifiableWidth);
    if (row.wants(8 /* layout */)) row.i('sysCastOffTotalW', o.castOffTotalWidth);
    if (row.wants(8 /* layout */)) row.i('sysCastOffJustW', o.castOffJustifiableWidth);
    if (row.wants(8 /* layout */)) row.b('sysOptimized', o.drawingIsOptimized);
  }
  if (bb is Measure) {
    final Measure o = bb as Measure;
    if (row.wants(2 /* pos */)) row.i('mXRel', o.getDrawingXRel());
    if (row.wants(8 /* layout */)) row.i('mType', o.measureType.index);
    if (row.wants(8 /* layout */)) row.i('mIndex', o.index);
    if (row.wants(4 /* link */)) row.r('mScoreDef', o.drawingScoreDef);
    if (row.wants(4 /* link */)) row.r('mEnding', o.drawingEnding);
    if (row.wants(16 /* cache */)) row.i('mCachedXRel', o.getCachedXRel());
    if (row.wants(16 /* cache */)) row.i('mCachedWidth', o.getCachedWidth());
    if (row.wants(16 /* cache */)) row.i('mCachedOverflow', o.getCachedOverflow());
  }
  if (bb is MeasureAligner) {
    final MeasureAligner o = bb as MeasureAligner;
    if (row.wants(8 /* layout */)) row.i('maNonJustLeft', o.getNonJustifiableMargin());
  }
  if (bb is Alignment) {
    final Alignment o = bb as Alignment;
    if (row.wants(2 /* pos */)) row.i('alXRel', o.getXRel());
    if (row.wants(8 /* layout */)) row.f('alTime', o.getTime());
    if (row.wants(8 /* layout */)) row.i('alType', o.getType().value);
  }
  if (bb is AlignmentReference) {
    final AlignmentReference o = bb as AlignmentReference;
    if (row.wants(8 /* layout */)) row.i('refLayerCount', priv(o, '_layerCount') as int);
    if (row.wants(4 /* link */)) row.refs('refElements', [for (final c in o.children) c]);
  }
  if (bb is GraceAligner) {
    final GraceAligner o = bb as GraceAligner;
    if (row.wants(8 /* layout */)) row.i('gaWidth', o.getWidth());
  }
  if (bb is SystemAligner) {
    final SystemAligner o = bb as SystemAligner;
    if (row.wants(4 /* link */)) row.r('saBottom', o.getBottomAlignment());
  }
  if (bb is StaffAlignment) {
    final StaffAlignment o = bb as StaffAlignment;
    if (row.wants(2 /* pos */)) row.i('stYRel', o.getYRel());
    if (row.wants(8 /* layout */)) row.i('stOverflowAbove', o.getOverflowAbove());
    if (row.wants(8 /* layout */)) row.i('stOverflowBelow', o.getOverflowBelow());
    if (row.wants(8 /* layout */)) row.i('stOverlap', o.getOverlap());
    if (row.wants(8 /* layout */)) row.i('stReqAbove', o.getRequestedSpaceAbove());
    if (row.wants(8 /* layout */)) row.i('stReqBelow', o.getRequestedSpaceBelow());
    if (row.wants(8 /* layout */)) row.i('stReqSpacing', o.getRequestedSpacing());
    if (row.wants(8 /* layout */)) row.i('stStaffHeight', o.getStaffHeight());
    if (row.wants(8 /* layout */)) row.i('stClefOverflowAbove', o.getScoreDefClefOverflowAbove());
    if (row.wants(8 /* layout */)) row.i('stClefOverflowBelow', o.getScoreDefClefOverflowBelow());
    if (row.wants(8 /* layout */)) row.i('stSpacingType', o.getSpacingType().index);
    if (row.wants(8 /* layout */)) row.ints('stVersesAbove', ([...(priv(o, '_verseAboveNs') as Set<int>)]..sort()));
    if (row.wants(8 /* layout */)) row.ints('stVersesBelow', ([...(priv(o, '_verseBelowNs') as Set<int>)]..sort()));
    if (row.wants(4 /* link */)) row.r('stStaff', o.getStaff());
    if (row.wants(16 /* cache */)) row.refs('stOverflowAboveBBs', [for (final b in (priv(o, '_overflowAboveBBoxes') as List<BoundingBox>)) b]);
    if (row.wants(16 /* cache */)) row.refs('stOverflowBelowBBs', [for (final b in (priv(o, '_overflowBelowBBoxes') as List<BoundingBox>)) b]);
  }
  if (bb is FloatingObject) {
    final FloatingObject o = bb as FloatingObject;
    if (row.wants(4 /* link */)) row.r('foCurrentPositioner', o.currentPositioner);
    if (row.wants(8 /* layout */)) row.i('foGrpId', o.drawingGrpId);
    if (row.wants(8 /* layout */)) row.i('foMaxYRel', o.maxDrawingYRel);
  }
  if (bb is FloatingPositioner) {
    final FloatingPositioner o = bb as FloatingPositioner;
    if (row.wants(2 /* pos */)) row.i('fpXRel', o.getDrawingXRel());
    if (row.wants(2 /* pos */)) row.i('fpYRel', o.getDrawingYRel());
    if (row.wants(8 /* layout */)) row.i('fpExtenderW', o.getDrawingExtenderWidth());
    if (row.wants(8 /* layout */)) row.i('fpPlace', o.getDrawingPlace().value);
    if (row.wants(8 /* layout */)) row.i('fpSpanningType', o.getSpanningType());
    if (row.wants(4 /* link */)) row.r('fpObject', o.getObject());
    if (row.wants(4 /* link */)) row.r('fpObjectX', o.getObjectX());
    if (row.wants(4 /* link */)) row.r('fpObjectY', o.getObjectY());
    if (row.wants(4 /* link */)) row.r('fpAlignment', o.getStaffAlignment());
  }
  if (bb is FloatingCurvePositioner) {
    final FloatingCurvePositioner o = bb as FloatingCurvePositioner;
    if (row.wants(8 /* layout */)) row.ints('cvPoints', [for (final p in (priv(o, '_points') as List<Point>)) ...[p.x, p.y]]);
    if (row.wants(8 /* layout */)) row.i('cvThickness', o.getThickness());
    if (row.wants(8 /* layout */)) row.i('cvDir', o.getDir().value);
    if (row.wants(8 /* layout */)) row.i('cvReqStaffSpace', o.getRequestedStaffSpace());
    if (row.wants(8 /* layout */)) row.ints('cvDiscarded', [for (final s in o.getSpannedElements()) s.discarded ? 1 : 0]);
    if (row.wants(4 /* link */)) row.r('cvCrossStaff', o.crossStaff);
    if (row.wants(4 /* link */)) row.refs('cvSpanned', [for (final s in o.getSpannedElements()) s.boundingBox]);
    if (row.wants(16 /* cache */)) row.i('cvCachedMinMaxY', priv(o, '_cachedMinMaxY') as int);
    if (row.wants(16 /* cache */)) row.ints('cvCachedX12', [priv(o, '_cachedX1') as int, priv(o, '_cachedX2') as int]);
  }
  if (bb is Staff) {
    final Staff o = bb as Staff;
    if (row.wants(8 /* layout */)) row.i('staffLines', o.drawingLines);
    if (row.wants(8 /* layout */)) row.i('staffNotationType', (o.drawingNotationtype?.value ?? 0));
    if (row.wants(8 /* layout */)) row.i('staffSize', o.drawingStaffSize);
    if (row.wants(8 /* layout */)) row.d('staffRotation', o.drawingRotation);
    if (row.wants(8 /* layout */)) row.b('staffIsOssia', o.isOssiaFlag);
    if (row.wants(8 /* layout */)) row.ints('ledgerAbove', [for (final l in o.ledgerLinesAbove) ...[l.dashes.length, ...[for (final d in l.dashes) ...[d.x1, d.x2]]]]);
    if (row.wants(8 /* layout */)) row.ints('ledgerBelow', [for (final l in o.ledgerLinesBelow) ...[l.dashes.length, ...[for (final d in l.dashes) ...[d.x1, d.x2]]]]);
    if (row.wants(8 /* layout */)) row.ints('ledgerAboveCue', [for (final l in o.ledgerLinesAboveCue) ...[l.dashes.length, ...[for (final d in l.dashes) ...[d.x1, d.x2]]]]);
    if (row.wants(8 /* layout */)) row.ints('ledgerBelowCue', [for (final l in o.ledgerLinesBelowCue) ...[l.dashes.length, ...[for (final d in l.dashes) ...[d.x1, d.x2]]]]);
    if (row.wants(4 /* link */)) row.r('staffAlignment', o.staffAlignment);
    if (row.wants(4 /* link */)) row.r('staffDrawingStaffDef', o.drawingStaffDef);
  }
  if (bb is Layer) {
    final Layer o = bb as Layer;
    if (row.wants(8 /* layout */)) row.i('layerStemDir', o.drawingStemDir.value);
    if (row.wants(8 /* layout */)) row.b('layerCrossFromAbove', o.crossStaffFromAbove);
    if (row.wants(8 /* layout */)) row.b('layerCrossFromBelow', o.crossStaffFromBelow);
  }
  if (bb is StaffDefDrawingInterface) {
    final StaffDefDrawingInterface o = bb as StaffDefDrawingInterface;
    if (row.wants(8 /* layout */)) row.b('sdDrawClef', priv(o, '_drawClef') as bool);
    if (row.wants(8 /* layout */)) row.b('sdDrawKeySig', priv(o, '_drawKeySig') as bool);
    if (row.wants(8 /* layout */)) row.b('sdDrawMensur', priv(o, '_drawMensur') as bool);
    if (row.wants(8 /* layout */)) row.b('sdDrawMeterSig', priv(o, '_drawMeterSig') as bool);
    if (row.wants(8 /* layout */)) row.b('sdDrawMeterSigGrp', priv(o, '_drawMeterSigGrp') as bool);
  }
  if (bb is LayerElement) {
    final LayerElement o = bb as LayerElement;
    if (row.wants(2 /* pos */)) row.i('xRel', o.drawingXRel);
    if (row.wants(2 /* pos */)) row.i('yRel', o.drawingYRel);
    if (row.wants(4 /* link */)) row.r('alignment', o.getAlignment());
    if (row.wants(4 /* link */)) row.r('graceAlignment', o.getGraceAlignment());
    if (row.wants(4 /* link */)) row.i('alignmentLayerN', o.getAlignmentLayerN());
    if (row.wants(4 /* link */)) row.r('crossStaff', o.crossStaff);
    if (row.wants(4 /* link */)) row.r('crossLayer', o.crossLayer);
    if (row.wants(8 /* layout */)) row.b('cueSize', o.drawingCueSize);
    if (row.wants(8 /* layout */)) row.i('scoreDefRole', o.scoreDefRole.index);
    if (row.wants(8 /* layout */)) row.b('inBeamSpan', o.isInBeamSpan);
    if (row.wants(8 /* layout */)) row.i('facsX', o.drawingFacsX);
    if (row.wants(8 /* layout */)) row.i('facsY', o.drawingFacsY);
    if (row.wants(16 /* cache */)) row.i('cachedXRel', priv(o, '_cachedXRel') as int);
    if (row.wants(16 /* cache */)) row.i('cachedYRel', priv(o, '_cachedYRel') as int);
  }
  if (bb is PositionInterface) {
    final PositionInterface o = bb as PositionInterface;
    if (row.wants(2 /* pos */)) row.i('loc', o.drawingLoc);
  }
  if (bb is StemmedDrawingInterface) {
    final StemmedDrawingInterface o = bb as StemmedDrawingInterface;
    if (row.wants(4 /* link */)) row.r('stem', o.getDrawingStem());
  }
  if (bb is TimePointInterface) {
    final TimePointInterface o = bb as TimePointInterface;
    if (row.wants(4 /* link */)) row.r('tStart', o.getStart());
  }
  if (bb is TimeSpanningInterface) {
    final TimeSpanningInterface o = bb as TimeSpanningInterface;
    if (row.wants(4 /* link */)) row.r('tEnd', o.getEnd());
  }
  if (bb is Stem) {
    final Stem o = bb as Stem;
    if (row.wants(8 /* layout */)) row.i('stemDir', o.drawingStemDir.value);
    if (row.wants(8 /* layout */)) row.i('stemLen', o.drawingStemLen);
    if (row.wants(8 /* layout */)) row.i('stemMod', (o.drawingStemMod?.value ?? 0));
    if (row.wants(8 /* layout */)) row.i('stemModRelY', o.stemModRelY);
    if (row.wants(8 /* layout */)) row.i('stemAdjust', o.drawingStemAdjust);
    if (row.wants(8 /* layout */)) row.b('stemVirtual', o.isVirtual);
  }
  if (bb is Note) {
    final Note o = bb as Note;
    if (row.wants(8 /* layout */)) row.b('noteFlipped', o.flippedNotehead);
    if (row.wants(8 /* layout */)) row.i('noteGroupPos', o.noteGroupPosition);
    if (row.wants(8 /* layout */)) row.i('noteSameasRole', o.stemSameasRole.index);
  }
  if (bb is Accid) {
    final Accid o = bb as Accid;
    if (row.wants(8 /* layout */)) row.b('accidSameLayer', o.alignedWithSameLayer);
    if (row.wants(4 /* link */)) row.r('accidUnison', o.drawingUnisonAccid);
  }
  if (bb is Dots) {
    final Dots o = bb as Dots;
    if (row.wants(8 /* layout */)) row.ints('dotLocs', [...(dotLocs(o))]);
    if (row.wants(8 /* layout */)) row.b('dotsAdjusted', o.isAdjusted);
    if (row.wants(8 /* layout */)) row.i('dotsFlagShift', o.flagShift);
  }
  if (bb is Flag) {
    final Flag o = bb as Flag;
    if (row.wants(8 /* layout */)) row.i('flagCount', o.drawingNbFlags);
  }
  if (bb is TupletBracket) {
    final TupletBracket o = bb as TupletBracket;
    if (row.wants(2 /* pos */)) row.i('tbXRelLeft', o.drawingXRelLeft);
    if (row.wants(2 /* pos */)) row.i('tbXRelRight', o.drawingXRelRight);
    if (row.wants(2 /* pos */)) row.i('tbYRelLeft', o.drawingYRelLeft);
    if (row.wants(2 /* pos */)) row.i('tbYRelRight', o.drawingYRelRight);
  }
  if (bb is Tuplet) {
    final Tuplet o = bb as Tuplet;
    if (row.wants(8 /* layout */)) row.i('tupletBracketPos', o.drawingBracketPos.value);
    if (row.wants(4 /* link */)) row.r('tupletLeft', o.drawingLeft);
    if (row.wants(4 /* link */)) row.r('tupletRight', o.drawingRight);
    if (row.wants(4 /* link */)) row.r('tupletBracketBeam', o.bracketAlignedBeam);
    if (row.wants(4 /* link */)) row.r('tupletNumBeam', o.numAlignedBeam);
  }
  if (bb is Artic) {
    final Artic o = bb as Artic;
    if (row.wants(8 /* layout */)) row.i('articPlace', o.drawingPlace.value);
  }
  if (bb is Syl) {
    final Syl o = bb as Syl;
    if (row.wants(8 /* layout */)) row.i('sylVerseN', o.drawingVerseN);
    if (row.wants(8 /* layout */)) row.i('sylVersePlace', (o.drawingVersePlace?.value ?? 0));
  }
  if (bb is KeySig) {
    final KeySig o = bb as KeySig;
    if (row.wants(8 /* layout */)) row.b('ksSkipCancel', o.skipCancellation);
    if (row.wants(8 /* layout */)) row.i('ksCancelType', o.drawingCancelAccidType.value);
    if (row.wants(8 /* layout */)) row.i('ksCancelCount', o.drawingCancelAccidCount);
  }
  if (bb is BarLine) {
    final BarLine o = bb as BarLine;
    if (row.wants(8 /* layout */)) row.i('barLinePosition', o.position.index);
  }
  if (bb is Slur) {
    final Slur o = bb as Slur;
    if (row.wants(8 /* layout */)) row.i('slurCurveDir', o.drawingCurveDir.index);
  }
  if (bb is BeamDrawingInterface) {
    final BeamDrawingInterface o = bb as BeamDrawingInterface;
    if (row.wants(8 /* layout */)) row.i('bdPlace', o.drawingPlace.value);
    if (row.wants(8 /* layout */)) row.i('bdWidth', o.beamWidth);
    if (row.wants(8 /* layout */)) row.i('bdWidthBlack', o.beamWidthBlack);
    if (row.wants(8 /* layout */)) row.i('bdWidthWhite', o.beamWidthWhite);
    if (row.wants(8 /* layout */)) row.i('bdFractionSize', o.fractionSize);
    if (row.wants(8 /* layout */)) row.b('bdChangingDur', o.changingDur);
    if (row.wants(8 /* layout */)) row.b('bdHasChord', o.beamHasChord);
    if (row.wants(8 /* layout */)) row.b('bdMultipleStemDir', o.hasMultipleStemDir);
    if (row.wants(8 /* layout */)) row.b('bdCueSize', o.cueSize);
    if (row.wants(8 /* layout */)) row.b('bdSpanning', o.isSpanningElement);
    if (row.wants(8 /* layout */)) row.i('bdShortestDur', o.shortestDur.value);
    if (row.wants(8 /* layout */)) row.i('bdNotesStemDir', o.notesStemDir.value);
    if (row.wants(8 /* layout */)) row.i('bdCrossStaffRel', o.crossStaffRel.value);
    if (row.wants(8 /* layout */)) row.ints('bdCoordMisc', [for (final c in o.beamElementCoordsOwned) ...[c.dur.value, c.breaksec, c.overlapMargin, c.beamRelativePlace.value, c.partialFlagPlace.value]]);
    if (row.wants(4 /* link */)) row.refs('bdCoordElements', [for (final c in o.beamElementCoordsOwned) c.element]);
    if (row.wants(4 /* link */)) row.r('bdCrossStaffContent', o.crossStaffContent);
    if (row.wants(4 /* link */)) row.r('bdBeamStaff', o.beamStaff);
  }
  if (bb is Beam) {
    final Beam o = bb as Beam;
    if (row.wants(8 /* layout */)) row.d('bsSlope', o.beamSegment.beamSlope);
    if (row.wants(8 /* layout */)) row.i('bsVerticalCenter', o.beamSegment.verticalCenter);
    if (row.wants(8 /* layout */)) row.i('bsLedgerAbove', o.beamSegment.ledgerLinesAbove);
    if (row.wants(8 /* layout */)) row.i('bsLedgerBelow', o.beamSegment.ledgerLinesBelow);
    if (row.wants(8 /* layout */)) row.i('bsUniformStemLen', o.beamSegment.uniformStemLength);
    if (row.wants(8 /* layout */)) row.i('bsWeightedPlace', o.beamSegment.weightedPlace.value);
    if (row.wants(8 /* layout */)) row.i('bsSameasRole', o.beamSegment.stemSameasRole.index);
    if (row.wants(8 /* layout */) && (o.beamSegment.firstNoteOrChord != null)) row.ints('bsCoordX', [for (final c in o.beamSegment.beamElementCoordRefs) c.x]);
    if (row.wants(8 /* layout */) && (o.beamSegment.firstNoteOrChord != null)) row.ints('bsCoordYBeam', [for (final c in o.beamSegment.beamElementCoordRefs) c.yBeam]);
    if (row.wants(4 /* link */)) row.r('beamStemSameas', o.stemSameasBeam);
  }
}
