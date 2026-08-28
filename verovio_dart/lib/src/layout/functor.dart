/// Port of `functor.h`, `functorinterface.h` and the default visit
/// implementations of `functorinterface.cpp` — the functor framework used by
/// the layout engine.
///
/// Dispatch design: C++ resolves the visited method through the per-class
/// `Accept()` overrides (`Lv::Accept` calls `VisitLv`, `Episema` has no
/// override and is routed to `LayerElement::Accept`, editorial leaves share
/// `EditorialElement::Accept`…). Dart has no virtual double dispatch, so the
/// resolution is done inside [Functor.visit] / [Functor.visitEnd] with the
/// [kAcceptChain] table (ClassId → ClassId visited as) followed by a switch
/// calling the typed visit method.
///
/// The default bodies of the visit methods mirror `functorinterface.cpp`:
/// every visit delegates to its parent visit (e.g., `visitNote` →
/// `visitLayerElement` → `visitObject`), so a functor overriding only
/// [Functor.visitObject] sees every node.
///
/// Deviations from the C++:
/// - `ConstFunctor` / `ConstFunctorInterface` are not ported (Dart has no
///   const object tree; the mutable functors cover both usages).
/// - `ImplementsEndInterface` defaults to true in [Functor] instead of being
///   abstract: whether an end method is overridden cannot be detected in
///   Dart, and calling the default end implementations is behaviourally
///   equivalent since they return FUNCTOR_CONTINUE.
/// - The OSSIA deepness exception exists only in the C++ const `Process`;
///   the Dart [Object.process] mirrors the mutable one.
library;

import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/layout/horizontal_aligner.dart'
    show
        Alignment,
        AlignmentReference,
        GraceAligner,
        HorizontalAligner,
        MeasureAligner,
        TimestampAligner;
import 'package:verovio_dart/src/layout/vertical_aligner.dart'
    show StaffAlignment, SystemAligner;
import 'package:verovio_dart/src/model/basic_elements.dart';
import 'package:verovio_dart/src/model/comparison.dart' show Filters;
import 'package:verovio_dart/src/model/control_element.dart';
import 'package:verovio_dart/src/model/control_elements_gen.dart';
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/model/editorial_element.dart';
import 'package:verovio_dart/src/model/floating_object.dart';
import 'package:verovio_dart/src/model/layer_element.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart';
import 'package:verovio_dart/src/model/mensur.dart';
import 'package:verovio_dart/src/model/misc_elements_gen.dart';
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/model/scoredef.dart';
import 'package:verovio_dart/src/model/system_page_elements.dart';
import 'package:verovio_dart/src/model/text_elements.dart';
import 'package:verovio_dart/src/model/zone.dart';

// ---------------------------------------------------------------------------
// Accept chain
// ---------------------------------------------------------------------------

/// Resolution of the C++ `Accept()` inheritance: maps the ClassIds of classes
/// that do **not** define their own `Accept()` to the ClassId whose VisitXxx
/// is invoked. All ClassIds missing from this table are visited as themselves.
const Map<ClassId, ClassId> kAcceptChain = {
  // Layer elements without a dedicated Accept are visited as LayerElement
  // (mirrors the missing Accept overrides in divline.cpp, episema.cpp,
  // liquescent.cpp, oriscus.cpp, quilisma.cpp and strophicus.cpp).
  ClassId.divLine: ClassId.layerElement,
  ClassId.epistema: ClassId.layerElement,
  ClassId.liquescent: ClassId.layerElement,
  ClassId.oriscus: ClassId.layerElement,
  ClassId.quilisma: ClassId.layerElement,
  ClassId.strophicus: ClassId.layerElement,
  // Editorial element subclasses share EditorialElement::Accept.
  ClassId.abbr: ClassId.editorialElement,
  ClassId.add: ClassId.editorialElement,
  ClassId.annot: ClassId.editorialElement,
  ClassId.app: ClassId.editorialElement,
  ClassId.choice: ClassId.editorialElement,
  ClassId.corr: ClassId.editorialElement,
  ClassId.damage: ClassId.editorialElement,
  ClassId.del: ClassId.editorialElement,
  ClassId.expan: ClassId.editorialElement,
  ClassId.lem: ClassId.editorialElement,
  ClassId.orig: ClassId.editorialElement,
  ClassId.rdg: ClassId.editorialElement,
  ClassId.ref: ClassId.editorialElement,
  ClassId.reg: ClassId.editorialElement,
  ClassId.restore: ClassId.editorialElement,
  ClassId.sic: ClassId.editorialElement,
  ClassId.subst: ClassId.editorialElement,
  ClassId.supplied: ClassId.editorialElement,
  ClassId.unclear: ClassId.editorialElement,
  // Objects extending Object without their own Accept.
  ClassId.symbolDef: ClassId.object,
  ClassId.symbolTable: ClassId.object,
  ClassId.accidFloating: ClassId.floatingObject,
  ClassId.floatingPositioner: ClassId.object,
  ClassId.floatingCurvePositioner: ClassId.object,
};

/// Return the ClassId whose VisitXxx method is invoked for [classId]
/// (mirrors the virtual `Accept` call resolution).
ClassId acceptClassId(ClassId classId) => kAcceptChain[classId] ?? classId;

// ---------------------------------------------------------------------------
// FunctorBase
// ---------------------------------------------------------------------------

/// This abstract class contains functionality that is common to all functors
/// (mirrors `vrv::FunctorBase`).
abstract class FunctorBase {
  /// Opt-in execution trace of functor runs (port-only test hook; no C++
  /// counterpart — the C++ pipeline order is verified by reading `page.cpp`).
  ///
  /// When non-null, every [Object.process] call that starts while no other
  /// process call is on the stack appends the functor's runtime type name to
  /// this list, in execution order — i.e. it records the top-level pipeline
  /// functors, not the sub-functors a functor may drive from inside its
  /// visits (`GetAlignmentLeftRightFunctor` from `GetLeftRight`,
  /// `AdjustTupletNumOverlapFunctor` from `AdjustTupletsY`, …). Tests set it
  /// before a layout phase and reset it to null afterwards.
  static List<String>? executionTrace;

  /// Depth of currently running [Object.process] calls; drives
  /// [executionTrace] (see there).
  static int processDepth = 0;

  FunctorCode _code = FunctorCode.continue_;
  Filters? _filters;
  bool _visibleOnly = true;
  bool _direction = forward;

  /// Getter for the functor code which controls traversal (mirrors
  /// `GetCode`).
  FunctorCode get code => _code;

  /// Reset the functor code to [FunctorCode.continue_] (mirrors
  /// `ResetCode`).
  void resetCode() => _code = FunctorCode.continue_;

  /// Set the functor code (mirrors `SetCode`).
  void setCode(FunctorCode code) => _code = code;

  /// Getter for the visibility flag (mirrors `VisibleOnly`).
  bool get visibleOnly => _visibleOnly;

  /// Setter for the visibility flag (mirrors `SetVisibleOnly`).
  void setVisibleOnly(bool visibleOnly) => _visibleOnly = visibleOnly;

  /// Getter for the filters (mirrors `GetFilters`).
  Filters? get filters => _filters;

  /// Set the filters and return the previous value (mirrors `SetFilters`).
  Filters? setFilters(Filters? filters) {
    final Filters? previous = _filters;
    _filters = filters;
    return previous;
  }

  /// Getter for the direction (mirrors `GetDirection`).
  bool get direction => _direction;

  /// Set the direction and return the previous value (mirrors
  /// `SetDirection`).
  bool setDirection(bool direction) {
    final bool previous = _direction;
    _direction = direction;
    return previous;
  }

  /// Return true if the functor implements the end interface (mirrors
  /// `ImplementsEndInterface`).
  bool get implementsEndInterface;
}

