/// Port of `include/vrv/vrvdef.h` — global definitions of Verovio.
library;

// ---------------------------------------------------------------------------
// Version
// ---------------------------------------------------------------------------

const int kVersionMajor = 6;
const int kVersionMinor = 2;
const int kVersionRevision = 0;
const bool kVersionDev = false;

/// Version string as used by Verovio ("Engraved by Verovio x.y.z").
String get verovioVersion =>
    '$kVersionMajor.$kVersionMinor.$kVersionRevision${kVersionDev ? '-dev' : ''}';

// ---------------------------------------------------------------------------
// Default MIDI values
// ---------------------------------------------------------------------------

const int midiVelocity = 90;
const int midiTempo = 120;

/// Unaccented gracenote duration in milliseconds.
const int unaccGracenoteDur = 27;

// ---------------------------------------------------------------------------
// Global defines
// ---------------------------------------------------------------------------

const int definitionFactor = 10;
const double defaultUnit = 9.0;

/// Whether [x] lies between [a] and [b] (in either order).
bool isIn(num x, num a, num b) {
  final num lo = a < b ? a : b;
  final num hi = a < b ? b : a;
  return x >= lo && x <= hi;
}

// ---------------------------------------------------------------------------
// Functor codes
// ---------------------------------------------------------------------------

/// Codes returned by functors.
enum FunctorCode {
  continue_,
  siblings,
  stop,
}

// ---------------------------------------------------------------------------
// Maximum number of levels between parent and children for search
// ---------------------------------------------------------------------------

const int maxAccidDepth = -1;
const int maxBeamDepth = -1;
const int maxChordDepth = -1;
const int maxFTremDepth = -1;
const int maxLigatureDepth = -1;
const int maxTabGrpDepth = -1;
const int maxTupletDepth = -1;
const int maxStaffGrpDepth = -1;
const int maxNoteDepth = -1;

// ---------------------------------------------------------------------------
// Ossia staff / layer @n offset
// ---------------------------------------------------------------------------

const int ossiaNOffset = 1000000;

// ---------------------------------------------------------------------------
// Unicode music codepoints
// ---------------------------------------------------------------------------

const int unicodeFlat = 0x266D; // ♭
const int unicodeNatural = 0x266E; // ♮
const int unicodeSharp = 0x266F; // ♯
const int unicodeUndertie = 0x203F; // ‿
const int unicodeDalSegno = 0x1D109; // 𝄉
const int unicodeDaCapo = 0x1D10A; // 𝄊
const int unicodeSegno = 0x1D10B; // 𝄋
const int unicodeCoda = 0x1D10C; // 𝄌
const int unicodeDoubleFlat = 0x1D12B; // 𝄫
const int unicodeDoubleSharp = 0x1D12A; // 𝄪

/// SMuFL symbols used in figured bass included in VerovioText.
const String vrvTextHarm = '\u266D\u266E\u266F'
    '\uE260\uE261\uE262\uE263\uE264'
    '\uEA50\uEA51\uEA52\uEA53\uEA54\uEA55\uEA56\uEA57\uEA58\uEA59\uEA5A\uEA5B'
    '\uEA5C\uEA5D\uEA5E\uEA5F\uEA60\uEA61\uEA62\uEA63\uEA64\uEA65\uEA66\uEA67'
    '\uECC0';

// ---------------------------------------------------------------------------
// data.LINEWIDTHTERM factors
// ---------------------------------------------------------------------------

const double lineWidthTermFactorNarrow = 1.0;
const double lineWidthTermFactorMedium = 2.0;
const double lineWidthTermFactorWide = 4.0;

// ---------------------------------------------------------------------------
// Types for editorial element
// ---------------------------------------------------------------------------

enum EditorialLevel {
  undefined,
  score,
  topLevel,
  scoreDef,
  staffGrp,
  measure,
  staff,
  layer,
  note,
  text,
  fb,
  running,
}

// ---------------------------------------------------------------------------
// Visibility for editorial and mdiv elements
// ---------------------------------------------------------------------------

enum VisibilityType {
  hidden,
  visible,
}

// ---------------------------------------------------------------------------
// The used SMuFL glyph anchors
// ---------------------------------------------------------------------------

enum SMuFLGlyphAnchor {
  stemDownNW,
  stemUpSE,
  cutOutNE,
  cutOutNW,
  cutOutSE,
  cutOutSW,
}

