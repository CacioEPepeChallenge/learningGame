//
//  CodePuzzleCards.swift
//  learning_game
//
//  Shared cards for the "Predict → Run → Explain" touchpoints (TP3, TP4),
//  built on the Figma card system (GameCardChrome / GameCardHeader /
//  GameButton / GameCodeBlockLabel) and matching the TP4 mockups:
//
//    LessonCardView     — I.R.I.S. intro card ("FOR IN LOOP")
//    TrueFalseCardView  — "TRUE OR FALSE" statement + True / False
//    CodePuzzleCardView — "CORRECT ORDER" / "FIX THE LOOP": drag blocks into
//                         the code, Check, watch it run on the stage, read why.
//    PuzzleStepDots     — ① ② ③ ④ ⑤ progress, bottom-right
//

import SwiftUI

// MARK: - Step dots (mockup: bottom-right)

struct PuzzleStepDots: View {
    var count = 5
    let current: Int
    let completed: Set<Int>

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...count, id: \.self) { n in
                let done = completed.contains(n)
                let isCurrent = n == current
                Text("\(n)")
                    .font(GameFont.play(12, bold: isCurrent))
                    .foregroundStyle(done ? GameColor.success : isCurrent ? GameColor.white : GameColor.ashGrey)
                    .frame(width: 22, height: 22)
                    .overlay(Circle().strokeBorder(done ? GameColor.success
                                                   : isCurrent ? GameColor.white : GameColor.slateGrey,
                                                   lineWidth: isCurrent ? 1.5 : 1))
                    .animation(.spring(duration: 0.4, bounce: 0.4), value: done)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Puzzle \(current) of \(count)")
    }
}

// MARK: - Syntax-coloured Swift line

enum SwiftSyntax {
    private static let keywords: Set<String> = [
        "let", "var", "for", "in", "while", "if", "else", "func", "return",
        "switch", "case", "default", "true", "false", "Int", "String", "Bool",
    ]

    static func attributed(_ line: String, size: CGFloat) -> AttributedString {
        var out = AttributedString()
        func add(_ s: Substring, _ color: Color, bold: Bool = false) {
            var a = AttributedString(String(s))
            a.foregroundColor = color
            a.font = GameFont.play(size, bold: bold)
            out += a
        }
        if line.trimmingCharacters(in: .whitespaces).hasPrefix("//") {
            add(Substring(line), GameColor.ashGrey)
            return out
        }
        var i = line.startIndex
        while i < line.endIndex {
            let c = line[i]
            if c == "\"" {
                var j = line.index(after: i)
                while j < line.endIndex, line[j] != "\"" { j = line.index(after: j) }
                let end = j < line.endIndex ? line.index(after: j) : j
                add(line[i..<end], GameColor.peach)
                i = end
            } else if c.isLetter || c == "_" {
                var j = i
                while j < line.endIndex, line[j].isLetter || line[j].isNumber || line[j] == "_" { j = line.index(after: j) }
                let word = line[i..<j]
                keywords.contains(String(word)) ? add(word, GameColor.accent, bold: true) : add(word, GameColor.white)
                i = j
            } else if c.isNumber {
                var j = i
                while j < line.endIndex, line[j].isNumber { j = line.index(after: j) }
                add(line[i..<j], GameColor.peach)
                i = j
            } else {
                add(line[i...i], GameColor.lightGrey)
                i = line.index(after: i)
            }
        }
        return out
    }
}

struct SwiftCodeText: View {
    let line: String
    var size: CGFloat = 13

    init(_ line: String, size: CGFloat = 13) {
        self.line = line
        self.size = size
    }

    var body: some View {
        Text(SwiftSyntax.attributed(line, size: size))
            .lineLimit(1)
            .fixedSize()
    }
}

// MARK: - Lesson card (mockup: "FOR IN LOOP")

struct LessonCardView: View {
    let content: LessonContent
    let onNext: () -> Void
    let onClose: () -> Void

    @State private var appeared = false

