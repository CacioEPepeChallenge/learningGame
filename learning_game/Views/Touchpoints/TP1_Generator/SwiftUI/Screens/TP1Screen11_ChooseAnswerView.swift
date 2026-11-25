//
//  TP1Screen11_ChooseAnswerView.swift
//  learning_game
//
//  Touchpoint 1 — Screen 11 "Choose the Correct Answer".
//  Three code cards (Figma: 220 × 120 Black cards). Tap one, then Check.
//  The chosen card shows "✓ CORRECT!" (Success) or "✕ NOT QUITE" (Error)
//  with an explanation; wrong → Try again, right → Next.
//

import SwiftUI

struct TP1Screen11_ChooseAnswerView: View {
    @Bindable var viewModel: TP1GeneratorViewModel

    @State private var appeared = false
    @State private var wrongShake: CGFloat = 0

    private var quiz: TP1ChoiceViewModel { viewModel.chooseAnswer }
    private var content: TP1ChoiceContent { quiz.content }

    // Figma geometry (card coordinates).
    private let optionX: [CGFloat] = [50, 290, 530]
    private let optionY: CGFloat = 136
    private let optionSize = CGSize(width: 220, height: 120)

    var body: some View {
        GameCardChrome(onClose: viewModel.close) {
            ZStack(alignment: .topLeading) {
                GameCardTitle(title: content.title, subtitle: content.subtitle)
                    .offset(x: 35, y: 24)

                ForEach(Array(content.options.enumerated()), id: \.element.id) { index, option in
                    optionCard(option)
                        .frame(width: optionSize.width, height: optionSize.height)
                        .offset(x: optionX[index], y: optionY)
                }

                feedback
                    .frame(maxWidth: .infinity)
                    .frame(height: 20)
                    .offset(y: 266)

                footerButton
                    .frame(maxWidth: .infinity)
                    .offset(y: 300)
            }
        }
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.96)
        .onAppear { withAnimation(.easeOut(duration: 0.25)) { appeared = true } }
        .sensoryFeedback(.selection, trigger: quiz.selected)
        .sensoryFeedback(trigger: quiz.checkCount) { _, _ in
            quiz.result == .correct ? .success : .error
        }
        .onChange(of: quiz.checkCount) {
            if quiz.result == .wrong { withAnimation(.linear(duration: 0.4)) { wrongShake += 1 } }
        }
    }

    // MARK: Option card

    private func optionCard(_ option: TP1ChoiceOption) -> some View {
        let shape = RoundedRectangle(cornerRadius: 3)
        let isSelected = quiz.selected == option.id
        let verdict: TP1QuizResult = isSelected ? quiz.result : .unanswered
        let border: Color = switch verdict {
        case .correct: GameColor.success
        case .wrong: GameColor.error
        case .unanswered: isSelected ? GameColor.accent : GameColor.slateGrey
        }

        return VStack(alignment: .leading, spacing: 10) {
            if verdict != .unanswered {
                HStack(spacing: 10) {
                    GameFeedbackIcon(isSuccess: verdict == .correct, size: 20)
                    Text((verdict == .correct ? content.correctLabel : content.wrongLabel).uppercased())
                        .font(GameFont.silkscreen(12))
                        .foregroundStyle(verdict == .correct ? GameColor.success : GameColor.error)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            GameCodeText(code: option.code, size: 14)
        }
        .padding(.horizontal, 15)
        .padding(.top, verdict == .unanswered ? 20 : 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(shape.fill(GameColor.black))
        .overlay(shape.strokeBorder(border, lineWidth: isSelected ? 2 : 1))
        .scaleEffect(isSelected && verdict == .unanswered ? 1.03 : 1)
        .modifier(GameShake(animatableData: verdict == .wrong ? wrongShake : 0))
        .contentShape(shape)
        .onTapGesture {
            withAnimation(.snappy(duration: 0.2)) { quiz.select(option.id) }
        }
        .animation(.snappy(duration: 0.25), value: verdict)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(option.code.replacingOccurrences(of: "\n", with: ", "))
    }

    // MARK: Feedback & footer

    @ViewBuilder
    private var feedback: some View {
        switch quiz.result {
        case .correct:
            TP1FeedbackLine(isSuccess: true, text: quiz.selectedOption?.explanation ?? "")
                .transition(.opacity)
        case .wrong:
            TP1FeedbackLine(isSuccess: false, text: quiz.selectedOption?.explanation ?? "")
                .transition(.opacity)
        case .unanswered:
            Text("\(Text(content.taskLabel).foregroundStyle(GameColor.accent)) \(content.taskText)")
                .font(GameFont.bodySmBold)
                .foregroundStyle(GameColor.white)
                .transition(.opacity)
        }
    }

    @ViewBuilder
    private var footerButton: some View {
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
            TP1ActionButton(title: content.checkTitle) {
                withAnimation(.easeOut(duration: 0.25)) { quiz.check() }
            }
            .disabled(quiz.selected == nil)
            .transition(.opacity)
        }
    }
}

// MARK: - Preview

#Preview("Screen 11 · Choose the Correct Answer", traits: .fixedLayout(width: 874, height: 402)) {
    ZStack {
        Image("background_dimmed")
            .resizable()
            .interpolation(.none)
            .scaledToFill()
        GameCardOverlay {
            TP1Screen11_ChooseAnswerView(viewModel: TP1GeneratorViewModel(startAt: .chooseAnswer))
        }
    }
}
