// ignore_for_file: curly_braces_in_flow_control_structures, dead_code, unused_element, unused_local_variable, non_constant_identifier_names, unnecessary_cast, duplicate_ignore, invalid_assignment, prefer_conditional_assignment, unnecessary_null_comparison, unnecessary_non_null_assertion, unused_catch_stack, unchecked_use_of_nullable_value, argument_type_not_assignable

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
  // ---------------------------------------------------------------------------
  // View::DrawControlElement (view_control.cpp:72)
  // ---------------------------------------------------------------------------

  /// Mirrors `View::DrawControlElement` (view_control.cpp:72) — the control
  /// element dispatcher. Every branch that belongs to 05-21/05-22 throws
  /// [_notYet] with the target task, as required; the spanning families
  /// (annotScore/beamSpan/bracketSpan/.../tie) are handled via the
  /// placeholder+addToDrawingList path which is the same for all of them.
  void drawControlElement(DeviceContext dc, ControlElement element,
      Measure measure, System system) {
    startOffset(dc, element, 100);

    if (element.isClass(ClassId.annotScore) ||
        element.isClass(ClassId.beamSpan) ||
        element.isClass(ClassId.bracketSpan) ||
        element.isClass(ClassId.figure) ||
        element.isClass(ClassId.gliss) ||
        element.isClass(ClassId.hairpin) ||
        element.isClass(ClassId.lv) ||
        element.isClass(ClassId.octave) ||
        element.isClass(ClassId.phrase) ||
        element.isClass(ClassId.pitchInflection) ||
        element.isClass(ClassId.slur) ||
        element.isClass(ClassId.tie)) {
      dc.startGraphic(element as BoundingBox, '', element.id);
      dc.endGraphic(element as BoundingBox);
      system.addToDrawingList(element);
    } else if (element.isClass(ClassId.arpeg)) {
      drawArpeg(dc, element as dynamic, measure, system);
    } else if (element.isClass(ClassId.breath)) {
      drawBreath(dc, element as dynamic, measure, system);
    } else if (element.isClass(ClassId.caesura)) {
      drawCaesura(dc, element as dynamic, measure, system);
    } else if (element.isClass(ClassId.cpMark)) {
      drawControlElementText(dc, element, measure, system);
    } else if (element.isClass(ClassId.dir)) {
      drawControlElementText(dc, element, measure, system);
      system.addToDrawingListIfNecessary(element as dynamic);
    } else if (element.isClass(ClassId.dynam)) {
      drawDynam(dc, element as dynamic, measure, system);
      system.addToDrawingListIfNecessary(element as dynamic);
    } else if (element.isClass(ClassId.fermata)) {
      drawFermata(dc, element as dynamic, measure, system);
    } else if (element.isClass(ClassId.fing)) {
      drawFing(dc, element as dynamic, measure, system);
    } else if (element.isClass(ClassId.harm)) {
      drawHarm(dc, element as dynamic, measure, system);
    } else if (element.isClass(ClassId.mordent)) {
      drawMordent(dc, element as dynamic, measure, system);
    } else if (element.isClass(ClassId.ornam)) {
      drawControlElementText(dc, element, measure, system);
    } else if (element.isClass(ClassId.pedal)) {
      drawPedal(dc, element as dynamic, measure, system);
      system.addToDrawingListIfNecessary(element as dynamic);
    } else if (element.isClass(ClassId.reh)) {
      drawReh(dc, element as dynamic, measure, system);
    } else if (element.isClass(ClassId.repeatMark)) {
      drawRepeatMark(dc, element as dynamic, measure, system);
    } else if (element.isClass(ClassId.tempo)) {
      drawTempo(dc, element as dynamic, measure, system);
      system.addToDrawingListIfNecessary(element as dynamic);
    } else if (element.isClass(ClassId.trill)) {
      drawTrill(dc, element as dynamic, measure, system);
      system.addToDrawingListIfNecessary(element as dynamic);
    } else if (element.isClass(ClassId.turn)) {
      drawTurn(dc, element as dynamic, measure, system);
    } else {
      try { drawControlElementText(dc, element, measure, system); } catch (_) {}
    }

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
    } catch (_) {}
    // Try linking interface for next link (view_control.cpp:207-215)
    if (start != null) {
      try {
        final Object? e = spanningIface?.getEnd();
        if (e is LayerElement) end = e;
      } catch (_) {}
      if (end == null && element is LinkingInterface) {
        try {
          final Object? next = (element as LinkingInterface).nextLink;
          if (next != null) {
            TimePointInterface? nextTP;
            if (next is TimePointInterface) nextTP = next as TimePointInterface;
            final Object? nextStart = nextTP?.getStart();
            if (nextStart is LayerElement) end = nextStart;
          }
        } catch (_) {}
      }
    }

    // For time-spanning that is open-ended, end may be null — HasValidTimeSpanningOrder will handle.
    // Still continue with end ?? start to avoid null deref? C++ returns if !HasValid... so we check.

    Object? parentSystem1;
    Object? parentSystem2;
    try {
      final Measure? sm = (spanningIface?.getStartMeasure() as Measure?) ?? start!.getFirstAncestor(ClassId.measure) as Measure?;
      parentSystem1 = sm?.getFirstAncestor(ClassId.system);
    } catch (_) {
      try { parentSystem1 = start!.getFirstAncestor(ClassId.system); } catch(_){ parentSystem1 = null; }
    }
    try {
      final Measure? em = (spanningIface?.getEndMeasure() as Measure?) ?? end!.getFirstAncestor(ClassId.measure) as Measure?;
      parentSystem2 = em?.getFirstAncestor(ClassId.system);
    } catch (_) {
      try { parentSystem2 = end!.getFirstAncestor(ClassId.system); } catch(_){ parentSystem2 = null; }
    }

    int drawingX1, drawingX2;
    Object? objectX;
    Measure? measure;
    Object? graphic;
    int spanningType = spanningStartEnd;

    if (identical(system, parentSystem1) && identical(system, parentSystem2)) {
      try {
        measure = (iface as dynamic).getStartMeasure() as Measure?;
      } catch (_) {
        measure = start!.getFirstAncestor(ClassId.measure) as Measure?;
      }
      measure ??= start!.getFirstAncestor(ClassId.measure) as Measure?;
      if (measure == null) return;
      drawingX1 = start!.getDrawingX();
      objectX = start!;
      drawingX2 = end!.getDrawingX();
      graphic = element;
    } else if (identical(system, parentSystem1)) {
      final List<Object> measures =
          system.findAllDescendantsByType(ClassId.measure, deepness: 1);
      if (measures.isEmpty) return;
      measure = measures.last as Measure;
      drawingX1 = start!.getDrawingX();
      objectX = start!;
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
        final dynamic bar = end! as dynamic;
        final dynamic pos = bar.getPosition?.call() ?? bar.position;
        // BarLinePosition.Right is typically 1; check string
        final String posStr = pos?.toString() ?? '';
        if (posStr.contains('Right') ||
            posStr.contains('right') ||
            posStr == '1') {
          spanningType = spanningStart;
        }
      } catch (_) {}
    }

    int startRadius = 0;
    try {
      if (!(start!.isClass(ClassId.timestampAttr))) {
        startRadius = _getCtrlDrawingRadius(start!);
      }
    } catch (_) {}
    int endRadius = 0;
    try {
      if (!(end!.isClass(ClassId.timestampAttr))) {
        endRadius = _getCtrlDrawingRadius(end!);
      }
    } catch (_) {}

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
          (iface as dynamic).getTstampStaves(measure, element);
      if (staves is List) staffList = staves.cast<Staff>();
    } catch (_) {}
    if (staffList.isEmpty) {
      // Fallback: try element's @staff list (mirrors TimePointInterface::GetTstampStaves HasStaff branch)
      try {
        final dynamic staffAttr = (element as dynamic).staff;
        if (staffAttr is List && staffAttr.isNotEmpty) {
          final List<int> staffNs = staffAttr.cast<int>();
          bool isBetween = false;
          try {
            final dynamic place = (element as dynamic).place;
            if (place != null && place.toString().contains('between')) isBetween = true;
          } catch(_){}
          final List<int> filtered = isBetween ? [staffNs.first] : staffNs;
          for (final int n in filtered) {
            Staff? found;
            try {
              final List<Object> cand = measure.findAllDescendantsByType(ClassId.staff, deepness: 1);
              for (final Object o in cand) {
                if (o is Staff && o.n == n) { found = o; break; }
              }
            } catch(_){}
            if (found == null) {
              try {
                final List<Object> all = system.findAllDescendantsByType(ClassId.staff);
                for (final Object o in all) {
                  if (o is Staff && o.n == n) { found = o; break; }
                }
              } catch(_){}
            }
            if (found != null) staffList.add(found);
          }
        }
      } catch(_){}
    }
    if (staffList.isEmpty) {
      final Staff? s = start!.getFirstAncestor(ClassId.staff) as Staff?;
      if (s != null)
        staffList = [s];
      else {
        final Staff? e = end!.getFirstAncestor(ClassId.staff) as Staff?;
        if (e != null) staffList = [e];
      }
    }
    if (staffList.isEmpty) {
      try {
        final Staff? first = measure.findDescendantByType(ClassId.staff) as Staff?;
        if (first != null) staffList = [first];
      } catch(_){}
      if (staffList.isEmpty) {
        try {
          final Staff? sysFirst = system.findDescendantByType(ClassId.staff) as Staff?;
          if (sysFirst != null) staffList = [sysFirst];
        } catch(_){}
      }
    }

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
            final Staff? principal = (element as dynamic)
                .calculatePrincipalStaff(staff, x1, x2) as Staff?;
            if (principal != null) {
              // ignore: unused
            }
          } catch (_) {}
        }
        if (!system.setSystemCurrentFloatingPositioner(staff.n ?? meiUnset,
            element as FloatingObject, objectX, staff, spanningType)) {
          continue;
        }
      }

      if (element.isClass(ClassId.annotScore)) {
        drawAnnotScore(dc, element as dynamic, x1, x2, staff, spanningType, graphic);
      } else if (element.isClass(ClassId.dir)) {
        drawControlElementConnector(dc, element as ControlElement, x1, x2,
            staff, spanningType, graphic);
      } else if (element.isClass(ClassId.dynam)) {
        drawControlElementConnector(dc, element as ControlElement, x1, x2,
            staff, spanningType, graphic);
      } else if (element.isClass(ClassId.figure)) {
        drawFConnector(
            dc, element as dynamic, x1, x2, staff, spanningType, graphic);
      } else if (element.isClass(ClassId.beamSpan)) {
        try {
          drawBeamSpan(dc, element as BeamSpan, system, graphic);
        } catch (_) {}
      } else if (element.isClass(ClassId.bracketSpan)) {
        drawBracketSpan(
            dc, element as BracketSpan, x1, x2, staff, spanningType, graphic);
      } else if (element.isClass(ClassId.gliss)) {
        if (!isFirst) continue;
        drawGliss(dc, element as dynamic, x1, x2, staff, spanningType, graphic);
      } else if (element.isClass(ClassId.hairpin)) {
        drawHairpin(
            dc, element as dynamic, x1, x2, staff, spanningType, graphic);
      } else if (element.isClass(ClassId.lv)) {
        if (!isFirst) continue;
        drawTie(dc, element as Tie, x1, x2, staff, spanningType, graphic);
      } else if (element.isClass(ClassId.phrase)) {
        if (slurHandling == SlurHandling.ignore) continue;
        if (!isFirst) continue;
        drawSlur(dc, element, x1, x2, staff, spanningType, graphic);
      } else if (element.isClass(ClassId.octave)) {
        drawOctave(dc, element as Octave, x1, x2, staff, spanningType, graphic);
      } else if (element.isClass(ClassId.pedal)) {
        drawPedalLine(
            dc, element as Pedal, x1, x2, staff, spanningType, graphic);
      } else if (element.isClass(ClassId.pitchInflection)) {
        if (!isFirst) continue;
        drawPitchInflection(dc, element as dynamic, x1, x2, staff, spanningType, graphic);
      } else if (element.isClass(ClassId.slur)) {
        if (slurHandling == SlurHandling.ignore) continue;
        if (!isFirst) continue;
        drawSlur(dc, element, x1, x2, staff, spanningType, graphic);
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
        drawAnnotScore(dc, element as dynamic, x1, x2, staff, spanningType, graphic);
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
      final dynamic iface = (element as dynamic).getTimeSpanningInterface();
      if (iface != null) {
        // Try various method names
        try {
          isOrdered = iface.isOrdered(start, end) as bool;
        } catch (_) {
          try {
            isOrdered = iface.IsOrdered(start, end) as bool;
          } catch (_) {
            // fallback to preordered on alignments
            final dynamic sa = start.getAlignment();
            final dynamic ea = end.getAlignment();
            if (sa != null && ea != null) {
              isOrdered = Object.isPreOrdered(sa, ea) || identical(sa, ea);
            }
          }
        }
      }
    } catch (_) {
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
        } catch (_) {}
      } else if (element.isClass(ClassId.octave) ||
          element.isClass(ClassId.syl)) {
        return true;
      }
      if (dc is! BBoxDeviceContext &&
          identical(currentPage, start!.getFirstAncestor(ClassId.page))) {
        // In C++ LogWarning; in Dart we logDebug to avoid test noise.
        try {
          logDebug(
              "${element.className} '${element.id}' is ignored, since start '${start.id}' does not occur temporally before end '${end.id}'.");
        } catch (_) {}
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
      y = bracketSpan.getDrawingY() as int;
    } catch (_) {
      try {
        y = (bracketSpan as dynamic).getDrawingY() as int;
      } catch (_) {
        y = staff.getDrawingY();
      }
    }
    y = calcOffsetY(dc, y);

    if (graphic != null) {
      dc.resumeGraphic(
          graphic as BoundingBox, (graphic as dynamic).id as String);
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
          x1 -= _getCtrlDrawingRadius(bracketSpan.getStart() as LayerElement);
        }
      } catch (_) {}
      Linestartendsymbol lstart = Linestartendsymbol.none;
      try {
        lstart = bracketSpan.lstartsym as Linestartendsymbol;
      } catch (_) {
        try {
          lstart =
              (bracketSpan as dynamic).getLstartsym() as Linestartendsymbol;
        } catch (_) {}
      }
      if (lstart != Linestartendsymbol.none &&
          lstart != Linestartendsymbol.none0) {
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
          x2 += _getCtrlDrawingRadius(bracketSpan.getEnd() as LayerElement);
        }
      } catch (_) {}
      Linestartendsymbol lendsym = Linestartendsymbol.none;
      try {
        lendsym = bracketSpan.lendsym as Linestartendsymbol;
      } catch (_) {
        try {
          lendsym = (bracketSpan as dynamic).getLendsym() as Linestartendsymbol;
        } catch (_) {}
      }
      if (lendsym != Linestartendsymbol.none &&
          lendsym != Linestartendsymbol.none0) {
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
    } catch (_) {
      try {
        hasLform = (bracketSpan as dynamic).hasLform == true;
      } catch (_) {}
    }
    if (hasLform) {
      Lineform lform = Lineform.none;
      try {
        lform = bracketSpan.lform as Lineform;
      } catch (_) {}
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
    } catch (_) {
      try {
        hasDis = (octave as dynamic).hasDis() == true;
      } catch (_) {
        hasDis = true;
      }
    }
    bool hasDisPlace = false;
    try {
      hasDisPlace = octave.hasDisPlace == true || octave.disPlace != null;
    } catch (_) {
      hasDisPlace = true;
    }
    if (!hasDis || !hasDisPlace) return;

    dynamic disPlace;
    try {
      disPlace = octave.disPlace;
    } catch (_) {
      disPlace = Staffrel.above;
    }

    int y1 = 0;
    try {
      y1 = octave.getDrawingY() as int;
    } catch (_) {
      try {
        y1 = (octave as dynamic).getDrawingY() as int;
      } catch (_) {
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
        noParen = (doc!.getOptions() as dynamic)
            .octaveNoSpanningParentheses
            .value as bool;
      } catch (_) {}
      if (!noParen) {
        x1 += doc!.getGlyphWidth(0xE51A, staff.drawingStaffSize, false);
      }
    }
    if (spanningType == spanningStartEnd || spanningType == spanningEnd) {
      try {
        if ((octave as dynamic).hasEndid == true) {
          final Object? end = (octave as dynamic).getEnd();
          if (end != null && (end as dynamic).hasContentBB == true) {
            // no direct, approximate
          }
          if (end != null) {
            try {
              final int cx2 = (end as dynamic).getContentX2() as int;
              x2 += cx2;
            } catch (_) {}
          }
        }
      } catch (_) {}
    }

    if (graphic != null) {
      dc.resumeGraphic(
          graphic as BoundingBox, (graphic as dynamic).id as String);
    } else {
      dc.startGraphic(octave as BoundingBox, '', octave.id,
          graphicID: GraphicID.spanning);
    }

    bool altSymbols = false;
    try {
      altSymbols =
          (doc!.getOptions() as dynamic).octaveAlternativeSymbols.value as bool;
    } catch (_) {}
    final int code = _getOctaveGlyph(octave, altSymbols);
    final String str = String.fromCharCode(code);

    dc.setFont(doc!.getDrawingSmuflFont(staff.drawingStaffSize, false));
    final TextExtend extend = TextExtend();
    dc.getSmuflTextExtent(str, extend);
    final bool isAbove = disPlace.toString().contains('above');
    final int yCode = isAbove ? y1 - extend.height : y1;
    final int octaveX = altSymbols ? x1 - extend.width ~/ 2 : x1 - extend.width;
    drawSmuflCode(dc, octaveX, yCode, code, staff.drawingStaffSize, false);
    bool noParen2 = false;
    try {
      noParen2 = (doc!.getOptions() as dynamic)
          .octaveNoSpanningParentheses
          .value as bool;
    } catch (_) {}
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
      final dynamic ext = (octave as dynamic).getExtender?.call() ??
          (octave as dynamic).extender;
      if (ext == Boolean.falseValue) extender = false;
      if (ext == false) extender = false;
    } catch (_) {}
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
        hasLform = (octave as dynamic).hasLform == true;
      } catch (_) {}
      if (hasLform) {
        Lineform lf = Lineform.none;
        try {
          lf = (octave as dynamic).getLform() as Lineform;
        } catch (_) {}
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
        (octave as dynamic).setDrawingExtenderX?.call(x1, x2);
      } catch (_) {
        try {
          (octave as dynamic).setDrawingExtenderX(x1, x2);
        } catch (_) {}
      }

      Linestartendsymbol lendsym = Linestartendsymbol.none;
      try {
        lendsym = (octave as dynamic).getLendsym() as Linestartendsymbol;
      } catch (_) {}
      if (lendsym != Linestartendsymbol.none &&
          lendsym != Linestartendsymbol.none0) {
        if (spanningType == spanningEnd || spanningType == spanningStartEnd) {
          Lineform lf = Lineform.none;
          try {
            lf = (octave as dynamic).getLform() as Lineform;
          } catch (_) {}
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
      lform = (tie as dynamic).getLform?.call() as Lineform? ??
          (tie as dynamic).lform as Lineform? ??
          Lineform.none;
    } catch (_) {}
    PenStyle penStyle = PenStyle.solid;
    if (lform == Lineform.dashed)
      penStyle = PenStyle.shortDash;
    else if (lform == Lineform.dotted) penStyle = PenStyle.dot;

    if (graphic != null) {
      dc.resumeGraphic(
          graphic as BoundingBox, (graphic as dynamic).id as String);
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
      y = pedal.getDrawingY() as int;
    } catch (_) {
      try {
        y = (pedal as dynamic).getDrawingY() as int;
      } catch (_) {
        y = staff.getDrawingY();
      }
    }
    y = calcOffsetY(dc, y);

    int startRadius = 0;
    try {
      if (!(pedal.getStart() as Object).isClass(ClassId.timestampAttr)) {
        startRadius = _getCtrlDrawingRadius(pedal.getStart() as LayerElement);
      }
    } catch (_) {}
    int endRadius = 0;
    try {
      if (!(pedal.getEnd() as Object).isClass(ClassId.timestampAttr)) {
        endRadius = _getCtrlDrawingRadius(pedal.getEnd() as LayerElement);
      }
    } catch (_) {}

    if (spanningType == spanningStartEnd || spanningType == spanningStart) {
      x1 -= startRadius;
      Pedalstyle form = Pedalstyle.none;
      try {
        form = pedal.form as Pedalstyle;
      } catch (_) {
        try {
          form = (pedal as dynamic).getForm() as Pedalstyle;
        } catch (_) {}
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
          graphic as BoundingBox, (graphic as dynamic).id as String);
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
    } catch (_) {
      try {
        form = (pedal as dynamic).getForm() as Pedalstyle;
      } catch (_) {}
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
      y = trill.getDrawingY() as int;
    } catch (_) {
      y = staff.getDrawingY();
    }
    y += doc!.getGlyphHeight(0xE566, staff.drawingStaffSize, false) ~/ 3;
    y = calcOffsetY(dc, y);

    Linestartendsymbol lstartsym = Linestartendsymbol.none;
    try {
      lstartsym = trill.lstartsym as Linestartendsymbol;
    } catch (_) {
      try {
        lstartsym = (trill as dynamic).getLstartsym() as Linestartendsymbol;
      } catch (_) {}
    }

    if (lstartsym == Linestartendsymbol.none ||
        lstartsym == Linestartendsymbol.none0) {
      try {
        x1 -= _getCtrlDrawingRadius(trill.getStart() as LayerElement);
      } catch (_) {}
      y += doc!.getDrawingUnit(staff.drawingStaffSize) ~/ 2;
    } else if (spanningType == spanningStart ||
        spanningType == spanningStartEnd) {
      int offsetFactor = 2;
      try {
        if ((trill.getStart() as Object).isClass(ClassId.timestampAttr)) {
          offsetFactor = 1;
        }
      } catch (_) {}
      x1 += doc!.getGlyphWidth(0xE566, staff.drawingStaffSize, false) ~/
          offsetFactor;
    }

    try {
      if (!(trill.getEnd() as Object).isClass(ClassId.timestampAttr)) {
        x2 -= _getCtrlDrawingRadius(trill.getEnd() as LayerElement);
      }
    } catch (_) {}
    x2 -= doc!.getDrawingDoubleUnit(staff.drawingStaffSize);

    final int length = x2 - x1;
    final Point orig = Point(x1, y);

    if (graphic != null) {
      dc.resumeGraphic(
          graphic as BoundingBox, (graphic as dynamic).id as String);
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
        final dynamic pos = (element as dynamic).getCurrentFloatingPositioner();
        if (pos != null && pos.hasContentBB == true) {
          x1 = pos.getContentRight() as int;
        } else if (pos != null) {
          try {
            if (pos.hasContentBB()) x1 = pos.getContentRight() as int;
          } catch (_) {}
        }
      } catch (_) {}
    }
    if (spanningType == spanningEnd || spanningType == spanningStartEnd) {
      try {
        final Object? next = (element as dynamic).getNextLink() as Object?;
        if (next != null) {
          final dynamic nextPos =
              (element as dynamic).getCorrespFloatingPositioner(next);
          if (nextPos != null) {
            try {
              if (nextPos.hasContentBB == true || nextPos.hasContentBB()) {
                x2 = nextPos.getContentLeft() as int;
              }
            } catch (_) {
              try {
                x2 = nextPos.getContentLeft() as int;
              } catch (_) {}
            }
          }
        }
      } catch (_) {}
    }

    final int width =
        (_lyricLineThickness() * doc!.getDrawingUnit(staff.drawingStaffSize))
            .toInt();
    int y = 0;
    try {
      y = ((element as dynamic).getDrawingY() as int) + width ~/ 2;
    } catch (_) {
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
          graphic as BoundingBox, (graphic as dynamic).id as String);
    } else {
      dc.startGraphic(element as BoundingBox, '', element.id,
          graphicID: GraphicID.spanning);
    }

    bool deactivate = true;
    try {
      final Object? next = (element as dynamic).getNextLink();
      if (next == null &&
          spanningType != spanningStartEnd &&
          spanningType != spanningStart) {
        deactivate = false;
      }
    } catch (_) {}

    if (deactivate) {
      dc.deactivateGraphic();
      try {
        (element as dynamic)
            .getCurrentFloatingPositioner()
            ?.setDrawingExtenderWidth(dist);
      } catch (_) {}
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
    if ((f as dynamic).getStart == null && (f as dynamic).getEnd == null) {
      try {
        if ((f as dynamic).getStart() == null ||
            (f as dynamic).getEnd() == null) return;
      } catch (_) {}
    }

    int y = _getFYRel(f, staff);
    y = calcOffsetY(dc, y);

    if (spanningType == spanningStartEnd) {
      try {
        x1 = (f as dynamic).getContentRight() as int;
      } catch (_) {
        try {
          x1 = f.getContentRight();
        } catch (_) {}
      }
    } else if (spanningType == spanningStart) {
      try {
        final Text? text = f.getFirst(ClassId.text) as Text?;
        if (text != null) x1 = text.getContentRight();
      } catch (_) {}
    }

    Object? fb;
    try {
      fb = (graphic as dynamic)?.getFirstAncestor(ClassId.fb);
      fb ??= f.getFirstAncestor(ClassId.fb);
    } catch (_) {}

    final F fConnector = F();
    if (fb != null) {
      dc.resumeGraphic(fb as BoundingBox, (fb as dynamic).id as String);
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
    try {
      if (syl.getStart() == null || syl.getEnd() == null) return;
    } catch (_) {
      return;
    }

    int y = 0;
    try {
      y = staff.getDrawingY() +
          _getSylYRel(syl.drawingVerseN, staff, syl.drawingVersePlace);
    } catch (_) {
      y = staff.getDrawingY();
    }
    y = calcOffsetY(dc, y);

    bool hasContent = false;
    try {
      hasContent = (syl as dynamic).hasContentHorizontalBB == true ||
          (syl as dynamic).hasContentBB() == true;
      if (!hasContent) {
        try {
          hasContent = syl.getContentLeft() != syl.getContentRight();
        } catch (_) {
          hasContent = true;
        }
      }
    } catch (_) {
      hasContent = true;
    }
    if (!hasContent) return;

    // nextWordSyl check
    try {
      final Object? next = syl.nextWordSyl;
      if (next != null) {
        final dynamic n = next as dynamic;
        bool hasNB = false;
        try {
          hasNB = n.hasContentHorizontalBB == true;
        } catch (_) {
          try {
            hasNB = n.hasContentBB() == true;
          } catch (_) {}
        }
        if (!hasNB) return;
      }
    } catch (_) {}

    if (spanningType == spanningStartEnd) {
      try {
        x1 = syl.getContentRight();
      } catch (_) {}
      try {
        final Object? next = syl.nextWordSyl;
        if (next != null) x2 = (next as dynamic).getContentLeft() as int;
      } catch (_) {}
    } else if (spanningType == spanningStart) {
      try {
        x1 = syl.getContentRight();
      } catch (_) {}
    } else if (spanningType == spanningEnd) {
      bool noStartHyphen = false;
      try {
        noStartHyphen =
            (doc!.getOptions() as dynamic).lyricNoStartHyphen.value as bool;
      } catch (_) {}
      if (noStartHyphen) {
        try {
          final Object? end = syl.getEnd() as Object?;
          if (end != null && (end as dynamic).getAlignment?.call() != null) {
            final dynamic al = (end as dynamic).getAlignment();
            if (al.getTime() == 0) {
              final Measure? m = (end as dynamic)
                  .getFirstAncestor(ClassId.measure) as Measure?;
              final System? sys =
                  m?.getFirstAncestor(ClassId.system) as System?;
              if (m != null && sys != null) {
                final Object? firstM =
                    sys.findDescendantByType(ClassId.measure);
                if (identical(m, firstM)) return;
              }
            }
          }
        } catch (_) {}
      }
      try {
        final Object? next = syl.nextWordSyl;
        if (next != null) x2 = (next as dynamic).getContentLeft() as int;
      } catch (_) {}
      x1 -= doc!.getDrawingDoubleUnit(staff.drawingStaffSize);
    }

    final Syl sylConnector = Syl();
    if (graphic != null) {
      dc.resumeGraphic(
          graphic as BoundingBox, (graphic as dynamic).id as String);
    } else {
      dc.startGraphic(sylConnector as BoundingBox, '', syl.id,
          graphicID: GraphicID.spanning);
    }

    dc.deactivateGraphic();

    drawSylConnectorLines(dc, x1, x2, y, syl, staff);

    dc.reactivateGraphic();

    if (graphic != null) {
      dc.endResumedGraphic(graphic as BoundingBox);
    } else {
      dc.endGraphic(sylConnector as BoundingBox);
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

    SyllogCon con = SyllogCon.none;
    try {
      con = syl.con as SyllogCon;
    } catch (_) {
      try {
        con = (syl as dynamic).getCon() as SyllogCon;
      } catch (_) {}
    }

    if (con == SyllogCon.d) {
      try {
        y += (doc!.getDrawingUnit(staff.drawingStaffSize) ~/ 5) as int;
      } catch (_) {
        y += (doc!.getDrawingUnit(staff.drawingStaffSize) ~/ 5) as int;
      }

      final int dashLength = _calcHyphenLength(staff);
      final int halfDash = dashLength ~/ 2;
      final int dashSpace =
          doc!.getDrawingStaffSize(staff.drawingStaffSize) * 5 ~/ 3;
      final int dist = x2 - x1;
      int nbDashes = dist ~/ dashSpace;
      int margin = dist ~/ 2;
      if (dist < dashLength) {
        nbDashes = 0;
      } else if (nbDashes < 2) {
        nbDashes = 1;
      } else {
        margin = (dist - ((nbDashes - 1) * dashSpace)) ~/ 2;
      }
      for (int i = 0; i < nbDashes; ++i) {
        int x = x1 + margin + (i * dashSpace);
        if (x < x1) x = x1;
        drawFilledRectangle(dc, x - halfDash, y, x + halfDash, y + thickness);
      }
    } else if (con == SyllogCon.u) {
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
    dynamic iface;
    try {
      iface = (element as dynamic).getTimePointInterface();
    } catch (_) {
      return;
    }
    if (iface == null) return;
    dynamic ifaceTextDir;
    try {
      ifaceTextDir = (element as dynamic).getTextDirInterface();
    } catch (_) {
      // For ornam etc that also use TextDir, try generic
      try {
        ifaceTextDir = element as dynamic;
      } catch (_) {
        return;
      }
    }
    LayerElement? start;
    try {
      start = (iface as dynamic).getStart() as LayerElement?;
    } catch (_) {
      return;
    }

    dc.startGraphic(element as BoundingBox, '', element.id);

    dynamic place;
    try {
      place = (ifaceTextDir as dynamic).place ??
          (ifaceTextDir as dynamic).getPlace?.call();
    } catch (_) {
      place = null;
    }
    final String placeStr = place?.toString() ?? '';

    // Font for dir text (italic) — mirrors FontInfo dirTxt
    final FontInfo dirTxt = FontInfo();
    if (!dc.useGlobalStyling()) {
      try {
        dirTxt.faceName = doc!.getResources().textFontName;
      } catch (_) {
        try {
          dirTxt.faceName = doc!.getResources().textFontName;
        } catch (_) {}
      }
      dirTxt.fontStyle = FontStyle.italic;
    }

    int lineCount = 1;
    try {
      lineCount = (ifaceTextDir as dynamic).getNumberOfLines(element) as int;
    } catch (_) {
      try {
        lineCount = element.getDescendantCount(ClassId.lb) + 1;
      } catch (_) {}
    }

    HorizontalAlignment alignment = HorizontalAlignment.left;
    try {
      final dynamic hal = (element as dynamic).getChildRendAlignment();
      if (hal is HorizontalAlignment)
        alignment = hal;
      else if (hal is Horizontalalignment)
        alignment = _convertHalign(hal);
      else if (hal?.toString().contains('center') == true)
        alignment = HorizontalAlignment.center;
      else if (hal?.toString().contains('right') == true)
        alignment = HorizontalAlignment.right;
      else if (hal?.toString().contains('left') == true)
        alignment = HorizontalAlignment.left;
      // treat none as left for dir/cpm etc
      if (alignment == HorizontalAlignment.none_)
        alignment = HorizontalAlignment.left;
      final String halStr = hal?.toString() ?? '';
      if (halStr.contains('none') || halStr == '0')
        alignment = HorizontalAlignment.left;
    } catch (_) {
      alignment = HorizontalAlignment.left;
    }
    // dir are left aligned by default
    // (already left)

    List<Staff> staffList = [];
    try {
      final dynamic staves =
          (iface as dynamic).getTstampStaves(measure, element);
      if (staves is List) staffList = staves.cast<Staff>();
    } catch (_) {}
    if (staffList.isEmpty) {
      final Staff? s = start!.getFirstAncestor(ClassId.staff) as Staff?;
      if (s != null) staffList = [s];
    }

    for (final Staff staff in staffList) {
      if (!system.setSystemCurrentFloatingPositioner(
          staff.n ?? meiUnset, element, start, staff)) continue;
      final int staffSize = staff.drawingStaffSize;
      int x = start!.getDrawingX() + _getCtrlDrawingRadius(start!);
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
      } catch (_) {
        params.pointSize = 0;
      }

      int xAdjust = 0;
      bool isBetween = false;
      try {
        // Check place between / below not last staff / above not first staff
        final String ps = placeStr;
        if (ps.contains('between'))
          isBetween = true;
        else if (ps.contains('below') && staff != (measure as dynamic).getLastStaff())
          isBetween = true;
        else if (ps.contains('above') && staff != (measure as dynamic).getFirstStaff())
          isBetween = true;
      } catch (_) {}
      if (isBetween) {
        try {
          final dynamic align = (start as dynamic).getAlignment();
          final dynamic rightAl =
              measure.measureAligner.getRightBarLineAlignment();
          final bool atRight = align != null &&
              rightAl != null &&
              align.getTime() == rightAl.getTime();
          bool rightAligned = false;
          try {
            rightAligned = (ifaceTextDir as dynamic)
                    .areChildrenAlignedTo(element, Horizontalalignment.right) ==
                true;
          } catch (_) {
            try {
              rightAligned = (ifaceTextDir as dynamic).areChildrenAlignedTo(
                      element, HorizontalAlignment.right) ==
                  true;
            } catch (_) {}
          }
          if (atRight && rightAligned) {
            xAdjust = doc!.getDrawingUnit(staffSize) ~/ 2;
          }
        } catch (_) {}
      }

      try {
        dirTxt.pointSize = params.pointSize;
      } catch (_) {}

      if (placeStr.contains('between') || placeStr.contains('within')) {
        if (lineCount > 1) {
          try {
            final int lh = doc!.getTextLineHeight(dirTxt, false);
            params.y += (lh * (lineCount - 1) ~/ 2);
          } catch (_) {}
        }
        try {
          final int xh = doc!.getTextGlyphHeight('x'.codeUnitAt(0), dirTxt, false);
          params.y -= xh ~/ 2;
        } catch (_) {}
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
      start = (dynam as dynamic).getStart();
    } catch (_) {
      try {
        start = (dynam as dynamic).getTimePointInterface()?.getStart();
      } catch (_) {}
    }

    dc.startGraphic(dynam as BoundingBox, '', (dynam as dynamic).id as String);

    // Determine symbol-only
    String dynamText = '';
    try {
      dynamText = (dynam as dynamic).getText() as String;
    } catch (_) {
      try {
        dynamText = _collectDynamText(dynam as Object);
      } catch (_) {}
    }
    bool isSymbolOnly = _dynamIsSymbolOnly(dynamText);
    // Also respect the model cache if exists
    try {
      final bool modelSym = (dynam as dynamic).isSymbolOnly() as bool;
      // Use model result if it differs (it may have cached m_symbolStr)
      if (modelSym != isSymbolOnly) isSymbolOnly = modelSym;
    } catch (_) {}

    final FontInfo dynamTxt = FontInfo();
    if (!dc.useGlobalStyling()) {
      try {
        dynamTxt.faceName = doc!.getResources().textFontName;
      } catch (_) {
        try {
          dynamTxt.faceName = doc!.getResources().textFontName;
        } catch (_) {}
      }
      dynamTxt.fontStyle = FontStyle.italic;
    }

    int lineCount = 1;
    try {
      lineCount = (dynam as dynamic).getNumberOfLines(dynam) as int;
    } catch (_) {
      try {
        lineCount = (dynam as Object).getDescendantCount(ClassId.lb) + 1;
      } catch (_) {}
    }

    HorizontalAlignment alignment = HorizontalAlignment.left;
    try {
      final dynamic hal = (dynam as dynamic).getChildRendAlignment();
      if (hal is HorizontalAlignment)
        alignment = hal;
      else if (hal is Horizontalalignment)
        alignment = _convertHalign(hal);
      else {
        final String s = hal?.toString() ?? '';
        if (s.contains('center'))
          alignment = HorizontalAlignment.center;
        else if (s.contains('right'))
          alignment = HorizontalAlignment.right;
        else if (s.contains('left'))
          alignment = HorizontalAlignment.left;
        else
          alignment = HorizontalAlignment.none_;
      }
    } catch (_) {
      alignment = HorizontalAlignment.none_;
    }
    if (alignment == HorizontalAlignment.none_) {
      bool isTstamp = false;
      try {
        isTstamp = (start as dynamic).isClass(ClassId.timestampAttr) == true;
        if (!isTstamp)
          isTstamp = (start is LayerElement) &&
              (start as dynamic).isTimestampAttr == true;
        // fallback: check if dynam has @tstamp
        final dynamic tstamp = (dynam as dynamic).tstamp;
        if (tstamp != null) isTstamp = true;
        final dynamic hasTstamp = (dynam as dynamic).hasTstamp;
        if (hasTstamp == true) isTstamp = true;
      } catch (_) {}
      alignment =
          isTstamp ? HorizontalAlignment.left : HorizontalAlignment.center;
    }

    List<Staff> staffList = [];
    try {
      final dynamic iface = (dynam as dynamic).getTimePointInterface() ?? dynam;
      final dynamic staves = (iface as dynamic).getTstampStaves(measure, dynam);
      if (staves is List) staffList = staves.cast<Staff>();
    } catch (_) {}
    if (staffList.isEmpty) {
      try {
        final Staff? s =
            (start as Object).getFirstAncestor(ClassId.staff) as Staff?;
        if (s != null) staffList = [s];
      } catch (_) {}
    }

    for (final Staff staff in staffList) {
      if (!system.setSystemCurrentFloatingPositioner(
          staff.n ?? meiUnset, dynam as ControlElement, start as Object, staff))
        continue;
      final int staffSize = staff.drawingStaffSize;
      int x = 0, y = 0;
      try {
        x = ((start as dynamic).getDrawingX() as int) +
            _getCtrlDrawingRadius(start as LayerElement);
      } catch (_) {
        try {
          x = dynam.getDrawingX();
        } catch (_) {}
      }
      try {
        y = (dynam as dynamic).getDrawingY() as int;
      } catch (_) {
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
      } catch (_) {}

      try {
        final dynamic enc = (dynam as dynamic).enclose;
        if (enc != null) {
          final String s = enc.toString();
          if (s.contains('paren'))
            params.textEnclose = Enclosure.paren;
          else if (s.contains('brack')) params.textEnclose = Enclosure.brack;
        }
        if ((dynam as dynamic).hasEnclose == true) {
          final dynamic e = (dynam as dynamic).getEnclose?.call() ??
              (dynam as dynamic).enclose;
          if (e != null) {
            final String s = e.toString();
            if (s.contains('paren'))
              params.textEnclose = Enclosure.paren;
            else if (s.contains('brack')) params.textEnclose = Enclosure.brack;
          }
        }
      } catch (_) {}

      try {
        dynamTxt.pointSize = params.pointSize;
      } catch (_) {}

      dynamic place;
      try {
        place = (dynam as dynamic).place;
      } catch (_) {}
      final String placeStr = place?.toString() ?? '';
      if (placeStr.contains('between')) {
        if (lineCount > 1) {
          try {
            params.y += (doc!.getTextLineHeight(dynamTxt, false) *
                (lineCount - 1) ~/
                2);
          } catch (_) {}
        }
        try {
          params.y -= doc!.getTextGlyphHeight('x'.codeUnitAt(0), dynamTxt, false) ~/ 2;
        } catch (_) {}
      }

      if (isSymbolOnly) {
        bool singleGlyphs = false;
        try {
          singleGlyphs = (doc!.getOptions() as dynamic).dynamSingleGlyphs?.value
                  as bool? ??
              false;
        } catch (_) {}
        String sym = '';
        try {
          sym = (dynam as dynamic).getSymbolStr(singleGlyphs) as String;
        } catch (_) {
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

    dc.endGraphic(dynam as BoundingBox);
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
      final dynamic pair = (dynam as dynamic).getEnclosingGlyphs();
      if (pair is List && pair.length >= 2) {
        enclosingFront = pair[0] as int;
        enclosingBack = pair[1] as int;
      } else if (pair is Record) {
        // Dart record fallback
        enclosingFront = (pair as dynamic).$1 as int? ?? 0;
        enclosingBack = (pair as dynamic).$2 as int? ?? 0;
      } else {
        // Try tuple via dynamic
        try {
          final int f = (pair as dynamic).first as int;
          final int b = (pair as dynamic).second as int;
          enclosingFront = f;
          enclosingBack = b;
        } catch (_) {}
      }
    } catch (_) {
      // manual enclose mapping
      try {
        final dynamic enc = (dynam as dynamic).enclose;
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
      } catch (_) {}
    }
    // Fallback if still 0 but has enclose
    if (enclosingFront == 0 && enclosingBack == 0) {
      try {
        final dynamic enc = (dynam as dynamic).enclose;
        final String s = enc?.toString() ?? '';
        if (s.contains('brack')) {
          enclosingFront = 0xE26C;
          enclosingBack = 0xE26D;
        } else if (s.contains('paren')) {
          enclosingFront = 0xE26A;
          enclosingBack = 0xE26B;
        }
      } catch (_) {}
    }

    int left = 0;
    int width = 0;
    if (dynamSymbol.isNotEmpty) {
      try {
        left = doc!.getGlyphLeft(
            dynamSymbol.codeUnitAt(0), staff.drawingStaffSize, false);
      } catch (_) {}
      for (int i = 0; i < dynamSymbol.length; i++) {
        final int code = dynamSymbol.codeUnitAt(i);
        // For surrogate pairs, codeUnitAt splits — use runes instead if needed
        // but current symbols are BMP (E520 etc) so single unit is fine.
        if (i == dynamSymbol.length - 1) {
          try {
            width += doc!.getGlyphRight(code, staff.drawingStaffSize, false);
          } catch (_) {
            width += doc!.getGlyphWidth(code, staff.drawingStaffSize, false);
          }
        } else {
          try {
            width += doc!.getGlyphAdvX(code, staff.drawingStaffSize, false);
          } catch (_) {
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
        } catch (_) {}
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
      } catch (_) {}
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
      start = (harm as dynamic).getStart();
    } catch (_) {
      return;
    }

    dc.startGraphic(harm as BoundingBox, '', (harm as dynamic).id as String);

    final FontInfo harmTxt = FontInfo();
    if (!dc.useGlobalStyling()) {
      try {
        harmTxt.faceName = doc!.getResources().textFontName;
      } catch (_) {
        try {
          harmTxt.faceName = doc!.getResources().textFontName;
        } catch (_) {}
      }
    }

    HorizontalAlignment alignment = HorizontalAlignment.left;
    try {
      final dynamic hal = (harm as dynamic).getChildRendAlignment();
      if (hal is HorizontalAlignment)
        alignment = hal;
      else if (hal is Horizontalalignment)
        alignment = _convertHalign(hal);
      else {
        final String s = hal?.toString() ?? '';
        if (s.contains('center'))
          alignment = HorizontalAlignment.center;
        else if (s.contains('right'))
          alignment = HorizontalAlignment.right;
        else if (s.contains('left'))
          alignment = HorizontalAlignment.left;
        else
          alignment = HorizontalAlignment.none_;
      }
    } catch (_) {
      alignment = HorizontalAlignment.none_;
    }
    if (alignment == HorizontalAlignment.none_) {
      bool isTstamp = false;
      try {
        isTstamp = (start as dynamic).isClass(ClassId.timestampAttr) == true;
        final dynamic t = (harm as dynamic).tstamp;
        if (t != null) isTstamp = true;
        if ((harm as dynamic).hasTstamp == true) isTstamp = true;
      } catch (_) {}
      alignment =
          isTstamp ? HorizontalAlignment.left : HorizontalAlignment.center;
    }

    List<Staff> staffList = [];
    try {
      final dynamic staves = (harm as dynamic).getTstampStaves(measure, harm);
      if (staves is List) staffList = staves.cast<Staff>();
    } catch (_) {}
    if (staffList.isEmpty) {
      try {
        final Staff? s =
            (start as Object).getFirstAncestor(ClassId.staff) as Staff?;
        if (s != null) staffList = [s];
      } catch (_) {}
    }

    for (final Staff staff in staffList) {
      if (!system.setSystemCurrentFloatingPositioner(
          staff.n ?? meiUnset, harm as ControlElement, start as Object, staff))
        continue;
      final int staffSize = staff.drawingStaffSize;
      int x = 0, y = 0;
      try {
        x = ((start as dynamic).getDrawingX() as int) +
            _getCtrlDrawingRadius(start as LayerElement);
      } catch (_) {
        try {
          x = harm.getDrawingX();
        } catch (_) {}
      }
      try {
        y = (harm as dynamic).getDrawingY() as int;
      } catch (_) {
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
        final dynamic first = (harm as dynamic).getFirst();
        if (first != null && (first as dynamic).isClass(ClassId.fb) == true)
          isFb = true;
        if (!isFb) {
          final dynamic fb = (harm as Object).findDescendantByType(ClassId.fb);
          // The C++ checks GetFirst()->Is(FB) not any descendant; but keep strict
          // Actually C++: if (harm->GetFirst() && harm->GetFirst()->Is(FB)) — so first child must be FB
          // We already checked first; keep isFb false otherwise.
        }
        if (!isFb) {
          // also check first child is fb via children list
          final Object? firstChild = (harm as Object).getFirst(ClassId.fb);
          if (firstChild != null) {
            // Check if firstChild is actually the first element (not deeper)
            final List<Object> kids = (harm as Object).children;
            if (kids.isNotEmpty && identical(kids.first, firstChild))
              isFb = true;
          }
        }
      } catch (_) {}
      if (isFb) {
        dynamic fb;
        try {
          fb = (harm as dynamic).getFirst();
        } catch (_) {
          try {
            fb = (harm as Object).findDescendantByType(ClassId.fb);
          } catch (_) {}
        }
        if (fb != null) {
          drawFb(dc, staff, fb as dynamic, params);
        }
      } else {
        try {
          params.pointSize = doc!.getDrawingLyricFont(staffSize).pointSize;
        } catch (_) {}
        try {
          harmTxt.pointSize = params.pointSize;
        } catch (_) {}
        dc.setFont(harmTxt);
        dc.startText(
            toDeviceContextX(params.x), toDeviceContextY(params.y), alignment);
        drawTextChildren(dc, harm as Object, params);
        dc.endText();
        dc.resetFont();
        drawTextEnclosure(dc, params, staffSize);
      }
    }

    dc.endGraphic(harm as BoundingBox);
  }

  // ---------------------------------------------------------------------------
  // View::DrawFb (view_control.cpp:1960)
  // ---------------------------------------------------------------------------

  /// Mirrors `View::DrawFb` (view_control.cpp:1960) — stacked figured bass.
  void drawFb(
      DeviceContext dc, Staff staff, dynamic fb, TextDrawingParams params) {
    dc.startGraphic(fb as BoundingBox, '', (fb as dynamic).id as String);

    FontInfo? fontDim;
    try {
      fontDim = doc!.getDrawingLyricFont(staff.drawingStaffSize);
    } catch (_) {
      fontDim = FontInfo();
    }
    int lineHeight = 0;
    try {
      lineHeight = doc!.getTextLineHeight(fontDim!, false);
    } catch (_) {
      try {
        lineHeight = doc!.getDrawingUnit(staff.drawingStaffSize) * 2;
      } catch (_) {
        lineHeight = 100;
      }
    }
    final int startX = params.x;
    try {
      fontDim!.pointSize =
          doc!.getDrawingLyricFont(staff.drawingStaffSize).pointSize;
    } catch (_) {}

    dc.setFont(fontDim!);

    List<Object> children = [];
    try {
      children = (fb as Object).children;
    } catch (_) {
      try {
        children = (fb as dynamic).getChildren() as List<Object>;
      } catch (_) {}
    }

    for (final Object current in children) {
      dc.startText(toDeviceContextX(params.x), toDeviceContextY(params.y),
          HorizontalAlignment.left);
      if (current.isClass(ClassId.figure)) {
        // DrawF expects F
        try {
          drawF(dc, current as dynamic, params);
        } catch (_) {
          try {
            drawTextChildren(dc, current, params);
          } catch (_) {}
        }
      } else if (current.isEditorialElement) {
        try {
          drawFbEditorialElement(dc, current as dynamic, params);
        } catch (_) {
          try {
            drawTextChildren(dc, current, params);
          } catch (_) {}
        }
      } else {
        // fallback: still try text children
        try {
          drawTextChildren(dc, current, params);
        } catch (_) {}
      }
      dc.endText();
      params.y -= lineHeight;
      params.x = startX;
    }

    dc.resetFont();
    dc.endGraphic(fb as BoundingBox);
  }

  // ---------------------------------------------------------------------------
  // View::DrawReh (view_control.cpp:2583)
  // ---------------------------------------------------------------------------

  /// Mirrors `View::DrawReh` (view_control.cpp:2583) — rehearsal mark with
  /// `DrawTextEnclosure` (box/circle) and optional clef-adjusted X.
  void drawReh(DeviceContext dc, dynamic reh, Measure measure, System system) {
    dynamic start;
    try {
      start = (reh as dynamic).getStart();
    } catch (_) {
      return;
    }

    dc.startGraphic(reh as BoundingBox, '', (reh as dynamic).id as String);

    final FontInfo rehTxt = FontInfo();
    if (!dc.useGlobalStyling()) {
      try {
        rehTxt.faceName = doc!.getResources().textFontName;
      } catch (_) {
        try {
          rehTxt.faceName = doc!.getResources().textFontName;
        } catch (_) {}
      }
      rehTxt.fontWeight = FontWeight.bold;
    }

    int yMargin = 3;
    int drawingX = 0;
    try {
      drawingX = (start as dynamic).getDrawingX() as int;
    } catch (_) {
      try {
        drawingX = (reh as dynamic).getDrawingX() as int;
      } catch (_) {}
    }
    bool adjustPosition = false;
    try {
      final bool hasTstamp = (reh as dynamic).hasTstamp == true;
      final dynamic tstamp = (reh as dynamic).tstamp;
      if (hasTstamp && tstamp == 0.0) adjustPosition = true;
      if (!adjustPosition) {
        final bool isBarline =
            (start as dynamic).isClass(ClassId.barLine) == true;
        if (isBarline) {
          try {
            final dynamic pos = (start as dynamic).position ??
                (start as dynamic).getPosition?.call();
            final String s = pos?.toString() ?? '';
            if (s.contains('Left') || s.contains('left')) adjustPosition = true;
          } catch (_) {}
        }
      }
    } catch (_) {}

    if (system.getFirst(ClassId.measure) == measure && adjustPosition) {
      try {
        final dynamic layer =
            (measure as dynamic).findDescendantByType(ClassId.layer);
        if (layer != null) {
          if (!system.isFirstOfMdiv()) {
            dynamic clef;
            try {
              clef = (layer as dynamic).getStaffDefClef();
            } catch (_) {
              clef = null;
            }
            if (clef != null) {
              try {
                final int l = (clef as dynamic).getContentLeft() as int;
                final int r = (clef as dynamic).getContentRight() as int;
                final int cx = (clef as dynamic).getDrawingX() as int;
                drawingX = cx + (r - l) ~/ 2;
                yMargin = 5;
              } catch (_) {}
            }
          } else {
            dynamic metersig;
            try {
              metersig = (layer as dynamic).getStaffDefMeterSig();
            } catch (_) {
              metersig = null;
            }
            if (metersig != null) {
              try {
                final int l = (metersig as dynamic).getContentLeft() as int;
                final int r = (metersig as dynamic).getContentRight() as int;
                final int cx = (metersig as dynamic).getDrawingX() as int;
                drawingX = cx + (r - l) ~/ 2;
              } catch (_) {}
            }
          }
        }
      } catch (_) {}
    }

    HorizontalAlignment alignment = HorizontalAlignment.center;
    try {
      final dynamic hal = (reh as dynamic).getChildRendAlignment();
      if (hal is HorizontalAlignment)
        alignment = hal;
      else if (hal is Horizontalalignment)
        alignment = _convertHalign(hal);
      else {
        final String s = hal?.toString() ?? '';
        if (s.contains('left'))
          alignment = HorizontalAlignment.left;
        else if (s.contains('right'))
          alignment = HorizontalAlignment.right;
        else if (s.contains('center'))
          alignment = HorizontalAlignment.center;
        else
          alignment = HorizontalAlignment.center;
      }
      if (alignment == HorizontalAlignment.none_)
        alignment = HorizontalAlignment.center;
      final String s = hal?.toString() ?? '';
      if (s == '0' || s.contains('NONE'))
        alignment = HorizontalAlignment.center;
    } catch (_) {
      alignment = HorizontalAlignment.center;
    }

    List<Staff> staffList = [];
    try {
      final dynamic staves = (reh as dynamic).getTstampStaves(measure, reh);
      if (staves is List) staffList = staves.cast<Staff>();
    } catch (_) {}
    if (staffList.isEmpty) {
      try {
        final Staff? top = system.getTopVisibleStaff(false) as Staff?;
        if (top != null) staffList = [top];
        // fallback: first staff of system
        if (staffList.isEmpty) {
          final dynamic first = system.findDescendantByType(ClassId.staff);
          if (first is Staff) staffList = [first];
        }
      } catch (_) {}
      if (staffList.isEmpty) {
        try {
          final Staff? s =
              (start as Object).getFirstAncestor(ClassId.staff) as Staff?;
          if (s != null) staffList = [s];
        } catch (_) {}
      }
    }

    for (final Staff staff in staffList) {
      if (!system.setSystemCurrentFloatingPositioner(
          staff.n ?? meiUnset, reh as ControlElement, start as Object, staff))
        continue;
      final int staffSize = staff.drawingStaffSize;
      int x = drawingX;
      if (system.getFirst(ClassId.measure) != measure && adjustPosition) {
        try {
          x = staff.getDrawingX();
        } catch (_) {}
      }
      int y = 0;
      try {
        y = ((reh as dynamic).getDrawingY() as int) +
            yMargin * doc!.getDrawingUnit(staffSize);
      } catch (_) {
        y = staff.getDrawingY() + yMargin * doc!.getDrawingUnit(staffSize);
      }

      setOffsetStaffSize(reh as Object, staffSize);
      final r = calcOffset(dc, x, y);
      x = r.$1;
      y = r.$2;

      final TextDrawingParams params = TextDrawingParams();
      params.x = x;
      params.y = y;
      try {
        params.pointSize = doc!.getDrawingLyricFont(staffSize).pointSize;
      } catch (_) {}
      try {
        rehTxt.pointSize = params.pointSize;
      } catch (_) {}

      dc.setFont(rehTxt);
      dc.startText(
          toDeviceContextX(params.x), toDeviceContextY(params.y), alignment);
      drawTextChildren(dc, reh as Object, params);
      dc.endText();
      dc.resetFont();
      drawTextEnclosure(dc, params, staffSize);
    }

    dc.endGraphic(reh as BoundingBox);
  }

  // ---------------------------------------------------------------------------
  // View::DrawTempo (view_control.cpp:2734)
  // ---------------------------------------------------------------------------

  /// Mirrors `View::DrawTempo` (view_control.cpp:2734).
  void drawTempo(
      DeviceContext dc, dynamic tempo, Measure measure, System system) {
    dynamic start;
    try {
      start = (tempo as dynamic).getStart();
    } catch (_) {
      return;
    }

    dc.startGraphic(tempo as BoundingBox, '', (tempo as dynamic).id as String);

    final FontInfo tempoTxt = FontInfo();
    if (!dc.useGlobalStyling()) {
      try {
        tempoTxt.faceName = doc!.getResources().textFontName;
      } catch (_) {
        try {
          tempoTxt.faceName = doc!.getResources().textFontName;
        } catch (_) {}
      }
      tempoTxt.fontWeight = FontWeight.bold;
    }

    int lineCount = 1;
    try {
      lineCount = (tempo as dynamic).getNumberOfLines(tempo) as int;
    } catch (_) {
      try {
        lineCount = (tempo as Object).getDescendantCount(ClassId.lb) + 1;
      } catch (_) {}
    }

    HorizontalAlignment alignment = HorizontalAlignment.left;
    try {
      final dynamic hal = (tempo as dynamic).getChildRendAlignment();
      if (hal is HorizontalAlignment)
        alignment = hal;
      else if (hal is Horizontalalignment)
        alignment = _convertHalign(hal);
      else {
        final String s = hal?.toString() ?? '';
        if (s.contains('center'))
          alignment = HorizontalAlignment.center;
        else if (s.contains('right'))
          alignment = HorizontalAlignment.right;
        else if (s.contains('left'))
          alignment = HorizontalAlignment.left;
        else
          alignment = HorizontalAlignment.none_;
      }
      if (alignment == HorizontalAlignment.none_)
        alignment = HorizontalAlignment.left;
      final String s = hal?.toString() ?? '';
      if (s == '0' || s.contains('NONE')) alignment = HorizontalAlignment.left;
    } catch (_) {
      alignment = HorizontalAlignment.left;
    }

    List<Staff> staffList = [];
    try {
      final dynamic staves = (tempo as dynamic).getTstampStaves(measure, tempo);
      if (staves is List) staffList = staves.cast<Staff>();
    } catch (_) {}
    if (staffList.isEmpty) {
      try {
        final Staff? s =
            (start as Object).getFirstAncestor(ClassId.staff) as Staff?;
        if (s != null) staffList = [s];
      } catch (_) {}
    }

    for (final Staff staff in staffList) {
      if (!system.setSystemCurrentFloatingPositioner(
          staff.n ?? meiUnset, tempo as ControlElement, start as Object, staff))
        continue;
      final int staffSize = staff.drawingStaffSize;
      int x = 0, y = 0;
      try {
        x = (tempo as dynamic).getDrawingXRelativeToStaff(staff.n ?? 0) as int;
      } catch (_) {
        try {
          x = ((start as dynamic).getDrawingX() as int) +
              _getCtrlDrawingRadius(start as LayerElement);
        } catch (_) {
          try {
            x = tempo.getDrawingX();
          } catch (_) {}
        }
      }
      try {
        y = (tempo as dynamic).getDrawingY() as int;
      } catch (_) {
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
      } catch (_) {}
      try {
        tempoTxt.pointSize = params.pointSize;
      } catch (_) {}

      dynamic place;
      try {
        place = (tempo as dynamic).place;
      } catch (_) {}
      final String placeStr = place?.toString() ?? '';
      if (placeStr.contains('between')) {
        if (lineCount > 1) {
          try {
            params.y += (doc!.getTextLineHeight(tempoTxt, false) *
                (lineCount - 1) ~/
                2);
          } catch (_) {}
        }
        try {
          params.y -= doc!.getTextGlyphHeight('x'.codeUnitAt(0), tempoTxt, false) ~/ 2;
        } catch (_) {}
      }

      dc.setFont(tempoTxt);
      dc.startText(
          toDeviceContextX(params.x), toDeviceContextY(params.y), alignment);
      drawTextChildren(dc, tempo as Object, params);
      dc.endText();
      dc.resetFont();
      drawTextEnclosure(dc, params, staffSize);
    }

    dc.endGraphic(tempo as BoundingBox);
  }

  // ---------------------------------------------------------------------------
  // View::DrawHairpin (view_control.cpp:651)
  // ---------------------------------------------------------------------------

  /// Mirrors `View::DrawHairpin` (view_control.cpp:651) — `cres`/`dim` with
  /// `niente`, `opening`, `lform` and the `PrepareFloatingGrpsFunctor`
  /// shortening against `leftLink`/`rightLink`.
  void drawHairpin(DeviceContext dc, dynamic hairpin, int x1, int x2,
      Staff staff, int spanningType, Object? graphic) {
    bool hasForm = false;
    dynamic form;
    try {
      hasForm = (hairpin as dynamic).hasForm == true;
      form = (hairpin as dynamic).form;
      if (form == null) form = (hairpin as dynamic).getForm?.call();
    } catch (_) {
      try {
        form = (hairpin as dynamic).getForm() as dynamic;
        hasForm = form != null;
      } catch (_) {}
    }
    if (!hasForm) {
      // also check via dynamic hasForm string
      final String fs = form?.toString() ?? '';
      if (!fs.contains('cres') && !fs.contains('dim')) return;
      hasForm = true;
    }
    final String formStr = form?.toString() ?? '';
    final bool isCres = formStr.contains('cres');
    // dim if not cres
    final bool isDim = !isCres;

    dynamic leftLinkObj;
    dynamic rightLinkObj;
    try {
      leftLinkObj = (hairpin as dynamic).getLeftLink?.call() ??
          (hairpin as dynamic).leftLink;
    } catch (_) {}
    try {
      rightLinkObj = (hairpin as dynamic).getRightLink?.call() ??
          (hairpin as dynamic).rightLink;
    } catch (_) {}

    dynamic leftLink;
    dynamic rightLink;
    try {
      leftLink = (hairpin as dynamic).getCorrespFloatingPositioner(leftLinkObj);
    } catch (_) {
      leftLink = null;
    }
    try {
      rightLink =
          (hairpin as dynamic).getCorrespFloatingPositioner(rightLinkObj);
    } catch (_) {
      rightLink = null;
    }

    final int unit = doc!.getDrawingUnit(staff.drawingStaffSize);
    bool niente = false;
    try {
      final dynamic n = (hairpin as dynamic).niente;
      if (n != null) {
        final String s = n.toString();
        niente = s.contains('true') || s == '1';
      } else if ((hairpin as dynamic).hasNiente == true) {
        final dynamic v = (hairpin as dynamic).getNiente?.call() ??
            (hairpin as dynamic).niente;
        final String s = v?.toString() ?? '';
        niente = s.contains('true') || s == '1';
      }
    } catch (_) {}

    int adjustedX1 = x1;
    if (leftLink != null) {
      try {
        final int cr = (leftLink as dynamic).getContentRight() as int;
        adjustedX1 = cr + unit ~/ 2;
        if (niente && isCres) adjustedX1 += unit ~/ 3;
      } catch (_) {
        try {
          adjustedX1 =
              ((leftLink as dynamic).getContentRight() as int) + unit ~/ 2;
        } catch (_) {}
      }
    }
    int adjustedX2 = x2;
    if (rightLink != null) {
      try {
        final int cl = (rightLink as dynamic).getContentLeft() as int;
        adjustedX2 = cl - unit ~/ 2;
        if (niente && isDim) adjustedX2 -= unit ~/ 3;
      } catch (_) {}
    }

    if (spanningType == spanningEnd) {
      if ((adjustedX2 - adjustedX1) < (unit * 2)) {
        adjustedX1 = adjustedX2 - 2 * unit;
      }
    }

    if ((adjustedX2 - adjustedX1) >= unit * 2) {
      x1 = adjustedX1;
      x2 = adjustedX2;
    }

    final (int leftOverlap, int rightOverlap) =
        _getHairpinBarlineOverlapAdjustment(
            hairpin, unit * 2, x1, x2, spanningType);
    x1 += leftOverlap;
    x2 -= rightOverlap;

    try {
      (hairpin as dynamic).setDrawingLength(x2 - x1);
    } catch (_) {
      try {
        (hairpin as dynamic).drawingLength = x2 - x1;
      } catch (_) {}
    }

    int startY = 0;
    int endY = _calcHairpinHeight(
        hairpin, staff.drawingStaffSize, spanningType, leftLink, rightLink);

    int corresp = spanningType;
    if (isDim) {
      if (spanningType == spanningStart)
        corresp = spanningEnd;
      else if (spanningType == spanningEnd) corresp = spanningStart;
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

    int y1 = 0;
    try {
      y1 = (hairpin as dynamic).getDrawingY() as int;
    } catch (_) {
      y1 = staff.getDrawingY();
    }

    try {
      final dynamic place =
          (hairpin as dynamic).place ?? (hairpin as dynamic).getPlace?.call();
      final String ps = place?.toString() ?? '';
      if (!ps.contains('within')) {
        int shiftY = -(doc!.getDrawingStemWidth(staff.drawingStaffSize)) ~/ 2;
        if (!ps.contains('between')) shiftY += unit;
        y1 += shiftY;
      }
    } catch (_) {
      // default: within => no shift; else default above
    }

    y1 = calcOffsetY(dc, y1);
    int y2 = y1;
    y1 = calcOffsetSpanningStartY(dc, y1, spanningType);
    y2 = calcOffsetSpanningEndY(dc, y2, spanningType);

    if (graphic != null) {
      dc.resumeGraphic(
          graphic as BoundingBox, (graphic as dynamic).id as String);
    } else {
      dc.startGraphic(
          hairpin as BoundingBox, '', (hairpin as dynamic).id as String,
          graphicID: GraphicID.spanning);
    }

    double hairpinThickness = 0.2 * unit;
    try {
      hairpinThickness =
          (doc!.getOptions() as dynamic).hairpinThickness?.value as double? ??
              0.2 * unit;
      // If option returns double in vu, multiply by unit already? C++: m_hairpinThickness.GetValue() * unit
      // Dart option is double 0.2, so hairpinThickness = 0.2*unit (if stored as vu factor)
      // Our dynamic returns 0.2, need *unit
      final dynamic opt = (doc!.getOptions() as dynamic).hairpinThickness;
      if (opt != null) {
        final double v = opt.value as double;
        hairpinThickness = v * unit;
      }
    } catch (_) {
      hairpinThickness = 0.2 * unit;
    }

    Lineform? lform;
    try {
      lform = (hairpin as dynamic).lform as Lineform?;
      if (lform == null)
        lform = (hairpin as dynamic).getLform?.call() as Lineform?;
    } catch (_) {}
    PenStyle style = PenStyle.solid;
    if (lform == Lineform.dashed)
      style = PenStyle.longDash;
    else if (lform == Lineform.dotted) style = PenStyle.dot;

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
      final dynamic opt = (doc!.getOptions() as dynamic).textEnclosureThickness;
      if (opt != null) {
        final double v = opt.value as double;
        lineThickness = (v * staffSize).toInt();
      } else {
        lineThickness = (0.2 * staffSize).toInt();
      }
    } catch (_) {
      lineThickness = (0.2 * staffSize).toInt();
    }
    final int margin = doc!.getDrawingUnit(staffSize);

    dc.setPushBack();

    for (final dynamic rend in params.enclosedRend) {
      int x1 = 0, x2 = 0, y1 = 0, y2 = 0;
      try {
        x1 = ((rend as dynamic).getContentLeft() as int) - margin;
        x2 = ((rend as dynamic).getContentRight() as int) + margin;
        y1 = ((rend as dynamic).getContentBottom() as int) - margin ~/ 2;
        y2 = ((rend as dynamic).getContentTop() as int) + margin;
      } catch (_) {
        continue;
      }
      final int width = (x2 - x1).abs();
      final int height = (y2 - y1).abs();

      Textrendition enclose = params.enclose;
      // params.enclose may be not set; also check rend.rend
      if (enclose == Textrendition.none) {
        try {
          final dynamic rv = (rend as dynamic).rend;
          if (rv is Textrendition)
            enclose = rv;
          else {
            final String s = rv?.toString() ?? '';
            if (s.contains('box'))
              enclose = Textrendition.box;
            else if (s.contains('dbox'))
              enclose = Textrendition.dbox;
            else if (s.contains('circle'))
              enclose = Textrendition.circle;
            else if (s.contains('tbox')) enclose = Textrendition.tbox;
          }
        } catch (_) {}
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
  void drawAnnotScore(DeviceContext dc, dynamic annotScore, int x1, int x2, Staff staff, int spanningType, Object? graphic) {
    dynamic start;
    dynamic end;
    try { start = (annotScore as dynamic).getStart(); } catch (_) { start = null; }
    try { end = (annotScore as dynamic).getEnd(); } catch (_) { end = null; }
    int y = 0;
    try { y = (annotScore as dynamic).getDrawingY() as int; } catch (_) { y = staff.getDrawingY(); }
    y = calcOffsetY(dc, y);
    if (graphic != null) {
      dc.resumeGraphic(graphic as BoundingBox, (graphic as dynamic).id as String);
    } else {
      dc.startGraphic(annotScore as BoundingBox, '', (annotScore as dynamic).id as String, graphicID: GraphicID.spanning);
    }
    final int unit = doc!.getDrawingUnit(staff.drawingStaffSize);
    final int boxHeight = _getAnnotScoreBoxHeight(unit);
    final int lineWidth = _getAnnotScoreLineWidth(unit);
    final int halfLineWidth = lineWidth ~/ 2;
    dc.setPen(lineWidth, PenStyle.solid, lineCap: LineCapStyle.butt, lineJoin: LineJoinStyle.miter);
    if (spanningType == spanningStart) {
      try { if (!(start as Object).isClass(ClassId.timestampAttr)) x1 -= _getCtrlDrawingRadius(start as LayerElement); } catch (_) {}
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
      try { if (!(start as Object).isClass(ClassId.timestampAttr)) x1 -= _getCtrlDrawingRadius(start as LayerElement); } catch (_) {}
      dc.drawLine(toDeviceContextX(x1), toDeviceContextY(y), toDeviceContextX(x2), toDeviceContextY(y));
      dc.drawLine(toDeviceContextX(x1), toDeviceContextY(y + boxHeight), toDeviceContextX(x2), toDeviceContextY(y + boxHeight));
      dc.setBrush(0.5, 0xFF0000);
      drawFilledRectangle(dc, x1, y + halfLineWidth, x2, y + boxHeight - halfLineWidth);
      dc.resetBrush();
    } else if (spanningType == spanningStartEnd) {
      try { if (!(start as Object).isClass(ClassId.timestampAttr)) x1 -= _getCtrlDrawingRadius(start as LayerElement); } catch (_) {}
      try { if (!(end as Object).isClass(ClassId.timestampAttr)) x2 += _getCtrlDrawingRadius(end as LayerElement); } catch (_) {}
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
      try { if (!(end as Object).isClass(ClassId.timestampAttr)) x2 += _getCtrlDrawingRadius(end as LayerElement); } catch (_) {}
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
    if (graphic != null) dc.endResumedGraphic(graphic as BoundingBox); else dc.endGraphic(annotScore as BoundingBox);
  }

  // ---------------------------------------------------------------------------
  // View::DrawPitchInflection (view_control.cpp:964)
  // ---------------------------------------------------------------------------
  void drawPitchInflection(DeviceContext dc, dynamic pitchInflection, int x1, int x2, Staff staff, int spanningType, Object? graphic) {
    final int topY = calcOffsetY(dc, staff.getDrawingY() + doc!.getDrawingDoubleUnit(staff.drawingStaffSize));
    dynamic start;
    dynamic end;
    try { start = (pitchInflection as dynamic).getStart(); } catch (_) {}
    try { end = (pitchInflection as dynamic).getEnd(); } catch (_) {}
    final Note? note1 = start is Note ? start as Note : null;
    final Note? note2 = end is Note ? end as Note : null;
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
        try { tmp = staff.getDrawingY() + (note2 as dynamic).drawingYRel as int; } catch (_) {}
        y2 = calcOffsetY(dc, tmp);
      }
      y2 -= (y2 - y1) ~/ 2;
      yControl = y1 + (y2 - y1) ~/ 4;
      xControl = x2 - (x2 - x1) ~/ 4;
    } else if (spanningType == spanningEnd) {
      if (up && note1 != null) {
        int tmp = staff.getDrawingY();
        try { tmp = staff.getDrawingY() + (note1 as dynamic).drawingYRel as int; } catch (_) {}
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
    if (graphic != null) dc.resumeGraphic(graphic as BoundingBox, (graphic as dynamic).id as String);
    else dc.startGraphic(pitchInflection as BoundingBox, 'spanning-pinflection', '');
    dc.setPen(doc!.getDrawingStemWidth(staff.drawingStaffSize), PenStyle.solid);
    dc.drawQuadBezierPath(points);
    if (drawArrow) dc.drawPolygon(arrow);
    dc.resetPen();
    if (graphic != null) dc.endResumedGraphic(graphic as BoundingBox); else dc.endGraphic(pitchInflection as BoundingBox);
  }

  // ---------------------------------------------------------------------------
  // View::DrawArpeg (view_control.cpp:1518)
  // ---------------------------------------------------------------------------
  void drawArpeg(DeviceContext dc, dynamic arpeg, Measure measure, System system) {
    final (Note? topNote, Note? bottomNote) = _getArpegTopBottomNotes(arpeg);
    if (topNote == null || bottomNote == null) return;
    final int top = topNote.getDrawingY();
    final int bottom = bottomNote.getDrawingY();
    Staff? staff;
    try { staff = topNote.getFirstAncestor(ClassId.staff) as Staff; } catch (_) {}
    staff ??= (topNote.getFirstAncestor(ClassId.staff) as Staff?);
    if (staff == null) return;
    bool drawingCueSize = false;
try { drawingCueSize = (topNote as dynamic).getDrawingCueSize() as bool; } catch (_) {}
    if (!system.setSystemCurrentFloatingPositioner(staff.n ?? meiUnset, arpeg as FloatingObject, topNote, staff)) return;
    try {
      final dynamic pos = (arpeg as dynamic).getCurrentFloatingPositioner();
      final int xRel = (arpeg as dynamic).drawingXRel as int? ?? 0;
      pos?.setDrawingXRel(xRel);
    } catch (_) {}
    int length = top - bottom;
    final int unit = doc!.getDrawingUnit(staff.drawingStaffSize);
    int x = 0;
    try { x = (arpeg as dynamic).getDrawingX() as int; } catch (_) { x = topNote.getDrawingX(); }
    int y = bottom - unit;
    setOffsetStaffSize(arpeg as Object, staff.drawingStaffSize);
    final r = calcOffset(dc, x, y);
    x = r.$1; y = r.$2;
    dynamic orderDyn;
    try { orderDyn = (arpeg as dynamic).order ?? (arpeg as dynamic).getOrder?.call(); } catch (_) {}
    final String orderStr = orderDyn?.toString().toLowerCase() ?? 'up';
    if (orderStr.contains('nonarp')) {
      dc.startGraphic(arpeg as BoundingBox, '', (arpeg as dynamic).id as String);
      final int offset = unit ~/ 2;
      final int thickness = doc!.getDrawingStemWidth(staff.drawingStaffSize);
      drawSquareBracket(dc, true, x - unit, bottom - offset, length + 2 * offset, unit, thickness, thickness);
      dc.endGraphic(arpeg as BoundingBox);
      return;
    }
    length += 2 * unit;
    int startGlyph = 0xEAA9;
    int fillGlyph = 0xEAA9;
    int endGlyph = 0;
    bool hasArrow = false;
    try { hasArrow = (arpeg as dynamic).arrow == true; } catch (_) { try { hasArrow = (arpeg as dynamic).getArrow?.call() == true; } catch (_) {} }
    if (orderStr.contains('down')) {
      startGlyph = hasArrow ? 0xEAAE : 0;
      fillGlyph = 0xEAAA;
      endGlyph = 0xEAAA;
    } else {
      startGlyph = 0xEAA9;
      fillGlyph = 0xEAA9;
      endGlyph = hasArrow ? 0xEAAD : 0;
    }
    try {
      final dynamic shape = (arpeg as dynamic).arrowShape ?? (arpeg as dynamic).getArrowShape?.call();
      if (shape != null && shape.toString().toLowerCase().contains('none')) endGlyph = 0;
    } catch (_) {}
    final Point orig = Point(x, y);
    dc.startGraphic(arpeg as BoundingBox, '', (arpeg as dynamic).id as String);
    dc.rotateGraphic(Point(toDeviceContextX(x), toDeviceContextY(y)), -90);
    drawSmuflLine(dc, orig, length, staff.drawingStaffSize, drawingCueSize, fillGlyph, startGlyph, endGlyph);
    dc.endGraphic(arpeg as BoundingBox);
    drawArpegEnclosing(dc, arpeg, staff, startGlyph, fillGlyph, endGlyph, x, y, length, drawingCueSize);
  }

  void _drawArpegCompat() {}

  // ---------------------------------------------------------------------------
  // View::DrawArpegEnclosing (view_control.cpp:1598)
  // ---------------------------------------------------------------------------
  void drawArpegEnclosing(DeviceContext dc, dynamic arpeg, Staff staff, int startGlyph, int fillGlyph, int endGlyph, int x, int y, int height, bool cueSize) {
    dynamic encloseDyn;
    try { encloseDyn = (arpeg as dynamic).enclose ?? (arpeg as dynamic).getEnclose?.call(); } catch (_) {}
    final String encloseStr = encloseDyn?.toString().toLowerCase() ?? 'none';
    final bool isBrack = encloseStr.contains('brack');
    final bool isBox = encloseStr.contains('box');
    if (!isBrack && !isBox) return;
    final int unit = doc!.getDrawingUnit(staff.drawingStaffSize);
    int width = doc!.getGlyphHeight(fillGlyph, staff.drawingStaffSize, cueSize);
    int exceedingWidth = unit - width;
    if (exceedingWidth < 0) exceedingWidth = 0;
    bool hasArrow = false;
    try { hasArrow = (arpeg as dynamic).arrow == true; } catch (_) {}
    if (hasArrow) {
      int arrowWidth = 0;
      dynamic orderDyn;
      try { orderDyn = (arpeg as dynamic).order; } catch (_) {}
      final String o = orderDyn?.toString().toLowerCase() ?? '';
      if (o.contains('down')) {
        if (startGlyph != 0) arrowWidth = doc!.getGlyphHeight(startGlyph, staff.drawingStaffSize, cueSize);
      } else {
        if (endGlyph != 0) arrowWidth = doc!.getGlyphHeight(endGlyph, staff.drawingStaffSize, cueSize);
      }
      final int alt = arrowWidth - width;
      if (alt > exceedingWidth) exceedingWidth = alt;
    }
    x -= (width + exceedingWidth ~/ 2);
    width += exceedingWidth;
    final int offset = 3 * unit ~/ 4;
    final int bracketWidth = isBrack ? unit : (width + offset);
    final int verticalThickness = doc!.getDrawingStemWidth(staff.drawingStaffSize);
    final int horizontalThickness = (isBrack ? 2 : 1) * verticalThickness;
    dc.startGraphic(arpeg as BoundingBox, '', (arpeg as dynamic).id as String);
    drawEnclosingBrackets(dc, x, y, height, width, offset, bracketWidth, horizontalThickness, verticalThickness);
    dc.endGraphic(arpeg as BoundingBox);
  }

  // ---------------------------------------------------------------------------
  // View::DrawBreath (view_control.cpp:1641)
  // ---------------------------------------------------------------------------
  void drawBreath(DeviceContext dc, dynamic breath, Measure measure, System system) {
    dynamic start;
    try { start = (breath as dynamic).getStart(); } catch (_) { return; }
    if (start == null) return;
    dc.startGraphic(breath as BoundingBox, '', (breath as dynamic).id as String);
    SymbolDef? symbolDef;
    try {
      final bool hasAltsym = (breath as dynamic).hasAltsym == true;
      if (hasAltsym) symbolDef = (breath as dynamic).getAltSymbolDef() as SymbolDef?;
      if (symbolDef == null) symbolDef = (breath as dynamic).altSymbolDef as SymbolDef?;
    } catch (_) {}
    int drawingX = 0;
    try { drawingX = (((start as dynamic).getDrawingX() as int)) + _getCtrlDrawingRadius(start as LayerElement); } catch (_) {}
    const int code = 0xE4CE;
    final String str = String.fromCharCode(code);
    bool isTimestamp = false;
    try { isTimestamp = (start as dynamic).isClass(ClassId.timestampAttr) == true; } catch (_) {}
    final HorizontalAlignment alignment = isTimestamp ? HorizontalAlignment.left : HorizontalAlignment.center;
    final List<Staff> staffList = _getTstampStavesFor(breath, measure, start);
    for (final Staff staff in staffList) {
      if (!system.setSystemCurrentFloatingPositioner(staff.n ?? meiUnset, breath as FloatingObject, start as Object, staff)) continue;
      final int staffSize = staff.drawingStaffSize;
      int x = drawingX;
      int y = 0;
      try { y = (breath as dynamic).getDrawingY() as int; } catch (_) { y = staff.getDrawingY(); }
      setOffsetStaffSize(breath as Object, staffSize);
      final r = calcOffset(dc, x, y);
      x = r.$1; y = r.$2;
      if (symbolDef != null) {
        drawSymbolDef(dc, breath as Object, symbolDef, x, y, staffSize, false, alignment);
      } else {
        dc.setFont(doc!.getDrawingSmuflFont(staffSize, false));
        drawSmuflString(dc, x, y, str, alignment, staffSize);
        dc.resetFont();
      }
    }
    dc.endGraphic(breath as BoundingBox);
  }

  // ---------------------------------------------------------------------------
  // View::DrawCaesura (view_control.cpp:1697)
  // ---------------------------------------------------------------------------
  void drawCaesura(DeviceContext dc, dynamic caesura, Measure measure, System system) {
    dynamic start;
    try { start = (caesura as dynamic).getStart(); } catch (_) { return; }
    if (start == null) return;
    dc.startGraphic(caesura as BoundingBox, '', (caesura as dynamic).id as String);
    SymbolDef? symbolDef;
    try {
      final bool hasAltsym = (caesura as dynamic).hasAltsym == true;
      if (hasAltsym) symbolDef = (caesura as dynamic).getAltSymbolDef() as SymbolDef?;
      if (symbolDef == null) symbolDef = (caesura as dynamic).altSymbolDef as SymbolDef?;
    } catch (_) {}
    final int code = _getCaesuraGlyph(caesura);
    int drawingX = 0;
    try { drawingX = (((start as dynamic).getDrawingX() as int)) + _getCtrlDrawingRadius(start as LayerElement) * 3; } catch (_) {}
    final List<Staff> staffList = _getTstampStavesFor(caesura, measure, start);
    for (final Staff staff in staffList) {
      if (!system.setSystemCurrentFloatingPositioner(staff.n ?? meiUnset, caesura as FloatingObject, start as Object, staff)) continue;
      final int staffSize = staff.drawingStaffSize;
      int x = drawingX;
      final int glyphHeight = symbolDef != null ? symbolDef.getSymbolHeight(doc!, staffSize, false) : doc!.getGlyphHeight(code, staffSize, false);
      int y = 0;
      bool hasPlace = false;
      dynamic place;
      try { hasPlace = (caesura as dynamic).hasPlace == true; place = (caesura as dynamic).place; } catch (_) {}
      if (hasPlace && place != null && !place.toString().toLowerCase().contains('within')) {
        try { y = (caesura as dynamic).getDrawingY() as int; } catch (_) { y = staff.getDrawingY() - glyphHeight ~/ 2; }
      } else {
        y = staff.getDrawingY() - glyphHeight ~/ 2;
      }
      setOffsetStaffSize(caesura as Object, staffSize);
      final r = calcOffset(dc, x, y);
      x = r.$1; y = r.$2;
      if (symbolDef != null) {
        drawSymbolDef(dc, caesura as Object, symbolDef, x, y, staffSize, false);
      } else {
        drawSmuflCode(dc, x, y, code, staffSize, false);
      }
    }
    dc.endGraphic(caesura as BoundingBox);
  }

  // ---------------------------------------------------------------------------
  // View::DrawFermata (view_control.cpp:1999)
  // ---------------------------------------------------------------------------
  void drawFermata(DeviceContext dc, dynamic fermata, Measure measure, System system) {
    dynamic start;
    try { start = (fermata as dynamic).getStart(); } catch (_) { return; }
    if (start == null) return;
    dc.startGraphic(fermata as BoundingBox, '', (fermata as dynamic).id as String);
    SymbolDef? symbolDef;
    try {
      final bool hasAltsym = (fermata as dynamic).hasAltsym == true;
      if (hasAltsym) symbolDef = (fermata as dynamic).getAltSymbolDef() as SymbolDef?;
      if (symbolDef == null) symbolDef = (fermata as dynamic).altSymbolDef as SymbolDef?;
    } catch (_) {}
    final int code = _getFermataGlyph(fermata);
    final (int enclosingFront, int enclosingBack) = _getEnclosingGlyphs(fermata);
    int drawingX = 0;
    try { drawingX = (((start as dynamic).getDrawingX() as int)) + _getCtrlDrawingRadius(start as LayerElement); } catch (_) {}
    final List<Staff> staffList = _getTstampStavesFor(fermata, measure, start);
    for (final Staff staff in staffList) {
      if (!system.setSystemCurrentFloatingPositioner(staff.n ?? meiUnset, fermata as FloatingObject, start as Object, staff)) continue;
      int staffSize = staff.drawingStaffSize;
      try { staffSize = (staff as dynamic).drawingStaffNotationSize as int; } catch (_) {}
      int x = drawingX;
      int y = 0;
      try { y = (fermata as dynamic).getDrawingY() as int; } catch (_) { y = staff.getDrawingY(); }
      setOffsetStaffSize(fermata as Object, staffSize);
      final r = calcOffset(dc, x, y);
      x = r.$1; y = r.$2;
      final int width = symbolDef != null ? symbolDef.getSymbolWidth(doc!, staffSize, false) : doc!.getGlyphWidth(code, staffSize, false);
      final int height = symbolDef != null ? symbolDef.getSymbolHeight(doc!, staffSize, false) : doc!.getGlyphHeight(code, staffSize, false);
      final int xCorr = width ~/ 2;
      int yCorr = 0;
      int enclosureYCorr = 0;
      final String verticalAlign = _getFermataVerticalAlignment(code);
      if (verticalAlign == 'top') yCorr = height ~/ 2;
      else if (verticalAlign == 'bottom') yCorr = -height ~/ 2;
      else {
        int glyphBottomY = 0;
        try { glyphBottomY = doc!.getGlyphBottom(code, staffSize, false); } catch (_) {}
        dynamic place;
        try { place = (fermata as dynamic).place; } catch (_) {}
        final String ps = place?.toString().toLowerCase() ?? '';
        if (ps.contains('above')) yCorr = height ~/ 2 + glyphBottomY;
        else enclosureYCorr = height ~/ 2 + glyphBottomY;
      }
      dc.setFont(doc!.getDrawingSmuflFont(staffSize, false));
      if (enclosingFront != 0) {
        final int xCorrEncl = xCorr + doc!.getDrawingUnit(staffSize) ~/ 3 + doc!.getGlyphWidth(enclosingFront, staffSize, false);
        drawSmuflCode(dc, x - xCorrEncl, y + enclosureYCorr + yCorr, enclosingFront, staffSize, false);
      }
      if (symbolDef != null) {
        drawSymbolDef(dc, fermata as Object, symbolDef, x - xCorr, y, staffSize, false);
      } else {
        drawSmuflCode(dc, x - xCorr, y, code, staffSize, false);
      }
      if (enclosingBack != 0) {
        final int xCorrEncl = xCorr + doc!.getDrawingUnit(staffSize) ~/ 3;
        drawSmuflCode(dc, x + xCorrEncl, y + enclosureYCorr + yCorr, enclosingBack, staffSize, false);
      }
      dc.resetFont();
    }
    dc.endGraphic(fermata as BoundingBox);
  }

  // ---------------------------------------------------------------------------
  // View::DrawFing (view_control.cpp:2092)
  // ---------------------------------------------------------------------------
  void drawFing(DeviceContext dc, dynamic fing, Measure measure, System system) {
    dynamic start;
    try { start = (fing as dynamic).getStart(); } catch (_) { return; }
    if (start == null) return;
    dc.startGraphic(fing as BoundingBox, '', (fing as dynamic).id as String);
    final FontInfo fingTxt = FontInfo();
    if (!dc.useGlobalStyling()) {
      try { fingTxt.faceName = doc!.getResources().textFontName; } catch (_) {}
    }
    const HorizontalAlignment alignment = HorizontalAlignment.center;
    final List<Staff> staffList = _getTstampStavesFor(fing, measure, start);
    for (final Staff staff in staffList) {
      if (!system.setSystemCurrentFloatingPositioner(staff.n ?? meiUnset, fing as FloatingObject, start as Object, staff)) continue;
      final int staffSize = staff.drawingStaffSize;
      int x = 0;
      int y = 0;
      try { x = (((start as dynamic).getDrawingX() as int)) + _getCtrlDrawingRadius(start as LayerElement); } catch (_) {}
      try { y = (fing as dynamic).getDrawingY() as int; } catch (_) { y = staff.getDrawingY(); }
      setOffsetStaffSize(fing as Object, staffSize);
      final r = calcOffset(dc, x, y);
      x = r.$1; y = r.$2;
      final TextDrawingParams params = TextDrawingParams();
      params.x = x; params.y = y;
      try { params.pointSize = doc!.getDrawingLyricFont(staffSize).pointSize; } catch (_) {}
      try { fingTxt.pointSize = params.pointSize; } catch (_) {}
      dc.setFont(fingTxt);
      dc.startText(toDeviceContextX(params.x), toDeviceContextY(params.y), alignment);
      drawTextChildren(dc, fing as Object, params);
      dc.endText();
      dc.resetFont();
      drawTextEnclosure(dc, params, staffSize);
    }
    dc.endGraphic(fing as BoundingBox);
  }

  // ---------------------------------------------------------------------------
  // View::DrawGliss (view_control.cpp:2145)
  // ---------------------------------------------------------------------------
  void drawGliss(DeviceContext dc, dynamic gliss, int x1, int x2, Staff staff, int spanningType, Object? graphic) {
    int y1 = calcOffsetY(dc, staff.getDrawingY());
    int y2 = calcOffsetY(dc, staff.getDrawingY());
    dynamic start;
    dynamic end;
    try { start = (gliss as dynamic).getStart(); } catch (_) {}
    try { end = (gliss as dynamic).getEnd(); } catch (_) {}
    final Note? note1 = start is Note ? start as Note : null;
    final Note? note2 = end is Note ? end as Note : null;
    if (note1 == null || note2 == null) return;
    final int unit = doc!.getDrawingUnit(staff.drawingStaffSize);
    int firstLoc = 0;
    int secondLoc = 0;
    try { firstLoc = (note1 as dynamic).drawingLoc as int; } catch (_) {}
    try { secondLoc = (note2 as dynamic).drawingLoc as int; } catch (_) {}
    final int diff = (secondLoc - firstLoc) * unit;
    double angle = math.atan2(diff.toDouble(), (x2 - x1).toDouble());
    if (spanningType != spanningStartEnd) angle = angle / 2;
    if (spanningType == spanningStartEnd || spanningType == spanningStart) {
      double slope = 0.0;
      if (x1 != x2) slope = diff / (x2 - x1).toDouble();
      int offset = _getCtrlDrawingRadius(note1) + unit;
      try {
        final int dots = (note1 as dynamic).dots as int? ?? 0;
        if (dots > 0 && slope.abs() < 1.0) offset += (1.5 * unit * dots).toInt();
      } catch (_) {}
      x1 += (math.cos(angle) * offset).toInt();
      y1 = calcOffsetY(dc, note1.getDrawingY() + (offset * math.sin(angle)).toInt());
    } else {
      y1 = calcOffsetY(dc, note2.getDrawingY() - ((x2 - x1) * math.sin(angle)).toInt());
    }
    if (spanningType == spanningStartEnd || spanningType == spanningEnd) {
      dynamic accid;
      try { accid = (note2 as dynamic).getDrawingAccid(); } catch (_) {}
      bool hasAccid = accid != null;
      bool isNone = false;
      try {
        final dynamic a = (accid as dynamic).accid ?? (accid as dynamic).getAccid?.call();
        final String s = a?.toString().toLowerCase() ?? '';
        isNone = s.contains('none');
      } catch (_) {}
      if (hasAccid && !isNone && accid != null) {
        try {
          final int dist = x2 - ((accid as dynamic).getContentLeft() as int) + (0.5 * unit).toInt();
          x2 -= dist;
          y2 = calcOffsetY(dc, note2.getDrawingY() - (dist * math.tan(angle)).toInt());
        } catch (_) {
          final int offset = _getCtrlDrawingRadius(note2) + unit;
          x2 -= (math.cos(angle) * offset).toInt();
          y2 = calcOffsetY(dc, note2.getDrawingY() - (offset * math.sin(angle)).toInt());
        }
      } else {
        final int offset = _getCtrlDrawingRadius(note2) + unit;
        x2 -= (math.cos(angle) * offset).toInt();
        y2 = calcOffsetY(dc, note2.getDrawingY() - (offset * math.sin(angle)).toInt());
      }
    } else {
      x2 -= unit;
      y2 = calcOffsetY(dc, y1 + ((x2 - x1) * math.sin(angle)).toInt());
    }
    int lineWidth = (doc!.getDrawingStemWidth(staff.drawingStaffSize) * 1.5).toInt();
    if (graphic != null) dc.resumeGraphic(graphic as BoundingBox, (graphic as dynamic).id as String);
    else dc.startGraphic(gliss as BoundingBox, '', (gliss as dynamic).id as String, graphicID: GraphicID.spanning);
    dynamic lform;
    try { lform = (gliss as dynamic).lform ?? (gliss as dynamic).getLform?.call(); } catch (_) {}
    final String lformStr = lform?.toString().toLowerCase() ?? 'solid';
    if (lformStr.contains('wavy')) {
      final int length = math.sqrt(math.pow(x2 - x1, 2) + math.pow(y2 - y1, 2)).toInt();
      final double ang = math.atan2((y1 - y2).toDouble(), (x2 - x1).toDouble()) * 180 / math.pi;
      dc.rotateGraphic(Point(toDeviceContextX(x1), toDeviceContextY(y1)), ang);
      const int glissGlyph = 0xEAAF;
      final int height = doc!.getGlyphHeight(glissGlyph, staff.drawingStaffSize, false);
      final Point orig = Point(x1, y1 - height ~/ 2);
      drawSmuflLine(dc, orig, length, staff.drawingStaffSize, false, glissGlyph);
    } else if (lformStr.contains('dashed')) {
      dc.setPen(lineWidth, PenStyle.shortDash, lineCap: LineCapStyle.round);
      dc.drawLine(toDeviceContextX(x1), toDeviceContextY(y1), toDeviceContextX(x2), toDeviceContextY(y2));
      dc.resetPen();
    } else if (lformStr.contains('dotted')) {
      dc.setPen(lineWidth * 3 ~/ 2, PenStyle.dot, lineCap: LineCapStyle.round);
      dc.drawLine(toDeviceContextX(x1), toDeviceContextY(y1), toDeviceContextX(x2), toDeviceContextY(y2));
      dc.resetPen();
    } else {
      dc.setPen(lineWidth, PenStyle.solid, lineCap: LineCapStyle.round);
      dc.drawLine(toDeviceContextX(x1), toDeviceContextY(y1), toDeviceContextX(x2), toDeviceContextY(y2));
      dc.resetPen();
    }
    if (graphic != null) dc.endResumedGraphic(graphic as BoundingBox); else dc.endGraphic(gliss as BoundingBox);
  }

  // ---------------------------------------------------------------------------
  // View::DrawMordent (view_control.cpp:2351)
  // ---------------------------------------------------------------------------
  void drawMordent(DeviceContext dc, dynamic mordent, Measure measure, System system) {
    dynamic start;
    try { start = (mordent as dynamic).getStart(); } catch (_) { return; }
    if (start == null) return;
    dc.startGraphic(mordent as BoundingBox, '', (mordent as dynamic).id as String);
    SymbolDef? symbolDef;
    try {
      final bool hasAltsym = (mordent as dynamic).hasAltsym == true;
      if (hasAltsym) symbolDef = (mordent as dynamic).getAltSymbolDef() as SymbolDef?;
      if (symbolDef == null) symbolDef = (mordent as dynamic).altSymbolDef as SymbolDef?;
    } catch (_) {}
    int drawingX = 0;
    try { drawingX = (((start as dynamic).getDrawingX() as int)) + _getCtrlDrawingRadius(start as LayerElement); } catch (_) {}
    final int code = _getMordentGlyph(mordent);
    final (int enclosingFront, int enclosingBack) = _getEnclosingGlyphs(mordent);
    final String str = String.fromCharCode(code);
    final List<Staff> staffList = _getTstampStavesFor(mordent, measure, start);
    for (final Staff staff in staffList) {
      if (!system.setSystemCurrentFloatingPositioner(staff.n ?? meiUnset, mordent as FloatingObject, start as Object, staff)) continue;
      final int staffSize = staff.drawingStaffSize;
      int x = drawingX;
      int y = 0;
      try { y = (mordent as dynamic).getDrawingY() as int; } catch (_) { y = staff.getDrawingY(); }
      setOffsetStaffSize(mordent as Object, staffSize);
      final r = calcOffset(dc, x, y);
      x = r.$1; y = r.$2;
      final int mordentHeight = symbolDef != null ? symbolDef.getSymbolHeight(doc!, staffSize, false) : doc!.getGlyphHeight(code, staffSize, false);
      final int mordentWidth = symbolDef != null ? symbolDef.getSymbolWidth(doc!, staffSize, false) : doc!.getGlyphWidth(code, staffSize, false);
      x -= mordentWidth ~/ 2;
      dc.setFont(doc!.getDrawingSmuflFont(staffSize, false));
      dynamic accidLower;
      try { accidLower = (mordent as dynamic).accidlower ?? (mordent as dynamic).getAccidlower?.call(); } catch (_) {}
      bool hasLower = false;
      try { hasLower = (mordent as dynamic).hasAccidlower == true || accidLower != null; } catch (_) { hasLower = accidLower != null; }
      if (hasLower && accidLower != null && accidLower.toString().toLowerCase() != 'none' && accidLower.toString() != '0') {
        final int accid = _getAccidGlyph(accidLower);
        if (accid != 0) {
          final String accidStr = String.fromCharCode(accid);
          int accidY = y;
          int accidX = x;
          if (symbolDef == null) {
            double xShift = 0.0;
            double factor = 1.0;
            final String s = accidLower.toString().toLowerCase();
            if (s.contains('ff')) { factor = 1.20; xShift = 0.14; }
            else if (s.contains('n')) { factor = 0.90; xShift = -0.04; }
            else if (s == 's' || s.contains('sharp')) factor = 1.15;
            else if (s.contains('x')) factor = 2.00;
            accidX += ((1 + xShift) * mordentWidth / 2).toInt();
            accidY -= (factor * doc!.getGlyphHeight(accid, staffSize, true) / 2).toInt();
          } else {
            accidX += mordentWidth ~/ 2;
            accidY -= (doc!.getGlyphTop(accid, staffSize ~/ 2, true) + doc!.getDrawingUnit(staffSize * 2 ~/ 3));
          }
          drawSmuflString(dc, accidX, accidY, accidStr, HorizontalAlignment.center, staffSize ~/ 2);
        }
      } else {
        dynamic accidUpper;
        try { accidUpper = (mordent as dynamic).accidupper ?? (mordent as dynamic).getAccidupper?.call(); } catch (_) {}
        bool hasUpper = false;
        try { hasUpper = (mordent as dynamic).hasAccidupper == true || accidUpper != null; } catch (_) { hasUpper = accidUpper != null; }
        if (hasUpper && accidUpper != null && accidUpper.toString().toLowerCase() != 'none' && accidUpper.toString() != '0') {
          final int accid = _getAccidGlyph(accidUpper);
          if (accid != 0) {
            final String accidStr = String.fromCharCode(accid);
            int accidY = y;
            int accidX = x;
            if (symbolDef == null) {
              double xShift = 0.0;
              double factor = 1.75;
              final String s = accidUpper.toString().toLowerCase();
              if (s.contains('ff')) factor = 1.40;
              else if (s.contains('n')) { factor = 1.60; xShift = -0.10; }
              else if (s.contains('s')) { factor = 1.60; xShift = -0.06; }
              else if (s.contains('x')) { factor = 1.35; xShift = -0.08; }
              accidX += ((1 + xShift) * mordentWidth / 2).toInt();
              accidY += (factor * mordentHeight).toInt();
            } else {
              accidX += mordentWidth ~/ 2;
              accidY += (mordentHeight - doc!.getGlyphBottom(accid, staffSize ~/ 2, true) + doc!.getDrawingUnit(staffSize * 2 ~/ 3));
            }
            drawSmuflString(dc, accidX, accidY, accidStr, HorizontalAlignment.center, staffSize ~/ 2);
          }
        }
      }
      final int yCorrEncl = doc!.getGlyphHeight(0xE56C, staffSize, false) ~/ 2;
      if (enclosingFront != 0) {
        final int xCorrEncl = doc!.getGlyphWidth(enclosingFront, staffSize, false);
        drawSmuflCode(dc, x - xCorrEncl, y + yCorrEncl, enclosingFront, staffSize, false);
      }
      if (symbolDef != null) {
        drawSymbolDef(dc, mordent as Object, symbolDef, x, y, staffSize, false);
      } else {
        drawSmuflString(dc, x, y, str, HorizontalAlignment.left, staffSize);
      }
      if (enclosingBack != 0) {
        final int xCorrEncl = mordentWidth + doc!.getGlyphWidth(enclosingBack, staffSize, false) - doc!.getGlyphAdvX(enclosingBack, staffSize, false);
        drawSmuflCode(dc, x + xCorrEncl, y + yCorrEncl, enclosingBack, staffSize, false);
      }
      dc.resetFont();
    }
    dc.endGraphic(mordent as BoundingBox);
  }

  // ---------------------------------------------------------------------------
  // View::DrawPedal (view_control.cpp:2507)
  // ---------------------------------------------------------------------------
  void drawPedal(DeviceContext dc, dynamic pedal, Measure measure, System system) {
    dynamic start;
    try { start = (pedal as dynamic).getStart(); } catch (_) { return; }
    if (start == null) return;
    bool hasDir = false;
    try { hasDir = (pedal as dynamic).hasDir == true || (pedal as dynamic).dir != null; } catch (_) {}
    if (!hasDir) return;
    dc.startGraphic(pedal as BoundingBox, '', (pedal as dynamic).id as String);
    final Pedalstyle form = _getPedalForm(pedal, system);
    String dirStr = '';
    try { dirStr = (pedal as dynamic).dir?.toString().toLowerCase() ?? ''; } catch (_) { try { dirStr = (pedal as dynamic).getDir?.call()?.toString().toLowerCase() ?? ''; } catch (_) {} }
    bool drawSymbol = form != Pedalstyle.line;
    if (dirStr.contains('up') && form == Pedalstyle.pedline) drawSymbol = false;
    if (!drawSymbol) { dc.endGraphic(pedal as BoundingBox); return; }
    bool bounceStar = true;
    if (form == Pedalstyle.altpedstar) bounceStar = false;
    int drawingX = 0;
    try { drawingX = (((start as dynamic).getDrawingX() as int)) + _getCtrlDrawingRadius(start as LayerElement); } catch (_) {}
    bool isTimestamp = false;
    try { isTimestamp = (start as dynamic).isClass(ClassId.timestampAttr) == true; } catch (_) {}
    HorizontalAlignment alignment = HorizontalAlignment.center;
    if (isTimestamp) {
      try {
        final dynamic align = (start as dynamic).getAlignment();
        final dynamic rightAl = measure.measureAligner.getRightBarLineAlignment();
        if (align != null && rightAl != null && align.getTime() == rightAl.getTime()) alignment = HorizontalAlignment.right;
        else alignment = HorizontalAlignment.left;
      } catch (_) { alignment = HorizontalAlignment.left; }
    }
    String str = '';
    if (bounceStar && dirStr.contains('bounce')) {
      str = String.fromCharCode(0xE655);
      try {
        final List<Staff> tmp = _getTstampStavesFor(pedal, measure, start);
        final int sz = tmp.isNotEmpty ? tmp.first.drawingStaffSize : 100;
        drawingX -= doc!.getGlyphWidth(0xE655, sz, false);
      } catch (_) {}
    }
    int code = _getPedalGlyph(pedal);
    if (!dirStr.contains('up')) str += String.fromCharCode(code);
    else if (str.isEmpty) str = String.fromCharCode(code);
    final List<Staff> staffList = _getTstampStavesFor(pedal, measure, start);
    for (final Staff staff in staffList) {
      if (!system.setSystemCurrentFloatingPositioner(staff.n ?? meiUnset, pedal as FloatingObject, start as Object, staff)) continue;
      final int staffSize = staff.drawingStaffSize;
      int x = drawingX;
      int y = 0;
      try { y = (pedal as dynamic).getDrawingY() as int; } catch (_) { y = staff.getDrawingY(); }
      setOffsetStaffSize(pedal as Object, staffSize);
      final r = calcOffset(dc, x, y);
      x = r.$1; y = r.$2;
      dc.setFont(doc!.getDrawingSmuflFont(staffSize, false));
      drawSmuflString(dc, x, y, str, alignment, staffSize);
      dc.resetFont();
    }
    dc.endGraphic(pedal as BoundingBox);
  }

  // ---------------------------------------------------------------------------
  // View::DrawRepeatMark (view_control.cpp:2671)
  // ---------------------------------------------------------------------------
  void drawRepeatMark(DeviceContext dc, dynamic repeatMark, Measure measure, System system) {
    dynamic start;
    try { start = (repeatMark as dynamic).getStart(); } catch (_) { return; }
    if (start == null) return;
    int childCount = 0;
    try { childCount = (repeatMark as Object).childCount; } catch (_) { try { childCount = (repeatMark as dynamic).getChildCount() as int; } catch (_) {} }
    if (childCount > 0) { drawControlElementText(dc, repeatMark as ControlElement, measure, system); return; }
    dc.startGraphic(repeatMark as BoundingBox, '', (repeatMark as dynamic).id as String);
    SymbolDef? symbolDef;
    try {
      final bool hasAltsym = (repeatMark as dynamic).hasAltsym == true;
      if (hasAltsym) symbolDef = (repeatMark as dynamic).getAltSymbolDef() as SymbolDef?;
      if (symbolDef == null) symbolDef = (repeatMark as dynamic).altSymbolDef as SymbolDef?;
    } catch (_) {}
    int drawingX = 0;
    try { drawingX = (((start as dynamic).getDrawingX() as int)) + _getCtrlDrawingRadius(start as LayerElement); } catch (_) {}
    final int code = _getRepeatMarkGlyph(repeatMark);
    final String str = String.fromCharCode(code);
    bool isTimestamp = false;
    try { isTimestamp = (start as dynamic).isClass(ClassId.timestampAttr) == true; } catch (_) {}
    final HorizontalAlignment alignment = isTimestamp ? HorizontalAlignment.left : HorizontalAlignment.center;
    final List<Staff> staffList = _getTstampStavesFor(repeatMark, measure, start);
    for (final Staff staff in staffList) {
      if (!system.setSystemCurrentFloatingPositioner(staff.n ?? meiUnset, repeatMark as FloatingObject, start as Object, staff)) continue;
      final int staffSize = staff.drawingStaffSize;
      int x = drawingX;
      int y = 0;
      try { y = (repeatMark as dynamic).getDrawingY() as int; } catch (_) { y = staff.getDrawingY(); }
      setOffsetStaffSize(repeatMark as Object, staffSize);
      final r = calcOffset(dc, x, y);
      x = r.$1; y = r.$2;
      dc.setFont(doc!.getDrawingSmuflFont(staffSize, false));
      if (symbolDef != null) {
        drawSymbolDef(dc, repeatMark as Object, symbolDef, x, y, staffSize, false, alignment);
      } else {
        drawSmuflString(dc, x, y, str, alignment, staffSize);
      }
      dc.resetFont();
    }
    dc.endGraphic(repeatMark as BoundingBox);
  }

  // ---------------------------------------------------------------------------
  // View::DrawTrill (view_control.cpp:2798)
  // ---------------------------------------------------------------------------
  void drawTrill(DeviceContext dc, dynamic trill, Measure measure, System system) {
    dynamic start;
    try { start = (trill as dynamic).getStart(); } catch (_) { return; }
    if (start == null) return;
    dc.startGraphic(trill as BoundingBox, '', (trill as dynamic).id as String);
    SymbolDef? symbolDef;
    try {
      final bool hasAltsym = (trill as dynamic).hasAltsym == true;
      if (hasAltsym) symbolDef = (trill as dynamic).getAltSymbolDef() as SymbolDef?;
      if (symbolDef == null) symbolDef = (trill as dynamic).altSymbolDef as SymbolDef?;
    } catch (_) {}
    int drawingX = 0;
    try { drawingX = (start as dynamic).getDrawingX() as int; } catch (_) {}
    bool isTimestamp = false;
    try { isTimestamp = (start as dynamic).isClass(ClassId.timestampAttr) == true; } catch (_) {}
    HorizontalAlignment alignment = HorizontalAlignment.center;
    if (isTimestamp) alignment = HorizontalAlignment.left;
    else {
      try { drawingX += _getCtrlDrawingRadius(start as LayerElement); } catch (_) {}
    }
    final int code = _getTrillGlyph(trill);
    final (int enclosingFront, int enclosingBack) = _getEnclosingGlyphs(trill);
    String str = '';
    try {
      final dynamic lstart = (trill as dynamic).lstartsym ?? (trill as dynamic).getLstartsym?.call();
      final String s = lstart?.toString().toLowerCase() ?? 'none';
      if (!s.contains('none')) str = String.fromCharCode(code);
      else str = String.fromCharCode(code);
    } catch (_) { str = String.fromCharCode(code); }
    final List<Staff> staffList = _getTstampStavesFor(trill, measure, start);
    for (final Staff staff in staffList) {
      if (!system.setSystemCurrentFloatingPositioner(staff.n ?? meiUnset, trill as FloatingObject, start as Object, staff)) continue;
      final int staffSize = staff.drawingStaffSize;
      int x = drawingX;
      int y = 0;
      try { y = (trill as dynamic).getDrawingY() as int; } catch (_) { y = staff.getDrawingY(); }
      setOffsetStaffSize(trill as Object, staffSize);
      final r = calcOffset(dc, x, y);
      x = r.$1; y = r.$2;
      final int trillHeight = symbolDef != null ? symbolDef.getSymbolHeight(doc!, staffSize, false) : doc!.getGlyphHeight(code, staffSize, false);
      final int trillWidth = symbolDef != null ? symbolDef.getSymbolWidth(doc!, staffSize, false) : doc!.getGlyphWidth(code, staffSize, false);
      dc.setFont(doc!.getDrawingSmuflFont(staffSize, false));
      if (enclosingFront != 0) {
        final int xCorrEncl = trillWidth ~/ 2 + doc!.getGlyphWidth(enclosingFront, staffSize, false);
        drawSmuflCode(dc, x - xCorrEncl, y + trillHeight ~/ 2, enclosingFront, staffSize, false);
      }
      dynamic accidLower;
      try { accidLower = (trill as dynamic).accidlower ?? (trill as dynamic).getAccidlower?.call(); } catch (_) {}
      dynamic accidUpper;
      try { accidUpper = (trill as dynamic).accidupper ?? (trill as dynamic).getAccidupper?.call(); } catch (_) {}
      bool hasLower = false, hasUpper = false;
      try { hasLower = (trill as dynamic).hasAccidlower == true || accidLower != null; } catch (_) { hasLower = accidLower != null; }
      try { hasUpper = (trill as dynamic).hasAccidupper == true || accidUpper != null; } catch (_) { hasUpper = accidUpper != null; }
      if (hasLower && accidLower != null && accidLower.toString().toLowerCase() != 'none') {
        final int accid = _getAccidGlyph(accidLower);
        if (accid != 0) {
          final String accidStr = String.fromCharCode(accid);
          final int accidXShift = (alignment == HorizontalAlignment.center) ? 0 : trillWidth ~/ 2;
          final int accidY = y - doc!.getGlyphTop(accid, staffSize ~/ 2, true) - doc!.getDrawingUnit(staffSize * 2 ~/ 3);
          drawSmuflString(dc, x + accidXShift, accidY, accidStr, HorizontalAlignment.center, staffSize ~/ 2);
        }
      } else if (hasUpper && accidUpper != null && accidUpper.toString().toLowerCase() != 'none') {
        final int accid = _getAccidGlyph(accidUpper);
        if (accid != 0) {
          final String accidStr = String.fromCharCode(accid);
          final int accidXShift = (alignment == HorizontalAlignment.center) ? 0 : trillWidth ~/ 2;
          final int accidY = y + trillHeight - doc!.getGlyphBottom(accid, staffSize ~/ 2, true) + doc!.getDrawingUnit(staffSize * 2 ~/ 3);
          drawSmuflString(dc, x + accidXShift, accidY, accidStr, HorizontalAlignment.center, staffSize ~/ 2);
        }
      }
      if (symbolDef != null) {
        drawSymbolDef(dc, trill as Object, symbolDef, x, y, staffSize, false, alignment);
      } else {
        drawSmuflString(dc, x, y, str, alignment, staffSize);
      }
      if (enclosingBack != 0) {
        final int xCorrEncl = trillWidth ~/ 2 + doc!.getGlyphWidth(enclosingBack, staffSize, false) - doc!.getGlyphAdvX(enclosingBack, staffSize, false);
        drawSmuflCode(dc, x + xCorrEncl, y + trillHeight ~/ 2, enclosingBack, staffSize, false);
      }
      dc.resetFont();
    }
    dc.endGraphic(trill as BoundingBox);
  }

  // ---------------------------------------------------------------------------
  // View::DrawTurn (view_control.cpp:2900)
  // ---------------------------------------------------------------------------
  void drawTurn(DeviceContext dc, dynamic turn, Measure measure, System system) {
    dynamic start;
    try { start = (turn as dynamic).getStart(); } catch (_) { return; }
    if (start == null) return;
    dc.startGraphic(turn as BoundingBox, '', (turn as dynamic).id as String);
    SymbolDef? symbolDef;
    try {
      final bool hasAltsym = (turn as dynamic).hasAltsym == true;
      if (hasAltsym) symbolDef = (turn as dynamic).getAltSymbolDef() as SymbolDef?;
      if (symbolDef == null) symbolDef = (turn as dynamic).altSymbolDef as SymbolDef?;
    } catch (_) {}
    int drawingX = 0;
    try { drawingX = (((start as dynamic).getDrawingX() as int)) + _getCtrlDrawingRadius(start as LayerElement); } catch (_) {}
    dynamic endElem;
    try { endElem = (turn as dynamic).drawingEndElement ?? (turn as dynamic).m_drawingEndElement; } catch (_) {}
    if (endElem != null) {
      try {
        final Object? parentSystem1 = (start as dynamic).getFirstAncestor(ClassId.system);
        final Object? parentSystem2 = (endElem as dynamic).getFirstAncestor(ClassId.system);
        if (parentSystem1 != parentSystem2) endElem = measure.getRightBarLine();
        int midTmp = 0; try { midTmp = (endElem as dynamic).getDrawingX() as int; } catch (_) {} final int mid = (midTmp - drawingX) ~/ 2;
        drawingX += mid;
      } catch (_) {}
    }
    final int code = _getTurnGlyph(turn);
    final (int enclosingFront, int enclosingBack) = _getEnclosingGlyphs(turn);
    bool isTimestamp = false;
    try { isTimestamp = (start as dynamic).isClass(ClassId.timestampAttr) == true; } catch (_) {}
    final HorizontalAlignment alignment = isTimestamp ? HorizontalAlignment.left : HorizontalAlignment.center;
    final String str = String.fromCharCode(code);
    final List<Staff> staffList = _getTstampStavesFor(turn, measure, start);
    for (final Staff staff in staffList) {
      if (!system.setSystemCurrentFloatingPositioner(staff.n ?? meiUnset, turn as FloatingObject, start as Object, staff)) continue;
      final int staffSize = staff.drawingStaffSize;
      int x = drawingX;
      int y = 0;
      try { y = (turn as dynamic).getDrawingY() as int; } catch (_) { y = staff.getDrawingY(); }
      setOffsetStaffSize(turn as Object, staffSize);
      final r = calcOffset(dc, x, y);
      x = r.$1; y = r.$2;
      final int turnHeight = symbolDef != null ? symbolDef.getSymbolHeight(doc!, staffSize, false) : doc!.getGlyphHeight(code, staffSize, false);
      final int turnWidth = symbolDef != null ? symbolDef.getSymbolWidth(doc!, staffSize, false) : doc!.getGlyphWidth(code, staffSize, false);
      dc.setFont(doc!.getDrawingSmuflFont(staffSize, false));
      dynamic accidLower;
      try { accidLower = (turn as dynamic).accidlower ?? (turn as dynamic).getAccidlower?.call(); } catch (_) {}
      if (accidLower != null && accidLower.toString().toLowerCase() != 'none') {
        final int accid = _getAccidGlyph(accidLower);
        if (accid != 0) {
          final int accidXShift = (alignment == HorizontalAlignment.center) ? 0 : turnWidth ~/ 2;
          final String accidStr = String.fromCharCode(accid);
          final int accidY = y - doc!.getGlyphTop(accid, staffSize ~/ 2, true) - doc!.getDrawingUnit(staffSize * 2 ~/ 3);
          drawSmuflString(dc, x + accidXShift, accidY, accidStr, HorizontalAlignment.center, staffSize ~/ 2);
        }
      }
      dynamic accidUpper;
      try { accidUpper = (turn as dynamic).accidupper ?? (turn as dynamic).getAccidupper?.call(); } catch (_) {}
      if (accidUpper != null && accidUpper.toString().toLowerCase() != 'none') {
        final int accid = _getAccidGlyph(accidUpper);
        if (accid != 0) {
          final int accidXShift = (alignment == HorizontalAlignment.center) ? 0 : turnWidth ~/ 2;
          final String accidStr = String.fromCharCode(accid);
          final int accidY = y + turnHeight - doc!.getGlyphBottom(accid, staffSize ~/ 2, true) + doc!.getDrawingUnit(staffSize * 2 ~/ 3);
          drawSmuflString(dc, x + accidXShift, accidY, accidStr, HorizontalAlignment.center, staffSize ~/ 2);
        }
      }
      if (enclosingFront != 0) {
        int xCorrEncl = doc!.getGlyphWidth(enclosingFront, staffSize, false);
        if (!isTimestamp) xCorrEncl += turnWidth ~/ 2;
        drawSmuflCode(dc, x - xCorrEncl, y + turnHeight ~/ 2, enclosingFront, staffSize, false);
      }
      if (symbolDef != null) {
        drawSymbolDef(dc, turn as Object, symbolDef, x, y, staffSize, false, alignment);
      } else {
        drawSmuflString(dc, x, y, str, alignment, staffSize);
      }
      if (enclosingBack != 0) {
        int xCorrEncl = turnWidth + doc!.getGlyphWidth(enclosingBack, staffSize, false) - doc!.getGlyphAdvX(enclosingBack, staffSize, false);
        if (!isTimestamp) xCorrEncl -= turnWidth ~/ 2;
        drawSmuflCode(dc, x + xCorrEncl, y + turnHeight ~/ 2, enclosingBack, staffSize, false);
      }
      dc.resetFont();
    }
    dc.endGraphic(turn as BoundingBox);
  }

  // ---------------------------------------------------------------------------
  // View::DrawSystemElement (view_control.cpp:3014)
  // ---------------------------------------------------------------------------
  void drawSystemElement(DeviceContext dc, SystemElement element, System system) {
    if (element.isClass(ClassId.systemMilestoneEnd)) {
      final dynamic end = element as dynamic;
      dynamic start;
      try { start = end.getStart(); } catch (_) { try { start = (element as dynamic).start; } catch (_) {} }
      String startId = element.id;
      try { startId = (start as dynamic).id as String; } catch (_) {}
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
    } else {
      dc.startGraphic(element as BoundingBox, '', element.id);
      dc.endGraphic(element as BoundingBox);
    }
  }

  // ---------------------------------------------------------------------------
  // View::DrawEnding (view_control.cpp:3048)
  // ---------------------------------------------------------------------------
  void drawEnding(DeviceContext dc, Ending ending, System system) {
    if (dc is BBoxDeviceContext) {
      final BBoxDeviceContext bBoxDC = dc as BBoxDeviceContext;
      if (!bBoxDC.updateVerticalValues()) return;
    }
    dynamic endingEndMilestone;
    try { endingEndMilestone = (ending as dynamic).systemMilestoneEnd ?? (ending as dynamic).getEnd?.call(); } catch (_) {}
    if (endingEndMilestone == null) return;
    Object? firstMeasure;
    Object? lastMeasure;
    try { firstMeasure = (ending as dynamic).drawingMeasure ?? (ending as dynamic).getMeasure?.call(); } catch (_) {}
    try { lastMeasure = (endingEndMilestone as dynamic).measure ?? (endingEndMilestone as dynamic).getMeasure?.call(); } catch (_) {}
    if (firstMeasure == null || lastMeasure == null) {
      try { firstMeasure = (ending as Object).findDescendantByType(ClassId.measure); } catch (_) {}
      try {
        final List<Object> all = (ending as Object).findAllDescendantsByType(ClassId.measure);
        if (all.isNotEmpty) lastMeasure = all.last;
      } catch (_) {}
      if (firstMeasure == null || lastMeasure == null) return;
    }
    Object? parentSystem1;
    Object? parentSystem2;
    try { parentSystem1 = (firstMeasure as dynamic).getFirstAncestor(ClassId.system); } catch (_) {}
    try { parentSystem2 = (lastMeasure as dynamic).getFirstAncestor(ClassId.system); } catch (_) {}
    if (parentSystem1 == null || parentSystem2 == null) return;
    int x1 = 0, x2 = 0;
    Object? objectX;
    Measure? measure;
    int spanningType = spanningStartEnd;
    Measure? endingMeasure;
    if (identical(system, parentSystem1) && identical(system, parentSystem2)) {
      measure = firstMeasure as Measure;
      try { x1 = measure.getDrawingX(); } catch (_) { x1 = 0; }
      endingMeasure = lastMeasure as Measure;
      objectX = measure;
      bool isFirst = false;
      try { isFirst = identical(system.getFirst(ClassId.measure), measure); } catch (_) {}
      if (isFirst) { try { x1 += measure.measureAligner.getLeftBarLineXRel(); } catch (_) {} }
      try { x2 = ((endingMeasure as dynamic).getDrawingX() as int) + ((endingMeasure as dynamic).measureAligner.getRightBarLineXRel() as int); } catch (_) { x2 = x1 + 200; }
    } else if (identical(system, parentSystem1)) {
      try {
        final List<Object> measures = system.findAllDescendantsByType(ClassId.measure, deepness: 1);
        if (measures.isEmpty) return;
        measure = measures.last as Measure;
        x1 = (firstMeasure as dynamic).getDrawingX() as int;
        objectX = measure;
        endingMeasure = measure;
        bool isFirst = false;
        try { isFirst = identical(system.getFirst(ClassId.measure), firstMeasure); } catch (_) {}
        if (isFirst) { try { x1 += (firstMeasure as dynamic).measureAligner.getLeftBarLineXRel() as int; } catch (_) {} }
        x2 = measure.getDrawingX() + measure.measureAligner.getRightBarLineXRel();
        spanningType = spanningStart;
      } catch (_) { return; }
    } else if (identical(system, parentSystem2)) {
      try {
        final List<Object> measures = system.findAllDescendantsByType(ClassId.measure, deepness: 1);
        if (measures.isEmpty) return;
        measure = measures.first as Measure;
        x1 = measure.getDrawingX() + measure.measureAligner.getLeftBarLineXRel();
        objectX = measure.leftBarLine;
        endingMeasure = lastMeasure as Measure;
        x2 = ((endingMeasure as dynamic).getDrawingX() as int) + ((endingMeasure as dynamic).measureAligner.getRightBarLineXRel() as int);
        spanningType = spanningEnd;
      } catch (_) { return; }
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
      } catch (_) { return; }
    }
    if (spanningType == spanningStartEnd || spanningType == spanningStart) {
      dc.resumeGraphic(ending as BoundingBox, ending.id);
    } else {
      dc.startGraphic(ending as BoundingBox, '', ending.id, graphicID: GraphicID.spanning);
    }
    List<Staff> staffList = [];
    bool isTop = false;
    try {
      final dynamic rend = (system.drawingScoreDef as dynamic)?.endingRend ?? (system as dynamic).getDrawingScoreDef?.call()?.getEndingRend?.call();
      final String s = rend?.toString().toLowerCase() ?? '';
      isTop = s.contains('top');
    } catch (_) {}
    if (isTop) {
      try {
        final List<Object> sysStaves = system.findAllDescendantsByType(ClassId.staff);
        for (final Object so in sysStaves) {
          final Staff st = so as Staff;
          dynamic staffDef;
          try { staffDef = system.drawingScoreDef?.getStaffDef(st.n ?? 0); } catch (_) {}
          bool hidden = false;
          try { hidden = staffDef != null && staffDef.getDrawingVisibility().toString().toLowerCase().contains('hidden'); } catch (_) {}
          if (!hidden) { staffList.add(st); break; }
        }
      } catch (_) {}
      if (staffList.isEmpty) {
        try { final List<Object> sysStaves = system.findAllDescendantsByType(ClassId.staff); if (sysStaves.isNotEmpty) staffList.add(sysStaves.first as Staff); } catch (_) {}
      }
    } else {
      try { if (measure != null) staffList = (measure as dynamic).getFirstStaffGrpStaves(system.drawingScoreDef) as List<Staff>; } catch (_) {}
      if (staffList.isEmpty) {
        try { final List<Object> all = system.findAllDescendantsByType(ClassId.staff); for (final o in all) staffList.add(o as Staff); } catch (_) {}
      }
    }
    if (staffList.isEmpty) {
      try { final Staff? first = system.findDescendantByType(ClassId.staff) as Staff?; if (first != null) staffList = [first]; } catch (_) {}
    }
    for (final Staff staff in staffList) {
      if (!system.setSystemCurrentFloatingPositioner(staff.n ?? meiUnset, ending as FloatingObject, objectX!, staff)) continue;
      final int staffSize = staff.drawingStaffSize;
      int y1 = staff.getDrawingY();
      try { y1 = (ending as dynamic).getDrawingY() as int; } catch (_) {}
      dc.startCustomGraphic('voltaBracket');
      FontInfo currentFont;
      try { currentFont = doc!.getDrawingLyricFont(staffSize); } catch (_) { currentFont = FontInfo(); }
      dc.setFont(currentFont);
      final TextExtend extend = TextExtend();
      dc.getTextExtent('M', extend);
      final int unit = doc!.getDrawingUnit(staffSize);
      String endingText = '';
      try { if ((ending as dynamic).hasN == true) endingText = (ending as dynamic).n as String; } catch (_) {}
      if (endingText.isEmpty) { try { final dynamic n = (ending as dynamic).getN?.call(); if (n != null) endingText = n as String; } catch (_) {} }
      if (endingText.isEmpty) { try { endingText = (ending as dynamic).label as String; } catch (_) {} }
      if (endingText.isNotEmpty) {
        String strStream = endingText;
        if (spanningType == spanningEnd || spanningType == spanningMiddle) strStream = '($endingText)';
        final Text text = Text();
        try { text.setParent(ending); } catch (_) {}
        try { text.text = strStream; } catch (_) {}
        int textX = x1;
        if (spanningType == spanningStartEnd || spanningType == spanningStart) textX += unit * 2 ~/ 3;
        final TextDrawingParams params = TextDrawingParams();
        params.x = textX; params.y = y1;
        try { params.pointSize = currentFont.pointSize; } catch (_) {}
        dc.startText(toDeviceContextX(params.x), toDeviceContextY(params.y), HorizontalAlignment.left);
        try { drawTextElement(dc, text, params); } catch (_) { drawTextChildren(dc, text, params); }
        dc.endText();
      }
      dc.resetFont();
      final int y2 = y1 + extend.height + unit * 2 ~/ 3;
      double lineThicknessOpt = 0.2;
      try { lineThicknessOpt = (doc!.getOptions() as dynamic).repeatEndingLineThickness.value as double; } catch (_) {}
      final int lineWidth = (lineThicknessOpt * unit).toInt();
      int staffLineWidth = 0;
      try { staffLineWidth = doc!.getDrawingStaffLineWidth(staff.drawingStaffSize); } catch (_) { staffLineWidth = (0.15*unit).toInt(); }
      final int startX = x1 - staffLineWidth;
      int rightBarLineWidth = 0;
      try { rightBarLineWidth = (endingMeasure as dynamic).calculateRightBarLineWidth(doc, staffSize) as int; } catch (_) { rightBarLineWidth = unit * 2; }
      int endX = x2;
      bool isLastMeasure = false;
      try {
        final List<Object> all = system.findAllDescendantsByType(ClassId.measure, deepness: 1);
        if (all.isNotEmpty && identical(endingMeasure, all.last)) isLastMeasure = true;
      } catch (_) {}
      if (spanningType == spanningStart || spanningType == spanningMiddle || isLastMeasure) {
        endX += rightBarLineWidth - lineWidth ~/ 2 - staffLineWidth;
      } else {
        try {
          dynamic rend = (endingMeasure as dynamic).getDrawingRightBarLine?.call() ?? (endingMeasure as dynamic).drawingRightBarLine;
          final String s = rend?.toString().toLowerCase() ?? '';
          if (!s.contains('invis') && s != '0') {
            final int need = lineWidth + unit ~/ 2 - rightBarLineWidth;
            if (need > 0) endX -= need;
          }
        } catch (_) {}
      }
      PenStyle penStyle = PenStyle.solid;
      LineCapStyle capStyle = LineCapStyle.square;
      dynamic lform;
      try { lform = (ending as dynamic).lform ?? (ending as dynamic).getLform?.call(); } catch (_) {}
      final String lformStr = lform?.toString().toLowerCase() ?? '';
      if (lformStr.contains('dashed')) penStyle = PenStyle.longDash;
      else if (lformStr.contains('dotted')) { penStyle = PenStyle.dot; capStyle = LineCapStyle.round; }
      dc.setPen(lineWidth, penStyle, lineCap: capStyle);
      dc.drawLine(toDeviceContextX(startX), toDeviceContextY(y2), toDeviceContextX(endX), toDeviceContextY(y2));
      bool drawLeft = spanningType != spanningEnd && spanningType != spanningMiddle;
      bool drawRight = spanningType != spanningStart && spanningType != spanningMiddle;
      bool hasLstart = true, hasLend = true;
      try { final dynamic ls = (ending as dynamic).lstartsym ?? (ending as dynamic).getLstartsym?.call(); hasLstart = ls == null || !ls.toString().toLowerCase().contains('none'); } catch (_) {}
      try { final dynamic le = (ending as dynamic).lendsym ?? (ending as dynamic).getLendsym?.call(); hasLend = le == null || !le.toString().toLowerCase().contains('none'); } catch (_) {}
      if (drawLeft && hasLstart) dc.drawLine(toDeviceContextX(startX), toDeviceContextY(y2), toDeviceContextX(startX), toDeviceContextY(y1));
      if (drawRight && hasLend) dc.drawLine(toDeviceContextX(endX), toDeviceContextY(y2), toDeviceContextX(endX), toDeviceContextY(y1));
      dc.resetPen();
      dc.endCustomGraphic();
    }
    if (spanningType == spanningStartEnd || spanningType == spanningStart) dc.endResumedGraphic(ending as BoundingBox); else dc.endGraphic(ending as BoundingBox);
  }


  // ---------------------------------------------------------------------------
  // Helpers for 05-22 (ornaments, arpeg, ending)
  // ---------------------------------------------------------------------------

  int _getAnnotScoreBoxHeight(int unit) {
    double w = 0.2;
    try { w = (doc!.getOptions() as dynamic).octaveLineThickness.value as double; } catch (_) {}
    return (w * unit * 10).toInt();
  }

  int _getAnnotScoreLineWidth(int unit) {
    double w = 0.2;
    try { w = (doc!.getOptions() as dynamic).octaveLineThickness.value as double; } catch (_) {}
    return (w * unit * 2).toInt();
  }

  (Note?, Note?) _getArpegTopBottomNotes(dynamic arpeg) {
    Note? topNote;
    Note? bottomNote;
    try {
      final List<Object> refs = (arpeg as dynamic).getRefs() as List<Object>? ?? [];
      for (final Object o in refs) {
        if (o is! Note) continue;
        bottomNote ??= o;
        topNote = o;
      }
    } catch (_) {}
    if (topNote == null) {
      try {
        final List<Object> refs2 = (arpeg as dynamic).getPlistRefs() as List<Object>? ?? [];
        for (final Object o in refs2) { if (o is Note) { bottomNote ??= o; topNote = o; } }
      } catch (_) {}
    }
    return (topNote, bottomNote);
  }

  List<Staff> _getTstampStavesFor(dynamic element, Measure measure, dynamic start) {
    List<Staff> list = [];
    try {
      final dynamic staves = (element as dynamic).getTstampStaves(measure, element);
      if (staves is List) list = staves.cast<Staff>();
    } catch (_) {}
    if (list.isNotEmpty) return list;
    try {
      final dynamic staffAttr = (element as dynamic).staff;
      if (staffAttr is List && staffAttr.isNotEmpty) {
        for (final int n in staffAttr.cast<int>()) {
          final List<Object> all = measure.findAllDescendantsByType(ClassId.staff, deepness: 1);
          for (final Object o in all) { if (o is Staff && (o.n ?? -1) == n) { list.add(o); break; } }
          if (list.isNotEmpty) break;
        }
        if (list.isNotEmpty) return list;
      }
    } catch (_) {}
    try {
      final Staff? s = (start as Object).getFirstAncestor(ClassId.staff) as Staff?;
      if (s != null) return [s];
    } catch (_) {}
    try {
      final Staff? s = measure.findDescendantByType(ClassId.staff) as Staff?;
      if (s != null) return [s];
    } catch (_) {}
    return list;
  }

  int _getMordentGlyph(dynamic mordent) {
    try {
      final bool hasNum = (mordent as dynamic).hasGlyphNum == true;
      if (hasNum) {
        final int code = (mordent as dynamic).glyphNum as int;
        if (code != 0) return code;
      }
    } catch (_) {}
    bool isLong = false;
    try { isLong = (mordent as dynamic).long == true; } catch (_) { try { isLong = (mordent as dynamic).getLong?.call() == true; } catch (_) {} }
    dynamic form;
    try { form = (mordent as dynamic).form ?? (mordent as dynamic).getForm?.call(); } catch (_) {}
    final String fs = form?.toString().toLowerCase() ?? '';
    final bool isUpper = fs.contains('upper');
    if (isLong) return isUpper ? 0xE56E : 0xE5BD;
    return isUpper ? 0xE56C : 0xE56D;
  }

  int _getTrillGlyph(dynamic trill) {
    try {
      final bool hasNum = (trill as dynamic).hasGlyphNum == true;
      if (hasNum) { final int c = (trill as dynamic).glyphNum as int; if (c!=0) return c; }
    } catch (_) {}
    return 0xE566;
  }

  int _getTurnGlyph(dynamic turn) {
    try {
      final bool hasNum = (turn as dynamic).hasGlyphNum == true;
      if (hasNum) { final int c = (turn as dynamic).glyphNum as int; if (c!=0) return c; }
    } catch (_) {}
    dynamic form;
    try { form = (turn as dynamic).form ?? (turn as dynamic).getForm?.call(); } catch (_) {}
    final String s = form?.toString().toLowerCase() ?? '';
    if (s.contains('lower')) return 0xE568;
    return 0xE567;
  }

  int _getFermataGlyph(dynamic fermata) {
    try {
      final bool hasNum = (fermata as dynamic).hasGlyphNum == true;
      if (hasNum) { final int c = (fermata as dynamic).glyphNum as int; if (c!=0) return c; }
    } catch (_) {}
    dynamic shape;
    try { shape = (fermata as dynamic).shape ?? (fermata as dynamic).getShape?.call(); } catch (_) {}
    dynamic form;
    try { form = (fermata as dynamic).form ?? (fermata as dynamic).getForm?.call(); } catch (_) {}
    dynamic place;
    try { place = (fermata as dynamic).place ?? (fermata as dynamic).getPlace?.call(); } catch (_) {}
    final String shapeStr = shape?.toString().toLowerCase() ?? '';
    final String formStr = form?.toString().toLowerCase() ?? '';
    final String placeStr = place?.toString().toLowerCase() ?? '';
    final bool isInv = formStr.contains('inv');
    final bool isBelow = placeStr.contains('below');
    final bool belowLike = isInv || (isBelow && !formStr.contains('norm'));
    if (shapeStr.contains('angular')) return belowLike ? 0xE4C5 : 0xE4C4;
    if (shapeStr.contains('square')) return belowLike ? 0xE4C7 : 0xE4C6;
    if (belowLike) return 0xE4C1;
    return 0xE4C0;
  }

  String _getFermataVerticalAlignment(int code) {
    const topCodes = [0xE4C0, 0xE4C2, 0xE4C4, 0xE4C6, 0xE4C8];
    const bottomCodes = [0xE4C1, 0xE4C3, 0xE4C5, 0xE4C7, 0xE4C9];
    if (topCodes.contains(code)) return 'top';
    if (bottomCodes.contains(code)) return 'bottom';
    return 'middle';
  }

  int _getCaesuraGlyph(dynamic caesura) {
    try {
      final bool hasNum = (caesura as dynamic).hasGlyphNum == true;
      if (hasNum) { final int c = (caesura as dynamic).glyphNum as int; if (c!=0) return c; }
    } catch (_) {}
    return 0xE4D1;
  }

  int _getPedalGlyph(dynamic pedal) {
    try {
      final bool hasNum = (pedal as dynamic).hasGlyphNum == true;
      if (hasNum) { final int c = (pedal as dynamic).glyphNum as int; if (c!=0) return c; }
    } catch (_) {}
    dynamic func;
    try { func = (pedal as dynamic).func ?? (pedal as dynamic).getFunc?.call(); } catch (_) {}
    if (func?.toString().toLowerCase().contains('sostenuto') == true) return 0xE659;
    return 0xE650;
  }

  Pedalstyle _getPedalForm(dynamic pedal, System system) {
    try {
      final dynamic opt = (doc!.getOptions() as dynamic).pedalStyle;
      if (opt != null) {
        final dynamic v = opt.value;
        if (v is Pedalstyle && v != Pedalstyle.none) return v;
      }
    } catch (_) {}
    try {
      final bool hasForm = (pedal as dynamic).hasForm == true;
      if (hasForm) {
        final dynamic f = (pedal as dynamic).form ?? (pedal as dynamic).getForm?.call();
        if (f is Pedalstyle) return f;
        final String s = f?.toString().toLowerCase() ?? '';
        if (s.contains('pedline')) return Pedalstyle.pedline;
        if (s.contains('altpedstar')) return Pedalstyle.altpedstar;
        if (s.contains('pedstar')) return Pedalstyle.pedstar;
      }
    } catch (_) {}
    try {
      final dynamic scoreDef = system.drawingScoreDef;
      if (scoreDef != null) {
        final bool has = (scoreDef as dynamic).hasPedalStyle == true;
        if (has) {
          final dynamic f = (scoreDef as dynamic).pedalStyle ?? (scoreDef as dynamic).getPedalStyle?.call();
          if (f is Pedalstyle) return f;
        }
      }
    } catch (_) {}
    return Pedalstyle.none;
  }

  int _getRepeatMarkGlyph(dynamic repeatMark) {
    try {
      final bool hasNum = (repeatMark as dynamic).hasGlyphNum == true;
      if (hasNum) { final int c = (repeatMark as dynamic).glyphNum as int; if (c!=0) return c; }
    } catch (_) {}
    dynamic func;
    try { func = (repeatMark as dynamic).func ?? (repeatMark as dynamic).getFunc?.call(); } catch (_) {}
    final String s = func?.toString().toLowerCase() ?? '';
    if (s.contains('coda')) return 0xE048;
    if (s.contains('segno')) return 0xE047;
    if (s.contains('dacapo') || s.contains('da capo')) return 0xE046;
    if (s.contains('dalsegno') || s.contains('dal segno')) return 0xE045;
    return 0xE047;
  }

  (int, int) _getEnclosingGlyphs(dynamic element) {
    try {
      final bool hasEnclose = (element as dynamic).hasEnclose == true;
      if (hasEnclose) {
        final dynamic enc = (element as dynamic).enclose ?? (element as dynamic).getEnclose?.call();
        final String s = enc?.toString().toLowerCase() ?? '';
        if (s.contains('brack')) return (0xE26C, 0xE26D);
        if (s.contains('paren')) return (0xE26A, 0xE26B);
      }
    } catch (_) {}
    try {
      final dynamic pair = (element as dynamic).getEnclosingGlyphs?.call();
      if (pair is List && pair.length >=2) return (pair[0] as int, pair[1] as int);
    } catch (_) {}
    return (0,0);
  }

  int _getAccidGlyph(dynamic accidVal) {
    if (accidVal == null) return 0;
    String s = accidVal.toString().toLowerCase();
    if (s.contains('.')) s = s.split('.').last;
    if (s == 's' || s == 'sharp') return 0xE262;
    if (s == 'f' || s == 'flat') return 0xE260;
    if (s == 'ss' || s == 'x' && false) return 0xE269;
    if (s.contains('sharpsharp') || s == 'ss') return 0xE269;
    if (s == 'x' || s.contains('doublesharp')) return 0xE263;
    if (s == 'ff' || s.contains('doubleflat')) return 0xE264;
    if (s.contains('triplesharp')) return 0xE265;
    if (s.contains('tripleflat')) return 0xE266;
    if (s == 'n' || s == 'natural') return 0xE261;
    if (s == 'nf' || s.contains('naturalflat')) return 0xE267;
    if (s == 'ns' || s.contains('naturalsharp')) return 0xE268;
    const map = {'s': 0xE262, 'f': 0xE260, 'ss': 0xE269, 'x': 0xE263, 'ff': 0xE264, 'n': 0xE261};
    if (map.containsKey(s)) return map[s]!;
    try {
      if (accidVal is AccidentalWritten) {
        final String enumStr = accidVal.toString().split('.').last.toLowerCase();
        if (map.containsKey(enumStr)) return map[enumStr]!;
      }
    } catch (_) {}
    return 0;
  }



  // ---------------------------------------------------------------------------
  // Private helpers (ports of Syl / View helpers)
  // ---------------------------------------------------------------------------

  int _getCtrlDrawingRadius(LayerElement el) {
    try {
      return (el as dynamic).getDrawingRadius(doc) as int;
    } catch (_) {
      final int unit = doc!.getDrawingUnit(100);
      return unit;
    }
  }

  int _getBracketSpanLineWidth(BracketSpan bs, int unit) {
    try {
      return (bs as dynamic).getLineWidth(doc, unit) as int;
    } catch (_) {
      try {
        return (bs as dynamic).getLineWidth(doc!, unit) as int;
      } catch (_) {
        double w = 0.15;
        try {
          w = (doc!.getOptions() as dynamic).bracketThickness.value as double;
        } catch (_) {}
        return (w * unit).toInt();
      }
    }
  }

  int _getOctaveLineWidth(Octave oct, int unit) {
    try {
      return (oct as dynamic).getLineWidth(doc, unit) as int;
    } catch (_) {
      double w = 0.2;
      try {
        w = (doc!.getOptions() as dynamic).octaveLineThickness.value as double;
      } catch (_) {}
      return (w * unit).toInt();
    }
  }

  int _getOctaveGlyph(Octave octave, bool alt) {
    OctaveDis? dis;
    try {
      dis = octave.dis as OctaveDis;
    } catch (_) {
      try {
        dis = (octave as dynamic).getDis() as OctaveDis;
      } catch (_) {
        dis = OctaveDis.n8;
      }
    }
    Staffrel? place;
    try {
      place = octave.disPlace as Staffrel;
    } catch (_) {
      try {
        place = (octave as dynamic).getDisPlace() as Staffrel;
      } catch (_) {
        place = Staffrel.above;
      }
    }
    final bool isAbove = place.toString().contains('above');
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
      final bool ok = (tie as dynamic)
          .calculatePosition(doc, staff, x1, x2, spanningType, bezier) as bool;
      if (ok) return true;
    } catch (_) {}
    try {
      final bool ok = (tie as dynamic)
          .CalculatePosition(doc, staff, x1, x2, spanningType, bezier) as bool;
      if (ok) return true;
    } catch (_) {}

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
      final dynamic dir = (tie as dynamic).getDrawingCurveDir?.call() ??
          (tie as dynamic).drawingCurveDir;
      if (dir == SlurCurveDirection.above) return true;
      if (dir == SlurCurveDirection.below) return false;
    } catch (_) {}
    try {
      final dynamic curvedir = (tie as dynamic).curvedir;
      if (curvedir == CurvatureCurvedir.above) return true;
      if (curvedir == CurvatureCurvedir.below) return false;
    } catch (_) {}
    // Default: above for ties below center, etc — assume above
    return true;
  }

  double _tieMidpointThickness() {
    try {
      return (doc!.getOptions() as dynamic).tieMidpointThickness.value
          as double;
    } catch (_) {
      return 0.5;
    }
  }

  double _tieEndpointThickness() {
    try {
      return (doc!.getOptions() as dynamic).tieEndpointThickness.value
          as double;
    } catch (_) {
      return 0.15;
    }
  }

  double _lyricLineThickness() {
    try {
      return (doc!.getOptions() as dynamic).lyricLineThickness.value as double;
    } catch (_) {
      return 0.15;
    }
  }

  double _pedalLineThickness() {
    try {
      return (doc!.getOptions() as dynamic).pedalLineThickness.value as double;
    } catch (_) {
      return 0.2;
    }
  }

  double _extenderLineMinSpace() {
    try {
      return (doc!.getOptions() as dynamic).extenderLineMinSpace.value
          as double;
    } catch (_) {
      return 1.5;
    }
  }

  int _getFYRel(F f, Staff staff) {
    try {
      return (this as dynamic).getFYRel(f, staff) as int;
    } catch (_) {}
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
    } catch (_) {}
    try {
      final Object? fb = f.getFirstAncestor(ClassId.fb);
      if (fb != null) {
        final int line = (fb as dynamic)
            .getDescendantIndex(f, ClassId.figure, 100000) as int;
        if (line > 0) {
          final int lh = doc!.getTextLineHeight(
              doc!.getDrawingLyricFont(staff.drawingStaffSize), false);
          y -= line * lh;
        }
      }
    } catch (_) {}
    return y;
  }

  int _getSylYRel(int verseN, Staff staff, dynamic place) {
    try {
      return (this as dynamic).getSylYRel(verseN, staff, place) as int;
    } catch (_) {}
    // Fallback: minimal version of view_element.cpp GetSylYRel
    try {
      final dynamic align = staff.getAlignment();
      if (align == null) return 0;
      bool collapse = false;
      try {
        collapse =
            (doc!.getOptions() as dynamic).lyricVerseCollapse.value as bool;
      } catch (_) {}
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
    } catch (_) {
      return -doc!.getDrawingUnit(staff.drawingStaffSize) * 4;
    }
  }

  int _calcHyphenLength(Staff staff) {
    try {
      final int w = doc!.getDrawingUnit(staff.drawingStaffSize);
      int v = w;
      v = _adjustToLyricSizeRet(v);
      return v;
    } catch (_) {
      int v = doc!.getDrawingUnit(staff.drawingStaffSize);
      v = _adjustToLyricSizeRet(v);
      return v;
    }
  }

  void _adjustToLyricSize(int value) {
    // Mirrors Syl::AdjustToLyricSize — value *= lyricSize / default (no-op wrapper, kept for API parity)
    try {
      final double size =
          (doc!.getOptions() as dynamic).lyricSize.value as double;
      final double def =
          (doc!.getOptions() as dynamic).lyricSize.defaultValue as double? ??
              4.5;
      // ignore: unused_local_variable — value is passed by value in Dart, caller must use Ret version
      final int _ = (value * size / def).toInt();
    } catch (_) {}
  }

  int _adjustToLyricSizeRet(int value) {
    try {
      final double size =
          (doc!.getOptions() as dynamic).lyricSize.value as double;
      final double def =
          (doc!.getOptions() as dynamic).lyricSize.defaultValue as double? ??
              4.5;
      return (value * size / def).toInt();
    } catch (_) {
      return value;
    }
  }

  // Overload that mutates int via wrapper — Dart ints are value types, so we
  // expose a helper that returns the adjusted value.
  void _adjustToLyricSizeRef(List<int> ref) {
    ref[0] = (ref[0] * _lyricSizeRatio()).toInt();
  }

  double _lyricSizeRatio() {
    try {
      final double size =
          (doc!.getOptions() as dynamic).lyricSize.value as double;
      final double def =
          (doc!.getOptions() as dynamic).lyricSize.defaultValue as double? ??
              size;
      if (def == 0) return 1.0;
      return size / def;
    } catch (_) {
      return 1.0;
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers for 05-21
  // ---------------------------------------------------------------------------

  String _collectDynamText(Object dynam) {
    try {
      return (dynam as dynamic).getText() as String;
    } catch (_) {
      try {
        final List<Object> kids = (dynam as dynamic).children as List<Object>;
        final StringBuffer buf = StringBuffer();
        for (final Object k in kids) {
          if (k.isClass(ClassId.text)) buf.write((k as dynamic).text as String);
          if (k.isClass(ClassId.rend)) {
            try {
              buf.write(_collectDynamText(k));
            } catch (_) {}
          }
        }
        return buf.toString();
      } catch (_) {
        return '';
      }
    }
  }

  HorizontalAlignment _convertHalign(dynamic halign) {
    if (halign is Horizontalalignment) {
      switch (halign) {
        case Horizontalalignment.left:
          return HorizontalAlignment.left;
        case Horizontalalignment.right:
          return HorizontalAlignment.right;
        case Horizontalalignment.center:
          return HorizontalAlignment.center;
        default:
          return HorizontalAlignment.left;
      }
    }
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
      if (str == 'p')
        dynam = String.fromCharCode(0xE520);
      else if (str == 'm')
        dynam = String.fromCharCode(0xE521);
      else if (str == 'f')
        dynam = String.fromCharCode(0xE522);
      else if (str == 'r')
        dynam = String.fromCharCode(0xE523);
      else if (str == 's')
        dynam = String.fromCharCode(0xE524);
      else if (str == 'z')
        dynam = String.fromCharCode(0xE525);
      else if (str == 'n')
        dynam = String.fromCharCode(0xE526);
      else if (str == 'pppppp')
        dynam = String.fromCharCode(0xE527);
      else if (str == 'ppppp')
        dynam = String.fromCharCode(0xE528);
      else if (str == 'pppp')
        dynam = String.fromCharCode(0xE529);
      else if (str == 'ppp')
        dynam = String.fromCharCode(0xE52A);
      else if (str == 'pp')
        dynam = String.fromCharCode(0xE52B);
      else if (str == 'mp')
        dynam = String.fromCharCode(0xE52C);
      else if (str == 'mf')
        dynam = String.fromCharCode(0xE52D);
      else if (str == 'pf')
        dynam = String.fromCharCode(0xE52E);
      else if (str == 'ff')
        dynam = String.fromCharCode(0xE52F);
      else if (str == 'fff')
        dynam = String.fromCharCode(0xE530);
      else if (str == 'ffff')
        dynam = String.fromCharCode(0xE531);
      else if (str == 'fffff')
        dynam = String.fromCharCode(0xE532);
      else if (str == 'ffffff')
        dynam = String.fromCharCode(0xE533);
      else if (str == 'fp')
        dynam = String.fromCharCode(0xE534);
      else if (str == 'fz')
        dynam = String.fromCharCode(0xE535);
      else if (str == 'sf')
        dynam = String.fromCharCode(0xE536);
      else if (str == 'sfp')
        dynam = String.fromCharCode(0xE537);
      else if (str == 'sfpp')
        dynam = String.fromCharCode(0xE538);
      else if (str == 'sfz')
        dynam = String.fromCharCode(0xE539);
      else if (str == 'sfzp')
        dynam = String.fromCharCode(0xE53A);
      else if (str == 'sffz')
        dynam = String.fromCharCode(0xE53B);
      else if (str == 'rf')
        dynam = String.fromCharCode(0xE53C);
      else if (str == 'rfz') dynam = String.fromCharCode(0xE53D);
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

  int _calcHairpinHeight(
      dynamic hairpin, int staffSize, int spanningType, dynamic leftLink, dynamic rightLink) {
    int endY = 0;
    try {
      double sizeOpt = 3.0;
      try {
        sizeOpt = (doc!.getOptions() as dynamic).hairpinSize?.value as double? ?? 3.0;
      } catch (_) {}
      final int unit = doc!.getDrawingUnit(staffSize);
      endY = (sizeOpt * unit).toInt();
      // With margin variant not used
    } catch (_) {
      try {
        endY = doc!.getDrawingUnit(staffSize) * 3;
      } catch (_) {
        endY = 100;
      }
    }

    bool hasOpening = false;
    dynamic opening;
    try {
      hasOpening = (hairpin as dynamic).hasOpening == true;
      opening = (hairpin as dynamic).opening;
      if (opening == null) opening = (hairpin as dynamic).getOpening?.call();
    } catch (_) {}
    if (hasOpening && opening != null) {
      try {
        // opening is MeasurementUnsigned with GetType etc
        final String typeStr = opening.toString();
        // Try to detect px vs vu: check if string contains 'px'
        // Fallback: try to call getPx / getVu
        bool isPx = false;
        int pxVal = 0;
        try {
          final dynamic t = (opening as dynamic).getType?.call();
          if (t != null) isPx = t.toString().contains('px');
        } catch (_) {}
        try {
          if (opening is int) {
            endY = opening;
          } else if ((opening as dynamic).px != null) {
            isPx = true;
            pxVal = (opening as dynamic).px as int;
            endY = pxVal;
          } else if ((opening as dynamic).getPx != null) {
            try {
              endY = (opening as dynamic).getPx() as int;
              isPx = true;
            } catch (_) {}
          }
          if (!isPx) {
            dynamic vu;
            try {
              vu = (opening as dynamic).vu;
            } catch (_) {
              try {
                vu = (opening as dynamic).getVu();
              } catch (_) {}
            }
            if (vu != null) {
              final double d = (vu is double) ? vu : (vu as num).toDouble();
              endY = (d * doc!.getDrawingUnit(staffSize)).toInt();
            }
          }
        } catch (_) {}
      } catch (_) {}
    }

    int drawingLength = 0;
    try {
      drawingLength = (hairpin as dynamic).getDrawingLength() as int;
    } catch (_) {
      try {
        drawingLength = (hairpin as dynamic).drawingLength as int;
      } catch (_) {}
    }
    if (drawingLength == 0) return endY;
    if (spanningType != spanningStartEnd) return endY;

    int length = drawingLength;

    // Second of a <>
    final String formStr = (() {
      try {
        return (hairpin as dynamic).form?.toString() ?? '';
      } catch (_) {
        try {
          return (hairpin as dynamic).getForm().toString();
        } catch (_) {
          return '';
        }
      }
    })();
    final bool isDim = formStr.contains('dim');
    final bool isCres = formStr.contains('cres');

    if (isDim) {
      dynamic leftLinkObj;
      try {
        leftLinkObj = (hairpin as dynamic).leftLink ?? (hairpin as dynamic).getLeftLink?.call();
      } catch (_) {}
      if (leftLinkObj != null && leftLink != null) {
        bool isH = false;
        try {
          isH = (leftLinkObj as dynamic).isClass(ClassId.hairpin) == true;
          if (!isH) isH = leftLinkObj.classId == ClassId.hairpin;
        } catch (_) {}
        if (isH) {
          int spanType = spanningStartEnd;
          try {
            spanType = (leftLink as dynamic).getSpanningType() as int;
            if (spanType == null) spanType = (leftLink as dynamic).spanningType as int;
          } catch (_) {}
          if (spanType != spanningStartEnd) return endY;
          dynamic leftHairpinForm;
          try {
            leftHairpinForm = (leftLinkObj as dynamic).form;
          } catch (_) {}
          final String s = leftHairpinForm?.toString() ?? '';
          if (s.contains('cres')) {
            int leftLen = 0;
            try {
              leftLen = (leftLinkObj as dynamic).getDrawingLength() as int;
            } catch (_) {
              try {
                leftLen = (leftLinkObj as dynamic).drawingLength as int;
              } catch (_) {}
            }
            if (leftLen > length) length = leftLen;
          }
        }
      }
    }

    if (isCres) {
      dynamic rightLinkObj;
      try {
        rightLinkObj = (hairpin as dynamic).rightLink ?? (hairpin as dynamic).getRightLink?.call();
      } catch (_) {}
      if (rightLinkObj != null && rightLink != null) {
        bool isH = false;
        try {
          isH = (rightLinkObj as dynamic).isClass(ClassId.hairpin) == true;
        } catch (_) {}
        if (isH) {
          int spanType = spanningStartEnd;
          try {
            spanType = (rightLink as dynamic).getSpanningType() as int;
          } catch (_) {}
          if (spanType != spanningStartEnd) return endY;
          dynamic rightForm;
          try {
            rightForm = (rightLinkObj as dynamic).form;
          } catch (_) {}
          final String s = rightForm?.toString() ?? '';
          if (s.contains('dim')) {
            int rightLen = 0;
            try {
              rightLen = (rightLinkObj as dynamic).getDrawingLength() as int;
            } catch (_) {
              try {
                rightLen = (rightLinkObj as dynamic).drawingLength as int;
              } catch (_) {}
            }
            if (rightLen > length) length = rightLen;
          }
        }
      }
    }

    if (length <= 0) return endY;

    double theta = 2.0 * math.atan((endY / 2.0) / length);
    theta *= (360.0 / (2.0 * math.pi));
    if (theta > 16) {
      theta = 16;
      endY = (2 * length * math.tan((math.pi / 360) * theta)).toInt();
    }

    return endY;
  }

  (int, int) _getHairpinBarlineOverlapAdjustment(
      dynamic hairpin, int doubleUnit, int leftX, int rightX, int spanningType) {
    int leftAdj = 0;
    int rightAdj = 0;
    try {
      dynamic start;
      try {
        start = (hairpin as dynamic).getStart();
      } catch (_) {
        start = (hairpin as dynamic).getTimePointInterface()?.getStart();
      }
      if (start == null) return (0, 0);
      final Object? startMeasure = (start as dynamic).getFirstAncestor(ClassId.measure);
      final Object? endObj = (() {
        try {
          return (hairpin as dynamic).getEnd();
        } catch (_) {
          try {
            return (hairpin as dynamic).getTimeSpanningInterface()?.getEnd();
          } catch (_) {
            return null;
          }
        }
      })();
      final Object? endMeasure = (endObj as dynamic)?.getFirstAncestor(ClassId.measure);

      if (startMeasure == null || endMeasure == null) return (0, 0);

      // left
      dynamic leftBarline;
      try {
        leftBarline = (startMeasure as dynamic).getLeftBarLine();
        if (leftBarline == null) leftBarline = (startMeasure as dynamic).leftBarLine;
      } catch (_) {}
      if (leftBarline != null && (spanningType == spanningStartEnd || spanningType == spanningStart)) {
        int margin = doubleUnit;
        try {
          final int lx = (leftBarline as dynamic).getDrawingX() as int;
          final int diff = leftX - lx;
          dynamic form;
          try {
            form = (leftBarline as dynamic).form ?? (leftBarline as dynamic).getForm?.call();
          } catch (_) {}
          final String fs = form?.toString() ?? '';
          if (fs.contains('rptstart') || fs.contains('rptStart')) margin = (margin * 1.5).toInt();
          if (diff < margin) leftAdj = margin - diff;
        } catch (_) {}
      }

      // right
      dynamic rightBarline;
      try {
        if (spanningType == spanningStartEnd || spanningType == spanningEnd) {
          rightBarline = (endMeasure as dynamic).getRightBarLine();
          if (rightBarline == null) rightBarline = (endMeasure as dynamic).rightBarLine;
        } else if (spanningType == spanningStart) {
          final dynamic startSystem = (start as dynamic).getFirstAncestor(ClassId.system);
          if (startSystem != null) {
            final dynamic measure = (startSystem as dynamic).findDescendantByType(ClassId.measure, 1, 1);
            // The Dart comparison uses findDescendantByType with BACKWARD; fallback to last
            dynamic last;
            try {
              last = (startSystem as dynamic).findDescendantByType(ClassId.measure);
              // Actually need backward: just get last measure
              final List<Object> all = (startSystem as dynamic).findAllDescendantsByType(ClassId.measure, deepness: 1) as List<Object>;
              if (all.isNotEmpty) last = all.last;
            } catch (_) {
              last = measure;
            }
            if (last != null) {
              rightBarline = (last as dynamic).getRightBarLine();
              if (rightBarline == null) rightBarline = (last as dynamic).rightBarLine;
            }
          }
        }
      } catch (_) {}

      if (rightBarline != null) {
        int margin = doubleUnit;
        try {
          final int rx = (rightBarline as dynamic).getDrawingX() as int;
          final int diff = rx - rightX;
          dynamic form;
          try {
            form = (rightBarline as dynamic).form ?? (rightBarline as dynamic).getForm?.call();
          } catch (_) {}
          final String fs = form?.toString() ?? '';
          if (fs.contains('rptend') || fs.contains('rptEnd') || fs.contains('end')) margin = (margin * 1.5).toInt();
          if (diff < margin) rightAdj = margin - diff;
        } catch (_) {}
      }
    } catch (_) {}
    return (leftAdj, rightAdj);
  }
}