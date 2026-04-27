import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SoundEvent {
  placeCorrect('place_correct.wav'),
  placeWrong('place_wrong.wav'),
  structureComplete('structure_complete.wav'),
  digitComplete('digit_complete.wav'),
  puzzleComplete('puzzle_complete.wav'),
  puzzleCompleteGenius('puzzle_complete_genius.wav'),
  comboDouble('combo_double.wav'),
  comboTriple('combo_triple.wav');

  const SoundEvent(this.filename);
  final String filename;
}

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

final soundServiceProvider = Provider<SoundService>((ref) {
  final svc = SoundService();
  ref.onDispose(svc.dispose);
  return svc;
});
