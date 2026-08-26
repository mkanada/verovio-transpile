/// Port of `iobase.h/cpp` — base classes for input and output filters.
///
/// `Input` is the base class of MEIInput, MusicXmlInput and ABCInput;
/// `Output` is the base class of the export filters (ported with the
/// respective phases).
library;

import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/model/object.dart';

// ---------------------------------------------------------------------------
// Output
// ---------------------------------------------------------------------------

/// This class is a base class for output classes (mirrors `vrv::Output`).
///
/// It is not an abstract class but should not be instantiated directly.
abstract class Output {
  Output(this.doc);

  /// The document being exported.
  final Doc doc;

  /// Main method for exporting the data. Overridden in child classes.
  String export();

  /// Dummy object method that must be overridden in child class.
  bool writeObject(Object object) => true;

  /// Dummy object method that must be overridden in child class.
  bool writeObjectEnd(Object object) => true;

  /// Method for skipping under certain circumstances.
  bool skip(Object object) => false;
}

// ---------------------------------------------------------------------------
// Input
// ---------------------------------------------------------------------------

/// This class is a base class for input classes (mirrors `vrv::Input`).
///
/// It is not an abstract class but should not be instantiated directly.
abstract class Input {
  Input(this.doc) {
    layoutInformation = LayoutInformation.none;
  }

  /// The document being filled by the import.
  final Doc doc;

  /// Indicates if we have layout information in the file loaded.
  ///
  /// The value will be [LayoutInformation.encoded] if we have `<pb>` or
  /// `<sb>` elements and [LayoutInformation.done] for page-based MEI. This
  /// value remains [LayoutInformation.none] with PAE import.
  LayoutInformation layoutInformation = LayoutInformation.none;

  String _outformat = 'mei';

  void setOutputFormat(String format) => _outformat = format;
  String getOutputFormat() => _outformat;

  /// Read the data; overridden in child classes.
  bool import(String data) => true;
}
