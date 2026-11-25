//
//  TP4Puzzle5View.swift
//  learning_game
//
//  Touchpoint 4 — Puzzle 5.
//  Final log isolation: for log in decryptedLogs { if log.isFinal { isolate(log) } }. isFirst isolates the wrong log; delete(log) deletes it.
//  Predict (place the blocks) → Run (Check animates the loop on the stage)
//  → Explain (feedback says why). Content: TP4LoopsContent.puzzle5.
//

import SwiftUI

struct TP4Puzzle5View: View {
    @Bindable var viewModel: TP4LaptopViewModel

    var body: some View {
        CodePuzzleCardView(puzzle: viewModel.puzzle5,
                           step: 5,
                           completed: viewModel.completed,
                           onNext: viewModel.goToNext,
                           onClose: viewModel.close)
    }
}

#Preview("TP4 · Puzzle 5", traits: .fixedLayout(width: 874, height: 402)) {
    ZStack {
        Image("background_light").resizable().interpolation(.none).scaledToFill().ignoresSafeArea()
        GameCardOverlay {
            TP4Puzzle5View(viewModel: TP4LaptopViewModel(startAt: .puzzle5))
        }
    }
}
