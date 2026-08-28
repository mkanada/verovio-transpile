/// Port of `svgdevicecontext.h/cpp` — a drawing context for generating SVG
/// files.
///
/// This slice (task 05-02) ports the document skeleton: the root `<svg>`
/// element with the C++ attribute set, `<desc>`, `<defs>`, the
/// `StartPage`/`EndPage` pair, the `<g>` group mechanism
/// (`Start*Graphic`/`End*Graphic`/`Resume*`) and the serializer. Task 05-03
/// added the geometric `Draw*` primitives and the `Pen`/`Brush` translation;
/// the text/glyph primitives (`DrawText`, `DrawMusicText`, `InsertGlyphRef`,
/// …) land with 05-04 and throw [UnimplementedError] until then.
///
/// Deviations from the C++:
/// - The pugixml `pugi::xml_document` is mapped onto the mutable [MeiXmlNode]
///   tree from `io/xml_node.dart` (the same tree the MEI readers use),
///   rooted at a `#document` element node exactly like `parseMeiXml`.
///   [MeiXmlNode] has no declaration node type, so the XML declaration is
///   remembered as a flag and emitted by the serializer.
/// - pugixml's writer is ported as [_save]/[_textOutput] (indent-per-depth,
///   ` />` for empty elements, single-pcdata text written inline, escaping)
///   so the output is byte-identical to `pugi::format_default`.
/// - C `printf` has no Dart equivalent: [_formatG] implements `%g` (6
///   significant digits, trailing zeros stripped) and `%f` becomes
///   `toStringAsFixed(6)`.
/// - `Object::GetAttributes` (the `AttModule::Get*` machinery) is not ported
///   yet; [appendAdditionalAttributes] throws [UnimplementedError] when the
///   `svgAdditionalAttribute` option is in use (impossible before the
///   toolkit option plumbing, Phase 7). With the default options the map is
///   empty and the behavior is identical.
/// - The `GIT_COMMIT` suffix of `GetVersion()` is not ported (empty in
///   release builds).
/// - The C++ private flag members are public fields (the repo style of
///   `DeviceContext`); `SetCss`/`SetAdditionalAttributes` keep method form
///   because they carry logic.
library;

import 'dart:math' as math;

import 'package:verovio_dart/src/core/attdef.dart'
    show HorizontalAlignment, meiUnset;
import 'package:verovio_dart/src/core/bounding_box.dart' show BoundingBox;
import 'package:verovio_dart/src/core/devicecontextbase.dart'
    show
        Brush,
        LineCapStyle,
        LineJoinStyle,
        Pen,
        PenStyle,
        colorBlack,
        colorBlue,
        colorCyan,
        colorGreen,
        colorLightGrey,
        colorNone,
        colorRed,
        colorWhite,
        degToRad;
import 'package:verovio_dart/src/core/options_shell.dart'
    show OptionSmuflTextFont;
import 'package:verovio_dart/src/core/point.dart' show Point;
import 'package:verovio_dart/src/core/vrvdef.dart'
    show
        ClassId,
        GraphicID,
        SMuFLGlyphAnchor,
        definitionFactor,
        kVersionDev,
        kVersionMajor,
        kVersionMinor,
        kVersionRevision;
import 'package:verovio_dart/src/io/xml_node.dart' show MeiXmlNode, parseMeiXml;
import 'package:verovio_dart/src/model/atts/atts_conversion.dart'
    show fontstyleToStr, fontweightToStr;
import 'package:verovio_dart/src/model/atts/atts_shared.dart'
    show
        AttColor,
        AttLabelled,
        AttLang,
        AttTyped,
        AttTypography,
        AttVisibility,
        AttWhitespace;
import 'package:verovio_dart/src/model/basic_elements.dart' show Staff;
import 'package:verovio_dart/src/model/floating_object.dart'
    show FloatingObject;
import 'package:verovio_dart/src/model/object.dart' as model;
import 'package:verovio_dart/src/model/scoredef.dart' show StaffDef;
import 'package:verovio_dart/src/rendering/device_context.dart'
    show DeviceContext;
import 'package:verovio_dart/src/rendering/glyph.dart' show Glyph;
import 'package:verovio_dart/src/rendering/resources.dart' show Resources;

/// This class implements a drawing context for generating SVG files.
/// The music font is embedded by incorporating ./data/[fontname]/[glyph].xml
/// glyphs within the SVG file.
///
/// Mirrors `vrv::SvgDeviceContext`.
class SvgDeviceContext extends DeviceContext {
  /// Mirrors `SvgDeviceContext(const std::string &docId)`.
  SvgDeviceContext(this.docId) : super(classId: ClassId.svgDeviceContext) {
    // create the initial SVG element
    // width and height need to be set later; these are taken care of in
    // "commit"
    svgNode = MeiXmlNode.element('svg');
    _document.appendChild(svgNode);
    svgNode.setAttribute('version', '1.1');
    svgNode.setAttribute('xmlns', 'http://www.w3.org/2000/svg');
    svgNode.setAttribute('xmlns:xlink', 'http://www.w3.org/1999/xlink');
    svgNode.setAttribute('overflow', 'visible');
    svgNode.setAttribute('id', docId);

    // start the stack
    _svgNodeStack.add(svgNode);
    currentNode = svgNode;
  }

  /// The document id (the random suffix of the root `@id`; mirrors
  /// `m_docId`). Also used to scope the CSS rules and as glyph postfix.
  final String docId;

  /// The logical origin (mirrors `m_originX`/`m_originY`, negated by
  /// [setLogicalOrigin]).
  int originX = 0;
  int originY = 0;

  // we use a buffer because we want to prepend the <defs> which will know
  // only when we reach the end of the page
  // some viewer seem to support to have the <defs> at the end, but some do
  // not (pdf2svg, for example)
  // for this reason, the full svg is finally written a string from the
  // destructor or when Flush() is called
  // (mirrors `m_outdata`)
  final StringBuffer _outdata = StringBuffer();

  /// did we flushed the file? (mirrors `m_committed`)
  bool _committed = false;

  /// Flag for indicating if the music font is currently used as text font
  /// (mirrors `m_vrvTextFont`). Reset by [startPage], set by the text
  /// drawing (task 05-04).
  bool vrvTextFont = false;

  /// Flag indicating we need a fallback font for the music Glyphs (mirrors
  /// `m_vrvTextFontFallback`).
  bool vrvTextFontFallback = false;

  // pugixml data (mirrors `m_svgDoc`, `m_svgNode`, `m_pageNode`,
  // `m_currentNode`, `m_svgNodeStack`)
  final MeiXmlNode _document = MeiXmlNode.element('#document');
  late MeiXmlNode svgNode;
  late MeiXmlNode pageNode;
  late MeiXmlNode currentNode;
  final List<MeiXmlNode> _svgNodeStack = [];

  // output as mm (for pdf generation with a 72 dpi)
  bool mmOutput = false;
  bool facsimile = false;
  // use LiberationTextFont
  bool useLiberation = false;
  // add bouding boxes in svg output
  bool svgBoundingBoxes = false;
  // add content bounding boxes in svg output
  bool svgContentBoundingBoxes = false;
  // use viewbox on svg root element
  bool svgViewBox = false;
  // output HTML5 data-* attributes
  bool html5 = false;
  // additional CSS (prefixed by [setCss]; mirrors `m_css`)
  String css = '';
  // copy additional attributes of given elements to the SVG, in the form
  // "note@pname; layer@n" (mirrors the `m_svgAdditionalAttributes` multimap)
  final Map<ClassId, List<String>> svgAdditionalAttributes = {};
  // format output as raw, stripping extraneous whitespace and non-content
  // newlines
  bool formatRaw = false;
  // remove xlink from href attributes
  bool removeXlink = false;
  // indentation value (-1 for tabs; the toolkit overrides the constructor
  // default of 2 with the `outputIndent` option, 3 in the default output)
  int indent = 2;
  // embedding of the smufl text font
  OptionSmuflTextFont smuflTextFont =
      OptionSmuflTextFont.SMUFLTEXTFONT_embedded;

  // -------------------------------------------------------------------------
  // Setters / getters
  // -------------------------------------------------------------------------

