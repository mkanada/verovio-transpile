// GENERATED FILE - do not edit. Regenerate with:
//   dart run tool/gen_atts.dart
// Source: origin/src/libmei/dist/atts_externalsymbols.h/.cpp
library;

import 'package:xml/xml.dart';
import 'mei_values.dart';

/// MEI attribute class for `att.ExtSymAuth` (mirrors `vrv::AttExtSymAuth`).
mixin AttExtSymAuth {
  /// `glyph.auth` — std::string.
  String? glyphAuth;
  bool get hasGlyphAuth => glyphAuth != null;

  /// `glyph.uri` — std::string.
  String? glyphUri;
  bool get hasGlyphUri => glyphUri != null;

  /// Mirrors `AttExtSymAuth::ReadExtSymAuth`.
  bool readExtSymAuth(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final glyphAuthRaw = element.get('glyph.auth');
    if (glyphAuthRaw != null) {
      glyphAuth = identityStr(glyphAuthRaw);
      if (removeAttr) element.remove('glyph.auth');
      hasAttribute = true;
    }
    final glyphUriRaw = element.get('glyph.uri');
    if (glyphUriRaw != null) {
      glyphUri = identityStr(glyphUriRaw);
      if (removeAttr) element.remove('glyph.uri');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttExtSymAuth::WriteExtSymAuth`.
  void writeExtSymAuth(XmlBuilder element) {
    if (hasGlyphAuth) {
      element.attribute('glyph.auth', identityStr(glyphAuth!));
    }
    if (hasGlyphUri) {
      element.attribute('glyph.uri', identityStr(glyphUri!));
    }
  }

  /// Copies the `AttExtSymAuth` members from [other].
  void copyAttExtSymAuth(covariant AttExtSymAuth other) {
    glyphAuth = other.glyphAuth;
    glyphUri = other.glyphUri;
  }
}

/// MEI attribute class for `att.ExtSymNames` (mirrors `vrv::AttExtSymNames`).
mixin AttExtSymNames {
  /// `glyph.name` — std::string.
  String? glyphName;
  bool get hasGlyphName => glyphName != null;

  /// `glyph.num` — data_HEXNUM.
  int? glyphNum;
  bool get hasGlyphNum => glyphNum != null;

  /// Mirrors `AttExtSymNames::ReadExtSymNames`.
  bool readExtSymNames(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final glyphNameRaw = element.get('glyph.name');
    if (glyphNameRaw != null) {
      glyphName = identityStr(glyphNameRaw);
      if (removeAttr) element.remove('glyph.name');
      hasAttribute = true;
    }
    final glyphNumRaw = element.get('glyph.num');
    if (glyphNumRaw != null) {
      glyphNum = strToHexnum(glyphNumRaw);
      if (removeAttr) element.remove('glyph.num');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttExtSymNames::WriteExtSymNames`.
  void writeExtSymNames(XmlBuilder element) {
    if (hasGlyphName) {
      element.attribute('glyph.name', identityStr(glyphName!));
    }
    if (hasGlyphNum) {
      element.attribute('glyph.num', hexnumToStr(glyphNum!));
    }
  }

  /// Copies the `AttExtSymNames` members from [other].
  void copyAttExtSymNames(covariant AttExtSymNames other) {
    glyphName = other.glyphName;
    glyphNum = other.glyphNum;
  }
}
