/// Port of `interface.h` — base class for regrouping MEI att classes into
/// interfaces.
library;

import 'package:verovio_dart/src/core/vrvdef.dart';

/// This is a base class for regrouping MEI att classes.
///
/// In the Dart port, interfaces are [mixin]s applied to model elements; they
/// implement this class for the common [reset]/[interfaceId] contract.
abstract class Interface {
  /// Virtual reset method: resets all attribute class members.
  void reset();

  /// The InterfaceId of the interface (mirrors `IsInterface()`).
  InterfaceId get interfaceId;
}
