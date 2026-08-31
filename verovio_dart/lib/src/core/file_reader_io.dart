/// File-system based reader used on VM / Flutter mobile & desktop.
library;

import 'dart:io';

String? readResourceFileSync(String path) {
  final file = File(path);
  if (!file.existsSync()) return null;
  return file.readAsStringSync();
}

List<int>? readResourceBytesSync(String path) {
  final file = File(path);
  if (!file.existsSync()) return null;
  return file.readAsBytesSync();
}

List<String>? listResourceDirSync(String path) {
  final dir = Directory(path);
  if (!dir.existsSync()) return null;
  return dir.listSync().map((e) => e.path).toList();
}