// ---------------------------------------------------------------------------
// Functor
// ---------------------------------------------------------------------------

/// This abstract class is the base class for all functors (mirrors
/// `vrv::Functor`, itself combining `FunctorBase` and `FunctorInterface`).
///
/// Concrete functors override the typed `visitXxx` methods they need; the
/// default implementations delegate to the parent visit exactly like the C++
/// defaults in `functorinterface.cpp`. Use [visit] / [visitEnd] as entry
/// points — [Object.process] calls them through the dispatch described at the
/// top of this library.
abstract class Functor extends FunctorBase {
  @override
  bool get implementsEndInterface => true;

  // -------------------------------------------------------------------------
  // Dispatch (mirrors the per-class Accept methods)
  // -------------------------------------------------------------------------

  /// Visit [object], resolving the concrete visit method from its ClassId
  /// (the equivalent of `object->Accept(*this)`).
  FunctorCode visit(Object object) => _dispatch(object, false);

  /// Visit the end of [object] (the equivalent of `object->AcceptEnd(*this)`).
  FunctorCode visitEnd(Object object) => _dispatch(object, true);

  FunctorCode _dispatch(Object object, bool end) {
    switch (acceptClassId(object.classId)) {
      // Object and doc
      case ClassId.object:
        return end ? visitObjectEnd(object) : visitObject(object);
      case ClassId.doc:
        final Doc doc = object as Doc;
        return end ? visitDocEnd(doc) : visitDoc(doc);
      // Container elements
      case ClassId.pages:
        final Pages pages = object as Pages;
        return end ? visitPagesEnd(pages) : visitPages(pages);
      case ClassId.page:
        final Page page = object as Page;
        return end ? visitPageEnd(page) : visitPage(page);
      case ClassId.mdiv:
        final Mdiv mdiv = object as Mdiv;
        return end ? visitMdivEnd(mdiv) : visitMdiv(mdiv);
      case ClassId.score:
        final Score score = object as Score;
        return end ? visitScoreEnd(score) : visitScore(score);
      case ClassId.pageMilestoneEnd:
        final PageMilestoneEnd pageMilestoneEnd = object as PageMilestoneEnd;
        return end
            ? visitPageMilestoneEnd(pageMilestoneEnd)
            : visitPageMilestone(pageMilestoneEnd);
      case ClassId.pageElement:
        final PageElement pageElement = object as PageElement;
        return end
            ? visitPageElementEnd(pageElement)
            : visitPageElement(pageElement);
      case ClassId.measure:
        final Measure measure = object as Measure;
        return end ? visitMeasureEnd(measure) : visitMeasure(measure);
      case ClassId.staff:
        final Staff staff = object as Staff;
        return end ? visitStaffEnd(staff) : visitStaff(staff);
      case ClassId.layer:
        final Layer layer = object as Layer;
        return end ? visitLayerEnd(layer) : visitLayer(layer);
      case ClassId.layerDef:
        final LayerDef layerDef = object as LayerDef;
        return end ? visitLayerDefEnd(layerDef) : visitLayerDef(layerDef);
      case ClassId.ossia:
        final Ossia ossia = object as Ossia;
        return end ? visitOssiaEnd(ossia) : visitOssia(ossia);
      case ClassId.scoreDefElement:
        final ScoreDefElement scoreDefElement = object as ScoreDefElement;
        return end
            ? visitScoreDefElementEnd(scoreDefElement)
            : visitScoreDefElement(scoreDefElement);
      case ClassId.scoreDef:
        final ScoreDef scoreDef = object as ScoreDef;
        return end ? visitScoreDefEnd(scoreDef) : visitScoreDef(scoreDef);
      case ClassId.staffDef:
        final StaffDef staffDef = object as StaffDef;
        return end ? visitStaffDefEnd(staffDef) : visitStaffDef(staffDef);
      case ClassId.staffGrp:
        final StaffGrp staffGrp = object as StaffGrp;
        return end ? visitStaffGrpEnd(staffGrp) : visitStaffGrp(staffGrp);
      case ClassId.system:
        final System system = object as System;
        return end ? visitSystemEnd(system) : visitSystem(system);
      case ClassId.tuning:
        final Tuning tuning = object as Tuning;
        return end ? visitTuningEnd(tuning) : visitTuning(tuning);
      // Editorial elements
      case ClassId.editorialElement:
        final EditorialElement editorialElement = object as EditorialElement;
        return end
            ? visitEditorialElementEnd(editorialElement)
            : visitEditorialElement(editorialElement);
      // Text layout elements
      case ClassId.textLayoutElement:
        final TextLayoutElement textLayoutElement = object as TextLayoutElement;
        return end
            ? visitTextLayoutElementEnd(textLayoutElement)
            : visitTextLayoutElement(textLayoutElement);
      case ClassId.div:
        final Div div = object as Div;
        return end ? visitDivEnd(div) : visitDiv(div);
      case ClassId.runningElement:
        final RunningElement runningElement = object as RunningElement;
        return end
            ? visitRunningElementEnd(runningElement)
            : visitRunningElement(runningElement);
      case ClassId.pgFoot:
        final PgFoot pgFoot = object as PgFoot;
        return end ? visitPgFootEnd(pgFoot) : visitPgFoot(pgFoot);
      case ClassId.pgHead:
        final PgHead pgHead = object as PgHead;
        return end ? visitPgHeadEnd(pgHead) : visitPgHead(pgHead);
      // System elements
      case ClassId.systemElement:
        final SystemElement systemElement = object as SystemElement;
        return end
            ? visitSystemElementEnd(systemElement)
            : visitSystemElement(systemElement);
      case ClassId.systemMilestoneEnd:
        final SystemMilestoneEnd systemMilestoneEnd =
            object as SystemMilestoneEnd;
        return end
            ? visitSystemMilestoneEnd(systemMilestoneEnd)
            : visitSystemMilestone(systemMilestoneEnd);
      case ClassId.ending:
        final Ending ending = object as Ending;
        return end ? visitEndingEnd(ending) : visitEnding(ending);
      case ClassId.expansion:
        final Expansion expansion = object as Expansion;
        return end ? visitExpansionEnd(expansion) : visitExpansion(expansion);
      case ClassId.section:
        final Section section = object as Section;
        return end ? visitSectionEnd(section) : visitSection(section);
      case ClassId.pb:
        final Pb pb = object as Pb;
        return end ? visitPbEnd(pb) : visitPb(pb);
      case ClassId.sb:
        final Sb sb = object as Sb;
        return end ? visitSbEnd(sb) : visitSb(sb);
      // Control elements
      case ClassId.controlElement:
        final ControlElement controlElement = object as ControlElement;
        return end
            ? visitControlElementEnd(controlElement)
            : visitControlElement(controlElement);
      case ClassId.anchoredText:
        final AnchoredText anchoredText = object as AnchoredText;
        return end
            ? visitAnchoredTextEnd(anchoredText)
            : visitAnchoredText(anchoredText);
      case ClassId.annotScore:
        final AnnotScore annotScore = object as AnnotScore;
        return end
            ? visitAnnotScoreEnd(annotScore)
            : visitAnnotScore(annotScore);
      case ClassId.arpeg:
        final Arpeg arpeg = object as Arpeg;
        return end ? visitArpegEnd(arpeg) : visitArpeg(arpeg);
      case ClassId.beamSpan:
        final BeamSpan beamSpan = object as BeamSpan;
        return end ? visitBeamSpanEnd(beamSpan) : visitBeamSpan(beamSpan);
      case ClassId.bracketSpan:
        final BracketSpan bracketSpan = object as BracketSpan;
        return end
            ? visitBracketSpanEnd(bracketSpan)
            : visitBracketSpan(bracketSpan);
      case ClassId.breath:
        final Breath breath = object as Breath;
        return end ? visitBreathEnd(breath) : visitBreath(breath);
      case ClassId.caesura:
        final Caesura caesura = object as Caesura;
        return end ? visitCaesuraEnd(caesura) : visitCaesura(caesura);
      case ClassId.cpMark:
        final CpMark cpMark = object as CpMark;
        return end ? visitCpMarkEnd(cpMark) : visitCpMark(cpMark);
      case ClassId.dir:
        final Dir dir = object as Dir;
        return end ? visitDirEnd(dir) : visitDir(dir);
      case ClassId.dynam:
        final Dynam dynam = object as Dynam;
        return end ? visitDynamEnd(dynam) : visitDynam(dynam);
      case ClassId.fermata:
        final Fermata fermata = object as Fermata;
        return end ? visitFermataEnd(fermata) : visitFermata(fermata);
      case ClassId.fing:
        final Fing fing = object as Fing;
        return end ? visitFingEnd(fing) : visitFing(fing);
      case ClassId.gliss:
        final Gliss gliss = object as Gliss;
        return end ? visitGlissEnd(gliss) : visitGliss(gliss);
      case ClassId.hairpin:
        final Hairpin hairpin = object as Hairpin;
        return end ? visitHairpinEnd(hairpin) : visitHairpin(hairpin);
      case ClassId.harm:
        final Harm harm = object as Harm;
        return end ? visitHarmEnd(harm) : visitHarm(harm);
      case ClassId.lv:
        final Lv lv = object as Lv;
        return end ? visitLvEnd(lv) : visitLv(lv);
      case ClassId.mnum:
        final MNum mNum = object as MNum;
        return end ? visitMNumEnd(mNum) : visitMNum(mNum);
      case ClassId.mordent:
        final Mordent mordent = object as Mordent;
        return end ? visitMordentEnd(mordent) : visitMordent(mordent);
      case ClassId.octave:
        final Octave octave = object as Octave;
        return end ? visitOctaveEnd(octave) : visitOctave(octave);
      case ClassId.ornam:
        final Ornam ornam = object as Ornam;
        return end ? visitOrnamEnd(ornam) : visitOrnam(ornam);
      case ClassId.pedal:
        final Pedal pedal = object as Pedal;
        return end ? visitPedalEnd(pedal) : visitPedal(pedal);
      case ClassId.phrase:
        final Phrase phrase = object as Phrase;
        return end ? visitPhraseEnd(phrase) : visitPhrase(phrase);
      case ClassId.pitchInflection:
        final PitchInflection pitchInflection = object as PitchInflection;
        return end
            ? visitPitchInflectionEnd(pitchInflection)
            : visitPitchInflection(pitchInflection);
      case ClassId.reh:
        final Reh reh = object as Reh;
        return end ? visitRehEnd(reh) : visitReh(reh);
      case ClassId.repeatMark:
        final RepeatMark repeatMark = object as RepeatMark;
        return end
            ? visitRepeatMarkEnd(repeatMark)
            : visitRepeatMark(repeatMark);
      case ClassId.slur:
        final Slur slur = object as Slur;
        return end ? visitSlurEnd(slur) : visitSlur(slur);
      case ClassId.tempo:
        final Tempo tempo = object as Tempo;
        return end ? visitTempoEnd(tempo) : visitTempo(tempo);
      case ClassId.tie:
        final Tie tie = object as Tie;
        return end ? visitTieEnd(tie) : visitTie(tie);
      case ClassId.trill:
        final Trill trill = object as Trill;
        return end ? visitTrillEnd(trill) : visitTrill(trill);
      case ClassId.turn:
        final Turn turn = object as Turn;
        return end ? visitTurnEnd(turn) : visitTurn(turn);
      // Layer elements
      case ClassId.layerElement:
        final LayerElement layerElement = object as LayerElement;
        return end
            ? visitLayerElementEnd(layerElement)
            : visitLayerElement(layerElement);
      case ClassId.genericElement:
        final GenericLayerElement genericLayerElement =
            object as GenericLayerElement;
        return end
            ? visitGenericLayerElementEnd(genericLayerElement)
            : visitGenericLayerElement(genericLayerElement);
      case ClassId.accid:
        final Accid accid = object as Accid;
        return end ? visitAccidEnd(accid) : visitAccid(accid);
      case ClassId.artic:
        final Artic artic = object as Artic;
        return end ? visitArticEnd(artic) : visitArtic(artic);
      case ClassId.barLine:
        final BarLine barLine = object as BarLine;
        return end ? visitBarLineEnd(barLine) : visitBarLine(barLine);
      case ClassId.beam:
        final Beam beam = object as Beam;
        return end ? visitBeamEnd(beam) : visitBeam(beam);
      case ClassId.beatRpt:
        final BeatRpt beatRpt = object as BeatRpt;
        return end ? visitBeatRptEnd(beatRpt) : visitBeatRpt(beatRpt);
      case ClassId.bTrem:
        final BTrem bTrem = object as BTrem;
        return end ? visitBTremEnd(bTrem) : visitBTrem(bTrem);
      case ClassId.chord:
        final Chord chord = object as Chord;
        return end ? visitChordEnd(chord) : visitChord(chord);
      case ClassId.clef:
        final Clef clef = object as Clef;
        return end ? visitClefEnd(clef) : visitClef(clef);
      case ClassId.custos:
        final Custos custos = object as Custos;
        return end ? visitCustosEnd(custos) : visitCustos(custos);
      case ClassId.dot:
        final Dot dot = object as Dot;
        return end ? visitDotEnd(dot) : visitDot(dot);
      case ClassId.dots:
        final Dots dots = object as Dots;
        return end ? visitDotsEnd(dots) : visitDots(dots);
      case ClassId.flag:
        final Flag flag = object as Flag;
        return end ? visitFlagEnd(flag) : visitFlag(flag);
      case ClassId.fTrem:
        final FTrem fTrem = object as FTrem;
        return end ? visitFTremEnd(fTrem) : visitFTrem(fTrem);
      case ClassId.graceGrp:
        final GraceGrp graceGrp = object as GraceGrp;
        return end ? visitGraceGrpEnd(graceGrp) : visitGraceGrp(graceGrp);
      case ClassId.halfmRpt:
        final HalfmRpt halfmRpt = object as HalfmRpt;
        return end ? visitHalfmRptEnd(halfmRpt) : visitHalfmRpt(halfmRpt);
      case ClassId.keyAccid:
        final KeyAccid keyAccid = object as KeyAccid;
        return end ? visitKeyAccidEnd(keyAccid) : visitKeyAccid(keyAccid);
      case ClassId.keysig:
        final KeySig keySig = object as KeySig;
        return end ? visitKeySigEnd(keySig) : visitKeySig(keySig);
      case ClassId.ligature:
        final Ligature ligature = object as Ligature;
        return end ? visitLigatureEnd(ligature) : visitLigature(ligature);
      case ClassId.mensur:
        final Mensur mensur = object as Mensur;
        return end ? visitMensurEnd(mensur) : visitMensur(mensur);
      case ClassId.meterSig:
        final MeterSig meterSig = object as MeterSig;
        return end ? visitMeterSigEnd(meterSig) : visitMeterSig(meterSig);
      case ClassId.meterSigGrp:
        final MeterSigGrp meterSigGrp = object as MeterSigGrp;
        return end
            ? visitMeterSigGrpEnd(meterSigGrp)
            : visitMeterSigGrp(meterSigGrp);
      case ClassId.mRest:
        final MRest mRest = object as MRest;
        return end ? visitMRestEnd(mRest) : visitMRest(mRest);
      case ClassId.mRpt:
        final MRpt mRpt = object as MRpt;
        return end ? visitMRptEnd(mRpt) : visitMRpt(mRpt);
      case ClassId.mRpt2:
        final MRpt2 mRpt2 = object as MRpt2;
        return end ? visitMRpt2End(mRpt2) : visitMRpt2(mRpt2);
      case ClassId.mSpace:
        final MSpace mSpace = object as MSpace;
        return end ? visitMSpaceEnd(mSpace) : visitMSpace(mSpace);
      case ClassId.multiRest:
        final MultiRest multiRest = object as MultiRest;
        return end ? visitMultiRestEnd(multiRest) : visitMultiRest(multiRest);
      case ClassId.multiRpt:
        final MultiRpt multiRpt = object as MultiRpt;
        return end ? visitMultiRptEnd(multiRpt) : visitMultiRpt(multiRpt);
      case ClassId.nc:
        final Nc nc = object as Nc;
        return end ? visitNcEnd(nc) : visitNc(nc);
      case ClassId.neume:
        final Neume neume = object as Neume;
        return end ? visitNeumeEnd(neume) : visitNeume(neume);
      case ClassId.note:
        final Note note = object as Note;
        return end ? visitNoteEnd(note) : visitNote(note);
      case ClassId.plica:
        final Plica plica = object as Plica;
        return end ? visitPlicaEnd(plica) : visitPlica(plica);
      case ClassId.proport:
        final Proport proport = object as Proport;
        return end ? visitProportEnd(proport) : visitProport(proport);
      case ClassId.rest:
        final Rest rest = object as Rest;
        return end ? visitRestEnd(rest) : visitRest(rest);
      case ClassId.space:
        final Space space = object as Space;
        return end ? visitSpaceEnd(space) : visitSpace(space);
      case ClassId.stem:
        final Stem stem = object as Stem;
        return end ? visitStemEnd(stem) : visitStem(stem);
      case ClassId.syl:
        final Syl syl = object as Syl;
        return end ? visitSylEnd(syl) : visitSyl(syl);
      case ClassId.syllable:
        final Syllable syllable = object as Syllable;
        return end ? visitSyllableEnd(syllable) : visitSyllable(syllable);
      case ClassId.tabDurSym:
        final TabDurSym tabDurSym = object as TabDurSym;
        return end ? visitTabDurSymEnd(tabDurSym) : visitTabDurSym(tabDurSym);
      case ClassId.tabGrp:
        final TabGrp tabGrp = object as TabGrp;
        return end ? visitTabGrpEnd(tabGrp) : visitTabGrp(tabGrp);
      case ClassId.timestampAttr:
        final TimestampAttr timestamp = object as TimestampAttr;
        return end ? visitTimestampEnd(timestamp) : visitTimestamp(timestamp);
      case ClassId.tuplet:
        final Tuplet tuplet = object as Tuplet;
        return end ? visitTupletEnd(tuplet) : visitTuplet(tuplet);
      case ClassId.tupletBracket:
        final TupletBracket tupletBracket = object as TupletBracket;
        return end
            ? visitTupletBracketEnd(tupletBracket)
            : visitTupletBracket(tupletBracket);
      case ClassId.tupletNum:
        final TupletNum tupletNum = object as TupletNum;
        return end ? visitTupletNumEnd(tupletNum) : visitTupletNum(tupletNum);
      case ClassId.verse:
        final Verse verse = object as Verse;
        return end ? visitVerseEnd(verse) : visitVerse(verse);
      // Text elements
      case ClassId.textElement:
        final TextElement textElement = object as TextElement;
        return end
            ? visitTextElementEnd(textElement)
            : visitTextElement(textElement);
      case ClassId.f:
        final F f = object as F;
        return end ? visitFEnd(f) : visitF(f);
      case ClassId.fig:
        final Fig fig = object as Fig;
        return end ? visitFigEnd(fig) : visitFig(fig);
      case ClassId.lb:
        final Lb lb = object as Lb;
        return end ? visitLbEnd(lb) : visitLb(lb);
      case ClassId.num:
        final Num num = object as Num;
        return end ? visitNumEnd(num) : visitNum(num);
      case ClassId.rend:
        final Rend rend = object as Rend;
        return end ? visitRendEnd(rend) : visitRend(rend);
      case ClassId.symbol:
        final Symbol symbol = object as Symbol;
        return end ? visitSymbolEnd(symbol) : visitSymbol(symbol);
      case ClassId.text:
        final Text text = object as Text;
        return end ? visitTextEnd(text) : visitText(text);
      // Facsimile elements
      case ClassId.facsimile:
        final Facsimile facsimile = object as Facsimile;
        return end ? visitFacsimileEnd(facsimile) : visitFacsimile(facsimile);
      case ClassId.graphic:
        final Graphic graphic = object as Graphic;
        return end ? visitGraphicEnd(graphic) : visitGraphic(graphic);
      case ClassId.surface:
        final Surface surface = object as Surface;
        return end ? visitSurfaceEnd(surface) : visitSurface(surface);
      case ClassId.zone:
        final Zone zone = object as Zone;
        return end ? visitZoneEnd(zone) : visitZone(zone);
      // Misc container elements
      case ClassId.course:
        final Course course = object as Course;
        return end ? visitCourseEnd(course) : visitCourse(course);
      case ClassId.fb:
        final Fb fb = object as Fb;
        return end ? visitFbEnd(fb) : visitFb(fb);
      case ClassId.grpSym:
        final GrpSym grpSym = object as GrpSym;
        return end ? visitGrpSymEnd(grpSym) : visitGrpSym(grpSym);
      case ClassId.instrDef:
        final InstrDef instrDef = object as InstrDef;
        return end ? visitInstrDefEnd(instrDef) : visitInstrDef(instrDef);
      case ClassId.label:
        final Label label = object as Label;
        return end ? visitLabelEnd(label) : visitLabel(label);
      case ClassId.labelAbbr:
        final LabelAbbr labelAbbr = object as LabelAbbr;
        return end ? visitLabelAbbrEnd(labelAbbr) : visitLabelAbbr(labelAbbr);
      // Horizontal aligners
      case ClassId.alignment:
        final Alignment alignment = object as Alignment;
        return end ? visitAlignmentEnd(alignment) : visitAlignment(alignment);
      case ClassId.alignmentReference:
        final AlignmentReference alignmentReference =
            object as AlignmentReference;
        return end
            ? visitAlignmentReferenceEnd(alignmentReference)
            : visitAlignmentReference(alignmentReference);
      case ClassId.measureAligner:
        final MeasureAligner measureAligner = object as MeasureAligner;
        return end
            ? visitMeasureAlignerEnd(measureAligner)
            : visitMeasureAligner(measureAligner);
      case ClassId.graceAligner:
        final GraceAligner graceAligner = object as GraceAligner;
        return end
            ? visitGraceAlignerEnd(graceAligner)
            : visitGraceAligner(graceAligner);
      case ClassId.timestampAligner:
        final TimestampAligner timestampAligner = object as TimestampAligner;
        return end
            ? visitTimestampAlignerEnd(timestampAligner)
            : visitTimestampAligner(timestampAligner);
      // Vertical aligners
      case ClassId.systemAligner:
        final SystemAligner systemAligner = object as SystemAligner;
        return end
            ? visitSystemAlignerEnd(systemAligner)
            : visitSystemAligner(systemAligner);
      case ClassId.staffAlignment:
        final StaffAlignment staffAlignment = object as StaffAlignment;
        return end
            ? visitStaffAlignmentEnd(staffAlignment)
            : visitStaffAlignment(staffAlignment);
      // Floating objects
      case ClassId.floatingObject:
        final FloatingObject floatingObject = object as FloatingObject;
        return end
            ? visitFloatingObjectEnd(floatingObject)
            : visitFloatingObject(floatingObject);
      default:
        // Any other ClassId (device contexts, unused attribute ids…) falls
        // back to the plain object visit, mirroring `Object::Accept`.
        return end ? visitObjectEnd(object) : visitObject(object);
    }
  }

