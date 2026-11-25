//
//  TP4Puzzle4View.swift
//  learning_game
//
//  Touchpoint 4 — Puzzle 4.
//  while loop buffer: while progress < 100 { stepDecrypt() }. Wrong conditions never run; a body that doesn't change progress runs forever until I.R.I.S. aborts it.
//  Predict (place the blocks) → Run (Check animates the loop on the stage)
//  → Explain (feedback says why). Content: TP4LoopsContent.puzzle4.
//

import SwiftUI

struct TP4Puzzle4View: View {
    @Bindable var viewModel: TP4LaptopViewModel

    var body: some View {
        CodePuzzleCardView(puzzle: viewModel.puzzle4,
                           step: 4,
                           completed: viewModel.completed,
                           onNext: viewModel.goToNext,
                           onClose: viewModel.close)
    }
}

#Preview("TP4 · Puzzle 4", traits: .fixedLayout(width: 874, height: 402)) {
    ZStack {
        Image("background_light").resizable().interpolation(.none).scaledToFill().ignoresSafeArea()
        GameCardOverlay {
            TP4Puzzle4View(viewModel: TP4LaptopViewModel(startAt: .puzzle4))
        }
    }
}
