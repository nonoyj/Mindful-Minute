import 'dart:math' as math;
import 'dart:typed_data';

/// Built-in ambient pad (looping WAV made in memory), used when the user has
/// not chosen their own music.
Uint8List calmWav() {
  const rate = 22050;
  const seconds = 12; // frequencies are m/12 Hz => seamless loop
  final n = rate * seconds;
  final d = ByteData(44 + n * 2);
  void s(int o, String v) {
    for (var i = 0; i < v.length; i++) {
      d.setUint8(o + i, v.codeUnitAt(i));
    }
  }

  s(0, 'RIFF');
  d.setUint32(4, 36 + n * 2, Endian.little);
  s(8, 'WAVE');
  s(12, 'fmt ');
  d.setUint32(16, 16, Endian.little);
  d.setUint16(20, 1, Endian.little);
  d.setUint16(22, 1, Endian.little);
  d.setUint32(24, rate, Endian.little);
  d.setUint32(28, rate * 2, Endian.little);
  d.setUint16(32, 2, Endian.little);
  d.setUint16(34, 16, Endian.little);
  s(36, 'data');
  d.setUint32(40, n * 2, Endian.little);
  const freqs = [130.75, 196.0, 261.5, 329.5];
  for (var i = 0; i < n; i++) {
    final t = i / rate;
    var v = 0.0;
    for (var k = 0; k < freqs.length; k++) {
      final lfo = 0.5 + 0.5 * math.sin(2 * math.pi * ((k + 1) / 12) * t);
      v += math.sin(2 * math.pi * freqs[k] * t) * lfo * 0.17;
    }
    d.setInt16(44 + i * 2, (v * 32767).round(), Endian.little);
  }
  return d.buffer.asUint8List();
}
