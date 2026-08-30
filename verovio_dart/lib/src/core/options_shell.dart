/// Minimal shell of `options.h/cpp` — the Verovio options container.
///
/// The full set of ~100 options and their parsing are ported with the public
/// Toolkit API (Phase 7); model code only needs typed accessors which are
/// added incrementally here.
library;

import 'package:verovio_dart/src/core/vrvdef.dart'
    show defaultUnit, definitionFactor;
import 'package:verovio_dart/src/core/attdef.dart' show MeiDuration;
import 'package:verovio_dart/src/core/smufl.dart' show smuflE551LyricsElision;
import 'package:verovio_dart/src/model/atts/mei_enums.dart'
    show Pedalstyle;

/// The page / system breaks handling (mirrors `option_BREAKS` from
/// options.h).
enum Breaks { none, auto, line, smart, encoded }

/// The mensural responsive view mode (mirrors `option_MENSURAL_RESP`).
enum MensuralResp { none, auto, selection }

/// The condensed layout control (mirrors `option_CONDENSE`).
enum Condense { none, auto, all, encoded }

/// The system divider display (mirrors `option_SYSTEMDIVIDER` from
/// options.h:90; the declaration order matches the C++ numeric values, which
/// `View::DrawSystemDivider` compares with `>` `SYSTEMDIVIDER_auto`).
enum SystemDivider { none, auto, left, leftRight }

/// Mirrors `TEMP_KEYSIG_STEP` (options.h:52): the width of one accidental in
/// a key signature, as a fraction of the glyph width (`View::
/// SetScoreDefDrawingWidth`, view_page.cpp:156).
const double tempKeysigStep = 0.4;

/// How the smufl text font is included in the SVG output (mirrors
/// `option_SMUFLTEXTFONT` from options.h).
enum OptionSmuflTextFont {
  SMUFLTEXTFONT_embedded,
  SMUFLTEXTFONT_linked,
  SMUFLTEXTFONT_none
}

/// Base option shell (mirrors `vrv::Option`).
class Option<T> {
  Option._(this.name, this.defaultValue, {this.definitionFactor = false})
      : _value = defaultValue;

  /// The long option name (e.g., `adjustPageHeight`).
  final String name;

  T defaultValue;

  /// The raw (unfactored) stored value; mirrors `m_value`. Read it through
  /// [value] (mirrors `GetValue()`) or [unfactoredValue] (mirrors
  /// `GetUnfactoredValue()`).
  T _value;

  /// Whether the definition factor (`DEFINITION_FACTOR`, 10) applies to this
  /// option (mirrors `m_definitionFactor`). Exactly the 7 options of
  /// options.cpp that pass `true` to `Init(...)` carry it: `pageHeight`,
  /// `pageMarginBottom`, `pageMarginLeft`, `pageMarginRight`, `pageMarginTop`,
  /// `pageWidth` and `unit`.
  final bool definitionFactor;

  /// The factored value, mirroring `OptionDbl::GetValue()` /
  /// `OptionInt::GetValue()`: `(m_definitionFactor) ? m_value *
  /// DEFINITION_FACTOR : m_value`.
  T get value => applyDefinitionFactor(_value, definitionFactor);

  /// Mirrors `SetValue(...)`: stores the unfactored value.
  set value(T newValue) {
    _value = newValue;
    _isSet = true;
  }

  /// Mirrors `GetUnfactoredValue()` — returns `m_value` without the
  /// definition factor. The C++ serializes options with it (toolkit.cpp).
  T get unfactoredValue => _value;

  bool get isSet => _isSet;
  bool _isSet = false;

  void setValue(T newValue) {
    value = newValue;
    _isSet = true;
  }

  /// Reset to the default value.
  void reset() {
    value = defaultValue;
    _isSet = false;
  }
}

/// Applies the definition factor to a raw option value (mirrors the ternary
/// in `OptionDbl::GetValue()` / `OptionInt::GetValue()`). Top-level so the
/// `definitionFactor` constant of `vrvdef.dart` is reachable without being
/// shadowed by the homonymous field of [Option].
T applyDefinitionFactor<T>(T raw, bool enabled) =>
    enabled && raw is num ? (raw * definitionFactor) as T : raw;

/// Creates an [Option] with a default value and an optional definition
/// factor (mirrors `Init(default, min, max, bool definitionFactor)`; the
/// bounds are a Phase-7 concern and are not carried here).
Option<T> createOption<T>(String name, T defaultValue,
        {bool definitionFactor = false}) =>
    Option._(name, defaultValue, definitionFactor: definitionFactor);

/// The options container (mirrors `vrv::Options`).
///
/// Under construction: options are added phase by phase as modules need them.
/// The IO-related options from `options.h` are registered here (Phase 3).
class Options {
  Options() {
    _registerAll();
  }

  final List<Option<dynamic>> options = [];

  // Input/output formats (mirrors `m_inputFromFormat` / `m_outputToFormat`;
  // values are `vrv::FileFormat` codes, 0 == UNKNOWN).
  int inputFromFormat = 0;
  int outputToFormat = 0;

