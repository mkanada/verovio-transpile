/// Registers all ported model classes in the [ObjectFactory].
///
/// Mirrors the `ClassRegistrar` static instances spread over the C++
/// element headers. New element classes must be added here.
///
/// Deviations from the C++:
/// - `oStaff`/`stageDir` are registered under the distinct pseudo-`ClassId`s
///   `factoryOstaff`/`factoryStagedir` (see `core/vrvdef.dart`), mirroring
///   `FACTORY_OSTAFF`/`FACTORY_STAGEDIR` (`vrvdef.h:287-288`, `staff.cpp:47`,
///   `dir.cpp:31`). The created objects still report `ClassId.staff`/`dir`
///   as their `classId`/`className`, exactly like `Staff(1,true):Object(STAFF)`
///   and `Dir(true):ControlElement(DIR)` in the C++ — the factory ids exist
///   only to disambiguate the two names in the registry.
library;

import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/model/basic_elements.dart';
import 'package:verovio_dart/src/model/control_elements_gen.dart' show Dir;
import 'package:verovio_dart/src/model/editorial_element.dart';
import 'package:verovio_dart/src/model/factory_registry_gen.dart';
import 'package:verovio_dart/src/model/mensur.dart';
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/model/scoredef.dart';
import 'package:verovio_dart/src/model/zone.dart';

/// Registers every currently ported element class.
void registerModelClasses([ObjectFactory? factory]) {
  final ObjectFactory f = factory ?? ObjectFactory.instance;

  // Classes generated from the C++ headers:
  registerGeneratedClasses(f);

  // Structure elements
  f.register('measure', ClassId.measure, Measure.new);
  f.register('staff', ClassId.staff, Staff.new);
  // Mirrors `staff.cpp:47` — pseudo-ClassId with fixed-arg factory:
  // `static const ClassRegistrar<Staff> s_factoryOStaff("oStaff",
  // FACTORY_OSTAFF, []() -> Object * { return new Staff(1, true); });`
  // Uses a distinct `ClassId.factoryOstaff` (see `core/vrvdef.dart` deviation
  // note) so the two `Staff` names do not collide in the ctor registry.
  f.register('oStaff', ClassId.factoryOstaff, () {
    final s = Staff();
    s.n = 1;
    s.setOssia(true);
    return s;
  });
  f.register('layer', ClassId.layer, Layer.new);
  f.register('section', ClassId.section, Section.new);
  f.register('score', ClassId.score, Score.new);
  f.register('mdiv', ClassId.mdiv, Mdiv.new);

  // Ossia staves (`ossia.cpp:32`, `ClassRegistrar<Ossia>("ossia", OSSIA)`).
  f.register('ossia', ClassId.ossia, Ossia.new);

  // Score definition elements
  f.register('scoreDef', ClassId.scoreDef, ScoreDef.new);
  f.register('staffDef', ClassId.staffDef, StaffDef.new);
  f.register('staffGrp', ClassId.staffGrp, StaffGrp.new);
  f.register('layerDef', ClassId.layerDef, LayerDef.new);
  f.register('mensur', ClassId.mensur, Mensur.new);

  // Layer elements
  f.register('note', ClassId.note, Note.new);
  f.register('rest', ClassId.rest, Rest.new);
  f.register('clef', ClassId.clef, Clef.new);
  f.register('barLine', ClassId.barLine, BarLine.new);

  // Facsimile
  f.register('zone', ClassId.zone, Zone.new);

  // Editorial elements
  f.register('abbr', ClassId.abbr, Abbr.new);
  f.register('add', ClassId.add, Add.new);
  f.register('annot', ClassId.annot, Annot.new);
  f.register('app', ClassId.app, App.new);
  f.register('choice', ClassId.choice, Choice.new);
  f.register('corr', ClassId.corr, Corr.new);
  f.register('damage', ClassId.damage, Damage.new);
  f.register('del', ClassId.del, Del.new);
  f.register('expan', ClassId.expan, Expan.new);
  f.register('lem', ClassId.lem, Lem.new);
  f.register('orig', ClassId.orig, Orig.new);
  f.register('rdg', ClassId.rdg, Rdg.new);
  f.register('ref', ClassId.ref, Ref.new);
  f.register('reg', ClassId.reg, Reg.new);
  f.register('restore', ClassId.restore, Restore.new);
  f.register('sic', ClassId.sic, Sic.new);
  f.register('subst', ClassId.subst, Subst.new);
  f.register('supplied', ClassId.supplied, Supplied.new);
  f.register('unclear', ClassId.unclear, Unclear.new);

  // Mirrors `dir.cpp:31` — pseudo-ClassId with fixed-arg factory:
  // `static const ClassRegistrar<Dir> s_factoryStageDir("stageDir",
  // FACTORY_STAGEDIR, []() -> Object * { return new Dir(true); });`
  // Distinct `ClassId.factoryStagedir` keeps the two `Dir` names from
  // colliding in the ctor registry (see deviation note in `core/vrvdef.dart`).
  f.register('stageDir', ClassId.factoryStagedir, () => Dir(true));
}
