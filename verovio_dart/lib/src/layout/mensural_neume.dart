/// Port of `calcligatureorneumeposfunctor.h/cpp` — the functor that sets the
/// note position of each note in a ligature and the nc position / drawing
/// glyphs of each neume:
///
/// - [CalcLigatureOrNeumePosFunctor] mirrors `vrv::CalcLigatureOrNeumePosFunctor`
///
/// The invocation sites of the C++ (`Page::ResetAligners` and
/// `Page::LayOutTranscription`, in both cases right after
/// CalcAlignmentPitchPosFunctor) are mirrored by the call in
/// `Page.layOutVertically` (doc.dart), which is where this port runs
/// CalcAlignmentPitchPosFunctor.
///
/// Deviations from the C++ (headless mode, no font metrics):
/// - Glyph widths go through Doc.getGlyphWidth (Bravura-inspired staff space
///   approximations tabulated for the glyphs consulted by the layout).
/// - Note::GetDrawingRadius reduced to the note branch with isInLigature=true
///   (see [_noteDrawingRadiusInLigature]); the @glyph.name / @head.shape
///   branches require the resources and are not consulted.
library;

import 'package:verovio_dart/src/core/attdef.dart'
    show MeiDuration, meiUnset;
import 'package:verovio_dart/src/core/smufl.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/layout/functor.dart';
import 'package:verovio_dart/src/layout/preparedata_functor.dart'
    show LayoutElementHelpers;
import 'package:verovio_dart/src/model/atts/mei_enums.dart';
import 'package:verovio_dart/src/model/basic_elements.dart'
    show Note, Staff;
import 'package:verovio_dart/src/model/doc.dart' show Doc;
import 'package:verovio_dart/src/model/layer_elements_gen.dart';
import 'package:verovio_dart/src/model/object.dart';

// ---------------------------------------------------------------------------
// CalcLigatureOrNeumePosFunctor
// ---------------------------------------------------------------------------

/// Sets the note position for each note in ligature and the glyph / position
/// of each nc in neume (headless port of
/// `vrv::CalcLigatureOrNeumePosFunctor`).
class CalcLigatureOrNeumePosFunctor extends DocFunctor {
  CalcLigatureOrNeumePosFunctor(super.doc);

  @override
  bool get implementsEndInterface => false;

