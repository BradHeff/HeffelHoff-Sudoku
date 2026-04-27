# Audio assets

`SoundService` (`lib/core/audio/sound_service.dart`) looks up these filenames at runtime. Drop in matching MP3 (or OGG/WAV) files; the service degrades silently if a file is missing, so you can ship without all of them and add them incrementally.

## Required files

| Filename | Trigger | Suggested character | Length |
|---|---|---|---|
| `place_correct.mp3` | Correct digit placed | Soft positive blip / "tink" | < 200ms |
| `place_wrong.mp3` | Wrong digit placed (life lost) | Low thud / negative buzz | < 300ms |
| `structure_complete.mp3` | A row, column, or 3×3 box completed | Short ascending sparkle / chime | ~600ms |
| `digit_complete.mp3` | All 9 instances of a digit placed | Brighter chime + small fanfare | ~900ms |
| `puzzle_complete.mp3` | Puzzle solved (regular tier) | Triumphant chord progression | ~1.5–2.5s |
| `puzzle_complete_genius.mp3` | Puzzle solved **under target time** ("genius") | Extended brassy fanfare with arpeggio | ~3–4s |
| `combo_double.mp3` | Two structures complete on same placement (optional) | Same as `structure_complete` but pitched up | ~600ms |
| `combo_triple.mp3` | Three structures complete on same placement (optional) | Bigger sparkle ascending | ~700ms |

## Where to source them

Free, no-attribution-required SFX libraries that fit:

- **mixkit.co/free-sound-effects/game** — game-specific, MP3 download
- **kenney.nl/assets/category:Audio** — public domain, sets like "UI Audio" and "Casino Audio"
- **freesound.org** — Creative Commons, search for "click positive", "chime", "fanfare short"
- **zapsplat.com** — free with free account, search for "puzzle solve", "ui correct"

## Sourcing tips

- Keep volumes consistent — peak around -6 dB to leave headroom.
- 44.1 kHz / 128–192 kbps MP3 is plenty.
- The `puzzle_complete_genius.mp3` should feel **clearly** bigger than `puzzle_complete.mp3` — that's the whole point of the under-target reward.
- For `place_correct.mp3` you want something you can hear 100+ times per puzzle without fatigue. Test it on loop for 60s before committing.

## Adding more

If you want extra event sounds (e.g. `pencil_toggle.mp3`, `hint_used.mp3`), add them here, then add a corresponding `play()` call to `SoundService` and invoke from the controller.
