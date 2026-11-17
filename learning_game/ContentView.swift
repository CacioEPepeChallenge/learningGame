//
//  ContentView.swift
//  learning_game
//
//  Created by Rudi Butarbutar on 10/11/26.
//

import SwiftUI
import SpriteKit
import GameController

enum Room: Int {
    case leo, scene2, scene3, scene4, scene5
}

@Observable
final class GameModel {
    
    var dialogLines: [DialogLine] = []
    var dialogIndex = 0
    var isDialogActive: Bool { !dialogLines.isEmpty }
    var overlayRoom: Room? = nil
    
    func openOverlay(_ room: Room) {
        overlayRoom = room
        mapScene.inputLocked = true
        virtualController?.disconnect()
    }
    
    func closeOverlay() {
        overlayRoom = nil
        mapScene.inputLocked = false
        virtualController?.connect()
    }
    
    func showDialog(_ lines: [DialogLine]) {
        guard !lines.isEmpty else { return }
        dialogLines = lines
        dialogIndex = 0
        currentScene.inputLocked = true
        virtualController?.disconnect()
    }
    
    func nextLine() {
        if dialogIndex < dialogLines.count - 1 {
            dialogIndex += 1
        } else {
            dialogLines = []
            ([mapScene] + Array(rooms.values)).forEach { $0.inputLocked = false }
            virtualController?.connect()
        }
    }
    
    var virtualController: GCVirtualController?
    var onInteract: (() -> Void)?
    
    static let sceneSize = CGSize(width: 390, height: 844)

    let mapScene = GameScene(size: sceneSize)
    let rooms: [Room: GameScene] = [
        .leo: LeoRoomScene(size: sceneSize),
        .scene2: Scene2(size: sceneSize),
        .scene3: Scene3(size: sceneSize),
        .scene4: Scene4(size: sceneSize),
        .scene5: Scene5(size: sceneSize)
    ]
    var currentRoom: Room? = nil

    var currentScene: GameScene {
        currentRoom.flatMap { rooms[$0] } ?? mapScene
    }

    init() {
        mapScene.onCheckpoint = { [weak self] index in
            guard let self, let room = Room(rawValue: index) else { return }
            if room == .scene2 {
                self.openOverlay(room)
            } else {
                self.currentRoom = room
            }
        }
        for scene in rooms.values {
            scene.onExit = { [weak self] in self?.currentRoom = nil }
        }
        for scene in [mapScene] + Array(rooms.values) {
            scene.onDialog = { [weak self] lines in self?.showDialog(lines) }
        }
        
        let cfg = GCVirtualController.Configuration()
        cfg.elements = [GCInputLeftThumbstick, GCInputButtonA]
        virtualController = GCVirtualController(configuration: cfg)
        virtualController?.connect()
    }
}

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

struct DialogBox: View {
    let line: DialogLine
    let isLast: Bool
    let onNext: () -> Void
    var body: some View {
        GeometryReader { geo in
            VStack {
                Spacer()
                HStack {
                    Text(line.speaker)
                        .font(.system(.headline, design: .monospaced))
                        .foregroundStyle(.yellow)
                    Text(line.text)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.white)
                    Spacer()
                    HStack {
                        Spacer()
                        Button(isLast ? "Close" : "Next", action: onNext)
                            .font(.system(.subheadline, design: .monospaced).bold())
                            .foregroundStyle(.black)
                            .padding(.horizontal, 14).padding(.vertical, 6)
                            .background(.white)
                    }
                }
                .padding()
                .frame(width: geo.size.width - 24, height: geo.size.height * 0.25)
                .background(.black.opacity(0.85))
            }
        }
    }
}

#Preview {
    ContentView()
}

#Preview("Interactive") {
    @Previewable @State var index = 0
    let lines = [
        DialogLine(speaker: "IRIS", text: "This is Leo's room. Something feels off..."),
        DialogLine(speaker: "IRIS", text: "Let's look for clues."),
        DialogLine(speaker: "You", text: "Leo, where did you go?")
    ]

    ZStack {
        Color.green.ignoresSafeArea()
        if index < lines.count {
            DialogBox(line: lines[index],
                      isLast: index == lines.count - 1,
                      onNext: { index += 1 })
        } else {
            Button("Restart") { index = 0 }
        }
    }
}
