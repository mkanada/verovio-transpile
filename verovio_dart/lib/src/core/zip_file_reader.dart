/// Port of `filereader.h/cpp` — a reader for zip archives, used for custom
/// SMuFL fonts loaded from compressed archives.
library;

import 'package:archive/archive.dart';

import 'package:verovio_dart/src/core/file_reader.dart';
import 'package:verovio_dart/src/core/logging.dart';

/// This class is a reader for zip archives (mirrors `vrv::ZipFileReader`).
///
/// Deviations from the C++:
/// - `Load(filename)` reads the archive through the pluggable
///   [resourceBytesReader] instead of an `std::ifstream`, so the package
///   stays web-safe (the stub reader returns `null` for every file). On the
///   C++/EMSCRIPTEN build `Load` also accepts base64 data URIs; here that
///   handling is up to the installed bytes reader.
/// - `LoadBytes` returns `false` when the bytes cannot be decoded; the C++
///   `miniz_cpp::zip_file` constructor parses lazily and always returns
///   `true`, failing later in the accessors instead.
class ZipFileReader {
  /// The decoded archive (the C++ keeps a `miniz_cpp::zip_file *m_file`).
  Archive? _archive;

  /// Reset a previously loaded file (mirrors `ZipFileReader::Reset`).
  void reset() {
    _archive = null;
  }

  /// Load a file into memory (mirrors `ZipFileReader::Load`).
  bool load(String filename) {
    final List<int>? bytes = resourceBytesReader(filename);
    if (bytes == null) {
      logError("File archive '$filename' could not be opened.");
      return false;
    }
    return loadBytes(bytes);
  }

  /// Load bytes into memory (mirrors `ZipFileReader::LoadBytes`).
  bool loadBytes(List<int> bytes) {
    reset();
    if (bytes.isEmpty) {
      logError('The archive could not be decoded');
      return false;
    }
    _archive = ZipDecoder().decodeBytes(bytes);
    return true;
  }

  /// Return a list of all files (including directories) — mirrors
  /// `ZipFileReader::GetFileList`.
  List<String> getFileList() {
    assert(_archive != null);
    final Archive? archive = _archive;
    if (archive == null) return [];
    return [for (final ArchiveFile member in archive.files) member.name];
  }

  /// Check if the archive contains the file (mirrors
  /// `ZipFileReader::HasFile`).
  bool hasFile(String filename) {
    assert(_archive != null);
    final Archive? archive = _archive;
    if (archive == null) return false;
    // Look for the file in the zip.
    return archive.files.any((info) => info.name == filename);
  }

  /// Read the text file. Return an empty string if the file does not exist
  /// (mirrors `ZipFileReader::ReadTextFile`).
  String readTextFile(String filename) {
    assert(_archive != null);
    final Archive? archive = _archive;
    if (archive == null) return '';
    // Look for the meta file in the zip.
    for (final ArchiveFile member in archive.files) {
      if (member.name == filename) {
        return String.fromCharCodes(member.content);
      }
    }
    logError("No file '$filename' to read found in the archive");
    return '';
  }
}
