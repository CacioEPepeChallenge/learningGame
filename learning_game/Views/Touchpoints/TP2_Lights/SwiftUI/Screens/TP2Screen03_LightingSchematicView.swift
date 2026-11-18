//
//  TP2Screen03_LightingSchematicView.swift
//  learning_game
//
//  Touchpoint 2 — Screen 3 "Lighting Schematic" (intro card).
//  Explains the two concepts of this touchpoint before any challenge:
//    • Array — an ordered list, positions (indexes) start at 0
//    • Enum  — a fixed list of choices (LightState: .on / .off / .dim)
//  Right: Leo's real code, with the lamps drawn under it by their index.
//

import SwiftUI

struct TP2Screen03_LightingSchematicView: View {
    @Bindable var viewModel: TP2LightsViewModel

    @State private var appeared = false

    private var content: TP2LightingSchematicContent { viewModel.lightingSchematic }

    var body: some View {
        GameCardChrome(onClose: viewModel.close) {
            ZStack(alignment: .topLeading) {
                GameCardHeader(title: content.title, subtitle: content.subtitle)
                    .offset(x: 26, y: 21)

                concepts
                    .frame(width: 340, alignment: .leading)
                    .offset(x: 34, y: 112)

                codePanel
                    .frame(width: 350, height: 196)
                    .offset(x: 398, y: 106)

                GameButton(title: content.buttonTitle, kind: .outline, action: viewModel.goToNext)
                    .frame(maxWidth: .infinity)
                    .offset(y: 317)
            }
        }
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.96)
        .onAppear { withAnimation(.easeOut(duration: 0.25)) { appeared = true } }
    }

    // MARK: Left — what is an Array / an Enum

    private var concepts: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(content.concepts) { concept in
                VStack(alignment: .leading, spacing: 5) {
                    Text(concept.name)
                        .font(GameFont.bodyBold)
                        .foregroundStyle(GameColor.accent)
                    Text(concept.explanation)
                        .font(GameFont.bodySm)
                        .foregroundStyle(GameColor.white)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 8) {
                        Text(concept.example)
                            .font(GameFont.play(13, bold: true))
                            .foregroundStyle(GameColor.info)
                        Text("→ \(concept.exampleNote)")
                            .font(GameFont.caption)
                            .foregroundStyle(GameColor.ashGrey)
                    }
                }
            }
        }
    }

    // MARK: Right — Leo's code + the array drawn as lamps

    private var codePanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            GameCodeText(code: content.code, size: 12, bold: true)

            Spacer(minLength: 0)

            HStack(alignment: .bottom, spacing: 34) {
                ForEach(viewModel.lamps) { lamp in
                    lampTile(lamp)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: 4).fill(GameColor.black))
    }

    private func lampTile(_ lamp: TP2Lamp) -> some View {
        let state = viewModel.roomLights[lamp.index]
        return HStack(alignment: .bottom, spacing: 8) {
            PixelImage(lamp.sprite(for: state))
                .brightness(lamp.darkening(for: state))
                .saturation(lamp.saturation(for: state))
                .frame(width: 58, height: 76, alignment: .bottom)
            VStack(alignment: .leading, spacing: 2) {
                Text("[\(lamp.index)]")
                    .font(GameFont.silkscreen(11))
                    .foregroundStyle(GameColor.accent)
                Text(lamp.name)
                    .font(GameFont.caption)
                    .foregroundStyle(GameColor.ashGrey)
                Text(state.code)
                    .font(GameFont.captionBold)
                    .foregroundStyle(state == .on ? GameColor.success : GameColor.lightGrey)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("roomLights \(lamp.index): \(lamp.name), \(state.rawValue)")
    }
}

// MARK: - Preview

#Preview("TP2 · Screen 3 · Lighting Schematic", traits: .fixedLayout(width: 874, height: 402)) {
    ZStack {
        Image("background_dimmed")
            .resizable()
            .interpolation(.none)
            .scaledToFill()
        GameCardOverlay {
            TP2Screen03_LightingSchematicView(viewModel: TP2LightsViewModel(startAt: .lightingSchematic))
        }
    }
}
