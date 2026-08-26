// GENERATED FILE - do not edit. Regenerate with:
//   dart run tool/gen_atts.dart
// Source: origin/src/libmei/dist/atttypes.h
library;

/// MEI `accidLog_FUNC`.
enum AccidlogFunc {
  /// `accidLog_FUNC_NONE`
  none(0),

  /// `accidLog_FUNC_caution`
  caution(1),

  /// `accidLog_FUNC_edit`
  edit(2),
  ;

  const AccidlogFunc(this.value);

  final int value;

  static AccidlogFunc fromValue(int value) =>
      AccidlogFunc.values.firstWhere((e) => e.value == value,
          orElse: () => AccidlogFunc.values.first);
}

/// MEI `anchoredTextLog_FUNC`.
enum AnchoredtextlogFunc {
  /// `anchoredTextLog_FUNC_NONE`
  none(0),

  /// `anchoredTextLog_FUNC_unknown`
  unknown(1),
  ;

  const AnchoredtextlogFunc(this.value);

  final int value;

  static AnchoredtextlogFunc fromValue(int value) =>
      AnchoredtextlogFunc.values.firstWhere((e) => e.value == value,
          orElse: () => AnchoredtextlogFunc.values.first);
}

/// MEI `annotLog_FUNC`.
enum AnnotlogFunc {
  /// `annotLog_FUNC_NONE`
  none(0),

  /// `annotLog_FUNC_display`
  display(1),
  ;

  const AnnotlogFunc(this.value);

  final int value;

  static AnnotlogFunc fromValue(int value) =>
      AnnotlogFunc.values.firstWhere((e) => e.value == value,
          orElse: () => AnnotlogFunc.values.first);
}

/// MEI `arpegLog_ORDER`.
enum ArpeglogOrder {
  /// `arpegLog_ORDER_NONE`
  none(0),

  /// `arpegLog_ORDER_up`
  up(1),

  /// `arpegLog_ORDER_down`
  down(2),

  /// `arpegLog_ORDER_nonarp`
  nonarp(3),
  ;

  const ArpeglogOrder(this.value);

  final int value;

  static ArpeglogOrder fromValue(int value) =>
      ArpeglogOrder.values.firstWhere((e) => e.value == value,
          orElse: () => ArpeglogOrder.values.first);
}

/// MEI `audience_AUDIENCE`.
enum AudienceAudience {
  /// `audience_AUDIENCE_NONE`
  none(0),

  /// `audience_AUDIENCE_private`
  private(1),

  /// `audience_AUDIENCE_public`
  public(2),
  ;

  const AudienceAudience(this.value);

  final int value;

  static AudienceAudience fromValue(int value) =>
      AudienceAudience.values.firstWhere((e) => e.value == value,
          orElse: () => AudienceAudience.values.first);
}

/// MEI `beamRend_FORM`.
enum BeamrendForm {
  /// `beamRend_FORM_NONE`
  none(0),

  /// `beamRend_FORM_acc`
  acc(1),

  /// `beamRend_FORM_mixed`
  mixed(2),

  /// `beamRend_FORM_rit`
  rit(3),

  /// `beamRend_FORM_norm`
  norm(4),
  ;

  const BeamrendForm(this.value);

  final int value;

  static BeamrendForm fromValue(int value) =>
      BeamrendForm.values.firstWhere((e) => e.value == value,
          orElse: () => BeamrendForm.values.first);
}

/// MEI `beamingVis_BEAMREND`.
enum BeamingvisBeamrend {
  /// `beamingVis_BEAMREND_NONE`
  none(0),

  /// `beamingVis_BEAMREND_acc`
  acc(1),

  /// `beamingVis_BEAMREND_rit`
  rit(2),

  /// `beamingVis_BEAMREND_norm`
  norm(3),
  ;

  const BeamingvisBeamrend(this.value);

  final int value;

  static BeamingvisBeamrend fromValue(int value) =>
      BeamingvisBeamrend.values.firstWhere((e) => e.value == value,
          orElse: () => BeamingvisBeamrend.values.first);
}

/// MEI `bracketSpanLog_FUNC`.
enum BracketspanlogFunc {
  /// `bracketSpanLog_FUNC_NONE`
  none(0),

  /// `bracketSpanLog_FUNC_coloration`
  coloration(1),

  /// `bracketSpanLog_FUNC_cross_rhythm`
  crossRhythm(2),

  /// `bracketSpanLog_FUNC_ligature`
  ligature(3),

  /// `bracketSpanLog_FUNC_analytical`
  analytical(4),

  /// `bracketSpanLog_FUNC_phrase`
  phrase(5),

  /// `bracketSpanLog_FUNC_uspecified`
  uspecified(6),
  ;

  const BracketspanlogFunc(this.value);

  final int value;

  static BracketspanlogFunc fromValue(int value) =>
      BracketspanlogFunc.values.firstWhere((e) => e.value == value,
          orElse: () => BracketspanlogFunc.values.first);
}

/// MEI `curvatureDirection_CURVE`.
enum CurvaturedirectionCurve {
  /// `curvatureDirection_CURVE_NONE`
  none(0),

  /// `curvatureDirection_CURVE_a`
  a(1),

  /// `curvatureDirection_CURVE_c`
  c(2),
  ;

  const CurvaturedirectionCurve(this.value);

  final int value;

  static CurvaturedirectionCurve fromValue(int value) =>
      CurvaturedirectionCurve.values.firstWhere((e) => e.value == value,
          orElse: () => CurvaturedirectionCurve.values.first);
}

/// MEI `curvature_CURVEDIR`.
enum CurvatureCurvedir {
  /// `curvature_CURVEDIR_NONE`
  none(0),

  /// `curvature_CURVEDIR_above`
  above(1),

  /// `curvature_CURVEDIR_below`
  below(2),

  /// `curvature_CURVEDIR_mixed`
  mixed(3),
  ;

  const CurvatureCurvedir(this.value);

  final int value;

  static CurvatureCurvedir fromValue(int value) =>
      CurvatureCurvedir.values.firstWhere((e) => e.value == value,
          orElse: () => CurvatureCurvedir.values.first);
}

/// MEI `curveLog_FUNC`.
enum CurvelogFunc {
  /// `curveLog_FUNC_NONE`
  none(0),

  /// `curveLog_FUNC_unknown`
  unknown(1),
  ;

  const CurvelogFunc(this.value);

  final int value;

  static CurvelogFunc fromValue(int value) =>
      CurvelogFunc.values.firstWhere((e) => e.value == value,
          orElse: () => CurvelogFunc.values.first);
}

/// MEI `cutout_CUTOUT`.
enum CutoutCutout {
  /// `cutout_CUTOUT_NONE`
  none(0),

  /// `cutout_CUTOUT_cutout`
  cutout(1),
  ;

  const CutoutCutout(this.value);

  final int value;

  static CutoutCutout fromValue(int value) =>
      CutoutCutout.values.firstWhere((e) => e.value == value,
          orElse: () => CutoutCutout.values.first);
}

/// MEI `data_ACCIDENTAL_GESTURAL`.
enum AccidentalGestural {
  /// `ACCIDENTAL_GESTURAL_NONE`
  none(0),

  /// `ACCIDENTAL_GESTURAL_s`
  s(1),

  /// `ACCIDENTAL_GESTURAL_f`
  f(2),

  /// `ACCIDENTAL_GESTURAL_ss`
  ss(3),

  /// `ACCIDENTAL_GESTURAL_ff`
  ff(4),

  /// `ACCIDENTAL_GESTURAL_ts`
  ts(5),

  /// `ACCIDENTAL_GESTURAL_tf`
  tf(6),

  /// `ACCIDENTAL_GESTURAL_n`
  n(7),

  /// `ACCIDENTAL_GESTURAL_su`
  su(8),

  /// `ACCIDENTAL_GESTURAL_sd`
  sd(9),

  /// `ACCIDENTAL_GESTURAL_fu`
  fu(10),

  /// `ACCIDENTAL_GESTURAL_fd`
  fd(11),

  /// `ACCIDENTAL_GESTURAL_xu`
  xu(12),

  /// `ACCIDENTAL_GESTURAL_ffd`
  ffd(13),

  /// `ACCIDENTAL_GESTURAL_bms`
  bms(14),

  /// `ACCIDENTAL_GESTURAL_kms`
  kms(15),

  /// `ACCIDENTAL_GESTURAL_bs`
  bs(16),

  /// `ACCIDENTAL_GESTURAL_ks`
  ks(17),

  /// `ACCIDENTAL_GESTURAL_kf`
  kf(18),

  /// `ACCIDENTAL_GESTURAL_bf`
  bf(19),

  /// `ACCIDENTAL_GESTURAL_kmf`
  kmf(20),

  /// `ACCIDENTAL_GESTURAL_bmf`
  bmf(21),

  /// `ACCIDENTAL_GESTURAL_koron`
  koron(22),

  /// `ACCIDENTAL_GESTURAL_sori`
  sori(23),
  ;

  const AccidentalGestural(this.value);

  final int value;

  static AccidentalGestural fromValue(int value) =>
      AccidentalGestural.values.firstWhere((e) => e.value == value,
          orElse: () => AccidentalGestural.values.first);
}

/// MEI `data_ACCIDENTAL_GESTURAL_basic`.
enum AccidentalGesturalBasic {
  /// `ACCIDENTAL_GESTURAL_basic_NONE`
  none(0),

  /// `ACCIDENTAL_GESTURAL_basic_s`
  s(1),

  /// `ACCIDENTAL_GESTURAL_basic_f`
  f(2),

  /// `ACCIDENTAL_GESTURAL_basic_ss`
  ss(3),

  /// `ACCIDENTAL_GESTURAL_basic_ff`
  ff(4),

  /// `ACCIDENTAL_GESTURAL_basic_ts`
  ts(5),

  /// `ACCIDENTAL_GESTURAL_basic_tf`
  tf(6),

  /// `ACCIDENTAL_GESTURAL_basic_n`
  n(7),
  ;

  const AccidentalGesturalBasic(this.value);

  final int value;

  static AccidentalGesturalBasic fromValue(int value) =>
      AccidentalGesturalBasic.values.firstWhere((e) => e.value == value,
          orElse: () => AccidentalGesturalBasic.values.first);
}

/// MEI `data_ACCIDENTAL_GESTURAL_extended`.
enum AccidentalGesturalExtended {
  /// `ACCIDENTAL_GESTURAL_extended_NONE`
  none(0),

  /// `ACCIDENTAL_GESTURAL_extended_su`
  su(1),

  /// `ACCIDENTAL_GESTURAL_extended_sd`
  sd(2),

  /// `ACCIDENTAL_GESTURAL_extended_fu`
  fu(3),

  /// `ACCIDENTAL_GESTURAL_extended_fd`
  fd(4),

  /// `ACCIDENTAL_GESTURAL_extended_xu`
  xu(5),

  /// `ACCIDENTAL_GESTURAL_extended_ffd`
  ffd(6),
  ;

  const AccidentalGesturalExtended(this.value);

  final int value;

  static AccidentalGesturalExtended fromValue(int value) =>
      AccidentalGesturalExtended.values.firstWhere((e) => e.value == value,
          orElse: () => AccidentalGesturalExtended.values.first);
}

/// MEI `data_ACCIDENTAL_WRITTEN`.
enum AccidentalWritten {
  /// `ACCIDENTAL_WRITTEN_NONE`
  none(0),

  /// `ACCIDENTAL_WRITTEN_s`
  s(1),

  /// `ACCIDENTAL_WRITTEN_f`
  f(2),

  /// `ACCIDENTAL_WRITTEN_ss`
  ss(3),

  /// `ACCIDENTAL_WRITTEN_x`
  x(4),

  /// `ACCIDENTAL_WRITTEN_ff`
  ff(5),

  /// `ACCIDENTAL_WRITTEN_xs`
  xs(6),

  /// `ACCIDENTAL_WRITTEN_sx`
  sx(7),

  /// `ACCIDENTAL_WRITTEN_ts`
  ts(8),

  /// `ACCIDENTAL_WRITTEN_tf`
  tf(9),

  /// `ACCIDENTAL_WRITTEN_n`
  n(10),

  /// `ACCIDENTAL_WRITTEN_nf`
  nf(11),

  /// `ACCIDENTAL_WRITTEN_ns`
  ns(12),

  /// `ACCIDENTAL_WRITTEN_su`
  su(13),

  /// `ACCIDENTAL_WRITTEN_sd`
  sd(14),

  /// `ACCIDENTAL_WRITTEN_fu`
  fu(15),

  /// `ACCIDENTAL_WRITTEN_fd`
  fd(16),

  /// `ACCIDENTAL_WRITTEN_nu`
  nu(17),

  /// `ACCIDENTAL_WRITTEN_nd`
  nd(18),

  /// `ACCIDENTAL_WRITTEN_xu`
  xu(19),

  /// `ACCIDENTAL_WRITTEN_xd`
  xd(20),

  /// `ACCIDENTAL_WRITTEN_ffu`
  ffu(21),

  /// `ACCIDENTAL_WRITTEN_ffd`
  ffd(22),

  /// `ACCIDENTAL_WRITTEN_1qf`
  n1qf(23),

  /// `ACCIDENTAL_WRITTEN_3qf`
  n3qf(24),

  /// `ACCIDENTAL_WRITTEN_1qs`
  n1qs(25),

  /// `ACCIDENTAL_WRITTEN_3qs`
  n3qs(26),

  /// `ACCIDENTAL_WRITTEN_bms`
  bms(27),

  /// `ACCIDENTAL_WRITTEN_kms`
  kms(28),

  /// `ACCIDENTAL_WRITTEN_bs`
  bs(29),

  /// `ACCIDENTAL_WRITTEN_ks`
  ks(30),

  /// `ACCIDENTAL_WRITTEN_kf`
  kf(31),

  /// `ACCIDENTAL_WRITTEN_bf`
  bf(32),

  /// `ACCIDENTAL_WRITTEN_kmf`
  kmf(33),

  /// `ACCIDENTAL_WRITTEN_bmf`
  bmf(34),

  /// `ACCIDENTAL_WRITTEN_koron`
  koron(35),

  /// `ACCIDENTAL_WRITTEN_sori`
  sori(36),
  ;

  const AccidentalWritten(this.value);

  final int value;

  static AccidentalWritten fromValue(int value) =>
      AccidentalWritten.values.firstWhere((e) => e.value == value,
          orElse: () => AccidentalWritten.values.first);
}

/// MEI `data_ACCIDENTAL_WRITTEN_basic`.
enum AccidentalWrittenBasic {
  /// `ACCIDENTAL_WRITTEN_basic_NONE`
  none(0),

  /// `ACCIDENTAL_WRITTEN_basic_s`
  s(1),

  /// `ACCIDENTAL_WRITTEN_basic_f`
  f(2),

  /// `ACCIDENTAL_WRITTEN_basic_ss`
  ss(3),

  /// `ACCIDENTAL_WRITTEN_basic_x`
  x(4),

  /// `ACCIDENTAL_WRITTEN_basic_ff`
  ff(5),

  /// `ACCIDENTAL_WRITTEN_basic_xs`
  xs(6),

  /// `ACCIDENTAL_WRITTEN_basic_sx`
  sx(7),

  /// `ACCIDENTAL_WRITTEN_basic_ts`
  ts(8),

  /// `ACCIDENTAL_WRITTEN_basic_tf`
  tf(9),

  /// `ACCIDENTAL_WRITTEN_basic_n`
  n(10),

  /// `ACCIDENTAL_WRITTEN_basic_nf`
  nf(11),

  /// `ACCIDENTAL_WRITTEN_basic_ns`
  ns(12),
  ;

  const AccidentalWrittenBasic(this.value);

  final int value;

  static AccidentalWrittenBasic fromValue(int value) =>
      AccidentalWrittenBasic.values.firstWhere((e) => e.value == value,
          orElse: () => AccidentalWrittenBasic.values.first);
}

/// MEI `data_ACCIDENTAL_WRITTEN_extended`.
enum AccidentalWrittenExtended {
  /// `ACCIDENTAL_WRITTEN_extended_NONE`
  none(0),

  /// `ACCIDENTAL_WRITTEN_extended_su`
  su(1),

  /// `ACCIDENTAL_WRITTEN_extended_sd`
  sd(2),

  /// `ACCIDENTAL_WRITTEN_extended_fu`
  fu(3),

  /// `ACCIDENTAL_WRITTEN_extended_fd`
  fd(4),

  /// `ACCIDENTAL_WRITTEN_extended_nu`
  nu(5),

  /// `ACCIDENTAL_WRITTEN_extended_nd`
  nd(6),

  /// `ACCIDENTAL_WRITTEN_extended_xu`
  xu(7),

  /// `ACCIDENTAL_WRITTEN_extended_xd`
  xd(8),

  /// `ACCIDENTAL_WRITTEN_extended_ffu`
  ffu(9),

  /// `ACCIDENTAL_WRITTEN_extended_ffd`
  ffd(10),

  /// `ACCIDENTAL_WRITTEN_extended_1qf`
  n1qf(11),

  /// `ACCIDENTAL_WRITTEN_extended_3qf`
  n3qf(12),

  /// `ACCIDENTAL_WRITTEN_extended_1qs`
  n1qs(13),

  /// `ACCIDENTAL_WRITTEN_extended_3qs`
  n3qs(14),
  ;

  const AccidentalWrittenExtended(this.value);

  final int value;

  static AccidentalWrittenExtended fromValue(int value) =>
      AccidentalWrittenExtended.values.firstWhere((e) => e.value == value,
          orElse: () => AccidentalWrittenExtended.values.first);
}

/// MEI `data_ACCIDENTAL_aeu`.
enum AccidentalAeu {
  /// `ACCIDENTAL_aeu_NONE`
  none(0),

  /// `ACCIDENTAL_aeu_bms`
  bms(1),

  /// `ACCIDENTAL_aeu_kms`
  kms(2),

  /// `ACCIDENTAL_aeu_bs`
  bs(3),

  /// `ACCIDENTAL_aeu_ks`
  ks(4),

  /// `ACCIDENTAL_aeu_kf`
  kf(5),

  /// `ACCIDENTAL_aeu_bf`
  bf(6),

  /// `ACCIDENTAL_aeu_kmf`
  kmf(7),

  /// `ACCIDENTAL_aeu_bmf`
  bmf(8),
  ;

  const AccidentalAeu(this.value);

  final int value;

  static AccidentalAeu fromValue(int value) =>
      AccidentalAeu.values.firstWhere((e) => e.value == value,
          orElse: () => AccidentalAeu.values.first);
}

/// MEI `data_ACCIDENTAL_persian`.
enum AccidentalPersian {
  /// `ACCIDENTAL_persian_NONE`
  none(0),

  /// `ACCIDENTAL_persian_koron`
  koron(1),

  /// `ACCIDENTAL_persian_sori`
  sori(2),
  ;

  const AccidentalPersian(this.value);

  final int value;

  static AccidentalPersian fromValue(int value) =>
      AccidentalPersian.values.firstWhere((e) => e.value == value,
          orElse: () => AccidentalPersian.values.first);
}

/// MEI `data_ARTICULATION`.
enum Articulation {
  /// `ARTICULATION_NONE`
  none(0),

  /// `ARTICULATION_acc`
  acc(1),

  /// `ARTICULATION_acc_inv`
  accInv(2),

  /// `ARTICULATION_acc_long`
  accLong(3),

  /// `ARTICULATION_acc_soft`
  accSoft(4),

  /// `ARTICULATION_stacc`
  stacc(5),

  /// `ARTICULATION_ten`
  ten(6),

  /// `ARTICULATION_stacciss`
  stacciss(7),

  /// `ARTICULATION_marc`
  marc(8),

  /// `ARTICULATION_spicc`
  spicc(9),

  /// `ARTICULATION_stress`
  stress(10),

  /// `ARTICULATION_unstress`
  unstress(11),

