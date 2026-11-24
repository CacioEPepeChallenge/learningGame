//
//  TP4TranscriptView.swift
//  learning_game
//
//  Touchpoint 4 — the decrypted final log, played back as a TRANSCRIPT
//  (mockup screens 11–13). Sensor / Leo lines type out one by one;
//  I.R.I.S. cuts in with a dialogue box at the bottom ("…", "The audio seems
//  to have cut off from here."). Tap to skip typing, answer I.R.I.S., and
//  close when the readout is done. Shown by GameModel over the room.
//

import SwiftUI

struct TP4TranscriptView: View {
    let onFinish: () -> Void

    private typealias Entry = (speaker: TP4Content.TranscriptSpeaker, text: String)
    private let lines = TP4Content.transcript

    @State private var shown: [Entry] = []
    @State private var typed = 0
    @State private var index = 0
    @State private var irisLine: String?
    @State private var finished = false
    @State private var typingTask: Task<Void, Never>?
    @State private var appeared = false

    var body: some View {
        ZStack {
            GameColor.black.opacity(0.55)
                .ignoresSafeArea()

            GameCardOverlay {
                panel
                    .contentShape(Rectangle())
                    .onTapGesture(perform: tap)
            }
        }
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) { appeared = true }
            advance()
        }
        .onDisappear { typingTask?.cancel() }
    }

    private var panel: some View {
        let shape = RoundedRectangle(cornerRadius: GameLayout.cornerRadius, style: .continuous)
        return ZStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 10) {
                Text("TRANSCRIPT")
                    .font(GameFont.silkscreen(30))
                    .foregroundStyle(GameColor.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 6)

                ForEach(Array(shown.enumerated()), id: \.offset) { i, entry in
                    let isLast = i == shown.count - 1
                    line(entry, visible: isLast ? typed : entry.text.count)
                        .transition(.opacity)
                }
                Spacer(minLength: 0)

                if finished {
                    Text("Tap to continue ›")
                        .font(GameFont.caption)
                        .foregroundStyle(GameColor.ashGrey)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, 44)
            .padding(.top, 22)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            if let irisLine {
                irisBox(irisLine)
                    .padding(14)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background { shape.fill(GameColor.black.opacity(0.85)); shape.fill(GameColor.accent2.opacity(0.12)) }
        .overlay(shape.strokeBorder(GameColor.slateGrey, lineWidth: 1))
        .animation(.easeOut(duration: 0.25), value: irisLine)
        .animation(.easeOut(duration: 0.25), value: finished)
    }

    private func line(_ entry: Entry, visible: Int) -> some View {
        let label = entry.speaker == .sensor ? "SENSOR DATA" : "LEO"
        let color = entry.speaker == .sensor ? GameColor.accent : GameColor.error
        let body = String(entry.text.prefix(visible))
        return Text("\(Text(label).foregroundStyle(color)): \(Text(body))")
            .font(GameFont.bodySm)
            .foregroundStyle(GameColor.white)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func irisBox(_ text: String) -> some View {
        HStack(spacing: 18) {
            Image("iris_dialogue")
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(width: 70, height: 70)
                .background(GameColor.black)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 6) {
                Text("IRIS")
                    .font(GameFont.silkscreen(14))
                    .foregroundStyle(GameColor.accent)
                Text(text)
                    .font(GameFont.bodySm)
                    .foregroundStyle(GameColor.white)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(GameColor.white)
                .padding(.trailing, 8)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color("Twilight").opacity(0.97)))
    }

    // MARK: Flow

    private func advance() {
        guard index < lines.count else {
            finished = true
            return
        }
        let entry = lines[index]
        index += 1
        if entry.speaker == .iris {
            irisLine = entry.text
        } else {
            withAnimation { shown.append(entry) }
            typed = 0
            typingTask?.cancel()
            typingTask = Task {
                while typed < entry.text.count {
                    try? await Task.sleep(for: .milliseconds(22))
                    if Task.isCancelled { return }
                    typed = min(entry.text.count, typed + 2)
                }
                try? await Task.sleep(for: .milliseconds(900))
                if Task.isCancelled { return }
                advance()
            }
        }
    }

    private func tap() {
        if irisLine != nil {
            irisLine = nil
            advance()
        } else if let last = shown.last, typed < last.text.count {
            typed = last.text.count          // skip typing; the task then moves on
        } else if finished {
            onFinish()
        } else {
            typingTask?.cancel()
            advance()
        }
    }
}

#Preview("TP4 · Transcript", traits: .fixedLayout(width: 874, height: 402)) {
    ZStack {
        Image("background_light").resizable().interpolation(.none).scaledToFill()
        TP4TranscriptView(onFinish: {})
    }
}
