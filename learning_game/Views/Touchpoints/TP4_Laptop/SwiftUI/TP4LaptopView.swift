//
//  TP4LaptopView.swift
//  learning_game
//
//  Coordinator for Touchpoint 4 (Loops — the laptop). Shows whichever card the
//  ViewModel says is current and chains Puzzle 1 → 2 → 3 → 4 → 5, then the
//  DECRYPTING… card. Same contract as TP1GeneratorRootView / TP2LightsRootView.
//
//  Usage from the game (ContentView):
//      if game.overlayRoom == .scene5 {
//          TP4LaptopView(onClose: game.closeOverlay, onComplete: game.completeOverlay)
//      }
//

import SwiftUI

struct TP4LaptopView: View {
    @State var viewModel: TP4LaptopViewModel

    init(viewModel: TP4LaptopViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    init(onClose: @escaping () -> Void, onComplete: @escaping () -> Void) {
        let vm = TP4LaptopViewModel()
        vm.onClose = onClose
        vm.onComplete = onComplete
        _viewModel = State(initialValue: vm)
    }

    var body: some View {
        if let screen = viewModel.currentScreen {
            GameCardOverlay {
                switch screen {
                case .forInLesson:
                    TP4LessonView(content: TP4Content.forInLesson, viewModel: viewModel)
                case .puzzle1:
                    TP4Puzzle1View(viewModel: viewModel)
                case .puzzle2:
                    TP4Puzzle2View(viewModel: viewModel)
                case .puzzle3:
                    TP4Puzzle3View(viewModel: viewModel)
                case .whileLesson:
                    TP4LessonView(content: TP4Content.whileLesson, viewModel: viewModel)
                case .puzzle4:
                    TP4Puzzle4View(viewModel: viewModel)
                case .puzzle5:
                    TP4Puzzle5View(viewModel: viewModel)
                case .decrypting:
                    TP4DecryptingView(viewModel: viewModel)
                }
            }
            // Every card after the first gets a "‹ Back" button (see GameCardChrome).
            .environment(\.gameBackAction, viewModel.canGoBack ? { viewModel.goBack() } : nil)
            .id(screen)
            .transition(.opacity)
            .overlay(alignment: .topTrailing) {
                DebugAutocompleteButton(action: { viewModel.onComplete?() })
            }
        }
    }
}

#Preview("TP4 flow", traits: .fixedLayout(width: 874, height: 402)) {
    ZStack {
        Image("background_light").resizable().interpolation(.none).scaledToFill()
        TP4LaptopView(viewModel: TP4LaptopViewModel())
    }
}