  /// `ARTICULATION_doit`
  doit(12),

  /// `ARTICULATION_scoop`
  scoop(13),

  /// `ARTICULATION_rip`
  rip(14),

  /// `ARTICULATION_plop`
  plop(15),

  /// `ARTICULATION_fall`
  fall(16),

  /// `ARTICULATION_longfall`
  longfall(17),

  /// `ARTICULATION_bend`
  bend(18),

  /// `ARTICULATION_flip`
  flip(19),

  /// `ARTICULATION_smear`
  smear(20),

  /// `ARTICULATION_shake`
  shake(21),

  /// `ARTICULATION_dnbow`
  dnbow(22),

  /// `ARTICULATION_upbow`
  upbow(23),

  /// `ARTICULATION_harm`
  harm(24),

  /// `ARTICULATION_snap`
  snap(25),

  /// `ARTICULATION_fingernail`
  fingernail(26),

  /// `ARTICULATION_damp`
  damp(27),

  /// `ARTICULATION_dampall`
  dampall(28),

  /// `ARTICULATION_open`
  open(29),

  /// `ARTICULATION_stop`
  stop(30),

  /// `ARTICULATION_dbltongue`
  dbltongue(31),

  /// `ARTICULATION_trpltongue`
  trpltongue(32),

  /// `ARTICULATION_heel`
  heel(33),

  /// `ARTICULATION_toe`
  toe(34),

  /// `ARTICULATION_tap`
  tap(35),

  /// `ARTICULATION_lhpizz`
  lhpizz(36),

  /// `ARTICULATION_dot`
  dot(37),

  /// `ARTICULATION_stroke`
  stroke(38),
  ;

  const Articulation(this.value);

  final int value;

  static Articulation fromValue(int value) =>
      Articulation.values.firstWhere((e) => e.value == value,
          orElse: () => Articulation.values.first);
}

/// MEI `data_BARMETHOD`.
enum Barmethod {
  /// `BARMETHOD_NONE`
  none(0),

  /// `BARMETHOD_mensur`
  mensur(1),

  /// `BARMETHOD_staff`
  staff(2),

  /// `BARMETHOD_takt`
  takt(3),
  ;

  const Barmethod(this.value);

  final int value;

  static Barmethod fromValue(int value) =>
      Barmethod.values.firstWhere((e) => e.value == value,
          orElse: () => Barmethod.values.first);
}

/// MEI `data_BARRENDITION`.
enum Barrendition {
  /// `BARRENDITION_NONE`
  none(0),

  /// `BARRENDITION_dashed`
  dashed(1),

  /// `BARRENDITION_dotted`
  dotted(2),

  /// `BARRENDITION_dbl`
  dbl(3),

  /// `BARRENDITION_dbldashed`
  dbldashed(4),

  /// `BARRENDITION_dbldotted`
  dbldotted(5),

  /// `BARRENDITION_dblheavy`
  dblheavy(6),

  /// `BARRENDITION_dblsegno`
  dblsegno(7),

  /// `BARRENDITION_end`
  end(8),

  /// `BARRENDITION_heavy`
  heavy(9),

  /// `BARRENDITION_invis`
  invis(10),

  /// `BARRENDITION_rptstart`
  rptstart(11),

  /// `BARRENDITION_rptboth`
  rptboth(12),

  /// `BARRENDITION_rptend`
  rptend(13),

  /// `BARRENDITION_segno`
  segno(14),

  /// `BARRENDITION_single`
  single(15),
  ;

  const Barrendition(this.value);

  final int value;

  static Barrendition fromValue(int value) =>
      Barrendition.values.firstWhere((e) => e.value == value,
          orElse: () => Barrendition.values.first);
}

/// MEI `data_BEAMPLACE`.
enum Beamplace {
  /// `BEAMPLACE_NONE`
  none(0),

  /// `BEAMPLACE_above`
  above(1),

  /// `BEAMPLACE_below`
  below(2),

  /// `BEAMPLACE_mixed`
  mixed(3),
  ;

  const Beamplace(this.value);

  final int value;

  static Beamplace fromValue(int value) =>
      Beamplace.values.firstWhere((e) => e.value == value,
          orElse: () => Beamplace.values.first);
}

/// MEI `data_BEATRPT_REND`.
enum BeatrptRend {
  /// `BEATRPT_REND_NONE`
  none(0),

  /// `BEATRPT_REND_1`
  n1(1),

  /// `BEATRPT_REND_2`
  n2(2),

  /// `BEATRPT_REND_3`
  n3(3),

  /// `BEATRPT_REND_4`
  n4(4),

  /// `BEATRPT_REND_5`
  n5(5),

  /// `BEATRPT_REND_mixed`
  mixed(6),
  ;

  const BeatrptRend(this.value);

  final int value;

  static BeatrptRend fromValue(int value) =>
      BeatrptRend.values.firstWhere((e) => e.value == value,
          orElse: () => BeatrptRend.values.first);
}

/// MEI `data_BETYPE`.
enum Betype {
  /// `BETYPE_NONE`
  none(0),

  /// `BETYPE_byte`
  byte(1),

  /// `BETYPE_smil`
  smil(2),

  /// `BETYPE_midi`
  midi(3),

  /// `BETYPE_mmc`
  mmc(4),

  /// `BETYPE_mtc`
  mtc(5),

  /// `BETYPE_smpte_25`
  smpte25(6),

  /// `BETYPE_smpte_24`
  smpte24(7),

  /// `BETYPE_smpte_df30`
  smpteDf30(8),

  /// `BETYPE_smpte_ndf30`
  smpteNdf30(9),

  /// `BETYPE_smpte_df29_97`
  smpteDf2997(10),

  /// `BETYPE_smpte_ndf29_97`
  smpteNdf2997(11),

  /// `BETYPE_tcf`
  tcf(12),

  /// `BETYPE_time`
  time(13),
  ;

  const Betype(this.value);

  final int value;

  static Betype fromValue(int value) => Betype.values
      .firstWhere((e) => e.value == value, orElse: () => Betype.values.first);
}

/// MEI `data_BOOLEAN`.
enum Boolean {
  /// `BOOLEAN_NONE`
  none(0),

  /// `BOOLEAN_true`
  trueValue(1),

  /// `BOOLEAN_false`
  falseValue(2),
  ;

  const Boolean(this.value);

  final int value;

  static Boolean fromValue(int value) => Boolean.values
      .firstWhere((e) => e.value == value, orElse: () => Boolean.values.first);
}

/// MEI `data_CANCELACCID`.
enum Cancelaccid {
  /// `CANCELACCID_NONE`
  none(0),

  /// `CANCELACCID_none`
  none0(1),

  /// `CANCELACCID_before`
  before(2),

  /// `CANCELACCID_after`
  after(3),

  /// `CANCELACCID_before_bar`
  beforeBar(4),
  ;

  const Cancelaccid(this.value);

  final int value;

  static Cancelaccid fromValue(int value) =>
      Cancelaccid.values.firstWhere((e) => e.value == value,
          orElse: () => Cancelaccid.values.first);
}

/// MEI `data_CERTAINTY`.
enum Certainty {
  /// `CERTAINTY_NONE`
  none(0),

  /// `CERTAINTY_high`
  high(1),

  /// `CERTAINTY_medium`
  medium(2),

  /// `CERTAINTY_low`
  low(3),

  /// `CERTAINTY_unknown`
  unknown(4),
  ;

  const Certainty(this.value);

  final int value;

  static Certainty fromValue(int value) =>
      Certainty.values.firstWhere((e) => e.value == value,
          orElse: () => Certainty.values.first);
}

/// MEI `data_CLEFSHAPE`.
enum Clefshape {
  /// `CLEFSHAPE_NONE`
  none(0),

  /// `CLEFSHAPE_G`
  g(1),

  /// `CLEFSHAPE_GG`
  gg(2),

  /// `CLEFSHAPE_F`
  f(3),

  /// `CLEFSHAPE_C`
  c(4),

  /// `CLEFSHAPE_perc`
  perc(5),

  /// `CLEFSHAPE_TAB`
  tab(6),
  ;

  const Clefshape(this.value);

  final int value;

  static Clefshape fromValue(int value) =>
      Clefshape.values.firstWhere((e) => e.value == value,
          orElse: () => Clefshape.values.first);
}

/// MEI `data_CLUSTER`.
enum Cluster {
  /// `CLUSTER_NONE`
  none(0),

  /// `CLUSTER_white`
  white(1),

  /// `CLUSTER_black`
  black(2),

  /// `CLUSTER_chromatic`
  chromatic(3),
  ;

  const Cluster(this.value);

  final int value;

  static Cluster fromValue(int value) => Cluster.values
      .firstWhere((e) => e.value == value, orElse: () => Cluster.values.first);
}

/// MEI `data_COLORNAMES`.
enum Colornames {
  /// `COLORNAMES_NONE`
  none(0),

  /// `COLORNAMES_aliceblue`
  aliceblue(1),

  /// `COLORNAMES_antiquewhite`
  antiquewhite(2),

  /// `COLORNAMES_aqua`
  aqua(3),

  /// `COLORNAMES_aquamarine`
  aquamarine(4),

  /// `COLORNAMES_azure`
  azure(5),

  /// `COLORNAMES_beige`
  beige(6),

  /// `COLORNAMES_bisque`
  bisque(7),

  /// `COLORNAMES_black`
  black(8),

  /// `COLORNAMES_blanchedalmond`
  blanchedalmond(9),

  /// `COLORNAMES_blue`
  blue(10),

  /// `COLORNAMES_blueviolet`
  blueviolet(11),

  /// `COLORNAMES_brown`
  brown(12),

  /// `COLORNAMES_burlywood`
  burlywood(13),

  /// `COLORNAMES_cadetblue`
  cadetblue(14),

  /// `COLORNAMES_chartreuse`
  chartreuse(15),

  /// `COLORNAMES_chocolate`
  chocolate(16),

  /// `COLORNAMES_coral`
  coral(17),

  /// `COLORNAMES_cornflowerblue`
  cornflowerblue(18),

  /// `COLORNAMES_cornsilk`
  cornsilk(19),

  /// `COLORNAMES_crimson`
  crimson(20),

  /// `COLORNAMES_cyan`
  cyan(21),

  /// `COLORNAMES_darkblue`
  darkblue(22),

  /// `COLORNAMES_darkcyan`
  darkcyan(23),

  /// `COLORNAMES_darkgoldenrod`
  darkgoldenrod(24),

  /// `COLORNAMES_darkgray`
  darkgray(25),

  /// `COLORNAMES_darkgreen`
  darkgreen(26),

  /// `COLORNAMES_darkgrey`
  darkgrey(27),

  /// `COLORNAMES_darkkhaki`
  darkkhaki(28),

  /// `COLORNAMES_darkmagenta`
  darkmagenta(29),

  /// `COLORNAMES_darkolivegreen`
  darkolivegreen(30),

  /// `COLORNAMES_darkorange`
  darkorange(31),

  /// `COLORNAMES_darkorchid`
  darkorchid(32),

  /// `COLORNAMES_darkred`
  darkred(33),

  /// `COLORNAMES_darksalmon`
  darksalmon(34),

  /// `COLORNAMES_darkseagreen`
  darkseagreen(35),

  /// `COLORNAMES_darkslateblue`
  darkslateblue(36),

  /// `COLORNAMES_darkslategray`
  darkslategray(37),

  /// `COLORNAMES_darkslategrey`
  darkslategrey(38),

  /// `COLORNAMES_darkturquoise`
  darkturquoise(39),

  /// `COLORNAMES_darkviolet`
  darkviolet(40),

  /// `COLORNAMES_deeppink`
  deeppink(41),

  /// `COLORNAMES_deepskyblue`
  deepskyblue(42),

  /// `COLORNAMES_dimgray`
  dimgray(43),

  /// `COLORNAMES_dimgrey`
  dimgrey(44),

  /// `COLORNAMES_dodgerblue`
  dodgerblue(45),

  /// `COLORNAMES_firebrick`
  firebrick(46),

  /// `COLORNAMES_floralwhite`
  floralwhite(47),

  /// `COLORNAMES_forestgreen`
  forestgreen(48),

  /// `COLORNAMES_fuchsia`
  fuchsia(49),

  /// `COLORNAMES_gainsboro`
  gainsboro(50),

  /// `COLORNAMES_ghostwhite`
  ghostwhite(51),

  /// `COLORNAMES_gold`
  gold(52),

  /// `COLORNAMES_goldenrod`
  goldenrod(53),

  /// `COLORNAMES_gray`
  gray(54),

  /// `COLORNAMES_green`
  green(55),

  /// `COLORNAMES_greenyellow`
  greenyellow(56),

  /// `COLORNAMES_grey`
  grey(57),

  /// `COLORNAMES_honeydew`
  honeydew(58),

  /// `COLORNAMES_hotpink`
  hotpink(59),

  /// `COLORNAMES_indianred`
  indianred(60),

  /// `COLORNAMES_indigo`
  indigo(61),

  /// `COLORNAMES_ivory`
  ivory(62),

  /// `COLORNAMES_khaki`
  khaki(63),

  /// `COLORNAMES_lavender`
  lavender(64),

  /// `COLORNAMES_lavenderblush`
  lavenderblush(65),

  /// `COLORNAMES_lawngreen`
  lawngreen(66),

  /// `COLORNAMES_lemonchiffon`
  lemonchiffon(67),

  /// `COLORNAMES_lightblue`
  lightblue(68),

  /// `COLORNAMES_lightcoral`
  lightcoral(69),

  /// `COLORNAMES_lightcyan`
  lightcyan(70),

  /// `COLORNAMES_lightgoldenrodyellow`
  lightgoldenrodyellow(71),

  /// `COLORNAMES_lightgray`
  lightgray(72),

  /// `COLORNAMES_lightgreen`
  lightgreen(73),

  /// `COLORNAMES_lightgrey`
  lightgrey(74),

  /// `COLORNAMES_lightpink`
  lightpink(75),

  /// `COLORNAMES_lightsalmon`
  lightsalmon(76),

  /// `COLORNAMES_lightseagreen`
  lightseagreen(77),

  /// `COLORNAMES_lightskyblue`
  lightskyblue(78),

  /// `COLORNAMES_lightslategray`
  lightslategray(79),

  /// `COLORNAMES_lightslategrey`
  lightslategrey(80),

  /// `COLORNAMES_lightsteelblue`
  lightsteelblue(81),

  /// `COLORNAMES_lightyellow`
  lightyellow(82),

  /// `COLORNAMES_lime`
  lime(83),

  /// `COLORNAMES_limegreen`
  limegreen(84),

  /// `COLORNAMES_linen`
  linen(85),

  /// `COLORNAMES_magenta`
  magenta(86),

  /// `COLORNAMES_maroon`
  maroon(87),

  /// `COLORNAMES_mediumaquamarine`
  mediumaquamarine(88),

  /// `COLORNAMES_mediumblue`
  mediumblue(89),

  /// `COLORNAMES_mediumorchid`
  mediumorchid(90),

  /// `COLORNAMES_mediumpurple`
  mediumpurple(91),

  /// `COLORNAMES_mediumseagreen`
  mediumseagreen(92),

  /// `COLORNAMES_mediumslateblue`
  mediumslateblue(93),

  /// `COLORNAMES_mediumspringgreen`
  mediumspringgreen(94),

  /// `COLORNAMES_mediumturquoise`
  mediumturquoise(95),

  /// `COLORNAMES_mediumvioletred`
  mediumvioletred(96),

  /// `COLORNAMES_midnightblue`
  midnightblue(97),

  /// `COLORNAMES_mintcream`
  mintcream(98),

  /// `COLORNAMES_mistyrose`
  mistyrose(99),

  /// `COLORNAMES_moccasin`
  moccasin(100),

  /// `COLORNAMES_navajowhite`
  navajowhite(101),

  /// `COLORNAMES_navy`
  navy(102),

  /// `COLORNAMES_oldlace`
  oldlace(103),

  /// `COLORNAMES_olive`
  olive(104),

  /// `COLORNAMES_olivedrab`
  olivedrab(105),

  /// `COLORNAMES_orange`
  orange(106),

  /// `COLORNAMES_orangered`
  orangered(107),

  /// `COLORNAMES_orchid`
  orchid(108),

  /// `COLORNAMES_palegoldenrod`
  palegoldenrod(109),

  /// `COLORNAMES_palegreen`
  palegreen(110),

  /// `COLORNAMES_paleturquoise`
  paleturquoise(111),

  /// `COLORNAMES_palevioletred`
  palevioletred(112),

  /// `COLORNAMES_papayawhip`
  papayawhip(113),

  /// `COLORNAMES_peachpuff`
  peachpuff(114),

  /// `COLORNAMES_peru`
  peru(115),

  /// `COLORNAMES_pink`
  pink(116),

  /// `COLORNAMES_plum`
  plum(117),

  /// `COLORNAMES_powderblue`
  powderblue(118),

  /// `COLORNAMES_purple`
  purple(119),

  /// `COLORNAMES_rebeccapurple`
  rebeccapurple(120),

  /// `COLORNAMES_red`
  red(121),

  /// `COLORNAMES_rosybrown`
  rosybrown(122),

  /// `COLORNAMES_royalblue`
  royalblue(123),

  /// `COLORNAMES_saddlebrown`
  saddlebrown(124),

  /// `COLORNAMES_salmon`
  salmon(125),

  /// `COLORNAMES_sandybrown`
  sandybrown(126),

  /// `COLORNAMES_seagreen`
  seagreen(127),

  /// `COLORNAMES_seashell`
  seashell(128),

  /// `COLORNAMES_sienna`
  sienna(129),

  /// `COLORNAMES_silver`
  silver(130),

  /// `COLORNAMES_skyblue`
  skyblue(131),

  /// `COLORNAMES_slateblue`
  slateblue(132),

  /// `COLORNAMES_slategray`
  slategray(133),

  /// `COLORNAMES_slategrey`
  slategrey(134),

  /// `COLORNAMES_snow`
  snow(135),

  /// `COLORNAMES_springgreen`
  springgreen(136),

  /// `COLORNAMES_steelblue`
  steelblue(137),

  /// `COLORNAMES_tan`
  tan(138),

  /// `COLORNAMES_teal`
  teal(139),

  /// `COLORNAMES_thistle`
  thistle(140),

  /// `COLORNAMES_tomato`
  tomato(141),

  /// `COLORNAMES_turquoise`
  turquoise(142),

  /// `COLORNAMES_violet`
  violet(143),

  /// `COLORNAMES_wheat`
  wheat(144),

  /// `COLORNAMES_white`
  white(145),

  /// `COLORNAMES_whitesmoke`
  whitesmoke(146),

  /// `COLORNAMES_yellow`
  yellow(147),

  /// `COLORNAMES_yellowgreen`
  yellowgreen(148),
  ;

  const Colornames(this.value);

  final int value;

  static Colornames fromValue(int value) =>
      Colornames.values.firstWhere((e) => e.value == value,
          orElse: () => Colornames.values.first);
}

/// MEI `data_COMPASSDIRECTION`.
enum Compassdirection {
  /// `COMPASSDIRECTION_NONE`
  none(0),

  /// `COMPASSDIRECTION_n`
  n(1),

  /// `COMPASSDIRECTION_e`
  e(2),

  /// `COMPASSDIRECTION_s`
  s(3),

  /// `COMPASSDIRECTION_w`
  w(4),

  /// `COMPASSDIRECTION_ne`
  ne(5),

  /// `COMPASSDIRECTION_nw`
  nw(6),

  /// `COMPASSDIRECTION_se`
  se(7),

  /// `COMPASSDIRECTION_sw`
  sw(8),
  ;

  const Compassdirection(this.value);

  final int value;

  static Compassdirection fromValue(int value) =>
      Compassdirection.values.firstWhere((e) => e.value == value,
          orElse: () => Compassdirection.values.first);
}

