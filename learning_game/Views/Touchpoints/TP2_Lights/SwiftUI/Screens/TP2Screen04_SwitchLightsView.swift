//
//  TP2Screen04_SwitchLightsView.swift
//  learning_game
//
//  Touchpoint 2 — Screen 4 "Switch the Lights" (first hands-on card).
//  Left: the two lamps = the two elements of `roomLights`. Tapping a lamp
//  runs `roomLights[i] = <next LightState>` (off → dim → on).
//  Right: the code panel shows that line live and the whole array.
//  Task: turn the hanging lamp on (roomLights[0] = .on) → Next unlocks.
//

import SwiftUI

struct TP2Screen04_SwitchLightsView: View {
    @Bindable var viewModel: TP2LightsViewModel

    @State private var appeared = false
    @State private var hintPulse = false

    private var content: TP2SwitchLightsContent { viewModel.switchLights }

    var body: some View {
        GameCardChrome(onClose: viewModel.close) {
            ZStack(alignment: .topLeading) {
                GameCardTitle(title: content.title, subtitle: content.subtitle)
                    .offset(x: 35, y: 24)

                HStack(spacing: 16) {
                    ForEach(viewModel.lamps) { lamp in
                        lampTile(lamp)
                            .frame(width: 154, height: 168)
                    }
                }
                .offset(x: 34, y: 100)

                codePanel
                    .frame(width: 368, height: 168)
                    .offset(x: 380, y: 100)

                feedback
                    .frame(maxWidth: .infinity)
                    .frame(height: 20)
                    .offset(y: 282)

                GameButton(title: content.buttonTitle, kind: .outline, action: viewModel.goToNext)
                    .disabled(!viewModel.isSwitchTaskDone)
                    .frame(maxWidth: .infinity)
                    .offset(y: 317)
            }
        }
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.96)
        .onAppear {
            withAnimation(.easeOut(duration: 0.25)) { appeared = true }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) { hintPulse = true }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: viewModel.roomLights)
        .sensoryFeedback(.success, trigger: viewModel.isSwitchTaskDone) { _, done in done }
    }

    // MARK: Lamps — tap to change roomLights[i]

    private func lampTile(_ lamp: TP2Lamp) -> some View {
        let state = viewModel.roomLights[lamp.index]
        let shape = RoundedRectangle(cornerRadius: 3)
        let isGoal = lamp.index == content.goalIndex
        let showHint = isGoal && !viewModel.hasTouchedLights
        let glow: Double = switch state {
        case .on: 0.55
        case .dim: 0.25
        case .off: 0
        }

        return ZStack {
            shape.fill(GameColor.black)

            // Light glow behind the lamp.
            RadialGradient(colors: [GameColor.info.opacity(glow), .clear],
                           center: .center, startRadius: 0, endRadius: 80)

            VStack(spacing: 6) {
                PixelImage(lamp.sprite(for: state))
                    .brightness(lamp.darkening(for: state))
                    .saturation(lamp.saturation(for: state))
                    .frame(width: 84, height: 96, alignment: .bottom)

                HStack(spacing: 6) {
                    Text("[\(lamp.index)]")
                        .font(GameFont.silkscreen(11))
                        .foregroundStyle(GameColor.accent)
                    Text(lamp.name)
                        .font(GameFont.caption)
                        .foregroundStyle(GameColor.ashGrey)
                }
                Text(state.code)
                    .font(GameFont.bodySmBold)
                    .foregroundStyle(stateColor(state))
                    .contentTransition(.opacity)
            }
            .padding(.top, 6)
        }
        .clipShape(shape)
        .overlay(shape.strokeBorder(showHint ? GameColor.accent : (state == .on ? GameColor.success : GameColor.slateGrey),
                                    lineWidth: showHint ? 2 : 1)
                    .opacity(showHint ? (hintPulse ? 1 : 0.25) : 1))
        .contentShape(shape)
        .onTapGesture {
            withAnimation(.snappy(duration: 0.2)) { viewModel.cycleLight(at: lamp.index) }
        }
        .animation(.easeOut(duration: 0.25), value: state)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("roomLights \(lamp.index), \(lamp.name): \(state.rawValue). Tap to change.")
        .accessibilityAddTraits(.isButton)
    }

    private func stateColor(_ state: TP2LightState) -> Color {
        switch state {
        case .on: GameColor.success
        case .dim: GameColor.info
        case .off: GameColor.lightGrey
        }
    }

    // MARK: Code panel — the line that just "ran"

    private var codePanel: some View {
        let shape = RoundedRectangle(cornerRadius: 4)
        return VStack(alignment: .leading, spacing: 14) {
            GameCodeText(code: content.codeHeader, size: 12, bold: true)

            Group {
                if let index = viewModel.lastChangedIndex {
                    let state = viewModel.roomLights[index]
                    Text("roomLights[\(index)] = \(Text(state.code).foregroundStyle(stateColor(state)))")
                        .font(GameFont.play(14, bold: true))
                        .foregroundStyle(GameColor.white)
                        .id("\(index)-\(state.rawValue)")
                        .transition(.asymmetric(insertion: .move(edge: .leading).combined(with: .opacity),
                                                removal: .opacity))
                } else {
                    Text(content.tapHint)
                        .font(GameFont.play(13))
                        .foregroundStyle(GameColor.info)
                }
            }
            .frame(height: 20, alignment: .leading)

            Text("// roomLights is now \(viewModel.roomLightsCode)")
                .font(GameFont.play(13))
                .foregroundStyle(GameColor.ashGrey)
                .contentTransition(.opacity)
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(shape.fill(GameColor.black))
        .overlay(shape.strokeBorder(viewModel.isSwitchTaskDone ? GameColor.success : GameColor.ashGrey, lineWidth: 1))
        .animation(.snappy(duration: 0.25), value: viewModel.roomLights)
    }

    // MARK: Task / feedback

    @ViewBuilder
    private var feedback: some View {
        if viewModel.isSwitchTaskDone {
            GameFeedbackLine(isSuccess: true, text: content.successFeedback)
                .transition(.opacity)
        } else {
            Text("\(Text(content.taskLabel).foregroundStyle(GameColor.accent)) \(content.taskText)")
                .font(GameFont.bodySmBold)
                .foregroundStyle(GameColor.white)
                .transition(.opacity)
        }
    }
}

// MARK: - Preview

#Preview("TP2 · Screen 4 · Switch the Lights", traits: .fixedLayout(width: 874, height: 402)) {
    ZStack {
        Image("background_dimmed")
            .resizable()
            .interpolation(.none)
            .scaledToFill()
        GameCardOverlay {
            TP2Screen04_SwitchLightsView(viewModel: TP2LightsViewModel(startAt: .switchLights))
        }
    }
}
