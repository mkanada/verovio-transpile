/// Port of `linkinginterface.h/cpp` — interface for elements having links
/// (@next / @sameas).
library;

import 'package:verovio_dart/src/core/utils.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/model/atts/atts_shared.dart';
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/model/interfaces/interface.dart';

/// Mirrors `vrv::LinkingInterface`.
///
/// Apply together with [AttLinking].
mixin LinkingInterface on AttLinking implements Interface {
  /// The resolved @next element.
  Object? nextLink;

  /// The fragment of the @next attribute.
  String nextID = '';

  /// The resolved @sameas element.
  Object? sameasLink;

  /// The fragment of the @sameas attribute.
  String sameasID = '';

  @override
  InterfaceId get interfaceId => InterfaceId.linking;

  @override
  void reset() {
    next = null;
    sameas = null;
    corresp = null;
    copyof = null;

    nextLink = null;
    nextID = '';
    sameasLink = null;
    sameasID = '';
  }

  /// Set the @next object. Asserts that none was previously set.
  void setNextLink(Object next) {
    assert(nextLink == null);
    nextLink = next;
  }

  /// Set the @sameas object. Asserts that none was previously set.
  void setSameasLink(Object sameas) {
    assert(sameasLink == null);
    sameasLink = sameas;
  }

  bool get hasNextLink => nextLink != null;
  bool get hasSameasLink => sameasLink != null;

  /// Extract the fragments of @next and @sameas if given.
  void setIDStr() {
    if (hasNext && next != null) {
      nextID = extractIDFragment(next!);
    }
    if (hasSameas && sameas != null) {
      sameasID = extractIDFragment(sameas!);
    }
  }

  /// Copies the interface state from [other].
  void copyLinkingFrom(covariant LinkingInterface other) {
    next = other.next;
    sameas = other.sameas;
    corresp = other.corresp;
    copyof = other.copyof;
    nextLink = other.nextLink;
    nextID = other.nextID;
    sameasLink = other.sameasLink;
    sameasID = other.sameasID;
  }

  /// Set the @corresp attribute to the ID (or its own @corresp) of [object].
  void addBackLink(Object object) {
    String newCorresp = '#${object.id}';
    final AttLinking? otherAtt =
        object is AttLinking ? (object as AttLinking) : null;
    if (otherAtt != null && otherAtt.corresp != null) {
      newCorresp = otherAtt.corresp!;
    }
    corresp = newCorresp;
  }
}