/// MEI `data_COMPASSDIRECTION_basic`.
enum CompassdirectionBasic {
  /// `COMPASSDIRECTION_basic_NONE`
  none(0),

  /// `COMPASSDIRECTION_basic_n`
  n(1),

  /// `COMPASSDIRECTION_basic_e`
  e(2),

  /// `COMPASSDIRECTION_basic_s`
  s(3),

  /// `COMPASSDIRECTION_basic_w`
  w(4),
  ;

  const CompassdirectionBasic(this.value);

  final int value;

  static CompassdirectionBasic fromValue(int value) =>
      CompassdirectionBasic.values.firstWhere((e) => e.value == value,
          orElse: () => CompassdirectionBasic.values.first);
}

/// MEI `data_COMPASSDIRECTION_extended`.
enum CompassdirectionExtended {
  /// `COMPASSDIRECTION_extended_NONE`
  none(0),

  /// `COMPASSDIRECTION_extended_ne`
  ne(1),

  /// `COMPASSDIRECTION_extended_nw`
  nw(2),

  /// `COMPASSDIRECTION_extended_se`
  se(3),

  /// `COMPASSDIRECTION_extended_sw`
  sw(4),
  ;

  const CompassdirectionExtended(this.value);

  final int value;

  static CompassdirectionExtended fromValue(int value) =>
      CompassdirectionExtended.values.firstWhere((e) => e.value == value,
          orElse: () => CompassdirectionExtended.values.first);
}

/// MEI `data_COURSETUNING`.
enum Coursetuning {
  /// `COURSETUNING_NONE`
  none(0),

  /// `COURSETUNING_guitar_standard`
  guitarStandard(1),

  /// `COURSETUNING_guitar_drop_D`
  guitarDropD(2),

  /// `COURSETUNING_guitar_open_D`
  guitarOpenD(3),

  /// `COURSETUNING_guitar_open_G`
  guitarOpenG(4),

  /// `COURSETUNING_guitar_open_A`
  guitarOpenA(5),

  /// `COURSETUNING_lute_renaissance_6`
  luteRenaissance6(6),

  /// `COURSETUNING_lute_baroque_d_major`
  luteBaroqueDMajor(7),

  /// `COURSETUNING_lute_baroque_d_minor`
  luteBaroqueDMinor(8),
  ;

  const Coursetuning(this.value);

  final int value;

  static Coursetuning fromValue(int value) =>
      Coursetuning.values.firstWhere((e) => e.value == value,
          orElse: () => Coursetuning.values.first);
}

/// MEI `data_DIVISIO`.
enum Divisio {
  /// `DIVISIO_NONE`
  none(0),

  /// `DIVISIO_ternaria`
  ternaria(1),

  /// `DIVISIO_quaternaria`
  quaternaria(2),

  /// `DIVISIO_senariaimperf`
  senariaimperf(3),

  /// `DIVISIO_senariaperf`
  senariaperf(4),

  /// `DIVISIO_octonaria`
  octonaria(5),

  /// `DIVISIO_novenaria`
  novenaria(6),

  /// `DIVISIO_duodenaria`
  duodenaria(7),
  ;

  const Divisio(this.value);

  final int value;

  static Divisio fromValue(int value) => Divisio.values
      .firstWhere((e) => e.value == value, orElse: () => Divisio.values.first);
}

/// MEI `data_DURATIONRESTS_mensural`.
enum DurationrestsMensural {
  /// `DURATIONRESTS_mensural_NONE`
  none(0),

  /// `DURATIONRESTS_mensural_2B`
  n2b(1),

  /// `DURATIONRESTS_mensural_3B`
  n3b(2),

  /// `DURATIONRESTS_mensural_maxima`
  maxima(3),

  /// `DURATIONRESTS_mensural_longa`
  longa(4),

  /// `DURATIONRESTS_mensural_brevis`
  brevis(5),

  /// `DURATIONRESTS_mensural_semibrevis`
  semibrevis(6),

  /// `DURATIONRESTS_mensural_minima`
  minima(7),

  /// `DURATIONRESTS_mensural_semiminima`
  semiminima(8),

  /// `DURATIONRESTS_mensural_fusa`
  fusa(9),

  /// `DURATIONRESTS_mensural_semifusa`
  semifusa(10),
  ;

  const DurationrestsMensural(this.value);

  final int value;

  static DurationrestsMensural fromValue(int value) =>
      DurationrestsMensural.values.firstWhere((e) => e.value == value,
          orElse: () => DurationrestsMensural.values.first);
}

/// MEI `data_DURQUALITY_mensural`.
enum DurqualityMensural {
  /// `DURQUALITY_mensural_NONE`
  none(0),

  /// `DURQUALITY_mensural_perfecta`
  perfecta(1),

  /// `DURQUALITY_mensural_imperfecta`
  imperfecta(2),

  /// `DURQUALITY_mensural_altera`
  altera(3),

  /// `DURQUALITY_mensural_minor`
  minor(4),

  /// `DURQUALITY_mensural_maior`
  maior(5),

  /// `DURQUALITY_mensural_duplex`
  duplex(6),
  ;

  const DurqualityMensural(this.value);

  final int value;

  static DurqualityMensural fromValue(int value) =>
      DurqualityMensural.values.firstWhere((e) => e.value == value,
          orElse: () => DurqualityMensural.values.first);
}

/// MEI `data_ENCLOSURE`.
enum Enclosure {
  /// `ENCLOSURE_NONE`
  none(0),

  /// `ENCLOSURE_paren`
  paren(1),

  /// `ENCLOSURE_brack`
  brack(2),

  /// `ENCLOSURE_box`
  box(3),

  /// `ENCLOSURE_none`
  none0(4),
  ;

  const Enclosure(this.value);

  final int value;

  static Enclosure fromValue(int value) =>
      Enclosure.values.firstWhere((e) => e.value == value,
          orElse: () => Enclosure.values.first);
}

/// MEI `data_EVENTREL`.
enum Eventrel {
  /// `EVENTREL_NONE`
  none(0),

  /// `EVENTREL_above`
  above(1),

  /// `EVENTREL_below`
  below(2),

  /// `EVENTREL_left`
  left(3),

  /// `EVENTREL_right`
  right(4),

  /// `EVENTREL_above_left`
  aboveLeft(5),

  /// `EVENTREL_above_right`
  aboveRight(6),

  /// `EVENTREL_below_left`
  belowLeft(7),

  /// `EVENTREL_below_right`
  belowRight(8),
  ;

  const Eventrel(this.value);

  final int value;

  static Eventrel fromValue(int value) => Eventrel.values
      .firstWhere((e) => e.value == value, orElse: () => Eventrel.values.first);
}

/// MEI `data_EVENTREL_basic`.
enum EventrelBasic {
  /// `EVENTREL_basic_NONE`
  none(0),

  /// `EVENTREL_basic_above`
  above(1),

  /// `EVENTREL_basic_below`
  below(2),

  /// `EVENTREL_basic_left`
  left(3),

  /// `EVENTREL_basic_right`
  right(4),
  ;

  const EventrelBasic(this.value);

  final int value;

  static EventrelBasic fromValue(int value) =>
      EventrelBasic.values.firstWhere((e) => e.value == value,
          orElse: () => EventrelBasic.values.first);
}

/// MEI `data_EVENTREL_extended`.
enum EventrelExtended {
  /// `EVENTREL_extended_NONE`
  none(0),

  /// `EVENTREL_extended_above_left`
  aboveLeft(1),

  /// `EVENTREL_extended_above_right`
  aboveRight(2),

  /// `EVENTREL_extended_below_left`
  belowLeft(3),

  /// `EVENTREL_extended_below_right`
  belowRight(4),
  ;

  const EventrelExtended(this.value);

  final int value;

  static EventrelExtended fromValue(int value) =>
      EventrelExtended.values.firstWhere((e) => e.value == value,
          orElse: () => EventrelExtended.values.first);
}

/// MEI `data_FILL`.
enum Fill {
  /// `FILL_NONE`
  none(0),

  /// `FILL_void`
  voidValue(1),

  /// `FILL_solid`
  solid(2),

  /// `FILL_top`
  top(3),

  /// `FILL_bottom`
  bottom(4),

  /// `FILL_left`
  left(5),

  /// `FILL_right`
  right(6),
  ;

  const Fill(this.value);

  final int value;

  static Fill fromValue(int value) => Fill.values
      .firstWhere((e) => e.value == value, orElse: () => Fill.values.first);
}

/// MEI `data_FLAGFORM_mensural`.
enum FlagformMensural {
  /// `FLAGFORM_mensural_NONE`
  none(0),

  /// `FLAGFORM_mensural_straight`
  straight(1),

  /// `FLAGFORM_mensural_angled`
  angled(2),

  /// `FLAGFORM_mensural_curled`
  curled(3),

  /// `FLAGFORM_mensural_flared`
  flared(4),

  /// `FLAGFORM_mensural_extended`
  extended(5),

  /// `FLAGFORM_mensural_hooked`
  hooked(6),
  ;

  const FlagformMensural(this.value);

  final int value;

  static FlagformMensural fromValue(int value) =>
      FlagformMensural.values.firstWhere((e) => e.value == value,
          orElse: () => FlagformMensural.values.first);
}

/// MEI `data_FLAGPOS_mensural`.
enum FlagposMensural {
  /// `FLAGPOS_mensural_NONE`
  none(0),

  /// `FLAGPOS_mensural_left`
  left(1),

  /// `FLAGPOS_mensural_right`
  right(2),

  /// `FLAGPOS_mensural_center`
  center(3),
  ;

  const FlagposMensural(this.value);

  final int value;

  static FlagposMensural fromValue(int value) =>
      FlagposMensural.values.firstWhere((e) => e.value == value,
          orElse: () => FlagposMensural.values.first);
}

/// MEI `data_FONTSIZETERM`.
enum Fontsizeterm {
  /// `FONTSIZETERM_NONE`
  none(0),

  /// `FONTSIZETERM_xx_small`
  xxSmall(1),

  /// `FONTSIZETERM_x_small`
  xSmall(2),

  /// `FONTSIZETERM_small`
  small(3),

  /// `FONTSIZETERM_normal`
  normal(4),

  /// `FONTSIZETERM_large`
  large(5),

  /// `FONTSIZETERM_x_large`
  xLarge(6),

  /// `FONTSIZETERM_xx_large`
  xxLarge(7),

  /// `FONTSIZETERM_smaller`
  smaller(8),

  /// `FONTSIZETERM_larger`
  larger(9),
  ;

  const Fontsizeterm(this.value);

  final int value;

  static Fontsizeterm fromValue(int value) =>
      Fontsizeterm.values.firstWhere((e) => e.value == value,
          orElse: () => Fontsizeterm.values.first);
}

/// MEI `data_FONTSTYLE`.
enum Fontstyle {
  /// `FONTSTYLE_NONE`
  none(0),

  /// `FONTSTYLE_italic`
  italic(1),

  /// `FONTSTYLE_normal`
  normal(2),

  /// `FONTSTYLE_oblique`
  oblique(3),
  ;

  const Fontstyle(this.value);

  final int value;

  static Fontstyle fromValue(int value) =>
      Fontstyle.values.firstWhere((e) => e.value == value,
          orElse: () => Fontstyle.values.first);
}

/// MEI `data_FONTWEIGHT`.
enum Fontweight {
  /// `FONTWEIGHT_NONE`
  none(0),

  /// `FONTWEIGHT_bold`
  bold(1),

  /// `FONTWEIGHT_normal`
  normal(2),
  ;

  const Fontweight(this.value);

  final int value;

  static Fontweight fromValue(int value) =>
      Fontweight.values.firstWhere((e) => e.value == value,
          orElse: () => Fontweight.values.first);
}

/// MEI `data_FRBRRELATIONSHIP`.
enum Frbrrelationship {
  /// `FRBRRELATIONSHIP_NONE`
  none(0),

  /// `FRBRRELATIONSHIP_hasAbridgement`
  hasabridgement(1),

  /// `FRBRRELATIONSHIP_isAbridgementOf`
  isabridgementof(2),

  /// `FRBRRELATIONSHIP_hasAdaptation`
  hasadaptation(3),

  /// `FRBRRELATIONSHIP_isAdaptationOf`
  isadaptationof(4),

  /// `FRBRRELATIONSHIP_hasAlternate`
  hasalternate(5),

  /// `FRBRRELATIONSHIP_isAlternateOf`
  isalternateof(6),

  /// `FRBRRELATIONSHIP_hasArrangement`
  hasarrangement(7),

  /// `FRBRRELATIONSHIP_isArrangementOf`
  isarrangementof(8),

  /// `FRBRRELATIONSHIP_hasComplement`
  hascomplement(9),

  /// `FRBRRELATIONSHIP_isComplementOf`
  iscomplementof(10),

  /// `FRBRRELATIONSHIP_hasEmbodiment`
  hasembodiment(11),

  /// `FRBRRELATIONSHIP_isEmbodimentOf`
  isembodimentof(12),

  /// `FRBRRELATIONSHIP_hasExemplar`
  hasexemplar(13),

  /// `FRBRRELATIONSHIP_isExemplarOf`
  isexemplarof(14),

  /// `FRBRRELATIONSHIP_hasImitation`
  hasimitation(15),

  /// `FRBRRELATIONSHIP_isImitationOf`
  isimitationof(16),

  /// `FRBRRELATIONSHIP_hasPart`
  haspart(17),

  /// `FRBRRELATIONSHIP_isPartOf`
  ispartof(18),

  /// `FRBRRELATIONSHIP_hasRealization`
  hasrealization(19),

  /// `FRBRRELATIONSHIP_isRealizationOf`
  isrealizationof(20),

  /// `FRBRRELATIONSHIP_hasReconfiguration`
  hasreconfiguration(21),

  /// `FRBRRELATIONSHIP_isReconfigurationOf`
  isreconfigurationof(22),

  /// `FRBRRELATIONSHIP_hasReproduction`
  hasreproduction(23),

  /// `FRBRRELATIONSHIP_isReproductionOf`
  isreproductionof(24),

  /// `FRBRRELATIONSHIP_hasRevision`
  hasrevision(25),

  /// `FRBRRELATIONSHIP_isRevisionOf`
  isrevisionof(26),

  /// `FRBRRELATIONSHIP_hasSuccessor`
  hassuccessor(27),

  /// `FRBRRELATIONSHIP_isSuccessorOf`
  issuccessorof(28),

  /// `FRBRRELATIONSHIP_hasSummarization`
  hassummarization(29),

  /// `FRBRRELATIONSHIP_isSummarizationOf`
  issummarizationof(30),

  /// `FRBRRELATIONSHIP_hasSupplement`
  hassupplement(31),

  /// `FRBRRELATIONSHIP_isSupplementOf`
  issupplementof(32),

  /// `FRBRRELATIONSHIP_hasTransformation`
  hastransformation(33),

  /// `FRBRRELATIONSHIP_isTransformationOf`
  istransformationof(34),

  /// `FRBRRELATIONSHIP_hasTranslation`
  hastranslation(35),

  /// `FRBRRELATIONSHIP_isTranslationOf`
  istranslationof(36),
  ;

  const Frbrrelationship(this.value);

  final int value;

  static Frbrrelationship fromValue(int value) =>
      Frbrrelationship.values.firstWhere((e) => e.value == value,
          orElse: () => Frbrrelationship.values.first);
}

/// MEI `data_GLISSANDO`.
enum Glissando {
  /// `GLISSANDO_NONE`
  none(0),

  /// `GLISSANDO_i`
  i(1),

  /// `GLISSANDO_m`
  m(2),

  /// `GLISSANDO_t`
  t(3),
  ;

  const Glissando(this.value);

  final int value;

  static Glissando fromValue(int value) =>
      Glissando.values.firstWhere((e) => e.value == value,
          orElse: () => Glissando.values.first);
}

/// MEI `data_GRACE`.
enum Grace {
  /// `GRACE_NONE`
  none(0),

  /// `GRACE_acc`
  acc(1),

  /// `GRACE_unacc`
  unacc(2),

  /// `GRACE_unknown`
  unknown(3),
  ;

  const Grace(this.value);

  final int value;

  static Grace fromValue(int value) => Grace.values
      .firstWhere((e) => e.value == value, orElse: () => Grace.values.first);
}

/// MEI `data_HARPPEDALPOSITION`.
enum Harppedalposition {
  /// `HARPPEDALPOSITION_NONE`
  none(0),

  /// `HARPPEDALPOSITION_f`
  f(1),

  /// `HARPPEDALPOSITION_n`
  n(2),

  /// `HARPPEDALPOSITION_s`
  s(3),
  ;

  const Harppedalposition(this.value);

  final int value;

  static Harppedalposition fromValue(int value) =>
      Harppedalposition.values.firstWhere((e) => e.value == value,
          orElse: () => Harppedalposition.values.first);
}

/// MEI `data_HEADSHAPE_list`.
enum HeadshapeList {
  /// `HEADSHAPE_list_NONE`
  none(0),

  /// `HEADSHAPE_list_quarter`
  quarter(1),

  /// `HEADSHAPE_list_half`
  half(2),

  /// `HEADSHAPE_list_whole`
  whole(3),

  /// `HEADSHAPE_list_backslash`
  backslash(4),

  /// `HEADSHAPE_list_circle`
  circle(5),

  /// `HEADSHAPE_list_plus`
  plus(6),

  /// `HEADSHAPE_list_diamond`
  diamond(7),

  /// `HEADSHAPE_list_isotriangle`
  isotriangle(8),

  /// `HEADSHAPE_list_oval`
  oval(9),

  /// `HEADSHAPE_list_piewedge`
  piewedge(10),

  /// `HEADSHAPE_list_rectangle`
  rectangle(11),

  /// `HEADSHAPE_list_rtriangle`
  rtriangle(12),

  /// `HEADSHAPE_list_semicircle`
  semicircle(13),

  /// `HEADSHAPE_list_slash`
  slash(14),

  /// `HEADSHAPE_list_square`
  square(15),

  /// `HEADSHAPE_list_x`
  x(16),
  ;

  const HeadshapeList(this.value);

  final int value;

  static HeadshapeList fromValue(int value) =>
      HeadshapeList.values.firstWhere((e) => e.value == value,
          orElse: () => HeadshapeList.values.first);
}

/// MEI `data_HORIZONTALALIGNMENT`.
enum Horizontalalignment {
  /// `HORIZONTALALIGNMENT_NONE`
  none(0),

  /// `HORIZONTALALIGNMENT_left`
  left(1),

  /// `HORIZONTALALIGNMENT_right`
  right(2),

  /// `HORIZONTALALIGNMENT_center`
  center(3),

  /// `HORIZONTALALIGNMENT_justify`
  justify(4),
  ;

  const Horizontalalignment(this.value);

  final int value;

  static Horizontalalignment fromValue(int value) =>
      Horizontalalignment.values.firstWhere((e) => e.value == value,
          orElse: () => Horizontalalignment.values.first);
}

/// MEI `data_LAYERSCHEME`.
enum Layerscheme {
  /// `LAYERSCHEME_NONE`
  none(0),

  /// `LAYERSCHEME_1`
  n1(1),

  /// `LAYERSCHEME_2o`
  n2o(2),

  /// `LAYERSCHEME_2f`
  n2f(3),

  /// `LAYERSCHEME_3o`
  n3o(4),

  /// `LAYERSCHEME_3f`
  n3f(5),
  ;

  const Layerscheme(this.value);

  final int value;

  static Layerscheme fromValue(int value) =>
      Layerscheme.values.firstWhere((e) => e.value == value,
          orElse: () => Layerscheme.values.first);
}

/// MEI `data_LIGATUREFORM`.
enum Ligatureform {
  /// `LIGATUREFORM_NONE`
  none(0),

  /// `LIGATUREFORM_recta`
  recta(1),

  /// `LIGATUREFORM_obliqua`
  obliqua(2),
  ;

  const Ligatureform(this.value);

  final int value;

