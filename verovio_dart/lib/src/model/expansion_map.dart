/// Port of `expansionmap.h/cpp` — the map of expanded (repeated) xml:ids and
/// the expansion engine used by `<expansion>` elements.
library;

import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/model/atts/mei_enums.dart' show Barrendition;
import 'package:verovio_dart/src/model/basic_elements.dart';
import 'package:verovio_dart/src/model/editorial_element.dart';
import 'package:verovio_dart/src/model/interfaces/linking_interface.dart';
import 'package:verovio_dart/src/model/interfaces/plist_interface.dart';
import 'package:verovio_dart/src/model/interfaces/time_interface.dart';
import 'package:verovio_dart/src/model/misc_elements_gen.dart';
import 'package:verovio_dart/src/model/object.dart';

/// The expansion map indicates which xml:id has been repeated (expanded)
/// elsewhere (mirrors `vrv::ExpansionMap`).
class ExpansionMap {
  ExpansionMap() {
    reset();
  }

  /// The id → expanded ids mapping (public in C++ as `m_map`).
  final Map<String, List<String>> map = {};

  /// A flag indicating that the generation process has been run even if the
  /// expansion map is empty.
  bool _isProcessed = false;

  /// Clear the content of the expansion map.
  void reset() {
    map.clear();
    _isProcessed = false;
  }

  /// Check if the map has been filled (mirrors `HasExpansionMap`).
  bool hasExpansionMap() => map.isNotEmpty;

  /// Setter and getter for the generating attempt flag.
  void setProcessed(bool isProcessed) => _isProcessed = isProcessed;
  bool isProcessed() => _isProcessed;