    var body: some View {
        GameCardChrome(onClose: onClose) {
            ZStack(alignment: .topLeading) {
                GameCardHeader(title: content.title, subtitle: content.subtitle)
                    .offset(x: 26, y: 21)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(content.paragraphs, id: \.self) { p in
                        Text(LocalizedStringKey(p))
                            .font(GameFont.bodySm)
                            .foregroundStyle(GameColor.white)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if !content.bullets.isEmpty {
                        VStack(alignment: .leading, spacing: 3) {
                            ForEach(content.bullets, id: \.self) { b in
                                HStack(alignment: .firstTextBaseline, spacing: 8) {
                                    Text("•").font(GameFont.bodySm).foregroundStyle(GameColor.white)
                                    Text(LocalizedStringKey(b))
                                        .font(GameFont.bodySm)
                                        .foregroundStyle(GameColor.white)
                                }
                            }
                        }
                        .padding(.leading, 8)
                    }
                }
                .frame(width: 470, alignment: .leading)
                .offset(x: 33, y: 112)

                codeBox
                    .frame(width: 200, height: 160)
                    .offset(x: 530, y: 120)

                GameButton(title: content.buttonTitle, kind: .outline, action: onNext)
                    .frame(maxWidth: .infinity)
                    .offset(y: 317)
            }
        }
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.96)
        .onAppear { withAnimation(.easeOut(duration: 0.25)) { appeared = true } }
    }

    private var codeBox: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(content.code.components(separatedBy: "\n").enumerated()), id: \.offset) { _, line in
                Text(SwiftSyntax.attributed(line, size: 10))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: 4).fill(GameColor.black))
    }
}

// MARK: - True / False card (mockup: "TRUE OR FALSE")

struct TrueFalseCardView: View {
    @Bindable var quiz: TrueFalseViewModel
    let step: Int
    let completed: Set<Int>
    let onNext: () -> Void
    let onClose: () -> Void

    @State private var appeared = false
    @State private var shake: CGFloat = 0

    private var content: TrueFalseContent { quiz.content }

    var body: some View {
        GameCardChrome(onClose: onClose) {
            ZStack(alignment: .topLeading) {
                GameCardTitle(title: content.title, subtitle: content.subtitle)
                    .offset(x: 35, y: 24)

                statementBox
                    .frame(maxWidth: .infinity)
                    .offset(y: 136)

                feedback
                    .frame(maxWidth: .infinity)
                    .frame(height: 20)
                    .offset(y: 273)

                buttons
                    .frame(maxWidth: .infinity)
                    .offset(y: 317)

                PuzzleStepDots(current: step, completed: completed)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 26)
                    .offset(y: 322)
            }
        }
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.96)
        .onAppear { withAnimation(.easeOut(duration: 0.25)) { appeared = true } }
        .sensoryFeedback(trigger: quiz.answerCount) { _, _ in quiz.isSolved ? .success : .error }
        .onChange(of: quiz.answerCount) {
            if quiz.result == .wrong { withAnimation(.linear(duration: 0.4)) { shake += 1 } }
        }
    }

    private var statementBox: some View {
        let shape = RoundedRectangle(cornerRadius: 4)
        let border: Color = switch quiz.result {
        case .correct: GameColor.success
        case .wrong: GameColor.error
        case .unanswered: GameColor.ashGrey
        }
        return Text(content.statement)
            .font(GameFont.bodySm)
            .foregroundStyle(GameColor.white)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 22)
            .padding(.vertical, 16)
            .frame(width: 340, alignment: .leading)
            .background(shape.fill(GameColor.black))
            .overlay(shape.strokeBorder(border, lineWidth: 1))
            .modifier(GameShake(animatableData: shake))
            .animation(.snappy(duration: 0.3), value: quiz.result)
    }

    @ViewBuilder private var feedback: some View {
        switch quiz.result {
        case .correct: GameFeedbackLine(isSuccess: true, text: content.successFeedback).transition(.opacity)
        case .wrong:   GameFeedbackLine(isSuccess: false, text: content.wrongFeedback).transition(.opacity)
        case .unanswered: EmptyView()
        }
    }

    @ViewBuilder private var buttons: some View {
        switch quiz.result {
        case .correct:
            GameButton(title: "Next", kind: .outline, action: onNext).transition(.opacity)
        case .wrong:
            GameButton(title: "Try again") { withAnimation(.snappy(duration: 0.25)) { quiz.retry() } }
                .transition(.opacity)
        case .unanswered:
            HStack(spacing: 12) {
                GameButton(title: "True") { withAnimation(.easeOut(duration: 0.25)) { quiz.answer(true) } }
                GameButton(title: "False", kind: .secondary) { withAnimation(.easeOut(duration: 0.25)) { quiz.answer(false) } }
            }
            .transition(.opacity)
        }
    }
}