  static Ligatureform fromValue(int value) =>
      Ligatureform.values.firstWhere((e) => e.value == value,
          orElse: () => Ligatureform.values.first);
}

/// MEI `data_LINEFORM`.
enum Lineform {
  /// `LINEFORM_NONE`
  none(0),

  /// `LINEFORM_dashed`
  dashed(1),

  /// `LINEFORM_dotted`
  dotted(2),

  /// `LINEFORM_solid`
  solid(3),

  /// `LINEFORM_wavy`
  wavy(4),
  ;

  const Lineform(this.value);

  final int value;

  static Lineform fromValue(int value) => Lineform.values
      .firstWhere((e) => e.value == value, orElse: () => Lineform.values.first);
}

/// MEI `data_LINESTARTENDSYMBOL`.
enum Linestartendsymbol {
  /// `LINESTARTENDSYMBOL_NONE`
  none(0),

  /// `LINESTARTENDSYMBOL_angledown`
  angledown(1),

  /// `LINESTARTENDSYMBOL_angleup`
  angleup(2),

  /// `LINESTARTENDSYMBOL_angleright`
  angleright(3),

  /// `LINESTARTENDSYMBOL_angleleft`
  angleleft(4),

  /// `LINESTARTENDSYMBOL_arrow`
  arrow(5),

  /// `LINESTARTENDSYMBOL_arrowopen`
  arrowopen(6),

  /// `LINESTARTENDSYMBOL_arrowwhite`
  arrowwhite(7),

  /// `LINESTARTENDSYMBOL_harpoonleft`
  harpoonleft(8),

  /// `LINESTARTENDSYMBOL_harpoonright`
  harpoonright(9),

  /// `LINESTARTENDSYMBOL_H`
  h(10),

  /// `LINESTARTENDSYMBOL_N`
  n(11),

  /// `LINESTARTENDSYMBOL_Th`
  th(12),

  /// `LINESTARTENDSYMBOL_ThRetro`
  thretro(13),

  /// `LINESTARTENDSYMBOL_ThRetroInv`
  thretroinv(14),

  /// `LINESTARTENDSYMBOL_ThInv`
  thinv(15),

  /// `LINESTARTENDSYMBOL_T`
  t(16),

  /// `LINESTARTENDSYMBOL_TInv`
  tinv(17),

  /// `LINESTARTENDSYMBOL_CH`
  ch(18),

  /// `LINESTARTENDSYMBOL_RH`
  rh(19),

  /// `LINESTARTENDSYMBOL_none`
  none0(20),
  ;

  const Linestartendsymbol(this.value);

  final int value;

  static Linestartendsymbol fromValue(int value) =>
      Linestartendsymbol.values.firstWhere((e) => e.value == value,
          orElse: () => Linestartendsymbol.values.first);
}

/// MEI `data_LINEWIDTHTERM`.
enum Linewidthterm {
  /// `LINEWIDTHTERM_NONE`
  none(0),

  /// `LINEWIDTHTERM_narrow`
  narrow(1),

  /// `LINEWIDTHTERM_medium`
  medium(2),

  /// `LINEWIDTHTERM_wide`
  wide(3),
  ;

  const Linewidthterm(this.value);

  final int value;

  static Linewidthterm fromValue(int value) =>
      Linewidthterm.values.firstWhere((e) => e.value == value,
          orElse: () => Linewidthterm.values.first);
}

/// MEI `data_MARCRELATORS_basic`.
enum MarcrelatorsBasic {
  /// `MARCRELATORS_basic_NONE`
  none(0),

  /// `MARCRELATORS_basic_arr`
  arr(1),

  /// `MARCRELATORS_basic_aut`
  aut(2),

  /// `MARCRELATORS_basic_cmp`
  cmp(3),

  /// `MARCRELATORS_basic_dte`
  dte(4),

  /// `MARCRELATORS_basic_edt`
  edt(5),

  /// `MARCRELATORS_basic_lbt`
  lbt(6),

  /// `MARCRELATORS_basic_lyr`
  lyr(7),
  ;

  const MarcrelatorsBasic(this.value);

  final int value;

  static MarcrelatorsBasic fromValue(int value) =>
      MarcrelatorsBasic.values.firstWhere((e) => e.value == value,
          orElse: () => MarcrelatorsBasic.values.first);
}

/// MEI `data_MARCRELATORS_extended`.
enum MarcrelatorsExtended {
  /// `MARCRELATORS_extended_NONE`
  none(0),

  /// `MARCRELATORS_extended_act`
  act(1),

  /// `MARCRELATORS_extended_ard`
  ard(2),

  /// `MARCRELATORS_extended_art`
  art(3),

  /// `MARCRELATORS_extended_aus`
  aus(4),

  /// `MARCRELATORS_extended_chr`
  chr(5),

  /// `MARCRELATORS_extended_cnd`
  cnd(6),

  /// `MARCRELATORS_extended_crp`
  crp(7),

  /// `MARCRELATORS_extended_cst`
  cst(8),

  /// `MARCRELATORS_extended_drt`
  drt(9),

  /// `MARCRELATORS_extended_egr`
  egr(10),

  /// `MARCRELATORS_extended_flm`
  flm(11),

  /// `MARCRELATORS_extended_fmd`
  fmd(12),

  /// `MARCRELATORS_extended_fmp`
  fmp(13),

  /// `MARCRELATORS_extended_itr`
  itr(14),

  /// `MARCRELATORS_extended_mcp`
  mcp(15),

  /// `MARCRELATORS_extended_mus`
  mus(16),

  /// `MARCRELATORS_extended_msd`
  msd(17),

  /// `MARCRELATORS_extended_pdr`
  pdr(18),

  /// `MARCRELATORS_extended_pmn`
  pmn(19),

  /// `MARCRELATORS_extended_prn`
  prn(20),

  /// `MARCRELATORS_extended_pro`
  pro(21),

  /// `MARCRELATORS_extended_rce`
  rce(22),

  /// `MARCRELATORS_extended_scr`
  scr(23),

  /// `MARCRELATORS_extended_sng`
  sng(24),

  /// `MARCRELATORS_extended_std`
  std(25),

  /// `MARCRELATORS_extended_trc`
  trc(26),

  /// `MARCRELATORS_extended_trl`
  trl(27),
  ;

  const MarcrelatorsExtended(this.value);

  final int value;

  static MarcrelatorsExtended fromValue(int value) =>
      MarcrelatorsExtended.values.firstWhere((e) => e.value == value,
          orElse: () => MarcrelatorsExtended.values.first);
}

/// MEI `data_MELODICFUNCTION`.
enum Melodicfunction {
  /// `MELODICFUNCTION_NONE`
  none(0),

  /// `MELODICFUNCTION_aln`
  aln(1),

  /// `MELODICFUNCTION_ant`
  ant(2),

  /// `MELODICFUNCTION_app`
  app(3),

  /// `MELODICFUNCTION_apt`
  apt(4),

  /// `MELODICFUNCTION_arp`
  arp(5),

  /// `MELODICFUNCTION_arp7`
  arp7(6),

  /// `MELODICFUNCTION_aun`
  aun(7),

  /// `MELODICFUNCTION_chg`
  chg(8),

  /// `MELODICFUNCTION_cln`
  cln(9),

  /// `MELODICFUNCTION_ct`
  ct(10),

  /// `MELODICFUNCTION_ct7`
  ct7(11),

  /// `MELODICFUNCTION_cun`
  cun(12),

  /// `MELODICFUNCTION_cup`
  cup(13),

  /// `MELODICFUNCTION_et`
  et(14),

  /// `MELODICFUNCTION_ln`
  ln(15),

  /// `MELODICFUNCTION_ped`
  ped(16),

  /// `MELODICFUNCTION_rep`
  rep(17),

  /// `MELODICFUNCTION_ret`
  ret(18),

  /// `MELODICFUNCTION_23ret`
  n23ret(19),

  /// `MELODICFUNCTION_78ret`
  n78ret(20),

  /// `MELODICFUNCTION_sus`
  sus(21),

  /// `MELODICFUNCTION_43sus`
  n43sus(22),

  /// `MELODICFUNCTION_98sus`
  n98sus(23),

  /// `MELODICFUNCTION_76sus`
  n76sus(24),

  /// `MELODICFUNCTION_un`
  un(25),

  /// `MELODICFUNCTION_un7`
  un7(26),

  /// `MELODICFUNCTION_upt`
  upt(27),

  /// `MELODICFUNCTION_upt7`
  upt7(28),
  ;

  const Melodicfunction(this.value);

  final int value;

  static Melodicfunction fromValue(int value) =>
      Melodicfunction.values.firstWhere((e) => e.value == value,
          orElse: () => Melodicfunction.values.first);
}

/// MEI `data_MENSURATIONSIGN`.
enum Mensurationsign {
  /// `MENSURATIONSIGN_NONE`
  none(0),

  /// `MENSURATIONSIGN_C`
  c(1),

  /// `MENSURATIONSIGN_O`
  o(2),

  /// `MENSURATIONSIGN_t`
  t(3),

  /// `MENSURATIONSIGN_q`
  q(4),

  /// `MENSURATIONSIGN_si`
  si(5),

  /// `MENSURATIONSIGN_i`
  i(6),

  /// `MENSURATIONSIGN_sg`
  sg(7),

  /// `MENSURATIONSIGN_g`
  g(8),

  /// `MENSURATIONSIGN_sp`
  sp(9),

  /// `MENSURATIONSIGN_p`
  p(10),

  /// `MENSURATIONSIGN_sy`
  sy(11),

  /// `MENSURATIONSIGN_y`
  y(12),

  /// `MENSURATIONSIGN_n`
  n(13),

  /// `MENSURATIONSIGN_oc`
  oc(14),

  /// `MENSURATIONSIGN_d`
  d(15),
  ;

  const Mensurationsign(this.value);

  final int value;

  static Mensurationsign fromValue(int value) =>
      Mensurationsign.values.firstWhere((e) => e.value == value,
          orElse: () => Mensurationsign.values.first);
}

/// MEI `data_METERFORM`.
enum Meterform {
  /// `METERFORM_NONE`
  none(0),

  /// `METERFORM_num`
  num(1),

  /// `METERFORM_denomsym`
  denomsym(2),

  /// `METERFORM_norm`
  norm(3),

  /// `METERFORM_symplusnorm`
  symplusnorm(4),
  ;

  const Meterform(this.value);

  final int value;

  static Meterform fromValue(int value) =>
      Meterform.values.firstWhere((e) => e.value == value,
          orElse: () => Meterform.values.first);
}

/// MEI `data_METERSIGN`.
enum Metersign {
  /// `METERSIGN_NONE`
  none(0),

  /// `METERSIGN_common`
  common(1),

  /// `METERSIGN_cut`
  cut(2),

  /// `METERSIGN_open`
  open(3),
  ;

  const Metersign(this.value);

  final int value;

  static Metersign fromValue(int value) =>
      Metersign.values.firstWhere((e) => e.value == value,
          orElse: () => Metersign.values.first);
}

/// MEI `data_MIDINAMES`.
enum Midinames {
  /// `MIDINAMES_NONE`
  none(0),

  /// `MIDINAMES_Acoustic_Grand_Piano`
  acousticGrandPiano(1),

  /// `MIDINAMES_Bright_Acoustic_Piano`
  brightAcousticPiano(2),

  /// `MIDINAMES_Electric_Grand_Piano`
  electricGrandPiano(3),

  /// `MIDINAMES_Honky_tonk_Piano`
  honkyTonkPiano(4),

  /// `MIDINAMES_Electric_Piano_1`
  electricPiano1(5),

  /// `MIDINAMES_Electric_Piano_2`
  electricPiano2(6),

  /// `MIDINAMES_Harpsichord`
  harpsichord(7),

  /// `MIDINAMES_Clavi`
  clavi(8),

  /// `MIDINAMES_Celesta`
  celesta(9),

  /// `MIDINAMES_Glockenspiel`
  glockenspiel(10),

  /// `MIDINAMES_Music_Box`
  musicBox(11),

  /// `MIDINAMES_Vibraphone`
  vibraphone(12),

  /// `MIDINAMES_Marimba`
  marimba(13),

  /// `MIDINAMES_Xylophone`
  xylophone(14),

  /// `MIDINAMES_Tubular_Bells`
  tubularBells(15),

  /// `MIDINAMES_Dulcimer`
  dulcimer(16),

  /// `MIDINAMES_Drawbar_Organ`
  drawbarOrgan(17),

  /// `MIDINAMES_Percussive_Organ`
  percussiveOrgan(18),

  /// `MIDINAMES_Rock_Organ`
  rockOrgan(19),

  /// `MIDINAMES_Church_Organ`
  churchOrgan(20),

  /// `MIDINAMES_Reed_Organ`
  reedOrgan(21),

  /// `MIDINAMES_Accordion`
  accordion(22),

  /// `MIDINAMES_Harmonica`
  harmonica(23),

  /// `MIDINAMES_Tango_Accordion`
  tangoAccordion(24),

  /// `MIDINAMES_Acoustic_Guitar_nylon`
  acousticGuitarNylon(25),

  /// `MIDINAMES_Acoustic_Guitar_steel`
  acousticGuitarSteel(26),

  /// `MIDINAMES_Electric_Guitar_jazz`
  electricGuitarJazz(27),

  /// `MIDINAMES_Electric_Guitar_clean`
  electricGuitarClean(28),

  /// `MIDINAMES_Electric_Guitar_muted`
  electricGuitarMuted(29),

  /// `MIDINAMES_Overdriven_Guitar`
  overdrivenGuitar(30),

  /// `MIDINAMES_Distortion_Guitar`
  distortionGuitar(31),

  /// `MIDINAMES_Guitar_harmonics`
  guitarHarmonics(32),

  /// `MIDINAMES_Acoustic_Bass`
  acousticBass(33),

  /// `MIDINAMES_Electric_Bass_finger`
  electricBassFinger(34),

  /// `MIDINAMES_Electric_Bass_pick`
  electricBassPick(35),

  /// `MIDINAMES_Fretless_Bass`
  fretlessBass(36),

  /// `MIDINAMES_Slap_Bass_1`
  slapBass1(37),

  /// `MIDINAMES_Slap_Bass_2`
  slapBass2(38),

  /// `MIDINAMES_Synth_Bass_1`
  synthBass1(39),

  /// `MIDINAMES_Synth_Bass_2`
  synthBass2(40),

  /// `MIDINAMES_Violin`
  violin(41),

  /// `MIDINAMES_Viola`
  viola(42),

  /// `MIDINAMES_Cello`
  cello(43),

  /// `MIDINAMES_Contrabass`
  contrabass(44),

  /// `MIDINAMES_Tremolo_Strings`
  tremoloStrings(45),

  /// `MIDINAMES_Pizzicato_Strings`
  pizzicatoStrings(46),

  /// `MIDINAMES_Orchestral_Harp`
  orchestralHarp(47),

  /// `MIDINAMES_Timpani`
  timpani(48),

  /// `MIDINAMES_String_Ensemble_1`
  stringEnsemble1(49),

  /// `MIDINAMES_String_Ensemble_2`
  stringEnsemble2(50),

  /// `MIDINAMES_SynthStrings_1`
  synthstrings1(51),

  /// `MIDINAMES_SynthStrings_2`
  synthstrings2(52),

  /// `MIDINAMES_Choir_Aahs`
  choirAahs(53),

  /// `MIDINAMES_Voice_Oohs`
  voiceOohs(54),

  /// `MIDINAMES_Synth_Voice`
  synthVoice(55),

  /// `MIDINAMES_Orchestra_Hit`
  orchestraHit(56),

  /// `MIDINAMES_Trumpet`
  trumpet(57),

  /// `MIDINAMES_Trombone`
  trombone(58),

  /// `MIDINAMES_Tuba`
  tuba(59),

  /// `MIDINAMES_Muted_Trumpet`
  mutedTrumpet(60),

  /// `MIDINAMES_French_Horn`
  frenchHorn(61),

  /// `MIDINAMES_Brass_Section`
  brassSection(62),

  /// `MIDINAMES_SynthBrass_1`
  synthbrass1(63),

  /// `MIDINAMES_SynthBrass_2`
  synthbrass2(64),

  /// `MIDINAMES_Soprano_Sax`
  sopranoSax(65),

  /// `MIDINAMES_Alto_Sax`
  altoSax(66),

  /// `MIDINAMES_Tenor_Sax`
  tenorSax(67),

  /// `MIDINAMES_Baritone_Sax`
  baritoneSax(68),

  /// `MIDINAMES_Oboe`
  oboe(69),

  /// `MIDINAMES_English_Horn`
  englishHorn(70),

  /// `MIDINAMES_Bassoon`
  bassoon(71),

  /// `MIDINAMES_Clarinet`
  clarinet(72),

  /// `MIDINAMES_Piccolo`
  piccolo(73),

  /// `MIDINAMES_Flute`
  flute(74),

  /// `MIDINAMES_Recorder`
  recorder(75),

  /// `MIDINAMES_Pan_Flute`
  panFlute(76),

  /// `MIDINAMES_Blown_Bottle`
  blownBottle(77),

  /// `MIDINAMES_Shakuhachi`
  shakuhachi(78),

  /// `MIDINAMES_Whistle`
  whistle(79),

  /// `MIDINAMES_Ocarina`
  ocarina(80),

  /// `MIDINAMES_Lead_1_square`
  lead1Square(81),

  /// `MIDINAMES_Lead_2_sawtooth`
  lead2Sawtooth(82),

  /// `MIDINAMES_Lead_3_calliope`
  lead3Calliope(83),

  /// `MIDINAMES_Lead_4_chiff`
  lead4Chiff(84),

  /// `MIDINAMES_Lead_5_charang`
  lead5Charang(85),

  /// `MIDINAMES_Lead_6_voice`
  lead6Voice(86),

  /// `MIDINAMES_Lead_7_fifths`
  lead7Fifths(87),

  /// `MIDINAMES_Lead_8_bass_and_lead`
  lead8BassAndLead(88),

  /// `MIDINAMES_Pad_1_new_age`
  pad1NewAge(89),

  /// `MIDINAMES_Pad_2_warm`
  pad2Warm(90),

  /// `MIDINAMES_Pad_3_polysynth`
  pad3Polysynth(91),

  /// `MIDINAMES_Pad_4_choir`
  pad4Choir(92),

  /// `MIDINAMES_Pad_5_bowed`
  pad5Bowed(93),

  /// `MIDINAMES_Pad_6_metallic`
  pad6Metallic(94),

  /// `MIDINAMES_Pad_7_halo`
  pad7Halo(95),

  /// `MIDINAMES_Pad_8_sweep`
  pad8Sweep(96),

  /// `MIDINAMES_FX_1_rain`
  fx1Rain(97),

  /// `MIDINAMES_FX_2_soundtrack`
  fx2Soundtrack(98),

  /// `MIDINAMES_FX_3_crystal`
  fx3Crystal(99),

  /// `MIDINAMES_FX_4_atmosphere`
  fx4Atmosphere(100),

  /// `MIDINAMES_FX_5_brightness`
  fx5Brightness(101),

  /// `MIDINAMES_FX_6_goblins`
  fx6Goblins(102),

  /// `MIDINAMES_FX_7_echoes`
  fx7Echoes(103),

  /// `MIDINAMES_FX_8_sci_fi`
  fx8SciFi(104),

  /// `MIDINAMES_Sitar`
  sitar(105),

  /// `MIDINAMES_Banjo`
  banjo(106),

  /// `MIDINAMES_Shamisen`
  shamisen(107),

  /// `MIDINAMES_Koto`
  koto(108),

  /// `MIDINAMES_Kalimba`
  kalimba(109),

  /// `MIDINAMES_Bag_pipe`
  bagPipe(110),

  /// `MIDINAMES_Fiddle`
  fiddle(111),

  /// `MIDINAMES_Shanai`
  shanai(112),

