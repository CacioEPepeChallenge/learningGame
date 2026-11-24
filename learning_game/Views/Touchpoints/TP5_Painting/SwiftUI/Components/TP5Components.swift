//
//  TP5Components.swift
//  learning_game
//
//  Shared pieces for the Touchpoint 5 (Functions) cards, built on the team
//  design system (GameColor / GameFont / GameCardChrome / GameButton /
//  GameCodeBlockLabel): sprite slots with placeholders, drop slots, tray
//  blocks, syntax-coloured code rows with a live "program counter", call
//  stack chips, lock dots, confetti and the puzzle card scaffold.
//

import SwiftUI
import UIKit

// MARK: - Lock dots (Figma ① ② ③ progress)

struct TP5LockDots: View {
    /// The lock this card is about (1…5).
    let current: Int?
    let opened: Set<Int>

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { n in
                let isOpen = opened.contains(n)
                let isCurrent = n == current && !isOpen
                Text("\(n)")
                    .font(GameFont.captionBold)
                    .foregroundStyle(isCurrent || isOpen ? GameColor.white : GameColor.ashGrey)
                    .frame(width: 20, height: 20)
                    .background(Circle().fill(isCurrent ? GameColor.mauve : .clear))
                    .overlay(Circle().strokeBorder(isOpen ? GameColor.success
                                                   : isCurrent ? .clear : GameColor.slateGrey,
                                                   lineWidth: 1))
                    .scaleEffect(isOpen && n == current ? 1.15 : 1)
                    .animation(.spring(duration: 0.4, bounce: 0.5), value: isOpen)
                    .accessibilityLabel("Lock \(n)\(isOpen ? ", open" : isCurrent ? ", current" : "")")
            }
        }
    }
}

// MARK: - Code text

enum TP5Syntax {
    private static let keywords: Set<String> = ["func", "let", "var", "return", "Int", "String", "Direction"]

    /// Swift line → coloured text: keywords bold Accent, strings/numbers Peach, comments AshGrey.
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
            } else if c == "-", line.index(after: i) < line.endIndex, line[line.index(after: i)] == ">" {
                let j = line.index(i, offsetBy: 2)
                add(line[i..<j], GameColor.accent, bold: true)
                i = j
            } else {
                add(line[i...i], GameColor.lightGrey)
                i = line.index(after: i)
            }
        }
        return out
    }
}

struct TP5CodeText: View {
    let line: String
    var size: CGFloat = 12

    init(_ line: String, size: CGFloat = 12) {
        self.line = line
        self.size = size
    }

    var body: some View {
        Text(TP5Syntax.attributed(line, size: size))
            .lineLimit(1)
            .fixedSize()
    }
}

/// One line of the code box with its line number. The active line (the one
/// Swift is executing right now) gets a navy bar and an Accent ▸ marker.
struct TP5CodeRow<Content: View>: View {
    let number: Int
    let isActive: Bool
    var height: CGFloat = 18
    var indent: Int = 0
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(spacing: 0) {
            Text(isActive ? "▸" : "\(number + 1)")
                .font(GameFont.play(10, bold: isActive))
                .foregroundStyle(isActive ? GameColor.accent : GameColor.slateGrey)
                .frame(width: 18, alignment: .trailing)
                .padding(.trailing, 8)
            HStack(spacing: 4) { content() }
                .padding(.leading, CGFloat(indent) * 16)
            Spacer(minLength: 0)
        }
        .frame(height: height)
        .background(alignment: .leading) {
            if isActive {
                RoundedRectangle(cornerRadius: 2)
                    .fill(GameColor.accent2.opacity(0.55))
                    .overlay(alignment: .leading) {
                        Rectangle().fill(GameColor.accent).frame(width: 2)
                    }
                    .shadow(color: GameColor.accent.opacity(0.25), radius: 4)
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.18), value: isActive)
    }
}

/// Black code box with a status border (Error on failure, Success when solved).
struct TP5CodeBox<Content: View>: View {
    var phase: TP5RunPhase = .editing
    @ViewBuilder let content: () -> Content

    private var border: Color {
        switch phase {
        case .solved: GameColor.success
        case .failed: GameColor.error
        case .running: GameColor.accent.opacity(0.7)
        case .editing: GameColor.slateGrey
        }
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 4)
        content()
            .padding(.vertical, 6)
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(shape.fill(GameColor.black))
            .overlay(shape.strokeBorder(border, lineWidth: 1))
            .animation(.easeOut(duration: 0.25), value: phase)
    }
}

/// Live call stack: one chip per function currently running (top = newest).
struct TP5CallStack: View {
    let frames: [String]

