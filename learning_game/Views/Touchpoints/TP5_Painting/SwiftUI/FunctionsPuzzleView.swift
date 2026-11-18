//
//  FunctionsPuzzleView.swift
//  learning_game
//
//  Touchpoint 5 — Functions (the painting safe).
//  Standalone puzzle window that pops up over the room after the player
//  interacts with the painting. Built natively to match the UI mockups in
//  /references (Slide2–Slide9): dark navy window, pixel-font neon title,
//  numbered step dots, answer cards, dashed code blocks and the mauve "Check" pill.
//
//  Flow: intro → True/False → drag-and-drop assembly → painting_safe.gif success.
//

import SwiftUI

// MARK: - Theme (sampled from the mockups / Color.xcassets)

private enum UI {
    static let window       = Color(hex: 0x16202E)
    static let windowBorder = Color(hex: 0x9C7898)
    static let title        = Color(hex: 0x3AC5F7)   // neon blue pixel title
    static let text         = Color(hex: 0xFAFAFA)
    static let muted        = Color(hex: 0xCFCED4)
    static let subtle       = Color(hex: 0x948EA0)   // AshGrey
    static let card         = Color(hex: 0x151515)
    static let cardBorder   = Color(hex: 0x47465A)
    static let editorBorder = Color(hex: 0x65636C)
    static let block        = Color(hex: 0x403653)
    static let blockBorder  = Color(hex: 0x9C7E83)
    static let pill         = Color(hex: 0x85486D)
    static let nextRing     = Color(hex: 0x32A0C8)
    static let stepCurrent  = Color(hex: 0x9C7898)
    static let stepDone     = Color(hex: 0x71AC6F)   // Success
    static let stepTodo     = Color(hex: 0x68566E)
    static let error        = Color(hex: 0xE0708A)   // lighter Error for legibility on navy
    static let keyword      = Color(hex: 0xE3AC9D)   // Peach

    static func body(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }
}

private extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

// MARK: - Puzzle window

struct FunctionsPuzzleView: View {
    /// Called when the player taps Continue on the success screen.
    var onComplete: () -> Void = {}
    /// Called by the ✕ in the corner. The ✕ is hidden when this is nil.
    var onClose: (() -> Void)? = nil

    @State private var model = FunctionsPuzzleModel()
    @State private var shake: CGFloat = 0
    @State private var targetedSlot: Int?
    @State private var bankTargeted = false
    @State private var snapFlash: Int?

    /// Window size in the mockups (874×450 canvas → 780×360 window).
    private static let designSize = CGSize(width: 780, height: 360)

