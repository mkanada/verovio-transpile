/// Port of `iomei.h/cpp` (`MEIInput`) — the native MEI parser.
///
/// The C++ uses pugixml directly; this port parses into the mutable
/// [MeiXmlNode] tree (`xml_node.dart`) so that attributes can be consumed,
/// renamed or removed while reading (upgrades of older MEI versions).
///
/// Each `readXxx` method creates one [MeiAttributeReader] over the element
/// attributes; every generated att-class reader consumes from it and
/// [readUnsupportedAttr] stores whatever is left into `object.unsupported`,
/// mirroring the pugi attribute-removal semantics of the original.
///
/// MEIOutput arrives with the export phase (Phase 7); compressed MEI
/// handling lives in the Toolkit (`toolkit.dart`).
library;

import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/utils.dart' show extractIDFragment;
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/io/iobase.dart';
import 'package:verovio_dart/src/io/xml_node.dart';
import 'package:verovio_dart/src/model/atts/mei_enums.dart' hide Tie;
import 'package:verovio_dart/src/model/atts/mei_values.dart';
import 'package:verovio_dart/src/model/basic_elements.dart';
import 'package:verovio_dart/src/model/control_element.dart'
    show ControlElement;
import 'package:verovio_dart/src/model/drawing_interfaces.dart'
    show PageMilestoneInterface, SystemMilestoneInterface;
import 'package:verovio_dart/src/model/doc.dart' show DocType, Page, Pages;
import 'package:verovio_dart/src/model/zone.dart' show Zone;
import 'package:verovio_dart/src/model/text_elements.dart'
    show RunningElement, TextElement, TextLayoutElement;
import 'package:verovio_dart/src/model/editorial_element.dart';
import 'package:verovio_dart/src/model/interfaces/duration_interface.dart'
    show DurationInterface;
import 'package:verovio_dart/src/model/atts/atts_conversion.dart';
import 'package:verovio_dart/src/model/control_elements_gen.dart';
import 'package:verovio_dart/src/model/layer_element.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart'
    show Accid, Artic, Beam, BeatRpt, BTrem, Chord, Custos, DivLine, Dot,
    Episema, FTrem, GraceGrp, HalfmRpt, KeyAccid, KeySig,
    Ligature, Liquescent, MeterSig, MeterSigGrp, MRest, MRpt, MRpt2,
    MSpace, MultiRest, MultiRpt, Nc, Neume, Oriscus, Plica, Proport,
    Quilisma, Space, Stem, Strophicus, Syl, Syllable, TabDurSym, TabGrp,
    Tuplet, Verse;
import 'package:verovio_dart/src/model/mensur.dart' show Mensur;
import 'package:verovio_dart/src/model/misc_elements_gen.dart';
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/model/scoredef.dart';
import 'package:verovio_dart/src/model/system_page_elements.dart';

/// The attribute name used for verovio page-based serializations
/// (mirrors `VEROVIO_SERIALIZATION` in vrvdef.h).
const String verovioSerialization = 'verovio';

/// This class is a file input stream for reading MEI files (mirrors
/// `vrv::MEIInput`).
class MeiInput extends Input {
  MeiInput(super.doc);

  /// The version of the file being read (mirrors `m_meiversion`).
  MeiversionMeiversion meiversion = MeiversionMeiversion.none;

  /// Whether we are reading page-based or score-based MEI (mirrors
  /// `m_readingScoreBased`).
  bool readingScoreBased = false;

  /// True once a scoreDef has been read (mirrors `m_hasScoreDef`).
  bool hasScoreDef = false;

  /// The comment to be attached to the next Object (mirrors `m_comment`).
  String comment = '';

  /// Deserializing flag for page-based serializations (mirrors
  /// `m_deserializing`).
  bool deserializing = false;

  /// The selected `<mdiv>` node (mirrors `m_selectedMdiv`).
  MeiXmlNode? selectedMdiv;

  /// Supported editorial element names (mirrors `s_editorialElementNames`).
  static const List<String> editorialElementNames = [
    'abbr', 'add', 'annot', 'app', 'choice', 'corr', 'damage', 'del', //
    'expan', 'lem', 'orig', 'rdg', 'ref', 'reg', 'restore', 'sic', //
    'subst', 'supplied', 'unclear',
  ];

  // -------------------------------------------------------------------------
  // Import / generic helpers
  // -------------------------------------------------------------------------

  @override
  @override
  bool import(String data) {
    final MeiXmlNode? root = parseMeiXml(data);
    if (root == null || root.childElements().isEmpty && root.name != 'mei') {
      logError('The tree of the MEI data cannot be parsed');
      return false;
    }
    final MeiXmlNode documentRoot =
        root.childElements().isNotEmpty ? root.childElements().first : root;
    if (deserializing) {
      doc.resetToSerialization();
      meiversion = MeiversionMeiversion.n51plusbasic; // MEI_CURRENT_VERSION
      final MeiXmlNode? pagesNode = documentRoot.child('pages') ??
          documentRoot.firstChild();
      if (pagesNode == null) {
        logError('No <pages> found in the serialization');
        return false;
      }
      return readPages(doc, pagesNode);
    } else {
      doc.reset();
      doc.setType(DocType.raw);
      return readDoc(documentRoot);
    }
  }

  /// Check if an element name is an editorial element name (mirrors
  /// `IsEditorialElementName`).
  bool isEditorialElementName(String elementName) =>
      editorialElementNames.contains(elementName);

  /// Normalize (trim) all attribute values of the element (mirrors
  /// `NormalizeAttributes`).
  void normalizeAttributes(MeiXmlNode xmlElement) {
    xmlElement.attributes.updateAll((key, value) => value.trim());
  }

  /// Store the @xml:id and pending comment on [object] (mirrors
  /// `SetMeiID`). Consumes the attribute from [reader].
  void setMeiID(MeiXmlNode element, Object object,
      [MeiAttributeReader? reader]) {
    if (comment.isNotEmpty) {
      object.comment = comment;
      comment = '';
    }

    if (!element.hasAttr('xml:id')) return;

    object.id = element.attr('xml:id')!;
    element.removeAttribute('xml:id');
    reader?.remove('xml:id');
  }

  /// Store remaining (unsupported) attributes into `object.unsupported`
  /// (mirrors `ReadUnsupportedAttr`).
  void readUnsupportedAttr(
      MeiAttributeReader reader, MeiXmlNode element, Object object) {
    for (final entry in reader.unsupported.entries) {
      object.unsupported.add((entry.key, entry.value));
    }
  }

  DocType strToDocType(String type) {
    switch (type) {
      case 'raw':
        return DocType.raw;
      case 'rendering':
        return DocType.rendering;
      case 'transcription':
        return DocType.transcription;
      case 'facsimile':
        return DocType.facs;
      default:
        logWarning("Unknown layout type '$type'");
        return DocType.raw;
    }
  }

  /// Attach a comment node to [object] or queue it for the next object
  /// (mirrors `ReadXMLComment`).
  bool readXMLComment(Object object, MeiXmlNode element) {
    if (element.nextSibling() != null) {
      comment = element.value ?? '';
    } else {
      object.closingComment = element.value ?? '';
    }
    return true;
  }

  /// True if the annot @type marks it as a score annotation (mirrors
  /// `IsAnnotScore`).
  bool isAnnotScore(MeiXmlNode annot) {
    final RegExp scoreRegex = RegExp(r'(^|\s)score($|\s)');
    final String? type = annot.attr('type');
    if (type == null) return false;
    return scoreRegex.hasMatch(type);
  }

  // Version comparisons used throughout the readers.
  bool _before400() => meiversion.value < MeiversionMeiversion.n400.value;
  bool _atOrBefore50() => meiversion.value <= MeiversionMeiversion.n50.value;
  bool _before50() => meiversion.value < MeiversionMeiversion.n50.value;
  bool _is2013() => meiversion == MeiversionMeiversion.n2013;

  // -------------------------------------------------------------------------
  // Base-class and interface readers
  // -------------------------------------------------------------------------

  /// Mirrors `MEIInput::ReadSystemElement`.
  void readSystemElement(
      MeiAttributeReader reader, MeiXmlNode element, SystemElement object) {
    setMeiID(element, object, reader);
    object.readTyped(reader);
  }

  /// Mirrors `MEIInput::ReadTextLayoutElement`.
  void readTextLayoutElement(
      MeiAttributeReader reader, MeiXmlNode element, TextLayoutElement object) {
    setMeiID(element, object, reader);
    object.readTyped(reader);
  }

  /// Mirrors `MEIInput::ReadRunningElement`.
  void readRunningElement(
      MeiAttributeReader reader, MeiXmlNode element, RunningElement object) {
    readTextLayoutElement(reader, element, object);
    object.readFormework(reader);

    if (deserializing) {
      if (element.hasAttr(verovioSerialization)) {
        if (element.attr(verovioSerialization) == 'generated') {
          object.isGeneratedFlag = true;
        }
        element.removeAttribute(verovioSerialization);
        reader.remove(verovioSerialization);
      }
    }
  }

  /// Mirrors `MEIInput::ReadScoreDefElement`.
  ///
  /// Reads clef / keySig / mensur / meterSig *attribute* definitions and
  /// adds them as `isAttribute` children of the scoreDef element.
  void readScoreDefElement(
      MeiAttributeReader reader, MeiXmlNode element, ScoreDefElement object) {
    setMeiID(element, object, reader);
    object.readTyped(reader);

    if (_atOrBefore50()) {
      upgradeScoreDefElementTo500(element);
    }

    // Consumes an attribute (marks it read in [reader]).
    String? take(String name) {
      final String? v = element.attr(name);
      if (v != null) reader.remove(name);
      return v;
    }

    // att.cleffing.log / att.cleffing.vis -> attribute Clef
    final String? clefShape = take('clef.shape');
    final String? clefLine = take('clef.line');
    final String? clefDis = take('clef.dis');
    final String? clefDisPlace = take('clef.dis.place');
    final String? clefColor = take('clef.color');
    final String? clefVisible = take('clef.visible');
    if (clefShape != null) {
      final Clef vrvClef = Clef();
      vrvClef.isAttribute = true;
      vrvClef.shape = strToClefshape(clefShape);
      if (clefLine != null) vrvClef.line = strToInt(clefLine);
      if (clefDis != null) vrvClef.dis = strToOctaveDis(clefDis);
      if (clefDisPlace != null) {
        vrvClef.disPlace = strToStaffrelBasic(clefDisPlace);
      }
      if (clefColor != null) vrvClef.color = clefColor;
      if (clefVisible != null) vrvClef.visible = strToBoolean(clefVisible);
      object.addChild(vrvClef);
    }

    // att.keySigDefault.* -> attribute KeySig
    final String? keyAccid = take('key.accid');
    final String? keyMode = take('key.mode');
    final String? keyPname = take('key.pname');
    final String? keysig = take('keysig');
    final String? keysigVisible = take('keysig.visible');
    final String? keysigCancelaccid = take('keysig.cancelaccid');
    if (keyAccid != null ||
        keyMode != null ||
        keyPname != null ||
        keysig != null ||
        keysigVisible != null ||
        keysigCancelaccid != null) {
      final KeySig vrvKeySig = KeySig();
      vrvKeySig.isAttribute = true;
      // Broken in MEI 4.0.2 - waiting for a fix (not reading @key.accid)
      if (keyMode != null) vrvKeySig.mode = strToMode(keyMode);
      if (keyPname != null) vrvKeySig.pname = strToPitchname(keyPname);
      if (keysig != null) vrvKeySig.sig = strToKeysignature(keysig);
      if (keysigVisible != null) {
        vrvKeySig.visible = strToBoolean(keysigVisible);
      }
      if (keysigCancelaccid != null) {
        vrvKeySig.cancelaccid = strToCancelaccid(keysigCancelaccid);
      }
      object.addChild(vrvKeySig);
    }

    // att.mensural.* -> attribute Mensur
    final String? mensurDot = take('mensur.dot');
    final String? proportNum = take('proport.num');
    final String? proportNumbase = take('proport.numbase');
    final String? mensurSign = take('mensur.sign');
    final String? mensurSlash = take('mensur.slash');
    final String? modusmaior = take('modusmaior');
    final String? modusminor = take('modusminor');
    final String? prolatio = take('prolatio');
    final String? tempus = take('tempus');
    final String? mensurColor = take('mensur.color');
    final String? mensurOrient = take('mensur.orient');
    if (mensurDot != null ||
        proportNum != null ||
        proportNumbase != null ||
        mensurSign != null ||
        mensurSlash != null ||
        modusmaior != null ||
        modusminor != null ||
        prolatio != null ||
        tempus != null ||
        mensurColor != null ||
        mensurOrient != null) {
      final Mensur vrvMensur = Mensur();
      vrvMensur.isAttribute = true;
      if (mensurDot != null) vrvMensur.dot = strToBoolean(mensurDot);
      if (proportNum != null) vrvMensur.num = strToInt(proportNum);
      if (proportNumbase != null) vrvMensur.numbase = strToInt(proportNumbase);
      if (mensurSign != null) {
        vrvMensur.sign = strToMensurationsign(mensurSign);
      }
      if (mensurSlash != null) vrvMensur.slash = strToInt(mensurSlash);
      if (modusmaior != null) vrvMensur.modusmaior = strToModusmaior(modusmaior);
      if (modusminor != null) vrvMensur.modusminor = strToModusminor(modusminor);
      if (prolatio != null) vrvMensur.prolatio = strToProlatio(prolatio);
      if (tempus != null) vrvMensur.tempus = strToTempus(tempus);
      if (mensurColor != null) vrvMensur.color = mensurColor;
      if (mensurOrient != null) {
        vrvMensur.orient = strToOrientation(mensurOrient);
      }

      if (_before50()) {
        upgradeMensurTo500(vrvMensur);
      }

      object.addChild(vrvMensur);
    }

    // att.meterSigDefault.* -> attribute MeterSig
    final String? meterCount = take('meter.count');
    final String? meterSym = take('meter.sym');
    final String? meterUnit = take('meter.unit');
    final String? meterForm = take('meter.form');
    final String? meterVisible = take('meter.visible');
    if (meterCount != null || meterSym != null || meterUnit != null) {
      final MeterSig vrvMeterSig = MeterSig();
      vrvMeterSig.isAttribute = true;
      if (meterCount != null) {
        vrvMeterSig.count = strToMetercountPair(meterCount);
      }
      if (meterSym != null) vrvMeterSig.sym = strToMetersign(meterSym);
      if (meterUnit != null) vrvMeterSig.unit = strToInt(meterUnit);
      if (meterForm != null) vrvMeterSig.form = strToMeterform(meterForm);
      if (meterVisible != null) {
        vrvMeterSig.visible = strToBoolean(meterVisible);
      }
      object.addChild(vrvMeterSig);
    }
  }

  /// Mirrors `MEIInput::ReadScoreDefInterface`.
  void readScoreDefInterface(
      MeiAttributeReader reader, MeiXmlNode element, ScoreDefElement object) {
    final dynamic dyn = object;
    dyn.readBarring(reader);
    dyn.readDurationDefault(reader);
    dyn.readLyricStyle(reader);
    dyn.readMeasureNumbers(reader);
    dyn.readMidiTempo(reader);
    dyn.readMmTempo(reader);
    dyn.readMultinumMeasures(reader);
    dyn.readOctaveDefault(reader);
    dyn.readPianoPedals(reader);
    dyn.readSpacing(reader);
    dyn.readSystems(reader);
  }

  /// Mirrors `MEIInput::ReadControlElement`.
  void readControlElement(
      MeiAttributeReader reader, MeiXmlNode element, ControlElement object) {
    setMeiID(element, object, reader);
    readAltSymInterface(reader, object);
    readLinkingInterface(reader, object);
    readOffsetInterface(reader, object);
    object.readColor(reader);
    object.readLabelled(reader);
    object.readTyped(reader);
  }

  /// Mirrors `MEIInput::ReadEditorialElement` (node/object variant).
  void readEditorialBase(
      MeiAttributeReader reader, MeiXmlNode element, EditorialElement object) {
    setMeiID(element, object, reader);

    if (deserializing) {
      if (element.hasAttr(verovioSerialization)) {
        if (element.attr(verovioSerialization) == 'hidden') {
          object.setVisibility(VisibilityType.hidden);
        }
        element.removeAttribute(verovioSerialization);
        reader.remove(verovioSerialization);
      }
    }

    object.readLabelled(reader);
    object.readTyped(reader);
  }

  /// Mirrors `MEIInput::ReadTextElement`.
  void readTextElementBase(
      MeiAttributeReader reader, MeiXmlNode element, TextElement object) {
    setMeiID(element, object, reader);
    object.readLabelled(reader);
    object.readTyped(reader);
  }

  /// Mirrors `MEIInput::ReadLayerElement`.
  void readLayerElement(
      MeiAttributeReader reader, MeiXmlNode element, LayerElement object) {
    setMeiID(element, object, reader);
    readFacsimileInterface(reader, object);
    readLinkingInterface(reader, object);
    object.readLabelled(reader);
    object.readTyped(reader);

    if (doc.isTranscription() && element.hasAttr('coord.x1')) {
      final dynamic dyn = object;
      dyn.readCoordX1(reader);
      dyn.drawingFacsX = (dyn.coordX1 as int?)! * definitionFactor;
    }
  }

  // Interface readers -------------------------------------------------------

  /// Mirrors `MEIInput::ReadAltSymInterface`.
  void readAltSymInterface(MeiAttributeReader reader, Object interface) {
    (interface as dynamic).readAltSym(reader);
  }

  /// Mirrors `MEIInput::ReadAreaPosInterface`.
  void readAreaPosInterface(MeiAttributeReader reader, Object interface) {
    final dynamic dyn = interface;
    dyn.readHorizontalAlign(reader);
    dyn.readVerticalAlign(reader);
  }

  /// Mirrors `MEIInput::ReadDurationInterface`.
  void readDurationInterface(MeiAttributeReader reader, Object interface) {
    if (_before400()) {
      upgradeDurGesTo400(reader, interface);
    }

    final dynamic dyn = interface;
    dyn.readAugmentDots(reader);
    dyn.readBeamSecondary(reader);
    dyn.readDurationGes(reader);
    dyn.readDurationLog(reader);
    dyn.readDurationQuality(reader);
    dyn.readDurationRatio(reader);
    dyn.readFermataPresent(reader);
    dyn.readStaffIdent(reader);

    if ((interface as DurationInterface).hasFermata) {
      doc.setMarkup(markupAnalyticalFermata);
    }
  }

  /// Mirrors `MEIInput::ReadLinkingInterface`.
  void readLinkingInterface(MeiAttributeReader reader, Object interface) {
    (interface as dynamic).readLinking(reader);
  }

  /// Mirrors `MEIInput::ReadFacsimileInterface`.
  void readFacsimileInterface(MeiAttributeReader reader, Object interface) {
    (interface as dynamic).readFacsimile(reader);
  }

  /// Mirrors `MEIInput::ReadOffsetInterface`.
  void readOffsetInterface(MeiAttributeReader reader, Object interface) {
    final dynamic dyn = interface;
    dyn.readVisualOffsetHo(reader);
    dyn.readVisualOffsetVo(reader);
  }

  /// Mirrors `MEIInput::ReadOffsetSpanningInterface`.
  void readOffsetSpanningInterface(MeiAttributeReader reader, Object interface) {
    final dynamic dyn = interface;
    dyn.readVisualOffset2Ho(reader);
    dyn.readVisualOffset2Vo(reader);
  }

  /// Mirrors `MEIInput::ReadPitchInterface`.
  void readPitchInterface(MeiAttributeReader reader, Object interface) {
    final dynamic dyn = interface;
    dyn.readNoteGes(reader);
    dyn.readOctave(reader);
    dyn.readPitch(reader);
    dyn.readPitchGes(reader);
  }

  /// Mirrors `MEIInput::ReadPlistInterface`.
  void readPlistInterface(MeiAttributeReader reader, Object interface) {
    (interface as dynamic).readPlist(reader);
  }

  /// Mirrors `MEIInput::ReadPositionInterface`.
  void readPositionInterface(MeiAttributeReader reader, Object interface) {
    final dynamic dyn = interface;
    dyn.readStaffLoc(reader);
    dyn.readStaffLocPitched(reader);
  }

  /// Mirrors `MEIInput::ReadTextDirInterface`.
  void readTextDirInterface(MeiAttributeReader reader, Object interface) {
    (interface as dynamic).readPlacementRelStaff(reader);
  }

  /// Mirrors `MEIInput::ReadTimePointInterface`.
  void readTimePointInterface(MeiAttributeReader reader, Object interface) {
    final dynamic dyn = interface;
    dyn.readPartIdent(reader);
    dyn.readStaffIdent(reader);
    dyn.readStartId(reader);
    dyn.readTimestampLog(reader);
  }

  /// Mirrors `MEIInput::ReadTimeSpanningInterface`.
  void readTimeSpanningInterface(MeiAttributeReader reader, Object interface) {
    readTimePointInterface(reader, interface);
    final dynamic dyn = interface;
    dyn.readStartEndId(reader);
    dyn.readTimestamp2Log(reader);
  }

  // -------------------------------------------------------------------------
  // Doc / mdiv / score
  // -------------------------------------------------------------------------

  /// Read the document (mirrors `ReadDoc`).
  bool readDoc(MeiXmlNode root) {
    bool success = true;
    readingScoreBased = true;

    if (root.hasAttr('meiversion')) {
      meiversion = strToMeiversionMeiversion(root.attr('meiversion')!);
    }
    // Default to MEI 6.0-dev
    if (meiversion == MeiversionMeiversion.none) {
      logWarning('MEI version found or not known, falling back to MEI 6.0-dev');
      meiversion = MeiversionMeiversion.n60Dev;
    }

    // only try to handle meiHead if we have a full MEI document
    if (root.name == 'mei') {
      final MeiXmlNode? head = root.child('meiHead');
      if (head == null) {
        logWarning('No header found in the MEI data, trying to proceed...');
      } else {
        // copy the complete header into the master document
        doc.header = head.copy();
      }
    }

    // music
    MeiXmlNode music;
    if (root.name == 'music') {
      music = root;
    } else {
      final MeiXmlNode? child = root.child('music');
      if (child == null) {
        logError('No <music> element found in the MEI data');
        return false;
      }
      music = child;
    }

    final MeiXmlNode? facsimile = music.child('facsimile');
    if (facsimile != null) {
      readFacsimile(facsimile);
      if (doc.getOptions().useFacsimile.value) {
        doc.setType(DocType.facs);
        doc.drawingPageHeight = doc.getFacsimile()?.getMaxY() ?? 0;
        doc.drawingPageWidth = doc.getFacsimile()?.getMaxX() ?? 0;
      }
      // Temporary solution to set the document type to Transcription when
      // using <facsimile>
      else if (doc.hasFacsimile() &&
          ((doc.getFacsimile()?.type ?? '').isNotEmpty)) {
        doc.setType(strToDocType(doc.getFacsimile()!.type!));
        // Facsimile data eventually sync via Doc::SyncFromFacsimileDoc
      }
      if (_nextSiblingElement(facsimile, 'facsimile') != null) {
        logWarning('Only first <facsimile> is processed');
      }
    }

    final MeiXmlNode? front = music.child('front');
    if (front != null) {
      // copy the complete front into the master document
      doc.front = front.copy();
    }

    final MeiXmlNode? back = music.child('back');
    if (back != null) {
      // copy the complete back into the master document
      doc.back = back.copy();
    }

    final MeiXmlNode? body = music.child('body');
    if (body == null) {
      logError('No <body> element found in the MEI data');
      return false;
    }

    final options = doc.getOptions();

    if (options.incip.value) {
      final MeiXmlNode header = doc.header as MeiXmlNode? ?? MeiXmlNode.element('#none');
      return readIncipits(header);
    }

    // Select the first mdiv by default
    MeiXmlNode? pages = body.child('pages');
    selectedMdiv = body.child('mdiv');

    if (selectedMdiv == null && pages == null) {
      logError('No <mdiv> or no <pages> element found in the MEI data');
      return false;
    } else if (selectedMdiv == null) {
      readingScoreBased = false;
    }
    // Old page-based files. We skip the mdiv and load the pages element.
    else if (selectedMdiv!.child('pages') != null && _is2013()) {
      pages = selectedMdiv!.child('pages');
      readingScoreBased = false;
    }

    // Reading score-based MEI
    if (readingScoreBased) {
      final String xPathQuery = options.mdivXPathQuery.value;
      // Give priority to mdiv-all - maybe we could give a warning
      if (!options.mdivAll.value && xPathQuery.isNotEmpty) {
        final MeiXmlNode? selection = selectNode(body, xPathQuery);
        if (selection != null) {
          selectedMdiv = selection;
        } else {
          logError("The <mdiv> requested with the xpath query '$xPathQuery' "
              'could not be found');
          return false;
        }
      } else {
        // Try to select the mdiv above the first score (if any) - if not, we
        // have pages or something is wrong
        final MeiXmlNode? scoreMdiv = selectFirstDescendantWhere(body, 'mdiv',
            (n) => n.childElements().any((c) => c.name == 'score'));
        if (scoreMdiv != null) {
          selectedMdiv = scoreMdiv;
        }
      }

      if (_countDescendants(selectedMdiv!, 'score') > 1) {
        logError('An <mdiv> with only one <score> descendant must be selected');
        return false;
      }

      if ((_countDescendants(selectedMdiv!, 'score') > 0) &&
          (_countDescendants(selectedMdiv!, 'pages') > 0)) {
        logError('An <mdiv> with only one <pages> or one <score> descendant '
            'must be selected');
        return false;
      }

      final bool allMdivVisible = options.mdivAll.value;
      success = readMdivChildren(doc, body, allMdivVisible);

      if (success) {
        doc.expandExpansions();
      }

      if (success) {
        doc.convertToPageBasedDoc();
        doc.convertMarkupDoc(!options.preserveAnalyticalMarkup.value);
      }

      if (success && !hasScoreDef) {
        logWarning('No scoreDef provided, trying to generate one...');
        success = doc.generateDocumentScoreDef();
      }
    }
    // Reading page-based MEI
    else {
      success = readPages(doc, pages!);

      if (success && !hasScoreDef) {
        logWarning('No scoreDef provided, trying to generate one...');
        success = doc.generateDocumentScoreDef();
      }
    }

    return success;
  }

