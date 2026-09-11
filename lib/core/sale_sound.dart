import 'dart:io' show Platform;
import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

/// Plays a short confirmation beep when a sale completes.
class SaleSound {
  SaleSound._() {
    // Swallow any async errors raised by the audio backend on its internal
    // streams (e.g. missing GStreamer plugins on Linux). Without a listener
    // these surface as unhandled exceptions and can kill the app.
    _player.onLog.listen((_) {}, onError: (Object _, StackTrace? __) {});
    _player.eventStream.listen((_) {}, onError: (Object _, StackTrace? __) {});
  }

  static final SaleSound instance = SaleSound._();
  final _player = AudioPlayer();

  /// Generates a short pleasant confirmation tone (WAV in memory).
  ///
  /// Never throws and never blocks the sale flow: on platforms without a
  /// working audio backend (e.g. Linux desktop missing GStreamer plugins)
  /// the sound is silently skipped.
  Future<void> play() async {
    try {
      // Linux often lacks GStreamer plugins; avoid the round-trip entirely.
      if (Platform.isLinux) return;
      final bytes = _generateBeep(
        frequency: 880, // A5 — bright, cheerful
        durationMs: 120,
        sampleRate: 22050,
        volume: 0.5,
      );
      await _player.stop();
      await _player.play(BytesSource(bytes));
    } catch (_) {
      // Audio unavailable (GStreamer plugin missing, headless host, …): ignore.
    }
  }

  /// Generates a WAV byte array for a sine-wave beep.
  static Uint8List _generateBeep({
    required double frequency,
    required int durationMs,
    required int sampleRate,
    required double volume,
  }) {
    final numSamples = (sampleRate * durationMs / 1000).round();
    final data = Int16List(numSamples);

    for (var i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      // Apply a quick fade-in / fade-out envelope to avoid clicks.
      final envelope = min(1.0, min(i / 400.0, (numSamples - i) / 400.0));
      data[i] =
          (sin(2 * pi * frequency * t) * 32767 * volume * envelope).round();
    }

    // Build a minimal WAV file in memory.
    final dataSize = numSamples * 2; // 16-bit mono = 2 bytes per sample
    final buf = ByteData(44 + dataSize);
    var off = 0;

    // RIFF header
    _writeAscii(buf, off, 'RIFF'); off += 4;
    buf.setUint32(off, 36 + dataSize, Endian.little); off += 4;
    _writeAscii(buf, off, 'WAVE'); off += 4;

    // fmt chunk
    _writeAscii(buf, off, 'fmt '); off += 4;
    buf.setUint32(off, 16, Endian.little); off += 4;          // chunk size
    buf.setUint16(off, 1, Endian.little); off += 2;           // PCM
    buf.setUint16(off, 1, Endian.little); off += 2;           // mono
    buf.setUint32(off, sampleRate, Endian.little); off += 4;  // sample rate
    buf.setUint32(off, sampleRate * 2, Endian.little); off += 4; // byte rate
    buf.setUint16(off, 2, Endian.little); off += 2;           // block align
    buf.setUint16(off, 16, Endian.little); off += 2;          // bits per sample

    // data chunk
    _writeAscii(buf, off, 'data'); off += 4;
    buf.setUint32(off, dataSize, Endian.little); off += 4;

    for (var i = 0; i < numSamples; i++) {
      buf.setInt16(off, data[i], Endian.little);
      off += 2;
    }

    return buf.buffer.asUint8List();
  }

  static void _writeAscii(ByteData buf, int offset, String s) {
    for (var i = 0; i < s.length; i++) {
      buf.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  void dispose() => _player.dispose();
}
