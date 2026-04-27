#!/usr/bin/env python3
"""Synthesize placeholder SFX into assets/audio/ as 16-bit mono WAVs.

Standalone, stdlib-only. Run with `python3 tools/synth_sounds.py`. Replace
any of the resulting files with real (mp3/wav) audio whenever it's
ready — SoundService will pick whichever exists at the named asset path.
"""

from __future__ import annotations

import math
import os
import struct
import wave
from dataclasses import dataclass

SAMPLE_RATE = 44100
ASSETS_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")

# ---------- helpers ----------

def _envelope(t: float, total: float, attack: float = 0.005, release: float = 0.06) -> float:
    """ADSR-style envelope. Quick attack, hold, exponential release."""
    if t < attack:
        return t / attack
    if t > total - release:
        x = (total - t) / release
        return max(0.0, x) ** 1.5
    return 1.0


def _sine(t: float, freq: float) -> float:
    return math.sin(2 * math.pi * freq * t)


def _square(t: float, freq: float) -> float:
    return 1.0 if (math.sin(2 * math.pi * freq * t) >= 0) else -1.0


def _saw(t: float, freq: float) -> float:
    return 2.0 * (t * freq - math.floor(0.5 + t * freq))


@dataclass
class Note:
    freq: float
    start: float        # seconds
    duration: float     # seconds
    amplitude: float = 0.55
    waveform: str = "sine"  # sine | square | saw


def render_notes(notes: list[Note], total_duration: float, peak: float = 0.85) -> bytes:
    """Mix notes into PCM int16 bytes, apply soft compressor at peak."""
    n_samples = int(total_duration * SAMPLE_RATE)
    buf = [0.0] * n_samples
    for note in notes:
        s0 = int(note.start * SAMPLE_RATE)
        n = int(note.duration * SAMPLE_RATE)
        for i in range(n):
            t_local = i / SAMPLE_RATE
            t_abs = (s0 + i) / SAMPLE_RATE
            env = _envelope(t_local, note.duration)
            wave_fn = {"sine": _sine, "square": _square, "saw": _saw}[note.waveform]
            sample = wave_fn(t_abs, note.freq) * env * note.amplitude
            idx = s0 + i
            if 0 <= idx < n_samples:
                buf[idx] += sample
    # Soft clip / normalise
    max_abs = max((abs(x) for x in buf), default=0) or 1.0
    target = peak / max(1.0, max_abs)
    out = bytearray()
    for x in buf:
        v = max(-1.0, min(1.0, x * target))
        out.extend(struct.pack("<h", int(v * 32767)))
    return bytes(out)


def write_wav(path: str, pcm: bytes) -> None:
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)
        w.writeframes(pcm)


def hz(midi: int) -> float:
    """MIDI note number → Hz. A4 (69) = 440Hz."""
    return 440.0 * (2 ** ((midi - 69) / 12.0))


# ---------- effect definitions ----------

def place_correct() -> tuple[bytes, float]:
    # Short rising blip C5 → E5
    dur = 0.12
    notes = [
        Note(hz(72), 0.00, 0.04, amplitude=0.6),  # C5
        Note(hz(76), 0.04, 0.08, amplitude=0.7),  # E5
    ]
    return render_notes(notes, dur), dur


def place_wrong() -> tuple[bytes, float]:
    # Short descending thud E4 → C4 (square wave for grit)
    dur = 0.18
    notes = [
        Note(hz(64), 0.00, 0.06, amplitude=0.55, waveform="square"),
        Note(hz(60), 0.06, 0.12, amplitude=0.55, waveform="square"),
        Note(hz(48), 0.06, 0.12, amplitude=0.30, waveform="sine"),
    ]
    return render_notes(notes, dur), dur


def structure_complete() -> tuple[bytes, float]:
    # Ascending major arpeggio C5-E5-G5
    dur = 0.5
    notes = [
        Note(hz(72), 0.00, 0.12),
        Note(hz(76), 0.12, 0.14),
        Note(hz(79), 0.26, 0.24, amplitude=0.7),
    ]
    return render_notes(notes, dur), dur


def digit_complete() -> tuple[bytes, float]:
    # Bigger arpeggio C5-E5-G5-C6 + sparkle
    dur = 0.85
    notes = [
        Note(hz(72), 0.00, 0.12),
        Note(hz(76), 0.10, 0.12),
        Note(hz(79), 0.20, 0.14),
        Note(hz(84), 0.34, 0.50, amplitude=0.75),
        # Sparkle high-octave shimmer overlaid
        Note(hz(96), 0.50, 0.20, amplitude=0.30),
        Note(hz(91), 0.55, 0.20, amplitude=0.30),
    ]
    return render_notes(notes, dur), dur


