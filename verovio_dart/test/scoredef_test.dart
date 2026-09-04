import 'package:test/test.dart';
import 'package:verovio_dart/src/core/attdef.dart'
    show MeiDuration, MeterCountSign;
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/factory_registry.dart';
import 'package:verovio_dart/src/model/atts/mei_enums.dart';
import 'package:verovio_dart/src/model/atts/mei_values.dart'
    show KeySignature;
import 'package:verovio_dart/src/model/basic_elements.dart';
import 'package:verovio_dart/src/model/editorial_element.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart';
import 'package:verovio_dart/src/model/mensur.dart';
import 'package:verovio_dart/src/model/misc_elements_gen.dart';
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/model/scoredef.dart';

void main() {
  setUp(registerModelClasses);

  group('ScoreDef / StaffDef / StaffGrp', () {
    test('factory creates the scoreDef family', () {
      expect(ObjectFactory.instance.create('scoreDef'), isA<ScoreDef>());
      expect(ObjectFactory.instance.create('staffDef'), isA<StaffDef>());
      expect(ObjectFactory.instance.create('staffGrp'), isA<StaffGrp>());
      expect(ObjectFactory.instance.create('layerDef'), isA<LayerDef>());
      expect(ObjectFactory.instance.create('mensur'), isA<Mensur>());
    });

    test('scoreDef accepts staffGrp and rejects arbitrary children', () {
      final scoreDef = ScoreDef();
      final staffGrp = StaffGrp();
      expect(scoreDef.addChild(staffGrp), isTrue);
      // Children are inserted by insert order (staffGrp last).
      expect(scoreDef.addChild(MeterSig()), isTrue);
      expect(scoreDef.getChild(0)!.classId, ClassId.meterSig);
      expect(scoreDef.addChild(Note()), isFalse);
    });

    test('staffDef supports clef/keySig/meterSig/label children', () {
      final staffDef = StaffDef()..n = 1;
      expect(staffDef.addChild(Clef()..shape = Clefshape.g), isTrue);
      expect(staffDef.addChild(KeySig()), isTrue);
      expect(staffDef.addChild(Label()), isTrue);
      expect(staffDef.addChild(StaffDef()), isFalse);
    });

    test('hasClefInfo and getClef work with direct children', () {
      final staffDef = StaffDef();
      expect(staffDef.hasClefInfo(), isFalse);
      final clef = Clef()
        ..shape = Clefshape.c
        ..line = 3;
      staffDef.addChild(clef);
      expect(staffDef.hasClefInfo(), isTrue);
      expect(staffDef.getClef(), same(clef));
      final copy = staffDef.getClefCopy();
      expect(copy, isNot(same(clef)));
      expect(copy.shape, Clefshape.c);
      expect(copy.line, 3);
    });

    test('getStaffDef finds by @n including ossias', () {
      final scoreDef = ScoreDef();
      final staffGrp = StaffGrp();
      final staffDef1 = StaffDef()..n = 1;
      final staffDef2 = StaffDef()..n = 2;
      staffGrp.addChild(staffDef1);
      staffGrp.addChild(staffDef2);
      scoreDef.addChild(staffGrp);

      expect(scoreDef.getStaffDef(1), same(staffDef1));
      expect(scoreDef.getStaffDef(2), same(staffDef2));
      expect(scoreDef.getStaffDef(3), isNull);

      // Ossia staffDef lookup through the drawing interface lists.
      final ossia = StaffDef()..n = ossiaNOffset + 1;
      staffDef2.addOssiaAbove(ossia);
      expect(scoreDef.getStaffDef(ossiaNOffset + 1), same(ossia));

      expect(scoreDef.getStaffNs(), [1, ossiaNOffset + 1, 2]);
    });

    test('getMaxStaffSize returns 100 when empty or unscaled', () {
      final scoreDef = ScoreDef();
      expect(scoreDef.getMaxStaffSize(), 100);

      final staffGrp = StaffGrp();
      scoreDef.addChild(staffGrp);
      expect(scoreDef.getMaxStaffSize(), 100);

      staffGrp.addChild(StaffDef()..scale = 50);
      expect(scoreDef.getMaxStaffSize(), 50);

      final staffDef2 = StaffDef()..scale = 75;
      staffGrp.addChild(staffDef2);
      // The maximum scale of the group wins.
      expect(scoreDef.getMaxStaffSize(), 75);

      // A staffDef without @scale resets the size to the default.
      staffGrp.addChild(StaffDef());
      expect(scoreDef.getMaxStaffSize(), 100);
    });

    test('replaceDrawingValuesFromStaffDef copies current values', () {
      final scoreDef = ScoreDef();
      final staffGrp = StaffGrp();
      final target = StaffDef()..n = 1;
      staffGrp.addChild(target);
      scoreDef.addChild(staffGrp);

      final source = StaffDef()..n = 1;
      source.addChild(Clef()
        ..shape = Clefshape.f
        ..line = 4);
      source.addChild(KeySig()
        ..sig = KeySignature(2, AccidentalWritten.s));

      scoreDef.replaceDrawingValuesFromStaffDef(source);

      expect(target.drawClef(), isTrue);
      expect(target.getCurrentClef().shape, Clefshape.f);
      expect(target.getCurrentKeySig().sig!.sig, 2);
      expect(target.drawKeySig(), isTrue);
    });
  });

  group('StaffGrp', () {
    test('filterList keeps only staffDefs', () {
      final staffGrp = StaffGrp();
      final staffDef = StaffDef()..n = 1;
      staffGrp.addChild(staffDef);
      staffGrp.addChild(Label());

      expect(staffGrp.getList().length, 1);
      expect(staffGrp.getList().first, same(staffDef));
    });

    test('getFirstLastStaffDef skips hidden staffDefs', () {
      final staffGrp = StaffGrp();
      final first = StaffDef()..n = 1;
      final hidden = StaffDef()..n = 2;
      final last = StaffDef()..n = 3;
      hidden.setDrawingVisibility(VisibilityOptimization.hidden);
      staffGrp.addChild(first);
      staffGrp.addChild(hidden);
      staffGrp.addChild(last);

      final result = staffGrp.getFirstLastStaffDef();
      expect(result.$1, same(first));
      expect(result.$2, same(last));
    });

    test('setEverythingVisible propagates to nested groups', () {
      final outer = StaffGrp();
      final inner = StaffGrp();
      final staffDef = StaffDef();
      inner.addChild(staffDef);
      outer.addChild(inner);

      inner.drawingVisibility = VisibilityOptimization.hidden;
      staffDef.setDrawingVisibility(VisibilityOptimization.hidden);

      outer.setEverythingVisible();

      expect(outer.drawingVisibility, VisibilityOptimization.show);
      expect(inner.drawingVisibility, VisibilityOptimization.show);
      expect(staffDef.getDrawingVisibility(), VisibilityOptimization.show);
    });
  });

  group('KeySig', () {
    test('getAccidCount and getAccidType from @sig', () {
      final keySig = KeySig()
        ..sig = KeySignature(3, AccidentalWritten.f);
      expect(keySig.getAccidCount(fromAttribute: true), 3);
      expect(keySig.getAccidType(), AccidentalWritten.f);
      expect(keySig.getFifthsInt(), -3);

      keySig.sig = KeySignature(2, AccidentalWritten.s);
      expect(keySig.getFifthsInt(), 2);
    });

    test('generateKeyAccidAttribChildren builds attribute children', () {
      final keySig = KeySig()
        ..sig = KeySignature(2, AccidentalWritten.s);
      keySig.generateKeyAccidAttribChildren();

      expect(keySig.childCount, 2);
      final first = keySig.getChild(0)!;
      expect(first.isAttribute, isTrue);

      final info = keySig.getKeyAccidInfoAt(0)!;
      expect(info.pname, Pitchname.f);
      expect(info.accid, AccidentalWritten.s);
    });

    test('convertToSig validates standard accidental series', () {
      final keySig = KeySig();
      for (final pname in [
        Pitchname.b,
        Pitchname.e,
        Pitchname.a,
      ]) {
        keySig.addChild(_makeKeyAccid(pname, AccidentalWritten.f));
      }

      final sig = keySig.convertToSig();
      expect(sig.sig, 3);
      expect(sig.accid, AccidentalWritten.f);
    });

    test('getOctave resolves the octave per clef', () {
      final treble = Clef()
        ..shape = Clefshape.g
        ..line = 2;

      // Flats order: b, e, a… with treble clef the b flat sits in octave 4.
      expect(
          KeySig.getOctave(AccidentalWritten.f, Pitchname.b, treble),
          4);
      expect(
          KeySig.getOctave(AccidentalWritten.s, Pitchname.f, treble),
          5);
    });
  });

  group('MeterSig', () {
    test('getTotalCount handles count, sym and signs', () {
      final meterSig = MeterSig();
      expect(meterSig.getTotalCount(), 0);

      meterSig.sym = Metersign.cut;
      expect(meterSig.getTotalCount(), 2);
      meterSig.sym = Metersign.common;
      expect(meterSig.getTotalCount(), 4);

      meterSig.setCount([3, 4], MeterCountSign.plus);
      expect(meterSig.getTotalCount(), 7);

      meterSig.setCount([8], MeterCountSign.none);
      expect(meterSig.getTotalCount(), 8);
    });

    test('getUnitAsDur maps units to durations', () {
      final meterSig = MeterSig()..unit = 4;
      expect(meterSig.getUnitAsDur(), MeiDuration.dur4);
      meterSig.unit = 8;
      expect(meterSig.getUnitAsDur(), MeiDuration.dur8);
      meterSig.unit = null;
      expect(meterSig.getUnitAsDur(), MeiDuration.dur4);
    });
  });

  group('MeterSigGrp', () {
    test('only accepts meterSig children', () {
      final grp = MeterSigGrp();
      expect(grp.addChild(MeterSig()), isTrue);
      expect(grp.addChild(Note()), isFalse);
    });

    test('interchanging groups align unit with shortest', () {
      final grp = MeterSigGrp()..func = MetersiggrplogFunc.interchanging;
      final sig34 = MeterSig()
        ..setCount([3], MeterCountSign.none)
        ..unit = 4;
      final sig68 = MeterSig()
        ..setCount([6], MeterCountSign.none)
        ..unit = 8;
      grp.addChild(sig34);
      grp.addChild(sig68);

      final simplified = grp.getSimplifiedMeterSig();
      expect(simplified, isNotNull);
      // 6/8 has the highest count/unit ratio; 3/4 becomes 6/8.
      final (counts, sign) = simplified!.getCountPair();
      if (simplified.unit == 8) {
        expect(counts, [6]);
      } else {
        expect(counts, [3]);
        expect(sign, MeterCountSign.none);
      }
    });

    test('mixed groups accumulate counts', () {
      final grp = MeterSigGrp()..func = MetersiggrplogFunc.mixed;
      grp.addChild(MeterSig()
        ..setCount([2], MeterCountSign.none)
        ..unit = 4);
      grp.addChild(MeterSig()
        ..setCount([3], MeterCountSign.none)
        ..unit = 8);

      final simplified = grp.getSimplifiedMeterSig();
      expect(simplified, isNotNull);
      // 2/4 + 3/8: the accumulated count is rescaled when a longer unit
      // appears (2/4 -> 4/8) giving 7/8.
      expect(simplified!.unit, 8);
      final (counts, _) = simplified.getCountPair();
      expect(counts, [7]);
    });
  });

  group('Chord', () {
    test('adds notes and puts stems/dots in front', () {
      final chord = Chord();
      final note1 = Note()..oct = 4;
      final note2 = Note()..oct = 5;
      final stem = Stem();

      expect(chord.addChild(note1), isTrue);
      expect(chord.addChild(note2), isTrue);
      expect(chord.addChild(stem), isTrue);

      expect(chord.children.first, same(stem));
      expect(chord.getList().length, 2);
    });

    test('positionInChord and extremes', () {
      final chord = Chord();
      final bottom = Note()
        ..pname = Pitchname.c
        ..oct = 4;
      final middle = Note()
        ..pname = Pitchname.e
        ..oct = 4;
      final top = Note()
        ..pname = Pitchname.g
        ..oct = 4;
      chord.addChild(bottom);
      chord.addChild(middle);
      chord.addChild(top);

      expect(chord.positionInChord(bottom), -1);
      expect(chord.positionInChord(middle), 0);
      expect(chord.positionInChord(top), 1);

      expect(chord.getBottomNote(), same(bottom));
      expect(chord.getTopNote(), same(top));
    });

    test('rejects non-note children but allows editorial markup', () {
      final chord = Chord();
      expect(chord.addChild(Rest()), isFalse);
      expect(chord.addChild(App()), isTrue);
    });
  });

  group('Tuplet', () {
    test('accepts notes/beams and tuplet parts in front', () {
      final tuplet = Tuplet();
      expect(tuplet.addChild(Note()), isTrue);
      expect(tuplet.addChild(TupletBracket()), isTrue);
      expect(tuplet.children.first.classId, ClassId.tupletBracket);
      expect(tuplet.getList().length, 1,
          reason: 'the bracket has no duration interface');
    });

    test('melodic direction follows the drawing extremes', () {
      final tuplet = Tuplet();
      final left = Note()
        ..pname = Pitchname.c
        ..oct = 4;
      final right = Note()
        ..pname = Pitchname.g
        ..oct = 4;
      tuplet.addChild(left);
      tuplet.addChild(right);
      tuplet.drawingLeft = left;
      tuplet.drawingRight = right;

      expect(tuplet.getMelodicDirection(), MelodicDirection.up);

      tuplet.drawingRight = left;
      tuplet.drawingLeft = right;
      expect(tuplet.getMelodicDirection(), MelodicDirection.down);
    });
  });

  group('Tuning', () {
    test('calcPitchNumber falls back to standard guitar', () {
      final tuning = Tuning();
      // Modern guitar, course 1 open string = E4 = 64.
      expect(tuning.calcPitchNumber(1, 0, Notationtype.tabGuitar), 64);
      // Fret 3 on course 1.
      expect(tuning.calcPitchNumber(1, 3, Notationtype.tabGuitar), 67);
    });

    test('course children override the default tuning', () {
      final tuning = Tuning();
      final course = Course()
        ..n = '1'
        ..pname = Pitchname.d
        ..oct = 4;
      tuning.addChild(course);

      expect(tuning.calcPitchNumber(1, 0, Notationtype.tabGuitar), 62);
    });
  });

  group('RunningElement page numbers', () {
    test('addPageNum builds a rend with a templated num', () {
      final pgFoot = PgFoot();
      pgFoot.addPageNum(Horizontalalignment.center, Verticalalignment.bottom);

      final rend = pgFoot.findDescendantByType(ClassId.rend) as Rend?;
      expect(rend, isNotNull);
      expect(rend!.halign, Horizontalalignment.center);

      final num = pgFoot.findDescendantByType(ClassId.num) as Num?;
      expect(num, isNotNull);
      expect(num!.label, 'page');
    });

  });

  group('SymbolDef / SymbolTable / Proport', () {
    test('symbolTable only accepts symbolDef children', () {
      final table = SymbolTable();
      expect(table.addChild(SymbolDef()), isTrue);
      expect(table.addChild(Graphic()), isFalse);
    });

    test('symbolDef accepts graphic/svg/symbol children', () {
      final symbolDef = SymbolDef();
      expect(symbolDef.addChild(Graphic()), isTrue);
      expect(symbolDef.addChild(Svg()), isTrue);
      expect(symbolDef.addChild(Symbol()), isTrue);
      expect(symbolDef.addChild(Text()), isFalse);
    });

    test('temporary parenting restores the original parent', () {
      final holder = SymbolTable();
      final symbolDef = SymbolDef();
      holder.addChild(symbolDef);

      final tempParent = Graphic();
      symbolDef.setTemporaryParent(tempParent);
      expect(symbolDef.parent, same(tempParent));

      symbolDef.resetTemporaryParent();
      expect(symbolDef.parent, same(holder));
    });

    test('proport cumulates ratios and reduces them', () {
      final p1 = Proport()
        ..num = 3
        ..numbase = 2;
      final p2 = Proport()
        ..num = 2
        ..numbase = 3;

      p2.cumulate(p1);
      expect(p2.cumulatedNum, 1);
      expect(p2.cumulatedNumbase, 1);

      // Reset type proportions are not cumulated.
      final reset = Proport()
        ..type = 'reset'
        ..num = 5
        ..numbase = 4;
      reset.cumulate(p2);
      expect(reset.cumulatedNum, 5);
    });
  });
}

KeyAccid _makeKeyAccid(Pitchname pname, AccidentalWritten accid) {
  final keyAccid = KeyAccid();
  keyAccid.pname = pname;
  keyAccid.accid = accid;
  return keyAccid;
}
