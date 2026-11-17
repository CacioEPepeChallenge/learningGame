//
//  GameModels.swift
//  learning_game
//
//  Created by Rudi Butarbutar on 17/11/26.
//

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