// ---------------------------------------------------------------------------
// Spanning types for control events
// ---------------------------------------------------------------------------

const int spanningStartEnd = 0;
const int spanningStart = 1;
const int spanningEnd = 2;
const int spanningMiddle = 3;

// ---------------------------------------------------------------------------
// Types for layer element
// ---------------------------------------------------------------------------

enum ElementScoreDefRole {
  none,
  system,
  intermediate,
  cautionary,
  ossia,
}

// ---------------------------------------------------------------------------
// ScoreDef drawing labels
// ---------------------------------------------------------------------------

enum ScoreDefDrawingLabels {
  full,
  abbr,
  none,
}

// ---------------------------------------------------------------------------
// Artic types
// ---------------------------------------------------------------------------

enum ArticType {
  inside,
  outside,
}

// ---------------------------------------------------------------------------
// Visibility optimization
// ---------------------------------------------------------------------------

enum VisibilityOptimization {
  none,
  hidden,
  show,
}

// ---------------------------------------------------------------------------
// Layout positions (3 x 3 grid)
// ---------------------------------------------------------------------------

const int positionLeft = 0;
const int positionCenter = 1;
const int positionRight = 2;

const int positionTop = 0;
const int positionMiddle = 3;
const int positionBottom = 6;

// ---------------------------------------------------------------------------
// Ligature shape bitfields
// ---------------------------------------------------------------------------

const int ligatureDefault = 0;
const int ligatureStemLeftUp = 1;
const int ligatureStemLeftDown = 2;
const int ligatureStemRightUp = 4;
const int ligatureStemRightDown = 8;
const int ligatureOblique = 16;
const int ligatureStacked = 32;

// ---------------------------------------------------------------------------
// Analytical markup bitfields
// ---------------------------------------------------------------------------

const int markupDefault = 0;
const int markupAnalyticalTie = 1;
const int markupAnalyticalFermata = 2;
const int markupGraceAttribute = 4;
const int markupArticMultival = 8;
const int markupScoredefDefinitions = 16;

// ---------------------------------------------------------------------------
// Layout information
// ---------------------------------------------------------------------------

enum LayoutInformation {
  none,
  encoded,
  done,
}

// ---------------------------------------------------------------------------
// Bounding box access
// ---------------------------------------------------------------------------

enum Accessor {
  self,
  content,
}

// ---------------------------------------------------------------------------
// Bounding box update modes of the BBoxDeviceContext
// (`#define BBOX_BOTH 0` etc., bboxdevicecontext.h:17-19)
// ---------------------------------------------------------------------------

const int BBOX_BOTH = 0;
const int BBOX_HORIZONTAL_ONLY = 1;
const int BBOX_VERTICAL_ONLY = 2;

// ---------------------------------------------------------------------------
// Some keys
// ---------------------------------------------------------------------------

const int keyLeft = 37;
const int keyUp = 38;
const int keyRight = 39;
const int keyDown = 40;

// ---------------------------------------------------------------------------
// Stem sameas drawing role
// ---------------------------------------------------------------------------

enum StemSameasDrawingRole {
  none,
  unset,
  primary,
  secondary,
}

// ---------------------------------------------------------------------------
// Slur curve direction (mirrors `vrv::SlurCurveDirection` from slur.h)
// ---------------------------------------------------------------------------

enum SlurCurveDirection {
  /// `SlurCurveDirection::None`
  none,

  /// `SlurCurveDirection::Above`
  above,

  /// `SlurCurveDirection::Below`
  below,

  /// `SlurCurveDirection::AboveBelow`
  aboveBelow,

  /// `SlurCurveDirection::BelowAbove`
  belowAbove,
}

// ---------------------------------------------------------------------------
// SMuFL text font (selected font or fallback)
// ---------------------------------------------------------------------------

enum SmuflTextFont {
  none,
  fontSelected,
  fontFallback,
}

// ---------------------------------------------------------------------------
// Graphic ID type
// ---------------------------------------------------------------------------

enum GraphicID {
  primary,
  spanning,
  symbolRef,
}

// ---------------------------------------------------------------------------
// Measure type
// ---------------------------------------------------------------------------

enum MeasureType {
  measured,
  unmeasured,
  neumeLine,
}

// ---------------------------------------------------------------------------
// Focus status type
// ---------------------------------------------------------------------------

