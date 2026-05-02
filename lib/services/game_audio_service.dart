import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

enum GameSfx {
  pickup,
  correct,
  wrong,
  hover,
  complete,
  star,
}

class GameAudioService {
  final Map<GameSfx, List<AudioPlayer>> _pool = {};
  final Map<GameSfx, int> _cursor = {};
  final Map<GameSfx, BytesSource> _sourceCache = {};

  Future<void> preload() async {
    _sourceCache[GameSfx.pickup] = BytesSource(_buildSineWav(540, 90));
    _sourceCache[GameSfx.correct] = BytesSource(_buildSineWav(760, 120));
    _sourceCache[GameSfx.wrong] = BytesSource(_buildSineWav(180, 150));
    _sourceCache[GameSfx.hover] = BytesSource(_buildSineWav(620, 60));
    _sourceCache[GameSfx.complete] = BytesSource(_buildSineWavSweep(420, 980, 380));
    _sourceCache[GameSfx.star] = BytesSource(_buildSineWav(1100, 130));

    for (final effect in GameSfx.values) {
      _pool[effect] = List.generate(3, (_) => AudioPlayer());
      _cursor[effect] = 0;
      for (final player in _pool[effect]!) {
        await player.setReleaseMode(ReleaseMode.stop);
      }
    }
  }

  Future<void> play(GameSfx effect, {double volume = 1}) async {
    final players = _pool[effect];
    final source = _sourceCache[effect];
    if (players == null || players.isEmpty || source == null) {
      return;
    }
    final next = _cursor[effect] ?? 0;
    final player = players[next];
    _cursor[effect] = (next + 1) % players.length;
    await player.setVolume(volume);
    await player.play(source);
  }

  Future<void> dispose() async {
    for (final players in _pool.values) {
      for (final p in players) {
        await p.dispose();
      }
    }
  }

  Uint8List _buildSineWav(int hz, int durationMs) {
    const sampleRate = 44100;
    final sampleCount = (sampleRate * durationMs / 1000).round();
    final pcm = Int16List(sampleCount);
    for (var i = 0; i < sampleCount; i++) {
      final t = i / sampleRate;
      final envelope = 1 - (i / sampleCount);
      final v = sin(2 * pi * hz * t) * envelope * 0.35;
      pcm[i] = (v * 32767).toInt();
    }
    return _wavFromPcm16(pcm, sampleRate);
  }

  Uint8List _buildSineWavSweep(int fromHz, int toHz, int durationMs) {
    const sampleRate = 44100;
    final sampleCount = (sampleRate * durationMs / 1000).round();
    final pcm = Int16List(sampleCount);
    for (var i = 0; i < sampleCount; i++) {
      final t = i / sampleRate;
      final progress = i / sampleCount;
      final hz = fromHz + ((toHz - fromHz) * progress);
      final envelope = sin(progress * pi);
      final v = sin(2 * pi * hz * t) * envelope * 0.4;
      pcm[i] = (v * 32767).toInt();
    }
    return _wavFromPcm16(pcm, sampleRate);
  }

  Uint8List _wavFromPcm16(Int16List pcm, int sampleRate) {
    final dataLength = pcm.length * 2;
    final byteData = ByteData(44 + dataLength);
    var o = 0;

    void writeString(String value) {
      for (final code in value.codeUnits) {
        byteData.setUint8(o++, code);
      }
    }

    writeString('RIFF');
    byteData.setUint32(o, 36 + dataLength, Endian.little);
    o += 4;
    writeString('WAVEfmt ');
    byteData.setUint32(o, 16, Endian.little);
    o += 4;
    byteData.setUint16(o, 1, Endian.little);
    o += 2;
    byteData.setUint16(o, 1, Endian.little);
    o += 2;
    byteData.setUint32(o, sampleRate, Endian.little);
    o += 4;
    byteData.setUint32(o, sampleRate * 2, Endian.little);
    o += 4;
    byteData.setUint16(o, 2, Endian.little);
    o += 2;
    byteData.setUint16(o, 16, Endian.little);
    o += 2;
    writeString('data');
    byteData.setUint32(o, dataLength, Endian.little);
    o += 4;
    for (final sample in pcm) {
      byteData.setInt16(o, sample, Endian.little);
      o += 2;
    }
    return byteData.buffer.asUint8List();
  }
}
