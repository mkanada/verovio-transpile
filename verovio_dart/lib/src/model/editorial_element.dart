/// Port of `editorial.h/cpp` — EditorialElement and the MEI editorial
/// element classes (app, lem, rdg, sic, corr…).
library;

import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/model/drawing_interfaces.dart';
import 'package:verovio_dart/src/model/atts/atts_shared.dart';
import 'package:verovio_dart/src/model/object.dart';

/// Mirrors `vrv::EditorialElement`.
class EditorialElement extends Object
    with
        VisibilityDrawingInterface,
        SystemMilestoneInterface,
        AttLabelled,
        AttPlist,
        AttSource,
        AttTyped {
  EditorialElement([ClassId classId = ClassId.editorialElement]) {
    _init(classId);
  }

  void _init(ClassId classId) {
    assignClassId(classId);
    reset();
  }

  @override
  String get className => '[MISSING]';

  @override
  void reset() {
    super.reset();
    label = null;
    type = null;
    visibility = VisibilityType.visible;
  }

  /// The visibility level of the editorial element (set by the IO when the
  /// element is read).
  EditorialLevel editorialLevel = EditorialLevel.undefined;

  @override
  bool isSupportedChild(ClassId classId) {
    // Mirrors EditorialElement::IsSupportedChild.
    const supported = {
      ClassId.layer,
      ClassId.measure,
      ClassId.scoreDef,
      ClassId.staff,
      ClassId.staffDef,
      ClassId.staffGrp,
      ClassId.dir,
    };
    if (supported.contains(classId)) return true;
    if (Object.isEditorialElementId(classId)) return true;
    if (Object.isSystemElementId(classId)) return true;
    if (Object.isControlElementId(classId)) return true;
    if (Object.isLayerElementId(classId)) return true;
    if (Object.isTextElementId(classId)) return true;
    return false;
  }

  @override
  void copyFrom(covariant EditorialElement other) {
    super.copyFrom(other);
    editorialLevel = other.editorialLevel;
    visibility = other.visibility;
  }
}

/// Base helper for the concrete editorial classes: they differ only by
/// classId / MEI name and (for app/lem/rdg etc.) milestone behaviour later.
class _EditorialLeaf extends EditorialElement {
  _EditorialLeaf(this._leafClassId, this._leafName) {
    // Re-run init with the concrete id (the parent constructor already ran
    // with the generic one).
    assignClassId(_leafClassId);
    reset();
  }

  final ClassId _leafClassId;
  final String _leafName;

  @override
  ClassId get classId => _leafClassId;

  @override
  String get className => _leafName;

  @override
  Object clone() {
    final copy = _EditorialLeaf(_leafClassId, _leafName);
    copy.copyFrom(this);
    return copy;
  }
}

// ---------------------------------------------------------------------------
// Concrete editorial element classes (mirrors editorial.h)
// ---------------------------------------------------------------------------

class Abbr extends _EditorialLeaf {
  Abbr() : super(ClassId.abbr, 'abbr');
}

class Add extends _EditorialLeaf {
  Add() : super(ClassId.add, 'add');
}

class Annot extends _EditorialLeaf with ObjectListInterface, TextListInterface {
  Annot() : super(ClassId.annot, 'annot');

  @override
  bool isSupportedChild(ClassId classId) => true;

  /// The copied XML content of the annotation (mirrors `Annot::m_content`).
  /// Typed dynamically because it is raw XML, not part of the object tree.
  dynamic content;
}

class App extends _EditorialLeaf {
  App() : super(ClassId.app, 'app');
}

class Choice extends _EditorialLeaf {
  Choice() : super(ClassId.choice, 'choice');
}

class Corr extends _EditorialLeaf {
  Corr() : super(ClassId.corr, 'corr');
}

class Damage extends _EditorialLeaf {
  Damage() : super(ClassId.damage, 'damage');
}

class Del extends _EditorialLeaf {
  Del() : super(ClassId.del, 'del');
}

class Expan extends _EditorialLeaf {
  Expan() : super(ClassId.expan, 'expan');
}

class Lem extends _EditorialLeaf {
  Lem() : super(ClassId.lem, 'lem');
}

class Orig extends _EditorialLeaf {
  Orig() : super(ClassId.orig, 'orig');
}

class Rdg extends _EditorialLeaf {
  Rdg() : super(ClassId.rdg, 'rdg');
}

class Ref extends _EditorialLeaf {
  Ref() : super(ClassId.ref, 'ref');
}

class Reg extends _EditorialLeaf {
  Reg() : super(ClassId.reg, 'reg');
}

class Restore extends _EditorialLeaf {
  Restore() : super(ClassId.restore, 'restore');
}

class Sic extends _EditorialLeaf {
  Sic() : super(ClassId.sic, 'sic');
}

class Subst extends _EditorialLeaf {
  Subst() : super(ClassId.subst, 'subst');
}

class Supplied extends _EditorialLeaf {
  Supplied() : super(ClassId.supplied, 'supplied');
}

class Unclear extends _EditorialLeaf {
  Unclear() : super(ClassId.unclear, 'unclear');
}
