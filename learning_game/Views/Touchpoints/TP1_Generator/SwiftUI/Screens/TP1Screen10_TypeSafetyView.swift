//
//  TP1Screen10_TypeSafetyView.swift
//  learning_game
//
//  Touchpoint 1 — Screen 10 "Type Safety" (Leo's note ②: overrideKey = "OMEGA").
//  Layout from Cards.png "Fix the function": picture box, code panel with
//  type blanks, and a column of type chips. Drag (or tap) a type into each
//  blank; a wrong type shows Swift's real compiler error under that line and
//  the monitor says ACCESS DENIED. Right types → OVERRIDE ACCEPTED.
//

import SwiftUI

struct TP1Screen10_TypeSafetyView: View {
    @Bindable var viewModel: TP1GeneratorViewModel

    @State private var appeared = false
    @State private var blankFrames: [TP1TypedLine.ID: CGRect] = [:]
    @State private var dragging: TP1DataType?
    @State private var dragTranslation: CGSize = .zero
    @State private var dragLocation: CGPoint?
    @State private var wrongShake: CGFloat = 0
    @State private var hintPulse = false

    private var puzzle: TP1TypeSafetyViewModel { viewModel.typeSafety }
    private var content: TP1TypeSafetyContent { puzzle.content }

    // Figma "Fix the function" geometry (card coordinates).
    private let panelFrame = CGRect(x: 200, y: 107, width: 380, height: 161)
    private let chipX: CGFloat = 619
    private let chipY: CGFloat = 116
    private let chipSize = CGSize(width: 102, height: 36)
    private let chipStep: CGFloat = 44
    private let blankSize = CGSize(width: 86, height: 30)

