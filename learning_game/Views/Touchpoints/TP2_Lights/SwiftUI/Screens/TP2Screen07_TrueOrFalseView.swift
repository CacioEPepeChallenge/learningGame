//
//  TP2Screen07_TrueOrFalseView.swift
//  learning_game
//
//  Touchpoint 2 — Screen 7 "True or False" (Figma frame 6, same layout as
//  TP1 Screen 12): centred code box, True (filled) / False (outline).
//  After answering, the code box explains what schedule[1] really is.
//

import SwiftUI

struct TP2Screen07_TrueOrFalseView: View {
    @Bindable var viewModel: TP2LightsViewModel

    @State private var appeared = false
    @State private var wrongShake: CGFloat = 0

    private var quiz: TP2TrueFalseViewModel { viewModel.trueOrFalse }
    private var content: TP2TrueFalseContent { quiz.content }

    var body: some View {
        GameCardChrome(onClose: viewModel.close) {
            ZStack(alignment: .topLeading) {
                GameCardTitle(title: content.title, subtitle: content.subtitle)
                    .offset(x: 35, y: 24)

                codeBox
                    .frame(maxWidth: .infinity)
                    .offset(y: 128)

                feedback
                    .frame(maxWidth: .infinity)
                    .frame(height: 20)
                    .offset(y: 273)

                footerButtons
                    .frame(maxWidth: .infinity)
                    .offset(y: 317)
            }
        }
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.96)
        .onAppear { withAnimation(.easeOut(duration: 0.25)) { appeared = true } }
        .sensoryFeedback(trigger: quiz.answerCount) { _, _ in quiz.result == .correct ? .success : .error }
        .onChange(of: quiz.answerCount) {
            if case .wrong = quiz.result { withAnimation(.linear(duration: 0.4)) { wrongShake += 1 } }
        }
    }

    private var codeBox: some View {
        let shape = RoundedRectangle(cornerRadius: 4)
        let border: Color = switch quiz.result {
        case .correct: GameColor.success
        case .wrong: GameColor.error
        case .unchecked: GameColor.ashGrey
        }
        return VStack(alignment: .leading, spacing: 10) {
            GameCodeText(code: content.code, size: 14)
            if quiz.result != .unchecked {
                Text(content.explanationCode)
                    .font(GameFont.play(12))
                    .foregroundStyle(GameColor.info)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(width: 440, alignment: .leading)
        .background(shape.fill(GameColor.black))
        .overlay(shape.strokeBorder(border, lineWidth: 1))
        .modifier(GameShake(animatableData: wrongShake))
        .animation(.snappy(duration: 0.3), value: quiz.result)
    }

    @ViewBuilder
    private var feedback: some View {
        switch quiz.result {
        case .correct:
            GameFeedbackLine(isSuccess: true, text: content.successFeedback).transition(.opacity)
        case .wrong:
            GameFeedbackLine(isSuccess: false, text: content.wrongFeedback).transition(.opacity)
        case .unchecked:
            EmptyView()
        }
    }

    @ViewBuilder
    private var footerButtons: some View {
        switch quiz.result {
        case .correct:
            GameButton(title: content.nextTitle, kind: .outline, action: viewModel.goToNext)
        case .wrong:
            GameButton(title: content.tryAgainTitle) {
                withAnimation(.snappy(duration: 0.25)) { quiz.retry() }
            }
        case .unchecked:
            HStack(spacing: 12) {
                GameButton(title: content.trueTitle) {
                    withAnimation(.easeOut(duration: 0.25)) { quiz.answer(true) }
                }
                GameButton(title: content.falseTitle, kind: .secondary) {
                    withAnimation(.easeOut(duration: 0.25)) { quiz.answer(false) }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("TP2 · Screen 7 · True or False", traits: .fixedLayout(width: 874, height: 402)) {
    ZStack {
        Image("background_dimmed").resizable().interpolation(.none).scaledToFill()
        GameCardOverlay {
            TP2Screen07_TrueOrFalseView(viewModel: TP2LightsViewModel(startAt: .trueOrFalse))
        }
    }
}
