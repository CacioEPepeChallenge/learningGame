//
//  TP5Stages.swift
//  learning_game
//
//  The visual on the left of each Touchpoint 5 card. Every lock works on the
//  SAME object the player found behind the painting: Leo's wall safe, drawn
//  from the game's own sprite (safe_open_slow.gif) via SafeArtView.
//
//    Intro   · slide the painting (same 32 × 48 scale as the safe) to reveal it
//    Lock 1  · disengage(): the dial turns, the T-handle pulls
//    Lock 2  · signals: flash() lights the safe's red LED, beep() chirps
//    Lock 3  · the safe's own dial, close up, turning to 7 · 3 · 8
//    Lock 4  · return values flow into the safe's keypad display
//    Lock 5  · the three latches on the door edge retract one by one
//
//  The 5 lights on the safe's bottom bezel are the five deadbolts: they turn
//  green as each lock is solved, on every card.
//

import SwiftUI

private func boltLights(_ opened: Set<Int>) -> [Bool] { (1...5).map(opened.contains) }

// MARK: - Intro · slide the painting off the safe

struct TP5PaintingReveal: View {
    let isMoved: Bool
    let onMove: () -> Void

    @State private var drag: CGFloat = 0
    @State private var hintPulse = false

    /// Painting and safe share the 32 × 48 art grid; 4 pt per art pixel.
    private let u: CGFloat = 4

    var body: some View {
        ZStack(alignment: .topLeading) {
            SafeArtView(unit: u)
                .offset(x: 4 * u, y: 7 * u)

            // The painting slides left off the safe, like painting_safe.gif.
            PixelImage("painting")
                .frame(width: 32 * u, height: 48 * u)
                .shadow(color: GameColor.black.opacity(0.6), radius: 6, x: 3, y: 4)
                .offset(x: isMoved ? -29 * u : drag)
                .gesture(
                    DragGesture()
                        .onChanged { drag = min(0, $0.translation.width) }
                        .onEnded { value in
                            if value.translation.width < -40 {
                                withAnimation(.easeInOut(duration: 0.7)) { onMove() }
                            }
                            withAnimation(.spring(duration: 0.4)) { drag = 0 }
                        }
                )
                .onTapGesture { withAnimation(.easeInOut(duration: 0.7)) { onMove() } }
                .accessibilityLabel(isMoved ? "Painting, moved aside" : "Painting. Slide it aside")
                .accessibilityAddTraits(.isButton)

            if !isMoved {
                Text("‹ SLIDE THE PAINTING")
                    .font(GameFont.silkscreen(9))
                    .foregroundStyle(GameColor.info)
                    .opacity(hintPulse ? 1 : 0.35)
                    .frame(width: 32 * u)
                    .offset(y: 48 * u + 6)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { hintPulse = true }
                    }
            }
        }
        .frame(width: 32 * u, height: 48 * u + 20, alignment: .topLeading)
        .padding(.leading, 116)
        .frame(width: 250, height: 210, alignment: .topLeading)
    }
}

// MARK: - Lock 1 · dial + handle

struct TP5SafeDoorStage: View {
    let dialTurns: Int
    let leverPulled: Bool
    let boltOpen: Bool
    let jammed: Bool
    var opened: Set<Int> = []

    @State private var sparkOn = false

    var body: some View {
        TP5StageFrame(glow: boltOpen ? GameColor.success : jammed ? GameColor.error : nil) {
            VStack(spacing: 6) {
                ZStack(alignment: .topLeading) {
                    SafeArtView(unit: 3.7,
                                dialQuarterTurns: dialTurns,
                                handlePulled: leverPulled || jammed,
                                bolts: boltLights(boltOpen ? opened.union([1]) : opened))
                    if jammed {
                        PixelImage("spark")
                            .frame(width: 28, height: 28)
                            .opacity(sparkOn ? 1 : 0.3)
                            .offset(x: 30, y: 70)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 0.12).repeatCount(8, autoreverses: true)) { sparkOn = true }
                            }
                            .transition(.opacity)
                    }
                }
                Text(boltOpen ? "DEADBOLT 1 OPEN" : jammed ? "HANDLE JAMMED" : "LOCKED")
                    .font(GameFont.silkscreen(8))
                    .foregroundStyle(boltOpen ? GameColor.success : jammed ? GameColor.error : GameColor.ashGrey)
            }
            .padding(.top, 6)
        }
    }
}

// MARK: - Lock 2 · the safe's LED and buzzer

struct TP5SignalStage: View {
    let lampOn: Bool
    let beepCount: Int
    let emitted: [P2Signal]
    var opened: Set<Int> = []

