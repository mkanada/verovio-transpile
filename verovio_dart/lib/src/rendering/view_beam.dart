/// Port of `view_beam.cpp` (tasks 05-17, 05-31): beam, FTrem and beamSpan drawing.
///
/// Mirrors `View::DrawBeam`, `DrawFTrem`, `DrawFTremSegment`,
/// `DrawBeamSegment` and `DrawBeamSpan` (view_beam.cpp:34-472).
/// The beam calculation `BeamSegment::CalcBeam` (beam.cpp:89) and
/// `BeamDrawingInterface::InitCoords` (drawinginterface.cpp:140) live in
/// `model/beam_segment.dart` and `model/drawing_interfaces.dart` respectively
/// (task 05-31 ported the full ~1500-line engine).
///
/// Deviations from the C++:
/// - `m_firstNoteOrChord`/`m_lastNoteOrChord` are kept as plain references
///   instead of raw pointers; `m_beamSlope` is a `double` as in the C++.
/// - `BeamSegment::m_stemSameasReverseRole` is a nullable `StemSameasDrawingRole`
///   rather than a raw pointer-to-role (Dart has no pointer-to-enum)

part of 'view.dart';

// ---------------------------------------------------------------------------
// ViewBeam
// ---------------------------------------------------------------------------

const int _partialNone = 0;
const int _partialThrough = 1;
const int _partialRight = 2;
const int _partialLeft = 3;

/// The `view_beam.cpp` methods of [View] (task 05-17).
extension ViewBeam on View {
  // -------------------------------------------------------------------------
  // View::DrawBeam (view_beam.cpp:34)
  // -------------------------------------------------------------------------

  /// Mirrors `View::DrawBeam` (view_beam.cpp:34).
  void drawBeam(
      DeviceContext dc, LayerElement element, Layer layer, Staff staff, Measure measure) {
    final Beam beam = element as Beam;
    if (beam.hasEmptyList()) return;

    // If the beam contains an FTrem, the C++ ignores the beam and just draws
    // its children (view_beam.cpp:52).
    final Object? ftremChild = beam.getFirst(ClassId.fTrem);
    if (ftremChild != null) {
      dc.startGraphic(element, '', element.id);
      drawLayerChildren(dc, beam, layer, staff, measure);
      dc.endGraphic(element);
      return;
    }

    if (beam.beamElementCoordsOwned.isEmpty) {
      beam.initCoords(beam.getList(), staff, beam.drawingPlace);
      final bool isCue = beam.cue == true ||
          beam.getFirstAncestor(ClassId.graceGrp) != null;
      beam.initCue(isCue);
      beam.initGraceStemDir(beam.getFirstAncestor(ClassId.graceGrp) != null);
    }

    final List<BeamElementCoord> coords =
        beam.beamElementCoordsOwned.cast<BeamElementCoord>();
    if (coords.isEmpty) {
      dc.startGraphic(element, '', element.id);
      drawLayerChildren(dc, beam, layer, staff, measure);
      dc.endGraphic(element);
      return;
    }

    beam.beamSegment.initCoordRefs(coords);

    // C++: `data_BEAMPLACE initialPlace = beam->GetPlace()` — the encoded
    // @place, not the computed drawingPlace (view_beam.cpp:58).
    Beamplace initialPlace = beam.place ?? Beamplace.none;
    if (beam.hasStemSameasBeam()) {
      beam.beamSegment.initSameasRoles(beam.stemSameasBeam, initialPlace);
    }

    if (!beam.beamSegment.stemSameasIsSecondary()) {
      beam.beamSegment.calcBeam(layer, staff, doc, beam, initialPlace);
    }

    dc.startGraphic(element, '', element.id);
    drawLayerChildren(dc, beam, layer, staff, measure);
    if (!beam.beamSegment.stemSameasIsSecondary()) {
      drawBeamSegment(dc, beam.beamSegment, beam, layer, staff);
    }
    dc.endGraphic(element);
  }

  // -------------------------------------------------------------------------
  // View::DrawFTrem (view_beam.cpp:91)
  // -------------------------------------------------------------------------