  // -------------------------------------------------------------------------
  // Visit object and doc
  // -------------------------------------------------------------------------

  FunctorCode visitObject(Object object) => FunctorCode.continue_;
  FunctorCode visitObjectEnd(Object object) => FunctorCode.continue_;
  FunctorCode visitDoc(Doc doc) => visitObject(doc);
  FunctorCode visitDocEnd(Doc doc) => visitObjectEnd(doc);

  // -------------------------------------------------------------------------
  // Visit container elements
  // -------------------------------------------------------------------------

  FunctorCode visitCourse(Course course) => visitObject(course);
  FunctorCode visitCourseEnd(Course course) => visitObjectEnd(course);
  FunctorCode visitFb(Fb fb) => visitObject(fb);
  FunctorCode visitFbEnd(Fb fb) => visitObjectEnd(fb);
  FunctorCode visitGrpSym(GrpSym grpSym) => visitObject(grpSym);
  FunctorCode visitGrpSymEnd(GrpSym grpSym) => visitObjectEnd(grpSym);
  FunctorCode visitInstrDef(InstrDef instrDef) => visitObject(instrDef);
  FunctorCode visitInstrDefEnd(InstrDef instrDef) => visitObjectEnd(instrDef);
  FunctorCode visitLabel(Label label) => visitObject(label);
  FunctorCode visitLabelEnd(Label label) => visitObjectEnd(label);
  FunctorCode visitLabelAbbr(LabelAbbr labelAbbr) => visitObject(labelAbbr);
  FunctorCode visitLabelAbbrEnd(LabelAbbr labelAbbr) =>
      visitObjectEnd(labelAbbr);
  FunctorCode visitLayer(Layer layer) => visitObject(layer);
  FunctorCode visitLayerEnd(Layer layer) => visitObjectEnd(layer);
  FunctorCode visitLayerDef(LayerDef layerDef) => visitObject(layerDef);
  FunctorCode visitLayerDefEnd(LayerDef layerDef) => visitObjectEnd(layerDef);
  FunctorCode visitMeasure(Measure measure) => visitObject(measure);
  FunctorCode visitMeasureEnd(Measure measure) => visitObjectEnd(measure);
  FunctorCode visitOssia(Ossia ossia) => visitObject(ossia);
  FunctorCode visitOssiaEnd(Ossia ossia) => visitObjectEnd(ossia);
  FunctorCode visitPage(Page page) => visitObject(page);
  FunctorCode visitPageEnd(Page page) => visitObjectEnd(page);
  FunctorCode visitPages(Pages pages) => visitObject(pages);
  FunctorCode visitPagesEnd(Pages pages) => visitObjectEnd(pages);
  FunctorCode visitPb(Pb pb) => visitSystemElement(pb);
  FunctorCode visitPbEnd(Pb pb) => visitSystemElementEnd(pb);
  FunctorCode visitSb(Sb sb) => visitSystemElement(sb);
  FunctorCode visitSbEnd(Sb sb) => visitSystemElementEnd(sb);
  FunctorCode visitScoreDef(ScoreDef scoreDef) =>
      visitScoreDefElement(scoreDef);
  FunctorCode visitScoreDefEnd(ScoreDef scoreDef) =>
      visitScoreDefElementEnd(scoreDef);
  FunctorCode visitScoreDefElement(ScoreDefElement scoreDefElement) =>
      visitObject(scoreDefElement);
  FunctorCode visitScoreDefElementEnd(ScoreDefElement scoreDefElement) =>
      visitObjectEnd(scoreDefElement);
  FunctorCode visitStaff(Staff staff) => visitObject(staff);
  FunctorCode visitStaffEnd(Staff staff) => visitObjectEnd(staff);
  FunctorCode visitStaffDef(StaffDef staffDef) =>
      visitScoreDefElement(staffDef);
  FunctorCode visitStaffDefEnd(StaffDef staffDef) =>
      visitScoreDefElementEnd(staffDef);
  FunctorCode visitStaffGrp(StaffGrp staffGrp) => visitObject(staffGrp);
  FunctorCode visitStaffGrpEnd(StaffGrp staffGrp) => visitObjectEnd(staffGrp);
  FunctorCode visitSystem(System system) => visitObject(system);
  FunctorCode visitSystemEnd(System system) => visitObjectEnd(system);
  FunctorCode visitTuning(Tuning tuning) => visitObject(tuning);
  FunctorCode visitTuningEnd(Tuning tuning) => visitObjectEnd(tuning);

