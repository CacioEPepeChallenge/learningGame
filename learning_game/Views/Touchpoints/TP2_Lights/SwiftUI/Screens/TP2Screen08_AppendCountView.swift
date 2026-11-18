//
//  TP2Screen08_AppendCountView.swift
//  learning_game
//
//  Touchpoint 2 — Screen 8 "Add a Light" (new challenge, laid out like the
//  Cards.png "Choose the correct answer — What will the code display?" card).
//  Code: roomLights = [.on, .dim]; roomLights.append(.off); print(count).
//  Pick 2 / 3 / 4 → Check. The left box draws the array as cells; when the
//  answer is right the appended cell [2] .off slides in.
//

import SwiftUI

struct TP2Screen08_AppendCountView: View {
    @Bindable var viewModel: TP2LightsViewModel

    @State private var appeared = false
    @State private var wrongShake: CGFloat = 0

    private var quiz: TP2CountChoiceViewModel { viewModel.appendCount }
    private var content: TP2AppendCountContent { quiz.content }

    // Same geometry as TP1 Screen 10 / Cards.png (card coordinates).
    private let panelFrame = CGRect(x: 200, y: 107, width: 380, height: 161)
    private let optionX: CGFloat = 619
    private let optionY: CGFloat = 116
    private let optionSize = CGSize(width: 102, height: 40)
    private let optionStep: CGFloat = 52

    var body: some View {
        GameCardChrome(onClose: viewModel.close) {
            ZStack(alignment: .topLeading) {
                GameCardTitle(title: content.title, subtitle: content.subtitle)
                    .offset(x: 35, y: 24)

                TP2ArrayCells(values: [.on, .dim], appended: quiz.isSolved ? .off : nil)
                    .frame(width: 133, height: 161)
                    .offset(x: 32, y: 107)

                codePanel
                    .frame(width: panelFrame.width, height: panelFrame.height)
                    .offset(x: panelFrame.minX, y: panelFrame.minY)

                options

                feedback
                    .frame(width: panelFrame.width, height: 20)
                    .offset(x: panelFrame.minX, y: 278)

                footerButton
                    .frame(maxWidth: .infinity)
                    .offset(y: 317)
            }
        }
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.96)
        .onAppear { withAnimation(.easeOut(duration: 0.25)) { appeared = true } }
        .sensoryFeedback(.selection, trigger: quiz.selected)
        .sensoryFeedback(trigger: quiz.checkCount) { _, _ in quiz.isSolved ? .success : .error }
        .onChange(of: quiz.checkCount) {
            if case .wrong = quiz.result { withAnimation(.linear(duration: 0.4)) { wrongShake += 1 } }
        }
    }

    private var codePanel: some View {
        let shape = RoundedRectangle(cornerRadius: 4)
        return GameCodeText(code: content.code, size: 14)
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(shape.fill(GameColor.black))
            .overlay(shape.strokeBorder(quiz.isSolved ? GameColor.success : GameColor.ashGrey, lineWidth: 1))
            .animation(.easeOut(duration: 0.25), value: quiz.result)
    }

    // MARK: Answer options (right column)

    private var options: some View {
        ForEach(Array(content.options.enumerated()), id: \.element) { index, option in
            let isSelected = quiz.selected == option
            let border: GameChip.Border = switch quiz.result {
            case .unchecked: isSelected ? .selected : .idle
            case .correct: isSelected ? .correct : .idle
            case .wrong: isSelected ? .wrong : .idle
            }
            GameChip(text: String(option),
                     fill: isSelected ? GameColor.midnight.opacity(0.7) : GameColor.black,
                     border: border,
                     pulses: false)        // no hint on answers: it would give one away
                .frame(width: optionSize.width, height: optionSize.height)
                .modifier(GameShake(animatableData: isSelected && quiz.result != .correct ? wrongShake : 0))
                .onTapGesture { withAnimation(.snappy(duration: 0.2)) { quiz.select(option) } }
                .offset(x: optionX, y: optionY + CGFloat(index) * optionStep)
                .accessibilityLabel("Answer \(option)")
                .accessibilityAddTraits(.isButton)
        }
    }

    // MARK: Feedback & footer

    @ViewBuilder
    private var feedback: some View {
        switch quiz.result {
        case .correct:
            GameFeedbackLine(isSuccess: true, text: quiz.explanation).transition(.opacity)
        case .wrong:
            GameFeedbackLine(isSuccess: false, text: quiz.explanation).transition(.opacity)
        case .unchecked:
            Text("\(Text(content.taskLabel).foregroundStyle(GameColor.accent)) \(content.taskText)")
                .font(GameFont.bodySmBold)
                .foregroundStyle(GameColor.white)
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
            .disabled(quiz.selected == nil)
        }
    }
}

// MARK: - Array drawn as cells

/// `roomLights` drawn as numbered cells: [0] .on, [1] .dim … plus an optional
/// appended cell that slides in (dashed "?" until it exists).
struct TP2ArrayCells: View {
    let values: [TP2LightState]
    let appended: TP2LightState?

    var body: some View {
        let box = RoundedRectangle(cornerRadius: 3)
        VStack(alignment: .leading, spacing: 8) {
            Text("roomLights")
                .font(GameFont.silkscreen(9))
                .foregroundStyle(GameColor.ashGrey)

            ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                cell(index: index, value: value, isNew: false)
            }

            if let appended {
                cell(index: values.count, value: appended, isNew: true)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(GameColor.slateGrey, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    .frame(height: 28)
                    .overlay(Text("?").font(GameFont.captionBold).foregroundStyle(GameColor.slateGrey))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(box.fill(GameColor.black))
        .overlay(box.strokeBorder(appended == nil ? GameColor.ashGrey : GameColor.success, lineWidth: 1))
        .animation(.spring(duration: 0.5, bounce: 0.3), value: appended)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("roomLights has \(values.count + (appended == nil ? 0 : 1)) items")
    }

    private func cell(index: Int, value: TP2LightState, isNew: Bool) -> some View {
        HStack(spacing: 8) {
            Text("[\(index)]")
                .font(GameFont.silkscreen(10))
                .foregroundStyle(GameColor.accent)
            Text(value.code)
                .font(GameFont.bodySmBold)
                .foregroundStyle(GameColor.white)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .frame(height: 28)
        .background(RoundedRectangle(cornerRadius: 3).fill(GameColor.midnight.opacity(0.7)))
        .overlay(RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(isNew ? GameColor.success : GameColor.mauve.opacity(0.6), lineWidth: 1))
    }
}

// MARK: - Preview

#Preview("TP2 · Screen 8 · Add a Light", traits: .fixedLayout(width: 874, height: 402)) {
    ZStack {
        Image("background_dimmed").resizable().interpolation(.none).scaledToFill()
        GameCardOverlay {
            TP2Screen08_AppendCountView(viewModel: TP2LightsViewModel(startAt: .appendCount))
        }
    }
}