    var body: some View {
        HStack(spacing: 4) {
            Text("STACK")
                .font(GameFont.silkscreen(8))
                .foregroundStyle(GameColor.ashGrey)
            if frames.isEmpty {
                Text("empty")
                    .font(GameFont.play(10))
                    .foregroundStyle(GameColor.slateGrey)
            }
            ForEach(Array(frames.enumerated()), id: \.offset) { index, frame in
                if index > 0 {
                    Text("›").font(GameFont.play(10)).foregroundStyle(GameColor.ashGrey)
                }
                Text(frame)
                    .font(GameFont.play(10, bold: index == frames.count - 1))
                    .foregroundStyle(index == frames.count - 1 ? GameColor.accent : GameColor.lightGrey)
                    .padding(.horizontal, 5)
                    .frame(height: 16)
                    .background(Capsule().fill(GameColor.midnight.opacity(0.8)))
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3, bounce: 0.3), value: frames)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(frames.isEmpty ? "Call stack empty" : "Call stack: \(frames.joined(separator: ", "))")
    }
}

// MARK: - Drag & drop

/// Inline drop slot inside the code box. Empty = Midnight box; while a block
/// hovers it glows Accent; a dropped block snaps in with a spring + flash.
struct TP5Slot: View {
    enum Status { case normal, correct, wrong }

    let text: String?
    let slotIndex: Int
    var status: Status = .normal
    var minWidth: CGFloat = 64
    var height: CGFloat = 22
    var isEnabled = true
    /// Should this slot light up / accept the hovering block?
    var accepts: (TP5DragItem) -> Bool = { _ in true }
    let onDrop: (TP5DragItem) -> Bool
    let onTap: () -> Void

    @State private var isTargeted = false
    @State private var snap = false

    private var borderColor: Color {
        if isTargeted { return GameColor.accent }
        switch status {
        case .normal: return text == nil ? .clear : GameColor.mauve.opacity(0.6)
        case .correct: return GameColor.success
        case .wrong: return GameColor.error
        }
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 3)
        ZStack {
            if let text {
                Text(text)
                    .font(GameFont.play(12))
                    .foregroundStyle(GameColor.white)
                    .lineLimit(1)
                    .fixedSize()
                    .padding(.horizontal, 7)
                    .frame(minWidth: minWidth, minHeight: height, maxHeight: height)
                    .background(shape.fill(GameColor.midnight.opacity(0.85)))
                    .draggable(TP5DragItem(raw: dragRaw ?? text, fromSlot: slotIndex)) {
                        TP5DragPreview(text: text)
                    }
                    .transition(.scale(scale: 1.3).combined(with: .opacity))
            } else {
                shape.fill(GameColor.midnight.opacity(isTargeted ? 0.9 : 0.55))
                    .frame(width: minWidth, height: height)
            }
        }
        .overlay(shape.strokeBorder(borderColor, lineWidth: isTargeted || status != .normal ? 1.5 : 1))
        .overlay(shape.strokeBorder(GameColor.accent, lineWidth: 2).padding(-3).opacity(snap ? 1 : 0))
        .shadow(color: GameColor.accent.opacity(isTargeted ? 0.6 : 0), radius: 6)
        .scaleEffect(isTargeted ? 1.08 : snap ? 1.05 : 1)
        .animation(.spring(duration: 0.25, bounce: 0.45), value: text)
        .animation(.easeOut(duration: 0.15), value: isTargeted)
        .contentShape(Rectangle())
        .onTapGesture { if isEnabled { withAnimation(.snappy(duration: 0.2)) { onTap() } } }
        .dropDestination(for: TP5DragItem.self) { items, _ in
            guard isEnabled, let item = items.first, accepts(item) else { return false }
            let ok = withAnimation(.spring(duration: 0.3, bounce: 0.45)) { onDrop(item) }
            if ok { flashSnap() }
            return ok
        } isTargeted: { over in
            isTargeted = over && isEnabled
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Slot: \(text ?? "empty")")
        .accessibilityHint(text == nil ? "Drop a block here" : "Tap to remove")
    }

    /// Raw value to send when dragged out (defaults to the visible text).
    var dragRaw: String? = nil

    private func flashSnap() {
        snap = true
        Task {
            try? await Task.sleep(for: .milliseconds(220))
            withAnimation(.easeOut(duration: 0.3)) { snap = false }
        }
    }
}

extension TP5Slot {
    func dragValue(_ raw: String?) -> TP5Slot {
        var copy = self
        copy.dragRaw = raw
        return copy
    }
}

struct TP5DragPreview: View {
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

/// Dashed tray block (GameCodeBlockLabel). Drag it into a slot, or tap it to
/// drop it into the next empty slot. Used single-use blocks leave a placeholder.
struct TP5TrayBlock: View {
    let text: String
    var raw: String? = nil
    var isUsed = false
    var isEnabled = true
    var height: CGFloat = 30
    let onTap: () -> Void

    @State private var bounce = false

