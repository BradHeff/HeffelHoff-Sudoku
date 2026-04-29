import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/sound_service.dart';
import '../../monetization/data/rewarded_economy_service.dart';
import '../../monetization/presentation/boost_offer_sheet.dart';
import '../../monetization/presentation/evil_unlock_sheet.dart';
import '../../profile/data/best_iq_repository.dart';
import '../data/attempts_repository.dart';
import '../data/backtracking_generator.dart';
import '../domain/board.dart';
import '../domain/difficulty.dart';
import '../domain/game_state.dart';
import '../domain/puzzle.dart';
import 'iq_calculator.dart';
import 'sync_status.dart';

class GameController extends StateNotifier<GameState> {
  GameController({
    required Difficulty difficulty,
    required SoundService sound,
    required AttemptsRepository attempts,
    required Ref ref,
    int? seed,
    int maxLives = 3,
    int hintCap = 1,
  })  : _maxLives = maxLives,
        _hintCap = hintCap,
        _sound = sound,
        _attempts = attempts,
        _ref = ref,
        super(GameLoading(difficulty: difficulty)) {
    _start(difficulty: difficulty, seed: seed);
  }

  final int _maxLives;
  final int _hintCap;
  int get hintCap => _hintCap;
  final SoundService _sound;
  final AttemptsRepository _attempts;
  final Ref _ref;
  ({Puzzle puzzle, DateTime startedAt, int timeSeconds, int mistakes,
    int hintsUsed, int livesUsed, int iqScore})? _lastWinPayload;
  Timer? _ticker;
  Timer? _digitCelebrationTimer;

  static const Duration kDigitCelebrationDuration = Duration(milliseconds: 1500);

