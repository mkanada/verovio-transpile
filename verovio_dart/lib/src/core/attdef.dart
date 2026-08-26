/// Port of `libmei/addons/attdef.h` — hand-coded MEI data defines.
library;

/// Value used for unset MEI attributes (mirrors `MEI_UNSET`).
const int meiUnset = -0x7FFFFFFF;

/// Value used for an unset octave (mirrors `MEI_UNSET_OCT`).
const int meiUnsetOct = -127;

/// Maximum duration denominator used for alignment (mirrors `DUR_MAX`).
const int durMax = 2048;

// ---------------------------------------------------------------------------
// data.DURATION
// ---------------------------------------------------------------------------

/// Mirrors `data_DURATION`. [MeiDuration.value] keeps the C++ numeric values
/// (including the negative and mensural ranges).
///
/// Named `MeiDuration` (instead of `Duration`) to avoid clashing with
/// `dart:core`'s [Duration]. Constants `dur1`..`dur2048` mirror
/// `DURATION_1`..`DURATION_2048`.
enum MeiDuration implements Comparable<MeiDuration> {
  none(-2),
  maxima(-1),
  long(0),
  breve(1),
  dur1(2),
  dur2(3),
  dur4(4),
  dur8(5),
  dur16(6),
  dur32(7),
  dur64(8),
  dur128(9),
  dur256(10),
  dur512(11),
  dur1024(12),
  dur2048(13),
  longa(100),
  brevis(101),
  semibrevis(102),
  minima(103),
  semiminima(104),
  fusa(105),
  semifusa(106);

  const MeiDuration(this.value);

  final int value;

  /// Returns the duration with the given [value]
  /// (mirrors `static_cast<data_DURATION>`).
  static MeiDuration fromValue(int value) =>
      MeiDuration.values.firstWhere((e) => e.value == value);

  @override
  int compareTo(MeiDuration other) => value.compareTo(other.value);

  /// Mirrors `vrv::DurationMin`.
  static MeiDuration min(MeiDuration a, MeiDuration b) =>
      a.value <= b.value ? a : b;

  /// Mirrors `vrv::DurationMax`.
  static MeiDuration max(MeiDuration a, MeiDuration b) =>
      a.value >= b.value ? a : b;
}

// ---------------------------------------------------------------------------
// data.PITCHNAME
// ---------------------------------------------------------------------------

enum PitchName {
  none(0),
  c(1),
  d(2),
  e(3),
  f(4),
  g(5),
  a(6),
  b(7);

  const PitchName(this.value);

  final int value;
}

// ---------------------------------------------------------------------------
// data.PITCHNAME.GES
// ---------------------------------------------------------------------------

enum PitchNameGes {
  none(0),
  c(1),
  d(2),
  e(3),
  f(4),
  g(5),
  a(6),
  b(7),
  none_(8);

  const PitchNameGes(this.value);

  final int value;
}

// ---------------------------------------------------------------------------
// MeterCountSign
// ---------------------------------------------------------------------------

enum MeterCountSign {
  none,
  slash,
  minus,
  asterisk,
  plus,
}

// ---------------------------------------------------------------------------
// data.FONTSTYLE
// ---------------------------------------------------------------------------

/// Mirrors `data_FONTSTYLE` (numeric values kept).
enum FontStyle {
  none_(0),
  italic(1),
  normal(2),
  oblique(3);

  const FontStyle(this.value);

  final int value;

  static FontStyle fromValue(int value) =>
      FontStyle.values.firstWhere((e) => e.value == value);
}

// ---------------------------------------------------------------------------
// data.FONTWEIGHT
// ---------------------------------------------------------------------------

/// Mirrors `data_FONTWEIGHT` (numeric values kept).
enum FontWeight {
  none_(0),
  bold(1),
  normal(2);

  const FontWeight(this.value);

  final int value;

  static FontWeight fromValue(int value) =>
      FontWeight.values.firstWhere((e) => e.value == value);
}

// ---------------------------------------------------------------------------
// data.HORIZONTALALIGNMENT
// ---------------------------------------------------------------------------

/// Mirrors `data_HORIZONTALALIGNMENT` (numeric values kept).
enum HorizontalAlignment {
  none_(0),
  left(1),
  right(2),
  center(3),
  justify(4);

  const HorizontalAlignment(this.value);

  final int value;

  static HorizontalAlignment fromValue(int value) =>
      HorizontalAlignment.values.firstWhere((e) => e.value == value);
}
