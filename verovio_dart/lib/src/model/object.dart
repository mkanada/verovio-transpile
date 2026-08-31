/// Port of `object.h/cpp` — the Object base class of the Verovio data model.
///
/// This class represents a basic object of the object tree (Doc → Pages →
/// Systems → Measures → Staves → Layers → LayerElements, plus floating
/// objects, editorial elements, etc.).
///
/// Functor-based features: `Process` is ported here (dispatching through
/// `lib/src/layout/functor.dart`); search helpers implemented here replicate
/// the same traversal semantics (editorial elements do not count towards
/// depth).
library;

import 'package:meta/meta.dart' show protected;
import '../core/attdef.dart' show meiUnset;
import '../layout/functor.dart' show Functor, FunctorBase;
import 'package:verovio_dart/src/core/bounding_box.dart';
import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/utils.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/rendering/resources.dart' show Resources;
import 'comparison.dart' show Comparison, Filters;
import 'doc.dart' show Doc;
import 'interfaces/linking_interface.dart' show LinkingInterface;
import 'misc_elements_gen.dart' show Text;
import 'drawing_interfaces.dart'
    show
        PageMilestoneInterface,
        SystemMilestoneInterface,
        VisibilityDrawingInterface;

/// Mirrors `UNLIMITED_DEPTH`.
const int unlimitedDepth = -10000;

/// Mirrors `FORWARD` / `BACKWARD` directions.
const bool forward = true;
const bool backward = false;

/// Comparator signature for sorting children.
typedef BinaryObjectComp = bool Function(Object a, Object b);

/// A list of objects.
typedef ListOfObjects = List<Object>;

/// This class represents a basic object (mirrors `vrv::Object`).
///
/// Note: the class intentionally shares its name with `dart:core`'s [Object];
/// within this library it always refers to the model class.
class Object extends BoundingBox {
  Object([ClassId classId = ClassId.object]) {
    if (_objectCounter++ == 0) {
      seedID();
    }
    _init(classId);
  }

  /// Initialisation method taking the class id argument (mirrors `Init`).
  void _init(ClassId classId) {
    _classId = classId;
    _parent = null;
    // Flags
    isAttribute = false;
    _isModified = true;
    _isReferenceObject = false;
    // Comments
    comment = '';
    closingComment = '';

    generateID();

    reset();
  }

  /// The children of the object. Unless [isReferenceObject] is set, the
  /// children are owned by this object.
  final List<Object> _children = [];

  /// The parent object.
  Object? _parent;

  /// The class id representing the actual (derived) class.
  ClassId _classId = ClassId.object;

  /// Members for storing / generating ids.
  String id = '';

  /// A reference object does not own children.
  bool _isReferenceObject = false;

  /// Indicates whether the object content is up-to-date or not.
  ///
  /// Useful for objects maintaining sub-lists of other objects when drawing
  /// (e.g., Beam). Mostly an optimization feature.
  bool _isModified = true;

  /// Iterator state used by [getFirst] / [getNext].
  int _iteratorCurrent = -1;
  ClassId _iteratorElementType = ClassId.unspecified;

  /// A vector for storing the list of InterfaceIds implemented.
  final List<InterfaceId> _interfaces = [];

  /// Comments attached to the object when printing an MEI element:
  /// printed before the element / before the closing tag respectively.
  String comment = '';
  String closingComment = '';

  /// An array of unsupported attributes as pairs, used for writing back data.
  final List<(String, String)> unsupported = [];

  /// A flag indicating if the Object represents an attribute in the original
  /// MEI (e.g., an Artic child in Note for an original @artic).
  bool isAttribute = false;

  /// A flag indicating if the Object is a copy created by an expanded
  /// expansion element.
  bool isExpansion = false;

  /// List of back-links to plist referring objects.
  final List<Object> _plistReferences = [];

  //----------------//
  // Static members //
  //----------------//

  /// A static counter for id generation.
  static int _objectCounter = 0;

  /// XML id counter.
  static int _xmlIDCounter = 0;

  // -------------------------------------------------------------------------
  // Standard methods
  // -------------------------------------------------------------------------

  @override
  ClassId get classId => _classId;

  /// Mirrors `Object::GetDocResources` (object.cpp:206): the resources of the
  /// [Doc] this object belongs to, or `null` when it is attached to none.
  Resources? getDocResources() {
    final Object? doc =
        classId == ClassId.doc ? this : getFirstAncestor(ClassId.doc);
    if (doc is Doc) return doc.getResources();
    logWarning('Requested resources unavailable, returning null');
    return null;
  }

  /// Exposes the raw field for the 05-27 parity test — must equal [classId].
  ///
  /// If a subclass overrides [classId] without calling [assignClassId] with
  /// the same value, this getter diverges from [classId] and the test fails.
  /// Mirrors the `m_classId` check in `object.h:105-145`.
  ClassId get debugRawClassId => _classId;

  /// Assigns the concrete [ClassId] of the derived base-class layer.
  ///
  /// Used by the element base classes (LayerElement, ControlElement…) whose
  /// constructors receive the concrete id; mirrors the C++ pattern where the
  /// ClassId is passed to the Object constructor.
  @protected
  void assignClassId(ClassId classId) {
    _classId = classId;
  }

  String get className => '[MISSING]';

  /// Make an object a reference object that does not own children.
  ///
  /// This cannot be undone and has to be set before any child is added.
  void setAsReferenceObject() {
    assert(_children.isEmpty);
    _isReferenceObject = true;
  }

  bool get isReferenceObject => _isReferenceObject;

  /// Wrapper for checking if an element is a floating object (system elements
  /// and control elements).
  bool get isFloatingObject => isSystemElement || isControlElement;

  // -------------------------------------------------------------------------
  // Group checks (instance + static)
  // -------------------------------------------------------------------------

