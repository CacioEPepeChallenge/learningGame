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

            if game.currentRoom != nil {
                Button("Back") { game.currentRoom = nil }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            
            if game.overlayRoom == .scene2 {
                Scene2Panel(onClose: game.closeOverlay)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
            
            if game.isDialogActive {
                DialogBox(line: game.dialogLines[game.dialogIndex],
                          isLast: game.dialogIndex == game.dialogLines.count - 1,
                          onNext: game.nextLine)
            }
        }
    }
}


#Preview {
    ContentView()
}
