
/// Options container mirroring `vrv::Options` — populated incrementally.
///
/// Main entry point of the library, mirroring `vrv::Toolkit`.
///
/// Under construction: methods are added phase by phase as modules are
/// ported. Phase 3 wires the input filters (MEI / MusicXML / ABC) with
/// format auto-detection.
library;

import 'dart:convert';
import 'dart:io' show File;
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import 'core/logging.dart';
import 'factory_registry.dart' show registerModelClasses;
import 'io/format.dart' as fmt;

export 'io/format.dart' show FileFormat;
import 'io/iobase.dart';
import 'io/ioabc.dart';
import 'io/iomusxml.dart';
import 'io/mei_input.dart';
import 'model/doc.dart';

/// Decode an UTF-16 byte sequence honouring the BOM (mirrors the
/// UTF-16 handling in `Toolkit::LoadFile` / `LoadUTF16File`).
String decodeUtf16(Uint8List bytes) {
  final bool bigEndian = (bytes[0] == 0xfe && bytes[1] == 0xff);
  final int start = bigEndian || (bytes[0] == 0xff && bytes[1] == 0xfe) ? 2 : 0;
  // Drop a possible second BOM (the C++ erases one leading unit as well).
  final StringBuffer out = StringBuffer();
  for (int i = start; i + 1 < bytes.length; i += 2) {
    final int unit = bigEndian
        ? (bytes[i] << 8) | bytes[i + 1]
        : bytes[i] | (bytes[i + 1] << 8);
    if (unit == 0xFEFF) continue;
    out.writeCharCode(unit);
  }
  return out.toString();
}

/// The ZIP signature (`PK\x03\x04`).
const List<int> zipSignature = [0x50, 0x4B, 0x03, 0x04];

/// Options container mirroring `vrv::Options` — populated incrementally.
class ToolkitOptions {
  final Map<String, String> raw = {};
}

class Toolkit {
  /// The main document (mirrors `m_doc`).
  final Doc doc = Doc();

  final ToolkitOptions options = ToolkitOptions();

  bool _loaded = false;
  String _mei = '';

  Toolkit() {
    registerModelClasses();
  }

  bool get ready => _loaded;

  /// Returns the currently loaded MEI document as a string.
  String getMEI() {
    if (!_loaded) throw StateError('No data loaded');
    return _mei;
  }

  // -------------------------------------------------------------------------
  // Input
  // -------------------------------------------------------------------------

  /// Set the input format explicitly (mirrors `SetInputFrom`); accepts the
  /// `fmt.FileFormat` name (e.g. "abc", "musicxml", "mei") or "auto".
  bool setInputFrom(String inputFrom) {
    if (inputFrom == 'auto') {
      doc.getOptions().inputFromFormat = fmt.FileFormat.auto.value;
      return true;
    }
    for (final fmt.FileFormat format in fmt.FileFormat.values) {
      if (format.name == inputFrom) {
        doc.getOptions().inputFromFormat = format.value;
        return true;
      }
    }
    logError("Invalid input format '$inputFrom'");
    return false;
  }

  /// Identify the input format from the data (mirrors
  /// `Toolkit::IdentifyInputFrom`).
  fmt.FileFormat identifyInputFrom(String data) =>
      fmt.identifyInputFrom(data);

  /// Load music from [data], auto-detecting the format (mirrors
  /// `Toolkit::LoadData`). Set [format] to skip detection.
  bool loadData(String data, {bool autoDetect = true}) {
    _reset();
    fmt.FileFormat inputFrom = fmt.FileFormat.unknown;
    final int configured = doc.getOptions().inputFromFormat;
    if (!autoDetect || configured != 0 && configured != fmt.FileFormat.auto.value) {
      inputFrom = _formatFromValue(configured);
    } else {
      inputFrom = fmt.identifyInputFrom(data);
    }

    Input? input = _inputFor(inputFrom);
    if (input == null) {
      logError('Unknown or unsupported input format');
      return false;
    }

    final bool ok = input.import(data);
    if (!ok) {
      logError('Import failed');
      return false;
    }
    _loaded = true;
    _mei = data;
    return true;
  }

