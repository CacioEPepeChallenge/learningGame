//
//  GameCodeBlocks.swift
//  learning_game
//
//  Shared code-puzzle pieces: answer slots, dashed code blocks, tray
//  placeholders, data / type chips and multi-line Swift code text.
//

import SwiftUI

// MARK: - Slots & blocks

/// Empty / filled answer slot (Black box, AshGrey border).
struct GameCodeSlot: View {
    enum Status { case empty, filled, correct, wrong, target }

    let text: String?
    let status: Status

    private var borderColor: Color {
        switch status {
        case .empty, .filled: GameColor.ashGrey
        case .correct: GameColor.success
        case .wrong: GameColor.error
        case .target: GameColor.accent
        }
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 3)
        ZStack {
            shape.fill(GameColor.black)
            if let text {
                GameCodeBlockLabel(text: text, dashed: false)
                    .padding(6)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
        }
        .overlay(shape.strokeBorder(borderColor, lineWidth: status == .target ? 2 : 1))
        .animation(.snappy(duration: 0.2), value: status)
    }
}

/// Code block chip: dark Midnight fill with a dashed Mauve border (tray),
/// or solid when sitting inside a slot.
struct GameCodeBlockLabel: View {
    let text: String
    var dashed = true

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 3)
        Text(text)
            .font(GameFont.bodySm)
            .foregroundStyle(GameColor.white)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(shape.fill(GameColor.midnight.opacity(0.7)))
            .overlay {
                if dashed {
                    shape.strokeBorder(GameColor.mauve, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                } else {
                    shape.strokeBorder(GameColor.mauve.opacity(0.6), lineWidth: 1)
                }
            }
    }
}

/// Faint dashed outline left in the tray where a placed block used to be.
struct GameBlockPlaceholder: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .strokeBorder(GameColor.slateGrey.opacity(0.6), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
    }
}

// MARK: - Chip

/// Rounded data / type chip from the Figma grid.
struct GameChip: View {
    enum Border { case idle, selected, paired, correct, wrong }

    let text: String
    let fill: Color
    let border: Border
    var pulses = false

    @State private var pulse = false

    private var strokeColor: Color {
        switch border {
        case .idle:     GameColor.slateGrey
        case .selected: GameColor.accent
        case .paired:   GameColor.white.opacity(0.25)
        case .correct:  GameColor.success
        case .wrong:    GameColor.error
        }
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 4)
        Text(text)
            .font(GameFont.bodySm)
            .foregroundStyle(GameColor.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(shape.fill(fill))
            .overlay(shape.strokeBorder(strokeColor, lineWidth: border == .selected ? 2 : 1))
            // Hint: gently pulse an Accent outline on the first chip until the player starts.
            .overlay {
                if pulses {
                    shape.strokeBorder(GameColor.accent, lineWidth: 2)
                        .opacity(pulse ? 0.9 : 0.1)
                        .shadow(color: GameColor.accent.opacity(pulse ? 0.7 : 0), radius: 6)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                                pulse = true
                            }
                        }
                        .transition(.opacity)
                }
            }
            .scaleEffect(border == .selected ? 1.05 : 1)
            .contentShape(shape)
            .animation(.snappy(duration: 0.2), value: border)
    }
}

// MARK: - Code text

/// Multi-line Swift snippet with `let` / `var` keywords in bold Accent.
struct GameCodeText: View {
    let code: String
    var size: CGFloat = 14

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(code.split(separator: "\n").enumerated()), id: \.offset) { _, line in
                lineView(String(line))
            }
        }
    }

    private func lineView(_ line: String) -> Text {
        for keyword in ["let ", "var "] where line.hasPrefix(keyword) {
            let rest = String(line.dropFirst(keyword.count))
            return Text("\(Text(keyword).font(GameFont.play(size, bold: true)).foregroundStyle(GameColor.accent))\(Text(rest).font(GameFont.play(size)).foregroundStyle(GameColor.white))")
        }
        return Text(line).font(GameFont.play(size)).foregroundStyle(GameColor.white)
    }
}
