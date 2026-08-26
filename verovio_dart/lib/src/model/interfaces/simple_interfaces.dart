/// Ports of the small interfaces: `altsyminterface`, `areaposinterface`,
/// `offsetinterface`, `scoredefinterface` and `textdirinterface`.
library;

import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/model/atts/atts_shared.dart';
import 'package:verovio_dart/src/model/atts/atts_usersymbols.dart';
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/model/interfaces/interface.dart';

/// Mirrors `vrv::AltSymInterface`. Apply with [AttAltSym].
mixin AltSymInterface on AttAltSym implements Interface {
  /// The resolved @altsym symbolDef element.
  Object? altSymbolDef;

  /// The fragment of the @altsym attribute.
  String altSymbolDefID = '';

  @override
  InterfaceId get interfaceId => InterfaceId.altSym;

  @override
  void reset() {
    altsym = null;
    altSymbolDef = null;
    altSymbolDefID = '';
  }

  bool get hasAltSymbolDef => altSymbolDef != null;

  /// Copies the interface state from [other].
  void copyAltSymFrom(covariant AltSymInterface other) {
    altsym = other.altsym;
    altSymbolDef = other.altSymbolDef;
    altSymbolDefID = other.altSymbolDefID;
  }

  /// Extract the fragment of the @altsym if given.
  void setIDStr() {
    if (hasAltsym && altsym != null) {
      // ExtractIDFragment
      final pos = altsym!.lastIndexOf('#');
      altSymbolDefID = (pos >= 0 && pos < altsym!.length - 1)
          ? altsym!.substring(pos + 1)
          : altsym!;
    }
  }
}

/// Mirrors `vrv::AreaPosInterface`. Apply with
/// [AttHorizontalAlign] and [AttVerticalAlign].
mixin AreaPosInterface
    on AttHorizontalAlign, AttVerticalAlign
    implements Interface {
  @override
  InterfaceId get interfaceId => InterfaceId.areaPos;

  @override
  void reset() {
    halign = null;
    valign = null;
  }

  /// Copies the interface state from [other].
  void copyAreaPosFrom(covariant AreaPosInterface other) {
    halign = other.halign;
    valign = other.valign;
  }
}

/// Mirrors `vrv::OffsetInterface`. Apply with
/// [AttVisualOffsetHo] and [AttVisualOffsetVo].
mixin OffsetInterface
    on AttVisualOffsetHo, AttVisualOffsetVo
    implements Interface {
  @override
  InterfaceId get interfaceId => InterfaceId.offset;

  @override
  void reset() {
    ho = null;
    vo = null;
  }

  /// Copies the interface state from [other].
  void copyOffsetFrom(covariant OffsetInterface other) {
    ho = other.ho;
    vo = other.vo;
  }
}

/// Mirrors `vrv::OffsetSpanningInterface`. Apply with
/// [AttVisualOffset2Ho] and [AttVisualOffset2Vo].
mixin OffsetSpanningInterface
    on AttVisualOffset2Ho, AttVisualOffset2Vo
    implements Interface {
  @override
  InterfaceId get interfaceId => InterfaceId.offsetSpanning;

  @override
  void reset() {
    startho = null;
    endho = null;
    startvo = null;
    endvo = null;
  }

  /// Copies the interface state from [other].
  void copyOffsetSpanningFrom(covariant OffsetSpanningInterface other) {
    startho = other.startho;
    endho = other.endho;
    startvo = other.startvo;
    endvo = other.endvo;
  }
}

/// Mirrors `vrv::ScoreDefInterface`. Apply with the scoreDef att classes.
mixin ScoreDefInterface implements Interface {
  @override
  InterfaceId get interfaceId => InterfaceId.scoreDef;

  @override
  void reset() {
    // The attribute members come from the applied generated mixins; they are
    // cleared individually by the element's own reset when needed.
  }

  /// Copies the interface state from [other] (no direct members).
  void copyScoreDefFrom(covariant ScoreDefInterface other) {}
}

/// Mirrors `vrv::TextDirInterface`. Apply with [AttPlacementRelStaff].
mixin TextDirInterface on AttPlacementRelStaff implements Interface {
  @override
  InterfaceId get interfaceId => InterfaceId.textDir;

  @override
  void reset() {
    place = null;
  }

  /// Copies the interface state from [other].
  void copyTextDirFrom(covariant TextDirInterface other) {
    place = other.place;
  }

  /// Return the number of lines in the text object by counting `<lb>`
  /// descendants (mirrors `GetNumberOfLines`).
  int getNumberOfLines(Object object) =>
      object.getDescendantCount(ClassId.lb) + 1;
}
