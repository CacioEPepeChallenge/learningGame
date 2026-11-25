//
//  PixelArtGenerator.swift
//  learning_game
//
//  Renders true pixel-art sprites at runtime from a tiny pixel canvas, for the
//  pieces that have no painted PNG yet (TP5 safe parts, the laptop screen
//  states, puzzle icons). Hard edges everywhere:
//    • CGContext: shouldAntialias = false, interpolationQuality = .none
//    • SKTexture: filteringMode = .nearest
//    • SwiftUI:   Image(uiImage:).interpolation(.none)
//
//  Colours come only from Color.xcassets (single-letter palette below).
//  A painted PNG with the same name in Sprites.xcassets always wins — see
//  `PixelSpriteView`. Objects that exist in the painted art (the safe, the
//  bookshelf, the monitor) are NOT redrawn here — see GameArt.swift.
//

import SwiftUI
import SpriteKit
import UIKit

// MARK: - Palette (Color.xcassets only)

enum PixelPalette {
    /// One letter per asset colour. "." = transparent.
    static let colors: [Character: String] = [
        "k": "NeutralBlack", "t": "Twilight", "s": "SlateGrey", "a": "AshGrey",
        "l": "LightGrey", "w": "NeutralWhite", "m": "Midnight", "b": "Burgundy",
        "v": "Mauve", "p": "Peach", "i": "Info", "g": "Sage", "G": "Success",
        "r": "Error", "c": "Accent", "n": "Accent2",
    ]

    static func uiColor(_ key: Character) -> UIColor? {
        guard let name = colors[key] else { return nil }
        return UIColor(named: name)
    }
}

// MARK: - Canvas

/// A grid of palette letters you draw into with rects / circles / lines.
struct PixelCanvas {
    let width: Int
    let height: Int
    private(set) var pixels: [Character]

    init(_ width: Int, _ height: Int, fill: Character = ".") {
        self.width = width
        self.height = height
        pixels = Array(repeating: fill, count: width * height)
    }

    /// Rows of palette letters (shorter rows are padded with ".").
    init(rows: [String]) {
        let w = rows.map(\.count).max() ?? 0
        self.init(w, rows.count)
        for (y, row) in rows.enumerated() {
            for (x, ch) in row.enumerated() { set(x, y, ch) }
        }
    }

    mutating func set(_ x: Int, _ y: Int, _ c: Character) {
        guard x >= 0, y >= 0, x < width, y < height else { return }
        pixels[y * width + x] = c
    }

    func get(_ x: Int, _ y: Int) -> Character {
        guard x >= 0, y >= 0, x < width, y < height else { return "." }
        return pixels[y * width + x]
    }

    mutating func rect(_ x: Int, _ y: Int, _ w: Int, _ h: Int, _ c: Character) {
        for yy in y..<(y + h) { for xx in x..<(x + w) { set(xx, yy, c) } }
    }

    mutating func frame(_ x: Int, _ y: Int, _ w: Int, _ h: Int, _ c: Character) {
        hline(x, x + w - 1, y, c); hline(x, x + w - 1, y + h - 1, c)
        vline(x, y, y + h - 1, c); vline(x + w - 1, y, y + h - 1, c)
    }

    mutating func hline(_ x0: Int, _ x1: Int, _ y: Int, _ c: Character) {
        for x in min(x0, x1)...max(x0, x1) { set(x, y, c) }
    }

    mutating func vline(_ x: Int, _ y0: Int, _ y1: Int, _ c: Character) {
        for y in min(y0, y1)...max(y0, y1) { set(x, y, c) }
    }

    mutating func disc(_ cx: Int, _ cy: Int, _ r: Int, _ c: Character) {
        for y in (cy - r)...(cy + r) {
            for x in (cx - r)...(cx + r) where (x - cx) * (x - cx) + (y - cy) * (y - cy) <= r * r + r / 2 {
                set(x, y, c)
            }
        }
    }

    mutating func ring(_ cx: Int, _ cy: Int, _ r: Int, _ c: Character) {
        for y in (cy - r)...(cy + r) {
            for x in (cx - r)...(cx + r) {
                let d = (x - cx) * (x - cx) + (y - cy) * (y - cy)
                if d <= r * r + r / 2, d >= (r - 1) * (r - 1) + (r - 1) / 2 { set(x, y, c) }
            }
        }
    }