    var body: some View {
        TP5StageFrame {
            VStack(spacing: 5) {
                ZStack {
                    // beep(): a sound ring from the safe.
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(GameColor.accent, lineWidth: 2)
                        .frame(width: 84, height: 108)
                        .keyframeAnimator(initialValue: Ring(), trigger: beepCount) { ring, v in
                            ring.scaleEffect(v.scale).opacity(v.opacity)
                        } keyframes: { _ in
                            KeyframeTrack(\.scale) {
                                LinearKeyframe(0.95, duration: 0.01)
                                LinearKeyframe(1.3, duration: 0.45)
                            }
                            KeyframeTrack(\.opacity) {
                                LinearKeyframe(0.9, duration: 0.01)
                                LinearKeyframe(0, duration: 0.45)
                            }
                        }
                    SafeArtView(unit: 3.1, ledOn: lampOn, bolts: boltLights(opened))
                        .keyframeAnimator(initialValue: 0.0, trigger: beepCount) { safe, x in
                            safe.offset(x: x)
                        } keyframes: { _ in
                            LinearKeyframe(1.5, duration: 0.04)
                            LinearKeyframe(-1.5, duration: 0.04)
                            LinearKeyframe(0, duration: 0.04)
                        }
                }
                .frame(height: 108)
                .padding(.top, 6)

                Text("SIGNALS SENT")
                    .font(GameFont.silkscreen(7))
                    .foregroundStyle(GameColor.ashGrey)

                HStack(spacing: 3) {
                    ForEach(Array(emitted.enumerated()), id: \.offset) { _, s in
                        TP5SignalChip(signal: s, compact: true)
                            .transition(.scale(scale: 0.5).combined(with: .opacity))
                    }
                }
                .frame(height: 18)
                .animation(.spring(duration: 0.3, bounce: 0.4), value: emitted.count)
                Spacer(minLength: 0)
            }
        }
        .onChange(of: beepCount) { RetroSFX.shared.playBlip() }
    }

    private struct Ring {
        var scale = 1.3
        var opacity = 0.0
    }
}

/// flash = the safe's red LED, beep = a sound wave.
struct TP5SignalChip: View {
    let signal: P2Signal
    var compact = false

    var body: some View {
        HStack(spacing: 3) {
            if signal == .flash {
                Rectangle()
                    .fill(GameColor.peach)
                    .frame(width: 5, height: 5)
                    .shadow(color: GameColor.error, radius: 3)
                    .frame(width: 12, height: 12)
            } else {
                PixelSpriteView("px_audio").frame(width: 14, height: 9)
            }
            if !compact {
                Text(signal.rawValue)
                    .font(GameFont.play(12))
                    .foregroundStyle(GameColor.white)
            }
        }
        .padding(.horizontal, compact ? 2 : 4)
        .frame(width: compact ? 20 : nil, height: compact ? 18 : 24)
        .background(RoundedRectangle(cornerRadius: 3).fill(signal == .flash ? GameColor.burgundy.opacity(0.6) : GameColor.accent2.opacity(0.8)))
    }
}

// MARK: - Lock 3 · the safe's dial, close up

struct TP5DialStage: View {
    let needleAngle: Double
    let reading: Int
    let results: [Bool?]

    private let size: CGFloat = 64