  MeiXmlNode? _nextSiblingElement(MeiXmlNode node, String name) {
    MeiXmlNode? current = node.nextSibling();
    while (current != null) {
      if (current.isElement && current.name == name) return current;
      current = current.nextSibling();
    }
    return null;
  }

  int _countDescendants(MeiXmlNode node, String name) {
    int count = 0;
    void walk(MeiXmlNode n) {
      for (final MeiXmlNode child in n.children) {
        if (child.isElement && child.name == name) count++;
        walk(child);
      }
    }

    walk(node);
    return count;
  }

  /// Read incipits from the header (mirrors `ReadIncipits`; PAE-encoded
  /// incipits are skipped because PAE support is out of scope).
  bool readIncipits(MeiXmlNode header) {
    final List<MeiXmlNode> incipSet = [];
    _collectDescendantElements(header, 'incip', incipSet);
    if (incipSet.isEmpty) {
      logError('No <incip> element found in the MEI data');
      return false;
    }

    int incipCount = 0;
    bool success = true;

    for (final MeiXmlNode incip in incipSet) {
      if (!success) break;
      final MeiXmlNode? incipCode = incip.child('incipCode');
      if (incipCode != null) {
        final String form = incipCode.attr('form') ?? '';
        if (form != 'plaineAndEasie' && form != 'pae') {
          // We do not consider it an error if the format is not supported
          logWarning('Incipit format in <incipCode> is not a supported format '
              'and will be skipped.');
          continue;
        }
        logWarning('Plaine & Easie incipits are not supported in this build '
            'and will be skipped.');
        continue;
      } else if (!_firstIsNamed(incip, 'score')) {
        logWarning('Only <incip> with a <score> first child can be read.');
        // The incipit will not be removed from the header
        continue;
      } else {
        final Mdiv mdiv = Mdiv();
        mdiv.makeVisible();
        doc.addChild(mdiv);
        success = readMdivChildren(mdiv, incip, true);
      }
      // Remove it from the header
      if (success) {
        incipCount++;
        incip.parent?.removeChild(incip);
      }
    }
    // If no incipit has been read, then the input fails
    if (incipCount == 0) success = false;

    if (success) {
      doc.convertToPageBasedDoc();
      doc.convertMarkupDoc(!doc.getOptions().preserveAnalyticalMarkup.value);
    }

    return success;
  }

  bool _firstIsNamed(MeiXmlNode node, String name) {
    for (final MeiXmlNode child in node.children) {
      if (child.isElement) return child.name == name;
    }
    return false;
  }

  void _collectDescendantElements(
      MeiXmlNode node, String name, List<MeiXmlNode> out) {
    for (final MeiXmlNode child in node.children) {
      if (!child.isElement) continue;
      if (child.name == name) out.add(child);
      _collectDescendantElements(child, name, out);
    }
  }

  // -------------------------------------------------------------------------
  // Page-based structure
  // -------------------------------------------------------------------------

  /// Read a `<pages>` container (mirrors `ReadPages`).
  bool readPages(Object parent, MeiXmlNode pages) {
    final Pages vrvPages = Pages();
    final MeiAttributeReader reader = MeiAttributeReader(pages.attributes);
    setMeiID(pages, vrvPages, reader);
    vrvPages.readLabelled(reader);
    vrvPages.readNNumberLike(reader);

    parent.addChild(vrvPages);

    // check if there is a type attribute for the score
    if (pages.hasAttr('type')) {
      doc.setType(strToDocType(pages.attr('type')!));
      pages.removeAttribute('type');
      reader.remove('type');
    }

    // This is a page-based MEI file
    layoutInformation = LayoutInformation.done;

    bool success = true;
    MeiXmlNode? current = pages.firstChild();
    while (current != null) {
      if (!success) break;
      if (current.isElement && current.name == 'page') {
        success = readPage(vrvPages, current);
      }
      // xml comment
      else if (!current.isElement) {
        success = readXMLComment(parent, current);
      } else {
        logWarning("Unsupported '<${current.name}>' within <pages>");
      }
      current = current.nextSibling();
    }

    readUnsupportedAttr(reader, pages, vrvPages);
    return success;
  }

  /// Read a `<page>` (mirrors `ReadPage`).
  bool readPage(Object parent, MeiXmlNode page) {
    final Page vrvPage = Page();
    final MeiAttributeReader reader = MeiAttributeReader(page.attributes);
    setMeiID(page, vrvPage, reader);

    void takeInt(String name, void Function(int) set) {
      if (page.hasAttr(name)) {
        set(strToInt(page.attr(name)!) * definitionFactor);
        page.removeAttribute(name);
        reader.remove(name);
      }
    }

    takeInt('page.height', (v) => vrvPage.pageHeight = v);
    takeInt('page.width', (v) => vrvPage.pageWidth = v);
    takeInt('page.botmar', (v) => vrvPage.pageMarginBottom = v);
    takeInt('page.leftmar', (v) => vrvPage.pageMarginLeft = v);
    takeInt('page.rightmar', (v) => vrvPage.pageMarginRight = v);
    takeInt('page.topmar', (v) => vrvPage.pageMarginTop = v);

    if (page.hasAttr('surface')) {
      vrvPage.surface = page.attr('surface')!;
      page.removeAttribute('surface');
      reader.remove('surface');
    }
    if (page.hasAttr('ppu')) {
      vrvPage.ppufactor = strToDbl(page.attr('ppu')!);
      // The ppu attribute is consumed but not stored as unsupported either
      // way in the C++.
      reader.remove('ppu');
    }

    parent.addChild(vrvPage);
    final bool success = readPageChildren(vrvPage, page);

    // TODO(phase-4): ApplyPPUFactorFunctor for transcription docs.

    readUnsupportedAttr(reader, page, vrvPage);
    return success;
  }

  /// Read the children of a `<page>` (mirrors `ReadPageChildren`).
  bool readPageChildren(Object parent, MeiXmlNode parentNode) {
    MeiXmlNode? current = parentNode.firstChild();
    while (current != null) {
      if (current.isElement && current.name == 'mdiv') {
        readMdiv(parent, current, true);
      } else if (current.isElement && current.name == 'score') {
        readScore(parent, current);
      } else if (current.isElement && current.name == 'system') {
        readSystem(parent, current);
      }
      // mdiv in page-based MEI
      else if (current.isElement && current.name == 'mdivb') {
        readMdiv(parent, current, true);
      } else if (current.isElement && current.name == 'milestoneEnd') {
        readPageMilestoneEnd(parent, current);
      }
      // xml comment
      else if (!current.isElement) {
        readXMLComment(parent, current);
      } else {
        logWarning("Unsupported '<${current.name}>' within <page>");
      }
      current = current.nextSibling();
    }

    return true;
  }

  /// Read a page milestoneEnd (mirrors `ReadPageMilestoneEnd`).
  bool readPageMilestoneEnd(Object parent, MeiXmlNode milestoneEnd) {
    // Check that we have a @startid
    if (!milestoneEnd.hasAttr('startid')) {
      logError('Missing @startid on  milestoneEnd');
      return false;
    }

    final String startID = milestoneEnd.attr('startid')!;
    final Object? start = doc.findDescendantByID(extractIDFragment(startID));
    if (start == null) {
      logError("Could not find start element '$startID' for milestoneEnd");
      return false;
    }

    // Check that it is a page milestone
    if (start is! PageMilestoneInterface) {
      logError(
          "The start element  '$startID' is not a page milestone element");
      return false;
    }

    final PageMilestoneEnd vrvElementEnd = PageMilestoneEnd(start);
    setMeiID(milestoneEnd, vrvElementEnd);
    (start as PageMilestoneInterface).setPageMilestoneEnd(vrvElementEnd);

    parent.addChild(vrvElementEnd);
    return true;
  }

  /// Read an `<mdiv>` (mirrors `ReadMdiv`).
  bool readMdiv(Object parent, MeiXmlNode mdiv, bool isVisible) {
    final Mdiv vrvMdiv = Mdiv();
    final MeiAttributeReader reader = MeiAttributeReader(mdiv.attributes);
    setMeiID(mdiv, vrvMdiv, reader);
    vrvMdiv.readNNumberLike(reader);

    parent.addChild(vrvMdiv);

    if (deserializing) {
      if (mdiv.hasAttr(verovioSerialization)) {
        isVisible = (mdiv.attr(verovioSerialization) != 'hidden');
        mdiv.removeAttribute(verovioSerialization);
        reader.remove(verovioSerialization);
      }
    }

    if (isVisible) {
      vrvMdiv.makeVisible();
    }

    readUnsupportedAttr(reader, mdiv, vrvMdiv);
    return readMdivChildren(vrvMdiv, mdiv, isVisible);
  }

  /// Read the children of an `<mdiv>` (mirrors `ReadMdivChildren`).
  bool readMdivChildren(Object parent, MeiXmlNode parentNode, bool isVisible) {
    if (!readingScoreBased && !deserializing) {
      if (parentNode.firstChild() != null) {
        logWarning('Unexpected <mdiv> content in page-based MEI');
      }
      return true;
    }

    MeiXmlNode? current = parentNode.firstChild();
    bool success = true;
    while (current != null) {
      // We make the mdiv visible if already set or if matching the selection
      final bool makeVisible = isVisible || identical(selectedMdiv, current);
      if (!success) break;
      if (current.isElement && current.name == 'mdiv') {
        success = readMdiv(parent, current, makeVisible);
      } else if (current.isElement && current.name == 'score') {
        // Possibly skip content on load
        if (!isVisible && doc.getOptions().loadSelectedMdivOnly.value) {
          current = current.nextSibling();
          continue;
        }
        // Read only the first score
        success = readScore(parent, current);
        if (parentNode.lastChild() != current) {
          logWarning('Skipping nodes after <score> element');
        }
        break;
      }
      // xml comment
      else if (!current.isElement) {
        success = readXMLComment(parent, current);
      } else {
        logWarning("Unsupported '<${current.name}>' within <mdiv>");
      }
      current = current.nextSibling();
    }

    return success;
  }

  /// Read a `<score>` (mirrors `ReadScore`).
  bool readScore(Object parent, MeiXmlNode score) {
    final Score vrvScore = Score();
    MeiAttributeReader reader = MeiAttributeReader(score.attributes);
    setMeiID(score, vrvScore, reader);
    vrvScore.readLabelled(reader);
    vrvScore.readNNumberLike(reader);

    parent.addChild(vrvScore);

    // This is a score-based MEI file
    readingScoreBased = true;

    // This actually sets the top-level ScoreDef for the Score.
    // Use a temporary score to read it (including editorial markup).
    final Score tmpScore = Score();
    final bool success0 = readScoreScoreDef(tmpScore, score);
    // Detach the first child
    final Object? subtree = tmpScore.detachChild(0);
    Object? scoreScoreDef;
    if (subtree == null || subtree.classId == ClassId.scoreDef) {
      scoreScoreDef = subtree;
    } else {
      scoreScoreDef = subtree.findDescendantByType(ClassId.scoreDef);
    }
    if (scoreScoreDef == null) {
      logError('No top-level scoreDef could be read as child or direct '
          'descendant of score.');
      return false;
    }
    vrvScore.setScoreDefSubtree(subtree, scoreScoreDef);
    hasScoreDef = true;

    if (!success0) return false;

    // We start from the second child (first one is the scoreDef subtree)
    bool success = true;
    MeiXmlNode? current = score.firstChild();
    current = current?.nextSibling();
    while (current != null) {
      if (!success) break;
      normalizeAttributes(current);
      final String elementName = current.name;
      // editorial
      if (isEditorialElementName(current.name)) {
        success =
            readEditorialElement(vrvScore, current, EditorialLevel.topLevel);
      }
      // content
      else if (elementName == 'ending') {
        success = readEnding(vrvScore, current);
      } else if (elementName == 'section') {
        success = readSection(vrvScore, current);
      } else if (elementName == 'sb') {
        success = readSb(vrvScore, current);
      } else if (elementName == 'pb') {
        success = readPb(vrvScore, current);
      }
      // xml comment
      else if (!current.isElement) {
        success = readXMLComment(parent, current);
      } else {
        logWarning('Element <$elementName> within <score> is not supported '
            'and will be ignored ');
      }
      current = current.nextSibling();
    }

    readUnsupportedAttr(reader, score, vrvScore);
    return success;
  }

  /// Read the scoreDef of a score (mirrors `ReadScoreScoreDef`).
  bool readScoreScoreDef(Object parent, MeiXmlNode parentNode) {
    bool success = false;

    // We look only at the first child for the scoreDef or the editorial tree.
    final MeiXmlNode? firstChild = parentNode.firstChild();
    // We return true because we can have empty editorial markup parents.
    if (firstChild == null || !firstChild.isElement) return true;

    if (isEditorialElementName(firstChild.name)) {
      success = readEditorialElement(parent, firstChild, EditorialLevel.score);
    } else if (firstChild.name == 'scoreDef') {
      success = readScoreDef(parent, firstChild);
    }

    return success;
  }

  // -------------------------------------------------------------------------
  // Sections / endings / expansions / pb / sb / systems
  // -------------------------------------------------------------------------

  /// Read a `<section>` (mirrors `ReadSection`).
  bool readSection(Object parent, MeiXmlNode section) {
    final Section vrvSection = Section();
    MeiAttributeReader reader = MeiAttributeReader(section.attributes);
    readSystemElement(reader, section, vrvSection);

    if (vrvSection.type == neumeLineType) {
      doc.setNeumeLines(true);
      return readSectionChildren(parent, section);
    }

    vrvSection.readNNumberLike(reader);
    vrvSection.readSectionVis(reader);

    parent.addChild(vrvSection);
    readUnsupportedAttr(reader, section, vrvSection);
    if (readingScoreBased) {
      return readSectionChildren(vrvSection, section);
    } else if (section.firstChild() != null) {
      logWarning('Unexpected <section> content in page-based MEI');
    }
    return true;
  }

  /// Read the children of a section-like element (mirrors
  /// `ReadSectionChildren`).
  bool readSectionChildren(Object parent, MeiXmlNode parentNode) {
    bool success = true;
    Measure? unmeasured;
    MeiXmlNode? current = parentNode.firstChild();
    while (current != null) {
      if (!success) break;
      normalizeAttributes(current);
      // editorial
      if (isEditorialElementName(current.name)) {
        success =
            readEditorialElement(parent, current, EditorialLevel.topLevel);
      }
      // content
      else if (current.name == 'div') {
        success = readDiv(parent, current);
      } else if (current.name == 'ending') {
        // we should not have endings with unmeasured music ...
        assert(unmeasured == null);
        success = readEnding(parent, current);
      } else if (current.name == 'expansion') {
        success = readExpansion(parent, current);
      } else if (current.name == 'scoreDef') {
        success = readScoreDef(parent, current);
      } else if (current.name == 'section') {
        success = readSection(parent, current);
      }
      // pb and sb
      else if (current.name == 'pb') {
        success = readPb(parent, current);
      } else if (current.name == 'sb') {
        success = readSb(parent, current);
      }
      // unmeasured music
      else if (current.name == 'staff') {
        if (unmeasured == null) {
          if (parent.classId == ClassId.section) {
            unmeasured = _newUnmeasured();
            parent.addChild(unmeasured);
          } else {
            logError('Unmeasured music within editorial markup is currently '
                'not supported');
            return false;
          }
        }
        success = readStaff(unmeasured, current);
      } else if (current.name == 'measure') {
        // no mixing of measured and unmeasured music within a system...
        assert(unmeasured == null);
        success = readMeasure(parent, current);
      }
      // xml comment
      else if (!current.isElement) {
        success = readXMLComment(parent, current);
      } else {
        logWarning("Unsupported '<${current.name}>' within <section>");
      }
      current = current.nextSibling();
    }

    // New <measure> for blank files in neume notation
    if (unmeasured == null &&
        parent.classId == ClassId.section &&
        doc.notationType == Notationtype.neume &&
        parent.findDescendantByType(ClassId.measure) == null) {
      final Measure measure = _newUnmeasured();
      parent.addChild(measure);
    }
    return success;
  }

  Measure _newUnmeasured() {
    if (doc.isNeumeLines()) {
      return Measure(MeasureType.neumeLine);
    } else {
      doc.setMensuralMusicOnly(true);
      return Measure(MeasureType.unmeasured);
    }
  }

  /// Read an `<ending>` (mirrors `ReadEnding`).
  bool readEnding(Object parent, MeiXmlNode ending) {
    final Ending vrvEnding = Ending();
    MeiAttributeReader reader = MeiAttributeReader(ending.attributes);
    readSystemElement(reader, ending, vrvEnding);

    vrvEnding.readLabelled(reader);
    vrvEnding.readLineRend(reader);
    vrvEnding.readLineRendBase(reader);
    vrvEnding.readNNumberLike(reader);

    parent.addChild(vrvEnding);
    readUnsupportedAttr(reader, ending, vrvEnding);
    if (readingScoreBased) {
      return readSectionChildren(vrvEnding, ending);
    }
    return true;
  }

  /// Read an `<expansion>` (mirrors `ReadExpansion`).
  bool readExpansion(Object parent, MeiXmlNode expansion) {
    final Expansion vrvExpansion = Expansion();
    MeiAttributeReader reader = MeiAttributeReader(expansion.attributes);
    readSystemElement(reader, expansion, vrvExpansion);
    readPlistInterface(reader, vrvExpansion);

    parent.addChild(vrvExpansion);
    readUnsupportedAttr(reader, expansion, vrvExpansion);
    if (readingScoreBased) {
      return readSectionChildren(vrvExpansion, expansion);
    }
    return true;
  }

  /// Read a `<pb>` (mirrors `ReadPb`).
  bool readPb(Object parent, MeiXmlNode pb) {
    layoutInformation = LayoutInformation.encoded;

    final Pb vrvPb = Pb();
    MeiAttributeReader reader = MeiAttributeReader(pb.attributes);
    readSystemElement(reader, pb, vrvPb);
    readFacsimileInterface(reader, vrvPb);

    vrvPb.readNNumberLike(reader);

    parent.addChild(vrvPb);
    readUnsupportedAttr(reader, pb, vrvPb);
    return true;
  }

  /// Read an `<sb>` (mirrors `ReadSb`).
  ///
  /// A `<sb>` alone is considered enough indication that we have encoded
  /// layout information (this is debatable - see the C++ comment).
  bool readSb(Object parent, MeiXmlNode sb) {
    layoutInformation = LayoutInformation.encoded;

    final Sb vrvSb = Sb();
    MeiAttributeReader reader = MeiAttributeReader(sb.attributes);
    readSystemElement(reader, sb, vrvSb);
    readFacsimileInterface(reader, vrvSb);

    vrvSb.readNNumberLike(reader);

    parent.addChild(vrvSb);
    readUnsupportedAttr(reader, sb, vrvSb);
    return true;
  }

  /// Read a `<system>` (mirrors `ReadSystem`).
  bool readSystem(Object parent, MeiXmlNode system) {
    final System vrvSystem = System();
    MeiAttributeReader reader = MeiAttributeReader(system.attributes);
    setMeiID(system, vrvSystem, reader);
    vrvSystem.readTyped(reader);

    if (system.hasAttr('system.leftmar')) {
      vrvSystem.systemLeftMar = strToInt(system.attr('system.leftmar')!);
      system.removeAttribute('system.leftmar');
      reader.remove('system.leftmar');
    }
    if (system.hasAttr('system.rightmar')) {
      vrvSystem.systemRightMar = strToInt(system.attr('system.rightmar')!);
      system.removeAttribute('system.rightmar');
      reader.remove('system.rightmar');
    }
    if (system.hasAttr('uly') && doc.isTranscription()) {
      vrvSystem.drawingFacsY =
          strToInt(system.attr('uly')!) * definitionFactor;
      system.removeAttribute('uly');
      reader.remove('uly');
    }

    parent.addChild(vrvSystem);
    readUnsupportedAttr(reader, system, vrvSystem);
    return readSystemChildren(vrvSystem, system);
  }

  /// Read the children of a system (mirrors `ReadSystemChildren`).
  bool readSystemChildren(Object parent, MeiXmlNode parentNode) {
    bool success = true;
    Measure? unmeasured;
    MeiXmlNode? current = parentNode.firstChild();
    while (current != null) {
      if (!success) break;
      normalizeAttributes(current);
      // editorial
      if (isEditorialElementName(current.name)) {
        success =
            readEditorialElement(parent, current, EditorialLevel.topLevel);
      }
      // section / section in page-based MEI
      else if (current.name == 'section' || current.name == 'secb') {
        success = readSection(parent, current);
      } else if (current.name == 'milestoneEnd') {
        success = readSystemMilestoneEnd(parent, current);
      }
      // content
      else if (current.name == 'scoreDef') {
        // we should not have scoredef with unmeasured music within a system
        assert(unmeasured == null);
        readScoreDef(parent, current);
      }
      // unmeasured music
      else if (current.name == 'staff') {
        if (unmeasured == null) {
          if (parent.classId == ClassId.system) {
            final System system = parent as System;
            unmeasured = Measure(MeasureType.unmeasured);
            doc.setMensuralMusicOnly(true);
            system.addChild(unmeasured);
          } else {
            logError('Unmeasured music within editorial markup is currently '
                'not supported');
            return false;
          }
        }
        success = readStaff(unmeasured, current);
      } else if (current.name == 'measure') {
        assert(unmeasured == null);
        success = readMeasure(parent, current);
      } else if (deserializing) {
        if (current.name == 'pb') {
          success = readPb(parent, current);
        } else if (current.name == 'sb') {
          success = readSb(parent, current);
        }
      }
      // xml comment
      else if (!current.isElement) {
        success = readXMLComment(parent, current);
      } else {
        logWarning("Unsupported '<${current.name}>' within <system>");
      }
      current = current.nextSibling();
    }
    return success;
  }

  /// Read a system milestoneEnd (mirrors `ReadSystemMilestoneEnd`).
  bool readSystemMilestoneEnd(Object parent, MeiXmlNode milestoneEnd) {
    if (!milestoneEnd.hasAttr('startid')) {
      logError('Missing @startid on  milestoneEnd');
      return false;
    }

    final String startID = milestoneEnd.attr('startid')!;
    final Object? start = doc.findDescendantByID(extractIDFragment(startID));
    if (start == null) {
      logError("Could not find start element '$startID' for milestoneEnd");
      return false;
    }

    if (start is! SystemMilestoneInterface) {
      logError(
          "The start element  '$startID' is not a system milestone element");
      return false;
    }

    final SystemMilestoneEnd vrvElementEnd = SystemMilestoneEnd(start);
    setMeiID(milestoneEnd, vrvElementEnd);
    (start as SystemMilestoneInterface).setSystemMilestoneEnd(vrvElementEnd);

    parent.addChild(vrvElementEnd);
    return true;
  }

  // -------------------------------------------------------------------------
  // scoreDef family
  // -------------------------------------------------------------------------