    /// Paste another canvas (transparent pixels skipped).
    mutating func stamp(_ other: PixelCanvas, at x: Int, _ y: Int) {
        for yy in 0..<other.height {
            for xx in 0..<other.width where other.get(xx, yy) != "." {
                set(x + xx, y + yy, other.get(xx, yy))
            }
        }
    }

    /// Swap one palette letter for another (tinting).
    func recolored(_ from: Character, _ to: Character) -> PixelCanvas {
        var copy = self
        copy.pixels = pixels.map { $0 == from ? to : $0 }
        return copy
    }
}

// MARK: - Generator

enum PixelArtGenerator {
    private static var cache: [String: UIImage] = [:]

    /// Renders a canvas with nearest-neighbour pixels (`scale` device pixels per art pixel).
    static func image(_ canvas: PixelCanvas, scale: Int = 4) -> UIImage {
        let w = canvas.width * scale, h = canvas.height * scale
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: w, height: h), format: format)
        return renderer.image { ctx in
            let cg = ctx.cgContext
            cg.setShouldAntialias(false)
            cg.setAllowsAntialiasing(false)
            cg.interpolationQuality = .none
            for y in 0..<canvas.height {
                for x in 0..<canvas.width {
                    guard let color = PixelPalette.uiColor(canvas.get(x, y)) else { continue }
                    cg.setFillColor(color.cgColor)
                    cg.fill(CGRect(x: x * scale, y: y * scale, width: scale, height: scale))
                }
            }
        }
    }

    /// Cached image for a named sprite.
    static func image(named key: String) -> UIImage? {
        if let hit = cache[key] { return hit }
        guard let canvas = PixelSprites.canvas(named: key) else { return nil }
        let img = image(canvas)
        cache[key] = img
        return img
    }

    /// SpriteKit texture with nearest filtering.
    static func texture(named key: String) -> SKTexture? {
        guard let img = image(named: key) else { return nil }
        let texture = SKTexture(image: img)
        texture.filteringMode = .nearest
        return texture
    }
}

/// SwiftUI view for a generated sprite. If a painted PNG with the same name
/// exists in Sprites.xcassets, that is shown instead.
struct PixelSpriteView: View {
    let name: String
    init(_ name: String) { self.name = name }

    var body: some View {
        if UIImage(named: name) != nil {
            PixelImage(name)
        } else if let img = PixelArtGenerator.image(named: name) {
            Image(uiImage: img)
                .resizable()
                .interpolation(.none)
                .scaledToFit()
        }
    }
}

// MARK: - Sprite library

enum PixelSprites {
    static func canvas(named key: String) -> PixelCanvas? {
        switch key {
        // Puzzle icons
        case "px_file":        return file
        case "px_lock":        return lock(open: false)
        case "px_lock_open":   return lock(open: true)
        case "px_video":       return video
        case "px_audio":       return audio
        case "px_corrupt":     return corrupt
        case "px_port":        return port
        case "px_book_red":    return book("b")
        case "px_book_green":  return book("g")
        case "px_book_blue":   return book("n")
        case "px_book_amber":  return book("i")
        case "px_keycard":     return keycard
        case "px_bolt":        return bolt
        // Laptop / monitor screen states (room)
        case "px_screen_locked":    return screen(decrypted: false)
        case "px_screen_decrypted": return screen(decrypted: true)
        default: return nil
        }
    }

    // MARK: Icons

    /// Lightning bolt (TP1 Generator Core header): gold with a peach edge.
    static let bolt = PixelCanvas(rows: [
        "......kkkk",
        ".....kpiik",
        "....kpiik.",
        "...kpiik..",
        "..kpiikkkk",
        ".kpiiiiiik",
        ".kkkkpiik.",
        "....kpik..",
        "...kpik...",
        "...kik....",
        "..kik.....",
        "..kk......",
    ])

    static let file = PixelCanvas(rows: [
        "kkkkkkk...",
        "klllllkk..",
        "klllllklk.",
        "klllllkkkk",
        "klaaaaallk",
        "kllllllllk",
        "klaaaaaalk",
        "kllllllllk",
        "klaaaalllk",
        "kllllllllk",
        "kkkkkkkkkk",
    ])