def puzzle_complete() -> tuple[bytes, float]:
    # Triumphant C major chord progression
    dur = 1.6
    notes = [
        # First chord — C major
        Note(hz(72), 0.00, 0.45),  # C5
        Note(hz(76), 0.00, 0.45),  # E5
        Note(hz(79), 0.00, 0.45),  # G5
        # Second — F major
        Note(hz(77), 0.45, 0.40),  # F5
        Note(hz(81), 0.45, 0.40),  # A5
        Note(hz(72), 0.45, 0.40),  # C5
        # Final — C major octave-up
        Note(hz(84), 0.85, 0.75, amplitude=0.7),  # C6
        Note(hz(76), 0.85, 0.75, amplitude=0.6),  # E5
        Note(hz(79), 0.85, 0.75, amplitude=0.6),  # G5
    ]
    return render_notes(notes, dur), dur


def puzzle_complete_genius() -> tuple[bytes, float]:
    # Extended brassy fanfare with ascending arpeggio + final big chord
    dur = 3.4
    notes = [
        # Fanfare lead-in (saw waves for brassy feel)
        Note(hz(67), 0.00, 0.18, amplitude=0.5, waveform="saw"),  # G4
        Note(hz(72), 0.18, 0.18, amplitude=0.5, waveform="saw"),  # C5
        Note(hz(76), 0.36, 0.18, amplitude=0.5, waveform="saw"),  # E5
        Note(hz(79), 0.54, 0.18, amplitude=0.5, waveform="saw"),  # G5
        # Quick arpeggio sparkle
        Note(hz(84), 0.72, 0.10),  # C6
        Note(hz(88), 0.82, 0.10),  # E6
        Note(hz(91), 0.92, 0.10),  # G6
        # Sustained C major chord (3 octaves)
        Note(hz(60), 1.05, 1.5, amplitude=0.55),  # C4
        Note(hz(72), 1.05, 1.5, amplitude=0.55),  # C5
        Note(hz(76), 1.05, 1.5, amplitude=0.55),  # E5
        Note(hz(79), 1.05, 1.5, amplitude=0.55),  # G5
        Note(hz(84), 1.05, 1.5, amplitude=0.55),  # C6
        # Final ringing top note
        Note(hz(96), 1.10, 2.20, amplitude=0.45),  # C7
        # Sparkle layer
        Note(hz(100), 2.0, 0.6, amplitude=0.25),
        Note(hz(103), 2.5, 0.6, amplitude=0.25),
    ]
    return render_notes(notes, dur, peak=0.9), dur


def combo_double() -> tuple[bytes, float]:
    # Same as structure_complete but pitched up a 4th
    dur = 0.5
    notes = [
        Note(hz(77), 0.00, 0.12),  # F5
        Note(hz(81), 0.12, 0.14),  # A5
        Note(hz(84), 0.26, 0.24, amplitude=0.7),  # C6
    ]
    return render_notes(notes, dur), dur


def combo_triple() -> tuple[bytes, float]:
    # Bigger ascending sparkle
    dur = 0.7
    notes = [
        Note(hz(72), 0.00, 0.10),  # C5
        Note(hz(76), 0.10, 0.10),  # E5
        Note(hz(79), 0.20, 0.10),  # G5
        Note(hz(84), 0.30, 0.10),  # C6
        Note(hz(88), 0.40, 0.30, amplitude=0.75),  # E6
    ]
    return render_notes(notes, dur), dur


# ---------- main ----------

EVENTS = {
    "place_correct.wav": place_correct,
    "place_wrong.wav": place_wrong,
    "structure_complete.wav": structure_complete,
    "digit_complete.wav": digit_complete,
    "puzzle_complete.wav": puzzle_complete,
    "puzzle_complete_genius.wav": puzzle_complete_genius,
    "combo_double.wav": combo_double,
    "combo_triple.wav": combo_triple,
}


def main() -> None:
    os.makedirs(ASSETS_DIR, exist_ok=True)
    for name, fn in EVENTS.items():
        pcm, dur = fn()
        path = os.path.join(ASSETS_DIR, name)
        write_wav(path, pcm)
        size_kb = os.path.getsize(path) / 1024
        print(f"{name:36s} {dur:5.2f}s  {size_kb:6.1f} KB")


if __name__ == "__main__":
    main()
