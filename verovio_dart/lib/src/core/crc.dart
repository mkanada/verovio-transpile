/// Port of `src/crc/crc.cpp` (CRC-16/CCITT-FALSE, as configured in crc.h).
///
/// Used by the Toolkit to derive short element ids.
library;

const int _width = 16;
const int _topBit = 1 << (_width - 1);
const int _polynomial = 0x1021;
const int _initialRemainder = 0xFFFF;
const int _finalXorValue = 0x0000;

final List<int> _crcTable = List<int>.filled(256, 0);
bool _initialized = false;

void _init() {
  if (_initialized) return;
  for (int dividend = 0; dividend < 256; ++dividend) {
    int remainder = dividend << (_width - 8);
    for (int bit = 8; bit > 0; --bit) {
      remainder = (remainder & _topBit) != 0
          ? ((remainder << 1) ^ _polynomial) & 0xFFFF
          : (remainder << 1) & 0xFFFF;
    }
    _crcTable[dividend] = remainder;
  }
  _initialized = true;
}

/// Computes the CRC of [message] (mirrors `crcFast`).
int crcFast(List<int> message, [int? nBytes]) {
  _init();
  final int count = nBytes ?? message.length;
  int remainder = _initialRemainder;
  for (int i = 0; i < count; ++i) {
    final int data = (message[i] ^ (remainder >> (_width - 8))) & 0xFF;
    remainder = (_crcTable[data] ^ (remainder << 8)) & 0xFFFF;
  }
  return remainder ^ _finalXorValue;
}