  /// `MIDINAMES_Tinkle_Bell`
  tinkleBell(113),

  /// `MIDINAMES_Agogo`
  agogo(114),

  /// `MIDINAMES_Steel_Drums`
  steelDrums(115),

  /// `MIDINAMES_Woodblock`
  woodblock(116),

  /// `MIDINAMES_Taiko_Drum`
  taikoDrum(117),

  /// `MIDINAMES_Melodic_Tom`
  melodicTom(118),

  /// `MIDINAMES_Synth_Drum`
  synthDrum(119),

  /// `MIDINAMES_Reverse_Cymbal`
  reverseCymbal(120),

  /// `MIDINAMES_Guitar_Fret_Noise`
  guitarFretNoise(121),

  /// `MIDINAMES_Breath_Noise`
  breathNoise(122),

  /// `MIDINAMES_Seashore`
  seashore(123),

  /// `MIDINAMES_Bird_Tweet`
  birdTweet(124),

  /// `MIDINAMES_Telephone_Ring`
  telephoneRing(125),

  /// `MIDINAMES_Helicopter`
  helicopter(126),

  /// `MIDINAMES_Applause`
  applause(127),

  /// `MIDINAMES_Gunshot`
  gunshot(128),

  /// `MIDINAMES_Acoustic_Bass_Drum`
  acousticBassDrum(129),

  /// `MIDINAMES_Bass_Drum_1`
  bassDrum1(130),

  /// `MIDINAMES_Side_Stick`
  sideStick(131),

  /// `MIDINAMES_Acoustic_Snare`
  acousticSnare(132),

  /// `MIDINAMES_Hand_Clap`
  handClap(133),

  /// `MIDINAMES_Electric_Snare`
  electricSnare(134),

  /// `MIDINAMES_Low_Floor_Tom`
  lowFloorTom(135),

  /// `MIDINAMES_Closed_Hi_Hat`
  closedHiHat(136),

  /// `MIDINAMES_High_Floor_Tom`
  highFloorTom(137),

  /// `MIDINAMES_Pedal_Hi_Hat`
  pedalHiHat(138),

  /// `MIDINAMES_Low_Tom`
  lowTom(139),

  /// `MIDINAMES_Open_Hi_Hat`
  openHiHat(140),

  /// `MIDINAMES_Low_Mid_Tom`
  lowMidTom(141),

  /// `MIDINAMES_Hi_Mid_Tom`
  hiMidTom(142),

  /// `MIDINAMES_Crash_Cymbal_1`
  crashCymbal1(143),

  /// `MIDINAMES_High_Tom`
  highTom(144),

  /// `MIDINAMES_Ride_Cymbal_1`
  rideCymbal1(145),

  /// `MIDINAMES_Chinese_Cymbal`
  chineseCymbal(146),

  /// `MIDINAMES_Ride_Bell`
  rideBell(147),

  /// `MIDINAMES_Tambourine`
  tambourine(148),

  /// `MIDINAMES_Splash_Cymbal`
  splashCymbal(149),

  /// `MIDINAMES_Cowbell`
  cowbell(150),

  /// `MIDINAMES_Crash_Cymbal_2`
  crashCymbal2(151),

  /// `MIDINAMES_Vibraslap`
  vibraslap(152),

  /// `MIDINAMES_Ride_Cymbal_2`
  rideCymbal2(153),

  /// `MIDINAMES_Hi_Bongo`
  hiBongo(154),

  /// `MIDINAMES_Low_Bongo`
  lowBongo(155),

  /// `MIDINAMES_Mute_Hi_Conga`
  muteHiConga(156),

  /// `MIDINAMES_Open_Hi_Conga`
  openHiConga(157),

  /// `MIDINAMES_Low_Conga`
  lowConga(158),

  /// `MIDINAMES_High_Timbale`
  highTimbale(159),

  /// `MIDINAMES_Low_Timbale`
  lowTimbale(160),

  /// `MIDINAMES_High_Agogo`
  highAgogo(161),

  /// `MIDINAMES_Low_Agogo`
  lowAgogo(162),

  /// `MIDINAMES_Cabasa`
  cabasa(163),

  /// `MIDINAMES_Maracas`
  maracas(164),

  /// `MIDINAMES_Short_Whistle`
  shortWhistle(165),

  /// `MIDINAMES_Long_Whistle`
  longWhistle(166),

  /// `MIDINAMES_Short_Guiro`
  shortGuiro(167),

  /// `MIDINAMES_Long_Guiro`
  longGuiro(168),

  /// `MIDINAMES_Claves`
  claves(169),

  /// `MIDINAMES_Hi_Wood_Block`
  hiWoodBlock(170),

  /// `MIDINAMES_Low_Wood_Block`
  lowWoodBlock(171),

  /// `MIDINAMES_Mute_Cuica`
  muteCuica(172),

  /// `MIDINAMES_Open_Cuica`
  openCuica(173),

  /// `MIDINAMES_Mute_Triangle`
  muteTriangle(174),

  /// `MIDINAMES_Open_Triangle`
  openTriangle(175),
  ;

  const Midinames(this.value);

  final int value;

  static Midinames fromValue(int value) =>
      Midinames.values.firstWhere((e) => e.value == value,
          orElse: () => Midinames.values.first);
}

/// MEI `data_MODE`.
enum Mode {
  /// `MODE_NONE`
  none(0),

  /// `MODE_major`
  major(1),

  /// `MODE_minor`
  minor(2),

  /// `MODE_dorian`
  dorian(3),

  /// `MODE_hypodorian`
  hypodorian(4),

  /// `MODE_phrygian`
  phrygian(5),

  /// `MODE_hypophrygian`
  hypophrygian(6),

  /// `MODE_lydian`
  lydian(7),

  /// `MODE_hypolydian`
  hypolydian(8),

  /// `MODE_mixolydian`
  mixolydian(9),

  /// `MODE_hypomixolydian`
  hypomixolydian(10),

  /// `MODE_peregrinus`
  peregrinus(11),

  /// `MODE_ionian`
  ionian(12),

  /// `MODE_hypoionian`
  hypoionian(13),

  /// `MODE_aeolian`
  aeolian(14),

  /// `MODE_hypoaeolian`
  hypoaeolian(15),

  /// `MODE_locrian`
  locrian(16),

  /// `MODE_hypolocrian`
  hypolocrian(17),
  ;

  const Mode(this.value);

  final int value;

  static Mode fromValue(int value) => Mode.values
      .firstWhere((e) => e.value == value, orElse: () => Mode.values.first);
}

/// MEI `data_MODE_cmn`.
enum ModeCmn {
  /// `MODE_cmn_NONE`
  none(0),

  /// `MODE_cmn_major`
  major(1),

  /// `MODE_cmn_minor`
  minor(2),
  ;

  const ModeCmn(this.value);

  final int value;

  static ModeCmn fromValue(int value) => ModeCmn.values
      .firstWhere((e) => e.value == value, orElse: () => ModeCmn.values.first);
}

/// MEI `data_MODE_extended`.
enum ModeExtended {
  /// `MODE_extended_NONE`
  none(0),

  /// `MODE_extended_ionian`
  ionian(1),

  /// `MODE_extended_hypoionian`
  hypoionian(2),

  /// `MODE_extended_aeolian`
  aeolian(3),

  /// `MODE_extended_hypoaeolian`
  hypoaeolian(4),

  /// `MODE_extended_locrian`
  locrian(5),

  /// `MODE_extended_hypolocrian`
  hypolocrian(6),
  ;

  const ModeExtended(this.value);

  final int value;

  static ModeExtended fromValue(int value) =>
      ModeExtended.values.firstWhere((e) => e.value == value,
          orElse: () => ModeExtended.values.first);
}

/// MEI `data_MODE_gregorian`.
enum ModeGregorian {
  /// `MODE_gregorian_NONE`
  none(0),

  /// `MODE_gregorian_dorian`
  dorian(1),

  /// `MODE_gregorian_hypodorian`
  hypodorian(2),

  /// `MODE_gregorian_phrygian`
  phrygian(3),

  /// `MODE_gregorian_hypophrygian`
  hypophrygian(4),

  /// `MODE_gregorian_lydian`
  lydian(5),

  /// `MODE_gregorian_hypolydian`
  hypolydian(6),

  /// `MODE_gregorian_mixolydian`
  mixolydian(7),

  /// `MODE_gregorian_hypomixolydian`
  hypomixolydian(8),

  /// `MODE_gregorian_peregrinus`
  peregrinus(9),
  ;

  const ModeGregorian(this.value);

  final int value;

  static ModeGregorian fromValue(int value) =>
      ModeGregorian.values.firstWhere((e) => e.value == value,
          orElse: () => ModeGregorian.values.first);
}

/// MEI `data_MODSRELATIONSHIP`.
enum Modsrelationship {
  /// `MODSRELATIONSHIP_NONE`
  none(0),

  /// `MODSRELATIONSHIP_preceding`
  preceding(1),

  /// `MODSRELATIONSHIP_succeeding`
  succeeding(2),

  /// `MODSRELATIONSHIP_original`
  original(3),

  /// `MODSRELATIONSHIP_host`
  host(4),

  /// `MODSRELATIONSHIP_constituent`
  constituent(5),

  /// `MODSRELATIONSHIP_otherVersion`
  otherversion(6),

  /// `MODSRELATIONSHIP_otherFormat`
  otherformat(7),

  /// `MODSRELATIONSHIP_isReferencedBy`
  isreferencedby(8),

  /// `MODSRELATIONSHIP_references`
  references(9),
  ;

  const Modsrelationship(this.value);

  final int value;

  static Modsrelationship fromValue(int value) =>
      Modsrelationship.values.firstWhere((e) => e.value == value,
          orElse: () => Modsrelationship.values.first);
}

/// MEI `data_MODUSMAIOR`.
enum Modusmaior {
  /// `MODUSMAIOR_NONE`
  none(-3),

  /// `MODUSMAIOR_2`
  n2(2),

  /// `MODUSMAIOR_3`
  n3(3),
  ;

  const Modusmaior(this.value);

  final int value;

  static Modusmaior fromValue(int value) =>
      Modusmaior.values.firstWhere((e) => e.value == value,
          orElse: () => Modusmaior.values.first);
}

/// MEI `data_MODUSMINOR`.
enum Modusminor {
  /// `MODUSMINOR_NONE`
  none(-3),

  /// `MODUSMINOR_2`
  n2(2),

  /// `MODUSMINOR_3`
  n3(3),
  ;

  const Modusminor(this.value);

  final int value;

  static Modusminor fromValue(int value) =>
      Modusminor.values.firstWhere((e) => e.value == value,
          orElse: () => Modusminor.values.first);
}

/// MEI `data_MULTIBREVERESTS_mensural`.
enum MultibreverestsMensural {
  /// `MULTIBREVERESTS_mensural_NONE`
  none(0),

  /// `MULTIBREVERESTS_mensural_2B`
  n2b(1),

  /// `MULTIBREVERESTS_mensural_3B`
  n3b(2),
  ;

  const MultibreverestsMensural(this.value);

  final int value;

  static MultibreverestsMensural fromValue(int value) =>
      MultibreverestsMensural.values.firstWhere((e) => e.value == value,
          orElse: () => MultibreverestsMensural.values.first);
}

/// MEI `data_NEIGHBORINGLAYER`.
enum Neighboringlayer {
  /// `NEIGHBORINGLAYER_NONE`
  none(0),

  /// `NEIGHBORINGLAYER_above`
  above(1),

  /// `NEIGHBORINGLAYER_below`
  below(2),
  ;

  const Neighboringlayer(this.value);

  final int value;

  static Neighboringlayer fromValue(int value) =>
      Neighboringlayer.values.firstWhere((e) => e.value == value,
          orElse: () => Neighboringlayer.values.first);
}

/// MEI `data_NONSTAFFPLACE`.
enum Nonstaffplace {
  /// `NONSTAFFPLACE_NONE`
  none(0),

  /// `NONSTAFFPLACE_botmar`
  botmar(1),

  /// `NONSTAFFPLACE_topmar`
  topmar(2),

  /// `NONSTAFFPLACE_leftmar`
  leftmar(3),

  /// `NONSTAFFPLACE_rightmar`
  rightmar(4),

  /// `NONSTAFFPLACE_facing`
  facing(5),

  /// `NONSTAFFPLACE_overleaf`
  overleaf(6),

  /// `NONSTAFFPLACE_end`
  end(7),

  /// `NONSTAFFPLACE_inter`
  inter(8),

  /// `NONSTAFFPLACE_intra`
  intra(9),

  /// `NONSTAFFPLACE_super`
  superValue(10),

  /// `NONSTAFFPLACE_sub`
  sub(11),

  /// `NONSTAFFPLACE_inspace`
  inspace(12),

  /// `NONSTAFFPLACE_superimposed`
  superimposed(13),
  ;

  const Nonstaffplace(this.value);

  final int value;

  static Nonstaffplace fromValue(int value) =>
      Nonstaffplace.values.firstWhere((e) => e.value == value,
          orElse: () => Nonstaffplace.values.first);
}

/// MEI `data_NOTATIONTYPE`.
enum Notationtype {
  /// `NOTATIONTYPE_NONE`
  none(0),

  /// `NOTATIONTYPE_cmn`
  cmn(1),

  /// `NOTATIONTYPE_mensural`
  mensural(2),

  /// `NOTATIONTYPE_mensural_black`
  mensuralBlack(3),

  /// `NOTATIONTYPE_mensural_white`
  mensuralWhite(4),

  /// `NOTATIONTYPE_neume`
  neume(5),

  /// `NOTATIONTYPE_tab`
  tab(6),

  /// `NOTATIONTYPE_tab_staff_like`
  tabStaffLike(7),

  /// `NOTATIONTYPE_tab_guitar`
  tabGuitar(8),

  /// `NOTATIONTYPE_tab_lute_french`
  tabLuteFrench(9),

  /// `NOTATIONTYPE_tab_lute_italian`
  tabLuteItalian(10),

  /// `NOTATIONTYPE_tab_lute_german`
  tabLuteGerman(11),
  ;

  const Notationtype(this.value);

  final int value;

  static Notationtype fromValue(int value) =>
      Notationtype.values.firstWhere((e) => e.value == value,
          orElse: () => Notationtype.values.first);
}

/// MEI `data_NOTEHEADMODIFIER`.
enum Noteheadmodifier {
  /// `NOTEHEADMODIFIER_NONE`
  none(0),

  /// `NOTEHEADMODIFIER_slash`
  slash(1),

  /// `NOTEHEADMODIFIER_backslash`
  backslash(2),

  /// `NOTEHEADMODIFIER_vline`
  vline(3),

  /// `NOTEHEADMODIFIER_hline`
  hline(4),

  /// `NOTEHEADMODIFIER_centerdot`
  centerdot(5),

  /// `NOTEHEADMODIFIER_paren`
  paren(6),

  /// `NOTEHEADMODIFIER_brack`
  brack(7),

  /// `NOTEHEADMODIFIER_box`
  box(8),

  /// `NOTEHEADMODIFIER_circle`
  circle(9),

  /// `NOTEHEADMODIFIER_fences`
  fences(10),
  ;

  const Noteheadmodifier(this.value);

  final int value;

  static Noteheadmodifier fromValue(int value) =>
      Noteheadmodifier.values.firstWhere((e) => e.value == value,
          orElse: () => Noteheadmodifier.values.first);
}

/// MEI `data_NOTEHEADMODIFIER_list`.
enum NoteheadmodifierList {
  /// `NOTEHEADMODIFIER_list_NONE`
  none(0),

  /// `NOTEHEADMODIFIER_list_slash`
  slash(1),

  /// `NOTEHEADMODIFIER_list_backslash`
  backslash(2),

  /// `NOTEHEADMODIFIER_list_vline`
  vline(3),

  /// `NOTEHEADMODIFIER_list_hline`
  hline(4),

  /// `NOTEHEADMODIFIER_list_centerdot`
  centerdot(5),

  /// `NOTEHEADMODIFIER_list_paren`
  paren(6),

  /// `NOTEHEADMODIFIER_list_brack`
  brack(7),

  /// `NOTEHEADMODIFIER_list_box`
  box(8),

  /// `NOTEHEADMODIFIER_list_circle`
  circle(9),

  /// `NOTEHEADMODIFIER_list_fences`
  fences(10),
  ;

  const NoteheadmodifierList(this.value);

  final int value;

  static NoteheadmodifierList fromValue(int value) =>
      NoteheadmodifierList.values.firstWhere((e) => e.value == value,
          orElse: () => NoteheadmodifierList.values.first);
}

/// MEI `data_OCTAVE_DIS`.
enum OctaveDis {
  /// `OCTAVE_DIS_NONE`
  none(0),

  /// `OCTAVE_DIS_8`
  n8(8),

  /// `OCTAVE_DIS_15`
  n15(15),

  /// `OCTAVE_DIS_22`
  n22(22),
  ;

  const OctaveDis(this.value);

  final int value;

  static OctaveDis fromValue(int value) =>
      OctaveDis.values.firstWhere((e) => e.value == value,
          orElse: () => OctaveDis.values.first);
}

/// MEI `data_ORIENTATION`.
enum Orientation {
  /// `ORIENTATION_NONE`
  none(0),

  /// `ORIENTATION_reversed`
  reversed(1),

  /// `ORIENTATION_90CW`
  n90cw(2),

  /// `ORIENTATION_90CCW`
  n90ccw(3),
  ;

  const Orientation(this.value);

  final int value;

  static Orientation fromValue(int value) =>
      Orientation.values.firstWhere((e) => e.value == value,
          orElse: () => Orientation.values.first);
}

/// MEI `data_PEDALSTYLE`.
enum Pedalstyle {
  /// `PEDALSTYLE_NONE`
  none(0),

  /// `PEDALSTYLE_line`
  line(1),

  /// `PEDALSTYLE_pedline`
  pedline(2),

  /// `PEDALSTYLE_pedstar`
  pedstar(3),

  /// `PEDALSTYLE_altpedstar`
  altpedstar(4),
  ;

  const Pedalstyle(this.value);

  final int value;

  static Pedalstyle fromValue(int value) =>
      Pedalstyle.values.firstWhere((e) => e.value == value,
          orElse: () => Pedalstyle.values.first);
}

/// MEI `data_PGFUNC`.
enum Pgfunc {
  /// `PGFUNC_NONE`
  none(0),

  /// `PGFUNC_all`
  all(1),

  /// `PGFUNC_first`
  first(2),

  /// `PGFUNC_last`
  last(3),

  /// `PGFUNC_alt1`
  alt1(4),

  /// `PGFUNC_alt2`
  alt2(5),
  ;

  const Pgfunc(this.value);

  final int value;

  static Pgfunc fromValue(int value) => Pgfunc.values
      .firstWhere((e) => e.value == value, orElse: () => Pgfunc.values.first);
}

/// MEI `data_PITCHNAME`.
enum Pitchname {
  /// `PITCHNAME_NONE`
  none(0),

  /// `PITCHNAME_c`
  c(1),

  /// `PITCHNAME_d`
  d(2),

  /// `PITCHNAME_e`
  e(3),

  /// `PITCHNAME_f`
  f(4),

  /// `PITCHNAME_g`
  g(5),

  /// `PITCHNAME_a`
  a(6),

  /// `PITCHNAME_b`
  b(7),
  ;

  const Pitchname(this.value);

  final int value;

  static Pitchname fromValue(int value) =>
      Pitchname.values.firstWhere((e) => e.value == value,
          orElse: () => Pitchname.values.first);
}

/// MEI `data_PITCHNAME_GES`.
enum PitchnameGes {
  /// `PITCHNAME_GES_NONE`
  none(0),

  /// `PITCHNAME_GES_c`
  c(1),

  /// `PITCHNAME_GES_d`
  d(2),

  /// `PITCHNAME_GES_e`
  e(3),

  /// `PITCHNAME_GES_f`
  f(4),