enum FocusStatusType {
  unset,
  set,
  used,
}

// ---------------------------------------------------------------------------
// Mensural cast-off type
// ---------------------------------------------------------------------------

enum MensuralCastOffType {
  init,
  unset,
  reset,
}

// ---------------------------------------------------------------------------
// The score time unit (quarter note)
// ---------------------------------------------------------------------------

const int scoreTimeUnit = 4;

/// The maximal duration resolution used by fraction conversions
/// (mirrors `DUR_MAX` from attdef.h).
const int durMax = 2048;

// ---------------------------------------------------------------------------
// Alignment types
// ---------------------------------------------------------------------------

/// Alignment types for aligning types together.
///
/// For example, we align notes and rests (default) together, clefs
/// separately, etc. (mirrors `vrv::AlignmentType` from horizontalaligner.h).
enum AlignmentType {
  /// `ALIGNMENT_SCOREDEF_OSSIA_CLEF`
  scoreDefOssiaClef(-2),

  /// `ALIGNMENT_SCOREDEF_OSSIA_KEYSIG`
  scoreDefOssiaKeySig(-1),

  /// `ALIGNMENT_MEASURE_START`
  measureStart(0),
  // Non-justifiable
  /// `ALIGNMENT_SCOREDEF_CLEF`
  scoreDefClef(1),

  /// `ALIGNMENT_SCOREDEF_KEYSIG`
  scoreDefKeySig(2),

  /// `ALIGNMENT_SCOREDEF_MENSUR`
  scoreDefMensur(3),

  /// `ALIGNMENT_SCOREDEF_METERSIG`
  scoreDefMeterSig(4),

  /// `ALIGNMENT_MEASURE_LEFT_BARLINE`
  measureLeftBarline(5),
  // Justifiable
  /// `ALIGNMENT_FULLMEASURE`
  fullMeasure(6),

  /// `ALIGNMENT_FULLMEASURE2`
  fullMeasure2(7),

  /// `ALIGNMENT_CLEF`
  clef(8),

  /// `ALIGNMENT_KEYSIG`
  keySig(9),

  /// `ALIGNMENT_MENSUR`
  mensur(10),

  /// `ALIGNMENT_METERSIG`
  meterSig(11),

  /// `ALIGNMENT_PROPORT`
  proport(12),

  /// `ALIGNMENT_DOT`
  dot(13),

  /// `ALIGNMENT_CUSTOS`
  custos(14),

  /// `ALIGNMENT_ACCID`
  accid(15),

  /// `ALIGNMENT_GRACENOTE`
  graceNote(16),

  /// `ALIGNMENT_BARLINE`
  barline(17),

  /// `ALIGNMENT_DIVLINE`
  divLine(18),

  /// `ALIGNMENT_DEFAULT`
  default_(19),
  // Non-justifiable
  /// `ALIGNMENT_MEASURE_RIGHT_BARLINE`
  measureRightBarline(20),

  /// `ALIGNMENT_SCOREDEF_CAUTION_CLEF`
  scoreDefCautionClef(21),

  /// `ALIGNMENT_SCOREDEF_CAUTION_KEYSIG`
  scoreDefCautionKeySig(22),

  /// `ALIGNMENT_SCOREDEF_CAUTION_MENSUR`
  scoreDefCautionMensur(23),

  /// `ALIGNMENT_SCOREDEF_CAUTION_METERSIG`
  scoreDefCautionMeterSig(24),

  /// `ALIGNMENT_MEASURE_END`
  measureEnd(25);

  const AlignmentType(this.value);

  /// The integer value of the enum entry (mirrors the C++ enumerator).
  final int value;
}

// ---------------------------------------------------------------------------
// Section representing a line in neon
// ---------------------------------------------------------------------------

const String neumeLineType = 'neon-neume-line';

// ---------------------------------------------------------------------------
// Legacy defines
// ---------------------------------------------------------------------------

const int octaveOffset = 4;

/// In half staff spaces.
const int standardStemLength = 7;
const int standardStemLengthTab = 3;

const double tablatureStaffRatio = 1.75;
const double germanTabStaffRatio = 2.2;

const double superScriptFactor = 0.58;
const double superScriptPosition = -0.20;
const double subScriptPosition = -0.17;

const double noteHeightToStaffSizeRatio = 2;
const double noteWidthToStaffSizeRatio = 1.4;