    var body: some View {
        GeometryReader { geo in
            let design = Self.designSize
            let scale = min(geo.size.width * 0.94 / design.width,
                            geo.size.height * 0.94 / design.height,
                            1.6)
            ZStack {
                // Swallow taps on the room behind the window.
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                    .onTapGesture {}

                window
                    .frame(width: design.width, height: design.height)
                    .scaleEffect(scale)
                    .frame(width: design.width * scale, height: design.height * scale)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .sensoryFeedback(.success, trigger: model.successPulse)
        .sensoryFeedback(.error, trigger: model.errorPulse)
        .sensoryFeedback(.impact(weight: .light), trigger: model.snapPulse)
        .onChange(of: model.errorPulse) {
            withAnimation(.linear(duration: 0.4)) { shake += 1 }
        }
    }

    private var window: some View {
        ZStack {
            Group {
                switch model.phase {
                case .intro:         intro
                case .interrogation: interrogation
                case .assembly:      assembly
                case .success:       success
                }
            }
            .id(model.phase)
            .transition(.opacity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(UI.window.opacity(0.97), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(UI.windowBorder.opacity(0.9), lineWidth: 1))
        .overlay(alignment: .topTrailing) {
            if let onClose {
                CloseButton(action: onClose)
                    .padding(.top, 20)
                    .padding(.trailing, 20)
            }
        }
    }

    // MARK: Shared chrome

    /// Pixel title + one-line instruction, positioned like the mockups.
    private func header(_ title: String, _ subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            PixelText(text: title, color: UI.title, pixel: 2, tracking: 2)
            Text(subtitle)
                .font(UI.body(15))
                .foregroundStyle(UI.text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.trailing, 40) // clear the ✕
    }

    private func stepDots(current: Int) -> some View {
        HStack(spacing: 4) {
            ForEach(1...3, id: \.self) { n in
                StepDot(number: n, state: n < current ? .done : n == current ? .current : .todo)
            }
        }
    }

    private var currentStep: Int {
        switch model.phase {
        case .intro, .interrogation: 1
        case .assembly: 2
        case .success: 4   // all three done
        }
    }

    // MARK: Intro (Slide 2)

    private var intro: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 26) {
                PixelSprite(name: "painting")
                    .frame(width: 180, height: 270)
                    .shadow(color: .black.opacity(0.5), radius: 10, y: 4)

                Text("execute unlockSafe() function to disengage deadbolts.")
                    .font(UI.body(15))
                    .foregroundStyle(UI.text)
                    .frame(width: 250, alignment: .leading)
                    .padding(.top, 48)
            }
            .padding(.leading, 60)
            .padding(.top, 14)

            Spacer(minLength: 0)

            PillButton(title: "Next", style: .next) {
                withAnimation(.easeInOut(duration: 0.25)) { model.begin() }
            }
            .padding(.bottom, 18)
        }
    }

    // MARK: Step 1 — True / False (Slides 4–5)

    private var interrogation: some View {
        VStack(alignment: .leading, spacing: 0) {
            header("Defining a function",
                   "Before the override unlocks, IRIS needs to know you understand functions.")

            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    stepDots(current: 1)
                        .padding(.top, 14)

                    Spacer(minLength: 0)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Statement: A Function is a reusable block of code defined once using the \(Text("func").foregroundStyle(UI.keyword).bold()) keyword, and then called by its name.")
                            .font(UI.body(15))
                            .foregroundStyle(UI.text)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)

                        feedback(model.verdict == .wrongAnswer
                                 ? "Access denied. Read the statement again."
                                 : nil)
                    }
                    .padding(.leading, 87)
                    .frame(width: 400, alignment: .leading)

                    Spacer(minLength: 0)
                }

                Spacer(minLength: 0)