  bool get isControlElement => isControlElementId(classId);
  bool get isEditorialElement => isEditorialElementId(classId);
  bool get isLayerElement => isLayerElementId(classId);
  bool get isPageElement => isPageElementId(classId);
  bool get isRunningElement => isRunningElementId(classId);
  bool get isScoreDefElement => isScoreDefElementId(classId);
  bool get isSystemElement => isSystemElementId(classId);
  bool get isTextElement => isTextElementId(classId);

  /// True when the object is a milestone (start) element that will have (or
  /// has) a corresponding end element (mirrors `Object::IsMilestoneElement`,
  /// object.cpp:239).
  ///
  /// Deviations from the C++:
  /// - the C++ `dynamic_cast` to the milestone interfaces is subsumed by the
  ///   nominal Dart `is` checks (the mixins are applied exactly where the
  ///   C++ multiple inheritance is).
  bool get isMilestoneElement {
    if (isEditorialElement ||
        isClass(ClassId.ending) ||
        isClass(ClassId.section)) {
      if (this is SystemMilestoneInterface) {
        return (this as SystemMilestoneInterface).isSystemMilestone();
      }
      assert(false);
      return false;
    } else if (isClass(ClassId.mdiv) || isClass(ClassId.score)) {
      if (this is PageMilestoneInterface) {
        return (this as PageMilestoneInterface).isPageMilestone();
      }
      assert(false);
      return false;
    }
    return false;
  }

  static bool isControlElementId(ClassId classId) =>
      _inRange(classId, ClassId.controlElement, ClassId.controlElementMax);
  static bool isEditorialElementId(ClassId classId) =>
      _inRange(classId, ClassId.editorialElement, ClassId.editorialElementMax);
  static bool isLayerElementId(ClassId classId) =>
      _inRange(classId, ClassId.layerElement, ClassId.layerElementMax);
  static bool isPageElementId(ClassId classId) =>
      _inRange(classId, ClassId.pageElement, ClassId.pageElementMax);
  static bool isRunningElementId(ClassId classId) =>
      _inRange(classId, ClassId.runningElement, ClassId.runningElementMax);
  static bool isScoreDefElementId(ClassId classId) =>
      _inRange(classId, ClassId.scoreDefElement, ClassId.scoreDefElementMax);
  static bool isSystemElementId(ClassId classId) =>
      _inRange(classId, ClassId.systemElement, ClassId.systemElementMax);
  static bool isTextElementId(ClassId classId) =>
      _inRange(classId, ClassId.textElement, ClassId.textElementMax);

  static bool _inRange(ClassId classId, ClassId min, ClassId max) =>
      classId.index > min.index && classId.index < max.index;

  // -------------------------------------------------------------------------
  // Interfaces registration
  // -------------------------------------------------------------------------

  void registerInterface(InterfaceId interfaceId) {
    _interfaces.add(interfaceId);
  }

  void registerInterfaces(List<InterfaceId> interfaceIds) {
    _interfaces.addAll(interfaceIds);
  }

  bool hasInterface(InterfaceId interfaceId) =>
      _interfaces.contains(interfaceId);

  // -------------------------------------------------------------------------
  // Reset / copy
  // -------------------------------------------------------------------------

  /// Reset the object: remove all children and reset attributes.
  ///
  /// Overriding methods must always call the parent implementation.
  void reset() {
    clearChildren();
    resetBoundingBox();
  }

  /// Copy the content of [other] into this object (mirrors `operator=`).
  ///
  /// Children are cloned recursively if [copyChildrenFrom] returns true.
  void copyFrom(Object other) {
    if (identical(this, other)) return;

    clearChildren();
    resetBoundingBox(); // It does not make sense to keep the BBox values.

    _classId = other._classId;
    _parent = null;
    // Flags
    isAttribute = other.isAttribute;
    _isModified = true;
    _isReferenceObject = other._isReferenceObject;

    // Also copy interfaces
    _interfaces.clear();
    _interfaces.addAll(other._interfaces);
    // New id
    generateID();
    // For now do not copy comments
    comment = other.comment;
    closingComment = other.closingComment;
    unsupported
      ..clear()
      ..addAll(other.unsupported);

    if (!other.copyChildren()) return;

    for (final Object current in other._children) {
      final Object clone = current.clone();
      if (clone is LinkingInterface) {
        (clone as LinkingInterface).addBackLink(current);
      }
      clone.setParent(this);
      clone.cloneReset();
      _children.add(clone);
    }

    // Mirrors `link->AddBackLink(&object)` performed by the C++
    // operator= for objects implementing LinkingInterface.
    if (this is LinkingInterface) {
      (this as LinkingInterface).addBackLink(other);
    }
  }

  /// Method call for copying child classes; must be overridden.
  Object clone() {
    throw UnimplementedError('clone() must be overridden by $runtimeType');
  }

  /// Indicate whether children have to be copied by copy / assignment.
  ///
  /// True by default but can be overridden (e.g., for Staff, Layer).
  bool copyChildren() => true;

  /// Reset pointers after a copy / assignment call.
  void cloneReset() {
    modify();
  }

  /// Move all children of [sourceParent] to this object.
  ///
  /// Objects must be of the same type unless [allowTypeChange]. After this
  /// operation, [sourceParent] has no child anymore. If [idx] is provided,
  /// children are moved at that position.
  void moveChildrenFrom(Object sourceParent,
      {int idx = -1, bool allowTypeChange = false}) {
    assert(!identical(this, sourceParent), 'Object cannot be copied to itself');
    assert(allowTypeChange || _classId == sourceParent._classId,
        'Object must be of the same type');

    while (sourceParent._children.isNotEmpty) {
      final Object child = sourceParent._children.removeAt(0);
      child.resetParent();
      if (idx != -1) {
        insertChild(child, idx);
        idx++;
      } else {
        addChild(child);
      }
    }
  }