    var body: some View {
        ZStack {
            GameBlockPlaceholder()
            if !isUsed {
                GameCodeBlockLabel(text: text)
                    .scaleEffect(bounce ? 0.92 : 1)
                    .draggable(TP5DragItem(raw: raw ?? text, fromSlot: nil)) {
                        TP5DragPreview(text: text)
                    }
                    .onTapGesture {
                        guard isEnabled else { return }
                        withAnimation(.spring(duration: 0.3, bounce: 0.4)) { onTap() }
                        bounce = true
                        withAnimation(.spring(duration: 0.3, bounce: 0.6).delay(0.05)) { bounce = false }
                    }
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
                    .accessibilityLabel("Block \(text)")
                    .accessibilityAddTraits(.isButton)
            }
        }
        .frame(height: height)
        .opacity(isEnabled ? 1 : 0.5)
        .animation(.snappy(duration: 0.2), value: isUsed)
    }
}

/// Tray container. Dropping a placed block back here removes it from the code.
struct TP5Tray<Content: View>: View {
    var title = "BLOCKS"
    var isEnabled = true
    let onReturn: (TP5DragItem) -> Void
    @ViewBuilder let content: () -> Content

    @State private var isTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(GameFont.silkscreen(9))
                    .foregroundStyle(GameColor.ashGrey)
                Spacer()
                Text("drag or tap")
                    .font(GameFont.play(9))
                    .foregroundStyle(GameColor.slateGrey)
            }
            content()
            Spacer(minLength: 0)
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(isTargeted ? GameColor.accent : GameColor.slateGrey.opacity(0.5),
                              style: StrokeStyle(lineWidth: 1, dash: isTargeted ? [] : [4, 3]))
        )
        .dropDestination(for: TP5DragItem.self) { items, _ in
            guard isEnabled, let item = items.first, item.fromSlot != nil else { return false }
            withAnimation(.snappy(duration: 0.25)) { onReturn(item) }
            return true
        } isTargeted: { isTargeted = $0 && isEnabled }
    }
}

// MARK: - Feedback

/// Under the puzzle: running status, hint (Info), or the result (Success / Error).
struct TP5FeedbackLine: View {
    let phase: TP5RunPhase
    let hint: String?
    var idle = "Drag the blocks into the code, then press Run."
    var runningText = "Running your code… watch the highlighted line."

    var body: some View {
        HStack(alignment: .top, spacing: 7) {
            icon
            Text(message)
                .font(GameFont.caption)
                .foregroundStyle(color)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: 640)
        .id(message)
        .transition(.opacity.combined(with: .offset(y: 4)))
        .animation(.easeOut(duration: 0.2), value: message)
    }

    private var message: String {
        switch phase {
        case .solved(let m), .failed(let m): return m
        case .running: return runningText
        case .editing: return hint ?? idle
        }
    }

    private var color: Color {
        switch phase {
        case .solved: GameColor.success
        case .failed: GameColor.error
        case .running: GameColor.accent
        case .editing: hint == nil ? GameColor.ashGrey : GameColor.info
        }
    }

    @ViewBuilder private var icon: some View {
        switch phase {
        case .solved: GameFeedbackIcon(isSuccess: true, size: 14)
        case .failed: GameFeedbackIcon(isSuccess: false, size: 14)
        case .running: TP5RunningDot()
        case .editing:
            if hint != nil {
                Text("IRIS")
                    .font(GameFont.silkscreen(8))
                    .foregroundStyle(GameColor.black)
                    .padding(.horizontal, 3)
                    .frame(height: 14)
                    .background(RoundedRectangle(cornerRadius: 2).fill(GameColor.info))
            }
        }
    }
}

private struct TP5RunningDot: View {
    @State private var on = false
    var body: some View {
        Circle()
            .fill(GameColor.accent)
            .frame(width: 8, height: 8)
            .padding(3)
            .opacity(on ? 1 : 0.25)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true)) { on = true }
            }
    }
}

// MARK: - Confetti (Cards.png "Fix the function" success)

struct TP5Confetti: View {
    /// Bump to fire a burst.
    let trigger: Int

    @State private var start: Date?
    private let pieces: [Piece] = (0..<70).map { _ in Piece() }
    private static let palette: [Color] = [GameColor.accent, GameColor.peach, GameColor.mauve,
                                           GameColor.success, GameColor.info, GameColor.burgundy]

    private struct Piece {
        let x = Double.random(in: 0...1)
        let delay = Double.random(in: 0...0.35)
        let speed = Double.random(in: 120...260)
        let drift = Double.random(in: -60...60)
        let spin = Double.random(in: -6...6)
        let size = Double.random(in: 4...8)
        let color = Int.random(in: 0..<6)
        let isSquare = Bool.random()
    }