  /// Setting mm output flag (false by default). Mirrors `SetMMOutput`.
  // set through the [mmOutput] field.

  /// Mirrors `GetFacsimile` / `SetFacsimile`.
  // set through the [facsimile] field.

  /// Setter for an additional CSS; the rules are prefixed with `#docId` for
  /// scoping them to the SVG (mirrors `SetCss`).
  void setCss(String css) {
    this.css = _prefixCssRules(css);
  }

  /// Copies additional attributes of defined elements to the SVG, each
  /// string in the form "elementName@attribute" (e.g., "note@pname").
  /// Mirrors `SetAdditionalAttributes`.
  void setAdditionalAttributes(List<String> additionalAttributes) {
    for (final String s in additionalAttributes) {
      // Parse <element@attribute>, e.g., "note@pname" (the C++ uses
      // `s.find("@")`; the option format guarantees the '@').
      final int at = s.indexOf('@');
      final String className = (at < 0) ? s : s.substring(0, at);
      final String attributeName = (at < 0) ? s : s.substring(at + 1);
      final ClassId classId =
          model.ObjectFactory.instance.getClassId(className);
      svgAdditionalAttributes.putIfAbsent(classId, () => []).add(attributeName);
    }
  }

  /// In SVG use global styling but not with mm output (for pdf generation).
  /// Mirrors `UseGlobalStyling`.
  @override
  bool useGlobalStyling() => !mmOutput;

  /// Indicate if offset should be applied. Mirrors `ApplyOffset`.
  @override
  bool applyOffset() => true;

  // -------------------------------------------------------------------------
  // Commit / output
  // -------------------------------------------------------------------------

  /// Get the SVG into a string. Add the xml tag if necessary.
  /// Mirrors `GetStringSVG`.
  String getStringSVG([bool xmlDeclaration = false]) {
    if (!_committed) _commit(xmlDeclaration);

    return _outdata.toString();
  }

  /// Flush the data to the internal buffer. Adds the xml tag if necessary.
  /// Mirrors the private `Commit`.
  void _commit([bool xmlDeclaration = false]) {
    if (_committed) {
      return;
    }

    // take care of width/height once userScale is updated
    double height = this.height * userScaleY;
    double width = this.width * userScaleX;
    String unit = 'px';

    if (mmOutput) {
      height /= 10;
      width /= 10;
      unit = 'mm';
    } else {
      final (int baseWidth, int baseHeight) = baseSize;
      if (baseWidth != 0 && baseHeight != 0) {
        height = baseHeight.toDouble();
        width = baseWidth.toDouble();
      } else {
        height = height.ceilToDouble();
        width = width.ceilToDouble();
      }
    }

    if (svgViewBox) {
      _prependAttribute(
          svgNode, 'viewBox', '0 0 ${_formatG(width)} ${_formatG(height)}');
    } else {
      _prependAttribute(svgNode, 'height', '${_formatG(height)}$unit');
      _prependAttribute(svgNode, 'width', '${_formatG(width)}$unit');
    }

    // add the woff2 font if needed
    if (smuflTextFont != OptionSmuflTextFont.SMUFLTEXTFONT_none) {
      final Resources? resources = getResources(showWarning: true);
      // include the selected font
      if (vrvTextFont && resources != null) {
        _includeTextFont(resources.currentFontName, resources);
      }
      // include the fallback font
      if (vrvTextFontFallback && resources != null) {
        _includeTextFont(resources.fallbackFontName, resources);
      }
    }
    if (useLiberation) {
      final Resources? resources = getResources(showWarning: true);
      if (resources != null) {
        _includeTextFont(resources.textFontName, resources);
      }
    }

    // header — the `<defs>` glyph loop of Commit (svgdevicecontext.cpp:204)
    // is ported in task 05-04 together with `InsertGlyphRef`/`GlyphRef`;
    // no glyph can be registered before the Draw* of 05-04 exist.
    // TODO(05-04): emit the glyph definitions into a prepended `<defs>`.

    // add description statement
    final MeiXmlNode desc = _prependChildNode(svgNode, 'desc');
    desc.setTextValue('Engraved by Verovio ${_getVersion()}');

    // save the glyph data to _outdata
    final String indentString = (indent == -1) ? '\t' : ' ' * indent;
    _save(_outdata, indentString, xmlDeclaration);

    _committed = true;
  }

  /// Copies additional attributes ... include the smufl text font either
  /// embedded or linked depending on smuflTextFont.
  /// Mirrors the private `IncludeTextFont`.
  void _includeTextFont(String fontname, Resources resources) {
    String cssContent;

    if (smuflTextFont == OptionSmuflTextFont.SMUFLTEXTFONT_embedded) {
      cssContent = resources.getCSSFontFor(fontname);
    } else {
      final String versionPath = kVersionDev
          ? 'develop'
          : '$kVersionMajor.$kVersionMinor.$kVersionRevision';
      cssContent =
          '@import url("https://www.verovio.org/javascript/$versionPath/data/$fontname.css");';
    }

    final MeiXmlNode css = _appendChildNode(svgNode, 'style');
    css.setAttribute('type', 'text/css');
    css.setTextValue(cssContent);
  }

  // -------------------------------------------------------------------------
  // Setters (background / text colors / origin)
  // -------------------------------------------------------------------------

  /// Mirrors `SetBackground` — we do not handle Background.
  @override
  void setBackground(int color, [int style = 0]) {}

  /// Mirrors `SetBackgroundImage`.
  @override
  void setBackgroundImage(Object? image, [double opacity = 1.0]) {}

  /// Mirrors `SetBackgroundMode` — we do not handle Background Mode.
  @override
  void setBackgroundMode(int mode) {}

  /// Mirrors `SetTextForeground` — we use the brush color for text.
  @override
  void setTextForeground(int color) {
    brush.color = color;
  }

  /// Mirrors `SetTextBackground` — we do not handle Text Background Mode.
  @override
  void setTextBackground(int color) {}

  /// Mirrors `SetLogicalOrigin`.
  @override
  void setLogicalOrigin(int x, int y) {
    originX = -x;
    originY = -y;
  }

  /// Mirrors `GetLogicalOrigin`.
  @override
  Point getLogicalOrigin() => Point(originX, originY);

  // -------------------------------------------------------------------------
  // Page lifecycle
  // -------------------------------------------------------------------------

  /// Mirrors `StartPage`.
  @override
  void startPage() {
    // Initialize the flag to false because we want to know if the font needs
    // to be included in the SVG
    vrvTextFont = false;
    vrvTextFontFallback = false;

    final Resources? resources = getResources();

    // default styles
    if (useGlobalStyling()) {
      currentNode = _appendChildNode(currentNode, 'style');
      currentNode.setAttribute('type', 'text/css');
      assert(resources != null);
      // `defaultCss` is the C++ local `css`, renamed not to shadow the
      // `css` field.
      String defaultCss =
          'g.ending, g.fing, g.reh, g.tempo {font-weight:bold;} '
          'g.dir, g.dynam, g.mNum {font-style:italic;}'
          'g.label {font-weight:normal;} '
          'ellipse, path, polygon, polyline, rect {stroke:currentColor} ';
      defaultCss = _prefixCssRules(defaultCss);
      currentNode.setTextValue(defaultCss);
      currentNode = _svgNodeStack.last;
    }

    if (css.isNotEmpty) {
      currentNode = _appendChildNode(currentNode, 'style');
      currentNode.setAttribute('type', 'text/css');
      currentNode.setTextValue(css);
      currentNode = _svgNodeStack.last;
    }

    // a graphic for definition scaling
    currentNode = _appendChildNode(currentNode, 'svg');
    _svgNodeStack.add(currentNode);
    currentNode.setAttribute('class', 'definition-scale');
    currentNode.setAttribute('color', 'black');
    currentNode.setAttribute(
        'font-family', '${resources!.textFontName}, serif');
    if (facsimile) {
      currentNode.setAttribute('viewBox', '0 0 $width $height');
    } else {
      currentNode.setAttribute('viewBox',
          '0 0 ${(width * viewBoxFactor).toInt()} ${(contentHeight * viewBoxFactor).toInt()}');
    }

    // a graphic for the origin
    currentNode = _appendChildNode(currentNode, 'g');
    _svgNodeStack.add(currentNode);
    currentNode.setAttribute('class', 'page-margin');
    currentNode.setAttribute('transform', 'translate($originX, $originY)');

    pageNode = currentNode;
  }

