// import 'package:audioplayers/audioplayers.dart';
// import 'package:flutter/services.dart';

// /// Tiny audio façade for the game. Pre-creates one [AudioPlayer] per SFX so
// /// they can overlap (e.g. catching two fruits in the same frame). If a sound
// /// asset is missing we silently swallow the error and trigger a haptic instead
// /// — the game stays playable on day one without you needing to source audio.
// class SoundManager {
//   SoundManager._();
//   static final SoundManager instance = SoundManager._();

//   bool _enabled = true;
//   bool _musicOn = true;

//   final AudioPlayer _catch = AudioPlayer();
//   final AudioPlayer _bomb = AudioPlayer();
//   final AudioPlayer _levelUp = AudioPlayer();
//   final AudioPlayer _gameOver = AudioPlayer();
//   final AudioPlayer _music = AudioPlayer();

//   bool get enabled => _enabled;
//   bool get musicOn => _musicOn;

//   Future<void> init() async {
//     for (final AudioPlayer p in <AudioPlayer>[_catch, _bomb, _levelUp, _gameOver]) {
//       await p.setReleaseMode(ReleaseMode.stop);
//       await p.setPlayerMode(PlayerMode.lowLatency);
//       await p.setVolume(0.85);
//     }
//     await _music.setReleaseMode(ReleaseMode.loop);
//     await _music.setVolume(0.30);
//   }

//   void setEnabled(bool v) {
//     _enabled = v;
//     if (!v) stopMusic();
//   }

//   void setMusic(bool v) {
//     _musicOn = v;
//     if (!v) stopMusic();
//   }

//   Future<void> _safe(AudioPlayer p, String assetPath) async {
//     if (!_enabled) return;
//     try {
//       await p.stop();
//       await p.play(AssetSource(assetPath));
//     } catch (_) {
//       // Asset missing — degrade gracefully. UX-wise we still want feedback.
//     }
//   }

//   // ── One-shots ──
//   Future<void> playCatch() async {
//     HapticFeedback.lightImpact();
//     return _safe(_catch, 'sounds/catch.mp3');
//   }

//   Future<void> playBomb() async {
//     HapticFeedback.heavyImpact();
//     return _safe(_bomb, 'sounds/bomb.mp3');
//   }

//   Future<void> playLevelUp() async {
//     HapticFeedback.mediumImpact();
//     return _safe(_levelUp, 'sounds/level_up.mp3');
//   }

//   Future<void> playGameOver() async {
//     HapticFeedback.heavyImpact();
//     return _safe(_gameOver, 'sounds/game_over.mp3');
//   }

//   // ── Background music ──
//   Future<void> startMusic() async {
//     if (!_enabled || !_musicOn) return;
//     try {
//       await _music.stop();
//       await _music.play(AssetSource('sounds/bg_music.mp3'));
//     } catch (_) {/* no music file */}
//   }

//   Future<void> stopMusic() async {
//     try { await _music.stop(); } catch (_) {}
//   }

//   Future<void> pauseMusic() async {
//     try { await _music.pause(); } catch (_) {}
//   }

//   Future<void> resumeMusic() async {
//     if (!_enabled || !_musicOn) return;
//     try { await _music.resume(); } catch (_) {}
//   }

//   Future<void> dispose() async {
//     for (final AudioPlayer p in <AudioPlayer>[
//       _catch, _bomb, _levelUp, _gameOver, _music,
//     ]) {
//       try { await p.dispose(); } catch (_) {}
//     }
//   }
// }

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Tiny audio façade for the game. Pre-creates one [AudioPlayer] per SFX so
/// they can overlap. Implements "Audio Ducking" where background music
/// smoothly lowers when SFX play, and returns to normal when they finish.
class SoundManager {
  SoundManager._();
  static final SoundManager instance = SoundManager._();

  bool _enabled = true;
  bool _musicOn = true;

  // Tracks how many SFX are currently playing to handle overlapping sounds
  int _sfxActiveCount = 0;

  final AudioPlayer _catch = AudioPlayer();
  final AudioPlayer _bomb = AudioPlayer();
  final AudioPlayer _levelUp = AudioPlayer();
  final AudioPlayer _gameOver = AudioPlayer();
  final AudioPlayer _music = AudioPlayer();

  // Volume controls for the ducking effect
  static const double _baseMusicVolume = 0.30;
  static const double _duckedMusicVolume = 0.08; // Lowers to ~8% during SFX
  double _currentMusicVolume = _baseMusicVolume;

  bool get enabled => _enabled;
  bool get musicOn => _musicOn;