  /// Read a `<scoreDef>` (mirrors `ReadScoreDef`).
  bool readScoreDef(Object parent, MeiXmlNode scoreDef) {
    final ScoreDef vrvScoreDef = ScoreDef();
    parent.addChild(vrvScoreDef);
    MeiAttributeReader reader = MeiAttributeReader(scoreDef.attributes);
    readScoreDefElement(reader, scoreDef, vrvScoreDef);

    if (_before400()) {
      upgradeScoreDefElementTo400(reader, scoreDef, vrvScoreDef);
    }

    if (doc.getOptions().moveScoreDefinitionToStaff.value) {
      if (vrvScoreDef.hasClefInfo() ||
          vrvScoreDef.hasKeySigInfo() ||
          vrvScoreDef.hasMeterSigGrpInfo() ||
          vrvScoreDef.hasMeterSigInfo() ||
          vrvScoreDef.hasMensurInfo()) {
        doc.setMarkup(markupScoredefDefinitions);
      }
    }

    readScoreDefInterface(reader, scoreDef, vrvScoreDef);
    final dynamic dyn = vrvScoreDef;
    dyn.readDistances(reader);
    dyn.readEndings(reader);
    dyn.readOptimization(reader);
    dyn.readTimeBase(reader);
    dyn.readTuning(reader);

    readUnsupportedAttr(reader, scoreDef, vrvScoreDef);
    return readScoreDefChildren(vrvScoreDef, scoreDef);
  }

  /// Read the children of a `<scoreDef>` (mirrors `ReadScoreDefChildren`).
  bool readScoreDefChildren(Object parent, MeiXmlNode parentNode) {
    bool success = true;
    MeiXmlNode? current = parentNode.firstChild();
    while (current != null) {
      if (!success) break;
      normalizeAttributes(current);
      // editorial
      if (isEditorialElementName(current.name)) {
        success =
            readEditorialElement(parent, current, EditorialLevel.scoreDef);
      }
      // clef, keySig, etc.
      else if (current.name == 'clef') {
        success = readClef(parent, current);
      } else if (current.name == 'grpSym') {
        success = readGrpSym(parent, current);
      } else if (current.name == 'keySig') {
        success = readKeySig(parent, current);
      } else if (current.name == 'mensur') {
        success = readMensur(parent, current);
      } else if (current.name == 'meterSig') {
        success = readMeterSig(parent, current);
      } else if (current.name == 'meterSigGrp') {
        success = readMeterSigGrp(parent, current);
      }
      // headers and footers
      else if (current.name == 'pgFoot' || current.name == 'pgFoot2') {
        if (_atOrBefore50()) upgradePgHeadFootTo500(current);
        success = readPgFoot(parent, current);
      } else if (current.name == 'pgHead' || current.name == 'pgHead2') {
        if (_atOrBefore50()) upgradePgHeadFootTo500(current);
        success = readPgHead(parent, current);
      }
      // symbolTable
      else if (current.name == 'symbolTable') {
        success = readSymbolTable(parent, current);
      }
      // content
      else if (current.name == 'staffGrp') {
        success = readStaffGrp(parent, current);
      }
      // xml comment
      else if (!current.isElement) {
        success = readXMLComment(parent, current);
      } else {
        logWarning("Unsupported '<${current.name}>' within <scoreDef>");
      }
      current = current.nextSibling();
    }
    return success;
  }

  /// Read a `<staffGrp>` (mirrors `ReadStaffGrp`).
  bool readStaffGrp(Object parent, MeiXmlNode staffGrp) {
    final StaffGrp vrvStaffGrp = StaffGrp();
    MeiAttributeReader reader = MeiAttributeReader(staffGrp.attributes);
    setMeiID(staffGrp, vrvStaffGrp, reader);

    if (_before400()) {
      upgradeStaffGrpTo400(staffGrp, vrvStaffGrp);
    }

    vrvStaffGrp.readBarring(reader);
    vrvStaffGrp.readBasic(reader);
    vrvStaffGrp.readLabelled(reader);
    vrvStaffGrp.readNNumberLike(reader);

    // att.staffGroupingSym -> attribute GrpSym
    final String? groupingSymbol = staffGrp.attr('symbol');
    if (groupingSymbol != null) {
      reader.remove('symbol');
      final GrpSym vrvGrpSym = GrpSym();
      vrvGrpSym.isAttribute = true;
      vrvGrpSym.symbol = strToStaffgroupingsymSymbol(groupingSymbol);
      vrvStaffGrp.addChild(vrvGrpSym);
    }

    vrvStaffGrp.readStaffGrpVis(reader);
    vrvStaffGrp.readTyped(reader);

    parent.addChild(vrvStaffGrp);
    readUnsupportedAttr(reader, staffGrp, vrvStaffGrp);
    return readStaffGrpChildren(vrvStaffGrp, staffGrp);
  }

  /// Read the children of a `<staffGrp>` (mirrors `ReadStaffGrpChildren`).
  bool readStaffGrpChildren(Object parent, MeiXmlNode parentNode) {
    bool success = true;
    bool missingStaffDef = true;
    MeiXmlNode? current = parentNode.firstChild();
    while (current != null) {
      if (!success) break;
      normalizeAttributes(current);
      // editorial
      if (isEditorialElementName(current.name)) {
        success =
            readEditorialElement(parent, current, EditorialLevel.staffGrp);
      }
      // content
      else if (current.name == 'grpSym') {
        success = readGrpSym(parent, current);
      } else if (current.name == 'instrDef') {
        success = readInstrDef(parent, current);
      } else if (current.name == 'label') {
        success = readLabel(parent, current);
      } else if (current.name == 'labelAbbr') {
        success = readLabelAbbr(parent, current);
      } else if (current.name == 'staffGrp') {
        success = readStaffGrp(parent, current);
        // innermost staffGrp child will report missing staffDef
        missingStaffDef = false;
      } else if (current.name == 'staffDef') {
        success = readStaffDef(parent, current);
        missingStaffDef = false;
      }
      // xml comment
      else if (!current.isElement) {
        success = readXMLComment(parent, current);
      } else {
        logWarning("Unsupported '<${current.name}>' within <staffGrp>");
      }
      current = current.nextSibling();
    }

    // Missing staffDefs lead to crashes in the ScoreDefSetCurrent functor
    if (success && missingStaffDef) {
      logError('Each <staffGrp> must contain at least one <staffDef>.');
      success = false;
    }

    return success;
  }

  /// Read a `<grpSym>` (mirrors `ReadGrpSym`).
  bool readGrpSym(Object parent, MeiXmlNode grpSym) {
    final GrpSym vrvGrpSym = GrpSym();
    MeiAttributeReader reader = MeiAttributeReader(grpSym.attributes);
    setMeiID(grpSym, vrvGrpSym, reader);

    final dynamic dyn = vrvGrpSym;
    dyn.readColor(reader);
    dyn.readGrpSymLog(reader);
    dyn.readStaffGroupingSym(reader);
    dyn.readStartId(reader);
    dyn.readStartEndId(reader);

    if (parent.classId == ClassId.scoreDef) {
      if (!(dyn.hasLevel as bool) || !(dyn.hasStartid as bool) ||
          !(dyn.hasEndid as bool)) {
        logWarning("<${grpSym.name}' nested under <scoreDef> must have "
            '@level, @startId and @endId attributes');
        return true;
      }
    }

    parent.addChild(vrvGrpSym);
    readUnsupportedAttr(reader, grpSym, vrvGrpSym);
    return true;
  }

  /// Read a `<pgFoot>` (mirrors `ReadPgFoot`).
  bool readPgFoot(Object parent, MeiXmlNode pgFoot) {
    final PgFoot vrvPgFoot = PgFoot();
    MeiAttributeReader reader = MeiAttributeReader(pgFoot.attributes);
    readRunningElement(reader, pgFoot, vrvPgFoot);

    parent.addChild(vrvPgFoot);
    readUnsupportedAttr(reader, pgFoot, vrvPgFoot);
    return readRunningChildren(vrvPgFoot, pgFoot, vrvPgFoot);
  }

  /// Read a `<pgHead>` (mirrors `ReadPgHead`).
  bool readPgHead(Object parent, MeiXmlNode pgHead) {
    final PgHead vrvPgHead = PgHead();
    MeiAttributeReader reader = MeiAttributeReader(pgHead.attributes);
    readRunningElement(reader, pgHead, vrvPgHead);

    parent.addChild(vrvPgHead);
    readUnsupportedAttr(reader, pgHead, vrvPgHead);
    return readRunningChildren(vrvPgHead, pgHead, vrvPgHead);
  }

  /// Read a `<div>` (mirrors `ReadDiv`).
  bool readDiv(Object parent, MeiXmlNode div) {
    final Div vrvDiv = Div();
    MeiAttributeReader reader = MeiAttributeReader(div.attributes);
    readTextLayoutElement(reader, div, vrvDiv);

    parent.addChild(vrvDiv);
    readUnsupportedAttr(reader, div, vrvDiv);
    return readRunningChildren(vrvDiv, div, vrvDiv);
  }

  /// Read the children of running elements (mirrors `ReadRunningChildren`).
  bool readRunningChildren(Object parent, MeiXmlNode parentNode,
      [Object? filter]) {
    bool success = true;
    MeiXmlNode? xmlElement = parentNode.firstChild();
    while (xmlElement != null) {
      if (!success) break;
      normalizeAttributes(xmlElement);
      final String elementName = xmlElement.name;
      if (filter != null && !isAllowed(elementName, filter)) {
        logWarning('Element <$elementName> within <${filter.className}> is '
            'not supported and will be ignored ');
        xmlElement = xmlElement.nextSibling();
        continue;
      }
      // editorial
      if (isEditorialElementName(xmlElement.name)) {
        success = readEditorialElement(
            parent, xmlElement, EditorialLevel.running, filter);
      }
      // content
      else if (elementName == 'fig') {
        success = readFig(parent, xmlElement);
      } else if (elementName == 'rend') {
        success = readRend(parent, xmlElement);
      }
      // xml comment
      else if (!xmlElement.isElement) {
        success = readXMLComment(parent, xmlElement);
      }
      // unknown
      else {
        logWarning('Element <$elementName> is unknown and will be ignored');
      }
      xmlElement = xmlElement.nextSibling();
    }
    return success;
  }

  /// Read a `<staffDef>` (mirrors `ReadStaffDef`).
  bool readStaffDef(Object parent, MeiXmlNode staffDef) {
    final StaffDef vrvStaffDef = StaffDef();
    MeiAttributeReader reader = MeiAttributeReader(staffDef.attributes);
    readScoreDefElement(reader, staffDef, vrvStaffDef);

    if (_before400()) {
      upgradeScoreDefElementTo400(reader, staffDef, vrvStaffDef);
      upgradeStaffDefTo400(staffDef, vrvStaffDef);
    }

    final dynamic dyn = vrvStaffDef;
    dyn.readDistances(reader);
    dyn.readLabelled(reader);
    dyn.readNInteger(reader);
    dyn.readNotationType(reader);
    dyn.readScalable(reader);
    dyn.readStaffDefLog(reader);
    dyn.readStaffDefVis(reader);
    dyn.readStaffDefVisTablature(reader);
    dyn.readTimeBase(reader);
    dyn.readTransposition(reader);

    if (!(dyn.hasN as bool)) {
      logWarning('No @n on <staffDef> might yield unpredictable results');
    }

    readScoreDefInterface(reader, staffDef, vrvStaffDef);

    doc.notationType = vrvStaffDef.notationtype ?? Notationtype.none;

    parent.addChild(vrvStaffDef);
    readUnsupportedAttr(reader, staffDef, vrvStaffDef);
    return readStaffDefChildren(vrvStaffDef, staffDef);
  }

  /// Read the children of a `<staffDef>` (mirrors `ReadStaffDefChildren`).
  bool readStaffDefChildren(Object parent, MeiXmlNode parentNode) {
    bool success = true;
    MeiXmlNode? current = parentNode.firstChild();
    while (current != null) {
      if (!success) break;
      normalizeAttributes(current);
      // clef, keySig, etc.
      if (current.name == 'clef') {
        success = readClef(parent, current);
      } else if (current.name == 'keySig') {
        success = readKeySig(parent, current);
      } else if (current.name == 'mensur') {
        success = readMensur(parent, current);
      } else if (current.name == 'meterSig') {
        success = readMeterSig(parent, current);
      } else if (current.name == 'meterSigGrp') {
        success = readMeterSigGrp(parent, current);
      }
      // content
      else if (current.name == 'instrDef') {
        success = readInstrDef(parent, current);
      } else if (current.name == 'label') {
        success = readLabel(parent, current);
      } else if (current.name == 'labelAbbr') {
        success = readLabelAbbr(parent, current);
      } else if (current.name == 'layerDef') {
        success = readLayerDef(parent, current);
      } else if (current.name == 'tuning') {
        success = readTuning(parent, current);
      }
      // xml comment
      else if (!current.isElement) {
        success = readXMLComment(parent, current);
      } else {
        logWarning("Unsupported '<${current.name}>' within <staffGrp>");
      }
      current = current.nextSibling();
    }
    return success;
  }

  /// Read a `<tuning>` (mirrors `ReadTuning`).
  bool readTuning(Object parent, MeiXmlNode tuning) {
    final Tuning vrvTuning = Tuning();
    MeiAttributeReader reader = MeiAttributeReader(tuning.attributes);
    setMeiID(tuning, vrvTuning, reader);

    parent.addChild(vrvTuning);
    vrvTuning.readTuningLog(reader);

    readUnsupportedAttr(reader, tuning, vrvTuning);
    return readTuningChildren(vrvTuning, tuning);
  }

  /// Read the children of a `<tuning>` (mirrors `ReadTuningChildren`).
  bool readTuningChildren(Object parent, MeiXmlNode parentNode) {
    bool success = true;
    MeiXmlNode? current = parentNode.firstChild();
    while (current != null) {
      if (!success) break;
      normalizeAttributes(current);
      // content
      if (current.name == 'course') {
        success = readCourse(parent, current);
      } else {
        logWarning("Unsupported '<${current.name}>' within <tuning>");
      }
      current = current.nextSibling();
    }
    return success;
  }

  /// Read a `<course>` (mirrors `ReadCourse`).
  bool readCourse(Object parent, MeiXmlNode course) {
    final Course vrvCourse = Course();
    MeiAttributeReader reader = MeiAttributeReader(course.attributes);
    setMeiID(course, vrvCourse, reader);

    parent.addChild(vrvCourse);
    final dynamic dyn = vrvCourse;
    dyn.readAccidental(reader);
    dyn.readNNumberLike(reader);
    dyn.readOctave(reader);
    dyn.readPitch(reader);

    readUnsupportedAttr(reader, course, vrvCourse);

    return true;
  }

  /// Read a `<symbolTable>` (mirrors `ReadSymbolTable`).
  bool readSymbolTable(Object parent, MeiXmlNode symbolTable) {
    final SymbolTable vrvSymbolTable = SymbolTable();
    MeiAttributeReader reader = MeiAttributeReader(symbolTable.attributes);
    setMeiID(symbolTable, vrvSymbolTable, reader);

    parent.addChild(vrvSymbolTable);

    bool success = true;
    MeiXmlNode? current = symbolTable.firstChild();
    while (current != null) {
      if (!success) break;
      normalizeAttributes(current);
      // symbolDef
      if (current.isElement && current.name == 'symbolDef') {
        success = readSymbolDef(vrvSymbolTable, current);
      }
      // xml comment
      else if (!current.isElement) {
        success = readXMLComment(parent, current);
      } else {
        logWarning("Unsupported '<${current.name}>' within <symbolTable>");
      }
      current = current.nextSibling();
    }

    readUnsupportedAttr(reader, symbolTable, vrvSymbolTable);
    return success;
  }

  /// Read an `<instrDef>` (mirrors `ReadInstrDef`; note: no unsupported-attr
  /// collection in the C++ either).
  bool readInstrDef(Object parent, MeiXmlNode instrDef) {
    final InstrDef vrvInstrDef = InstrDef();
    MeiAttributeReader reader = MeiAttributeReader(instrDef.attributes);
    setMeiID(instrDef, vrvInstrDef, reader);

    if (_before400()) {
      if (instrDef.hasAttr('midi.volume')) {
        final double midiValue = strToDbl(instrDef.attr('midi.volume')!);
        final String percent =
            '${(midiValue / 127 * 100 * 100).roundToDouble() / 100}%';
        instrDef.setAttribute('midi.volume', percent);
      }
    }

    parent.addChild(vrvInstrDef);
    final dynamic dyn = vrvInstrDef;
    dyn.readChannelized(reader);
    dyn.readLabelled(reader);
    dyn.readMidiInstrument(reader);
    dyn.readNNumberLike(reader);

    return true;
  }

  /// Read a `<label>` (mirrors `ReadLabel`).
  bool readLabel(Object parent, MeiXmlNode label) {
    final Label vrvLabel = Label();
    MeiAttributeReader reader = MeiAttributeReader(label.attributes);
    setMeiID(label, vrvLabel, reader);

    parent.addChild(vrvLabel);
    readUnsupportedAttr(reader, label, vrvLabel);
    return readTextChildren(vrvLabel, label, vrvLabel);
  }

  /// Read a `<labelAbbr>` (mirrors `ReadLabelAbbr`).
  bool readLabelAbbr(Object parent, MeiXmlNode labelAbbr) {
    final LabelAbbr vrvLabelAbbr = LabelAbbr();
    MeiAttributeReader reader = MeiAttributeReader(labelAbbr.attributes);
    setMeiID(labelAbbr, vrvLabelAbbr, reader);

    parent.addChild(vrvLabelAbbr);
    readUnsupportedAttr(reader, labelAbbr, vrvLabelAbbr);
    return readTextChildren(vrvLabelAbbr, labelAbbr, vrvLabelAbbr);
  }

  /// Read a `<layerDef>` (mirrors `ReadLayerDef`).
  bool readLayerDef(Object parent, MeiXmlNode layerDef) {
    final LayerDef vrvLayerDef = LayerDef();
    MeiAttributeReader reader = MeiAttributeReader(layerDef.attributes);
    setMeiID(layerDef, vrvLayerDef, reader);

    final dynamic dyn = vrvLayerDef;
    dyn.readLabelled(reader);
    dyn.readNInteger(reader);
    dyn.readTyped(reader);

    parent.addChild(vrvLayerDef);
    readUnsupportedAttr(reader, layerDef, vrvLayerDef);
    return readLayerDefChildren(vrvLayerDef, layerDef);
  }

  /// Read the children of a `<layerDef>` (mirrors `ReadLayerDefChildren`).
  bool readLayerDefChildren(Object parent, MeiXmlNode parentNode) {
    bool success = true;
    for (final MeiXmlNode current in parentNode.childrenElements()) {
      if (!success) break;
      switch (current.name) {
        case 'instrDef':
          success = readInstrDef(parent, current);
          break;
        case 'label':
          success = readLabel(parent, current);
          break;
        case 'labelAbbr':
          success = readLabelAbbr(parent, current);
          break;
        case '':
          break; // no comments among elements
        default:
          logWarning("Unsupported '<${current.name}>' within <layerDef>");
      }
    }
    return success;
  }

  /// Read a `<symbolDef>` (mirrors `ReadSymbolDef`).
  bool readSymbolDef(Object parent, MeiXmlNode symbolDef) {
    final SymbolDef vrvSymbolDef = SymbolDef();
    MeiAttributeReader reader = MeiAttributeReader(symbolDef.attributes);
    setMeiID(symbolDef, vrvSymbolDef, reader);

    parent.addChild(vrvSymbolDef);
    readUnsupportedAttr(reader, symbolDef, vrvSymbolDef);
    return readSymbolDefChildren(vrvSymbolDef, symbolDef);
  }

  /// Read the children of a `<symbolDef>` (mirrors `ReadSymbolDefChildren`).
  bool readSymbolDefChildren(Object parent, MeiXmlNode parentNode,
      [Object? filter]) {
    bool success = true;
    MeiXmlNode? xmlElement = parentNode.firstChild();
    while (xmlElement != null) {
      if (!success) break;
      normalizeAttributes(xmlElement);
      final String elementName = xmlElement.name;
      if (filter != null && !isAllowed(elementName, filter)) {
        logWarning('Element <$elementName> within <${filter.className}> is '
            'not supported and will be ignored ');
        xmlElement = xmlElement.nextSibling();
        continue;
      }
      // content
      if (elementName == 'graphic') {
        success = readGraphic(parent, xmlElement);
      } else if (elementName == 'svg') {
        success = readSvg(parent, xmlElement);
      } else if (elementName == 'symbol') {
        success = readSymbol(parent, xmlElement);
      }
      // xml comment
      else if (!xmlElement.isElement) {
        success = readXMLComment(parent, xmlElement);
      }
      // unknown
      else {
        logWarning('Element <$elementName> is unknown and will be ignored');
      }
      xmlElement = xmlElement.nextSibling();
    }
    return success;
  }

  // -------------------------------------------------------------------------
  // Measure / staff / layer
  // -------------------------------------------------------------------------

  /// Read a `<measure>` (mirrors `ReadMeasure`).
  bool readMeasure(Object parent, MeiXmlNode measure) {
    final Measure vrvMeasure = Measure();
    if (doc.isMensuralMusicOnly()) {
      logWarning('Mixing mensural and non mensural music is not supported. '
          'Trying to go ahead...');
      doc.setMensuralMusicOnly(false);
    }
    MeiAttributeReader reader = MeiAttributeReader(measure.attributes);
    setMeiID(measure, vrvMeasure, reader);
    readFacsimileInterface(reader, vrvMeasure);

    final dynamic dyn = vrvMeasure;
    dyn.readBarring(reader);
    dyn.readMeasureLog(reader);
    dyn.readMeterConformanceBar(reader);
    dyn.readNNumberLike(reader);
    dyn.readPointing(reader);
    dyn.readTyped(reader);

    if (measure.hasAttr('coord.x1') &&
        measure.hasAttr('coord.x2') &&
        doc.isTranscription()) {
      dyn.readCoordX1(reader);
      dyn.readCoordX2(reader);
      vrvMeasure.drawingFacsX1 = (dyn.coordX1 as int?)! * definitionFactor;
      vrvMeasure.drawingFacsX2 = (dyn.coordX2 as int?)! * definitionFactor;
    }

    parent.addChild(vrvMeasure);
    readUnsupportedAttr(reader, measure, vrvMeasure);
    return readMeasureChildren(vrvMeasure, measure);
  }

  /// Read the children of a `<measure>` (mirrors `ReadMeasureChildren`).
  bool readMeasureChildren(Object parent, MeiXmlNode parentNode) {
    bool success = true;
    MeiXmlNode? current = parentNode.firstChild();
    while (current != null) {
      if (!success) break;
      normalizeAttributes(current);
      final String currentName = current.name;
      // editorial
      if (isEditorialElementName(currentName)) {
        if (currentName == 'annot' && isAnnotScore(current)) {
          success = readAnnotScore(parent, current);
        } else {
          success =
              readEditorialElement(parent, current, EditorialLevel.measure);
        }
      }
      // content
      else if (currentName == 'anchoredText') {
        success = readAnchoredText(parent, current);
      } else if (currentName == 'arpeg') {
        success = readArpeg(parent, current);
      } else if (currentName == 'beamSpan') {
        success = readBeamSpan(parent, current);
      } else if (currentName == 'bracketSpan') {
        success = readBracketSpan(parent, current);
      } else if (currentName == 'breath') {
        success = readBreath(parent, current);
      } else if (currentName == 'caesura') {
        success = readCaesura(parent, current);
      } else if (currentName == 'cpMark') {
        success = readCpMark(parent, current);
      } else if (currentName == 'dir') {
        success = readDir(parent, current);
      } else if (currentName == 'dynam') {
        success = readDynam(parent, current);
      } else if (currentName == 'fermata') {
        success = readFermata(parent, current);
      } else if (currentName == 'fing') {
        success = readFing(parent, current);
      } else if (currentName == 'gliss') {
        success = readGliss(parent, current);
      } else if (currentName == 'hairpin') {
        success = readHairpin(parent, current);
      } else if (currentName == 'harm') {
        success = readHarm(parent, current);
      } else if (currentName == 'lv') {
        success = readLv(parent, current);
      } else if (currentName == 'mNum') {
        success = readMNum(parent, current);
      } else if (currentName == 'mordent') {
        success = readMordent(parent, current);
      } else if (currentName == 'octave') {
        success = readOctave(parent, current);
      } else if (currentName == 'ornam') {
        success = readOrnam(parent, current);
      } else if (currentName == 'ossia') {
        success = readOssia(parent, current);
      } else if (currentName == 'pedal') {
        success = readPedal(parent, current);
      } else if (currentName == 'phrase') {
        success = readPhrase(parent, current);
      } else if (currentName == 'pitchInflection') {
        success = readPitchInflection(parent, current);
      } else if (currentName == 'reh') {
        success = readReh(parent, current);
      } else if (currentName == 'repeatMark') {
        success = readRepeatMark(parent, current);
      } else if (currentName == 'slur') {
        success = readSlur(parent, current);
      } else if (currentName == 'staff') {
        success = readStaff(parent, current);
      } else if (currentName == 'stageDir') {
        success = readDir(parent, current, true);
      } else if (currentName == 'tempo') {
        success = readTempo(parent, current);
      } else if (currentName == 'tie') {
        success = readTie(parent, current);
      } else if (currentName == 'trill') {
        success = readTrill(parent, current);
      } else if (currentName == 'turn') {
        success = readTurn(parent, current);
      } else if (currentName == 'tupletSpan') {
        final Object? measureObject = parent.classId == ClassId.measure ? parent : null;
        if (measureObject == null ||
            !readTupletSpanAsTuplet(measureObject as Measure, current)) {
          logWarning('<tupletSpan> is not readable as <tuplet> and will be '
              'ignored');
        }
      }
      // xml comment
      else if (!current.isElement) {
        success = readXMLComment(parent, current);
      } else {
        logWarning("Unsupported '<$currentName>' within <measure>");
      }
      current = current.nextSibling();
    }
    return success;
  }

