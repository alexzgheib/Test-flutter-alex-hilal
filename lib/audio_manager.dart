import 'package:audioplayers/audioplayers.dart';

class AudioManager {
  // We use multiple players so sounds can overlap (e.g. eating while music plays)
  static final AudioPlayer _bgmPlayer = AudioPlayer();
  static final AudioPlayer _sfxPlayer = AudioPlayer();

  static bool _isMuted = false;

  static bool get isMuted => _isMuted;

  static Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    if (_isMuted) {
      await _bgmPlayer.pause();
    } else {
      await _bgmPlayer.resume();
    }
  }

  static Future<void> playMenuBgm() async {
    if (_isMuted) return;
    try {
      _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.play(UrlSource('https://raw.githubusercontent.com/photonstorm/phaser3-examples/master/public/assets/audio/oedipus_ark_pandora.mp3'), volume: 0.5);
    } catch (e) {
      print("Error playing Menu BGM: $e");
    }
  }

  static Future<void> playBgm() async {
    if (_isMuted) return;
    try {
      _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      // Valid working audio: bodenstaendig_2000_in_rock_4bit.mp3
      await _bgmPlayer.play(UrlSource('https://raw.githubusercontent.com/photonstorm/phaser3-examples/master/public/assets/audio/bodenstaendig_2000_in_rock_4bit.mp3'), volume: 0.5);
    } catch (e) {
      print("Error playing BGM: $e");
    }
  }

  static Future<void> stopBgm() async {
    await _bgmPlayer.stop();
  }

  static Future<void> playEatSound() async {
    if (_isMuted) return;
    try {
      await _sfxPlayer.play(UrlSource('https://raw.githubusercontent.com/photonstorm/phaser3-examples/master/public/assets/audio/SoundEffects/p-ping.mp3'), volume: 1.0);
    } catch (e) {
      print("Error playing eat sound: $e");
    }
  }

  static Future<void> playPowerupSound() async {
    if (_isMuted) return;
    try {
      final player = AudioPlayer(); // Create new player for overlapping sfx
      await player.play(UrlSource('https://raw.githubusercontent.com/photonstorm/phaser3-examples/master/public/assets/audio/SoundEffects/key.wav'), volume: 1.0);
    } catch (e) {
      print("Error playing powerup sound: $e");
    }
  }

  static Future<void> playGameOverSound() async {
    if (_isMuted) return;
    try {
      await _sfxPlayer.play(UrlSource('https://raw.githubusercontent.com/photonstorm/phaser3-examples/master/public/assets/audio/SoundEffects/squash.mp3'), volume: 1.0);
    } catch (e) {
      print("Error playing game over sound: $e");
    }
  }

  static Future<void> playExplosionSound() async {
    if (_isMuted) return;
    try {
      await _sfxPlayer.play(UrlSource('https://raw.githubusercontent.com/photonstorm/phaser3-examples/master/public/assets/audio/SoundEffects/explosion.mp3'), volume: 1.0);
    } catch (e) {
      print("Error playing explosion sound: $e");
    }
  }
}