// MARK: - Code puzzle card (mockup: "CORRECT ORDER")

struct CodePuzzleCardView: View {
    @Bindable var puzzle: CodePuzzleViewModel
    let step: Int
    let completed: Set<Int>
    let onNext: () -> Void
    let onClose: () -> Void

    @State private var appeared = false
    @State private var shake: CGFloat = 0

    private var content: CodePuzzleContent { puzzle.content }
    private let rowHeight: CGFloat = 26
    private var codeHeight: CGFloat { CGFloat(content.lines.count) * rowHeight + 20 }

    var body: some View {
        GameCardChrome(onClose: onClose) {
            ZStack(alignment: .topLeading) {
                GameCardTitle(title: content.title, subtitle: content.subtitle)
                    .offset(x: 35, y: 24)

                PuzzleStageView(stage: puzzle.stage, phase: puzzle.phase)
                    .frame(width: 140, height: 168)
                    .offset(x: 32, y: 94)

                if content.trayBelow {
                    codeBox
                        .frame(width: 564, height: codeHeight)
                        .offset(x: 186, y: 94)
                    tray(columns: nil)
                        .frame(width: 564, alignment: .leading)
                        .offset(x: 186, y: 94 + codeHeight + 12)
                } else {
                    codeBox
                        .frame(width: 372, height: 168)
                        .offset(x: 186, y: 94)
                    tray(columns: 2)
                        .frame(width: 182, height: 168, alignment: .top)
                        .offset(x: 568, y: 94)
                }

                feedback
                    .frame(maxWidth: .infinity)
                    .frame(height: 34)
                    .offset(y: 270)

                buttons
                    .frame(maxWidth: .infinity)
                    .offset(y: 317)

                PuzzleStepDots(current: step, completed: completed)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 26)
                    .offset(y: 322)
            }
        }
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.96)
        .onAppear { withAnimation(.easeOut(duration: 0.25)) { appeared = true } }
        .sensoryFeedback(.selection, trigger: puzzle.slots)
        .sensoryFeedback(trigger: puzzle.phase) { _, new in
            switch new {
            case .solved: .success
            case .failed: .error
            default: nil
            }
        }
        .onChange(of: puzzle.phase) { _, new in
            if case .failed = new { withAnimation(.linear(duration: 0.4)) { shake += 1 } }
        }
    }

    // MARK: Code

    private var codeBox: some View {
        let shape = RoundedRectangle(cornerRadius: 4)
        let border: Color = switch puzzle.phase {
        case .solved: GameColor.success
        case .failed: GameColor.error
        case .running: GameColor.accent.opacity(0.7)
        case .editing: GameColor.ashGrey
        }
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(content.lines.indices, id: \.self) { i in
                codeRow(i)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(shape.fill(GameColor.black))
        .overlay(shape.strokeBorder(border, lineWidth: 1))
        .overlay(alignment: .topTrailing) {
            if let note = puzzle.note {
                Text(note)
                    .font(GameFont.play(10, bold: true))
                    .foregroundStyle(GameColor.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(GameColor.info))
                    .padding(6)
                    .id(note)
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
        .animation(.snappy(duration: 0.25), value: puzzle.note)
        .modifier(GameShake(animatableData: shake))
    }

    private func codeRow(_ i: Int) -> some View {
        let active = puzzle.activeLine == i
        return HStack(spacing: 4) {
            Text(active ? "▸" : " ")
                .font(GameFont.play(11, bold: true))
                .foregroundStyle(GameColor.accent)
                .frame(width: 10)
            ForEach(Array(content.lines[i].enumerated()), id: \.offset) { _, segment in
                switch segment {
                case .code(let text):
                    SwiftCodeText(text, size: 13)
                case .slot(let index):
                    slot(index)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(height: rowHeight)
        .background(alignment: .leading) {
            if active {
                RoundedRectangle(cornerRadius: 2)
                    .fill(GameColor.accent2.opacity(0.55))
                    .overlay(alignment: .leading) { Rectangle().fill(GameColor.accent).frame(width: 2) }
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.18), value: active)
    }

    private func slot(_ index: Int) -> some View {
        let block = puzzle.slots[index]
        let status: CodeDropSlot.Status = puzzle.wrongSlots.contains(index) ? .wrong
            : puzzle.isSolved ? .correct : .normal
        return CodeDropSlot(block: block, slotIndex: index, status: status,
                            isEnabled: puzzle.canEdit, pulsesHint: !puzzle.hasStarted && index == 0,
                            onDrop: { item in
                                puzzle.place(item.block, at: index, from: item.fromSlot)
                                return true
                            },
                            onTap: { puzzle.remove(at: index) })
    }

    // MARK: Tray

    @ViewBuilder
    private func tray(columns: Int?) -> some View {
        let blocks = ForEach(content.blocks, id: \.self) { block in
            CodeTrayBlock(text: block, isUsed: puzzle.isUsed(block), isEnabled: puzzle.canEdit,
                          sizesToText: columns == nil) {
                withAnimation(.snappy(duration: 0.25)) { puzzle.place(block) }
            }
        }
        Group {
            if let columns {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: columns), spacing: 6) {
                    blocks.frame(height: 28)
                }
            } else {
                FlowRow(spacing: 8) { blocks.frame(height: 30) }
            }
        }
        .dropDestination(for: CodeBlockDragItem.self) { items, _ in
            guard puzzle.canEdit, let item = items.first, let source = item.fromSlot else { return false }
            withAnimation(.snappy(duration: 0.25)) { puzzle.remove(at: source) }
            return true
        }
    }

    // MARK: Feedback & buttons

    @ViewBuilder private var feedback: some View {
        switch puzzle.phase {
        case .solved(let message):
            feedbackText(message, success: true)
        case .failed(let message):
            feedbackText(message, success: false)
        case .running:
            Text("Running…")
                .font(GameFont.caption)
                .foregroundStyle(GameColor.accent)
        case .editing:
            EmptyView()
        }
    }

    private func feedbackText(_ message: String, success: Bool) -> some View {
        HStack(alignment: .top, spacing: 6) {
            GameFeedbackIcon(isSuccess: success, size: 14)
            Text(message)
                .font(GameFont.caption)
                .foregroundStyle(success ? GameColor.success : GameColor.error)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: 600)
        .transition(.opacity)
    }

    @ViewBuilder private var buttons: some View {
        switch puzzle.phase {
        case .editing:
            GameButton(title: "Check") { Task { await puzzle.check() } }
                .disabled(!puzzle.allFilled)
        case .running:
            GameButton(title: "Running…", action: {}).disabled(true)
        case .failed:
            GameButton(title: "Try again") { withAnimation(.snappy(duration: 0.25)) { puzzle.retry() } }
        case .solved:
            GameButton(title: "Next", kind: .outline, action: onNext)
        }
    }
}

// MARK: - Stage

/// Left box of a code puzzle: the items the code works on (logs, books…),
/// which light up as the loop / condition runs.
struct PuzzleStageView: View {
    let stage: PuzzleStage
    var phase: CodePuzzleViewModel.Phase = .editing

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 4)
        let glow: Color? = switch phase {
        case .solved: GameColor.success
        case .failed: GameColor.error
        default: nil
        }
        Group {
            switch stage.scene {
            case .list: listScene
            case .monitor: monitorScene
            case .bookshelf: bookshelfScene
            }
        }
        .padding(9)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background { shape.fill(GameColor.black); shape.fill(GameColor.accent2.opacity(0.15)) }
        .overlay(shape.strokeBorder(glow ?? GameColor.slateGrey, lineWidth: 1))
        .shadow(color: (glow ?? .clear).opacity(0.5), radius: 8)
        .animation(.spring(duration: 0.35, bounce: 0.3), value: stage)
    }

    // MARK: Plain list

    private var listScene: some View {
            VStack(alignment: .leading, spacing: 5) {
                Text(stage.title.uppercased())
                    .font(GameFont.silkscreen(8))
                    .foregroundStyle(GameColor.ashGrey)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.bottom, 2)

                ForEach(stage.items) { item in
                    itemRow(item)
                }

                Spacer(minLength: 0)

                if let progress = stage.progress {
                    VStack(alignment: .leading, spacing: 3) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(GameColor.slateGrey.opacity(0.5))
                                Capsule().fill(progress >= 100 ? GameColor.success : GameColor.accent)
                                    .frame(width: geo.size.width * CGFloat(min(progress, 100)) / 100)
                            }
                        }
                        .frame(height: 8)
                        Text("\(progress)%")
                            .font(GameFont.silkscreen(9))
                            .foregroundStyle(progress >= 100 ? GameColor.success : GameColor.accent)
                            .contentTransition(.numericText(value: Double(progress)))
                    }
                }
                if let counter = stage.counter {
                    Text(counter)
                        .font(GameFont.play(10, bold: true))
                        .foregroundStyle(GameColor.info)
                        .contentTransition(.numericText())
                }
            }
    }

    // MARK: Leo's PC — the items are files on its screen

    private var monitorScene: some View {
        let width: CGFloat = 130
        let s = width / GameArt.monitorSize.width
        let screen = GameArt.monitorScreen
        return VStack(spacing: 6) {
            ZStack(alignment: .topLeading) {
                ArtImage(GameArt.monitor)
                    .frame(width: width, height: GameArt.monitorSize.height * s)
                // The screen itself shows the program's data.
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 3) {
                        Rectangle().fill(GameColor.success).frame(width: 3, height: 3)
                        Text(stage.title)
                            .font(GameFont.play(7, bold: true))
                            .foregroundStyle(GameColor.lightGrey)
                            .lineLimit(1)
                    }
                    ForEach(stage.items) { item in
                        screenRow(item)
                    }
                    if let progress = stage.progress {
                        Spacer(minLength: 0)
                        progressBar(progress, height: 6)
                        Text("\(progress)%")
                            .font(GameFont.silkscreen(8))
                            .foregroundStyle(progress >= 100 ? GameColor.success : GameColor.accent)
                            .contentTransition(.numericText(value: Double(progress)))
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 3)
                .frame(width: screen.width * s, height: screen.height * s, alignment: .topLeading)
                .background(GameColor.accent2)
                .clipped()
                .offset(x: screen.minX * s, y: screen.minY * s)
            }
            .frame(width: width, height: GameArt.monitorSize.height * s, alignment: .topLeading)

            if let counter = stage.counter {
                Text(counter)
                    .font(GameFont.play(10, bold: true))
                    .foregroundStyle(GameColor.info)
                    .contentTransition(.numericText())
            }
            Spacer(minLength: 0)
        }
        .padding(.top, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func screenRow(_ item: StageItem) -> some View {
        let tint = color(item.state)
        return HStack(spacing: 3) {
            PixelSpriteView(item.icon)
                .frame(width: 9, height: 9)
                .opacity(item.state == .skipped ? 0.35 : 1)
            Text(item.label)
                .font(GameFont.play(7, bold: item.state == .active || item.state == .picked))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 0)
            stateBadge(item.state).scaleEffect(0.8)
        }
        .padding(.horizontal, 2)
        .frame(height: 10)
        .background(Rectangle().fill(item.state == .active ? GameColor.accent.opacity(0.35) : .clear))
    }

    // MARK: Leo's bookshelf — the items sit on its shelves

    private var bookshelfScene: some View {
        let scale: CGFloat = 0.86
        let shelfRows: [CGFloat] = [34, 68, 100, 133]       // shelf centres in the painted bookshelf
        let rows = stage.items.count == 1 ? [3] : Array(0..<min(stage.items.count, 4))
        return VStack(spacing: 4) {
            ZStack(alignment: .topLeading) {
                ArtImage(GameArt.bookshelf)
                    .frame(width: 98 * scale, height: 153 * scale)
                ForEach(Array(stage.items.prefix(4).enumerated()), id: \.element.id) { i, item in
                    shelfTag(item)
                        .frame(width: 108)
                        .offset(x: -12, y: shelfRows[rows[i]] * scale - 9)
                }
            }
            .frame(width: 98 * scale, height: 153 * scale, alignment: .topLeading)

            if let counter = stage.counter {
                Text(counter)
                    .font(GameFont.play(9, bold: true))
                    .foregroundStyle(GameColor.info)
            }
        }
        .padding(.top, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func shelfTag(_ item: StageItem) -> some View {
        let tint = color(item.state)
        let lit = item.state != .idle && item.state != .skipped
        return HStack(spacing: 4) {
            PixelSpriteView(item.icon).frame(width: 11, height: 11)
            Text(item.label)
                .font(GameFont.play(9, bold: lit))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 0)
            stateBadge(item.state)
        }
        .padding(.horizontal, 5)
        .frame(height: 18)
        .background(RoundedRectangle(cornerRadius: 3).fill(GameColor.black.opacity(0.82)))
        .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(lit ? tint : GameColor.slateGrey, lineWidth: lit ? 1.5 : 1))
        .shadow(color: lit ? tint.opacity(0.6) : .clear, radius: 5)
        .opacity(item.state == .skipped ? 0.55 : 1)
    }

    private func color(_ state: StageItemState) -> Color {
        switch state {
        case .idle: GameColor.lightGrey
        case .active: GameColor.accent
        case .done: GameColor.success
        case .skipped: GameColor.ashGrey
        case .failed: GameColor.error
        case .picked: GameColor.info
        }
    }

    private func progressBar(_ progress: Int, height: CGFloat) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(GameColor.slateGrey.opacity(0.6))
                Capsule().fill(progress >= 100 ? GameColor.success : GameColor.accent)
                    .frame(width: geo.size.width * CGFloat(min(progress, 100)) / 100)
            }
        }
        .frame(height: height)
    }

    private func itemRow(_ item: StageItem) -> some View {
        let tint: Color = switch item.state {
        case .idle: GameColor.lightGrey
        case .active: GameColor.accent
        case .done: GameColor.success
        case .skipped: GameColor.slateGrey
        case .failed: GameColor.error
        case .picked: GameColor.info
        }
        return HStack(spacing: 6) {
            PixelSpriteView(item.icon)
                .frame(width: 16, height: 16)
                .opacity(item.state == .skipped ? 0.4 : 1)
            Text(item.label)
                .font(GameFont.play(10, bold: item.state == .active || item.state == .picked))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 0)
            stateBadge(item.state)
        }
        .padding(.horizontal, 4)
        .frame(height: 20)
        .background(RoundedRectangle(cornerRadius: 3).fill(item.state == .active ? GameColor.accent2.opacity(0.6) : .clear))
        .scaleEffect(item.state == .active || item.state == .picked ? 1.04 : 1)
    }

    @ViewBuilder private func stateBadge(_ state: StageItemState) -> some View {
        switch state {
        case .done: PixelSpriteView("px_lock_open").frame(width: 10, height: 11)
        case .idle: PixelSpriteView("px_lock").frame(width: 10, height: 11)
        case .failed: GameFeedbackIcon(isSuccess: false, size: 11)
        case .picked: Text("★").font(GameFont.play(10, bold: true)).foregroundStyle(GameColor.info)
        case .active, .skipped: EmptyView()
        }
    }
}