  /// Read an `<ossia>` (mirrors `ReadOssia`).
  ///
  /// The visibility computation for hidden ossias needs
  /// `GetOriginalStaffForOssia` (layout phase); here only the basic
  /// no-@n / no-layer cases are applied.
  bool readOssia(Object parent, MeiXmlNode ossia) {
    final Ossia vrvOssia = Ossia();
    MeiAttributeReader reader = MeiAttributeReader(ossia.attributes);
    setMeiID(ossia, vrvOssia, reader);
    vrvOssia.readTyped(reader);

    parent.addChild(vrvOssia);
    readUnsupportedAttr(reader, ossia, vrvOssia);

    bool success = true;
    MeiXmlNode? current = ossia.firstChild();
    while (current != null) {
      final String currentName = current.name;
      if (current.isElement && currentName == 'staff') {
        success = readStaff(vrvOssia, current);
      } else if (current.isElement && currentName == 'oStaff') {
        success = readOStaff(vrvOssia, current);
      }
      current = current.nextSibling();
    }

    // Check that we don't have encoding that we do not support
    if (!doc.getOptions().ossiaHidden.value) {
      final List<Object> staves = vrvOssia.findAllDescendantsByType(ClassId.staff);
      for (final Object object in staves) {
        final Staff staff = object as Staff;
        if (!staff.isOssia()) continue;
        // Hide oStaff with no n (even if n="1" is added in ReadOStaff but for
        // the sake of completeness)
        bool hide = !(staff.n != null);
        // Hide oStaff with no layer
        hide = hide || staff.findDescendantByType(ClassId.layer) == null;
        // TODO(phase-4): also hide when GetOriginalStaffForOssia fails.
        if (hide) staff.setVisibility(VisibilityType.hidden);
      }
    }

    return success;
  }

  /// Read a `<meterSigGrp>` (mirrors `ReadMeterSigGrp`).
  bool readMeterSigGrp(Object parent, MeiXmlNode meterSigGrp) {
    final MeterSigGrp vrvMeterSigGrp = MeterSigGrp();
    MeiAttributeReader reader = MeiAttributeReader(meterSigGrp.attributes);
    readLayerElement(reader, meterSigGrp, vrvMeterSigGrp);
    final dynamic dyn = vrvMeterSigGrp;
    dyn.readBasic(reader);
    dyn.readMeterSigGrpLog(reader);
    dyn.readVisibility(reader);

    parent.addChild(vrvMeterSigGrp);
    readUnsupportedAttr(reader, meterSigGrp, vrvMeterSigGrp);
    return readMeterSigGrpChildren(vrvMeterSigGrp, meterSigGrp);
  }

  /// Read the children of a `<meterSigGrp>` (mirrors
  /// `ReadMeterSigGrpChildren`).
  bool readMeterSigGrpChildren(Object parent, MeiXmlNode parentNode) {
    bool success = true;
    MeiXmlNode? current = parentNode.firstChild();
    while (current != null) {
      if (!success) break;
      normalizeAttributes(current);
      // content
      if (current.isElement && current.name == 'meterSig') {
        success = readMeterSig(parent, current);
      }
      // xml comment
      else if (!current.isElement) {
        success = readXMLComment(parent, current);
      } else {
        logWarning("Unsupported '<${current.name}>' within <meterSigGrp>");
      }
      current = current.nextSibling();
    }
    return success;
  }

  /// Read a `<staff>` (mirrors `ReadStaff`).
  bool readStaff(Object parent, MeiXmlNode staff) {
    final Staff vrvStaff = Staff();
    MeiAttributeReader reader = MeiAttributeReader(staff.attributes);
    setMeiID(staff, vrvStaff, reader);
    readFacsimileInterface(reader, vrvStaff);

    final dynamic dyn = vrvStaff;
    dyn.readNInteger(reader);
    dyn.readTyped(reader);
    dyn.readVisibility(reader);

    if (vrvStaff.n == null || vrvStaff.n == 0) {
      logWarning('No @n on <staff> or a value of 0 might yield unpredictable '
          'results');
    }

    parent.addChild(vrvStaff);
    readUnsupportedAttr(reader, staff, vrvStaff);
    return readStaffChildren(vrvStaff, staff);
  }

  /// Read an `<oStaff>` (ossia staff; mirrors `ReadOStaff`).
  bool readOStaff(Object parent, MeiXmlNode oStaff) {
    final Staff vrvStaff = Staff();
    vrvStaff.setOssia(true);
    MeiAttributeReader reader = MeiAttributeReader(oStaff.attributes);
    setMeiID(oStaff, vrvStaff, reader);
    readFacsimileInterface(reader, vrvStaff);

    final dynamic dyn = vrvStaff;
    dyn.readNInteger(reader);
    dyn.readTyped(reader);
    dyn.readVisibility(reader);

    if (vrvStaff.n == null || vrvStaff.n == 0) {
      logWarning('No @n on <staff> or a value of 0 might yield unpredictable '
          'results');
    }

    vrvStaff.drawingN = vrvStaff.n ?? 0;

    if (doc.getOptions().ossiaHidden.value) {
      vrvStaff.setVisibility(VisibilityType.hidden);
    }

    parent.addChild(vrvStaff);
    readUnsupportedAttr(reader, oStaff, vrvStaff);
    return readStaffChildren(vrvStaff, oStaff);
  }

  /// Read the children of a `<staff>` (mirrors `ReadStaffChildren`).
  bool readStaffChildren(Object parent, MeiXmlNode parentNode) {
    bool success = true;
    MeiXmlNode? current = parentNode.firstChild();
    while (current != null) {
      if (!success) break;
      normalizeAttributes(current);
      // editorial
      if (isEditorialElementName(current.name)) {
        success = readEditorialElement(parent, current, EditorialLevel.staff);
      }
      // content
      else if (current.name == 'layer') {
        success = readLayer(parent, current);
      }
      // xml comment
      else if (!current.isElement) {
        success = readXMLComment(parent, current);
      } else {
        logWarning("Unsupported '<${current.name}>' within <staff>");
      }
      current = current.nextSibling();
    }
    return success;
  }

  /// Read a `<layer>` (mirrors `ReadLayer`).
  bool readLayer(Object parent, MeiXmlNode layer) {
    final Layer vrvLayer = Layer();
    MeiAttributeReader reader = MeiAttributeReader(layer.attributes);
    setMeiID(layer, vrvLayer, reader);

    final dynamic dyn = vrvLayer;
    dyn.readCue(reader);
    dyn.readNInteger(reader);
    dyn.readTyped(reader);
    dyn.readVisibility(reader);

    if (!(dyn.hasN as bool)) {
      logWarning('Missing @n on <layer>, filled by order');
    } else if ((dyn.n as int?) == 0) {
      logWarning("Value @n='0' on <layer> might yield unpredictable results");
    }

    // Check that we have only one single layer in mensural music staves
    if (doc.isMensuralMusicOnly() &&
        (parent.getChildCount(ClassId.layer) > 0)) {
      logWarning('Mensural music with more than one layer is not supported. '
          'Trying to go ahead...');
      doc.setMensuralMusicOnly(false);
    }

    parent.addChild(vrvLayer);
    readUnsupportedAttr(reader, layer, vrvLayer);
    return readLayerChildren(vrvLayer, layer);
  }

  // -------------------------------------------------------------------------
  // Layer elements
  // -------------------------------------------------------------------------

  /// Check if an [element] name is allowed within [filterParent] (mirrors
  /// `IsAllowed`).
  bool isAllowed(String element, Object? filterParent) {
    if (filterParent == null || element.isEmpty) return true;

    bool isName(String n) => element == n;
    final ClassId id = filterParent.classId;

    bool any(List<String> names) => names.any(isName);

    // editorial
    if (isEditorialElementName(element)) {
      // Because of the Clone issue on annot do not support it in label and
      // labelAbbr.
      if (id == ClassId.label && element == 'annot') return false;
      if (id == ClassId.labelAbbr && element == 'annot') return false;
      return true;
    }
    // filter for annot / dynam / num / figure-like containers
    else if (id == ClassId.annot) {
      return isName('');
    } else if (id == ClassId.dynam) {
      return element.isEmpty || isName('lb') || isName('rend');
    } else if (id == ClassId.dir ||
        id == ClassId.ornam ||
        id == ClassId.repeatMark ||
        id == ClassId.tempo) {
      return element.isEmpty || isName('lb') || isName('rend') ||
          isName('symbol');
    } else if (id == ClassId.fig) {
      return isName('svg');
    } else if (id == ClassId.figure) {
      return isName('');
    } else if (id == ClassId.num) {
      return isName('');
    }
    // filter for harm
    else if (id == ClassId.harm) {
      return element.isEmpty || isName('rend') || isName('fb');
    }
    // filter for rend
    else if (id == ClassId.rend) {
      return element.isEmpty ||
          isName('lb') ||
          isName('num') ||
          isName('rend') ||
          isName('symbol');
    }
    // filter for any other control element
    else if (filterParent.isControlElement) {
      return element.isEmpty || isName('rend');
    }
    // filter for running elements and div
    else if (filterParent.isRunningElement || id == ClassId.div) {
      return isName('fig') || isName('rend');
    }
    // filter for beam
    else if (id == ClassId.beam) {
      return any([
        'beam', 'bTrem', 'chord', 'clef', 'fTrem', 'graceGrp', 'note', //
        'rest', 'space', 'tabGrp', 'tuplet'
      ]);
    }
    // filter for bTrem
    else if (id == ClassId.bTrem) {
      return any(['chord', 'clef', 'note']);
    }
    // filter for chord
    else if (id == ClassId.chord) {
      return any(['note', 'artic', 'verse']);
    }
    // filter for custos
    else if (id == ClassId.custos) {
      return isName('accid');
    }
    // filter for fTrem
    else if (id == ClassId.fTrem) {
      return any(['chord', 'clef', 'note']);
    }
    // filter for graceGrp
    else if (id == ClassId.graceGrp) {
      return any(['beam', 'chord', 'note', 'rest', 'space']);
    }
    // filter for keySig
    else if (id == ClassId.keysig) {
      return isName('keyAccid');
    }
    // filter for label
    else if (id == ClassId.label) {
      return element.isEmpty || isName('lb') || isName('rend');
    }
    // filter for labelAbbr
    else if (id == ClassId.labelAbbr) {
      return element.isEmpty || isName('lb') || isName('rend');
    }
    // filter for ligature
    else if (id == ClassId.ligature) {
      return isName('dot') || isName('note');
    }
    // filter for neume
    else if (id == ClassId.neume) {
      return isName('nc');
    }
    // filter for nc
    else if (id == ClassId.nc) {
      return any(['episema', 'liquescent', 'oriscus', 'quilisma', 'strophicus']);
    }
    // filter for note
    else if (id == ClassId.note) {
      return any(['accid', 'artic', 'plica', 'stem', 'syl', 'verse']);
    }
    // filter for rest
    else if (id == ClassId.rest) {
      return false;
    }
    // filter for syllable
    else if (id == ClassId.syllable) {
      return any(['accid', 'clef', 'divLine', 'neume', 'syl']);
    }
    // filter for syl
    else if (id == ClassId.syl) {
      return element.isEmpty || isName('rend');
    }
    // filter for tabGrp
    else if (id == ClassId.tabGrp) {
      return any(['tabDurSym', 'note', 'rest']);
    }
    // filter for tuplet
    else if (id == ClassId.tuplet) {
      return any([
        'beam', 'bTrem', 'chord', 'clef', 'fTrem', 'note', 'rest', //
        'space', 'tabGrp', 'tuplet'
      ]);
    }
    // filter for tuning
    else if (id == ClassId.tuning) {
      return isName('course');
    }
    // filter for verse
    else if (id == ClassId.verse) {
      return any(['label', 'labelAbbr', 'syl']);
    } else {
      logDebug("Unknown filter for '${filterParent.className}'");
      return true;
    }
  }

  /// Read the children of a layer (mirrors `ReadLayerChildren`).
  bool readLayerChildren(Object parent, MeiXmlNode parentNode,
      [Object? filter]) {
    bool success = true;
    MeiXmlNode? xmlElement = parentNode.firstChild();
    while (xmlElement != null) {
      if (!success) break;
      normalizeAttributes(xmlElement);

      final String elementName = xmlElement.name;
      if (!xmlElement.isElement) {
        success = readXMLComment(parent, xmlElement);
        xmlElement = xmlElement.nextSibling();
        continue;
      }
      if (filter != null && !isAllowed(elementName, filter)) {
        logWarning('Element <$elementName> within <${filter.className}> is '
            'not supported and will be ignored ');
        xmlElement = xmlElement.nextSibling();
        continue;
      }
      // editorial
      if (isEditorialElementName(xmlElement.name)) {
        success =
            readEditorialElement(parent, xmlElement, EditorialLevel.layer, filter);
      }
      // content
      else if (elementName == 'accid') {
        success = readAccid(parent, xmlElement);
      } else if (elementName == 'artic') {
        success = readArtic(parent, xmlElement);
      } else if (elementName == 'barLine') {
        success = readBarLine(parent, xmlElement);
      } else if (elementName == 'beam') {
        success = readBeam(parent, xmlElement);
      } else if (elementName == 'beatRpt') {
        success = readBeatRpt(parent, xmlElement);
      } else if (elementName == 'bTrem') {
        success = readBTrem(parent, xmlElement);
      } else if (elementName == 'chord') {
        success = readChord(parent, xmlElement);
      } else if (elementName == 'clef') {
        success = readClef(parent, xmlElement);
      } else if (elementName == 'custos') {
        success = readCustos(parent, xmlElement);
      } else if (elementName == 'divLine') {
        success = readDivLine(parent, xmlElement);
      } else if (elementName == 'dot') {
        success = readDot(parent, xmlElement);
      } else if (elementName == 'episema') {
        success = readEpisema(parent, xmlElement);
      } else if (elementName == 'fTrem') {
        success = readFTrem(parent, xmlElement);
      } else if (elementName == 'gap') {
        success = readGenericLayerElement(parent, xmlElement);
      } else if (elementName == 'graceGrp') {
        success = readGraceGrp(parent, xmlElement);
      } else if (elementName == 'halfmRpt') {
        success = readHalfmRpt(parent, xmlElement);
      } else if (elementName == 'keyAccid') {
        success = readKeyAccid(parent, xmlElement);
      } else if (elementName == 'keySig') {
        success = readKeySig(parent, xmlElement);
      } else if (elementName == 'label') {
        success = readLabel(parent, xmlElement);
      } else if (elementName == 'labelAbbr') {
        success = readLabelAbbr(parent, xmlElement);
      } else if (elementName == 'ligature') {
        success = readLigature(parent, xmlElement);
      } else if (elementName == 'liquescent') {
        success = readLiquescent(parent, xmlElement);
      } else if (elementName == 'mensur') {
        success = readMensur(parent, xmlElement);
      } else if (elementName == 'meterSig') {
        success = readMeterSig(parent, xmlElement);
      } else if (elementName == 'meterSigGrp') {
        success = readMeterSigGrp(parent, xmlElement);
      } else if (elementName == 'nc') {
        success = readNc(parent, xmlElement);
      } else if (elementName == 'neume') {
        success = readNeume(parent, xmlElement);
      } else if (elementName == 'note') {
        success = readNote(parent, xmlElement);
      } else if (elementName == 'mRest') {
        success = readMRest(parent, xmlElement);
      } else if (elementName == 'mRpt') {
        success = readMRpt(parent, xmlElement);
      } else if (elementName == 'mRpt2') {
        success = readMRpt2(parent, xmlElement);
      } else if (elementName == 'mSpace') {
        success = readMSpace(parent, xmlElement);
      } else if (elementName == 'multiRest') {
        success = readMultiRest(parent, xmlElement);
      } else if (elementName == 'multiRpt') {
        success = readMultiRpt(parent, xmlElement);
      } else if (elementName == 'oriscus') {
        success = readOriscus(parent, xmlElement);
      } else if (elementName == 'pb') {
        success = readGenericLayerElement(parent, xmlElement);
      } else if (elementName == 'plica') {
        success = readPlica(parent, xmlElement);
      } else if (elementName == 'proport') {
        success = readProport(parent, xmlElement);
      } else if (elementName == 'quilisma') {
        success = readQuilisma(parent, xmlElement);
      } else if (elementName == 'rest') {
        success = readRest(parent, xmlElement);
      } else if (elementName == 'sb') {
        success = readGenericLayerElement(parent, xmlElement);
      } else if (elementName == 'space') {
        success = readSpace(parent, xmlElement);
      } else if (elementName == 'stem') {
        success = readStem(parent, xmlElement);
      } else if (elementName == 'strophicus') {
        success = readStrophicus(parent, xmlElement);
      } else if (elementName == 'syl') {
        success = readSyl(parent, xmlElement);
      } else if (elementName == 'syllable') {
        success = readSyllable(parent, xmlElement);
      } else if (elementName == 'tabDurSym') {
        success = readTabDurSym(parent, xmlElement);
      } else if (elementName == 'tabGrp') {
        success = readTabGrp(parent, xmlElement);
      } else if (elementName == 'tuplet') {
        success = readTuplet(parent, xmlElement);
      } else if (elementName == 'verse') {
        success = readVerse(parent, xmlElement);
      }
      // unknown
      else {
        logWarning('Element <$elementName> is unknown and will be ignored');
      }
      xmlElement = xmlElement.nextSibling();
    }
    return success;
  }

  /// Helper reading @accid/@accid.ges into an Accid child (mirrors
  /// `ReadAccidAttr`).
  void readAccidAttr(MeiXmlNode node, MeiAttributeReader reader, Object object) {
    final String? accid = node.attr('accid');
    final String? accidGes = node.attr('accid.ges');
    if (accid != null || accidGes != null) {
      final Accid vrvAccid = Accid();
      vrvAccid.isAttribute = true;
      if (accid != null) vrvAccid.accid = strToAccidentalWritten(accid);
      if (accidGes != null) vrvAccid.accidGes = strToAccidentalGestural(accidGes);
      object.addChild(vrvAccid);
      reader.remove('accid');
      reader.remove('accid.ges');
    }
  }

  /// Read an `<accid>` (mirrors `ReadAccid`).
  bool readAccid(Object parent, MeiXmlNode accid) {
    final Accid vrvAccid = Accid();
    MeiAttributeReader reader = MeiAttributeReader(accid.attributes);
    readLayerElement(reader, accid, vrvAccid);

    readOffsetInterface(reader, vrvAccid);
    readPositionInterface(reader, vrvAccid);
    final dynamic dyn = vrvAccid;
    dyn.readAccidental(reader);
    dyn.readAccidentalGes(reader);
    dyn.readAccidLog(reader);
    dyn.readColor(reader);
    dyn.readEnclosingChars(reader);
    dyn.readExtSymAuth(reader);
    dyn.readExtSymNames(reader);
    dyn.readPlacementOnStaff(reader);
    dyn.readPlacementRelEvent(reader);

    parent.addChild(vrvAccid);
    readUnsupportedAttr(reader, accid, vrvAccid);
    return true;
  }

  /// Read an `<artic>` (mirrors `ReadArtic`).
  bool readArtic(Object parent, MeiXmlNode artic) {
    final Artic vrvArtic = Artic();
    MeiAttributeReader reader = MeiAttributeReader(artic.attributes);
    readLayerElement(reader, artic, vrvArtic);

    readOffsetInterface(reader, vrvArtic);
    final dynamic dyn = vrvArtic;
    dyn.readArticulation(reader);
    dyn.readArticulationGes(reader);
    dyn.readColor(reader);
    dyn.readEnclosingChars(reader);
    dyn.readExtSymAuth(reader);
    dyn.readExtSymNames(reader);
    dyn.readPlacementRelEvent(reader);

    if ((vrvArtic.artic?.length ?? 0) > 1) {
      doc.setMarkup(markupArticMultival);
    }

    parent.addChild(vrvArtic);
    readUnsupportedAttr(reader, artic, vrvArtic);
    return true;
  }

  /// Read a `<barLine>` (mirrors `ReadBarLine`).
  bool readBarLine(Object parent, MeiXmlNode barLine) {
    final BarLine vrvBarLine = BarLine();
    MeiAttributeReader reader = MeiAttributeReader(barLine.attributes);
    readLayerElement(reader, barLine, vrvBarLine);

    final dynamic dyn = vrvBarLine;
    dyn.readBarLineLog(reader);
    dyn.readBarLineVis(reader);
    dyn.readColor(reader);
    dyn.readNNumberLike(reader);
    dyn.readVisibility(reader);

    parent.addChild(vrvBarLine);
    readUnsupportedAttr(reader, barLine, vrvBarLine);
    return true;
  }

  /// Read a `<beam>` (mirrors `ReadBeam`).
  bool readBeam(Object parent, MeiXmlNode beam) {
    final Beam vrvBeam = Beam();
    MeiAttributeReader reader = MeiAttributeReader(beam.attributes);
    readLayerElement(reader, beam, vrvBeam);

    final dynamic dyn = vrvBeam;
    dyn.readBeamedWith(reader);
    dyn.readBeamRend(reader);
    dyn.readColor(reader);
    dyn.readCue(reader);

    parent.addChild(vrvBeam);
    readUnsupportedAttr(reader, beam, vrvBeam);
    return readLayerChildren(vrvBeam, beam, vrvBeam);
  }

  /// Read a `<beatRpt>` (mirrors `ReadBeatRpt`).
  bool readBeatRpt(Object parent, MeiXmlNode beatRpt) {
    final BeatRpt vrvBeatRpt = BeatRpt();
    MeiAttributeReader reader = MeiAttributeReader(beatRpt.attributes);
    readLayerElement(reader, beatRpt, vrvBeatRpt);

    final dynamic dyn = vrvBeatRpt;
    dyn.readColor(reader);
    dyn.readBeatRptLog(reader);
    dyn.readBeatRptVis(reader);

    if (_before400()) {
      upgradeBeatRptTo400(beatRpt, vrvBeatRpt);
    }

    parent.addChild(vrvBeatRpt);
    readUnsupportedAttr(reader, beatRpt, vrvBeatRpt);
    return true;
  }

  /// Read a `<bTrem>` (mirrors `ReadBTrem`).
  bool readBTrem(Object parent, MeiXmlNode bTrem) {
    final BTrem vrvBTrem = BTrem();
    MeiAttributeReader reader = MeiAttributeReader(bTrem.attributes);
    readLayerElement(reader, bTrem, vrvBTrem);

    final dynamic dyn = vrvBTrem;
    dyn.readTremForm(reader);
    dyn.readNumbered(reader);
    dyn.readNumberPlacement(reader);
    dyn.readTremMeasured(reader);

    parent.addChild(vrvBTrem);
    readUnsupportedAttr(reader, bTrem, vrvBTrem);
    return readLayerChildren(vrvBTrem, bTrem, vrvBTrem);
  }