  /// `PITCHNAME_GES_g`
  g(5),

  /// `PITCHNAME_GES_a`
  a(6),

  /// `PITCHNAME_GES_b`
  b(7),

  /// `PITCHNAME_GES_none`
  none0(8),
  ;

  const PitchnameGes(this.value);

  final int value;

  static PitchnameGes fromValue(int value) =>
      PitchnameGes.values.firstWhere((e) => e.value == value,
          orElse: () => PitchnameGes.values.first);
}

/// MEI `data_PROLATIO`.
enum Prolatio {
  /// `PROLATIO_NONE`
  none(-3),

  /// `PROLATIO_2`
  n2(2),

  /// `PROLATIO_3`
  n3(3),
  ;

  const Prolatio(this.value);

  final int value;

  static Prolatio fromValue(int value) => Prolatio.values
      .firstWhere((e) => e.value == value, orElse: () => Prolatio.values.first);
}

/// MEI `data_RELATIONSHIP`.
enum Relationship {
  /// `RELATIONSHIP_NONE`
  none(0),

  /// `RELATIONSHIP_hasAbridgement`
  hasabridgement(1),

  /// `RELATIONSHIP_isAbridgementOf`
  isabridgementof(2),

  /// `RELATIONSHIP_hasAdaptation`
  hasadaptation(3),

  /// `RELATIONSHIP_isAdaptationOf`
  isadaptationof(4),

  /// `RELATIONSHIP_hasAlternate`
  hasalternate(5),

  /// `RELATIONSHIP_isAlternateOf`
  isalternateof(6),

  /// `RELATIONSHIP_hasArrangement`
  hasarrangement(7),

  /// `RELATIONSHIP_isArrangementOf`
  isarrangementof(8),

  /// `RELATIONSHIP_hasComplement`
  hascomplement(9),

  /// `RELATIONSHIP_isComplementOf`
  iscomplementof(10),

  /// `RELATIONSHIP_hasEmbodiment`
  hasembodiment(11),

  /// `RELATIONSHIP_isEmbodimentOf`
  isembodimentof(12),

  /// `RELATIONSHIP_hasExemplar`
  hasexemplar(13),

  /// `RELATIONSHIP_isExemplarOf`
  isexemplarof(14),

  /// `RELATIONSHIP_hasImitation`
  hasimitation(15),

  /// `RELATIONSHIP_isImitationOf`
  isimitationof(16),

  /// `RELATIONSHIP_hasPart`
  haspart(17),

  /// `RELATIONSHIP_isPartOf`
  ispartof(18),

  /// `RELATIONSHIP_hasRealization`
  hasrealization(19),

  /// `RELATIONSHIP_isRealizationOf`
  isrealizationof(20),

  /// `RELATIONSHIP_hasReconfiguration`
  hasreconfiguration(21),

  /// `RELATIONSHIP_isReconfigurationOf`
  isreconfigurationof(22),

  /// `RELATIONSHIP_hasReproduction`
  hasreproduction(23),

  /// `RELATIONSHIP_isReproductionOf`
  isreproductionof(24),

  /// `RELATIONSHIP_hasRevision`
  hasrevision(25),

  /// `RELATIONSHIP_isRevisionOf`
  isrevisionof(26),

  /// `RELATIONSHIP_hasSuccessor`
  hassuccessor(27),

  /// `RELATIONSHIP_isSuccessorOf`
  issuccessorof(28),

  /// `RELATIONSHIP_hasSummarization`
  hassummarization(29),

  /// `RELATIONSHIP_isSummarizationOf`
  issummarizationof(30),

  /// `RELATIONSHIP_hasSupplement`
  hassupplement(31),

  /// `RELATIONSHIP_isSupplementOf`
  issupplementof(32),

  /// `RELATIONSHIP_hasTransformation`
  hastransformation(33),

  /// `RELATIONSHIP_isTransformationOf`
  istransformationof(34),

  /// `RELATIONSHIP_hasTranslation`
  hastranslation(35),

  /// `RELATIONSHIP_isTranslationOf`
  istranslationof(36),

  /// `RELATIONSHIP_preceding`
  preceding(37),

  /// `RELATIONSHIP_succeeding`
  succeeding(38),

  /// `RELATIONSHIP_original`
  original(39),

  /// `RELATIONSHIP_host`
  host(40),

  /// `RELATIONSHIP_constituent`
  constituent(41),

  /// `RELATIONSHIP_otherVersion`
  otherversion(42),

  /// `RELATIONSHIP_otherFormat`
  otherformat(43),

  /// `RELATIONSHIP_isReferencedBy`
  isreferencedby(44),

  /// `RELATIONSHIP_references`
  references(45),
  ;

  const Relationship(this.value);

  final int value;

  static Relationship fromValue(int value) =>
      Relationship.values.firstWhere((e) => e.value == value,
          orElse: () => Relationship.values.first);
}

/// MEI `data_RELATORS`.
enum Relators {
  /// `RELATORS_NONE`
  none(0),

  /// `RELATORS_arr`
  arr(1),

  /// `RELATORS_aut`
  aut(2),

  /// `RELATORS_cmp`
  cmp(3),

  /// `RELATORS_dte`
  dte(4),

  /// `RELATORS_edt`
  edt(5),

  /// `RELATORS_lbt`
  lbt(6),

  /// `RELATORS_lyr`
  lyr(7),

  /// `RELATORS_act`
  act(8),

  /// `RELATORS_ard`
  ard(9),

  /// `RELATORS_art`
  art(10),

  /// `RELATORS_aus`
  aus(11),

  /// `RELATORS_chr`
  chr(12),

  /// `RELATORS_cnd`
  cnd(13),

  /// `RELATORS_crp`
  crp(14),

  /// `RELATORS_cst`
  cst(15),

  /// `RELATORS_drt`
  drt(16),

  /// `RELATORS_egr`
  egr(17),

  /// `RELATORS_flm`
  flm(18),

  /// `RELATORS_fmd`
  fmd(19),

  /// `RELATORS_fmp`
  fmp(20),

  /// `RELATORS_itr`
  itr(21),

  /// `RELATORS_mcp`
  mcp(22),

  /// `RELATORS_mus`
  mus(23),

  /// `RELATORS_msd`
  msd(24),

  /// `RELATORS_pdr`
  pdr(25),

  /// `RELATORS_pmn`
  pmn(26),

  /// `RELATORS_prn`
  prn(27),

  /// `RELATORS_pro`
  pro(28),

  /// `RELATORS_rce`
  rce(29),

  /// `RELATORS_scr`
  scr(30),

  /// `RELATORS_sng`
  sng(31),

  /// `RELATORS_std`
  std(32),

  /// `RELATORS_trc`
  trc(33),

  /// `RELATORS_trl`
  trl(34),
  ;

  const Relators(this.value);

  final int value;

  static Relators fromValue(int value) => Relators.values
      .firstWhere((e) => e.value == value, orElse: () => Relators.values.first);
}

/// MEI `data_ROTATION`.
enum Rotation {
  /// `ROTATION_NONE`
  none(0),

  /// `ROTATION_none`
  none0(1),

  /// `ROTATION_down`
  down(2),

  /// `ROTATION_left`
  left(3),

  /// `ROTATION_ne`
  ne(4),

  /// `ROTATION_nw`
  nw(5),

  /// `ROTATION_se`
  se(6),

  /// `ROTATION_sw`
  sw(7),
  ;

  const Rotation(this.value);

  final int value;

  static Rotation fromValue(int value) => Rotation.values
      .firstWhere((e) => e.value == value, orElse: () => Rotation.values.first);
}

/// MEI `data_ROTATIONDIRECTION`.
enum Rotationdirection {
  /// `ROTATIONDIRECTION_NONE`
  none(0),

  /// `ROTATIONDIRECTION_none`
  none0(1),

  /// `ROTATIONDIRECTION_down`
  down(2),

  /// `ROTATIONDIRECTION_left`
  left(3),

  /// `ROTATIONDIRECTION_ne`
  ne(4),

  /// `ROTATIONDIRECTION_nw`
  nw(5),

  /// `ROTATIONDIRECTION_se`
  se(6),

  /// `ROTATIONDIRECTION_sw`
  sw(7),
  ;

  const Rotationdirection(this.value);

  final int value;

  static Rotationdirection fromValue(int value) =>
      Rotationdirection.values.firstWhere((e) => e.value == value,
          orElse: () => Rotationdirection.values.first);
}

/// MEI `data_STAFFITEM`.
enum Staffitem {
  /// `STAFFITEM_NONE`
  none(0),

  /// `STAFFITEM_accid`
  accid(1),

  /// `STAFFITEM_annot`
  annot(2),

  /// `STAFFITEM_artic`
  artic(3),

  /// `STAFFITEM_dir`
  dir(4),

  /// `STAFFITEM_dynam`
  dynam(5),

  /// `STAFFITEM_harm`
  harm(6),

  /// `STAFFITEM_ornam`
  ornam(7),

  /// `STAFFITEM_sp`
  sp(8),

  /// `STAFFITEM_stageDir`
  stagedir(9),

  /// `STAFFITEM_tempo`
  tempo(10),

  /// `STAFFITEM_beam`
  beam(11),

  /// `STAFFITEM_bend`
  bend(12),

  /// `STAFFITEM_bracketSpan`
  bracketspan(13),

  /// `STAFFITEM_breath`
  breath(14),

  /// `STAFFITEM_cpMark`
  cpmark(15),

  /// `STAFFITEM_fermata`
  fermata(16),

  /// `STAFFITEM_fing`
  fing(17),

  /// `STAFFITEM_hairpin`
  hairpin(18),

  /// `STAFFITEM_harpPedal`
  harppedal(19),

  /// `STAFFITEM_lv`
  lv(20),

  /// `STAFFITEM_mordent`
  mordent(21),

  /// `STAFFITEM_octave`
  octave(22),

  /// `STAFFITEM_pedal`
  pedal(23),

  /// `STAFFITEM_reh`
  reh(24),

  /// `STAFFITEM_tie`
  tie(25),

  /// `STAFFITEM_trill`
  trill(26),

  /// `STAFFITEM_tuplet`
  tuplet(27),

  /// `STAFFITEM_turn`
  turn(28),

  /// `STAFFITEM_ligature`
  ligature(29),
  ;

  const Staffitem(this.value);

  final int value;

  static Staffitem fromValue(int value) =>
      Staffitem.values.firstWhere((e) => e.value == value,
          orElse: () => Staffitem.values.first);
}

/// MEI `data_STAFFITEM_basic`.
enum StaffitemBasic {
  /// `STAFFITEM_basic_NONE`
  none(0),

  /// `STAFFITEM_basic_accid`
  accid(1),

  /// `STAFFITEM_basic_annot`
  annot(2),

  /// `STAFFITEM_basic_artic`
  artic(3),

  /// `STAFFITEM_basic_dir`
  dir(4),

  /// `STAFFITEM_basic_dynam`
  dynam(5),

  /// `STAFFITEM_basic_harm`
  harm(6),

  /// `STAFFITEM_basic_ornam`
  ornam(7),

  /// `STAFFITEM_basic_sp`
  sp(8),

  /// `STAFFITEM_basic_stageDir`
  stagedir(9),

  /// `STAFFITEM_basic_tempo`
  tempo(10),
  ;

  const StaffitemBasic(this.value);

  final int value;

  static StaffitemBasic fromValue(int value) =>
      StaffitemBasic.values.firstWhere((e) => e.value == value,
          orElse: () => StaffitemBasic.values.first);
}

/// MEI `data_STAFFITEM_cmn`.
enum StaffitemCmn {
  /// `STAFFITEM_cmn_NONE`
  none(0),

  /// `STAFFITEM_cmn_beam`
  beam(1),

  /// `STAFFITEM_cmn_bend`
  bend(2),

  /// `STAFFITEM_cmn_bracketSpan`
  bracketspan(3),

  /// `STAFFITEM_cmn_breath`
  breath(4),

  /// `STAFFITEM_cmn_cpMark`
  cpmark(5),

  /// `STAFFITEM_cmn_fermata`
  fermata(6),

  /// `STAFFITEM_cmn_fing`
  fing(7),

  /// `STAFFITEM_cmn_hairpin`
  hairpin(8),

  /// `STAFFITEM_cmn_harpPedal`
  harppedal(9),

  /// `STAFFITEM_cmn_lv`
  lv(10),

  /// `STAFFITEM_cmn_mordent`
  mordent(11),

  /// `STAFFITEM_cmn_octave`
  octave(12),

  /// `STAFFITEM_cmn_pedal`
  pedal(13),

  /// `STAFFITEM_cmn_reh`
  reh(14),

  /// `STAFFITEM_cmn_tie`
  tie(15),

  /// `STAFFITEM_cmn_trill`
  trill(16),

  /// `STAFFITEM_cmn_tuplet`
  tuplet(17),

  /// `STAFFITEM_cmn_turn`
  turn(18),
  ;

  const StaffitemCmn(this.value);

  final int value;

  static StaffitemCmn fromValue(int value) =>
      StaffitemCmn.values.firstWhere((e) => e.value == value,
          orElse: () => StaffitemCmn.values.first);
}

/// MEI `data_STAFFITEM_mensural`.
enum StaffitemMensural {
  /// `STAFFITEM_mensural_NONE`
  none(0),

  /// `STAFFITEM_mensural_ligature`
  ligature(1),
  ;

  const StaffitemMensural(this.value);

  final int value;

  static StaffitemMensural fromValue(int value) =>
      StaffitemMensural.values.firstWhere((e) => e.value == value,
          orElse: () => StaffitemMensural.values.first);
}

/// MEI `data_STAFFREL`.
enum Staffrel {
  /// `STAFFREL_NONE`
  none(0),

  /// `STAFFREL_above`
  above(1),

  /// `STAFFREL_below`
  below(2),

  /// `STAFFREL_between`
  between(3),

  /// `STAFFREL_within`
  within(4),
  ;

  const Staffrel(this.value);

  final int value;

  static Staffrel fromValue(int value) => Staffrel.values
      .firstWhere((e) => e.value == value, orElse: () => Staffrel.values.first);
}

/// MEI `data_STAFFREL_basic`.
enum StaffrelBasic {
  /// `STAFFREL_basic_NONE`
  none(0),

  /// `STAFFREL_basic_above`
  above(1),

  /// `STAFFREL_basic_below`
  below(2),
  ;

  const StaffrelBasic(this.value);

  final int value;

  static StaffrelBasic fromValue(int value) =>
      StaffrelBasic.values.firstWhere((e) => e.value == value,
          orElse: () => StaffrelBasic.values.first);
}

/// MEI `data_STAFFREL_extended`.
enum StaffrelExtended {
  /// `STAFFREL_extended_NONE`
  none(0),

  /// `STAFFREL_extended_between`
  between(1),

  /// `STAFFREL_extended_within`
  within(2),
  ;

  const StaffrelExtended(this.value);

  final int value;

  static StaffrelExtended fromValue(int value) =>
      StaffrelExtended.values.firstWhere((e) => e.value == value,
          orElse: () => StaffrelExtended.values.first);
}

/// MEI `data_STEMDIRECTION`.
enum Stemdirection {
  /// `STEMDIRECTION_NONE`
  none(0),

  /// `STEMDIRECTION_up`
  up(1),

  /// `STEMDIRECTION_down`
  down(2),

  /// `STEMDIRECTION_left`
  left(3),

  /// `STEMDIRECTION_right`
  right(4),

  /// `STEMDIRECTION_ne`
  ne(5),

  /// `STEMDIRECTION_se`
  se(6),

  /// `STEMDIRECTION_nw`
  nw(7),

  /// `STEMDIRECTION_sw`
  sw(8),
  ;

  const Stemdirection(this.value);

  final int value;

  static Stemdirection fromValue(int value) =>
      Stemdirection.values.firstWhere((e) => e.value == value,
          orElse: () => Stemdirection.values.first);
}

/// MEI `data_STEMDIRECTION_basic`.
enum StemdirectionBasic {
  /// `STEMDIRECTION_basic_NONE`
  none(0),

  /// `STEMDIRECTION_basic_up`
  up(1),

  /// `STEMDIRECTION_basic_down`
  down(2),
  ;

  const StemdirectionBasic(this.value);

  final int value;

  static StemdirectionBasic fromValue(int value) =>
      StemdirectionBasic.values.firstWhere((e) => e.value == value,
          orElse: () => StemdirectionBasic.values.first);
}

/// MEI `data_STEMDIRECTION_extended`.
enum StemdirectionExtended {
  /// `STEMDIRECTION_extended_NONE`
  none(0),

  /// `STEMDIRECTION_extended_left`
  left(1),

  /// `STEMDIRECTION_extended_right`
  right(2),

  /// `STEMDIRECTION_extended_ne`
  ne(3),

  /// `STEMDIRECTION_extended_se`
  se(4),

  /// `STEMDIRECTION_extended_nw`
  nw(5),

  /// `STEMDIRECTION_extended_sw`
  sw(6),
  ;

  const StemdirectionExtended(this.value);

  final int value;

  static StemdirectionExtended fromValue(int value) =>
      StemdirectionExtended.values.firstWhere((e) => e.value == value,
          orElse: () => StemdirectionExtended.values.first);
}

/// MEI `data_STEMFORM_mensural`.
enum StemformMensural {
  /// `STEMFORM_mensural_NONE`
  none(0),

  /// `STEMFORM_mensural_circle`
  circle(1),

  /// `STEMFORM_mensural_oblique`
  oblique(2),

  /// `STEMFORM_mensural_swallowtail`
  swallowtail(3),

  /// `STEMFORM_mensural_virgula`
  virgula(4),
  ;

  const StemformMensural(this.value);

  final int value;

  static StemformMensural fromValue(int value) =>
      StemformMensural.values.firstWhere((e) => e.value == value,
          orElse: () => StemformMensural.values.first);
}

/// MEI `data_STEMMODIFIER`.
enum Stemmodifier {
  /// `STEMMODIFIER_NONE`
  none(0),

  /// `STEMMODIFIER_none`
  none0(1),

  /// `STEMMODIFIER_1slash`
  n1slash(2),

  /// `STEMMODIFIER_2slash`
  n2slash(3),

  /// `STEMMODIFIER_3slash`
  n3slash(4),

  /// `STEMMODIFIER_4slash`
  n4slash(5),

  /// `STEMMODIFIER_5slash`
  n5slash(6),

  /// `STEMMODIFIER_6slash`
  n6slash(7),

  /// `STEMMODIFIER_sprech`
  sprech(8),

  /// `STEMMODIFIER_z`
  z(9),
  ;

  const Stemmodifier(this.value);

  final int value;

  static Stemmodifier fromValue(int value) =>
      Stemmodifier.values.firstWhere((e) => e.value == value,
          orElse: () => Stemmodifier.values.first);
}

/// MEI `data_STEMPOSITION`.
enum Stemposition {
  /// `STEMPOSITION_NONE`
  none(0),

  /// `STEMPOSITION_left`
  left(1),

  /// `STEMPOSITION_right`
  right(2),

  /// `STEMPOSITION_center`
  center(3),
  ;

  const Stemposition(this.value);

  final int value;

  static Stemposition fromValue(int value) =>
      Stemposition.values.firstWhere((e) => e.value == value,
          orElse: () => Stemposition.values.first);
}

/// MEI `data_TEMPERAMENT`.
enum Temperament {
  /// `TEMPERAMENT_NONE`
  none(0),

  /// `TEMPERAMENT_equal`
  equal(1),

  /// `TEMPERAMENT_just`
  just(2),

  /// `TEMPERAMENT_mean`
  mean(3),

  /// `TEMPERAMENT_pythagorean`
  pythagorean(4),
  ;

  const Temperament(this.value);

  final int value;

  static Temperament fromValue(int value) =>
      Temperament.values.firstWhere((e) => e.value == value,
          orElse: () => Temperament.values.first);
}