// MARK: - Drag & drop pieces

/// Inline answer slot inside the code box.
struct CodeDropSlot: View {
    enum Status { case normal, correct, wrong }

    let block: String?
    let slotIndex: Int
    var status: Status = .normal
    var isEnabled = true
    var pulsesHint = false
    let onDrop: (CodeBlockDragItem) -> Bool
    let onTap: () -> Void

    @State private var isTargeted = false
    @State private var snap = false
    @State private var pulse = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 3)
        let border: Color = isTargeted ? GameColor.accent
            : status == .wrong ? GameColor.error
            : status == .correct ? GameColor.success
            : block == nil ? .clear : GameColor.mauve.opacity(0.6)
        ZStack {
            if let block {
                Text(block)
                    .font(GameFont.play(13))
                    .foregroundStyle(GameColor.white)
                    .lineLimit(1)
                    .fixedSize()
                    .padding(.horizontal, 8)
                    .frame(minWidth: 56, minHeight: 22, maxHeight: 22)
                    .background(shape.fill(GameColor.midnight.opacity(0.9)))
                    .draggable(CodeBlockDragItem(block: block, fromSlot: slotIndex)) { CodeDragPreview(text: block) }
                    .transition(.scale(scale: 1.3).combined(with: .opacity))
            } else {
                shape.fill(GameColor.midnight.opacity(isTargeted ? 0.95 : 0.6))
                    .frame(width: 64, height: 22)
            }
        }
        .overlay(shape.strokeBorder(border, lineWidth: status == .normal && !isTargeted ? 1 : 1.5))
        .overlay {
            if pulsesHint && block == nil {
                shape.strokeBorder(GameColor.accent, lineWidth: 1.5)
                    .opacity(pulse ? 0.9 : 0.15)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) { pulse = true }
                    }
            }
        }
        .overlay(shape.strokeBorder(GameColor.accent, lineWidth: 2).padding(-3).opacity(snap ? 1 : 0))
        .shadow(color: GameColor.accent.opacity(isTargeted ? 0.6 : 0), radius: 6)
        .scaleEffect(isTargeted ? 1.08 : snap ? 1.05 : 1)
        .animation(.spring(duration: 0.25, bounce: 0.45), value: block)
        .animation(.easeOut(duration: 0.15), value: isTargeted)
        .contentShape(Rectangle())
        .onTapGesture { if isEnabled { withAnimation(.snappy(duration: 0.2)) { onTap() } } }
        .dropDestination(for: CodeBlockDragItem.self) { items, _ in
            guard isEnabled, let item = items.first else { return false }
            let ok = withAnimation(.spring(duration: 0.3, bounce: 0.45)) { onDrop(item) }
            if ok { flashSnap() }
            return ok
        } isTargeted: { isTargeted = $0 && isEnabled }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Slot: \(block ?? "empty")")
        .accessibilityHint(block == nil ? "Drop a block here" : "Tap to remove")
    }

    private func flashSnap() {
        snap = true
        Task {
            try? await Task.sleep(for: .milliseconds(220))
            withAnimation(.easeOut(duration: 0.3)) { snap = false }
        }
    }
}

