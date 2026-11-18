//
//  TP1Screen13_BoolSwitchView.swift
//  learning_game
//
//  Touchpoint 1 — Screen 13 "Boolean Switch" (Leo's note ③: coolingPump = true).
//  Same layout as Screen 10: picture box (the pump's rocker switch), code
//  panel with one blank, value chips on the right. Drag `true` into
//  `var coolingPump: Bool = [____]` to flip the switch ON. Afterwards the
//  switch is tappable and shows `coolingPump.toggle()` in the code.
//

import SwiftUI

struct TP1Screen13_BoolSwitchView: View {
    @Bindable var viewModel: TP1GeneratorViewModel

    @State private var appeared = false
    @State private var blankFrame: CGRect = .zero
    @State private var dragging: TP1BoolChoice.ID?
    @State private var dragTranslation: CGSize = .zero
    @State private var dragLocation: CGPoint?
    @State private var hintPulse = false

    private var puzzle: TP1BoolSwitchViewModel { viewModel.boolSwitch }
    private var content: TP1BoolSwitchContent { puzzle.content }

    // Same geometry as Screen 10 ("Fix the function").
    private let panelFrame = CGRect(x: 200, y: 107, width: 380, height: 161)
    private let chipX: CGFloat = 619
    private let chipY: CGFloat = 116
    private let chipSize = CGSize(width: 102, height: 36)
    private let chipStep: CGFloat = 44