  // -------------------------------------------------------------------------
  // Visit editorial elements
  // -------------------------------------------------------------------------

  FunctorCode visitEditorialElement(EditorialElement editorialElement) =>
      visitObject(editorialElement);
  FunctorCode visitEditorialElementEnd(EditorialElement editorialElement) =>
      visitObjectEnd(editorialElement);

  // -------------------------------------------------------------------------
  // Visit text layout elements
  // -------------------------------------------------------------------------

  FunctorCode visitDiv(Div div) => visitTextLayoutElement(div);
  FunctorCode visitDivEnd(Div div) => visitTextLayoutElementEnd(div);
  FunctorCode visitRunningElement(RunningElement runningElement) =>
      visitTextLayoutElement(runningElement);
  FunctorCode visitRunningElementEnd(RunningElement runningElement) =>
      visitTextLayoutElementEnd(runningElement);
  FunctorCode visitPgFoot(PgFoot pgFoot) => visitRunningElement(pgFoot);
  FunctorCode visitPgFootEnd(PgFoot pgFoot) => visitRunningElementEnd(pgFoot);
  FunctorCode visitPgHead(PgHead pgHead) => visitRunningElement(pgHead);
  FunctorCode visitPgHeadEnd(PgHead pgHead) => visitRunningElementEnd(pgHead);
  FunctorCode visitTextLayoutElement(TextLayoutElement textLayoutElement) =>
      visitObject(textLayoutElement);
  FunctorCode visitTextLayoutElementEnd(TextLayoutElement textLayoutElement) =>
      visitObjectEnd(textLayoutElement);