  /// Mirrors `EndPage`.
  @override
  void endPage() {
    // end page-margin
    _svgNodeStack.removeLast();
    // end definition-scale
    _svgNodeStack.removeLast();
    // end page-scale
    // _svgNodeStack.removeLast();
    currentNode = _svgNodeStack.last;
  }

  /// Method for adding description element. Mirrors `AddDescription`.
  @override
  void addDescription(String text) {
    final MeiXmlNode desc = _appendChildNode(currentNode, 'desc');
    desc.setTextValue(text);
  }

  // -------------------------------------------------------------------------
  // Graphic lifecycle
  // -------------------------------------------------------------------------

  /// Mirrors `StartGraphic`.
  @override
  void startGraphic(BoundingBox object, String gClass, String gId,
      {GraphicID graphicID = GraphicID.primary, bool prepend = false}) {
    final model.Object obj = object as model.Object;
    String gClassFull = gClass;

    if (obj case final AttTyped attTyped) {
      if (attTyped.hasType) {
        gClassFull += (gClassFull.isEmpty ? '' : ' ') + attTyped.type!;
      }
    }

    if (prepend) {
      currentNode = _prependChildNode(currentNode, 'g');
    } else {
      currentNode = _appendChildNode(currentNode, 'g');
    }
    _svgNodeStack.add(currentNode);
    appendIdAndClass(gId, obj.className, gClassFull, graphicID);
    appendAdditionalAttributes(obj);

    // Add data-plist with html5 (now only for annot)
    if (html5 && obj.hasPlistReferences) {
      final String ids = _concatenateIDs(obj.plistReferences);
      setCustomGraphicAttributes('plist-referring', ids);
    }

    // this sets staffDef styles for lyrics
    if (obj.classId == ClassId.staff) {
      final Staff staff = obj as Staff;

      assert(staff.drawingStaffDef != null);

      final StaffDef drawingStaffDef = staff.drawingStaffDef! as StaffDef;

      String styleStr = '';
      if (drawingStaffDef.hasLyricFam) {
        styleStr += 'font-family:${drawingStaffDef.lyricFam};';
      }
      if (drawingStaffDef.hasLyricName) {
        styleStr += 'font-family:${drawingStaffDef.lyricName};';
      }
      if (drawingStaffDef.hasLyricStyle) {
        styleStr +=
            'font-style:${fontstyleToStr(drawingStaffDef.lyricStyle!)};';
      }
      if (drawingStaffDef.hasLyricWeight) {
        styleStr +=
            'font-weight:${fontweightToStr(drawingStaffDef.lyricWeight!)};';
      }
      if (styleStr.isNotEmpty) currentNode.setAttribute('style', styleStr);
    }

    if (obj case final AttColor attColor) {
      if (attColor.hasColor) {
        currentNode.setAttribute('color', attColor.color!);
        currentNode.setAttribute('fill', attColor.color!);
      }
    }

    if (obj case final AttLabelled attLabelled) {
      if (attLabelled.hasLabel) {
        final MeiXmlNode svgTitle = _prependChildNode(currentNode, 'title');
        svgTitle.setAttribute('class', 'labelAttr');
        svgTitle.setTextValue(attLabelled.label!);
      }
    }

    if (obj case final AttLang attLang) {
      if (attLang.hasLang) {
        currentNode.setAttribute('xml:lang', attLang.lang!);
      }
    }

    if (obj case final AttTypography attTypography) {
      if (attTypography.hasFontname) {
        currentNode.setAttribute('font-family', attTypography.fontname!);
      }
      if (attTypography.hasFontstyle) {
        currentNode.setAttribute(
            'font-style', fontstyleToStr(attTypography.fontstyle!));
      }
      if (attTypography.hasFontweight) {
        currentNode.setAttribute(
            'font-weight', fontweightToStr(attTypography.fontweight!));
      }
    }

    if (obj case final AttVisibility attVisibility) {
      if (attVisibility.hasVisible) {
        if (attVisibility.visible == true) {
          currentNode.setAttribute('visibility', 'visible');
        } else if (attVisibility.visible == false) {
          currentNode.setAttribute('visibility', 'hidden');
        }
      }
    }
  }

  /// Mirrors `EndGraphic`.
  @override
  void endGraphic(BoundingBox object) {
    // Mirrors `this->DrawSvgBoundingBox(object, view)`: the Dart signature
    // dropped the `View *view` parameter, so no geometry conversions are
    // passed and the body does nothing beyond the guard (as with a null
    // view in the C++) until the View lands (task 05-06).
    drawSvgBoundingBox(object as model.Object);
    _svgNodeStack.removeLast();
    currentNode = _svgNodeStack.last;
  }

  /// Mirrors `StartCustomGraphic` — a custom graphic does not correspond to
  /// an Object.
  @override
  void startCustomGraphic(String name, [String gClass = '', String gId = '']) {
    currentNode = _appendChildNode(currentNode, 'g');
    _svgNodeStack.add(currentNode);
    appendIdAndClass(gId, name, gClass);
  }

  /// Mirrors `EndCustomGraphic`.
  @override
  void endCustomGraphic() {
    _svgNodeStack.removeLast();
    currentNode = _svgNodeStack.last;
  }

  /// Method for changing the color of a custom graphic.
  /// Mirrors `SetCustomGraphicColor`.
  @override
  void setCustomGraphicColor(String color) {
    currentNode.setAttribute('color', color);
    currentNode.setAttribute('fill', color);
  }

  /// Method for adding custom graphic data-* attributes.
  /// Mirrors `SetCustomGraphicAttributes`.
  @override
  void setCustomGraphicAttributes(String data, String value) {
    currentNode.setAttribute('data-$data', value);
  }

  /// Methods for re-starting a graphic for objects drawn in separate steps.
  /// Mirrors `ResumeGraphic`.
  @override
  void resumeGraphic(BoundingBox object, String gId) {
    final String idAttr = html5 ? 'data-id' : 'id';
    // Mirrors the pugixml xpath `//g[@id="..."]`: document-wide search in
    // document order (see [_findGById]).
    final MeiXmlNode? selection = _findGById(svgNode, idAttr, gId);
    if (selection != null) {
      currentNode = selection;
    }
    _svgNodeStack.add(currentNode);
  }

  /// Mirrors `EndResumedGraphic`.
  @override
  void endResumedGraphic(BoundingBox object) {
    _svgNodeStack.removeLast();
    currentNode = _svgNodeStack.last;
  }

  /// Method for starting a text graphic (`<tspan>`).
  /// Mirrors `StartTextGraphic`.
  @override
  void startTextGraphic(BoundingBox object, String gClass, String gId) {
    final model.Object obj = object as model.Object;
    currentNode = _addChild('tspan');
    _svgNodeStack.add(currentNode);
    appendIdAndClass(gId, obj.className, gClass);
    appendAdditionalAttributes(obj);

    if (obj case final AttColor attColor) {
      if (attColor.hasColor) currentNode.setAttribute('fill', attColor.color!);
    }

    if (obj case final AttLabelled attLabelled) {
      if (attLabelled.hasLabel) {
        final MeiXmlNode svgTitle = _prependChildNode(currentNode, 'title');
        svgTitle.setAttribute('class', 'labelAttr');
        svgTitle.setTextValue(attLabelled.label!);
      }
    }

    if (obj case final AttLang attLang) {
      if (attLang.hasLang) {
        currentNode.setAttribute('xml:lang', attLang.lang!);
      }
    }

    if (obj case final AttTypography attTypography) {
      if (attTypography.hasFontname) {
        currentNode.setAttribute('font-family', attTypography.fontname!);
      }
      if (attTypography.hasFontstyle) {
        currentNode.setAttribute(
            'font-style', fontstyleToStr(attTypography.fontstyle!));
      }
      if (attTypography.hasFontweight) {
        currentNode.setAttribute(
            'font-weight', fontweightToStr(attTypography.fontweight!));
      }
    }

    if (obj case final AttWhitespace attWhitespace) {
      if (attWhitespace.hasSpace) {
        currentNode.setAttribute('xml:space', attWhitespace.space!);
      }
    }
  }