  /// Replace [currentChild] with [replacingChild].
  ///
  /// The currentChild is not deleted by this method.
  void replaceChild(Object currentChild, Object replacingChild) {
    assert(getChildIndex(currentChild) != -1);
    assert(getChildIndex(replacingChild) == -1);

    final int idx = getChildIndex(currentChild);
    currentChild.resetParent();
    _children[idx] = replacingChild;
    replacingChild.setParent(this);
    modify();
  }

  /// Insert [newChild] before [child].
  void insertBefore(Object child, Object newChild) {
    assert(getChildIndex(child) != -1);
    assert(getChildIndex(newChild) == -1);

    insertChild(newChild, getChildIndex(child));
    modify();
  }

  /// Insert [newChild] after [child].
  void insertAfter(Object child, Object newChild) {
    assert(getChildIndex(child) != -1);
    assert(getChildIndex(newChild) == -1);

    insertChild(newChild, getChildIndex(child) + 1);
    modify();
  }

  /// Sort children by [comp] (stable sort).
  ///
  /// Returns true if the order of children changed.
  void sortChildren(BinaryObjectComp comp) {
    // Stable sort via index tie-breaking.
    final Map<Object, int> order = {
      for (var i = 0; i < _children.length; ++i) _children[i]: i,
    };
    _children.sort((a, b) {
      if (comp(a, b)) return -1;
      if (comp(b, a)) return 1;
      return order[a]! - order[b]!;
    });
    modify();
  }

  /// Move this object to [targetParent].
  void moveItselfTo(Object targetParent) {
    assert(parent != null);
    assert(!identical(parent, targetParent));

    final Object? relinquished = parent!.relinquish(idx!);
    assert(relinquished != null && identical(relinquished, this));
    targetParent.addChild(relinquished!);
  }

  // -------------------------------------------------------------------------
  // IDs
  // -------------------------------------------------------------------------

  void swapID(Object other) {
    final String swap = id;
    id = other.id;
    other.id = swap;
  }

  void resetID() {
    generateID();
  }

  void generateID() {
    // A random letter from a-z.
    final String letter = String.fromCharCode(0x61 + (_xmlIDCounter % 26));
    id = letter + generateHashID();
  }

  static void seedID([int seed = 0]) {
    if (seed == 0) {
      // Random start ID.
      _xmlIDCounter = DateTime.now().microsecondsSinceEpoch & 0xFFFFFFFF;
    } else {
      // Deterministic start ID.
      _xmlIDCounter = hash(seed);
    }
  }

  static String generateHashID() {
    final int nr = hash(++_xmlIDCounter);
    return baseEncodeInt(nr, 36);
  }

  static int hash(int number, {bool reverse = false}) {
    const int mask = 0xFFFFFFFF;
    final int magicNumber = reverse ? 0x119de1f3 : 0x45d9f3b;
    number &= mask;
    number = (((number >> 16) ^ number) * magicNumber) & mask;
    number = (((number >> 16) ^ number) * magicNumber) & mask;
    number = ((number >> 16) ^ number) & mask;
    return number;
  }

  // -------------------------------------------------------------------------
  // Children count / access
  // -------------------------------------------------------------------------

  int get childCount => _children.length;

  int getChildCount(ClassId classId) => _children
      .where(
          (child) => classId == ClassId.unspecified || child.classId == classId)
      .length;

  int getChildCountWithDepth(ClassId classId, int depth) =>
      findAllDescendantsByType(classId, deepness: depth).length;

  int getDescendantCount(ClassId classId) =>
      findAllDescendantsByType(classId).length;

  /// Child access (generic).
  Object? getChild(int idx, [ClassId? classId]) {
    if (classId == null) {
      if (idx < 0 || idx >= _children.length) return null;
      return _children[idx];
    }
    final List<Object> objects = findAllDescendantsByType(classId,
        continueDepthSearchForMatches: true, deepness: 1);
    if (idx < 0 || idx >= objects.length) return null;
    return objects[idx];
  }

  /// Return the child of [parent] that is the ancestor of [descendant]
  /// (or [descendant] itself if it is already a direct child).
  Object? getDirectChildOf(Object parent, Object descendant) {
    if (!parent.hasDescendant(descendant)) return null;
    Object? result = descendant;
    while (result != null && !identical(result.parent, parent)) {
      result = result.parent;
    }
    return result;
  }

  /// Return the children (unmodifiable view).
  List<Object> get children => List.unmodifiable(_children);

  /// Return a reference to the children that allows modification.
  ///
  /// Should only be used in AddChild override methods.
  List<Object> get childrenForModification => _children;

  // -------------------------------------------------------------------------
  // Iterators
  // -------------------------------------------------------------------------

  /// Returns the first child of the specified type (null if none).
  ///
  /// Always call [getFirst] before [getNext].
  Object? getFirst([ClassId classId = ClassId.unspecified]) {
    _iteratorElementType = classId;
    for (int i = 0; i < _children.length; ++i) {
      if (_matches(_children[i])) {
        _iteratorCurrent = i;
        return _children[i];
      }
    }
    _iteratorCurrent = _children.length;
    return null;
  }

  /// Returns the next child of the type stored by [getFirst].
  Object? getNext() {
    for (int i = _iteratorCurrent + 1; i < _children.length; ++i) {
      if (_matches(_children[i])) {
        _iteratorCurrent = i;
        return _children[i];
      }
    }
    _iteratorCurrent = _children.length;
    return null;
  }

  bool _matches(Object child) =>
      _iteratorElementType == ClassId.unspecified ||
      child.classId == _iteratorElementType;

  /// Retrieving the next sibling of [child] of the given type (null if not
  /// found).
  Object? getNextSibling(Object child, [ClassId? classId]) {
    final int start = getChildIndex(child);
    if (start == -1) return null;
    for (int i = start + 1; i < _children.length; ++i) {
      if (classId == null || _children[i].classId == classId) {
        return _children[i];
      }
    }
    return null;
  }

