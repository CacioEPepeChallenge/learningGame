//
//  TP2Screen09_FixCodeView.swift
//  learning_game
//
//  Touchpoint 2 — Screen 9 "Fix the Code" (Figma frame 7, laid out like
//  TP1 Screen 10 / Cards.png "Fix the function").
//      [____] LightState { case on, off, dim }
//      var roomLights: [LightState] = [.on, .off]
//      roomLights[1] = [____]
//  Chips: .bright / enum / "dim" / .dim. Wrong chips show Swift's real
//  compiler error under the line. Solved → the desk lamp dims.
//

import SwiftUI

struct TP2Screen09_FixCodeView: View {
    @Bindable var viewModel: TP2LightsViewModel

    @State private var appeared = false
    @State private var hintPulse = false
    @State private var wrongShake: CGFloat = 0
    @State private var blankFrames: [Int: CGRect] = [:]
    @State private var dragging: Int?
    @State private var dragTranslation: CGSize = .zero
    @State private var dragLocation: CGPoint?

    private var quiz: TP2FixCodeViewModel { viewModel.fixCode }
    private var content: TP2FixCodeContent { quiz.content }

    private let panelFrame = CGRect(x: 200, y: 100, width: 380, height: 178)
    private let chipX: CGFloat = 619
    private let chipY: CGFloat = 112
    private let chipSize = CGSize(width: 102, height: 36)
    private let chipStep: CGFloat = 44