  /// Read a `<chord>` (mirrors `ReadChord`).
  bool readChord(Object parent, MeiXmlNode chord) {
    final Chord vrvChord = Chord();
    MeiAttributeReader reader = MeiAttributeReader(chord.attributes);
    readLayerElement(reader, chord, vrvChord);

    if (_before400() && chord.hasAttr('size')) {
      chord.removeAttribute('size');
      reader.remove('size');
      chord.setAttribute('cue', 'true');
    }

    readDurationInterface(reader, vrvChord);
    final dynamic dyn = vrvChord;
    dyn.readChordVis(reader);
    dyn.readColor(reader);
    dyn.readCue(reader);
    dyn.readGraced(reader);
    dyn.readStems(reader);
    dyn.readStemsCmn(reader);
    dyn.readTiePresent(reader);
    dyn.readVisibility(reader);

    // att.articulation -> attribute Artic child; consumes @artic.
    dyn.readArticulation(reader);
    if ((dyn.hasArtic as bool)) {
      final Artic vrvArtic = Artic();
      vrvArtic.isAttribute = true;
      vrvArtic.artic = (dyn.artic as List<Articulation>? ?? const []);
      vrvChord.addChild(vrvArtic);
    }

    if ((dyn.hasTie as bool)) {
      doc.setMarkup(markupAnalyticalTie);
    }

    parent.addChild(vrvChord);
    readUnsupportedAttr(reader, chord, vrvChord);
    return readLayerChildren(vrvChord, chord, vrvChord);
  }

  /// Read a `<clef>` (mirrors `ReadClef`).
  bool readClef(Object parent, MeiXmlNode clef) {
    final Clef vrvClef = Clef();
    MeiAttributeReader reader = MeiAttributeReader(clef.attributes);
    readLayerElement(reader, clef, vrvClef);

    readOffsetInterface(reader, vrvClef);
    final dynamic dyn = vrvClef;
    dyn.readClefLog(reader);
    dyn.readClefShape(reader);
    dyn.readColor(reader);
    dyn.readEnclosingChars(reader);
    dyn.readExtSymAuth(reader);
    dyn.readExtSymNames(reader);
    dyn.readLineLoc(reader);
    dyn.readOctave(reader);
    dyn.readOctaveDisplacement(reader);
    dyn.readStaffIdent(reader);
    dyn.readTypography(reader);
    dyn.readVisibility(reader);

    parent.addChild(vrvClef);
    readUnsupportedAttr(reader, clef, vrvClef);
    return true;
  }

  /// Read a `<custos>` (mirrors `ReadCustos`).
  bool readCustos(Object parent, MeiXmlNode custos) {
    final Custos vrvCustos = Custos();
    MeiAttributeReader reader = MeiAttributeReader(custos.attributes);
    readLayerElement(reader, custos, vrvCustos);

    readFacsimileInterface(reader, vrvCustos);
    readOffsetInterface(reader, vrvCustos);
    readPitchInterface(reader, vrvCustos);
    readPositionInterface(reader, vrvCustos);
    final dynamic dyn = vrvCustos;
    dyn.readColor(reader);
    dyn.readExtSymAuth(reader);
    dyn.readExtSymNames(reader);

    readAccidAttr(custos, reader, vrvCustos);

    parent.addChild(vrvCustos);
    readUnsupportedAttr(reader, custos, vrvCustos);
    return readLayerChildren(vrvCustos, custos, vrvCustos);
  }

  /// Read a `<divLine>` (mirrors `ReadDivLine`).
  bool readDivLine(Object parent, MeiXmlNode divLine) {
    final DivLine vrvDivLine = DivLine();
    MeiAttributeReader reader = MeiAttributeReader(divLine.attributes);
    readLayerElement(reader, divLine, vrvDivLine);

    readOffsetInterface(reader, vrvDivLine);
    final dynamic dyn = vrvDivLine;
    dyn.readDivLineLog(reader);
    dyn.readColor(reader);
    dyn.readVisibility(reader);
    dyn.readExtSymAuth(reader);
    dyn.readExtSymNames(reader);

    parent.addChild(vrvDivLine);
    readUnsupportedAttr(reader, divLine, vrvDivLine);
    return true;
  }

  /// Read a `<dot>` (mirrors `ReadDot`).
  bool readDot(Object parent, MeiXmlNode dot) {
    final Dot vrvDot = Dot();
    MeiAttributeReader reader = MeiAttributeReader(dot.attributes);
    readLayerElement(reader, dot, vrvDot);

    readOffsetInterface(reader, vrvDot);
    readPositionInterface(reader, vrvDot);
    final dynamic dyn = vrvDot;
    dyn.readColor(reader);
    dyn.readDotLog(reader);

    parent.addChild(vrvDot);
    readUnsupportedAttr(reader, dot, vrvDot);
    return true;
  }

  /// Read an `<fTrem>` (mirrors `ReadFTrem`).
  bool readFTrem(Object parent, MeiXmlNode fTrem) {
    final FTrem vrvFTrem = FTrem();
    MeiAttributeReader reader = MeiAttributeReader(fTrem.attributes);
    readLayerElement(reader, fTrem, vrvFTrem);

    if (_before400()) {
      upgradeFTremTo400(fTrem, vrvFTrem);
    }

    final dynamic dyn = vrvFTrem;
    dyn.readFTremVis(reader);
    dyn.readTremMeasured(reader);

    parent.addChild(vrvFTrem);
    readUnsupportedAttr(reader, fTrem, vrvFTrem);
    return readLayerChildren(vrvFTrem, fTrem, vrvFTrem);
  }

  /// Read an unhandled layer element (`<gap>` etc.; mirrors
  /// `ReadGenericLayerElement`). The content is stored serialized.
  bool readGenericLayerElement(Object parent, MeiXmlNode element) {
    final GenericLayerElement vrvElement = GenericLayerElement(element.name);
    MeiAttributeReader reader = MeiAttributeReader(element.attributes);
    readLayerElement(reader, element, vrvElement);

    // Store the content as a string document
    vrvElement.content = element.serialize();

    parent.addChild(vrvElement);
    readUnsupportedAttr(reader, element, vrvElement);
    return true;
  }

  /// Read a `<graceGrp>` (mirrors `ReadGraceGrp`).
  bool readGraceGrp(Object parent, MeiXmlNode graceGrp) {
    final GraceGrp vrvGraceGrp = GraceGrp();
    MeiAttributeReader reader = MeiAttributeReader(graceGrp.attributes);
    readLayerElement(reader, graceGrp, vrvGraceGrp);

    final dynamic dyn = vrvGraceGrp;
    dyn.readColor(reader);
    dyn.readGraced(reader);
    dyn.readGraceGrpLog(reader);

    parent.addChild(vrvGraceGrp);
    readUnsupportedAttr(reader, graceGrp, vrvGraceGrp);
    return readLayerChildren(vrvGraceGrp, graceGrp, vrvGraceGrp);
  }

  /// Read a `<halfmRpt>` (mirrors `ReadHalfmRpt`).
  bool readHalfmRpt(Object parent, MeiXmlNode halfmRpt) {
    final HalfmRpt vrvHalfmRpt = HalfmRpt();
    MeiAttributeReader reader = MeiAttributeReader(halfmRpt.attributes);
    readLayerElement(reader, halfmRpt, vrvHalfmRpt);

    readOffsetInterface(reader, vrvHalfmRpt);
    vrvHalfmRpt.readColor(reader);

    parent.addChild(vrvHalfmRpt);
    readUnsupportedAttr(reader, halfmRpt, vrvHalfmRpt);
    return true;
  }

  /// Read a `<keyAccid>` (mirrors `ReadKeyAccid`).
  bool readKeyAccid(Object parent, MeiXmlNode keyAccid) {
    final KeyAccid vrvKeyAccid = KeyAccid();
    MeiAttributeReader reader = MeiAttributeReader(keyAccid.attributes);
    readLayerElement(reader, keyAccid, vrvKeyAccid);

    readPitchInterface(reader, vrvKeyAccid);
    readPositionInterface(reader, vrvKeyAccid);
    final dynamic dyn = vrvKeyAccid;
    dyn.readAccidental(reader);
    dyn.readColor(reader);
    dyn.readEnclosingChars(reader);
    dyn.readExtSymAuth(reader);
    dyn.readExtSymNames(reader);

    parent.addChild(vrvKeyAccid);
    readUnsupportedAttr(reader, keyAccid, vrvKeyAccid);
    return true;
  }

  /// Read a `<keySig>` (mirrors `ReadKeySig`).
  bool readKeySig(Object parent, MeiXmlNode keySig) {
    final KeySig vrvKeySig = KeySig();
    MeiAttributeReader reader = MeiAttributeReader(keySig.attributes);
    readLayerElement(reader, keySig, vrvKeySig);

    if (_atOrBefore50()) {
      upgradeKeySigTo500(keySig);
    }

    final dynamic dyn = vrvKeySig;
    dyn.readColor(reader);
    dyn.readKeySigAnl(reader);
    dyn.readKeySigLog(reader);
    dyn.readKeySigVis(reader);
    dyn.readPitch(reader);
    dyn.readVisibility(reader);

    parent.addChild(vrvKeySig);
    readUnsupportedAttr(reader, keySig, vrvKeySig);
    return readLayerChildren(vrvKeySig, keySig, vrvKeySig);
  }

  /// Read a `<ligature>` (mirrors `ReadLigature`).
  bool readLigature(Object parent, MeiXmlNode ligature) {
    final Ligature vrvLigature = Ligature();
    MeiAttributeReader reader = MeiAttributeReader(ligature.attributes);
    readLayerElement(reader, ligature, vrvLigature);

    vrvLigature.readLigatureVis(reader);

    parent.addChild(vrvLigature);
    readUnsupportedAttr(reader, ligature, vrvLigature);
    return readLayerChildren(vrvLigature, ligature, vrvLigature);
  }

  /// Read a `<liquescent>` (mirrors `ReadLiquescent`).
  bool readLiquescent(Object parent, MeiXmlNode liquescent) {
    final Liquescent vrvLiquescent = Liquescent();
    MeiAttributeReader reader = MeiAttributeReader(liquescent.attributes);
    readLayerElement(reader, liquescent, vrvLiquescent);

    readOffsetInterface(reader, vrvLiquescent);
    readPositionInterface(reader, vrvLiquescent);
    vrvLiquescent.readColor(reader);

    parent.addChild(vrvLiquescent);
    readUnsupportedAttr(reader, liquescent, vrvLiquescent);
    return true;
  }

  /// Read a `<mensur>` (mirrors `ReadMensur`).
  bool readMensur(Object parent, MeiXmlNode mensur) {
    final Mensur vrvMensur = Mensur();
    MeiAttributeReader reader = MeiAttributeReader(mensur.attributes);
    readLayerElement(reader, mensur, vrvMensur);

    if (_before400() && mensur.hasAttr('size')) {
      mensur.removeAttribute('size');
      reader.remove('size');
      mensur.setAttribute('cue', 'true');
    }

    final dynamic dyn = vrvMensur;
    dyn.readColor(reader);
    dyn.readCue(reader);
    dyn.readDurationRatio(reader);
    dyn.readMensuralShared(reader);
    dyn.readMensurVis(reader);
    dyn.readSlashCount(reader);
    dyn.readStaffLoc(reader);

    if (_before50()) {
      upgradeMensurTo500(vrvMensur);
    }

    parent.addChild(vrvMensur);
    readUnsupportedAttr(reader, mensur, vrvMensur);
    return true;
  }

  /// Read a `<meterSig>` (mirrors `ReadMeterSig`).
  bool readMeterSig(Object parent, MeiXmlNode meterSig) {
    final MeterSig vrvMeterSig = MeterSig();
    MeiAttributeReader reader = MeiAttributeReader(meterSig.attributes);
    readLayerElement(reader, meterSig, vrvMeterSig);

    if (_atOrBefore50()) {
      upgradeMeterSigTo500(meterSig, vrvMeterSig);
    }

    final dynamic dyn = vrvMeterSig;
    dyn.readColor(reader);
    dyn.readEnclosingChars(reader);
    dyn.readExtSymNames(reader);
    dyn.readMeterSigLog(reader);
    dyn.readMeterSigVis(reader);
    dyn.readTypography(reader);
    dyn.readVisibility(reader);

    parent.addChild(vrvMeterSig);
    readUnsupportedAttr(reader, meterSig, vrvMeterSig);
    return true;
  }

  /// Read an `<episema>` (mirrors `ReadEpisema`).
  bool readEpisema(Object parent, MeiXmlNode episema) {
    final Episema vrvEpisema = Episema();
    MeiAttributeReader reader = MeiAttributeReader(episema.attributes);
    readLayerElement(reader, episema, vrvEpisema);

    readOffsetInterface(reader, vrvEpisema);
    readPitchInterface(reader, vrvEpisema);
    readPositionInterface(reader, vrvEpisema);
    final dynamic dyn = vrvEpisema;
    dyn.readColor(reader);
    dyn.readEpisemaVis(reader);

    parent.addChild(vrvEpisema);
    return readLayerChildren(vrvEpisema, episema, vrvEpisema);
  }

  /// Read an `<mRest>` (mirrors `ReadMRest`).
  bool readMRest(Object parent, MeiXmlNode mRest) {
    final MRest vrvMRest = MRest();
    MeiAttributeReader reader = MeiAttributeReader(mRest.attributes);
    readLayerElement(reader, mRest, vrvMRest);

    readOffsetInterface(reader, vrvMRest);
    readPositionInterface(reader, vrvMRest);

    if (_before400() && mRest.hasAttr('size')) {
      mRest.removeAttribute('size');
      reader.remove('size');
      mRest.setAttribute('cue', 'true');
    }

    final dynamic dyn = vrvMRest;
    dyn.readColor(reader);
    dyn.readCue(reader);
    dyn.readCutout(reader);
    dyn.readFermataPresent(reader);
    dyn.readVisibility(reader);

    if ((dyn.hasFermata as bool)) {
      doc.setMarkup(markupAnalyticalFermata);
    }

    parent.addChild(vrvMRest);
    readUnsupportedAttr(reader, mRest, vrvMRest);
    return true;
  }

  /// Read an `<mRpt>` (mirrors `ReadMRpt`).
  bool readMRpt(Object parent, MeiXmlNode mRpt) {
    final MRpt vrvMRpt = MRpt();
    MeiAttributeReader reader = MeiAttributeReader(mRpt.attributes);
    readLayerElement(reader, mRpt, vrvMRpt);

    final dynamic dyn = vrvMRpt;
    dyn.readColor(reader);
    dyn.readNumbered(reader);
    dyn.readNumberPlacement(reader);

    parent.addChild(vrvMRpt);
    readUnsupportedAttr(reader, mRpt, vrvMRpt);
    return true;
  }

  /// Read an `<mRpt2>` (mirrors `ReadMRpt2`).
  bool readMRpt2(Object parent, MeiXmlNode mRpt2) {
    final MRpt2 vrvMRpt2 = MRpt2();
    MeiAttributeReader reader = MeiAttributeReader(mRpt2.attributes);
    readLayerElement(reader, mRpt2, vrvMRpt2);

    vrvMRpt2.readColor(reader);

    parent.addChild(vrvMRpt2);
    readUnsupportedAttr(reader, mRpt2, vrvMRpt2);
    return true;
  }

  /// Read an `<mSpace>` (mirrors `ReadMSpace`).
  bool readMSpace(Object parent, MeiXmlNode mSpace) {
    final MSpace vrvMSpace = MSpace();
    MeiAttributeReader reader = MeiAttributeReader(mSpace.attributes);
    readLayerElement(reader, mSpace, vrvMSpace);

    parent.addChild(vrvMSpace);
    readUnsupportedAttr(reader, mSpace, vrvMSpace);
    return true;
  }

  /// Read a `<multiRest>` (mirrors `ReadMultiRest`).
  bool readMultiRest(Object parent, MeiXmlNode multiRest) {
    final MultiRest vrvMultiRest = MultiRest();
    MeiAttributeReader reader = MeiAttributeReader(multiRest.attributes);
    readLayerElement(reader, multiRest, vrvMultiRest);

    readPositionInterface(reader, vrvMultiRest);
    final dynamic dyn = vrvMultiRest;
    dyn.readColor(reader);
    dyn.readMultiRestVis(reader);
    dyn.readNumbered(reader);
    dyn.readNumberPlacement(reader);
    dyn.readWidth(reader);

    parent.addChild(vrvMultiRest);
    readUnsupportedAttr(reader, multiRest, vrvMultiRest);
    return true;
  }

  /// Read a `<multiRpt>` (mirrors `ReadMultiRpt`).
  bool readMultiRpt(Object parent, MeiXmlNode multiRpt) {
    final MultiRpt vrvMultiRpt = MultiRpt();
    MeiAttributeReader reader = MeiAttributeReader(multiRpt.attributes);
    readLayerElement(reader, multiRpt, vrvMultiRpt);

    vrvMultiRpt.readNumbered(reader);

    parent.addChild(vrvMultiRpt);
    readUnsupportedAttr(reader, multiRpt, vrvMultiRpt);
    return true;
  }

  /// Read an `<nc>` (mirrors `ReadNc`).
  bool readNc(Object parent, MeiXmlNode nc) {
    final Nc vrvNc = Nc();
    MeiAttributeReader reader = MeiAttributeReader(nc.attributes);
    readLayerElement(reader, nc, vrvNc);

    readDurationInterface(reader, vrvNc);
    readOffsetInterface(reader, vrvNc);
    readPitchInterface(reader, vrvNc);
    readPositionInterface(reader, vrvNc);
    final dynamic dyn = vrvNc;
    dyn.readColor(reader);
    dyn.readCurvatureDirection(reader);
    dyn.readIntervalMelodic(reader);
    dyn.readNcForm(reader);

    parent.addChild(vrvNc);
    return readLayerChildren(vrvNc, nc, vrvNc);
  }

  /// Read a `<neume>` (mirrors `ReadNeume`).
  bool readNeume(Object parent, MeiXmlNode neume) {
    final Neume vrvNeume = Neume();
    MeiAttributeReader reader = MeiAttributeReader(neume.attributes);
    readLayerElement(reader, neume, vrvNeume);

    readOffsetInterface(reader, vrvNeume);
    vrvNeume.readColor(reader);

    parent.addChild(vrvNeume);
    return readLayerChildren(vrvNeume, neume, vrvNeume);
  }

  /// Read a `<note>` (mirrors `ReadNote`).
  bool readNote(Object parent, MeiXmlNode note) {
    final Note vrvNote = Note();
    MeiAttributeReader reader = MeiAttributeReader(note.attributes);
    readLayerElement(reader, note, vrvNote);

    if (_before400() && note.hasAttr('size')) {
      note.removeAttribute('size');
      reader.remove('size');
      note.setAttribute('cue', 'true');
    }

    readAltSymInterface(reader, vrvNote);
    readDurationInterface(reader, vrvNote);
    readOffsetInterface(reader, vrvNote);
    readPitchInterface(reader, vrvNote);
    readPositionInterface(reader, vrvNote);
    final dynamic dyn = vrvNote;
    dyn.readColor(reader);
    dyn.readColoration(reader);
    dyn.readCue(reader);
    dyn.readExtSymAuth(reader);
    dyn.readExtSymNames(reader);
    dyn.readGraced(reader);
    dyn.readHarmonicFunction(reader);
    dyn.readMidiVelocity(reader);
    dyn.readNoteHeads(reader);
    dyn.readNoteVisMensural(reader);
    dyn.readStems(reader);
    dyn.readStemsCmn(reader);
    dyn.readStringtab(reader);
    dyn.readTiePresent(reader);
    dyn.readVisibility(reader);

    // att.articulation -> attribute Artic child.
    dyn.readArticulation(reader);
    if ((dyn.hasArtic as bool)) {
      final Artic vrvArtic = Artic();
      vrvArtic.isAttribute = true;
      final List<Articulation> articList =
          (dyn.artic as List<Articulation>? ?? const []);
      vrvArtic.artic = articList;
      if (articList.length > 1) {
        doc.setMarkup(markupArticMultival);
      }
      vrvNote.addChild(vrvArtic);
    }

    readAccidAttr(note, reader, vrvNote);

    if ((dyn.hasTie as bool)) {
      doc.setMarkup(markupAnalyticalTie);
    }

    parent.addChild(vrvNote);
    readUnsupportedAttr(reader, note, vrvNote);
    return readLayerChildren(vrvNote, note, vrvNote);
  }

  /// Read an `<oriscus>` (mirrors `ReadOriscus`).
  bool readOriscus(Object parent, MeiXmlNode oriscus) {
    final Oriscus vrvOriscus = Oriscus();
    MeiAttributeReader reader = MeiAttributeReader(oriscus.attributes);
    readLayerElement(reader, oriscus, vrvOriscus);

    readOffsetInterface(reader, vrvOriscus);
    readPositionInterface(reader, vrvOriscus);
    vrvOriscus.readColor(reader);

    parent.addChild(vrvOriscus);
    readUnsupportedAttr(reader, oriscus, vrvOriscus);

    return true;
  }

  /// Read a `<plica>` (mirrors `ReadPlica`).
  bool readPlica(Object parent, MeiXmlNode plica) {
    final Plica vrvPlica = Plica();
    MeiAttributeReader reader = MeiAttributeReader(plica.attributes);
    readLayerElement(reader, plica, vrvPlica);

    vrvPlica.readPlicaVis(reader);

    parent.addChild(vrvPlica);
    readUnsupportedAttr(reader, plica, vrvPlica);
    return true;
  }

  /// Read a `<proport>` (mirrors `ReadProport`).
  bool readProport(Object parent, MeiXmlNode proport) {
    final Proport vrvProport = Proport();
    MeiAttributeReader reader = MeiAttributeReader(proport.attributes);
    readLayerElement(reader, proport, vrvProport);

    vrvProport.readDurationRatio(reader);

    parent.addChild(vrvProport);
    readUnsupportedAttr(reader, proport, vrvProport);
    return true;
  }

  /// Read a `<quilisma>` (mirrors `ReadQuilisma`).
  bool readQuilisma(Object parent, MeiXmlNode quilisma) {
    final Quilisma vrvQuilisma = Quilisma();
    MeiAttributeReader reader = MeiAttributeReader(quilisma.attributes);
    readLayerElement(reader, quilisma, vrvQuilisma);

    readOffsetInterface(reader, vrvQuilisma);
    readPositionInterface(reader, vrvQuilisma);
    vrvQuilisma.readColor(reader);

    parent.addChild(vrvQuilisma);
    readUnsupportedAttr(reader, quilisma, vrvQuilisma);

    return true;
  }

  /// Read a `<rest>` (mirrors `ReadRest`).
  bool readRest(Object parent, MeiXmlNode rest) {
    final Rest vrvRest = Rest();
    MeiAttributeReader reader = MeiAttributeReader(rest.attributes);
    readLayerElement(reader, rest, vrvRest);

    if (_before400() && rest.hasAttr('size')) {
      rest.removeAttribute('size');
      reader.remove('size');
      rest.setAttribute('cue', 'true');
    }

    readAltSymInterface(reader, vrvRest);
    readDurationInterface(reader, vrvRest);
    readOffsetInterface(reader, vrvRest);
    readPositionInterface(reader, vrvRest);
    final dynamic dyn = vrvRest;
    dyn.readColor(reader);
    dyn.readCue(reader);
    dyn.readEnclosingChars(reader);
    dyn.readExtSymAuth(reader);
    dyn.readExtSymNames(reader);
    dyn.readRestVisMensural(reader);

    parent.addChild(vrvRest);
    readUnsupportedAttr(reader, rest, vrvRest);
    return readLayerChildren(vrvRest, rest, vrvRest);
  }

  /// Read a `<space>` (mirrors `ReadSpace`).
  bool readSpace(Object parent, MeiXmlNode space) {
    final Space vrvSpace = Space();
    MeiAttributeReader reader = MeiAttributeReader(space.attributes);
    readLayerElement(reader, space, vrvSpace);

    readDurationInterface(reader, vrvSpace);

    parent.addChild(vrvSpace);
    readUnsupportedAttr(reader, space, vrvSpace);
    return true;
  }

  /// Read a `<stem>` (mirrors `ReadStem`).
  bool readStem(Object parent, MeiXmlNode stem) {
    final Stem vrvStem = Stem();
    MeiAttributeReader reader = MeiAttributeReader(stem.attributes);
    readLayerElement(reader, stem, vrvStem);

    final dynamic dyn = vrvStem;
    dyn.readGraced(reader);
    dyn.readStemVis(reader);
    dyn.readVisibility(reader);

    parent.addChild(vrvStem);
    readUnsupportedAttr(reader, stem, vrvStem);
    return true;
  }