  /// Retrieving the previous sibling of [child] of the given type.
  Object? getPreviousSibling(Object child, [ClassId? classId]) {
    final int start = getChildIndex(child);
    if (start == -1) return null;
    for (int i = start - 1; i >= 0; --i) {
      if (classId == null || _children[i].classId == classId) {
        return _children[i];
      }
    }
    return null;
  }

  /// Return the last child of the given type (null if none).
  Object? getLast([ClassId? classId]) {
    for (int i = _children.length - 1; i >= 0; --i) {
      if (classId == null || _children[i].classId == classId) {
        return _children[i];
      }
    }
    return null;
  }

  // -------------------------------------------------------------------------
  // Parent
  // -------------------------------------------------------------------------

  Object? get parent => _parent;

  /// Set the parent of the object. The current parent is expected to be null.
  void setParent(Object parent) {
    assert(_parent == null);
    _parent = parent;
  }

  /// Reset the parent of the object. The current parent is not expected to be
  /// null.
  void resetParent() {
    _parent = null;
  }

  // -------------------------------------------------------------------------
  // Adding children
  // -------------------------------------------------------------------------

  /// Base method for checking if a child can be added; must be overridden.
  bool isSupportedChild(ClassId classId) {
    logDebug('Method for adding $classId to $className should be overridden');
    return false;
  }

  /// Base method for adding children; can be overridden.
  bool addChild(Object child) {
    if (!isSupportedChild(child.classId) || !addChildAdditionalCheck(child)) {
      logError("Adding '${child.className}' to a '$className'");
      return false;
    }

    if (!isReferenceObject) {
      child.setParent(this);
    }
    final int insertOrder = getInsertOrderFor(child.classId);
    // No child or no order specified — the child is appended at the end.
    if (_children.isEmpty || insertOrder == meiUnset) {
      _children.add(child);
    } else {
      int i = 0;
      for (final Object existingChild in _children) {
        // By doing abs() we convert VRV_UNSET to a positive value and insert
        // anything with an insertOrder before it.
        if (getInsertOrderFor(existingChild.classId).abs() > insertOrder) break;
        ++i;
      }
      i = i < _children.length ? i : _children.length;
      _children.insert(i, child);
    }
    modify();

    return true;
  }

  /// Additional check when adding a child.
  bool addChildAdditionalCheck(Object child) => true;

  /// Return the child order for the given [classId].
  ///
  /// By default, a child is added at the end ([meiUnset]), but a class can
  /// override this method to order them using a static list of ClassIds.
  int getInsertOrderFor(ClassId classId) => meiUnset;

  /// Find the order from an overridden [getInsertOrderFor] method.
  int getInsertOrderForIn(ClassId classId, List<ClassId> order) {
    final int index = order.indexOf(classId);
    if (index == -1) return meiUnset;
    return index;
  }

  // -------------------------------------------------------------------------
  // Indices / structure manipulation
  // -------------------------------------------------------------------------

  /// Return the index position of the object in its parent (-1 if not found).
  int? get idx {
    assert(_parent != null);
    return _parent?.getChildIndex(this);
  }

  /// Look for the [child] in the children and return its position (-1 if not
  /// found).
  int getChildIndex(Object child) {
    for (int i = 0; i < _children.length; ++i) {
      if (identical(child, _children[i])) return i;
    }
    return -1;
  }

  /// Look for all objects of a class and return the position (-1 if not
  /// found).
  int getDescendantIndex(Object child, ClassId classId, int depth) {
    final List<Object> objects =
        findAllDescendantsByType(classId, deepness: depth);
    for (int i = 0; i < objects.length; ++i) {
      if (identical(child, objects[i])) return i;
    }
    return -1;
  }

  /// Insert an element at position [idx].
  void insertChild(Object element, int idx) {
    // With this method we require the parent to be null.
    assert(element.parent == null);
    element.setParent(this);

    if (idx >= _children.length) {
      _children.add(element);
      return;
    }
    _children.insert(idx, element);
  }

  /// Rotates the child elements leftwards: elements from [first] (included)
  /// to [last] (not included) are rotated so that the element at [middle]
  /// becomes the new first element (see `std::rotate`).
  void rotateChildren(int first, int middle, int last) {
    final List<Object> rotated = [
      ..._children.sublist(middle, last),
      ..._children.sublist(first, middle),
    ];
    _children.replaceRange(first, last, rotated);
  }

  /// Detach the child at [idx] (null if not found).
  ///
  /// The parent pointer of the detached child is set to null.
  Object? detachChild(int idx) {
    if (idx >= _children.length) return null;
    final Object child = _children[idx];
    child.resetParent();
    _children.removeAt(idx);
    return child;
  }

  /// Replace this object with a copy of [other]. They must be of the same
  /// class.
  void replaceWithCopyOf(Object other) {
    final Object? savedParent = parent;
    copyFrom(other);
    cloneReset();
    if (savedParent != null) {
      _parent = savedParent;
    }
  }

  /// Return true if the object has [child] as descendant (direct or not).
  ///
  /// Processes depth-first.
  bool hasDescendant(Object child, [int deepness = unlimitedDepth]) {
    for (final Object iter in _children) {
      if (identical(child, iter)) return true;
      if (deepness == 0) return false;
      if (iter.hasDescendant(child, deepness - 1)) return true;
    }
    return false;
  }

  /// Give up ownership of the child at [idx] (null if not found).
  ///
  /// To be used only in the particular case where the child cannot be
  /// detached straight away (typically within an iterator). The parent of the
  /// object is set to null but the object stays in the list; call
  /// [clearRelinquishedChildren] afterwards if the parent is not destroyed.
  Object? relinquish(int idx) {
    if (idx >= _children.length) return null;
    final Object child = _children[idx];
    child.resetParent();
    return child;
  }

  /// Removes all the children that were previously relinquished.
  void clearRelinquishedChildren() {
    _children.removeWhere((child) => !identical(child.parent, this));
  }