/// MEI `data_TEMPUS`.
enum Tempus {
  /// `TEMPUS_NONE`
  none(-3),

  /// `TEMPUS_2`
  n2(2),

  /// `TEMPUS_3`
  n3(3),
  ;

  const Tempus(this.value);

  final int value;

  static Tempus fromValue(int value) => Tempus.values
      .firstWhere((e) => e.value == value, orElse: () => Tempus.values.first);
}

/// MEI `data_TEXTRENDITION`.
enum Textrendition {
  /// `TEXTRENDITION_NONE`
  none(0),

  /// `TEXTRENDITION_quote`
  quote(1),

  /// `TEXTRENDITION_quotedbl`
  quotedbl(2),

  /// `TEXTRENDITION_italic`
  italic(3),

  /// `TEXTRENDITION_oblique`
  oblique(4),

  /// `TEXTRENDITION_smcaps`
  smcaps(5),

  /// `TEXTRENDITION_bold`
  bold(6),

  /// `TEXTRENDITION_bolder`
  bolder(7),

  /// `TEXTRENDITION_lighter`
  lighter(8),

  /// `TEXTRENDITION_box`
  box(9),

  /// `TEXTRENDITION_circle`
  circle(10),

  /// `TEXTRENDITION_dbox`
  dbox(11),

  /// `TEXTRENDITION_tbox`
  tbox(12),

  /// `TEXTRENDITION_bslash`
  bslash(13),

  /// `TEXTRENDITION_fslash`
  fslash(14),

  /// `TEXTRENDITION_line_through`
  lineThrough(15),

  /// `TEXTRENDITION_none`
  none0(16),

  /// `TEXTRENDITION_overline`
  overline(17),

  /// `TEXTRENDITION_overstrike`
  overstrike(18),

  /// `TEXTRENDITION_strike`
  strike(19),

  /// `TEXTRENDITION_sub`
  sub(20),

  /// `TEXTRENDITION_sup`
  sup(21),

  /// `TEXTRENDITION_superimpose`
  superimpose(22),

  /// `TEXTRENDITION_underline`
  underline(23),

  /// `TEXTRENDITION_x_through`
  xThrough(24),

  /// `TEXTRENDITION_ltr`
  ltr(25),

  /// `TEXTRENDITION_rtl`
  rtl(26),

  /// `TEXTRENDITION_lro`
  lro(27),

  /// `TEXTRENDITION_rlo`
  rlo(28),
  ;

  const Textrendition(this.value);

  final int value;

  static Textrendition fromValue(int value) =>
      Textrendition.values.firstWhere((e) => e.value == value,
          orElse: () => Textrendition.values.first);
}

/// MEI `data_TEXTRENDITIONLIST`.
enum Textrenditionlist {
  /// `TEXTRENDITIONLIST_NONE`
  none(0),

  /// `TEXTRENDITIONLIST_quote`
  quote(1),

  /// `TEXTRENDITIONLIST_quotedbl`
  quotedbl(2),

  /// `TEXTRENDITIONLIST_italic`
  italic(3),

  /// `TEXTRENDITIONLIST_oblique`
  oblique(4),

  /// `TEXTRENDITIONLIST_smcaps`
  smcaps(5),

  /// `TEXTRENDITIONLIST_bold`
  bold(6),

  /// `TEXTRENDITIONLIST_bolder`
  bolder(7),

  /// `TEXTRENDITIONLIST_lighter`
  lighter(8),

  /// `TEXTRENDITIONLIST_box`
  box(9),

  /// `TEXTRENDITIONLIST_circle`
  circle(10),

  /// `TEXTRENDITIONLIST_dbox`
  dbox(11),

  /// `TEXTRENDITIONLIST_tbox`
  tbox(12),

  /// `TEXTRENDITIONLIST_bslash`
  bslash(13),

  /// `TEXTRENDITIONLIST_fslash`
  fslash(14),

  /// `TEXTRENDITIONLIST_line_through`
  lineThrough(15),

  /// `TEXTRENDITIONLIST_none`
  none0(16),

  /// `TEXTRENDITIONLIST_overline`
  overline(17),

  /// `TEXTRENDITIONLIST_overstrike`
  overstrike(18),

  /// `TEXTRENDITIONLIST_strike`
  strike(19),

  /// `TEXTRENDITIONLIST_sub`
  sub(20),

  /// `TEXTRENDITIONLIST_sup`
  sup(21),

  /// `TEXTRENDITIONLIST_superimpose`
  superimpose(22),

  /// `TEXTRENDITIONLIST_underline`
  underline(23),

  /// `TEXTRENDITIONLIST_x_through`
  xThrough(24),

  /// `TEXTRENDITIONLIST_ltr`
  ltr(25),

  /// `TEXTRENDITIONLIST_rtl`
  rtl(26),

  /// `TEXTRENDITIONLIST_lro`
  lro(27),

  /// `TEXTRENDITIONLIST_rlo`
  rlo(28),
  ;

  const Textrenditionlist(this.value);

  final int value;

  static Textrenditionlist fromValue(int value) =>
      Textrenditionlist.values.firstWhere((e) => e.value == value,
          orElse: () => Textrenditionlist.values.first);
}

/// MEI `data_TIE`.
enum Tie {
  /// `TIE_NONE`
  none(0),

  /// `TIE_i`
  i(1),

  /// `TIE_m`
  m(2),

  /// `TIE_t`
  t(3),
  ;

  const Tie(this.value);

  final int value;

  static Tie fromValue(int value) => Tie.values
      .firstWhere((e) => e.value == value, orElse: () => Tie.values.first);
}

/// MEI `data_VERTICALALIGNMENT`.
enum Verticalalignment {
  /// `VERTICALALIGNMENT_NONE`
  none(0),

  /// `VERTICALALIGNMENT_top`
  top(1),

  /// `VERTICALALIGNMENT_middle`
  middle(2),

  /// `VERTICALALIGNMENT_bottom`
  bottom(3),

  /// `VERTICALALIGNMENT_baseline`
  baseline(4),
  ;

  const Verticalalignment(this.value);

  final int value;

  static Verticalalignment fromValue(int value) =>
      Verticalalignment.values.firstWhere((e) => e.value == value,
          orElse: () => Verticalalignment.values.first);
}

/// MEI `divLineLog_FORM`.
enum DivlinelogForm {
  /// `divLineLog_FORM_NONE`
  none(0),

  /// `divLineLog_FORM_caesura`
  caesura(1),

  /// `divLineLog_FORM_finalis`
  finalis(2),

  /// `divLineLog_FORM_maior`
  maior(3),

  /// `divLineLog_FORM_maxima`
  maxima(4),

  /// `divLineLog_FORM_minima`
  minima(5),

  /// `divLineLog_FORM_virgula`
  virgula(6),
  ;

  const DivlinelogForm(this.value);

  final int value;

  static DivlinelogForm fromValue(int value) =>
      DivlinelogForm.values.firstWhere((e) => e.value == value,
          orElse: () => DivlinelogForm.values.first);
}

/// MEI `docStatus_STATUS`.
enum DocstatusStatus {
  /// `docStatus_STATUS_NONE`
  none(0),

  /// `docStatus_STATUS_draft`
  draft(1),

  /// `docStatus_STATUS_in_process`
  inProcess(2),

  /// `docStatus_STATUS_candidate`
  candidate(3),

  /// `docStatus_STATUS_approved`
  approved(4),

  /// `docStatus_STATUS_published`
  published(5),

  /// `docStatus_STATUS_withdrawn`
  withdrawn(6),

  /// `docStatus_STATUS_embargoed`
  embargoed(7),
  ;

  const DocstatusStatus(this.value);

  final int value;

  static DocstatusStatus fromValue(int value) =>
      DocstatusStatus.values.firstWhere((e) => e.value == value,
          orElse: () => DocstatusStatus.values.first);
}

/// MEI `dotLog_FORM`.
enum DotlogForm {
  /// `dotLog_FORM_NONE`
  none(0),

  /// `dotLog_FORM_aug`
  aug(1),

  /// `dotLog_FORM_div`
  div(2),
  ;

  const DotlogForm(this.value);

  final int value;

  static DotlogForm fromValue(int value) =>
      DotlogForm.values.firstWhere((e) => e.value == value,
          orElse: () => DotlogForm.values.first);
}

/// MEI `endings_ENDINGREND`.
enum EndingsEndingrend {
  /// `endings_ENDINGREND_NONE`
  none(0),

  /// `endings_ENDINGREND_top`
  top(1),

  /// `endings_ENDINGREND_barred`
  barred(2),

  /// `endings_ENDINGREND_grouped`
  grouped(3),
  ;

  const EndingsEndingrend(this.value);

  final int value;

  static EndingsEndingrend fromValue(int value) =>
      EndingsEndingrend.values.firstWhere((e) => e.value == value,
          orElse: () => EndingsEndingrend.values.first);
}

/// MEI `episemaVis_FORM`.
enum EpisemavisForm {
  /// `episemaVis_FORM_NONE`
  none(0),

  /// `episemaVis_FORM_h`
  h(1),

  /// `episemaVis_FORM_v`
  v(2),
  ;

  const EpisemavisForm(this.value);

  final int value;

  static EpisemavisForm fromValue(int value) =>
      EpisemavisForm.values.firstWhere((e) => e.value == value,
          orElse: () => EpisemavisForm.values.first);
}

/// MEI `evidence_EVIDENCE`.
enum EvidenceEvidence {
  /// `evidence_EVIDENCE_NONE`
  none(0),

  /// `evidence_EVIDENCE_internal`
  internal(1),

  /// `evidence_EVIDENCE_external`
  external(2),

  /// `evidence_EVIDENCE_conjecture`
  conjecture(3),
  ;

  const EvidenceEvidence(this.value);

  final int value;

  static EvidenceEvidence fromValue(int value) =>
      EvidenceEvidence.values.firstWhere((e) => e.value == value,
          orElse: () => EvidenceEvidence.values.first);
}

/// MEI `extSymAuth_GLYPHAUTH`.
enum ExtsymauthGlyphauth {
  /// `extSymAuth_GLYPHAUTH_NONE`
  none(0),

  /// `extSymAuth_GLYPHAUTH_smufl`
  smufl(1),
  ;

  const ExtsymauthGlyphauth(this.value);

  final int value;

  static ExtsymauthGlyphauth fromValue(int value) =>
      ExtsymauthGlyphauth.values.firstWhere((e) => e.value == value,
          orElse: () => ExtsymauthGlyphauth.values.first);
}

/// MEI `fermataVis_FORM`.
enum FermatavisForm {
  /// `fermataVis_FORM_NONE`
  none(0),

  /// `fermataVis_FORM_inv`
  inv(1),

  /// `fermataVis_FORM_norm`
  norm(2),
  ;

  const FermatavisForm(this.value);

  final int value;

  static FermatavisForm fromValue(int value) =>
      FermatavisForm.values.firstWhere((e) => e.value == value,
          orElse: () => FermatavisForm.values.first);
}

/// MEI `fermataVis_SHAPE`.
enum FermatavisShape {
  /// `fermataVis_SHAPE_NONE`
  none(0),

  /// `fermataVis_SHAPE_curved`
  curved(1),

  /// `fermataVis_SHAPE_square`
  square(2),

  /// `fermataVis_SHAPE_angular`
  angular(3),
  ;

  const FermatavisShape(this.value);

  final int value;

  static FermatavisShape fromValue(int value) =>
      FermatavisShape.values.firstWhere((e) => e.value == value,
          orElse: () => FermatavisShape.values.first);
}

/// MEI `fingGrpLog_FORM`.
enum FinggrplogForm {
  /// `fingGrpLog_FORM_NONE`
  none(0),

  /// `fingGrpLog_FORM_alter`
  alter(1),

  /// `fingGrpLog_FORM_combi`
  combi(2),

  /// `fingGrpLog_FORM_subst`
  subst(3),
  ;

  const FinggrplogForm(this.value);

  final int value;

  static FinggrplogForm fromValue(int value) =>
      FinggrplogForm.values.firstWhere((e) => e.value == value,
          orElse: () => FinggrplogForm.values.first);
}

/// MEI `fingGrpVis_ORIENT`.
enum FinggrpvisOrient {
  /// `fingGrpVis_ORIENT_NONE`
  none(0),

  /// `fingGrpVis_ORIENT_horiz`
  horiz(1),

  /// `fingGrpVis_ORIENT_vert`
  vert(2),
  ;

  const FinggrpvisOrient(this.value);

  final int value;

  static FinggrpvisOrient fromValue(int value) =>
      FinggrpvisOrient.values.firstWhere((e) => e.value == value,
          orElse: () => FinggrpvisOrient.values.first);
}

/// MEI `graceGrpLog_ATTACH`.
enum GracegrplogAttach {
  /// `graceGrpLog_ATTACH_NONE`
  none(0),

  /// `graceGrpLog_ATTACH_pre`
  pre(1),

  /// `graceGrpLog_ATTACH_post`
  post(2),

  /// `graceGrpLog_ATTACH_unknown`
  unknown(3),
  ;

  const GracegrplogAttach(this.value);

  final int value;

  static GracegrplogAttach fromValue(int value) =>
      GracegrplogAttach.values.firstWhere((e) => e.value == value,
          orElse: () => GracegrplogAttach.values.first);
}

/// MEI `hairpinLog_FORM`.
enum HairpinlogForm {
  /// `hairpinLog_FORM_NONE`
  none(0),

  /// `hairpinLog_FORM_cres`
  cres(1),

  /// `hairpinLog_FORM_dim`
  dim(2),
  ;

  const HairpinlogForm(this.value);

  final int value;

  static HairpinlogForm fromValue(int value) =>
      HairpinlogForm.values.firstWhere((e) => e.value == value,
          orElse: () => HairpinlogForm.values.first);
}

/// MEI `harmAnl_FORM`.
enum HarmanlForm {
  /// `harmAnl_FORM_NONE`
  none(0),

  /// `harmAnl_FORM_explicit`
  explicit(1),

  /// `harmAnl_FORM_implied`
  implied(2),
  ;

  const HarmanlForm(this.value);

  final int value;

  static HarmanlForm fromValue(int value) =>
      HarmanlForm.values.firstWhere((e) => e.value == value,
          orElse: () => HarmanlForm.values.first);
}

/// MEI `harmVis_RENDGRID`.
enum HarmvisRendgrid {
  /// `harmVis_RENDGRID_NONE`
  none(0),

  /// `harmVis_RENDGRID_grid`
  grid(1),

  /// `harmVis_RENDGRID_gridtext`
  gridtext(2),

  /// `harmVis_RENDGRID_text`
  text(3),
  ;

  const HarmvisRendgrid(this.value);

  final int value;

  static HarmvisRendgrid fromValue(int value) =>
      HarmvisRendgrid.values.firstWhere((e) => e.value == value,
          orElse: () => HarmvisRendgrid.values.first);
}

/// MEI `lineLog_FUNC`.
enum LinelogFunc {
  /// `lineLog_FUNC_NONE`
  none(0),

  /// `lineLog_FUNC_coloration`
  coloration(1),

  /// `lineLog_FUNC_ligature`
  ligature(2),

  /// `lineLog_FUNC_unknown`
  unknown(3),
  ;

  const LinelogFunc(this.value);

  final int value;

  static LinelogFunc fromValue(int value) =>
      LinelogFunc.values.firstWhere((e) => e.value == value,
          orElse: () => LinelogFunc.values.first);
}

/// MEI `measurement_UNIT`.
enum MeasurementUnit {
  /// `measurement_UNIT_NONE`
  none(0),

  /// `measurement_UNIT_byte`
  byte(1),

  /// `measurement_UNIT_char`
  char(2),

  /// `measurement_UNIT_cm`
  cm(3),

  /// `measurement_UNIT_deg`
  deg(4),

  /// `measurement_UNIT_in`
  inValue(5),

  /// `measurement_UNIT_issue`
  issue(6),

  /// `measurement_UNIT_ft`
  ft(7),

  /// `measurement_UNIT_m`
  m(8),

  /// `measurement_UNIT_mm`
  mm(9),

  /// `measurement_UNIT_page`
  page(10),

  /// `measurement_UNIT_pc`
  pc(11),

  /// `measurement_UNIT_pt`
  pt(12),

  /// `measurement_UNIT_px`
  px(13),

  /// `measurement_UNIT_rad`
  rad(14),

  /// `measurement_UNIT_record`
  record(15),

  /// `measurement_UNIT_vol`
  vol(16),

  /// `measurement_UNIT_vu`
  vu(17),
  ;

  const MeasurementUnit(this.value);

  final int value;

  static MeasurementUnit fromValue(int value) =>
      MeasurementUnit.values.firstWhere((e) => e.value == value,
          orElse: () => MeasurementUnit.values.first);
}

/// MEI `meiVersion_MEIVERSION`.
enum MeiversionMeiversion {
  /// `meiVersion_MEIVERSION_NONE`
  none(0),

  /// `meiVersion_MEIVERSION_2013`
  n2013(1),

  /// `meiVersion_MEIVERSION_3_0_0`
  n300(2),

  /// `meiVersion_MEIVERSION_4_0_0`
  n400(3),

  /// `meiVersion_MEIVERSION_4_0_1`
  n401(4),

  /// `meiVersion_MEIVERSION_5_0`
  n50(5),

  /// `meiVersion_MEIVERSION_5_1`
  n51(6),

  /// `meiVersion_MEIVERSION_5_0plusbasic`
  n50plusbasic(7),

  /// `meiVersion_MEIVERSION_5_0plusCMN`
  n50pluscmn(8),

  /// `meiVersion_MEIVERSION_5_0plusMensural`
  n50plusmensural(9),

  /// `meiVersion_MEIVERSION_5_0plusNeumes`
  n50plusneumes(10),

  /// `meiVersion_MEIVERSION_5_1plusbasic`
  n51plusbasic(11),

  /// `meiVersion_MEIVERSION_5_1plusCMN`
  n51pluscmn(12),

  /// `meiVersion_MEIVERSION_5_1plusMensural`
  n51plusmensural(13),

  /// `meiVersion_MEIVERSION_5_1plusNeumes`
  n51plusneumes(14),

  /// `meiVersion_MEIVERSION_6_0_dev`
  n60Dev(15),

  /// `meiVersion_MEIVERSION_6_0_devplusbasic`
  n60Devplusbasic(16),
  ;

  const MeiversionMeiversion(this.value);

  final int value;

  static MeiversionMeiversion fromValue(int value) =>
      MeiversionMeiversion.values.firstWhere((e) => e.value == value,
          orElse: () => MeiversionMeiversion.values.first);
}

/// MEI `mensurVis_FORM`.
enum MensurvisForm {
  /// `mensurVis_FORM_NONE`
  none(0),

  /// `mensurVis_FORM_horizontal`
  horizontal(1),

  /// `mensurVis_FORM_vertical`
  vertical(2),
  ;

  const MensurvisForm(this.value);

  final int value;

  static MensurvisForm fromValue(int value) =>
      MensurvisForm.values.firstWhere((e) => e.value == value,
          orElse: () => MensurvisForm.values.first);
}

/// MEI `mensuralVis_MENSURFORM`.
enum MensuralvisMensurform {
  /// `mensuralVis_MENSURFORM_NONE`
  none(0),

  /// `mensuralVis_MENSURFORM_horizontal`
  horizontal(1),

  /// `mensuralVis_MENSURFORM_vertical`
  vertical(2),
  ;

  const MensuralvisMensurform(this.value);

  final int value;

  static MensuralvisMensurform fromValue(int value) =>
      MensuralvisMensurform.values.firstWhere((e) => e.value == value,
          orElse: () => MensuralvisMensurform.values.first);
}

/// MEI `meterConformance_METCON`.
enum MeterconformanceMetcon {
  /// `meterConformance_METCON_NONE`
  none(0),

  /// `meterConformance_METCON_c`
  c(1),

  /// `meterConformance_METCON_i`
  i(2),