  /// Expand [expansion] recursively, cloning and inserting the referenced
  /// sections after [prevSection] (mirrors `Expand`).
  Object? expand(Expansion expansion, List<String> existingList,
      Object? prevSect, List<String> deletionList,
      [bool deleteList = false]) {
    final Object? parent = expansion.parent;
    assert(parent != null);

    final List<String> expansionPlist = expansion.plist ?? const [];
    if (expansionPlist.isEmpty) {
      logWarning(
          'ExpansionMap::Expand: Expansion element ${expansion.id} has empty @plist. Nothing expanded.');
      return prevSect;
    }

    assert(prevSect != null);
    assert(prevSect!.parent != null);

    // Cloned parent container.
    Object? insertHere;

    // If the expansion parent already exists, create a new empty such
    // element.
    if (existingList.contains(parent!.id)) {
      final ClassId parentClassId = parent.classId;
      Object? newContainer;
      // Check the type of the expansion parent.
      if (parentClassId == ClassId.section) {
        newContainer = Section();
      } else if (parentClassId == ClassId.ending) {
        newContainer = Ending();
      } else if (parentClassId == ClassId.lem) {
        newContainer = Lem();
      } else if (parentClassId == ClassId.rdg) {
        newContainer = Rdg();
      } else {
        logWarning(
            'ExpansionMap::Expand: Expansion element ${expansion.id} has unsupported parent type.');
        return prevSect;
      }

      assert(parent.parent != null);
      final Object? referenceChild =
          parent.getDirectChildOf(parent.parent!, prevSect!);
      assert(referenceChild != null);
      parent.parent!.insertAfter(referenceChild!, newContainer);
      generatePredictableIDs(parent, newContainer);
      logDebug(
          'Creating new container <${newContainer.className}> for expansion element ${newContainer.id}');

      insertHere = newContainer;
    } else {
      existingList.add(parent.id);
    }

    // Find and add all relevant (and new) expansion sibling ids to the
    // deletion list.
    for (final Object sibling in parent.children) {
      if ((sibling.classId == ClassId.section ||
              sibling.classId == ClassId.ending ||
              sibling.classId == ClassId.lem ||
              sibling.classId == ClassId.rdg) &&
          !deletionList.contains(sibling.id)) {
        deletionList.add(sibling.id);
      }
    }

    // Iterate over the expansion plist.
    for (String id in expansionPlist) {
      logDebug('Looking for element in @plist: $id');
      if (id.startsWith('#')) id = id.substring(1); // Remove leading hash.
      final Object? currSect = parent.findDescendantByID(id);
      if (currSect == null) {
        // Warn about referenced element not found and continue.
        logWarning(
            'ExpansionMap::Expand: Element referenced in @plist not found: $id');
        continue;
      }
      if (currSect is Expansion) {
        // If the id is itself an expansion, resolve it recursively.
        prevSect = expand(currSect, existingList, prevSect, deletionList);
      } else {
        // The id is already in existingList or currSect is not in the
        // expansion parent: clone object, update ids, insert it.
        if (existingList.contains(id) ||
            (insertHere != null && !identical(currSect.parent, insertHere))) {
          // Clone the current section/ending/rdg/lem and rename it, adding
          // "-rend2" for the first repetition etc.
          final Object clonedObject = currSect.clone();
          clonedObject.cloneReset();
          generatePredictableIDs(currSect, clonedObject);

          // Get ids of old and new sections and add them to the map.
          final List<String> oldIds = [currSect.id];
          getIDList(currSect, oldIds);
          final List<String> clonedIds = [clonedObject.id];
          getIDList(clonedObject, clonedIds);
          for (int i = 0; (i < oldIds.length) && (i < clonedIds.length); ++i) {
            addExpandedIDToExpansionMap(oldIds[i], clonedIds[i]);
          }

          // Go through the cloned object and update the interfaces holding
          // references.
          updateIDs(clonedObject);

          logDebug('Cloning element in @plist: ${clonedObject.id}');

          if (insertHere != null) {
            // Add to the new container, if it exists.
            insertHere.addChild(clonedObject);
          } else {
            // Or add after the previous section.
            prevSect!.parent!.insertAfter(prevSect, clonedObject);
          }

          prevSect = clonedObject;
          existingList.add(clonedObject.id);
        } else {
          // Add to existingList, remember previous element, re-order if
          // necessary.
          bool moveCurrentElement = false;
          final int prevIdx = prevSect!.idx ?? -1;
          final int childCount = prevSect.parent!.childCount;
          final int currIdx = currSect.idx ?? -1;

          // Check re-order when within same parent.
          if (currSect.parent!.id == prevSect.parent!.id) {
            // If prevSect has a next element and it is different than
            // currSect (or there is none), move it after currSect.
            if (prevIdx < childCount - 1) {
              final Object? nextElement =
                  prevSect.parent!.getChild(prevIdx + 1);
              assert(nextElement != null);
              if (_isExpansible(nextElement) &&
                  !identical(nextElement, currSect)) {
                moveCurrentElement = true;
              }
            } else {
              moveCurrentElement = true;
            }
          }

          // Move prevSect to after currSect.
          if (moveCurrentElement && currIdx < prevIdx && prevIdx < childCount) {
            logDebug(
                'Re-ordering element ${currSect.id} to after ${prevSect.id}');
            currSect.parent!.rotateChildren(currIdx, currIdx + 1, prevIdx + 1);
          } else {
            logDebug('Leaving existing element ${currSect.id}');
          }

          prevSect = currSect;
          existingList.add(id);
        }
      }
    }

    // At the very end, remove unused sections from structure if not in
    // existingList.
    if (deleteList) {
      for (final String del in deletionList) {
        if (!existingList.contains(del)) {
          final Object? currSect = parent.findDescendantByID(del);
          assert(currSect != null);

          final int idx = currSect!.idx ?? -1;
          logDebug(
              'ExpansionMap::Expand: Removing unused section/ending/rdg/lem with id $del');
          currSect.parent!.detachChild(idx);
        }
      }
    }

    return prevSect;
  }

  static bool _isExpansible(Object? object) =>
      object != null &&
      (object.classId == ClassId.section ||
          object.classId == ClassId.ending ||
          object.classId == ClassId.lem ||
          object.classId == ClassId.rdg);