    var body: some View {
        GameCardChrome(onClose: viewModel.close) {
            ZStack(alignment: .topLeading) {
                GameCardTitle(title: content.title, subtitle: content.subtitle)
                    .offset(x: 35, y: 24)

                deskLamp
                    .frame(width: 133, height: 126)
                    .offset(x: 32, y: 120)

                codePanel
                    .frame(width: panelFrame.width, height: panelFrame.height)
                    .offset(x: panelFrame.minX, y: panelFrame.minY)

                chips

                feedback
                    .frame(width: panelFrame.width, height: 20)
                    .offset(x: panelFrame.minX, y: 286)

                footerButton
                    .frame(maxWidth: .infinity)
                    .offset(y: 317)
            }
            .coordinateSpace(.named("tp2fix"))
        }
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.96)
        .onAppear {
            withAnimation(.easeOut(duration: 0.25)) { appeared = true }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) { hintPulse = true }
        }
        .sensoryFeedback(.selection, trigger: quiz.filled)
        .sensoryFeedback(trigger: quiz.checkCount) { _, _ in quiz.isSolved ? .success : .error }
        .onChange(of: quiz.filled) { RetroSFX.shared.playTick() }
        .onChange(of: quiz.checkCount) {
            if case .wrong = quiz.result {
                withAnimation(.linear(duration: 0.4)) { wrongShake += 1 }
                RetroSFX.shared.playBack()
            } else if quiz.isSolved {
                RetroSFX.shared.playSuccess()
            }
        }
    }

    // MARK: Desk lamp (picture box)

    private var deskLamp: some View {
        let lamp = viewModel.lamps[1]
        let state = viewModel.roomLights[1]
        let box = RoundedRectangle(cornerRadius: 3)
        let isError = quiz.result != .unchecked && !quiz.isSolved
        return ZStack {
            box.fill(GameColor.black)
            RadialGradient(colors: [GameColor.info.opacity(state == .dim ? 0.3 : state == .on ? 0.55 : 0), .clear],
                           center: .center, startRadius: 0, endRadius: 70)
            PixelImage(lamp.sprite(for: state))
                .brightness(lamp.darkening(for: state))
                .saturation(lamp.saturation(for: state))
                .frame(width: 80, height: 80)
                .offset(y: -8)
                .modifier(GameShake(amount: 4, animatableData: isError ? wrongShake : 0))
            Text("roomLights[1] = \(state.code)")
                .font(GameFont.silkscreen(8))
                .foregroundStyle(isError ? GameColor.error : quiz.isSolved ? GameColor.success : GameColor.ashGrey)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 8)
        }
        .clipShape(box)
        .overlay(box.strokeBorder(quiz.isSolved ? GameColor.success : GameColor.ashGrey, lineWidth: 1))
        .animation(.easeOut(duration: 0.4), value: state)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Desk lamp, \(state.rawValue)")
    }

    // MARK: Code panel with two blanks

    private var codePanel: some View {
        let shape = RoundedRectangle(cornerRadius: 4)
        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                blank(0)
                Text("LightState {").font(GameFont.bodySm).foregroundStyle(GameColor.white)
            }
            GameCodeText(code: "    case on, off, dim\n}", size: 13)
            errorLine(0)

            GameCodeText(code: "var roomLights: [LightState] = [.on, .off]", size: 13)
            HStack(spacing: 6) {
                Text("roomLights[1] =").font(GameFont.bodySm).foregroundStyle(GameColor.white)
                blank(1)
            }
            errorLine(1)
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(shape.fill(GameColor.black))
        .overlay(shape.strokeBorder(quiz.isSolved ? GameColor.success : GameColor.ashGrey, lineWidth: 1))
        .animation(.easeOut(duration: 0.25), value: quiz.result)
    }

    private func errorLine(_ blank: Int) -> some View {
        Text(quiz.error(forBlank: blank) ?? " ")
            .font(GameFont.play(10))
            .foregroundStyle(GameColor.error)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .frame(height: 14, alignment: .leading)
    }

    private func blank(_ id: Int) -> some View {
        let shape = RoundedRectangle(cornerRadius: 3)
        let chip = quiz.chip(inBlank: id)
        let isTarget = dragging != nil && blankIndex(at: dragLocation) == id
        let showHint = !quiz.hasStarted && id == 0
        let border: Color = isTarget || showHint ? GameColor.accent
            : quiz.result.isWrong(id) ? GameColor.error
            : quiz.isSolved ? GameColor.success
            : .clear

        return ZStack {
            shape.fill(GameColor.midnight.opacity(0.7))
            if let chip {
                Text(chip.text)
                    .font(GameFont.bodySmBold)
                    .foregroundStyle(GameColor.white)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
        }
        .frame(width: 80, height: 28)
        .overlay(shape.strokeBorder(border, lineWidth: isTarget ? 2 : 1)
                    .opacity(showHint && !isTarget ? (hintPulse ? 1 : 0.2) : 1))
        .modifier(GameShake(amount: 4, animatableData: quiz.result.isWrong(id) ? wrongShake : 0))
        .contentShape(shape)
        .onTapGesture { withAnimation(.snappy(duration: 0.25)) { quiz.clear(id) } }
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named("tp2fix")) } action: { blankFrames[id] = $0 }
        .accessibilityLabel("Blank \(id + 1): \(chip?.text ?? "empty")")
    }

    private func blankIndex(at point: CGPoint?) -> Int? {
        guard let point else { return nil }
        return blankFrames.first { $0.value.insetBy(dx: -10, dy: -10).contains(point) }?.key
    }

    // MARK: Chips (right column)

    private var chips: some View {
        ForEach(Array(content.chips.enumerated()), id: \.element.id) { index, chip in
            ZStack {
                if quiz.isUsed(chip.id) {
                    GameBlockPlaceholder()
                } else {
                    GameCodeBlockLabel(text: chip.text)
                        .scaleEffect(dragging == chip.id ? 1.1 : 1)
                        .offset(dragging == chip.id ? dragTranslation : .zero)
                        .gesture(dragGesture(for: chip.id))
                        .onTapGesture { withAnimation(.snappy(duration: 0.25)) { quiz.place(chip.id) } }
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                        .accessibilityLabel("Block \(chip.text)")
                        .accessibilityAddTraits(.isButton)
                }
            }
            .frame(width: chipSize.width, height: chipSize.height)
            .offset(x: chipX, y: chipY + CGFloat(index) * chipStep)
            .zIndex(dragging == chip.id ? 1 : 0)
        }
    }

    private func dragGesture(for id: Int) -> some Gesture {
        DragGesture(minimumDistance: 6, coordinateSpace: .named("tp2fix"))
            .onChanged { value in
                guard !quiz.isSolved else { return }
                dragging = id
                dragTranslation = value.translation
                dragLocation = value.location
            }
            .onEnded { value in
                let target = blankIndex(at: value.location)
                withAnimation(.snappy(duration: 0.25)) {
                    if let target { quiz.place(id, in: target) }
                    dragging = nil
                    dragTranslation = .zero
                    dragLocation = nil
                }
            }
    }

    // MARK: Feedback & footer

    @ViewBuilder
    private var feedback: some View {
        switch quiz.result {
        case .correct:
            GameFeedbackLine(isSuccess: true, text: content.successFeedback).transition(.opacity)
        case .wrong:
            GameFeedbackLine(isSuccess: false, text: content.wrongFeedback).transition(.opacity)
        case .unchecked:
            Text("\(Text(content.taskLabel).foregroundStyle(GameColor.accent)) \(content.taskText)")
                .font(GameFont.bodySmBold)
                .foregroundStyle(GameColor.white)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
    }

    @ViewBuilder
    private var footerButton: some View {
        switch quiz.result {
        case .correct:
            GameButton(title: content.nextTitle, kind: .outline, action: viewModel.goToNext)
        case .wrong:
            GameButton(title: content.tryAgainTitle) {
                withAnimation(.snappy(duration: 0.25)) { quiz.retry() }
            }
        case .unchecked:
            GameButton(title: content.checkTitle) {
                withAnimation(.easeOut(duration: 0.25)) { quiz.check() }
            }
            .disabled(!quiz.allFilled)
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }
}

// MARK: - Preview

#Preview("TP2 · Screen 9 · Fix the Code", traits: .fixedLayout(width: 874, height: 402)) {
    ZStack {
        Image("background_dimmed").resizable().interpolation(.none).scaledToFill()
        GameCardOverlay {
            TP2Screen09_FixCodeView(viewModel: TP2LightsViewModel(startAt: .fixCode))
        }
    }
}
