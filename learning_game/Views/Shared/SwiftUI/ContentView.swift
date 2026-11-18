//
//  ContentView.swift
//  learning_game
//
//  Created by Rudi Butarbutar on 10/11/26.
//

import SwiftUI
import SpriteKit
import GameController



struct ContentView: View {
    @State private var game = GameModel()

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            SpriteView(scene: game.currentScene,
                       transition: .fade(withDuration: 0.5),
                       debugOptions: [.showsFPS, .showsNodeCount])
            .ignoresSafeArea()
            .onAppear{ game.playIntro() }

            if game.currentRoom != nil {
                Button("Back") { game.currentRoom = nil }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            
            if game.overlayRoom == .scene2 {
                TP1GeneratorRootView(
                    onClose: game.closeOverlay,
                    onComplete: game.completeOverlay
                )
                .transition(.opacity)
            }
            
            if game.overlayRoom == .scene3 {
                TP2LightsRootView(
                    onClose: game.closeOverlay,
                    onComplete: game.completeOverlay
                )
                .transition(.opacity)
            }

            
            if game.isDialogActive {
                DialogBox(line: game.dialogLines[game.dialogIndex],
                          isLast: game.dialogIndex == game.dialogLines.count - 1,
                          onNext: game.nextLine)
            }
            

            
            if let id = game.activeTouchpoint,
               let prompt = game.touchpointPrompts[id] {
                TouchpointPrompt(
                    line: DialogLine(speaker: "IRIS", text: prompt.text),
                    onConfirm: { game.confirmTouchpoint() },
                    onCancel: { game.cancelTouchpoint() }
                )
            }
        }
    }
}


#Preview {
    ContentView()
}
