//
//  TP4Puzzle3View.swift
//  learning_game
//
//  Touchpoint 4 — Puzzle 3.
//  for-in with a filter: for entry in rawLogs { if entry.isVideo { decrypt(entry) } }. Choosing isAudio actually runs, so the player watches the wrong log get decrypted.
//  Predict (place the blocks) → Run (Check animates the loop on the stage)
//  → Explain (feedback says why). Content: TP4LoopsContent.puzzle3.
//

import SwiftUI

struct TP4Puzzle3View: View {
    @Bindable var viewModel: TP4LaptopViewModel

    var body: some View {
        CodePuzzleCardView(puzzle: viewModel.puzzle3,
                           step: 3,
                           completed: viewModel.completed,
                           onNext: viewModel.goToNext,
                           onClose: viewModel.close)
    }
}

#Preview("TP4 · Puzzle 3", traits: .fixedLayout(width: 874, height: 402)) {
    ZStack {
        Image("background_light").resizable().interpolation(.none).scaledToFill()
        GameCardOverlay {
            TP4Puzzle3View(viewModel: TP4LaptopViewModel(startAt: .puzzle3))
        }
    }
}
