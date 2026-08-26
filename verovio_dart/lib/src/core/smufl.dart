/// Port of `smufl.h` — SMuFL constants used by the core.
library;

import 'package:verovio_dart/src/core/vrvdef.dart';

/// The number of default SMuFL glyphs expected in the fallback fonts
/// (`SMUFL_COUNT`).
const int smuflCount = 650;

// SMuFL accidental glyph code points (used by `Accid::GetAccidGlyph`).
const int smuflE0A4NoteheadBlack = 0xE0A4;
const int smuflE220Tremolo1 = 0xE220;
const int smuflE260AccidentalFlat = 0xE260;
const int smuflE261AccidentalNatural = 0xE261;
const int smuflE262AccidentalSharp = 0xE262;
const int smuflE263AccidentalDoubleSharp = 0xE263;
const int smuflE264AccidentalDoubleFlat = 0xE264;
const int smuflE265AccidentalTripleSharp = 0xE265;
const int smuflE266AccidentalTripleFlat = 0xE266;
const int smuflE267AccidentalNaturalFlat = 0xE267;
const int smuflE268AccidentalNaturalSharp = 0xE268;
const int smuflE269AccidentalSharpSharp = 0xE269;
const int smuflE270AccidentalQuarterToneFlatArrowUp = 0xE270;
const int smuflE271AccidentalThreeQuarterTonesFlatArrowDown = 0xE271;
const int smuflE272AccidentalQuarterToneSharpNaturalArrowUp = 0xE272;
const int smuflE273AccidentalQuarterToneFlatNaturalArrowDown = 0xE273;
const int smuflE274AccidentalThreeQuarterTonesSharpArrowUp = 0xE274;
const int smuflE275AccidentalQuarterToneSharpArrowDown = 0xE275;
const int smuflE280AccidentalQuarterToneFlatStein = 0xE280;
const int smuflE281AccidentalThreeQuarterTonesFlatZimmermann = 0xE281;
const int smuflE282AccidentalQuarterToneSharpStein = 0xE282;
const int smuflE283AccidentalThreeQuarterTonesSharpStein = 0xE283;
const int smuflE440AccidentalBuyukMucennebFlat = 0xE440;
const int smuflE441AccidentalKucukMucennebFlat = 0xE441;
const int smuflE442AccidentalBakiyeFlat = 0xE442;
const int smuflE443AccidentalKomaFlat = 0xE443;
const int smuflE444AccidentalKomaSharp = 0xE444;
const int smuflE445AccidentalBakiyeSharp = 0xE445;
const int smuflE446AccidentalKucukMucennebSharp = 0xE446;
const int smuflE447AccidentalBuyukMucennebSharp = 0xE447;
const int smuflE460AccidentalKoron = 0xE460;
const int smuflE461AccidentalSori = 0xE461;

// SMuFL chant / neume glyphs used by CalcLigatureOrNeumePosFunctor.
const int smuflE990ChantPunctum = 0xE990;
const int smuflE991ChantPunctumInclinatum = 0xE991;
const int smuflE994ChantAuctumAsc = 0xE994;
const int smuflE995ChantAuctumDesc = 0xE995;
const int smuflE996ChantPunctumVirga = 0xE996;
const int smuflE997ChantPunctumVirgaReversed = 0xE997;
const int smuflE99BChantQuilisma = 0xE99B;
const int smuflE9A1ChantPunctumDeminutum = 0xE9A1;
const int smuflE9B4ChantEntryLineAsc2nd = 0xE9B4;
const int smuflE9B5ChantEntryLineAsc3rd = 0xE9B5;
const int smuflE9B6ChantEntryLineAsc4th = 0xE9B6;
const int smuflE9B7ChantEntryLineAsc5th = 0xE9B7;
const int smuflE9B9ChantLigaturaDesc2nd = 0xE9B9;
const int smuflE9BAChantLigaturaDesc3rd = 0xE9BA;
const int smuflE9BBChantLigaturaDesc4th = 0xE9BB;
const int smuflE9BCChantLigaturaDesc5th = 0xE9BC;
const int smuflE9BEChantConnectingLineAsc3rd = 0xE9BE;
const int smuflEA29MedRenStrophicusCMN = 0xEA29;
const int smuflEA2AMedRenOriscusCMN = 0xEA2A;

// SMuFL noteheads used by LayerElement::GetDrawingRadius.
const int smuflE0A1NoteheadDoubleWholeSquare = 0xE0A1;
const int smuflE0A2NoteheadWhole = 0xE0A2;
const int smuflE0A3NoteheadHalf = 0xE0A3;

/// Static method that converts unicode music code points to their SMuFL
/// equivalent (mirrors `Resources::GetSmuflGlyphForUnicodeChar`).
/// Returns [unicodeChar] itself if nothing can be converted.
int getSmuflGlyphForUnicodeChar(int unicodeChar) {
  switch (unicodeChar) {
    case unicodeDalSegno:
      return 0xE045; // SMUFL_E045_dalSegno
    case unicodeDaCapo:
      return 0xE046; // SMUFL_E046_daCapo
    case unicodeSegno:
      return 0xE047; // SMUFL_E047_segno
    case unicodeCoda:
      return 0xE048; // SMUFL_E048_coda
    default:
      return unicodeChar;
  }
}