  /// Read `<incip>` elements from the header instead of the full score
  /// (mirrors `m_incip`).
  late final Option<bool> incip;

  /// Move scoreDef definitions to staffDefs on load (mirrors
  /// `m_moveScoreDefinitionToStaff`, default false as in options.cpp).
  late final Option<bool> moveScoreDefinitionToStaff;

  /// Preserve analytical markup instead of converting it (mirrors
  /// `m_preserveAnalyticalMarkup`).
  late final Option<bool> preserveAnalyticalMarkup;

  /// Use facsimile information for layout (mirrors `m_useFacsimile`).
  late final Option<bool> useFacsimile;

  /// XPath queries selecting the `<lem>`/`<rdg>` to make visible in `<app>`
  /// (mirrors `m_appXPathQuery`).
  late final Option<List<String>> appXPathQuery;

  /// XPath queries selecting the child to make visible in `<choice>`
  /// (mirrors `m_choiceXPathQuery`).
  late final Option<List<String>> choiceXPathQuery;

  /// Always expand expansions (mirrors `m_expandAlways`).
  late final Option<bool> expandAlways;

  /// Never expand expansions (mirrors `m_expandNever`).
  late final Option<bool> expandNever;

  /// Load only the selected mdiv (mirrors `m_loadSelectedMdivOnly`).
  late final Option<bool> loadSelectedMdivOnly;

  /// Load all mdivs (mirrors `m_mdivAll`).
  late final Option<bool> mdivAll;

  /// XPath query selecting the `<mdiv>` to load (mirrors
  /// `m_mdivXPathQuery`).
  late final Option<String> mdivXPathQuery;

  /// Hide ossia staves (mirrors `m_ossiaHidden`).
  late final Option<bool> ossiaHidden;

  /// XPath queries selecting the child to make visible in `<subst>`
  /// (mirrors `m_substXPathQuery`).
  late final Option<List<String>> substXPathQuery;

  // -------------------------------------------------------------------------
  // Layout options (Phase 4) — defaults mirror options.cpp
  // -------------------------------------------------------------------------

  /// The MEI unit, half of the distance between two staff lines (mirrors
  /// `m_unit`, default `DEFAULT_UNIT`).
  late final Option<double> unit;

  /// The staff minimal spacing in MEI units (mirrors `m_spacingStaff`).
  late final Option<int> spacingStaff;

  /// The brace group minimal spacing (mirrors `m_spacingBraceGroup`).
  late final Option<int> spacingBraceGroup;

  /// The bracket group minimal spacing (mirrors `m_spacingBracketGroup`).
  late final Option<int> spacingBracketGroup;

  /// The ossia spacing factor relative to the staff spacing (mirrors
  /// `m_spacingOssia`).
  late final Option<double> spacingOssia;

  /// The system justification factor (mirrors `m_justificationSystem`).
  late final Option<double> justificationSystem;

  /// The staff justification factor (mirrors `m_justificationStaff`).
  late final Option<double> justificationStaff;

  /// The brace group justification factor (mirrors
  /// `m_justificationBraceGroup`).
  late final Option<double> justificationBraceGroup;

  /// The bracket group justification factor (mirrors
  /// `m_justificationBracketGroup`).
  late final Option<double> justificationBracketGroup;

  /// Collapse empty verse lines in lyrics (mirrors `m_lyricVerseCollapse`).
  late final Option<bool> lyricVerseCollapse;

  /// The SMuFL codepoint (or `unicodeUndertie`) used for lyric elisions
  /// (mirrors `m_lyricElision`, default `smuflE551LyricsElision`).
  late final Option<int> lyricElision;

  /// The lyric verse line height factor (mirrors `m_lyricHeightFactor`, default 1.0).
  late final Option<double> lyricHeightFactor;

  /// The lyric extender line thickness (mirrors `m_lyricLineThickness`, default 0.25).
  late final Option<double> lyricLineThickness;

  /// Do not show hyphens at the beginning of a system (mirrors `m_lyricNoStartHyphen`).
  late final Option<bool> lyricNoStartHyphen;

  /// The minimal margin above the lyrics in MEI units (mirrors `m_lyricTopMinMargin`, default 2.0).
  late final Option<double> lyricTopMinMargin;

  /// The lyrics size in MEI units (mirrors `m_lyricSize`, default 4.5).
  late final Option<double> lyricSize;

  /// The lyric word space length, in units of the drawing unit (mirrors
  /// `m_lyricWordSpace`, default 1.20).
  late final Option<double> lyricWordSpace;

  /// Align grace notes rhythmically with all staves (mirrors
  /// `m_graceRhythmAlign`).
  late final Option<bool> graceRhythmAlign;

  /// Align the right position of a grace group with all staves (mirrors
  /// `m_graceRightAlign`).
  late final Option<bool> graceRightAlign;

  /// The ossia staff size ratio (mirrors `m_ossiaStaffSize`).
  late final Option<double> ossiaStaffSize;

  /// The thickness of the system bracket (mirrors `m_bracketThickness`).
  late final Option<double> bracketThickness;

