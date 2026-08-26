/// Port of `plistinterface.h/cpp` — interface for elements having a
/// @plist reference list.
library;

import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/utils.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/model/atts/atts_shared.dart';
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/model/interfaces/interface.dart';

/// Mirrors `vrv::PlistInterface`.
///
/// Apply together with [AttPlist].
mixin PlistInterface on AttPlist implements Interface {
  /// An array of resolved references (filled by the prepare plist functor).
  final List<Object> references = [];

  /// An array of parsed any URIs stored as ids.
  final List<String> ids = [];

  @override
  InterfaceId get interfaceId => InterfaceId.plist;

  @override
  void reset() {
    plist = null;
    references.clear();
    ids.clear();
  }

  /// Add a reference to the @plist vector (if not already there).
  void addRef(String ref) {
    if (plist == null || !plist!.contains(ref)) {
      plist = [...(plist ?? <String>[]), ref];
    }
  }

  /// Add a reference without duplicate checking (for expansion@plist).
  void addRefAllowDuplicate(String ref) {
    plist = [...(plist ?? <String>[]), ref];
  }

  /// Set a reference object; called when the id is found. Redefine
  /// [isValidRef] in child classes for specific validation.
  void setRef(Object ref) {
    if (!isValidRef(ref)) return;
    if (!references.any((o) => identical(o, ref))) {
      references.add(ref);
    }
  }

  /// Retrieve all reference objects.
  List<Object> getRefs() => List.unmodifiable(references);

  /// Copies the interface state from [other].
  void copyPlistFrom(covariant PlistInterface other) {
    plist = other.plist == null ? null : [...other.plist!];
    references.addAll(other.references);
    ids.addAll(other.ids);
  }

  /// Extract the fragment of the any URIs given in @plist.
  void setIDStrs() {
    assert(ids.isEmpty && references.isEmpty);

    for (final String uri in plist ?? const <String>[]) {
      final String id = extractIDFragment(uri);
      if (id.isNotEmpty) {
        ids.add(id);
      } else {
        logError("Cannot parse the anyURI '$uri'");
      }
    }
  }

  /// Method to be redefined in child classes if specific validation is
  /// required; called from [setRef].
  bool isValidRef(Object ref) => true;
}
