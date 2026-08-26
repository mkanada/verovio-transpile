import 'package:test/test.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/model/object.dart';

/// Concrete test objects registered under distinct class ids. The real
/// element classes arrive with the rest of Phase 2; here we use the base
/// Object with explicit ids.
class Node extends Object {
  Node([super.classId]);

  @override
  String get className => 'Node';

  @override
  bool isSupportedChild(ClassId classId) => true;

  @override
  Object clone() {
    final Node copy = Node(classId);
    copy.copyFrom(this);
    return copy;
  }
}

void main() {
  group('Object IDs', () {
    test('generated ids start with a letter and are unique', () {
      final a = Node();
      final b = Node();
      expect(a.id, matches(RegExp(r'[a-z].+')));
      expect(a.id, isNot(b.id));
    });

    test('generateHashID is deterministic from the counter and reversible '
        'seeds give deterministic ids', () {
      Object.seedID(42);
      final id1 = Object.generateHashID();
      Object.seedID(42);
      final id2 = Object.generateHashID();
      expect(id1, id2);
    });

    test('hash matches known C++ values', () {
      // Reference values computed with the C++ implementation of Hash().
      expect(Object.hash(0), 0);
      expect(Object.hash(1), 0x31251ba7);
    });

    test('swapID exchanges ids', () {
      final a = Node();
      final b = Node();
      final idA = a.id;
      final idB = b.id;
      a.swapID(b);
      expect(a.id, idB);
      expect(b.id, idA);
    });
  });

  group('Object tree', () {
    late Object root;
    late Object c1;
    late Object c2;

    setUp(() {
      root = Node();
      c1 = Node();
      c2 = Node();
      expect(root.addChild(c1), isTrue);
      expect(root.addChild(c2), isTrue);
    });

    test('addChild sets parent and index', () {
      expect(c1.parent, same(root));
      expect(c2.parent, same(root));
      expect(root.getChildIndex(c1), 0);
      expect(root.getChildIndex(c2), 1);
      expect(c1.idx, 0);
      expect(c2.idx, 1);
    });

    test('childCount / getChildCount', () {
      expect(root.childCount, 2);
      expect(root.getChildCount(ClassId.object), 2);
      expect(root.getChildCount(ClassId.note), 0);
    });

    test('getFirst/getNext iterate children', () {
      expect(root.getFirst(), same(c1));
      expect(root.getNext(), same(c2));
      expect(root.getNext(), isNull);
      expect(root.getFirst(ClassId.note), isNull);
    });

    test('getNextSibling/getPreviousSibling/getLast', () {
      expect(root.getNextSibling(c1), same(c2));
      expect(root.getPreviousSibling(c2), same(c1));
      expect(root.getLast(), same(c2));
    });

    test('insertChild / detachChild', () {
      final c3 = Node();
      root.insertChild(c3, 1);
      expect(root.childCount, 3);
      expect(root.getChild(1), same(c3));

      final detached = root.detachChild(1)!;
      expect(detached, same(c3));
      expect(c3.parent, isNull);
      expect(root.childCount, 2);
    });

    test('insertBefore/insertAfter/replaceChild', () {
      final before = Node();
      root.insertBefore(c1, before);
      expect(root.getChildIndex(before), 0);

      final after = Node();
      root.insertAfter(before, after);
      expect(root.getChildIndex(after), 1);

      final replacement = Node();
      root.replaceChild(after, replacement);
      expect(root.getChild(1), same(replacement));
      expect(after.parent, isNull);
    });

    test('deleteChild removes it from the list', () {
      expect(root.deleteChild(c1), isTrue);
      expect(root.childCount, 1);
      expect(root.getChildIndex(c1), -1);
    });

    test('hasDescendant finds direct and deep descendants', () {
      final grandChild = Node();
      c1.addChild(grandChild);

      expect(root.hasDescendant(c1), isTrue);
      expect(root.hasDescendant(grandChild), isTrue);
      expect(c2.hasDescendant(grandChild), isFalse);
      // Deepness limits the search depth.
      expect(root.hasDescendant(grandChild, 0), isFalse);
      expect(root.hasDescendant(grandChild, 1), isTrue);
    });

    test('moveChildrenFrom moves ownership', () {
      final target = Node();
      target.moveChildrenFrom(root);
      expect(target.childCount, 2);
      expect(root.childCount, 0);
      expect(c1.parent, same(target));
      expect(identical(target.getChild(0), c1), isTrue);
    });

    test('relinquish + clearRelinquishedChildren', () {
      final child = root.relinquish(0)!;
      expect(child.parent, isNull);
      expect(root.childCount, 2); // still in the list
      root.clearRelinquishedChildren();
      expect(root.childCount, 1); // c1 removed, c2 still owned
    });

    test('rotateChildren rotates leftwards like std::rotate', () {
      final c3 = Node();
      final c4 = Node();
      root.addChild(c3);
      root.addChild(c4);
      // [c1 c2 c3 c4] rotate(first=0, middle=2, last=4) => [c3 c4 c1 c2]
      root.rotateChildren(0, 2, 4);
      expect(identical(root.getChild(0), c3), isTrue);
      expect(identical(root.getChild(1), c4), isTrue);
      expect(identical(root.getChild(2), c1), isTrue);
      expect(identical(root.getChild(3), c2), isTrue);
    });

    test('sortChildren stable sorts by comparator', () {
      final a = Node()..id = 'a';
      final b = Node()..id = 'b';
      final c = Node()..id = 'c';
      final parent = Node();
      parent.addChild(b);
      parent.addChild(a);
      parent.addChild(c);
      parent.sortChildren((x, y) => x.id.compareTo(y.id) < 0);
      expect(parent.getChild(0)!.id, 'a');
      expect(parent.getChild(1)!.id, 'b');
      expect(parent.getChild(2)!.id, 'c');
    });
  });

  group('Object ancestors / search', () {
    test('ancestors and firstAncestor', () {
      final root = Node(ClassId.doc);
      final measure = Node(ClassId.measure);
      final staff = Node(ClassId.staff);
      final note = Node(ClassId.note);
      root.addChild(measure);
      measure.addChild(staff);
      staff.addChild(note);

      final ancestors = note.getAncestors();
      expect(ancestors.length, 3);
      expect(identical(ancestors[0], staff), isTrue);
      expect(note.getFirstAncestor(ClassId.measure), same(measure));
      expect(note.getFirstAncestor(ClassId.doc), same(root));
      expect(note.getFirstAncestor(ClassId.score, 2), isNull);
      expect(
          note.getFirstAncestorInRange(ClassId.facsimile, ClassId.page),
          same(measure));
      // Returns the object itself when its direct parent is of the type.
      expect(note.getLastAncestorNot(ClassId.staff), same(note));
            // From staff itself (parent not of the type) nothing is found.
      expect(staff.getLastAncestorNot(ClassId.staff), isNull);
      final ossia = Node(ClassId.ossia);
      measure.addChild(ossia);
      expect(measure.getFirstChildNot(ClassId.staff), same(ossia));
      expect(measure.getFirstChildNot(ClassId.note), same(staff));
    });

    test('findDescendantByID searches the subtree', () {
      final root = Node();
      final child = Node();
      root.addChild(child);
      final grand = Node();
      child.addChild(grand);
      grand.id = 'target';

      expect(root.findDescendantByID('target'), same(grand));
      expect(root.findDescendantByID('nope'), isNull);
      // Self is not searched (skipFirst semantics).
      root.id = 'root-id';
      expect(root.findDescendantByID('root-id'), isNull);
    });

    test('findAllDescendantsByType respects editorial depth', () {
      final root = Node();
      final app = Node(ClassId.app); // editorial element
      final insideApp = Node(ClassId.note);
      app.addChild(insideApp);
      final outside = Node(ClassId.note);
      root.addChild(app);
      root.addChild(outside);

      // Editorial elements do not count towards depth: depth 1 finds both
      // notes (one level below root, but the app level is free).
      expect(root.findAllDescendantsByType(ClassId.note, deepness: 1).length,
          2);
      expect(root.getDescendantCount(ClassId.note), 2);
    });

    test('fillFlatList includes self in preorder', () {
      final root = Node();
      final a = Node();
      final b = Node();
      root.addChild(a);
      a.addChild(b);

      final List<Object> flat = [];
      root.fillFlatList(flat);
      expect(flat.length, 3);
      expect(identical(flat[0], root), isTrue);
      expect(identical(flat[1], a), isTrue);
      expect(identical(flat[2], b), isTrue);
    });

    test('isPreOrdered checks preorder relation', () {
      final root = Node();
      final a = Node();
      final b = Node();
      root.addChild(a);
      root.addChild(b);
      final aChild = Node();
      a.addChild(aChild);

      expect(Object.isPreOrdered(a, b), isTrue);
      expect(Object.isPreOrdered(b, a), isFalse);
      expect(Object.isPreOrdered(root, a), isTrue);
      expect(Object.isPreOrdered(a, root), isFalse);
      expect(Object.isPreOrdered(aChild, b), isTrue);
    });
  });

  group('Object modification flags', () {
    test('modify propagates to parents', () {
      final root = Node();
      final child = Node();
      root.addChild(child);
      root.modify(false);
      expect(root.isModified, isFalse);
      child.modify();
      expect(root.isModified, isTrue);
      expect(child.isModified, isTrue);
    });
  });

  group('ObjectFactory', () {
    test('register/create roundtrip', () {
      final factory = ObjectFactory.instance;
      factory.register('testNode', ClassId.unspecified, () => Node());
      expect(factory.getClassId('testNode'), ClassId.unspecified);
      expect(factory.create('testNode'), isA<Node>());
      expect(factory.create('unknown-element'), isNull);
      expect(factory.getClassIds(['testNode', 'unknown']).length, 1);
    });
  });

  group('Reference objects', () {
    test('reference object does not take ownership', () {
      final ref = Node()..setAsReferenceObject();
      final child = Node();
      expect(ref.addChild(child), isTrue);
      expect(child.parent, isNull); // no parent assigned
      expect(ref.isReferenceObject, isTrue);
      expect(ref.childCount, 1); // but kept in the list
    });
  });
}
