import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import 'package:draw_together/src/utils/app_assets.dart';
import 'package:draw_together/src/utils/app_shared.dart';

class AppAudioManager {
  AppAudioManager(this._appShared)
    : _assetCache = AudioCache(prefix: ''),
      _backgroundPlayer = AudioPlayer() {
    _backgroundPlayer.audioCache = _assetCache;
  }

  final AppShared _appShared;
  final AudioCache _assetCache;
  final AudioPlayer _backgroundPlayer;
  AudioPool? _tapPool;
  bool _isBackgroundStarted = false;
  bool _backgroundMusicEnabled = true;
  bool _soundEffectsEnabled = true;

  bool get backgroundMusicEnabled => _backgroundMusicEnabled;

  bool get soundEffectsEnabled => _soundEffectsEnabled;

  Future<void> initialize() async {
    _backgroundMusicEnabled = _appShared.getBackgroundMusicEnabled();
    _soundEffectsEnabled = _appShared.getSoundEffectsEnabled();
    await _backgroundPlayer.setReleaseMode(ReleaseMode.loop);
    await _backgroundPlayer.setVolume(0.42);
    _tapPool = await AudioPool.create(
      source: AssetSource(AppAssets.buttonTapAudioMp3),
      minPlayers: 2,
      maxPlayers: 4,
      audioCache: _assetCache,
      playerMode: PlayerMode.mediaPlayer,
    );
  }

  void startBackgroundMusic() {
    if (!_backgroundMusicEnabled || _isBackgroundStarted) return;
    unawaited(_startBackgroundMusic());
  }

  void playButtonTap() {
    if (!_soundEffectsEnabled) return;
    unawaited(_playButtonTap());
  }

  Future<void> setBackgroundMusicEnabled(bool enabled) async {
    _backgroundMusicEnabled = enabled;
    await _appShared.setBackgroundMusicEnabled(enabled);

    if (enabled) {
      startBackgroundMusic();
      return;
    }

    await _backgroundPlayer.stop();
    _isBackgroundStarted = false;
  }

  Future<void> setSoundEffectsEnabled(bool enabled) async {
    _soundEffectsEnabled = enabled;
    await _appShared.setSoundEffectsEnabled(enabled);
  }

  Future<void> _startBackgroundMusic() async {
    try {
      await _backgroundPlayer.play(
        AssetSource(AppAssets.backgroundAudioMp3),
        volume: 0.42,
      );
      _isBackgroundStarted = true;
    } catch (_) {
      _isBackgroundStarted = false;
    }
  }

  Future<void> _playButtonTap() async {
    try {
      startBackgroundMusic();
      await _tapPool?.start(volume: 0.72);
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _tapPool?.dispose();
    await _backgroundPlayer.dispose();
  }
}
