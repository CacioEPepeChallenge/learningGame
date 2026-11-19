//
//  TP5Stages.swift
//  learning_game
//
//  The animated "stage" on the left of each Touchpoint 5 lock card, plus the
//  painting reveal on the intro card. Every visual uses a TP5Sprite slot:
//  until the art exists you see a drawn stand-in with a dashed outline and the
//  asset name (debug builds). See TP5_SPRITES.md for the full list.
//

import SwiftUI

// MARK: - Intro · slide the painting aside

struct TP5PaintingReveal: View {
    let isMoved: Bool
    let onMove: () -> Void

    @State private var drag: CGFloat = 0
    @State private var hintPulse = false

    var body: some View {
        ZStack {
            // The safe hidden behind the painting.
            TP5Sprite(name: "tp5_safe_closed") { TP5VectorSafe(lit: 0) }
                .frame(width: 132, height: 160)

            PixelImage("painting")
                .frame(width: 128, height: 192)
                .shadow(color: GameColor.black.opacity(0.6), radius: 8, x: 4, y: 6)
                .rotationEffect(.degrees(isMoved ? 4 : Double(drag) / 20), anchor: .topLeading)
                .offset(x: isMoved ? 92 : drag, y: isMoved ? 6 : 0)
                .gesture(
                    DragGesture()
                        .onChanged { drag = max(0, $0.translation.width) }
                        .onEnded { value in
                            if value.translation.width > 50 {
                                withAnimation(.spring(duration: 0.6, bounce: 0.3)) { onMove() }
                            }
                            withAnimation(.spring(duration: 0.4)) { drag = 0 }
                        }
                )
                .onTapGesture { withAnimation(.spring(duration: 0.6, bounce: 0.3)) { onMove() } }
                .accessibilityLabel(isMoved ? "Painting, moved aside" : "Painting. Slide it aside")
                .accessibilityAddTraits(.isButton)

            if !isMoved {
                Text("SLIDE THE PAINTING ›")
                    .font(GameFont.silkscreen(9))
                    .foregroundStyle(GameColor.info)
                    .opacity(hintPulse ? 1 : 0.35)
                    .offset(y: 112)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { hintPulse = true }
                    }
            }
        }
        .frame(width: 250, height: 210)
    }
}

/// Drawn stand-in for the safe: grey door, dial, and five bolt lights.
struct TP5VectorSafe: View {
    /// How many of the five bolt lights are green.
    var lit: Int

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(GameColor.slateGrey)
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(GameColor.ashGrey, lineWidth: 3))
            RoundedRectangle(cornerRadius: 3)
                .strokeBorder(GameColor.black.opacity(0.5), lineWidth: 2)
                .padding(12)
            TP5VectorDial()
                .frame(width: 46, height: 46)
                .offset(y: -12)
            HStack(spacing: 6) {
                ForEach(0..<5, id: \.self) { i in
                    Circle()
                        .fill(i < lit ? GameColor.success : GameColor.error)
                        .frame(width: 8, height: 8)
                        .shadow(color: (i < lit ? GameColor.success : GameColor.error).opacity(0.8), radius: 3)
                }
            }
            .offset(y: 42)
        }
    }
}

/// Drawn dial: ring, ten ticks, centre knob and a marker.
struct TP5VectorDial: View {
    var body: some View {
        ZStack {
            Circle().fill(GameColor.black.opacity(0.7))
            Circle().strokeBorder(GameColor.lightGrey, lineWidth: 2)
            ForEach(0..<10, id: \.self) { i in
                Rectangle()
                    .fill(GameColor.lightGrey)
                    .frame(width: 1.5, height: 5)
                    .offset(y: -15)
                    .rotationEffect(.degrees(Double(i) * 36))
            }
            Circle().fill(GameColor.ashGrey).frame(width: 12, height: 12)
            Rectangle().fill(GameColor.error).frame(width: 2, height: 9).offset(y: -9)
        }
    }
}

// MARK: - Lock 1 · the safe door (dial + lever + bolt)

struct TP5SafeDoorStage: View {
    let dialTurns: Int
    let leverPulled: Bool
    let boltOpen: Bool
    let jammed: Bool

    @State private var sparkOn = false

