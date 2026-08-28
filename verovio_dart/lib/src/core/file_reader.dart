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

/// Signature of a synchronous binary file reader: returns the raw bytes of
/// [path] or `null` if it cannot be read (needed for zip archives, which
/// must not go through the text decoder).
typedef ResourceBytesReader = List<int>? Function(String path);

/// Signature of a synchronous directory lister: returns the full paths of
/// the entries in [path] (files and subdirectories, like
/// `std::filesystem::directory_iterator`) or `null` if it cannot be listed.
typedef ResourceDirectoryLister = List<String>? Function(String path);

ResourceFileReader? _override;
ResourceBytesReader? _bytesOverride;
ResourceDirectoryLister? _dirListerOverride;

/// The current global resource file reader.
ResourceFileReader get resourceFileReader =>
    _override ?? impl.readResourceFileSync;

set resourceFileReader(ResourceFileReader? reader) => _override = reader;

/// The current global binary file reader.
ResourceBytesReader get resourceBytesReader =>
    _bytesOverride ?? impl.readResourceBytesSync;

set resourceBytesReader(ResourceBytesReader? reader) => _bytesOverride = reader;

/// The current global directory lister.
ResourceDirectoryLister get resourceDirectoryLister =>
    _dirListerOverride ?? impl.listResourceDirSync;

set resourceDirectoryLister(ResourceDirectoryLister? lister) =>
    _dirListerOverride = lister;