  /// Clear the children list (all children are released to the GC).
  void clearChildren() {
    if (_isReferenceObject) {
      _children.clear();
      return;
    }
    for (final Object child in _children) {
      // We need to check if this is still the parent — ownership might have
      // been given up with relinquish.
      if (identical(child.parent, this)) {
        child.resetParent();
      }
    }
    _children.clear();
  }

  /// Remove [child]. Returns false if the child could not be found.
  bool deleteChild(Object child) {
    final int idx = getChildIndex(child);
    if (idx != -1) {
      _children.removeAt(idx);
      modify();
      return true;
    }
    return false;
  }

  /// Delete the children matching [comparison]. Returns the number of
  /// deleted children.
  int deleteChildrenByComparison(bool Function(Object) comparison) {
    final int before = _children.length;
    _children.removeWhere(comparison);
    final int count = before - _children.length;
    if (count > 0) modify();
    return count;
  }

  // -------------------------------------------------------------------------
  // Functor processing
  // -------------------------------------------------------------------------

  /// Process the object tree with [functor], depth-first (mirrors
  /// `Object::Process(Functor &, int, bool)`).
  ///
  /// [deepness] limits the number of levels between the parent and its
  /// children ([unlimitedDepth] by default); editorial elements do not count
  /// towards it. [skipFirst] skips the visit of this object itself.
  void process(
    Functor functor, {
    int deepness = unlimitedDepth,
    bool skipFirst = false,
  }) {
    // Port-only execution trace: record the top-level pipeline functors
    // (runs started while no other process call is on the stack); sub-functor
    // runs nested inside another functor's visits are not part of the
    // page.cpp pipeline order the tests assert.
    if (FunctorBase.processDepth == 0 && FunctorBase.executionTrace != null) {
      FunctorBase.executionTrace!.add(functor.runtimeType.toString());
    }
    FunctorBase.processDepth++;
    try {
      if (functor.code == FunctorCode.stop) {
        return;
      }

      if (!skipFirst) {
        final FunctorCode code = functor.visit(this);
        functor.setCode(code);
      }

      // Do not go any deeper in this case.
      if (functor.code == FunctorCode.siblings) {
        functor.setCode(FunctorCode.continue_);
        return;
      } else if (isEditorialElement) {
        // Since editorial objects do not count, increase the deepness limit.
        ++deepness;
      }
      if (deepness == 0) {
        // Any need to change the functor code?
        return;
      }
      --deepness;

      if (!skipChildren(functor.visibleOnly)) {
        final List<Object> childrenList = childrenForModification;
        final Filters? filters = functor.filters;
        if (functor.direction == backward) {
          for (int i = childrenList.length - 1; i >= 0; --i) {
            // We end up here if there is no filter at all or for the current
            // child type.
            if (filtersApply(filters, childrenList[i])) {
              childrenList[i].process(functor, deepness: deepness);
            }
          }
        } else {
          for (final Object child in childrenList) {
            // We end up here if there is no filter at all or for the current
            // child type.
            if (filtersApply(filters, child)) {
              child.process(functor, deepness: deepness);
            }
          }
        }
      }

      if (functor.implementsEndInterface && !skipFirst) {
        final FunctorCode code = functor.visitEnd(this);
        functor.setCode(code);
      }
    } finally {
      FunctorBase.processDepth--;
    }
  }

  /// Return true if the children have to be skipped during processing
  /// (mirrors `Object::SkipChildren`): with [visibleOnly], hidden mdiv /
  /// staff / system / editorial elements are not entered.
  bool skipChildren(bool visibleOnly) {
    if (visibleOnly) {
      if (isEditorialElement ||
          classId == ClassId.mdiv ||
          classId == ClassId.staff ||
          isSystemElement) {
        final VisibilityDrawingInterface? interface =
            this is VisibilityDrawingInterface
                ? this as VisibilityDrawingInterface
                : null;
        assert(interface != null);
        if (interface != null && interface.isHidden) {
          return true;
        }
      }
    }
    return false;
  }

  /// Apply the comparison [filters] to [object]; always true without filters
  /// (mirrors `Object::FiltersApply`).
  bool filtersApply(Filters? filters, Object object) =>
      filters?.apply(object) ?? true;

  // -------------------------------------------------------------------------
  // Search
  // -------------------------------------------------------------------------

  /// Look for a descendant with the specified [id] (null if not found).
  Object? findDescendantByID(String id,
      {int deepness = unlimitedDepth, bool direction = forward}) {
    final List<Object> result = [];
    _traverse(this, deepness, skipSelf: true, direction: direction,
        visit: (Object object) {
      if (object.id == id) {
        result.add(object);
        return FunctorCode.stop;
      }
      return FunctorCode.continue_;
    });
    return result.isEmpty ? null : result.first;
  }

  /// Look for a descendant with the specified type (null if not found).
  Object? findDescendantByType(ClassId classId,
      {int deepness = unlimitedDepth, bool direction = forward}) {
    final List<Object> found =
        findAllDescendantsByType(classId, deepness: deepness);
    return found.isEmpty ? null : found.first;
  }

  /// Return all the objects with the specified type.
  List<Object> findAllDescendantsByType(ClassId classId,
      {bool continueDepthSearchForMatches = true,
      int deepness = unlimitedDepth}) {
    final List<Object> descendants = [];
    _traverse(this, deepness, skipSelf: true, direction: forward,
        visit: (Object object) {
      if (classId == ClassId.unspecified || object.classId == classId) {
        descendants.add(object);
        return continueDepthSearchForMatches
            ? FunctorCode.continue_
            : FunctorCode.siblings;
      }
      return FunctorCode.continue_;
    });
    return descendants;
  }

  /// Returns all ancestors (nearest first).
  List<Object> getAncestors() {
    final List<Object> ancestors = [];
    Object? object = _parent;
    while (object != null) {
      ancestors.add(object);
      object = object._parent;
    }
    return ancestors;
  }

