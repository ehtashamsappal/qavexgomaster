/// Sound effects + background music backed by the generated WAV assets.
library;

import 'package:audioplayers/audioplayers.dart';

class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  final AudioPlayer _sfx = AudioPlayer();
  final AudioPlayer _bgm = AudioPlayer();
  bool _ready = false;
  bool soundOn = true;
  bool musicOn = true;
  String? _currentBgm;

  static const List<String> sfxNames = [
    'stone_place',
    'capture',
    'pass',
    'button',
    'win',
    'lose',
    'coin',
    'achievement',
    'tick',
    'error',
  ];

  Future<void> init({required bool sound, required bool music}) async {
    soundOn = sound;
    musicOn = music;
    if (_ready) return;
    _ready = true;
    try {
      await _bgm.setReleaseMode(ReleaseMode.loop);
      await _bgm.setVolume(0.35);
    } catch (_) {}
  }

  void syncSettings({required bool sound, required bool music}) {
    final musicChanged = musicOn != music;
    soundOn = sound;
    musicOn = music;
    if (musicChanged) {
      if (music && _currentBgm != null) {
        startBgm(_currentBgm!);
      } else if (!music) {
        stopBgm();
      }
    }
  }

  Future<void> playSfx(String name) async {
    if (!_ready || !soundOn) return;
    if (!sfxNames.contains(name)) return;
    try {
      await _sfx.play(AssetSource('audio/sfx_$name.wav'));
    } catch (_) {}
  }

  Future<void> startBgm(String track) async {
    _currentBgm = track;
    if (!_ready || !musicOn) return;
    try {
      await _bgm.play(AssetSource('audio/$track.wav'));
    } catch (_) {}
  }

  Future<void> stopBgm() async {
    try {
      await _bgm.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    try {
      await _sfx.dispose();
      await _bgm.dispose();
    } catch (_) {}
    _ready = false;
  }
}
