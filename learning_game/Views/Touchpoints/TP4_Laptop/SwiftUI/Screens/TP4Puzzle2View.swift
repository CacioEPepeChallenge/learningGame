//
//  TP4Puzzle2View.swift
//  learning_game
//
//  Touchpoint 4 — Puzzle 2.
//  Basic for-in assembly: for log in secureFiles { decrypt(log) }. Mockup "CORRECT ORDER" layout (blocks under the code).
//  Predict (place the blocks) → Run (Check animates the loop on the stage)
//  → Explain (feedback says why). Content: TP4LoopsContent.puzzle2.
//

import SwiftUI

struct TP4Puzzle2View: View {
    @Bindable var viewModel: TP4LaptopViewModel

    var body: some View {
        CodePuzzleCardView(puzzle: viewModel.puzzle2,
                           step: 2,
                           completed: viewModel.completed,
                           onNext: viewModel.goToNext,
                           onClose: viewModel.close)
    }
}

#Preview("TP4 · Puzzle 2", traits: .fixedLayout(width: 874, height: 402)) {
    ZStack {
        Image("background_light").resizable().interpolation(.none).scaledToFill().ignoresSafeArea()
        GameCardOverlay {
            TP4Puzzle2View(viewModel: TP4LaptopViewModel(startAt: .puzzle2))
        }
    }
}
