//
//  GameTheme.swift
//  learning_game
//
//  Shared design tokens for every touchpoint: the 15-color palette
//  (Color.xcassets), the Figma typography (Silkscreen titles, Play text)
//  and PixelImage for razor-sharp pixel art.
//

import SwiftUI
import CoreText

// MARK: - Palette

/// Only colors from Color.xcassets. Never use system colors or hex values in game views.
enum GameColor {
    static let midnight  = Color("Midnight")
    static let burgundy  = Color("Burgundy")
    static let sage      = Color("Sage")
    static let mauve     = Color("Mauve")
    static let peach     = Color("Peach")
    static let black     = Color("NeutralBlack")
    static let slateGrey = Color("SlateGrey")
    static let ashGrey   = Color("AshGrey")
    static let lightGrey = Color("LightGrey")
    static let white     = Color("NeutralWhite")
    static let error     = Color("Error")
    static let success   = Color("Success")
    static let info      = Color("Info")
    static let accent    = Color("Accent")
    static let accent2   = Color("Accent2")
}

// MARK: - Typography (Typography.png)

enum GameFont {
    /// Silkscreen — 24 Large Title, 20 Title, 18 Sous-titre.
    static func silkscreen(_ size: CGFloat) -> Font {
        registerIfNeeded()
        return .custom("Silkscreen-Regular", fixedSize: size)
    }

    /// Play — 16 Body, 14 Body Sm, 12 Caption.
    static func play(_ size: CGFloat, bold: Bool = false) -> Font {
        registerIfNeeded()
        return .custom(bold ? "Play-Bold" : "Play-Regular", fixedSize: size)
    }

    static var largeTitle: Font { silkscreen(24) }
    static var title: Font      { silkscreen(20) }
    static var sousTitre: Font  { silkscreen(18) }
    static var body: Font       { play(16) }
    static var bodyBold: Font   { play(16, bold: true) }
    static var bodySm: Font     { play(14) }
    static var bodySmBold: Font { play(14, bold: true) }
    static var caption: Font    { play(12) }
    static var captionBold: Font { play(12, bold: true) }

    /// Registers the bundled .ttf files at runtime, so no Info.plist edit is needed.
    private static let registration: Void = {
        for name in ["Silkscreen-Regular", "Play-Regular", "Play-Bold"] {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }()

    static func registerIfNeeded() { _ = registration }
}

// MARK: - Pixel art

/// Sprite from Sprites.xcassets rendered with hard pixel edges.
struct PixelImage: View {
    let name: String
    init(_ name: String) { self.name = name }

    var body: some View {
        Image(name)
            .resizable()
            .interpolation(.none)
            .scaledToFit()
    }
}