// ---------------------------------------------------------------------------
// ClassIds
// ---------------------------------------------------------------------------

/// Identifies Object child classes through the `Object.isClass` mechanism.
///
/// Mirrors `vrv::ClassId`. Boundary ids (e.g. [layerElement]) identify base
/// classes that are never instantiated directly.
enum ClassId {
  boundingBox,
  object,
  deviceContext,
  floatingObject,
  floatingPositioner,
  floatingCurvePositioner,
  // Ids for ungrouped objects
  accidFloating,
  alignment,
  alignmentReference,
  clefAttr,
  course,
  doc,
  facsimile,
  fb,
  grpSym,
  graceAligner,
  graphic,
  instrDef,
  keysigAttr,
  label,
  labelAbbr,
  layer,
  measure,
  measureAligner,
  mensurAttr,
  meterSigAttr,
  ossia,
  page,
  pages,
  staff,
  staffAlignment,
  staffGrp,
  surface,
  svg,
  symbolDef,
  symbolTable,
  system,
  systemAligner,
  systemAlignment,
  timestampAligner,
  tuning,
  zone,
  // Ids for EditorialElement child classes
  editorialElement,
  abbr,
  add,
  annot,
  app,
  choice,
  corr,
  damage,
  del,
  expan,
  lem,
  orig,
  rdg,
  ref,
  reg,
  restore,
  sic,
  subst,
  supplied,
  unclear,
  editorialElementMax,
  // Ids for TextLayoutElement child classes
  textLayoutElement,
  div,
  // Ids for RunningElement child classes
  runningElement,
  pgFoot,
  pgHead,
  runningElementMax,
  textLayoutElementMax,
  // Ids for PageElement child classes
  pageElement,
  pageMilestoneEnd,
  mdiv,
  score,
  pageElementMax,
  // Ids for SystemElement child classes
  systemElement,
  systemMilestoneEnd,
  ending,
  expansion,
  pb,
  sb,
  section,
  systemElementMax,
  // Ids for ControlElement child classes
  controlElement,
  anchoredText,
  annotScore,
  arpeg,
  beamSpan,
  bracketSpan,
  breath,
  caesura,
  cpMark,
  dir,
  dynam,
  fermata,
  fing,
  gliss,
  hairpin,
  harm,
  lv,
  mordent,
  mnum,
  ornam,
  octave,
  pedal,
  phrase,
  pitchInflection,
  reh,
  repeatMark,
  slur,
  tempo,
  tie,
  trill,
  turn,
  controlElementMax,
  // Ids for LayerElement child classes
  layerElement,
  accid,
  artic,
  barLine,
  beam,
  beatRpt,
  bTrem,
  chord,
  clef,
  custos,
  divLine,
  dot,
  dots,
  epistema,
  flag,
  fTrem,
  genericElement,
  graceGrp,
  halfmRpt,
  keysig,
  keyAccid,
  ligature,
  liquescent,
  mensur,
  meterSig,
  meterSigGrp,
  mRest,
  mRpt,
  mRpt2,
  mSpace,
  multiRest,
  multiRpt,
  nc,
  note,
  neume,
  oriscus,
  plica,
  proport,
  quilisma,
  strophicus,
  rest,
  space,
  stem,
  syl,
  syllable,
  tabGrp,
  tabDurSym,
  timestampAttr,
  tuplet,
  tupletBracket,
  tupletNum,
  verse,
  layerElementMax,
  // Ids for ScoreDefElement child classes
  scoreDefElement,
  layerDef,
  scoreDef,
  staffDef,
  scoreDefElementMax,
  // Ids for TextElement child classes
  textElement,
  f,
  fbText,
  fig,
  figure,
  lb,
  num,
  rend,
  symbol,
  text,
  textElementMax,
  //
  bboxDeviceContext,
  svgDeviceContext,
  customDeviceContext,
  // Pseudo ids for custom factory functions
  factoryStagedir,
  factoryOstaff,
  //
  unspecified,
}

// ---------------------------------------------------------------------------
// InterfaceIds
// ---------------------------------------------------------------------------

/// Mirrors `vrv::InterfaceId`.
enum InterfaceId {
  interface,
  altSym,
  areaPos,
  boundary,
  duration,
  linking,
  facsimile,
  offset,
  offsetSpanning,
  pitch,
  plist,
  position,
  scoreDef,
  textDir,
  timePoint,
  timeSpanning,
}
