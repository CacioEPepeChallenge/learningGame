//
//  TP2Screen02_DialogueView.swift
//  learning_game
//
//  Touchpoint 2 — Screen 2: I.R.I.S. dialogue bar over the room (Figma frame 2).
//  Reuses the game's shared `DialogBox` (Views/Shared/Components/DialogBox.swift):
//  tap the bar to continue; after the last line the first card opens.
//

import SwiftUI

struct TP2Screen02_DialogueView: View {
    @Bindable var viewModel: TP2LightsViewModel

    var body: some View {
        DialogBox(line: viewModel.currentDialogueLine,
                  isLast: viewModel.isLastDialogueLine,
                  onNext: { withAnimation(.easeOut(duration: 0.25)) { viewModel.nextDialogueLine() } })
            .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
}

// MARK: - Preview

#Preview("TP2 · Screen 2 · Dialogue", traits: .fixedLayout(width: 874, height: 402)) {
    ZStack {
        Image("background_dimmed")
            .resizable()
            .interpolation(.none)
            .scaledToFill()
        TP2Screen02_DialogueView(viewModel: TP2LightsViewModel())
    }
}
