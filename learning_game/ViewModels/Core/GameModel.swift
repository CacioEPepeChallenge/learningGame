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
    var playerName: String = "Anonymous"
    var showNameEntry: Bool = true
    var showStartScene: Bool = true
    var showPaintingReveal: Bool = false
    var showSafeReveal: Bool = false
    var showEndingScene: Bool = false
    var showBlackScreen: Bool = false
    /// TP4's decrypted final-log readout (TP4TranscriptView).
    var showTranscript: Bool = false
    
    
    var activeTouchpoint: Int? = nil
    let touchpointPrompts: [Int: (text: String, room: Room)] = [
         1: ("Leo wiped the boot sequence. Before we rewrite it, we need power. Generator first.", .scene2),
         2: ("Now the lamp. Hard to code in the dark.", .scene3),
         3: ("Now the bookshelf. We need to find some data there.", .scene4),
         4: ("Leo's workstation. His video logs are still on the drive, every one of them encrypted.", .scene5),
         5: ("The painting on the East Wall. The sensors say Leo tore it down that night.", .scene6)
     ]

    let touchpointCompletions: [Int: (text: String, nextOverlay: String?, background: String?)] = [
        1: ("You turned on the generator! let's go to the next one.", "TP2", nil),
        2: ("The lamp is on. Now we can actually see what Leo left behind.", "TP3", "background_light"),
        3: ("Great! you have managed the files", "TP4", "background_light"),
        4: ("Great! you have managed the Logs", "TP5", "background_light"),
        5: ("Great! you have opened the safe", "TP6", "background_light")
    ]

    var inProgressTouchPoint: Int?

    // MARK: Scripts between touchpoints

    /// TP3 → TP4: the files lead to Leo's PC.
    private var bookshelfToLaptop: [DialogLine] { [
        DialogLine(speaker: "IRIS", text: "Data port online. Leo moved his files from the shelf drive to his PC before he disappeared."),
        DialogLine(speaker: playerName, text: "So whatever happened to him is on that computer."),
        DialogLine(speaker: "IRIS", text: "Logically, yes. His workstation is on the desk. I have marked it for you."),
    ] }

    /// Arriving at the PC (after LET'S GO).
    private var laptopArrival: [DialogLine] { [
        DialogLine(speaker: playerName, text: "Okay, the files are here. But there are still hundreds of encrypted video logs."),
        DialogLine(speaker: playerName, text: "How do I know which one is the last one he recorded?"),
        DialogLine(speaker: "IRIS", text: "We do not have time to manually decrypt them one by one."),
        DialogLine(speaker: "IRIS", text: "We will use a Loop to shatter the encryption on all of them simultaneously."),
    ] }

    /// TP4 → TP5: after the transcript, the sensor log points at the painting.
    private var laptopToPainting: [DialogLine] { [
        DialogLine(speaker: playerName, text: "...Strange, why did the audio cut off, and what was he hiding that was so important..."),
        DialogLine(speaker: "IRIS", text: "The sensor data is clear. Before he fled, he went to the East Wall."),
        DialogLine(speaker: playerName, text: "The painting... Leo never hangs anything crooked."),
        DialogLine(speaker: "IRIS", text: "Then we look behind it. I have marked the painting for you."),
    ] }

    /// TP5 solved, right before the safe opens (SafeRevealView continues the scene).
    private var safeUnlocked: [DialogLine] { [
        DialogLine(speaker: "IRIS", text: "All five deadbolts disengaged."),
        DialogLine(speaker: playerName, text: "Whatever Leo was hiding... it's in there."),
    ] }

    /// The painting-reveal animation has played (so re-entering TP5 skips it).
    private var paintingRevealed = false
    
    var completedTouchpoints: Set<Int> = []

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
        let isReplay = completedTouchpoints.contains(id)
        completedTouchpoints.insert(id)
        inProgressTouchPoint = nil
        guard let completion = touchpointCompletions[id] else { return }

        // Replaying an old touchpoint must not roll the map back to an earlier overlay/background
        if isReplay {
            showDialog([DialogLine(speaker: "IRIS", text: completion.text)])
            return
        }

        if id == 4 {
            // Laptop decrypted: screen flips, decrypt chirp, then the readout.
            mapScene.setMonitor(.decrypted)
            RetroSFX.shared.playDecrypt()
            showDialog([
                DialogLine(speaker: "IRIS", text: "Playing audio transcript and room sensor data for the final log. Video feed is unavailable.")
            ]) { [weak self] in
                guard let self else { return }
                self.showTranscript = true
                self.mapScene.inputLocked = true
                self.virtualController?.disconnect()
            }
            return
        }

        if id == 5 {
            pendingCompletion = completion
            showDialog(safeUnlocked) { [weak self] in
                guard let self else { return }
                self.showSafeReveal = true
                self.currentScene.inputLocked = true
                self.virtualController?.disconnect()
            }
            return
        }

        applyCompletion(completion, lines: id == 3 ? bookshelfToLaptop : nil)
    }

    private var pendingCompletion: (text: String, nextOverlay: String?, background: String?)?

    /// The painting-reveal animation plays when the player reaches the glowing
    /// painting; when it ends, the uncovered safe glows and Touchpoint 5 opens.
    func finishPaintingReveal() {
        showPaintingReveal = false
        paintingRevealed = true
        mapScene.swapGeneratorOverlay(to: "TP5")      // painting pulled aside, safe glowing
        openOverlay(.scene6)
    }

    /// The player closed TP4's transcript: the PC stops glowing, the painting
    /// starts, and I.R.I.S. points the player to the East Wall.
    func finishTranscript() {
        showTranscript = false
        mapScene.inputLocked = false
        connectController()
        mapScene.swapGeneratorOverlay(to: "TP6")      // no overlay glow
        mapScene.showPaintingGlow()
        showDialog(laptopToPainting)
    }

    func finishSafeReveal() {
        showSafeReveal = false
        if let completion = pendingCompletion {
            if let overlay = completion.nextOverlay {
                mapScene.swapGeneratorOverlay(to: overlay)
            }
            if let background = completion.background {
                mapScene.swapBackground(to: background)
            }
            pendingCompletion = nil
        }
        showEndingScene = true
    }

    func finishEndingScene() {
        showEndingScene = false
        showBlackScreen = true
    }

    func finishStartScene() {
        showStartScene = false
        playIntro()
    }

    func finishNameEntry(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        playerName = trimmed.isEmpty ? "Anonymous" : trimmed
        showNameEntry = false
    }

    private func applyCompletion(_ completion: (text: String, nextOverlay: String?, background: String?),
                                 lines: [DialogLine]? = nil) {
        if mapScene.activeTouchpointID == 4 { mapScene.setMonitor(.locked) }
        if let overlay = completion.nextOverlay {
            mapScene.swapGeneratorOverlay(to: overlay)
        }
        if let background = completion.background {
            mapScene.swapBackground(to: background)
        }
        showDialog(lines ?? [DialogLine(speaker: "IRIS", text: completion.text)])
    }

    func showTouchpointPrompt(_ id: Int) {
          activeTouchpoint = id
//          currentScene.inputLocked = true
//          virtualController?.disconnect()
    }

    func confirmTouchpoint() {
        guard let id = activeTouchpoint else { return }
        launchTouchpoint(id)
    }

    /// Opens a touchpoint's puzzle flow (from the prompt, or straight away when
    /// the player tapped the glowing object and the MC walked there).
    func launchTouchpoint(_ id: Int) {
        guard let room = touchpointPrompts[id]?.room else { return }
        activeTouchpoint = nil
        inProgressTouchPoint = id
        switch id {
        case 4:
            showDialog(laptopArrival) { [weak self] in
                self?.openOverlay(room)
            }
        case 5:
            mapScene.hideObjectGlow()
            if paintingRevealed {
                openOverlay(room)
            } else {
                showPaintingReveal = true
                mapScene.inputLocked = true
                virtualController?.disconnect()
            }
        default:
            openOverlay(room)
        }
    }

    /// Puts the room in the state the player would have reached right before
    /// touchpoint `id` (earlier ones finished, lights on, the right object
    /// glowing, the MC beside the previous object) and plays the hand-off lines.
    /// Used by DevStart to test one touchpoint without replaying the game.
    func jumpToTouchpoint(_ id: Int) {
        let target = min(max(id, 2), 5)
        let scene = mapScene
        scene.showGeneratorOverlay()
        for done in 1..<target { scene.completeTouchpoint(done) }
        if target >= 3 { scene.swapBackground(to: "background_light") }
        if let previousArea = [1: Tile(col: 24, row: 1), 2: Tile(col: 13, row: 4),
                               3: Tile(col: 15, row: 4), 4: Tile(col: 8, row: 4)][target - 1] {
            scene.placeHero(at: previousArea)
        }

        switch target {
        case 4:
            scene.swapGeneratorOverlay(to: "TP4")       // PC glowing
            scene.setMonitor(.locked)
            showDialog(bookshelfToLaptop)
        case 5:
            scene.setMonitor(.decrypted)
            scene.swapGeneratorOverlay(to: "TP6")       // no overlay glow
            scene.showPaintingGlow()
            showDialog(laptopToPainting)
        default:
            scene.swapGeneratorOverlay(to: "TP\(target)")
            if let text = touchpointCompletions[target - 1]?.text {
                showDialog([DialogLine(speaker: "IRIS", text: text)])
            }
        }
    }

    func cancelTouchpoint() {
        activeTouchpoint = nil
        currentScene.inputLocked = false
        connectController()
    }
    
    func openOverlay(_ room: Room) {
        overlayRoom = room
        mapScene.inputLocked = true
        virtualController?.disconnect()
    }
    
    func closeOverlay() {
        overlayRoom = nil
        mapScene.inputLocked = false
        connectController()
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
            connectController()
            let completion = dialogCompletion
            dialogCompletion = nil
            completion?()
        }
    }
    
    var virtualController: GCVirtualController?
    var onInteract: (() -> Void)?

    /// Connects this model's own joystick and binds A on that controller only.
    /// (A global GCControllerDidConnect observer let an old GameModel grab
    /// the A button after "Start Again".)
    func connectController() {
        virtualController?.connect { [weak self] _ in
            DispatchQueue.main.async {
                self?.virtualController?.controller?.extendedGamepad?.buttonA.pressedChangedHandler = { [weak self] _, _, pressed in
                    guard pressed else { return }
                    self?.handleButtonA()
                }
            }
        }
    }

    /// Call before replacing this model so its joystick doesn't linger on screen
    /// or stay as GCController.current, which GameScene reads for movement.
    func tearDown() {
        virtualController?.disconnect()
        virtualController = nil
    }

    // A button presses the touchpoint prompt's button ("LET'S GO" / "LET'S TRY AGAIN")
    private func handleButtonA() {
        guard activeTouchpoint != nil else { return }
        confirmTouchpoint()
    }
    
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
            DialogLine(speaker: playerName, text:
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
            DialogLine(speaker: playerName, text: "What the hell is that?"),
            DialogLine(speaker: "IRIS", text:
                        """
                        I am I.R.I.S. The intelligence he engineered to manage this environment. 
                        """),
            DialogLine(speaker: "IRIS", text:
                        """
                       Two days ago, he severed my primary nodes, throttled the grid, and left me to decay in the dark.
                       """),
            DialogLine(speaker: playerName, text:
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
            DialogLine(speaker: playerName, text: "...Fine. Where do we start?")
        ]) { [weak self] in
            self?.mapScene.showGeneratorOverlay()
        }
    }


    init() {
        mapScene.onTouchpointPrompt = { [weak self] id in
            self?.showTouchpointPrompt(id)
        }

        // Walking up to the glowing object (tap or joystick) shows the I.R.I.S.
        // prompt bubble; LET'S GO launches the touchpoint.
        mapScene.onTouchpointArrived = { [weak self] id in
            self?.showTouchpointPrompt(id)
        }

        mapScene.onHeroMoved = { [weak self] in
            guard self?.activeTouchpoint != nil else { return }
            self?.cancelTouchpoint()
        }

        // Joystick A button: at a glowing object, A opens its prompt; with the
        // prompt showing, A is LET'S GO.
        mapScene.onInteract = { [weak self] in
            guard let self, !self.isDialogActive, self.overlayRoom == nil,
                  !self.mapScene.inputLocked else { return }
            if self.activeTouchpoint != nil {
                self.confirmTouchpoint()
            } else if let id = self.mapScene.touchpointUnderHero {
                self.showTouchpointPrompt(id)
            }
        }

        // Developer shortcut (App/DevStart.swift): skip straight to a touchpoint.
        if let start = DevStart.touchpoint {
            showNameEntry = false
            showStartScene = false
            hasPlayedIntro = true
            mapScene.onReady = { [weak self] in
                DispatchQueue.main.async { self?.jumpToTouchpoint(start) }
            }
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
        // Joystick stays disconnected until startSceneView finishes.
        // finishStartScene() → playIntro() → showDialog → nextLine calls connectController().
    }
}
