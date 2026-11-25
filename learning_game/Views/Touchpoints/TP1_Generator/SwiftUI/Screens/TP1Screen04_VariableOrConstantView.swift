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

    /// Slider fill once a column has been answered (Mauve → violet).
    private static let answeredTint = GameColor.mauve.mix(with: GameColor.accent2, by: 0.45)

    // Layout from the Figma (iPhone 17 - 10 idle / iPhone 17 - 34 feedback), in card points.
    private let columnWidth: CGFloat = 330
    private let leftX: CGFloat = 26
    private let rightX: CGFloat = 404

    var body: some View {
        GameCardChrome(onClose: viewModel.close) {
            ZStack(alignment: .topLeading) {
                GameCardTitle(title: content.title, subtitle: content.subtitle)
                    .offset(x: 28, y: 24)

                variableColumn
                    .frame(width: columnWidth, alignment: .leading)
                    .offset(x: leftX, y: 105)

                Rectangle()
                    .fill(GameColor.ashGrey)
                    .frame(width: 1.5, height: 190)
                    .offset(x: 380, y: 99)

                constantColumn
                    .frame(width: columnWidth, alignment: .leading)
                    .offset(x: rightX, y: 105)

                TP1PillButton(title: content.buttonTitle, kind: .next, action: viewModel.goToNext)
                    .disabled(!viewModel.isPowerLevelCorrect)
                    .offset(x: GameLayout.card.width - TP1Footer.sideInset - 132, y: TP1Footer.buttonTop)
            }
        }
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.96)
        .onAppear { withAnimation(.easeOut(duration: 0.25)) { appeared = true } }
        .sensoryFeedback(.error, trigger: viewModel.constantChangeAttempts)
        .sensoryFeedback(.success, trigger: viewModel.isPowerLevelCorrect) { _, new in new }
        .onChange(of: viewModel.isPowerLevelCorrect) { _, new in
            if new { RetroSFX.shared.playSuccess() }
        }
        .onChange(of: viewModel.constantChangeAttempts) { RetroSFX.shared.playBack() }
        .task(id: viewModel.constantChangeAttempts) {
            guard viewModel.hasTriedChangingConstant else { return }
            withAnimation(.easeOut(duration: 0.15)) { showConstantError = true }
            withAnimation(.linear(duration: 0.4)) { errorShake += 1 }
            try? await Task.sleep(for: .seconds(3))
            withAnimation(.easeIn(duration: 0.3)) { showConstantError = false }
        }
    }

    // MARK: Left — var

    private var variableColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            explanation(keyword: content.variableKeyword, rest: content.variableExplanation)
                .frame(height: 44, alignment: .topLeading)

            TP1CodeLine(keyword: "var",
                        name: content.variableName,
                        value: viewModel.powerLevel,
                        status: viewModel.isPowerLevelCorrect ? .success : .normal)
                .padding(.top, 12)
                .animation(.snappy(duration: 0.2), value: viewModel.powerLevel)

            sliderRow(
                value: Binding(get: { viewModel.powerLevel },
                               set: { viewModel.setPowerLevel($0) }),
                range: content.variableRange,
                isLocked: false,
                showsHint: !viewModel.hasTouchedPowerLevel,
                tint: viewModel.isPowerLevelCorrect ? Self.answeredTint : GameColor.mauve
            )

            feedbackSlot {
                if viewModel.isPowerLevelCorrect {
                    feedback(isSuccess: true, text: content.variableSuccess)
                }
            }
        }
    }

    // MARK: Right — let

    private var constantColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            explanation(keyword: content.constantKeyword, rest: content.constantExplanation)
                .frame(height: 44, alignment: .topLeading)

            TP1CodeLine(keyword: "let",
                        name: content.constantName,
                        value: content.constantValue,
                        status: showConstantError ? .error : .normal)
                .modifier(GameShake(animatableData: errorShake))
                .padding(.top, 12)

            sliderRow(
                value: .constant(content.constantValue),
                range: content.constantRange,
                isLocked: true,
                tint: showConstantError ? Self.answeredTint : GameColor.mauve
            )

            feedbackSlot {
                if showConstantError {
                    feedback(isSuccess: false, text: content.constantError)
                }
            }
        }
    }

    // MARK: Pieces

    /// "A **variable** is a container…" with the keyword in Accent.
    private func explanation(keyword: String, rest: String) -> some View {
        Text("A \(Text(keyword).foregroundStyle(GameColor.accent)) \(rest)")
            .font(GameFont.body)
            .foregroundStyle(GameColor.white)
            .lineSpacing(1)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// Big check / cross + caption under the slider (wraps to two lines).
    private func feedback(isSuccess: Bool, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            GameFeedbackIcon(isSuccess: isSuccess, size: 20)
            Text(text)
                .font(GameFont.bodySm)
                .foregroundStyle(isSuccess ? GameColor.success : GameColor.error)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.leading, 4)
    }

    /// Fixed-height area under the slider for the success / error caption.
    private func feedbackSlot<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        ZStack(alignment: .topLeading) {
            content().transition(.opacity.combined(with: .move(edge: .top)))
        }
        .frame(width: columnWidth, height: 42, alignment: .topLeading)
        .padding(.top, 6)
    }

    private func sliderRow(value: Binding<Int>,
                           range: ClosedRange<Int>,
                           isLocked: Bool,
                           showsHint: Bool = false,
                           tint: Color) -> some View {
        // "0" at x 2, track 19…295, max label at x 302 (column coordinates).
        ZStack(alignment: .leading) {
            Text(String(range.lowerBound))
                .fixedSize()
                .offset(x: 2)
            GameSlider(value: value,
                      range: range,
                      isLocked: isLocked,
                      showsHint: showsHint,
                      onLockedAttempt: viewModel.attemptToChangeConstant,
                      tint: tint)
                .frame(width: 276)
                .offset(x: 19)
            Text(String(range.upperBound))
                .fixedSize()
                .offset(x: 302)
        }
        .frame(width: columnWidth, height: 44, alignment: .leading)
        .font(GameFont.body)
        .foregroundStyle(GameColor.white)
        .padding(.top, 8)
    }
}

// MARK: - Preview

#Preview("Screen 4 · Variable or Constant", traits: .fixedLayout(width: 874, height: 402)) {
    ZStack {
        Image("background_dimmed")
            .resizable()
            .interpolation(.none)
            .scaledToFill()
        GameCardOverlay {
            TP1Screen04_VariableOrConstantView(viewModel: TP1GeneratorViewModel(startAt: .variableOrConstant))
        }
    }
}

