//
//  TP1Screen12_TrueOrFalseView.swift
//  learning_game
//
//  Touchpoint 1 — Screen 12 "True or False".
//  A centered code box (Figma) and two buttons: True (filled Burgundy) and
//  False (Burgundy outline). After answering, the code box reveals Swift's
//  real compiler output, so the player sees *why*.
//

import SwiftUI

struct TP1Screen12_TrueOrFalseView: View {
    @Bindable var viewModel: TP1GeneratorViewModel

    @State private var appeared = false
    @State private var wrongShake: CGFloat = 0

    private var quiz: TP1TrueFalseViewModel { viewModel.trueOrFalse }
    private var content: TP1TrueFalseContent { quiz.content }

    /// Swift's message for assigning to a `let`.
    private let compilerOutput = "error: cannot assign to value: 'overrideKey' is a 'let' constant"

    var body: some View {
        GameCardChrome(onClose: viewModel.close) {
            ZStack(alignment: .topLeading) {
                GameCardTitle(title: content.title, subtitle: content.subtitle)
                    .offset(x: 35, y: 24)

                codeBox
                    .frame(maxWidth: .infinity)
                    .offset(y: 140)

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
        .sensoryFeedback(trigger: quiz.answerCount) { _, _ in
            quiz.result == .correct ? .success : .error
        }
        .onChange(of: quiz.answerCount) {
            if quiz.result == .wrong { withAnimation(.linear(duration: 0.4)) { wrongShake += 1 } }
        }
    }

    // MARK: Code box

    private var codeBox: some View {
        let shape = RoundedRectangle(cornerRadius: 4)
        let border: Color = switch quiz.result {
        case .correct: GameColor.success
        case .wrong: GameColor.error
        case .unanswered: GameColor.ashGrey
        }
        return VStack(alignment: .leading, spacing: 10) {
            GameCodeText(code: content.code, size: 14)
            if quiz.result != .unanswered {
                Text(compilerOutput)
                    .font(GameFont.play(11))
                    .foregroundStyle(GameColor.error)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(width: 380, alignment: .leading)
        .background(shape.fill(GameColor.black))
        .overlay(shape.strokeBorder(border, lineWidth: 1))
        .modifier(GameShake(animatableData: wrongShake))
        .animation(.snappy(duration: 0.3), value: quiz.result)
    }

    // MARK: Feedback & footer

    @ViewBuilder
    private var feedback: some View {
        switch quiz.result {
        case .correct:
            TP1FeedbackLine(isSuccess: true, text: content.successFeedback)
                .transition(.opacity)
        case .wrong:
            TP1FeedbackLine(isSuccess: false, text: content.wrongFeedback)
                .transition(.opacity)
        case .unanswered:
            EmptyView()
        }
    }

    @ViewBuilder
    private var footerButtons: some View {
        switch quiz.result {
        case .correct:
            TP1NextButton(title: content.nextTitle, action: viewModel.goToNext)
                .transition(.opacity)
        case .wrong:
            TP1ActionButton(title: content.tryAgainTitle) {
                withAnimation(.snappy(duration: 0.25)) { quiz.retry() }
            }
            .transition(.opacity)
        case .unanswered:
            HStack(spacing: 12) {
                TP1ActionButton(title: content.trueTitle) {
                    withAnimation(.easeOut(duration: 0.25)) { quiz.answer(true) }
                }
                TP1ActionButton(title: content.falseTitle, kind: .secondary) {
                    withAnimation(.easeOut(duration: 0.25)) { quiz.answer(false) }
                }
            }
            .transition(.opacity)
        }
    }
}

// MARK: - Preview

#Preview("Screen 12 · True or False", traits: .fixedLayout(width: 874, height: 402)) {
    ZStack {
        Image("background_dimmed")
            .resizable()
            .interpolation(.none)
            .scaledToFill()
        GameCardOverlay {
            TP1Screen12_TrueOrFalseView(viewModel: TP1GeneratorViewModel(startAt: .trueOrFalse))
        }
    }
}
