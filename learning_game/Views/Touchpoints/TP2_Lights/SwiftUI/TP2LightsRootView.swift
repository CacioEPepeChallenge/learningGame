//
//  TP2LightsRootView.swift
//  learning_game
//
//  Entry point for Touchpoint 2's cards (Arrays & Enums). The game layer
//  shows this on top of the room; it displays whichever card the ViewModel
//  says is current.
//
//  Usage from the game (ContentView):
//      if game.overlayRoom == .scene3 {
//          TP2LightsRootView(onClose: game.closeOverlay,
//                            onComplete: game.completeOverlay)
//      }
//

import SwiftUI

struct TP2LightsRootView: View {
    @State var viewModel: TP2LightsViewModel

    init(viewModel: TP2LightsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    /// Convenience for the game layer: a fresh Touchpoint 2 run with callbacks.
    init(onClose: @escaping () -> Void, onComplete: @escaping () -> Void) {
        let vm = TP2LightsViewModel()
        vm.onClose = onClose
        vm.onComplete = onComplete
        _viewModel = State(initialValue: vm)
    }

    var body: some View {
        if let screen = viewModel.currentScreen {
            Group {
                switch screen {
                case .dialogue:
                    // Dialogue bar over the room — not a card.
                    TP2Screen02_DialogueView(viewModel: viewModel)
                case .lightingSchematic:
                    GameCardOverlay { TP2Screen03_LightingSchematicView(viewModel: viewModel) }
                case .switchLights:
                    GameCardOverlay { TP2Screen04_SwitchLightsView(viewModel: viewModel) }
                case .reconstruct:
                    GameCardOverlay { TP2Screen05_ReconstructView(viewModel: viewModel) }
                case .readArray:
                    GameCardOverlay { TP2Screen06_ReadArrayView(viewModel: viewModel) }
                case .trueOrFalse:
                    GameCardOverlay { TP2Screen07_TrueOrFalseView(viewModel: viewModel) }
                case .appendCount:
                    GameCardOverlay { TP2Screen08_AppendCountView(viewModel: viewModel) }
                case .fixCode:
                    GameCardOverlay { TP2Screen09_FixCodeView(viewModel: viewModel) }
                case .lightsRestored:
                    GameCardOverlay { TP2Screen10_LightsRestoredView(viewModel: viewModel) }
                }
            }
            // Every card after the dialogue gets a "‹ Back" button (see GameCardChrome).
            .environment(\.gameBackAction, viewModel.canGoBack ? { viewModel.goBack() } : nil)
            .id(screen)
            .transition(.opacity)
            .overlay(alignment: .topTrailing) {
                DebugAutocompleteButton(action: { viewModel.onComplete?() })
            }
        }
    }
}

#Preview("TP2 flow", traits: .fixedLayout(width: 874, height: 402)) {
    ZStack {
        Image("background_dimmed")
            .resizable()
            .interpolation(.none)
            .scaledToFill()
        TP2LightsRootView(viewModel: TP2LightsViewModel())
    }
}