  Future<void> init() async {
    // Setup standard SFX players
    for (final AudioPlayer p in <AudioPlayer>[_catch, _levelUp, _gameOver]) {
      await p.setReleaseMode(ReleaseMode.stop);
      await p.setPlayerMode(PlayerMode.lowLatency);
      await p.setVolume(0.85);
    }

    // Setup Bomb SFX player with INCREASED volume
    await _bomb.setReleaseMode(ReleaseMode.stop);
    await _bomb.setPlayerMode(PlayerMode.lowLatency);
    await _bomb.setVolume(1.0); // Max volume for bomb impact

    // Setup Background Music player
    await _music.setReleaseMode(ReleaseMode.loop);
    await _music.setVolume(_baseMusicVolume);

    // Attach completion listeners to automatically restore music volume
    for (final AudioPlayer p in <AudioPlayer>[_catch, _bomb, _levelUp, _gameOver]) {
      p.onPlayerComplete.listen((_) {
        if (_sfxActiveCount > 0) _sfxActiveCount--;
        _updateMusicVolume(); // Fade music back up
      });
    }
  }

  void setEnabled(bool v) {
    _enabled = v;
    if (!v) stopMusic();
  }

  void setMusic(bool v) {
    _musicOn = v;
    if (!v) stopMusic();
  }

  /// Smoothly ducks the background music when SFX play, 
  /// and smoothly restores it when all SFX finish.
  Future<void> _updateMusicVolume() async {
    if (!_musicOn) return;
    
    // Determine target volume based on active SFX
    final double target = _sfxActiveCount > 0 ? _duckedMusicVolume : _baseMusicVolume;
    
    try {
      // Quick 120ms smooth linear fade to prevent harsh audio "pops"
      const int steps = 4;
      const Duration stepDelay = Duration(milliseconds: 30);
      final double startVol = _currentMusicVolume;
      final double diff = target - startVol;

      for (int i = 1; i <= steps; i++) {
        await Future.delayed(stepDelay);
        _currentMusicVolume = startVol + (diff * (i / steps));
        await _music.setVolume(_currentMusicVolume);
      }
    } catch (_) {
      // Fallback to instant change if fade fails for any reason
      _currentMusicVolume = target;
      try { await _music.setVolume(target); } catch (_) {}
    }
  }

  Future<void> _safe(AudioPlayer p, String assetPath) async {
    if (!_enabled) return;
    
    try {
      // Check if this specific player was already playing a sound
      bool wasPlaying = false;
      try {
        wasPlaying = p.state == PlayerState.playing;
      } catch (_) {}

      await p.stop();
      
      // If it wasn't playing, this is a NEW sound entering the mix
      if (!wasPlaying) {
        _sfxActiveCount++;
      }
      
      // Trigger the ducking effect on the background music
      await _updateMusicVolume(); 
      
      // Play the new sound effect
      await p.play(AssetSource(assetPath));
    } catch (_) {
      // If playback fails, ensure we don't leave the volume ducked permanently
      if (_sfxActiveCount > 0) _sfxActiveCount--;
      await _updateMusicVolume();
    }
  }

  // ── One-shots ──
  Future<void> playCatch() async {
    HapticFeedback.lightImpact();
    return _safe(_catch, 'sounds/catch.mp3');
  }

  Future<void> playBomb() async {
    HapticFeedback.heavyImpact();
    return _safe(_bomb, 'sounds/bomb.mp3');
  }

  Future<void> playLevelUp() async {
    HapticFeedback.mediumImpact();
    return _safe(_levelUp, 'sounds/level_up.mp3');
  }

  Future<void> playGameOver() async {
    HapticFeedback.heavyImpact();
    return _safe(_gameOver, 'sounds/game_over.mp3');
  }

  // ── Background music ──
  Future<void> startMusic() async {
    if (!_enabled || !_musicOn) return;
    try {
      await _music.stop();
      _currentMusicVolume = _baseMusicVolume; // Reset volume tracker
      await _music.setVolume(_baseMusicVolume);
      await _music.play(AssetSource('sounds/bg_music.mp3'));
    } catch (_) {/* no music file */}
  }

  Future<void> stopMusic() async {
    try { await _music.stop(); } catch (_) {}
  }

  Future<void> pauseMusic() async {
    try { await _music.pause(); } catch (_) {}
  }

  Future<void> resumeMusic() async {
    if (!_enabled || !_musicOn) return;
    try { await _music.resume(); } catch (_) {}
  }

  Future<void> dispose() async {
    for (final AudioPlayer p in <AudioPlayer>[
      _catch, _bomb, _levelUp, _gameOver, _music,
    ]) {
      try { await p.dispose(); } catch (_) {}
    }
  }
}