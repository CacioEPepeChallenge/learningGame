//
//  TP1GeneratorRootView.swift
//  learning_game
//
//  Entry point for Touchpoint 1's cards. The game layer shows this on top of
//  the room; it displays whichever card the ViewModel says is current.
//
//  Usage from the game (ContentView):
//      if game.overlayRoom == .scene2 {
//          TP1GeneratorRootView(onClose: game.closeOverlay,
//                               onComplete: game.completeOverlay)
//      }
//

import SwiftUI

struct TP1GeneratorRootView: View {
    @State var viewModel: TP1GeneratorViewModel

    init(viewModel: TP1GeneratorViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    /// Convenience for the game layer: a fresh Touchpoint 1 run with callbacks.
    init(onClose: @escaping () -> Void, onComplete: @escaping () -> Void) {
        let vm = TP1GeneratorViewModel()
        vm.onClose = onClose
        vm.onComplete = onComplete
        _viewModel = State(initialValue: vm)
    }

    var body: some View {
        if let screen = viewModel.currentScreen {
            GameCardOverlay {
                ZStack(alignment: .topLeading) {
                switch screen {
                case .generatorCore:
                    TP1Screen03_GeneratorCoreView(content: viewModel.generatorCore,
                                                  onStart: viewModel.goToNext,
                                                  onClose: viewModel.close)
                case .variableOrConstant:
                    TP1Screen04_VariableOrConstantView(viewModel: viewModel)
                case .dataTypes:
                    TP1Screen05_DataTypesView(viewModel: viewModel)
                case .declaringVariable:
                    TP1Screen08_DeclareVariableView(viewModel: viewModel)
                case .declaringConstant:
                    TP1Screen09_DeclareConstantView(viewModel: viewModel)
                case .typeSafety:
                    TP1Screen10_TypeSafetyView(viewModel: viewModel)
                case .chooseAnswer:
                    TP1Screen11_ChooseAnswerView(viewModel: viewModel)
                case .trueOrFalse:
                    TP1Screen12_TrueOrFalseView(viewModel: viewModel)
                case .boolSwitch:
                    TP1Screen13_BoolSwitchView(viewModel: viewModel)
                case .ignition:
                    TP1Screen14_IgnitionView(viewModel: viewModel)
                case .congratulations:
                    TP1Screen15_CongratulationsView(viewModel: viewModel)
                }

                // Every card except the first gets the "‹ Back" pill (Figma iPhone 17 - 10),
                // on the same row as the right-aligned Next pill.
                if viewModel.canGoBack {
                    TP1PillButton(title: "Back", kind: .back) { viewModel.goBack() }
                        .offset(x: TP1Footer.sideInset - 2, y: TP1Footer.buttonTop)
                }
                }
            }
            // TP1 draws its own Back pill above, so the card chrome's text "‹ Back" stays off.
            .environment(\.gameBackAction, nil)
            .id(screen)
            .transition(.opacity)
            .overlay(alignment: .topTrailing) {
                DebugAutocompleteButton(action: { viewModel.onComplete?() })
            }
        }
    }
}

#Preview("TP1 flow", traits: .fixedLayout(width: 874, height: 402)) {
    ZStack {
        Image("background_dimmed")
            .resizable()
            .interpolation(.none)
            .scaledToFill()
        TP1GeneratorRootView(viewModel: TP1GeneratorViewModel())
    }
}
