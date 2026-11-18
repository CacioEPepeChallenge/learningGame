//
//  TP1Screen15_CongratulationsView.swift
//  learning_game
//
//  Touchpoint 1 — Screen 15 "Congratulations" (Cards.png, Intro Challenges).
//  I.R.I.S. header, a glowing present in the middle — tap it to reveal the
//  next clue (the desk lamp, Touchpoint 2) — and "Discover a new clue",
//  which closes the cards and hands control back to the game.
//

import SwiftUI

struct TP1Screen15_CongratulationsView: View {
    @Bindable var viewModel: TP1GeneratorViewModel

    @State private var appeared = false
    @State private var pulse = false

    private var content: TP1CongratulationsContent { viewModel.congratulations }

    var body: some View {
        GameCardChrome(onClose: viewModel.close) {
            ZStack(alignment: .topLeading) {
                GameCardHeader(title: content.title, subtitle: content.subtitle)
                    .offset(x: 26, y: 21)

                present
                    .frame(maxWidth: .infinity)
                    .offset(y: 118)

                GameButton(title: content.buttonTitle, kind: .outline, action: viewModel.goToNext)
                    .disabled(!viewModel.isPresentOpened)
                    .frame(maxWidth: .infinity)
                    .offset(y: 317)
            }
        }
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.96)
        .onAppear {
            withAnimation(.easeOut(duration: 0.25)) { appeared = true }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) { pulse = true }
        }
        .sensoryFeedback(.success, trigger: viewModel.isPresentOpened) { _, new in new }
    }

    /// Figma: a soft glow in the middle of the card. Tap → the clue appears.
    private var present: some View {
        let opened = viewModel.isPresentOpened
        return VStack(spacing: 10) {
            ZStack {
                RadialGradient(colors: [GameColor.info.opacity(opened ? 0.55 : 0.35),
                                        GameColor.peach.opacity(0.12), .clear],
                               center: .center, startRadius: 0, endRadius: 80)
                    .frame(width: 170, height: 150)
                    .scaleEffect(pulse && !opened ? 1.08 : 1)

                if opened {
                    PixelImage("lamp_dim")
                        .frame(width: 96, height: 96)
                        .transition(.scale(scale: 0.4).combined(with: .opacity))
                } else {
                    Text(content.tapHint.uppercased())
                        .font(GameFont.silkscreen(10))
                        .foregroundStyle(GameColor.info)
                        .opacity(pulse ? 1 : 0.5)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(duration: 0.5, bounce: 0.35)) { viewModel.openPresent() }
            }
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(opened ? content.clue : "Present. \(content.tapHint)")

            Text(content.clue)
                .font(GameFont.bodySm)
                .foregroundStyle(GameColor.lightGrey)
                .opacity(opened ? 1 : 0)
        }
    }
}

// MARK: - Preview

#Preview("Screen 15 · Congratulations", traits: .fixedLayout(width: 874, height: 402)) {
    ZStack {
        GameColor.midnight
        GameCardOverlay {
            TP1Screen15_CongratulationsView(viewModel: TP1GeneratorViewModel(startAt: .congratulations))
        }
    }
}