  /// Update the ids of interfaces (TimePoint/TimeSpanning, @plist and
  /// linking attributes) referencing other elements within the
  /// cloned tree (mirrors `UpdateIDs`); see also `newIdFrom`.
  bool updateIDs(Object object) {
    for (final Object o in object.children) {
      o.isExpansion = true;
      if (o.hasInterface(InterfaceId.timePoint)) {
        final TimePointInterface interface = o as TimePointInterface;
        // @startid
        String oldStartId = interface.startid ?? '';
        if (oldStartId.startsWith('#')) {
          oldStartId = oldStartId.substring(1);
        }
        final String newStartId = getExpansionIDsForElement(oldStartId).last;
        if (newStartId.isNotEmpty) interface.startid = '#$newStartId';
      }
      if (o.hasInterface(InterfaceId.timeSpanning)) {
        final TimeSpanningInterface interface = o as TimeSpanningInterface;
        // @startid
        String oldStartId = interface.startid ?? '';
        if (oldStartId.startsWith('#')) {
          oldStartId = oldStartId.substring(1);
        }
        String newId = getExpansionIDsForElement(oldStartId).last;
        if (newId.isNotEmpty) interface.startid = '#$newId';
        // @endid
        oldStartId = interface.endid ?? '';
        if (oldStartId.startsWith('#')) {
          oldStartId = oldStartId.substring(1);
        }
        newId = getExpansionIDsForElement(oldStartId).last;
        if (newId.isNotEmpty) interface.endid = '#$newId';
      }
      if (o.hasInterface(InterfaceId.plist)) {
        final PlistInterface interface = o as PlistInterface; // @plist
        final List<String> oldList = interface.plist ?? const [];
        final List<String> newList = [
          for (final String oldRefString in oldList)
            '#${getExpansionIDsForElement(oldRefString.startsWith('#') ? oldRefString.substring(1) : oldRefString).last}',
        ];
        interface.plist = newList;
      } else if (o.hasInterface(InterfaceId.linking)) {
        final LinkingInterface interface = o as LinkingInterface;
        // @sameas
        String oldIdString = interface.sameas ?? '';
        newIdFrom(oldIdString, (v) => interface.sameas = v);
        // @next
        oldIdString = interface.next ?? '';
        newIdFrom(oldIdString, (v) => interface.next = v);
        // @prev — stored through AttLinking.prev? (@prev does not exist in
        // att.linking; kept for parity with the C++ which reads GetPrev).
        // @copyof
        oldIdString = interface.copyof ?? '';
        newIdFrom(oldIdString, (v) => interface.copyof = v);
        // @synch / @corresp are handled by Object::clone /
        // LinkingInterface::addBackLink respectively.
      }
      updateIDs(o);
    }
    return true;
  }

  /// Helper resolving [oldIdString] through the map and applying
  /// [setter] with the `"#newId"` value when non-empty.
  void newIdFrom(String oldIdString, void Function(String) setter) {
    if (!oldIdString.startsWith('#')) return;
    final String stripped = oldIdString.substring(1);
    final String newIdString = getExpansionIDsForElement(stripped).last;
    if (newIdString.isNotEmpty) setter('#$newIdString');
  }

  /// Add an id string to an original/notated id (mirrors
  /// `AddExpandedIDToExpansionMap`).
  bool addExpandedIDToExpansionMap(String origXmlId, String newXmlId) {
    final List<String>? list = map[origXmlId];
    if (list != null) {
      list.add(newXmlId); // Add to existing key.
      for (final String s in List<String>.from(list)) {
        if (s != list.first && s != list.last) {
          map[s]?.add(newXmlId); // Add to middle keys.
        }
      }
      map[newXmlId] = [...list]; // Add new as key.
    } else {
      map[origXmlId] = [origXmlId, newXmlId];
      map[newXmlId] = [origXmlId, newXmlId];
    }
    return true;
  }

  /// Return the list of expanded ids for an element (mirrors
  /// `GetExpansionIDsForElement`).
  List<String> getExpansionIDsForElement(String xmlId) {
    return map[xmlId] ?? <String>[xmlId];
  }

  /// Collect all the descendant ids of [object] into [idList] (mirrors
  /// `GetIDList`).
  void getIDList(Object object, List<String> idList) {
    for (final Object o in object.children) {
      idList.add(o.id);
      getIDList(o, idList);
    }
  }

  /// Generate predictable "-rendN" ids for the cloned tree (mirrors
  /// `GeneratePredictableIDs`).
  void generatePredictableIDs(Object source, Object target) {
    target.resetID();
    target.id =
        '${source.id}-rend${getExpansionIDsForElement(source.id).length + 1}';

    final List<Object> sourceObjects = source.children;
    final List<Object> targetObjects = target.children;
    if (sourceObjects.isEmpty || sourceObjects.length != targetObjects.length) {
      return;
    }

    int i = 0;
    for (final Object s in sourceObjects) {
      generatePredictableIDs(s, targetObjects[i++]);
    }
  }

