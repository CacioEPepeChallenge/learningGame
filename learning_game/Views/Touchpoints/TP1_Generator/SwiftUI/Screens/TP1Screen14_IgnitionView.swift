//
//  TP1Screen14_IgnitionView.swift
//  learning_game
//
//  Touchpoint 1 — Screen 14 "Ignition" (the payoff).
//  Leo's 3 notes are ticked off with the Swift line the player wrote for each.
//  Ignite → grid power counts to 100%, the generator shakes, sparks burst and
//  it glows Success green. Next → Congratulations card.
//

import SwiftUI

struct TP1Screen14_IgnitionView: View {
    @Bindable var viewModel: TP1GeneratorViewModel

    @State private var appeared = false
    @State private var igniting = false
    @State private var rumble: CGFloat = 0
    @State private var burst = false

    private var content: TP1IgnitionContent { viewModel.ignition }

    var body: some View {
        GameCardChrome(onClose: viewModel.close) {
            ZStack(alignment: .topLeading) {
                GameCardTitle(title: content.title, subtitle: content.subtitle)
                    .offset(x: 35, y: 24)

                generatorBox
                    .frame(width: 220, height: 170)
                    .offset(x: 32, y: 100)

                notes
                    .frame(width: 440, alignment: .leading)
                    .offset(x: 290, y: 100)

                gridPowerBar
                    .frame(width: 440)
                    .offset(x: 290, y: 226)

                feedback
                    .frame(maxWidth: .infinity)
                    .frame(height: 20)
                    .offset(y: 280)

                footerButton
                    .frame(maxWidth: .infinity)
                    .offset(y: 317)
            }
        }
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.96)
        .onAppear { withAnimation(.easeOut(duration: 0.25)) { appeared = true } }
        .sensoryFeedback(.impact(weight: .light), trigger: viewModel.gridPower / 20)
        .sensoryFeedback(.success, trigger: viewModel.isIgnited) { _, new in new }
    }

    // MARK: Generator

    private var generatorBox: some View {
        let box = RoundedRectangle(cornerRadius: 3)
        let online = viewModel.isIgnited
        return ZStack {
            box.fill(GameColor.black)

            RadialGradient(colors: [(online ? GameColor.success : GameColor.info).opacity(online ? 0.5 : Double(viewModel.gridPower) / 250), .clear],
                           center: .center, startRadius: 0, endRadius: 110)

            PixelImage("TP1Generator")
                .frame(width: 150, height: 137)
                .modifier(GameShake(amount: 3, animatableData: rumble))
                .saturation(online || igniting ? 1 : 0.55)

            if burst {
                PixelImage("spark")
                    .frame(width: 150, height: 150)
                    .transition(.asymmetric(insertion: .scale(scale: 0.3).combined(with: .opacity),
                                            removal: .scale(scale: 1.4).combined(with: .opacity)))
            }

            Text(online ? "ONLINE" : "OFFLINE")
                .font(GameFont.silkscreen(9))
                .foregroundStyle(online ? GameColor.success : GameColor.error)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 8)
        }
        .clipShape(box)
        .overlay(box.strokeBorder(online ? GameColor.success : GameColor.ashGrey, lineWidth: 1))
        .shadow(color: GameColor.success.opacity(online ? 0.5 : 0), radius: 16)
        .animation(.easeOut(duration: 0.4), value: online)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Generator \(online ? "online" : "offline")")
    }

    // MARK: Leo's notes checklist

    private var notes: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(content.notesTitle)
                .font(GameFont.bodyBold)
                .foregroundStyle(GameColor.white)
                .padding(.bottom, 2)

            ForEach(TP1LeoNote.allCases) { note in
                let done = viewModel.completedNotes.contains(note)
                HStack(spacing: 12) {
                    if done {
                        GameFeedbackIcon(isSuccess: true, size: 18)
                    } else {
                        Circle().strokeBorder(GameColor.slateGrey, lineWidth: 1.5).frame(width: 18, height: 18)
                    }
                    GameCodeText(code: note.code, size: 14)
                        .opacity(done ? 1 : 0.45)
                }
            }
        }
    }

    // MARK: Grid power

    private var gridPowerBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(content.gridPowerLabel)
                    .font(GameFont.silkscreen(10))
                    .foregroundStyle(GameColor.ashGrey)
                Spacer()
                Text("\(viewModel.gridPower)%")
                    .font(GameFont.silkscreen(10))
                    .foregroundStyle(viewModel.isIgnited ? GameColor.success : GameColor.info)
                    .contentTransition(.numericText(value: Double(viewModel.gridPower)))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(GameColor.black)
                    Capsule()
                        .fill(viewModel.isIgnited ? GameColor.success : GameColor.info)
                        .frame(width: max(geo.size.width * CGFloat(viewModel.gridPower) / 100, 0))
                }
                .overlay(Capsule().strokeBorder(GameColor.slateGrey, lineWidth: 1))
            }
            .frame(height: 12)
        }
        .animation(.linear(duration: 0.05), value: viewModel.gridPower)
    }

    // MARK: Feedback & footer

    @ViewBuilder
    private var feedback: some View {
        if viewModel.isIgnited {
            TP1FeedbackLine(isSuccess: true, text: content.onlineFeedback)
                .transition(.opacity)
        } else if !viewModel.allNotesDone {
            TP1FeedbackLine(isSuccess: false, text: content.missingNotes)
        }
    }

    @ViewBuilder
    private var footerButton: some View {
        if viewModel.isIgnited {
            TP1NextButton(title: content.nextTitle, action: viewModel.goToNext)
                .transition(.opacity)
        } else {
            TP1ActionButton(title: content.igniteTitle) {
                Task { await runIgnition() }
            }
            .disabled(!viewModel.allNotesDone || igniting)
        }
    }

    @MainActor
    private func runIgnition() async {
        igniting = true
        withAnimation(.linear(duration: 1.3).repeatCount(1)) { rumble += 8 }
        await viewModel.ignite()
        withAnimation(.easeOut(duration: 0.2)) { burst = true }
        try? await Task.sleep(for: .milliseconds(600))
        withAnimation(.easeIn(duration: 0.35)) { burst = false }
        igniting = false
    }
}

// MARK: - Preview

#Preview("Screen 14 · Ignition", traits: .fixedLayout(width: 874, height: 402)) {
    let vm = TP1GeneratorViewModel(startAt: .ignition)
    TP1LeoNote.allCases.forEach(vm.complete)
    return ZStack {
        GameColor.midnight
        GameCardOverlay { TP1Screen14_IgnitionView(viewModel: vm) }
    }
}