    var body: some View {
        TP5StageFrame(glow: results.allSatisfy { $0 == true } ? GameColor.success
                      : results.contains(false) ? GameColor.error : nil) {
            VStack(spacing: 5) {
                // Leo's note from the back of the painting.
                HStack(spacing: 5) {
                    ForEach(0..<3, id: \.self) { i in
                        Text("\(P3Engine.combination[i])")
                            .font(GameFont.silkscreen(13))
                            .foregroundStyle(results[i] == true ? GameColor.success
                                             : results[i] == false ? GameColor.error : GameColor.black)
                        if i < 2 { Text("·").font(GameFont.play(13)).foregroundStyle(GameColor.black) }
                    }
                }
                .frame(width: 104, height: 22)
                .background(RoundedRectangle(cornerRadius: 1).fill(GameColor.peach))
                .rotationEffect(.degrees(-2))
                .padding(.top, 5)

                ZStack {
                    // The real dial turns under a fixed index mark.
                    ZStack {
                        ArtImage(GameArt.safeDial)
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                        ForEach(0..<10, id: \.self) { i in
                            // Numbers ride on the dial but stay upright.
                            Text("\(i)")
                                .font(GameFont.play(10, bold: true))
                                .foregroundStyle(GameColor.lightGrey)
                                .rotationEffect(.degrees(needleAngle - Double(i) * 36))
                                .offset(y: -(size / 2 + 9))
                                .rotationEffect(.degrees(Double(i) * 36))
                        }
                    }
                    .rotationEffect(.degrees(-needleAngle))
                    .animation(.spring(duration: 0.22, bounce: 0.2), value: needleAngle)

                    // Index mark, fixed at the top.
                    IndexMark()
                        .fill(GameColor.error)
                        .frame(width: 10, height: 7)
                        .offset(y: -(size / 2 + 20))
                }
                .frame(width: 120, height: 112)

                Text("READING \(reading)")
                    .font(GameFont.silkscreen(9))
                    .foregroundStyle(GameColor.accent)
                    .contentTransition(.numericText(value: Double(reading)))
                    .animation(.snappy, value: reading)
                Spacer(minLength: 0)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Dial reads \(reading). Combination 7, 3, 8.")
    }

    private struct IndexMark: Shape {
        func path(in r: CGRect) -> Path {
            Path { p in
                p.move(to: CGPoint(x: r.minX, y: r.minY))
                p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
                p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
                p.closeSubpath()
            }
        }
    }
}

// MARK: - Lock 4 · return values → the safe's keypad

struct TP5MachineStage: View {
    /// Inner → outer.
    let pipeline: [P4Function?]
    let activeMachine: Int?
    let orbValue: Int
    let orbPosition: Int
    let keypad: Int?

    private let rowY: [CGFloat] = [24, 54, 84]
    private let orbY: [CGFloat] = [6, 42, 72, 124]

    var body: some View {
        TP5StageFrame(glow: keypad.map { $0 == P4Engine.target ? GameColor.success : GameColor.error }) {
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(GameColor.slateGrey)
                    .frame(width: 2, height: 124)
                    .offset(x: 21, y: 10)

                Text("4 IN")
                    .font(GameFont.silkscreen(8))
                    .foregroundStyle(GameColor.ashGrey)
                    .offset(x: 42, y: 6)

                // The functions, in the order they run (inner first), styled like the code.
                ForEach(0..<3, id: \.self) { k in
                    functionChip(pipeline[k], active: activeMachine == k)
                        .frame(width: 88, height: 22)
                        .offset(x: 42, y: rowY[k])
                }

                Text("SAFE KEYPAD")
                    .font(GameFont.silkscreen(7))
                    .foregroundStyle(GameColor.info)
                    .offset(x: 42, y: 112)

                // The safe's keypad display: the final return value lands here.
                HStack(spacing: 4) {
                    Text(keypad.map { "\($0)" } ?? "--")
                        .font(GameFont.silkscreen(12))
                        .foregroundStyle(keypad == nil ? GameColor.ashGrey
                                         : keypad == P4Engine.target ? GameColor.success : GameColor.error)
                        .contentTransition(.numericText())
                    Text("/ 22")
                        .font(GameFont.silkscreen(9))
                        .foregroundStyle(GameColor.ashGrey)
                }
                .frame(width: 88, height: 24)
                .background(RoundedRectangle(cornerRadius: 2).fill(GameColor.black))
                .overlay(RoundedRectangle(cornerRadius: 2).strokeBorder(GameColor.info, lineWidth: 2))
                .offset(x: 42, y: 124)

                // The value travelling down.
                Text("\(orbValue)")
                    .font(GameFont.play(11, bold: true))
                    .foregroundStyle(GameColor.black)
                    .contentTransition(.numericText(value: Double(orbValue)))
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(GameColor.accent))
                    .shadow(color: GameColor.accent.opacity(0.9), radius: 6)
                    .offset(x: 10, y: orbY[orbPosition])
                    .animation(.spring(duration: 0.5, bounce: 0.3), value: orbPosition)
                    .animation(.snappy, value: orbValue)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    @ViewBuilder
    private func functionChip(_ f: P4Function?, active: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: 3)
        if let f {
            Text("\(f.rawValue)()")
                .font(GameFont.play(11, bold: active))
                .foregroundStyle(GameColor.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(shape.fill(GameColor.midnight.opacity(0.9)))
                .overlay(shape.strokeBorder(active ? GameColor.accent : GameColor.mauve.opacity(0.6), lineWidth: active ? 1.5 : 1))
                .shadow(color: GameColor.accent.opacity(active ? 0.8 : 0), radius: 6)
                .scaleEffect(active ? 1.06 : 1)
                .animation(.spring(duration: 0.3, bounce: 0.5), value: active)
        } else {
            shape.strokeBorder(GameColor.slateGrey, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                .overlay(Text("?").font(GameFont.silkscreen(10)).foregroundStyle(GameColor.slateGrey))
        }
    }
}

// MARK: - Lock 5 · the door latches

struct TP5LatchStage: View {
    let latches: [LatchState]
    let activeLatch: Int?
    let jammedLatch: Int?
    let binding: String?
    var opened: Set<Int> = []

    var body: some View {
        TP5StageFrame(glow: latches.allSatisfy { $0 == .open } ? GameColor.success
                      : jammedLatch != nil ? GameColor.error : nil) {
            VStack(spacing: 6) {
                SafeArtView(unit: 3.7,
                            bolts: boltLights(latches.allSatisfy { $0 == .open } ? opened.union([5]) : opened),
                            latches: latches,
                            activeLatch: activeLatch,
                            jammedLatch: jammedLatch)
                    .padding(.top, 6)

                Text(binding ?? "id = ?")
                    .font(GameFont.play(11, bold: true))
                    .foregroundStyle(binding == nil ? GameColor.slateGrey : GameColor.accent)
                    .padding(.horizontal, 8)
                    .frame(height: 18)
                    .background(Capsule().fill(GameColor.midnight.opacity(0.8)))
                    .contentTransition(.numericText())
                    .animation(.snappy, value: binding)
                Spacer(minLength: 0)
            }
        }
    }
}