  /// The thickness of the system sub-bracket (mirrors
  /// `m_subBracketThickness`, default 0.20).
  late final Option<double> subBracketThickness;

  /// Use the brace glyph from the current font instead of the bezier-curve
  /// drawing (mirrors `m_useBraceGlyph`, default false).
  late final Option<bool> useBraceGlyph;

  /// Default bottom margin for staves and control events (mirrors
  /// `m_defaultBottomMargin`; used by `Doc::GetBottomMargin(STAFF)`).
  late final Option<double> defaultBottomMargin;

  /// Default top margin for control events (mirrors `m_defaultTopMargin`).
  late final Option<double> defaultTopMargin;

  /// The top margin for artic (mirrors `m_topMarginArtic`).
  late final Option<double> topMarginArtic;

  /// The bottom margin for artic (mirrors `m_bottomMarginArtic`).
  late final Option<double> bottomMarginArtic;

  /// The top / bottom margin for harm (mirrors `m_topMarginHarm` /
  /// `m_bottomMarginHarm`).
  late final Option<double> topMarginHarm;
  late final Option<double> bottomMarginHarm;

  /// The bottom margin for octave (mirrors `m_bottomMarginOctave`).
  late final Option<double> bottomMarginOctave;

  /// The bottom margin for the page header (mirrors `m_bottomMarginPgHead`).
  /// Port of `Options::m_bottomMarginPgHead` (options.cpp:1686, registered as
  /// "bottomMarginHeader", default 2.0).
  late final Option<double> bottomMarginPgHead;

  /// The top margin for the page footer (mirrors `m_topMarginPgFooter`).
  /// Port of `Options::m_topMarginPgFooter` (options.cpp:1840, default 2.0).
  late final Option<double> topMarginPgFooter;

  // -------------------------------------------------------------------------
  // Slur options (Phase 4 floating positioners) — defaults mirror options.cpp
  // -------------------------------------------------------------------------

  /// The scale of the fingering font compared to the default font size
  /// (mirrors `m_fingeringScale`, options.cpp:1298, default 0.75); read by
  /// `Doc::UpdateDrawingValues` (doc.cpp:2396).
  late final Option<double> fingeringScale;

  /// The global pedal style (mirrors `m_pedalStyle`, options.cpp:1123,
  /// default `PEDALSTYLE_NONE`); read by `Pedal::GetPedalForm`
  /// (pedal.cpp:93).
  late final Option<Pedalstyle> pedalStyle;

  /// Slur safety distance in MEI units to obstacles (mirrors
  /// `m_slurMargin`, default 1.0).
  late final Option<double> slurMargin;

  /// The slur endpoint thickness in MEI units (mirrors
  /// `m_slurEndpointThickness`, default 0.1).
  late final Option<double> slurEndpointThickness;

  /// The flexibility of the slur endpoints (mirrors
  /// `m_slurEndpointFlexibility`, default 0.0).
  late final Option<double> slurEndpointFlexibility;

  /// The maximum slur slope in degrees (mirrors `m_slurMaxSlope`, default 60).
  late final Option<double> slurMaxSlope;

  /// The midpoint slur thickness in MEI units (mirrors
  /// `m_slurMidpointThickness`, default 0.6).
  late final Option<double> slurMidpointThickness;

  /// Slur symmetry — high value means more symmetric slurs (mirrors
  /// `m_slurSymmetry`, default 0.0).
  late final Option<double> slurSymmetry;

  /// Slur curve factor — high value means rounder slurs (mirrors
  /// `m_slurCurveFactor`, default 1.0).
  late final Option<double> slurCurveFactor;

  /// The staff line width in MEI units (mirrors `m_staffLineWidth`,
  /// default 0.15).
  late final Option<double> staffLineWidth;

  /// The mensural duration equivalence level (mirrors
  /// `m_durationEquivalence`, default `DURATION_EQ_brevis`).
  late final Option<MeiDuration> durationEquivalence;

  /// The length of ledger lines relative to the notehead, in staff units
  /// (mirrors `m_ledgerLineExtension`, default 0.54).
  late final Option<double> ledgerLineExtension;

  /// The thickness of the ledger lines in MEI units (mirrors
  /// `m_ledgerLineThickness`, default 0.25).
  late final Option<double> ledgerLineThickness;

  /// Whether to use SMuFL's predefined dynamics glyph combinations
  /// (mirrors `m_dynamSingleGlyphs`, default false).
  late final Option<bool> dynamSingleGlyphs;

  /// The height of the hairpin in MEI units (mirrors `m_hairpinSize`,
  /// options.cpp, default 3.0); read by `Doc::GetDrawingHairpinSize`
  /// (doc.cpp:2070).
  late final Option<double> hairpinSize;

  /// The thickness of the hairpin in MEI units (mirrors `m_hairpinThickness`,
  /// default 0.2).
  late final Option<double> hairpinThickness;

  /// Use alternative symbols for displaying octaves (mirrors
  /// `m_octaveAlternativeSymbols`, default false).
  late final Option<bool> octaveAlternativeSymbols;

