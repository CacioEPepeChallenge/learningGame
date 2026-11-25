//
//  TP1CardStyle.swift
//  learning_game
//
//  Touchpoint 1 card pieces from the updated Figma (iPhone 17 - 10 / 34):
//    TP1CardHeader  — pixel icon (⚡ for the generator) + Silkscreen title + subtitle
//    TP1NoteCard    — Leo's tilted override-notes card
//    TP1PillButton  — "Start mission" (glowing), "‹ Back" pill, "Next" (dim until ready)
//    TP1CodeLine    — one-line code box: black, light border → green / red
//

import SwiftUI

// MARK: - Header

/// Intro-card header with a small pixel icon instead of the I.R.I.S. portrait.
struct TP1CardHeader: View {
    let icon: String
    let title: String
    let subtitle: String

    @State private var glow = false

    var body: some View {
        HStack(alignment: .top, spacing: 38) {
            PixelSpriteView(icon)
                .frame(width: 30, height: 36)
                .shadow(color: GameColor.info.opacity(glow ? 0.8 : 0.35), radius: glow ? 10 : 5)
                .padding(.top, 8)
            VStack(alignment: .leading, spacing: 4) {
                Text(title.uppercased())
                    .font(GameFont.title)
                    .foregroundStyle(GameColor.accent)
                Text(subtitle)
                    .font(GameFont.bodyBold)
                    .foregroundStyle(GameColor.white)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { glow = true }
        }
    }
}

// MARK: - Leo's note card

/// A slightly tilted card, like a note taped to the generator.
struct TP1NoteCard<Content: View>: View {
    var tilt: Double = -1.6
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(.horizontal, 22)
            .padding(.vertical, 18)
            .background(Rectangle().fill(GameColor.black))
            .overlay(Rectangle().strokeBorder(GameColor.ashGrey, lineWidth: 1))
            .shadow(color: GameColor.black.opacity(0.6), radius: 8, y: 4)
            .rotationEffect(.degrees(tilt))
    }
}

// MARK: - Buttons

struct TP1PillButton: View {
    enum Kind {
        /// Filled Burgundy with a soft glow ("Start mission").
        case mission
        /// Dark pill with a chevron ("‹ Back").
        case back
        /// Accent outline with glow when enabled; dim grey when disabled ("Next").
        case next
    }

    let title: String
    let kind: Kind
    var width: CGFloat = 132
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if kind == .back {
                    Path { p in
                        p.move(to: CGPoint(x: 7, y: 0))
                        p.addLine(to: CGPoint(x: 0, y: 7))
                        p.addLine(to: CGPoint(x: 7, y: 14))
                    }
                    .stroke(GameColor.white, style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
                    .frame(width: 7, height: 14)
                }
                Text(title)
                    .font(GameFont.play(17))
                    .foregroundStyle(isEnabled ? GameColor.white : GameColor.slateGrey)
                    .lineLimit(1)
            }
            // At least `width`; longer labels ("Discover a new clue") grow the pill.
            .padding(.horizontal, 24)
            .frame(minWidth: width, minHeight: 40, maxHeight: 40)
            .fixedSize()
            .background { background }
            .contentShape(Capsule())
        }
        .buttonStyle(TP1PressStyle())
        .animation(.easeOut(duration: 0.25), value: isEnabled)
    }

    @ViewBuilder
    private var background: some View {
        switch kind {
        case .mission:
            Capsule().fill(GameColor.burgundy)
                .overlay(Capsule().strokeBorder(GameColor.mauve, lineWidth: 1))
                .shadow(color: GameColor.mauve.opacity(0.7), radius: 10)
        case .back:
            Capsule().fill(GameColor.slateGrey.opacity(0.35))
                .overlay(Capsule().strokeBorder(GameColor.slateGrey, lineWidth: 1))
        case .next:
            Capsule().fill(GameColor.black)
                .overlay(Capsule().strokeBorder(isEnabled ? GameColor.accent : GameColor.slateGrey.opacity(0.6),
                                                lineWidth: isEnabled ? 1.5 : 1))
                .shadow(color: GameColor.accent.opacity(isEnabled ? 0.55 : 0), radius: 8)
        }
    }
}

private struct TP1PressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Code line

/// `var powerLevel = 20` in a black box with a light border that turns
/// green (correct) or red (error).
struct TP1CodeLine: View {
    let keyword: String
    let name: String
    let value: Int
    var status: GameCodeBox.Status = .normal

    private var border: Color {
        switch status {
        case .normal:  GameColor.lightGrey
        case .success: GameColor.success
        case .error:   GameColor.error
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            Text("\(keyword) \(name) = ")
            Text(String(value))
                .contentTransition(.numericText(value: Double(value)))
            Spacer(minLength: 0)
        }
        .font(GameFont.bodySm)
        .foregroundStyle(GameColor.white)
        .padding(.horizontal, 16)
        .frame(height: 41)
        .background(Rectangle().fill(GameColor.black))
        .overlay(Rectangle().strokeBorder(border, lineWidth: 1))
        .animation(.easeOut(duration: 0.2), value: status)
    }
}

// MARK: - Footer row

/// Where the Back / Next pills sit on every TP1 card (card points).
enum TP1Footer {
    /// Top of the 40-pt pills: their centre lines up with the cards' Check / Try again buttons.
    static let buttonTop: CGFloat = 309
    static let sideInset: CGFloat = 32
}

/// "Next" for a card's footer slot. The slot is full width at y 317, so this
/// pushes the pill to the right edge and lifts it onto the Back pill's row.
struct TP1NextButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        TP1PillButton(title: title, kind: .next, action: action)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, TP1Footer.sideInset)
            .offset(y: TP1Footer.buttonTop - 317)
    }
}

/// Check / Try again / True / False / Ignite: a 40-pt pill in the card's
/// footer slot (y 317), lifted onto the same bottom row as Back and Next.
struct TP1ActionButton: View {
    let title: String
    var kind: GameButtonKind = .primary
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(GameFont.play(17))
                .foregroundStyle(GameColor.white.opacity(isEnabled ? 1 : 0.45))
                .lineLimit(1)
                .padding(.horizontal, 24)
                .frame(minWidth: 160, minHeight: 40, maxHeight: 40)
                .fixedSize()
                .background {
                    switch kind {
                    case .secondary:
                        Capsule().strokeBorder(GameColor.burgundy, lineWidth: 1.5)
                    case .outline:
                        Capsule().strokeBorder(GameColor.accent, lineWidth: 1.5)
                    case .primary:
                        Capsule().fill(GameColor.burgundy)
                            .overlay(Capsule().strokeBorder(GameColor.mauve, lineWidth: 1))
                            .shadow(color: GameColor.mauve.opacity(isEnabled ? 0.45 : 0), radius: 8)
                    }
                }
                .opacity(isEnabled ? 1 : 0.5)
                .contentShape(Capsule())
        }
        .buttonStyle(TP1PressStyle())
        .animation(.easeOut(duration: 0.25), value: isEnabled)
        .offset(y: TP1Footer.buttonTop - 317)
    }
}

// MARK: - Feedback

/// Success / error line under a challenge, at 16 pt (the shared one is 12 pt).
struct TP1FeedbackLine: View {
    let isSuccess: Bool
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            GameFeedbackIcon(isSuccess: isSuccess, size: 18)
            Text(text)
                .font(GameFont.body)
                .foregroundStyle(isSuccess ? GameColor.success : GameColor.error)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}
