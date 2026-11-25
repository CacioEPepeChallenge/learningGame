//
//  TP3Puzzle5View.swift
//  learning_game
//
//  Touchpoint 3 — Puzzle 5.
//  &&: download only with the keycard AND a live port. || actually runs both test scenarios and corrupts run B.
//  Content: TP3ConditionalsContent.puzzle5.
//

import SwiftUI

struct TP3Puzzle5View: View {
    @Bindable var viewModel: TP3BookshelfViewModel

    var body: some View {
        CodePuzzleCardView(puzzle: viewModel.puzzle5,
                           step: 5,
                           completed: viewModel.completed,
                           onNext: viewModel.goToNext,
                           onClose: viewModel.close)
    }
}

#Preview("TP3 · Puzzle 5", traits: .fixedLayout(width: 874, height: 402)) {
    ZStack {
        Image("background_light").resizable().interpolation(.none).scaledToFill().ignoresSafeArea()
        GameCardOverlay {
            TP3Puzzle5View(viewModel: TP3BookshelfViewModel(startAt: .puzzle5))
        }
    }
}
