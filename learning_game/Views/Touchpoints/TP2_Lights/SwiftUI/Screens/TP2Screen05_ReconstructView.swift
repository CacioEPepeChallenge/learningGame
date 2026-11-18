//
//  TP2Screen05_ReconstructView.swift
//  learning_game
//
//  Touchpoint 2 — Screen 5 "Reconstruct the Code" (Figma frame 5,
//  laid out like the "Reconstruct the code" cards in Cards.png / TP1 Screen 8).
//  Build `roomLights [0] = .on` in 4 answer slots from 6 blocks.
//  Traps: `[1]` (that's the desk lamp) and `"on"` (a String, not a LightState).
//  Tap a block → next empty slot · drag a block → that slot · tap a slot → back.
//  The picture box is a close-up of the room's hanging lamp (background_dimmed);
//  when the code is right the lamp lights up.
//

import SwiftUI

struct TP2Screen05_ReconstructView: View {
    @Bindable var viewModel: TP2LightsViewModel

    @State private var appeared = false
    @State private var wrongShake: CGFloat = 0
    @State private var dragging: TP2Block.ID?
    @State private var dragTranslation: CGSize = .zero
    @State private var dragLocation: CGPoint?

    private var content: TP2ReconstructContent { viewModel.reconstruct }

    // Same geometry as the TP1 block cards (card coordinates).
    private let slotSize = CGSize(width: 98, height: 54)
    private let slotX: CGFloat = 214
    private let slotStep: CGFloat = 112
    private let slotY: CGFloat = 140
    private let trayY: CGFloat = 208
    private let blockSize = CGSize(width: 76, height: 40)
    private let trayGap: CGFloat = 6

    private var trayX: CGFloat {
        let n = CGFloat(content.blocks.count)
        return 431 - (n * blockSize.width + (n - 1) * trayGap) / 2   // centred under the slots
    }

