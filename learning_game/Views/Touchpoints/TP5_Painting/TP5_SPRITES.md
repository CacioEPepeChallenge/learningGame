# Touchpoint 5 · Functions — sprite list

Drop each PNG into `Resources/Assets/Sprites.xcassets` with **exactly this name**.
Until it exists, the game draws a vector stand-in inside a dashed outline with the
name printed on it (debug builds only), so you can see where each sprite goes.

Pixel art is scaled with nearest-neighbour, so draw at a small size (e.g. 1× = the
point size below ÷ 2) and keep the aspect ratio. Transparent background.

**Animated sprites:** add frames `name_1`, `name_2`, … instead of `name`.
(The code currently animates by rotating/sliding the single sprite; frames are
optional extras.)

## Intro card — the painting

| Asset | Size (pt) | What to draw |
|---|---|---|
| `painting` | 128 × 192 | ✅ already exists |
| `tp5_safe_closed` | 132 × 160 | Wall safe front, closed, with **5 small red bolt lights** along the bottom. Revealed when the player slides the painting. |

## Lock 1 · Define, then call

| Asset | Size (pt) | What to draw |
|---|---|---|
| `tp5_safe_door` | 104 × 116 | Close-up of the safe door (background plate, no dial/lever). |
| `tp5_safe_dial` | 48 × 48 | Round combination dial, top-down. **Rotates in code**, so draw it centered and symmetric. |
| `tp5_safe_lever` | 14 × 52 | Vertical lever / handle. **Rotates around its top end** (pivot at the top). |
| `tp5_safe_bolt` | 40 × 10 | Horizontal steel deadbolt bar. Slides right when the lock opens. |
| `spark` | 30 × 30 | ✅ already exists (shown when the lever jams) |

## Lock 2 · Trace the calls

| Asset | Size (pt) | What to draw |
|---|---|---|
| `lamp_on` / `lamp_off` | 52 × 52 | ✅ already exist (the `flash()` signal) |
| `tp5_speaker` | 34 × 34 | Small retro speaker / buzzer (the `beep()` signal). Pulses + ring wave in code. Optional frames `tp5_speaker_1…n` for a vibrating cone. |

## Lock 3 · Pass the arguments

| Asset | Size (pt) | What to draw |
|---|---|---|
| `tp5_clue_note` | 112 × 28 | Torn sticky note / paper strip (Leo's handwriting). **Leave it blank**: the digits `7 · 3 · 8` are drawn on top in code so they can turn green/red. |
| `tp5_dial_face` | 100 × 100 | Big dial face with numbers **0–9 clockwise, 0 at the top**, 36° apart (the needle math depends on that layout). |
| `tp5_dial_needle` | 4 × 36 | Thin needle pointing **up**, pivot at its bottom end. Rotates in code. |

## Lock 4 · Return the key

| Asset | Size (pt) | What to draw |
|---|---|---|
| `tp5_machine_double` | 88 × 28 | Little machine / pipe module for `double`. The function name is drawn on top in code, so leave space in the middle. |
| `tp5_machine_addThree` | 88 × 28 | Same family, different colour/icon, for `addThree`. |
| `tp5_machine_square` | 88 × 28 | Same family, for `square`. |
| `tp5_keypad` | 88 × 18 | Small LCD keypad display strip (the result `22 / 22` is drawn on top). |

## Lock 5 · Write it once

| Asset | Size (pt) | What to draw |
|---|---|---|
| `tp5_latch_frame` | 96 × 24 | Horizontal latch housing / rail (the bar slides inside it). |
| `tp5_latch_bar` | 44 × 10 | The latch bar itself. Tinted by state in the fallback (burgundy locked → amber unlatched → green open); with a sprite, consider a neutral metal bar. |

## Finale

| Asset | Size (pt) | What to draw |
|---|---|---|
| `painting_safe.gif` | 128 × 192 | ✅ already exists (painting slides away, safe opens) |

## Nice-to-have (not wired yet)

- `iris_happy`, `iris_alert`: I.R.I.S. reaction faces, to swap with `iris` on the lesson/feedback lines.
- `tp5_lock_closed` / `tp5_lock_open` (20 × 20): could replace the numbered lock dots.