  /// Read a `<strophicus>` (mirrors `ReadStrophicus`).
  bool readStrophicus(Object parent, MeiXmlNode strophicus) {
    final Strophicus vrvStrophicus = Strophicus();
    MeiAttributeReader reader = MeiAttributeReader(strophicus.attributes);
    readLayerElement(reader, strophicus, vrvStrophicus);

    readOffsetInterface(reader, vrvStrophicus);
    readPositionInterface(reader, vrvStrophicus);
    vrvStrophicus.readColor(reader);

    parent.addChild(vrvStrophicus);
    readUnsupportedAttr(reader, strophicus, vrvStrophicus);

    return true;
  }

  /// Read a `<syl>` (mirrors `ReadSyl`).
  bool readSyl(Object parent, MeiXmlNode syl) {
    // Add empty text node for empty syl element for invisible bbox in neume
    // notation
    if (syl.firstChild() == null && doc.hasFacsimile() && doc.isNeumeLines()) {
      syl.setTextValue('');
    }
    final Syl vrvSyl = Syl();
    MeiAttributeReader reader = MeiAttributeReader(syl.attributes);
    readLayerElement(reader, syl, vrvSyl);

    readFacsimileInterface(reader, vrvSyl);
    readOffsetInterface(reader, vrvSyl);
    final dynamic dyn = vrvSyl;
    dyn.readLang(reader);
    dyn.readTypography(reader);
    dyn.readSylLog(reader);

    parent.addChild(vrvSyl);
    readUnsupportedAttr(reader, syl, vrvSyl);
    return readTextChildren(vrvSyl, syl, vrvSyl);
  }

  /// Read a `<syllable>` (mirrors `ReadSyllable`).
  bool readSyllable(Object parent, MeiXmlNode syllable) {
    final Syllable vrvSyllable = Syllable();
    MeiAttributeReader reader = MeiAttributeReader(syllable.attributes);
    readLayerElement(reader, syllable, vrvSyllable);

    final dynamic dyn = vrvSyllable;
    dyn.readColor(reader);
    dyn.readSlashCount(reader);

    parent.addChild(vrvSyllable);
    return readLayerChildren(vrvSyllable, syllable, vrvSyllable);
  }

  /// Read a `<tabDurSym>` (mirrors `ReadTabDurSym`).
  bool readTabDurSym(Object parent, MeiXmlNode tabRhyhtm) {
    final TabDurSym vrvTabDurSym = TabDurSym();
    MeiAttributeReader reader = MeiAttributeReader(tabRhyhtm.attributes);
    readLayerElement(reader, tabRhyhtm, vrvTabDurSym);

    final dynamic dyn = vrvTabDurSym;
    dyn.readNNumberLike(reader);
    dyn.readStringtab(reader);
    dyn.readVisualOffsetVo(reader);

    parent.addChild(vrvTabDurSym);
    readUnsupportedAttr(reader, tabRhyhtm, vrvTabDurSym);
    return true;
  }

  /// Read a `<tabGrp>` (mirrors `ReadTabGrp`).
  bool readTabGrp(Object parent, MeiXmlNode tabGrp) {
    final TabGrp vrvTabGrp = TabGrp();
    MeiAttributeReader reader = MeiAttributeReader(tabGrp.attributes);
    readLayerElement(reader, tabGrp, vrvTabGrp);

    readDurationInterface(reader, vrvTabGrp);
    readOffsetInterface(reader, vrvTabGrp);

    parent.addChild(vrvTabGrp);
    readUnsupportedAttr(reader, tabGrp, vrvTabGrp);
    return readLayerChildren(vrvTabGrp, tabGrp, vrvTabGrp);
  }

  /// Read a `<tuplet>` (mirrors `ReadTuplet`).
  bool readTuplet(Object parent, MeiXmlNode tuplet) {
    final Tuplet vrvTuplet = Tuplet();
    MeiAttributeReader reader = MeiAttributeReader(tuplet.attributes);
    readLayerElement(reader, tuplet, vrvTuplet);

    final dynamic dyn = vrvTuplet;
    dyn.readColor(reader);
    dyn.readDurationRatio(reader);
    dyn.readNumberPlacement(reader);
    dyn.readTupletVis(reader);

    parent.addChild(vrvTuplet);
    readUnsupportedAttr(reader, tuplet, vrvTuplet);
    return readLayerChildren(vrvTuplet, tuplet, vrvTuplet);
  }

  /// Read a `<verse>` (mirrors `ReadVerse`).
  bool readVerse(Object parent, MeiXmlNode verse) {
    final Verse vrvVerse = Verse();
    MeiAttributeReader reader = MeiAttributeReader(verse.attributes);
    readLayerElement(reader, verse, vrvVerse);

    final dynamic dyn = vrvVerse;
    dyn.readColor(reader);
    dyn.readLang(reader);
    dyn.readNInteger(reader);
    dyn.readPlacementRelStaff(reader);
    dyn.readTypography(reader);

    parent.addChild(vrvVerse);
    readUnsupportedAttr(reader, verse, vrvVerse);
    return readLayerChildren(vrvVerse, verse, vrvVerse);
  }

  // -------------------------------------------------------------------------
  // Control elements
  // -------------------------------------------------------------------------

  /// Read an `<anchoredText>` (mirrors `ReadAnchoredText`).
  bool readAnchoredText(Object parent, MeiXmlNode anchoredText) {
    final AnchoredText vrvAnchoredText = AnchoredText();
    MeiAttributeReader reader = MeiAttributeReader(anchoredText.attributes);
    readControlElement(reader, anchoredText, vrvAnchoredText);

    readTextDirInterface(reader, vrvAnchoredText);

    readUnsupportedAttr(reader, anchoredText, vrvAnchoredText);
    parent.addChild(vrvAnchoredText);
    return readTextChildren(vrvAnchoredText, anchoredText, vrvAnchoredText);
  }

  /// Read an `<arpeg>` (mirrors `ReadArpeg`).
  bool readArpeg(Object parent, MeiXmlNode arpeg) {
    final Arpeg vrvArpeg = Arpeg();
    MeiAttributeReader reader = MeiAttributeReader(arpeg.attributes);
    readControlElement(reader, arpeg, vrvArpeg);

    readPlistInterface(reader, vrvArpeg);
    readTimePointInterface(reader, vrvArpeg);
    final dynamic dyn = vrvArpeg;
    dyn.readArpegLog(reader);
    dyn.readArpegVis(reader);
    dyn.readEnclosingChars(reader);

    parent.addChild(vrvArpeg);
    readUnsupportedAttr(reader, arpeg, vrvArpeg);
    return true;
  }

  /// Read a `<beamSpan>` (mirrors `ReadBeamSpan`).
  bool readBeamSpan(Object parent, MeiXmlNode beamSpan) {
    final BeamSpan vrvBeamSpan = BeamSpan();
    MeiAttributeReader reader = MeiAttributeReader(beamSpan.attributes);
    readControlElement(reader, beamSpan, vrvBeamSpan);

    readPlistInterface(reader, vrvBeamSpan);
    readTimeSpanningInterface(reader, vrvBeamSpan);
    final dynamic dyn = vrvBeamSpan;
    dyn.readBeamedWith(reader);
    dyn.readBeamRend(reader);

    parent.addChild(vrvBeamSpan);
    readUnsupportedAttr(reader, beamSpan, vrvBeamSpan);
    return true;
  }

  /// Read a `<bracketSpan>` (mirrors `ReadBracketSpan`).
  bool readBracketSpan(Object parent, MeiXmlNode bracketSpan) {
    final BracketSpan vrvBracketSpan = BracketSpan();
    MeiAttributeReader reader = MeiAttributeReader(bracketSpan.attributes);
    readControlElement(reader, bracketSpan, vrvBracketSpan);

    readTimeSpanningInterface(reader, vrvBracketSpan);
    final dynamic dyn = vrvBracketSpan;
    dyn.readBracketSpanLog(reader);
    dyn.readLineRend(reader);
    dyn.readLineRendBase(reader);

    parent.addChild(vrvBracketSpan);
    readUnsupportedAttr(reader, bracketSpan, vrvBracketSpan);
    return true;
  }

  /// Read a `<breath>` (mirrors `ReadBreath`).
  bool readBreath(Object parent, MeiXmlNode breath) {
    final Breath vrvBreath = Breath();
    MeiAttributeReader reader = MeiAttributeReader(breath.attributes);
    readControlElement(reader, breath, vrvBreath);

    readTimePointInterface(reader, vrvBreath);
    vrvBreath.readPlacementRelStaff(reader);

    parent.addChild(vrvBreath);
    readUnsupportedAttr(reader, breath, vrvBreath);
    return true;
  }

  /// Read a `<caesura>` (mirrors `ReadCaesura`).
  bool readCaesura(Object parent, MeiXmlNode caesura) {
    final Caesura vrvCaesura = Caesura();
    MeiAttributeReader reader = MeiAttributeReader(caesura.attributes);
    readControlElement(reader, caesura, vrvCaesura);

    readTimePointInterface(reader, vrvCaesura);
    final dynamic dyn = vrvCaesura;
    dyn.readExtSymAuth(reader);
    dyn.readExtSymNames(reader);
    dyn.readPlacementRelStaff(reader);

    parent.addChild(vrvCaesura);
    readUnsupportedAttr(reader, caesura, vrvCaesura);
    return true;
  }

  /// Read a `<cpMark>` (mirrors `ReadCpMark`).
  bool readCpMark(Object parent, MeiXmlNode cpMark) {
    final CpMark vrvCpMark = CpMark();
    MeiAttributeReader reader = MeiAttributeReader(cpMark.attributes);
    readControlElement(reader, cpMark, vrvCpMark);

    readTextDirInterface(reader, vrvCpMark);
    readTimeSpanningInterface(reader, vrvCpMark);

    parent.addChild(vrvCpMark);
    readUnsupportedAttr(reader, cpMark, vrvCpMark);
    return readTextChildren(vrvCpMark, cpMark, vrvCpMark);
  }

  /// Read a `<dir>` / `<stageDir>` (mirrors `ReadDir`).
  bool readDir(Object parent, MeiXmlNode dir, [bool isStageDir = false]) {
    final Dir vrvDir = Dir(isStageDir);
    MeiAttributeReader reader = MeiAttributeReader(dir.attributes);
    readControlElement(reader, dir, vrvDir);

    readTextDirInterface(reader, vrvDir);
    readTimeSpanningInterface(reader, vrvDir);
    final dynamic dyn = vrvDir;
    dyn.readLang(reader);
    dyn.readLineRendBase(reader);
    dyn.readExtender(reader);
    dyn.readVerticalGroup(reader);

    parent.addChild(vrvDir);
    readUnsupportedAttr(reader, dir, vrvDir);
    return readTextChildren(vrvDir, dir, vrvDir);
  }

  /// Read a `<dynam>` (mirrors `ReadDynam`).
  bool readDynam(Object parent, MeiXmlNode dynam) {
    final Dynam vrvDynam = Dynam();
    MeiAttributeReader reader = MeiAttributeReader(dynam.attributes);
    readControlElement(reader, dynam, vrvDynam);

    readTextDirInterface(reader, vrvDynam);
    readTimeSpanningInterface(reader, vrvDynam);
    final dynamic dyn = vrvDynam;
    dyn.readEnclosingChars(reader);
    dyn.readExtender(reader);
    dyn.readLineRendBase(reader);
    dyn.readMidiValue(reader);
    dyn.readMidiValue2(reader);
    dyn.readVerticalGroup(reader);

    parent.addChild(vrvDynam);
    readUnsupportedAttr(reader, dynam, vrvDynam);
    return readTextChildren(vrvDynam, dynam, vrvDynam);
  }

  /// Read a `<fermata>` (mirrors `ReadFermata`).
  bool readFermata(Object parent, MeiXmlNode fermata) {
    final Fermata vrvFermata = Fermata();
    MeiAttributeReader reader = MeiAttributeReader(fermata.attributes);
    readControlElement(reader, fermata, vrvFermata);

    readTimePointInterface(reader, vrvFermata);
    final dynamic dyn = vrvFermata;
    dyn.readEnclosingChars(reader);
    dyn.readExtSymAuth(reader);
    dyn.readExtSymNames(reader);
    dyn.readFermataVis(reader);
    dyn.readPlacementRelStaff(reader);

    parent.addChild(vrvFermata);
    readUnsupportedAttr(reader, fermata, vrvFermata);
    return true;
  }

  /// Read a `<fing>` (mirrors `ReadFing`).
  bool readFing(Object parent, MeiXmlNode fing) {
    final Fing vrvFing = Fing();
    MeiAttributeReader reader = MeiAttributeReader(fing.attributes);
    readControlElement(reader, fing, vrvFing);

    readTextDirInterface(reader, vrvFing);
    readTimePointInterface(reader, vrvFing);
    vrvFing.readNNumberLike(reader);

    parent.addChild(vrvFing);
    readUnsupportedAttr(reader, fing, vrvFing);
    return readTextChildren(vrvFing, fing, vrvFing);
  }

  /// Read a `<gliss>` (mirrors `ReadGliss`).
  bool readGliss(Object parent, MeiXmlNode gliss) {
    final Gliss vrvGliss = Gliss();
    MeiAttributeReader reader = MeiAttributeReader(gliss.attributes);
    readControlElement(reader, gliss, vrvGliss);

    readTimeSpanningInterface(reader, vrvGliss);
    final dynamic dyn = vrvGliss;
    dyn.readLineRend(reader);
    dyn.readLineRendBase(reader);
    dyn.readNNumberLike(reader);

    parent.addChild(vrvGliss);
    readUnsupportedAttr(reader, gliss, vrvGliss);
    return true;
  }

  /// Read a `<hairpin>` (mirrors `ReadHairpin`).
  bool readHairpin(Object parent, MeiXmlNode hairpin) {
    final Hairpin vrvHairpin = Hairpin();
    MeiAttributeReader reader = MeiAttributeReader(hairpin.attributes);
    readControlElement(reader, hairpin, vrvHairpin);

    readOffsetSpanningInterface(reader, vrvHairpin);
    readTimeSpanningInterface(reader, vrvHairpin);
    final dynamic dyn = vrvHairpin;
    dyn.readHairpinLog(reader);
    dyn.readHairpinVis(reader);
    dyn.readLineRendBase(reader);
    dyn.readPlacementRelStaff(reader);
    dyn.readVerticalGroup(reader);

    parent.addChild(vrvHairpin);
    readUnsupportedAttr(reader, hairpin, vrvHairpin);
    return true;
  }

  /// Read a `<harm>` (mirrors `ReadHarm`).
  bool readHarm(Object parent, MeiXmlNode harm) {
    final Harm vrvHarm = Harm();
    MeiAttributeReader reader = MeiAttributeReader(harm.attributes);
    readControlElement(reader, harm, vrvHarm);

    readTextDirInterface(reader, vrvHarm);
    readTimeSpanningInterface(reader, vrvHarm);
    final dynamic dyn = vrvHarm;
    dyn.readLang(reader);
    dyn.readNNumberLike(reader);

    parent.addChild(vrvHarm);
    readUnsupportedAttr(reader, harm, vrvHarm);
    return readTextChildren(vrvHarm, harm, vrvHarm);
  }

  /// Read an `<lv>` (mirrors `ReadLv`).
  bool readLv(Object parent, MeiXmlNode lv) {
    final Lv vrvLv = Lv();
    MeiAttributeReader reader = MeiAttributeReader(lv.attributes);
    readControlElement(reader, lv, vrvLv);

    readOffsetSpanningInterface(reader, vrvLv);
    readTimeSpanningInterface(reader, vrvLv);
    final dynamic dyn = vrvLv;
    dyn.readCurvature(reader);
    dyn.readLineRendBase(reader);

    parent.addChild(vrvLv);
    readUnsupportedAttr(reader, lv, vrvLv);
    return true;
  }

  /// Read an `<mNum>` (mirrors `ReadMNum`).
  bool readMNum(Object parent, MeiXmlNode mNum) {
    final MNum vrvMNum = MNum();
    MeiAttributeReader reader = MeiAttributeReader(mNum.attributes);
    readControlElement(reader, mNum, vrvMNum);

    readTextDirInterface(reader, vrvMNum);
    readTimePointInterface(reader, vrvMNum);
    final dynamic dyn = vrvMNum;
    dyn.readLang(reader);
    dyn.readTypography(reader);

    if (deserializing) {
      if (mNum.hasAttr(verovioSerialization)) {
        if (mNum.attr(verovioSerialization) == 'generated') {
          vrvMNum.isGeneratedFlag = true;
        }
        mNum.removeAttribute(verovioSerialization);
      }
    }

    parent.addChild(vrvMNum);
    return readTextChildren(vrvMNum, mNum, vrvMNum);
  }

  /// Read a `<mordent>` (mirrors `ReadMordent`).
  bool readMordent(Object parent, MeiXmlNode mordent) {
    final Mordent vrvMordent = Mordent();
    MeiAttributeReader reader = MeiAttributeReader(mordent.attributes);
    readControlElement(reader, mordent, vrvMordent);

    if (_before400()) {
      upgradeMordentTo400(mordent, vrvMordent);
    }

    readTimePointInterface(reader, vrvMordent);
    final dynamic dyn = vrvMordent;
    dyn.readEnclosingChars(reader);
    dyn.readExtSymAuth(reader);
    dyn.readExtSymNames(reader);
    dyn.readOrnamentAccid(reader);
    dyn.readPlacementRelStaff(reader);
    dyn.readMordentLog(reader);

    parent.addChild(vrvMordent);
    readUnsupportedAttr(reader, mordent, vrvMordent);
    return true;
  }

  /// Read an `<octave>` (mirrors `ReadOctave`).
  bool readOctave(Object parent, MeiXmlNode octave) {
    final Octave vrvOctave = Octave();
    MeiAttributeReader reader = MeiAttributeReader(octave.attributes);
    readControlElement(reader, octave, vrvOctave);

    readTimeSpanningInterface(reader, vrvOctave);
    final dynamic dyn = vrvOctave;
    dyn.readExtender(reader);
    dyn.readLineRend(reader);
    dyn.readLineRendBase(reader);
    dyn.readNNumberLike(reader);
    dyn.readOctaveDisplacement(reader);

    parent.addChild(vrvOctave);
    readUnsupportedAttr(reader, octave, vrvOctave);
    return true;
  }

  /// Read an `<ornam>` (mirrors `ReadOrnam`).
  bool readOrnam(Object parent, MeiXmlNode ornam) {
    final Ornam vrvOrnam = Ornam();
    MeiAttributeReader reader = MeiAttributeReader(ornam.attributes);
    readControlElement(reader, ornam, vrvOrnam);

    readTextDirInterface(reader, vrvOrnam);
    readTimePointInterface(reader, vrvOrnam);
    vrvOrnam.readOrnamentAccid(reader);

    parent.addChild(vrvOrnam);
    readUnsupportedAttr(reader, ornam, vrvOrnam);
    return readTextChildren(vrvOrnam, ornam, vrvOrnam);
  }

  /// Read a `<pedal>` (mirrors `ReadPedal`).
  bool readPedal(Object parent, MeiXmlNode pedal) {
    final Pedal vrvPedal = Pedal();
    MeiAttributeReader reader = MeiAttributeReader(pedal.attributes);
    readControlElement(reader, pedal, vrvPedal);

    readTimeSpanningInterface(reader, vrvPedal);
    final dynamic dyn = vrvPedal;
    dyn.readExtSymAuth(reader);
    dyn.readExtSymNames(reader);
    dyn.readPedalLog(reader);
    dyn.readPedalVis(reader);
    dyn.readPlacementRelStaff(reader);
    dyn.readVerticalGroup(reader);

    parent.addChild(vrvPedal);
    readUnsupportedAttr(reader, pedal, vrvPedal);
    return true;
  }

  /// Read a `<phrase>` (mirrors `ReadPhrase`).
  bool readPhrase(Object parent, MeiXmlNode phrase) {
    final Phrase vrvPhrase = Phrase();
    MeiAttributeReader reader = MeiAttributeReader(phrase.attributes);
    readControlElement(reader, phrase, vrvPhrase);

    readOffsetSpanningInterface(reader, vrvPhrase);
    readTimeSpanningInterface(reader, vrvPhrase);
    final dynamic dyn = vrvPhrase;
    dyn.readCurvature(reader);
    dyn.readLayerIdent(reader);
    dyn.readLineRendBase(reader);

    parent.addChild(vrvPhrase);
    readUnsupportedAttr(reader, phrase, vrvPhrase);
    return true;
  }

  /// Read a `<pitchInflection>` (mirrors `ReadPitchInflection`).
  bool readPitchInflection(Object parent, MeiXmlNode pitchInflection) {
    final PitchInflection vrvPitchInflection = PitchInflection();
    MeiAttributeReader reader = MeiAttributeReader(pitchInflection.attributes);
    readControlElement(reader, pitchInflection, vrvPitchInflection);

    readTimeSpanningInterface(reader, vrvPitchInflection);

    parent.addChild(vrvPitchInflection);
    readUnsupportedAttr(reader, pitchInflection, vrvPitchInflection);
    return true;
  }

  /// Read a `<reh>` (mirrors `ReadReh`).
  bool readReh(Object parent, MeiXmlNode reh) {
    final Reh vrvReh = Reh();
    MeiAttributeReader reader = MeiAttributeReader(reh.attributes);
    readControlElement(reader, reh, vrvReh);

    readTextDirInterface(reader, vrvReh);
    readTimePointInterface(reader, vrvReh);
    final dynamic dyn = vrvReh;
    dyn.readLang(reader);
    dyn.readVerticalGroup(reader);

    parent.addChild(vrvReh);
    readUnsupportedAttr(reader, reh, vrvReh);
    return readTextChildren(vrvReh, reh, vrvReh);
  }

  /// Read a `<repeatMark>` (mirrors `ReadRepeatMark`).
  bool readRepeatMark(Object parent, MeiXmlNode repeatMark) {
    final RepeatMark vrvRepeatMark = RepeatMark();
    MeiAttributeReader reader = MeiAttributeReader(repeatMark.attributes);
    readControlElement(reader, repeatMark, vrvRepeatMark);

    readTextDirInterface(reader, vrvRepeatMark);
    readTimePointInterface(reader, vrvRepeatMark);
    final dynamic dyn = vrvRepeatMark;
    dyn.readExtSymAuth(reader);
    dyn.readExtSymNames(reader);
    dyn.readRepeatMarkLog(reader);

    parent.addChild(vrvRepeatMark);
    readUnsupportedAttr(reader, repeatMark, vrvRepeatMark);
    return readTextChildren(vrvRepeatMark, repeatMark, vrvRepeatMark);
  }

  /// Read a `<slur>` (mirrors `ReadSlur`).
  bool readSlur(Object parent, MeiXmlNode slur) {
    final Slur vrvSlur = Slur();
    MeiAttributeReader reader = MeiAttributeReader(slur.attributes);
    readControlElement(reader, slur, vrvSlur);

    readOffsetSpanningInterface(reader, vrvSlur);
    readTimeSpanningInterface(reader, vrvSlur);
    final dynamic dyn = vrvSlur;
    dyn.readCurvature(reader);
    dyn.readLayerIdent(reader);
    dyn.readLineRendBase(reader);

    parent.addChild(vrvSlur);
    readUnsupportedAttr(reader, slur, vrvSlur);
    return true;
  }

  /// Read a `<tempo>` (mirrors `ReadTempo`).
  bool readTempo(Object parent, MeiXmlNode tempo) {
    final Tempo vrvTempo = Tempo();
    MeiAttributeReader reader = MeiAttributeReader(tempo.attributes);
    readControlElement(reader, tempo, vrvTempo);

    readTextDirInterface(reader, vrvTempo);
    readTimeSpanningInterface(reader, vrvTempo);
    final dynamic dyn = vrvTempo;
    dyn.readExtender(reader);
    dyn.readLang(reader);
    dyn.readMidiTempo(reader);
    dyn.readMmTempo(reader);

    parent.addChild(vrvTempo);
    readUnsupportedAttr(reader, tempo, vrvTempo);
    return readTextChildren(vrvTempo, tempo, vrvTempo);
  }

  /// Read a `<tie>` (mirrors `ReadTie`).
  bool readTie(Object parent, MeiXmlNode tie) {
    final Tie vrvTie = Tie();
    MeiAttributeReader reader = MeiAttributeReader(tie.attributes);
    readControlElement(reader, tie, vrvTie);

    readOffsetSpanningInterface(reader, vrvTie);
    readTimeSpanningInterface(reader, vrvTie);
    final dynamic dyn = vrvTie;
    dyn.readCurvature(reader);
    dyn.readLineRendBase(reader);

    parent.addChild(vrvTie);
    readUnsupportedAttr(reader, tie, vrvTie);
    return true;
  }