    var body: some View {
        GameCardChrome(onClose: viewModel.close) {
            ZStack(alignment: .topLeading) {
                GameCardTitle(title: content.title, subtitle: content.subtitle)
                    .offset(x: 35, y: 24)

                TP2LampCloseUp(isOn: viewModel.isReconstructSolved)
                    .frame(width: 133, height: 126)
                    .offset(x: 32, y: 128)

                slots
                tray

                feedback
                    .frame(maxWidth: .infinity)
                    .frame(height: 20)
                    .offset(y: 273)

                footerButton
                    .frame(maxWidth: .infinity)
                    .offset(y: 317)
            }
            .coordinateSpace(.named("tp2card"))
        }
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.96)
        .onAppear { withAnimation(.easeOut(duration: 0.25)) { appeared = true } }
        .sensoryFeedback(.selection, trigger: viewModel.slots)
        .sensoryFeedback(trigger: viewModel.reconstructCheckCount) { _, _ in
            viewModel.isReconstructSolved ? .success : .error
        }
        .onChange(of: viewModel.reconstructCheckCount) {
            if case .wrong = viewModel.reconstructResult {
                withAnimation(.linear(duration: 0.4)) { wrongShake += 1 }
            }
        }
    }

    // MARK: Slots

    private var slots: some View {
        ForEach(viewModel.slots.indices, id: \.self) { index in
            GameCodeSlot(text: viewModel.block(inSlot: index)?.text, status: slotStatus(index))
                .frame(width: slotSize.width, height: slotSize.height)
                .modifier(GameShake(animatableData: viewModel.isWrong(slot: index) ? wrongShake : 0))
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.snappy(duration: 0.25)) { viewModel.removeBlock(at: index) }
                }
                .offset(x: slotX + CGFloat(index) * slotStep, y: slotY)
                .accessibilityLabel("Slot \(index + 1): \(viewModel.block(inSlot: index)?.text ?? "empty")")
        }
    }

    private func slotStatus(_ index: Int) -> GameCodeSlot.Status {
        if dragging != nil, slotIndex(at: dragLocation) == index { return .target }
        guard viewModel.slots[index] != nil else {
            // Hint: outline the first slot until the player starts.
            return !viewModel.hasStartedLine && index == 0 ? .target : .empty
        }
        switch viewModel.reconstructResult {
        case .unchecked: return .filled
        case .correct: return .correct
        case .wrong(let wrong): return wrong.contains(index) ? .wrong : .correct
        }
    }

    private func slotIndex(at point: CGPoint?) -> Int? {
        guard let point else { return nil }
        return viewModel.slots.indices.first { index in
            CGRect(x: slotX + CGFloat(index) * slotStep, y: slotY,
                   width: slotSize.width, height: slotSize.height)
                .insetBy(dx: -8, dy: -10).contains(point)
        }
    }

    // MARK: Tray

    private var tray: some View {
        ForEach(Array(content.blocks.enumerated()), id: \.element.id) { index, block in
            ZStack {
                GameBlockPlaceholder()
                if !viewModel.isPlaced(block.id) {
                    GameCodeBlockLabel(text: block.text)
                        .scaleEffect(dragging == block.id ? 1.1 : 1)
                        .shadow(color: GameColor.black.opacity(dragging == block.id ? 0.6 : 0), radius: 6, y: 3)
                        .offset(dragging == block.id ? dragTranslation : .zero)
                        .gesture(dragGesture(for: block.id))
                        .onTapGesture {
                            withAnimation(.snappy(duration: 0.25)) { viewModel.placeBlock(block.id) }
                        }
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                        .accessibilityLabel("Block \(block.text)")
                        .accessibilityAddTraits(.isButton)
                }
            }
            .frame(width: blockSize.width, height: blockSize.height)
            .offset(x: trayX + CGFloat(index) * (blockSize.width + trayGap), y: trayY)
            .zIndex(dragging == block.id ? 1 : 0)
        }
    }

    private func dragGesture(for id: TP2Block.ID) -> some Gesture {
        DragGesture(minimumDistance: 6, coordinateSpace: .named("tp2card"))
            .onChanged { value in
                guard !viewModel.isReconstructSolved else { return }
                dragging = id
                dragTranslation = value.translation
                dragLocation = value.location
            }
            .onEnded { value in
                let target = slotIndex(at: value.location)
                withAnimation(.snappy(duration: 0.25)) {
                    if let target { viewModel.placeBlock(id, at: target) }
                    dragging = nil
                    dragTranslation = .zero
                    dragLocation = nil
                }
            }
    }

    // MARK: Feedback & footer

    @ViewBuilder
    private var feedback: some View {
        switch viewModel.reconstructResult {
        case .correct:
            GameFeedbackLine(isSuccess: true, text: content.successFeedback)
                .transition(.opacity)
        case .wrong:
            GameFeedbackLine(isSuccess: false, text: viewModel.reconstructWrongMessage)
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
        switch viewModel.reconstructResult {
        case .correct:
            GameButton(title: content.nextTitle, kind: .outline, action: viewModel.goToNext)
                .transition(.opacity)
        case .wrong:
            GameButton(title: content.tryAgainTitle) {
                withAnimation(.snappy(duration: 0.25)) { viewModel.retryLine() }
            }
            .transition(.opacity)
        case .unchecked:
            if viewModel.isLineFull {
                GameButton(title: content.checkTitle) {
                    withAnimation(.easeOut(duration: 0.25)) { viewModel.checkLine() }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }
}

// MARK: - Lamp close-up (picture box)

/// Close-up of the room's hanging lamp, cropped from `background_dimmed`
/// (1748 × 804). When `isOn`, an Accent glow lights the lamp and the room.
struct TP2LampCloseUp: View {
    let isOn: Bool

    /// Crop of the background around the hanging lamp (x 690…1005, y 0…298).
    private let crop = CGRect(x: 690, y: 0, width: 315, height: 298)
    private let imageSize = CGSize(width: 1748, height: 804)

    var body: some View {
        GeometryReader { geo in
            let scale = geo.size.width / crop.width
            ZStack(alignment: .topLeading) {
                Image("background_dimmed")
                    .resizable()
                    .interpolation(.none)
                    .frame(width: imageSize.width * scale, height: imageSize.height * scale)
                    .offset(x: -crop.minX * scale, y: -crop.minY * scale)
                    .brightness(isOn ? 0.08 : -0.12)

                // Light from the lamp shade (lamp centre ≈ x 848, shade bottom ≈ y 165 in the background).
                RadialGradient(colors: [GameColor.white.opacity(isOn ? 0.55 : 0),
                                        GameColor.accent.opacity(isOn ? 0.55 : 0),
                                        GameColor.accent.opacity(isOn ? 0.18 : 0),
                                        .clear],
                               center: UnitPoint(x: (848 - crop.minX) / crop.width, y: 168 / crop.height),
                               startRadius: 0, endRadius: geo.size.width * 0.62)
                    .frame(width: geo.size.width, height: geo.size.height)   // the box, not the full background
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            .clipped()
        }
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(isOn ? GameColor.accent : GameColor.ashGrey, lineWidth: 1))
        .shadow(color: GameColor.accent.opacity(isOn ? 0.5 : 0), radius: 14)
        .animation(.easeOut(duration: 0.6), value: isOn)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Hanging lamp, \(isOn ? "on" : "off")")
    }
}

// MARK: - Preview

#Preview("TP2 · Screen 5 · Reconstruct the Code", traits: .fixedLayout(width: 874, height: 402)) {
    ZStack {
        Image("background_dimmed")
            .resizable()
            .interpolation(.none)
            .scaledToFill()
        GameCardOverlay {
            TP2Screen05_ReconstructView(viewModel: TP2LightsViewModel(startAt: .reconstruct))
        }
    }
}
