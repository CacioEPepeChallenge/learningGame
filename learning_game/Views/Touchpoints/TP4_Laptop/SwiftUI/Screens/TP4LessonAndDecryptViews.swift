//
//  TP4LessonAndDecryptViews.swift
//  learning_game
//
//  Touchpoint 4 — the two I.R.I.S. lesson cards ("FOR IN LOOP", "WHILE LOOP")
//  and the "DECRYPTING…" card shown after Puzzle 5 (mockup screen 9).
//

import SwiftUI

struct TP4LessonView: View {
    let content: LessonContent
    @Bindable var viewModel: TP4LaptopViewModel

    var body: some View {
        LessonCardView(content: content, onNext: viewModel.goToNext, onClose: viewModel.close)
    }
}

/// Big pixel "DECRYPTING…" with a scrolling hex stream; plays the decrypt
/// sound and moves on by itself.
struct TP4DecryptingView: View {
    @Bindable var viewModel: TP4LaptopViewModel

    @State private var appeared = false
    @State private var dots = 0
    @State private var progress = 0.0

    var body: some View {
        GameCardChrome(onClose: viewModel.close) {
            VStack(spacing: 18) {
                Spacer()
                Text("DECRYPTING" + String(repeating: ".", count: dots))
                    .font(GameFont.silkscreen(44))
                    .foregroundStyle(GameColor.accent)
                    .shadow(color: GameColor.accent.opacity(0.6), radius: 10)
                    .frame(width: 560, alignment: .leading)
                    .padding(.leading, 120)

                TimelineView(.periodic(from: .now, by: 0.08)) { t in
                    Text(hexLine(seed: Int(t.date.timeIntervalSinceReferenceDate * 12)))
                        .font(GameFont.play(11))
                        .foregroundStyle(GameColor.success.opacity(0.7))
                        .lineLimit(1)
                }
                .frame(width: 520)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(GameColor.slateGrey.opacity(0.4))
                        Capsule().fill(GameColor.accent).frame(width: geo.size.width * progress)
                    }
                }
                .frame(width: 520, height: 6)
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
        .opacity(appeared ? 1 : 0)
        .onAppear { withAnimation(.easeOut(duration: 0.25)) { appeared = true } }
        .task {
            RetroSFX.shared.playDecrypt()
            withAnimation(.easeInOut(duration: 2.6)) { progress = 1 }
            for _ in 0..<9 {
                try? await Task.sleep(for: .milliseconds(320))
                dots = (dots + 1) % 4
            }
            viewModel.goToNext()
        }
    }

    private func hexLine(seed: Int) -> String {
        var x = UInt64(truncatingIfNeeded: seed &* 2654435761)
        return (0..<14).map { _ in
            x = x &* 6364136223846793005 &+ 1442695040888963407
            return String(format: "%02X%02X", Int(x >> 56), Int((x >> 48) & 0xFF))
        }.joined(separator: " ")
    }
}
