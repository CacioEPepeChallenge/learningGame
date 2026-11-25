//
//  TP3Puzzle1View.swift
//  learning_game
//
//  Touchpoint 3 — Puzzle 1.
//  True or False: an if runs its block only when the condition is true.
//  Content: TP3ConditionalsContent.puzzle1.
//

import SwiftUI

struct TP3Puzzle1View: View {
    @Bindable var viewModel: TP3BookshelfViewModel

    var body: some View {
        TrueFalseCardView(quiz: viewModel.puzzle1,
                          step: 1,
                          completed: viewModel.completed,
                          onNext: viewModel.goToNext,
                          onClose: viewModel.close)
    }
}

#Preview("TP3 · Puzzle 1", traits: .fixedLayout(width: 874, height: 402)) {
    ZStack {
        Image("background_light").resizable().interpolation(.none).scaledToFill().ignoresSafeArea()
        GameCardOverlay {
            TP3Puzzle1View(viewModel: TP3BookshelfViewModel(startAt: .puzzle1))
        }
    }
}
