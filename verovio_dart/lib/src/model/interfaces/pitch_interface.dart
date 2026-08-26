/// Port of `pitchinterface.h/cpp` — interface for elements with pitch, such
/// as notes and neumes.
library;

import 'package:verovio_dart/src/core/attdef.dart';
import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/model/atts/atts_gestural.dart';
import 'package:verovio_dart/src/model/atts/atts_shared.dart';
import 'package:verovio_dart/src/model/atts/mei_enums.dart';
import 'package:verovio_dart/src/model/interfaces/interface.dart';

/// Mirrors `vrv::PitchInterface`.
///
/// Apply together with [AttNoteGes], [AttOctave], [AttPitch] and
/// [AttPitchGes].
mixin PitchInterface
    on AttNoteGes, AttOctave, AttPitch, AttPitchGes
    implements Interface {
  /// The default octave: extracted from scoreDef/staffDef and used when no
  /// octave attribute is given.
  int octDefault = meiUnsetOct;

  @override
  InterfaceId get interfaceId => InterfaceId.pitch;

  @override
  void reset() {
    // Resetting the attribute members means clearing them (unset).
    pnameGes = null;
    octGes = null;
    pname = null;
    oct = null;
    octDefault = meiUnsetOct;
  }

  bool get hasOctDefault => octDefault != meiUnsetOct;

  /// Copies the interface state from [other].
  void copyPitchFrom(covariant PitchInterface other) {
    pnameGes = other.pnameGes;
    octGes = other.octGes;
    pname = other.pname;
    oct = other.oct;
    octDefault = other.octDefault;
  }

  void setOctDefault(int oct) => octDefault = oct;

  /// Mirrors `HasIdenticalPitchInterface` — unimplemented in the C++ as well
  /// (logs an error and returns false).
  bool hasIdenticalPitchInterface(PitchInterface? other) {
    logError('PitchInterface::HasIdenticalPitchInterface missing');
    assert(false);
    return false;
  }

  /// Shift pname and octave by a certain number of steps.
  void adjustPitchByOffset(int pitchOffset) {
    int p = (pname?.value ?? Pitchname.none.value) + pitchOffset;
    // Unset octave falls back to the C++ sentinel value (-127); the clamps
    // below bring it back into range.
    int o = oct ?? meiUnsetOct;

    // Check if a change in octave is necessary.
    while (p > Pitchname.b.value) {
      p -= 7;
      o++;
    }
    while (p < Pitchname.c.value) {
      p += 7;
      o--;
    }

    // If it falls out of allowed range, set to allowed extreme values.
    if (o > 9) {
      o = 9;
      p = Pitchname.b.value;
    } else if (o < 0) {
      o = 0;
      p = Pitchname.c.value;
    }

    pname = Pitchname.fromValue(p);
    oct = o;
  }

  /// Get steps between calling object and parameter. Returns calling pitch
  /// minus parameter pitch.
  int pitchDifferenceTo(PitchInterface pi) {
    final int mine = pname?.value ?? Pitchname.none.value;
    final int theirs = pi.pname?.value ?? Pitchname.none.value;
    return mine - theirs + 7 * ((oct ?? 0) - (pi.oct ?? 0));
  }

  //----------------//
  // Static methods //
  //----------------//

  /// Adjust the pname and the octave for values outside the range.
  static void adjustPname(List<int> pnameAndOct) {
    assert(pnameAndOct.length == 2);
    int pname = pnameAndOct[0];
    int oct = pnameAndOct[1];
    if (pname < Pitchname.c.value) {
      if (oct > 0) oct--;
      pname = Pitchname.b.value;
    } else if (pname > Pitchname.b.value) {
      if (oct < 7) oct++;
      pname = Pitchname.c.value;
    }
    pnameAndOct[0] = pname;
    pnameAndOct[1] = oct;
  }

  /// Calculate the loc for a pitch and octave considering the clef loc
  /// offset. E.g., return 0 for C4 with clef C1, -2 with clef G2.
  ///
  /// The element-aware overload (`CalcLoc(element, layer, ...)`) arrives with
  /// the element classes.
  static int calcLoc(Pitchname pname, int oct, int clefLocOffset) {
    // E.g., C4 with clef C1: (4 - 4 * 7) + (1 - 1) + 0;
    return (oct - octaveOffset) * 7 + (pname.value - 1) + clefLocOffset;
  }
}
