/// Platform abstraction for reading bundled resource files synchronously.
///
/// The default implementation reads from the filesystem (`dart:io`). On the
/// web (or in Flutter with assets loaded through the asset bundle) install an
/// alternative reader with the [fileReader] setter.
library;

import 'file_reader_stub.dart' if (dart.library.io) 'file_reader_io.dart'
    as impl;

/// Signature of a synchronous file reader: returns the content of [path] or
/// `null` if it cannot be read.
typedef ResourceFileReader = String? Function(String path);

ResourceFileReader? _override;

/// The current global resource file reader.
ResourceFileReader get resourceFileReader =>
    _override ?? impl.readResourceFileSync;

set resourceFileReader(ResourceFileReader? reader) => _override = reader;