  /// Mirrors `EndTextGraphic`.
  @override
  void endTextGraphic(BoundingBox object) {
    // See [endGraphic] for the missing view conversions.
    drawSvgBoundingBox(object as model.Object);
    _svgNodeStack.removeLast();
    currentNode = _svgNodeStack.last;
  }

  /// Method for rotating a graphic (clockwise).
  /// Mirrors `RotateGraphic`.
  @override
  void rotateGraphic(Point orig, double angle) {
    if (currentNode.hasAttr('transform')) {
      return;
    }

    currentNode.setAttribute(
        'transform', 'rotate(${angle.toStringAsFixed(6)} ${orig.x},${orig.y})');
  }

  /// Add id, data-id and class attributes. Mirrors `AppendIdAndClass`.
  void appendIdAndClass(String gId, String baseClass, String addedClasses,
      [GraphicID graphicID = GraphicID.primary]) {
    String baseClassFull = baseClass;

    if (gId.isNotEmpty) {
      if (html5) {
        currentNode.setAttribute('data-id', gId);
      } else if (graphicID == GraphicID.primary) {
        // Don't write ids for HTML5 to avoid id clashes when embedding into
        // an HTML document.
        currentNode.setAttribute('id', gId);
      }
    }

    if (html5) {
      currentNode.setAttribute('data-class', baseClassFull);
    }

    if (graphicID != GraphicID.primary) {
      final String addClass =
          (graphicID == GraphicID.spanning) ? ' spanning' : ' symbol-ref';
      baseClassFull += ' id-$gId$addClass';
    }
    if (addedClasses.isNotEmpty) {
      baseClassFull += ' $addedClasses';
    }
    currentNode.setAttribute('class', baseClassFull);
  }

  /// Append additional attributes, as given in [svgAdditionalAttributes].
  /// Mirrors `AppendAdditionalAttributes`.
  void appendAdditionalAttributes(model.Object object) {
    final List<String>? attributeNames =
        svgAdditionalAttributes[object.classId];
    if (attributeNames == null) return;
    for (final String attributeName in attributeNames) {
      // Mirrors the inner loop over the attributes returned by
      // `Object::GetAttributes`, which is not ported yet (the
      // `AttModule::Get*` machinery). Only reachable with the
      // `svgAdditionalAttribute` option set, which the toolkit plumbing
      // (Phase 7) does not allow yet.
      // TODO(06-08): emit `data-<name>` for matching Object::GetAttributes
      // entries.
      throw UnimplementedError(
          'SvgDeviceContext.appendAdditionalAttributes($attributeName)');
    }
  }

  /// Internal method for drawing debug SVG bounding box rectangles, used
  /// with the `svgBoundingBoxes` / `svgContentBoundingBoxes` options (off by
  /// default).
  /// Mirrors `DrawSvgBoundingBoxRectangle` (svgdevicecontext.cpp:1296) —
  /// private in the C++; public here so the body can be exercised by the
  /// tests before the `View` class lands (same precedent as
  /// [appendIdAndClass]).
  void drawSvgBoundingBoxRectangle(int x, int y, int width, int height) {
    // negative heights or widths are not allowed in SVG
    if (height < 0) {
      height = -height;
      y -= height;
    }
    if (width < 0) {
      width = -width;
      x -= width;
    }

    final MeiXmlNode rectChild = _addChild('rect');
    rectChild.setAttribute('x', '$x');
    rectChild.setAttribute('y', '$y');
    rectChild.setAttribute('height', '$height');
    rectChild.setAttribute('width', '$width');

    rectChild.setAttribute('fill', 'transparent');
    rectChild.setAttribute('stroke-width', '0');
  }

  /// Internal method for drawing the debug bounding box of an object, used
  /// with the `svgBoundingBoxes` option (off by default).
  /// Mirrors `DrawSvgBoundingBox(Object *object, View *view)`
  /// (svgdevicecontext.cpp:1320) — private in the C++; public here so the
  /// body can be exercised by the tests before the `View` class lands (same
  /// precedent as [appendIdAndClass]).
  ///
  /// Deviations from the C++:
  /// - The `View *view` parameter does not exist yet (the `View` class is
  ///   ported in task 05-06). The body only uses the view for the
  ///   `ToDeviceContextX`/`ToDeviceContextY` conversions (view.cpp:72, :84 —
  ///   identity X and Y flipped against the page content height), so those
  ///   two functions are injected instead; passing `null` for either mirrors
  ///   a null `View *`, in which case the C++ body does nothing beyond the
  ///   `m_svgBoundingBoxes && view` guard. [endGraphic] / [endTextGraphic]
  ///   call this without conversions for now.
  void drawSvgBoundingBox(model.Object object,
      {int Function(int x)? toDeviceContextX,
      int Function(int y)? toDeviceContextY}) {
    final Resources? resources = getResources();
    assert(resources != null);

    bool groupInPage = false;
    bool drawAnchors = false;
    final bool drawContentBB = svgContentBoundingBoxes;

    if (svgBoundingBoxes &&
        toDeviceContextX != null &&
        toDeviceContextY != null) {
      BoundingBox box = object;
      // For floating elements, get the current bounding box set by
      // System::SetCurrentFloatingPositioner
      if (object.isFloatingObject) {
        final FloatingObject floatingObject = object as FloatingObject;
        final BoundingBox? currentBox =
            floatingObject.getCurrentFloatingPositioner();
        // No bounding box found, ignore the object - this happens when the
        // @staff is missing because the element is never drawn but there is
        // still a EndGraphic call.
        if (currentBox == null) return;
        box = currentBox;
      }

      // The C++ local `currentNode` (a copy of `m_currentNode`), renamed not
      // to shadow the [currentNode] field.
      final MeiXmlNode savedCurrentNode = currentNode;
      // The three `groupInPage`/`drawAnchors` branches are dead in the C++
      // as well (both flags are false and never change); `ignore` keeps the
      // analyzer from flagging the mirrored dead code.
      // ignore: dead_code
      if (groupInPage) {
        currentNode = pageNode;
      }

      startGraphic(object, 'bounding-box', 'bbox-${object.id}',
          graphicID: GraphicID.primary, prepend: true);

      if (box.hasSelfBB()) {
        drawSvgBoundingBoxRectangle(
            toDeviceContextX(object.getDrawingX() + box.getSelfX1()),
            toDeviceContextY(object.getDrawingY() + box.getSelfY1()),
            toDeviceContextX(object.getDrawingX() + box.getSelfX2()) -
                toDeviceContextX(object.getDrawingX() + box.getSelfX1()),
            toDeviceContextY(object.getDrawingY() + box.getSelfY2()) -
                toDeviceContextY(object.getDrawingY() + box.getSelfY1()));
      }

      // ignore: dead_code
      if (drawAnchors) {
        const List<SMuFLGlyphAnchor> anchors = [
          SMuFLGlyphAnchor.cutOutNE,
          SMuFLGlyphAnchor.cutOutNW,
          SMuFLGlyphAnchor.cutOutSE,
          SMuFLGlyphAnchor.cutOutSW,
        ];

        for (final SMuFLGlyphAnchor iter in anchors) {
          if (object.boundingBoxGlyph != 0) {
            final Glyph? glyph =
                resources!.getGlyphByCode(object.boundingBoxGlyph);
            assert(glyph != null);

            if (glyph!.hasAnchor(iter)) {
              final Point fontPoint = glyph.getAnchor(iter);
              final (int x, int y, int w, int h) = glyph.getBoundingBox();
              final int smuflGlyphFontSize = object.boundingBoxGlyphFontSize;

              final Point p = Point(0, 0);
              // The C++ divisions are int/int (truncating).
              p.x = object.getSelfLeft() -
                  x * smuflGlyphFontSize ~/ glyph.unitsPerEm;
              p.x += fontPoint.x * smuflGlyphFontSize ~/ glyph.unitsPerEm;
              p.y = object.getSelfBottom() -
                  y * smuflGlyphFontSize ~/ glyph.unitsPerEm;
              p.y += fontPoint.y * smuflGlyphFontSize ~/ glyph.unitsPerEm;

              setPen(10, PenStyle.solid, opacity: 1.0, color: colorGreen);
              setBrush(1.0, colorGreen);
              drawCircle(toDeviceContextX(p.x), toDeviceContextY(p.y), 5);
              resetBrush();
              resetPen();
            }
          }
        }
      }

      endGraphic(object);

      // ignore: dead_code
      if (groupInPage) {
        currentNode = pageNode;
      }

      if (drawContentBB) {
        if (object.hasContentBB()) {
          startGraphic(object, 'content-bounding-box', 'cbbox-${object.id}',
              graphicID: GraphicID.primary, prepend: true);
          if (object.hasContentBB()) {
            drawSvgBoundingBoxRectangle(
                toDeviceContextX(object.getDrawingX() + box.getContentX1()),
                toDeviceContextY(object.getDrawingY() + box.getContentY1()),
                toDeviceContextX(object.getDrawingX() + box.getContentX2()) -
                    toDeviceContextX(object.getDrawingX() + box.getContentX1()),
                toDeviceContextY(object.getDrawingY() + box.getContentY2()) -
                    toDeviceContextY(
                        object.getDrawingY() + box.getContentY1()));
          }
          endGraphic(object);
        }
      }

      // ignore: dead_code
      if (groupInPage) {
        currentNode = savedCurrentNode;
      }
    }
  }