    var body: some View {
        TimelineView(.animation(paused: start == nil)) { timeline in
            Canvas { context, size in
                guard let start else { return }
                let t = timeline.date.timeIntervalSince(start)
                for p in pieces {
                    let local = t - p.delay
                    guard local > 0 else { continue }
                    let y = -10 + p.speed * local + 90 * local * local
                    guard y < size.height + 10 else { continue }
                    let x = p.x * size.width + p.drift * local
                    var ctx = context
                    ctx.translateBy(x: x, y: y)
                    ctx.rotate(by: .radians(p.spin * local))
                    let rect = CGRect(x: -p.size / 2, y: -p.size / 2, width: p.size, height: p.isSquare ? p.size : p.size * 0.5)
                    ctx.fill(Path(rect), with: .color(Self.palette[p.color]))
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) {
            start = .now
            Task {
                try? await Task.sleep(for: .seconds(3))
                start = nil
            }
        }
    }
}

// MARK: - Puzzle card scaffold

/// The shared Touchpoint 5 lock card, laid out on the Figma challenge grid:
/// title + subtitle, lock dots, [stage | code box | tray], feedback, buttons.
struct TP5PuzzleCard<Stage: View, Code: View, Tray: View>: View {
    let title: String
    let subtitle: String
    let lock: Int
    let opened: Set<Int>
    let phase: TP5RunPhase
    let hint: String?
    var idleText = "Drag the blocks into the code, then press Run."
    var runningText = "Running your code… watch the highlighted line."
    /// Code box width; the tray takes the rest of the row.
    var codeWidth: CGFloat = 356
    let canRun: Bool
    let runCount: Int
    let onRun: () -> Void
    let onRetry: () -> Void
    let onHint: () -> Void
    let onNext: () -> Void
    let onClose: () -> Void
    @ViewBuilder let stage: () -> Stage
    @ViewBuilder let code: () -> Code
    @ViewBuilder let tray: () -> Tray

    @State private var appeared = false
    @State private var shake: CGFloat = 0
    @State private var celebrate = 0

    var body: some View {
        GameCardChrome(onClose: onClose) {
            ZStack(alignment: .topLeading) {
                GameCardTitle(title: title, subtitle: subtitle)
                    .offset(x: 35, y: 22)

                TP5LockDots(current: lock, opened: opened)
                    .offset(x: 35, y: 76)

                stage()
                    .frame(width: 140, height: 160)
                    .offset(x: 32, y: 104)

                code()
                    .frame(width: codeWidth, height: 160)
                    .modifier(GameShake(animatableData: shake))
                    .offset(x: 186, y: 104)

                tray()
                    .frame(width: 752 - (200 + codeWidth), height: 160)
                    .offset(x: 200 + codeWidth, y: 104)

                TP5FeedbackLine(phase: phase, hint: hint, idle: idleText, runningText: runningText)
                    .frame(maxWidth: .infinity)
                    .frame(height: 34)
                    .offset(y: 272)

                buttons
                    .frame(maxWidth: .infinity)
                    .offset(y: 317)

                TP5Confetti(trigger: celebrate)
                    .frame(width: GameLayout.card.width, height: GameLayout.card.height)
            }
        }
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.96)
        .onAppear { withAnimation(.easeOut(duration: 0.25)) { appeared = true } }
        .onChange(of: phase) { _, new in
            if new.isFailed { withAnimation(.linear(duration: 0.4)) { shake += 1 } }
            if new.isSolved { celebrate += 1 }
        }
        .sensoryFeedback(trigger: phase) { _, new in
            switch new {
            case .solved: .success
            case .failed: .error
            default: nil
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: runCount)
    }

    @ViewBuilder private var buttons: some View {
        HStack(spacing: 12) {
            switch phase {
            case .editing:
                GameButton(title: "Hint", kind: .secondary, action: onHint)
                GameButton(title: "Run ▸", action: onRun)
                    .disabled(!canRun)
            case .running:
                GameButton(title: "Running…", action: {})
                    .disabled(true)
            case .failed:
                GameButton(title: "Hint", kind: .secondary) { onRetry(); onHint() }
                GameButton(title: "Try again", action: onRetry)
            case .solved:
                GameButton(title: "Next", kind: .outline, action: onNext)
            }
        }
        .animation(.snappy(duration: 0.2), value: phase)
    }
}

/// Dark framed box for a stage visual (left column of a lock card).
struct TP5StageFrame<Content: View>: View {
    var glow: Color? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 4)
        content()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background { shape.fill(GameColor.black); shape.fill(GameColor.accent2.opacity(0.18)) }
            .clipShape(shape)
            .overlay(shape.strokeBorder(glow ?? GameColor.slateGrey, lineWidth: 1))
            .shadow(color: (glow ?? .clear).opacity(0.5), radius: 10)
            .animation(.easeOut(duration: 0.3), value: glow)
    }
}
