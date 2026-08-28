/// File-system based reader used on VM / Flutter mobile & desktop.
library;

import 'dart:io';

String? readResourceFileSync(String path) {
  try {
    return File(path).readAsStringSync();
  } catch (_) {
    return null;
  }
}

List<int>? readResourceBytesSync(String path) {
  try {
    return File(path).readAsBytesSync();
  } catch (_) {
    return null;
  }
}

List<String>? listResourceDirSync(String path) {
  try {
    return Directory(path).listSync().map((e) => e.path).toList();
  } catch (_) {
    return null;
  }
}