  // -------------------------------------------------------------------------
  // Visit system elements
  // -------------------------------------------------------------------------

  FunctorCode visitEnding(Ending ending) => visitSystemElement(ending);
  FunctorCode visitEndingEnd(Ending ending) => visitSystemElementEnd(ending);
  FunctorCode visitExpansion(Expansion expansion) =>
      visitSystemElement(expansion);
  FunctorCode visitExpansionEnd(Expansion expansion) =>
      visitSystemElementEnd(expansion);
  FunctorCode visitSection(Section section) => visitSystemElement(section);
  FunctorCode visitSectionEnd(Section section) =>
      visitSystemElementEnd(section);
  FunctorCode visitSystemElement(SystemElement systemElement) =>
      visitFloatingObject(systemElement);
  FunctorCode visitSystemElementEnd(SystemElement systemElement) =>
      visitFloatingObjectEnd(systemElement);
  FunctorCode visitSystemMilestone(SystemMilestoneEnd systemMilestoneEnd) =>
      visitSystemElement(systemMilestoneEnd);
  FunctorCode visitSystemMilestoneEnd(SystemMilestoneEnd systemMilestoneEnd) =>
      visitSystemElementEnd(systemMilestoneEnd);

  // -------------------------------------------------------------------------
  // Visit page elements
  // -------------------------------------------------------------------------

  FunctorCode visitMdiv(Mdiv mdiv) => visitPageElement(mdiv);
  FunctorCode visitMdivEnd(Mdiv mdiv) => visitPageElementEnd(mdiv);
  FunctorCode visitPageElement(PageElement pageElement) =>
      visitObject(pageElement);
  FunctorCode visitPageElementEnd(PageElement pageElement) =>
      visitObjectEnd(pageElement);
  FunctorCode visitPageMilestone(PageMilestoneEnd pageMilestoneEnd) =>
      visitPageElement(pageMilestoneEnd);
  FunctorCode visitPageMilestoneEnd(PageMilestoneEnd pageMilestoneEnd) =>
      visitPageElementEnd(pageMilestoneEnd);
  FunctorCode visitScore(Score score) => visitPageElement(score);
  FunctorCode visitScoreEnd(Score score) => visitPageElementEnd(score);

