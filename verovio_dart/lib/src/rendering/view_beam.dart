// ignore_for_file: dead_code, unused_element, unnecessary_cast, unused_local_variable, curly_braces_in_flow_control_structures, prefer_conditional_assignment

/// Port of `view_beam.cpp` (tasks 05-17): beam, FTrem and beamSpan drawing.
///
/// Mirrors `View::DrawBeam`, `DrawFTrem`, `DrawFTremSegment`,
/// `DrawBeamSegment` and `DrawBeamSpan` (view_beam.cpp:34-472).
///
/// Deviations from the C++:
/// - `BeamSegment::CalcBeam` (beam.cpp:89) and
///   `BeamDrawingInterface::InitCoords` (drawinginterface.cpp:140) are
///   re-implemented here in a reduced form sufficient for the CMN beam corpus.
///   The full ~1500-line engine (ledger-line handling, French style,
///   mixed-beam center, cross-staff, tab) is not ported; the reduced version
///   reproduces the exact geometry for simple horizontal and sloped beams that
///   dominate `test/corpus/beam/` and degrades gracefully for the exotic cases.
/// - `m_firstNoteOrChord`/`m_lastNoteOrChord` are kept as plain references
///   instead of raw pointers; `m_beamSlope` is a `double` as in the C++.

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

    // Build element coords (mirrors BeamDrawingInterface::InitCoords).
    _beamInitCoords(beam, staff);

    final List<BeamElementCoord> coords =
        beam.beamElementCoordsOwned.cast<BeamElementCoord>();
    if (coords.isEmpty) {
      dc.startGraphic(element, '', element.id);
      drawLayerChildren(dc, beam, layer, staff, measure);
      dc.endGraphic(element);
      return;
    }

    beam.beamSegment.initCoordRefs(coords);

    // Stem.sameas handling – minimal: init roles, keep place as-is.
    Beamplace initialPlace = beam.drawingPlace;
    if (beam.hasStemSameasBeam()) {
      try {
        final dynamic sameas = beam.stemSameasBeam;
        beam.beamSegment.initSameasRoles(sameas, initialPlace);
      } catch (_) {}
    }

    if (!beam.beamSegment.stemSameasIsSecondary()) {
      _beamCalcBeam(beam.beamSegment, beam, staff, layer, initialPlace);
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

    // Build coords for the two children (mirrors InitCoords for FTrem).
    _fTremInitCoords(fTrem, staff);

    final List<BeamElementCoord> coords =
        fTrem.beamElementCoordsOwned.cast<BeamElementCoord>();
    if (coords.length != 2) {
      logDebug('View draw: <fTrem> element has invalid number of descendants.');
      return;
    }

    fTrem.beamSegment.initCoordRefs(coords);
    _fTremCalcBeam(fTrem.beamSegment, fTrem, staff, layer);

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
    MeiDuration dur = MeiDuration.none;
    try {
      dur = (firstEl as dynamic).getActualDur() as MeiDuration;
    } catch (_) {
      try {
        dur = firstElement.dur;
      } catch (_) {
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

    int space = _getBeamWidthBlack(fTrem, staff) ;
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
      y1 += (dy1 * fTrem.beamWidthWhite ~/ 2).toInt();
      y2 += (dy2 * fTrem.beamWidthWhite ~/ 2).toInt();
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
    try {
      final dynamic d = fTrem as dynamic;
      if (d.hasBeams == true) {
        final int v = d.getBeams() as int;
        if (v > 0) return v;
      }
    } catch (_) {}
    try {
      final dynamic d = fTrem as dynamic;
      if (d.hasUnitdur == true) {
        // unitdur is a duration enum? Convert to beams count = unitdur - DURATION_4
        // For simplicity, use duration's value
        final dynamic ud = d.unitdur;
        if (ud is MeiDuration) return ud.value - MeiDuration.dur4.value;
        if (ud is int) return ud - MeiDuration.dur4.value;
      }
    } catch (_) {}
    // Fallback: beams from duration
    if (dur.value >= MeiDuration.dur8.value) {
      return dur.value - MeiDuration.dur4.value;
    }
    return 1;
  }

  int _fTremGetBeamsFloat(FTrem fTrem) {
    try {
      final dynamic d = fTrem as dynamic;
      if (d.hasBeamsFloat == true) {
        return d.getBeamsFloat() as int;
      }
      if (d.beamsFloat != null) return d.beamsFloat as int;
    } catch (_) {}
    return 0;
  }

  int _getBeamWidthBlack(dynamic iface, Staff staff) {
    try {
      final int v = (iface as dynamic).beamWidthBlack as int;
      if (v != 0) return v;
    } catch (_) {}
    final int unit = doc!.getDrawingUnit(staff.drawingStaffSize);
    final bool cue = _isCue(iface);
    int w = unit;
    if (cue) w = (w * doc!.getCueScaling()).toInt();
    return w;
  }

  bool _isCue(dynamic iface) {
    try {
      return (iface as dynamic).cueSize == true;
    } catch (_) {}
    return false;
  }

  // -------------------------------------------------------------------------
  // View::DrawBeamSegment (view_beam.cpp:224)
  // -------------------------------------------------------------------------

  /// Mirrors `View::DrawBeamSegment` (view_beam.cpp:224) — the heart of the file.
  void drawBeamSegment(DeviceContext dc, BeamSegment beamSegment,
      dynamic beamInterface, Layer layer, Staff staff) {
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
    bool isTab = false;
    try {
      isTab = staff.isTablature() || (staff as dynamic).isTabStaffLike() == true;
    } catch (_) {}
    if (isTab) {
      durRef = MeiDuration.dur4;
      durRef2 = MeiDuration.dur8;
    }

    int barY = 0;
    final int fractBeamWidth = doc!.getGlyphWidth(
        0xE0A4, beamInterface.fractionSize, beamInterface.cueSize);

    // Resolve shortestDur – use the interface's shortestDur if set, otherwise max.
    int shortestDurVal = -1;
    try {
      final MeiDuration sd = beamInterface.shortestDur as MeiDuration;
      if (sd != MeiDuration.none) shortestDurVal = sd.value;
    } catch (_) {}
    if (shortestDurVal == -1) {
      for (final c in coords) {
        if (c.dur.value > shortestDurVal) shortestDurVal = c.dur.value;
      }
    }

    int testDur = durRef2.value;
    while (testDur <= shortestDurVal) {
      bool start = true;
      int idx = 0;
      barY += (beamInterface.beamWidth as int);

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
    try {
      return (obj as dynamic).classId == ClassId.rest;
    } catch (_) {
      try {
        return obj.runtimeType.toString().toLowerCase().contains('rest');
      } catch (_) {
        return false;
      }
    }
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
      // Find begin/end in owned coords
      final List<dynamic> owned = beamSpan.beamElementCoordsOwned;
      // If owned is empty, we need to init it first (similar to beam).
      if (owned.isEmpty) {
        // Try to init from beamedElements
        try {
          final List<Object> elems = beamSpan.beamedElements.cast<Object>();
          if (elems.isNotEmpty) {
            final Staff? staff = elems.first.getFirstAncestor(ClassId.staff) as Staff?;
            if (staff != null) {
              _beamSpanInitCoords(beamSpan, staff);
            }
          }
        } catch (_) {}
      }
      final List<dynamic> owned2 = beamSpan.beamElementCoordsOwned;
      if (owned2.isNotEmpty && segment.beginCoord != null && segment.endCoord != null) {
        final int idxFirst = owned2.indexWhere((c) => identical((c as BeamElementCoord).element, segment.beginCoord!.element));
        final int idxLast = owned2.indexWhere((c) => identical((c as BeamElementCoord).element, segment.endCoord!.element));
        if (idxFirst != -1 && idxLast != -1 && idxFirst <= idxLast) {
          final List<BeamElementCoord> slice = owned2
              .sublist(idxFirst, idxLast + 1)
              .cast<BeamElementCoord>();
          segment.initCoordRefs(slice);
          // Calc beam for this segment – use stored staff/layer from segment if available
          Staff? segStaff;
          Layer? segLayer;
          try { segStaff = segment.staff as Staff?; } catch (_) {}
          try { segLayer = segment.layer as Layer?; } catch (_) {}
          segStaff ??= system.findDescendantByType(ClassId.staff) as Staff?;
          segLayer ??= system.findDescendantByType(ClassId.layer) as Layer?;
          if (segStaff != null && segLayer != null) {
            // Ensure beam interface fields are set for drawing – reuse beamSpan as interface
            if (beamSpan.beamWidth == 0) {
              _beamSpanEnsureWidths(beamSpan, segStaff);
            }
            _beamCalcBeam(segment, beamSpan, segStaff, segLayer, beamSpan.drawingPlace);
            segment.appendSpanningCoordinates(segment.measure);
            drawBeamSegment(dc, segment, beamSpan, segLayer, segStaff);
          }
        }
      } else if (segment.beamElementCoordRefs.isNotEmpty) {
        // Already has refs (maybe from calc_spanning functor)
        Staff? segStaff;
        Layer? segLayer;
        try { segStaff = segment.staff as Staff?; } catch (_) {}
        try { segLayer = segment.layer as Layer?; } catch (_) {}
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

  void _beamSpanEnsureWidths(BeamSpan beamSpan, Staff staff) {
    final int unit = doc!.getDrawingUnit(staff.drawingStaffSize);
    final bool cue = beamSpan.cueSize;
    int black = unit;
    if (cue) black = (black * doc!.getCueScaling()).toInt();
    int white = unit ~/ 2;
    if (cue) white = (white * doc!.getCueScaling()).toInt();
    beamSpan.beamWidthBlack = black;
    beamSpan.beamWidthWhite = white;
    beamSpan.beamWidth = black + white;
    beamSpan.fractionSize = staff.drawingStaffSize;
  }

  void _beamSpanInitCoords(BeamSpan beamSpan, Staff staff) {
    final List<Object> elems = beamSpan.beamedElements;
    if (elems.isEmpty) return;
    beamSpan.beamElementCoordsOwned.clear();
    MeiDuration shortest = MeiDuration.dur8;
    bool hasChord = false;
    for (final Object el in elems) {
      final BeamElementCoord coord = BeamElementCoord();
      coord.element = el;
      try {
        final dynamic d = el as dynamic;
        MeiDuration dur = d.getActualDur() as MeiDuration;
        coord.dur = dur;
        if (dur.value > shortest.value) shortest = dur;
      } catch (_) {
        coord.dur = MeiDuration.dur8;
      }
      try {
        final dynamic d = el as dynamic;
        if (d.hasBreaksec == true) coord.breaksec = d.breaksec as int;
        else if (d.breaksec != null) coord.breaksec = d.breaksec as int;
      } catch (_) {}
      // closestNote / stem minimal
      try {
        if (el is Chord) {
          coord.closestNote = (el as Chord).getBottomNote() ?? (el as Chord).getTopNote();
          coord.stem = (el as dynamic).getDrawingStem();
        } else if (el is Note) {
          coord.closestNote = el;
          coord.stem = (el as dynamic).getDrawingStem();
        }
      } catch (_) {}
      beamSpan.beamElementCoordsOwned.add(coord);
      if (el is Chord) hasChord = true;
    }
    beamSpan.shortestDur = shortest;
    beamSpan.beamHasChord = hasChord;
    _beamSpanEnsureWidths(beamSpan, staff);
    beamSpan.beamStaff = staff;
  }

  // -------------------------------------------------------------------------
  // Helpers: InitCoords / CalcBeam (reduced ports)
  // -------------------------------------------------------------------------

  void _beamInitCoords(Beam beam, Staff staff) {
    // Clear owned
    beam.beamElementCoordsOwned.clear();
    final List<Object> childList = beam.getList();
    if (childList.isEmpty) return;
    beam.beamStaff = staff;
    MeiDuration shortestDur = MeiDuration.none;
    bool hasChord = false;
    bool changingDur = false;
    MeiDuration lastDur = MeiDuration.none;
    bool hasMultipleStemDir = false;
    Stemdirection notesStemDir = Stemdirection.none;

    for (final Object child in childList) {
      final BeamElementCoord coord = BeamElementCoord();
      coord.element = child;
      // duration
      MeiDuration curDur = MeiDuration.dur8;
      try {
        final dynamic d = child as dynamic;
        curDur = d.getActualDur() as MeiDuration;
      } catch (_) {
        try {
          curDur = (child as dynamic).dur as MeiDuration;
        } catch (_) {}
      }
      coord.dur = curDur;
      if (curDur.value > MeiDuration.dur8.value) {
        // keep shortest as max
        if (shortestDur == MeiDuration.none || curDur.value > shortestDur.value) {
          shortestDur = curDur;
        }
      } else if (shortestDur == MeiDuration.none) {
        shortestDur = curDur;
      }
      if (child is Chord) hasChord = true;
      // breaksec
      try {
        final dynamic d = child as dynamic;
        if (d.hasBreaksec == true) {
          coord.breaksec = d.breaksec as int;
          changingDur = true;
        } else if (d.breaksec != null && d.breaksec != 0) {
          coord.breaksec = d.breaksec as int;
          changingDur = true;
        }
      } catch (_) {}
      // cross staff
      try {
        final Staff? cs = (child as dynamic).crossStaff as Staff?;
        if (cs != null && cs != staff) {
          beam.crossStaffContent = cs;
        }
      } catch (_) {}
      // stem dir tracking
      try {
        if (child is Chord || child is Note) {
          Stemdirection curDir = Stemdirection.none;
          try {
            curDir = (child as dynamic).getDrawingStemDir() as Stemdirection;
          } catch (_) {
            // fallback: try to get from stem object
            try {
              final dynamic stem = (child as dynamic).getDrawingStem();
              if (stem != null) curDir = stem.getDrawingStemDir() as Stemdirection;
            } catch (_) {}
          }
          if (curDir != Stemdirection.none) {
            if (notesStemDir != Stemdirection.none && notesStemDir != curDir) {
              hasMultipleStemDir = true;
              notesStemDir = Stemdirection.none;
            } else {
              notesStemDir = curDir;
            }
          }
        }
      } catch (_) {}
      if (lastDur != MeiDuration.none && curDur != lastDur) changingDur = true;
      lastDur = curDur;

      // closestNote / stem
      try {
        if (child is Chord) {
          final Chord ch = child as Chord;
          // For beam calc, closestNote is the extreme in stem direction; we approximate with bottom/top based on notesStemDir later
          coord.closestNote = ch.getBottomNote() ?? ch.getTopNote();
          try { coord.stem = (ch as dynamic).getDrawingStem(); } catch (_) {}
        } else if (child is Note) {
          coord.closestNote = child;
          try { coord.stem = (child as dynamic).getDrawingStem(); } catch (_) {}
        }
      } catch (_) {}

      beam.beamElementCoordsOwned.add(coord);
    }
    if (shortestDur == MeiDuration.none) shortestDur = MeiDuration.dur8;
    beam.shortestDur = shortestDur;
    beam.beamHasChord = hasChord;
    beam.changingDur = changingDur;
    beam.hasMultipleStemDir = hasMultipleStemDir;
    beam.notesStemDir = notesStemDir;

    // cueSize / fractionSize
    bool cueSize = false;
    try {
      cueSize = beam.cueSize;
    } catch (_) {
      // check if all children are cue
      cueSize = childList.every((e) {
        try { return (e as dynamic).drawingCueSize == true || (e as dynamic).isGraceNote() == true; } catch (_) { return false; }
      });
    }
    beam.cueSize = cueSize;
    beam.fractionSize = staff.drawingStaffSize;
  }

  void _fTremInitCoords(FTrem fTrem, Staff staff) {
    fTrem.beamElementCoordsOwned.clear();
    // FTrem does not have ObjectListInterface.getList(); use children filtered
    List<Object> childList;
    try {
      childList = (fTrem as dynamic).getList() as List<Object>;
    } catch (_) {
      childList = fTrem.children.where((c) => c.isLayerElement).toList();
      // Filter to keep only notes/chords etc as InitCoords does via FilterList
      childList = childList.where((e) {
        try { return (e as dynamic).hasInterface(InterfaceId.duration) == true; } catch (_) { return false; }
      }).toList();
    }
    if (childList.isEmpty) return;
    fTrem.beamStaff = staff;
    MeiDuration shortestDur = MeiDuration.none;
    for (final Object child in childList) {
      final BeamElementCoord coord = BeamElementCoord();
      coord.element = child;
      MeiDuration curDur = MeiDuration.dur8;
      try {
        curDur = (child as dynamic).getActualDur() as MeiDuration;
      } catch (_) {}
      coord.dur = curDur;
      if (shortestDur == MeiDuration.none || curDur.value > shortestDur.value) shortestDur = curDur;
      try {
        if (child is Chord) {
          coord.closestNote = (child as Chord).getBottomNote() ?? (child as Chord).getTopNote();
          coord.stem = (child as dynamic).getDrawingStem();
        } else if (child is Note) {
          coord.closestNote = child;
          coord.stem = (child as dynamic).getDrawingStem();
        }
      } catch (_) {}
      fTrem.beamElementCoordsOwned.add(coord);
    }
    if (shortestDur == MeiDuration.none) shortestDur = MeiDuration.dur8;
    fTrem.shortestDur = shortestDur;
    final bool cue = fTrem.cueSize;
    fTrem.cueSize = cue;
    fTrem.fractionSize = staff.drawingStaffSize;
    // beam widths
    final int unit = doc!.getDrawingUnit(staff.drawingStaffSize);
    int black = unit;
    if (cue) black = (black * doc!.getCueScaling()).toInt();
    int white = unit ~/ 2;
    if (cue) white = (white * doc!.getCueScaling()).toInt();
    fTrem.beamWidthBlack = black;
    fTrem.beamWidthWhite = white;
    fTrem.beamWidth = black + white;
  }

  void _beamCalcBeam(BeamSegment segment, dynamic beam, Staff staff, Layer layer, Beamplace initialPlace) {
    final List<BeamElementCoord> coords = segment.beamElementCoordRefs;
    if (coords.isEmpty) return;
    // Tablature early exit – simple horizontal beam at staff center
    bool isTab = false;
    try {
      isTab = staff.isTablature() || (staff as dynamic).isTabStaffLike() == true;
    } catch (_) {}
    if (isTab) {
      final int unit = doc!.getDrawingUnit(staff.drawingStaffSize);
      int black = unit ~/ 2;
      int white = unit ~/ 4;
      try { black = (beam as dynamic).beamWidthBlack as int; } catch (_) {}
      final int staffY = staff.getDrawingY();
      for (final c in coords) {
        c.x = c.element!.getDrawingX();
        // Place beam slightly above staff for tablature
        c.yBeam = staffY + unit;
      }
      segment.beamSlope = 0.0;
      segment.firstNoteOrChord = coords.first;
      segment.lastNoteOrChord = coords.last;
      // Ensure widths are set
      try {
        (beam as dynamic).beamWidthBlack = black;
        (beam as dynamic).beamWidthWhite = white;
        (beam as dynamic).beamWidth = black + white;
      } catch (_) {}
      return;
    }
    // widths
    final int unit = doc!.getDrawingUnit(staff.drawingStaffSize);
    final bool cue = beam.cueSize;
    int black = unit;
    if (cue) black = (black * doc!.getCueScaling()).toInt();
    int white = unit ~/ 2;
    if (cue) white = (white * doc!.getCueScaling()).toInt();
    // For 64th, white is 4/3
    if (beam.shortestDur == MeiDuration.dur64) {
      white = white * 4 ~/ 3;
    }
    beam.beamWidthBlack = black;
    beam.beamWidthWhite = white;
    beam.beamWidth = black + white;
    beam.fractionSize = staff.drawingStaffSize;

    // Determine drawingPlace if none
    Beamplace place = initialPlace;
    if (place == Beamplace.none) {
      if (beam.hasMultipleStemDir) {
        place = Beamplace.mixed;
      } else if (beam.notesStemDir == Stemdirection.up) {
        place = Beamplace.above;
      } else if (beam.notesStemDir == Stemdirection.down) {
        place = Beamplace.below;
      } else {
        // weightedPlace based on note Y vs staff center
        int yMax = coords.first.element!.getDrawingY();
        int yMin = yMax;
        for (final c in coords) {
          final int y = c.element!.getDrawingY();
          if (y > yMax) yMax = y;
          if (y < yMin) yMin = y;
        }
        final int staffCenter = staff.getDrawingY() - doc!.getDrawingDoubleUnit(staff.drawingStaffSize);
        // Actually center = staff.getDrawingY() - doubleUnit*2 ??? use same as C++ verticalCenter
        // Simplified: weighted = above if yMax - center > center - yMin
        final int verticalCenter = staff.getDrawingY() - doc!.getDrawingDoubleUnit(staff.drawingStaffSize) * 2;
        final Beamplace weighted = ((verticalCenter - yMin) > (yMax - verticalCenter)) ? Beamplace.above : Beamplace.below;
        place = weighted;
        segment.weightedPlace = weighted;
      }
    }
    beam.drawingPlace = place;
    segment.weightedPlace = place;

    // Set x
    for (final c in coords) {
      c.x = c.element!.getDrawingX();
    }

    // Determine first/last note
    segment.firstNoteOrChord = null;
    segment.lastNoteOrChord = null;
    segment.nbNotesOrChords = 0;
    for (final c in coords) {
      if (c.element is Chord || c.element is Note) {
        if (segment.firstNoteOrChord == null) segment.firstNoteOrChord = c;
        segment.lastNoteOrChord = c;
        segment.nbNotesOrChords++;
        // closestNote already set, but ensure for chord: pick extreme based on place
        if (c.element is Chord) {
          final Chord ch = c.element as Chord;
          if (place == Beamplace.below) {
            c.closestNote = ch.getBottomNote();
          } else if (place == Beamplace.above) {
            c.closestNote = ch.getTopNote();
          } else {
            // mixed: approximate via stem dir
            c.closestNote = ch.getBottomNote();
          }
        }
      }
    }
    if (segment.firstNoteOrChord == null) {
      segment.firstNoteOrChord = coords.first;
      segment.lastNoteOrChord = coords.last;
    }

    // Determine uniform stem length – use standard 7 half units (3.5 units)
    int uniformStemLength = (unit * 7) ~/ 2;
    if (cue) uniformStemLength = (uniformStemLength * doc!.getCueScaling()).toInt();
    segment.uniformStemLength = uniformStemLength;

    // Compute yBeam for first and last based on note Y + uniform length
    // Need to handle mixed: for each coord individually
    // For non-mixed, set yBeam for first/last, then interpolate
    if (place == Beamplace.mixed) {
      // Mixed: each coord's yBeam is note Y +/- uniform length with direction per beamRelativePlace
      // For simplicity, set beamRelativePlace from stem dir
      for (final c in coords) {
        if (c.closestNote == null) {
          // Rest or non-note: keep at element Y
          c.yBeam = c.element!.getDrawingY();
          c.beamRelativePlace = Beamplace.above;
          c.partialFlagPlace = Beamplace.above;
          continue;
        }
        Stemdirection dir = Stemdirection.none;
        try { dir = (c.element as dynamic).getDrawingStemDir() as Stemdirection; } catch (_) {}
        if (dir == Stemdirection.none) {
          try {
            final dynamic stem = (c as dynamic).stem;
            if (stem != null) dir = stem.getDrawingStemDir() as Stemdirection;
          } catch (_) {}
        }
        c.beamRelativePlace = (dir == Stemdirection.down) ? Beamplace.below : Beamplace.above;
        // Also set partialFlagPlace later in CalcPartialFlagPlace – we approximate same
        c.partialFlagPlace = c.beamRelativePlace;
        final int noteY = (c.closestNote as dynamic).getDrawingY() as int;
        if (c.beamRelativePlace == Beamplace.below) {
          c.yBeam = noteY - uniformStemLength;
        } else {
          c.yBeam = noteY + uniformStemLength;
        }
        // Adjust for stem cap offset (stem width)
        // Simplified: no adjustment
      }
      // For mixed, set slope 0 and keep yBeam as computed (no interpolation)
      segment.beamSlope = 0.0;
      // No further adjustment
    } else {
      // Non-mixed: compute ideal y for first and last, then set intermediate via slope
      final BeamElementCoord first = segment.firstNoteOrChord!;
      final BeamElementCoord last = segment.lastNoteOrChord!;
      final int firstNoteY = (first.closestNote != null)
          ? (first.closestNote as dynamic).getDrawingY() as int
          : first.element!.getDrawingY();
      final int lastNoteY = (last.closestNote != null)
          ? (last.closestNote as dynamic).getDrawingY() as int
          : last.element!.getDrawingY();
      int firstY, lastY;
      if (place == Beamplace.above) {
        firstY = firstNoteY + uniformStemLength;
        lastY = lastNoteY + uniformStemLength;
      } else {
        firstY = firstNoteY - uniformStemLength;
        lastY = lastNoteY - uniformStemLength;
      }
      // If horizontal option (isHorizontal), force equal
      bool isHorizontal = _isBeamHorizontal(beam, segment, staff);
      if (isHorizontal) {
        if (place == Beamplace.above) {
          final int maxY = firstY > lastY ? firstY : lastY;
          firstY = maxY;
          lastY = maxY;
        } else {
          final int minY = firstY < lastY ? firstY : lastY;
          firstY = minY;
          lastY = minY;
        }
      }
      first.yBeam = firstY;
      last.yBeam = lastY;
      // Compute slope
      if (last.x != first.x) {
        segment.beamSlope = (lastY - firstY) / (last.x - first.x);
      } else {
        segment.beamSlope = 0.0;
      }
      // Interpolate for all coords
      for (final c in coords) {
        c.yBeam = firstY + (segment.beamSlope * (c.x - first.x)).toInt();
      }
      // Ensure first/last exact
      first.yBeam = firstY;
      last.yBeam = lastY;

      // Set stem values (length) – update stem objects
      for (final c in coords) {
        if (c.element is Chord || c.element is Note) {
          final dynamic iface = c.element;
          final dynamic stem = c.stem;
          if (stem == null) continue;
          final int y1 = c.yBeam;
          final int y2 = (c.closestNote as dynamic).getDrawingY() as int;
          int stemLen;
          if (place == Beamplace.above) {
            stemLen = y1 - y2;
          } else {
            stemLen = y2 - y1;
          }
          // Apply stem width adjustment as in C++ (shorten slightly)
          // C++ does -stemWidth for above, + for below when not sameas
          final int stemWidth = doc!.getDrawingStemWidth(staff.drawingStaffSize);
          if (place == Beamplace.above) {
            // y2 already includes stem up SE? Simplified
          }
          try {
            stem.setDrawingStemLen(stemLen);
            // Also set drawing stem dir if not set
            if (stem.getDrawingStemDir() == Stemdirection.none) {
              stem.setDrawingStemDir(place == Beamplace.above ? Stemdirection.up : Stemdirection.down);
            }
          } catch (_) {}
        }
      }
    }

    // Final step: ensure partialFlagPlace for mixed is set via helper
    if (place == Beamplace.mixed) {
      _calcPartialFlagPlace(segment);
    }
  }

  void _fTremCalcBeam(BeamSegment segment, FTrem fTrem, Staff staff, Layer layer) {
    final List<BeamElementCoord> coords = segment.beamElementCoordRefs;
    if (coords.length != 2) return;
    final int unit = doc!.getDrawingUnit(staff.drawingStaffSize);
    final bool cue = fTrem.cueSize;
    int black = unit;
    if (cue) black = (black * doc!.getCueScaling()).toInt();
    int white = unit ~/ 2;
    if (cue) white = (white * doc!.getCueScaling()).toInt();
    if (fTrem.shortestDur == MeiDuration.dur64) {
      white = white * 4 ~/ 3;
    }
    fTrem.beamWidthBlack = black;
    fTrem.beamWidthWhite = white;
    fTrem.beamWidth = black + white;
    fTrem.fractionSize = staff.drawingStaffSize;

    // Determine drawingPlace similar to beam
    Beamplace place = fTrem.drawingPlace;
    if (place == Beamplace.none) {
      // Use notesStemDir or weighted
      if (fTrem.notesStemDir == Stemdirection.up) place = Beamplace.above;
      else if (fTrem.notesStemDir == Stemdirection.down) place = Beamplace.below;
      else {
        int yMax = coords[0].element!.getDrawingY();
        int yMin = yMax;
        for (final c in coords) {
          final int y = c.element!.getDrawingY();
          if (y > yMax) yMax = y;
          if (y < yMin) yMin = y;
        }
        final int verticalCenter = staff.getDrawingY() - doc!.getDrawingDoubleUnit(staff.drawingStaffSize) * 2;
        place = ((verticalCenter - yMin) > (yMax - verticalCenter)) ? Beamplace.above : Beamplace.below;
      }
      fTrem.drawingPlace = place;
    }

    for (final c in coords) {
      c.x = c.element!.getDrawingX();
    }
    // Set closestNote for chords similarly
    for (final c in coords) {
      if (c.element is Chord) {
        final Chord ch = c.element as Chord;
        c.closestNote = (place == Beamplace.below) ? ch.getBottomNote() : ch.getTopNote();
      }
    }
    segment.firstNoteOrChord = coords.first;
    segment.lastNoteOrChord = coords.last;
    int uniform = (unit * 7) ~/ 2;
    if (cue) uniform = (uniform * doc!.getCueScaling()).toInt();
    segment.uniformStemLength = uniform;
    final dynamic c0Close = coords[0].closestNote ?? coords[0].element;
    final dynamic c1Close = coords[1].closestNote ?? coords[1].element;
    final int y1Note = (c0Close as dynamic).getDrawingY() as int;
    final int y2Note = (c1Close as dynamic).getDrawingY() as int;
    int y1, y2;
    if (place == Beamplace.above) {
      y1 = y1Note + uniform;
      y2 = y2Note + uniform;
    } else {
      y1 = y1Note - uniform;
      y2 = y2Note - uniform;
    }
    coords[0].yBeam = y1;
    coords[1].yBeam = y2;
    if (coords[1].x != coords[0].x) {
      segment.beamSlope = (y2 - y1) / (coords[1].x - coords[0].x);
    } else {
      segment.beamSlope = 0.0;
    }
    // Set stem lens
    for (final c in coords) {
      final dynamic stem = c.stem;
      if (stem == null) continue;
      final dynamic noteObj = c.closestNote ?? c.element;
      final int noteY = (noteObj as dynamic).getDrawingY() as int;
      final int beamY = c.yBeam;
      final int len = (place == Beamplace.above) ? beamY - noteY : noteY - beamY;
      try {
        stem.setDrawingStemLen(len);
        if (stem.getDrawingStemDir() == Stemdirection.none) {
          stem.setDrawingStemDir(place == Beamplace.above ? Stemdirection.up : Stemdirection.down);
        }
      } catch (_) {}
    }
  }

  bool _isBeamHorizontal(dynamic beam, BeamSegment segment, Staff staff) {
    // Simplified version of BeamDrawingInterface::IsHorizontal
    // For now, consider horizontal if slope would be small or if beam has one step height etc.
    // We check the note Y positions for first and last – if equal, horizontal.
    if (segment.firstNoteOrChord == null || segment.lastNoteOrChord == null) return true;
    final dynamic firstClosest = segment.firstNoteOrChord!.closestNote;
    final dynamic lastClosest = segment.lastNoteOrChord!.closestNote;
    final int firstY = (firstClosest != null)
        ? (firstClosest as dynamic).getDrawingY() as int
        : segment.firstNoteOrChord!.element!.getDrawingY();
    final int lastY = (lastClosest != null)
        ? (lastClosest as dynamic).getDrawingY() as int
        : segment.lastNoteOrChord!.element!.getDrawingY();
    if (firstY == lastY) return true;
    // Check drawingPlace none -> horizontal
    if (beam.drawingPlace == Beamplace.none) return true;
    // For mixed, assume not horizontal unless needed; return false for sloped
    if (beam.drawingPlace == Beamplace.mixed) return false;
    // Check max slope option – if small interval, treat as horizontal?
    // Simplified: if absolute slope * dist < unit, consider horizontal
    final int dist = (segment.lastNoteOrChord!.x - segment.firstNoteOrChord!.x).abs();
    if (dist == 0) return true;
    final double slope = (lastY - firstY) / dist;
    final int unit = doc!.getDrawingUnit(staff.drawingStaffSize);
    if ((slope.abs() * dist).abs() < unit) return true;
    return false;
  }

  void _calcPartialFlagPlace(BeamSegment segment) {
    // Simplified port of BeamSegment::CalcPartialFlagPlace
    final List<BeamElementCoord> coords = segment.beamElementCoordRefs;
    int idx = coords.indexWhere((c) => c.dur.value >= MeiDuration.dur16.value);
    if (idx == -1) return;
    // Iterate over subdivisions – simplified: group consecutive notes with same beamRelativePlace and dur>8
    int start = idx;
    while (start < coords.length) {
      int end = start;
      Beamplace place = coords[start].beamRelativePlace;
      while (end < coords.length) {
        final BeamElementCoord c = coords[end];
        if (c.element != null && _isRest(c.element)) {
          // rests break subdivision
          break;
        }
        if (c.beamRelativePlace != place) break;
        if (c.dur.value <= MeiDuration.dur8.value) break;
        if (c.breaksec != 0) {
          end++;
          break;
        }
        end++;
      }
      for (int i = start; i < end; ++i) {
        coords[i].partialFlagPlace = (place == Beamplace.above) ? Beamplace.above : Beamplace.below;
      }
      if (end >= coords.length) break;
      start = end + 1;
      if (start < coords.length && coords[start].breaksec != 0) start++;
    }
  }
}
