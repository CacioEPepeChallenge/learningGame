//
//  TP5IntroAndLessonViews.swift
//  learning_game
//
//  Touchpoint 5 — the intro card (slide the painting aside to find the safe),
//  the five lesson cards (Intro Challenges style, with a "Watch it run"
//  demo that steps through the example code), and the open-safe finale.
//

import SwiftUI

/// The five locks, in order.
enum TP5LockInfo {
    static let names = [
        "Define, then call",
        "Trace the calls",
        "Pass the arguments",
        "Return the key",
        "Write it once",
    ]
}

// MARK: - Intro

struct TP5IntroView: View {
    @Bindable var viewModel: TP5PaintingViewModel

    @State private var appeared = false

    var body: some View {
        let moved = viewModel.isPaintingMoved
        GameCardChrome(onClose: viewModel.close) {
            ZStack(alignment: .topLeading) {
                GameCardHeader(title: "The painting", subtitle: "Leo never hangs anything crooked.")
                    .offset(x: 26, y: 21)

                TP5PaintingReveal(isMoved: moved, onMove: viewModel.movePainting)
                    .offset(x: 34, y: 98)

                VStack(alignment: .leading, spacing: 12) {
                    Text(moved
                         ? "A safe! Five deadbolts, and each one is wired to a function. Crack all five to open it."
                         : "Something is hidden behind this painting. Slide it aside to see what Leo was protecting.")
                        .font(GameFont.bodySm)
                        .foregroundStyle(GameColor.white)
                        .fixedSize(horizontal: false, vertical: true)
                        .id(moved)
                        .transition(.opacity)

                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(TP5LockInfo.names.indices, id: \.self) { i in
                            HStack(spacing: 10) {
                                Text("\(i + 1)")
                                    .font(GameFont.captionBold)
                                    .foregroundStyle(GameColor.ashGrey)
                                    .frame(width: 20, height: 20)
                                    .overlay(Circle().strokeBorder(GameColor.slateGrey, lineWidth: 1))
                                Text(TP5LockInfo.names[i])
                                    .font(GameFont.bodySm)
                                    .foregroundStyle(GameColor.lightGrey)
                                Spacer()
                                Text("LOCKED")
                                    .font(GameFont.silkscreen(9))
                                    .foregroundStyle(GameColor.error)
                            }
                            .opacity(moved ? 1 : 0.25)
                            .offset(x: moved ? 0 : 12)
                            .animation(.spring(duration: 0.5).delay(Double(i) * 0.07), value: moved)
                        }
                    }
                }
                .frame(width: 400, alignment: .leading)
                .offset(x: 330, y: 108)

                GameButton(title: "Start", action: viewModel.goToNext)
                    .disabled(!moved)
                    .frame(maxWidth: .infinity)
                    .offset(y: 317)
            }
        }
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.96)
        .onAppear { withAnimation(.easeOut(duration: 0.25)) { appeared = true } }
        .sensoryFeedback(.impact(weight: .medium), trigger: moved)
    }
}

// MARK: - Lesson

struct TP5LessonView: View {
    let lesson: TP5Lesson
    let number: Int
    let opened: Set<Int>
    let onNext: () -> Void
    let onClose: () -> Void

    @State private var appeared = false
    @State private var activeLine: Int?
    @State private var note: String?
    @State private var outputs: [String] = []
    @State private var stack: [String] = []
    @State private var isPlaying = false
    @State private var hasPlayed = false
    @State private var playTask: Task<Void, Never>?