  /// Mirrors `View::DrawFTrem` (view_beam.cpp:91).
  void drawFTrem(
      DeviceContext dc, LayerElement element, Layer layer, Staff staff, Measure measure) {
    final FTrem fTrem = element as FTrem;
    if (fTrem.childCount == 0) return;

    if (fTrem.beamElementCoordsOwned.isEmpty) {
      final List<Object> childList =
          fTrem.children.where((c) => c.isLayerElement).toList();
      fTrem.initCoords(childList, staff, Beamplace.none);
      fTrem.initCue(false);
    }

    final List<BeamElementCoord> coords =
        fTrem.beamElementCoordsOwned.cast<BeamElementCoord>();
    if (coords.length != 2) {
      logDebug('View draw: <fTrem> element has invalid number of descendants.');
      return;
    }

    fTrem.beamSegment.initCoordRefs(coords);
    fTrem.beamSegment.calcBeam(layer, staff, doc, fTrem, Beamplace.none);

    dc.startGraphic(element, '', element.id);
    drawLayerChildren(dc, fTrem, layer, staff, measure);
    drawFTremSegment(dc, staff, fTrem);
    dc.endGraphic(element);
  }

  // -------------------------------------------------------------------------
  // View::DrawFTremSegment (view_beam.cpp:139)
  // -------------------------------------------------------------------------

  /// Mirrors `View::DrawFTremSegment` (view_beam.cpp:139).
  void drawFTremSegment(DeviceContext dc, Staff staff, FTrem fTrem) {
    final List<BeamElementCoord> coords =
        fTrem.beamSegment.beamElementCoordRefs;
    if (coords.length < 2) return;

    final BeamElementCoord firstElement = coords[0];
    final BeamElementCoord secondElement = coords[1];

    final Object? firstEl = firstElement.element;
    if (firstEl == null) return;
    MeiDuration dur = firstElement.dur;
    if (dur == MeiDuration.none) {
      // fallback to element's actual duration if coord dur not set
      if (firstEl is Note) {
        dur = firstEl.getActualDur();
      } else if (firstEl is Chord) {
        dur = firstEl.getActualDur();
      } else {
        dur = MeiDuration.dur8;
      }
    }

    if (dur.value > MeiDuration.dur1.value) {
      final int stemWidth = doc!.getDrawingStemWidth(staff.drawingStaffSize);
      firstElement.x -= stemWidth ~/ 2;
      secondElement.x += stemWidth ~/ 2;
    }

    final int allBars = _fTremGetBeams(fTrem, dur);
    int floatingBars = _fTremGetBeamsFloat(fTrem);
    int fullBars = allBars - floatingBars;

    int y1 = firstElement.yBeam;
    int y2 = secondElement.yBeam;
    int x1 = firstElement.x;
    int x2 = secondElement.x;

    final double shiftY =
        (fTrem.drawingPlace == Beamplace.below) ? 1.0 : -1.0;
    final double dy1 = shiftY;
    final double dy2 = shiftY;

    int space = _getBeamWidthBlack(fTrem, staff);
    // For non-stem notes the bar should be shortened (dur < 2).
    if (dur.value < MeiDuration.dur2.value) {
      if (fTrem.drawingPlace == Beamplace.below) x1 += 2 * space;
      y1 += (2 * space * fTrem.beamSegment.beamSlope).toInt();
      if (fTrem.drawingPlace == Beamplace.above) x2 -= 2 * space;
      y2 -= (2 * space * fTrem.beamSegment.beamSlope).toInt();
      fullBars = allBars;
      floatingBars = 0;
    } else if ((dur.value > MeiDuration.dur2.value) && floatingBars == 0) {
      fullBars = dur.value - MeiDuration.dur4.value;
      floatingBars = allBars - fullBars;
      if (fullBars < 0) fullBars = 0;
      if (floatingBars < 0) floatingBars = 0;
    }

    final int polygonHeight = (fTrem.beamWidthBlack * shiftY).toInt();
    for (int j = 0; j < fullBars; ++j) {
      drawObliquePolygon(dc, x1, y1, x2, y2, polygonHeight);
      y1 += polygonHeight;
      y2 += polygonHeight;
      y1 += (dy1 * fTrem.beamWidthWhite).toInt();
      y2 += (dy2 * fTrem.beamWidthWhite).toInt();
    }

    if (fullBars == 0) {
      y1 += (dy1 * fTrem.beamWidthWhite / 2).toInt();
      y2 += (dy2 * fTrem.beamWidthWhite / 2).toInt();
    }

    x1 += space;
    y1 += (space * fTrem.beamSegment.beamSlope).toInt();
    x2 -= space;
    y2 -= (space * fTrem.beamSegment.beamSlope).toInt();

    for (int j = 0; j < floatingBars; ++j) {
      drawObliquePolygon(dc, x1, y1, x2, y2, polygonHeight);
      y1 += polygonHeight;
      y2 += polygonHeight;
      y1 += (dy1 * fTrem.beamWidthWhite).toInt();
      y2 += (dy2 * fTrem.beamWidthWhite).toInt();
    }
  }