  /// The thickness of the line used for an octave line (mirrors
  /// `m_octaveLineThickness`, default 0.20).
  late final Option<double> octaveLineThickness;

  /// Do not enclose octaves that are spanning over systems with parentheses
  /// (mirrors `m_octaveNoSpanningParentheses`, default false).
  late final Option<bool> octaveNoSpanningParentheses;

  /// The thickness of the line used for piano pedaling (mirrors
  /// `m_pedalLineThickness`, default 0.20).
  late final Option<double> pedalLineThickness;

  /// The thickness of the repeat and ending line (mirrors
  /// `m_repeatEndingLineThickness`, default 0.15).
  late final Option<double> repeatEndingLineThickness;

  /// The thickness of the line text enclosing box (mirrors
  /// `m_textEnclosureThickness`, default 0.2).
  late final Option<double> textEnclosureThickness;

  /// The endpoint tie thickness in MEI units (mirrors
  /// `m_tieEndpointThickness`, default 0.1).
  late final Option<double> tieEndpointThickness;

  /// The midpoint tie thickness in MEI units (mirrors
  /// `m_tieMidpointThickness`, default 0.5).
  late final Option<double> tieMidpointThickness;

  /// The minimum space for extender lines in MEI units (mirrors
  /// `m_extenderLineMinSpace`, default 1.5).
  late final Option<double> extenderLineMinSpace;

  /// Whether to output HTML5-compatible SVG (mirrors `m_svgHtml5`, default
  /// false).
  late final Option<bool> svgHtml5;

  // -------------------------------------------------------------------------
  // Cast-off / justification options (Phase 4) — defaults mirror options.cpp
  // -------------------------------------------------------------------------

  /// Define page and system breaks layout (mirrors `m_breaks`, default
  /// `BREAKS_auto`).
  late final Option<Breaks> breaks;

  /// Smart breaks sb usage threshold (mirrors `m_breaksSmartSb`, default
  /// 0.66).
  late final Option<double> breaksSmartSb;

  /// Avoid widow measures, i.e., a single measure on the last system (mirrors
  /// `m_breaksNoWidow`, default false).
  late final Option<bool> breaksNoWidow;

  /// Maximum number of systems per page (mirrors `m_systemMaxPerPage`,
  /// default 0 = no limit).
  late final Option<int> systemMaxPerPage;

  /// Justify spacing vertically to fill the page (mirrors
  /// `m_justifyVertically`, default false).
  late final Option<bool> justifyVertically;

  /// Minimum last-system-justification width (mirrors
  /// `m_minLastJustification`, default 0.8).
  late final Option<double> minLastJustification;

  /// Maximum ratio of justifiable height for a page (mirrors
  /// `m_justificationMaxVertical`, default 0.2).
  late final Option<double> justificationMaxVertical;

  /// The system minimal spacing in MEI units (mirrors `m_spacingSystem`,
  /// default 4).
  late final Option<int> spacingSystem;

  /// Adjust the page height to the height of the content (mirrors
  /// `m_adjustPageHeight`, default false).
  late final Option<bool> adjustPageHeight;

  /// Adjust the page width to the width of the content (mirrors
  /// `m_adjustPageWidth`, default false).
  late final Option<bool> adjustPageWidth;

  /// Do not justify the system (mirrors `m_noJustification`, default false).
  late final Option<bool> noJustification;

  /// The page height (mirrors `m_pageHeight`, default 2970).
  late final Option<int> pageHeight;

  /// The page width (mirrors `m_pageWidth`, default 2100).
  late final Option<int> pageWidth;

  /// The page bottom margin (mirrors `m_pageMarginBottom`, default 50).
  late final Option<int> pageMarginBottom;

  /// The page left margin (mirrors `m_pageMarginLeft`, default 50).
  late final Option<int> pageMarginLeft;

  /// The page right margin (mirrors `m_pageMarginRight`, default 50).
  late final Option<int> pageMarginRight;

  /// The page top margin (mirrors `m_pageMarginTop`, default 50).
  late final Option<int> pageMarginTop;

  // -------------------------------------------------------------------------
  // Rendering / page fitting options (Phase 5) — defaults mirror options.cpp
  // -------------------------------------------------------------------------

  /// Scale of the output in percent, 100 is normal size (mirrors
  /// `m_scale`, options.cpp:960, `DEFAULT_SCALE` = 100).
  late final Option<int> scale;

  /// Scale the content within the page instead of scaling the page itself
  /// (mirrors `m_scaleToPageSize`, options.cpp:1135, default false).
  late final Option<bool> scaleToPageSize;

  /// Scale down page content to fit the page height if needed (mirrors
  /// `m_shrinkToFit`, options.cpp:1148, default false).
  late final Option<bool> shrinkToFit;

  /// The display of system dividers (mirrors `m_systemDivider`,
  /// options.cpp:1536, default `SYSTEMDIVIDER_auto`).
  late final Option<SystemDivider> systemDivider;