    var body: some View {
        GameCardChrome(onClose: onClose) {
            ZStack(alignment: .topLeading) {
                GameCardHeader(title: "Lesson \(number) · \(lesson.title)", subtitle: lesson.subtitle)
                    .offset(x: 26, y: 21)

                explanation
                    .frame(width: 350, alignment: .leading)
                    .offset(x: 33, y: 108)

                demoBox
                    .frame(width: 344, height: 206)
                    .offset(x: 406, y: 98)

                HStack(spacing: 12) {
                    GameButton(title: hasPlayed ? "Watch again" : "Watch it run", kind: .outline, action: play)
                        .disabled(isPlaying)
                    GameButton(title: "Let's Go!", action: onNext)
                }
                .frame(maxWidth: .infinity)
                .offset(y: 317)
            }
        }
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.96)
        .onAppear { withAnimation(.easeOut(duration: 0.25)) { appeared = true } }
        .onDisappear { playTask?.cancel() }
    }

    private var explanation: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(lesson.paragraphs, id: \.self) { p in
                Text(p)
                    .font(GameFont.bodySm)
                    .foregroundStyle(GameColor.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("KEY IDEA")
                    .font(GameFont.silkscreen(8))
                    .foregroundStyle(GameColor.black)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: 2).fill(GameColor.info))
                Text(lesson.keyIdea)
                    .font(GameFont.bodySmBold)
                    .foregroundStyle(GameColor.info)
                    .fixedSize(horizontal: false, vertical: true)
            }
            TP5LockDots(current: number, opened: opened)
                .padding(.top, 2)
        }
    }

    private var demoBox: some View {
        TP5CodeBox(phase: isPlaying ? .running : .editing) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(lesson.code.indices, id: \.self) { i in
                    TP5CodeRow(number: i, isActive: activeLine == i, height: 15) {
                        TP5CodeText(lesson.code[i], size: 11)
                    }
                }
                Spacer(minLength: 4)

                Rectangle().fill(GameColor.slateGrey.opacity(0.5)).frame(height: 1)
                    .padding(.bottom, 5)

                TP5CallStack(frames: stack)
                    .frame(height: 16)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("OUTPUT")
                        .font(GameFont.silkscreen(8))
                        .foregroundStyle(GameColor.ashGrey)
                    Text(outputs.isEmpty ? "…" : outputs.joined(separator: "  ·  "))
                        .font(GameFont.play(11))
                        .foregroundStyle(GameColor.peach)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .contentTransition(.opacity)
                }
                .frame(height: 16)

                Text(note ?? (hasPlayed ? " " : "Tap Watch it run to step through the code."))
                    .font(GameFont.play(11, bold: note != nil))
                    .foregroundStyle(note == nil ? GameColor.slateGrey : GameColor.info)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(height: 15)
                    .id(note)
                    .transition(.opacity)
            }
        }
    }

    private func play() {
        playTask?.cancel()
        playTask = Task {
            isPlaying = true
            outputs = []
            for step in lesson.demo {
                if Task.isCancelled { return }
                withAnimation(.easeOut(duration: 0.2)) {
                    activeLine = step.line
                    note = step.note
                    stack = step.stack
                    if let o = step.output { outputs.append(o) }
                }
                try? await Task.sleep(for: .milliseconds(1150))
            }
            withAnimation {
                activeLine = nil
                stack = []
                note = "Done! Your turn."
            }
            isPlaying = false
            hasPlayed = true
        }
    }
}

// MARK: - Finale

struct TP5SafeOpenView: View {
    @Bindable var viewModel: TP5PaintingViewModel

    @State private var appeared = false
    @State private var celebrate = 0

    private let learned = [
        "func stores steps, and () calls them",
        "Calls can nest. The call stack keeps track",
        "Parameters let one function do many jobs",
        "-> and return hand a value back",
        "Repeated code → one function + a parameter",
    ]

    var body: some View {
        GameCardChrome(onClose: viewModel.close) {
            ZStack(alignment: .topLeading) {
                GameCardHeader(title: "Congratulations", subtitle: "All five deadbolts are open.")
                    .offset(x: 26, y: 21)

                AnimatedGIFView(name: "painting_safe")
                    .frame(width: 128, height: 192)
                    .shadow(color: GameColor.accent.opacity(0.45), radius: 18)
                    .offset(x: 70, y: 104)

                VStack(alignment: .leading, spacing: 8) {
                    Text("WHAT YOU LEARNED")
                        .font(GameFont.silkscreen(11))
                        .foregroundStyle(GameColor.accent)
                    ForEach(learned.indices, id: \.self) { i in
                        HStack(spacing: 8) {
                            GameFeedbackIcon(isSuccess: true, size: 14)
                            Text(learned[i])
                                .font(GameFont.bodySm)
                                .foregroundStyle(GameColor.white)
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(x: appeared ? 0 : 16)
                        .animation(.spring(duration: 0.5).delay(0.3 + Double(i) * 0.12), value: appeared)
                    }
                    Text("IRIS: Something's inside. Let's see what Leo left behind.")
                        .font(GameFont.caption)
                        .foregroundStyle(GameColor.info)
                        .padding(.top, 6)
                }
                .frame(width: 430, alignment: .leading)
                .offset(x: 290, y: 112)

                GameButton(title: "Discover a new clue", kind: .outline, action: viewModel.goToNext)
                    .frame(maxWidth: .infinity)
                    .offset(y: 317)

                TP5Confetti(trigger: celebrate)
                    .frame(width: GameLayout.card.width, height: GameLayout.card.height)
            }
        }
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.96)
        .onAppear {
            withAnimation(.easeOut(duration: 0.25)) { appeared = true }
            celebrate += 1
        }
        .sensoryFeedback(.success, trigger: celebrate)
    }
}