  /// Load music from a file; handles zip archives and UTF-16 input
  /// (mirrors `Toolkit::LoadFile`).
  bool loadFile(String filename) {
    final File file = File(filename);
    if (!file.existsSync()) {
      logError("File '$filename' could not be opened");
      return false;
    }
    if (isZipFile(filename)) {
      return loadZipFile(filename);
    }
    final Uint8List bytes = file.readAsBytesSync();
    // UTF-16 BOMs - decode manually (mirrors LoadUTF16File).
    if (bytes.length >= 2 &&
        ((bytes[0] == 0xff && bytes[1] == 0xfe) ||
            (bytes[0] == 0xfe && bytes[1] == 0xff))) {
      return loadData(decodeUtf16(bytes));
    }
    return loadData(utf8.decode(bytes));
  }

  /// Load a compressed MEI / MXL style archive from [bytes] (mirrors
  /// `Toolkit::LoadZipData`).
  bool loadZipData(Uint8List bytes) {
    _reset();
    try {
      final Archive archive = ZipDecoder().decodeBytes(bytes);
      const String metaInf = 'META-INF/container.xml';
      ArchiveFile? container;
      for (final ArchiveFile file in archive.files) {
        if (file.name == metaInf) {
          container = file;
          break;
        }
      }
      if (container == null) {
        logError("No '$metaInf' file to load found in the archive");
        return false;
      }
      final String containerXml = utf8.decode(container.content as List<int>);
      final XmlDocument doc = XmlDocument.parse(containerXml);
      final String? fullPath = doc.rootElement
          .findElements('rootfiles')
          .expand((e) => e.findElements('rootfile'))
          .map((e) => e.getAttribute('full-path'))
          .firstWhere((v) => v != null, orElse: () => null);
      if (fullPath == null || fullPath.isEmpty) {
        logError('No file to load found in the archive');
        return false;
      }
      ArchiveFile? entry;
      for (final ArchiveFile file in archive.files) {
        if (file.name == fullPath) {
          entry = file;
          break;
        }
      }
      if (entry == null) {
        logError("File '$fullPath' not found in the archive");
        return false;
      }
      logInfo("Loading file '$fullPath' in the archive");
      return loadData(utf8.decode(entry.content as List<int>));
    } on ArchiveException catch (_) {
      logError('The archive could not be decoded');
      return false;
    }
  }

  /// Load a compressed MEI / MXL style archive (mirrors
  /// `Toolkit::LoadZipFile`).
  bool loadZipFile(String filename) {
    final File file = File(filename);
    if (!file.existsSync()) {
      logError("File '$filename' could not be opened");
      return false;
    }
    return loadZipData(file.readAsBytesSync());
  }

  /// Check whether the file starts with the ZIP signature (mirrors
  /// `Toolkit::IsZip`).
  bool isZipFile(String filename) {
    final File file = File(filename);
    if (!file.existsSync()) return false;
    final Uint8List bytes = file.readAsBytesSync();
    if (bytes.length < 4) return false;
    for (int i = 0; i < 4; ++i) {
      if (bytes[i] != zipSignature[i]) return false;
    }
    return true;
  }

  void _reset() {
    doc.reset();
    _loaded = false;
    _mei = '';
  }

  fmt.FileFormat _formatFromValue(int value) {
    for (final fmt.FileFormat format in fmt.FileFormat.values) {
      if (format.value == value) return format;
    }
    return fmt.FileFormat.unknown;
  }

  /// Create the input filter for a format, mirroring the switch in
  /// `Toolkit::LoadData`. Humdrum-only formats and PAE are excluded from
  /// this build.
  Input? _inputFor(fmt.FileFormat format) {
    switch (format) {
      case fmt.FileFormat.abc:
        return AbcInput(doc);
      case fmt.FileFormat.mei:
        return MeiInput(doc);
      case fmt.FileFormat.musicxml:
        return MusicXmlInput(doc);
      case fmt.FileFormat.serialization:
      case fmt.FileFormat.unknown:
      case fmt.FileFormat.auto:
        // Unknown XML data that cannot be identified is treated as MEI,
        // mirroring the C++ fallback in identifyInputFrom.
        return MeiInput(doc);
      default:
        // Formats not supported by this build (Humdrum family, PAE, GABC,
        // DARMS, CMME, Volpiano, Esac…).
        return null;
    }
  }

  /// Loads music from [data] interpreted as MEI (legacy helper kept for the
  /// earlier phases).
  bool loadDataString(String data) => loadData(data);

  // TODO(phase-5): renderToSVG / renderToPageSVG once View* is ported.
  // TODO(phase-6): getMIDI / timemap exports.
}