  // -------------------------------------------------------------------------
  // Visit control elements
  // -------------------------------------------------------------------------

  FunctorCode visitAnchoredText(AnchoredText anchoredText) =>
      visitControlElement(anchoredText);
  FunctorCode visitAnchoredTextEnd(AnchoredText anchoredText) =>
      visitControlElementEnd(anchoredText);
  FunctorCode visitAnnotScore(AnnotScore annotScore) =>
      visitControlElement(annotScore);
  FunctorCode visitAnnotScoreEnd(AnnotScore annotScore) =>
      visitControlElementEnd(annotScore);
  FunctorCode visitArpeg(Arpeg arpeg) => visitControlElement(arpeg);
  FunctorCode visitArpegEnd(Arpeg arpeg) => visitControlElementEnd(arpeg);
  FunctorCode visitBeamSpan(BeamSpan beamSpan) => visitControlElement(beamSpan);
  FunctorCode visitBeamSpanEnd(BeamSpan beamSpan) =>
      visitControlElementEnd(beamSpan);
  FunctorCode visitBracketSpan(BracketSpan bracketSpan) =>
      visitControlElement(bracketSpan);
  FunctorCode visitBracketSpanEnd(BracketSpan bracketSpan) =>
      visitControlElementEnd(bracketSpan);
  FunctorCode visitBreath(Breath breath) => visitControlElement(breath);
  FunctorCode visitBreathEnd(Breath breath) => visitControlElementEnd(breath);
  FunctorCode visitCaesura(Caesura caesura) => visitControlElement(caesura);
  FunctorCode visitCaesuraEnd(Caesura caesura) =>
      visitControlElementEnd(caesura);
  FunctorCode visitControlElement(ControlElement controlElement) =>
      visitFloatingObject(controlElement);
  FunctorCode visitControlElementEnd(ControlElement controlElement) =>
      visitFloatingObjectEnd(controlElement);
  FunctorCode visitCpMark(CpMark cpMark) => visitControlElement(cpMark);
  FunctorCode visitCpMarkEnd(CpMark cpMark) => visitControlElementEnd(cpMark);
  FunctorCode visitDir(Dir dir) => visitControlElement(dir);
  FunctorCode visitDirEnd(Dir dir) => visitControlElementEnd(dir);
  FunctorCode visitDynam(Dynam dynam) => visitControlElement(dynam);
  FunctorCode visitDynamEnd(Dynam dynam) => visitControlElementEnd(dynam);
  FunctorCode visitFermata(Fermata fermata) => visitControlElement(fermata);
  FunctorCode visitFermataEnd(Fermata fermata) =>
      visitControlElementEnd(fermata);
  FunctorCode visitFing(Fing fing) => visitControlElement(fing);
  FunctorCode visitFingEnd(Fing fing) => visitControlElementEnd(fing);
  FunctorCode visitGliss(Gliss gliss) => visitControlElement(gliss);
  FunctorCode visitGlissEnd(Gliss gliss) => visitControlElementEnd(gliss);
  FunctorCode visitHairpin(Hairpin hairpin) => visitControlElement(hairpin);
  FunctorCode visitHairpinEnd(Hairpin hairpin) =>
      visitControlElementEnd(hairpin);
  FunctorCode visitHarm(Harm harm) => visitControlElement(harm);
  FunctorCode visitHarmEnd(Harm harm) => visitControlElementEnd(harm);
  FunctorCode visitLv(Lv lv) => visitTie(lv);
  FunctorCode visitLvEnd(Lv lv) => visitTieEnd(lv);
  FunctorCode visitMordent(Mordent mordent) => visitControlElement(mordent);
  FunctorCode visitMordentEnd(Mordent mordent) =>
      visitControlElementEnd(mordent);
  FunctorCode visitMNum(MNum mNum) => visitControlElement(mNum);
  FunctorCode visitMNumEnd(MNum mNum) => visitControlElementEnd(mNum);
  FunctorCode visitOctave(Octave octave) => visitControlElement(octave);
  FunctorCode visitOctaveEnd(Octave octave) => visitControlElementEnd(octave);
  FunctorCode visitOrnam(Ornam ornam) => visitControlElement(ornam);
  FunctorCode visitOrnamEnd(Ornam ornam) => visitControlElementEnd(ornam);
  FunctorCode visitPedal(Pedal pedal) => visitControlElement(pedal);
  FunctorCode visitPedalEnd(Pedal pedal) => visitControlElementEnd(pedal);
  FunctorCode visitPhrase(Phrase phrase) => visitSlur(phrase);
  FunctorCode visitPhraseEnd(Phrase phrase) => visitSlurEnd(phrase);
  FunctorCode visitPitchInflection(PitchInflection pitchInflection) =>
      visitControlElement(pitchInflection);
  FunctorCode visitPitchInflectionEnd(PitchInflection pitchInflection) =>
      visitControlElementEnd(pitchInflection);
  FunctorCode visitReh(Reh reh) => visitControlElement(reh);
  FunctorCode visitRehEnd(Reh reh) => visitControlElementEnd(reh);
  FunctorCode visitRepeatMark(RepeatMark repeatMark) =>
      visitControlElement(repeatMark);
  FunctorCode visitRepeatMarkEnd(RepeatMark repeatMark) =>
      visitControlElementEnd(repeatMark);
  FunctorCode visitSlur(Slur slur) => visitControlElement(slur);
  FunctorCode visitSlurEnd(Slur slur) => visitControlElementEnd(slur);
  FunctorCode visitTempo(Tempo tempo) => visitControlElement(tempo);
  FunctorCode visitTempoEnd(Tempo tempo) => visitControlElementEnd(tempo);
  FunctorCode visitTie(Tie tie) => visitControlElement(tie);
  FunctorCode visitTieEnd(Tie tie) => visitControlElementEnd(tie);
  FunctorCode visitTrill(Trill trill) => visitControlElement(trill);
  FunctorCode visitTrillEnd(Trill trill) => visitControlElementEnd(trill);
  FunctorCode visitTurn(Turn turn) => visitControlElement(turn);
  FunctorCode visitTurnEnd(Turn turn) => visitControlElementEnd(turn);

  // -------------------------------------------------------------------------
  // Visit layer elements
  // -------------------------------------------------------------------------

