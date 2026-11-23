//
//  TP3Puzzle3View.swift
//  learning_game
//
//  Touchpoint 3 — Puzzle 3.
//  if / else: pull the Atlas, skip every other book. Swapping the branches runs and pulls the wrong book.
//  Content: TP3ConditionalsContent.puzzle3.
//

import SwiftUI

struct TP3Puzzle3View: View {
    @Bindable var viewModel: TP3BookshelfViewModel

    var body: some View {
        CodePuzzleCardView(puzzle: viewModel.puzzle3,
                           step: 3,
                           completed: viewModel.completed,
                           onNext: viewModel.goToNext,
                           onClose: viewModel.close)
    }
}

#Preview("TP3 · Puzzle 3", traits: .fixedLayout(width: 874, height: 402)) {
    ZStack {
        Image("background_light").resizable().interpolation(.none).scaledToFill()
        GameCardOverlay {
            TP3Puzzle3View(viewModel: TP3BookshelfViewModel(startAt: .puzzle3))
        }
    }
}
