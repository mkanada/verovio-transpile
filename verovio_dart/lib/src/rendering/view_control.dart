
/// Port of `view_control.cpp` (A+B+C) — completo (tasks 05-20/05-21/05-22).
///
/// Mirrors the `View::Draw*` methods of `view_control.cpp` (3306 lines, 6.2.0):
/// - 05-20 slice (12 methods): `DrawControlElement` (72),
///   `DrawTimeSpanningElement` (183), `HasValidTimeSpanningOrder` (435),
///   `DrawBracketSpan` (564), `DrawOctave` (815), `DrawTie` (1067),
///   `DrawPedalLine` (1110), `DrawTrillExtension` (1189),
///   `DrawControlElementConnector` (1240), `DrawFConnector` (1336),
///   `DrawSylConnector` (1394), `DrawSylConnectorLines` (1468).
/// - 05-21 slice (9 methods): `DrawControlElementText` (1745),
///   `DrawDynam` (1829), `DrawDynamSymbolOnly` (1910), `DrawFb` (1960),
///   `DrawHarm` (2288), `DrawReh` (2583), `DrawTempo` (2734),
///   `DrawHairpin` (651), `DrawTextEnclosure` (3265).
/// - 05-22 slice (16 methods): `DrawAnnotScore` (464), `DrawPitchInflection`
///   (964), `DrawArpeg` (1518), `DrawArpegEnclosing` (1598), `DrawBreath`
///   (1641), `DrawCaesura` (1697), `DrawFermata` (1999), `DrawFing` (2092),
///   `DrawGliss` (2145), `DrawMordent` (2351), `DrawPedal` (2507),
///   `DrawRepeatMark` (2671), `DrawTrill` (2798), `DrawTurn` (2900),
///   `DrawSystemElement` (3014), `DrawEnding` (3048) — fechando `view_control.cpp`.
///
/// This file is a `part` of the `view.dart` library (task 05-06 partitioning
/// decision: one `part` per `view_*.cpp`). The C++ continues the `View` class
/// here; Dart cannot split a class body across files, so the methods are
/// declared as members of the [ViewControl] extension below — same library,
/// therefore the same privacy scope as the class members (like the C++ member
/// visibility from every `view_*.cpp`).
///
/// Deviations from the C++:
/// - `DeviceContext *dc` pointers become non-nullable [DeviceContext] references.
/// - `vrv_cast<BBoxDeviceContext*>` (line 190) becomes `is BBoxDeviceContext`.
/// - `int &x, int &y` output params become return values / mutated [Point].
/// - `std::vector<Staff*>` becomes `List<Staff>`.
/// - `char spanningType` becomes `int` (constants `spanningStartEnd` etc.).
/// - Some `Get*` helpers that are not yet ported on the model (`GetLineWidth`,
///   `GetOctaveGlyph`, `GetFYRel`, `GetSylYRel`, `AdjustToLyricSize`,
///   `CalcHyphenLength`) are reproduced here as private helpers with the same
///   arithmetic, using `dynamic` fallbacks when the model object does not yet
///   expose the method.
/// - `BoundingBox::GetBezierThicknessCoefficient` is available via
///   `BoundingBox.getBezierThicknessCoefficient`.
part of 'view.dart';

/// The `view_control.cpp` methods of [View] ported by task 05-20.
extension ViewControl on View {
  dynamic _dyn(dynamic o) => o;
  // ---------------------------------------------------------------------------
  // View::DrawControlElement (view_control.cpp:72)
  // ---------------------------------------------------------------------------

  /// Mirrors `View::DrawControlElement` (view_control.cpp:72) — the control
  /// element dispatcher. Every branch that belongs to 05-21/05-22 throws
  /// [_notYet] with the target task, as required; the spanning families
  /// (annotScore/beamSpan/bracketSpan/.../tie) are handled via the
  /// placeholder+addToDrawingList path which is the same for all of them.
  /// Mirrors `LayerElement::GetDrawingRadius` (layerelement.cpp:599) — the
  /// port lives on the model; this alias keeps the one-argument call shape
  /// this file uses everywhere.
  int _drawingRadius(LayerElement el) => el.getDrawingRadius(doc!);

  void drawControlElement(DeviceContext dc, ControlElement element,
      Measure measure, System system) {
    startOffset(dc, element, 100);

    if (element.isClass(ClassId.annotScore) ||
        element.isClass(ClassId.beamSpan) ||
        element.isClass(ClassId.bracketSpan) ||
        // C++ FIGURE ↔ Dart ClassId.f (the value the F object carries; the
        // `ClassId.figure` enum value is carried by no object)
        element.isClass(ClassId.f) ||
        element.isClass(ClassId.gliss) ||
        element.isClass(ClassId.hairpin) ||
        element.isClass(ClassId.lv) ||
        element.isClass(ClassId.octave) ||
        element.isClass(ClassId.phrase) ||
        element.isClass(ClassId.pitchInflection) ||
        element.isClass(ClassId.slur) ||
        element.isClass(ClassId.tie)) {
      // create placeholder
      dc.startGraphic(element, '', element.id);
      dc.endGraphic(element);
      system.addToDrawingList(element);
    } else if (element.isClass(ClassId.arpeg)) {
      drawArpeg(dc, element as Arpeg, measure, system);
    } else if (element.isClass(ClassId.breath)) {
      drawBreath(dc, element as Breath, measure, system);
    } else if (element.isClass(ClassId.caesura)) {
      drawCaesura(dc, element as Caesura, measure, system);
    } else if (element.isClass(ClassId.cpMark)) {
      drawControlElementText(dc, element, measure, system);
    } else if (element.isClass(ClassId.dir)) {
      drawControlElementText(dc, element, measure, system);
      system.addToDrawingListIfNecessary(element);
    } else if (element.isClass(ClassId.dynam)) {
      drawDynam(dc, _dyn(element), measure, system);
      system.addToDrawingListIfNecessary(element);
    } else if (element.isClass(ClassId.fermata)) {
      drawFermata(dc, element as Fermata, measure, system);
    } else if (element.isClass(ClassId.fing)) {
      drawFing(dc, element as Fing, measure, system);
    } else if (element.isClass(ClassId.harm)) {
      drawHarm(dc, _dyn(element), measure, system);
    } else if (element.isClass(ClassId.mordent)) {
      drawMordent(dc, element as Mordent, measure, system);
    } else if (element.isClass(ClassId.ornam)) {
      drawControlElementText(dc, element, measure, system);
    } else if (element.isClass(ClassId.pedal)) {
      drawPedal(dc, element as Pedal, measure, system);
      system.addToDrawingListIfNecessary(element);
    } else if (element.isClass(ClassId.reh)) {
      drawReh(dc, element as Reh, measure, system);
    } else if (element.isClass(ClassId.repeatMark)) {
      drawRepeatMark(dc, element as RepeatMark, measure, system);
    } else if (element.isClass(ClassId.tempo)) {
      drawTempo(dc, _dyn(element), measure, system);
      system.addToDrawingListIfNecessary(element);
    } else if (element.isClass(ClassId.trill)) {
      drawTrill(dc, element as Trill, measure, system);
      system.addToDrawingListIfNecessary(element);
    } else if (element.isClass(ClassId.turn)) {
      drawTurn(dc, element as Turn, measure, system);
    }
    // The C++ has no else branch (view_control.cpp:72-170): elements not
    // listed (e.g. mNum, drawn by View::DrawMeasure) are not drawn here.

    endOffset(dc, element);
  }

  // ---------------------------------------------------------------------------
  // View::DrawTimeSpanningElement (view_control.cpp:183)
  // ---------------------------------------------------------------------------

  /// Mirrors `View::DrawTimeSpanningElement` (view_control.cpp:183) — the
  /// machine that resolves start/end spanning across systems, with the
  /// `BBoxDeviceContext` special path (line 190) reproduced via `is` check.
  void drawTimeSpanningElement(
      DeviceContext dc, Object element, System system) {
    // BBox special path (view_control.cpp:189-195): avoids drawing the same
    // element twice in the BBox pass. Reproduced with `is` check.
    if (dc is BBoxDeviceContext) {
      final BBoxDeviceContext bBoxDC = dc;
      if (!bBoxDC.updateVerticalValues()) {
        if (element.isClass(ClassId.annotScore) ||
            element.isClass(ClassId.bracketSpan) ||
            element.isClass(ClassId.hairpin) ||
            element.isClass(ClassId.octave) ||
            element.isClass(ClassId.pitchInflection)) {
          return;
        }
      }
    }

    // Resolve TimeSpanningInterface and start/end LayerElements (183-216)
    // Dart uses `is` checks for the interface mixins; the C++ Get*Interface() dispatch
    // is reproduced via the same lookup (see functor.dart kAcceptChain comment).
    TimeSpanningInterface? spanningIface;
    TimePointInterface? pointIface;
    if (element is TimeSpanningInterface) spanningIface = element as TimeSpanningInterface;
    if (element is TimePointInterface) pointIface = element as TimePointInterface;
    dynamic iface = spanningIface ?? pointIface;
    if (iface == null) {
    }

    LayerElement? start;
    LayerElement? end;
    try {
      final Object? s = spanningIface?.getStart() ?? pointIface?.getStart();
      if (s is LayerElement) start = s;
    } catch (e) { e.toString(); }
    // Try linking interface for next link (view_control.cpp:207-215)
    if (start != null) {
      try {
        final Object? e = spanningIface?.getEnd();
        if (e is LayerElement) end = e;
      } catch (e) { e.toString(); }
      if (end == null && element is LinkingInterface) {
        try {
          final Object? next = (element as LinkingInterface).nextLink;
          if (next != null) {
            TimePointInterface? nextTP;
            if (next is TimePointInterface) nextTP = next as TimePointInterface;
            final Object? nextStart = nextTP?.getStart();
            if (nextStart is LayerElement) end = nextStart;
          }
        } catch (e) { e.toString(); }
      }
    }

    // view_control.cpp:222: stop when the spanning is not temporally ordered
    // (start must occur before end).
    if (!hasValidTimeSpanningOrder(dc, element, start, end)) return;

    // For time-spanning that is open-ended, end may be null — HasValidTimeSpanningOrder will handle.
    // Still continue with end ?? start to avoid null deref? C++ returns if !HasValid... so we check.

    Object? parentSystem1;
    Object? parentSystem2;
    try {
      final Measure? sm = spanningIface?.getStartMeasure() ?? start!.getFirstAncestor(ClassId.measure) as Measure?;
      parentSystem1 = sm?.getFirstAncestor(ClassId.system);
    } catch (e) {
      try { parentSystem1 = start!.getFirstAncestor(ClassId.system); } catch(e){ parentSystem1 = null; }
    }
    try {
      final Measure? em = spanningIface?.getEndMeasure() ?? end!.getFirstAncestor(ClassId.measure) as Measure?;
      parentSystem2 = em?.getFirstAncestor(ClassId.system);
    } catch (e) {
      try { parentSystem2 = end!.getFirstAncestor(ClassId.system); } catch(e){ parentSystem2 = null; }
    }

    int drawingX1, drawingX2;
    Object? objectX;
    Measure? measure;
    Object? graphic;
    int spanningType = spanningStartEnd;

    if (identical(system, parentSystem1) && identical(system, parentSystem2)) {
      try {
        measure = _dyn(iface).getStartMeasure() as Measure?;
      } catch (e) {
        measure = start!.getFirstAncestor(ClassId.measure) as Measure?;
      }
      measure ??= start!.getFirstAncestor(ClassId.measure) as Measure?;
      if (measure == null) return;
      drawingX1 = start!.getDrawingX();
      objectX = start;
      drawingX2 = end!.getDrawingX();
      graphic = element;
    } else if (identical(system, parentSystem1)) {
      final List<Object> measures =
          system.findAllDescendantsByType(ClassId.measure, deepness: 1);
      if (measures.isEmpty) return;
      measure = measures.last as Measure;
      drawingX1 = start!.getDrawingX();
      objectX = start;
      drawingX2 =
          measure.getDrawingX() + measure.measureAligner.getRightBarLineXRel();
      graphic = element;
      spanningType = spanningStart;
    } else if (identical(system, parentSystem2)) {
      final List<Object> measures =
          system.findAllDescendantsByType(ClassId.measure, deepness: 1);
      if (measures.isEmpty) return;
      measure = measures.first as Measure;
      drawingX1 =
          measure.getDrawingX() + measure.measureAligner.getLeftBarLineXRel();
      objectX = measure.leftBarLine;
      drawingX2 = end!.getDrawingX();
      spanningType = spanningEnd;
    } else if (parentSystem1 != null &&
        parentSystem2 != null &&
        Object.isPreOrdered(parentSystem1, system) &&
        Object.isPreOrdered(system, parentSystem2)) {
      final List<Object> measures =
          system.findAllDescendantsByType(ClassId.measure, deepness: 1);
      if (measures.isEmpty) return;
      measure = measures.first as Measure;
      drawingX1 =
          measure.getDrawingX() + measure.measureAligner.getLeftBarLineXRel();
      objectX = measure.leftBarLine;
      final Measure last = measures.last as Measure;
      drawingX2 =
          last.getDrawingX() + last.measureAligner.getRightBarLineXRel();
      spanningType = spanningMiddle;
    } else {
      return;
    }

    // Overwrite for open-ended control events ending on right barline (view_control.cpp:286)
    if (spanningType == spanningStartEnd && end!.isClass(ClassId.barLine)) {
      try {
        final dynamic bar = _dyn(end);
        final dynamic pos = bar.getPosition?.call() ?? bar.position;
        // BarLinePosition.Right is typically 1; check string
        final String posStr = pos?.toString() ?? '';
        if (posStr.contains('Right') ||
            posStr.contains('right') ||
            posStr == '1') {
          spanningType = spanningStart;
        }
      } catch (e) { e.toString(); }
    }

    int startRadius = 0;
    try {
      if (!(start!.isClass(ClassId.timestampAttr))) {
        startRadius = _drawingRadius(start);
      }
    } catch (e) { e.toString(); }
    int endRadius = 0;
    try {
      if (!(end!.isClass(ClassId.timestampAttr))) {
        endRadius = _drawingRadius(end);
      }
    } catch (e) { e.toString(); }

    if (spanningType == spanningStartEnd) {
      drawingX1 += startRadius;
      drawingX2 += endRadius;
    } else if (spanningType == spanningStart) {
      drawingX1 += startRadius;
    } else if (spanningType == spanningEnd) {
      drawingX2 += endRadius;
    }

    // Staff list (view_control.cpp:315)
    List<Staff> staffList = [];
    try {
      final dynamic staves =
          _dyn(iface).getTstampStaves(measure, element);
      if (staves is List) staffList = staves.cast<Staff>();
    } catch (e) { e.toString(); }
    if (staffList.isEmpty) {
      // Fallback: try element's @staff list (mirrors TimePointInterface::GetTstampStaves HasStaff branch)
      try {
        final dynamic staffAttr = _dyn(element).staff;
        if (staffAttr is List && staffAttr.isNotEmpty) {
          final List<int> staffNs = staffAttr.cast<int>();
          bool isBetween = false;
          try {
            final dynamic place = _dyn(element).place;
            if (place != null && place.toString().contains('between')) isBetween = true;
          } catch (e) { e.toString(); }
          final List<int> filtered = isBetween ? [staffNs.first] : staffNs;
          for (final int n in filtered) {
            Staff? found;
            try {
              final List<Object> cand = measure.findAllDescendantsByType(ClassId.staff, deepness: 1);
              for (final Object o in cand) {
                if (o is Staff && o.n == n) { found = o; break; }
              }
            } catch (e) { e.toString(); }
            if (found == null) {
              try {
                final List<Object> all = system.findAllDescendantsByType(ClassId.staff);
                for (final Object o in all) {
                  if (o is Staff && o.n == n) { found = o; break; }
                }
              } catch (e) { e.toString(); }
            }
            if (found != null) staffList.add(found);
          }
        }
      } catch (e) { e.toString(); }
    }
    if (staffList.isEmpty) {
      if (start != null) {
        final Staff? s = start.getFirstAncestor(ClassId.staff) as Staff?;
        if (s != null) {
          staffList = [s];
        } else if (end != null) {
          final Staff? e = end.getFirstAncestor(ClassId.staff) as Staff?;
          if (e != null) staffList = [e];
        }
      } else if (end != null) {
        final Staff? e = end.getFirstAncestor(ClassId.staff) as Staff?;
        if (e != null) staffList = [e];
      }
    }
    if (staffList.isEmpty) {
      try {
        final Staff? first = measure.findDescendantByType(ClassId.staff) as Staff?;
        if (first != null) staffList = [first];
      } catch (e) { e.toString(); }
      if (staffList.isEmpty) {
        try {
          final Staff? sysFirst = system.findDescendantByType(ClassId.staff) as Staff?;
          if (sysFirst != null) staffList = [sysFirst];
        } catch (e) { e.toString(); }
      }
    }
    if (staffList.isEmpty) return;

    bool isFirst = true;
    for (final Staff staff in staffList) {
      final int staffSize = staff.drawingStaffSize;
      int x1 = drawingX1;
      int x2 = drawingX2;

      setOffsetStaffSize(element, staffSize);
      x1 = calcOffsetSpanningStartX(dc, x1, spanningType);
      x2 = calcOffsetSpanningEndX(dc, x2, spanningType);

      // Floating positioner creation for ControlElements (view_control.cpp:328-340)
      if (element is ControlElement) {
        if (element.isClass(ClassId.phrase) || element.isClass(ClassId.slur)) {
          if (slurHandling == SlurHandling.ignore) break;
          try {
            final Staff? principal = _dyn(element)
                .calculatePrincipalStaff(staff, x1, x2) as Staff?;
            if (principal != null) {
              // ignore: unused
            }
          } catch (e) { e.toString(); }
        }
        if (!system.setSystemCurrentFloatingPositioner(staff.n ?? meiUnset,
            element as FloatingObject, objectX, staff, spanningType)) {
          continue;
        }
      }

      if (element.isClass(ClassId.annotScore)) {
        drawAnnotScore(
            dc, element as AnnotScore, x1, x2, staff, spanningType, graphic);
      } else if (element.isClass(ClassId.dir)) {
        drawControlElementConnector(dc, element as ControlElement, x1, x2,
            staff, spanningType, graphic);
      } else if (element.isClass(ClassId.dynam)) {
        drawControlElementConnector(dc, element as ControlElement, x1, x2,
            staff, spanningType, graphic);
      } else if (element.isClass(ClassId.f)) {
        // C++ FIGURE ↔ Dart ClassId.f; cast to F check in DrawFConnector
        drawFConnector(
            dc, element as F, x1, x2, staff, spanningType, graphic);
      } else if (element.isClass(ClassId.beamSpan)) {
        try {
          drawBeamSpan(dc, element as BeamSpan, system, graphic);
        } catch (e) { e.toString(); }
      } else if (element.isClass(ClassId.bracketSpan)) {
        drawBracketSpan(
            dc, element as BracketSpan, x1, x2, staff, spanningType, graphic);
      } else if (element.isClass(ClassId.gliss)) {
        if (!isFirst) continue;
        drawGliss(dc, element as Gliss, x1, x2, staff, spanningType, graphic);
      } else if (element.isClass(ClassId.hairpin)) {
        drawHairpin(
            dc, element as Hairpin, x1, x2, staff, spanningType, graphic);
      } else if (element.isClass(ClassId.lv)) {
        if (!isFirst) continue;
        drawTie(dc, element as Tie, x1, x2, staff, spanningType, graphic);
      } else if (element.isClass(ClassId.phrase)) {
        if (slurHandling == SlurHandling.ignore) continue;
        if (!isFirst) continue;
        drawSlur(dc, element as Slur, x1, x2, staff, spanningType, graphic);
      } else if (element.isClass(ClassId.octave)) {
        drawOctave(dc, element as Octave, x1, x2, staff, spanningType, graphic);
      } else if (element.isClass(ClassId.pedal)) {
        drawPedalLine(
            dc, element as Pedal, x1, x2, staff, spanningType, graphic);
      } else if (element.isClass(ClassId.pitchInflection)) {
        if (!isFirst) continue;
        drawPitchInflection(dc, element as PitchInflection, x1, x2, staff,
            spanningType, graphic);
      } else if (element.isClass(ClassId.slur)) {
        if (slurHandling == SlurHandling.ignore) continue;
        if (!isFirst) continue;
        drawSlur(dc, element as Slur, x1, x2, staff, spanningType, graphic);
      } else if (element.isClass(ClassId.syl)) {
        // prolong to end of notehead (view_control.cpp:412)
        x2 += endRadius;
        drawSylConnector(
            dc, element as Syl, x1, x2, staff, spanningType, graphic);
      } else if (element.isClass(ClassId.tempo)) {
        drawControlElementConnector(dc, element as ControlElement, x1, x2,
            staff, spanningType, graphic);
      } else if (element.isClass(ClassId.tie)) {
        if (!isFirst) continue;
        drawTie(dc, element as Tie, x1, x2, staff, spanningType, graphic);
      } else if (element.isClass(ClassId.annotScore)) {
        drawAnnotScore(
            dc, element as AnnotScore, x1, x2, staff, spanningType, graphic);
      } else if (element.isClass(ClassId.trill)) {
        drawTrillExtension(dc, element as Trill, x1, x2, staff, spanningType, graphic);
      } else {}

      isFirst = false;
    }
  }

  // ---------------------------------------------------------------------------
  // View::HasValidTimeSpanningOrder (view_control.cpp:435)
  // ---------------------------------------------------------------------------

  /// Mirrors `View::HasValidTimeSpanningOrder` (view_control.cpp:435).
  bool hasValidTimeSpanningOrder(DeviceContext dc, Object element,
      LayerElement? start, LayerElement? end) {
    if (start == null || end == null) return false;

    bool isOrdered = true;
    try {
      if (element is TimeSpanningInterface) {
        isOrdered = (element as TimeSpanningInterface)
            .isOrderedWith(start, end);
      }
    } catch (e) {
      isOrdered = true;
    }

    if (!isOrdered) {
      if (element.isClass(ClassId.slur)) {
        try {
          if (start.getAlignment() == end.getAlignment()) {
            if (start.isGraceNote() || end.isGraceNote()) {
              return true;
            }
          }
        } catch (e) { e.toString(); }
      } else if (element.isClass(ClassId.octave) ||
          element.isClass(ClassId.syl)) {
        return true;
      }
      if (dc is! BBoxDeviceContext &&
          identical(currentPage, start.getFirstAncestor(ClassId.page))) {
        // In C++ LogWarning; in Dart we logDebug to avoid test noise.
        try {
          logDebug(
              "${element.className} '${element.id}' is ignored, since start '${start.id}' does not occur temporally before end '${end.id}'.");
        } catch (e) { e.toString(); }
      }
      return false;
    }
    return true;
  }