                VStack(spacing: 14) {
                    AnswerCard(text: "True",
                               detail: "Define it once with func, then call it by name.",
                               state: cardState(for: true),
                               height: 80) { model.select(answer: true) }
                    AnswerCard(text: "False",
                               detail: "Functions must be rewritten every time they're used.",
                               state: cardState(for: false),
                               height: 86) { model.select(answer: false) }
                }
                .frame(width: 213)
                .padding(.top, 4)
                .padding(.trailing, 90)
                .modifier(Shake(animatableData: shake))
            }

            checkRow(title: "Check", enabled: model.selectedAnswer != nil) {
                withAnimation(.easeInOut(duration: 0.25)) { model.checkAnswer() }
            }
        }
        .padding(.leading, 33)
        .padding(.top, 28)
    }

    private func cardState(for answer: Bool) -> AnswerCard.State {
        guard model.selectedAnswer == answer else { return .idle }
        return model.verdict == .wrongAnswer ? .wrong : .selected
    }

    // MARK: Step 2 — Drag-and-drop assembly (Slides 6 & 8)

    private var assembly: some View {
        VStack(alignment: .leading, spacing: 0) {
            header("Calling the function",
                   "Define unlockSafe() with the bypass inside { }, then call it below the braces.")

            HStack(alignment: .top, spacing: 0) {
                stepDots(current: 2)
                    .padding(.top, 14)
                    .frame(width: 100, alignment: .leading)

                editor
                    .frame(width: 400, height: 172)
                    .padding(.top, 12)
                    .modifier(Shake(animatableData: shake))

                Spacer(minLength: 0)

                bank
                    .frame(width: 200)
                    .padding(.top, 6)
                    .padding(.trailing, 22)
            }

            Spacer(minLength: 0)

            checkRow(title: "Execute", enabled: model.allSlotsFilled) {
                withAnimation(.easeInOut(duration: 0.3)) { model.execute() }
            }
        }
        .padding(.leading, 33)
        .padding(.top, 28)
    }

    private var editor: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("// Define the function, then call it to run it")
                .font(UI.body(12))
                .foregroundStyle(UI.muted)
                .padding(.bottom, 2)

            codeLine {
                slot(0)
                slot(1)
                codeText("{")
            }
            codeLine(indent: 1) {
                slot(2)
            }
            codeLine {
                codeText("}")
            }
            codeLine {
                slot(3)
            }

            Spacer(minLength: 0)

            Group {
                if model.verdict == .syntaxError {
                    Text("// error: \(model.wrongSlots.count) block\(model.wrongSlots.count == 1 ? "" : "s") out of place")
                        .foregroundStyle(UI.error)
                } else if let token = model.selectedToken {
                    Text("// tap a slot to place \(token.rawValue)")
                        .foregroundStyle(UI.title)
                } else {
                    Text(" ")
                }
            }
            .font(UI.body(12))
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(UI.card, in: RoundedRectangle(cornerRadius: 3))
        .overlay(RoundedRectangle(cornerRadius: 3).stroke(UI.editorBorder, lineWidth: 1))
    }

    private func codeLine<Content: View>(indent: Int = 0, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 6) {
            content()
        }
        .padding(.leading, CGFloat(indent) * 24)
        .frame(height: 26, alignment: .leading)
    }

    private func codeText(_ s: String) -> some View {
        Text(s)
            .font(UI.body(14))
            .foregroundStyle(UI.text)
    }

    @ViewBuilder
    private func slot(_ index: Int) -> some View {
        let token = model.slots[index]
        let isWrong = model.wrongSlots.contains(index)
        let isTargeted = targetedSlot == index
        let awaitingTap = model.selectedToken != nil

        ZStack {
            if let token {
                CodeBlock(token: token, placed: true)
                    .overlay(RoundedRectangle(cornerRadius: 3)
                        .stroke(isWrong ? UI.error : .clear, lineWidth: 1.5))
                    .draggable(BlockPayload(token: token, sourceSlot: index)) {
                        CodeBlock(token: token, placed: false)
                    }
                    .transition(.scale(scale: 1.25).combined(with: .opacity))
            } else {
                RoundedRectangle(cornerRadius: 3)
                    .fill(UI.block)
                    .frame(width: 84, height: 22)
                    .overlay(RoundedRectangle(cornerRadius: 3)
                        .stroke(UI.title.opacity(awaitingTap ? 0.7 : 0), lineWidth: 1))
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(UI.title, lineWidth: 1.5)
                .padding(-3)
                .opacity(isTargeted || snapFlash == index ? 1 : 0)
        )
        .shadow(color: UI.title.opacity(isTargeted ? 0.6 : 0), radius: 6)
        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: token)
        .animation(.easeOut(duration: 0.15), value: isTargeted)
        .contentShape(Rectangle())
        .onTapGesture { withAnimation(.snappy) { model.tapSlot(index) } }
        .dropDestination(for: BlockPayload.self) { items, _ in
            guard let payload = items.first else { return false }
            model.drop(payload, into: index)
            flashSnap(index)
            return true
        } isTargeted: { over in
            if over { targetedSlot = index } else if targetedSlot == index { targetedSlot = nil }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Code slot \(index + 1): \(token?.rawValue ?? "empty")")
        .accessibilityHint(awaitingTap ? "Places the selected block" : "Clears this slot")
    }

    private func flashSnap(_ index: Int) {
        snapFlash = index
        Task {
            try? await Task.sleep(for: .milliseconds(220))
            withAnimation(.easeOut(duration: 0.25)) {
                if snapFlash == index { snapFlash = nil }
            }
        }
    }

    private var bank: some View {
        VStack(spacing: 9) {
            ForEach(CodeToken.allCases) { token in
                let selected = model.selectedToken == token
                CodeBlock(token: token, placed: false, height: 36)
                    .overlay(RoundedRectangle(cornerRadius: 4)
                        .stroke(UI.title, lineWidth: selected ? 1.5 : 0))
                    .scaleEffect(selected ? 1.05 : 1)
                    .contentShape(Rectangle())
                    .onTapGesture { withAnimation(.snappy) { model.toggleSelection(token) } }
                    .draggable(BlockPayload(token: token, sourceSlot: nil)) {
                        CodeBlock(token: token, placed: false, height: 36)
                    }
                    .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .frame(maxWidth: .infinity)
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .stroke(UI.title.opacity(bankTargeted ? 0.8 : 0),
                        style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
        )
        .dropDestination(for: BlockPayload.self) { items, _ in
            guard let payload = items.first, payload.sourceSlot != nil else { return false }
            withAnimation(.snappy) { model.returnToBank(payload) }
            return true
        } isTargeted: { bankTargeted = $0 }
    }

    // MARK: Success — painting_safe.gif

    private var success: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 30) {
                AnimatedGIFView(name: "painting_safe")
                    .frame(width: 180, height: 270)
                    .shadow(color: .black.opacity(0.5), radius: 10, y: 4)

                VStack(alignment: .leading, spacing: 14) {
                    PixelText(text: "Safe unlocked", color: UI.title, pixel: 2, tracking: 2)
                    Text("unlockSafe() ran executeBypassSequence(). The deadbolts are disengaged.")
                        .font(UI.body(15))
                        .foregroundStyle(UI.text)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("\(Text("func").foregroundStyle(UI.keyword)) unlockSafe() {")
                        Text("    executeBypassSequence()")
                        Text("}")
                        Text("unlockSafe()")
                    }
                    .font(UI.body(13))
                    .foregroundStyle(UI.text)
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(UI.card, in: RoundedRectangle(cornerRadius: 3))
                    .overlay(RoundedRectangle(cornerRadius: 3).stroke(UI.editorBorder, lineWidth: 1))

                    stepDots(current: currentStep)
                }
                .frame(width: 300, alignment: .leading)
                .padding(.top, 34)
            }
            .padding(.top, 14)

            Spacer(minLength: 0)

            PillButton(title: "Continue", style: .next, action: onComplete)
                .padding(.bottom, 18)
        }
    }

    // MARK: Bits

    private func checkRow(title: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        HStack {
            Spacer()
            PillButton(title: title, style: .check, enabled: enabled, action: action)
            Spacer()
        }
        .padding(.leading, -33) // re-centre within the full window width
        .padding(.bottom, 18)
    }

    @ViewBuilder
    private func feedback(_ message: String?) -> some View {
        Text(message ?? " ")
            .font(UI.body(12, .medium))
            .foregroundStyle(UI.error)
            .opacity(message == nil ? 0 : 1)
    }
}