  /// Return the first ancestor of the specified type.
  ///
  /// [maxSteps] limits the search to a certain number of levels if not -1.
  Object? getFirstAncestor(ClassId classId, [int maxSteps = -1]) {
    if (maxSteps == 0 || _parent == null) return null;

    if (_parent!._classId == classId) return _parent;
    return _parent!.getFirstAncestor(classId, maxSteps - 1);
  }

  Object? getFirstAncestorInRange(ClassId classIdMin, ClassId classIdMax,
      [int maxDepth = -1]) {
    if (maxDepth == 0 || _parent == null) return null;

    if (_parent!._classId.index > classIdMin.index &&
        _parent!._classId.index < classIdMax.index) {
      return _parent;
    }
    return _parent!
        .getFirstAncestorInRange(classIdMin, classIdMax, maxDepth - 1);
  }

  /// Return the last ancestor that is NOT of the specified type.
  Object? getLastAncestorNot(ClassId classId, [int maxSteps = -1]) {
    if (maxSteps == 0 || _parent == null) return null;

    if (_parent!._classId == classId) return this;
    return _parent!.getLastAncestorNot(classId, maxSteps - 1);
  }

  /// Return the first child that is NOT of the specified type.
  Object? getFirstChildNot(ClassId classId) {
    for (final Object child in _children) {
      if (child.classId != classId) return child;
    }
    return null;
  }

  /// Return true if the object contains any editorial content.
  bool get hasEditorialContent => findAllDescendantsByClassIdPredicate(
      (ClassId classId) => isEditorialElementId(classId)).isNotEmpty;

  /// Return true if the object contains anything that is not editorial
  /// content.
  bool get hasNonEditorialContent => findAllDescendantsByClassIdPredicate(
      (ClassId classId) => !isEditorialElementId(classId)).isNotEmpty;

  /// Return all the objects matching a ClassId predicate.
  ///
  /// Simplified equivalent of `FindAllDescendantsByComparison` (self excluded)
  /// until the Comparison functors are ported.
  List<Object> findAllDescendantsByClassIdPredicate(
      bool Function(ClassId) match,
      {int deepness = unlimitedDepth}) {
    final List<Object> objects = [];
    _traverse(this, deepness, skipSelf: true, direction: forward,
        visit: (Object object) {
      if (match(object.classId)) objects.add(object);
      return FunctorCode.continue_;
    });
    return objects;
  }

  /// Look for a descendant object for which the [comparison] is true
  /// (mirrors `FindDescendantByComparison`; self excluded).
  Object? findDescendantByComparison(Comparison comparison,
      {int deepness = unlimitedDepth, bool direction = forward}) {
    final List<Object> result = [];
    _traverse(this, deepness, skipSelf: true, direction: direction,
        visit: (Object object) {
      if (comparison(object)) {
        result.add(object);
        return FunctorCode.stop;
      }
      return FunctorCode.continue_;
    });
    return result.isEmpty ? null : result.first;
  }

  /// Look for the last descendant matching the comparison in traversal order
  /// (mirrors `FindDescendantExtremeByComparison`; self excluded).
  Object? findDescendantExtremeByComparison(Comparison comparison,
      {int deepness = unlimitedDepth, bool direction = forward}) {
    Object? extreme;
    _traverse(this, deepness, skipSelf: true, direction: direction,
        visit: (Object object) {
      if (comparison(object)) extreme = object;
      return FunctorCode.continue_;
    });
    return extreme;
  }

  /// Look for all descendants matching the comparison (mirrors
  /// `FindAllDescendantsByComparison`; self excluded).
  List<Object> findAllDescendantsMatching(Comparison comparison,
      {int deepness = unlimitedDepth, bool direction = forward}) {
    final List<Object> objects = [];
    _traverse(this, deepness, skipSelf: true, direction: direction,
        visit: (Object object) {
      if (comparison(object)) objects.add(object);
      return FunctorCode.continue_;
    });
    return objects;
  }

  /// Fill [flatList] with all the objects in the tree (preorder, including
  /// this one). Mirrors `FillFlatList`.
  void fillFlatList(List<Object> flatList) {
    _traverse(this, unlimitedDepth, skipSelf: false, direction: forward,
        visit: (Object object) {
      flatList.add(object);
      return FunctorCode.continue_;
    });
  }

  // -------------------------------------------------------------------------
  // Traversal helper replicating Object::Process semantics for searches
  // -------------------------------------------------------------------------

  /// Preorder traversal mirroring `Process`: editorial elements do not count
  /// towards [deepness]; a visit returning [FunctorCode.siblings] skips the
  /// children of that node; [FunctorCode.stop] aborts the whole traversal.
  ///
  /// The root node is visited only when [skipSelf] is false; its own visit
  /// code controls whether children are entered.
  void _traverse(
    Object node,
    int deepness, {
    required bool skipSelf,
    required bool direction,
    required FunctorCode Function(Object) visit,
  }) {
    if (!skipSelf) {
      final FunctorCode code = visit(node);
      if (code == FunctorCode.stop) return;
      // Do not go any deeper in this case.
      if (code == FunctorCode.siblings) return;
    }

    _traverseChildrenOnly(node, deepness, direction, visit);
  }

  /// Continue a traversal for a node whose visit already happened.
  void _traverseChildrenOnly(Object node, int deepness, bool direction,
      FunctorCode Function(Object) visit) {
    int d = deepness;
    if (node.isEditorialElement) ++d;
    if (d == 0) return;
    --d;

    final List<Object> children = node._children;
    final int start = direction == backward ? children.length - 1 : 0;
    final int end = direction == backward ? -1 : children.length;
    final int step = direction == backward ? -1 : 1;
    for (int i = start; i != end; i += step) {
      final Object child = children[i];
      final FunctorCode code = visit(child);
      if (code == FunctorCode.stop) return;
      if (code != FunctorCode.siblings) {
        _traverseChildrenOnly(child, d, direction, visit);
      }
    }
  }

  // -------------------------------------------------------------------------
  // Modification flags
  // -------------------------------------------------------------------------