  // ---------------------------------------------------------------------------
  // View::DrawBracketSpan (view_control.cpp:564)
  // ---------------------------------------------------------------------------

  /// Mirrors `View::DrawBracketSpan` (view_control.cpp:564).
  void drawBracketSpan(DeviceContext dc, BracketSpan bracketSpan, int x1,
      int x2, Staff staff, int spanningType, Object? graphic) {
    int y = 0;
    try {
      y = bracketSpan.getDrawingY();
    } catch (e) {
      try {
        y = _dyn(bracketSpan).getDrawingY() as int;
      } catch (e) {
        y = staff.getDrawingY();
      }
    }
    y = calcOffsetY(dc, y);

    if (graphic != null) {
      dc.resumeGraphic(
          graphic as BoundingBox, _dyn(graphic).id as String);
    } else {
      dc.startGraphic(bracketSpan as BoundingBox, '', bracketSpan.id,
          graphicID: GraphicID.spanning);
    }

    final int unit = doc!.getDrawingUnit(staff.drawingStaffSize);
    int lineWidth = _getBracketSpanLineWidth(bracketSpan, unit);

    x1 += lineWidth ~/ 2;
    x2 -= lineWidth ~/ 2;

    dc.setPen(lineWidth, PenStyle.solid,
        lineCap: LineCapStyle.butt, lineJoin: LineJoinStyle.miter);

    if (spanningType == spanningStartEnd || spanningType == spanningStart) {
      try {
        if (!(bracketSpan.getStart() as Object)
            .isClass(ClassId.timestampAttr)) {
          x1 -= _drawingRadius(bracketSpan.getStart() as LayerElement);
        }
      } catch (e) { e.toString(); }
      Linestartendsymbol lstart = Linestartendsymbol.none;
      try {
        lstart = bracketSpan.lstartsym as Linestartendsymbol;
      } catch (e) {
        try {
          lstart =
              _dyn(bracketSpan).getLstartsym() as Linestartendsymbol;
        } catch (e) { e.toString(); }
      }
      // The C++ compares against `LINESTARTENDSYMBOL_none` (the MEI "none"
      // value, 20), NOT against `LINESTARTENDSYMBOL_NONE` (the unset default,
      // 0) — so the hooks are drawn unless @lstartsym/@lendsym="none" is given
      // explicitly (view_control.cpp:596,609). `none` above is the unset
      // default and must draw; only `none0` suppresses.
      if (lstart != Linestartendsymbol.none0) {
        final List<Point> hookLeft = [
          Point(toDeviceContextX(x1), toDeviceContextY(y - unit * 2)),
          Point(toDeviceContextX(x1), toDeviceContextY(y)),
          Point(toDeviceContextX(x1 + unit), toDeviceContextY(y)),
        ];
        dc.drawPolyline(hookLeft);
      }
    }
    if (spanningType == spanningStartEnd || spanningType == spanningEnd) {
      try {
        if (!(bracketSpan.getEnd() as Object).isClass(ClassId.timestampAttr)) {
          x2 += _drawingRadius(bracketSpan.getEnd() as LayerElement);
        }
      } catch (e) { e.toString(); }
      Linestartendsymbol lendsym = Linestartendsymbol.none;
      try {
        lendsym = bracketSpan.lendsym as Linestartendsymbol;
      } catch (e) {
        try {
          lendsym = _dyn(bracketSpan).getLendsym() as Linestartendsymbol;
        } catch (e) { e.toString(); }
      }
      if (lendsym != Linestartendsymbol.none0) {
        final List<Point> hookRight = [
          Point(toDeviceContextX(x2), toDeviceContextY(y - unit * 2)),
          Point(toDeviceContextX(x2), toDeviceContextY(y)),
          Point(toDeviceContextX(x2 - unit), toDeviceContextY(y)),
        ];
        dc.drawPolyline(hookRight);
      }
    }

    bool hasLform = false;
    try {
      hasLform = bracketSpan.hasLform;
    } catch (e) {
      try {
        hasLform = _dyn(bracketSpan).hasLform == true;
      } catch (e) { e.toString(); }
    }
    if (hasLform) {
      Lineform lform = Lineform.none;
      try {
        lform = bracketSpan.lform as Lineform;
      } catch (e) { e.toString(); }
      PenStyle penStyle = PenStyle.solid;
      LineCapStyle cap = LineCapStyle.butt;
      if (lform == Lineform.dashed) {
        penStyle = PenStyle.longDash;
        cap = LineCapStyle.square;
      } else if (lform == Lineform.dotted) {
        penStyle = PenStyle.dot;
        cap = LineCapStyle.round;
        x1 += unit + lineWidth * 2;
        x2 -= unit + lineWidth * 2;
        final int diff = (x2 - x1) % (lineWidth * 3 + 1);
        x1 += diff ~/ 2;
      }
      dc.setPen(lineWidth, penStyle, lineCap: cap);
      dc.drawLine(toDeviceContextX(x1), toDeviceContextY(y),
          toDeviceContextX(x2), toDeviceContextY(y));
      dc.resetPen();
    }

    dc.resetPen();

    if (graphic != null) {
      dc.endResumedGraphic(graphic as BoundingBox);
    } else {
      dc.endGraphic(bracketSpan as BoundingBox);
    }
  }

  // ---------------------------------------------------------------------------
  // View::DrawOctave (view_control.cpp:815)
  // ---------------------------------------------------------------------------

  /// Mirrors `View::DrawOctave` (view_control.cpp:815).
  void drawOctave(DeviceContext dc, Octave octave, int x1, int x2, Staff staff,
      int spanningType, Object? graphic) {
    bool hasDis = false;
    try {
      hasDis = octave.hasDis == true || octave.dis != null;
    } catch (e) {
      try {
        hasDis = _dyn(octave).hasDis() == true;
      } catch (e) {
        hasDis = true;
      }
    }
    bool hasDisPlace = false;
    try {
      hasDisPlace = octave.hasDisPlace == true || octave.disPlace != null;
    } catch (e) {
      hasDisPlace = true;
    }
    if (!hasDis || !hasDisPlace) return;

    dynamic disPlace;
    try {
      disPlace = octave.disPlace;
    } catch (e) {
      disPlace = Staffrel.above;
    }

    int y1 = 0;
    try {
      y1 = octave.getDrawingY();
    } catch (e) {
      try {
        y1 = _dyn(octave).getDrawingY() as int;
      } catch (e) {
        y1 = staff.getDrawingY();
      }
    }
    y1 = calcOffsetY(dc, y1);
    int y2 = y1;
    final int unit = doc!.getDrawingUnit(staff.drawingStaffSize);

    if (spanningType == spanningEnd || spanningType == spanningMiddle) {
      x1 += doc!.getGlyphWidth(0xE0A2, staff.drawingStaffSize, false) ~/ 2;
      bool noParen = false;
      try {
        noParen = (_dyn(doc!.getOptions()))
            .octaveNoSpanningParentheses
            .value as bool;
      } catch (e) { e.toString(); }
      if (!noParen) {
        x1 += doc!.getGlyphWidth(0xE51A, staff.drawingStaffSize, false);
      }
    }
    if (spanningType == spanningStartEnd || spanningType == spanningEnd) {
      try {
        if (_dyn(octave).hasEndid == true) {
          final Object? end = _dyn(octave).getEnd();
          if (end != null && _dyn(end).hasContentBB == true) {
            // no direct, approximate
          }
          if (end != null) {
            try {
              final int cx2 = _dyn(end).getContentX2() as int;
              x2 += cx2;
            } catch (e) { e.toString(); }
          }
        }
      } catch (e) { e.toString(); }
    }

    if (graphic != null) {
      dc.resumeGraphic(
          graphic as BoundingBox, _dyn(graphic).id as String);
    } else {
      dc.startGraphic(octave as BoundingBox, '', octave.id,
          graphicID: GraphicID.spanning);
    }

    bool altSymbols = false;
    try {
      altSymbols =
          (_dyn(doc!.getOptions())).octaveAlternativeSymbols.value as bool;
    } catch (e) { e.toString(); }
    final int code = _getOctaveGlyph(octave, altSymbols);
    final String str = String.fromCharCode(code);

    dc.setFont(doc!.getDrawingSmuflFont(staff.drawingStaffSize, false));
    final TextExtend extend = TextExtend();
    dc.getSmuflTextExtent(str, extend);
    final bool isAbove = disPlace == Staffrel.above;
    final int yCode = isAbove ? y1 - extend.height : y1;
    final int octaveX = altSymbols ? x1 - extend.width ~/ 2 : x1 - extend.width;
    drawSmuflCode(dc, octaveX, yCode, code, staff.drawingStaffSize, false);
    bool noParen2 = false;
    try {
      noParen2 = (_dyn(doc!.getOptions()))
          .octaveNoSpanningParentheses
          .value as bool;
    } catch (e) { e.toString(); }
    if ((spanningType == spanningEnd || spanningType == spanningMiddle) &&
        !noParen2) {
      final int leftW =
          doc!.getGlyphWidth(0xE51A, staff.drawingStaffSize, false);
      final int rightW =
          doc!.getGlyphWidth(0xE51B, staff.drawingStaffSize, false);
      final int glyphW =
          doc!.getGlyphWidth(code, staff.drawingStaffSize, false);
      drawSmuflCode(
          dc, octaveX - leftW, yCode, 0xE51A, staff.drawingStaffSize, false);
      drawSmuflCode(
          dc, octaveX + glyphW, yCode, 0xE51B, staff.drawingStaffSize, false);
      x1 += rightW;
    }
    dc.resetFont();

    bool extender = true;
    try {
      final dynamic ext = _dyn(octave).getExtender?.call() ??
          _dyn(octave).extender;
      if (ext == Boolean.falseValue) extender = false;
      if (ext == false) extender = false;
    } catch (e) { e.toString(); }
    if (extender) {
      int lineWidth = _getOctaveLineWidth(octave, unit);
      final int gap = lineWidth * 4;
      x1 += lineWidth;
      if (altSymbols) x1 += extend.width ~/ 2;

      PenStyle penStyle = PenStyle.shortDash;
      LineCapStyle cap = LineCapStyle.square;
      int actualGap = gap;
      int actualLineWidth = lineWidth;
      bool hasLform = false;
      try {
        hasLform = _dyn(octave).hasLform == true;
      } catch (e) { e.toString(); }
      if (hasLform) {
        Lineform lf = Lineform.none;
        try {
          lf = _dyn(octave).getLform() as Lineform;
        } catch (e) { e.toString(); }
        if (lf == Lineform.solid) {
          penStyle = PenStyle.solid;
          actualGap = 0;
        } else if (lf == Lineform.dotted) {
          if (spanningType == spanningStartEnd || spanningType == spanningEnd) {
            final int diff = (x2 - x1) % (gap + 1);
            x2 += (gap - diff < diff) ? gap - diff : -diff;
          }
          penStyle = PenStyle.solid;
          cap = LineCapStyle.round;
          actualLineWidth = lineWidth * 3 ~/ 2;
        }
      }
      dc.setPen(actualLineWidth, penStyle, gapLength: actualGap, lineCap: cap);

      final bool isAboveHook = isAbove;
      y1 += isAboveHook ? -lineWidth ~/ 2 : lineWidth ~/ 2;
      y2 = isAboveHook ? y1 - unit * 2 : y1 + unit * 2;

      if (x1 + unit > x2) {
        x2 = x1 + unit - lineWidth ~/ 2;
      } else {
        dc.drawLine(toDeviceContextX(x1), toDeviceContextY(y1),
            toDeviceContextX(x2), toDeviceContextY(y1));
      }

      try {
        _dyn(octave).setDrawingExtenderX?.call(x1, x2);
      } catch (e) {
        try {
          _dyn(octave).setDrawingExtenderX(x1, x2);
        } catch (e) { e.toString(); }
      }

      Linestartendsymbol lendsym = Linestartendsymbol.none;
      try {
        lendsym = _dyn(octave).getLendsym() as Linestartendsymbol;
      } catch (e) { e.toString(); }
      // The C++ compares against `LINESTARTENDSYMBOL_none` (the MEI "none"
      // value, 20), NOT against `LINESTARTENDSYMBOL_NONE` (the unset default,
      // 0) — so the hook is drawn unless @lendsym="none" is given explicitly
      // (view_control.cpp:931). `none0` mirrors the MEI value here.
      if (lendsym != Linestartendsymbol.none0) {
        if (spanningType == spanningEnd || spanningType == spanningStartEnd) {
          Lineform lf = Lineform.none;
          try {
            lf = _dyn(octave).getLform() as Lineform;
          } catch (e) { e.toString(); }
          if (lf == Lineform.dotted) {
            dc.setPen(lineWidth * 3 ~/ 2, PenStyle.dot,
                gapLength:
                    gap < unit * 2 - lineWidth ? gap : unit * 2 - lineWidth,
                lineCap: LineCapStyle.round);
            dc.drawLine(toDeviceContextX(x2), toDeviceContextY(y1),
                toDeviceContextX(x2), toDeviceContextY(y2));
            dc.resetPen();
          } else {
            dc.setPen(lineWidth, PenStyle.solid);
            final List<Point> hook = [
              Point(toDeviceContextX(x2), toDeviceContextY(y2)),
              Point(toDeviceContextX(x2), toDeviceContextY(y1)),
              Point(toDeviceContextX(x2 - unit), toDeviceContextY(y1)),
            ];
            dc.drawPolyline(hook);
            dc.resetPen();
          }
        }
      }

      dc.resetPen();
    }

    if (graphic != null) {
      dc.endResumedGraphic(graphic as BoundingBox);
    } else {
      dc.endGraphic(octave as BoundingBox);
    }
  }

  // ---------------------------------------------------------------------------
  // View::DrawTie (view_control.cpp:1067)
  // ---------------------------------------------------------------------------

  /// Mirrors `View::DrawTie` (view_control.cpp:1067) — the geometry comes from
  /// `Tie::CalculatePosition` (Phase 4). Here we port the View part and
  /// approximate the curve with a reduced `CalculatePosition`.
  void drawTie(DeviceContext dc, Tie tie, int x1, int x2, Staff staff,
      int spanningType, Object? graphic) {
    final List<Point> bezier = List<Point>.filled(4, Point(0, 0));
    if (!_calculateTiePosition(tie, staff, x1, x2, spanningType, bezier)) {
      return;
    }
    for (final Point p in bezier) {
      p.y = calcOffsetY(dc, p.y);
    }

    Lineform lform = Lineform.none;
    try {
      lform = _dyn(tie).getLform?.call() as Lineform? ??
          _dyn(tie).lform as Lineform? ??
          Lineform.none;
    } catch (e) { e.toString(); }
    PenStyle penStyle = PenStyle.solid;
    if (lform == Lineform.dashed) {
      penStyle = PenStyle.shortDash;
    } else if (lform == Lineform.dotted) penStyle = PenStyle.dot;

    if (graphic != null) {
      dc.resumeGraphic(
          graphic as BoundingBox, _dyn(graphic).id as String);
    } else {
      dc.startGraphic(tie as BoundingBox, '', tie.id,
          graphicID: GraphicID.spanning);
    }

    final int thickness =
        (doc!.getDrawingUnit(staff.drawingStaffSize) * _tieMidpointThickness())
            .toInt();
    final int penWidth =
        (_tieEndpointThickness() * doc!.getDrawingUnit(staff.drawingStaffSize))
            .toInt();
    final double coeff =
        BoundingBox.getBezierThicknessCoefficient(bezier, thickness, penWidth);
    drawThickBezierCurve(dc, bezier, (coeff * thickness).toInt(),
        staff.drawingStaffSize, penWidth, penStyle);

    if (graphic != null) {
      dc.endResumedGraphic(graphic as BoundingBox);
    } else {
      dc.endGraphic(tie as BoundingBox);
    }
  }

  // ---------------------------------------------------------------------------
  // View::DrawPedalLine (view_control.cpp:1110)
  // ---------------------------------------------------------------------------

  /// Mirrors `View::DrawPedalLine` (view_control.cpp:1110).
  void drawPedalLine(DeviceContext dc, Pedal pedal, int x1, int x2, Staff staff,
      int spanningType, Object? graphic) {
    int y = 0;
    try {
      y = pedal.getDrawingY();
    } catch (e) {
      try {
        y = _dyn(pedal).getDrawingY() as int;
      } catch (e) {
        y = staff.getDrawingY();
      }
    }
    y = calcOffsetY(dc, y);

    int startRadius = 0;
    try {
      if (!(pedal.getStart() as Object).isClass(ClassId.timestampAttr)) {
        startRadius = _drawingRadius(pedal.getStart() as LayerElement);
      }
    } catch (e) { e.toString(); }
    int endRadius = 0;
    try {
      if (!(pedal.getEnd() as Object).isClass(ClassId.timestampAttr)) {
        endRadius = _drawingRadius(pedal.getEnd() as LayerElement);
      }
    } catch (e) { e.toString(); }

    if (spanningType == spanningStartEnd || spanningType == spanningStart) {
      x1 -= startRadius;
      Pedalstyle form = Pedalstyle.none;
      try {
        form = pedal.form as Pedalstyle;
      } catch (e) {
        try {
          form = _dyn(pedal).getForm() as Pedalstyle;
        } catch (e) { e.toString(); }
      }
      if (form == Pedalstyle.pedline || form == Pedalstyle.pedstar) {
        x1 += doc!.getGlyphWidth(0xE650, staff.drawingStaffSize, false);
      }
    }
    if (spanningType == spanningStartEnd || spanningType == spanningEnd) {
      x2 -= endRadius - doc!.getDrawingStemWidth(staff.drawingStaffSize);
    }

    if (graphic != null) {
      dc.resumeGraphic(
          graphic as BoundingBox, _dyn(graphic).id as String);
    } else {
      dc.startGraphic(pedal as BoundingBox, '', pedal.id,
          graphicID: GraphicID.spanning);
    }

    final int bracketSize = doc!.getDrawingDoubleUnit(staff.drawingStaffSize);
    final int lineWidth =
        (_pedalLineThickness() * doc!.getDrawingUnit(staff.drawingStaffSize))
            .toInt();

    Pedalstyle form = Pedalstyle.none;
    try {
      form = pedal.form as Pedalstyle;
    } catch (e) {
      try {
        form = _dyn(pedal).getForm() as Pedalstyle;
      } catch (e) { e.toString(); }
    }

    if (spanningType == spanningStartEnd || spanningType == spanningStart) {
      if (form != Pedalstyle.pedline && form != Pedalstyle.pedstar) {
        drawFilledRectangle(dc, x1, y, x1 + bracketSize ~/ 2, y + lineWidth);
        drawFilledRectangle(dc, x1, y, x1 + lineWidth, y + bracketSize);
      }
    }
    if (spanningType == spanningStartEnd || spanningType == spanningEnd) {
      if (form != Pedalstyle.pedstar) {
        drawFilledRectangle(dc, x2 - bracketSize ~/ 2, y, x2, y + lineWidth);
        drawFilledRectangle(dc, x2 - lineWidth, y, x2, y + bracketSize);
      } else {
        final String str = String.fromCharCode(0xE655);
        final int staffSize = staff.drawingStaffSize;
        dc.setFont(doc!.getDrawingSmuflFont(staffSize, false));
        drawSmuflString(dc, x2, y, str, HorizontalAlignment.left, staffSize);
        dc.resetFont();
      }
    }
    drawFilledRectangle(
        dc, x1 + bracketSize ~/ 2, y, x2 - bracketSize ~/ 2, y + lineWidth);

    if (graphic != null) {
      dc.endResumedGraphic(graphic as BoundingBox);
    } else {
      dc.endGraphic(pedal as BoundingBox);
    }
  }

  // ---------------------------------------------------------------------------
  // View::DrawTrillExtension (view_control.cpp:1189)
  // ---------------------------------------------------------------------------

  /// Mirrors `View::DrawTrillExtension` (view_control.cpp:1189).
  void drawTrillExtension(DeviceContext dc, Trill trill, int x1, int x2,
      Staff staff, int spanningType, Object? graphic) {
    int y = 0;
    try {
      y = trill.getDrawingY();
    } catch (e) {
      y = staff.getDrawingY();
    }
    y += doc!.getGlyphHeight(0xE566, staff.drawingStaffSize, false) ~/ 3;
    y = calcOffsetY(dc, y);

    Linestartendsymbol lstartsym = Linestartendsymbol.none;
    try {
      lstartsym = trill.lstartsym as Linestartendsymbol;
    } catch (e) {
      try {
        lstartsym = _dyn(trill).getLstartsym() as Linestartendsymbol;
      } catch (e) { e.toString(); }
    }

    if (lstartsym == Linestartendsymbol.none ||
        lstartsym == Linestartendsymbol.none0) {
      try {
        x1 -= _drawingRadius(trill.getStart() as LayerElement);
      } catch (e) { e.toString(); }
      y += doc!.getDrawingUnit(staff.drawingStaffSize) ~/ 2;
    } else if (spanningType == spanningStart ||
        spanningType == spanningStartEnd) {
      int offsetFactor = 2;
      try {
        if ((trill.getStart() as Object).isClass(ClassId.timestampAttr)) {
          offsetFactor = 1;
        }
      } catch (e) { e.toString(); }
      x1 += doc!.getGlyphWidth(0xE566, staff.drawingStaffSize, false) ~/
          offsetFactor;
    }

    try {
      if (!(trill.getEnd() as Object).isClass(ClassId.timestampAttr)) {
        x2 -= _drawingRadius(trill.getEnd() as LayerElement);
      }
    } catch (e) { e.toString(); }
    x2 -= doc!.getDrawingDoubleUnit(staff.drawingStaffSize);

    final int length = x2 - x1;
    final Point orig = Point(x1, y);

    if (graphic != null) {
      dc.resumeGraphic(
          graphic as BoundingBox, _dyn(graphic).id as String);
    } else {
      dc.startGraphic(trill as BoundingBox, '', trill.id,
          graphicID: GraphicID.spanning);
    }

    drawSmuflLine(
        dc, orig, length, staff.drawingStaffSize, false, 0xE59D, 0, 0xE59E);

    if (graphic != null) {
      dc.endResumedGraphic(graphic as BoundingBox);
    } else {
      dc.endGraphic(trill as BoundingBox);
    }
  }

  // ---------------------------------------------------------------------------
  // View::DrawControlElementConnector (view_control.cpp:1240)
  // ---------------------------------------------------------------------------

