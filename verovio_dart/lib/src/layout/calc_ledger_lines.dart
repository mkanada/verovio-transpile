/// Port of `calcledgerlinesfunctor.h/cpp`: computes the ledger (leger) lines
/// above/below a staff for notes and accidentals whose pitch falls outside
/// the staff lines, mirroring `vrv::CalcLedgerLinesFunctor`.
///
/// Runs twice in the C++ (`Page::LayOutVertically`, right after
/// `ResetVerticalAlignmentFunctor` and before `AlignVerticallyFunctor`; and
/// `Page::LayOutPitchPos`, after `CalcStemFunctor`) — see `doc.dart` for both
/// wiring points.
library;

import 'package:verovio_dart/src/core/attdef.dart' show MeiDuration;
import 'package:verovio_dart/src/core/smufl.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/layout/functor.dart';
import 'package:verovio_dart/src/layout/preparedata_functor.dart'
    show LayoutElementHelpers;
import 'package:verovio_dart/src/model/atts/mei_enums.dart'
    show Horizontalalignment;
import 'package:verovio_dart/src/model/basic_elements.dart'
    show Dash, LedgerLine, Note, Staff;
import 'package:verovio_dart/src/model/doc.dart' show Doc;
import 'package:verovio_dart/src/model/interfaces/position_interface.dart';
import 'package:verovio_dart/src/model/layer_element.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart' show Accid;
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/rendering/glyph.dart' show Glyph;
import 'package:verovio_dart/src/rendering/resources.dart' show Resources;

/// Calculates the ledger lines (mirrors `vrv::CalcLedgerLinesFunctor`).
class CalcLedgerLinesFunctor extends DocFunctor {
  CalcLedgerLinesFunctor(super.doc);

