//
//  TP1Monitors.swift
//  learning_game
//
//  Picture-box visuals (133 × 126, left side of the challenge cards) that
//  react to the player's answer:
//    TP1VoltageMeter   — Screen 9: wobbling meter that locks steady at 220V.
//    TP1OverrideMonitor — Screen 10: generator monitor, OFFLINE → OVERRIDE ACCEPTED.
//

import SwiftUI

/// Shared reaction states for the picture-box visuals.
enum TP1VisualState: Equatable { case idle, error, success }

// MARK: - Voltage meter (Screen 9)

/// `part_meter` sprite. Idle: the needle wobbles (voltage unstable).
/// Error: shakes red ("UNLOCKED!"). Success: steady, "LOCKED AT 220V".
struct TP1VoltageMeter: View {
    let state: TP1VisualState

    @State private var shake: CGFloat = 0

    private var caption: String {
        switch state {
        case .idle: "LIMIT NOT SET"
        case .error: "UNLOCKED!"
        case .success: "LOCKED AT 220V"
        }
    }

    private var tint: Color {
        switch state {
        case .idle: GameColor.ashGrey
        case .error: GameColor.error
        case .success: GameColor.success
        }
    }

    var body: some View {
        let box = RoundedRectangle(cornerRadius: 3)
        ZStack(alignment: .top) {
            box.fill(GameColor.black)

            TimelineView(.animation(minimumInterval: 0.08, paused: state == .success)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                // Unstable voltage: small jittery wobble until the limit is locked.
                let wobble = state == .success ? 0 : sin(t * 13) * 2.5 + sin(t * 31) * 1.2
                PixelImage("part_meter")
                    .frame(width: 92, height: 92)
                    .rotationEffect(.degrees(wobble))
            }
            .padding(.top, 6)
            .modifier(GameShake(amount: 5, animatableData: shake))

            Text(caption)
                .font(GameFont.silkscreen(8))
                .foregroundStyle(tint)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 10)
                .contentTransition(.opacity)
        }
        .clipShape(box)
        .overlay(box.strokeBorder(state == .success ? GameColor.success : GameColor.ashGrey, lineWidth: 1))
        .shadow(color: GameColor.success.opacity(state == .success ? 0.45 : 0), radius: 14)
        .animation(.easeOut(duration: 0.3), value: state)
        .onChange(of: state) { _, new in
            if new == .error { withAnimation(.linear(duration: 0.4)) { shake += 1 } }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Voltage meter: \(caption)")
    }
}

// MARK: - Override monitor (Screen 10)

/// The generator control monitor (`computer2`, stand cropped) from Screen 3.
struct TP1OverrideMonitor: View {
    let state: TP1VisualState

    @State private var blink = false
    @State private var flash = false

    private var windowText: String {
        switch state {
        case .idle: "OFFLINE"
        case .error: "DENIED"
        case .success: "OMEGA"
        }
    }

    private var statusText: String {
        switch state {
        case .idle: "BOOT MEMORY WIPED"
        case .error: "ACCESS DENIED"
        case .success: "OVERRIDE ACCEPTED"
        }
    }

    private var tint: Color { state == .success ? GameColor.success : GameColor.error }

    var body: some View {
        let box = RoundedRectangle(cornerRadius: 3)
        ZStack(alignment: .top) {
            box.fill(GameColor.black)

            monitor
                .frame(width: 121, height: 80)
                .padding(.top, 10)

            Text(statusText)
                .font(GameFont.silkscreen(8))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 6)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 12)
                .contentTransition(.opacity)
        }
        .clipShape(box)
        .overlay(box.strokeBorder(state == .success ? GameColor.success : GameColor.ashGrey, lineWidth: 1))
        .shadow(color: GameColor.success.opacity(state == .success ? 0.45 : 0), radius: 14)
        .animation(.easeOut(duration: 0.3), value: state)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { blink = true }
        }
        .onChange(of: state) { _, new in
            guard new != .idle else { return }
            flash = true
            withAnimation(.easeOut(duration: 0.45)) { flash = false }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Generator monitor: \(statusText)")
    }

    /// computer2.png is 555 × 508; only the screen part (top ~365 px) is shown.
    private var monitor: some View {
        GeometryReader { geo in
            let s = geo.size.width / 555
            ZStack(alignment: .topLeading) {
                Image("computer2")
                    .resizable()
                    .interpolation(.none)
                    .frame(width: 555 * s, height: 508 * s)

                ZStack {
                    GameColor.black.opacity(0.5)
                    GameColor.success.opacity(state == .success ? 0.25 : 0)
                    GameColor.white.opacity(flash ? 0.6 : 0)
                }
                .frame(width: (503 - 48) * s, height: (328 - 62) * s)
                .offset(x: 48 * s, y: 62 * s)

                ZStack {
                    GameColor.black
                    Text(windowText)
                        .font(GameFont.silkscreen(8))
                        .foregroundStyle(tint)
                        .opacity(state == .idle && blink ? 0.35 : 1)
                        .contentTransition(.opacity)
                }
                .frame(width: (399 - 155) * s, height: (262 - 143) * s)
                .offset(x: 155 * s, y: 143 * s)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            .clipped()
        }
    }
}
