/// Port of `StaffDefDrawingInterface` from drawinginterface.h/cpp.
///
/// Holds the current clef/keySig/mensur/meterSig values used for drawing,
/// together with the drawing flags and the ossia staffDefs.
library;

import 'package:verovio_dart/src/model/basic_elements.dart' show Clef;
import 'package:verovio_dart/src/model/atts/mei_enums.dart'
    show MetersiggrplogFunc;
import 'package:verovio_dart/src/model/layer_elements_gen.dart'
    show KeySig, MeterSig, MeterSigGrp, Proport;
import 'package:verovio_dart/src/model/mensur.dart' show Mensur;
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/model/scoredef.dart' show StaffDef;

/// Mirrors `vrv::StaffDefDrawingInterface`.
mixin StaffDefDrawingInterface {
  // The current clef / key signature / mensur / meter signature values.
  // These are clones of element or attribute values (mirrors
  // m_currentClef, m_currentKeySig, m_currentMensur, m_currentMeterSig,
  // m_currentMeterSigGrp and m_currentProport).
  final Clef _currentClef = Clef();
  final KeySig _currentKeySig = KeySig();
  final Mensur _currentMensur = Mensur();
  final MeterSig _currentMeterSig = MeterSig();
  final MeterSigGrp _currentMeterSigGrp = MeterSigGrp();
  final Proport _currentProport = Proport();

  /// Flags indicating whether the clef, keysig and mensur need to be drawn.
  bool _drawClef = false;
  bool _drawKeySig = false;
  bool _drawMensur = false;
  bool _drawMeterSig = false;
  bool _drawMeterSigGrp = false;

  /// Lists of ossia staffDefs above and below (owned by the interface).
  /// Mirrors `std::list<StaffDef *> m_ossiasAbove` / `m_ossiasBelow` in
  /// `drawinginterface.h` (used via `staffdef.h`).
  final List<StaffDef> ossiasAbove = [];
  final List<StaffDef> ossiasBelow = [];

  /// Copy the whole drawing state of [other] onto this interface (part of
  /// the implicit member copy performed by the C++ `operator=`; required so
  /// that copies of staffDefs keep their draw flags and current values).
  void copyDrawingStateFrom(StaffDefDrawingInterface other) {
    _currentClef.copyFrom(other._currentClef);
    _currentKeySig.copyFrom(other._currentKeySig);
    _currentMensur.copyFrom(other._currentMensur);
    _currentMeterSig.copyFrom(other._currentMeterSig);
    _currentMeterSigGrp.copyFrom(other._currentMeterSigGrp);
    _currentProport.copyFrom(other._currentProport);

    _drawClef = other._drawClef;
    _drawKeySig = other._drawKeySig;
    _drawMensur = other._drawMensur;
    _drawMeterSig = other._drawMeterSig;
    _drawMeterSigGrp = other._drawMeterSigGrp;

    ossiasAbove
      ..clear()
      ..addAll(other.ossiasAbove);
    ossiasBelow
      ..clear()
      ..addAll(other.ossiasBelow);
  }

  /// Mirrors `StaffDefDrawingInterface::Reset`.
  void resetStaffDefDrawingInterface() {
    _currentClef.reset();
    _currentKeySig.reset();
    _currentMensur.reset();
    _currentMeterSig.reset();
    _currentMeterSigGrp.reset();
    _currentProport.reset();

    _drawClef = false;
    _drawKeySig = false;
    _drawMensur = false;
    _drawMeterSig = false;
    _drawMeterSigGrp = false;

    resetOssiaStaffDefs();
  }

  /// Clear the ossia staffDef lists (mirrors `ResetOssiaStaffDefs`).
  void resetOssiaStaffDefs() {
    ossiasAbove.clear();
    ossiasBelow.clear();
  }

  // -------------------------------------------------------------------------
  // Drawing flags
  // -------------------------------------------------------------------------

  bool drawClef() => _drawClef && _currentClef.hasShape;
  void setDrawClef(bool drawClef) => _drawClef = drawClef;

  bool drawKeySig() => _drawKeySig;
  void setDrawKeySig(bool drawKeySig) => _drawKeySig = drawKeySig;

  bool drawMensur() =>
      _drawMensur && (_currentMensur.hasSign || _currentMensur.hasNum);
  void setDrawMensur(bool drawMensur) => _drawMensur = drawMensur;

  bool drawMeterSig() =>
      _drawMeterSig && (_currentMeterSig.hasUnit || _currentMeterSig.hasSym);
  void setDrawMeterSig(bool drawMeterSig) => _drawMeterSig = drawMeterSig;

  bool drawMeterSigGrp() {
    if (_drawMeterSigGrp) {
      final int childListSize = _currentMeterSigGrp.getListSize();
      if (childListSize > 1) return true;
    }
    return false;
  }

  void setDrawMeterSigGrp(bool drawMeterSigGrp) =>
      _drawMeterSigGrp = drawMeterSigGrp;

  // -------------------------------------------------------------------------
  // Current value setters / getters
  // -------------------------------------------------------------------------

  void setCurrentClef(Clef? clef) {
    if (clef != null) {
      final copy = clef.clone() as Clef;
      copy.cloneReset();
      _currentClef.copyFrom(copy);
    }
  }

  void setCurrentKeySig(KeySig? keySig) {
    if (keySig != null) {
      final bool ignoreCancel = _currentKeySig.hasNonAttribKeyAccidChildren() ||
          keySig.hasNonAttribKeyAccidChildren();
      final int drawingCancelAccidCount = _currentKeySig.getAccidCount();
      final drawingCancelAccidType = _currentKeySig.getAccidType();

      final copy = keySig.clone() as KeySig;
      copy.cloneReset();
      _currentKeySig.copyFrom(copy);

      if (ignoreCancel) {
        _currentKeySig.skipCancellation = true;
      } else {
        _currentKeySig.drawingCancelAccidCount = drawingCancelAccidCount;
        _currentKeySig.drawingCancelAccidType = drawingCancelAccidType;
      }
    }
  }

  void setCurrentMensur(Mensur? mensur) {
    if (mensur != null) {
      final copy = mensur.clone() as Mensur;
      copy.cloneReset();
      _currentMensur.copyFrom(copy);
    }
  }

  void setCurrentMeterSig(MeterSig? meterSig) {
    if (meterSig != null) {
      final copy = meterSig.clone() as MeterSig;
      copy.cloneReset();
      _currentMeterSig.copyFrom(copy);
    }
  }

  void setCurrentMeterSigGrp(MeterSigGrp? meterSigGrp) {
    if (meterSigGrp != null) {
      final copy = meterSigGrp.clone() as MeterSigGrp;
      copy.cloneReset();
      _currentMeterSigGrp.copyFrom(copy);
    }
  }

  void setCurrentProport(Proport? proport) {
    if (proport != null) {
      final copy = proport.clone() as Proport;
      copy.cloneReset();
      _currentProport.copyFrom(copy);
    }
  }

  Clef getCurrentClef() => _currentClef;
  KeySig getCurrentKeySig() => _currentKeySig;
  Mensur getCurrentMensur() => _currentMensur;
  MeterSig getCurrentMeterSig() => _currentMeterSig;
  MeterSigGrp getCurrentMeterSigGrp() => _currentMeterSigGrp;
  Proport getCurrentProport() => _currentProport;

  /// Alternate the current meterSig when the group is alternating (mirrors
  /// `AlternateCurrentMeterSig`). [measure] may be any measure object.
  void alternateCurrentMeterSig(Object? measure) {
    if (_currentMeterSigGrp.func == MetersiggrplogFunc.alternating) {
      if (measure != null) {
        _currentMeterSigGrp.setMeasureBasedCount(measure);
      }
      final MeterSig? meter = _currentMeterSigGrp.getSimplifiedMeterSig();
      setCurrentMeterSig(meter);
    }
  }

  // -------------------------------------------------------------------------
  // Ossia staffDefs
  // -------------------------------------------------------------------------

  /// Add an ossia staffDef above (ownership is taken by the interface).
  /// Mirrors `StaffDefDrawingInterface::AddOssiaAbove(StaffDef *)`.
  void addOssiaAbove(StaffDef ossiaStaffDef) => ossiasAbove.add(ossiaStaffDef);

  /// Add an ossia staffDef below (ownership is taken by the interface).
  /// Mirrors `StaffDefDrawingInterface::AddOssiaBelow(StaffDef *)`.
  void addOssiaBelow(StaffDef ossiaStaffDef) => ossiasBelow.add(ossiaStaffDef);

  /// Return the ossia staffDef with number [staffN] (null if not found).
  /// Mirrors `StaffDefDrawingInterface::GetOssiaStaffDef(int) const`.
  StaffDef? getOssiaStaffDef(int staffN) {
    for (final StaffDef ossia in ossiasAbove) {
      if (ossia.n == staffN) return ossia;
    }
    for (final StaffDef ossia in ossiasBelow) {
      if (ossia.n == staffN) return ossia;
    }
    return null;
  }

  /// Append the @n of the ossias above to [staffNs].
  /// Mirrors `StaffDefDrawingInterface::GetOssiaAboveNs`.
  void getOssiaAboveNs(List<int> staffNs) {
    for (final StaffDef ossia in ossiasAbove) {
      staffNs.add(ossia.n ?? 0);
    }
  }

  /// Append the @n of the ossias below to [staffNs].
  /// Mirrors `StaffDefDrawingInterface::GetOssiaBelowNs`.
  void getOssiaBelowNs(List<int> staffNs) {
    for (final StaffDef ossia in ossiasBelow) {
      staffNs.add(ossia.n ?? 0);
    }
  }
}