  /// Read a `<trill>` (mirrors `ReadTrill`).
  bool readTrill(Object parent, MeiXmlNode trill) {
    final Trill vrvTrill = Trill();
    MeiAttributeReader reader = MeiAttributeReader(trill.attributes);
    readControlElement(reader, trill, vrvTrill);

    readTimeSpanningInterface(reader, vrvTrill);
    final dynamic dyn = vrvTrill;
    dyn.readEnclosingChars(reader);
    dyn.readExtender(reader);
    dyn.readExtSymAuth(reader);
    dyn.readExtSymNames(reader);
    dyn.readLineRend(reader);
    dyn.readNNumberLike(reader);
    dyn.readOrnamentAccid(reader);
    dyn.readPlacementRelStaff(reader);

    parent.addChild(vrvTrill);
    readUnsupportedAttr(reader, trill, vrvTrill);
    return true;
  }

  /// Read a `<turn>` (mirrors `ReadTurn`).
  bool readTurn(Object parent, MeiXmlNode turn) {
    final Turn vrvTurn = Turn();
    MeiAttributeReader reader = MeiAttributeReader(turn.attributes);
    readControlElement(reader, turn, vrvTurn);

    if (_before400()) {
      upgradeTurnTo400(turn, vrvTurn);
    }

    readTimePointInterface(reader, vrvTurn);
    final dynamic dyn = vrvTurn;
    dyn.readEnclosingChars(reader);
    dyn.readExtSymAuth(reader);
    dyn.readExtSymNames(reader);
    dyn.readOrnamentAccid(reader);
    dyn.readPlacementRelStaff(reader);
    dyn.readTurnLog(reader);

    parent.addChild(vrvTurn);
    readUnsupportedAttr(reader, turn, vrvTurn);
    return true;
  }

  /// Read a score annotation within measures (mirrors `ReadAnnotScore`).
  bool readAnnotScore(Object parent, MeiXmlNode annot) {
    final AnnotScore vrvAnnotScore = AnnotScore();

    MeiAttributeReader reader = MeiAttributeReader(annot.attributes);
    readControlElement(reader, annot, vrvAnnotScore);
    readPlistInterface(reader, vrvAnnotScore);
    readTimeSpanningInterface(reader, vrvAnnotScore);

    parent.addChild(vrvAnnotScore);

    bool hasNonTextContent = false;
    for (final MeiXmlNode child in annot.children) {
      final String nodeName = child.isElement ? child.name : '';
      if (!hasNonTextContent && nodeName.isNotEmpty) hasNonTextContent = true;
    }
    readUnsupportedAttr(reader, annot, vrvAnnotScore);
    // Unless annot has only text we do not load children.
    if (hasNonTextContent) {
      return true;
    } else {
      return readTextChildren(vrvAnnotScore, annot, vrvAnnotScore);
    }
  }

  // -------------------------------------------------------------------------
  // Text and figure elements
  // -------------------------------------------------------------------------

  /// Read the children of text containers (mirrors `ReadTextChildren`).
  bool readTextChildren(Object parent, MeiXmlNode parentNode,
      [Object? filter]) {
    bool success = true;
    int i = 0;
    MeiXmlNode? xmlElement = parentNode.firstChild();
    while (xmlElement != null) {
      if (!success) break;
      normalizeAttributes(xmlElement);
      final String elementName = xmlElement.name;
      if (filter != null && !isAllowed(elementName, filter)) {
        logWarning('Element <$elementName> within <${filter.className}> is '
            'not supported and will be ignored ');
        xmlElement = xmlElement.nextSibling();
        continue;
      }
      // editorial
      if (isEditorialElementName(xmlElement.name)) {
        success =
            readEditorialElement(parent, xmlElement, EditorialLevel.text, filter);
      }
      // content
      else if (elementName == 'fig') {
        success = readFig(parent, xmlElement);
      } else if (elementName == 'lb') {
        success = readLb(parent, xmlElement);
      } else if (elementName == 'num') {
        success = readNum(parent, xmlElement);
      } else if (elementName == 'rend') {
        success = readRend(parent, xmlElement);
      } else if (elementName == 'svg') {
        success = readSvg(parent, xmlElement);
      } else if (elementName == 'symbol') {
        success = readSymbol(parent, xmlElement);
      } else if (xmlElement.isText && (xmlElement.value?.isNotEmpty ?? false)) {
        final bool trimLeft = (i == 0);
        final bool trimRight = (xmlElement.nextSibling() == null);
        success = readText(parent, xmlElement, trimLeft, trimRight);
      }
      // figured bass
      else if (elementName == 'fb') {
        success = readFb(parent, xmlElement);
      }
      // xml comment
      else if (!xmlElement.isElement) {
        success = readXMLComment(parent, xmlElement);
      }
      // unknown
      else {
        logWarning('Element <$elementName> is unknown and will be ignored');
      }
      ++i;
      xmlElement = xmlElement.nextSibling();
    }
    return success;
  }

  /// Read an `<f>` within figured bass (mirrors `ReadF`).
  bool readF(Object parent, MeiXmlNode f) {
    final F vrvF = F();
    MeiAttributeReader reader = MeiAttributeReader(f.attributes);
    readTextElementBase(reader, f, vrvF);

    readTimeSpanningInterface(reader, vrvF);
    vrvF.readExtender(reader);

    parent.addChild(vrvF);
    readUnsupportedAttr(reader, f, vrvF);
    return readTextChildren(vrvF, f, vrvF);
  }

  /// Read a `<fig>` (mirrors `ReadFig`).
  bool readFig(Object parent, MeiXmlNode fig) {
    final Fig vrvFig = Fig();
    MeiAttributeReader reader = MeiAttributeReader(fig.attributes);
    readTextElementBase(reader, fig, vrvFig);

    readAreaPosInterface(reader, vrvFig);

    parent.addChild(vrvFig);
    readUnsupportedAttr(reader, fig, vrvFig);
    return readTextChildren(vrvFig, fig, vrvFig);
  }

  /// Read an `<lb>` (mirrors `ReadLb`).
  bool readLb(Object parent, MeiXmlNode lb) {
    final Lb vrvLb = Lb();
    MeiAttributeReader reader = MeiAttributeReader(lb.attributes);
    readTextElementBase(reader, lb, vrvLb);

    parent.addChild(vrvLb);
    readUnsupportedAttr(reader, lb, vrvLb);
    return true;
  }

  /// Read a `<num>` (mirrors `ReadNum`).
  bool readNum(Object parent, MeiXmlNode num) {
    final Num vrvNum = Num();
    MeiAttributeReader reader = MeiAttributeReader(num.attributes);
    readTextElementBase(reader, num, vrvNum);

    parent.addChild(vrvNum);
    readUnsupportedAttr(reader, num, vrvNum);
    return readTextChildren(vrvNum, num, vrvNum);
  }

  /// Read a `<rend>` (mirrors `ReadRend`).
  bool readRend(Object parent, MeiXmlNode rend) {
    if (_atOrBefore50()) {
      upgradeRendTo500(rend);
    }

    final Rend vrvRend = Rend();
    MeiAttributeReader reader = MeiAttributeReader(rend.attributes);
    readTextElementBase(reader, rend, vrvRend);

    readAreaPosInterface(reader, vrvRend);

    final dynamic dyn = vrvRend;
    dyn.readColor(reader);
    dyn.readExtSymAuth(reader);
    dyn.readLang(reader);
    dyn.readNNumberLike(reader);
    dyn.readTextRendition(reader);
    dyn.readTypography(reader);
    dyn.readWhitespace(reader);

    if ((vrvRend.getFirstAncestor(ClassId.rend) != null) &&
        ((dyn.hasHalign as bool) || (dyn.hasValign as bool))) {
      logWarning('@halign or @valign in nested <rend> element <rend> '
          '${vrvRend.id} will be ignored');
      // Eventually to be added to unsupported attributes?
      dyn.halign = Horizontalalignment.none;
      dyn.valign = Verticalalignment.none;
    }
    // Previously we would use @fontname="VerovioText"; now
    // @glyph.auth="smufl".
    if ((dyn.hasFontname as bool) && (dyn.fontname as String) == 'VerovioText') {
      logWarning("Using rend@fontname with 'VerovioText' is deprecated. Use "
                  "'rend@glyph.auth=\"smufl\"' instead");
      dyn.glyphAuth = 'smufl';
      dyn.fontname = '';
    }

    parent.addChild(vrvRend);
    readUnsupportedAttr(reader, rend, vrvRend);
    return readTextChildren(vrvRend, rend, vrvRend);
  }

  /// Read an `<svg>` (mirrors `ReadSvg`; content stored serialized).
  bool readSvg(Object parent, MeiXmlNode svg) {
    final Svg vrvSvg = Svg();
    MeiAttributeReader reader = MeiAttributeReader(svg.attributes);
    // Still read the @xml:id for handling the comments
    setMeiID(svg, vrvSvg, reader);

    // Read the @id by hand
    if (svg.hasAttr('id')) {
      vrvSvg.id = svg.attr('id')!;
      svg.removeAttribute('id');
      reader.remove('id');
    }

    if (svg.name == 'svg') {
      vrvSvg.content = svg.serialize();
    } else {
      logWarning('No svg content found for <fig> ${parent.id}');
    }

    parent.addChild(vrvSvg);
    readUnsupportedAttr(reader, svg, vrvSvg);
    return true;
  }

  /// Read a `<symbol>` (mirrors `ReadSymbol`).
  bool readSymbol(Object parent, MeiXmlNode symbol) {
    final Symbol vrvSymbol = Symbol();
    MeiAttributeReader reader = MeiAttributeReader(symbol.attributes);
    readTextElementBase(reader, symbol, vrvSymbol);

    final dynamic dyn = vrvSymbol;
    dyn.readColor(reader);
    dyn.readExtSymAuth(reader);
    dyn.readExtSymNames(reader);
    dyn.readTypography(reader);

    parent.addChild(vrvSymbol);
    readUnsupportedAttr(reader, symbol, vrvSymbol);
    return true;
  }

  /// Read a text node (mirrors `ReadText`).
  bool readText(
      Object parent, MeiXmlNode text, bool trimLeft, bool trimRight) {
    final Text vrvText = Text();

    String str = text.value ?? '';
    if (trimLeft) str = _leftTrim(str);
    if (trimRight) str = _rightTrim(str);

    vrvText.text = str;

    parent.addChild(vrvText);
    return true;
  }

  String _leftTrim(String str) =>
      str.replaceFirst(RegExp(r'^\s+'), '');

  String _rightTrim(String str) => str.replaceFirst(RegExp(r'\s+$'), '');

  // -------------------------------------------------------------------------
  // Figured bass
  // -------------------------------------------------------------------------

  /// Read a `<fb>` (mirrors `ReadFb`).
  bool readFb(Object parent, MeiXmlNode fb) {
    final Fb vrvFb = Fb();
    MeiAttributeReader reader = MeiAttributeReader(fb.attributes);
    setMeiID(fb, vrvFb, reader);

    parent.addChild(vrvFb);
    readUnsupportedAttr(reader, fb, vrvFb);
    return readFbChildren(vrvFb, fb);
  }

  /// Read the children of an `<fb>` (mirrors `ReadFbChildren`).
  bool readFbChildren(Object parent, MeiXmlNode parentNode) {
    bool success = true;
    MeiXmlNode? current = parentNode.firstChild();
    while (current != null) {
      if (!success) break;
      normalizeAttributes(current);
      // editorial
      if (isEditorialElementName(current.name)) {
        success = readEditorialElement(parent, current, EditorialLevel.fb);
      }
      // content
      else if (current.name == 'f') {
        success = readF(parent, current);
      }
      // xml comment
      else if (!current.isElement) {
        success = readXMLComment(parent, current);
      } else {
        logWarning("Unsupported '<${current.name}>' within <fb>");
      }
      current = current.nextSibling();
    }
    return success;
  }

  // -------------------------------------------------------------------------
  // Editorial elements
  // -------------------------------------------------------------------------

  /// Dispatch to the editorial readers (mirrors the first `ReadEditorialElement`
  /// overload).
  bool readEditorialElement(Object parent, MeiXmlNode current,
      EditorialLevel level,
      [Object? filter]) {
    switch (current.name) {
      case 'abbr':
        return readAbbr(parent, current, level, filter);
      case 'add':
        return readAdd(parent, current, level, filter);
      case 'app':
        return readApp(parent, current, level, filter);
      case 'annot':
        return readAnnot(parent, current);
      case 'choice':
        return readChoice(parent, current, level, filter);
      case 'corr':
        return readCorr(parent, current, level, filter);
      case 'damage':
        return readDamage(parent, current, level, filter);
      case 'del':
        return readDel(parent, current, level, filter);
      case 'expan':
        return readExpan(parent, current, level, filter);
      case 'orig':
        return readOrig(parent, current, level, filter);
      case 'ref':
        return readRef(parent, current, level, filter);
      case 'reg':
        return readReg(parent, current, level, filter);
      case 'restore':
        return readRestore(parent, current, level, filter);
      case 'sic':
        return readSic(parent, current, level, filter);
      case 'subst':
        return readSubst(parent, current, level, filter);
      case 'supplied':
        return readSupplied(parent, current, level, filter);
      case 'unclear':
        return readUnclear(parent, current, level, filter);
      default:
        assert(false); // s_editorialElementNames should be updated
        return false;
    }
  }

  bool readAbbr(Object parent, MeiXmlNode abbr, EditorialLevel level,
      [Object? filter]) =>
      _readSourceEditorial(Abbr(), parent, abbr, level, filter);

  bool readAdd(Object parent, MeiXmlNode add, EditorialLevel level,
          [Object? filter]) =>
      _readSourceEditorial(Add(), parent, add, level, filter);

  bool readCorr(Object parent, MeiXmlNode corr, EditorialLevel level,
          [Object? filter]) =>
      _readSourceEditorial(Corr(), parent, corr, level, filter);

  bool readDamage(Object parent, MeiXmlNode damage, EditorialLevel level,
          [Object? filter]) =>
      _readSourceEditorial(Damage(), parent, damage, level, filter);

  bool readDel(Object parent, MeiXmlNode del, EditorialLevel level,
          [Object? filter]) =>
      _readSourceEditorial(Del(), parent, del, level, filter);

  bool readExpan(Object parent, MeiXmlNode expan, EditorialLevel level,
          [Object? filter]) =>
      _readSourceEditorial(Expan(), parent, expan, level, filter);

  bool readOrig(Object parent, MeiXmlNode orig, EditorialLevel level,
          [Object? filter]) =>
      _readSourceEditorial(Orig(), parent, orig, level, filter);

  bool readRef(Object parent, MeiXmlNode ref, EditorialLevel level,
          [Object? filter]) =>
      _readPlainEditorial(Ref(), parent, ref, level, filter);

  bool readReg(Object parent, MeiXmlNode reg, EditorialLevel level,
          [Object? filter]) =>
      _readSourceEditorial(Reg(), parent, reg, level, filter);

  bool readRestore(Object parent, MeiXmlNode restore, EditorialLevel level,
          [Object? filter]) =>
      _readSourceEditorial(Restore(), parent, restore, level, filter);

  bool readSic(Object parent, MeiXmlNode sic, EditorialLevel level,
          [Object? filter]) =>
      _readSourceEditorial(Sic(), parent, sic, level, filter);

  bool readSupplied(Object parent, MeiXmlNode supplied, EditorialLevel level,
          [Object? filter]) =>
      _readSourceEditorial(Supplied(), parent, supplied, level, filter);

  bool readUnclear(Object parent, MeiXmlNode unclear, EditorialLevel level,
          [Object? filter]) =>
      _readSourceEditorial(Unclear(), parent, unclear, level, filter);

  /// Shared body for editorial elements that only have @source + children.
  bool _readSourceEditorial(EditorialElement object, Object parent,
      MeiXmlNode element, EditorialLevel level,
      [Object? filter]) {
    MeiAttributeReader reader = MeiAttributeReader(element.attributes);
    readEditorialBase(reader, element, object);
    final dynamic dyn = object;
    dyn.readSource(reader);

    parent.addChild(object);
    readUnsupportedAttr(reader, element, object);
    return readEditorialChildren(object, element, level, filter);
  }

  /// Shared body for editorial elements without extra attributes (`<ref>`).
  bool _readPlainEditorial(EditorialElement object, Object parent,
      MeiXmlNode element, EditorialLevel level,
      [Object? filter]) {
    MeiAttributeReader reader = MeiAttributeReader(element.attributes);
    readEditorialBase(reader, element, object);

    parent.addChild(object);
    readUnsupportedAttr(reader, element, object);
    return readEditorialChildren(object, element, level, filter);
  }

  /// Read an `<annot>` (mirrors `ReadAnnot`).
  bool readAnnot(Object parent, MeiXmlNode annot) {
    final Annot vrvAnnot = Annot();
    MeiAttributeReader reader = MeiAttributeReader(annot.attributes);
    readEditorialBase(reader, annot, vrvAnnot);

    final dynamic dyn = vrvAnnot;
    dyn.readPlist(reader);
    dyn.readSource(reader);

    parent.addChild(vrvAnnot);
    vrvAnnot.content = annot.copy();

    bool hasNonTextContent = false;
    // copy all the nodes inside into the document
    for (final MeiXmlNode child in annot.children) {
      final String nodeName = child.isElement ? child.name : '';
      if (!hasNonTextContent && nodeName.isNotEmpty) hasNonTextContent = true;
    }
    readUnsupportedAttr(reader, annot, vrvAnnot);
    // Unless annot has only text we do not load children because they are
    // preserved in Annot::m_content.
    if (hasNonTextContent) {
      return true;
    } else {
      return readTextChildren(vrvAnnot, annot, vrvAnnot);
    }
  }

  /// Read an `<app>` (mirrors `ReadApp`).
  bool readApp(Object parent, MeiXmlNode app, EditorialLevel level,
      [Object? filter]) {
    if (!hasScoreDef) {
      assert(level == EditorialLevel.score);
    }
    final App vrvApp = App();
    vrvApp.editorialLevel = level;
    MeiAttributeReader reader = MeiAttributeReader(app.attributes);
    readEditorialBase(reader, app, vrvApp);

    parent.addChild(vrvApp);
    readUnsupportedAttr(reader, app, vrvApp);
    return readAppChildren(vrvApp, app, level, filter);
  }

  /// Read the children of an `<app>` (mirrors `ReadAppChildren`).
  bool readAppChildren(Object parent, MeiXmlNode parentNode,
      EditorialLevel level,
      [Object? filter]) {
    // Check if one child node matches the m_appXPathQuery
    MeiXmlNode? selectedLemOrRdg;
    final List<String> xPathQueries =
        doc.getOptions().appXPathQuery.value;
    for (final String query in xPathQueries) {
      final MeiXmlNode? selection = selectNode(parentNode, query);
      if (selection != null) {
        selectedLemOrRdg = selection;
        break;
      }
    }

    bool success = true;
    bool hasXPathSelected = false;
    MeiXmlNode? current = parentNode.firstChild();
    while (current != null) {
      if (!success) break;
      if (current.isElement && current.name == 'lem') {
        success = readLem(parent, current, level, filter);
      } else if (current.isElement && current.name == 'rdg') {
        success = readRdg(parent, current, level, filter);
      }
      // xml comment
      else if (!current.isElement) {
        success = readXMLComment(parent, current);
      } else {
        logWarning("Unsupported '<${current.name}>' within <app>");
      }
      // Now we check if the xpath selection (if any) matches the current
      // node. If yes, make it visible.
      if (identical(selectedLemOrRdg, current)) {
        final Object? last = parent.getLast();
        if (last is EditorialElement) {
          last.setVisibility(VisibilityType.visible);
          hasXPathSelected = true;
        }
      }
      current = current.nextSibling();
    }

    // If no child was made visible through the xpath selection, make the
    // first one visible.
    if (!hasXPathSelected) {
      final Object? first = parent.getFirst();
      if (first is EditorialElement) {
        first.setVisibility(VisibilityType.visible);
      } else if (!deserializing && parent.classId != ClassId.system) {
        logWarning('Could not make one <rdg> or <lem> visible');
      }
    }
    return success;
  }

  /// Read a `<lem>` (hidden by default; mirrors `ReadLem`).
  bool readLem(Object parent, MeiXmlNode lem, EditorialLevel level,
      [Object? filter]) {
    final Lem vrvLem = Lem();
    // By default make them all hidden; ReadAppChildren makes one visible.
    vrvLem.setVisibility(VisibilityType.hidden);
    MeiAttributeReader reader = MeiAttributeReader(lem.attributes);
    readEditorialBase(reader, lem, vrvLem);

    final dynamic dyn = vrvLem;
    dyn.readSource(reader);

    parent.addChild(vrvLem);
    readUnsupportedAttr(reader, lem, vrvLem);
    return readEditorialChildren(vrvLem, lem, level, filter);
  }

  /// Read an `<rdg>` (hidden by default; mirrors `ReadRdg`).
  bool readRdg(Object parent, MeiXmlNode rdg, EditorialLevel level,
      [Object? filter]) {
    final Rdg vrvRdg = Rdg();
    vrvRdg.setVisibility(VisibilityType.hidden);
    MeiAttributeReader reader = MeiAttributeReader(rdg.attributes);
    readEditorialBase(reader, rdg, vrvRdg);

    final dynamic dyn = vrvRdg;
    dyn.readSource(reader);

    parent.addChild(vrvRdg);
    readUnsupportedAttr(reader, rdg, vrvRdg);
    return readEditorialChildren(vrvRdg, rdg, level, filter);
  }

  /// Read a `<choice>` (mirrors `ReadChoice`).
  bool readChoice(Object parent, MeiXmlNode choice, EditorialLevel level,
      [Object? filter]) {
    if (!hasScoreDef) {
      assert(level == EditorialLevel.score);
    }
    final Choice vrvChoice = Choice();
    vrvChoice.editorialLevel = level;
    MeiAttributeReader reader = MeiAttributeReader(choice.attributes);
    readEditorialBase(reader, choice, vrvChoice);

    parent.addChild(vrvChoice);
    readUnsupportedAttr(reader, choice, vrvChoice);
    return readChoiceChildren(vrvChoice, choice, level, filter);
  }

  /// Read the children of a `<choice>` (mirrors `ReadChoiceChildren`).
  bool readChoiceChildren(Object parent, MeiXmlNode parentNode,
      EditorialLevel level,
      [Object? filter]) {
    // Check if one child node matches a value in m_choiceXPathQuery
    MeiXmlNode? selectedChild;
    final List<String> xPathQueries =
        doc.getOptions().choiceXPathQuery.value;
    for (final String query in xPathQueries) {
      final MeiXmlNode? selection = selectNode(parentNode, query);
      if (selection != null) {
        selectedChild = selection;
        break;
      }
    }

    bool success = true;
    bool hasXPathSelected = false;
    MeiXmlNode? current = parentNode.firstChild();
    while (current != null) {
      if (!success) break;
      switch (current.name) {
        case 'abbr':
          success = readAbbr(parent, current, level, filter);
          break;
        case 'choice':
          success = readChoice(parent, current, level, filter);
          break;
        case 'corr':
          success = readCorr(parent, current, level, filter);
          break;
        case 'expan':
          success = readExpan(parent, current, level, filter);
          break;
        case 'orig':
          success = readOrig(parent, current, level, filter);
          break;
        case 'ref':
          success = readRef(parent, current, level, filter);
          break;
        case 'reg':
          success = readReg(parent, current, level, filter);
          break;
        case 'sic':
          success = readSic(parent, current, level, filter);
          break;
        case 'unclear':
          success = readUnclear(parent, current, level, filter);
          break;
        case '':
          break;
        default:
          if (!current.isElement) {
            success = readXMLComment(parent, current);
          } else {
            logWarning("Unsupported '<${current.name}>' within <choice>");
          }
      }
      // Now check whether the xpath selection matches the current node.
      final Object? last = parent.getLast();
      if (success && last is EditorialElement) {
        if (identical(selectedChild, current)) {
          last.setVisibility(VisibilityType.visible);
          hasXPathSelected = true;
        } else {
          last.setVisibility(VisibilityType.hidden);
        }
      }
      current = current.nextSibling();
    }

    if (!hasXPathSelected) {
      final Object? first = parent.getFirst();
      if (first is EditorialElement) {
        first.setVisibility(VisibilityType.visible);
      } else if (!deserializing && parent.classId != ClassId.system) {
        logWarning('Could not make one child of <choice> visible');
      }
    }
    return success;
  }