  // -------------------------------------------------------------------------
  // Text lifecycle (task 05-04)
  // -------------------------------------------------------------------------

  /// Mirrors `StartText` (svgdevicecontext.cpp:1003).
  @override
  void startText(int x, int y,
      [HorizontalAlignment alignment = HorizontalAlignment.left]) {
    // TODO(05-04): port StartText.
    throw UnimplementedError('SvgDeviceContext.startText');
  }

  /// Mirrors `EndText` (svgdevicecontext.cpp:1060).
  @override
  void endText() {
    // TODO(05-04): port EndText.
    throw UnimplementedError('SvgDeviceContext.endText');
  }

  /// Mirrors `MoveTextTo` (svgdevicecontext.cpp:1050).
  @override
  void moveTextTo(int x, int y, HorizontalAlignment alignment) {
    // TODO(05-04): port MoveTextTo.
    throw UnimplementedError('SvgDeviceContext.moveTextTo');
  }

  /// Mirrors `MoveTextVerticallyTo` (svgdevicecontext.cpp:1066).
  @override
  void moveTextVerticallyTo(int y) {
    // TODO(05-04): port MoveTextVerticallyTo.
    throw UnimplementedError('SvgDeviceContext.moveTextVerticallyTo');
  }

  // -------------------------------------------------------------------------
  // Pen / color translation (svgdevicecontext.cpp:602-631, :1274)
  // -------------------------------------------------------------------------

  /// Mirrors `GetColor` (svgdevicecontext.cpp:1274) — private in the C++;
  /// public here so the tests can exercise it before the `View` class lands
  /// (same precedent as [appendIdAndClass]).
  String getColor(int color) {
    switch (color) {
      case colorNone:
        return 'currentColor';
      case colorBlack:
        return '#000000';
      case colorWhite:
        return '#FFFFFF';
      case colorRed:
        return '#FF0000';
      case colorGreen:
        return '#00FF00';
      case colorBlue:
        return '#0000FF';
      case colorCyan:
        return '#00FFFF';
      case colorLightGrey:
        return '#777777';
      default:
        // Mirrors `StringFormat("#%06X", color)`: uppercase hex of the
        // 32-bit two's complement value, zero-padded to 6 digits.
        return '#${color.toUnsigned(32).toRadixString(16).toUpperCase().padLeft(6, '0')}';
    }
  }

  /// Mirrors `AppendStrokeLineCap` (svgdevicecontext.cpp:602).
  void _appendStrokeLineCap(MeiXmlNode node, Pen pen) {
    switch (pen.lineCap) {
      case LineCapStyle.butt:
        node.setAttribute('stroke-linecap', 'butt');
      case LineCapStyle.round:
        node.setAttribute('stroke-linecap', 'round');
      case LineCapStyle.square:
        node.setAttribute('stroke-linecap', 'square');
      default:
        break;
    }
  }

  /// Mirrors `AppendStrokeLineJoin` (svgdevicecontext.cpp:612).
  void _appendStrokeLineJoin(MeiXmlNode node, Pen pen) {
    switch (pen.lineJoin) {
      case LineJoinStyle.arcs:
        node.setAttribute('stroke-linejoin', 'arcs');
      case LineJoinStyle.bevel:
        node.setAttribute('stroke-linejoin', 'bevel');
      case LineJoinStyle.miter:
        node.setAttribute('stroke-linejoin', 'miter');
      case LineJoinStyle.miterClip:
        node.setAttribute('stroke-linejoin', 'miter-clip');
      case LineJoinStyle.round:
        node.setAttribute('stroke-linejoin', 'round');
      default:
        break;
    }
  }

  /// Mirrors `AppendStrokeDashArray` (svgdevicecontext.cpp:624).
  void _appendStrokeDashArray(MeiXmlNode node, Pen pen) {
    if (pen.dashLength > 0) {
      final int dashLength = pen.dashLength;
      final int gapLength = (pen.gapLength > 0) ? pen.gapLength : dashLength;
      node.setAttribute('stroke-dasharray', '$dashLength $gapLength');
    }
  }

  // -------------------------------------------------------------------------
  // Drawing primitives (tasks 05-03 / 05-04)
  // -------------------------------------------------------------------------

  /// Mirrors `DrawQuadBezierPath` (svgdevicecontext.cpp:670).
  @override
  void drawQuadBezierPath(List<Point> bezier) {
    assert(bezier.length == 3);
    final Pen currentPen = pen;

    final MeiXmlNode pathChild = _addChild('path');
    pathChild.setAttribute('d',
        'M${bezier[0].x},${bezier[0].y} Q${bezier[1].x},${bezier[1].y} ${bezier[2].x},${bezier[2].y}');
    pathChild.setAttribute('fill', 'none');

    if (currentPen.width > 0) {
      pathChild.setAttribute('stroke-width', '${currentPen.width}');
    }
    if (currentPen.hasColor || !useGlobalStyling()) {
      pathChild.setAttribute('stroke', getColor(currentPen.color));
    }
    pathChild.setAttribute('stroke-linecap', 'round');
    pathChild.setAttribute('stroke-linejoin', 'round');
    _appendStrokeDashArray(pathChild, currentPen);
  }

  /// Mirrors `DrawCubicBezierPath` (svgdevicecontext.cpp:693).
  @override
  void drawCubicBezierPath(List<Point> bezier) {
    assert(bezier.length == 4);
    final Pen currentPen = pen;

    final MeiXmlNode pathChild = _addChild('path');
    pathChild.setAttribute('d',
        'M${bezier[0].x},${bezier[0].y} C${bezier[1].x},${bezier[1].y} ${bezier[2].x},${bezier[2].y} ${bezier[3].x},${bezier[3].y}');
    pathChild.setAttribute('fill', 'none');

    if (currentPen.width > 0) {
      pathChild.setAttribute('stroke-width', '${currentPen.width}');
    }
    if (currentPen.hasColor || !useGlobalStyling()) {
      pathChild.setAttribute('stroke', getColor(currentPen.color));
    }
    pathChild.setAttribute('stroke-linecap', 'round');
    pathChild.setAttribute('stroke-linejoin', 'round');
    _appendStrokeDashArray(pathChild, currentPen);
  }

  /// Mirrors `DrawCubicBezierPathFilled` (svgdevicecontext.cpp:717).
  @override
  void drawCubicBezierPathFilled(List<Point> bezier1, List<Point> bezier2) {
    assert(bezier1.length == 4);
    assert(bezier2.length == 4);
    final Pen currentPen = pen;

    final MeiXmlNode pathChild = _addChild('path');
    pathChild.setAttribute('d',
        'M${bezier1[0].x},${bezier1[0].y} C${bezier1[1].x},${bezier1[1].y} ${bezier1[2].x},${bezier1[2].y} ${bezier1[3].x},${bezier1[3].y} C${bezier2[2].x},${bezier2[2].y} ${bezier2[1].x},${bezier2[1].y} ${bezier2[0].x},${bezier2[0].y}');

    if (currentPen.width > 0) {
      pathChild.setAttribute('stroke-width', '${currentPen.width}');
    }
    if (currentPen.hasColor || !useGlobalStyling()) {
      pathChild.setAttribute('stroke', getColor(currentPen.color));
    }
    pathChild.setAttribute('stroke-linecap', 'round');
    pathChild.setAttribute('stroke-linejoin', 'round');
  }

