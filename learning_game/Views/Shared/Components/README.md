# Shared SwiftUI components

Reusable building blocks for every touchpoint card (Figma: `DesignRefs/Cards.png`,
`DesignRefs/Typography.png`), taken from the Touchpoint 1 screens.

## Rules
- **Colors:** only `GameColor.*` (the 15-color palette in `Color.xcassets`). No `.blue`, `.gray`, hex, etc.
- **Fonts:** only `GameFont.*` — Silkscreen for titles, Play for text (fonts are in `Resources/Fonts`,
  registered automatically at runtime, no Info.plist change needed).
- **Pixel art:** use `PixelImage("spriteName")` (sets `.interpolation(.none)` for sharp pixels).
- **Layout:** cards are designed at the Figma frame size (874 × 402, card 782 × 362) and
  `GameCardOverlay` scales them to fit any screen — place things with the Figma coordinates.

## Files
| File | What's inside |
|---|---|
| `GameTheme.swift` | `GameColor`, `GameFont` (largeTitle, title, sousTitre, body, bodySm, caption…), `PixelImage` |
| `GameCard.swift` | `GameCardOverlay`, `GameCardChrome` (panel, × close, ‹ Back), `GameCardHeader` (I.R.I.S. + title), `GameCardTitle`, `GameButton` (`.primary` / `.outline` / `.secondary`) |
| `GameControls.swift` | `GameCodeBox`, `GameSlider` (drag hint, locked mode), `GameFeedbackIcon`, `GameFeedbackLine`, `GameShake` |
| `GameCodeBlocks.swift` | `GameCodeSlot`, `GameCodeBlockLabel`, `GameBlockPlaceholder`, `GameChip`, `GameCodeText` |

## Minimal card
```swift
GameCardOverlay {
    GameCardChrome(onClose: { /* hide the card */ }) {
        ZStack(alignment: .topLeading) {
            GameCardTitle(title: "Wire the Lamp", subtitle: "Plug the right type into each part.")
                .offset(x: 35, y: 24)
            // … your challenge, placed with Figma coordinates …
            GameButton(title: "Check") { /* check */ }
                .frame(maxWidth: .infinity)
                .offset(y: 317)
        }
    }
}
// Optional ‹ Back button on the card:
// .environment(\.gameBackAction, { goBack() })
```