  @override
  FunctorCode visitAccid(Accid accid) {
    if (accid.getFirstAncestor(ClassId.note) != null || !accid.hasAccid) {
      return FunctorCode.siblings;
    }

    final Staff staff = accid.getAncestorStaffLayout();

    final int width = _docGetGlyphWidth(
        doc, Accid.getAccidGlyph(accid.accid!), staff.drawingStaffSize, false);

    _calcForLayerElement(accid, width, Horizontalalignment.center);

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitNote(Note note) {
    if (note.hasVisible && note.visible == false) {
      return FunctorCode.siblings;
    }

    if (!note.isVisible()) {
      return FunctorCode.siblings;
    }

    final int radius = _noteDrawingRadius(note, doc);

    _calcForLayerElement(note, 2 * radius, Horizontalalignment.left);

    return FunctorCode.siblings;
  }

  /// Mirrors `CalcLedgerLinesFunctor::CalcForLayerElement`.
  void _calcForLayerElement(
      LayerElement layerElement, int width, Horizontalalignment alignment) {
    final Staff staff = layerElement.getAncestorStaffResolveCrossStaff()!;

    final int staffSize = staff.drawingStaffSize;
    final int staffX = staff.getDrawingX();
    final bool drawingCueSize = layerElement.drawingCueSize;

    final PositionInterface interface = layerElement as PositionInterface;
    final (bool hasLines, int linesAbove, int linesBelow) =
        interface.hasLedgerLines(staff);
    if (!hasLines) return;

    final int extension =
        doc.getDrawingLedgerLineExtension(staffSize, drawingCueSize);
    int left = layerElement.getDrawingX() - extension - staffX;
    int right = layerElement.getDrawingX() + width + extension - staffX;

    if (alignment == Horizontalalignment.center) {
      right -= width ~/ 2;
      left -= width ~/ 2;
    }

    // Deviation: the C++ optionally attaches the LayerElement as the dash's
    // "event" object when `--svg-html5` is on, for interactive hover; option
    // plumbing has not arrived yet (see CLAUDE.md), so the event is always
    // omitted here. It has no effect on the dash extents computed below.
    const Object? event = null;

    if (linesAbove > 0) {
      staff.addLedgerLineAbove(
          linesAbove, left, right, extension, drawingCueSize, event);
    } else {
      staff.addLedgerLineBelow(
          linesBelow, left, right, extension, drawingCueSize, event);
    }
  }

  @override
  FunctorCode visitStaffEnd(Staff staff) {
    final int extension =
        doc.getDrawingLedgerLineExtension(staff.drawingStaffSize, false);
    final int minExtension = doc.getDrawingMinimalLedgerLineExtension(
        staff.drawingStaffSize, false);
    final double cueScaling = doc.getCueScaling();
    _adjustLedgerLines(staff.getLedgerLinesAbove(),
        staff.getLedgerLinesAboveCue(), cueScaling, extension, minExtension);
    _adjustLedgerLines(staff.getLedgerLinesBelow(),
        staff.getLedgerLinesBelowCue(), cueScaling, extension, minExtension);

    return FunctorCode.continue_;
  }

  /// Mirrors `CalcLedgerLinesFunctor::AdjustLedgerLines`: shortens ledger
  /// lines which overlap with neighbors.
  ///
  /// By construction, any overlaps or small gaps in outer dash lines must
  /// also occur in the innermost dash line. It thus suffices to resolve any
  /// problems in the innermost dash line and apply the adjustments to the
  /// corresponding dashes further away from the staff.
  void _adjustLedgerLines(List<LedgerLine> lines, List<LedgerLine> cueLines,
      double cueScaling, int extension, int minExtension) {
    // For each dash on the inner line (both cue and normal) construct an
    // adjustment with zero delta, then sort them.
    final List<_Adjustment> adjustments = [];
    if (lines.isNotEmpty) {
      for (final Dash dash in lines.first.dashes) {
        adjustments.add(_Adjustment(dash.x1, dash.x2, false));
      }
    }
    if (cueLines.isNotEmpty) {
      for (final Dash dash in cueLines.first.dashes) {
        adjustments.add(_Adjustment(dash.x1, dash.x2, true));
      }
    }

    adjustments.sort((a, b) {
      if (a.left != b.left) return a.left.compareTo(b.left);
      return a.right.compareTo(b.right);
    });

    // By comparing successive dashes, compute the necessary adjustment
    // (delta) for each of them.
    final int defaultGap = 100 * extension; // large enough to never trigger.
    int leftGapProportion = defaultGap;

    for (int i = 0; i < adjustments.length; i++) {
      final _Adjustment current = adjustments[i];
      final _Adjustment? next =
          i + 1 < adjustments.length ? adjustments[i + 1] : null;
      final int rightGap = next != null ? next.left - current.right : defaultGap;
      final bool nextIsCue = next?.isCue ?? false;

      final double currentCueScale = current.isCue ? cueScaling : 1.0;
      final double nextCueScale = nextIsCue ? cueScaling : 1.0;
      final int rightGapProportion =
          (currentCueScale / (currentCueScale + nextCueScale) * rightGap)
              .toInt();
      final int nextLeftGapProportion =
          (nextCueScale / (currentCueScale + nextCueScale) * rightGap).toInt();

      // The gap between successive dashes should be at least one extension.
      final int minGapProportion =
          leftGapProportion < rightGapProportion ? leftGapProportion : rightGapProportion;
      if (minGapProportion < currentCueScale * extension / 2.0) {
        final int minTotal =
            (minGapProportion + currentCueScale * extension).toInt();
        final int newExtension = _maxInt((2 * minTotal / 3).toInt(),
            (currentCueScale * minExtension).toInt());
        current.delta = (currentCueScale * extension).toInt() - newExtension;
        assert(current.delta >= 0);
      }

      leftGapProportion = nextLeftGapProportion;
    }

    // Finally, transfer the adjustments to all ledger lines — every dash on
    // the same note/chord obtains the same ledger line extension.
    for (final _Adjustment adjustment in adjustments) {
      if (adjustment.delta > 0) {
        final List<LedgerLine> linesToAdjust =
            adjustment.isCue ? cueLines : lines;
        for (final LedgerLine line in linesToAdjust) {
          for (final Dash dash in line.dashes) {
            if (dash.x1 >= adjustment.left && dash.x2 <= adjustment.right) {
              dash.x1 += adjustment.delta;
              dash.x2 -= adjustment.delta;
              break;
            }
          }
        }
      }
    }
  }
}

int _maxInt(int a, int b) => a > b ? a : b;

/// One dash-boundary adjustment (mirrors the local `Adjustment` struct in
/// `CalcLedgerLinesFunctor::AdjustLedgerLines`).
class _Adjustment {
  _Adjustment(this.left, this.right, this.isCue);