// MARK: - Components

/// Numbered circle from the mockups: filled mauve = current, green ring = done, grey ring = to do.
private struct StepDot: View {
    enum State { case done, current, todo }
    let number: Int
    let state: State

    var body: some View {
        Text("\(number)")
            .font(.system(size: 13, weight: state == .current ? .bold : .regular))
            .foregroundStyle(state == .todo ? UI.muted : UI.text)
            .frame(width: 24, height: 24)
            .background(Circle().fill(state == .current ? UI.stepCurrent : .clear))
            .overlay(Circle().stroke(state == .done ? UI.stepDone : state == .todo ? UI.stepTodo : .clear,
                                     lineWidth: 1.2))
            .accessibilityLabel("Step \(number)\(state == .done ? ", done" : state == .current ? ", current" : "")")
    }
}

/// Dark answer card with a thin border (Slide 5).
private struct AnswerCard: View {
    enum State { case idle, selected, wrong }
    let text: String
    let detail: String
    let state: State
    let height: CGFloat
    let action: () -> Void

    private var border: Color {
        switch state {
        case .idle: UI.cardBorder
        case .selected: UI.title
        case .wrong: UI.error
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(text)
                    .font(UI.body(15, .semibold))
                    .foregroundStyle(state == .idle ? UI.text : border)
                Text(detail)
                    .font(UI.body(13))
                    .foregroundStyle(UI.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: height, alignment: .topLeading)
            .background(UI.card, in: RoundedRectangle(cornerRadius: 3))
            .overlay(RoundedRectangle(cornerRadius: 3).stroke(border, lineWidth: state == .idle ? 1 : 1.5))
            .shadow(color: state == .selected ? UI.title.opacity(0.35) : .clear, radius: 6)
        }
        .buttonStyle(PressScale())
        .accessibilityAddTraits(state == .idle ? [] : .isSelected)
    }
}

