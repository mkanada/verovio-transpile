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
