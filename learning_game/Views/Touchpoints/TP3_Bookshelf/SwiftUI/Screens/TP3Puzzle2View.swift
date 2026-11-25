//
//  TP3Puzzle2View.swift
//  learning_game
//
//  Touchpoint 3 — Puzzle 2.
//  if shelfPower > 50 { openPort() } — "Correct order" layout. Flipping the comparison actually runs and the port stays shut.
//  Content: TP3ConditionalsContent.puzzle2.
//

import SwiftUI

struct TP3Puzzle2View: View {
    @Bindable var viewModel: TP3BookshelfViewModel

    var body: some View {
        CodePuzzleCardView(puzzle: viewModel.puzzle2,
                           step: 2,
                           completed: viewModel.completed,
                           onNext: viewModel.goToNext,
                           onClose: viewModel.close)
    }
}

#Preview("TP3 · Puzzle 2", traits: .fixedLayout(width: 874, height: 402)) {
    ZStack {
        Image("background_light").resizable().interpolation(.none).scaledToFill().ignoresSafeArea()
        GameCardOverlay {
            TP3Puzzle2View(viewModel: TP3BookshelfViewModel(startAt: .puzzle2))
        }
    }
}