  int _fTremGetBeams(FTrem fTrem, MeiDuration dur) {
    if (fTrem.hasBeams && fTrem.beams != null && fTrem.beams! > 0) {
      return fTrem.beams!;
    }
    if (fTrem.hasUnitdur && fTrem.unitdur != null) {
      return fTrem.unitdur!.value - MeiDuration.dur4.value;
    }
    // Fallback: beams from duration
    if (dur.value >= MeiDuration.dur8.value) {
      return dur.value - MeiDuration.dur4.value;
    }
    return 1;
  }

  int _fTremGetBeamsFloat(FTrem fTrem) {
    if (fTrem.hasBeamsFloat && fTrem.beamsFloat != null) {
      return fTrem.beamsFloat!;
    }
    return 0;
  }

  int _getBeamWidthBlack(BeamDrawingInterface iface, Staff staff) {
    if (iface.beamWidthBlack != 0) return iface.beamWidthBlack;
    final int unit = doc!.getDrawingUnit(staff.drawingStaffSize);
    final bool cue = _isCue(iface);
    int w = unit;
    if (cue) w = (w * doc!.getCueScaling()).toInt();
    return w;
  }

  bool _isCue(BeamDrawingInterface iface) {
    return iface.cueSize;
  }

  // -------------------------------------------------------------------------
  // View::DrawBeamSegment (view_beam.cpp:224)
  // -------------------------------------------------------------------------

