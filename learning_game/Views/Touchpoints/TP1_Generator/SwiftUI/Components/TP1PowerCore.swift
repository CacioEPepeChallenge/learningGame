//
//  TP1PowerCore.swift
//  learning_game
//
//  Touchpoint 1 only — the generator power core (Screen 8 picture box).
//

import SwiftUI

// MARK: - Power core (Screen 8 visual)

/// The generator's energy core. Dim and grey when dead; glows brighter with
/// each correct block; bursts with sparks and pulses Info gold when complete.
struct TP1PowerCore: View {
    /// 0…1 — share of blocks in the right place.
    let progress: Double
    let isComplete: Bool
    let isError: Bool

    @State private var pulse = false
    @State private var burst = false

    private var percent: Int { isComplete ? 100 : Int((progress * 75).rounded()) }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 3)
        ZStack {
            shape.fill(GameColor.black)

            // Dead core: faint grey haze (always there, like the Figma).
            RadialGradient(colors: [GameColor.ashGrey.opacity(0.45), GameColor.ashGrey.opacity(0.08), .clear],
                           center: .center, startRadius: 0, endRadius: 70)

            // Live core: Info / Peach glow that grows with progress.
            RadialGradient(colors: [GameColor.peach, GameColor.info.opacity(0.85), GameColor.info.opacity(0.15), .clear],
                           center: .center, startRadius: 0, endRadius: 30 + 40 * progress)
                .opacity(isComplete ? 1 : progress * 0.8)
                .scaleEffect(isComplete && pulse ? 1.12 : 1)

            // Error flash.
            RadialGradient(colors: [GameColor.error.opacity(0.7), .clear],
                           center: .center, startRadius: 0, endRadius: 60)
                .opacity(isError ? 1 : 0)

            if burst {
                PixelImage("spark")
                    .frame(width: 120, height: 120)
                    .transition(.asymmetric(insertion: .scale(scale: 0.3).combined(with: .opacity),
                                            removal: .scale(scale: 1.4).combined(with: .opacity)))
            }

            VStack {
                Spacer()
                Text("POWER \(percent)%")
                    .font(GameFont.silkscreen(10))
                    .foregroundStyle(isComplete ? GameColor.info : GameColor.ashGrey)
                    .contentTransition(.numericText(value: Double(percent)))
                    .padding(.bottom, 6)
            }
        }
        .clipShape(shape)
        .overlay(shape.strokeBorder(isComplete ? GameColor.info : GameColor.ashGrey, lineWidth: 1))
        .shadow(color: GameColor.info.opacity(isComplete ? 0.5 : 0), radius: 14)
        .animation(.easeOut(duration: 0.4), value: progress)
        .animation(.easeOut(duration: 0.25), value: isError)
        .onChange(of: isComplete, initial: true) { _, done in
            guard done else { return }
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) { pulse = true }
            withAnimation(.easeOut(duration: 0.2)) { burst = true }
            Task {
                try? await Task.sleep(for: .milliseconds(650))
                withAnimation(.easeIn(duration: 0.35)) { burst = false }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Power core \(percent) percent")
    }
}
