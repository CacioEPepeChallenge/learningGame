//
//  TP3BookshelfView.swift
//  learning_game
//
//  Coordinator for Touchpoint 3 (Conditionals — the bookshelf & data port).
//  Lesson → Puzzle 1 → 2 → 3 → 4 → 5. Same contract as TP4LaptopView.
//
//  Usage from the game (ContentView):
//      if game.overlayRoom == .scene4 {
//          TP3BookshelfView(onClose: game.closeOverlay, onComplete: game.completeOverlay)
//      }
//

import SwiftUI

struct TP3BookshelfView: View {
    @State var viewModel: TP3BookshelfViewModel

    init(viewModel: TP3BookshelfViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    init(onClose: @escaping () -> Void, onComplete: @escaping () -> Void) {
        let vm = TP3BookshelfViewModel()
        vm.onClose = onClose
        vm.onComplete = onComplete
        _viewModel = State(initialValue: vm)
    }

    var body: some View {
        if let screen = viewModel.currentScreen {
            GameCardOverlay {
                switch screen {
                case .lesson:
                    LessonCardView(content: TP3Content.lesson, onNext: viewModel.goToNext, onClose: viewModel.close)
                case .puzzle1: TP3Puzzle1View(viewModel: viewModel)
                case .puzzle2: TP3Puzzle2View(viewModel: viewModel)
                case .puzzle3: TP3Puzzle3View(viewModel: viewModel)
                case .puzzle4: TP3Puzzle4View(viewModel: viewModel)
                case .puzzle5: TP3Puzzle5View(viewModel: viewModel)
                }
            }
            .environment(\.gameBackAction, viewModel.canGoBack ? { viewModel.goBack() } : nil)
            .id(screen)
            .transition(.opacity)
            .overlay(alignment: .topTrailing) {
                DebugAutocompleteButton(action: { viewModel.onComplete?() })
            }
        }
    }
}

#Preview("TP3 flow", traits: .fixedLayout(width: 874, height: 402)) {
    ZStack {
        Image("background_light").resizable().interpolation(.none).scaledToFill().ignoresSafeArea()
        TP3BookshelfView(viewModel: TP3BookshelfViewModel())
    }
}
