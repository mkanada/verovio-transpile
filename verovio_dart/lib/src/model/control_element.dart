/// Port of `controlelement.h/cpp` — base class for control elements
/// (slurs, hairpins, dynamics, directions…).
library;

import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/model/atts/atts_shared.dart';
import 'package:verovio_dart/src/model/atts/atts_usersymbols.dart';
import 'package:verovio_dart/src/model/atts/mei_enums.dart' show Horizontalalignment;
import 'package:verovio_dart/src/model/floating_object.dart';
import 'package:verovio_dart/src/model/interfaces/linking_interface.dart';
import 'package:verovio_dart/src/model/interfaces/simple_interfaces.dart';
import 'package:verovio_dart/src/model/misc_elements_gen.dart' show Rend;

/// Mirrors `vrv::ControlElement`.
class ControlElement extends FloatingObject
    with
        AttAltSym,
        AttLinking,
        AttVisualOffsetHo,
        AttVisualOffsetVo,
        AttColor,
        AttLabelled,
        AttTyped,
        AltSymInterface,
        LinkingInterface,
        OffsetInterface {
  ControlElement([ClassId classId = ClassId.controlElement]) {
    _init(classId);
  }

  void _init(ClassId classId) {
    assignClassId(classId);
    reset();
  }

  @override
  String get className => '[MISSING]';

  @override
  void reset() {
    super.reset();
    altsym = null;
    next = null;
    sameas = null;
    corresp = null;
    copyof = null;
    ho = null;
    vo = null;
    color = null;
    label = null;
    type = null;

    // Register the interfaces for `hasInterface` lookups (mirrors the C++
    // RegisterInterface calls performed by the interface constructors).
    registerInterfaces([
      InterfaceId.altSym,
      InterfaceId.linking,
      InterfaceId.offset,
    ]);
  }

  @override
  bool isSupportedChild(ClassId classId) {
    logDebug('Method for adding $classId to $className should be overridden');
    return false;
  }

  /// Mirrors `ControlElement::GetChildRendAlignment` (controlelement.cpp:75):
  /// the `@halign` of the first descendant `<rend>`, or `none` when there is
  /// none or it does not carry `@halign`.
  Horizontalalignment getChildRendAlignment() {
    final Object? rend = findDescendantByType(ClassId.rend);
    if (rend == null || !(rend as Rend).hasHalign) {
      return Horizontalalignment.none;
    }
    return rend.halign!;
  }
}
