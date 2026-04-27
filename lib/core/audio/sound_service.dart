import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Semantic sound events. Map to filenames in `assets/audio/` — see
/// `assets/audio/README.md` for what to drop in.
enum SoundEvent {
  placeCorrect('place_correct.mp3'),
  placeWrong('place_wrong.mp3'),
  structureComplete('structure_complete.mp3'),
  digitComplete('digit_complete.mp3'),
  puzzleComplete('puzzle_complete.mp3'),
  puzzleCompleteGenius('puzzle_complete_genius.mp3'),
  comboDouble('combo_double.mp3'),
  comboTriple('combo_triple.mp3');

  const SoundEvent(this.filename);
  final String filename;
}

/// Plays short SFX. Each event gets its own [AudioPlayer] so a wrong-tap
/// doesn't cut off a celebration that's still ringing.
///
/// Files are loaded lazily on first `play()`. If a file is missing or
/// fails to load, the service swallows the error and continues silently
/// — the game stays playable while the audio team is still sourcing
/// assets.
class SoundService {
  SoundService();

  bool _muted = false;
  double _volume = 1.0;
  final Map<SoundEvent, AudioPlayer> _players = {};
  final Set<SoundEvent> _missing = {};

  bool get muted => _muted;
  double get volume => _volume;

  void setMuted(bool value) {
    _muted = value;
    if (_muted) {
      for (final p in _players.values) {
        p.stop();
      }
    }
  }

  void setVolume(double v) {
    _volume = v.clamp(0.0, 1.0);
    for (final p in _players.values) {
      p.setVolume(_volume);
    }
  }

  Future<void> play(SoundEvent event) async {
    if (_muted) return;
    if (_missing.contains(event)) return;
    try {
      final player = _players.putIfAbsent(
        event,
        () => AudioPlayer(playerId: 'sfx_${event.name}')
          ..setReleaseMode(ReleaseMode.stop),
      );
      await player.stop();
      await player.setVolume(_volume);
      await player.play(AssetSource('audio/${event.filename}'));
    } catch (e, st) {
      // First failure for this event is logged + cached; subsequent
      // attempts skip silently so we don't spam the console.
      _missing.add(event);
      if (kDebugMode) {
        debugPrint('[SoundService] missing or unplayable: ${event.filename} — $e');
        debugPrintStack(stackTrace: st, maxFrames: 3);
      }
    }
  }

  Future<void> dispose() async {
    for (final p in _players.values) {
      await p.dispose();
    }
    _players.clear();
  }
}

/// Process-wide singleton; survives navigation. Kept alive in main.dart's
/// ProviderScope.
final soundServiceProvider = Provider<SoundService>((ref) {
  final svc = SoundService();
  ref.onDispose(svc.dispose);
  return svc;
});
