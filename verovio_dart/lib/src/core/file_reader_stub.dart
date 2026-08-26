/// Stub reader for platforms without `dart:io` (web).
///
/// Returns `null` for every file; callers fall back to defaults. On the web
/// a platform-specific reader must be installed via `resourceFileReader`.
library;

String? readResourceFileSync(String path) => null;