    var body: some View {
        GameCardChrome(onClose: viewModel.close) {
            ZStack(alignment: .topLeading) {
                GameCardTitle(title: content.title, subtitle: content.subtitle)
                    .offset(x: 35, y: 24)

                TP1PumpSwitch(isOn: puzzle.isPumpOn,
                              state: switchState,
                              isTappable: puzzle.isSolved,
                              onTap: { withAnimation(.snappy(duration: 0.25)) { puzzle.toggle() } })
                    .frame(width: 133, height: 126)
                    .offset(x: 32, y: 128)

                codePanel
                    .frame(width: panelFrame.width, height: panelFrame.height)
                    .offset(x: panelFrame.minX, y: panelFrame.minY)

                chips

                feedback
                    .frame(width: panelFrame.width, height: 20)
                    .offset(x: panelFrame.minX, y: 278)

                footerButton
                    .frame(maxWidth: .infinity)
                    .offset(y: 317)
            }
            .coordinateSpace(.named("tp1card"))
        }
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.96)
        .onAppear {
            withAnimation(.easeOut(duration: 0.25)) { appeared = true }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) { hintPulse = true }
        }
        .sensoryFeedback(.selection, trigger: puzzle.placed)
        .sensoryFeedback(.impact(weight: .medium), trigger: puzzle.toggleCount)
        .sensoryFeedback(trigger: puzzle.checkCount) { _, _ in
            puzzle.isSolved ? .success : .error
        }
    }

    private var switchState: TP1VisualState {
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

            HStack(spacing: 0) {
                Text("var")
                    .font(GameFont.bodySmBold)
                    .foregroundStyle(GameColor.accent)
                Text(" \(content.name): Bool = ")
                    .font(GameFont.bodySm)
                    .foregroundStyle(GameColor.white)
                blank
            }

            Text(puzzle.compilerError ?? " ")
                .font(GameFont.play(10))
                .foregroundStyle(GameColor.error)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(height: 16, alignment: .leading)
                .padding(.top, 3)
                .padding(.bottom, 6)

            // After solving: show the .toggle() playground.
            if puzzle.isSolved {
                if puzzle.toggleCount > 0 {
                    HStack(spacing: 0) {
                        Text("\(content.name).toggle()")
                            .font(GameFont.bodySm)
                            .foregroundStyle(GameColor.white)
                        Text("  // now \(puzzle.isPumpOn ? "true" : "false")")
                            .font(GameFont.play(13))
                            .foregroundStyle(puzzle.isPumpOn ? GameColor.success : GameColor.error)
                            .contentTransition(.opacity)
                    }
                    .transition(.opacity)
                } else {
                    Text("// \(content.toggleHint)")
                        .font(GameFont.play(13))
                        .foregroundStyle(GameColor.info)
                        .transition(.opacity)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(shape.fill(GameColor.black))
        .overlay(shape.strokeBorder(puzzle.isSolved ? GameColor.success : GameColor.ashGrey, lineWidth: 1))
        .animation(.easeOut(duration: 0.25), value: puzzle.result)
        .animation(.easeOut(duration: 0.25), value: puzzle.toggleCount)
    }

    private var blank: some View {
        let shape = RoundedRectangle(cornerRadius: 3)
        let isTarget = dragging != nil && blankFrame.insetBy(dx: -10, dy: -10).contains(dragLocation ?? .zero)
        let showHint = puzzle.placed == nil && puzzle.result == .unchecked
        let border: Color = isTarget || showHint ? GameColor.accent
            : puzzle.result == .wrong ? GameColor.error
            : puzzle.isSolved ? GameColor.success
            : .clear

        return ZStack {
            shape.fill(GameColor.midnight.opacity(0.7))
            if let choice = puzzle.placedChoice {
                Text(choice.text)
                    .font(GameFont.bodySmBold)
                    .foregroundStyle(GameColor.white)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
        }
        .frame(width: 86, height: 30)
        .overlay(shape.strokeBorder(border, lineWidth: isTarget ? 2 : 1)
                    .opacity(showHint && !isTarget ? (hintPulse ? 1 : 0.2) : 1))
        .contentShape(shape)
        .onTapGesture { withAnimation(.snappy(duration: 0.25)) { puzzle.clear() } }
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named("tp1card")) } action: {
            blankFrame = $0
        }
        .accessibilityLabel("coolingPump value: \(puzzle.placedChoice?.text ?? "empty")")
    }

    // MARK: Value chips

    private var chips: some View {
        ForEach(Array(content.choices.enumerated()), id: \.element.id) { index, choice in
            ZStack {
                if puzzle.placed == choice.id {
                    GameBlockPlaceholder()
                } else {
                    GameCodeBlockLabel(text: choice.text)
                        .scaleEffect(dragging == choice.id ? 1.1 : 1)
                        .shadow(color: GameColor.black.opacity(dragging == choice.id ? 0.6 : 0), radius: 6, y: 3)
                        .offset(dragging == choice.id ? dragTranslation : .zero)
                        .gesture(dragGesture(for: choice.id))
                        .onTapGesture {
                            withAnimation(.snappy(duration: 0.25)) { puzzle.place(choice.id) }
                        }
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                        .accessibilityLabel("Value \(choice.text)")
                        .accessibilityAddTraits(.isButton)
                }
            }
            .frame(width: chipSize.width, height: chipSize.height)
            .offset(x: chipX, y: chipY + CGFloat(index) * chipStep)
            .zIndex(dragging == choice.id ? 1 : 0)
        }
    }

    private func dragGesture(for id: TP1BoolChoice.ID) -> some Gesture {
        DragGesture(minimumDistance: 6, coordinateSpace: .named("tp1card"))
            .onChanged { value in
                guard !puzzle.isSolved else { return }
                dragging = id
                dragTranslation = value.translation
                dragLocation = value.location
            }
            .onEnded { value in
                let hit = blankFrame.insetBy(dx: -10, dy: -10).contains(value.location)
                withAnimation(.snappy(duration: 0.25)) {
                    if hit { puzzle.place(id) }
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
            if puzzle.isPumpOn {
                GameFeedbackLine(isSuccess: true, text: content.successFeedback)
                    .transition(.opacity)
            } else {
                GameFeedbackLine(isSuccess: false, text: content.pumpOffWarning)
                    .transition(.opacity)
            }
        case .wrong:
            GameFeedbackLine(isSuccess: false, text: puzzle.placedChoice?.feedback ?? "")
                .transition(.opacity)
        case .unchecked:
            Text("\(Text(content.taskLabel).foregroundStyle(GameColor.accent)) \(content.taskText)")
                .font(GameFont.bodySmBold)
                .foregroundStyle(GameColor.white)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .transition(.opacity)
        }
    }

    @ViewBuilder
    private var footerButton: some View {
        switch puzzle.result {
        case .correct:
            GameButton(title: content.nextTitle, kind: .outline, action: viewModel.goToNext)
                .disabled(!puzzle.canContinue)
                .transition(.opacity)
        case .wrong:
            GameButton(title: content.tryAgainTitle) {
                withAnimation(.snappy(duration: 0.25)) { puzzle.retry() }
            }
            .transition(.opacity)
        case .unchecked:
            if puzzle.placed != nil {
                GameButton(title: content.checkTitle) {
                    withAnimation(.easeOut(duration: 0.25)) { puzzle.check() }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }
}

// MARK: - Pump switch visual

/// The cooling pump's rocker switch (`part_switch_off` / `part_switch_on`).
struct TP1PumpSwitch: View {
    let isOn: Bool
    let state: TP1VisualState
    let isTappable: Bool
    let onTap: () -> Void

    @State private var shake: CGFloat = 0
    @State private var pulse = false

    private var caption: String {
        if state == .error { return "PUMP ERROR" }
        return isOn ? "PUMP ON" : "PUMP OFF"
    }

    private var tint: Color {
        if state == .error { return GameColor.error }
        return isOn ? GameColor.success : GameColor.ashGrey
    }

    var body: some View {
        let box = RoundedRectangle(cornerRadius: 3)
        ZStack(alignment: .top) {
            box.fill(GameColor.black)

            // Soft Success glow behind the switch when the pump runs.
            RadialGradient(colors: [GameColor.success.opacity(isOn ? 0.45 : 0), .clear],
                           center: .center, startRadius: 0, endRadius: 60)

            PixelImage(isOn ? "part_switch_on" : "part_switch_off")
                .frame(width: 84, height: 84)
                .padding(.top, 8)
                .scaleEffect(isTappable && pulse ? 1.05 : 1)
                .modifier(GameShake(amount: 5, animatableData: shake))

            Text(caption)
                .font(GameFont.silkscreen(9))
                .foregroundStyle(tint)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 10)
                .contentTransition(.opacity)
        }
        .clipShape(box)
        .overlay(box.strokeBorder(isOn ? GameColor.success : GameColor.ashGrey, lineWidth: 1))
        .shadow(color: GameColor.success.opacity(isOn ? 0.45 : 0), radius: 14)
        .contentShape(box)
        .onTapGesture { if isTappable { onTap() } }
        .animation(.snappy(duration: 0.25), value: isOn)
        .animation(.easeOut(duration: 0.3), value: state)
        .onChange(of: state) { _, new in
            if new == .error { withAnimation(.linear(duration: 0.4)) { shake += 1 } }
        }
        .onChange(of: isTappable, initial: true) { _, tappable in
            guard tappable else { return }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) { pulse = true }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Cooling pump switch, \(isOn ? "on" : "off")")
        .accessibilityAddTraits(isTappable ? .isButton : [])
    }
}

// MARK: - Preview

#Preview("Screen 13 · Boolean Switch", traits: .fixedLayout(width: 874, height: 402)) {
    ZStack {
        Image("background")
            .resizable()
            .interpolation(.none)
            .scaledToFill()
        GameCardOverlay {
            TP1Screen13_BoolSwitchView(viewModel: TP1GeneratorViewModel(startAt: .boolSwitch))
        }
    }
}