  /// Read a `<subst>` (mirrors `ReadSubst`).
  bool readSubst(Object parent, MeiXmlNode subst, EditorialLevel level,
      [Object? filter]) {
    if (!hasScoreDef) {
      assert(level == EditorialLevel.score);
    }
    final Subst vrvSubst = Subst();
    vrvSubst.editorialLevel = level;
    MeiAttributeReader reader = MeiAttributeReader(subst.attributes);
    readEditorialBase(reader, subst, vrvSubst);

    parent.addChild(vrvSubst);
    readUnsupportedAttr(reader, subst, vrvSubst);
    return readSubstChildren(vrvSubst, subst, level, filter);
  }

  /// Read the children of a `<subst>` (mirrors `ReadSubstChildren`).
  bool readSubstChildren(Object parent, MeiXmlNode parentNode,
      EditorialLevel level,
      [Object? filter]) {
    MeiXmlNode? selectedChild;
    final List<String> xPathQueries =
        doc.getOptions().substXPathQuery.value;
    for (final String query in xPathQueries) {
      final MeiXmlNode? selection = selectNode(parentNode, query);
      if (selection != null) {
        selectedChild = selection;
        break;
      }
    }

    bool success = true;
    bool hasXPathSelected = false;
    MeiXmlNode? current = parentNode.firstChild();
    while (current != null) {
      if (!success) break;
      if (current.isElement && current.name == 'add') {
        success = readAdd(parent, current, level, filter);
      } else if (current.isElement && current.name == 'del') {
        success = readDel(parent, current, level, filter);
      } else if (current.isElement && current.name == 'subst') {
        success = readSubst(parent, current, level, filter);
      }
      // xml comment
      else if (!current.isElement) {
        success = readXMLComment(parent, current);
      } else {
        logWarning("Unsupported '<${current.name}>' within <subst>");
      }
      final Object? last = parent.getLast();
      if (success && last is EditorialElement) {
        if (identical(selectedChild, current)) {
          last.setVisibility(VisibilityType.visible);
          hasXPathSelected = true;
        } else {
          last.setVisibility(VisibilityType.hidden);
        }
      }
      current = current.nextSibling();
    }

    if (!hasXPathSelected) {
      final Object? first = parent.getFirst();
      if (first is EditorialElement) {
        first.setVisibility(VisibilityType.visible);
      } else {
        logWarning('Could not make one child of <subst> visible');
      }
    }
    return success;
  }

  /// Route the children reading by editorial level (mirrors
  /// `ReadEditorialChildren`).
  bool readEditorialChildren(Object parent, MeiXmlNode parentNode,
      EditorialLevel level,
      [Object? filter]) {
    switch (level) {
      case EditorialLevel.score:
        return readScoreScoreDef(parent, parentNode);
      case EditorialLevel.topLevel:
        if (readingScoreBased) {
          return readSectionChildren(parent, parentNode);
        } else {
          return readSystemChildren(parent, parentNode);
        }
      case EditorialLevel.scoreDef:
        return readScoreDefChildren(parent, parentNode);
      case EditorialLevel.staffGrp:
        return readStaffGrpChildren(parent, parentNode);
      case EditorialLevel.measure:
        return readMeasureChildren(parent, parentNode);
      case EditorialLevel.staff:
        return readStaffChildren(parent, parentNode);
      case EditorialLevel.layer:
        return readLayerChildren(parent, parentNode, filter);
      case EditorialLevel.text:
        return readTextChildren(parent, parentNode, filter);
      case EditorialLevel.fb:
        return readFbChildren(parent, parentNode);
      case EditorialLevel.running:
        return readRunningChildren(parent, parentNode, filter);
      default:
        return false;
    }
  }

  // -------------------------------------------------------------------------
  // Facsimile
  // -------------------------------------------------------------------------

  /// Read a `<facsimile>` (mirrors `ReadFacsimile`).
  bool readFacsimile(MeiXmlNode facsimile) {
    final Facsimile vrvFacsimile = Facsimile();
    MeiAttributeReader reader = MeiAttributeReader(facsimile.attributes);
    // Read xmlId (if present)
    setMeiID(facsimile, vrvFacsimile, reader);
    vrvFacsimile.readTyped(reader);
    // Read children
    for (final MeiXmlNode child in facsimile.childrenElements()) {
      if (child.name == 'surface') {
        readSurface(vrvFacsimile, child);
      } else {
        logWarning("Unsupported element <${child.name}> in <facsimile>");
      }
    }
    doc.setFacsimile(vrvFacsimile);
    return true;
  }

  /// Read a `<surface>` (mirrors `ReadSurface`).
  bool readSurface(Facsimile parent, MeiXmlNode surface) {
    final Surface vrvSurface = Surface();
    MeiAttributeReader reader = MeiAttributeReader(surface.attributes);
    setMeiID(surface, vrvSurface, reader);
    final dynamic dyn = vrvSurface;
    dyn.readCoordinated(reader);
    dyn.readCoordinatedUl(reader);
    dyn.readTyped(reader);

    for (final MeiXmlNode child in surface.childrenElements()) {
      if (child.name == 'graphic') {
        readGraphic(vrvSurface, child);
      } else if (child.name == 'zone') {
        readZone(vrvSurface, child);
      } else {
        logWarning("Unsupported element <${child.name}> in <surface>");
      }
    }
    parent.addChild(vrvSurface);
    return true;
  }

  /// Read a `<zone>` (mirrors `ReadZone`).
  bool readZone(Surface parent, MeiXmlNode zone) {
    final Zone vrvZone = Zone();
    MeiAttributeReader reader = MeiAttributeReader(zone.attributes);
    setMeiID(zone, vrvZone, reader);
    final dynamic dyn = vrvZone;
    dyn.readCoordinated(reader);
    dyn.readCoordinatedUl(reader);
    dyn.readTyped(reader);
    parent.addChild(vrvZone);
    return true;
  }

  /// Read a `<graphic>` (mirrors `ReadGraphic`).
  bool readGraphic(Object parent, MeiXmlNode graphic) {
    final Graphic vrvGraphic = Graphic();
    MeiAttributeReader reader = MeiAttributeReader(graphic.attributes);
    setMeiID(graphic, vrvGraphic, reader);
    final dynamic dyn = vrvGraphic;
    dyn.readPointing(reader);
    dyn.readWidth(reader);
    dyn.readHeight(reader);
    dyn.readTyped(reader);
    parent.addChild(vrvGraphic);
    readUnsupportedAttr(reader, graphic, vrvGraphic);
    return true;
  }

  /// Convert a `<tupletSpan>` into a `<tuplet>` (mirrors
  /// `ReadTupletSpanAsTuplet`).
  bool readTupletSpanAsTuplet(Measure? measure, MeiXmlNode tupletSpan) {
    if (measure == null) {
      logWarning('Cannot read <tupletSpan> within editorial markup');
      return false;
    }

    final Tuplet tuplet = Tuplet();
    setMeiID(tupletSpan, tuplet);

    LayerElement? start;
    LayerElement? end;

    // att.labelled / att.typed / att.duration.ratio / att.tuplet.vis
    final String? label = tupletSpan.attr('label');
    if (label != null) tuplet.label = label;

    final String? type = tupletSpan.attr('type');
    tuplet.type = type ?? 'tupletSpan';

    final String? num = tupletSpan.attr('num');
    if (num != null) tuplet.num = strToInt(num);
    final String? numbase = tupletSpan.attr('numbase');
    if (numbase != null) tuplet.numbase = strToInt(numbase);

    final String? bracketPlace = tupletSpan.attr('bracket.place');
    if (bracketPlace != null) {
      tuplet.bracketPlace = strToStaffrelBasic(bracketPlace);
    }
    final String? bracketVisible = tupletSpan.attr('bracket.visible');
    if (bracketVisible != null) {
      tuplet.bracketVisible = strToBoolean(bracketVisible);
    }
    final String? numFormat = tupletSpan.attr('num.format');
    if (numFormat != null) {
      tuplet.numFormat = strToTupletvisNumformat(numFormat);
    }
    final String? color = tupletSpan.attr('color');
    if (color != null) tuplet.color = color;
    final String? numPlace = tupletSpan.attr('num.place');
    if (numPlace != null) tuplet.numPlace = strToStaffrelBasic(numPlace);
    final String? numVisible = tupletSpan.attr('num.visible');
    if (numVisible != null) tuplet.numVisible = strToBoolean(numVisible);

    // position (pitch)
    final String? startid = tupletSpan.attr('startid');
    if (startid != null) {
      final String refId = extractIDFragment(startid);
      start =
          measure.findDescendantByID(refId) as LayerElement?;
      if (start == null) {
        logWarning("Element with @startid '$refId' not found when trying to "
            'read the <tupletSpan>');
      }
    }
    final String? endid = tupletSpan.attr('endid');
    if (endid != null) {
      final String refId = extractIDFragment(endid);
      end = measure.findDescendantByID(refId) as LayerElement?;
      if (end == null) {
        logWarning("Element with @endid '$refId' not found when trying to "
            'read the <tupletSpan>');
      }
    }
    if (start == null || end == null) {
      return false;
    }

    final LayerElement? startChild =
        start.getLastAncestorNot(ClassId.layer) as LayerElement?;
    final LayerElement? endChild =
        end.getLastAncestorNot(ClassId.layer) as LayerElement?;

    if (startChild == null ||
        endChild == null ||
        !identical(startChild.parent, endChild.parent)) {
      logWarning("Start and end elements for <tupletSpan> '${tuplet.id}' not "
          'in the same layer');
      return false;
    }

    final Layer parentLayer = startChild.parent as Layer;

    final int startIdx = startChild.idx ?? -1;
    final int endIdx = endChild.idx ?? -1;
    for (int i = endIdx; i >= startIdx; --i) {
      final Object? element = parentLayer.detachChild(i);
      if (element != null) tuplet.insertChild(element, 0);
    }
    parentLayer.insertChild(tuplet, startIdx);

    return true;
  }

  // -------------------------------------------------------------------------
  // Upgrades of older MEI versions
  // -------------------------------------------------------------------------

  /// Mirrors `UpgradeKeySigTo_5_0`.
  void upgradeKeySigTo500(MeiXmlNode keySig) {
    if (keySig.hasAttr('sig.showchange')) {
      final bool? showchange =
          strToBoolean(keySig.attr('sig.showchange')!);
      keySig.renameAttribute('sig.showchange', 'cancelaccid');
      if (showchange == true) {
        keySig.setAttribute(
            'cancelaccid', cancelaccidToStr(Cancelaccid.before));
      } else {
        keySig.setAttribute('cancelaccid', cancelaccidToStr(Cancelaccid.none));
      }
    }
  }

  /// Mirrors `UpgradePgHeadFootTo_5_0`.
  void upgradePgHeadFootTo500(MeiXmlNode element) {
    if (element.name == 'pgFoot' && !element.hasAttr('func')) {
      element.setAttribute('func', 'first');
    } else if (element.name == 'pgFoot2') {
      element.name = 'pgFoot';
      element.setAttribute('func', 'all');
    } else if (element.name == 'pgHead' && !element.hasAttr('func')) {
      element.setAttribute('func', 'first');
    } else if (element.name == 'pgHead2') {
      element.name = 'pgHead';
      element.setAttribute('func', 'all');
    }
  }

  /// Mirrors `UpgradeMeterSigTo_5_0`.
  void upgradeMeterSigTo500(MeiXmlNode meterSig, MeterSig vrvMeterSig) {
    if (meterSig.hasAttr('form')) {
      final String value = meterSig.attr('form')!;
      if (value == 'invis') {
        meterSig.removeAttribute('form');
        vrvMeterSig.visible = false;
      }
    }
  }

  /// Mirrors `UpgradeScoreDefElementTo_5_0` (attribute renames only).
  void upgradeScoreDefElementTo500(MeiXmlNode scoreDefElement) {
    if (scoreDefElement.hasAttr('key.sig')) {
      scoreDefElement.renameAttribute('key.sig', 'keysig');
    }
    if (scoreDefElement.hasAttr('keysig.showchange')) {
      final bool? showchange =
          strToBoolean(scoreDefElement.attr('keysig.showchange')!);
      scoreDefElement.renameAttribute('keysig.showchange', 'keysig.cancelaccid');
      if (showchange == true) {
        scoreDefElement.setAttribute(
            'keysig.cancelaccid', cancelaccidToStr(Cancelaccid.before));
      } else {
        scoreDefElement.setAttribute(
            'keysig.cancelaccid', cancelaccidToStr(Cancelaccid.none));
      }
    }
    if (scoreDefElement.hasAttr('meter.form')) {
      final String value = scoreDefElement.attr('meter.form')!;
      if (value == 'invis') {
        scoreDefElement.removeAttribute('meter.form');
        scoreDefElement.setAttribute('meter.visible', 'false');
      }
    }
    if (scoreDefElement.hasAttr('keysig.show')) {
      scoreDefElement.renameAttribute('keysig.show', 'keysig.visible');
    }
  }

  /// Mirrors `UpgradeRendTo_5_0`.
  void upgradeRendTo500(MeiXmlNode element) {
    if (element.hasAttr('fontfam')) {
      final String value = element.attr('fontfam')!;
      if (value == 'smufl') {
        element.renameAttribute('fontfam', 'glyph.auth');
      }
    }
  }

  /// Mirrors `UpgradeBeatRptTo_4_0_0`.
  void upgradeBeatRptTo400(MeiXmlNode beatRpt, BeatRpt vrvBeatRpt) {
    String value = '';
    if (beatRpt.hasAttr('rend')) {
      value = beatRpt.attr('rend')!;
      beatRpt.removeAttribute('rend');
    } else if (beatRpt.hasAttr('form')) {
      value = beatRpt.attr('form')!;
      beatRpt.removeAttribute('form');
    }
    if (value.isEmpty) return;
    switch (value) {
      case '4':
      case '8':
        vrvBeatRpt.slash = BeatrptRend.n1;
        break;
      case '16':
        vrvBeatRpt.slash = BeatrptRend.n2;
        break;
      case '32':
        vrvBeatRpt.slash = BeatrptRend.n3;
        break;
      case '64':
        vrvBeatRpt.slash = BeatrptRend.n4;
        break;
      case '128':
        vrvBeatRpt.slash = BeatrptRend.n5;
        break;
      case 'mixed':
        vrvBeatRpt.slash = BeatrptRend.mixed;
        break;
    }
  }

  /// Mirrors `UpgradeDurGesTo_4_0_0`.
  void upgradeDurGesTo400(MeiAttributeReader reader, Object interface) {
    final dynamic nodeReader = interface;
    final String? durGes = reader.get('dur.ges');
    if (durGes != null && durGes.isNotEmpty) {
      if (durGes.endsWith('p')) {
        nodeReader.durPpq = int.tryParse(durGes.substring(0, durGes.length - 1)) ?? 0;
      } else if (durGes.endsWith('r')) {
        nodeReader.durRecip = durGes.substring(0, durGes.length - 1);
      } else if (durGes.endsWith('s')) {
        try {
          nodeReader.durReal = double.parse(durGes.substring(0, durGes.length - 1));
        } on FormatException catch (_) {
          logError('Upgrading to 4.0.0: invalid float value $durGes');
        }
      }
      reader.remove('dur.ges');
    }
  }

  /// Mirrors `UpgradeFTremTo_4_0_0`.
  void upgradeFTremTo400(MeiXmlNode fTrem, FTrem vrvFTrem) {
    if (fTrem.hasAttr('slash')) {
      vrvFTrem.beams = strToInt(fTrem.attr('slash')!);
      fTrem.removeAttribute('slash');
    }
  }

  /// Mirrors `UpgradeMensurTo_5_0`.
  void upgradeMensurTo500(Mensur vrvMensur) {
    if ((vrvMensur.tempus != null) && (vrvMensur.sign == null)) {
      vrvMensur.sign = (vrvMensur.tempus == Tempus.n3)
          ? Mensurationsign.o
          : Mensurationsign.c;
    }
    if ((vrvMensur.prolatio != null) && (vrvMensur.dot == null)) {
      vrvMensur.dot = (vrvMensur.prolatio == Prolatio.n3);
    }
  }

  /// Mirrors `UpgradeMordentTo_4_0_0`.
  void upgradeMordentTo400(MeiXmlNode mordent, Mordent vrvMordent) {
    if (mordent.hasAttr('form')) {
      final String form = mordent.attr('form')!;
      if (form == 'norm') {
        vrvMordent.form = MordentlogForm.lower;
      } else if (form == 'inv') {
        vrvMordent.form = MordentlogForm.upper;
      } else {
        logWarning("Unsupported value '$form' for att.mordent.log@form "
            '(MEI 3.0)');
      }
      mordent.removeAttribute('form');
    }
  }

  /// Mirrors `UpgradeScoreDefElementTo_4_0_0`.
  void upgradeScoreDefElementTo400(MeiAttributeReader reader,
      MeiXmlNode scoreDefElement, ScoreDefElement vrvScoreDefElement) {
    final KeySig? keySig =
        vrvScoreDefElement.findDescendantByType(ClassId.keysig) as KeySig?;
    final MeterSig? meterSig =
        vrvScoreDefElement.findDescendantByType(ClassId.meterSig) as MeterSig?;

    if (scoreDefElement.hasAttr('key.sig.show')) {
      if (keySig != null) {
        keySig.visible = strToBoolean(scoreDefElement.attr('key.sig.show')!);
        scoreDefElement.removeAttribute('key.sig.show');
        reader.remove('key.sig.show');
      } else {
        logWarning("No keySig found when trying to upgrade '@key.sig.show'");
      }
    }
    if (scoreDefElement.hasAttr('key.sig.showchange')) {
      if (keySig != null) {
        if (strToBoolean(scoreDefElement.attr('key.sig.showchange')!) == true) {
          keySig.cancelaccid = Cancelaccid.before;
        } else {
          keySig.cancelaccid = Cancelaccid.none;
        }
        scoreDefElement.removeAttribute('key.sig.showchange');
        reader.remove('key.sig.showchange');
      } else {
        logWarning(
            "No keySig found when trying to upgrade '@key.sig.showchange'");
      }
    }
    if (scoreDefElement.hasAttr('meter.rend')) {
      if (meterSig != null) {
        meterSig.form = strToMeterform(scoreDefElement.attr('meter.rend')!);
        scoreDefElement.removeAttribute('meter.rend');
        reader.remove('meter.rend');
      }
    }
  }

  /// Mirrors `UpgradeStaffDefTo_4_0_0`.
  void upgradeStaffDefTo400(MeiXmlNode staffDef, StaffDef vrvStaffDef) {
    if (staffDef.hasAttr('label')) {
      final Text text = Text();
      text.text = staffDef.attr('label')!;
      final Label label = Label();
      label.addChild(text);
      vrvStaffDef.addChild(label);
      staffDef.removeAttribute('label');
    }
    if (staffDef.hasAttr('label.abbr')) {
      final Text text = Text();
      text.text = staffDef.attr('label.abbr')!;
      final LabelAbbr labelAbbr = LabelAbbr();
      labelAbbr.addChild(text);
      vrvStaffDef.addChild(labelAbbr);
      staffDef.removeAttribute('label.abbr');
    }
  }

  /// Mirrors `UpgradeStaffGrpTo_4_0_0`.
  void upgradeStaffGrpTo400(MeiXmlNode staffGrp, StaffGrp vrvStaffGrp) {
    if (staffGrp.hasAttr('barthru')) {
      vrvStaffGrp.barThru = strToBoolean(staffGrp.attr('barthru')!);
      staffGrp.removeAttribute('barthru');
    }
    if (staffGrp.hasAttr('label')) {
      final Text text = Text();
      text.text = staffGrp.attr('label')!;
      final Label label = Label();
      label.addChild(text);
      vrvStaffGrp.addChild(label);
      staffGrp.removeAttribute('label');
    }
    if (staffGrp.hasAttr('label.abbr')) {
      final Text text = Text();
      text.text = staffGrp.attr('label.abbr')!;
      final LabelAbbr labelAbbr = LabelAbbr();
      labelAbbr.addChild(text);
      vrvStaffGrp.addChild(labelAbbr);
      staffGrp.removeAttribute('label.abbr');
    }
  }

  /// Mirrors `UpgradeTurnTo_4_0_0`.
  void upgradeTurnTo400(MeiXmlNode turn, Turn vrvTurn) {
    if (turn.hasAttr('form')) {
      final String form = turn.attr('form')!;
      if (form == 'inv') {
        vrvTurn.form = TurnlogForm.lower;
      } else if (form == 'norm') {
        vrvTurn.form = TurnlogForm.lower; // sic - mirrors the C++
      } else {
        logWarning("Unsupported value '$form' for att.turn.log@form (MEI 3.0)");
      }
      turn.removeAttribute('form');
    }
  }

  // PART8_MARKER
}

// ---------------------------------------------------------------------------
// Minimal XPath support
// ---------------------------------------------------------------------------

/// Evaluate an XPath [query] against [context], returning the first match.
///
/// This is a pragmatic subset of XPath covering the query forms used by the
/// Verovio options (`mdiv-x-path`, `app-x-path-query`, …) and the zip
/// container: absolute paths (`/container/rootfiles/rootfile`), descendant
/// searches (`.//mdiv`, `//mdiv`) with optional predicates
/// (`[@n='2']`, `[@type='x'][@n='y']`, `[count(score)>0]`).
MeiXmlNode? selectNode(MeiXmlNode context, String query) {
  final List<String> steps = _splitQuery(query);
  if (steps.isEmpty) return null;

  // Absolute path from the document root.
  MeiXmlNode? current = context;
  if (query.startsWith('/')) {
    MeiXmlNode? root = context;
    while (root?.parent != null) {
      root = root!.parent;
    }
    current = root;
    final List<String> abs = steps.where((s) => s.isNotEmpty).toList();
    for (final String step in abs) {
      current = _step(current!, step);
      if (current == null) return null;
    }
    return current;
  }

  for (final String step in steps) {
    if (step == '.') continue;
    if (step.startsWith('.//')) {
      final MeiXmlNode? found = selectFirstDescendantWhere(
          current!, step.substring(3).split('[').first,
          (node) => _matchesPredicates(node, step));
      if (found == null) {
        return null;
      }
      current = found;
    } else {
      current = _step(current!, step);
      if (current == null) return null;
    }
  }
  return current;
}

/// Split an XPath query into steps (naive split on '/').
List<String> _splitQuery(String query) =>
    query.split('/').where((s) => s.isNotEmpty || query.startsWith('/')).toList();

/// Apply one path step to [node]; supports name[pred1][pred2].
MeiXmlNode? _step(MeiXmlNode node, String step) {
  final int bracket = step.indexOf('[');
  final String name = bracket == -1 ? step : step.substring(0, bracket);
  final bool hasPredicates = bracket != -1;
  for (final MeiXmlNode child in node.childrenElements()) {
    if (name != '*' && child.name != name && name != child.name) {
      continue;
    }
    if (hasPredicates && !_matchesPredicates(child, step)) continue;
    return child;
  }
  return null;
}

/// Check the `[...]` predicates of a step against [node].
bool _matchesPredicates(MeiXmlNode node, String step) {
  final RegExp predRe = RegExp(r'\[([^\]]+)\]');
  for (final RegExpMatch m in predRe.allMatches(step)) {
    final String pred = m.group(1)!;
    // count(child)>0
    final RegExp countRe = RegExp(r'^count\((\w+)\)\s*>\s*0$');
    final RegExpMatch? countMatch = countRe.firstMatch(pred);
    if (countMatch != null) {
      final String childName = countMatch.group(1)!;
      if (!node.childElements().any((c) => c.name == childName)) return false;
      continue;
    }
    // @attr='value'
    final RegExp attrRe = RegExp(r"^@([\w.:-]+)\s*=\s*'([^']*)'$");
    final RegExpMatch? attrMatch = attrRe.firstMatch(pred);
    if (attrMatch != null) {
      final String attr = attrMatch.group(1)!;
      final String value = attrMatch.group(2)!;
      if (node.attr(attr) != value) return false;
      continue;
    }
    // Unsupported predicate - be conservative and reject.
    logWarning("XPath predicate '[$pred]' is not supported by this build");
    return false;
  }
  return true;
}

/// Find the first descendant element named [name] matching [predicate]
/// (depth-first).
MeiXmlNode? selectFirstDescendantWhere(
    MeiXmlNode node, String name, bool Function(MeiXmlNode) predicate) {
  for (final MeiXmlNode child in node.childrenElements()) {
    if (child.name == name && predicate(child)) return child;
    final MeiXmlNode? found =
        selectFirstDescendantWhere(child, name, predicate);
    if (found != null) return found;
  }
  return null;
}