  FunctorCode visitAccid(Accid accid) => visitLayerElement(accid);
  FunctorCode visitAccidEnd(Accid accid) => visitLayerElementEnd(accid);
  FunctorCode visitArtic(Artic artic) => visitLayerElement(artic);
  FunctorCode visitArticEnd(Artic artic) => visitLayerElementEnd(artic);
  FunctorCode visitBarLine(BarLine barLine) => visitLayerElement(barLine);
  FunctorCode visitBarLineEnd(BarLine barLine) => visitLayerElementEnd(barLine);
  FunctorCode visitBeam(Beam beam) => visitLayerElement(beam);
  FunctorCode visitBeamEnd(Beam beam) => visitLayerElementEnd(beam);
  FunctorCode visitBeatRpt(BeatRpt beatRpt) => visitLayerElement(beatRpt);
  FunctorCode visitBeatRptEnd(BeatRpt beatRpt) => visitLayerElementEnd(beatRpt);
  FunctorCode visitBTrem(BTrem bTrem) => visitLayerElement(bTrem);
  FunctorCode visitBTremEnd(BTrem bTrem) => visitLayerElementEnd(bTrem);
  FunctorCode visitChord(Chord chord) => visitLayerElement(chord);
  FunctorCode visitChordEnd(Chord chord) => visitLayerElementEnd(chord);
  FunctorCode visitClef(Clef clef) => visitLayerElement(clef);
  FunctorCode visitClefEnd(Clef clef) => visitLayerElementEnd(clef);
  FunctorCode visitCustos(Custos custos) => visitLayerElement(custos);
  FunctorCode visitCustosEnd(Custos custos) => visitLayerElementEnd(custos);
  FunctorCode visitDot(Dot dot) => visitLayerElement(dot);
  FunctorCode visitDotEnd(Dot dot) => visitLayerElementEnd(dot);
  FunctorCode visitDots(Dots dots) => visitLayerElement(dots);
  FunctorCode visitDotsEnd(Dots dots) => visitLayerElementEnd(dots);
  FunctorCode visitFlag(Flag flag) => visitLayerElement(flag);
  FunctorCode visitFlagEnd(Flag flag) => visitLayerElementEnd(flag);
  FunctorCode visitFTrem(FTrem fTrem) => visitLayerElement(fTrem);
  FunctorCode visitFTremEnd(FTrem fTrem) => visitLayerElementEnd(fTrem);
  FunctorCode visitGenericLayerElement(
          GenericLayerElement genericLayerElement) =>
      visitLayerElement(genericLayerElement);
  FunctorCode visitGenericLayerElementEnd(
          GenericLayerElement genericLayerElement) =>
      visitLayerElementEnd(genericLayerElement);
  FunctorCode visitGraceGrp(GraceGrp graceGrp) => visitLayerElement(graceGrp);
  FunctorCode visitGraceGrpEnd(GraceGrp graceGrp) =>
      visitLayerElementEnd(graceGrp);
  FunctorCode visitHalfmRpt(HalfmRpt halfmRpt) => visitLayerElement(halfmRpt);
  FunctorCode visitHalfmRptEnd(HalfmRpt halfmRpt) =>
      visitLayerElementEnd(halfmRpt);
  FunctorCode visitKeyAccid(KeyAccid keyAccid) => visitLayerElement(keyAccid);
  FunctorCode visitKeyAccidEnd(KeyAccid keyAccid) =>
      visitLayerElementEnd(keyAccid);
  FunctorCode visitKeySig(KeySig keySig) => visitLayerElement(keySig);
  FunctorCode visitKeySigEnd(KeySig keySig) => visitLayerElementEnd(keySig);
  FunctorCode visitLayerElement(LayerElement layerElement) =>
      visitObject(layerElement);
  FunctorCode visitLayerElementEnd(LayerElement layerElement) =>
      visitObjectEnd(layerElement);
  FunctorCode visitLigature(Ligature ligature) => visitLayerElement(ligature);
  FunctorCode visitLigatureEnd(Ligature ligature) =>
      visitLayerElementEnd(ligature);
  FunctorCode visitMensur(Mensur mensur) => visitLayerElement(mensur);
  FunctorCode visitMensurEnd(Mensur mensur) => visitLayerElementEnd(mensur);
  FunctorCode visitMeterSig(MeterSig meterSig) => visitLayerElement(meterSig);
  FunctorCode visitMeterSigEnd(MeterSig meterSig) =>
      visitLayerElementEnd(meterSig);
  FunctorCode visitMeterSigGrp(MeterSigGrp meterSigGrp) =>
      visitLayerElement(meterSigGrp);
  FunctorCode visitMeterSigGrpEnd(MeterSigGrp meterSigGrp) =>
      visitLayerElementEnd(meterSigGrp);
  FunctorCode visitMRest(MRest mRest) => visitLayerElement(mRest);
  FunctorCode visitMRestEnd(MRest mRest) => visitLayerElementEnd(mRest);
  FunctorCode visitMRpt(MRpt mRpt) => visitLayerElement(mRpt);
  FunctorCode visitMRptEnd(MRpt mRpt) => visitLayerElementEnd(mRpt);
  FunctorCode visitMRpt2(MRpt2 mRpt2) => visitLayerElement(mRpt2);
  FunctorCode visitMRpt2End(MRpt2 mRpt2) => visitLayerElementEnd(mRpt2);
  FunctorCode visitMSpace(MSpace mSpace) => visitLayerElement(mSpace);
  FunctorCode visitMSpaceEnd(MSpace mSpace) => visitLayerElementEnd(mSpace);
  FunctorCode visitMultiRest(MultiRest multiRest) =>
      visitLayerElement(multiRest);
  FunctorCode visitMultiRestEnd(MultiRest multiRest) =>
      visitLayerElementEnd(multiRest);
  FunctorCode visitMultiRpt(MultiRpt multiRpt) => visitLayerElement(multiRpt);
  FunctorCode visitMultiRptEnd(MultiRpt multiRpt) =>
      visitLayerElementEnd(multiRpt);
  FunctorCode visitNc(Nc nc) => visitLayerElement(nc);
  FunctorCode visitNcEnd(Nc nc) => visitLayerElementEnd(nc);
  FunctorCode visitNeume(Neume neume) => visitLayerElement(neume);
  FunctorCode visitNeumeEnd(Neume neume) => visitLayerElementEnd(neume);
  FunctorCode visitNote(Note note) => visitLayerElement(note);
  FunctorCode visitNoteEnd(Note note) => visitLayerElementEnd(note);
  FunctorCode visitPlica(Plica plica) => visitLayerElement(plica);
  FunctorCode visitPlicaEnd(Plica plica) => visitLayerElementEnd(plica);
  FunctorCode visitProport(Proport proport) => visitLayerElement(proport);
  FunctorCode visitProportEnd(Proport proport) => visitLayerElementEnd(proport);
  FunctorCode visitRest(Rest rest) => visitLayerElement(rest);
  FunctorCode visitRestEnd(Rest rest) => visitLayerElementEnd(rest);
  FunctorCode visitSpace(Space space) => visitLayerElement(space);
  FunctorCode visitSpaceEnd(Space space) => visitLayerElementEnd(space);
  FunctorCode visitStem(Stem stem) => visitLayerElement(stem);
  FunctorCode visitStemEnd(Stem stem) => visitLayerElementEnd(stem);
  FunctorCode visitSyl(Syl syl) => visitLayerElement(syl);
  FunctorCode visitSylEnd(Syl syl) => visitLayerElementEnd(syl);
  FunctorCode visitSyllable(Syllable syllable) => visitLayerElement(syllable);
  FunctorCode visitSyllableEnd(Syllable syllable) =>
      visitLayerElementEnd(syllable);
  FunctorCode visitTabDurSym(TabDurSym tabDurSym) =>
      visitLayerElement(tabDurSym);
  FunctorCode visitTabDurSymEnd(TabDurSym tabDurSym) =>
      visitLayerElementEnd(tabDurSym);
  FunctorCode visitTabGrp(TabGrp tabGrp) => visitLayerElement(tabGrp);
  FunctorCode visitTabGrpEnd(TabGrp tabGrp) => visitLayerElementEnd(tabGrp);
  FunctorCode visitTimestamp(TimestampAttr timestamp) =>
      visitLayerElement(timestamp);
  FunctorCode visitTimestampEnd(TimestampAttr timestamp) =>
      visitLayerElementEnd(timestamp);
  FunctorCode visitTuplet(Tuplet tuplet) => visitLayerElement(tuplet);
  FunctorCode visitTupletEnd(Tuplet tuplet) => visitLayerElementEnd(tuplet);
  FunctorCode visitTupletBracket(TupletBracket tupletBracket) =>
      visitLayerElement(tupletBracket);
  FunctorCode visitTupletBracketEnd(TupletBracket tupletBracket) =>
      visitLayerElementEnd(tupletBracket);
  FunctorCode visitTupletNum(TupletNum tupletNum) =>
      visitLayerElement(tupletNum);
  FunctorCode visitTupletNumEnd(TupletNum tupletNum) =>
      visitLayerElementEnd(tupletNum);
  FunctorCode visitVerse(Verse verse) => visitLayerElement(verse);
  FunctorCode visitVerseEnd(Verse verse) => visitLayerElementEnd(verse);