  bool get isModified => _isModified;

  /// Mark the object and its parent (if any) as modified.
  void modify([bool modified = true]) {
    // If we have a parent and a new modification, propagate it.
    if (_parent != null && modified) {
      _parent!.modify();
    }
    _isModified = modified;
  }

  // -------------------------------------------------------------------------
  // plist back-links
  // -------------------------------------------------------------------------

  bool get hasPlistReferences => _plistReferences.isNotEmpty;
  void resetPlistReferences() => _plistReferences.clear();
  List<Object> get plistReferences => List.unmodifiable(_plistReferences);
  void addPlistReference(Object object) => _plistReferences.add(object);

  // -------------------------------------------------------------------------
  // Drawing position
  // -------------------------------------------------------------------------

  @override
  int getDrawingX() {
    // The root of the tree (the Doc) has no parent; its x position is the
    // origin (mirrors Page::GetDrawingX returning 0 without a view).
    if (_parent == null) return 0;
    return _parent!.getDrawingX();
  }

  @override
  int getDrawingY() {
    if (_parent == null) return 0;
    return _parent!.getDrawingY();
  }

  @override
  void resetCachedDrawingX() {
    cachedDrawingX = meiUnset;
    for (final Object child in _children) {
      child.resetCachedDrawingX();
    }
  }

  @override
  void resetCachedDrawingY() {
    cachedDrawingY = meiUnset;
    for (final Object child in _children) {
      child.resetCachedDrawingY();
    }
  }

  // -------------------------------------------------------------------------
  // Debugging
  // -------------------------------------------------------------------------

  /// Output the class name of the object and of its children recursively.
  void logDebugTree([int maxDepth = unlimitedDepth, int level = 0]) {
    logDebug('${'\t' * level}${logDebugTreeMsg()}');

    if (maxDepth == level) return;

    for (final Object child in _children) {
      child.logDebugTree(maxDepth, level + 1);
    }
  }

  String logDebugTreeMsg() => className;

  // -------------------------------------------------------------------------
  // Static ordering
  // -------------------------------------------------------------------------

  /// Return true if [left] appears before [right] in preorder traversal.
  static bool isPreOrdered(Object left, Object right) {
    final List<Object> ancestorsLeft = [left, ...left.getAncestors()];
    // Check if right is an ancestor of left.
    if (ancestorsLeft.any((o) => identical(o, right))) return false;
    final List<Object> ancestorsRight = [right, ...right.getAncestors()];
    // Check if left is an ancestor of right.
    if (ancestorsRight.any((o) => identical(o, left))) return true;

    // There must be mismatches now since we included left and right in the
    // ancestor lists above: find the first mismatching pair from the root
    // downwards (std::mismatch on the reversed lists).
    int iL = ancestorsLeft.length - 1;
    int iR = ancestorsRight.length - 1;
    while (
        iL > 0 && iR > 0 && identical(ancestorsLeft[iL], ancestorsRight[iR])) {
      --iL;
      --iR;
    }
    final Object? commonParent = ancestorsLeft[iL].parent;
    if (commonParent != null) {
      return commonParent.getChildIndex(ancestorsLeft[iL]) <
          commonParent.getChildIndex(ancestorsRight[iR]);
    }
    return true;
  }
}

//----------------------------------------------------------------------------
// ObjectListInterface
//----------------------------------------------------------------------------

/// Pseudo interface for elements maintaining a flat list of children objects
/// for processing (mirrors `vrv::ObjectListInterface`).
///
/// The list is a flattened list of pointers to descendant elements. Use as a
/// mixin on element classes derived from [Object].
mixin ObjectListInterface on Object {
  // The flat list of children.
  final List<Object> _list = [];

  /// Filter the list for a specific class.
  ///
  /// For example, keep only notes in Beam.
  void filterList(List<Object> childList) {}

  /// Reset the list of children and call [filterList].
  void resetList() {
    // Nothing to do, the list is up to date.
    if (!isModified) return;

    modify(false);
    _list.clear();
    fillFlatList(_list);
    filterList(_list);
  }

  /// Return the list; it is updated first if outdated.
  List<Object> getList() {
    resetList();
    return _list;
  }

  bool hasEmptyList() {
    resetList();
    return _list.isEmpty;
  }

  int getListSize() {
    resetList();
    return _list.length;
  }

  Object? getListFront() {
    resetList();
    assert(_list.isNotEmpty);
    return _list.isEmpty ? null : _list.first;
  }

  Object? getListBack() {
    resetList();
    assert(_list.isNotEmpty);
    return _list.isEmpty ? null : _list.last;
  }

  /// Look for the object in the list and return its position (-1 if not
  /// found).
  int getListIndex(Object listElement) {
    for (int i = 0; i < _list.length; ++i) {
      if (identical(listElement, _list[i])) return i;
    }
    return -1;
  }

  /// Gets the first item of type [classId] starting at [startFrom].
  Object? getListFirst(Object startFrom,
      [ClassId classId = ClassId.unspecified]) {
    final int idx = getListIndex(startFrom);
    if (idx == -1) return null;
    for (int i = idx; i < _list.length; ++i) {
      if (classId == ClassId.unspecified || _list[i].classId == classId) {
        return _list[i];
      }
    }
    return null;
  }

  /// Gets the first item of type [classId] backwards starting at [startFrom].
  Object? getListFirstBackward(Object startFrom,
      [ClassId classId = ClassId.unspecified]) {
    final int idx = getListIndex(startFrom);
    if (idx == -1) return null;
    for (int i = idx; i >= 0; --i) {
      if (classId == ClassId.unspecified || _list[i].classId == classId) {
        return _list[i];
      }
    }
    return null;
  }

  /// Returns the previous object in the list (null if not found).
  Object? getListPrevious(Object listElement) {
    final int i = getListIndex(listElement);
    if (i == -1 || i == 0) return null;
    return _list[i - 1];
  }

  /// Returns the next object in the list (null if not found).
  Object? getListNext(Object listElement) {
    final int i = getListIndex(listElement);
    if (i == -1 || i >= _list.length - 1) return null;
    return _list[i + 1];
  }
}

