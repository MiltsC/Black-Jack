import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._();
  factory AudioService() => _instance;
  AudioService._();

  final AudioPlayer _player = AudioPlayer();
  bool _muted = false;

  static const int _sampleRate = 44100;

  bool get muted => _muted;
  void toggleMute() => _muted = !_muted;

  Future<void> playDeal() async {
    if (_muted) return;
    final samples = _cardSlide();
    await _play(samples);
  }

  Future<void> playChipClick() async {
    if (_muted) return;
    final samples = _chipDrop();
    await _play(samples);
  }

  Future<void> playFlip() async {
    if (_muted) return;
    final samples = _cardFlip();
    await _play(samples);
  }

  Future<void> playBlackjack() async {
    if (_muted) return;
    final samples = _winChime(big: true);
    await _play(samples);
  }

  Future<void> playWin() async {
    if (_muted) return;
    final samples = _winChime(big: false);
    await _play(samples);
  }

  Future<void> playLoss() async {
    if (_muted) return;
    final samples = _lossSound();
    await _play(samples);
  }

  // Card sliding across felt: filtered noise burst with a quick attack and
  // medium decay, band-passed around 2-5kHz to mimic the papery swoosh.
  Int16List _cardSlide() {
    final rng = Random();
    final ms = 120;
    final n = (_sampleRate * ms / 1000).round();
    final out = Int16List(n);
    double lpState = 0;
    double hpState = 0;
    final lpAlpha = 0.12;
    final hpAlpha = 0.95;

    for (int i = 0; i < n; i++) {
      final t = i / n;
      final env = t < 0.05 ? t / 0.05 : pow(1.0 - (t - 0.05) / 0.95, 1.8);
      final noise = rng.nextDouble() * 2 - 1;
      // Low-pass then high-pass to band-limit the noise
      lpState += lpAlpha * (noise - lpState);
      hpState += hpAlpha * (lpState - hpState);
      final filtered = lpState - hpState;
      out[i] = (filtered * 32767 * 0.35 * env).round().clamp(-32768, 32767);
    }
    return out;
  }

  // Card flip: two quick snaps close together (the bend and release)
  Int16List _cardFlip() {
    final rng = Random();
    final ms = 150;
    final n = (_sampleRate * ms / 1000).round();
    final out = Int16List(n);
    double lpState = 0;

    for (int i = 0; i < n; i++) {
      final t = i / n;
      double env = 0;
      if (t < 0.3) {
        final lt = t / 0.3;
        env = lt < 0.08 ? lt / 0.08 : pow(1.0 - (lt - 0.08) / 0.92, 2.5).toDouble();
      } else if (t > 0.35 && t < 0.65) {
        final lt = (t - 0.35) / 0.3;
        env = (lt < 0.08 ? lt / 0.08 : pow(1.0 - (lt - 0.08) / 0.92, 2.5).toDouble()) * 0.7;
      }

      final noise = rng.nextDouble() * 2 - 1;
      lpState += 0.18 * (noise - lpState);
      out[i] = (lpState * 32767 * 0.4 * env).round().clamp(-32768, 32767);
    }
    return out;
  }

  // Chip dropping on felt: a sharper click with a subtle ceramic-like ring
  Int16List _chipDrop() {
    final rng = Random();
    final ms = 100;
    final n = (_sampleRate * ms / 1000).round();
    final out = Int16List(n);
    double lpState = 0;

    for (int i = 0; i < n; i++) {
      final t = i / n;
      final iF = i / _sampleRate;
      final env = t < 0.02 ? t / 0.02 : pow(1.0 - (t - 0.02) / 0.98, 3.0);

      final noise = rng.nextDouble() * 2 - 1;
      lpState += 0.25 * (noise - lpState);
      final ring = sin(2 * pi * 4200 * iF) * pow(1.0 - t, 6.0) * 0.3;

      final sample = (lpState * 0.5 + ring) * env;
      out[i] = (sample * 32767 * 0.4).round().clamp(-32768, 32767);
    }
    return out;
  }

  // Win chime: ascending bell-like tones with harmonics
  Int16List _winChime({required bool big}) {
    final notes = big ? [523.0, 659.0, 784.0, 1047.0] : [523.0, 659.0, 784.0];
    final noteMs = big ? 180 : 150;
    final gapMs = big ? 80 : 60;
    final totalMs = notes.length * noteMs + (notes.length - 1) * gapMs;
    final n = (_sampleRate * totalMs / 1000).round();
    final out = Int16List(n);

    for (int ni = 0; ni < notes.length; ni++) {
      final freq = notes[ni];
      final startSample = (ni * (noteMs + gapMs) / 1000 * _sampleRate).round();
      final noteSamples = (noteMs / 1000 * _sampleRate).round();

      for (int i = 0; i < noteSamples && startSample + i < n; i++) {
        final t = i / noteSamples;
        final iF = i / _sampleRate;
        // Bell envelope: fast attack, smooth exponential decay
        final env = t < 0.03 ? t / 0.03 : exp(-4.0 * (t - 0.03));
        // Fundamental + harmonics for a bell timbre
        final fundamental = sin(2 * pi * freq * iF);
        final h2 = sin(2 * pi * freq * 2.0 * iF) * 0.3;
        final h3 = sin(2 * pi * freq * 3.0 * iF) * 0.1;
        final sample = (fundamental + h2 + h3) * env * 0.22;
        final idx = startSample + i;
        out[idx] = (out[idx] + sample * 32767).round().clamp(-32768, 32767);
      }
    }
    return out;
  }

  // Loss: descending muted tone, like a low "womp womp"
  Int16List _lossSound() {
    final ms = 450;
    final n = (_sampleRate * ms / 1000).round();
    final out = Int16List(n);

    for (int i = 0; i < n; i++) {
      final t = i / n;
      final iF = i / _sampleRate;
      // Frequency slides down from ~350 to ~180 Hz
      final freq = 350 - 170 * t;
      final env = t < 0.05 ? t / 0.05 : pow(1.0 - (t - 0.05) / 0.95, 1.5);
      // Slightly hollow timbre (fundamental + quiet odd harmonic)
      final sample = sin(2 * pi * freq * iF) * 0.8 +
          sin(2 * pi * freq * 3 * iF) * 0.08;
      out[i] = (sample * 32767 * 0.2 * env).round().clamp(-32768, 32767);
    }
    return out;
  }

  Future<void> _play(Int16List samples) async {
    try {
      final wavData = _buildWav(samples);
      await _player.play(BytesSource(wavData));
    } catch (_) {}
  }

  Uint8List _buildWav(Int16List samples) {
    final dataSize = samples.length * 2;
    final fileSize = 44 + dataSize;
    final buffer = ByteData(fileSize);
    int offset = 0;

    void writeString(String s) {
      for (int i = 0; i < s.length; i++) {
        buffer.setUint8(offset++, s.codeUnitAt(i));
      }
    }

    writeString('RIFF');
    buffer.setUint32(offset, fileSize - 8, Endian.little); offset += 4;
    writeString('WAVE');
    writeString('fmt ');
    buffer.setUint32(offset, 16, Endian.little); offset += 4;
    buffer.setUint16(offset, 1, Endian.little); offset += 2;
    buffer.setUint16(offset, 1, Endian.little); offset += 2;
    buffer.setUint32(offset, _sampleRate, Endian.little); offset += 4;
    buffer.setUint32(offset, _sampleRate * 2, Endian.little); offset += 4;
    buffer.setUint16(offset, 2, Endian.little); offset += 2;
    buffer.setUint16(offset, 16, Endian.little); offset += 2;
    writeString('data');
    buffer.setUint32(offset, dataSize, Endian.little); offset += 4;

    for (int i = 0; i < samples.length; i++) {
      buffer.setInt16(offset, samples[i], Endian.little);
      offset += 2;
    }

    return buffer.buffer.asUint8List();
  }
}
