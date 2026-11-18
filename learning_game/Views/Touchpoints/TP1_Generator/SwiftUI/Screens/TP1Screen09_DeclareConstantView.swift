//
//  TP1Screen09_DeclareConstantView.swift
//  learning_game
//
//  Touchpoint 1 — Screen 9 "Declaring Constant".
//  Build `let maxVoltage = 220` (the locked constant from Screen 4) from
//  blocks. Trap: `var`. The voltage meter wobbles until the limit is locked,
//  shakes red on a wrong answer, and settles at "LOCKED AT 220V" when solved.
//

import SwiftUI

struct TP1Screen09_DeclareConstantView: View {
    @Bindable var viewModel: TP1GeneratorViewModel

    var body: some View {
        let puzzle = viewModel.declareConstant
        TP1BlockPuzzleCard(puzzle: puzzle,
                           onNext: viewModel.goToNext,
                           onClose: viewModel.close) {
            TP1VoltageMeter(state: visualState(puzzle))
        }
    }

    private func visualState(_ puzzle: TP1BlockPuzzleViewModel) -> TP1VisualState {
        switch puzzle.result {
        case .unchecked: .idle
        case .correct: .success
        case .wrong: .error
        }
    }
}

// MARK: - Preview

#Preview("Screen 9 · Declaring Constant", traits: .fixedLayout(width: 874, height: 402)) {
    ZStack {
        Image("background")
            .resizable()
            .interpolation(.none)
            .scaledToFill()
        GameCardOverlay {
            TP1Screen09_DeclareConstantView(viewModel: TP1GeneratorViewModel(startAt: .declaringConstant))
        }
    }
}
