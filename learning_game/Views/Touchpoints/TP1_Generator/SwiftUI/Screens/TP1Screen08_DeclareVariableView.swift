//
//  TP1Screen08_DeclareVariableView.swift
//  learning_game
//
//  Touchpoint 1 — Screen 8 "Declaring Variables" (Leo's note ①).
//  Build `var powerLevel = 100` from blocks (a `let` block is the trap —
//  Leo says powerLevel must stay adjustable). Each correct block makes the
//  power core glow brighter; solving it bursts the core to POWER 100%.
//

import SwiftUI

struct TP1Screen08_DeclareVariableView: View {
    @Bindable var viewModel: TP1GeneratorViewModel

    var body: some View {
        let puzzle = viewModel.declareVariable
        TP1BlockPuzzleCard(puzzle: puzzle,
                           onNext: viewModel.goToNext,
                           onClose: viewModel.close) {
            TP1PowerCore(progress: puzzle.progress,
                         isComplete: puzzle.isSolved,
                         isError: puzzle.result != .unchecked && !puzzle.isSolved)
        }
    }
}

// MARK: - Preview

#Preview("Screen 8 · Declaring Variables", traits: .fixedLayout(width: 874, height: 402)) {
    ZStack {
        Image("background")
            .resizable()
            .interpolation(.none)
            .scaledToFill()
        GameCardOverlay {
            TP1Screen08_DeclareVariableView(viewModel: TP1GeneratorViewModel(startAt: .declaringVariable))
        }
    }
}
