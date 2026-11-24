//
//  TP5PaintingRootView.swift
//  learning_game
//
//  Entry point for Touchpoint 5 (Functions — the painting safe). The game
//  layer shows this on top of the room; it displays whichever card the
//  ViewModel says is current. Same contract as TP1GeneratorRootView.
//
//  Usage from the game (ContentView):
//      if game.overlayRoom == .scene5 {
//          TP5PaintingRootView(onClose: game.closeOverlay,
//                              onComplete: game.completeOverlay)
//      }
//

import SwiftUI

struct TP5PaintingRootView: View {
    @State var viewModel: TP5PaintingViewModel

    init(viewModel: TP5PaintingViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    /// Convenience for the game layer: a fresh Touchpoint 5 run with callbacks.
    init(paintingRevealed: Bool = false, onClose: @escaping () -> Void, onComplete: @escaping () -> Void) {
        let vm = TP5PaintingViewModel(paintingRevealed: paintingRevealed)
        vm.onClose = onClose
        vm.onComplete = onComplete
        _viewModel = State(initialValue: vm)
    }

    var body: some View {
        if let screen = viewModel.currentScreen {
            GameCardOverlay {
                switch screen {
                case .intro:
                    TP5IntroView(viewModel: viewModel)
                case .lesson1, .lesson2, .lesson3, .lesson4, .lesson5:
                    if let lesson = viewModel.lesson(for: screen), let n = screen.lockNumber {
                        TP5LessonView(lesson: lesson, number: n, opened: viewModel.openedLocks,
                                      onNext: viewModel.goToNext, onClose: viewModel.close)
                    }
                case .defineCall:
                    TP5Lock1DefineCallView(viewModel: viewModel)
                case .traceCalls:
                    TP5Lock2TraceCallsView(viewModel: viewModel)
                case .arguments:
                    TP5Lock3ArgumentsView(viewModel: viewModel)
                case .returnValues:
                    TP5Lock4ReturnValuesView(viewModel: viewModel)
                case .reuse:
                    TP5Lock5ReuseView(viewModel: viewModel)
                case .safeOpen:
                    TP5SafeOpenView(viewModel: viewModel)
                }
            }
            // Every card except the first gets a "‹ Back" button (see GameCardChrome).
            .environment(\.gameBackAction, viewModel.canGoBack ? { viewModel.goBack() } : nil)
            .id(screen)
            .transition(.opacity)
            .overlay(alignment: .topTrailing) {
                DebugAutocompleteButton(action: { viewModel.onComplete?() })
            }
        }
    }
}

#Preview("TP5 flow", traits: .fixedLayout(width: 874, height: 402)) {
    ZStack {
        Image("background_dimmed")
            .resizable()
            .interpolation(.none)
            .scaledToFill()
        TP5PaintingRootView(viewModel: TP5PaintingViewModel())
    }
}

#Preview("TP5 · Lock 3", traits: .fixedLayout(width: 874, height: 402)) {
    ZStack {
        GameColor.midnight
        TP5PaintingRootView(viewModel: TP5PaintingViewModel(startAt: .arguments))
    }
}