  /// Mirrors `DrawBentParallelogramFilled` (svgdevicecontext.cpp:740).
  @override
  void drawBentParallelogramFilled(List<Point> side, int height) {
    assert(side.length == 4);
    final Pen currentPen = pen;

    final MeiXmlNode pathChild = _addChild('path');
    pathChild.setAttribute('d',
        'M${side[0].x},${side[0].y} C${side[1].x},${side[1].y} ${side[2].x},${side[2].y} ${side[3].x},${side[3].y} L${side[3].x},${side[3].y + height} C${side[2].x},${side[2].y + height} ${side[1].x},${side[1].y + height} ${side[0].x},${side[0].y + height} Z');

    if (currentPen.width > 0) {
      pathChild.setAttribute('stroke-width', '${currentPen.width}');
    }
    if (currentPen.hasColor || !useGlobalStyling()) {
      pathChild.setAttribute('stroke', getColor(currentPen.color));
    }
    pathChild.setAttribute('stroke-linecap', 'round');
    pathChild.setAttribute('stroke-linejoin', 'round');
  }

  /// Mirrors `DrawCircle` (svgdevicecontext.cpp:761).
  @override
  void drawCircle(int x, int y, int radius) {
    drawEllipse(x - radius, y - radius, 2 * radius, 2 * radius);
  }

  /// Mirrors `DrawEllipse` (svgdevicecontext.cpp:766).
  @override
  void drawEllipse(int x, int y, int width, int height) {
    final Pen currentPen = pen;
    final Brush currentBrush = brush;

    final int rh = height ~/ 2;
    final int rw = width ~/ 2;

    final MeiXmlNode ellipseChild = _addChild('ellipse');
    ellipseChild.setAttribute('cx', '${x + rw}');
    ellipseChild.setAttribute('cy', '${y + rh}');
    ellipseChild.setAttribute('rx', '$rw');
    ellipseChild.setAttribute('ry', '$rh');

    if (currentBrush.hasOpacity) {
      ellipseChild.setAttribute(
          'fill-opacity', _formatG(currentBrush.opacity, 9));
    }
    if (currentPen.width > 0) {
      ellipseChild.setAttribute('stroke-width', '${currentPen.width}');
    }
    if (currentPen.hasColor || !useGlobalStyling()) {
      ellipseChild.setAttribute('stroke', getColor(currentPen.color));
    }
    if (currentPen.hasOpacity) {
      ellipseChild.setAttribute(
          'stroke-opacity', _formatG(currentPen.opacity, 9));
    }
  }

  /// Mirrors `DrawEllipticArc` (svgdevicecontext.cpp:797).
  @override
  void drawEllipticArc(
      int x, int y, int width, int height, double start, double end) {
    // Draws an arc of an ellipse. The current pen is used for drawing the
    // arc and the current brush is used for drawing the pie. This function
    // is currently only available for X window and PostScript device
    // contexts.
    //
    // x and y specify the x and y coordinates of the upper-left corner of
    // the rectangle that contains the ellipse.
    //
    // width and height specify the width and height of the rectangle that
    // contains the ellipse.
    //
    // start and end specify the start and end of the arc relative to the
    // three-o'clock position from the center of the rectangle. Angles are
    // specified in degrees (360 is a complete circle). Positive values mean
    // counter-clockwise motion. If start is equal to end, a complete
    // ellipse will be drawn.

    // known bug: SVG draws with the current pen along the radii, but this
    // does not happen in wxMSW

    final Pen currentPen = pen;
    final Brush currentBrush = brush;

    // radius — `width / 2` is int/int division in the C++.
    final double rx = (width ~/ 2).toDouble();
    final double ry = (height ~/ 2).toDouble();
    // center
    final double xc = x + rx;
    final double yc = y + ry;

    final double xs = xc + rx * math.cos(degToRad(start));
    final double xe = xc + rx * math.cos(degToRad(end));
    final double ys = yc - ry * math.sin(degToRad(start));
    final double ye = yc - ry * math.sin(degToRad(end));

    // now same as circle arc...
    final double theta1 = math.atan2(ys - yc, xs - xc);
    final double theta2 = math.atan2(ye - yc, xe - xc);

    // flag for large or small arc 0 means less than 180 degrees
    final int fArc = ((theta2 - theta1) > 0) ? 1 : 0;

    final int fSweep = ((theta2 - theta1).abs() > math.pi) ? 1 : 0;

    final MeiXmlNode pathChild = _addChild('path');
    // `int(xs)` truncates toward zero, like `.truncate()`.
    pathChild.setAttribute('d',
        'M${xs.truncate()} ${ys.truncate()} A${rx.truncate().abs()} ${ry.truncate().abs()} 0.0 $fArc $fSweep ${xe.truncate()} ${ye.truncate()}');

    if (currentBrush.hasOpacity) {
      pathChild.setAttribute('fill-opacity', _formatG(currentBrush.opacity, 9));
    }
    if (currentPen.width > 0) {
      pathChild.setAttribute('stroke-width', '${currentPen.width}');
    }
    if (currentPen.hasColor || !useGlobalStyling()) {
      pathChild.setAttribute('stroke', getColor(currentPen.color));
    }
    if (currentPen.hasOpacity) {
      pathChild.setAttribute('stroke-opacity', _formatG(currentPen.opacity, 9));
    }
  }

  /// Mirrors `DrawLine` (svgdevicecontext.cpp:866).
  @override
  void drawLine(int x1, int y1, int x2, int y2) {
    final Pen currentPen = pen;

    final MeiXmlNode pathChild = _addChild('path');
    pathChild.setAttribute('d', 'M$x1 $y1 L$x2 $y2');

    if (currentPen.width > 0) {
      pathChild.setAttribute('stroke-width', '${currentPen.width}');
    }
    if (currentPen.hasColor || !useGlobalStyling()) {
      pathChild.setAttribute('stroke', getColor(currentPen.color));
    }
    if (currentPen.hasOpacity) {
      pathChild.setAttribute('stroke-opacity', _formatG(currentPen.opacity, 9));
    }

    _appendStrokeLineCap(pathChild, currentPen);
    _appendStrokeDashArray(pathChild, currentPen);
  }

  /// Mirrors `DrawPolyline` (svgdevicecontext.cpp:888).
  @override
  void drawPolyline(List<Point> points, {bool close = false}) {
    final Pen currentPen = pen;

    final MeiXmlNode polylineChild = _addChild(close ? 'polygon' : 'polyline');

    if (currentPen.width > 0) {
      polylineChild.setAttribute('stroke-width', '${currentPen.width}');
    }
    if (currentPen.hasColor || !useGlobalStyling()) {
      polylineChild.setAttribute('stroke', getColor(currentPen.color));
    }
    if (currentPen.hasOpacity) {
      polylineChild.setAttribute(
          'stroke-opacity', _formatG(currentPen.opacity, 9));
    }

    _appendStrokeLineCap(polylineChild, currentPen);
    _appendStrokeLineJoin(polylineChild, currentPen);
    _appendStrokeDashArray(polylineChild, currentPen);

    if (points.length > 2) polylineChild.setAttribute('fill', 'none');

    String pointsString = '';
    for (final Point point in points) {
      pointsString += '${point.x},${point.y} ';
    }
    polylineChild.setAttribute('points', pointsString);
  }