    var body: some View {
        TP5StageFrame(glow: boltOpen ? GameColor.success : jammed ? GameColor.error : nil) {
            ZStack {
                TP5Sprite(name: "tp5_safe_door") {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(GameColor.slateGrey)
                        .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(GameColor.ashGrey, lineWidth: 2))
                }
                .frame(width: 104, height: 116)
                .offset(y: -10)

                TP5Sprite(name: "tp5_safe_dial") { TP5VectorDial() }
                    .frame(width: 48, height: 48)
                    .rotationEffect(.degrees(Double(dialTurns) * 252))
                    .animation(.spring(duration: 0.7, bounce: 0.25), value: dialTurns)
                    .offset(x: -18, y: -26)

                TP5Sprite(name: "tp5_safe_lever") {
                    VStack(spacing: 0) {
                        Circle().fill(GameColor.ashGrey).frame(width: 10, height: 10)
                        Capsule().fill(GameColor.lightGrey).frame(width: 6, height: 30)
                        Circle().fill(GameColor.burgundy).frame(width: 12, height: 12)
                    }
                }
                .frame(width: 14, height: 52)
                .rotationEffect(.degrees(leverPulled ? -65 : jammed ? -15 : 0), anchor: .top)
                .animation(.spring(duration: 0.5, bounce: jammed ? 0.7 : 0.3), value: leverPulled)
                .animation(.spring(duration: 0.3, bounce: 0.8), value: jammed)
                .offset(x: 26, y: -24)

                // The deadbolt slides out of the door when it opens.
                TP5Sprite(name: "tp5_safe_bolt") {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(boltOpen ? GameColor.success : GameColor.lightGrey)
                }
                .frame(width: 40, height: 10)
                .offset(x: boltOpen ? 66 : 44, y: 30)
                .animation(.spring(duration: 0.6, bounce: 0.2), value: boltOpen)

                if jammed {
                    PixelImage("spark")
                        .frame(width: 30, height: 30)
                        .opacity(sparkOn ? 1 : 0.3)
                        .offset(x: 34, y: -4)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 0.12).repeatCount(8, autoreverses: true)) { sparkOn = true }
                        }
                        .transition(.opacity)
                }

                Text(boltOpen ? "BOLT OPEN" : jammed ? "JAMMED" : "LOCKED")
                    .font(GameFont.silkscreen(9))
                    .foregroundStyle(boltOpen ? GameColor.success : jammed ? GameColor.error : GameColor.ashGrey)
                    .offset(y: 66)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(boltOpen ? "The deadbolt is open" : jammed ? "The lever jammed" : "The safe is locked")
    }
}

// MARK: - Lock 2 · lamp + speaker signals

struct TP5SignalStage: View {
    let lampOn: Bool
    let beepCount: Int
    let emitted: [P2Signal]

    var body: some View {
        TP5StageFrame {
            VStack(spacing: 6) {
                HStack(spacing: 10) {
                    PixelImage(lampOn ? "lamp_on" : "lamp_off")
                        .frame(width: 52, height: 52)
                        .shadow(color: GameColor.info.opacity(lampOn ? 0.9 : 0), radius: 14)
                        .animation(.easeOut(duration: 0.12), value: lampOn)

                    ZStack {
                        Circle()
                            .strokeBorder(GameColor.accent, lineWidth: 2)
                            .frame(width: 44, height: 44)
                            .keyframeAnimator(initialValue: RingState(), trigger: beepCount) { ring, value in
                                ring.scaleEffect(value.scale).opacity(value.opacity)
                            } keyframes: { _ in
                                KeyframeTrack(\.scale) {
                                    LinearKeyframe(0.6, duration: 0.01)
                                    LinearKeyframe(1.5, duration: 0.5)
                                }
                                KeyframeTrack(\.opacity) {
                                    LinearKeyframe(1, duration: 0.01)
                                    LinearKeyframe(0, duration: 0.5)
                                }
                            }
                        TP5Sprite(name: "tp5_speaker") { TP5VectorSpeaker() }
                            .frame(width: 34, height: 34)
                            .keyframeAnimator(initialValue: 1.0, trigger: beepCount) { view, s in
                                view.scaleEffect(s)
                            } keyframes: { _ in
                                SpringKeyframe(1.25, duration: 0.12)
                                SpringKeyframe(1.0, duration: 0.3)
                            }
                    }
                    .frame(width: 52, height: 52)
                }
                .padding(.top, 12)

                Text("OUTPUT")
                    .font(GameFont.silkscreen(8))
                    .foregroundStyle(GameColor.ashGrey)

                LazyVGrid(columns: Array(repeating: GridItem(.fixed(20), spacing: 4), count: 5), spacing: 4) {
                    ForEach(Array(emitted.enumerated()), id: \.offset) { _, s in
                        TP5SignalChip(signal: s, compact: true)
                            .transition(.scale(scale: 0.5).combined(with: .opacity))
                    }
                }
                .animation(.spring(duration: 0.3, bounce: 0.4), value: emitted.count)
                Spacer(minLength: 0)
            }
        }
    }

    private struct RingState {
        var scale = 1.5
        var opacity = 0.0
    }
}