    var body: some View {
        GameCardChrome(onClose: viewModel.close) {
            ZStack(alignment: .topLeading) {
                GameCardTitle(title: content.title, subtitle: content.subtitle)
                    .offset(x: 35, y: 24)

                TP1OverrideMonitor(state: visualState)
                    .frame(width: 133, height: 126)
                    .offset(x: 32, y: 128)

                codePanel
                    .frame(width: panelFrame.width, height: panelFrame.height)
                    .offset(x: panelFrame.minX, y: panelFrame.minY)

                chips

                // Centered under the code panel so it never runs into the chips.
                feedback
                    .frame(width: panelFrame.width, height: 20)
                    .offset(x: panelFrame.minX, y: 278)

                // Check / Try again / Next all sit bottom-right, where Next appears.
                footerButton
                    .tp1FooterTrailing()
            }
            .coordinateSpace(.named("tp1card"))
        }
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.96)
        .onAppear {
            withAnimation(.easeOut(duration: 0.25)) { appeared = true }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) { hintPulse = true }
        }
        .sensoryFeedback(.selection, trigger: puzzle.blanks)
        .sensoryFeedback(trigger: puzzle.checkCount) { _, _ in
            puzzle.isSolved ? .success : .error
        }
        .onChange(of: puzzle.blanks) { RetroSFX.shared.playTick() }
        .onChange(of: puzzle.checkCount) {
            if case .wrong = puzzle.result {
                withAnimation(.linear(duration: 0.4)) { wrongShake += 1 }
                RetroSFX.shared.playBack()
            } else if puzzle.isSolved {
                RetroSFX.shared.playSuccess()
            }
        }
    }

    private var visualState: TP1VisualState {
        switch puzzle.result {
        case .unchecked: .idle
        case .correct: .success
        case .wrong: .error
        }
    }

    // MARK: Code panel

    private var codePanel: some View {
        let shape = RoundedRectangle(cornerRadius: 4)
        return VStack(alignment: .leading, spacing: 0) {
            Text(content.comment)
                .font(GameFont.play(13))
                .foregroundStyle(GameColor.ashGrey)
                .padding(.bottom, 14)

            ForEach(content.lines) { line in
                codeLine(line)
                // Fixed row for the compiler error so nothing jumps.
                Text(puzzle.compilerError(for: line) ?? " ")
                    .font(GameFont.play(12))
                    .foregroundStyle(GameColor.error)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(height: 16, alignment: .leading)
                    .padding(.top, 3)
                    .padding(.bottom, 6)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(shape.fill(GameColor.black))
        .overlay(shape.strokeBorder(puzzle.isSolved ? GameColor.success : GameColor.ashGrey, lineWidth: 1))
        .animation(.easeOut(duration: 0.25), value: puzzle.result)
    }

    /// `let overrideKey: [____] = "OMEGA"`
    private func codeLine(_ line: TP1TypedLine) -> some View {
        HStack(spacing: 0) {
            Text(line.keyword)
                .font(GameFont.bodySmBold)
                .foregroundStyle(GameColor.accent)
            Text(" \(line.name): ")
                .font(GameFont.bodySm)
                .foregroundStyle(GameColor.white)
            blank(line)
            Text(" = \(line.value)")
                .font(GameFont.bodySm)
                .foregroundStyle(GameColor.white)
        }
    }

    private func blank(_ line: TP1TypedLine) -> some View {
        let shape = RoundedRectangle(cornerRadius: 3)
        let type = puzzle.blanks[line.id]
        let isTarget = dragging != nil && blankIndex(at: dragLocation) == line.id
        let showHint = !puzzle.hasStarted && line.id == content.lines.first?.id
        let border: Color = isTarget || showHint ? GameColor.accent
            : puzzle.isWrong(line.id) ? GameColor.error
            : puzzle.isSolved ? GameColor.success
            : .clear

        return ZStack {
            shape.fill(GameColor.midnight.opacity(0.7))
            if let type {
                Text(type.rawValue)
                    .font(GameFont.bodySmBold)
                    .foregroundStyle(GameColor.white)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
        }
        .frame(width: blankSize.width, height: blankSize.height)
        .overlay(shape.strokeBorder(border, lineWidth: isTarget ? 2 : 1)
                    .opacity(showHint ? (hintPulse ? 1 : 0.2) : 1))
        .modifier(GameShake(amount: 4, animatableData: puzzle.isWrong(line.id) ? wrongShake : 0))
        .contentShape(shape)
        .onTapGesture {
            withAnimation(.snappy(duration: 0.25)) { puzzle.clear(line.id) }
        }
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named("tp1card")) } action: {
            blankFrames[line.id] = $0
        }
        .accessibilityLabel("\(line.name) type: \(type?.rawValue ?? "empty")")
    }

    private func blankIndex(at point: CGPoint?) -> TP1TypedLine.ID? {
        guard let point else { return nil }
        return blankFrames.first { $0.value.insetBy(dx: -10, dy: -10).contains(point) }?.key
    }

    // MARK: Type chips (right column)

    private var chips: some View {
        ForEach(Array(content.chips.enumerated()), id: \.element) { index, type in
            let used = puzzle.isUsed(type)
            ZStack {
                if used {
                    GameBlockPlaceholder()
                } else {
                    GameCodeBlockLabel(text: type.rawValue)
                        .scaleEffect(dragging == type ? 1.1 : 1)
                        .shadow(color: GameColor.black.opacity(dragging == type ? 0.6 : 0), radius: 6, y: 3)
                        .offset(dragging == type ? dragTranslation : .zero)
                        .gesture(dragGesture(for: type))
                        .onTapGesture {
                            withAnimation(.snappy(duration: 0.25)) { puzzle.place(type) }
                        }
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                        .accessibilityLabel("Type \(type.rawValue)")
                        .accessibilityAddTraits(.isButton)
                }
            }
            .frame(width: chipSize.width, height: chipSize.height)
            .offset(x: chipX, y: chipY + CGFloat(index) * chipStep)
            .zIndex(dragging == type ? 1 : 0)
        }
    }

    private func dragGesture(for type: TP1DataType) -> some Gesture {
        DragGesture(minimumDistance: 6, coordinateSpace: .named("tp1card"))
            .onChanged { value in
                guard !puzzle.isSolved else { return }
                dragging = type
                dragTranslation = value.translation
                dragLocation = value.location
            }
            .onEnded { value in
                let target = blankIndex(at: value.location)
                withAnimation(.snappy(duration: 0.25)) {
                    if let target { puzzle.place(type, in: target) }
                    dragging = nil
                    dragTranslation = .zero
                    dragLocation = nil
                }
            }
    }

    // MARK: Feedback & footer

    @ViewBuilder
    private var feedback: some View {
        switch puzzle.result {
        case .correct:
            TP1FeedbackLine(isSuccess: true, text: content.successFeedback)
                .transition(.opacity)
        case .wrong:
            TP1FeedbackLine(isSuccess: false, text: content.wrongFeedback)
                .transition(.opacity)
        case .unchecked:
            Text("\(Text(content.taskLabel).foregroundStyle(GameColor.accent)) \(content.taskText)")
                .font(GameFont.bodySmBold)
                .foregroundStyle(GameColor.white)
                .transition(.opacity)
        }
    }

    @ViewBuilder
    private var footerButton: some View {
        switch puzzle.result {
        case .correct:
            TP1NextButton(title: content.nextTitle, action: viewModel.goToNext)
                .transition(.opacity)
        case .wrong:
            TP1ActionButton(title: content.tryAgainTitle) {
                withAnimation(.snappy(duration: 0.25)) { puzzle.retry() }
            }
            .transition(.opacity)
        case .unchecked:
            // Greyed-out until every blank has a type, so the footer slot never goes empty.
            TP1ActionButton(title: content.checkTitle) {
                withAnimation(.easeOut(duration: 0.25)) { puzzle.check() }
            }
            .disabled(!puzzle.allFilled)
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }
}

// MARK: - Preview

#Preview("Screen 10 · Type Safety", traits: .fixedLayout(width: 874, height: 402)) {
    ZStack {
        Image("background_dimmed")
            .resizable()
            .interpolation(.none)
            .scaledToFill()
        GameCardOverlay {
            TP1Screen10_TypeSafetyView(viewModel: TP1GeneratorViewModel(startAt: .typeSafety))
        }
    }
}