  /// Serialize the map as a JSON object string (mirrors `ToJson`).
  String toJson() {
    final buffer = StringBuffer('{');
    var first = true;
    for (final entry in map.entries) {
      if (!first) buffer.write(', ');
      first = false;
      final ids =
          entry.value.map((s) => '"${s.replaceAll('"', r'\"')}"').join(', ');
      buffer.write('"${entry.key.replaceAll('"', r'\"')}": [$ids]');
    }
    buffer.write('}');
    return buffer.toString();
  }

  /// Generate an expansion for the score by analysing repeats and endings
  /// (mirrors `GenerateExpansionFor`).
  void generateExpansionFor(Score score) {
    _isProcessed = true;

    if (score.hasEditorialContent) {
      logWarning('An expansion cannot be generated with editorial content');
      return;
    }

    if (score.findAllDescendantsByType(ClassId.section).length > 1) {
      logWarning('An expansion cannot be generated with more than one section');
      return;
    }

    final Section? section =
        score.findDescendantByType(ClassId.section, deepness: 1) as Section?;
    assert(section != null);

    final List<Object> children = section!.children;

    final expansion = Expansion();

    int firstIdx = 0;
    int lastIdx = -1;

    bool isStartFromPrevious = false;

    for (var i = 0; i < children.length; ++i) {
      final current = children[i];
      if (current is Measure) {
        // The current measure has a repeat end on its left.
        if (isPreviousRepeatEnd(current)) {
          final ref = '#${createSection(section, firstIdx, lastIdx)}';
          expansion.addRefAllowDuplicate(ref);
          expansion.addRefAllowDuplicate(ref);
        }
        if (isStartFromPrevious || isRepeatStart(current)) {
          firstIdx = i;
        }
        // The current measure has a repeat start on its right.
        isStartFromPrevious = isNextRepeatStart(current);
        lastIdx = i;
        if (isRepeatEnd(current)) {
          final ref = '#${createSection(section, firstIdx, lastIdx)}';
          expansion.addRefAllowDuplicate(ref);
          expansion.addRefAllowDuplicate(ref);
        }
      }
    }

    if ((expansion.plist ?? const []).isEmpty) {
      // Nothing to do (the C++ deletes the expansion).
    } else {
      section.insertChild(expansion, 0);
    }
  }

  /// Move the children of [section] between [firstIdx] and [lastIdx]
  /// (inclusive) into a new sub-section inserted before the first one
  /// (mirrors `CreateSection`). Returns the new sub-section id.
  ///
  /// The indices refer to positions captured before any detachment; they are
  /// resolved lazily like the C++ iterators would be.
  String createSection(Section section, int firstIdx, int lastIdx) {
    final subSection = Section();
    final List<Object> childrenAtCall = section.children;
    if (firstIdx >= childrenAtCall.length) return subSection.id;
    final first = childrenAtCall[firstIdx];

    section.insertBefore(first, subSection);

    // Detach the measures from the original section and add them to the
    // sub-section. Indices shift by one because of the insertion above.
    for (int i = firstIdx + 1; i <= lastIdx + 1 && i < section.childCount;) {
      final Object? child = section.detachChild(i);
      if (child == null) break;
      subSection.addChild(child);
    }
    return subSection.id;
  }

  // -------------------------------------------------------------------------
  // Static methods: repeat detection on measure bar lines
  // -------------------------------------------------------------------------

  static bool _hasLeftMatch(Measure measure, List<Barrendition> match) =>
      measure.hasLeft && match.contains(measure.left);

  static bool _hasRightMatch(Measure measure, List<Barrendition> match) =>
      measure.hasRight && match.contains(measure.right);

  /// Return true if the measure has a repeat start on its left (mirrors
  /// `IsRepeatStart`).
  static bool isRepeatStart(Measure measure) => _hasLeftMatch(measure, const [
        Barrendition.rptboth,
        Barrendition.rptstart,
      ]);

  /// Return true if the measure has a repeat end on its right (mirrors
  /// `IsRepeatEnd`).
  static bool isRepeatEnd(Measure measure) => _hasRightMatch(measure, const [
        Barrendition.rptboth,
        Barrendition.rptend,
      ]);

  /// Return true if the next measure starts with a repeat (mirrors
  /// `IsNextRepeatStart`).
  static bool isNextRepeatStart(Measure measure) =>
      _hasRightMatch(measure, const [
        Barrendition.rptboth,
        Barrendition.rptstart,
      ]);

  /// Return true if the previous measure ends with a repeat (mirrors
  /// `IsPreviousRepeatEnd`).
  static bool isPreviousRepeatEnd(Measure measure) =>
      _hasLeftMatch(measure, const [
        Barrendition.rptboth,
        Barrendition.rptend,
      ]);
}
