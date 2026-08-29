/// Port of `smufl.h` — SMuFL constants used by the core.
library;

import 'package:verovio_dart/src/core/vrvdef.dart';

/// The number of default SMuFL glyphs expected in the fallback fonts
/// (`SMUFL_COUNT`).
const int smuflCount = 650;

// Lyric elision glyph code points (`option_ELISION` in options.h); the
// Unicode undertie alternative (`UNICODE_UNDERTIE`) lives in vrvdef.dart.
// Used by `Syl::CalcConnectorSpacing`.
const int smuflE550LyricsElisionNarrow = 0xE550;
const int smuflE551LyricsElision = 0xE551;
const int smuflE552LyricsElisionWide = 0xE552;

// SMuFL accidental glyph code points (used by `Accid::GetAccidGlyph`).
const int smuflE0A4NoteheadBlack = 0xE0A4;
const int smuflE220Tremolo1 = 0xE220;
const int smuflE240Flag8thUp = 0xE240;
const int smuflE241Flag8thDown = 0xE241;
const int smuflE242Flag16thUp = 0xE242;
const int smuflE243Flag16thDown = 0xE243;
const int smuflE244Flag32ndUp = 0xE244;
const int smuflE245Flag32ndDown = 0xE245;
const int smuflE246Flag64thUp = 0xE246;
const int smuflE247Flag64thDown = 0xE247;
const int smuflE248Flag128thUp = 0xE248;
const int smuflE249Flag128thDown = 0xE249;
const int smuflE24AFlag256thUp = 0xE24A;
const int smuflE24BFlag256thDown = 0xE24B;
const int smuflE24CFlag512thUp = 0xE24C;
const int smuflE24DFlag512thDown = 0xE24D;
const int smuflE24EFlag1024thUp = 0xE24E;
const int smuflE24FFlag1024thDown = 0xE24F;
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

// SMuFL ornaments used by Turn::GetTurnHeight (turn.cpp:87) and
// FloatingPositioner::CalcDrawingYRel (floatingobject.cpp:503).
const int smuflE567OrnamentTurn = 0xE567;
const int smuflE568OrnamentTurnInverted = 0xE568;
const int smuflE569OrnamentTurnSlash = 0xE569;
const int smuflE56COrnamentShortTrill = 0xE56C;
const int smuflE56DOrnamentMordent = 0xE56D;

// SMuFL staffGrp symbols used by View::DrawGrpSym / DrawBracket / DrawBrace
// (view_page.cpp:403-677).
const int smuflE000Brace = 0xE000; // SMUFL_E000_brace
const int smuflE003BracketTop = 0xE003; // SMUFL_E003_bracketTop
const int smuflE004BracketBottom = 0xE004; // SMUFL_E004_bracketBottom
const int smuflE044RepeatDot = 0xE044; // SMUFL_E044_repeatDot
const int smuflE04ASegnoSerpent1 = 0xE04A; // SMUFL_E04A_segnoSerpent1
const int smuflE08CTimeSigPlus = 0xE08C; // SMUFL_E08C_timeSigPlus

// SMuFL clefs used by Clef::GetClefGlyph (clef.cpp:132).
const int smuflE050Gclef = 0xE050; // SMUFL_E050_gClef
const int smuflE051GClef15mb = 0xE051; // SMUFL_E051_gClef15mb
const int smuflE052GClef8vb = 0xE052; // SMUFL_E052_gClef8vb
const int smuflE053GClef8va = 0xE053; // SMUFL_E053_gClef8va
const int smuflE054GClef15ma = 0xE054; // SMUFL_E054_gClef15ma
const int smuflE055GClef8vbOld = 0xE055; // SMUFL_E055_gClef8vbOld
const int smuflE05CCclef = 0xE05C; // SMUFL_E05C_cClef
const int smuflE05DCclef8vb = 0xE05D; // SMUFL_E05D_cClef8vb
const int smuflE062Fclef = 0xE062; // SMUFL_E062_fClef
const int smuflE063FClef15mb = 0xE063; // SMUFL_E063_fClef15mb
const int smuflE064FClef8vb = 0xE064; // SMUFL_E064_fClef8vb
const int smuflE065FClef8va = 0xE065; // SMUFL_E065_fClef8va
const int smuflE066FClef15ma = 0xE066; // SMUFL_E066_fClef15ma
const int smuflE069UnpitchedPercussionClef1 =
    0xE069; // SMUFL_E069_unpitchedPercussionClef1
const int smuflE06D6stringTabClef = 0xE06D; // SMUFL_E06D_6stringTabClef
const int smuflE900MensuralGclef = 0xE900; // SMUFL_E900_mensuralGclef
const int smuflE901MensuralGclefPetrucci =
    0xE901; // SMUFL_E901_mensuralGclefPetrucci
const int smuflE902ChantFclef = 0xE902; // SMUFL_E902_chantFclef
const int smuflE904MensuralFclefPetrucci =
    0xE904; // SMUFL_E904_mensuralFclefPetrucci
const int smuflE906ChantCclef = 0xE906; // SMUFL_E906_chantCclef
const int smuflE907MensuralCclefPetrucciPosLowest =
    0xE907; // SMUFL_E907_mensuralCclefPetrucciPosLowest
const int smuflE908MensuralCclefPetrucciPosLow =
    0xE908; // SMUFL_E908_mensuralCclefPetrucciPosLow
const int smuflE909MensuralCclefPetrucciPosMiddle =
    0xE909; // SMUFL_E909_mensuralCclefPetrucciPosMiddle
const int smuflE90AMensuralCclefPetrucciPosHigh =
    0xE90A; // SMUFL_E90A_mensuralCclefPetrucciPosHigh
const int smuflE90BMensuralCclefPetrucciPosHighest =
    0xE90B; // SMUFL_E90B_mensuralCclefPetrucciPosHighest

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
