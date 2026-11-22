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

            if game.overlayRoom == .scene4 {
                Scene4Panel(
                    onClose: game.closeOverlay,
                    onComplete: game.completeOverlay
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            if game.overlayRoom == .scene5 {
                Scene4Panel(
                    onClose: game.closeOverlay,
                    onComplete: game.completeOverlay
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            if game.overlayRoom == .scene6 {
                Scene4Panel(
                    onClose: game.closeOverlay,
                    onComplete: game.completeOverlay
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            
            if game.showPaintingReveal {
                PaintingRevealView(onComplete: { game.finishPaintingReveal() })
                    .transition(.opacity)
            }

            if game.showSafeReveal {
                SafeRevealView(onComplete: { game.finishSafeReveal() },
                               playerName: game.playerName)
                    .transition(.opacity)
            }

            if game.showEndingScene {
                endingSceneView(onComplete: { game.finishEndingScene() })
                    .transition(.opacity)
            }

            if game.showBlackScreen {
                ZStack(alignment: .bottomTrailing) {
                    Color.black
                        .ignoresSafeArea()
                    VStack(alignment: .trailing, spacing: 12) {
                        Text("To be continued →")
                            .font(.system(.title3, design: .monospaced).bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Capsule())
                        Button(action: { game = GameModel() }) {
                            Text("Start Again")
                                .font(.system(.title3, design: .monospaced).bold())
                                .foregroundStyle(.black)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.white)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(24)
                }
                .transition(.opacity)
            }

            if game.showStartScene && !game.showNameEntry {
                startSceneView(onComplete: { game.finishStartScene() },
                               playerName: game.playerName)
                    .transition(.opacity)
            }

            if game.showNameEntry {
                NameEntryView(onSubmit: { game.finishNameEntry($0) })
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
                    onConfirm: { game.confirmTouchpoint() }
                )
            }
        }
    }
}


#Preview {
    ContentView()
}