struct TP5VectorSpeaker: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4).fill(GameColor.slateGrey)
            Circle().fill(GameColor.black).padding(7)
            Circle().fill(GameColor.ashGrey).padding(13)
        }
    }
}

/// flash / beep chip with a little icon (lamp or speaker).
struct TP5SignalChip: View {
    let signal: P2Signal
    var compact = false

    var body: some View {
        HStack(spacing: 3) {
            if signal == .flash {
                PixelImage("lamp_on").frame(width: 16, height: 16)
            } else {
                TP5Sprite(name: "tp5_speaker") { TP5VectorSpeaker() }
                    .frame(width: 14, height: 14)
            }
            if !compact {
                Text(signal.rawValue)
                    .font(GameFont.play(12))
                    .foregroundStyle(GameColor.white)
            }
        }
        .padding(.horizontal, compact ? 2 : 4)
        .frame(width: compact ? 20 : nil, height: compact ? 20 : 24)
        .background(RoundedRectangle(cornerRadius: 3).fill(signal == .flash ? GameColor.burgundy.opacity(0.6) : GameColor.accent2.opacity(0.8)))
    }
}

// MARK: - Lock 3 · the combination dial

struct TP5DialStage: View {
    let needleAngle: Double
    let reading: Int
    let results: [Bool?]