    static func lock(open: Bool) -> PixelCanvas {
        PixelCanvas(rows: [
            "..kkk..",
            ".k...k.",
            open ? ".k....." : ".k...k.",
            "kkkkkkk",
            open ? "kGGGGGk" : "kiiiiik",
            open ? "kGGkGGk" : "kiikiik",
            open ? "kGGGGGk" : "kiiiiik",
            "kkkkkkk",
        ])
    }

    static let video = PixelCanvas(rows: [
        "kkkkkkkk....",
        "knnnnnnk..kk",
        "knccnnnk.kck",
        "kncwcnnkkcck",
        "knccnnnkkcck",
        "knnnnnnk.kck",
        "knnnnnnk..kk",
        "kkkkkkkk....",
    ])

    static let audio = PixelCanvas(rows: [
        "......v.....",
        "...v..v.v...",
        ".v.v.vv.v.v.",
        "vvvvvvvvvvvv",
        ".v.v.vv.v.v.",
        "...v..v.v...",
        "......v.....",
    ])

    static let corrupt = PixelCanvas(rows: [
        "kkkkkkk...",
        "krrlrrkk..",
        "klrrlrkrk.",
        "krlrrlkkkk",
        "krrlrrrlrk",
        "klrrlrlrrk",
        "kkkkkkkkkk",
    ])

    static let port = PixelCanvas(rows: [
        "kkkkkkkkkkkk",
        "kaaaaaaaaaak",
        "kakkkkkkkkak",
        "kaklklklklak",
        "kakkkkkkkkak",
        "kaaaaaaaaaak",
        "kaGaaaaaarak",
        "kkkkkkkkkkkk",
    ])

    static let keycard = PixelCanvas(rows: [
        "kkkkkkkkkkkk",
        "kccccccccclk",
        "kciiicccccck",
        "kciiicnnnnck",
        "kccccccccclk",
        "kcnnnnnnnnck",
        "kkkkkkkkkkkk",
    ])

    static func book(_ color: Character) -> PixelCanvas {
        PixelCanvas(rows: [
            "kkkkkk",
            "kXXXXk",
            "kXiiXk",
            "kXXXXk",
            "kXXXXk",
            "kXXXXk",
            "kXXXXk",
            "kXiiXk",
            "kXXXXk",
            "kkkkkk",
        ]).recolored("X", color)
    }

    // MARK: Monitor screen (laptop locked / decrypted)

    /// The PC's screen in the room, at the room art's own pixel size (63 × 40,
    /// exactly the painted screen area) and in the monitor's own style
    /// (navy screen, lavender window frame — see computer2.png).
    static func screen(decrypted: Bool) -> PixelCanvas {
        var c = PixelCanvas(63, 40, fill: "n")
        // Window: frame + title bar, like the window drawn on computer2.png.
        c.frame(5, 4, 53, 32, "a")
        c.hline(6, 56, 7, "a")
        c.rect(6, 5, 51, 2, "s")
        c.rect(52, 5, 2, 2, decrypted ? "G" : "r")
        c.rect(48, 5, 2, 2, "a")
        if decrypted {
            // Decrypted readout: log lines, the isolated final log highlighted.
            let lines: [(Int, Character)] = [(30, "G"), (18, "G"), (36, "G"), (24, "G"), (40, "c")]
            for (i, line) in lines.enumerated() {
                let y = 11 + i * 4
                c.set(9, y, "l")
                c.hline(12, 12 + line.0, y, line.1)
                if line.1 == "c" { c.rect(12 + line.0 + 2, y - 1, 2, 3, "w") }   // cursor
            }
        } else {
            // Encrypted: padlock and scrambled red data.
            let lockArt = PixelCanvas(rows: [
                "..kkkkk..",
                ".k.....k.",
                ".k.....k.",
                ".k.....k.",
                "kkkkkkkkk",
                "krrrrrrrk",
                "krrrkrrrk",
                "krrrkrrrk",
                "krrrrrrrk",
                "kkkkkkkkk",
            ]).recolored(".", ".")
            c.stamp(lockArt, at: 27, 10)
            for (i, x) in [9, 15, 22, 30, 36, 43, 49].enumerated() {
                c.hline(x, x + (i % 2 == 0 ? 3 : 2), 25, "r")
                c.hline(x + 1, x + 4, 28, "b")
                c.hline(x, x + 1, 31, "r")
            }
        }
        return c
    }
}