  final int left;
  final int right;
  final bool isCue;
  int delta = 0;
}

/// Mirrors `LayerElement::GetDrawingRadius` reduced to the `Note` branch —
/// the only one `CalcLedgerLinesFunctor::VisitNote` ever calls it on. Reads
/// real SMuFL glyph metrics from `Resources` (same pattern as
/// `View+BBoxDeviceContext.glyphWidth` / `adjust_tuplets.dart`'s `_getDrawingRadius`),
/// falling back to `Doc.getGlyphWidth`'s tabulated approximation when the
/// fonts are unavailable.
///
/// Deviation: mensural noteheads (`Note::GetMensuralNoteheadGlyph`) are not
/// ported — this port's mensural notation does not reach ledger lines yet.
int _noteDrawingRadius(Note note, Doc doc) {
  final int code = _noteheadGlyphForDur(note.getDrawingDur());
  final Staff staff = note.getAncestorStaffLayout();
  return _docGetGlyphWidth(doc, code, staff.drawingStaffSize, note.drawingCueSize) ~/
      2;
}

/// Mirrors `Note::GetNoteheadGlyph` duration mapping (note.cpp).
int _noteheadGlyphForDur(MeiDuration dur) {
  if (dur == MeiDuration.breve) return smuflE0A1NoteheadDoubleWholeSquare;
  if (dur == MeiDuration.longa) return smuflE0A1NoteheadDoubleWholeSquare;
  if (dur == MeiDuration.dur1) return smuflE0A2NoteheadWhole;
  if (dur == MeiDuration.dur2) return smuflE0A3NoteheadHalf;
  return smuflE0A4NoteheadBlack;
}

/// Mirrors `Doc::GetGlyphWidth(code, staffSize, graceSize)` (resources
/// backed); falls back to the tabulated approximation of `Doc.getGlyphWidth`
/// when the fonts are unavailable. Same pattern as `adjust_tuplets.dart`'s
/// `_docGetGlyphWidth` and `mensural_neume.dart`'s equivalent.
int _docGetGlyphWidth(Doc doc, int code, int staffSize, bool graceSize) {
  _LedgerGlyphMetrics.ensure();
  final Resources resources = _LedgerGlyphMetrics.resources;
  final Glyph? glyph =
      _LedgerGlyphMetrics.ok ? resources.getGlyphByCode(code) : null;
  if (glyph == null) {
    return doc.getGlyphWidth(code, staffSize, graceSize);
  }
  int pointSize = (doc.options.unit.value * 8 * staffSize / 100).toInt();
  if (graceSize) pointSize = doc.getCueSize(pointSize);
  return (glyph.horizAdvX * pointSize) ~/ glyph.unitsPerEm;
}

class _LedgerGlyphMetrics {
  static bool _done = false;
  static late final Resources resources;

  static void ensure() {
    if (_done) return;
    _done = true;
    // Repo convention (00-MESTRE §4.6): consumers must point the resources
    // at the package assets folder; the static default ('data') is wrong for
    // this layout.
    final Resources res = Resources();
    res.path = 'assets/data';
    if (!res.ok) res.initFonts();
    resources = res;
  }

  static bool get ok => resources.ok;
}
