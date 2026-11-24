//
//  TP4Puzzle1View.swift
//  learning_game
//
//  Touchpoint 4 — Puzzle 1 · "TRUE OR FALSE" (Predict: loop fundamentals).
//  A for-in loop runs the same block once for every item in a collection,
//  without writing it again and again → True.
//

import SwiftUI

struct TP4Puzzle1View: View {
    @Bindable var viewModel: TP4LaptopViewModel

    var body: some View {
        TrueFalseCardView(quiz: viewModel.puzzle1,
                          step: 1,
                          completed: viewModel.completed,
                          onNext: viewModel.goToNext,
                          onClose: viewModel.close)
    }
}

#Preview("TP4 · Puzzle 1", traits: .fixedLayout(width: 874, height: 402)) {
    ZStack {
        Image("background_light").resizable().interpolation(.none).scaledToFill()
        GameCardOverlay {
            TP4Puzzle1View(viewModel: TP4LaptopViewModel(startAt: .puzzle1))
        }
    }
}
