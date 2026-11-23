# Touchpoint 5 · Functions — where the art comes from

Every TP5 visual is built from art that is **already in the game**, so the
puzzle cards show the same objects the player sees in the room:

| What | Source | Code |
|---|---|---|
| Leo's wall safe (body, dial, T-handle, latch nubs) | `Resources/Animation/safe_open_slow.gif`, frame 0 — the 32 × 48 sprite drawn at 6× | `GameArt.safe…`, `SafeArtView` |
| The painting | `painting` (Sprites.xcassets, 32 × 48 at 10×) | `TP5PaintingReveal` |
| Jam spark | `spark` | `TP5SafeDoorStage` |

`SafeArtView` (Views/Shared/Components/GameArt.swift) animates the real parts:

- **Lock 1** — the dial spins, the T-handle pulls down.
- **Lock 2** — `flash()` lights the safe's red LED; `beep()` chirps (RetroSFX).
- **Lock 3** — the safe's own dial, close up, turning under an index mark.
- **Lock 4** — return values travel into the safe's keypad display.
- **Lock 5** — three latches on the door edge go bolted → lifted → retracted.
- **All cards** — the 5 lights on the bottom bezel are the deadbolts; they turn
  green as locks open.

After TP5 the game's `SafeRevealView` plays `safe_open_slow.gif`, so the safe
the player has been working on is the one that opens.

## Changing the art

Replace `safe_open_slow.gif` (keep the 32 × 48 grid at 6×) and every TP5 card
updates. If the layout of the safe changes, update the art-pixel rectangles at
the top of `GameArt` (dial, handle, door patch, edge row) and the offsets in
`SafeArtView`.