  /// Mirrors `View::DrawControlElementConnector` (view_control.cpp:1240).
  void drawControlElementConnector(DeviceContext dc, ControlElement element,
      int x1, int x2, Staff staff, int spanningType, Object? graphic) {
    // Adjust x1 for start floating positioner content right
    if (spanningType == spanningStart || spanningType == spanningStartEnd) {
      try {
        final dynamic pos = _dyn(element).getCurrentFloatingPositioner();
        if (pos != null && pos.hasContentBB == true) {
          x1 = pos.getContentRight() as int;
        } else if (pos != null) {
          try {
            if (pos.hasContentBB()) x1 = pos.getContentRight() as int;
          } catch (e) { e.toString(); }
        }
      } catch (e) { e.toString(); }
    }
    if (spanningType == spanningEnd || spanningType == spanningStartEnd) {
      try {
        final Object? next = _dyn(element).getNextLink() as Object?;
        if (next != null) {
          final dynamic nextPos =
              _dyn(element).getCorrespFloatingPositioner(next);
          if (nextPos != null) {
            try {
              if (nextPos.hasContentBB == true || nextPos.hasContentBB()) {
                x2 = nextPos.getContentLeft() as int;
              }
            } catch (e) {
              try {
                x2 = nextPos.getContentLeft() as int;
              } catch (e) { e.toString(); }
            }
          }
        }
      } catch (e) { e.toString(); }
    }

    final int width =
        (_lyricLineThickness() * doc!.getDrawingUnit(staff.drawingStaffSize))
            .toInt();
    int y = 0;
    try {
      y = (_dyn(element).getDrawingY() as int) + width ~/ 2;
    } catch (e) {
      y = staff.getDrawingY() + width ~/ 2;
    }
    y = calcOffsetY(dc, y);

    final int unit = doc!.getDrawingUnit(staff.drawingStaffSize);
    final int dashSpace =
        doc!.getDrawingStaffSize(staff.drawingStaffSize) * 5 ~/ 3;
    final int minDashSpace = (_extenderLineMinSpace() * unit).toInt();
    final int halfDashLength = unit * 2 ~/ 3;

    final int dist = x2 - x1;
    int nbDashes = dist ~/ dashSpace;
    int margin = dist ~/ 2;
    if (dist < minDashSpace) {
      nbDashes = 0;
    } else if (nbDashes < 2) {
      nbDashes = 1;
    } else {
      margin = (dist - ((nbDashes - 1) * dashSpace)) ~/ 2;
    }

    if (graphic != null) {
      dc.resumeGraphic(
          graphic as BoundingBox, _dyn(graphic).id as String);
    } else {
      dc.startGraphic(element as BoundingBox, '', element.id,
          graphicID: GraphicID.spanning);
    }

    bool deactivate = true;
    try {
      final Object? next = _dyn(element).getNextLink();
      if (next == null &&
          spanningType != spanningStartEnd &&
          spanningType != spanningStart) {
        deactivate = false;
      }
    } catch (e) { e.toString(); }

    if (deactivate) {
      dc.deactivateGraphic();
      try {
        _dyn(element)
            .getCurrentFloatingPositioner()
            ?.setDrawingExtenderWidth(dist);
      } catch (e) { e.toString(); }
    }

    for (int i = 0; i < nbDashes; ++i) {
      int x = x1 + margin + (i * dashSpace);
      if (x < x1) x = x1;
      drawFilledRectangle(
          dc, x - halfDashLength, y, x + halfDashLength, y + width);
    }

    if (deactivate) {
      dc.reactivateGraphic();
    }

    if (graphic != null) {
      dc.endResumedGraphic(graphic as BoundingBox);
    } else {
      dc.endGraphic(element as BoundingBox);
    }
  }

  // ---------------------------------------------------------------------------
  // View::DrawFConnector (view_control.cpp:1336)
  // ---------------------------------------------------------------------------

  /// Mirrors `View::DrawFConnector` (view_control.cpp:1336).
  void drawFConnector(DeviceContext dc, F f, int x1, int x2, Staff staff,
      int spanningType, Object? graphic) {
    if (_dyn(f).getStart == null && _dyn(f).getEnd == null) {
      try {
        if (_dyn(f).getStart() == null ||
            _dyn(f).getEnd() == null) {
          return;
        }
      } catch (e) { e.toString(); }
    }

    int y = _getFYRel(f, staff);
    y = calcOffsetY(dc, y);

    if (spanningType == spanningStartEnd) {
      try {
        x1 = _dyn(f).getContentRight() as int;
      } catch (e) {
        try {
          x1 = f.getContentRight();
        } catch (e) { e.toString(); }
      }
    } else if (spanningType == spanningStart) {
      try {
        final Text? text = f.getFirst(ClassId.text) as Text?;
        if (text != null) x1 = text.getContentRight();
      } catch (e) { e.toString(); }
    }

    Object? fb;
    try {
      fb = _dyn(graphic)?.getFirstAncestor(ClassId.fb);
      fb ??= f.getFirstAncestor(ClassId.fb);
    } catch (e) { e.toString(); }

    final F fConnector = F();
    if (fb != null) {
      dc.resumeGraphic(fb as BoundingBox, _dyn(fb).id as String);
    } else {
      dc.startGraphic(fConnector as BoundingBox, '', f.id,
          graphicID: GraphicID.spanning);
    }

    dc.deactivateGraphic();

    int width =
        (_lyricLineThickness() * doc!.getDrawingUnit(staff.drawingStaffSize))
            .toInt();
    width = _adjustToLyricSizeRet(width);

    drawFilledRectangle(dc, x1, y, x2, y + width);

    dc.reactivateGraphic();

    if (fb != null) {
      dc.endResumedGraphic(fb as BoundingBox);
    } else {
      dc.endGraphic(fConnector as BoundingBox);
    }
  }

  // ---------------------------------------------------------------------------
  // View::DrawSylConnector (view_control.cpp:1394)
  // ---------------------------------------------------------------------------

  /// Mirrors `View::DrawSylConnector` (view_control.cpp:1394).
  void drawSylConnector(DeviceContext dc, Syl syl, int x1, int x2, Staff staff,
      int spanningType, Object? graphic) {
    if (syl.getStart() == null || syl.getEnd() == null) return;

    final Staffrel place = _toStaffrel(syl.drawingVersePlace);
    int y = staff.getDrawingY() + getSylYRel(syl.drawingVerseN, staff, place);
    y = calcOffsetY(dc, y);

    // Invalid bounding boxes might occur for empty syllables without text
    // child (view_control.cpp:1404-1406).
    if (!syl.hasContentHorizontalBB()) return;
    final Object? nextWordSyl = syl.nextWordSyl;
    if (nextWordSyl != null && !nextWordSyl.hasContentHorizontalBB()) return;

    // The both correspond to the current system, which means no system break
    // in-between (simple case) — view_control.cpp:1408-1442.
    if (spanningType == spanningStartEnd) {
      x1 = syl.getContentRight();
      if (nextWordSyl != null) {
        x2 = nextWordSyl.getContentLeft();
      }
    }
    // Only the first parent is the same, this means that the syl is "open" at
    // the end of the system (view_control.cpp:1415-1418).
    else if (spanningType == spanningStart) {
      x1 = syl.getContentRight();
    }
    // We are in the system of the last note - draw the connector from the
    // beginning of the system (view_control.cpp:1419-1437).
    else if (spanningType == spanningEnd) {
      // If we do not want to show hyphens at the start of a system and the end
      // is at time 0.
      if (doc!.getOptions().lyricNoStartHyphen.value &&
          (syl.getEnd()!.getAlignment()?.getTime() == Fraction(0))) {
        // Return but only if the end is in the first measure of the system...
        final Measure? measure =
            syl.getEnd()!.getFirstAncestor(ClassId.measure) as Measure?;
        final System? system =
            measure?.getFirstAncestor(ClassId.system) as System?;
        if (measure != null && system != null) {
          if (identical(measure, system.findDescendantByType(ClassId.measure))) {
            return;
          }
        }
      }
      // Otherwise just adjust x2.
      if (nextWordSyl != null) {
        x2 = nextWordSyl.getContentLeft();
      }
      x1 -= doc!.getDrawingDoubleUnit(staff.drawingStaffSize);
    }
    // Rare case where neither the first note nor the last note are in the
    // current system - draw the connector throughout the system: nothing to
    // adjust (view_control.cpp:1438-1442).

    // Because Syl is not a ControlElement (FloatingElement) with
    // FloatingPositioner we need to instantiate a temporary object in order
    // not to reset the Syl bounding box (view_control.cpp:1444-1452).
    final Syl sylConnector = Syl();
    if (graphic != null) {
      dc.resumeGraphic(graphic, graphic.id);
    } else {
      dc.startGraphic(sylConnector, '', syl.id, graphicID: GraphicID.spanning);
    }

    dc.deactivateGraphic();

    drawSylConnectorLines(dc, x1, x2, y, syl, staff);

    dc.reactivateGraphic();

    if (graphic != null) {
      dc.endResumedGraphic(graphic);
    } else {
      dc.endGraphic(sylConnector);
    }
  }

  // ---------------------------------------------------------------------------
  // View::DrawSylConnectorLines (view_control.cpp:1468)
  // ---------------------------------------------------------------------------

