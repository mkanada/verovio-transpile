/// Dart port of Verovio 6.2 — music notation engraving library.
///
/// This library is a functional equivalent (1:1 port) of the C++ Verovio.
/// See [Toolkit] for the main entry point and [loadData]/[loadFile] for
/// reading MEI, MusicXML and ABC input.
library;

export 'src/toolkit.dart';
export 'src/io/format.dart' show FileFormat, identifyInputFrom;
export 'src/io/iobase.dart' show Input;
