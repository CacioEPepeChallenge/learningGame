//
//  GameArt.swift
//  learning_game
//
//  Slices of the game's own painted pixel art, so puzzle visuals show the exact
//  objects the player sees in the room — not separate stand-ins:
//
//    • Leo's wall safe  — safe_open_slow.gif, frame 0 (32 × 48 art px, drawn at 6×)
//    • the bookshelf    — background_light (874 × 402 room art)
//    • the PC monitor   — computer2.png
//
//  Every slice is drawn with nearest-neighbour scaling (`ArtImage`).
//

import SwiftUI
import UIKit
import ImageIO

enum GameArt {
    private static var frames: [String: [CGImage]] = [:]
    private static var crops: [String: CGImage] = [:]

    /// All frames of a GIF in the app bundle.
    static func gifFrames(_ name: String) -> [CGImage] {
        if let hit = frames[name] { return hit }
        guard let url = Bundle.main.url(forResource: name, withExtension: "gif"),
              let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return [] }
        let all = (0..<CGImageSourceGetCount(source)).compactMap { CGImageSourceCreateImageAtIndex(source, $0, nil) }
        frames[name] = all
        return all
    }

    private static func cached(_ key: String, _ make: () -> CGImage?) -> CGImage? {
        if let hit = crops[key] { return hit }
        guard let image = make() else { return nil }
        crops[key] = image
        return image
    }

    // MARK: Leo's safe (safe_open_slow.gif is the 32 × 48 art at 6×)

    private static let safeGIFScale: CGFloat = 6
    /// The safe body inside the 32 × 48 art: x 4…29, y 7…40.
    static let safeBodyRect = CGRect(x: 4, y: 7, width: 26, height: 34)

    /// A rectangle of the closed safe, in art pixels of the 32 × 48 sprite.
    static func safe(_ artRect: CGRect, frame: Int = 0) -> CGImage? {
        cached("safe\(frame)\(artRect)") {
            let all = gifFrames("safe_open_slow")
            guard all.indices.contains(frame) else { return nil }
            let s = safeGIFScale
            return all[frame].cropping(to: CGRect(x: artRect.minX * s, y: artRect.minY * s,
                                                  width: artRect.width * s, height: artRect.height * s))
        }
    }

    static var safeBody: CGImage? { safe(safeBodyRect) }
    static var safeBodyOpen: CGImage? { safe(safeBodyRect, frame: max(0, gifFrames("safe_open_slow").count - 1)) }
    /// The combination dial (9 × 9 art px, centre = art (15, 21)).
    static var safeDial: CGImage? { safe(CGRect(x: 11, y: 17, width: 9, height: 9)) }
    /// The T-handle: stem + brass plate (9 × 7 art px).
    static var safeHandle: CGImage? { safe(CGRect(x: 11, y: 26, width: 9, height: 7)) }
    /// A plain strip of door surface, used to patch behind moving parts.
    static var safeDoorPatch: CGImage? { safe(CGRect(x: 21, y: 13, width: 1, height: 1)) }
    /// One clean row of the door's right edge + frame (door edge, frame, frame shade).
    static var safeEdgeRow: CGImage? { safe(CGRect(x: 25, y: 13, width: 3, height: 1)) }

    // MARK: Room objects

    /// A rectangle of the lit room background (874 × 402 art).
    static func room(_ rect: CGRect) -> CGImage? {
        cached("room\(rect)") {
            UIImage(named: "background_light")?.cgImage?.cropping(to: rect)
        }
    }

    /// Leo's bookshelf as painted in the room.
    static var bookshelf: CGImage? { room(CGRect(x: 452, y: 104, width: 98, height: 153)) }

    /// The PC monitor (computer2.png, 555 × 508).
    static var monitor: CGImage? { UIImage(named: "computer2")?.cgImage }
    /// The monitor's screen inside computer2.png.
    static let monitorScreen = CGRect(x: 48, y: 62, width: 455, height: 266)
    static let monitorSize = CGSize(width: 555, height: 508)
}

/// A slice of painted art, scaled with hard pixel edges.
struct ArtImage: View {
    let image: CGImage?
    init(_ image: CGImage?) { self.image = image }

    var body: some View {
        if let image {
            Image(decorative: image, scale: 1)
                .resizable()
                .interpolation(.none)
        } else {
            Color.clear
        }
    }
}

// MARK: - Leo's safe, with working parts

/// The game's safe sprite, drawn at `unit` points per art pixel (26 × 34 art px),
/// with its real parts animated on top:
///   • dial        — turns in quarter steps
///   • T-handle    — pulls down
///   • red LED     — flashes
///   • 5 deadbolt LEDs on the bottom bezel (red → green)
///   • 3 latches on the door edge (bolted → lifted → retracted)
struct SafeArtView: View {
    var unit: CGFloat = 4
    var dialQuarterTurns = 0
    var handlePulled = false
    var ledOn = false
    /// Deadbolt lights, left to right.
    var bolts: [Bool] = Array(repeating: false, count: 5)
    /// nil = the art's own two latch nubs; otherwise draw three working latches.
    var latches: [LatchState]? = nil
    var activeLatch: Int? = nil
    var jammedLatch: Int? = nil
    var showOpenDoor = false

