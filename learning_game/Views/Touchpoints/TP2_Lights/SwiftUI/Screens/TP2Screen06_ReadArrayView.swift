//
//  TP2Screen06_ReadArrayView.swift
//  learning_game
//
//  Touchpoint 2 — Screen 6 "Read the Array" (new challenge, laid out like
//  the TP1 Data Types matcher). Match each index expression to the value it
//  reads: schedule[0] → .on, [1] → .dim, [2] → .off, [3] → out of range.
//  Tap an index, then its value (or the other way round). Each pair gets
//  its own colour; Check → green / red borders → Next or Try again.
//

import SwiftUI

struct TP2Screen06_ReadArrayView: View {
    @Bindable var viewModel: TP2LightsViewModel

    @State private var appeared = false
    @State private var wrongShake: CGFloat = 0

    private var quiz: TP2MatchViewModel { viewModel.readArray }
    private var content: TP2ReadArrayContent { quiz.content }

    // TP1 matcher grid geometry (card coordinates).
    private let chipSize = CGSize(width: 104, height: 40)
    private let columnX: [CGFloat] = [520, 640]
    private let firstRowY: CGFloat = 100
    private let rowStep: CGFloat = 50

    var body: some View {
        GameCardChrome(onClose: viewModel.close) {
            ZStack(alignment: .topLeading) {
                GameCardTitle(title: content.title, subtitle: content.subtitle)
                    .offset(x: 35, y: 24)

                lesson
                    .frame(width: 450, alignment: .leading)
                    .offset(x: 34, y: 100)

                grid

                footerButton
                    .frame(maxWidth: .infinity)
                    .offset(y: 317)
            }
        }
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.96)
        .onAppear { withAnimation(.easeOut(duration: 0.25)) { appeared = true } }
        .sensoryFeedback(.selection, trigger: quiz.pairs)
        .sensoryFeedback(trigger: quiz.checkCount) { _, _ in quiz.isSolved ? .success : .error }
        .onChange(of: quiz.pairs) { RetroSFX.shared.playTick() }
        .onChange(of: quiz.checkCount) {
            if case .wrong = quiz.result {
                withAnimation(.linear(duration: 0.4)) { wrongShake += 1 }
                RetroSFX.shared.playBack()
            } else if quiz.isSolved {
                RetroSFX.shared.playSuccess()
            }
        }
    }

    // MARK: Left — code, explanation, exercise

    private var lesson: some View {
        VStack(alignment: .leading, spacing: 12) {
            GameCodeText(code: content.code, size: 12, bold: true)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 4).fill(GameColor.black))

            Text(content.explanation)
                .font(GameFont.bodySm)
                .foregroundStyle(GameColor.white)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            Group {
                switch quiz.result {
                case .correct:
                    GameFeedbackLine(isSuccess: true, text: content.successFeedback)
                case .wrong:
                    GameFeedbackLine(isSuccess: false, text: content.wrongFeedback)
                case .unchecked:
                    Text("\(Text(content.taskLabel).foregroundStyle(GameColor.accent)) \(content.taskText)")
                        .font(GameFont.bodySmBold)
                        .foregroundStyle(GameColor.white)
                }
            }
            .frame(height: 20, alignment: .leading)
            .transition(.opacity)
        }
    }

    // MARK: Right — 4 × 2 grid

    private var grid: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(content.left.enumerated()), id: \.element.id) { row, item in
                let paired = quiz.pairs[item.id] != nil
                GameChip(text: item.text,
                         fill: paired ? Self.pairColor(item.id) : GameColor.black,
                         border: border(left: item.id),
                         pulses: !quiz.hasStarted && row == 0)
                    .frame(width: chipSize.width, height: chipSize.height)
                    .modifier(GameShake(animatableData: quiz.result.isWrong(item.id) ? wrongShake : 0))
                    .onTapGesture { withAnimation(.snappy(duration: 0.2)) { quiz.tapLeft(item.id) } }
                    .offset(x: columnX[0], y: firstRowY + CGFloat(row) * rowStep)
                    .accessibilityAddTraits(.isButton)
            }
            ForEach(Array(content.right.enumerated()), id: \.element.id) { shuffledRow, item in
                let left = quiz.left(pairedWith: item.id)
                // Once solved, each value slides next to its index so every row reads
                // correctly (schedule[0] .on, schedule[1] .dim, …).
                let row = quiz.isSolved ? (left.flatMap { id in content.left.firstIndex { $0.id == id } } ?? shuffledRow)
                                        : shuffledRow
                GameChip(text: item.text,
                         fill: left.map(Self.pairColor) ?? GameColor.black,
                         border: border(right: item.id, pairedLeft: left),
                         pulses: false)
                    .frame(width: chipSize.width, height: chipSize.height)
                    .modifier(GameShake(animatableData: left.map(quiz.result.isWrong) == true ? wrongShake : 0))
                    .onTapGesture { withAnimation(.snappy(duration: 0.2)) { quiz.tapRight(item.id) } }
                    .offset(x: columnX[1], y: firstRowY + CGFloat(row) * rowStep)
                    .animation(.spring(duration: 0.5, bounce: 0.2), value: quiz.isSolved)
                    .accessibilityAddTraits(.isButton)
            }
        }
    }

    private func border(left id: Int) -> GameChip.Border {
        if quiz.selectedLeft == id { return .selected }
        guard quiz.pairs[id] != nil else { return .idle }
        return checked(id)
    }

    private func border(right id: Int, pairedLeft: Int?) -> GameChip.Border {
        if quiz.selectedRight == id { return .selected }
        guard let left = pairedLeft else { return .idle }
        return checked(left)
    }

    private func checked(_ left: Int) -> GameChip.Border {
        switch quiz.result {
        case .unchecked: .paired
        case .correct: .correct
        case .wrong(let ids): ids.contains(left) ? .wrong : .correct
        }
    }

    /// Each pair keeps the colour of its index row. No Burgundy here: next to the
    /// Error red borders it read like a wrong answer.
    static func pairColor(_ id: Int) -> Color {
        switch id {
        case 0: GameColor.accent2
        case 1: GameColor.sage
        case 2: GameColor.mauve
        default: GameColor.midnight.opacity(0.7)
        }
    }

    // MARK: Footer

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
            .disabled(!quiz.allPaired)
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }
}

// MARK: - Preview

#Preview("TP2 · Screen 6 · Read the Array", traits: .fixedLayout(width: 874, height: 402)) {
    ZStack {
        Image("background_dimmed").resizable().interpolation(.none).scaledToFill()
        GameCardOverlay {
            TP2Screen06_ReadArrayView(viewModel: TP2LightsViewModel(startAt: .readArray))
        }
    }
}