/// Purple syntax block with a dashed outline (Slides 6 & 8). When placed in a
/// slot it shrinks to the code-line height and its outline turns solid.
private struct CodeBlock: View {
    let token: CodeToken
    let placed: Bool
    var height: CGFloat = 24

    var body: some View {
        Text(token.rawValue)
            .font(.system(size: placed ? 13 : 14))
            .foregroundStyle(token == .funcKeyword || token == .varKeyword ? UI.keyword : UI.text)
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, placed ? 8 : 12)
            .frame(height: placed ? 22 : height)
            .background(UI.block, in: RoundedRectangle(cornerRadius: placed ? 3 : 4))
            .overlay(
                RoundedRectangle(cornerRadius: placed ? 3 : 4)
                    .stroke(UI.blockBorder,
                            style: StrokeStyle(lineWidth: 1, dash: placed ? [] : [4, 3]))
                    .opacity(placed ? 0.5 : 1)
            )
    }
}

/// Capsule buttons: mauve "Check"/"Execute" and blue-ringed "Next"/"Continue".
private struct PillButton: View {
    enum Style { case check, next }
    let title: String
    let style: Style
    var enabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(UI.body(15))
                .foregroundStyle(style == .check ? UI.text : UI.title)
                .frame(width: 160, height: 32)
                .background(Capsule().fill(style == .check ? UI.pill : UI.card))
                .overlay(Capsule().stroke(style == .next ? UI.nextRing : .clear, lineWidth: 1))
                .opacity(enabled ? 1 : 0.4)
        }
        .buttonStyle(PressScale())
        .disabled(!enabled)
    }
}

/// Thin ✕ from the mockups.
private struct CloseButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Path { p in
                p.move(to: .zero); p.addLine(to: CGPoint(x: 13, y: 13))
                p.move(to: CGPoint(x: 13, y: 0)); p.addLine(to: CGPoint(x: 0, y: 13))
            }
            .stroke(UI.muted, style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
            .frame(width: 13, height: 13)
            .padding(8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressScale())
        .accessibilityLabel("Close")
    }
}

/// Crisp, nearest-neighbour scaled sprite from the asset catalog.
private struct PixelSprite: View {
    let name: String
    var body: some View {
        Image(name)
            .resizable()
            .interpolation(.none)
            .scaledToFit()
    }
}

private struct PressScale: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Previews

#Preview("Functions puzzle", traits: .landscapeLeft) {
    ZStack {
        Image("fullbackground").resizable().scaledToFill().ignoresSafeArea()
        FunctionsPuzzleView(onClose: {})
    }
}