  // -------------------------------------------------------------------------
  // Horizontal spacing options (Phase 4) — defaults mirror options.cpp
  // -------------------------------------------------------------------------

  /// Align notes and rests without adding duration based space (mirrors
  /// `m_evenNoteSpacing`, default false).
  late final Option<bool> evenNoteSpacing;

  /// Detect long duration for adjusting spacing (mirrors
  /// `m_spacingDurDetection`, default false).
  late final Option<bool> spacingDurDetection;

  /// The linear spacing factor (mirrors `m_spacingLinear`, default 0.25).
  late final Option<double> spacingLinear;

  /// The non-linear spacing factor (mirrors `m_spacingNonLinear`, default
  /// 0.6).
  late final Option<double> spacingNonLinear;

  /// The minimal measure width in MEI units (mirrors `m_measureMinWidth`,
  /// default 15).
  late final Option<int> measureMinWidth;

  /// The minimum length of tie in MEI units (mirrors `m_tieMinLength`,
  /// default 2.0).
  late final Option<double> tieMinLength;

  /// The barline width (mirrors `m_barLineWidth`, default 0.30).
  late final Option<double> barLineWidth;

  /// The thick barline thickness (mirrors `m_thickBarlineThickness`, default
  /// 1.0).
  late final Option<double> thickBarlineThickness;

  /// The barline separation (mirrors `m_barLineSeparation`, default 0.8).
  late final Option<double> barLineSeparation;

  /// The dashed barline dash length (mirrors `m_dashedBarLineDashLength`,
  /// default 8/7).
  late final Option<double> dashedBarLineDashLength;

  /// The dashed barline gap length (mirrors `m_dashedBarLineGapLength`,
  /// default 8/7).
  late final Option<double> dashedBarLineGapLength;

  /// The repeat barline dot separation (mirrors
  /// `m_repeatBarLineDotSeparation`, default 0.36).
  late final Option<double> repeatBarLineDotSeparation;

  /// How frequently to place measure numbers (mirrors `m_mnumInterval`,
  /// default 0 — system-start numbers and non-generated; no periodic).
  late final Option<int> mnumInterval;

  /// The grace size ratio numerator (mirrors `m_graceFactor`, default 0.75).
  late final Option<double> graceFactor;

  /// Draw ligatures as brackets (mirrors `m_ligatureAsBracket`, default
  /// false).
  late final Option<bool> ligatureAsBracket;

  /// Each nc gets an alignment as neumes would be notes (mirrors
  /// `m_neumeAsNote`, default false).
  late final Option<bool> neumeAsNote;

  /// Render liquescent head without tails (mirrors `m_liquescentWithoutTails`,
  /// default false).
  late final Option<bool> liquescentWithoutTails;

  /// Allow angled tuplet brackets on beams after trying to move them
  /// (mirrors `m_tupletAngledOnBeams`, default false).
  late final Option<bool> tupletAngledOnBeams;

  /// Place the tuplet number on the opposite side of the bracket
  /// (mirrors `m_tupletNumHead`, default false).
  late final Option<bool> tupletNumHead;

  /// The thickness of the tuplet bracket (mirrors
  /// `m_tupletBracketThickness`, default 0.2).
  late final Option<double> tupletBracketThickness;

  /// Make mensural content responsive (mirrors `m_mensuralResponsiveView`,
  /// default MensuralResp.auto). The `selection` mode
  /// (ConvertToMensuralViewDoc) is not ported and behaves like `auto`.
  late final Option<MensuralResp> mensuralResponsiveView;

  /// Control condensed score layout (mirrors `m_condense`, default
  /// `CONDENSE_auto`).
  late final Option<Condense> condense;

  /// When condensing a score, also condense the first page (mirrors
  /// `m_condenseFirstPage`, default false).
  late final Option<bool> condenseFirstPage;

  /// When condensing a score, do not condense the last system (mirrors
  /// `m_condenseNotLastSystem`, default false).
  late final Option<bool> condenseNotLastSystem;

  /// When condensing a score, also condense pages with a tempo or fermata
  /// (mirrors `m_condenseTempoPages`, default false).
  late final Option<bool> condenseTempoPages;

  /// The default left margin (mirrors `m_defaultLeftMargin`, default 0.0).
  late final Option<double> defaultLeftMargin;

  /// The default right margin (mirrors `m_defaultRightMargin`, default 0.0).
  late final Option<double> defaultRightMargin;

  /// The left margins per element (mirrors the `m_leftMargin*` option
  /// family; see [Options._registerMargins] for the defaults).
  late final Map<String, Option<double>> leftMargins;

  /// The right margins per element (mirrors the `m_rightMargin*` family).
  late final Map<String, Option<double>> rightMargins;

  void registerOption(Option<dynamic> option) {
    options.add(option);
  }