struct CodeDragPreview: View {
    let text: String

    var body: some View {
        Text(text)
            .font(GameFont.play(13))
            .foregroundStyle(GameColor.white)
            .padding(.horizontal, 10)
            .frame(height: 30)
            .background(RoundedRectangle(cornerRadius: 3).fill(GameColor.midnight))
            .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(GameColor.accent, lineWidth: 1.5))
    }
}

/// Dashed tray block. Drag it into a slot, or tap to fill the next empty slot.
struct CodeTrayBlock: View {
    let text: String
    var isUsed = false
    var isEnabled = true
    /// In a flowing row the block sizes to its text; in a grid it fills its cell.
    var sizesToText = true
    let onTap: () -> Void

    var body: some View {
        ZStack {
            GameBlockPlaceholder()
            if !isUsed {
                GameCodeBlockLabel(text: text)
                    .draggable(CodeBlockDragItem(block: text, fromSlot: nil)) { CodeDragPreview(text: text) }
                    .onTapGesture { if isEnabled { onTap() } }
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
                    .accessibilityLabel("Block \(text)")
                    .accessibilityAddTraits(.isButton)
            }
        }
        .frame(minWidth: sizesToText ? CGFloat(text.count) * 7 + 20 : nil)
        .opacity(isEnabled ? 1 : 0.6)
        .animation(.snappy(duration: 0.2), value: isUsed)
    }
}

/// Wraps children onto new rows (tray under the code).
struct FlowRow: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, maxX: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0; y += rowHeight + spacing; rowHeight = 0
            }
            x += size.width + spacing
            maxX = max(maxX, x - spacing)
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxX, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX; y += rowHeight + spacing; rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
