//
//  GameControls.swift
//  learning_game
//
//  Shared interactive pieces: one-line code box, Figma slider (with drag
//  hint and locked mode), success / error feedback icon + line, shake.
//

import SwiftUI

// MARK: - Code box

/// Dark box with one line of Swift, e.g. `var powerLevel = 20`.
struct GameCodeBox: View {
    enum Status { case normal, success, error }

    let keyword: String
    let name: String
    let value: Int
    var status: Status = .normal

    private var borderColor: Color {
        switch status {
        case .normal:  GameColor.slateGrey
        case .success: GameColor.success
        case .error:   GameColor.error
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            Text("\(keyword) \(name) = ")
            Text(String(value))
                .foregroundStyle(status == .success ? GameColor.success : GameColor.lightGrey)
                .contentTransition(.numericText(value: Double(value)))
            Spacer(minLength: 0)
        }
        .font(GameFont.bodySm)
        .foregroundStyle(GameColor.lightGrey)
        .padding(.horizontal, 16)
        .frame(height: 48)
        .background(RoundedRectangle(cornerRadius: 4).fill(GameColor.black))
        .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(borderColor, lineWidth: 1))
        .animation(.easeOut(duration: 0.2), value: status)
    }
}

// MARK: - Slider

/// Figma slider: active track | thin vertical thumb | inactive track with end dot.
/// When `isLocked`, it resists the drag, springs back and calls `onLockedAttempt`.
struct GameSlider: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    var isLocked = false
    /// Shows a looping "drag me →" hint until the player first moves the slider.
    var showsHint = false
    var onLockedAttempt: () -> Void = {}
    var onEditingEnded: () -> Void = {}
    /// Colour of the filled track and the thumb.
    var tint: Color = GameColor.mauve

    private let trackHeight: CGFloat = 16
    private let thumbSize = CGSize(width: 4, height: 44)
    private let gap: CGFloat = 6

    @GestureState private var resistance: CGFloat = 0
    @State private var didReportAttempt = false

    private var fraction: CGFloat {
        CGFloat(value - range.lowerBound) / CGFloat(range.upperBound - range.lowerBound)
    }

    var body: some View {
        GeometryReader { geo in
            let usable = geo.size.width - thumbSize.width
            let thumbX = fraction * usable + resistance

            ZStack(alignment: .leading) {
                // Active (filled) track
                Capsule()
                    .fill(tint)
                    .frame(width: max(thumbX - gap, 0), height: trackHeight)

                // Inactive track + end dot
                Capsule()
                    .fill(GameColor.lightGrey)
                    .frame(width: max(geo.size.width - thumbX - thumbSize.width - gap, 0),
                           height: trackHeight)
                    .overlay(alignment: .trailing) {
                        Circle()
                            .fill(GameColor.slateGrey)
                            .frame(width: 4, height: 4)
                            .padding(.trailing, 6)
                    }
                    .offset(x: thumbX + thumbSize.width + gap)

                // Drag hint: a faint Accent "ghost" thumb glides toward the max, on loop.
                if showsHint {
                    TimelineView(.animation) { timeline in
                        let t = timeline.date.timeIntervalSinceReferenceDate
                            .truncatingRemainder(dividingBy: 1.6) / 1.6
                        let eased = 1 - pow(1 - t, 3)
                        let ghostX = min(thumbX + eased * 80, usable)
                        Capsule()
                            .fill(GameColor.accent)
                            .frame(width: thumbSize.width, height: thumbSize.height)
                            .opacity(sin(.pi * t) * 0.8)
                            .shadow(color: GameColor.accent.opacity(0.8), radius: 6)
                            .offset(x: ghostX)
                    }
                    .allowsHitTesting(false)
                    .transition(.opacity)
                }

                // Thumb
                Capsule()
                    .fill(isLocked && didReportAttempt ? GameColor.error : tint)
                    .frame(width: thumbSize.width, height: thumbSize.height)
                    .shadow(color: GameColor.accent.opacity(showsHint ? 0.9 : 0),
                            radius: showsHint ? 6 : 0)
                    .offset(x: thumbX)
            }
            .animation(.easeOut(duration: 0.3), value: showsHint)
            .animation(.easeOut(duration: 0.3), value: tint)
            .frame(width: geo.size.width, height: geo.size.height, alignment: .leading)
            .contentShape(Rectangle())
            .gesture(dragGesture(usable: usable))
        }
        .frame(height: thumbSize.height)
        .sensoryFeedback(.selection, trigger: value)
    }

    private func dragGesture(usable: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($resistance) { drag, state, _ in
                guard isLocked else { return }
                // Rubber-band: the constant barely budges, then springs back on release.
                let t = drag.translation.width
                state = 10 * tanh(t / 60)
            }
            .onChanged { drag in
                if isLocked {
                    if !didReportAttempt, abs(drag.translation.width) > 4 {
                        didReportAttempt = true
                        onLockedAttempt()
                    }
                    return
                }
                let f = min(max((drag.location.x - thumbSize.width / 2) / usable, 0), 1)
                let span = Double(range.upperBound - range.lowerBound)
                value = range.lowerBound + Int((Double(f) * span).rounded())
            }
            .onEnded { _ in
                didReportAttempt = false
                onEditingEnded()
            }
    }
}

// MARK: - Feedback

/// Filled circle with a check (success) or a cross (error), as in Cards.png.
struct GameFeedbackIcon: View {
    let isSuccess: Bool
    var size: CGFloat = 16

    var body: some View {
        ZStack {
            Circle().fill(isSuccess ? GameColor.success : GameColor.error)
            Path { p in
                let s = size
                if isSuccess {
                    p.move(to: CGPoint(x: s * 0.28, y: s * 0.52))
                    p.addLine(to: CGPoint(x: s * 0.44, y: s * 0.68))
                    p.addLine(to: CGPoint(x: s * 0.72, y: s * 0.36))
                } else {
                    p.move(to: CGPoint(x: s * 0.33, y: s * 0.33))
                    p.addLine(to: CGPoint(x: s * 0.67, y: s * 0.67))
                    p.move(to: CGPoint(x: s * 0.67, y: s * 0.33))
                    p.addLine(to: CGPoint(x: s * 0.33, y: s * 0.67))
                }
            }
            .stroke(GameColor.black, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }
}

/// Icon + caption line under a challenge ("True! …" / "Error: …").
struct GameFeedbackLine: View {
    let isSuccess: Bool
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            GameFeedbackIcon(isSuccess: isSuccess, size: 14)
            Text(text)
                .font(GameFont.caption)
                .foregroundStyle(isSuccess ? GameColor.success : GameColor.error)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

// MARK: - Shake

struct GameShake: GeometryEffect {
    var amount: CGFloat = 6
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: amount * sin(animatableData * .pi * 4), y: 0))
    }
}

#Preview{
    GameFeedbackLine(isSuccess: true, text: "yay")
}