  // -------------------------------------------------------------------------
  // Visit text elements
  // -------------------------------------------------------------------------

  FunctorCode visitF(F f) => visitTextElement(f);
  FunctorCode visitFEnd(F f) => visitTextElementEnd(f);
  FunctorCode visitFig(Fig fig) => visitTextElement(fig);
  FunctorCode visitFigEnd(Fig fig) => visitTextElementEnd(fig);
  FunctorCode visitLb(Lb lb) => visitTextElement(lb);
  FunctorCode visitLbEnd(Lb lb) => visitTextElementEnd(lb);
  FunctorCode visitNum(Num num) => visitTextElement(num);
  FunctorCode visitNumEnd(Num num) => visitTextElementEnd(num);
  FunctorCode visitRend(Rend rend) => visitTextElement(rend);
  FunctorCode visitRendEnd(Rend rend) => visitTextElementEnd(rend);
  FunctorCode visitSymbol(Symbol symbol) => visitTextElement(symbol);
  FunctorCode visitSymbolEnd(Symbol symbol) => visitTextElementEnd(symbol);
  FunctorCode visitText(Text text) => visitTextElement(text);
  FunctorCode visitTextEnd(Text text) => visitTextElementEnd(text);
  FunctorCode visitTextElement(TextElement textElement) =>
      visitObject(textElement);
  FunctorCode visitTextElementEnd(TextElement textElement) =>
      visitObjectEnd(textElement);

  // -------------------------------------------------------------------------
  // Visit facsimile elements
  // -------------------------------------------------------------------------

  FunctorCode visitFacsimile(Facsimile facsimile) => visitObject(facsimile);
  FunctorCode visitFacsimileEnd(Facsimile facsimile) =>
      visitObjectEnd(facsimile);
  FunctorCode visitGraphic(Graphic graphic) => visitObject(graphic);
  FunctorCode visitGraphicEnd(Graphic graphic) => visitObjectEnd(graphic);
  FunctorCode visitSurface(Surface surface) => visitObject(surface);
  FunctorCode visitSurfaceEnd(Surface surface) => visitObjectEnd(surface);
  FunctorCode visitSvg(Svg svg) => visitObject(svg);
  FunctorCode visitSvgEnd(Svg svg) => visitObjectEnd(svg);
  FunctorCode visitZone(Zone zone) => visitObject(zone);
  FunctorCode visitZoneEnd(Zone zone) => visitObjectEnd(zone);

  // -------------------------------------------------------------------------
  // Visit horizontal aligners
  // -------------------------------------------------------------------------

  FunctorCode visitAlignment(Alignment alignment) => visitObject(alignment);
  FunctorCode visitAlignmentEnd(Alignment alignment) =>
      visitObjectEnd(alignment);
  FunctorCode visitAlignmentReference(AlignmentReference alignmentReference) =>
      visitObject(alignmentReference);
  FunctorCode visitAlignmentReferenceEnd(
          AlignmentReference alignmentReference) =>
      visitObjectEnd(alignmentReference);
  FunctorCode visitHorizontalAligner(HorizontalAligner horizontalAligner) =>
      visitObject(horizontalAligner);
  FunctorCode visitHorizontalAlignerEnd(HorizontalAligner horizontalAligner) =>
      visitObjectEnd(horizontalAligner);
  FunctorCode visitMeasureAligner(MeasureAligner measureAligner) =>
      visitHorizontalAligner(measureAligner);
  FunctorCode visitMeasureAlignerEnd(MeasureAligner measureAligner) =>
      visitHorizontalAlignerEnd(measureAligner);
  FunctorCode visitGraceAligner(GraceAligner graceAligner) =>
      visitHorizontalAligner(graceAligner);
  FunctorCode visitGraceAlignerEnd(GraceAligner graceAligner) =>
      visitHorizontalAlignerEnd(graceAligner);
  FunctorCode visitTimestampAligner(TimestampAligner timestampAligner) =>
      visitObject(timestampAligner);
  FunctorCode visitTimestampAlignerEnd(TimestampAligner timestampAligner) =>
      visitObjectEnd(timestampAligner);

  // -------------------------------------------------------------------------
  // Visit vertical aligners
  // -------------------------------------------------------------------------

  FunctorCode visitSystemAligner(SystemAligner systemAligner) =>
      visitObject(systemAligner);
  FunctorCode visitSystemAlignerEnd(SystemAligner systemAligner) =>
      visitObjectEnd(systemAligner);
  FunctorCode visitStaffAlignment(StaffAlignment staffAlignment) =>
      visitObject(staffAlignment);
  FunctorCode visitStaffAlignmentEnd(StaffAlignment staffAlignment) =>
      visitObjectEnd(staffAlignment);

  // -------------------------------------------------------------------------
  // Visit floating objects
  // -------------------------------------------------------------------------

  FunctorCode visitFloatingObject(FloatingObject floatingObject) =>
      visitObject(floatingObject);
  FunctorCode visitFloatingObjectEnd(FloatingObject floatingObject) =>
      visitObjectEnd(floatingObject);
}

// ---------------------------------------------------------------------------
// DocFunctor
// ---------------------------------------------------------------------------

/// This abstract class is the base class for all functors that need access to
/// the document (mirrors `vrv::DocFunctor`).
abstract class DocFunctor extends Functor {
  DocFunctor(this.doc);

  /// The document (mirrors `m_doc`).
  final Doc doc;

  /// Getter for the document (mirrors `GetDoc`).
  Doc getDoc() => doc;
}

// ---------------------------------------------------------------------------
// CollectAndProcess
// ---------------------------------------------------------------------------

/// Mixin for all functors that require two step processing: (1) collecting
/// data, (2) processing data (mirrors `vrv::CollectAndProcess`).
mixin CollectAndProcess {
  /// Indicates the current phase: collecting vs processing data (mirrors
  /// `m_processingData`).
  bool _processingData = false;

  bool get isCollectingData => !_processingData;
  bool get isProcessingData => _processingData;
  void setDataCollectionCompleted() => _processingData = true;
}

// ---------------------------------------------------------------------------
// Trivial concrete functors (proof of concept / test helpers)
//
// The full functor families (preparedata, convert, find, reset, save,
// scoringup, setscoredef, transpose…) arrive with the next tasks.
// ---------------------------------------------------------------------------

/// Counts the nodes of the tree by ClassId (test helper).
///
/// Because every default visit delegates to [visitObject] (like the C++
/// defaults), overriding `visitObject` alone counts every node.
class CountFunctor extends Functor {
  /// The number of nodes seen per concrete ClassId.
  final Map<ClassId, int> counts = <ClassId, int>{};

  /// The total number of nodes seen.
  int get total => counts.values.fold(0, (sum, count) => sum + count);

  /// The number of nodes seen for [classId].
  int count(ClassId classId) => counts[classId] ?? 0;

  @override
  FunctorCode visitObject(Object object) {
    counts[object.classId] = (counts[object.classId] ?? 0) + 1;
    return FunctorCode.continue_;
  }
}

/// Collects all Measure, Staff and Layer objects (test helper).
class MeasureStaffLayerCollector extends Functor {
  final List<Measure> measures = [];
  final List<Staff> staves = [];
  final List<Layer> layers = [];

  @override
  FunctorCode visitMeasure(Measure measure) {
    measures.add(measure);
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitStaff(Staff staff) {
    staves.add(staff);
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitLayer(Layer layer) {
    layers.add(layer);
    return FunctorCode.continue_;
  }
}
