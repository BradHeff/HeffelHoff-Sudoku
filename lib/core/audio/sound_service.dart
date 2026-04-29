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

/// Low-latency SFX. Each event gets its own pre-loaded `AudioPool` so
/// `play()` returns instantly without hitting the asset bundle. Without
/// pooling, every fire pays a stop+setSource roundtrip — audible delay
/// on rapid digit placements / structure-completion bursts.
class SoundService {
  SoundService();

  bool _muted = false;
  double _volume = 1.0;
  final Map<SoundEvent, Future<AudioPool>> _pools = {};
  final Set<SoundEvent> _missing = {};

  bool get muted => _muted;
  double get volume => _volume;

  void setMuted(bool value) {
    _muted = value;
  }

  void setVolume(double v) {
    _volume = v.clamp(0.0, 1.0);
  }

  /// Pre-loads every SFX into its pool so the first occurrence in-game
  /// has no asset-load delay. Call from the splash screen.
  Future<void> warmAll() async {
    await Future.wait(SoundEvent.values.map(_poolFor));
  }

  Future<AudioPool> _poolFor(SoundEvent event) {
    return _pools.putIfAbsent(event, () async {
      try {
        return await AudioPool.create(
          source: AssetSource('audio/${event.filename}'),
          maxPlayers: 2,
        );
      } catch (e, st) {
        _missing.add(event);
        if (kDebugMode) {
          debugPrint('[SoundService] missing or unplayable: ${event.filename} — $e');
          debugPrintStack(stackTrace: st, maxFrames: 3);
        }
        rethrow;
      }
    });
  }

  Future<void> play(SoundEvent event) async {
    if (_muted) return;
    if (_missing.contains(event)) return;
    try {
      final pool = await _poolFor(event);
      await pool.start(volume: _volume);
    } catch (_) {
      _missing.add(event);
    }
  }

  Future<void> dispose() async {
    for (final f in _pools.values) {
      try {
        final pool = await f;
        await pool.dispose();
      } catch (_) {}
    }
    _pools.clear();
  }
}

final soundServiceProvider = Provider<SoundService>((ref) {
  final svc = SoundService();
  ref.onDispose(svc.dispose);
  return svc;
});
