//
//  TP1Screen05_DataTypesView.swift
//  learning_game
//
//  Touchpoint 1 — Screens 5, 6 and 7 "Data Types" (one card, three states):
//    Screen 5 — empty grid: tap a value, then its type, to wire a pair.
//    Screen 6 — all 4 pairs wired (each pair gets its own color) → Check.
//    Screen 7 — checked: borders turn Success green → Next.
//  Wrong pairs get an Error border + shake and a "Try again" button that
//  clears only the wrong pairs.
//

import SwiftUI

struct TP1Screen05_DataTypesView: View {
    @Bindable var viewModel: TP1GeneratorViewModel

    @State private var appeared = false
    @State private var wrongShake: CGFloat = 0

    private var content: TP1DataTypesContent { viewModel.dataTypes }

    // Figma grid geometry (card coordinates).
    private let chipSize = CGSize(width: 88, height: 40)
    private let columnX: [CGFloat] = [541, 650]
    private let firstRowY: CGFloat = 104
    private let rowStep: CGFloat = 52

    var body: some View {
        GameCardChrome(onClose: viewModel.close) {
            ZStack(alignment: .topLeading) {
                GameCardHeader(title: content.title, subtitle: content.subtitle)
                    .offset(x: 26, y: 21)

                lesson
                    .frame(width: 470, alignment: .leading)
                    .offset(x: 34, y: 121)

                grid

                footerButton
                    .frame(maxWidth: .infinity)
                    .offset(y: 317)
            }
        }
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.96)
        .onAppear { withAnimation(.easeOut(duration: 0.25)) { appeared = true } }
        .sensoryFeedback(.selection, trigger: viewModel.pairs.count)
        .sensoryFeedback(trigger: viewModel.checkCount) { _, _ in
            viewModel.matchResult == .correct ? .success : .error
        }
        .onChange(of: viewModel.checkCount) {
            if case .wrong = viewModel.matchResult {
                withAnimation(.linear(duration: 0.4)) { wrongShake += 1 }
            }
        }
    }

    // MARK: Left — explanation, rules, exercise

    private var lesson: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(content.intro)
                .font(GameFont.body)
                .foregroundStyle(GameColor.white)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .frame(width: 445, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                ForEach(content.rules) { rule in
                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        Circle()
                            .fill(GameColor.accent)
                            .frame(width: 4, height: 4)
                            .alignmentGuide(.firstTextBaseline) { $0[.bottom] + 4 }
                            .frame(width: 12, alignment: .leading)
                            .padding(.leading, 10)
                        Text(rule.type.rawValue)
                            .font(GameFont.bodyBold)
                            .foregroundStyle(Self.labelColor(rule.type))
                            .frame(width: 64, alignment: .leading)
                        Text("— \(rule.description)")
                            .font(GameFont.body)
                            .foregroundStyle(GameColor.white)
                    }
                }
            }
            .padding(.top, 16)

            exerciseOrFeedback
                .frame(height: 20, alignment: .leading)
                .padding(.top, 7)
        }
    }

    @ViewBuilder
    private var exerciseOrFeedback: some View {
        if case .wrong = viewModel.matchResult {
            GameFeedbackLine(isSuccess: false, text: content.wrongFeedback)
                .transition(.opacity)
        } else {
            Text("\(Text(content.exerciseLabel).foregroundStyle(GameColor.accent)) \(content.exerciseText)")
                .font(GameFont.bodyBold)
                .foregroundStyle(GameColor.white)
                .transition(.opacity)
        }
    }

    // MARK: Right — 4 × 2 chip grid

    private var grid: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(content.values.enumerated()), id: \.element.id) { row, value in
                valueChip(value, row: row)
                    .offset(x: columnX[0], y: firstRowY + CGFloat(row) * rowStep)
            }
            ForEach(Array(content.types.enumerated()), id: \.element) { row, type in
                typeChip(type)
                    .offset(x: columnX[1], y: firstRowY + CGFloat(row) * rowStep)
            }
        }
    }

    private func valueChip(_ value: TP1DataValue, row: Int) -> some View {
        let isPaired = viewModel.pairs[value.id] != nil
        let pulses = !viewModel.hasStartedMatching && row == 0
        return GameChip(text: value.text,
                       fill: isPaired ? Self.pairColor(value.id) : GameColor.black,
                       border: border(forValue: value.id),
                       pulses: pulses)
            .frame(width: chipSize.width, height: chipSize.height)
            .modifier(GameShake(animatableData: isWrong(value.id) ? wrongShake : 0))
            .onTapGesture { withAnimation(.snappy(duration: 0.2)) { viewModel.tapValue(value.id) } }
            .accessibilityAddTraits(.isButton)
    }

    private func typeChip(_ type: TP1DataType) -> some View {
        let pairedValue = viewModel.value(pairedWith: type)
        return GameChip(text: type.rawValue,
                       fill: pairedValue.map(Self.pairColor) ?? GameColor.black,
                       border: border(forType: type, pairedValue: pairedValue),
                       pulses: false)
            .frame(width: chipSize.width, height: chipSize.height)
            .modifier(GameShake(animatableData: pairedValue.map(isWrong) == true ? wrongShake : 0))
            .onTapGesture { withAnimation(.snappy(duration: 0.2)) { viewModel.tapType(type) } }
            .accessibilityAddTraits(.isButton)
    }

    // MARK: Footer button

    @ViewBuilder
    private var footerButton: some View {
        switch viewModel.matchResult {
        case .correct:
            GameButton(title: content.nextTitle, kind: .outline, action: viewModel.goToNext)
                .transition(.opacity)
        case .wrong:
            GameButton(title: content.tryAgainTitle) {
                withAnimation(.snappy(duration: 0.25)) { viewModel.retryPairs() }
            }
            .transition(.opacity)
        case .unchecked:
            if viewModel.allPaired {
                GameButton(title: content.checkTitle) {
                    withAnimation(.easeOut(duration: 0.25)) { viewModel.checkPairs() }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }

    // MARK: Styling helpers

    private func isWrong(_ id: TP1DataValue.ID) -> Bool {
        if case .wrong(let ids) = viewModel.matchResult { return ids.contains(id) }
        return false
    }

    private func border(forValue id: TP1DataValue.ID) -> GameChip.Border {
        if viewModel.selectedValue == id { return .selected }
        guard viewModel.pairs[id] != nil else { return .idle }
        return checkedBorder(for: id)
    }

    private func border(forType type: TP1DataType, pairedValue: TP1DataValue.ID?) -> GameChip.Border {
        if viewModel.selectedType == type { return .selected }
        guard let id = pairedValue else { return .idle }
        return checkedBorder(for: id)
    }

    private func checkedBorder(for id: TP1DataValue.ID) -> GameChip.Border {
        switch viewModel.matchResult {
        case .unchecked: .paired
        case .correct: .correct
        case .wrong(let ids): ids.contains(id) ? .wrong : .correct
        }
    }

    /// Each pair keeps the color of its value row (Figma: Burgundy, Sage, Mauve, dark Midnight).
    static func pairColor(_ id: TP1DataValue.ID) -> Color {
        switch id {
        case 0: GameColor.burgundy
        case 1: GameColor.sage
        case 2: GameColor.mauve
        default: GameColor.midnight.opacity(0.7)
        }
    }

    /// Bullet label colors from the Figma.
    static func labelColor(_ type: TP1DataType) -> Color {
        switch type {
        case .int: GameColor.accent
        case .double: GameColor.info
        case .string: GameColor.success
        case .bool: GameColor.peach
        }
    }
}

// MARK: - Preview

#Preview("Screens 5–7 · Data Types", traits: .fixedLayout(width: 874, height: 402)) {
    ZStack {
        Image("background_dimmed")
            .resizable()
            .interpolation(.none)
            .scaledToFill()
        GameCardOverlay {
            TP1Screen05_DataTypesView(viewModel: TP1GeneratorViewModel(startAt: .dataTypes))
        }
    }
}
