//
//  TP1BlockPuzzleCard.swift
//  learning_game
//
//  Shared layout for "Put the blocks in the correct order" cards (Screens 8, 9).
//  Figma geometry: visual box left, 4 answer slots on top, block tray below,
//  feedback line, then Check / Try again / Next.
//

import SwiftUI

struct TP1BlockPuzzleCard<Visual: View>: View {
    @Bindable var puzzle: TP1BlockPuzzleViewModel
    let onNext: () -> Void
    let onClose: () -> Void
    @ViewBuilder let visual: () -> Visual

    @State private var appeared = false
    @State private var dragging: TP1CodeBlock.ID?
    @State private var dragTranslation: CGSize = .zero
    @State private var dragLocation: CGPoint?
    @State private var wrongShake: CGFloat = 0

    private var content: TP1BlockPuzzleContent { puzzle.content }

    // Figma geometry (card coordinates).
    private let slotSize = CGSize(width: 98, height: 54)
    private let slotX: CGFloat = 214
    private let slotStep: CGFloat = 112
    private let slotY: CGFloat = 140
    private let trayY: CGFloat = 208
    private let blockHeight: CGFloat = 40
    /// Up to 5 blocks fill the slot span (214…648). More blocks get a little
    /// narrower and the tray is centered under the slots.
    private var trayGap: CGFloat { content.blocks.count > 5 ? 6 : 8 }

    private var blockWidth: CGFloat {
        let n = CGFloat(content.blocks.count)
        return n > 5 ? 76 : (434 - (n - 1) * trayGap) / n
    }

    private var trayX: CGFloat {
        let n = CGFloat(content.blocks.count)
        let width = n * blockWidth + (n - 1) * trayGap
        return 431 - width / 2          // 431 = center of the slot span
    }

