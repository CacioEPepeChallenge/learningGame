//
//  TP1Screen03_GeneratorCoreView.swift
//  learning_game
//
//  Touchpoint 1 — Screen 3 "Generator Core" (intro card).
//  Shows Leo's override notes and the offline generator control panel.
//

import SwiftUI

struct TP1Screen03_GeneratorCoreView: View {
    let content: TP1GeneratorCoreContent
    var onStart: () -> Void
    var onClose: () -> Void

    @State private var appeared = false

    var body: some View {
        GameCardChrome(onClose: onClose) {
            ZStack(alignment: .topLeading) {
                GameCardHeader(title: content.title, subtitle: content.subtitle)
                    .offset(x: 26, y: 21)

                overrideNotes
                    .offset(x: 33, y: 126)

                TP1OfflineMonitor(message: content.monitorMessage, status: content.monitorStatus)
                    .frame(width: 234, height: 154)
                    .offset(x: 505, y: 124)

                GameButton(title: content.buttonTitle, action: onStart)
                    .frame(maxWidth: .infinity)
                    .offset(y: 317)
            }
        }
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.96)
        .onAppear {
            withAnimation(.easeOut(duration: 0.25)) { appeared = true }
        }
    }

    private var overrideNotes: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(content.notesTitle)
                .font(GameFont.bodyBold)
                .foregroundStyle(GameColor.white)
                .padding(.bottom, 18)

            VStack(alignment: .leading, spacing: 5) {
                ForEach(content.notes) { note in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Circle()
                            .fill(GameColor.white)
                            .frame(width: 4, height: 4)
                            .alignmentGuide(.firstTextBaseline) { $0[.bottom] + 4 }
                        Text(note.text)
                            .font(GameFont.play(15))
                            .foregroundStyle(GameColor.white)
                    }
                    .padding(.leading, 5)
                }
            }
        }
    }
}

/// The generator control panel: `computer2` monitor (stand cropped off, as in the Figma)
/// with a dark window and the status line drawn live in Error red.
struct TP1OfflineMonitor: View {
    let message: String
    let status: String

    @State private var blink = false

    var body: some View {
        GeometryReader { geo in
            // computer2.png is 555 × 508; the screen part is the top ~365 px.
            let s = geo.size.width / 555
            ZStack(alignment: .topLeading) {
                Image("computer2")
                    .resizable()
                    .interpolation(.none)
                    .frame(width: 555 * s, height: 508 * s)

                // Darken the sprite's blue screen to the Figma's slate (≈ #1F233A).
                GameColor.black.opacity(0.5)
                    .frame(width: (503 - 48) * s, height: (328 - 62) * s)
                    .offset(x: 48 * s, y: 62 * s)

                // Window body inside the sprite's drawn window outline.
                ZStack {
                    GameColor.black
                    Text(message)
                        .font(GameFont.play(11))
                        .foregroundStyle(GameColor.error)
                        .opacity(blink ? 0.35 : 1)
                }
                .frame(width: (399 - 155) * s, height: (262 - 143) * s)
                .offset(x: 155 * s, y: 143 * s)

                Text(status)
                    .font(GameFont.play(11))
                    .foregroundStyle(GameColor.error)
                    .frame(width: geo.size.width)
                    .offset(y: 290 * s)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            .clipped()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                blink = true
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Generator control panel: \(message). \(status)")
    }
}

// MARK: - Preview

#Preview("Screen 3 · Generator Core", traits: .fixedLayout(width: 874, height: 402)) {
    ZStack {
        Image("background_dimmed")
            .resizable()
            .interpolation(.none)
            .scaledToFill()
        GameCardOverlay {
            TP1Screen03_GeneratorCoreView(content: .figma, onStart: {}, onClose: {})
        }
    }
}
