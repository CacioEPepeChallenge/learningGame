//
//  TP2Screen10_LightsRestoredView.swift
//  learning_game
//
//  Touchpoint 2 — Screen 10 "Lights Restored" (payoff, like TP1 Ignition).
//  Every light turns on (roomLights = [.on, .on]), I.R.I.S. thanks the
//  player and a short recap lists what Arrays & Enums can do.
//  Continue → Touchpoint 2 is complete (game: completeOverlay).
//

import SwiftUI

struct TP2Screen10_LightsRestoredView: View {
    @Bindable var viewModel: TP2LightsViewModel

    @State private var appeared = false
    @State private var shownRecap = 0

    private var content: TP2LightsRestoredContent { viewModel.lightsRestored }

    var body: some View {
        GameCardChrome(onClose: viewModel.close) {
            ZStack(alignment: .topLeading) {
                GameCardHeader(title: content.title, subtitle: content.subtitle)
                    .offset(x: 26, y: 21)

                lamps
                    .offset(x: 32, y: 112)

                recap
                    .frame(width: 430, alignment: .leading)
                    .offset(x: 318, y: 112)

                GameButton(title: content.buttonTitle, action: viewModel.goToNext)
                    .frame(maxWidth: .infinity)
                    .offset(y: 317)
            }
        }
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.96)
        .task {
            withAnimation(.easeOut(duration: 0.25)) { appeared = true }
            try? await Task.sleep(for: .milliseconds(350))
            withAnimation(.easeOut(duration: 0.6)) { viewModel.restoreAllLights() }
            for index in content.recap.indices {
                try? await Task.sleep(for: .milliseconds(220))
                withAnimation(.easeOut(duration: 0.3)) { shownRecap = index + 1 }
            }
        }
        .sensoryFeedback(.success, trigger: viewModel.roomLights.allSatisfy { $0 == .on }) { _, allOn in allOn }
    }

    // MARK: Left — both lamps, lit

    private var lamps: some View {
        HStack(spacing: 14) {
            VStack(spacing: 6) {
                TP2LampCloseUp(isOn: viewModel.roomLights[0] == .on)
                    .frame(width: 120, height: 120)
                label(0)
            }
            VStack(spacing: 6) {
                deskLamp
                    .frame(width: 120, height: 120)
                label(1)
            }
        }
    }

    private var deskLamp: some View {
        let lamp = viewModel.lamps[1]
        let state = viewModel.roomLights[1]
        let box = RoundedRectangle(cornerRadius: 3)
        return ZStack {
            box.fill(GameColor.black)
            RadialGradient(colors: [GameColor.info.opacity(state == .on ? 0.55 : 0.2), .clear],
                           center: .center, startRadius: 0, endRadius: 70)
            PixelImage(lamp.sprite(for: state))
                .brightness(lamp.darkening(for: state))
                .saturation(lamp.saturation(for: state))
                .frame(width: 80, height: 80)
        }
        .clipShape(box)
        .overlay(box.strokeBorder(state == .on ? GameColor.success : GameColor.ashGrey, lineWidth: 1))
        .animation(.easeOut(duration: 0.6), value: state)
    }

    private func label(_ index: Int) -> some View {
        let state = viewModel.roomLights[index]
        return HStack(spacing: 6) {
            Text("[\(index)]")
                .font(GameFont.silkscreen(10))
                .foregroundStyle(GameColor.accent)
            Text(state.code)
                .font(GameFont.bodySmBold)
                .foregroundStyle(state == .on ? GameColor.success : GameColor.lightGrey)
                .contentTransition(.opacity)
        }
    }

    // MARK: Right — recap

    private var recap: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(content.recapTitle)
                .font(GameFont.bodyBold)
                .foregroundStyle(GameColor.white)
                .padding(.bottom, 2)
            ForEach(Array(content.recap.enumerated()), id: \.offset) { index, line in
                HStack(alignment: .top, spacing: 10) {
                    GameFeedbackIcon(isSuccess: true, size: 16)
                        .padding(.top, 1)
                    Text(line)
                        .font(GameFont.bodySm)
                        .foregroundStyle(GameColor.white)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .opacity(index < shownRecap ? 1 : 0)
                .offset(x: index < shownRecap ? 0 : -8)
            }
        }
    }
}

// MARK: - Preview

#Preview("TP2 · Screen 10 · Lights Restored", traits: .fixedLayout(width: 874, height: 402)) {
    ZStack {
        Image("background_dimmed").resizable().interpolation(.none).scaledToFill()
        GameCardOverlay {
            TP2Screen10_LightsRestoredView(viewModel: TP2LightsViewModel(startAt: .lightsRestored))
        }
    }
}
