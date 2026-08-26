/// Port of `mensur.h/cpp` — the MEI `<mensur>` element.
///
/// The mensur stores the mensural notation parameters (@sign, @num/@numbase,
/// @modus…). It appears as child of scoreDef/staffDef (as attribute-like
/// element) or within a layer.
library;

import 'package:verovio_dart/src/model/atts/atts_mensural.dart';
import 'package:verovio_dart/src/model/atts/atts_shared.dart';
import 'package:verovio_dart/src/model/atts/atts_visual.dart';
import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/model/interfaces/duration_interface.dart'
    show MensurValues;
import 'package:verovio_dart/src/model/layer_element.dart';
import 'package:verovio_dart/src/model/object.dart';

/// Mirrors `vrv::Mensur`.
class Mensur extends LayerElement
    with
        AttColor,
        AttCue,
        AttDurationRatio,
        AttMensuralShared,
        AttMensurVis,
        AttSlashCount,
        AttStaffLoc
    implements MensurValues {
  Mensur() : super(ClassId.mensur) {
    reset();
  }

  //----------------//
  // Static members //
  //----------------//

  /// Static member for setting a value from a controller (mirrors `s_num`).
  static const int sNum = 3;

  /// Static member for setting a value from a controller (mirrors
  /// `s_numBase`).
  static const int sNumBase = 2;

  @override
  ClassId get classId => ClassId.mensur;

  @override
  String get className => 'mensur';

  @override
  Object clone() {
    final copy = Mensur();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Mensur other) {
    super.copyFrom(other);
    copyAttColor(other);
    copyAttCue(other);
    copyAttDurationRatio(other);
    copyAttMensuralShared(other);
    copyAttMensurVis(other);
    copyAttSlashCount(other);
    copyAttStaffLoc(other);
  }

  @override
  void reset() {
    super.reset();
    // AttColor
    color = null;
    // AttCue
    cue = null;
    // AttDurationRatio
    this.num = null;
    numbase = null;
    // AttMensuralShared
    modusmaior = null;
    modusminor = null;
    prolatio = null;
    tempus = null;
    divisio = null;
    // AttMensurVis
    dot = null;
    form = null;
    orient = null;
    sign = null;
    // AttSlashCount
    slash = null;
    // AttStaffLoc
    loc = null;
  }

  @override
  bool get hasToBeAligned => true;

  @override
  bool get isScoreDefElement =>
      parent != null && getFirstAncestor(ClassId.scoreDef) != null;

  @override
  bool isSupportedChild(ClassId classId) {
    logDebug('Method for adding $classId to $className should be overridden');
    return false;
  }
}