  /// Mirrors `View::DrawBeamSegment` (view_beam.cpp:224) — the heart of the file.
  void drawBeamSegment(DeviceContext dc, BeamSegment beamSegment,
      BeamDrawingInterface beamInterface, Layer layer, Staff staff) {
    final List<BeamElementCoord> coords = beamSegment.beamElementCoordRefs;
    if (coords.isEmpty) return;
    final int elementCount = coords.length;
    final int last = elementCount - 1;

    // Adjust x for stem width (view_beam.cpp:251-252).
    final int stemWidth = doc!.getDrawingStemWidth(staff.drawingStaffSize);
    coords[0].x -= stemWidth ~/ 2;
    coords[last].x += stemWidth ~/ 2;

    final int shiftY =
        (beamInterface.drawingPlace == Beamplace.below) ? 1 : -1;

    int y1 = coords[0].yBeam;
    int y2 = coords[last].yBeam;
    int x1 = coords[0].x;
    int x2 = coords[last].x;

    final int polygonHeight = beamInterface.beamWidthBlack * shiftY;
    drawObliquePolygon(dc, x1, y1, x2, y2, polygonHeight);

    // ----- partial bars -----

    // Map noteIndexes ignoring rests except first/last (view_beam.cpp:284-289).
    final List<int> noteIndexes = [];
    for (int i = 0; i < elementCount; ++i) {
      final Object? el = coords[i].element;
      final bool isRest = el != null && _isRest(el);
      if (isRest && i > 0 && i < elementCount - 1) continue;
      noteIndexes.add(i);
    }
    final int noteCount = noteIndexes.length;
    if (noteCount == 0) return;

    MeiDuration durRef = MeiDuration.dur8;
    MeiDuration durRef2 = MeiDuration.dur16;
    // Mirrors `View::DrawBeamSegment` (view_beam.cpp:295): the shifted
    // reference durations apply to French/German/Italian lute tablature and
    // staff-like tablature — notably NOT to `tab.guitar` (covered by the
    // generic `IsTablature`, which excludes staff-like instead).
    final bool isTabShift = staff.isTabLuteFrench() ||
        staff.isTabLuteGerman() ||
        staff.isTabLuteItalian() ||
        staff.isTabStaffLike();
    if (isTabShift) {
      durRef = MeiDuration.dur4;
      durRef2 = MeiDuration.dur8;
    }

    int barY = 0;
    final int fractBeamWidth = doc!.getGlyphWidth(
        0xE0A4, beamInterface.fractionSize, beamInterface.cueSize);

    // Resolve shortestDur – use the interface's shortestDur if set, otherwise max.
    int shortestDurVal = -1;
    final MeiDuration sd = beamInterface.shortestDur;
    if (sd != MeiDuration.none) shortestDurVal = sd.value;
    if (shortestDurVal == -1) {
      for (final c in coords) {
        if (c.dur.value > shortestDurVal) shortestDurVal = c.dur.value;
      }
    }

    int testDur = durRef2.value;
    while (testDur <= shortestDurVal) {
      bool start = true;
      int idx = 0;
      barY += beamInterface.beamWidth;

      for (int i = 0; i < noteCount - 1; ++i) {
        idx = noteIndexes[i];
        final int nextIdx = noteIndexes[i + 1];
        final bool breakSec = (coords[idx].breaksec != 0) &&
            (testDur - durRef.value >= coords[idx].breaksec);
        coords[idx].partialFlags[testDur - durRef.value] = _partialNone;
        if (coords[idx].dur.value >= testDur) {
          if ((coords[nextIdx].dur.value >= testDur) && !breakSec) {
            coords[idx].partialFlags[testDur - durRef.value] = _partialThrough;
          } else {
            if (start) {
              if ((idx != 0) && _isRest(coords[idx - 1].element)) {
                coords[idx].partialFlags[testDur - durRef.value] = _partialLeft;
              } else {
                coords[idx].partialFlags[testDur - durRef.value] = _partialRight;
              }
            } else if (coords[noteIndexes[i - 1]].dur.value < testDur) {
              if (testDur == durRef2.value) {
                coords[idx].partialFlags[testDur - durRef.value] = _partialLeft;
              } else if (coords[noteIndexes[i - 1]]
                      .partialFlags[testDur - 1 - durRef.value] ==
                  _partialThrough) {
                coords[idx].partialFlags[testDur - durRef.value] = _partialLeft;
              } else if (coords[idx]
                      .partialFlags[testDur - 1 - durRef.value] !=
                  _partialLeft) {
                coords[idx].partialFlags[testDur - durRef.value] = _partialRight;
              } else {
                coords[idx].partialFlags[testDur - durRef.value] = _partialLeft;
              }
            }
          }
        }
        start = breakSec;
      }
      // last one
      idx = noteIndexes.last;
      coords[idx].partialFlags[testDur - durRef.value] = _partialNone;
      if (coords[idx].dur.value >= testDur) {
        if ((noteCount == 1) ||
            (coords[noteIndexes[noteCount - 2]].dur.value < testDur) ||
            start) {
          coords[idx].partialFlags[testDur - durRef.value] = _partialLeft;
        }
      }

      // draw them
      for (int i = 0; i < noteCount; ++i) {
        int barYPos = 0;
        idx = noteIndexes[i];
        if (Beamplace.mixed == beamInterface.drawingPlace) {
          int elemIndex = idx;
          if (Beamplace.none == coords[idx].partialFlagPlace) {
            if ((0 == i) ||
                ((noteCount - 1) == i) ||
                (coords[noteIndexes[i - 1]].partialFlagPlace !=
                    coords[noteIndexes[i + 1]].partialFlagPlace)) {
              continue;
            }
            elemIndex = noteIndexes[i - 1];
          }
          barYPos = barY *
              ((Beamplace.above == coords[elemIndex].partialFlagPlace) ? 1 : -1);
        } else {
          barYPos = shiftY * barY;
        }
        final int flag = coords[idx].partialFlags[testDur - durRef.value];
        if (flag == _partialThrough) {
          if (i >= noteCount - 1) continue;
          y1 = coords[idx].yBeam + barYPos;
          y2 = coords[noteIndexes[i + 1]].yBeam + barYPos;
          drawObliquePolygon(dc, coords[idx].x, y1,
              coords[noteIndexes[i + 1]].x, y2, polygonHeight);
        } else if (flag == _partialRight) {
          y1 = coords[idx].yBeam + barYPos;
          final int x2p = coords[idx].x + fractBeamWidth;
          final int y2p = (beamSegment.firstNoteOrChord!.yBeam +
                  barYPos +
                  beamSegment.beamSlope * (x2p - beamSegment.firstNoteOrChord!.x))
              .toInt();
          drawObliquePolygon(dc, coords[idx].x, y1, x2p, y2p, polygonHeight);
        } else if (flag == _partialLeft) {
          y2 = coords[idx].yBeam + barYPos;
          final int x1p = coords[idx].x - fractBeamWidth;
          final int y1p = (beamSegment.firstNoteOrChord!.yBeam +
                  barYPos +
                  beamSegment.beamSlope * (x1p - beamSegment.firstNoteOrChord!.x))
              .toInt();
          drawObliquePolygon(dc, x1p, y1p, coords[idx].x, y2, polygonHeight);
        }
      }

      testDur += 1;
    }
  }