/// Port of `DrawingListInterface` (drawinginterface.h:34-79): maintains the
/// flat list of objects whose drawing is postponed (e.g., spanning control
/// elements drawn after the measure content, tuplets after beams).
///
/// Applied to [System] and [Layer] (the C++ also applies it to `Chord`,
/// which arrives with the layer element rendering tasks).
mixin DrawingListInterface on Object {
  /// The list of objects for which drawing is postponed (mirrors
  /// `m_drawingList`, drawinginterface.h:77).
  final List<Object> _drawingList = [];

  /// Add an element to the drawing list, unless it is already there
  /// (mirrors `DrawingListInterface::AddToDrawingList`,
  /// drawinginterface.cpp:47).
  void addToDrawingList(Object object) {
    for (final Object element in _drawingList) {
      if (identical(element, object)) return;
    }
    _drawingList.add(object);
  }

  /// Return the drawing list (mirrors `GetDrawingList`,
  /// drawinginterface.cpp:61).
  List<Object> getDrawingList() => _drawingList;

  /// Clear the drawing list — called when the layer starts to be drawn
  /// (mirrors `ResetDrawingList`, drawinginterface.cpp:66; the C++
  /// `DrawingListInterface::Reset` called from `System::Reset` /
  /// `Layer::Reset` clears the same list).
  void resetDrawingList() => _drawingList.clear();
}

/// Port of `TextListInterface`: an ObjectListInterface whose filtered list
/// contains only the text-ish children (mirrors
/// `TextListInterface::FilterList`, object.cpp:1596).
mixin TextListInterface on ObjectListInterface {
  @override
  void filterList(List<Object> childList) {
    // Remove anything that is not an Lb or a Text (object.cpp:1602): "keep
    // only text-ish children, drop e.g. Rend, Verse, Dir...".
    childList.removeWhere((Object object) =>
        !(object.isClass(ClassId.lb) || object.isClass(ClassId.text)));
  }

  /// Concatenate the text of the (filtered) children, skipping `lb` elements
  /// (mirrors `TextListInterface::GetText`, object.cpp:1565).
  ///
  /// Deviations from the C++:
  /// - the C++ `vrv_cast` to `Text` was previously a dynamic cast
  ///   access here: importing the generated `Text` class from `object.dart`
  ///   would create a model-internal import cycle, and the filtered list
  ///   guarantees the cast target (the C++ `assert(text)` subsumed).
  String getText() {
    String concatText = '';
    for (final Object child in getList()) {
      if (child.isClass(ClassId.lb)) continue;
      concatText += (child as Text).text;
    }
    return concatText;
  }

  /// Split the text of the (filtered) children into lines at `lb` elements
  /// (mirrors `TextListInterface::GetTextLines`, object.cpp:1581).
  ///
  /// Deviations from the C++:
  /// - the C++ only breaks a line when the accumulated buffer is non-empty
  ///   (`child->Is(LB) && !concatText.empty()`); when it is empty (leading or
  ///   consecutive `<lb/>`) it falls through to `vrv_cast<Text*>(child)` on
  ///   the `Lb` itself, undefined behavior it never actually exercises in
  ///   valid content. This port skips an empty-buffer `lb` instead of
  ///   attempting that cast, which Dart's sound type system cannot survive.
  List<String> getTextLines() {
    final List<String> lines = [];
    String concatText = '';
    for (final Object child in getList()) {
      if (child.isClass(ClassId.lb)) {
        if (concatText.isNotEmpty) {
          lines.add(concatText);
          concatText = '';
        }
        continue;
      }
      concatText += (child as Text).text;
    }
    if (concatText.isNotEmpty) {
      lines.add(concatText);
    }
    return lines;
  }
}

//----------------------------------------------------------------------------
// ObjectFactory
//----------------------------------------------------------------------------

typedef ObjectCreator = Object Function();

/// Factory for creating model objects from MEI element names or class ids
/// (mirrors `vrv::ObjectFactory`).
///
/// Element classes register themselves via [register]; the registrations are
/// generated together with the element classes.
class ObjectFactory {
  ObjectFactory._();

  static final ObjectFactory instance = ObjectFactory._();

  final Map<ClassId, ObjectCreator> _ctorsRegistry = {};
  final Map<String, ClassId> _classIdsRegistry = {};

  /// Create the object from the MEI element string name by making a lookup
  /// in the register.
  Object? create(String name) {
    final ClassId classId = getClassId(name);
    if (classId == ClassId.object) return null;

    return createFromClassId(classId);
  }

  /// Create the object from the [classId] by making a lookup in the register.
  Object? createFromClassId(ClassId classId) {
    final ObjectCreator? creator = _ctorsRegistry[classId];
    if (creator != null) return creator();

    logError("Factory for '$classId' not found");
    return null;
  }

  /// Add the name / constructor map entry to the register.
  void register(String name, ClassId classId, ObjectCreator function) {
    _ctorsRegistry[classId] = function;
    _classIdsRegistry[name] = classId;
  }

  /// Get the ClassId from the MEI element string name ([ClassId.object] when
  /// not found).
  ClassId getClassId(String name) {
    final ClassId? classId = _classIdsRegistry[name];
    if (classId != null) return classId;
    logError("ClassId for '$name' not found");
    return ClassId.object;
  }

  /// Get the corresponding ClassIds from the vector of MEI element names.
  List<ClassId> getClassIds(List<String> classStrings) {
    final List<ClassId> classIds = [];
    for (final String str in classStrings) {
      final ClassId? id = _classIdsRegistry[str];
      if (id != null) {
        classIds.add(id);
      } else {
        logDebug("Class name '$str' could not be matched");
      }
    }
    return classIds;
  }
}