  /// `meterConformance_METCON_o`
  o(3),
  ;

  const MeterconformanceMetcon(this.value);

  final int value;

  static MeterconformanceMetcon fromValue(int value) =>
      MeterconformanceMetcon.values.firstWhere((e) => e.value == value,
          orElse: () => MeterconformanceMetcon.values.first);
}

/// MEI `meterSigGrpLog_FUNC`.
enum MetersiggrplogFunc {
  /// `meterSigGrpLog_FUNC_NONE`
  none(0),

  /// `meterSigGrpLog_FUNC_alternating`
  alternating(1),

  /// `meterSigGrpLog_FUNC_interchanging`
  interchanging(2),

  /// `meterSigGrpLog_FUNC_mixed`
  mixed(3),

  /// `meterSigGrpLog_FUNC_other`
  other(4),
  ;

  const MetersiggrplogFunc(this.value);

  final int value;

  static MetersiggrplogFunc fromValue(int value) =>
      MetersiggrplogFunc.values.firstWhere((e) => e.value == value,
          orElse: () => MetersiggrplogFunc.values.first);
}

/// MEI `mordentLog_FORM`.
enum MordentlogForm {
  /// `mordentLog_FORM_NONE`
  none(0),

  /// `mordentLog_FORM_lower`
  lower(1),

  /// `mordentLog_FORM_upper`
  upper(2),
  ;

  const MordentlogForm(this.value);

  final int value;

  static MordentlogForm fromValue(int value) =>
      MordentlogForm.values.firstWhere((e) => e.value == value,
          orElse: () => MordentlogForm.values.first);
}

/// MEI `ncForm_CON`.
enum NcformCon {
  /// `ncForm_CON_NONE`
  none(0),

  /// `ncForm_CON_g`
  g(1),

  /// `ncForm_CON_l`
  l(2),

  /// `ncForm_CON_e`
  e(3),
  ;

  const NcformCon(this.value);

  final int value;

  static NcformCon fromValue(int value) =>
      NcformCon.values.firstWhere((e) => e.value == value,
          orElse: () => NcformCon.values.first);
}

/// MEI `ncForm_RELLEN`.
enum NcformRellen {
  /// `ncForm_RELLEN_NONE`
  none(0),

  /// `ncForm_RELLEN_l`
  l(1),

  /// `ncForm_RELLEN_s`
  s(2),
  ;

  const NcformRellen(this.value);

  final int value;

  static NcformRellen fromValue(int value) =>
      NcformRellen.values.firstWhere((e) => e.value == value,
          orElse: () => NcformRellen.values.first);
}

/// MEI `neumeType_TYPE`.
enum NeumetypeType {
  /// `neumeType_TYPE_NONE`
  none(0),

  /// `neumeType_TYPE_apostropha`
  apostropha(1),

  /// `neumeType_TYPE_bistropha`
  bistropha(2),

  /// `neumeType_TYPE_cephalicus`
  cephalicus(3),

  /// `neumeType_TYPE_climacus`
  climacus(4),

  /// `neumeType_TYPE_clivis`
  clivis(5),

  /// `neumeType_TYPE_epiphonus`
  epiphonus(6),

  /// `neumeType_TYPE_oriscus`
  oriscus(7),

  /// `neumeType_TYPE_pes`
  pes(8),

  /// `neumeType_TYPE_pessubpunctis`
  pessubpunctis(9),

  /// `neumeType_TYPE_porrectus`
  porrectus(10),

  /// `neumeType_TYPE_porrectusflexus`
  porrectusflexus(11),

  /// `neumeType_TYPE_pressusmaior`
  pressusmaior(12),

  /// `neumeType_TYPE_pressusminor`
  pressusminor(13),

  /// `neumeType_TYPE_punctum`
  punctum(14),

  /// `neumeType_TYPE_quilisma`
  quilisma(15),

  /// `neumeType_TYPE_scandicus`
  scandicus(16),

  /// `neumeType_TYPE_strophicus`
  strophicus(17),

  /// `neumeType_TYPE_torculus`
  torculus(18),

  /// `neumeType_TYPE_torculusresupinus`
  torculusresupinus(19),

  /// `neumeType_TYPE_tristropha`
  tristropha(20),

  /// `neumeType_TYPE_virga`
  virga(21),

  /// `neumeType_TYPE_virgastrata`
  virgastrata(22),
  ;

  const NeumetypeType(this.value);

  final int value;

  static NeumetypeType fromValue(int value) =>
      NeumetypeType.values.firstWhere((e) => e.value == value,
          orElse: () => NeumetypeType.values.first);
}

/// MEI `noteGes_EXTREMIS`.
enum NotegesExtremis {
  /// `noteGes_EXTREMIS_NONE`
  none(0),

  /// `noteGes_EXTREMIS_highest`
  highest(1),

  /// `noteGes_EXTREMIS_lowest`
  lowest(2),
  ;

  const NotegesExtremis(this.value);

  final int value;

  static NotegesExtremis fromValue(int value) =>
      NotegesExtremis.values.firstWhere((e) => e.value == value,
          orElse: () => NotegesExtremis.values.first);
}

/// MEI `noteHeads_HEADAUTH`.
enum NoteheadsHeadauth {
  /// `noteHeads_HEADAUTH_NONE`
  none(0),

  /// `noteHeads_HEADAUTH_smufl`
  smufl(1),
  ;

  const NoteheadsHeadauth(this.value);

  final int value;

  static NoteheadsHeadauth fromValue(int value) =>
      NoteheadsHeadauth.values.firstWhere((e) => e.value == value,
          orElse: () => NoteheadsHeadauth.values.first);
}

/// MEI `octaveLog_COLL`.
enum OctavelogColl {
  /// `octaveLog_COLL_NONE`
  none(0),

  /// `octaveLog_COLL_coll`
  coll(1),
  ;

  const OctavelogColl(this.value);

  final int value;

  static OctavelogColl fromValue(int value) =>
      OctavelogColl.values.firstWhere((e) => e.value == value,
          orElse: () => OctavelogColl.values.first);
}

/// MEI `pbVis_FOLIUM`.
enum PbvisFolium {
  /// `pbVis_FOLIUM_NONE`
  none(0),

  /// `pbVis_FOLIUM_verso`
  verso(1),

  /// `pbVis_FOLIUM_recto`
  recto(2),
  ;

  const PbvisFolium(this.value);

  final int value;

  static PbvisFolium fromValue(int value) =>
      PbvisFolium.values.firstWhere((e) => e.value == value,
          orElse: () => PbvisFolium.values.first);
}

/// MEI `pedalLog_DIR`.
enum PedallogDir {
  /// `pedalLog_DIR_NONE`
  none(0),

  /// `pedalLog_DIR_down`
  down(1),

  /// `pedalLog_DIR_up`
  up(2),

  /// `pedalLog_DIR_half`
  half(3),

  /// `pedalLog_DIR_bounce`
  bounce(4),
  ;

  const PedallogDir(this.value);

  final int value;

  static PedallogDir fromValue(int value) =>
      PedallogDir.values.firstWhere((e) => e.value == value,
          orElse: () => PedallogDir.values.first);
}

/// MEI `pedalLog_FUNC`.
enum PedallogFunc {
  /// `pedalLog_FUNC_NONE`
  none(0),

  /// `pedalLog_FUNC_sustain`
  sustain(1),

  /// `pedalLog_FUNC_soft`
  soft(2),

  /// `pedalLog_FUNC_sostenuto`
  sostenuto(3),

  /// `pedalLog_FUNC_silent`
  silent(4),
  ;

  const PedallogFunc(this.value);

  final int value;

  static PedallogFunc fromValue(int value) =>
      PedallogFunc.values.firstWhere((e) => e.value == value,
          orElse: () => PedallogFunc.values.first);
}

/// MEI `pointing_XLINKACTUATE`.
enum PointingXlinkactuate {
  /// `pointing_XLINKACTUATE_NONE`
  none(0),

  /// `pointing_XLINKACTUATE_onLoad`
  onload(1),

  /// `pointing_XLINKACTUATE_onRequest`
  onrequest(2),

  /// `pointing_XLINKACTUATE_none`
  none0(3),

  /// `pointing_XLINKACTUATE_other`
  other(4),
  ;

  const PointingXlinkactuate(this.value);

  final int value;

  static PointingXlinkactuate fromValue(int value) =>
      PointingXlinkactuate.values.firstWhere((e) => e.value == value,
          orElse: () => PointingXlinkactuate.values.first);
}

/// MEI `pointing_XLINKSHOW`.
enum PointingXlinkshow {
  /// `pointing_XLINKSHOW_NONE`
  none(0),

  /// `pointing_XLINKSHOW_new`
  newValue(1),

  /// `pointing_XLINKSHOW_replace`
  replace(2),

  /// `pointing_XLINKSHOW_embed`
  embed(3),

  /// `pointing_XLINKSHOW_none`
  none0(4),

  /// `pointing_XLINKSHOW_other`
  other(5),
  ;

  const PointingXlinkshow(this.value);

  final int value;

  static PointingXlinkshow fromValue(int value) =>
      PointingXlinkshow.values.firstWhere((e) => e.value == value,
          orElse: () => PointingXlinkshow.values.first);
}

/// MEI `recordType_RECORDTYPE`.
enum RecordtypeRecordtype {
  /// `recordType_RECORDTYPE_NONE`
  none(0),

  /// `recordType_RECORDTYPE_a`
  a(1),

  /// `recordType_RECORDTYPE_c`
  c(2),

  /// `recordType_RECORDTYPE_d`
  d(3),

  /// `recordType_RECORDTYPE_e`
  e(4),

  /// `recordType_RECORDTYPE_f`
  f(5),

  /// `recordType_RECORDTYPE_g`
  g(6),

  /// `recordType_RECORDTYPE_i`
  i(7),

  /// `recordType_RECORDTYPE_j`
  j(8),

  /// `recordType_RECORDTYPE_k`
  k(9),

  /// `recordType_RECORDTYPE_m`
  m(10),

  /// `recordType_RECORDTYPE_o`
  o(11),

  /// `recordType_RECORDTYPE_p`
  p(12),

  /// `recordType_RECORDTYPE_r`
  r(13),

  /// `recordType_RECORDTYPE_t`
  t(14),
  ;

  const RecordtypeRecordtype(this.value);

  final int value;

  static RecordtypeRecordtype fromValue(int value) =>
      RecordtypeRecordtype.values.firstWhere((e) => e.value == value,
          orElse: () => RecordtypeRecordtype.values.first);
}

/// MEI `regularMethod_METHOD`.
enum RegularmethodMethod {
  /// `regularMethod_METHOD_NONE`
  none(0),

  /// `regularMethod_METHOD_silent`
  silent(1),

  /// `regularMethod_METHOD_markup`
  markup(2),
  ;

  const RegularmethodMethod(this.value);

  final int value;

  static RegularmethodMethod fromValue(int value) =>
      RegularmethodMethod.values.firstWhere((e) => e.value == value,
          orElse: () => RegularmethodMethod.values.first);
}

/// MEI `rehearsal_REHENCLOSE`.
enum RehearsalRehenclose {
  /// `rehearsal_REHENCLOSE_NONE`
  none(0),

  /// `rehearsal_REHENCLOSE_box`
  box(1),

  /// `rehearsal_REHENCLOSE_circle`
  circle(2),

  /// `rehearsal_REHENCLOSE_none`
  none0(3),
  ;

  const RehearsalRehenclose(this.value);

  final int value;

  static RehearsalRehenclose fromValue(int value) =>
      RehearsalRehenclose.values.firstWhere((e) => e.value == value,
          orElse: () => RehearsalRehenclose.values.first);
}

/// MEI `repeatMarkLog_FUNC`.
enum RepeatmarklogFunc {
  /// `repeatMarkLog_FUNC_NONE`
  none(0),

  /// `repeatMarkLog_FUNC_coda`
  coda(1),

  /// `repeatMarkLog_FUNC_segno`
  segno(2),

  /// `repeatMarkLog_FUNC_dalSegno`
  dalsegno(3),

  /// `repeatMarkLog_FUNC_daCapo`
  dacapo(4),

  /// `repeatMarkLog_FUNC_fine`
  fine(5),

  /// `repeatMarkLog_FUNC_daCapoAlFine`
  dacapoalfine(6),

  /// `repeatMarkLog_FUNC_dalSegnoAlFine`
  dalsegnoalfine(7),

  /// `repeatMarkLog_FUNC_daCapoAlCoda`
  dacapoalcoda(8),

  /// `repeatMarkLog_FUNC_dalSegnoAlCoda`
  dalsegnoalcoda(9),

  /// `repeatMarkLog_FUNC_repeatLeft`
  repeatleft(10),

  /// `repeatMarkLog_FUNC_repeatRight`
  repeatright(11),

  /// `repeatMarkLog_FUNC_repeatRightLeft`
  repeatrightleft(12),
  ;

  const RepeatmarklogFunc(this.value);

  final int value;

  static RepeatmarklogFunc fromValue(int value) =>
      RepeatmarklogFunc.values.firstWhere((e) => e.value == value,
          orElse: () => RepeatmarklogFunc.values.first);
}

/// MEI `sbVis_FORM`.
enum SbvisForm {
  /// `sbVis_FORM_NONE`
  none(0),

  /// `sbVis_FORM_hash`
  hash(1),
  ;

  const SbvisForm(this.value);

  final int value;

  static SbvisForm fromValue(int value) =>
      SbvisForm.values.firstWhere((e) => e.value == value,
          orElse: () => SbvisForm.values.first);
}

/// MEI `staffGroupingSym_SYMBOL`.
enum StaffgroupingsymSymbol {
  /// `staffGroupingSym_SYMBOL_NONE`
  none(0),

  /// `staffGroupingSym_SYMBOL_brace`
  brace(1),

  /// `staffGroupingSym_SYMBOL_bracket`
  bracket(2),

  /// `staffGroupingSym_SYMBOL_bracketsq`
  bracketsq(3),

  /// `staffGroupingSym_SYMBOL_line`
  line(4),

  /// `staffGroupingSym_SYMBOL_none`
  none0(5),
  ;

  const StaffgroupingsymSymbol(this.value);

  final int value;

  static StaffgroupingsymSymbol fromValue(int value) =>
      StaffgroupingsymSymbol.values.firstWhere((e) => e.value == value,
          orElse: () => StaffgroupingsymSymbol.values.first);
}

/// MEI `sylLog_CON`.
enum SyllogCon {
  /// `sylLog_CON_NONE`
  none(0),

  /// `sylLog_CON_s`
  s(1),

  /// `sylLog_CON_d`
  d(2),

  /// `sylLog_CON_u`
  u(3),

  /// `sylLog_CON_t`
  t(4),

  /// `sylLog_CON_c`
  c(5),

  /// `sylLog_CON_v`
  v(6),

  /// `sylLog_CON_i`
  i(7),

  /// `sylLog_CON_b`
  b(8),
  ;

  const SyllogCon(this.value);

  final int value;

  static SyllogCon fromValue(int value) =>
      SyllogCon.values.firstWhere((e) => e.value == value,
          orElse: () => SyllogCon.values.first);
}

/// MEI `sylLog_WORDPOS`.
enum SyllogWordpos {
  /// `sylLog_WORDPOS_NONE`
  none(0),

  /// `sylLog_WORDPOS_i`
  i(1),

  /// `sylLog_WORDPOS_m`
  m(2),

  /// `sylLog_WORDPOS_s`
  s(3),

  /// `sylLog_WORDPOS_t`
  t(4),
  ;

  const SyllogWordpos(this.value);

  final int value;

  static SyllogWordpos fromValue(int value) =>
      SyllogWordpos.values.firstWhere((e) => e.value == value,
          orElse: () => SyllogWordpos.values.first);
}

/// MEI `targetEval_EVALUATE`.
enum TargetevalEvaluate {
  /// `targetEval_EVALUATE_NONE`
  none(0),

  /// `targetEval_EVALUATE_all`
  all(1),

  /// `targetEval_EVALUATE_one`
  one(2),

  /// `targetEval_EVALUATE_none`
  none0(3),
  ;

  const TargetevalEvaluate(this.value);

  final int value;

  static TargetevalEvaluate fromValue(int value) =>
      TargetevalEvaluate.values.firstWhere((e) => e.value == value,
          orElse: () => TargetevalEvaluate.values.first);
}

/// MEI `tempoLog_FUNC`.
enum TempologFunc {
  /// `tempoLog_FUNC_NONE`
  none(0),

  /// `tempoLog_FUNC_continuous`
  continuous(1),

  /// `tempoLog_FUNC_instantaneous`
  instantaneous(2),

  /// `tempoLog_FUNC_metricmod`
  metricmod(3),

  /// `tempoLog_FUNC_precedente`
  precedente(4),
  ;

  const TempologFunc(this.value);

  final int value;

  static TempologFunc fromValue(int value) =>
      TempologFunc.values.firstWhere((e) => e.value == value,
          orElse: () => TempologFunc.values.first);
}

/// MEI `tremForm_FORM`.
enum TremformForm {
  /// `tremForm_FORM_NONE`
  none(0),

  /// `tremForm_FORM_meas`
  meas(1),

  /// `tremForm_FORM_unmeas`
  unmeas(2),
  ;

  const TremformForm(this.value);

  final int value;

  static TremformForm fromValue(int value) =>
      TremformForm.values.firstWhere((e) => e.value == value,
          orElse: () => TremformForm.values.first);
}

/// MEI `tupletVis_NUMFORMAT`.
enum TupletvisNumformat {
  /// `tupletVis_NUMFORMAT_NONE`
  none(0),

  /// `tupletVis_NUMFORMAT_count`
  count(1),

  /// `tupletVis_NUMFORMAT_ratio`
  ratio(2),
  ;

  const TupletvisNumformat(this.value);

  final int value;

  static TupletvisNumformat fromValue(int value) =>
      TupletvisNumformat.values.firstWhere((e) => e.value == value,
          orElse: () => TupletvisNumformat.values.first);
}

/// MEI `turnLog_FORM`.
enum TurnlogForm {
  /// `turnLog_FORM_NONE`
  none(0),

  /// `turnLog_FORM_lower`
  lower(1),

  /// `turnLog_FORM_upper`
  upper(2),
  ;

  const TurnlogForm(this.value);

  final int value;

  static TurnlogForm fromValue(int value) =>
      TurnlogForm.values.firstWhere((e) => e.value == value,
          orElse: () => TurnlogForm.values.first);
}

/// MEI `voltaGroupingSym_VOLTASYM`.
enum VoltagroupingsymVoltasym {
  /// `voltaGroupingSym_VOLTASYM_NONE`
  none(0),

  /// `voltaGroupingSym_VOLTASYM_brace`
  brace(1),

  /// `voltaGroupingSym_VOLTASYM_bracket`
  bracket(2),

  /// `voltaGroupingSym_VOLTASYM_bracketsq`
  bracketsq(3),

  /// `voltaGroupingSym_VOLTASYM_line`
  line(4),

  /// `voltaGroupingSym_VOLTASYM_none`
  none0(5),
  ;

  const VoltagroupingsymVoltasym(this.value);

  final int value;

  static VoltagroupingsymVoltasym fromValue(int value) =>
      VoltagroupingsymVoltasym.values.firstWhere((e) => e.value == value,
          orElse: () => VoltagroupingsymVoltasym.values.first);
}

/// MEI `whitespace_XMLSPACE`.
enum WhitespaceXmlspace {
  /// `whitespace_XMLSPACE_NONE`
  none(0),

  /// `whitespace_XMLSPACE_default`
  defaultValue(1),

  /// `whitespace_XMLSPACE_preserve`
  preserve(2),
  ;

  const WhitespaceXmlspace(this.value);

  final int value;

  static WhitespaceXmlspace fromValue(int value) =>
      WhitespaceXmlspace.values.firstWhere((e) => e.value == value,
          orElse: () => WhitespaceXmlspace.values.first);
}