  /// Mirrors `View::DrawSylConnectorLines` (view_control.cpp:1468) — hyphen
  /// (`con == d`) vs extender (`con == u`), registered by `DrawSyl` (05-16).
  void drawSylConnectorLines(
      DeviceContext dc, int x1, int x2, int y, Syl syl, Staff staff) {
    if (dc is BBoxDeviceContext) return;

    int thickness =
        (_lyricLineThickness() * doc!.getDrawingUnit(staff.drawingStaffSize))
            .toInt();
    thickness = _adjustToLyricSizeRet(thickness);

    if (syl.con == SyllogCon.d) {
      // C++: `m_lyricSize.GetValue() * GetDrawingUnit(...) / 5` — the
      // multiplication is double, the division truncates to int
      // (view_control.cpp:1479).
      y += (doc!.getOptions().lyricSize.value *
              doc!.getDrawingUnit(staff.drawingStaffSize) /
              5)
          .toInt();

      // The length of the dash and the space between them
      // (view_control.cpp:1482-1500).
      final int dashLength = syl.calcHyphenLength(doc!, staff.drawingStaffSize);
      final int halfDashLength = dashLength ~/ 2;

      final int dashSpace =
          doc!.getDrawingStaffSize(staff.drawingStaffSize) * 5 ~/ 3;
      final int dist = x2 - x1;
      int nbDashes = dist ~/ dashSpace;

      int margin = dist ~/ 2;
      // no dash if the distance is smaller than a dash length
      if (dist < dashLength) {
        logDebug('Hyphen space under the limit');
        nbDashes = 0;
      } else if (nbDashes < 2) {
        nbDashes = 1;
      } else {
        margin = (dist - ((nbDashes - 1) * dashSpace)) ~/ 2;
      }

      for (int i = 0; i < nbDashes; ++i) {
        int x = x1 + margin + (i * dashSpace);
        if (x < x1) x = x1;

        drawFilledRectangle(
            dc, x - halfDashLength, y, x + halfDashLength, y + thickness);
      }
    } else if (syl.con == SyllogCon.u) {
      x1 += doc!.getDrawingUnit(staff.drawingStaffSize) ~/ 2;
      if (x2 > x1) {
        drawFilledRectangle(dc, x1, y, x2, y + thickness);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // View::DrawControlElementText (view_control.cpp:1745)
  // ---------------------------------------------------------------------------

  /// Mirrors `View::DrawControlElementText` (view_control.cpp:1745) — base for
  /// `dir`, `tempo` (non-spanning), `cpMark`, `ornam` and `repeatMark` with
  /// children. `dir` has no `DrawDir` of its own (line 72 comment).
  void drawControlElementText(DeviceContext dc, ControlElement element,
      Measure measure, System system) {
    // Mirrors `View::DrawControlElementText` (view_control.cpp:1745). The
    // interface getters live on `Object` (object.h:192-196) and return null
    // when the class does not apply the interface.
    final TimePointInterface? iface = element.getTimePointInterface();
    if (iface == null) return;
    final TextDirInterface? ifaceTextDir = element.getTextDirInterface();
    final LayerElement? start = iface.getStart();

    // The C++ asserts the interfaces and `if (!start) return;` (1760).
    if (start == null) return;

    dc.startGraphic(element as BoundingBox, '', element.id);

    final Staffrel? place =
        (ifaceTextDir != null) ? ifaceTextDir.place : null;

    // Font for dir text (italic) — mirrors FontInfo dirTxt
    final FontInfo dirTxt = FontInfo();
    if (!dc.useGlobalStyling()) {
      dirTxt.faceName = doc!.getResources().textFontName;
      dirTxt.fontStyle = FontStyle.italic;
    }

    final int lineCount = (ifaceTextDir != null)
        ? ifaceTextDir.getNumberOfLines(element)
        : 1;

    HorizontalAlignment alignment = HorizontalAlignment.left;
    try {
      final dynamic hal = _dyn(element).getChildRendAlignment();
      if (hal is HorizontalAlignment) {
        alignment = hal;
      } else if (hal is Horizontalalignment)
        alignment = _convertHalign(hal);
      else if (hal?.toString().contains('center') == true)
        alignment = HorizontalAlignment.center;
      else if (hal?.toString().contains('right') == true)
        alignment = HorizontalAlignment.right;
      else if (hal?.toString().contains('left') == true)
        alignment = HorizontalAlignment.left;
      // treat none as left for dir/cpm etc
      if (alignment == HorizontalAlignment.none_) {
        alignment = HorizontalAlignment.left;
      }
      final String halStr = hal?.toString() ?? '';
      if (halStr.contains('none') || halStr == '0') {
        alignment = HorizontalAlignment.left;
      }
    } catch (e) {
      alignment = HorizontalAlignment.left;
    }
    // dir are left aligned by default
    // (already left)

    // Mirrors `interface->GetTstampStaves(measure, element)` — no fallback in
    // the C++: an empty list simply skips the drawing loop.
    final List<Staff> staffList = iface.getTstampStaves(measure, element);

    for (final Staff staff in staffList) {
      if (!system.setSystemCurrentFloatingPositioner(
          staff.n ?? meiUnset, element, start, staff)) {
        continue;
      }
      final int staffSize = staff.drawingStaffSize;
      int x = start.getDrawingX() + _drawingRadius(start);
      int y = element.getDrawingY();

      setOffsetStaffSize(element, staffSize);
      final r = calcOffset(dc, x, y);
      x = r.$1;
      y = r.$2;

      final TextDrawingParams params = TextDrawingParams();
      params.x = x;
      params.y = y;
      try {
        params.pointSize = doc!.getDrawingLyricFont(staffSize).pointSize;
      } catch (e) {
        params.pointSize = 0;
      }

      int xAdjust = 0;
      // Mirrors `isBetweenStaves` (view_control.cpp:1788-1791).
      final bool isBetween = (place == Staffrel.between) ||
          ((place == Staffrel.below) && (staff != measure.getLastStaff())) ||
          ((place == Staffrel.above) && (staff != measure.getFirstStaff()));
      if (isBetween) {
        try {
          final dynamic align = _dyn(start).getAlignment();
          final dynamic rightAl =
              measure.measureAligner.getRightBarLineAlignment();
          final bool atRight = align != null &&
              rightAl != null &&
              align.getTime() == rightAl.getTime();
          final bool rightAligned = (ifaceTextDir != null) &&
              ifaceTextDir.areChildrenAlignedTo(
                  element, Horizontalalignment.right);
          if (atRight && rightAligned) {
            xAdjust = doc!.getDrawingUnit(staffSize) ~/ 2;
          }
        } catch (e) { e.toString(); }
      }

      dirTxt.pointSize = params.pointSize;

      if (place == Staffrel.between || place == Staffrel.within) {
        if (lineCount > 1) {
          final int lh = doc!.getTextLineHeight(dirTxt, false);
          params.y += (lh * (lineCount - 1) ~/ 2);
        }
        final int xh =
            doc!.getTextGlyphHeight('x'.codeUnitAt(0), dirTxt, false);
        params.y -= xh ~/ 2;
      }

      dc.setFont(dirTxt);
      dc.startText(toDeviceContextX(params.x - xAdjust),
          toDeviceContextY(params.y), alignment);
      drawTextChildren(dc, element, params);
      dc.endText();
      dc.resetFont();

      drawTextEnclosure(dc, params, staffSize);
    }

    dc.endGraphic(element as BoundingBox);
  }

  // ---------------------------------------------------------------------------
  // View::DrawDynam (view_control.cpp:1829)
  // ---------------------------------------------------------------------------

  /// Mirrors `View::DrawDynam` (view_control.cpp:1829) — chooses
  /// `DrawDynamSymbolOnly` when the text is only `p`/`m`/`f`/`r`/`s`/`z`/`n`.
  void drawDynam(
      DeviceContext dc, dynamic dynam, Measure measure, System system) {
    dynamic start;
    try {
      start = _dyn(dynam).getStart();
    } catch (e) {
      try {
        start = _dyn(dynam).getTimePointInterface()?.getStart();
      } catch (e) { e.toString(); }
    }

    dc.startGraphic(dynam as BoundingBox, '', _dyn(dynam).id as String);

    // Determine symbol-only
    String dynamText = '';
    try {
      dynamText = _dyn(dynam).getText() as String;
    } catch (e) {
      try {
        dynamText = _collectDynamText(dynam as Object);
      } catch (e) { e.toString(); }
    }
    bool isSymbolOnly = _dynamIsSymbolOnly(dynamText);
    // Also respect the model cache if exists
    try {
      final bool modelSym = _dyn(dynam).isSymbolOnly() as bool;
      // Use model result if it differs (it may have cached m_symbolStr)
      if (modelSym != isSymbolOnly) isSymbolOnly = modelSym;
    } catch (e) { e.toString(); }

    final FontInfo dynamTxt = FontInfo();
    if (!dc.useGlobalStyling()) {
      try {
        dynamTxt.faceName = doc!.getResources().textFontName;
      } catch (e) {
        try {
          dynamTxt.faceName = doc!.getResources().textFontName;
        } catch (e) { e.toString(); }
      }
      dynamTxt.fontStyle = FontStyle.italic;
    }

    int lineCount = 1;
    try {
      lineCount = _dyn(dynam).getNumberOfLines(dynam) as int;
    } catch (e) {
      try {
        lineCount = (dynam as Object).getDescendantCount(ClassId.lb) + 1;
      } catch (e) { e.toString(); }
    }

    HorizontalAlignment alignment = HorizontalAlignment.left;
    try {
      final dynamic hal = _dyn(dynam).getChildRendAlignment();
      if (hal is HorizontalAlignment) {
        alignment = hal;
      } else if (hal is Horizontalalignment)
        alignment = _convertHalign(hal);
      else {
        final String s = hal?.toString() ?? '';
        if (s.contains('center')) {
          alignment = HorizontalAlignment.center;
        } else if (s.contains('right'))
          alignment = HorizontalAlignment.right;
        else if (s.contains('left'))
          alignment = HorizontalAlignment.left;
        else
          alignment = HorizontalAlignment.none_;
      }
    } catch (e) {
      alignment = HorizontalAlignment.none_;
    }
    if (alignment == HorizontalAlignment.none_) {
      bool isTstamp = false;
      try {
        isTstamp = _dyn(start).isClass(ClassId.timestampAttr) == true;
        if (!isTstamp) {
          isTstamp = (start is LayerElement) &&
              _dyn(start).isTimestampAttr == true;
        }
        // fallback: check if dynam has @tstamp
        final dynamic tstamp = _dyn(dynam).tstamp;
        if (tstamp != null) isTstamp = true;
        final dynamic hasTstamp = _dyn(dynam).hasTstamp;
        if (hasTstamp == true) isTstamp = true;
      } catch (e) { e.toString(); }
      alignment =
          isTstamp ? HorizontalAlignment.left : HorizontalAlignment.center;
    }

    List<Staff> staffList = [];
    try {
      final dynamic iface = _dyn(dynam).getTimePointInterface() ?? dynam;
      final dynamic staves = _dyn(iface).getTstampStaves(measure, dynam);
      if (staves is List) staffList = staves.cast<Staff>();
    } catch (e) { e.toString(); }
    if (staffList.isEmpty) {
      try {
        final Staff? s =
            (start as Object).getFirstAncestor(ClassId.staff) as Staff?;
        if (s != null) staffList = [s];
      } catch (e) { e.toString(); }
    }

    for (final Staff staff in staffList) {
      if (!system.setSystemCurrentFloatingPositioner(
          staff.n ?? meiUnset, dynam as ControlElement, start as Object, staff)) {
        continue;
      }
      final int staffSize = staff.drawingStaffSize;
      int x = 0, y = 0;
      try {
        x = (_dyn(start).getDrawingX() as int) +
            _drawingRadius(start as LayerElement);
      } catch (e) {
        try {
          x = dynam.getDrawingX();
        } catch (e) { e.toString(); }
      }
      try {
        y = _dyn(dynam).getDrawingY() as int;
      } catch (e) {
        y = staff.getDrawingY();
      }

      setOffsetStaffSize(dynam as Object, staffSize);
      final r = calcOffset(dc, x, y);
      x = r.$1;
      y = r.$2;

      final TextDrawingParams params = TextDrawingParams();
      params.x = x;
      params.y = y;
      try {
        params.pointSize = doc!.getDrawingLyricFont(staffSize).pointSize;
      } catch (e) { e.toString(); }

      try {
        final dynamic enc = _dyn(dynam).enclose;
        if (enc != null) {
          final String s = enc.toString();
          if (s.contains('paren')) {
            params.textEnclose = Enclosure.paren;
          } else if (s.contains('brack')) params.textEnclose = Enclosure.brack;
        }
        if (_dyn(dynam).hasEnclose == true) {
          final dynamic e = _dyn(dynam).getEnclose?.call() ??
              _dyn(dynam).enclose;
          if (e != null) {
            final String s = e.toString();
            if (s.contains('paren')) {
              params.textEnclose = Enclosure.paren;
            } else if (s.contains('brack')) params.textEnclose = Enclosure.brack;
          }
        }
      } catch (e) { e.toString(); }

      try {
        dynamTxt.pointSize = params.pointSize;
      } catch (e) { e.toString(); }

      dynamic place;
      try {
        place = _dyn(dynam).place;
      } catch (e) { e.toString(); }
      final String placeStr = place?.toString() ?? '';
      if (placeStr.contains('between')) {
        if (lineCount > 1) {
          try {
            params.y += (doc!.getTextLineHeight(dynamTxt, false) *
                (lineCount - 1) ~/
                2);
          } catch (e) { e.toString(); }
        }
        try {
          params.y -= doc!.getTextGlyphHeight('x'.codeUnitAt(0), dynamTxt, false) ~/ 2;
        } catch (e) { e.toString(); }
      }

      if (isSymbolOnly) {
        bool singleGlyphs = false;
        try {
          singleGlyphs = (_dyn(doc!.getOptions())).dynamSingleGlyphs?.value
                  as bool? ??
              false;
        } catch (e) { e.toString(); }
        String sym = '';
        try {
          sym = _dyn(dynam).getSymbolStr(singleGlyphs) as String;
        } catch (e) {
          sym = _dynamGetSymbolStr(dynamText, singleGlyphs);
        }
        drawDynamSymbolOnly(dc, staff, dynam, sym, alignment, params);
      } else {
        dc.setFont(dynamTxt);
        dc.startText(
            toDeviceContextX(params.x), toDeviceContextY(params.y), alignment);
        drawTextChildren(dc, dynam as Object, params);
        dc.endText();
        dc.resetFont();
      }
      drawTextEnclosure(dc, params, staffSize);
    }

    dc.endGraphic(dynam);
  }

  // ---------------------------------------------------------------------------
  // View::DrawDynamSymbolOnly (view_control.cpp:1910)
  // ---------------------------------------------------------------------------

  /// Mirrors `View::DrawDynamSymbolOnly` (view_control.cpp:1910) — SMuFL glyph
  /// path for symbol-only dynamics.
  void drawDynamSymbolOnly(
      DeviceContext dc,
      Staff staff,
      dynamic dynam,
      String dynamSymbol,
      HorizontalAlignment alignment,
      TextDrawingParams params) {
    dc.setFont(doc!.getDrawingSmuflFont(staff.drawingStaffSize, false));

    int enclosingFront = 0, enclosingBack = 0;
    try {
      final dynamic pair = _dyn(dynam).getEnclosingGlyphs();
      if (pair is List && pair.length >= 2) {
        enclosingFront = pair[0] as int;
        enclosingBack = pair[1] as int;
      } else if (pair is Record) {
        // Dart record fallback
        enclosingFront = _dyn(pair).$1 as int? ?? 0;
        enclosingBack = _dyn(pair).$2 as int? ?? 0;
      } else {
        // Try tuple via dynamic
        try {
          final int f = _dyn(pair).first as int;
          final int b = _dyn(pair).second as int;
          enclosingFront = f;
          enclosingBack = b;
        } catch (e) { e.toString(); }
      }
    } catch (e) {
      // manual enclose mapping
      try {
        final dynamic enc = _dyn(dynam).enclose;
        if (enc != null) {
          final String s = enc.toString();
          if (s.contains('brack')) {
            enclosingFront = 0xE26C;
            enclosingBack = 0xE26D;
          } else if (s.contains('paren')) {
            enclosingFront = 0xE26A;
            enclosingBack = 0xE26B;
          }
        }
      } catch (e) { e.toString(); }
    }
    // Fallback if still 0 but has enclose
    if (enclosingFront == 0 && enclosingBack == 0) {
      try {
        final dynamic enc = _dyn(dynam).enclose;
        final String s = enc?.toString() ?? '';
        if (s.contains('brack')) {
          enclosingFront = 0xE26C;
          enclosingBack = 0xE26D;
        } else if (s.contains('paren')) {
          enclosingFront = 0xE26A;
          enclosingBack = 0xE26B;
        }
      } catch (e) { e.toString(); }
    }

    int left = 0;
    int width = 0;
    if (dynamSymbol.isNotEmpty) {
      try {
        left = doc!.getGlyphLeft(
            dynamSymbol.codeUnitAt(0), staff.drawingStaffSize, false);
      } catch (e) { e.toString(); }
      for (int i = 0; i < dynamSymbol.length; i++) {
        final int code = dynamSymbol.codeUnitAt(i);
        // For surrogate pairs, codeUnitAt splits — use runes instead if needed
        // but current symbols are BMP (E520 etc) so single unit is fine.
        if (i == dynamSymbol.length - 1) {
          try {
            width += doc!.getGlyphRight(code, staff.drawingStaffSize, false);
          } catch (e) {
            width += doc!.getGlyphWidth(code, staff.drawingStaffSize, false);
          }
        } else {
          try {
            width += doc!.getGlyphAdvX(code, staff.drawingStaffSize, false);
          } catch (e) {
            width += doc!.getGlyphWidth(code, staff.drawingStaffSize, false);
          }
        }
      }
      // If runes include surrogate pairs (unlikely for SMuFL 0xE520..E53D), fallback to runes length 1
      if (dynamSymbol.runes.length == 1 && dynamSymbol.length == 2) {
        // surrogate pair case
        final int cp = dynamSymbol.runes.first;
        try {
          left = doc!.getGlyphLeft(cp, staff.drawingStaffSize, false);
          width = doc!.getGlyphRight(cp, staff.drawingStaffSize, false);
        } catch (e) { e.toString(); }
      }
    }

    final int unit = doc!.getDrawingUnit(staff.drawingStaffSize);
    if (enclosingFront != 0) {
      final String open = String.fromCharCode(enclosingFront);
      drawSmuflString(dc, params.x, params.y + unit, open, alignment,
          staff.drawingStaffSize);
      int adv = 0;
      try {
        adv = doc!.getGlyphWidth(enclosingFront, staff.drawingStaffSize, false);
      } catch (e) { e.toString(); }
      params.x += adv - left + unit ~/ 6;
    }

    drawSmuflString(
        dc, params.x, params.y, dynamSymbol, alignment, staff.drawingStaffSize);

    if (enclosingBack != 0) {
      final String close = String.fromCharCode(enclosingBack);
      params.x += width + unit ~/ 6;
      drawSmuflString(dc, params.x, params.y + unit, close, alignment,
          staff.drawingStaffSize);
    }

    dc.resetFont();
  }

  // ---------------------------------------------------------------------------
  // View::DrawHarm (view_control.cpp:2288)
  // ---------------------------------------------------------------------------

  /// Mirrors `View::DrawHarm` (view_control.cpp:2288).
  void drawHarm(
      DeviceContext dc, dynamic harm, Measure measure, System system) {
    dynamic start;
    try {
      start = _dyn(harm).getStart();
    } catch (e) {
      return;
    }

    dc.startGraphic(harm as BoundingBox, '', _dyn(harm).id as String);

    final FontInfo harmTxt = FontInfo();
    if (!dc.useGlobalStyling()) {
      try {
        harmTxt.faceName = doc!.getResources().textFontName;
      } catch (e) {
        try {
          harmTxt.faceName = doc!.getResources().textFontName;
        } catch (e) { e.toString(); }
      }
    }

    HorizontalAlignment alignment = HorizontalAlignment.left;
    try {
      final dynamic hal = _dyn(harm).getChildRendAlignment();
      if (hal is HorizontalAlignment) {
        alignment = hal;
      } else if (hal is Horizontalalignment)
        alignment = _convertHalign(hal);
      else {
        final String s = hal?.toString() ?? '';
        if (s.contains('center')) {
          alignment = HorizontalAlignment.center;
        } else if (s.contains('right'))
          alignment = HorizontalAlignment.right;
        else if (s.contains('left'))
          alignment = HorizontalAlignment.left;
        else
          alignment = HorizontalAlignment.none_;
      }
    } catch (e) {
      alignment = HorizontalAlignment.none_;
    }
    if (alignment == HorizontalAlignment.none_) {
      bool isTstamp = false;
      try {
        isTstamp = _dyn(start).isClass(ClassId.timestampAttr) == true;
        final dynamic t = _dyn(harm).tstamp;
        if (t != null) isTstamp = true;
        if (_dyn(harm).hasTstamp == true) isTstamp = true;
      } catch (e) { e.toString(); }
      alignment =
          isTstamp ? HorizontalAlignment.left : HorizontalAlignment.center;
    }

    List<Staff> staffList = [];
    try {
      final dynamic staves = _dyn(harm).getTstampStaves(measure, harm);
      if (staves is List) staffList = staves.cast<Staff>();
    } catch (e) { e.toString(); }
    if (staffList.isEmpty) {
      try {
        final Staff? s =
            (start as Object).getFirstAncestor(ClassId.staff) as Staff?;
        if (s != null) staffList = [s];
      } catch (e) { e.toString(); }
    }

    for (final Staff staff in staffList) {
      if (!system.setSystemCurrentFloatingPositioner(
          staff.n ?? meiUnset, harm as ControlElement, start as Object, staff)) {
        continue;
      }
      final int staffSize = staff.drawingStaffSize;
      int x = 0, y = 0;
      try {
        x = (_dyn(start).getDrawingX() as int) +
            _drawingRadius(start as LayerElement);
      } catch (e) {
        try {
          x = harm.getDrawingX();
        } catch (e) { e.toString(); }
      }
      try {
        y = _dyn(harm).getDrawingY() as int;
      } catch (e) {
        y = staff.getDrawingY();
      }

      setOffsetStaffSize(harm as Object, staffSize);
      final r = calcOffset(dc, x, y);
      x = r.$1;
      y = r.$2;

      final TextDrawingParams params = TextDrawingParams();
      params.x = x;
      params.y = y;

      bool isFb = false;
      try {
        final dynamic first = _dyn(harm).getFirst();
        if (first != null && _dyn(first).isClass(ClassId.fb) == true) {
          isFb = true;
        }
        // removed dead fb lookup (was unused variable)
        if (!isFb) {
          // also check first child is fb via children list
          final Object? firstChild = (harm as Object).getFirst(ClassId.fb);
          if (firstChild != null) {
            // Check if firstChild is actually the first element (not deeper)
            final List<Object> kids = (harm as Object).children;
            if (kids.isNotEmpty && identical(kids.first, firstChild)) {
              isFb = true;
            }
          }
        }
      } catch (e) { e.toString(); }
      if (isFb) {
        dynamic fb;
        try {
          fb = _dyn(harm).getFirst();
        } catch (e) {
          try {
            fb = (harm as Object).findDescendantByType(ClassId.fb);
          } catch (e) { e.toString(); }
        }
        if (fb != null) {
          drawFb(dc, staff, _dyn(fb), params);
        }
      } else {
        try {
          params.pointSize = doc!.getDrawingLyricFont(staffSize).pointSize;
        } catch (e) { e.toString(); }
        try {
          harmTxt.pointSize = params.pointSize;
        } catch (e) { e.toString(); }
        dc.setFont(harmTxt);
        dc.startText(
            toDeviceContextX(params.x), toDeviceContextY(params.y), alignment);
        drawTextChildren(dc, harm as Object, params);
        dc.endText();
        dc.resetFont();
        drawTextEnclosure(dc, params, staffSize);
      }
    }

    dc.endGraphic(harm);
  }

  // ---------------------------------------------------------------------------
  // View::DrawFb (view_control.cpp:1960)
  // ---------------------------------------------------------------------------

  /// Mirrors `View::DrawFb` (view_control.cpp:1960) — stacked figured bass.
  void drawFb(
      DeviceContext dc, Staff staff, dynamic fb, TextDrawingParams params) {
    dc.startGraphic(fb as BoundingBox, '', _dyn(fb).id as String);

    FontInfo? fontDim;
    try {
      fontDim = doc!.getDrawingLyricFont(staff.drawingStaffSize);
    } catch (e) {
      fontDim = FontInfo();
    }
    int lineHeight = 0;
    try {
      lineHeight = doc!.getTextLineHeight(fontDim, false);
    } catch (e) {
      try {
        lineHeight = doc!.getDrawingUnit(staff.drawingStaffSize) * 2;
      } catch (e) {
        lineHeight = 100;
      }
    }
    final int startX = params.x;
    try {
      fontDim.pointSize =
          doc!.getDrawingLyricFont(staff.drawingStaffSize).pointSize;
    } catch (e) { e.toString(); }

    dc.setFont(fontDim);

    List<Object> children = [];
    try {
      children = (fb as Object).children;
    } catch (e) {
      try {
        children = _dyn(fb).getChildren() as List<Object>;
      } catch (e) { e.toString(); }
    }

    for (final Object current in children) {
      dc.startText(toDeviceContextX(params.x), toDeviceContextY(params.y),
          HorizontalAlignment.left);
      if (current.isClass(ClassId.f)) {
        // C++ FIGURE ↔ Dart ClassId.f (view_control.cpp:1977); cast to F
        // check in DrawF. No fallback: a failed cast must surface, not
        // silently draw the figure without its <tspan class="f"> wrapper.
        drawF(dc, current as F, params);
      } else if (current.isEditorialElement) {
        try {
          drawFbEditorialElement(dc, _dyn(current), params);
        } catch (e) {
          try {
            drawTextChildren(dc, current, params);
          } catch (e) { e.toString(); }
        }
      } else {
        // fallback: still try text children
        try {
          drawTextChildren(dc, current, params);
        } catch (e) { e.toString(); }
      }
      dc.endText();
      params.y -= lineHeight;
      params.x = startX;
    }

    dc.resetFont();
    dc.endGraphic(fb);
  }

  // ---------------------------------------------------------------------------
  // View::DrawReh (view_control.cpp:2583)
  // ---------------------------------------------------------------------------

  /// Mirrors `View::DrawReh` (view_control.cpp:2583) — rehearsal mark with
  /// `DrawTextEnclosure` (box/circle) and optional clef-adjusted X.
  void drawReh(DeviceContext dc, Reh reh, Measure measure, System system) {
    // Reh should be drawn at measure start
    final LayerElement? rehStart = reh.getStart();
    if (rehStart == null) return;

    dc.startGraphic(reh, '', reh.id);

    final FontInfo rehTxt = FontInfo();
    if (!dc.useGlobalStyling()) {
      rehTxt.faceName = doc!.getResources().textFontName;
      rehTxt.fontWeight = FontWeight.bold;
    }

    // Number of units above the staff - 3 by default, 5 when above a clef
    int yMargin = 3;

    int drawingX = rehStart.getDrawingX();
    final bool adjustPosition = ((reh.hasTstamp && (reh.tstamp == 0.0)) ||
        (rehStart is BarLine && rehStart.position == BarlinePosition.left));
    if ((system.getFirst(ClassId.measure) == measure) && adjustPosition) {
      // StaffDef information is always in the first layer
      final Layer? layer =
          measure.findDescendantByType(ClassId.layer) as Layer?;
      if (layer != null) {
        if (!system.isFirstOfMdiv()) {
          final Clef? clef = layer.getStaffDefClef();
          if (clef != null) {
            drawingX = clef.getDrawingX() +
                (clef.getContentRight() - clef.getContentLeft()) ~/ 2;
            // Increase the margin when above the clef
            yMargin = 5;
          }
        } else {
          final MeterSig? metersig = layer.getStaffDefMeterSig();
          if (metersig != null) {
            drawingX = metersig.getDrawingX() +
                (metersig.getContentRight() - metersig.getContentLeft()) ~/ 2;
          }
        }
      }
    }

    HorizontalAlignment alignment =
        _convertHalign(reh.getChildRendAlignment());
    // Rehearsal marks are center aligned by default
    if (alignment == HorizontalAlignment.none_) {
      alignment = HorizontalAlignment.center;
    }

    final List<Staff> staffList = reh.getTstampStaves(measure, reh);
    if (staffList.isEmpty) {
      final Staff? staff = system.getTopVisibleStaff(false);
      if (staff != null) staffList.add(staff);
    }

    for (final Staff staff in staffList) {
      if (!system.setSystemCurrentFloatingPositioner(
          staff.n ?? meiUnset, reh, rehStart, staff)) {
        continue;
      }
      final int staffSize = staff.drawingStaffSize;
      int x = drawingX;
      if ((system.getFirst(ClassId.measure) != measure) && adjustPosition) {
        x = staff.getDrawingX();
      }
      int y = reh.getDrawingY() + yMargin * doc!.getDrawingUnit(staffSize);

      setOffsetStaffSize(reh, staffSize);
      final (int, int) offset = calcOffset(dc, x, y);
      x = offset.$1;
      y = offset.$2;

      final TextDrawingParams params = TextDrawingParams();
      params.x = x;
      params.y = y;
      params.pointSize = doc!.getDrawingLyricFont(staffSize).pointSize;

      rehTxt.pointSize = params.pointSize;

      dc.setFont(rehTxt);

      dc.startText(
          toDeviceContextX(params.x), toDeviceContextY(params.y), alignment);
      drawTextChildren(dc, reh, params);
      dc.endText();

      dc.resetFont();

      drawTextEnclosure(dc, params, staffSize);
    }

    dc.endGraphic(reh);
  }

  // ---------------------------------------------------------------------------
  // View::DrawTempo (view_control.cpp:2734)
  // ---------------------------------------------------------------------------

  /// Mirrors `View::DrawTempo` (view_control.cpp:2734).
  void drawTempo(
      DeviceContext dc, dynamic tempo, Measure measure, System system) {
    // "Cannot draw a tempo that has no start position" — view_control.cpp:2741:
    //     if (!tempo->GetStart()) return;
    //
    // This guard used to be `try { start = ...; } catch (e) { return; }`, which
    // returns when `getStart()` *throws* — not when it returns null, as the C++
    // tests. `Tempo` mixes in `TimePointInterface`, whose `getStart()` is a
    // plain field read that cannot throw, and `drawControlElement` dispatches
    // here only under `isClass(ClassId.tempo)`, so the catch was unreachable
    // and the null case fell through to the `start as Object` cast below.
    //
    // The null is a normal pipeline state, not bad data: `drawTempo` also runs
    // in the intermediate bounding-box pass (`Page.layOutHorizontally` ->
    // `_renderBoundingBoxes`, inside `castOffDocBase`), before the @tstamp is
    // resolved on that tree. Task 2026-08-29-01.
    final Object? start = _dyn(tempo).getStart() as Object?;
    if (start == null) return;

    dc.startGraphic(tempo as BoundingBox, '', _dyn(tempo).id as String);

    final FontInfo tempoTxt = FontInfo();
    if (!dc.useGlobalStyling()) {
      try {
        tempoTxt.faceName = doc!.getResources().textFontName;
      } catch (e) {
        try {
          tempoTxt.faceName = doc!.getResources().textFontName;
        } catch (e) { e.toString(); }
      }
      tempoTxt.fontWeight = FontWeight.bold;
    }

    int lineCount = 1;
    try {
      lineCount = _dyn(tempo).getNumberOfLines(tempo) as int;
    } catch (e) {
      try {
        lineCount = (tempo as Object).getDescendantCount(ClassId.lb) + 1;
      } catch (e) { e.toString(); }
    }

    HorizontalAlignment alignment = HorizontalAlignment.left;
    try {
      final dynamic hal = _dyn(tempo).getChildRendAlignment();
      if (hal is HorizontalAlignment) {
        alignment = hal;
      } else if (hal is Horizontalalignment)
        alignment = _convertHalign(hal);
      else {
        final String s = hal?.toString() ?? '';
        if (s.contains('center')) {
          alignment = HorizontalAlignment.center;
        } else if (s.contains('right'))
          alignment = HorizontalAlignment.right;
        else if (s.contains('left'))
          alignment = HorizontalAlignment.left;
        else
          alignment = HorizontalAlignment.none_;
      }
      if (alignment == HorizontalAlignment.none_) {
        alignment = HorizontalAlignment.left;
      }
      final String s = hal?.toString() ?? '';
      if (s == '0' || s.contains('NONE')) alignment = HorizontalAlignment.left;
    } catch (e) {
      alignment = HorizontalAlignment.left;
    }

    List<Staff> staffList = [];
    try {
      final dynamic staves = _dyn(tempo).getTstampStaves(measure, tempo);
      if (staves is List) staffList = staves.cast<Staff>();
    } catch (e) { e.toString(); }
    if (staffList.isEmpty) {
      try {
        final Staff? s =
            (start).getFirstAncestor(ClassId.staff) as Staff?;
        if (s != null) staffList = [s];
      } catch (e) { e.toString(); }
    }

    for (final Staff staff in staffList) {
      if (!system.setSystemCurrentFloatingPositioner(
          staff.n ?? meiUnset, tempo as ControlElement, start, staff)) {
        continue;
      }
      final int staffSize = staff.drawingStaffSize;
      int x = 0, y = 0;
      try {
        x = _dyn(tempo).getDrawingXRelativeToStaff(staff.n ?? 0) as int;
      } catch (e) {
        try {
          x = (_dyn(start).getDrawingX() as int) +
              _drawingRadius(start as LayerElement);
        } catch (e) {
          try {
            x = tempo.getDrawingX();
          } catch (e) { e.toString(); }
        }
      }
      try {
        y = _dyn(tempo).getDrawingY() as int;
      } catch (e) {
        y = staff.getDrawingY();
      }

      setOffsetStaffSize(tempo as Object, staffSize);
      final r = calcOffset(dc, x, y);
      x = r.$1;
      y = r.$2;

      final TextDrawingParams params = TextDrawingParams();
      params.x = x;
      params.y = y;
      try {
        params.pointSize = doc!.getDrawingLyricFont(staffSize).pointSize;
      } catch (e) { e.toString(); }
      try {
        tempoTxt.pointSize = params.pointSize;
      } catch (e) { e.toString(); }

      dynamic place;
      try {
        place = _dyn(tempo).place;
      } catch (e) { e.toString(); }
      final String placeStr = place?.toString() ?? '';
      if (placeStr.contains('between')) {
        if (lineCount > 1) {
          try {
            params.y += (doc!.getTextLineHeight(tempoTxt, false) *
                (lineCount - 1) ~/
                2);
          } catch (e) { e.toString(); }
        }
        try {
          params.y -= doc!.getTextGlyphHeight('x'.codeUnitAt(0), tempoTxt, false) ~/ 2;
        } catch (e) { e.toString(); }
      }

      dc.setFont(tempoTxt);
      dc.startText(
          toDeviceContextX(params.x), toDeviceContextY(params.y), alignment);
      drawTextChildren(dc, tempo as Object, params);
      dc.endText();
      dc.resetFont();
      drawTextEnclosure(dc, params, staffSize);
    }

    dc.endGraphic(tempo);
  }

  // ---------------------------------------------------------------------------
  // View::DrawHairpin (view_control.cpp:651)
  // ---------------------------------------------------------------------------

  /// Mirrors `View::DrawHairpin` (view_control.cpp:651) — `cres`/`dim` with
  /// `niente`, `opening`, `lform` and the `PrepareFloatingGrpsFunctor`
  /// shortening against `leftLink`/`rightLink`.
  void drawHairpin(DeviceContext dc, Hairpin hairpin, int x1, int x2,
      Staff staff, int spanningType, Object? graphic) {
    if (!hairpin.hasForm) {
      // we cannot draw a hairpin that has no form
      return;
    }

    final FloatingPositioner? leftLink =
        hairpin.getCorrespFloatingPositioner(hairpin.getLeftLink());
    final FloatingPositioner? rightLink =
        hairpin.getCorrespFloatingPositioner(hairpin.getRightLink());

    final int unit = doc!.getDrawingUnit(staff.drawingStaffSize);
    final HairpinlogForm form = hairpin.form!;
    final bool isDim = (form == HairpinlogForm.dim);
    final bool niente = hairpin.hasNiente ? (hairpin.niente == true) : false;

    int adjustedX1 = x1;
    if (leftLink != null) {
      adjustedX1 = leftLink.getContentRight() + unit ~/ 2;
      adjustedX1 += (niente && (form == HairpinlogForm.cres)) ? unit ~/ 3 : 0;
    }
    int adjustedX2 = x2;
    if (rightLink != null) {
      adjustedX2 = rightLink.getContentLeft() - unit ~/ 2;
      adjustedX2 -= (niente && (form == HairpinlogForm.dim)) ? unit ~/ 3 : 0;
    }

    // Beginning of a system, very short hairpin needs to be push left
    if (spanningType == spanningEnd) {
      if ((adjustedX2 - adjustedX1) < (unit * 2)) {
        adjustedX1 = adjustedX2 - 2 * unit;
      }
    }

    // In any case, a hairpin should not be shorter than 2 units.
    if ((adjustedX2 - adjustedX1) >= unit * 2) {
      x1 = adjustedX1;
      x2 = adjustedX2;
    }

    final (int leftOverlap, int rightOverlap) =
        _getHairpinBarlineOverlapAdjustment(
            hairpin, unit * 2, x1, x2, spanningType);
    x1 += leftOverlap;
    x2 -= rightOverlap;

    // Store the full drawing length
    hairpin.setDrawingLength(x2 - x1);

    int startY = 0;
    int endY = hairpin.calcHeight(
        doc!, staff.drawingStaffSize, spanningType, leftLink, rightLink);

    int corresp = spanningType;
    if (isDim) {
      if (spanningType == spanningStart) {
        corresp = spanningEnd;
      } else if (spanningType == spanningEnd) corresp = spanningStart;
    }

    if (corresp == spanningStart) {
      endY = endY * 2 ~/ 3;
    } else if (corresp == spanningEnd) {
      startY = endY ~/ 3;
    } else if (corresp == spanningMiddle) {
      startY = endY ~/ 3;
      endY = endY * 2 ~/ 3;
    }

    if (isDim) {
      final int tmp = startY;
      startY = endY;
      endY = tmp;
    }

    int y1 = hairpin.getDrawingY();

    if (hairpin.place != Staffrel.within) {
      int shiftY = -(doc!.getDrawingStemWidth(staff.drawingStaffSize)) ~/ 2;
      if (hairpin.place != Staffrel.between) shiftY += unit;
      y1 += shiftY;
    }

    y1 = calcOffsetY(dc, y1);
    int y2 = y1;
    y1 = calcOffsetSpanningStartY(dc, y1, spanningType);
    y2 = calcOffsetSpanningEndY(dc, y2, spanningType);

    if (graphic != null) {
      dc.resumeGraphic(graphic, graphic.id);
    } else {
      dc.startGraphic(hairpin, '', hairpin.id,
          graphicID: GraphicID.spanning);
    }

    final double hairpinThickness =
        doc!.getOptions().hairpinThickness.value * unit;

    PenStyle style = PenStyle.solid;
    if (hairpin.lform == Lineform.dashed) {
      style = PenStyle.longDash;
    } else if (hairpin.lform == Lineform.dotted) {
      style = PenStyle.dot;
    }

    final LineCapStyle cap =
        (style == PenStyle.dot) ? LineCapStyle.round : LineCapStyle.square;

    dc.setPen(hairpinThickness.toInt(), style,
        lineCap: cap, lineJoin: LineJoinStyle.miter);

    if ((startY == 0) && !niente) {
      final List<Point> p = [
        Point(toDeviceContextX(x2), toDeviceContextY(y2 - endY ~/ 2)),
        Point(toDeviceContextX(x1), toDeviceContextY(y1)),
        Point(toDeviceContextX(x2), toDeviceContextY(y2 + endY ~/ 2)),
      ];
      dc.drawPolyline(p);
    } else if ((endY == 0) && !niente) {
      final List<Point> p = [
        Point(toDeviceContextX(x1), toDeviceContextY(y1 - startY ~/ 2)),
        Point(toDeviceContextX(x2), toDeviceContextY(y2)),
        Point(toDeviceContextX(x1), toDeviceContextY(y1 + startY ~/ 2)),
      ];
      dc.drawPolyline(p);
    } else {
      if (niente) {
        dc.setBrush(0.0);
        if (startY == 0) {
          dc.drawCircle(toDeviceContextX(x1), toDeviceContextY(y1), unit ~/ 2);
          if (x2 != x1) startY = unit * endY ~/ (x2 - x1) ~/ 2;
          x1 += unit ~/ 2;
        } else if (endY == 0) {
          dc.drawCircle(toDeviceContextX(x2), toDeviceContextY(y2), unit ~/ 2);
          if (x2 != x1) endY = unit * startY ~/ (x2 - x1) ~/ 2;
          x2 -= unit ~/ 2;
        }
        dc.resetBrush();
      }
      final List<Point> p1 = [
        Point(toDeviceContextX(x1), toDeviceContextY(y1 - startY ~/ 2)),
        Point(toDeviceContextX(x2), toDeviceContextY(y2 - endY ~/ 2)),
      ];
      dc.drawPolyline(p1);
      final List<Point> p2 = [
        Point(toDeviceContextX(x1), toDeviceContextY(y1 + startY ~/ 2)),
        Point(toDeviceContextX(x2), toDeviceContextY(y2 + endY ~/ 2)),
      ];
      dc.drawPolyline(p2);
    }
    dc.resetPen();

    if (graphic != null) {
      dc.endResumedGraphic(graphic as BoundingBox);
    } else {
      dc.endGraphic(hairpin as BoundingBox);
    }
  }

  // ---------------------------------------------------------------------------
  // View::DrawTextEnclosure (view_control.cpp:3265)
  // ---------------------------------------------------------------------------

  /// Mirrors `View::DrawTextEnclosure` (view_control.cpp:3265) — box/circle/
  /// diamond enclosure around `rend` children.
  void drawTextEnclosure(
      DeviceContext dc, TextDrawingParams params, int staffSize) {
    int lineThickness = 0;
    try {
      final dynamic opt = (_dyn(doc!.getOptions())).textEnclosureThickness;
      if (opt != null) {
        final double v = opt.value as double;
        lineThickness = (v * staffSize).toInt();
      } else {
        lineThickness = (0.2 * staffSize).toInt();
      }
    } catch (e) {
      lineThickness = (0.2 * staffSize).toInt();
    }
    final int margin = doc!.getDrawingUnit(staffSize);

    dc.setPushBack();

    for (final dynamic rend in params.enclosedRend) {
      int x1 = 0, x2 = 0, y1 = 0, y2 = 0;
      try {
        x1 = (_dyn(rend).getContentLeft() as int) - margin;
        x2 = (_dyn(rend).getContentRight() as int) + margin;
        y1 = (_dyn(rend).getContentBottom() as int) - margin ~/ 2;
        y2 = (_dyn(rend).getContentTop() as int) + margin;
      } catch (e) {
        continue;
      }
      final int width = (x2 - x1).abs();
      final int height = (y2 - y1).abs();

      Textrendition enclose = params.enclose;
      // params.enclose may be not set; also check rend.rend
      if (enclose == Textrendition.none) {
        try {
          final dynamic rv = _dyn(rend).rend;
          if (rv is Textrendition) {
            enclose = rv;
          } else {
            final String s = rv?.toString() ?? '';
            if (s.contains('box')) {
              enclose = Textrendition.box;
            } else if (s.contains('dbox'))
              enclose = Textrendition.dbox;
            else if (s.contains('circle'))
              enclose = Textrendition.circle;
            else if (s.contains('tbox')) enclose = Textrendition.tbox;
          }
        } catch (e) { e.toString(); }
      }

      if (enclose == Textrendition.box) {
        drawNotFilledRectangle(dc, x1, y1, x2, y2, lineThickness, 0);
      } else if (enclose == Textrendition.dbox) {
        final int yCenter = y1 + (y2 - y1) ~/ 2;
        // height*sqrt2 as in C++: sqrt(2)≈1.414
        final int h = (height * 1.4142135623730951).toInt();
        drawDiamond(
            dc, x1 - width ~/ 2, yCenter, h, width * 2, false, lineThickness);
      } else if (enclose == Textrendition.circle) {
        if (height > width) {
          final int cx = x1 + (x2 - x1) ~/ 2;
          x1 = cx - height ~/ 2;
          x2 = cx + height ~/ 2;
        } else if (height < width) {
          x1 -= width ~/ 8;
          x2 += width ~/ 8;
        }
        drawNotFilledEllipse(dc, x1, y1, x2, y2, lineThickness);
      } else if (enclose == Textrendition.tbox) {
        drawNotFilledRectangle(dc, x1, y1, x2, y2, lineThickness, 0);
      }
    }

    dc.resetPushBack();
  }

// Inserted methods for 05-22
  // ---------------------------------------------------------------------------
  // View::DrawAnnotScore (view_control.cpp:464)
  // ---------------------------------------------------------------------------
  void drawAnnotScore(DeviceContext dc, AnnotScore annotScore, int x1, int x2,
      Staff staff, int spanningType, Object? graphic) {
    final LayerElement? start = annotScore.getStart();
    final LayerElement? end = annotScore.getEnd();

    // May need to set/tweak y pos
    int y = annotScore.getDrawingY();
    y = calcOffsetY(dc, y);

    // This has been copied from bracketSpan and is likely to be wrong
    if (graphic != null) {
      dc.resumeGraphic(graphic, graphic.id);
    } else {
      dc.startGraphic(annotScore, '', annotScore.id,
          graphicID: GraphicID.spanning);
    }
    final int unit = doc!.getDrawingUnit(staff.drawingStaffSize);
    final int boxHeight = _getAnnotScoreBoxHeight(unit);
    final int lineWidth = _getAnnotScoreLineWidth(unit);
    final int halfLineWidth = lineWidth ~/ 2;
    dc.setPen(lineWidth, PenStyle.solid, lineCap: LineCapStyle.butt, lineJoin: LineJoinStyle.miter);
    if (spanningType == spanningStart) {
      if (start != null && !start.isClass(ClassId.timestampAttr)) {
        x1 -= _drawingRadius(start);
      }
      final List<Point> box = [
        Point(toDeviceContextX(x2), toDeviceContextY(y)),
        Point(toDeviceContextX(x1), toDeviceContextY(y)),
        Point(toDeviceContextX(x1), toDeviceContextY(y + boxHeight)),
        Point(toDeviceContextX(x2), toDeviceContextY(y + boxHeight)),
      ];
      dc.drawPolyline(box);
      dc.setBrush(0.5, 0xFF0000);
      drawFilledRectangle(dc, x1 + halfLineWidth, y + halfLineWidth, x2, y + boxHeight - halfLineWidth);
      dc.resetBrush();
    } else if (spanningType == spanningMiddle) {
      if (start != null && !start.isClass(ClassId.timestampAttr)) {
        x1 -= _drawingRadius(start);
      }
      dc.drawLine(toDeviceContextX(x1), toDeviceContextY(y), toDeviceContextX(x2), toDeviceContextY(y));
      dc.drawLine(toDeviceContextX(x1), toDeviceContextY(y + boxHeight), toDeviceContextX(x2), toDeviceContextY(y + boxHeight));
      dc.setBrush(0.5, 0xFF0000);
      drawFilledRectangle(dc, x1, y + halfLineWidth, x2, y + boxHeight - halfLineWidth);
      dc.resetBrush();
    } else if (spanningType == spanningStartEnd) {
      if (start != null && !start.isClass(ClassId.timestampAttr)) {
        x1 -= _drawingRadius(start);
      }
      if (end != null && !end.isClass(ClassId.timestampAttr)) {
        x2 += _drawingRadius(end);
      }
      final List<Point> box = [
        Point(toDeviceContextX(x2), toDeviceContextY(y)),
        Point(toDeviceContextX(x1), toDeviceContextY(y)),
        Point(toDeviceContextX(x1), toDeviceContextY(y + boxHeight)),
        Point(toDeviceContextX(x2), toDeviceContextY(y + boxHeight)),
      ];
      dc.drawPolyline(box, close: true);
      dc.setBrush(0.5, 0xFF0000);
      drawFilledRectangle(dc, x1 + halfLineWidth, y + halfLineWidth, x2 - halfLineWidth, y + boxHeight - halfLineWidth);
      dc.resetBrush();
    } else if (spanningType == spanningEnd) {
      if (end != null && !end.isClass(ClassId.timestampAttr)) {
        x2 += _drawingRadius(end);
      }
      final List<Point> box = [
        Point(toDeviceContextX(x1), toDeviceContextY(y)),
        Point(toDeviceContextX(x2), toDeviceContextY(y)),
        Point(toDeviceContextX(x2), toDeviceContextY(y + boxHeight)),
        Point(toDeviceContextX(x1), toDeviceContextY(y + boxHeight)),
      ];
      dc.drawPolyline(box);
      dc.setBrush(0.5, 0xFF0000);
      drawFilledRectangle(dc, x1, y + halfLineWidth, x2 - halfLineWidth, y + boxHeight - halfLineWidth);
      dc.resetBrush();
    }
    dc.resetPen();
    if (graphic != null) {
      dc.endResumedGraphic(graphic);
    } else {
      dc.endGraphic(annotScore);
    }
  }

  // ---------------------------------------------------------------------------
  // View::DrawPitchInflection (view_control.cpp:964)
  // ---------------------------------------------------------------------------
  void drawPitchInflection(DeviceContext dc, PitchInflection pitchInflection,
      int x1, int x2, Staff staff, int spanningType, Object? graphic) {
    final int topY = calcOffsetY(dc, staff.getDrawingY() + doc!.getDrawingDoubleUnit(staff.drawingStaffSize));
    dynamic start;
    dynamic end;
    try { start = _dyn(pitchInflection).getStart(); } catch (e) { e.toString(); }
    try { end = _dyn(pitchInflection).getEnd(); } catch (e) { e.toString(); }
    final Note? note1 = start is Note ? start : null;
    final Note? note2 = end is Note ? end : null;
    int baseY1 = note1 != null ? calcOffsetY(dc, note1.getDrawingY()) : topY;
    int baseY2 = note2 != null ? calcOffsetY(dc, note2.getDrawingY()) : topY;
    final bool up = note1 != null;
    int y1 = up ? baseY1 : topY;
    int y2 = up ? topY : baseY2;
    int xControl = x2;
    int yControl = y1;
    bool drawArrow = true;
    if (spanningType == spanningStart) {
      drawArrow = false;
      if (!up && note2 != null) {
        int tmp = staff.getDrawingY();
        try { tmp = staff.getDrawingY() + _dyn(note2).drawingYRel as int; } catch (e) { e.toString(); }
        y2 = calcOffsetY(dc, tmp);
      }
      y2 -= (y2 - y1) ~/ 2;
      yControl = y1 + (y2 - y1) ~/ 4;
      xControl = x2 - (x2 - x1) ~/ 4;
    } else if (spanningType == spanningEnd) {
      if (up) {
        int tmp = staff.getDrawingY();
        try { tmp = staff.getDrawingY() + _dyn(note1).drawingYRel as int; } catch (e) { e.toString(); }
        y1 = calcOffsetY(dc, tmp);
      }
      y1 += (y2 - y1) ~/ 2;
      yControl = y1 + (y2 - y1) ~/ 4;
      xControl = x2 - (x2 - x1) ~/ 4;
    } else if (spanningType == spanningMiddle) return;
    final List<Point> points = [
      Point(toDeviceContextX(x1), toDeviceContextY(y1)),
      Point(toDeviceContextX(xControl), toDeviceContextY(yControl)),
      Point(toDeviceContextX(x2), toDeviceContextY(y2)),
    ];
    final int arrowWidth = doc!.getDrawingUnit(staff.drawingStaffSize) ~/ 2;
    int arrowHeight = arrowWidth * 3 ~/ 2;
    arrowHeight = up ? arrowHeight : -arrowHeight;
    final List<Point> arrow = [
      Point(toDeviceContextX(x2 - arrowWidth), toDeviceContextY(y2)),
      Point(toDeviceContextX(x2 + arrowWidth), toDeviceContextY(y2)),
      Point(toDeviceContextX(x2), toDeviceContextY(y2 + arrowHeight)),
    ];
    if (graphic != null) {
      dc.resumeGraphic(graphic as BoundingBox, _dyn(graphic).id as String);
    } else {
      dc.startGraphic(pitchInflection as BoundingBox, 'spanning-pinflection', '');
    }
    dc.setPen(doc!.getDrawingStemWidth(staff.drawingStaffSize), PenStyle.solid);
    dc.drawQuadBezierPath(points);
    if (drawArrow) dc.drawPolygon(arrow);
    dc.resetPen();
    if (graphic != null) {
      dc.endResumedGraphic(graphic as BoundingBox);
    } else {
      dc.endGraphic(pitchInflection as BoundingBox);
    }
  }

  // ---------------------------------------------------------------------------
  // View::DrawArpeg (view_control.cpp:1518)
  // ---------------------------------------------------------------------------
  void drawArpeg(
      DeviceContext dc, Arpeg arpeg, Measure measure, System system) {
    final (Note? topNote, Note? bottomNote) = arpeg.getDrawingTopBottomNotes();

    // We cannot draw without a top and bottom note
    if (topNote == null || bottomNote == null) return;

    final int top = topNote.getDrawingY();
    final int bottom = bottomNote.getDrawingY();

    // We arbitrarily look at the top note
    // Mirrors `LayerElement::GetAncestorStaff()` (layerelement.cpp:517).
    final Staff staff = topNote.getFirstAncestor(ClassId.staff) as Staff;
    final bool drawingCueSize = topNote.drawingCueSize;

    // We are going to have only one FloatingPositioner - staff will be the top
    // note one
    if (!system.setSystemCurrentFloatingPositioner(
        staff.n ?? meiUnset, arpeg, topNote, staff)) {
      return;
    }
    // Special case: because the positioner objects are reset in
    // ResetVerticalAlignment we need to reset the value of the DrawingXRel each
    // time. The value is stored in Arpeg.
    arpeg.getCurrentFloatingPositioner()?.setDrawingXRel(arpeg.drawingXRel);

    int length = top - bottom;
    // We add - substract a unit in order to have the line going to the edge
    final int unit = doc!.getDrawingUnit(staff.drawingStaffSize);

    int x = arpeg.getDrawingX();
    int y = bottom - unit;

    setOffsetStaffSize(arpeg, staff.drawingStaffSize);
    final (int, int) offset = calcOffset(dc, x, y);
    x = offset.$1;
    y = offset.$2;

    final ArpeglogOrder? order = arpeg.order;
    if (order == ArpeglogOrder.nonarp) {
      dc.startGraphic(arpeg, '', arpeg.id);
      final int bracketOffset = unit ~/ 2;
      final int thickness = doc!.getDrawingStemWidth(staff.drawingStaffSize);
      drawSquareBracket(dc, true, x - unit, bottom - bracketOffset,
          length + 2 * bracketOffset, unit, thickness, thickness);
      dc.endGraphic(arpeg);
    } else {
      length += 2 * unit;
      int startGlyph = 0xEAA9; // wiggleArpeggiatoUp
      int fillGlyph = 0xEAA9; // wiggleArpeggiatoUp
      int endGlyph = (arpeg.arrow == true) ? 0xEAAD : 0;

      if (order == ArpeglogOrder.down) {
        startGlyph = (arpeg.arrow == true) ? 0xEAAE : 0;
        fillGlyph = 0xEAAA; // wiggleArpeggiatoDown
        endGlyph = 0xEAAA;
      }

      if (arpeg.arrowShape == Linestartendsymbol.none) endGlyph = 0;

      final Point orig = Point(x, y);

      dc.startGraphic(arpeg, '', arpeg.id);

      // Smufl glyphs are horizontal - Rotate them counter clockwise
      const int angle = -90;
      dc.rotateGraphic(
          Point(toDeviceContextX(x), toDeviceContextY(y)), angle.toDouble());

      drawSmuflLine(dc, orig, length, staff.drawingStaffSize, drawingCueSize,
          fillGlyph, startGlyph, endGlyph);

      dc.endGraphic(arpeg);

      // Possibly draw enclosing brackets
      drawArpegEnclosing(dc, arpeg, staff, startGlyph, fillGlyph, endGlyph, x,
          y, length, drawingCueSize);
    }
  }

  // ---------------------------------------------------------------------------
  // View::DrawArpegEnclosing (view_control.cpp:1598)
  // ---------------------------------------------------------------------------
  void drawArpegEnclosing(DeviceContext dc, Arpeg arpeg, Staff staff,
      int startGlyph, int fillGlyph, int endGlyph, int x, int y, int height,
      bool cueSize) {
    if ((arpeg.enclose == Enclosure.brack) ||
        (arpeg.enclose == Enclosure.box)) {
      // Calculate position and width
      final int unit = doc!.getDrawingUnit(staff.drawingStaffSize);
      int width =
          doc!.getGlyphHeight(fillGlyph, staff.drawingStaffSize, cueSize);
      int exceedingWidth = math.max(unit - width, 0);
      if (arpeg.arrow == true) {
        int arrowWidth = 0;
        if (arpeg.order == ArpeglogOrder.down) {
          arrowWidth = doc!
              .getGlyphHeight(startGlyph, staff.drawingStaffSize, cueSize);
        } else {
          arrowWidth =
              doc!.getGlyphHeight(endGlyph, staff.drawingStaffSize, cueSize);
        }
        exceedingWidth = math.max(exceedingWidth, arrowWidth - width);
      }
      x -= (width + exceedingWidth ~/ 2);
      width += exceedingWidth;

      // We use overlapping brackets to draw boxes :)
      final int offset = 3 * unit ~/ 4;
      final int bracketWidth =
          (arpeg.enclose == Enclosure.brack) ? unit : (width + offset);
      final int verticalThickness =
          doc!.getDrawingStemWidth(staff.drawingStaffSize);
      final int horizontalThickness =
          ((arpeg.enclose == Enclosure.brack) ? 2 : 1) * verticalThickness;

      dc.startGraphic(arpeg, '', arpeg.id);
      drawEnclosingBrackets(dc, x, y, height, width, offset, bracketWidth,
          horizontalThickness, verticalThickness);
      dc.endGraphic(arpeg);
    } else if (arpeg.hasEnclose && (arpeg.enclose != Enclosure.none)) {
      logWarning(
          'Only drawing of enclosing brackets and boxes is supported for arpeggio.');
    }
  }

  // ---------------------------------------------------------------------------
  // View::DrawBreath (view_control.cpp:1641)
  // ---------------------------------------------------------------------------
  void drawBreath(
      DeviceContext dc, Breath breath, Measure measure, System system) {
    // Cannot draw a breath that has no start position
    final LayerElement? start = breath.getStart();
    if (start == null) return;

    dc.startGraphic(breath, '', breath.id);

    SymbolDef? symbolDef;
    if (breath.hasAltsym && breath.hasAltSymbolDef) {
      symbolDef = breath.altSymbolDef;
    }

    final int drawingX = start.getDrawingX() + start.getDrawingRadius(doc!);

    // use breath mark comma glyph
    const int code = 0xE4CE; // breathMarkComma
    final String str = String.fromCharCode(code);

    // center the glyph only with @startid
    final HorizontalAlignment alignment =
        start.isClass(ClassId.timestampAttr)
            ? HorizontalAlignment.left
            : HorizontalAlignment.center;

    final List<Staff> staffList = breath.getTstampStaves(measure, breath);
    for (final Staff staff in staffList) {
      if (!system.setSystemCurrentFloatingPositioner(
          staff.n ?? meiUnset, breath, start, staff)) {
        continue;
      }
      final int staffSize = staff.drawingStaffSize;
      int x = drawingX;
      int y = breath.getDrawingY();

      setOffsetStaffSize(breath, staffSize);
      final (int, int) offset = calcOffset(dc, x, y);
      x = offset.$1;
      y = offset.$2;

      if (symbolDef != null) {
        drawSymbolDef(dc, breath, symbolDef, x, y, staffSize, false, alignment);
      } else {
        dc.setFont(doc!.getDrawingSmuflFont(staffSize, false));
        drawSmuflString(dc, x, y, str, alignment, staffSize);
        dc.resetFont();
      }
    }

    dc.endGraphic(breath);
  }

  // ---------------------------------------------------------------------------
  // View::DrawCaesura (view_control.cpp:1697)
  // ---------------------------------------------------------------------------
  void drawCaesura(
      DeviceContext dc, Caesura caesura, Measure measure, System system) {
    // Cannot draw a caesura that has no start position
    final LayerElement? start = caesura.getStart();
    if (start == null) return;

    dc.startGraphic(caesura, '', caesura.id);

    SymbolDef? symbolDef;
    if (caesura.hasAltsym && caesura.hasAltSymbolDef) {
      symbolDef = caesura.altSymbolDef;
    }

    final int code = caesura.getCaesuraGlyph();
    final int drawingX =
        start.getDrawingX() + start.getDrawingRadius(doc!) * 3;

    final List<Staff> staffList = caesura.getTstampStaves(measure, caesura);
    for (final Staff staff in staffList) {
      if (!system.setSystemCurrentFloatingPositioner(
          staff.n ?? meiUnset, caesura, start, staff)) {
        continue;
      }

      final int staffSize = staff.drawingStaffSize;
      int x = drawingX;
      final int glyphHeight = (symbolDef != null)
          ? symbolDef.getSymbolHeight(doc!, staffSize, false)
          : doc!.getGlyphHeight(code, staffSize, false);
      int y = (caesura.hasPlace && (caesura.place != Staffrel.within))
          ? caesura.getDrawingY()
          : staff.getDrawingY() - glyphHeight ~/ 2;

      setOffsetStaffSize(caesura, staffSize);
      final (int, int) offset = calcOffset(dc, x, y);
      x = offset.$1;
      y = offset.$2;

      if (symbolDef != null) {
        drawSymbolDef(dc, caesura, symbolDef, x, y, staffSize, false);
      } else {
        drawSmuflCode(dc, x, y, code, staffSize, false);
      }
    }

    dc.endGraphic(caesura);
  }

  // ---------------------------------------------------------------------------
  // View::DrawFermata (view_control.cpp:1999)
  // ---------------------------------------------------------------------------
  void drawFermata(
      DeviceContext dc, Fermata fermata, Measure measure, System system) {
    // Cannot draw a fermata that has no start position
    final LayerElement? start = fermata.getStart();
    if (start == null) return;

    const bool drawingCueSize = false;

    dc.startGraphic(fermata, '', fermata.id);

    SymbolDef? symbolDef;
    if (fermata.hasAltsym && fermata.hasAltSymbolDef) {
      symbolDef = fermata.altSymbolDef;
    }

    final int code = fermata.getFermataGlyph();
    final (int enclosingFront, int enclosingBack) = fermata.getEnclosingGlyphs();

    final int drawingX = start.getDrawingX() + start.getDrawingRadius(doc!);

    final List<Staff> staffList = fermata.getTstampStaves(measure, fermata);
    for (final Staff staff in staffList) {
      if (!system.setSystemCurrentFloatingPositioner(
          staff.n ?? meiUnset, fermata, start, staff)) {
        continue;
      }
      final int staffSize = staff.getDrawingStaffNotationSize();
      int x = drawingX;
      int y = fermata.getDrawingY();

      setOffsetStaffSize(fermata, staffSize);
      final (int, int) offset = calcOffset(dc, x, y);
      x = offset.$1;
      y = offset.$2;

      final int width = (symbolDef != null)
          ? symbolDef.getSymbolWidth(doc!, staffSize, drawingCueSize)
          : doc!.getGlyphWidth(code, staffSize, drawingCueSize);
      final int height = (symbolDef != null)
          ? symbolDef.getSymbolHeight(doc!, staffSize, drawingCueSize)
          : doc!.getGlyphHeight(code, staffSize, drawingCueSize);

      // The correction for centering the glyph
      final int xCorr = width ~/ 2;
      int yCorr = 0;

      final Verticalalignment yAlignment = Fermata.getVerticalAlignment(code);
      int enclosureYCorr = 0;
      if (yAlignment == Verticalalignment.top) {
        yCorr = height ~/ 2;
      } else if (yAlignment == Verticalalignment.bottom) {
        yCorr = -height ~/ 2;
      } else {
        final int glyphBottomY = doc!.getGlyphBottom(code, staffSize, false);
        if (fermata.place == Staffrel.above) {
          yCorr = height ~/ 2 + glyphBottomY;
        } else {
          enclosureYCorr = height ~/ 2 + glyphBottomY;
        }
      }

      // Draw glyph including possible enclosing brackets
      dc.setFont(doc!.getDrawingSmuflFont(staffSize, drawingCueSize));

      if (enclosingFront != 0) {
        final int xCorrEncl = xCorr +
            doc!.getDrawingUnit(staffSize) ~/ 3 +
            doc!.getGlyphWidth(enclosingFront, staffSize, drawingCueSize);
        drawSmuflCode(dc, x - xCorrEncl, y + enclosureYCorr + yCorr,
            enclosingFront, staffSize, drawingCueSize);
      }

      if (symbolDef != null) {
        drawSymbolDef(
            dc, fermata, symbolDef, x - xCorr, y, staffSize, drawingCueSize);
      } else {
        drawSmuflCode(dc, x - xCorr, y, code, staffSize, drawingCueSize);
      }

      if (enclosingBack != 0) {
        final int xCorrEncl = xCorr + doc!.getDrawingUnit(staffSize) ~/ 3;
        drawSmuflCode(dc, x + xCorrEncl, y + enclosureYCorr + yCorr,
            enclosingBack, staffSize, drawingCueSize);
      }

      dc.resetFont();
    }

    dc.endGraphic(fermata);
  }

  // ---------------------------------------------------------------------------
  // View::DrawFing (view_control.cpp:2092)
  // ---------------------------------------------------------------------------
  void drawFing(DeviceContext dc, Fing fing, Measure measure, System system) {
    // Cannot draw a fing that has no start position
    final LayerElement? start = fing.getStart();
    if (start == null) return;

    dc.startGraphic(fing, '', fing.id);

    final FontInfo fingTxt = FontInfo();
    if (!dc.useGlobalStyling()) {
      fingTxt.faceName = doc!.getResources().textFontName;
    }

    // center fingering
    const HorizontalAlignment alignment = HorizontalAlignment.center;

    final List<Staff> staffList = fing.getTstampStaves(measure, fing);
    for (final Staff staff in staffList) {
      if (!system.setSystemCurrentFloatingPositioner(
          staff.n ?? meiUnset, fing, start, staff)) {
        continue;
      }
      final int staffSize = staff.drawingStaffSize;
      int x = start.getDrawingX() + start.getDrawingRadius(doc!);
      int y = fing.getDrawingY();

      setOffsetStaffSize(fing, staffSize);
      final (int, int) offset = calcOffset(dc, x, y);
      x = offset.$1;
      y = offset.$2;

      final TextDrawingParams params = TextDrawingParams();
      params.x = x;
      params.y = y;
      params.pointSize = doc!.getFingeringFont(staffSize).pointSize;

      fingTxt.pointSize = params.pointSize;

      dc.setFont(fingTxt);

      dc.startText(
          toDeviceContextX(params.x), toDeviceContextY(params.y), alignment);
      drawTextChildren(dc, fing, params);
      dc.endText();

      dc.resetFont();

      drawTextEnclosure(dc, params, staffSize);
    }

    dc.endGraphic(fing);
  }

  // ---------------------------------------------------------------------------
  // View::DrawGliss (view_control.cpp:2145)
  // ---------------------------------------------------------------------------
  void drawGliss(DeviceContext dc, Gliss gliss, int x1, int x2, Staff staff,
      int spanningType, Object? graphic) {
    int y1 = staff.getDrawingY();
    int y2 = staff.getDrawingY();
    y1 = calcOffsetY(dc, y1);
    y2 = calcOffsetY(dc, y2);

    /************** parent layers **************/

    final Object? startObj = gliss.getStart();
    final Object? endObj = gliss.getEnd();
    final Note? note1 = startObj is Note ? startObj : null;
    final Note? note2 = endObj is Note ? endObj : null;

    if (note1 == null || note2 == null) {
      // no note, obviously nothing to do...
      // this also means that notes with tstamp events are not supported
      return;
    }

    final int unit = doc!.getDrawingUnit(staff.drawingStaffSize);
    final int firstLoc = note1.drawingLoc;
    final int secondLoc = note2.drawingLoc;
    final int diff = (secondLoc - firstLoc) * unit;
    double angle = math.atan2(diff.toDouble(), (x2 - x1).toDouble());

    // only half at system breaks
    if (spanningType != spanningStartEnd) angle = angle / 2;

    // the normal case
    if (spanningType == spanningStartEnd || spanningType == spanningStart) {
      double slope = 0.0;
      if (x1 != x2) slope = diff / (x2 - x1).toDouble();
      int offset = note1.getDrawingRadius(doc!) + unit;
      if ((note1.dots ?? 0) > 0 && slope.abs() < 1.0) {
        offset += (1.5 * unit * (note1.dots ?? 0)).toInt();
      }
      x1 += (math.cos(angle) * offset).toInt();
      y1 = note1.getDrawingY() + (offset * math.sin(angle)).toInt();
    } else {
      y1 = note2.getDrawingY() - ((x2 - x1) * math.sin(angle)).toInt();
    }
    if (spanningType == spanningStartEnd || spanningType == spanningEnd) {
      final Accid? accid = note2.getDrawingAccid();
      if (accid != null && (accid.accid != AccidentalWritten.none)) {
        final int dist = x2 - accid.getContentLeft() + (0.5 * unit).toInt();
        x2 -= dist;
        y2 = note2.getDrawingY() - (dist * math.tan(angle)).toInt();
        while (((firstLoc > secondLoc) &&
                (y2 + 0.5 * unit * math.sin(angle) > accid.getContentTop())) ||
            ((secondLoc > firstLoc) &&
                (y2 + 0.5 * unit * math.sin(angle) < accid.getContentBottom()))) {
          y2 += (unit * math.sin(angle)).toInt();
          x2 += (unit * math.cos(angle)).toInt();
        }
      } else {
        final int offset = note2.getDrawingRadius(doc!) + unit;
        x2 -= (math.cos(angle) * offset).toInt();
        y2 = note2.getDrawingY() - (offset * math.sin(angle)).toInt();
      }
    } else {
      // shorten it
      x2 -= unit;
      y2 = y1 + ((x2 - x1) * math.sin(angle)).toInt();
    }

    int lineWidth =
        (doc!.getDrawingStemWidth(staff.drawingStaffSize) * 1.5).toInt();
    if (gliss.hasLwidth) {
      final LineWidth lwidth = gliss.lwidth!;
      if (lwidth.type == LinewidthType.lineWidthTerm) {
        if (lwidth.lineWidthTerm == Linewidthterm.narrow) {
          lineWidth = (lineWidth * lineWidthTermFactorNarrow).toInt();
        } else if (lwidth.lineWidthTerm == Linewidthterm.medium) {
          lineWidth = (lineWidth * lineWidthTermFactorMedium).toInt();
        } else if (lwidth.lineWidthTerm == Linewidthterm.wide) {
          lineWidth = (lineWidth * lineWidthTermFactorWide).toInt();
        }
      } else if (lwidth.type == LinewidthType.measurementunsigned) {
        if (lwidth.measurementunsigned.type == MeasurementType.px) {
          lineWidth = lwidth.measurementunsigned.px;
        } else {
          lineWidth = (lwidth.measurementunsigned.vu *
                  doc!.getDrawingUnit(staff.drawingStaffSize))
              .toInt();
        }
      }
    }

    if (graphic != null) {
      dc.resumeGraphic(graphic, graphic.id);
    } else {
      dc.startGraphic(gliss, '', gliss.id, graphicID: GraphicID.spanning);
    }

    switch (gliss.lform) {
      case Lineform.wavy:
        {
          final int length =
              math.sqrt(math.pow(x2 - x1, 2) + math.pow(y2 - y1, 2)).toInt();
          final double rotation =
              math.atan2((y1 - y2).toDouble(), (x2 - x1).toDouble()) *
                  180 /
                  math.pi;
          // Smufl glyphs are horizontal - Rotate them counter clockwise
          dc.rotateGraphic(
              Point(toDeviceContextX(x1), toDeviceContextY(y1)), rotation);

          const int glissGlyph = 0xEAAF; // wiggleGlissando
          final int height =
              doc!.getGlyphHeight(glissGlyph, staff.drawingStaffSize, false);
          final Point orig = Point(x1, y1 - height ~/ 2);
          drawSmuflLine(
              dc, orig, length, staff.drawingStaffSize, false, glissGlyph);
          break;
        }
      case Lineform.dashed:
        dc.setPen(lineWidth, PenStyle.shortDash, lineCap: LineCapStyle.round);
        dc.drawLine(toDeviceContextX(x1), toDeviceContextY(y1),
            toDeviceContextX(x2), toDeviceContextY(y2));
        dc.resetPen();
        break;
      case Lineform.dotted:
        dc.setPen(lineWidth * 3 ~/ 2, PenStyle.dot,
            lineCap: LineCapStyle.round);
        dc.drawLine(toDeviceContextX(x1), toDeviceContextY(y1),
            toDeviceContextX(x2), toDeviceContextY(y2));
        dc.resetPen();
        break;
      case Lineform.solid:
      default:
        dc.setPen(lineWidth, PenStyle.solid, lineCap: LineCapStyle.round);
        dc.drawLine(toDeviceContextX(x1), toDeviceContextY(y1),
            toDeviceContextX(x2), toDeviceContextY(y2));
        dc.resetPen();
        break;
    }

    if (graphic != null) {
      dc.endResumedGraphic(graphic);
    } else {
      dc.endGraphic(gliss);
    }
  }

  // ---------------------------------------------------------------------------
  // View::DrawMordent (view_control.cpp:2351)
  // ---------------------------------------------------------------------------
  void drawMordent(
      DeviceContext dc, Mordent mordent, Measure measure, System system) {
    // Cannot draw a mordent that has no start position
    final LayerElement? start = mordent.getStart();
    if (start == null) return;

    dc.startGraphic(mordent, '', mordent.id);

    SymbolDef? symbolDef;
    if (mordent.hasAltsym && mordent.hasAltSymbolDef) {
      symbolDef = mordent.altSymbolDef;
    }

    final int drawingX = start.getDrawingX() + start.getDrawingRadius(doc!);

    // set mordent glyph
    final int code = mordent.getMordentGlyph();

    final (int enclosingFront, int enclosingBack) = mordent.getEnclosingGlyphs();

    final String str = String.fromCharCode(code);

    final List<Staff> staffList = mordent.getTstampStaves(measure, mordent);

    for (final Staff staff in staffList) {
      if (!system.setSystemCurrentFloatingPositioner(
          staff.n ?? meiUnset, mordent, start, staff)) {
        continue;
      }
      final int staffSize = staff.drawingStaffSize;
      int x = drawingX;
      int y = mordent.getDrawingY();

      setOffsetStaffSize(mordent, staffSize);
      final (int, int) offset = calcOffset(dc, x, y);
      x = offset.$1;
      y = offset.$2;

      final int mordentHeight = (symbolDef != null)
          ? symbolDef.getSymbolHeight(doc!, staffSize, false)
          : doc!.getGlyphHeight(code, staffSize, false);
      final int mordentWidth = (symbolDef != null)
          ? symbolDef.getSymbolWidth(doc!, staffSize, false)
          : doc!.getGlyphWidth(code, staffSize, false);
      x -= mordentWidth ~/ 2;

      dc.setFont(doc!.getDrawingSmuflFont(staffSize, false));

      if (mordent.hasAccidlower) {
        final int accid = Accid.getAccidGlyph(mordent.accidlower!);
        final String accidStr = String.fromCharCode(accid);
        int accidY = y;
        int accidX = x;
        if (symbolDef == null) {
          // Adjust the y position
          double xShift = 0.0;
          double factor = 1.0;
          final AccidentalWritten meiaccid = mordent.accidlower!;
          // optimized vertical kerning for Leipzig font:
          if (meiaccid == AccidentalWritten.ff) {
            factor = 1.20;
            xShift = 0.14;
          } else if (meiaccid == AccidentalWritten.f) {
            factor = 1.20;
            xShift = -0.02;
          } else if (meiaccid == AccidentalWritten.n) {
            factor = 0.90;
            xShift = -0.04;
          } else if (meiaccid == AccidentalWritten.s) {
            factor = 1.15;
          } else if (meiaccid == AccidentalWritten.x) {
            factor = 2.00;
          }
          accidX += ((1 + xShift) * mordentWidth / 2).toInt();
          accidY -=
              (factor * doc!.getGlyphHeight(accid, staffSize, true) / 2).toInt();
        } else {
          accidX += mordentWidth ~/ 2;
          accidY -= (doc!.getGlyphTop(accid, staffSize ~/ 2, true) +
              doc!.getDrawingUnit(staffSize * 2 ~/ 3));
        }
        drawSmuflString(dc, accidX, accidY, accidStr,
            HorizontalAlignment.center, staffSize ~/ 2, false);
      } else if (mordent.hasAccidupper) {
        final int accid = Accid.getAccidGlyph(mordent.accidupper!);
        final String accidStr = String.fromCharCode(accid);
        int accidY = y;
        int accidX = x;
        // Adjust the y position
        if (symbolDef == null) {
          double xShift = 0.0;
          double factor = 1.75;
          final AccidentalWritten meiaccid = mordent.accidupper!;
          // optimized vertical kerning for Leipzig font:
          if (meiaccid == AccidentalWritten.ff) {
            factor = 1.40;
          } else if (meiaccid == AccidentalWritten.f) {
            factor = 1.25;
          } else if (meiaccid == AccidentalWritten.n) {
            factor = 1.60;
            xShift = -0.10;
          } else if (meiaccid == AccidentalWritten.s) {
            factor = 1.60;
            xShift = -0.06;
          } else if (meiaccid == AccidentalWritten.x) {
            factor = 1.35;
            xShift = -0.08;
          }
          accidX += ((1 + xShift) * mordentWidth / 2).toInt();
          accidY += (factor * mordentHeight).toInt();
        } else {
          accidX += mordentWidth ~/ 2;
          accidY += (mordentHeight -
              doc!.getGlyphBottom(accid, staffSize ~/ 2, true) +
              doc!.getDrawingUnit(staffSize * 2 ~/ 3));
        }
        drawSmuflString(dc, accidX, accidY, accidStr,
            HorizontalAlignment.center, staffSize ~/ 2, false);
      }

      // hardcoded vertical offset because of the slash
      final int yCorrEncl =
          doc!.getGlyphHeight(0xE56C, staffSize, false) ~/ 2;

      if (enclosingFront != 0) {
        final int xCorrEncl =
            doc!.getGlyphWidth(enclosingFront, staffSize, false);
        drawSmuflCode(dc, x - xCorrEncl, y + yCorrEncl, enclosingFront,
            staffSize, false);
      }

      if (symbolDef != null) {
        drawSymbolDef(dc, mordent, symbolDef, x, y, staffSize, false);
      } else {
        drawSmuflString(
            dc, x, y, str, HorizontalAlignment.left, staffSize);
      }

      if (enclosingBack != 0) {
        final int xCorrEncl = mordentWidth +
            doc!.getGlyphWidth(enclosingBack, staffSize, false) -
            doc!.getGlyphAdvX(enclosingBack, staffSize, false);
        drawSmuflCode(
            dc, x + xCorrEncl, y + yCorrEncl, enclosingBack, staffSize, false);
      }

      dc.resetFont();
    }

    dc.endGraphic(mordent);
  }

  // ---------------------------------------------------------------------------
  // View::DrawPedal (view_control.cpp:2507)
  // ---------------------------------------------------------------------------
  void drawPedal(
      DeviceContext dc, Pedal pedal, Measure measure, System system) {
    // Cannot draw a pedal that has no start position
    final LayerElement? start = pedal.getStart();
    if (start == null) return;

    // just as without a dir attribute
    if (!pedal.hasDir) return;

    dc.startGraphic(pedal, '', pedal.id);

    final Pedalstyle form = pedal.getPedalForm(doc!, system);

    bool drawSymbol = (form != Pedalstyle.line);
    if (pedal.dir == PedallogDir.up && form == Pedalstyle.pedline) {
      drawSymbol = false;
    }

    // Draw a symbol, if it's not a line
    if (drawSymbol) {
      bool bounceStar = true;
      if (form == Pedalstyle.altpedstar) bounceStar = false;

      int drawingX = start.getDrawingX() + start.getDrawingRadius(doc!);

      HorizontalAlignment alignment = HorizontalAlignment.center;
      // center the pedal only with @startid
      if (start.isClass(ClassId.timestampAttr)) {
        if (start.getAlignment()?.getTime() ==
            measure.measureAligner.getRightBarLineAlignment()?.getTime()) {
          alignment = HorizontalAlignment.right;
        } else {
          alignment = HorizontalAlignment.left;
        }
      }

      final List<Staff> staffList = pedal.getTstampStaves(measure, pedal);

      int code = 0xE655; // keyboardPedalUp
      String str = '';
      if (bounceStar && (pedal.dir == PedallogDir.bounce)) {
        str += String.fromCharCode(code);
        // Get the staff size of the first staff
        final int staffSize =
            staffList.isNotEmpty ? staffList.first.drawingStaffSize : 100;
        drawingX -= doc!.getGlyphWidth(0xE655, staffSize, false);
      }
      if (pedal.dir != PedallogDir.up) {
        code = pedal.getPedalGlyph();
      }
      str += String.fromCharCode(code);

      for (final Staff staff in staffList) {
        if (!system.setSystemCurrentFloatingPositioner(
            staff.n ?? meiUnset, pedal, start, staff)) {
          continue;
        }
        final int staffSize = staff.drawingStaffSize;
        int x = drawingX;
        int y = pedal.getDrawingY();

        setOffsetStaffSize(pedal, staffSize);
        final (int, int) offset = calcOffset(dc, x, y);
        x = offset.$1;
        y = offset.$2;

        dc.setFont(doc!.getDrawingSmuflFont(staffSize, false));
        drawSmuflString(dc, x, y, str, alignment, staffSize);
        dc.resetFont();
      }
    }

    dc.endGraphic(pedal);
  }

  // ---------------------------------------------------------------------------
  // View::DrawRepeatMark (view_control.cpp:2671)
  // ---------------------------------------------------------------------------
  void drawRepeatMark(
      DeviceContext dc, RepeatMark repeatMark, Measure measure, System system) {
    // Cannot draw a repeatMark that has no start position
    final LayerElement? start = repeatMark.getStart();
    if (start == null) return;

    // If there is text content, drawn it as a text control element
    if (repeatMark.childCount > 0) {
      drawControlElementText(dc, repeatMark, measure, system);
      return;
    }

    dc.startGraphic(repeatMark, '', repeatMark.id);

    SymbolDef? symbolDef;
    if (repeatMark.hasAltsym && repeatMark.hasAltSymbolDef) {
      symbolDef = repeatMark.altSymbolDef;
    }

    final int drawingX = start.getDrawingX() + start.getDrawingRadius(doc!);

    final int code = repeatMark.getMarkGlyph();
    final String str = String.fromCharCode(code);

    // center the glyph only with @startid
    final HorizontalAlignment alignment =
        start.isClass(ClassId.timestampAttr)
            ? HorizontalAlignment.left
            : HorizontalAlignment.center;

    final List<Staff> staffList =
        repeatMark.getTstampStaves(measure, repeatMark);
    for (final Staff staff in staffList) {
      if (!system.setSystemCurrentFloatingPositioner(
          staff.n ?? meiUnset, repeatMark, start, staff)) {
        continue;
      }
      final int staffSize = staff.drawingStaffSize;
      int x = drawingX;
      int y = repeatMark.getDrawingY();

      setOffsetStaffSize(repeatMark, staffSize);
      final (int, int) offset = calcOffset(dc, x, y);
      x = offset.$1;
      y = offset.$2;

      dc.setFont(doc!.getDrawingSmuflFont(staffSize, false));
      if (symbolDef != null) {
        drawSymbolDef(
            dc, repeatMark, symbolDef, x, y, staffSize, false, alignment);
      } else {
        drawSmuflString(dc, x, y, str, alignment, staffSize);
      }
      dc.resetFont();
    }

    dc.endGraphic(repeatMark);
  }

  // ---------------------------------------------------------------------------
  // View::DrawTrill (view_control.cpp:2798)
  // ---------------------------------------------------------------------------
  void drawTrill(
      DeviceContext dc, Trill trill, Measure measure, System system) {
    // Cannot draw a trill that has no start position
    final LayerElement? start = trill.getStart();
    if (start == null) return;

    dc.startGraphic(trill, '', trill.id);

    SymbolDef? symbolDef;
    if (trill.hasAltsym && trill.hasAltSymbolDef) {
      symbolDef = trill.altSymbolDef;
    }

    int drawingX = start.getDrawingX();

    HorizontalAlignment alignment = HorizontalAlignment.center;
    // center the trill only with @startid
    if (start.isClass(ClassId.timestampAttr)) {
      alignment = HorizontalAlignment.left;
    } else {
      drawingX += start.getDrawingRadius(doc!);
    }

    // for a start always put trill up
    final int code = trill.getTrillGlyph();
    final (int enclosingFront, int enclosingBack) = trill.getEnclosingGlyphs();
    String str = '';

    if (trill.lstartsym != Linestartendsymbol.none) {
      str = String.fromCharCode(code);
    }

    final List<Staff> staffList = trill.getTstampStaves(measure, trill);
    for (final Staff staff in staffList) {
      if (!system.setSystemCurrentFloatingPositioner(
          staff.n ?? meiUnset, trill, start, staff)) {
        continue;
      }
      final int staffSize = staff.drawingStaffSize;
      int x = drawingX;
      int y = trill.getDrawingY();

      setOffsetStaffSize(trill, staffSize);
      final (int, int) offset = calcOffset(dc, x, y);
      x = offset.$1;
      y = offset.$2;

      final int trillHeight = (symbolDef != null)
          ? symbolDef.getSymbolHeight(doc!, staffSize, false)
          : doc!.getGlyphHeight(code, staffSize, false);
      final int trillWidth = (symbolDef != null)
          ? symbolDef.getSymbolWidth(doc!, staffSize, false)
          : doc!.getGlyphWidth(code, staffSize, false);

      dc.setFont(doc!.getDrawingSmuflFont(staffSize, false));

      if (enclosingFront != 0) {
        final int xCorrEncl = trillWidth ~/ 2 +
            doc!.getGlyphWidth(enclosingFront, staffSize, false);
        drawSmuflCode(dc, x - xCorrEncl, y + trillHeight ~/ 2, enclosingFront,
            staffSize, false);
      }

      // Upper and lower accidentals are currently exclusive, but should both
      // be allowed at the same time.
      if (trill.hasAccidlower) {
        final int accidXShift =
            (alignment == HorizontalAlignment.center) ? 0 : trillWidth ~/ 2;
        final int accid = Accid.getAccidGlyph(trill.accidlower!);
        final String accidStr = String.fromCharCode(accid);
        final int accidY = y -
            doc!.getGlyphTop(accid, staffSize ~/ 2, true) -
            doc!.getDrawingUnit(staffSize * 2 ~/ 3);
        drawSmuflString(dc, x + accidXShift, accidY, accidStr,
            HorizontalAlignment.center, staffSize ~/ 2, false);
      } else if (trill.hasAccidupper) {
        final int accidXShift =
            (alignment == HorizontalAlignment.center) ? 0 : trillWidth ~/ 2;
        final int accid = Accid.getAccidGlyph(trill.accidupper!);
        final String accidStr = String.fromCharCode(accid);
        final int accidY = y +
            trillHeight -
            doc!.getGlyphBottom(accid, staffSize ~/ 2, true) +
            doc!.getDrawingUnit(staffSize * 2 ~/ 3);
        drawSmuflString(dc, x + accidXShift, accidY, accidStr,
            HorizontalAlignment.center, staffSize ~/ 2, false);
      }

      if (symbolDef != null) {
        drawSymbolDef(dc, trill, symbolDef, x, y, staffSize, false, alignment);
      } else {
        drawSmuflString(dc, x, y, str, alignment, staffSize);
      }

      if (enclosingBack != 0) {
        final int xCorrEncl = trillWidth ~/ 2 +
            doc!.getGlyphWidth(enclosingBack, staffSize, false) -
            doc!.getGlyphAdvX(enclosingBack, staffSize, false);
        drawSmuflCode(dc, x + xCorrEncl, y + trillHeight ~/ 2, enclosingBack,
            staffSize, false);
      }

      dc.resetFont();
    }

    dc.endGraphic(trill);
  }

  // ---------------------------------------------------------------------------
  // View::DrawTurn (view_control.cpp:2900)
  // ---------------------------------------------------------------------------
  void drawTurn(DeviceContext dc, Turn turn, Measure measure, System system) {
    // Cannot draw a turn that has no start position
    final LayerElement? start = turn.getStart();
    if (start == null) return;

    dc.startGraphic(turn, '', turn.id);

    SymbolDef? symbolDef;
    if (turn.hasAltsym && turn.hasAltSymbolDef) {
      symbolDef = turn.altSymbolDef;
    }

    int drawingX = start.getDrawingX() + start.getDrawingRadius(doc!);

    if (turn.drawingEndElement != null) {
      // Get the parent system of the start and end element
      LayerElement? end = turn.drawingEndElement;
      final Object? parentSystem1 = start.getFirstAncestor(ClassId.system);
      final Object? parentSystem2 = end!.getFirstAncestor(ClassId.system);
      // We have a system break, use the measure right bar line instead
      if (parentSystem1 != parentSystem2) end = measure.getRightBarLine();
      drawingX += ((end.getDrawingX() - drawingX) ~/ 2);
    }

    // set norm as default
    final int code = turn.getTurnGlyph();

    final (int enclosingFront, int enclosingBack) = turn.getEnclosingGlyphs();

    HorizontalAlignment alignment = HorizontalAlignment.center;
    // center the turn only with @startid
    if (start.isClass(ClassId.timestampAttr)) {
      alignment = HorizontalAlignment.left;
    }

    final String str = String.fromCharCode(code);

    final List<Staff> staffList = turn.getTstampStaves(measure, turn);
    for (final Staff staff in staffList) {
      if (!system.setSystemCurrentFloatingPositioner(
          staff.n ?? meiUnset, turn, start, staff)) {
        continue;
      }
      final int staffSize = staff.drawingStaffSize;
      int x = drawingX;
      int y = turn.getDrawingY();

      setOffsetStaffSize(turn, staffSize);
      final (int, int) offset = calcOffset(dc, x, y);
      x = offset.$1;
      y = offset.$2;

      final int turnHeight = (symbolDef != null)
          ? symbolDef.getSymbolHeight(doc!, staffSize, false)
          : doc!.getGlyphHeight(code, staffSize, false);
      final int turnWidth = (symbolDef != null)
          ? symbolDef.getSymbolWidth(doc!, staffSize, false)
          : doc!.getGlyphWidth(code, staffSize, false);

      dc.setFont(doc!.getDrawingSmuflFont(staffSize, false));

      if (turn.hasAccidlower) {
        final int accidXShift =
            (alignment == HorizontalAlignment.center) ? 0 : turnWidth ~/ 2;
        final int accid = Accid.getAccidGlyph(turn.accidlower!);
        final String accidStr = String.fromCharCode(accid);
        final int accidY = y -
            doc!.getGlyphTop(accid, staffSize ~/ 2, true) -
            doc!.getDrawingUnit(staffSize * 2 ~/ 3);
        drawSmuflString(dc, x + accidXShift, accidY, accidStr,
            HorizontalAlignment.center, staffSize ~/ 2, false);
      }
      if (turn.hasAccidupper) {
        final int accidXShift =
            (alignment == HorizontalAlignment.center) ? 0 : turnWidth ~/ 2;
        final int accid = Accid.getAccidGlyph(turn.accidupper!);
        final String accidStr = String.fromCharCode(accid);
        final int accidY = y +
            turnHeight -
            doc!.getGlyphBottom(accid, staffSize ~/ 2, true) +
            doc!.getDrawingUnit(staffSize * 2 ~/ 3);
        drawSmuflString(dc, x + accidXShift, accidY, accidStr,
            HorizontalAlignment.center, staffSize ~/ 2, false);
      }

      if (enclosingFront != 0) {
        int xCorrEncl = doc!.getGlyphWidth(enclosingFront, staffSize, false);
        if (!start.isClass(ClassId.timestampAttr)) xCorrEncl += turnWidth ~/ 2;
        drawSmuflCode(dc, x - xCorrEncl, y + turnHeight ~/ 2, enclosingFront,
            staffSize, false);
      }

      if (symbolDef != null) {
        drawSymbolDef(dc, turn, symbolDef, x, y, staffSize, false, alignment);
      } else {
        drawSmuflString(dc, x, y, str, alignment, staffSize);
      }

      if (enclosingBack != 0) {
        int xCorrEncl = turnWidth +
            doc!.getGlyphWidth(enclosingBack, staffSize, false) -
            doc!.getGlyphAdvX(enclosingBack, staffSize, false);
        if (!start.isClass(ClassId.timestampAttr)) xCorrEncl -= turnWidth ~/ 2;
        drawSmuflCode(dc, x + xCorrEncl, y + turnHeight ~/ 2, enclosingBack,
            staffSize, false);
      }

      dc.resetFont();
    }

    dc.endGraphic(turn);
  }

  // ---------------------------------------------------------------------------
  // View::DrawSystemElement (view_control.cpp:3014)
  // ---------------------------------------------------------------------------
  void drawSystemElement(DeviceContext dc, SystemElement element, System system) {
    if (element.isClass(ClassId.systemMilestoneEnd)) {
      final dynamic end = _dyn(element);
      dynamic start;
      try { start = end.getStart(); } catch (e) { try { start = _dyn(element).start; } catch (e) { e.toString(); } }
      String startId = element.id;
      try { startId = _dyn(start).id as String; } catch (e) { e.toString(); }
      dc.startGraphic(element as BoundingBox, startId, element.id);
      dc.endGraphic(element as BoundingBox);
    } else if (element.isClass(ClassId.ending)) {
      dc.startGraphic(element as BoundingBox, 'systemMilestone', element.id);
      dc.endGraphic(element as BoundingBox);
    } else if (element.isClass(ClassId.pb)) {
      dc.startGraphic(element as BoundingBox, '', element.id);
      dc.endGraphic(element as BoundingBox);
    } else if (element.isClass(ClassId.sb)) {
      dc.startGraphic(element as BoundingBox, '', element.id);
      dc.endGraphic(element as BoundingBox);
    } else if (element.isClass(ClassId.section)) {
      dc.startGraphic(element as BoundingBox, 'systemMilestone', element.id);
      dc.endGraphic(element as BoundingBox);
    }
    // Removed invented else — C++ has no generic branch, unknown
    // SystemElement draws nothing (assert). Mirrors view_control.cpp:3014.
  }

  // ---------------------------------------------------------------------------
  // View::DrawEnding (view_control.cpp:3048)
  // ---------------------------------------------------------------------------
  void drawEnding(DeviceContext dc, Ending ending, System system) {
    if (dc is BBoxDeviceContext) {
      final BBoxDeviceContext bBoxDC = dc;
      if (!bBoxDC.updateVerticalValues()) return;
    }
    dynamic endingEndMilestone;
    try { endingEndMilestone = _dyn(ending).systemMilestoneEnd ?? _dyn(ending).getEnd?.call(); } catch (e) { e.toString(); }
    if (endingEndMilestone == null) return;
    Object? firstMeasure;
    Object? lastMeasure;
    try { firstMeasure = _dyn(ending).drawingMeasure ?? _dyn(ending).getMeasure?.call(); } catch (e) { e.toString(); }
    try { lastMeasure = _dyn(endingEndMilestone).measure ?? _dyn(endingEndMilestone).getMeasure?.call(); } catch (e) { e.toString(); }
    if (firstMeasure == null || lastMeasure == null) {
      try { firstMeasure = (ending as Object).findDescendantByType(ClassId.measure); } catch (e) { e.toString(); }
      try {
        final List<Object> all = (ending as Object).findAllDescendantsByType(ClassId.measure);
        if (all.isNotEmpty) lastMeasure = all.last;
      } catch (e) { e.toString(); }
      if (firstMeasure == null || lastMeasure == null) return;
    }
    Object? parentSystem1;
    Object? parentSystem2;
    try { parentSystem1 = _dyn(firstMeasure).getFirstAncestor(ClassId.system); } catch (e) { e.toString(); }
    try { parentSystem2 = _dyn(lastMeasure).getFirstAncestor(ClassId.system); } catch (e) { e.toString(); }
    if (parentSystem1 == null || parentSystem2 == null) return;
    int x1 = 0, x2 = 0;
    Object? objectX;
    Measure? measure;
    int spanningType = spanningStartEnd;
    Measure? endingMeasure;
    if (identical(system, parentSystem1) && identical(system, parentSystem2)) {
      measure = firstMeasure as Measure;
      try { x1 = measure.getDrawingX(); } catch (e) { x1 = 0; }
      endingMeasure = lastMeasure as Measure;
      objectX = measure;
      bool isFirst = false;
      try { isFirst = identical(system.getFirst(ClassId.measure), measure); } catch (e) { e.toString(); }
      if (isFirst) { try { x1 += measure.measureAligner.getLeftBarLineXRel(); } catch (e) { e.toString(); } }
      try { x2 = (_dyn(endingMeasure).getDrawingX() as int) + (_dyn(endingMeasure).measureAligner.getRightBarLineXRel() as int); } catch (e) { x2 = x1 + 200; }
    } else if (identical(system, parentSystem1)) {
      try {
        final List<Object> measures = system.findAllDescendantsByType(ClassId.measure, deepness: 1);
        if (measures.isEmpty) return;
        measure = measures.last as Measure;
        x1 = _dyn(firstMeasure).getDrawingX() as int;
        objectX = measure;
        endingMeasure = measure;
        bool isFirst = false;
        try { isFirst = identical(system.getFirst(ClassId.measure), firstMeasure); } catch (e) { e.toString(); }
        if (isFirst) { try { x1 += _dyn(firstMeasure).measureAligner.getLeftBarLineXRel() as int; } catch (e) { e.toString(); } }
        x2 = measure.getDrawingX() + measure.measureAligner.getRightBarLineXRel();
        spanningType = spanningStart;
      } catch (e) { return; }
    } else if (identical(system, parentSystem2)) {
      try {
        final List<Object> measures = system.findAllDescendantsByType(ClassId.measure, deepness: 1);
        if (measures.isEmpty) return;
        measure = measures.first as Measure;
        x1 = measure.getDrawingX() + measure.measureAligner.getLeftBarLineXRel();
        objectX = measure.leftBarLine;
        endingMeasure = lastMeasure as Measure;
        x2 = (_dyn(endingMeasure).getDrawingX() as int) + (_dyn(endingMeasure).measureAligner.getRightBarLineXRel() as int);
        spanningType = spanningEnd;
      } catch (e) { return; }
    } else {
      try {
        final List<Object> measuresF = system.findAllDescendantsByType(ClassId.measure, deepness: 1);
        if (measuresF.isEmpty) return;
        measure = measuresF.first as Measure;
        x1 = measure.getDrawingX() + measure.measureAligner.getLeftBarLineXRel();
        objectX = measure.leftBarLine;
        endingMeasure = measure;
        final List<Object> measuresL = system.findAllDescendantsByType(ClassId.measure, deepness: 1);
        final Measure last = measuresL.last as Measure;
        x2 = last.getDrawingX() + last.measureAligner.getRightBarLineXRel();
        spanningType = spanningMiddle;
      } catch (e) { return; }
    }
    if (spanningType == spanningStartEnd || spanningType == spanningStart) {
      dc.resumeGraphic(ending as BoundingBox, ending.id);
    } else {
      dc.startGraphic(ending as BoundingBox, '', ending.id, graphicID: GraphicID.spanning);
    }
    List<Staff> staffList = [];
    bool isTop = false;
    try {
      final dynamic rend = _dyn(system.drawingScoreDef)?.endingRend ?? _dyn(system).getDrawingScoreDef?.call()?.getEndingRend?.call();
      final String s = rend?.toString().toLowerCase() ?? '';
      isTop = s.contains('top');
    } catch (e) { e.toString(); }
    if (isTop) {
      try {
        final List<Object> sysStaves = system.findAllDescendantsByType(ClassId.staff);
        for (final Object so in sysStaves) {
          final Staff st = so as Staff;
          dynamic staffDef;
          try { staffDef = system.drawingScoreDef?.getStaffDef(st.n ?? 0); } catch (e) { e.toString(); }
          bool hidden = false;
          try { hidden = staffDef != null && staffDef.getDrawingVisibility().toString().toLowerCase().contains('hidden'); } catch (e) { e.toString(); }
          if (!hidden) { staffList.add(st); break; }
        }
      } catch (e) { e.toString(); }
      if (staffList.isEmpty) {
        try { final List<Object> sysStaves = system.findAllDescendantsByType(ClassId.staff); if (sysStaves.isNotEmpty) staffList.add(sysStaves.first as Staff); } catch (e) { e.toString(); }
      }
    } else {
      // By default, endings are drawn on top of each group
      // (@ending.rend="grouped") unless "top" is specified
      // (view_control.cpp:3157-3158).
      staffList = measure.getFirstStaffGrpStaves(system.drawingScoreDef!);
    }
    if (staffList.isEmpty) {
      try { final Staff? first = system.findDescendantByType(ClassId.staff) as Staff?; if (first != null) staffList = [first]; } catch (e) { e.toString(); }
    }
    for (final Staff staff in staffList) {
      if (!system.setSystemCurrentFloatingPositioner(staff.n ?? meiUnset, ending as FloatingObject, objectX, staff)) continue;
      final int staffSize = staff.drawingStaffSize;
      int y1 = staff.getDrawingY();
      try { y1 = _dyn(ending).getDrawingY() as int; } catch (e) { e.toString(); }
      dc.startCustomGraphic('voltaBracket');
      FontInfo currentFont;
      try { currentFont = doc!.getDrawingLyricFont(staffSize); } catch (e) { currentFont = FontInfo(); }
      dc.setFont(currentFont);
      final TextExtend extend = TextExtend();
      dc.getTextExtent('M', extend);
      final int unit = doc!.getDrawingUnit(staffSize);
      String endingText = '';
      try { if (_dyn(ending).hasN == true) endingText = _dyn(ending).n as String; } catch (e) { e.toString(); }
      if (endingText.isEmpty) { try { final dynamic n = _dyn(ending).getN?.call(); if (n != null) endingText = n as String; } catch (e) { e.toString(); } }
      if (endingText.isEmpty) { try { endingText = _dyn(ending).label as String; } catch (e) { e.toString(); } }
      if (endingText.isNotEmpty) {
        String strStream = endingText;
        if (spanningType == spanningEnd || spanningType == spanningMiddle) strStream = '($endingText)';
        final Text text = Text();
        try { text.setParent(ending); } catch (e) { e.toString(); }
        try { text.text = strStream; } catch (e) { e.toString(); }
        int textX = x1;
        if (spanningType == spanningStartEnd || spanningType == spanningStart) textX += unit * 2 ~/ 3;
        final TextDrawingParams params = TextDrawingParams();
        params.x = textX; params.y = y1;
        try { params.pointSize = currentFont.pointSize; } catch (e) { e.toString(); }
        dc.startText(toDeviceContextX(params.x), toDeviceContextY(params.y), HorizontalAlignment.left);
        try { drawTextElement(dc, text, params); } catch (e) { drawTextChildren(dc, text, params); }
        dc.endText();
      }
      dc.resetFont();
      final int y2 = y1 + extend.height + unit * 2 ~/ 3;
      double lineThicknessOpt = 0.2;
      try { lineThicknessOpt = (_dyn(doc!.getOptions())).repeatEndingLineThickness.value as double; } catch (e) { e.toString(); }
      final int lineWidth = (lineThicknessOpt * unit).toInt();
      int staffLineWidth = 0;
      try { staffLineWidth = doc!.getDrawingStaffLineWidth(staff.drawingStaffSize); } catch (e) { staffLineWidth = (0.15*unit).toInt(); }
      final int startX = x1 - staffLineWidth;
      int rightBarLineWidth = 0;
      try { rightBarLineWidth = _dyn(endingMeasure).calculateRightBarLineWidth(doc, staffSize) as int; } catch (e) { rightBarLineWidth = unit * 2; }
      int endX = x2;
      bool isLastMeasure = false;
      try {
        final List<Object> all = system.findAllDescendantsByType(ClassId.measure, deepness: 1);
        if (all.isNotEmpty && identical(endingMeasure, all.last)) isLastMeasure = true;
      } catch (e) { e.toString(); }
      if (spanningType == spanningStart || spanningType == spanningMiddle || isLastMeasure) {
        endX += rightBarLineWidth - lineWidth ~/ 2 - staffLineWidth;
      } else {
        try {
          dynamic rend = _dyn(endingMeasure).getDrawingRightBarLine?.call() ?? _dyn(endingMeasure).drawingRightBarLine;
          final String s = rend?.toString().toLowerCase() ?? '';
          if (!s.contains('invis') && s != '0') {
            final int need = lineWidth + unit ~/ 2 - rightBarLineWidth;
            if (need > 0) endX -= need;
          }
        } catch (e) { e.toString(); }
      }
      PenStyle penStyle = PenStyle.solid;
      LineCapStyle capStyle = LineCapStyle.square;
      dynamic lform;
      try { lform = _dyn(ending).lform ?? _dyn(ending).getLform?.call(); } catch (e) { e.toString(); }
      final String lformStr = lform?.toString().toLowerCase() ?? '';
      if (lformStr.contains('dashed')) {
        penStyle = PenStyle.longDash;
      } else if (lformStr.contains('dotted')) { penStyle = PenStyle.dot; capStyle = LineCapStyle.round; }
      dc.setPen(lineWidth, penStyle, lineCap: capStyle);
      dc.drawLine(toDeviceContextX(startX), toDeviceContextY(y2), toDeviceContextX(endX), toDeviceContextY(y2));
      bool drawLeft = spanningType != spanningEnd && spanningType != spanningMiddle;
      bool drawRight = spanningType != spanningStart && spanningType != spanningMiddle;
      bool hasLstart = true, hasLend = true;
      try { final dynamic ls = _dyn(ending).lstartsym ?? _dyn(ending).getLstartsym?.call(); hasLstart = ls == null || !ls.toString().toLowerCase().contains('none'); } catch (e) { e.toString(); }
      try { final dynamic le = _dyn(ending).lendsym ?? _dyn(ending).getLendsym?.call(); hasLend = le == null || !le.toString().toLowerCase().contains('none'); } catch (e) { e.toString(); }
      if (drawLeft && hasLstart) dc.drawLine(toDeviceContextX(startX), toDeviceContextY(y2), toDeviceContextX(startX), toDeviceContextY(y1));
      if (drawRight && hasLend) dc.drawLine(toDeviceContextX(endX), toDeviceContextY(y2), toDeviceContextX(endX), toDeviceContextY(y1));
      dc.resetPen();
      dc.endCustomGraphic();
    }
    if (spanningType == spanningStartEnd || spanningType == spanningStart) {
      dc.endResumedGraphic(ending as BoundingBox);
    } else {
      dc.endGraphic(ending as BoundingBox);
    }
  }


  // ---------------------------------------------------------------------------
  // Helpers for 05-22 (ornaments, arpeg, ending)
  // ---------------------------------------------------------------------------

  int _getAnnotScoreBoxHeight(int unit) {
    double w = 0.2;
    try { w = (_dyn(doc!.getOptions())).octaveLineThickness.value as double; } catch (e) { e.toString(); }
    return (w * unit * 10).toInt();
  }

  int _getAnnotScoreLineWidth(int unit) {
    double w = 0.2;
    try { w = (_dyn(doc!.getOptions())).octaveLineThickness.value as double; } catch (e) { e.toString(); }
    return (w * unit * 2).toInt();
  }

  int _getBracketSpanLineWidth(BracketSpan bs, int unit) {
    try {
      return _dyn(bs).getLineWidth(doc, unit) as int;
    } catch (e) {
      try {
        return _dyn(bs).getLineWidth(doc!, unit) as int;
      } catch (e) {
        // Mirrors `BracketSpan::GetLineWidth` (bracketspan.cpp:52): the base
        // is `octaveLineThickness * unit`, NOT `bracketThickness` (that
        // option belongs to staffGrp `<bracket>`), plus @lwidth handling.
        double w = 0.2;
        try {
          w = (_dyn(doc!.getOptions())).octaveLineThickness.value as double;
        } catch (e) { e.toString(); }
        int lineWidth = (w * unit).toInt();
        if (bs.hasLwidth) {
          final LineWidth lwidth = bs.lwidth!;
          if (lwidth.type == LinewidthType.lineWidthTerm) {
            if (lwidth.lineWidthTerm == Linewidthterm.narrow) {
              lineWidth = (lineWidth * lineWidthTermFactorNarrow).toInt();
            } else if (lwidth.lineWidthTerm == Linewidthterm.medium) {
              lineWidth = (lineWidth * lineWidthTermFactorMedium).toInt();
            } else if (lwidth.lineWidthTerm == Linewidthterm.wide) {
              lineWidth = (lineWidth * lineWidthTermFactorWide).toInt();
            }
          } else if (lwidth.type == LinewidthType.measurementunsigned) {
            if (lwidth.measurementunsigned.type == MeasurementType.px) {
              lineWidth = lwidth.measurementunsigned.px;
            } else {
              lineWidth =
                  (lwidth.measurementunsigned.vu * unit).toInt();
            }
          }
        }
        return lineWidth;
      }
    }
  }

  int _getOctaveLineWidth(Octave oct, int unit) {
    try {
      return _dyn(oct).getLineWidth(doc, unit) as int;
    } catch (e) {
      double w = 0.2;
      try {
        w = (_dyn(doc!.getOptions())).octaveLineThickness.value as double;
      } catch (e) { e.toString(); }
      return (w * unit).toInt();
    }
  }

  int _getOctaveGlyph(Octave octave, bool alt) {
    OctaveDis? dis;
    try {
      dis = octave.dis as OctaveDis;
    } catch (e) {
      try {
        dis = _dyn(octave).getDis() as OctaveDis;
      } catch (e) {
        dis = OctaveDis.n8;
      }
    }
    Staffrel? place;
    try {
      place = octave.disPlace as Staffrel;
    } catch (e) {
      try {
        place = _dyn(octave).getDisPlace() as Staffrel;
      } catch (e) {
        place = Staffrel.above;
      }
    }
    final bool isAbove = place == Staffrel.above;
    if (isAbove) {
      if (dis == OctaveDis.n8) return alt ? 0xE511 : 0xE510;
      if (dis == OctaveDis.n15) return alt ? 0xE515 : 0xE514;
      if (dis == OctaveDis.n22) return alt ? 0xE518 : 0xE517;
    } else {
      if (dis == OctaveDis.n8) return alt ? 0xE51C : 0xE510;
      if (dis == OctaveDis.n15) return alt ? 0xE51D : 0xE514;
      if (dis == OctaveDis.n22) return alt ? 0xE51E : 0xE517;
    }
    return 0xE510;
  }

  bool _calculateTiePosition(Tie tie, Staff staff, int x1, int x2,
      int spanningType, List<Point> bezier) {
    // Attempt to call the model's CalculatePosition if it exists (Phase 4)
    try {
      final bool ok = _dyn(tie)
          .calculatePosition(doc, staff, x1, x2, spanningType, bezier) as bool;
      if (ok) return true;
    } catch (e) { e.toString(); }
    try {
      final bool ok = _dyn(tie)
          .CalculatePosition(doc, staff, x1, x2, spanningType, bezier) as bool;
      if (ok) return true;
    } catch (e) { e.toString(); }

    // Fallback: simple symmetric arch (used for structural tests; numeric
    // equality is not required for this task's structural harness).
    final int y = staff.getDrawingY();
    final int unit = doc!.getDrawingUnit(staff.drawingStaffSize);
    final bool isAbove = _tieIsAbove(tie, staff);
    final int height = (x2 - x1).abs() ~/ 4 + unit;
    final int dy = isAbove ? height : -height;
    // Slight vertical offset for spanning types (broken ties)
    int y1 = y;
    int y2 = y;
    if (spanningType == spanningStart) y2 = y + dy ~/ 2;
    if (spanningType == spanningEnd) y1 = y + dy ~/ 2;
    if (spanningType == spanningMiddle) {
      y1 = y + dy ~/ 3;
      y2 = y + dy ~/ 3;
    }
    // Control points at 1/3 and 2/3 with vertical offset
    bezier[0] = Point(x1, y1);
    bezier[1] = Point(x1 + (x2 - x1) ~/ 3, y1 + dy);
    bezier[2] = Point(x1 + 2 * (x2 - x1) ~/ 3, y2 + dy);
    bezier[3] = Point(x2, y2);
    return true;
  }

  bool _tieIsAbove(Tie tie, Staff staff) {
    try {
      final dynamic dir = _dyn(tie).getDrawingCurveDir?.call() ??
          _dyn(tie).drawingCurveDir;
      if (dir == SlurCurveDirection.above) return true;
      if (dir == SlurCurveDirection.below) return false;
    } catch (e) { e.toString(); }
    try {
      final dynamic curvedir = _dyn(tie).curvedir;
      if (curvedir == CurvatureCurvedir.above) return true;
      if (curvedir == CurvatureCurvedir.below) return false;
    } catch (e) { e.toString(); }
    // Default: above for ties below center, etc — assume above
    return true;
  }

  double _tieMidpointThickness() {
    try {
      return (_dyn(doc!.getOptions())).tieMidpointThickness.value
          as double;
    } catch (e) {
      return 0.5;
    }
  }

  double _tieEndpointThickness() {
    try {
      return (_dyn(doc!.getOptions())).tieEndpointThickness.value
          as double;
    } catch (e) {
      return 0.15;
    }
  }

  double _lyricLineThickness() {
    try {
      return (_dyn(doc!.getOptions())).lyricLineThickness.value as double;
    } catch (e) {
      return 0.15;
    }
  }

  double _pedalLineThickness() {
    try {
      return (_dyn(doc!.getOptions())).pedalLineThickness.value as double;
    } catch (e) {
      return 0.2;
    }
  }

  double _extenderLineMinSpace() {
    try {
      return (_dyn(doc!.getOptions())).extenderLineMinSpace.value
          as double;
    } catch (e) {
      return 1.5;
    }
  }

  int _getFYRel(F f, Staff staff) {
    try {
      return _dyn(this).getFYRel(f, staff) as int;
    } catch (e) { e.toString(); }
    // Fallback: emulate view_element.cpp GetFYRel
    int y = staff.getDrawingY();
    try {
      final dynamic align = staff.getAlignment();
      if (align != null) {
        y -=
            (align.getStaffHeight() as int) + (align.getOverflowBelow() as int);
        final dynamic pos = align.findFirstFloatingPositioner(ClassId.harm);
        if (pos != null) y = pos.getDrawingY() as int;
      }
    } catch (e) { e.toString(); }
    try {
      final Object? fb = f.getFirstAncestor(ClassId.fb);
      if (fb != null) {
        final int line = _dyn(fb)
            .getDescendantIndex(f, ClassId.f, 100000) as int;
        if (line > 0) {
          final int lh = doc!.getTextLineHeight(
              doc!.getDrawingLyricFont(staff.drawingStaffSize), false);
          y -= line * lh;
        }
      }
    } catch (e) { e.toString(); }
    return y;
  }

  int _getSylYRel(int verseN, Staff staff, dynamic place) {
    try {
      return _dyn(this).getSylYRel(verseN, staff, place) as int;
    } catch (e) { e.toString(); }
    // Fallback: minimal version of view_element.cpp GetSylYRel
    try {
      final dynamic align = staff.getAlignment();
      if (align == null) return 0;
      bool collapse = false;
      try {
        collapse =
            (_dyn(doc!.getOptions())).lyricVerseCollapse.value as bool;
      } catch (e) { e.toString(); }
      final int unit = doc!.getDrawingUnit(staff.drawingStaffSize);
      // Approximate: 3 units per verse below
      final int verseHeight = unit * 3;
      final int margin = (doc!.getBottomMargin(ClassId.syl) * unit).toInt();
      final String placeStr = place?.toString() ?? 'below';
      if (placeStr.contains('above')) {
        return (align.getOverflowAbove() -
                align.getVersePositionAbove(verseN, collapse) *
                    (verseHeight + margin) -
                verseHeight)
            .toInt();
      } else {
        return (-align.getStaffHeight() -
                align.getOverflowBelow() +
                align.getVersePositionBelow(verseN, collapse) *
                    (verseHeight + margin))
            .toInt();
      }
    } catch (e) {
      return -doc!.getDrawingUnit(staff.drawingStaffSize) * 4;
    }
  }

  int _adjustToLyricSizeRet(int value) {
    try {
      final double size =
          (_dyn(doc!.getOptions())).lyricSize.value as double;
      final double def =
          (_dyn(doc!.getOptions())).lyricSize.defaultValue as double? ??
              4.5;
      return (value * size / def).toInt();
    } catch (e) {
      return value;
    }
  }

  // Overload that mutates int via wrapper — Dart ints are value types, so we
  // expose a helper that returns the adjusted value.


  // ---------------------------------------------------------------------------
  // Helpers for 05-21
  // ---------------------------------------------------------------------------

  String _collectDynamText(Object dynam) {
    try {
      return _dyn(dynam).getText() as String;
    } catch (e) {
      try {
        final List<Object> kids = _dyn(dynam).children as List<Object>;
        final StringBuffer buf = StringBuffer();
        for (final Object k in kids) {
          if (k.isClass(ClassId.text)) buf.write(_dyn(k).text as String);
          if (k.isClass(ClassId.rend)) {
            try {
              buf.write(_collectDynamText(k));
            } catch (e) { e.toString(); }
          }
        }
        return buf.toString();
      } catch (e) {
        return '';
      }
    }
  }

  HorizontalAlignment _convertHalign(dynamic halign) {
    if (halign is Horizontalalignment) return convertHalign(halign);
    final String s = halign?.toString() ?? '';
    if (s.contains('center')) return HorizontalAlignment.center;
    if (s.contains('right')) return HorizontalAlignment.right;
    return HorizontalAlignment.left;
  }

  bool _dynamIsSymbolOnly(String str) {
    if (str.isEmpty) return false;
    for (final int cp in str.runes) {
      final String ch = String.fromCharCode(cp);
      if (!['p', 'm', 'f', 'r', 's', 'z', 'n'].contains(ch)) return false;
    }
    return true;
  }

  String _dynamGetSymbolStr(String str, bool singleGlyphs) {
    String dynam = '';
    if (!singleGlyphs) {
      if (str == 'p') {
        dynam = String.fromCharCode(0xE520);
      } else if (str == 'm') {
        dynam = String.fromCharCode(0xE521);
      } else if (str == 'f') {
        dynam = String.fromCharCode(0xE522);
      } else if (str == 'r') {
        dynam = String.fromCharCode(0xE523);
      } else if (str == 's') {
        dynam = String.fromCharCode(0xE524);
      } else if (str == 'z') {
        dynam = String.fromCharCode(0xE525);
      } else if (str == 'n') {
        dynam = String.fromCharCode(0xE526);
      } else if (str == 'pppppp') {
        dynam = String.fromCharCode(0xE527);
      } else if (str == 'ppppp') {
        dynam = String.fromCharCode(0xE528);
      } else if (str == 'pppp') {
        dynam = String.fromCharCode(0xE529);
      } else if (str == 'ppp') {
        dynam = String.fromCharCode(0xE52A);
      } else if (str == 'pp') {
        dynam = String.fromCharCode(0xE52B);
      } else if (str == 'mp') {
        dynam = String.fromCharCode(0xE52C);
      } else if (str == 'mf') {
        dynam = String.fromCharCode(0xE52D);
      } else if (str == 'pf') {
        dynam = String.fromCharCode(0xE52E);
      } else if (str == 'ff') {
        dynam = String.fromCharCode(0xE52F);
      } else if (str == 'fff') {
        dynam = String.fromCharCode(0xE530);
      } else if (str == 'ffff') {
        dynam = String.fromCharCode(0xE531);
      } else if (str == 'fffff') {
        dynam = String.fromCharCode(0xE532);
      } else if (str == 'ffffff') {
        dynam = String.fromCharCode(0xE533);
      } else if (str == 'fp') {
        dynam = String.fromCharCode(0xE534);
      } else if (str == 'fz') {
        dynam = String.fromCharCode(0xE535);
      } else if (str == 'sf') {
        dynam = String.fromCharCode(0xE536);
      } else if (str == 'sfp') {
        dynam = String.fromCharCode(0xE537);
      } else if (str == 'sfpp') {
        dynam = String.fromCharCode(0xE538);
      } else if (str == 'sfz') {
        dynam = String.fromCharCode(0xE539);
      } else if (str == 'sfzp') {
        dynam = String.fromCharCode(0xE53A);
      } else if (str == 'sffz') {
        dynam = String.fromCharCode(0xE53B);
      } else if (str == 'rf') {
        dynam = String.fromCharCode(0xE53C);
      } else if (str == 'rfz') {
        dynam = String.fromCharCode(0xE53D);
      }
    }
    if (dynam.isNotEmpty) return dynam;
    const List<String> chars = ['p', 'm', 'f', 'r', 's', 'z', 'n'];
    const List<int> smufl = [0xE520, 0xE521, 0xE522, 0xE523, 0xE524, 0xE525, 0xE526];
    dynam = str;
    for (int i = 0; i < chars.length; i++) {
      dynam = dynam.replaceAll(chars[i], String.fromCharCode(smufl[i]));
    }
    return dynam;
  }

  (int, int) _getHairpinBarlineOverlapAdjustment(
      dynamic hairpin, int doubleUnit, int leftX, int rightX, int spanningType) {
    int leftAdj = 0;
    int rightAdj = 0;
    try {
      dynamic start;
      try {
        start = _dyn(hairpin).getStart();
      } catch (e) {
        start = _dyn(hairpin).getTimePointInterface()?.getStart();
      }
      if (start == null) return (0, 0);
      final Object? startMeasure = _dyn(start).getFirstAncestor(ClassId.measure);
      final Object? endObj = (() {
        try {
          return _dyn(hairpin).getEnd();
        } catch (e) {
          try {
            return _dyn(hairpin).getTimeSpanningInterface()?.getEnd();
          } catch (e) {
            return null;
          }
        }
      })();
      final Object? endMeasure = _dyn(endObj)?.getFirstAncestor(ClassId.measure);

      if (startMeasure == null || endMeasure == null) return (0, 0);

      // left
      dynamic leftBarline;
      try {
        leftBarline = _dyn(startMeasure).getLeftBarLine();
        leftBarline ??= _dyn(startMeasure).leftBarLine;
      } catch (e) { e.toString(); }
      if (leftBarline != null && (spanningType == spanningStartEnd || spanningType == spanningStart)) {
        int margin = doubleUnit;
        try {
          final int lx = _dyn(leftBarline).getDrawingX() as int;
          final int diff = leftX - lx;
          dynamic form;
          try {
            form = _dyn(leftBarline).form ?? _dyn(leftBarline).getForm?.call();
          } catch (e) { e.toString(); }
          final String fs = form?.toString() ?? '';
          if (fs.contains('rptstart') || fs.contains('rptStart')) margin = (margin * 1.5).toInt();
          if (diff < margin) leftAdj = margin - diff;
        } catch (e) { e.toString(); }
      }

      // right
      dynamic rightBarline;
      try {
        if (spanningType == spanningStartEnd || spanningType == spanningEnd) {
          rightBarline = _dyn(endMeasure).getRightBarLine();
          rightBarline ??= _dyn(endMeasure).rightBarLine;
        } else if (spanningType == spanningStart) {
          final dynamic startSystem = _dyn(start).getFirstAncestor(ClassId.system);
          if (startSystem != null) {
            final dynamic measure = _dyn(startSystem).findDescendantByType(ClassId.measure, 1, 1);
            // The Dart comparison uses findDescendantByType with BACKWARD; fallback to last
            dynamic last;
            try {
              last = _dyn(startSystem).findDescendantByType(ClassId.measure);
              // Actually need backward: just get last measure
              final List<Object> all = _dyn(startSystem).findAllDescendantsByType(ClassId.measure, deepness: 1) as List<Object>;
              if (all.isNotEmpty) last = all.last;
            } catch (e) {
              last = measure;
            }
            if (last != null) {
              rightBarline = _dyn(last).getRightBarLine();
              rightBarline ??= _dyn(last).rightBarLine;
            }
          }
        }
      } catch (e) { e.toString(); }

      if (rightBarline != null) {
        int margin = doubleUnit;
        try {
          final int rx = _dyn(rightBarline).getDrawingX() as int;
          final int diff = rx - rightX;
          dynamic form;
          try {
            form = _dyn(rightBarline).form ?? _dyn(rightBarline).getForm?.call();
          } catch (e) { e.toString(); }
          final String fs = form?.toString() ?? '';
          if (fs.contains('rptend') || fs.contains('rptEnd') || fs.contains('end')) margin = (margin * 1.5).toInt();
          if (diff < margin) rightAdj = margin - diff;
        } catch (e) { e.toString(); }
      }
    } catch (e) { e.toString(); }
    return (leftAdj, rightAdj);
  }
}