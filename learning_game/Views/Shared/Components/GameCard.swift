//
//  GameCard.swift
//  learning_game
//
//  The shared challenge card from the Figma (Cards.png): fixed-size card
//  scaled to fit the screen, dark panel + Mauve border, × close, ‹ Back,
//  I.R.I.S. header / title, and the three button styles.
//

import SwiftUI

enum GameLayout {
    /// Figma frame (iPhone landscape).
    static let frame = CGSize(width: 874, height: 402)
    /// Card inside the frame.
    static let card = CGSize(width: 782, height: 362)
    static let cornerRadius: CGFloat = 10
}

/// Hosts a card over the game: fills the screen, blocks taps to the game below,
/// and scales the fixed-size card to fit.
struct GameCardOverlay<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        GeometryReader { geo in
            let scale = min(geo.size.width / GameLayout.frame.width,
                            geo.size.height / GameLayout.frame.height)
            ZStack {
                // Swallow taps so the game underneath doesn't react while a card is open.
                GameColor.black.opacity(0.001)
                    .contentShape(Rectangle())
                    .onTapGesture {}

                content()
                    .frame(width: GameLayout.card.width, height: GameLayout.card.height)
                    .scaleEffect(scale)
                    .frame(width: GameLayout.card.width * scale,
                           height: GameLayout.card.height * scale)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
    }
}

/// Card chrome: background, border and the top-right close button.
struct GameCardChrome<Content: View>: View {
    var onClose: (() -> Void)?
    @ViewBuilder let content: () -> Content

    /// Set by the touchpoint's root view (e.g. TP1GeneratorRootView) for every card except the first.
    @Environment(\.gameBackAction) private var onBack

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: GameLayout.cornerRadius, style: .continuous)
    }

    var body: some View {
        content()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background {
                // Figma panel ≈ #121923: Black with a faint Accent2 (navy) tint.
                shape.fill(GameColor.black)
                shape.fill(GameColor.accent2.opacity(0.12))
            }
            .overlay { shape.strokeBorder(GameColor.mauve, lineWidth: 1) }
            .overlay(alignment: .topTrailing) {
                if let onClose {
                    GameCloseButton(action: onClose)
                        .padding(.top, 26)
                        .padding(.trailing, 25)
                }
            }
            .overlay(alignment: .bottomLeading) {
                if let onBack {
                    GameBackButton(action: onBack)
                        .padding(.leading, 33)
                        .padding(.bottom, 13)
                }
            }
    }
}

extension EnvironmentValues {
    /// "Back to the previous card" action; nil on the first card.
    @Entry var gameBackAction: (() -> Void)? = nil
}

/// "‹ Back" text button (bottom-left of the card), LightGrey, Play 14.
struct GameBackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Path { p in
                    p.move(to: CGPoint(x: 6, y: 0))
                    p.addLine(to: CGPoint(x: 0, y: 6))
                    p.addLine(to: CGPoint(x: 6, y: 12))
                }
                .stroke(GameColor.lightGrey, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                .frame(width: 6, height: 12)
                Text("Back")
                    .font(GameFont.bodySm)
                    .foregroundStyle(GameColor.lightGrey)
            }
            .frame(height: 32)
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, -8)
        .accessibilityLabel("Back to previous card")
    }
}

/// Thin "×" drawn with two strokes, LightGrey, 14 pt.
struct GameCloseButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Path { p in
                p.move(to: .zero); p.addLine(to: CGPoint(x: 14, y: 14))
                p.move(to: CGPoint(x: 14, y: 0)); p.addLine(to: CGPoint(x: 0, y: 14))
            }
            .stroke(GameColor.lightGrey, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            .frame(width: 14, height: 14)
            .padding(10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(-10)
        .accessibilityLabel("Close")
    }
}

/// I.R.I.S. portrait + Silkscreen title + bold subtitle (top-left of intro cards).
struct GameCardHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 36) {
            PixelImage("iris")
                .frame(width: 96, height: 72)
                .shadow(color: GameColor.accent.opacity(0.35), radius: 14)
            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(GameFont.title)
                    .foregroundStyle(GameColor.accent)
                Text(subtitle)
                    .font(GameFont.bodyBold)
                    .foregroundStyle(GameColor.white)
            }
        }
    }
}

// MARK: - Buttons

enum GameButtonKind {
    /// Filled Burgundy capsule (Start, Check, True, Try again, Let's Go!).
    case primary
    /// Accent outline capsule (Next).
    case outline
    /// Burgundy outline capsule (False).
    case secondary
}

struct GameButton: View {
    let title: String
    var kind: GameButtonKind = .primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(GameFont.body)
                .foregroundStyle(GameColor.white)
                .frame(width: 160, height: 32)
                .background {
                    switch kind {
                    case .primary:   Capsule().fill(GameColor.burgundy)
                    case .outline:   Capsule().strokeBorder(GameColor.accent, lineWidth: 1)
                    case .secondary: Capsule().strokeBorder(GameColor.burgundy, lineWidth: 1)
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(GamePressStyle())
    }
}

private struct GamePressStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(!isEnabled ? 0.35 : configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
            .animation(.easeOut(duration: 0.25), value: isEnabled)
    }
}

/// Title + subtitle without the I.R.I.S. portrait (challenge cards).
struct GameCardTitle: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(GameFont.title)
                .foregroundStyle(GameColor.accent)
            Text(subtitle)
                .font(GameFont.body)
                .foregroundStyle(GameColor.white)
        }
    }
}