  void _registerAll() {
    incip = createOption('incip', false);
    moveScoreDefinitionToStaff =
        createOption('moveScoreDefinitionToStaff', false);
    preserveAnalyticalMarkup = createOption('preserveAnalyticalMarkup', false);
    useFacsimile = createOption('useFacsimile', false);
    appXPathQuery = createOption('appXPathQuery', <String>[]);
    choiceXPathQuery = createOption('choiceXPathQuery', <String>[]);
    expandAlways = createOption('expandAlways', false);
    expandNever = createOption('expandNever', false);
    loadSelectedMdivOnly = createOption('loadSelectedMdivOnly', false);
    mdivAll = createOption('mdivAll', false);
    mdivXPathQuery = createOption('mdivXPathQuery', '');
    ossiaHidden = createOption('ossiaHidden', false);
    substXPathQuery = createOption('substXPathQuery', <String>[]);

    // Layout options (defaults from options.cpp).
    // The 7 options with `Init(..., true)` (definitionFactor) mirror
    // options.cpp:1100-1120 and :1198-1199 exactly.
    unit = createOption('unit', defaultUnit, definitionFactor: true);
    spacingStaff = createOption('spacingStaff', 12);
    spacingBraceGroup = createOption('spacingBraceGroup', 12);
    spacingBracketGroup = createOption('spacingBracketGroup', 12);
    spacingOssia = createOption('spacingOssia', 0.35);
    justificationSystem = createOption('justificationSystem', 1.0);
    justificationStaff = createOption('justificationStaff', 1.0);
    justificationBraceGroup = createOption('justificationBraceGroup', 1.0);
    justificationBracketGroup = createOption('justificationBracketGroup', 1.0);
    lyricVerseCollapse = createOption('lyricVerseCollapse', false);
    lyricElision = createOption('lyricElision', smuflE551LyricsElision);
    lyricHeightFactor = createOption('lyricHeightFactor', 1.0);
    lyricLineThickness = createOption('lyricLineThickness', 0.25);
    lyricNoStartHyphen = createOption('lyricNoStartHyphen', false);
    lyricTopMinMargin = createOption('lyricTopMinMargin', 2.0);
    lyricSize = createOption('lyricSize', 4.5);
    lyricWordSpace = createOption('lyricWordSpace', 1.20);
    graceRhythmAlign = createOption('graceRhythmAlign', false);
    graceRightAlign = createOption('graceRightAlign', false);
    ossiaStaffSize = createOption('ossiaStaffSize', 0.75);
    bracketThickness = createOption('bracketThickness', 1.0);
    subBracketThickness = createOption('subBracketThickness', 0.20);
    useBraceGlyph = createOption('useBraceGlyph', false);
    defaultBottomMargin = createOption('defaultBottomMargin', 0.5);
    defaultTopMargin = createOption('defaultTopMargin', 0.5);
    topMarginArtic = createOption('topMarginArtic', 0.75);
    bottomMarginArtic = createOption('bottomMarginArtic', 0.75);
    topMarginHarm = createOption('topMarginHarm', 1.0);
    bottomMarginHarm = createOption('bottomMarginHarm', 1.0);
    bottomMarginOctave = createOption('bottomMarginOctave', 1.0);
    bottomMarginPgHead = createOption('bottomMarginHeader', 2.0);
    topMarginPgFooter = createOption('topMarginPgFooter', 2.0);

    // Slur options (defaults from options.cpp).
    slurMargin = createOption('slurMargin', 1.0);
    fingeringScale = createOption('fingeringScale', 0.75);
    pedalStyle = createOption('pedalStyle', Pedalstyle.none);
    slurEndpointThickness = createOption('slurEndpointThickness', 0.1);
    slurEndpointFlexibility = createOption('slurEndpointFlexibility', 0.0);
    slurMaxSlope = createOption('slurMaxSlope', 60.0);
    slurMidpointThickness = createOption('slurMidpointThickness', 0.6);
    slurSymmetry = createOption('slurSymmetry', 0.0);
    slurCurveFactor = createOption('slurCurveFactor', 1.0);
    staffLineWidth = createOption('staffLineWidth', 0.15);
    durationEquivalence =
        createOption('durationEquivalence', MeiDuration.breve);
    ledgerLineExtension = createOption('ledgerLineExtension', 0.54);
    ledgerLineThickness = createOption('ledgerLineThickness', 0.25);
    dynamSingleGlyphs = createOption('dynamSingleGlyphs', false);
    hairpinSize = createOption('hairpinSize', 3.0);
    hairpinThickness = createOption('hairpinThickness', 0.2);
    octaveAlternativeSymbols = createOption('octaveAlternativeSymbols', false);
    octaveLineThickness = createOption('octaveLineThickness', 0.20);
    octaveNoSpanningParentheses =
        createOption('octaveNoSpanningParentheses', false);
    pedalLineThickness = createOption('pedalLineThickness', 0.20);
    repeatEndingLineThickness = createOption('repeatEndingLineThickness', 0.15);
    textEnclosureThickness = createOption('textEnclosureThickness', 0.2);
    tieEndpointThickness = createOption('tieEndpointThickness', 0.1);
    tieMidpointThickness = createOption('tieMidpointThickness', 0.5);
    extenderLineMinSpace = createOption('extenderLineMinSpace', 1.5);
    svgHtml5 = createOption('svgHtml5', false);

    // Cast-off / justification options (defaults from options.cpp).
    breaks = createOption('breaks', Breaks.auto);
    breaksSmartSb = createOption('breaksSmartSb', 0.66);
    breaksNoWidow = createOption('breaksNoWidow', false);
    systemMaxPerPage = createOption('systemMaxPerPage', 0);
    justifyVertically = createOption('justifyVertically', false);
    minLastJustification = createOption('minLastJustification', 0.8);
    justificationMaxVertical = createOption('justificationMaxVertical', 0.2);
    spacingSystem = createOption('spacingSystem', 4);
    adjustPageHeight = createOption('adjustPageHeight', false);
    adjustPageWidth = createOption('adjustPageWidth', false);
    noJustification = createOption('noJustification', false);
    pageHeight = createOption('pageHeight', 2970, definitionFactor: true);
    pageWidth = createOption('pageWidth', 2100, definitionFactor: true);
    pageMarginBottom =
        createOption('pageMarginBottom', 50, definitionFactor: true);
    pageMarginLeft = createOption('pageMarginLeft', 50, definitionFactor: true);
    pageMarginRight =
        createOption('pageMarginRight', 50, definitionFactor: true);
    pageMarginTop = createOption('pageMarginTop', 50, definitionFactor: true);

    // Rendering / page fitting options (defaults from options.cpp).
    scale = createOption('scale', 100);
    scaleToPageSize = createOption('scaleToPageSize', false);
    shrinkToFit = createOption('shrinkToFit', false);
    systemDivider = createOption('systemDivider', SystemDivider.auto);

    // Horizontal spacing options (defaults from options.cpp).
    evenNoteSpacing = createOption('evenNoteSpacing', false);
    spacingDurDetection = createOption('spacingDurDetection', false);
    spacingLinear = createOption('spacingLinear', 0.25);
    spacingNonLinear = createOption('spacingNonLinear', 0.6);
    measureMinWidth = createOption('measureMinWidth', 15);
    tieMinLength = createOption('tieMinLength', 2.0);
    barLineWidth = createOption('barLineWidth', 0.30);
    thickBarlineThickness = createOption('thickBarlineThickness', 1.0);
    barLineSeparation = createOption('barLineSeparation', 0.80);
    dashedBarLineDashLength =
        createOption('dashedBarLineDashLength', 8.0 / 7.0);
    dashedBarLineGapLength = createOption('dashedBarLineGapLength', 8.0 / 7.0);
    repeatBarLineDotSeparation =
        createOption('repeatBarLineDotSeparation', 0.36);
    mnumInterval = createOption('mnumInterval', 0);
    graceFactor = createOption('graceFactor', 0.75);
    ligatureAsBracket = createOption('ligatureAsBracket', false);
    neumeAsNote = createOption('neumeAsNote', false);
    liquescentWithoutTails = createOption('liquescentWithoutTails', false);
    tupletAngledOnBeams = createOption('tupletAngledOnBeams', false);
    tupletNumHead = createOption('tupletNumHead', false);
    tupletBracketThickness = createOption('tupletBracketThickness', 0.2);
    mensuralResponsiveView =
        createOption('mensuralResponsiveView', MensuralResp.auto);
    condense = createOption('condense', Condense.auto);
    condenseFirstPage = createOption('condenseFirstPage', false);
    condenseNotLastSystem = createOption('condenseNotLastSystem', false);
    condenseTempoPages = createOption('condenseTempoPages', false);
    defaultLeftMargin = createOption('defaultLeftMargin', 0.0);
    defaultRightMargin = createOption('defaultRightMargin', 0.0);

    registerOption(evenNoteSpacing);
    registerOption(spacingDurDetection);
    registerOption(spacingLinear);
    registerOption(spacingNonLinear);
    registerOption(measureMinWidth);
    registerOption(tieMinLength);
    registerOption(barLineWidth);
    registerOption(thickBarlineThickness);
    registerOption(barLineSeparation);
    registerOption(dashedBarLineDashLength);
    registerOption(dashedBarLineGapLength);
    registerOption(repeatBarLineDotSeparation);
    registerOption(mnumInterval);
    registerOption(graceFactor);
    registerOption(ligatureAsBracket);
    registerOption(neumeAsNote);
    registerOption(liquescentWithoutTails);
    registerOption(tupletAngledOnBeams);
    registerOption(tupletNumHead);
    registerOption(tupletBracketThickness);
    registerOption(mensuralResponsiveView);
    registerOption(condense);
    registerOption(condenseFirstPage);
    registerOption(condenseNotLastSystem);
    registerOption(condenseTempoPages);
    registerOption(defaultLeftMargin);
    registerOption(defaultRightMargin);

    _registerMargins();

    registerOption(incip);
    registerOption(moveScoreDefinitionToStaff);
    registerOption(preserveAnalyticalMarkup);
    registerOption(useFacsimile);
    registerOption(appXPathQuery);
    registerOption(choiceXPathQuery);
    registerOption(expandAlways);
    registerOption(expandNever);
    registerOption(loadSelectedMdivOnly);
    registerOption(mdivAll);
    registerOption(mdivXPathQuery);
    registerOption(ossiaHidden);
    registerOption(substXPathQuery);

    registerOption(unit);
    registerOption(spacingStaff);
    registerOption(spacingBraceGroup);
    registerOption(spacingBracketGroup);
    registerOption(spacingOssia);
    registerOption(justificationSystem);
    registerOption(justificationStaff);
    registerOption(justificationBraceGroup);
    registerOption(justificationBracketGroup);
    registerOption(lyricVerseCollapse);
    registerOption(lyricElision);
    registerOption(lyricHeightFactor);
    registerOption(lyricLineThickness);
    registerOption(lyricNoStartHyphen);
    registerOption(lyricTopMinMargin);
    registerOption(lyricSize);
    registerOption(lyricWordSpace);
    registerOption(graceRhythmAlign);
    registerOption(graceRightAlign);
    registerOption(ossiaStaffSize);
    registerOption(bracketThickness);
    registerOption(subBracketThickness);
    registerOption(useBraceGlyph);
    registerOption(defaultBottomMargin);
    registerOption(defaultTopMargin);
    registerOption(topMarginArtic);
    registerOption(bottomMarginArtic);
    registerOption(topMarginHarm);
    registerOption(bottomMarginHarm);
    registerOption(bottomMarginOctave);
    registerOption(bottomMarginPgHead);
    registerOption(topMarginPgFooter);
    registerOption(slurMargin);
    registerOption(fingeringScale);
    registerOption(pedalStyle);
    registerOption(slurEndpointThickness);
    registerOption(slurEndpointFlexibility);
    registerOption(slurMaxSlope);
    registerOption(slurMidpointThickness);
    registerOption(slurSymmetry);
    registerOption(slurCurveFactor);
    registerOption(staffLineWidth);
    registerOption(durationEquivalence);
    registerOption(ledgerLineExtension);
    registerOption(ledgerLineThickness);
    registerOption(dynamSingleGlyphs);
    registerOption(hairpinSize);
    registerOption(hairpinThickness);
    registerOption(octaveAlternativeSymbols);
    registerOption(octaveLineThickness);
    registerOption(octaveNoSpanningParentheses);
    registerOption(pedalLineThickness);
    registerOption(repeatEndingLineThickness);
    registerOption(textEnclosureThickness);
    registerOption(tieEndpointThickness);
    registerOption(tieMidpointThickness);
    registerOption(extenderLineMinSpace);
    registerOption(svgHtml5);

    registerOption(breaks);
    registerOption(breaksSmartSb);
    registerOption(breaksNoWidow);
    registerOption(systemMaxPerPage);
    registerOption(justifyVertically);
    registerOption(minLastJustification);
    registerOption(justificationMaxVertical);
    registerOption(spacingSystem);
    registerOption(adjustPageHeight);
    registerOption(adjustPageWidth);
    registerOption(noJustification);
    registerOption(pageHeight);
    registerOption(pageWidth);
    registerOption(pageMarginBottom);
    registerOption(pageMarginLeft);
    registerOption(pageMarginRight);
    registerOption(pageMarginTop);
  }