    var body: some View {
        GameCardChrome(onClose: onClose) {
            ZStack(alignment: .topLeading) {
                GameCardTitle(title: content.title, subtitle: content.subtitle)
                    .offset(x: 35, y: 24)

                visual()
                    .frame(width: 133, height: 126)
                    .offset(x: 32, y: 128)

                slots
                tray

                feedback
                    .frame(maxWidth: .infinity)
                    .frame(height: 20)
                    .offset(y: 273)

                // Check / Try again / Next all sit bottom-right, where Next appears.
                footerButton
                    .tp1FooterTrailing()
            }
            .coordinateSpace(.named("tp1card"))
        }
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.96)
        .onAppear { withAnimation(.easeOut(duration: 0.25)) { appeared = true } }
        .sensoryFeedback(.selection, trigger: puzzle.slots)
        .sensoryFeedback(trigger: puzzle.checkCount) { _, _ in
            puzzle.isSolved ? .success : .error
        }
        .onChange(of: puzzle.slots) { RetroSFX.shared.playTick() }
        .onChange(of: puzzle.checkCount) {
            if case .wrong = puzzle.result {
                withAnimation(.linear(duration: 0.4)) { wrongShake += 1 }
                RetroSFX.shared.playBack()
            } else if puzzle.isSolved {
                RetroSFX.shared.playSuccess()
            }
        }
    }

    // MARK: Slots

    private var slots: some View {
        ForEach(puzzle.slots.indices, id: \.self) { index in
            GameCodeSlot(text: puzzle.block(inSlot: index)?.text, status: slotStatus(index))
                .frame(width: slotSize.width, height: slotSize.height)
                .modifier(GameShake(animatableData: puzzle.isWrong(slot: index) ? wrongShake : 0))
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.snappy(duration: 0.25)) { puzzle.removeBlock(at: index) }
                }
                .offset(x: slotX + CGFloat(index) * slotStep, y: slotY)
                .accessibilityLabel("Slot \(index + 1): \(puzzle.block(inSlot: index)?.text ?? "empty")")
        }
    }

    private func slotStatus(_ index: Int) -> GameCodeSlot.Status {
        if dragging != nil, slotIndex(at: dragLocation) == index { return .target }
        guard puzzle.slots[index] != nil else {
            // Hint: outline the first slot in Accent until the player starts.
            return !puzzle.hasStarted && index == 0 ? .target : .empty
        }
        switch puzzle.result {
        case .unchecked: return .filled
        case .correct: return .correct
        case .wrong(let wrong): return wrong.contains(index) ? .wrong : .correct
        }
    }

    private func slotRect(_ index: Int) -> CGRect {
        CGRect(x: slotX + CGFloat(index) * slotStep, y: slotY,
               width: slotSize.width, height: slotSize.height)
    }

    private func slotIndex(at point: CGPoint?) -> Int? {
        guard let point else { return nil }
        return puzzle.slots.indices.first { slotRect($0).insetBy(dx: -8, dy: -10).contains(point) }
    }

    // MARK: Tray

    private var tray: some View {
        ForEach(Array(content.blocks.enumerated()), id: \.element.id) { index, block in
            let x = trayX + CGFloat(index) * (blockWidth + trayGap)
            ZStack {
                GameBlockPlaceholder()
                if !puzzle.isPlaced(block.id) {
                    GameCodeBlockLabel(text: block.text)
                        .scaleEffect(dragging == block.id ? 1.1 : 1)
                        .shadow(color: GameColor.black.opacity(dragging == block.id ? 0.6 : 0), radius: 6, y: 3)
                        .offset(dragging == block.id ? dragTranslation : .zero)
                        .gesture(dragGesture(for: block.id))
                        .onTapGesture {
                            withAnimation(.snappy(duration: 0.25)) { puzzle.place(block.id) }
                        }
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                        .accessibilityLabel("Block \(block.text)")
                        .accessibilityAddTraits(.isButton)
                }
            }
            .frame(width: blockWidth, height: blockHeight)
            .offset(x: x, y: trayY)
            .zIndex(dragging == block.id ? 1 : 0)
        }
    }

    private func dragGesture(for id: TP1CodeBlock.ID) -> some Gesture {
        DragGesture(minimumDistance: 6, coordinateSpace: .named("tp1card"))
            .onChanged { value in
                guard !puzzle.isSolved else { return }
                dragging = id
                dragTranslation = value.translation
                dragLocation = value.location
            }
            .onEnded { value in
                let target = slotIndex(at: value.location)
                withAnimation(.snappy(duration: 0.25)) {
                    if let target { puzzle.place(id, at: target) }
                    dragging = nil
                    dragTranslation = .zero
                    dragLocation = nil
                }
            }
    }

    // MARK: Feedback & footer

    @ViewBuilder
    private var feedback: some View {
        switch puzzle.result {
        case .correct:
            TP1FeedbackLine(isSuccess: true, text: content.successFeedback)
                .transition(.opacity)
        case .wrong:
            TP1FeedbackLine(isSuccess: false, text: puzzle.wrongMessage)
                .transition(.opacity)
        case .unchecked:
            Text("\(Text(content.taskLabel).foregroundStyle(GameColor.accent)) \(content.taskText)")
                .font(GameFont.bodySmBold)
                .foregroundStyle(GameColor.white)
                .transition(.opacity)
        }
    }

    @ViewBuilder
    private var footerButton: some View {
        switch puzzle.result {
        case .correct:
            TP1NextButton(title: content.nextTitle, action: onNext)
                .transition(.opacity)
        case .wrong:
            TP1ActionButton(title: content.tryAgainTitle) {
                withAnimation(.snappy(duration: 0.25)) { puzzle.retry() }
            }
            .transition(.opacity)
        case .unchecked:
            // Greyed-out until every slot has a block, so the footer slot never goes empty.
            TP1ActionButton(title: content.checkTitle) {
                withAnimation(.easeOut(duration: 0.25)) { puzzle.check() }
            }
            .disabled(!puzzle.allFilled)
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }
}