    private var u: CGFloat { unit }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ArtImage(showOpenDoor ? GameArt.safeBodyOpen : GameArt.safeBody)
                .frame(width: 26 * u, height: 34 * u)

            if !showOpenDoor {
                // Dial (centre art (15,21) → body (11,14)). The art is symmetric, so each
                // turn spins 1¼ times — you see it turn, and it lands pixel-aligned.
                ArtImage(GameArt.safeDial)
                    .frame(width: 9 * u, height: 9 * u)
                    .rotationEffect(.degrees(Double(dialQuarterTurns) * 450))
                    .animation(.easeInOut(duration: 0.6), value: dialQuarterTurns)
                    .offset(x: 7 * u, y: 10 * u)

                // T-handle: patch the door behind it, then slide it down when pulled.
                if handlePulled {
                    ArtImage(GameArt.safeDoorPatch)
                        .frame(width: 9 * u, height: 2 * u)
                        .offset(x: 7 * u, y: 19 * u)
                }
                ArtImage(GameArt.safeHandle)
                    .frame(width: 9 * u, height: 7 * u)
                    .offset(x: 7 * u, y: (19 + (handlePulled ? 1.5 : 0)) * u)
                    .animation(.spring(duration: 0.35, bounce: 0.45), value: handlePulled)

                // Status LED above the dial (art (15,16) → body (11,9)).
                Rectangle()
                    .fill(GameColor.peach)
                    .frame(width: u, height: u)
                    .shadow(color: GameColor.error, radius: ledOn ? 3 * u : 0)
                    .shadow(color: GameColor.peach.opacity(0.8), radius: ledOn ? u : 0)
                    .opacity(ledOn ? 1 : 0)
                    .offset(x: 11 * u, y: 9 * u)
                    .animation(.easeOut(duration: 0.08), value: ledOn)

                if let latches { latchLayer(latches) }
            }

            // Deadbolt lights on the bottom bezel (body row 30).
            ForEach(0..<5, id: \.self) { i in
                let on = bolts.indices.contains(i) && bolts[i]
                Rectangle()
                    .fill(on ? GameColor.success : GameColor.error)
                    .frame(width: 2 * u, height: u)
                    .shadow(color: (on ? GameColor.success : GameColor.error).opacity(0.9), radius: on ? 1.5 * u : 0.6 * u)
                    .offset(x: (3 + CGFloat(i) * 4) * u, y: 30 * u)
                    .animation(.spring(duration: 0.4, bounce: 0.5), value: on)
            }
        }
        .frame(width: 26 * u, height: 34 * u, alignment: .topLeading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Leo's safe. \(bolts.filter { $0 }.count) of 5 deadbolts open.")
    }

    /// Three latches on the door's right edge (body rows 8, 15.5, 23).
    @ViewBuilder
    private func latchLayer(_ states: [LatchState]) -> some View {
        let rows: [CGFloat] = [8, 15.5, 23]
        ForEach(0..<min(3, states.count), id: \.self) { i in
            // Cover the painted nub, so only our working latch shows.
            ArtImage(GameArt.safeEdgeRow)
                .frame(width: 3 * u, height: 2 * u)
                .offset(x: 21 * u, y: rows[i] * u)
            latch(states[i], index: i + 1)
                .offset(y: rows[i] * u)
        }
    }

    private func latch(_ state: LatchState, index: Int) -> some View {
        // Bolted: reaches into the frame. Open: retracted into the door.
        let x: CGFloat = state == .open ? 17.5 : 20
        let indicator: Color = switch state {
        case .locked: GameColor.error
        case .unlatched: GameColor.info
        case .open: GameColor.success
        }
        return HStack(spacing: 0) {
            Rectangle().fill(indicator).frame(width: u, height: 2 * u)
            Rectangle().fill(GameColor.ashGrey).frame(width: 3 * u, height: 2 * u)
        }
        .overlay(Rectangle().strokeBorder(GameColor.black, lineWidth: max(1, u * 0.35)))
        .offset(x: x * u, y: state == .unlatched ? -0.5 * u : 0)
        .shadow(color: GameColor.accent.opacity(activeLatch == index ? 0.9 : 0), radius: 2 * u)
        .modifier(GameShake(amount: u, animatableData: jammedLatch == index ? 2 : 0))
        .animation(.spring(duration: 0.4, bounce: 0.3), value: state)
        .animation(.linear(duration: 0.4), value: jammedLatch)
    }
}