  bool _isRest(Object? obj) {
    if (obj == null) return false;
    if (obj is Rest) return true;
    return obj.classId == ClassId.rest;
  }

  // -------------------------------------------------------------------------
  // View::DrawBeamSpan (view_beam.cpp:429)
  // -------------------------------------------------------------------------

  /// Mirrors `View::DrawBeamSpan` (view_beam.cpp:429).
  void drawBeamSpan(
      DeviceContext dc, BeamSpan beamSpan, System system, Object? graphic) {
    if (graphic != null) {
      dc.resumeGraphic(graphic, graphic.id as String);
    } else {
      dc.startGraphic(beamSpan, '', beamSpan.id as String);
    }

    final BeamSpanSegment? segment = beamSpan.getSegmentForSystem(system);
    if (segment != null) {
      segment.reset();
      final List<BeamElementCoord> owned =
          beamSpan.beamElementCoordsOwned.cast<BeamElementCoord>();
      if (owned.isEmpty) {
        final List<Object> elems = beamSpan.beamedElements.cast<Object>();
        if (elems.isNotEmpty) {
          final Staff? staff =
              elems.first.getFirstAncestor(ClassId.staff) as Staff?;
          if (staff != null) {
            beamSpan.initCoords(elems, staff, beamSpan.drawingPlace);
            beamSpan.initCue(beamSpan.cueSize);
            beamSpan.initGraceStemDir(false);
          }
        }
      }
      final List<BeamElementCoord> owned2 =
          beamSpan.beamElementCoordsOwned.cast<BeamElementCoord>();
      if (owned2.isNotEmpty &&
          segment.beginCoord != null &&
          segment.endCoord != null) {
        final int idxFirst = owned2.indexWhere(
            (c) => identical(c.element, segment.beginCoord!.element));
        final int idxLast = owned2.indexWhere(
            (c) => identical(c.element, segment.endCoord!.element));
        if (idxFirst != -1 && idxLast != -1 && idxFirst <= idxLast) {
          final List<BeamElementCoord> slice =
              owned2.sublist(idxFirst, idxLast + 1);
          segment.initCoordRefs(slice);
          Staff? segStaff = segment.staff as Staff?;
          Layer? segLayer = segment.layer as Layer?;
          segStaff ??= system.findDescendantByType(ClassId.staff) as Staff?;
          segLayer ??= system.findDescendantByType(ClassId.layer) as Layer?;
          if (segStaff != null && segLayer != null) {
            segment.calcBeam(
                segLayer, segStaff, doc, beamSpan, beamSpan.drawingPlace);
            segment.appendSpanningCoordinates(segment.measure);
            drawBeamSegment(dc, segment, beamSpan, segLayer, segStaff);
          }
        }
      } else if (segment.beamElementCoordRefs.isNotEmpty) {
        Staff? segStaff = segment.staff as Staff?;
        Layer? segLayer = segment.layer as Layer?;
        if (segStaff != null && segLayer != null) {
          drawBeamSegment(dc, segment, beamSpan, segLayer, segStaff);
        }
      }
    }

    if (graphic != null) {
      dc.endResumedGraphic(graphic);
    } else {
      dc.endGraphic(beamSpan);
    }
  }
}
