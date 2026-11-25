//
//  TP3Puzzle4View.swift
//  learning_game
//
//  Touchpoint 3 — Puzzle 4.
//  else if / else chain on the port light (amber → wait()).
//  Content: TP3ConditionalsContent.puzzle4.
//

import SwiftUI

struct TP3Puzzle4View: View {
    @Bindable var viewModel: TP3BookshelfViewModel

    var body: some View {
        CodePuzzleCardView(puzzle: viewModel.puzzle4,
                           step: 4,
                           completed: viewModel.completed,
                           onNext: viewModel.goToNext,
                           onClose: viewModel.close)
    }
}

#Preview("TP3 · Puzzle 4", traits: .fixedLayout(width: 874, height: 402)) {
    ZStack {
        Image("background_light").resizable().interpolation(.none).scaledToFill().ignoresSafeArea()
        GameCardOverlay {
            TP3Puzzle4View(viewModel: TP3BookshelfViewModel(startAt: .puzzle4))
        }
    }
}