  /// Registers the element margin options (mirrors the `m_elementMargins`
  /// group in options.cpp).
  void _registerMargins() {
    // (name, left default, right default) as in options.cpp.
    const List<(String, double, double)> margins = [
      ('Accid', 1.0, 0.5),
      ('BarLine', 0.0, 0.0),
      ('BeatRpt', 2.0, 0.0),
      ('Chord', 1.0, 0.0),
      ('Clef', 1.0, 1.0),
      ('KeySig', 1.0, 1.0),
      ('LeftBarLine', 1.0, 1.0),
      ('Mensur', 1.0, 1.0),
      ('MeterSig', 1.0, 1.0),
      ('MRest', 0.0, 0.0),
      ('MRpt2', 0.0, 0.0),
      ('MultiRest', 0.0, 0.0),
      ('MultiRpt', 0.0, 0.0),
      ('Note', 1.0, 0.0),
      ('Rest', 1.0, 0.0),
      ('RightBarLine', 1.0, 0.0),
      ('TabDurSym', 1.0, 0.0),
    ];

    leftMargins = {};
    rightMargins = {};
    for (final (String name, double left, double right) in margins) {
      final Option<double> leftOption = createOption('leftMargin$name', left);
      final Option<double> rightOption =
          createOption('rightMargin$name', right);
      leftMargins[name] = leftOption;
      rightMargins[name] = rightOption;
      registerOption(leftOption);
      registerOption(rightOption);
    }
  }

  /// Copy all values from [other] (mirrors `Options::operator=`).
  void copyFrom(Options other) {
    for (final Option<dynamic> option in other.options) {
      final Option<dynamic>? source =
          other.options.where((o) => o.name == option.name).firstOrNull;
      // The C++ CopyTo copies `m_value` directly, i.e., without the
      // definition factor; copying the factored read would double it.
      if (source != null) option.value = source.unfactoredValue;
    }
  }
}