  /// Mirrors `DrawPolygon` (svgdevicecontext.cpp:918).
  @override
  void drawPolygon(List<Point> points) {
    final Pen currentPen = pen;
    final Brush currentBrush = brush;

    final MeiXmlNode polygonChild = _addChild('polygon');

    if (currentPen.width > 0) {
      polygonChild.setAttribute('stroke-width', '${currentPen.width}');
    }
    if (currentPen.hasColor || !useGlobalStyling()) {
      polygonChild.setAttribute('stroke', getColor(currentPen.color));
    }
    if (currentPen.hasOpacity) {
      polygonChild.setAttribute(
          'stroke-opacity', _formatG(currentPen.opacity, 9));
    }
    _appendStrokeLineJoin(polygonChild, currentPen);
    _appendStrokeDashArray(polygonChild, currentPen);

    if (currentBrush.hasColor) {
      polygonChild.setAttribute('fill', getColor(currentBrush.color));
    }
    if (currentBrush.hasOpacity) {
      polygonChild.setAttribute(
          'fill-opacity', _formatG(currentBrush.opacity, 9));
    }

    String pointsString = '${points[0].x},${points[0].y}';
    for (int i = 1; i < points.length; ++i) {
      pointsString += ' ${points[i].x},${points[i].y}';
    }
    polygonChild.setAttribute('points', pointsString);
  }

  /// Mirrors `DrawRectangle` (svgdevicecontext.cpp:954).
  @override
  void drawRectangle(int x, int y, int width, int height) {
    drawRoundedRectangle(x, y, width, height, 0);
  }

  /// Mirrors `DrawRotatedText` (svgdevicecontext.cpp:1148).
  @override
  void drawRotatedText(String text, int x, int y, double angle) {
    // TODO(05-04): port DrawRotatedText.
    throw UnimplementedError('SvgDeviceContext.drawRotatedText');
  }

  /// Mirrors `DrawRoundedRectangle` (svgdevicecontext.cpp:959).
  @override
  void drawRoundedRectangle(int x, int y, int width, int height, int radius) {
    final Pen currentPen = pen;
    final Brush currentBrush = brush;

    final MeiXmlNode rectChild = _addChild('rect');

    if (currentPen.width > 0) {
      rectChild.setAttribute('stroke-width', '${currentPen.width}');
    }
    if (currentPen.hasColor || !useGlobalStyling()) {
      rectChild.setAttribute('stroke', getColor(currentPen.color));
    }
    if (currentPen.hasOpacity) {
      rectChild.setAttribute('stroke-opacity', _formatG(currentPen.opacity, 9));
    }

    if (currentBrush.hasColor) {
      rectChild.setAttribute('fill', getColor(currentBrush.color));
    }
    if (currentBrush.hasOpacity) {
      rectChild.setAttribute('fill-opacity', _formatG(currentBrush.opacity, 9));
    }

    // negative heights or widths are not allowed in SVG
    if (height < 0) {
      height = -height;
      y -= height;
    }
    if (width < 0) {
      width = -width;
      x -= width;
    }

    rectChild.setAttribute('x', '$x');
    rectChild.setAttribute('y', '$y');
    rectChild.setAttribute('height', '$height');
    rectChild.setAttribute('width', '$width');
    if (radius != 0) rectChild.setAttribute('rx', '$radius');
  }

  /// Mirrors `DrawText` (svgdevicecontext.cpp:1079).
  @override
  void drawText(String text,
      {String? wtext,
      int x = meiUnset,
      int y = meiUnset,
      int width = meiUnset,
      int height = meiUnset}) {
    // TODO(05-04): port DrawText.
    throw UnimplementedError('SvgDeviceContext.drawText');
  }

  /// Mirrors `DrawMusicText` (svgdevicecontext.cpp:1153).
  @override
  void drawMusicText(String text, int x, int y, {bool setSmuflGlyph = false}) {
    // TODO(05-04): port DrawMusicText.
    throw UnimplementedError('SvgDeviceContext.drawMusicText');
  }

  /// Mirrors `DrawSpline` (svgdevicecontext.cpp:1196) — empty in the C++ as
  /// well.
  @override
  void drawSpline(List<Point> points) {}

  /// Mirrors `DrawGraphicUri` (svgdevicecontext.cpp:1198).
  @override
  void drawGraphicUri(int x, int y, int width, int height, String uri) {
    final MeiXmlNode image = _appendChildNode(currentNode, 'image');
    image.setAttribute('xlink:href', uri);
    image.setAttribute('x', '$x');
    image.setAttribute('y', '$y');
    image.setAttribute('width', '$width');
    image.setAttribute('height', '$height');
  }

  /// Mirrors `DrawSvgShape` (svgdevicecontext.cpp:1208).
  ///
  /// Deviations from the C++:
  /// - The C++ takes a `pugi::xml_node svg` (`Svg::Get()`, i.e., the first
  ///   child of the stored document) and `append_copy`s its children. The
  ///   Dart `Svg` model class stores the content as a string, so the
  ///   signature carries a string that is parsed here; the children of the
  ///   parsed root are copied (deep-copied with [MeiXmlNode.copy]).
  @override
  void drawSvgShape(
      int x, int y, int width, int height, double scale, String svg) {
    currentNode.setAttribute('transform',
        'translate($x, $y) scale(${_formatF(scale * definitionFactor)}, ${_formatF(scale * definitionFactor)})');

    // Remove the ID in the SVG because it might be duplicated and that will
    // not be valid
    currentNode.removeAttribute('id');

    final MeiXmlNode? document = parseMeiXml(svg);
    // A parse failure (or an empty string) mirrors a null pugixml node, over
    // which `svg.children()` iterates nothing.
    if (document == null || document.children.isEmpty) return;
    final MeiXmlNode root = document.children.first;
    for (final MeiXmlNode child in root.children) {
      currentNode.appendChild(child.copy());
    }
  }

  /// Mirrors `DrawBackgroundImage` (svgdevicecontext.cpp:1222) — empty in
  /// the C++ as well.
  @override
  void drawBackgroundImage([int x = 0, int y = 0]) {}

  // -------------------------------------------------------------------------
  // Tree helpers (pugixml operations on MeiXmlNode)
  // -------------------------------------------------------------------------

  /// Mirrors the private `AddChild`: adds the child before the first `<g>`
  /// child if there is one (so that graphics come after bounding boxes),
  /// honoring the push-back mode otherwise.
  MeiXmlNode _addChild(String name) {
    final MeiXmlNode? g = currentNode.child('g');
    if (g != null) {
      return _insertChildBefore(currentNode, name, g);
    } else {
      return (pushBack)
          ? _prependChildNode(currentNode, name)
          : _appendChildNode(currentNode, name);
    }
  }

  /// `append_child` of pugixml (auxiliary of the port; [MeiXmlNode] only
  /// offers [MeiXmlNode.appendChild] taking a ready node).
  static MeiXmlNode _appendChildNode(MeiXmlNode parent, String name) {
    final MeiXmlNode child = MeiXmlNode.element(name);
    parent.appendChild(child);
    return child;
  }

  /// `prepend_child` of pugixml (auxiliary of the port).
  static MeiXmlNode _prependChildNode(MeiXmlNode parent, String name) {
    final MeiXmlNode child = MeiXmlNode.element(name);
    child.parent = parent;
    parent.children.insert(0, child);
    return child;
  }

  /// `insert_child_before` of pugixml (auxiliary of the port).
  static MeiXmlNode _insertChildBefore(
      MeiXmlNode parent, String name, MeiXmlNode reference) {
    final MeiXmlNode child = MeiXmlNode.element(name);
    child.parent = parent;
    parent.children.insert(parent.children.indexOf(reference), child);
    return child;
  }

  /// `prepend_attribute` of pugixml (auxiliary of the port): the attribute
  /// becomes the first one. The [MeiXmlNode.attributes] map preserves
  /// insertion order, so it is rebuilt with the new entry first.
  static void _prependAttribute(MeiXmlNode node, String name, String value) {
    if (node.attributes.containsKey(name)) {
      node.attributes[name] = value;
      return;
    }
    final Map<String, String> previous = Map.of(node.attributes);
    node.attributes
      ..clear()
      ..[name] = value
      ..addAll(previous);
  }