  Future<void> _start({required Difficulty difficulty, int? seed}) async {
    // Reset the sync badge so a new puzzle doesn't inherit "Result saved"
    // from the previous round's post-game screen.
    _ref.read(lastSubmitStatusProvider.notifier).state = SyncStatus.idle;
    _lastWinPayload = null;
    final s = seed ?? DateTime.now().millisecondsSinceEpoch;
    try {
      final puzzle = await _generate(seed: s, difficulty: difficulty);
      final board = Board.fromClues(puzzle.clues);
      state = GameOngoing(
        puzzle: puzzle,
        board: board,
        selected: null,
        lives: _maxLives,
        maxLives: _maxLives,
        mistakes: 0,
        hintsUsed: 0,
        elapsed: Duration.zero,
        startedAt: DateTime.now(),
        pencilMode: false,
        paused: false,
      );
      _startTicker();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Generator failed: $e\n$st');
      }
      state = const GameError('Could not generate a puzzle. Please try again.');
    }
  }

  Future<Puzzle> _generate({required int seed, required Difficulty difficulty}) async {
    return BacktrackingGenerator.generate(seed: seed, difficulty: difficulty);
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final s = state;
      if (s is GameOngoing && !s.paused) {
        state = s.copyWith(elapsed: s.elapsed + const Duration(seconds: 1));
      }
    });
  }

  /// Tap-to-select. Highlight survives a single empty-cell tap that
  /// follows a filled-cell tap; a second consecutive empty-cell tap
  /// clears it.
  void selectCell(int row, int col) {
    final s = state;
    if (s is! GameOngoing) return;

    final newCell = s.board.at(row, col);
    final prev = s.selected;
    final prevCell = prev != null ? s.board.at(prev.row, prev.col) : null;
    final prevWasFilled = prevCell != null && prevCell.value != 0 && !prevCell.isWrong;

    int? nextHighlight;
    var clearHighlight = false;
    if (newCell.value != 0 && !newCell.isWrong) {
      nextHighlight = newCell.value;
    } else if (prevWasFilled && s.highlightedDigit != null) {
      nextHighlight = s.highlightedDigit;
    } else {
      clearHighlight = true;
    }

    state = s.copyWith(
      selected: (row: row, col: col),
      highlightedDigit: nextHighlight,
      clearHighlight: clearHighlight,
    );
  }

  void togglePencil() {
    final s = state;
    if (s is! GameOngoing) return;
    state = s.copyWith(pencilMode: !s.pencilMode);
  }

  void setPaused(bool paused) {
    final s = state;
    if (s is! GameOngoing) return;
    state = s.copyWith(paused: paused);
  }

  /// Place [digit] at the selected cell. Returns true if accepted.
  bool enterDigit(int digit) {
    final s = state;
    if (s is! GameOngoing) return false;
    final sel = s.selected;
    if (sel == null) return false;
    final cell = s.board.at(sel.row, sel.col);
    if (cell.isGiven) return false;

    if (s.pencilMode && cell.isEmpty) {
      final mask = cell.pencilMarks ^ (1 << (digit - 1));
      state = s.copyWith(board: s.board.withCell(cell.copyWith(pencilMarks: mask)));
      return true;
    }

    // Once a digit has been correctly placed, the cell is locked. Any
    // further taps (same digit or different) on a filled, non-wrong cell
    // are no-ops. Wrong-flagged cells stay editable until the 1.2s
    // auto-clear runs.
    if (cell.value != 0 && !cell.isWrong) {
      return false;
    }

    final correct = s.puzzle.isCorrect(row: sel.row, col: sel.col, value: digit);
    if (correct) {
      final next = s.board.withCell(cell.copyWith(value: digit, pencilMarks: 0, isWrong: false));
      _sound.play(SoundEvent.placeCorrect);
      _afterPlacement(
        s.copyWith(highlightedDigit: digit),
        next,
        placedDigit: digit,
        placedRow: sel.row,
        placedCol: sel.col,
      );
      return true;
    }

    _sound.play(SoundEvent.placeWrong);
    final wrongCell = cell.copyWith(value: digit, pencilMarks: 0, isWrong: true);
    final lives = s.lives - 1;
    final mistakes = s.mistakes + 1;
    final boardWithWrong = s.board.withCell(wrongCell);
    state = s.copyWith(board: boardWithWrong, lives: lives, mistakes: mistakes);

    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      final cur = state;
      if (cur is GameOngoing) {
        final c = cur.board.at(sel.row, sel.col);
        if (c.isWrong) {
          state = cur.copyWith(
            board: cur.board.withCell(c.copyWith(value: 0, isWrong: false)),
          );
        }
      }
    });

    if (lives <= 0) {
      _stopTicker();
      final ongoingSnap = s.copyWith(
        board: boardWithWrong,
        lives: 0,
        mistakes: mistakes,
      );
      if (ongoingSnap.extraLifeUsed) {
        _flagLossPopup();
        state = GameLost(
          puzzle: s.puzzle,
          timeSeconds: s.elapsed.inSeconds,
          mistakes: mistakes,
        );
      } else {
        state = GameOutOfLives(ongoing: ongoingSnap);
      }
    }
    return false;
  }

  /// After a Medium / Hard win, queue the Evil-unlock offer for the
  /// home screen — but only if Evil hasn't already been unlocked.
  /// Other tiers (including Evil itself) skip the offer.
  void _flagWinPopupsIfNeeded(Difficulty tier) {
    if (tier != Difficulty.medium && tier != Difficulty.hard) return;
    final econ = _ref.read(rewardedEconomyProvider);
    if (econ.evilUnlocked) return;
    _ref.read(pendingEvilUnlockOfferProvider.notifier).state = true;
  }

  /// Records the loss and only queues the boost offer on every Nth
  /// failure — see RewardedEconomyService for the cadence. Showing the
  /// sheet after every loss was too aggressive.
  void _flagLossPopup() {
    final econ = _ref.read(rewardedEconomyProvider.notifier);
    econ.recordLossAndShouldOffer().then((shouldOffer) {
      if (shouldOffer) {
        _ref.read(pendingBoostOfferProvider.notifier).state = true;
      }
    });
  }

  /// Refunds 1 life after the player accepted the out-of-lives offer
  /// (rewarded ad watched or extra-life IAP purchased). Resumes play.
  void restoreLife() {
    final s = state;
    if (s is! GameOutOfLives) return;
    final cur = s.ongoing;
    state = cur.copyWith(lives: 1, extraLifeUsed: true);
    _startTicker();
  }

  /// Player declined the offer. Finalise as GameLost.
  void confirmGameLost() {
    final s = state;
    if (s is! GameOutOfLives) return;
    final cur = s.ongoing;
    _flagLossPopup();
    state = GameLost(
      puzzle: cur.puzzle,
      timeSeconds: cur.elapsed.inSeconds,
      mistakes: cur.mistakes,
    );
  }

  /// Grants 1 extra hint slot for this puzzle (consumable IAP).
  void purchaseExtraHint() {
    final s = state;
    if (s is! GameOngoing) return;
    if (s.extraHintPurchased) return;
    state = s.copyWith(extraHintPurchased: true);
  }

  void erase() {
    final s = state;
    if (s is! GameOngoing) return;
    final sel = s.selected;
    if (sel == null) return;
    final cell = s.board.at(sel.row, sel.col);
    if (cell.isGiven || cell.isEmpty) return;
    // Correctly-placed cells are locked. Erase only clears wrong-flagged
    // values and pencil marks.
    if (cell.value != 0 && !cell.isWrong) {
      if (cell.pencilMarks == 0) return;
      state = s.copyWith(
        board: s.board.withCell(cell.copyWith(pencilMarks: 0)),
      );
      return;
    }
    state = s.copyWith(
      board: s.board.withCell(cell.copyWith(value: 0, pencilMarks: 0, isWrong: false)),
    );
  }

  /// Reveal the correct digit. If no usable cell is selected, walks
  /// the board and uses the first empty / wrong-flagged cell.
  void useHint() {
    final s = state;
    if (s is! GameOngoing) return;

    var sel = s.selected;

    bool needsRetarget(({int row, int col}) target) {
      final c = s.board.at(target.row, target.col);
      return c.isGiven ||
          (c.value != 0 && !c.isWrong && c.value == s.puzzle.digitAt(target.row, target.col));
    }

    if (sel == null || needsRetarget(sel)) {
      sel = null;
      for (var i = 0; i < 81; i++) {
        final r = i ~/ 9;
        final c = i % 9;
        final cell = s.board.at(r, c);
        if (cell.isGiven) continue;
        final correct = s.puzzle.digitAt(r, c);
        if (cell.value != correct || cell.isWrong) {
          sel = (row: r, col: c);
          break;
        }
      }
      if (sel == null) return;
    }

    final cell = s.board.at(sel.row, sel.col);
    final correct = s.puzzle.digitAt(sel.row, sel.col);
    final next = s.board.withCell(
      cell.copyWith(value: correct, pencilMarks: 0, isWrong: false),
    );
    _afterPlacement(
      s.copyWith(hintsUsed: s.hintsUsed + 1, selected: sel, highlightedDigit: correct),
      next,
      placedDigit: correct,
      placedRow: sel.row,
      placedCol: sel.col,
    );
  }

  /// Detects 8→9 transitions for digit/row/col/box and fires the
  /// matching celebrations. Transitions to GameWon when the board fills.
  void _afterPlacement(
    GameOngoing s,
    Board next, {
    required int placedDigit,
    required int placedRow,
    required int placedCol,
  }) {
    if (next.isFull) {
      _stopTicker();
      final time = s.elapsed.inSeconds;
      final iq = IqCalculator.compute(
        difficulty: s.difficulty,
        timeSeconds: time,
        mistakes: s.mistakes,
        hintsUsed: s.hintsUsed,
      );
      final wasUnderTarget = time < s.difficulty.targetTimeSeconds;
      _sound.play(
        wasUnderTarget ? SoundEvent.puzzleCompleteGenius : SoundEvent.puzzleComplete,
      );

      _lastWinPayload = (
        puzzle: s.puzzle,
        startedAt: s.startedAt,
        timeSeconds: time,
        mistakes: s.mistakes,
        hintsUsed: s.hintsUsed,
        livesUsed: s.maxLives - s.lives,
        iqScore: iq.iqScore,
      );
      unawaited(_runSubmitWin());
      _flagWinPopupsIfNeeded(s.difficulty);

      state = GameWon(
        puzzle: s.puzzle,
        timeSeconds: time,
        mistakes: s.mistakes,
        hintsUsed: s.hintsUsed,
        livesRemaining: s.lives,
        iqScore: iq.iqScore,
        wasUnderTarget: wasUnderTarget,
      );
      return;
    }

    final placedBox = (placedRow ~/ 3) * 3 + (placedCol ~/ 3);

    final completedDigit = (s.board.countDigit(placedDigit) != 9 &&
            next.countDigit(placedDigit) == 9)
        ? placedDigit
        : null;
    final completedRow = (!s.board.rowFull(placedRow) && next.rowFull(placedRow))
        ? placedRow
        : null;
    final completedCol = (!s.board.colFull(placedCol) && next.colFull(placedCol))
        ? placedCol
        : null;
    final completedBox = (!s.board.boxFull(placedBox) && next.boxFull(placedBox))
        ? placedBox
        : null;

    final anyCompletion = completedDigit != null ||
        completedRow != null ||
        completedCol != null ||
        completedBox != null;

    if (anyCompletion) {
      _digitCelebrationTimer?.cancel();
      final at = DateTime.now();

      final structureCount = [completedRow, completedCol, completedBox]
          .where((e) => e != null)
          .length;
      if (completedDigit != null) {
        _sound.play(SoundEvent.digitComplete);
      } else if (structureCount >= 3) {
        _sound.play(SoundEvent.comboTriple);
      } else if (structureCount == 2) {
        _sound.play(SoundEvent.comboDouble);
      } else {
        _sound.play(SoundEvent.structureComplete);
      }

      state = s.copyWith(
        board: next,
        lastCompletedDigit: completedDigit,
        lastCompletedRow: completedRow,
        lastCompletedCol: completedCol,
        lastCompletedBox: completedBox,
        lastCompletedAt: at,
      );
      _digitCelebrationTimer = Timer(kDigitCelebrationDuration, () {
        final cur = state;
        if (cur is GameOngoing && cur.lastCompletedAt == at) {
          state = cur.copyWith(clearLastCompleted: true);
        }
      });
    } else {
      state = s.copyWith(board: next);
    }
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  /// Submits the most recent win and updates [lastSubmitStatusProvider]
  /// so the post-game screen can show a syncing → synced/failed badge.
  Future<void> _runSubmitWin() async {
    final payload = _lastWinPayload;
    if (payload == null) return;
    _ref.read(lastSubmitStatusProvider.notifier).state = SyncStatus.syncing;
    final ok = await _attempts.submitWin(
      puzzle: payload.puzzle,
      startedAt: payload.startedAt,
      timeSeconds: payload.timeSeconds,
      mistakes: payload.mistakes,
      hintsUsed: payload.hintsUsed,
      livesUsed: payload.livesUsed,
      iqScore: payload.iqScore,
    );
    if (!mounted) return;
    _ref.read(lastSubmitStatusProvider.notifier).state =
        ok ? SyncStatus.synced : SyncStatus.failed;
    if (ok) {
      // The leaderboard trigger has just upserted a (potentially new)
      // best — refresh the home-screen progression header so it shows
      // the new IQ next time the player navigates back.
      _ref.invalidate(userBestIqProvider);
    }
  }

  /// Re-runs the submit for the most recent win — surfaced as the "Retry"
  /// action on the post-game sync badge.
  Future<void> retrySubmitWin() => _runSubmitWin();

  @override
  void dispose() {
    _stopTicker();
    _digitCelebrationTimer?.cancel();
    super.dispose();
  }
}

final gameControllerProvider = StateNotifierProvider.autoDispose
    .family<GameController, GameState, ({Difficulty difficulty, int? seed})>(
  (ref, args) {
    // Compute the per-puzzle starting lives + hints from the rewarded
    // economy. Order of precedence:
    //   base 3 lives
    //   + pending boost (2 if user watched the post-loss ad)
    //   + drain from persistent bonus pool (loyalty milestone reward)
    // Capped at 5.
    final econ = ref.read(rewardedEconomyProvider.notifier);
    final boost = econ.consumeNextPuzzleBoost();
    var lives = 3 + boost.lives;
    final headroom = (kMaxPuzzleLives - lives).clamp(0, kMaxPuzzleLives);
    if (headroom > 0) {
      lives += econ.drainBonusPool(headroom);
    }
    final hintCap = (1 + boost.hints).clamp(1, kMaxPuzzleHints);
    return GameController(
      difficulty: args.difficulty,
      seed: args.seed,
      sound: ref.watch(soundServiceProvider),
      attempts: ref.watch(attemptsRepositoryProvider),
      ref: ref,
      maxLives: lives,
      hintCap: hintCap,
    );
  },
);