    var body: some View {
        TP5StageFrame(glow: results.allSatisfy { $0 == true } ? GameColor.success
                      : results.contains(false) ? GameColor.error : nil) {
            VStack(spacing: 6) {
                // Leo's clue, taped to the back of the painting.
                TP5Sprite(name: "tp5_clue_note") {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(GameColor.peach)
                        .rotationEffect(.degrees(-2))
                }
                .frame(width: 112, height: 28)
                .overlay {
                    HStack(spacing: 6) {
                        ForEach(0..<3, id: \.self) { i in
                            Text("\(P3Engine.combination[i])")
                                .font(GameFont.silkscreen(14))
                                .foregroundStyle(results[i] == true ? GameColor.success
                                                 : results[i] == false ? GameColor.error : GameColor.black)
                            if i < 2 { Text("·").font(GameFont.play(14)).foregroundStyle(GameColor.black) }
                        }
                    }
                }
                .padding(.top, 8)

                ZStack {
                    TP5Sprite(name: "tp5_dial_face") { TP5VectorDialFace() }
                        .frame(width: 100, height: 100)
                    TP5Sprite(name: "tp5_dial_needle") {
                        Capsule().fill(GameColor.accent)
                            .shadow(color: GameColor.accent.opacity(0.8), radius: 3)
                    }
                    .frame(width: 4, height: 36)
                    .offset(y: -18)
                    .rotationEffect(.degrees(needleAngle))
                    .animation(.spring(duration: 0.22, bounce: 0.3), value: needleAngle)
                    Circle().fill(GameColor.lightGrey).frame(width: 10, height: 10)
                }

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
}

/// Drawn dial face with 0…9 around the rim (0 at the top, clockwise).
struct TP5VectorDialFace: View {
    var body: some View {
        GeometryReader { geo in
            let r = geo.size.width / 2
            ZStack {
                Circle().fill(GameColor.black)
                Circle().strokeBorder(GameColor.slateGrey, lineWidth: 3)
                ForEach(0..<10, id: \.self) { i in
                    let a = Double(i) * 36 * .pi / 180
                    Text("\(i)")
                        .font(GameFont.play(11, bold: true))
                        .foregroundStyle(GameColor.lightGrey)
                        .position(x: r + sin(a) * (r - 13), y: r - cos(a) * (r - 13))
                }
            }
        }
    }
}

// MARK: - Lock 4 · the function machines

struct TP5MachineStage: View {
    /// Inner → outer.
    let pipeline: [P4Function?]
    let activeMachine: Int?
    let orbValue: Int
    let orbPosition: Int
    let keypad: Int?

    private let machineY: [CGFloat] = [30, 70, 110]
    private let orbY: [CGFloat] = [14, 64, 104, 148]

    var body: some View {
        TP5StageFrame(glow: keypad.map { $0 == P4Engine.target ? GameColor.success : GameColor.error }) {
            ZStack(alignment: .topLeading) {
                // The pipe the value travels down.
                Rectangle()
                    .fill(GameColor.slateGrey)
                    .frame(width: 2, height: 136)
                    .offset(x: 21, y: 14)

                Text("INPUT")
                    .font(GameFont.silkscreen(8))
                    .foregroundStyle(GameColor.ashGrey)
                    .offset(x: 42, y: 9)

                ForEach(0..<3, id: \.self) { k in
                    machine(pipeline[k], active: activeMachine == k)
                        .frame(width: 88, height: 28)
                        .offset(x: 42, y: machineY[k])
                }

                TP5Sprite(name: "tp5_keypad") {
                    RoundedRectangle(cornerRadius: 3).fill(GameColor.black)
                        .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(GameColor.slateGrey, lineWidth: 1))
                }
                .frame(width: 88, height: 18)
                .overlay {
                    Text(keypad.map { "\($0) / 22" } ?? "-- / 22")
                        .font(GameFont.silkscreen(9))
                        .foregroundStyle(keypad == nil ? GameColor.ashGrey
                                         : keypad == P4Engine.target ? GameColor.success : GameColor.error)
                }
                .offset(x: 42, y: 139)

                // The value orb.
                Text("\(orbValue)")
                    .font(GameFont.play(11, bold: true))
                    .foregroundStyle(GameColor.black)
                    .contentTransition(.numericText(value: Double(orbValue)))
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(GameColor.accent))
                    .shadow(color: GameColor.accent.opacity(0.9), radius: 6)
                    .offset(x: 10, y: orbY[orbPosition] - 12)
                    .animation(.spring(duration: 0.5, bounce: 0.3), value: orbPosition)
                    .animation(.snappy, value: orbValue)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    @ViewBuilder
    private func machine(_ f: P4Function?, active: Bool) -> some View {
        if let f {
            TP5Sprite(name: "tp5_machine_\(f.rawValue)") {
                RoundedRectangle(cornerRadius: 4)
                    .fill(GameColor.midnight)
                    .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(GameColor.mauve, lineWidth: 1))
            }
            .overlay {
                Text(f.rawValue)
                    .font(GameFont.play(10, bold: true))
                    .foregroundStyle(GameColor.white)
            }
            .shadow(color: GameColor.accent.opacity(active ? 0.9 : 0), radius: 8)
            .scaleEffect(active ? 1.08 : 1)
            .animation(.spring(duration: 0.3, bounce: 0.5), value: active)
        } else {
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(GameColor.slateGrey, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                .overlay(Text("?").font(GameFont.silkscreen(10)).foregroundStyle(GameColor.slateGrey))
        }
    }
}

// MARK: - Lock 5 · three latches

struct TP5LatchStage: View {
    let latches: [LatchState]
    let activeLatch: Int?
    let jammedLatch: Int?
    let binding: String?

    var body: some View {
        TP5StageFrame(glow: latches.allSatisfy { $0 == .open } ? GameColor.success
                      : jammedLatch != nil ? GameColor.error : nil) {
            VStack(spacing: 9) {
                Text("LATCHES")
                    .font(GameFont.silkscreen(8))
                    .foregroundStyle(GameColor.ashGrey)
                    .padding(.top, 10)

                ForEach(0..<3, id: \.self) { i in
                    latch(i + 1, state: latches[i])
                }

                Text(binding ?? "id = ?")
                    .font(GameFont.play(11, bold: true))
                    .foregroundStyle(binding == nil ? GameColor.slateGrey : GameColor.accent)
                    .padding(.horizontal, 8)
                    .frame(height: 20)
                    .background(Capsule().fill(GameColor.midnight.opacity(0.8)))
                    .contentTransition(.numericText())
                    .animation(.snappy, value: binding)
                Spacer(minLength: 0)
            }
        }
    }

    private func color(_ state: LatchState) -> Color {
        switch state {
        case .locked: GameColor.burgundy
        case .unlatched: GameColor.info
        case .open: GameColor.success
        }
    }

    private func latch(_ n: Int, state: LatchState) -> some View {
        let active = activeLatch == n
        let jam = jammedLatch == n
        return HStack(spacing: 6) {
            Text("\(n)")
                .font(GameFont.silkscreen(11))
                .foregroundStyle(active ? GameColor.accent : GameColor.lightGrey)
                .frame(width: 12)
            ZStack(alignment: .leading) {
                TP5Sprite(name: "tp5_latch_frame") {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(GameColor.black)
                        .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(GameColor.slateGrey, lineWidth: 1))
                }
                TP5Sprite(name: "tp5_latch_bar") {
                    Capsule().fill(color(state))
                }
                .frame(width: 44, height: 10)
                .offset(x: state == .open ? 46 : 4, y: state == .unlatched ? -3 : 0)
                .animation(.spring(duration: 0.45, bounce: 0.3), value: state)
            }
            .frame(width: 96, height: 24)
            .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(GameColor.accent, lineWidth: active ? 1.5 : 0))
            .modifier(GameShake(amount: 3, animatableData: jam ? 2 : 0))
            .animation(.linear(duration: 0.4), value: jam)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Latch \(n): \(state == .open ? "open" : state == .unlatched ? "unlatched" : "locked")")
    }
}
