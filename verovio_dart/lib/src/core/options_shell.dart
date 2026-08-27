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

/// The page / system breaks handling (mirrors `option_BREAKS` from
/// options.h).
enum Breaks { none, auto, line, smart, encoded }

/// The mensural responsive view mode (mirrors `option_MENSURAL_RESP`).
enum MensuralResp { none, auto, selection }

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

  // -------------------------------------------------------------------------
  // Slur options (Phase 4 floating positioners) — defaults mirror options.cpp
  // -------------------------------------------------------------------------

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

  /// Make mensural content responsive (mirrors `m_mensuralResponsiveView`,
  /// default MensuralResp.auto). The `selection` mode
  /// (ConvertToMensuralViewDoc) is not ported and behaves like `auto`.
  late final Option<MensuralResp> mensuralResponsiveView;

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
    lyricSize = createOption('lyricSize', 4.5);
    lyricWordSpace = createOption('lyricWordSpace', 1.20);
    graceRhythmAlign = createOption('graceRhythmAlign', false);
    graceRightAlign = createOption('graceRightAlign', false);
    ossiaStaffSize = createOption('ossiaStaffSize', 0.75);
    bracketThickness = createOption('bracketThickness', 1.0);
    defaultBottomMargin = createOption('defaultBottomMargin', 0.5);
    defaultTopMargin = createOption('defaultTopMargin', 0.5);
    topMarginArtic = createOption('topMarginArtic', 0.75);
    bottomMarginArtic = createOption('bottomMarginArtic', 0.75);
    topMarginHarm = createOption('topMarginHarm', 1.0);
    bottomMarginHarm = createOption('bottomMarginHarm', 1.0);
    bottomMarginOctave = createOption('bottomMarginOctave', 1.0);

    // Slur options (defaults from options.cpp).
    slurMargin = createOption('slurMargin', 1.0);
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

    // Horizontal spacing options (defaults from options.cpp).
    evenNoteSpacing = createOption('evenNoteSpacing', false);
    spacingDurDetection = createOption('spacingDurDetection', false);
    spacingLinear = createOption('spacingLinear', 0.25);
    spacingNonLinear = createOption('spacingNonLinear', 0.6);
    measureMinWidth = createOption('measureMinWidth', 15);
    tieMinLength = createOption('tieMinLength', 2.0);
    barLineWidth = createOption('barLineWidth', 0.30);
    graceFactor = createOption('graceFactor', 0.75);
    ligatureAsBracket = createOption('ligatureAsBracket', false);
    neumeAsNote = createOption('neumeAsNote', false);
    liquescentWithoutTails = createOption('liquescentWithoutTails', false);
    tupletAngledOnBeams = createOption('tupletAngledOnBeams', false);
    tupletNumHead = createOption('tupletNumHead', false);
    mensuralResponsiveView =
        createOption('mensuralResponsiveView', MensuralResp.auto);
    defaultLeftMargin = createOption('defaultLeftMargin', 0.0);
    defaultRightMargin = createOption('defaultRightMargin', 0.0);

    registerOption(evenNoteSpacing);
    registerOption(spacingDurDetection);
    registerOption(spacingLinear);
    registerOption(spacingNonLinear);
    registerOption(measureMinWidth);
    registerOption(tieMinLength);
    registerOption(barLineWidth);
    registerOption(graceFactor);
    registerOption(ligatureAsBracket);
    registerOption(neumeAsNote);
    registerOption(liquescentWithoutTails);
    registerOption(tupletAngledOnBeams);
    registerOption(tupletNumHead);
    registerOption(mensuralResponsiveView);
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
    registerOption(lyricSize);
    registerOption(lyricWordSpace);
    registerOption(graceRhythmAlign);
    registerOption(graceRightAlign);
    registerOption(ossiaStaffSize);
    registerOption(bracketThickness);
    registerOption(defaultBottomMargin);
    registerOption(defaultTopMargin);
    registerOption(topMarginArtic);
    registerOption(bottomMarginArtic);
    registerOption(topMarginHarm);
    registerOption(bottomMarginHarm);
    registerOption(bottomMarginOctave);
    registerOption(slurMargin);
    registerOption(slurEndpointThickness);
    registerOption(slurEndpointFlexibility);
    registerOption(slurMaxSlope);
    registerOption(slurMidpointThickness);
    registerOption(slurSymmetry);
    registerOption(slurCurveFactor);
    registerOption(staffLineWidth);
    registerOption(durationEquivalence);
    registerOption(ledgerLineExtension);

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