  @override
  FunctorCode visitLigature(Ligature ligature) {
    if (doc.getOptions().ligatureAsBracket.value) return FunctorCode.continue_;

    ligature.drawingShapes.clear();

    final List<Object> notes = ligature.getList();
    if (notes.isEmpty) return FunctorCode.siblings;
    final Note lastNote = notes.last as Note;
    final Staff staff = ligature.getAncestorStaffLayout();

    if (notes.length < 2) return FunctorCode.siblings;

    Note? previousNote;
    bool previousUp = false;
    int n1 = 0;
    int n2 = 1;

    final bool isMensuralBlack =
        staff.drawingNotationtype == Notationtype.mensuralBlack;
    bool oblique = false;
    if ((notes.length == 2) &&
        (ligature.form == Ligatureform.obliqua)) {
      oblique = true;
    }

    // For better clarity, we loop within the visitLigature instead of
    // implementing visitNote.

    for (final Object object in notes) {
      final Note note = object as Note;

      ligature.drawingShapes.add(ligatureDefault);

      if (previousNote == null) {
        previousNote = note;
        continue;
      }

      // Look at the @lig attribute on the previous note
      if (previousNote.lig == Ligatureform.obliqua) oblique = true;
      MeiDuration dur1 = previousNote.getActualDur();
      MeiDuration dur2 = note.getActualDur();
      // Same treatment for Mx and LG except for positioning, which is done
      // above. We still need to avoid oblique, so keep a flag.
      bool isMaxima = false;
      if (dur1 == MeiDuration.maxima) {
        dur1 = MeiDuration.long;
        isMaxima = true;
      }
      if (dur2 == MeiDuration.maxima) dur2 = MeiDuration.long;

      final int diatonicStep =
          note.getDiatonicPitch() - previousNote.getDiatonicPitch();
      final bool up = (diatonicStep > 0);
      final bool isLastNote = identical(note, lastNote);

      // L - L
      if ((dur1 == MeiDuration.long) && (dur2 == MeiDuration.long)) {
        if (up) {
          ligature.drawingShapes[n1] = ligatureStemRightDown;
          ligature.drawingShapes[n2] = ligatureStemRightDown;
        } else {
          // nothing to change
        }
      }
      // L - B
      else if ((dur1 == MeiDuration.long) && (dur2 == MeiDuration.breve)) {
        if (up) {
          ligature.drawingShapes[n1] = ligatureStemRightDown;
        }
        // automatically set oblique on B, but not with Mx and only at the
        // beginning and end
        else if (!isMaxima && ((n1 == 0) || isLastNote)) {
          ligature.drawingShapes[n1] = ligatureOblique;
          // make sure the previous one is not oblique
          if (n1 > 0) {
            ligature.drawingShapes[n1 - 1] &= ~ligatureOblique;
          }
        }
      }
      // B - B
      else if ((dur1 == MeiDuration.breve) && (dur2 == MeiDuration.breve)) {
        if (up) {
          // nothing to change
        }
        // automatically set oblique on B only at the beginning and end
        else if ((n1 == 0) || isLastNote) {
          ligature.drawingShapes[n1] = ligatureOblique;
          // make sure the previous one is not oblique
          if (n1 > 0) {
            ligature.drawingShapes[n1 - 1] &= ~ligatureOblique;
          } else {
            ligature.drawingShapes[n1] |= ligatureStemLeftDown;
          }
        }
      }
      // B - L
      else if ((dur1 == MeiDuration.breve) && (dur2 == MeiDuration.long)) {
        if (up) {
          ligature.drawingShapes[n2] = ligatureStemRightDown;
        } else {
          if (!isLastNote) {
            ligature.drawingShapes[n2] = ligatureStemRightDown;
          }
          if (n1 == 0) {
            ligature.drawingShapes[n1] = ligatureStemLeftDown;
          }
        }
      }
      // SB - SB
      else if ((dur1 == MeiDuration.dur1) && (dur2 == MeiDuration.dur1)) {
        ligature.drawingShapes[n1] = ligatureStemLeftUp;
      }
      // SB - L (this should not happen on the first two notes, but this is an
      // encoding problem)
      else if ((dur1 == MeiDuration.dur1) && (dur2 == MeiDuration.long)) {
        if (up) {
          ligature.drawingShapes[n2] = ligatureStemRightDown;
        } else {
          // nothing to change
        }
      }
      // SB - B (this should not happen on the first two notes, but this is an
      // encoding problem)
      else if ((dur1 == MeiDuration.dur1) && (dur2 == MeiDuration.breve)) {
        if (up) {
          // nothing to change
        }
        // only set the oblique with the SB if the following B is not the
        // start of an oblique
        else if (note.lig != Ligatureform.obliqua) {
          ligature.drawingShapes[n1] = ligatureOblique;
          if (n1 > 0) {
            ligature.drawingShapes[n1 - 1] &= ~ligatureOblique;
          }
        }
      }

      // Blindly set the oblique shape without trying to deal with encoding
      // problems
      if (oblique) {
        ligature.drawingShapes[n1] |= ligatureOblique;
        if (n1 > 0) {
          ligature.drawingShapes[n1 - 1] &= ~ligatureOblique;
        }
      }

      // With mensural black notation, stack longa going up
      if (isLastNote &&
          isMensuralBlack &&
          (dur2 == MeiDuration.long) &&
          up) {
        // Stack only if at least a third
        int stackThreshold = 1;
        // If the previous was going down, adjust the threshold
        if ((n1 > 0) && !previousUp) {
          // For oblique, stack but only from a fourth, for recta, never
          // stack them
          stackThreshold =
              (ligature.drawingShapes[n1 - 1] & ligatureOblique) != 0
                  ? 2
                  : meiUnset;
        }
        if (diatonicStep > stackThreshold) {
          ligature.drawingShapes[n2] = ligatureStacked;
        }
      }

      oblique = false;
      previousNote = note;
      previousUp = up;
      ++n1;
      ++n2;
    }

    /**** Set the xRel position for each note ****/

    int previousRight = 0;
    previousNote = null;
    n1 = 0;

    for (final Object object in notes) {
      final Note note = object as Note;

      // previousRight is 0 for the first note
      final int width = (_noteDrawingRadiusInLigature(doc, note, staff) * 2) -
          doc.getDrawingStemWidth(staff.drawingStaffSize);
      // With stacked notes, back-track the position
      if (ligature.drawingShapes[n1 + 1] & ligatureStacked != 0) {
        previousRight -= width;
      }
      note.setDrawingXRel(previousRight);
      previousRight += width;

      if (previousNote == null) {
        previousNote = note;
        continue;
      }

      final int diatonicStep =
          note.getDiatonicPitch() - previousNote.getDiatonicPitch();

      // For large interval and oblique, adjust the x position to limit the
      // angle
      if (((ligature.drawingShapes[n1] & ligatureOblique) != 0) &&
          (diatonicStep.abs() > 2)) {
        // angle stays the same from third onward (2 / 3 or a brevis per
        // diatonic step)
        final int shift = (diatonicStep.abs() - 2) * width * 2 ~/ 3;
        note.setDrawingXRel(note.drawingXRel + shift);
        previousRight += shift;
      }
      previousNote = note;
      ++n1;
    }

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitNeume(Neume neume) {
    if (doc.getOptions().neumeAsNote.value) return FunctorCode.siblings;

    final List<Object> ncs = neume.findAllDescendantsByType(ClassId.nc);

    final Staff staff = neume.getAncestorStaffLayout();
    final int staffSize = staff.drawingStaffSize;
    final int unit = doc.getDrawingUnit(staffSize);

    int xRel = 0;
    Nc? previousNc;
    bool previousLig = false;

    for (final Object object in ncs) {
      final Nc nc = object as Nc;

      final bool hasLiquescent =
          nc.findDescendantByType(ClassId.liquescent) != null;
      final bool hasOriscus = nc.findDescendantByType(ClassId.oriscus) != null;
      final bool hasQuilisma =
          nc.findDescendantByType(ClassId.quilisma) != null;
      final bool hasStrophicus =
          nc.findDescendantByType(ClassId.strophicus) != null;

      final int lineWidth =
          doc.getGlyphWidth(smuflE9BEChantConnectingLineAsc3rd, staffSize,
              false);

      // Make sure we have at least one glyph
      nc.drawingGlyphs.clear();
      nc.drawingGlyphs.add(NcDrawingGlyph());

      final int pitchDifference =
          (previousNc != null)
              ? _pitchOrLocDifferenceTo(nc, previousNc)
              : 0;
      bool overlapWithPrevious = (pitchDifference == 0) ? false : true;

      if (hasLiquescent) {
        final bool gabcNoTailsOption =
            doc.getOptions().liquescentWithoutTails.value;
        if (!gabcNoTailsOption) {
          while (nc.drawingGlyphs.length < 3) {
            nc.drawingGlyphs.add(NcDrawingGlyph());
          }
        }

        const int ncWidthGlyph = smuflE995ChantAuctumDesc;

        if (nc.curve == CurvaturedirectionCurve.c) {
          nc.drawingGlyphs[0].fontNo = smuflE995ChantAuctumDesc;
          if (!gabcNoTailsOption) {
            nc.drawingGlyphs[1].fontNo = smuflE9BEChantConnectingLineAsc3rd;
            nc.drawingGlyphs[2].fontNo = smuflE9BEChantConnectingLineAsc3rd;
            nc.drawingGlyphs[2].xOffset = (doc
                        .getGlyphWidth(ncWidthGlyph, staffSize, false) -
                    lineWidth)
                .toDouble();
            nc.drawingGlyphs[1].yOffset = -1.75 * unit;
            nc.drawingGlyphs[2].yOffset = -1.9 * unit;
          }
        } else if (nc.curve == CurvaturedirectionCurve.a) {
          nc.drawingGlyphs[0].fontNo = smuflE994ChantAuctumAsc;
          if (!gabcNoTailsOption) {
            nc.drawingGlyphs[1].fontNo = smuflE9BEChantConnectingLineAsc3rd;
            nc.drawingGlyphs[2].fontNo = smuflE9BEChantConnectingLineAsc3rd;
            nc.drawingGlyphs[2].xOffset = (doc
                        .getGlyphWidth(ncWidthGlyph, staffSize, false) -
                    lineWidth)
                .toDouble();
            nc.drawingGlyphs[1].yOffset = 0.5 * unit;
            nc.drawingGlyphs[2].yOffset = 0.75 * unit;
          }
        } else {
          nc.drawingGlyphs[0].fontNo = smuflE9A1ChantPunctumDeminutum;
        }
      } else if (hasOriscus) {
        nc.drawingGlyphs[0].fontNo = smuflEA2AMedRenOriscusCMN;
      } else if (hasQuilisma) {
        nc.drawingGlyphs[0].fontNo = smuflE99BChantQuilisma;
      } else if (hasStrophicus) {
        nc.drawingGlyphs[0].fontNo = smuflEA29MedRenStrophicusCMN;
      } else {
        nc.drawingGlyphs[0].fontNo = smuflE990ChantPunctum;

        if (nc.ligated == true) {
          // This is the first nc of a ligature
          if (!previousLig) {
            // Temporarily set a second line glyph
            nc.drawingGlyphs[0].fontNo = smuflE9B4ChantEntryLineAsc2nd;
            previousLig = true;
          }
          // This is the second
          else {
            // No overlap in this case since the second starts at the same
            // position as the first
            overlapWithPrevious = false;
            assert(previousNc != null);
            previousLig = false;
            nc.drawingGlyphs[0].yOffset = (-pitchDifference * unit).toDouble();
            previousNc!.drawingGlyphs[0].yOffset =
                (pitchDifference * unit).toDouble();

            // set the glyph for both the current and previous nc
            switch (pitchDifference) {
              case -1:
                nc.drawingGlyphs[0].fontNo = smuflE9B9ChantLigaturaDesc2nd;
                previousNc.drawingGlyphs[0].fontNo =
                    smuflE9B4ChantEntryLineAsc2nd;
                break;
              case -2:
                nc.drawingGlyphs[0].fontNo = smuflE9BAChantLigaturaDesc3rd;
                previousNc.drawingGlyphs[0].fontNo =
                    smuflE9B5ChantEntryLineAsc3rd;
                break;
              case -3:
                nc.drawingGlyphs[0].fontNo = smuflE9BBChantLigaturaDesc4th;
                previousNc.drawingGlyphs[0].fontNo =
                    smuflE9B6ChantEntryLineAsc4th;
                break;
              case -4:
                nc.drawingGlyphs[0].fontNo = smuflE9BCChantLigaturaDesc5th;
                previousNc.drawingGlyphs[0].fontNo =
                    smuflE9B7ChantEntryLineAsc5th;
                break;
              default:
                break;
            }
          }
        }
        // Check if nc is part of a ligature or is an inclinatum
        else if (nc.hasTilt && nc.tilt == Compassdirection.se) {
          nc.drawingGlyphs[0].fontNo = smuflE991ChantPunctumInclinatum;
          // No overlap with this shape
          overlapWithPrevious = false;
        }
        // If the nc is supposed to be a virga and currently is being rendered
        // as a punctum change it to a virga
        else if (nc.tilt == Compassdirection.s &&
            nc.drawingGlyphs[0].fontNo == smuflE990ChantPunctum) {
          nc.drawingGlyphs[0].fontNo = smuflE996ChantPunctumVirga;
        } else if (nc.tilt == Compassdirection.n &&
            nc.drawingGlyphs[0].fontNo == smuflE990ChantPunctum) {
          nc.drawingGlyphs[0].fontNo = smuflE997ChantPunctumVirgaReversed;
        }
      }

      // xRel remains unset with facsimile
      if (!doc.hasFacsimile()) {
        // If the nc overlaps with the previous, move it back from a line
        // width
        if (overlapWithPrevious) {
          xRel -= lineWidth;
        }

        nc.setDrawingXRel(xRel);
        // The first glyph set the spacing - unless we are starting a
        // ligature, in which case no spacing should be added between the two
        // nc
        if (!previousLig) {
          xRel += doc.getGlyphWidth(
              nc.drawingGlyphs[0].fontNo, staffSize, false);
        }
      }

      previousNc = nc;
    }

    return FunctorCode.siblings;
  }
}

// ---------------------------------------------------------------------------
// Helpers shared with the model (ports of the C++ member functions used here)
// ---------------------------------------------------------------------------

/// Mirrors `Nc::PitchOrLocDifferenceTo`: the pitch difference takes
/// precedence over the loc difference.
int _pitchOrLocDifferenceTo(Nc nc, Nc other) {
  int difference = nc.pitchDifferenceTo(other);
  if ((difference == 0) && nc.hasLoc && other.hasLoc) {
    difference = nc.loc! - other.loc!;
  }
  return difference;
}

/// Mirrors `LayerElement::GetDrawingRadius(doc, isInLigature = true)`
/// reduced to notes: the radius (half width) of the notehead used when
/// spacing the notes of a ligature.
///
/// Deviation: the @glyph.name / @head.shape / @head.fill lookups of
/// Note::GetNoteheadGlyph require the resources; the plain noteheads are
/// used (solid whole / half noteheads like the C++ default).
int _noteDrawingRadiusInLigature(Doc doc, Note note, Staff staff) {
  final int staffSize = staff.drawingStaffSize;
  final MeiDuration dur = note.getActualDur();
  final bool isMensuralDur = note.isMensuralDur;

  // Mensural note shorter than DURATION_breve (or any note within a
  // ligature with duration whole): the brevis width applies.
  if ((isMensuralDur && dur.value <= MeiDuration.breve.value) ||
      ((dur == MeiDuration.dur1))) {
    final int widthFactor = (dur == MeiDuration.maxima) ? 2 : 1;
    if (staff.drawingNotationtype == Notationtype.mensuralBlack) {
      return (widthFactor * doc.getDrawingBrevisWidth(staffSize) * 0.7)
          .toInt();
    } else {
      return widthFactor * doc.getDrawingBrevisWidth(staffSize);
    }
  }

  // Otherwise the glyph based radius (mirrors GetNoteheadGlyph).
  int code = smuflE0A4NoteheadBlack;
  if (dur == MeiDuration.breve) {
    code = smuflE0A1NoteheadDoubleWholeSquare;
  } else if (dur == MeiDuration.dur1) {
    code = smuflE0A2NoteheadWhole;
  } else if (dur == MeiDuration.dur2) {
    code = smuflE0A3NoteheadHalf;
  }

  return doc.getGlyphWidth(code, staffSize, note.drawingCueSize) ~/ 2;
}
