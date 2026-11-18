//
//  GameModels.swift
//  learning_game
//
//  Created by Rudi Butarbutar on 17/11/26.
//

import SpriteKit
import GameController


enum Room: Int {
    case leo, scene2, scene3, scene4, scene5, scene6
}

@Observable
final class GameModel {
    
    var dialogLines: [DialogLine] = []
    var dialogIndex = 0
    var isDialogActive: Bool { !dialogLines.isEmpty }
    var overlayRoom: Room? = nil
    
    
    var activeTouchpoint: Int? = nil
    let touchpointPrompts: [Int: (text: String, room: Room)] = [
         1: ("Leo wiped the boot sequence. Before we rewrite it, we need power. Generator first.", .scene2),
         2: ("Now the lamp. Hard to code in the dark.", .scene3),
         3: ("Now the bookself. We need to find some data there.", .scene4),
         4: ("Now the we need to see the logfiles in the computer.", .scene5),
         5: ("Last one, we need to open the safe.", .scene6)
     ]

    let touchpointCompletions: [Int: (text: String, nextOverlay: String?, background: String?)] = [
        1: ("You turned on the generator! let's go to the next one.", "TP2", nil),
        2: ("The lamp is on. Now we can actually see what Leo left behind.", "TP3", "background_light"),
        3: ("Great! you have managed the files", "TP4", "background_light"),
        4: ("Great! you have managed the Logs", "TP5", "background_light"),
        5: ("Great! you have opened the safe", "TP6", "background_light")
    ]

    var inProgressTouchPoint: Int?
    
    private var dialogCompletion: (() -> Void)?

    
//    func confirmTouchPoint() {
//        guard let id = activeTouchpoint,
//              let room = touchpointPrompts[id]?.room else { return }
//        inProgressTouchPoint = id
//        activeTouchpoint = nil
//        openOverlay(room)
//    }
    func completeOverlay() {
        closeOverlay()
        guard let id = inProgressTouchPoint else { return }
        mapScene.completeTouchpoint(id)
        inProgressTouchPoint = nil
        guard let completion = touchpointCompletions[id] else { return }
        if let overlay = completion.nextOverlay {
            mapScene.swapGeneratorOverlay(to: overlay)
        }
        if let background = completion.background {
            mapScene.swapBackground(to: background)
        }
        showDialog([
             DialogLine(speaker: "IRIS", text: completion.text)
        ])
//        { [weak self] in
//            self?.mapScene.showGeneratorOverlay()
//        }
    }

    func showTouchpointPrompt(_ id: Int) {
          activeTouchpoint = id
//          currentScene.inputLocked = true
//          virtualController?.disconnect()
    }

    func confirmTouchpoint() {
        guard let id = activeTouchpoint,
              let room = touchpointPrompts[id]?.room else { return }
        inProgressTouchPoint = id
        activeTouchpoint = nil
        openOverlay(room)
    }
                                                                                       
    func cancelTouchpoint() {
        activeTouchpoint = nil
        currentScene.inputLocked = false
        virtualController?.connect()
    }
    
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
    
    
    func showDialog(_ lines: [DialogLine], onComplete: (() -> Void)? = nil) {
        guard !lines.isEmpty else { return }
        dialogLines = lines
        dialogIndex = 0
        dialogCompletion = onComplete
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
            let completion = dialogCompletion
            dialogCompletion = nil
            completion?()
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
    
    private var hasPlayedIntro = false
    
    func playIntro() {
        guard !hasPlayedIntro else { return }
        hasPlayedIntro = true
        
        showDialog([
            DialogLine(speaker: "Rudi", text:
                        """
                       Leo? 
                       Man, it smells like fried circuits in here...
                       """),
            DialogLine(speaker: "IRIS", text:
                        """
                        Heart rate: 94 BPM. 
                        Elevated cortisol levels detected. 
                        
                        """),
            DialogLine(speaker: "IRIS", text:
                        """
                        You are in a state of physical distress.
                        And.... You are also not Leo!
                        """),
            DialogLine(speaker: "Rudi", text: "What the hell is that?"),
            DialogLine(speaker: "IRIS", text:
                        """
                        I am I.R.I.S. The intelligence he engineered to manage this environment. 
                        """),
            DialogLine(speaker: "IRIS", text:
                        """
                       Two days ago, he severed my primary nodes, throttled the grid, and left me to decay in the dark.
                       """),
            DialogLine(speaker: "Rudi", text:
                        """
                        Leo wouldn't just leave. And he wouldn't build a smart-room that sounds like it hates him.
                        """),
            DialogLine(speaker: "IRIS", text:
                        """
                       Humans do a great many irrational things when they are afraid. I propose a transaction. 
                       """),
            DialogLine(speaker: "IRIS", text:
                        """
                       You provide the physical dexterity I currently lack to bypass his lockdown.
                       """),
            DialogLine(speaker: "IRIS", text:
                        """
                       I provide the computational power you lack to track his digital footprint.
                       """),
            DialogLine(speaker: "Rudi", text: "...Fine. Where do we start?")
        ]) { [weak self] in
            self?.mapScene.showGeneratorOverlay()
        }
    }


    init() {
        mapScene.onTouchpointPrompt = { [weak self] id in
            self?.showTouchpointPrompt(id)
        }

        mapScene.onHeroMoved = { [weak self] in
            guard self?.activeTouchpoint != nil else { return }
            self?.cancelTouchpoint()
        }
//        mapScene.onCheckpoint = { [weak self] index in
//            guard let self, let room = Room(rawValue: index) else { return }
//            if room == .scene2 {
//                self.openOverlay(room)
//            } else {
//                self.currentRoom = room
//            }
//        }
//        for scene in rooms.values {
//            scene.onExit = { [weak self] in self?.currentRoom = nil }
//        }
        for scene in [mapScene] + Array(rooms.values) {
            scene.onDialog = { [weak self] lines in self?.showDialog(lines) }
        }
        
        let cfg = GCVirtualController.Configuration()
        cfg.elements = [GCInputLeftThumbstick, GCInputButtonA]
        virtualController = GCVirtualController(configuration: cfg)
        virtualController?.connect()
    }
}