  /// Search helper for [resumeGraphic], mirroring the pugixml xpath
  /// `//g[@id="..."]`: a document-wide search in document order.
  static MeiXmlNode? _findGById(MeiXmlNode root, String idAttr, String gId) {
    for (final MeiXmlNode node in root.children) {
      if (!node.isElement) continue;
      if (node.name == 'g' && node.attr(idAttr) == gId) return node;
      final MeiXmlNode? found = _findGById(node, idAttr, gId);
      if (found != null) return found;
    }
    return null;
  }

  /// Port of `ConcatenateIDs` (vrv.cpp:258): `#id1 #id2 …`.
  static String _concatenateIDs(List<model.Object> objects) {
    final List<String> ids = [
      for (final model.Object object in objects) '#${object.id} '
    ];
    String uris = ids.join();
    if (uris.isNotEmpty) uris = uris.substring(0, uris.length - 1);
    return uris;
  }

  /// Port of `PrefixCssRules` (svgdevicecontext.cpp:633): prefixes each
  /// selector of each rule with `#docId` for scoping them to the SVG.
  String _prefixCssRules(String rules) {
    final RegExp selectorRegex = RegExp(r'([^{}]+)\s*\{([^}]*)\}');

    String result = '';

    for (final RegExpMatch match in selectorRegex.allMatches(rules)) {
      final String selectors = match.group(1)!;
      final String properties = match.group(2)!;

      // Split by comma to handle multi-selectors (mirrors the std::getline
      // loop, which drops a trailing empty token).
      final List<String> prefixedSelectors = <String>[];
      int start = 0;
      while (true) {
        final int comma = selectors.indexOf(',', start);
        if (comma < 0) {
          if (start < selectors.length) {
            prefixedSelectors
                .add('#$docId ${selectors.substring(start).trim()}');
          }
          break;
        }
        prefixedSelectors
            .add('#$docId ${selectors.substring(start, comma).trim()}');
        start = comma + 1;
      }

      if (prefixedSelectors.isEmpty) continue;

      result += '${prefixedSelectors.join(', ')} {$properties}';
    }

    return result;
  }

  // -------------------------------------------------------------------------
  // Serialization (port of the pugixml writer)
  // -------------------------------------------------------------------------

  /// Port of the pugixml `node_output` writer for the subset of node types
  /// this class produces (elements, pcdata; comments pass through): each
  /// element child on its own line indented by depth, pcdata written inline,
  /// empty elements as `<name … />` (without the space in raw format), and
  /// a trailing newline at document end. The xml declaration is written
  /// here because [MeiXmlNode] has no declaration node type.
  void _save(StringBuffer writer, String indentString, bool xmlDeclaration) {
    const int indentNewline = 1;
    const int indentIndent = 2;

    if (xmlDeclaration) {
      // Mirrors the pugi::node_declaration prepended by `Commit` with
      // `pugi::format_default` output flags.
      writer.write('<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n');
    }

    final int indentLength = formatRaw ? 0 : indentString.length;
    int indentFlags = indentIndent;

    MeiXmlNode node = _document;
    int depth = 0;

    do {
      if (node.isText) {
        _textOutput(writer, node.value ?? '', isAttr: false);
        indentFlags = 0;
      } else if (node.isComment) {
        writer.write('<!--${node.value ?? ''}-->');
        indentFlags = indentNewline | indentIndent;
      } else if (identical(node, _document)) {
        if ((indentFlags & indentNewline) != 0 && !formatRaw) {
          writer.write('\n');
        }
        if ((indentFlags & indentIndent) != 0 && indentLength > 0) {
          writer.write(indentString * depth);
        }
        indentFlags = indentIndent;

        if (node.children.isNotEmpty) {
          node = node.children.first;
          continue;
        }
      } else {
        if ((indentFlags & indentNewline) != 0 && !formatRaw) {
          writer.write('\n');
        }
        if ((indentFlags & indentIndent) != 0 && indentLength > 0) {
          writer.write(indentString * depth);
        }

        indentFlags = indentNewline | indentIndent;

        // node_output_start
        writer.write('<');
        writer.write(node.name);
        node.attributes.forEach((String name, String value) {
          writer.write(' ');
          writer.write(name);
          writer.write('="');
          _textOutput(writer, value, isAttr: true);
          writer.write('"');
        });

        if (node.children.isEmpty) {
          if (!formatRaw) writer.write(' ');
          writer.write('/>');
        } else {
          writer.write('>');
          node = node.children.first;
          depth++;
          continue;
        }
      }

      // continue to the next node
      while (!identical(node, _document)) {
        final MeiXmlNode? next = node.nextSibling();
        if (next != null) {
          node = next;
          break;
        }

        node = node.parent!;

        // write closing node
        if (!identical(node, _document)) {
          depth--;

          if ((indentFlags & indentNewline) != 0 && !formatRaw) {
            writer.write('\n');
          }
          if ((indentFlags & indentIndent) != 0 && indentLength > 0) {
            writer.write(indentString * depth);
          }

          writer.write('</');
          writer.write(node.name);
          writer.write('>');

          indentFlags = indentNewline | indentIndent;
        }
      }
    } while (!identical(node, _document));

    if ((indentFlags & indentNewline) != 0 && !formatRaw) writer.write('\n');
  }

  /// Port of pugixml `text_output_escaped` with the default flags: in pcdata
  /// context `&`, `<` and `>` are escaped; in attribute context additionally
  /// `"`. Control characters are written as decimal `&#NN;` (two digits) —
  /// in pcdata context `\t`, `\n` and `\r` pass through.
  static void _textOutput(StringBuffer writer, String s,
      {required bool isAttr}) {
    for (int i = 0; i < s.length; ++i) {
      final int ch = s.codeUnitAt(i);
      switch (ch) {
        case 0x26: // &
          writer.write('&amp;');
        case 0x3C: // <
          writer.write('&lt;');
        case 0x3E: // >
          writer.write('&gt;');
        case 0x22 when isAttr: // "
          writer.write('&quot;');
        default:
          final bool isSpecial =
              ch < 0x20 && (isAttr || (ch != 0x09 && ch != 0x0A && ch != 0x0D));
          if (isSpecial) {
            writer.write('&#${ch ~/ 10}${ch % 10};');
          } else {
            writer.writeCharCode(ch);
          }
      }
    }
  }

  // -------------------------------------------------------------------------
  // Small port helpers
  // -------------------------------------------------------------------------

  /// Port of `GetVersion` (vrv.cpp:416) without the `GIT_COMMIT` suffix.
  static String _getVersion() {
    final String dev = kVersionDev ? '-dev' : '';
    return '$kVersionMajor.$kVersionMinor.$kVersionRevision$dev';
  }

  /// Port of C `printf("%g")` — [precision] significant digits, trailing
  /// zeros stripped, fixed notation for exponents in [-4, 6). Auxiliary of
  /// the port, used by `_commit` for the `width`/`height`/`viewBox` values
  /// (default precision 6) and by the opacity attributes, where pugixml
  /// formats floats with `%.9g` (`default_float_precision`).
  static String _formatG(double value, [int precision = 6]) {
    if (value == 0.0) return value.isNegative ? '-0' : '0';

    final int exponent =
        int.parse(value.abs().toStringAsExponential().split('e')[1]);

    if (exponent >= -4 && exponent < 6) {
      String s = value.toStringAsFixed(precision - 1 - exponent);
      if (s.contains('.')) {
        s = s.replaceFirst(RegExp(r'0+$'), '');
        s = s.replaceFirst(RegExp(r'\.$'), '');
      }
      return s;
    }

    // Scientific style; the exponent gets the C format (sign and at least
    // two digits).
    final List<String> parts =
        value.toStringAsExponential(precision - 1).split('e');
    String mantissa = parts[0];
    if (mantissa.contains('.')) {
      mantissa = mantissa.replaceFirst(RegExp(r'0+$'), '');
      mantissa = mantissa.replaceFirst(RegExp(r'\.$'), '');
    }
    final String sign = parts[1].startsWith('-') ? '-' : '+';
    final String digits =
        parts[1].replaceFirst(RegExp(r'^[+-]'), '').padLeft(2, '0');
    return '${mantissa}e$sign$digits';
  }

  /// Port of C `printf("%f")` — fixed notation with 6 decimal places.
  /// Auxiliary of the port, used by [drawSvgShape].
  static String _formatF(double value) => value.toStringAsFixed(6);
}
