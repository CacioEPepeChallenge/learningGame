//
//  TP1Screen04_VariableOrConstantView.swift
//  learning_game
//
//  Touchpoint 1 — Screen 4 "Variable or Constant".
//  Left: `var powerLevel` slider moves freely — drag it to 100 (Leo's notes).
//  Right: `let maxVoltage` slider is locked — it resists, springs back and
//  shows Swift's compiler error. Next unlocks once powerLevel == 100.
//

import SwiftUI

struct TP1Screen04_VariableOrConstantView: View {
    @Bindable var viewModel: TP1GeneratorViewModel

    @State private var appeared = false
    @State private var showConstantError = false
    @State private var errorShake: CGFloat = 0

    private var content: TP1VariableOrConstantContent { viewModel.variableOrConstant }

    var body: some View {
        GameCardChrome(onClose: viewModel.close) {
            ZStack(alignment: .topLeading) {
                GameCardTitle(title: content.title, subtitle: content.subtitle)
                    .offset(x: 33, y: 26)

                variableColumn
                    .frame(width: 340, alignment: .leading)
                    .offset(x: 33, y: 107)

                Rectangle()
                    .fill(GameColor.ashGrey)
                    .frame(width: 1.5, height: 189)
                    .offset(x: 385.5, y: 100)

                constantColumn
                    .frame(width: 340, alignment: .leading)
                    .offset(x: 410, y: 107)

                GameButton(title: content.buttonTitle, kind: .outline, action: viewModel.goToNext)
                    .disabled(!viewModel.isPowerLevelCorrect)
                    .frame(maxWidth: .infinity)
                    .offset(y: 317)
            }
        }
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.96)
        .onAppear { withAnimation(.easeOut(duration: 0.25)) { appeared = true } }
        .sensoryFeedback(.error, trigger: viewModel.constantChangeAttempts)
        .sensoryFeedback(.success, trigger: viewModel.isPowerLevelCorrect) { _, new in new }
        .task(id: viewModel.constantChangeAttempts) {
            guard viewModel.hasTriedChangingConstant else { return }
            withAnimation(.easeOut(duration: 0.15)) { showConstantError = true }
            withAnimation(.linear(duration: 0.4)) { errorShake += 1 }
            try? await Task.sleep(for: .seconds(2.5))
            withAnimation(.easeIn(duration: 0.3)) { showConstantError = false }
        }
    }

    // MARK: Left — var

    private var variableColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            explanation(keyword: content.variableKeyword, rest: content.variableExplanation)
                .frame(height: 44, alignment: .topLeading)

            GameCodeBox(keyword: "var",
                       name: content.variableName,
                       value: viewModel.powerLevel,
                       status: viewModel.isPowerLevelCorrect ? .success : .normal)
                .frame(width: 291)
                .padding(.top, 22)
                .animation(.snappy(duration: 0.2), value: viewModel.powerLevel)

            feedbackSlot {
                if viewModel.isPowerLevelCorrect {
                    GameFeedbackLine(isSuccess: true, text: content.variableSuccess)
                } else {
                    taskLine
                }
            }

            sliderRow(
                value: Binding(get: { viewModel.powerLevel },
                               set: { viewModel.setPowerLevel($0) }),
                range: content.variableRange,
                isLocked: false,
                showsHint: !viewModel.hasTouchedPowerLevel,
                highlightsMax: !viewModel.isPowerLevelCorrect
            )
        }
    }

    // MARK: Right — let

    private var constantColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            explanation(keyword: content.constantKeyword, rest: content.constantExplanation)
                .frame(height: 44, alignment: .topLeading)

            GameCodeBox(keyword: "let",
                       name: content.constantName,
                       value: content.constantValue,
                       status: showConstantError ? .error : .normal)
                .frame(width: 291)
                .modifier(GameShake(animatableData: errorShake))
                .padding(.top, 22)

            feedbackSlot {
                if showConstantError {
                    GameFeedbackLine(isSuccess: false, text: content.constantError)
                }
            }

            sliderRow(
                value: .constant(content.constantValue),
                range: content.constantRange,
                isLocked: true
            )
        }
    }

    // MARK: Pieces

    /// "Task: Slide powerLevel to 100." — same style as the Figma's "Exercice:" line.
    private var taskLine: some View {
        Text("\(Text(content.taskLabel).foregroundStyle(GameColor.accent)) \(content.taskText)")
            .font(GameFont.bodySmBold)
            .foregroundStyle(GameColor.white)
            .lineLimit(1)
    }

    /// "A **variable** is a container…" with the keyword in bold Accent.
    private func explanation(keyword: String, rest: String) -> some View {
        Text("A \(Text(keyword).font(GameFont.bodyBold).foregroundStyle(GameColor.accent)) \(rest)")
            .font(GameFont.body)
            .foregroundStyle(GameColor.white)
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// Fixed-height row under the code box for the success / error caption.
    private func feedbackSlot<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        ZStack(alignment: .leading) {
            content().transition(.opacity.combined(with: .move(edge: .top)))
        }
        .frame(width: 291, height: 16, alignment: .leading)
        .padding(.top, 0)
    }

    private func sliderRow(value: Binding<Int>,
                           range: ClosedRange<Int>,
                           isLocked: Bool,
                           showsHint: Bool = false,
                           highlightsMax: Bool = false) -> some View {
        // Fixed positions from the Figma: "0" at x 4, track 18…296, max label at x 301.
        ZStack(alignment: .leading) {
            Text(String(range.lowerBound))
                .fixedSize()
                .offset(x: 4)
            GameSlider(value: value,
                      range: range,
                      isLocked: isLocked,
                      showsHint: showsHint,
                      onLockedAttempt: viewModel.attemptToChangeConstant)
                .frame(width: 278)
                .offset(x: 18)
            // Target value: Accent + bold until reached.
            Text(String(range.upperBound))
                .font(highlightsMax ? GameFont.bodyBold : GameFont.body)
                .foregroundStyle(highlightsMax ? GameColor.accent : GameColor.white)
                .fixedSize()
                .offset(x: 301)
                .animation(.easeOut(duration: 0.25), value: highlightsMax)
        }
        .frame(width: 340, height: 44, alignment: .leading)
        .font(GameFont.body)
        .foregroundStyle(GameColor.white)
        .padding(.top, 2)
    }
}

// MARK: - Preview

#Preview("Screen 4 · Variable or Constant", traits: .fixedLayout(width: 874, height: 402)) {
    ZStack {
        Image("background")
            .resizable()
            .interpolation(.none)
            .scaledToFill()
        GameCardOverlay {
            TP1Screen04_VariableOrConstantView(viewModel: TP1GeneratorViewModel(startAt: .variableOrConstant))
        }
    }
}

