//
//  GameScene.swift
//  learning_game
//
//  Created by Rudi Butarbutar on 10/11/26.
//

import SpriteKit
import SwiftUI
import GameController


class GameScene: SKScene {
    var blockedTiles: [Tile] {
        let cols = Int(size.width / tileSize)
        let rows = Int(size.height / tileSize)
        let topHalfStart = rows / 2 - 1
        
        let wallRow = (topHalfStart..<rows).flatMap { row in
            (0..<cols).map { col in Tile(col: col, row: row) }
        }
        
        let rect = (0...4).flatMap { col in
            (2...4).map { row in Tile(col: col, row: row) }
        }
        let rect2 = (25...26).flatMap { col in
            (0...2).map { row in Tile(col: col, row: row) }
        }
        
        return wallRow + rect + rect2
    }
    private let allTouchpointAreas: [Int: [Tile]] = [
        1: [Tile(col: 24, row: 0), Tile(col: 24, row: 1), Tile(col: 24, row: 2)],
        2: [Tile(col: 13, row: 4), Tile(col: 13, row: 3), Tile(col: 12, row: 4)],
        3: [Tile(col: 15, row: 4), Tile(col: 16, row: 4)],
        4: [Tile(col: 7, row: 4), Tile(col: 8, row: 4)],   // beside the desk, so the MC doesn't hide the PC screen
        5: [Tile(col: 25, row: 4), Tile(col: 26, row: 4)]
    ]
    
    var unlockedTouchpoints: Set<Int> = [1]
    
    var touchpointAreas: [Int: [Tile]] {
        allTouchpointAreas.filter { unlockedTouchpoints.contains($0.key) }
    }
    
    var onDialog: (([DialogLine]) -> Void)?
    var inputLocked = false
    private var isBuilt = false
    private let hero = SKSpriteNode(imageNamed: "mc_front")

    private enum Facing { case front, back, left, right }
    private var facing: Facing = .front
    private let tFront = SKTexture(imageNamed: "mc_front")
    private let tFrontWalk = SKTexture(imageNamed: "mc_front_walk")
    private let tBack = SKTexture(imageNamed: "mc_back")
    private let tSideLeft = SKTexture(imageNamed: "mc_side_left")
    private let tSideWalkLeft = SKTexture(imageNamed: "mc_side_walk_left")
    private let touchpoint1 = SKSpriteNode(color: .systemBlue, size: CGSize(width: 32, height: 32))
    var checkpoints: [Tile] { [
        Tile(col: 2, row: 6),
        Tile(col: 9, row: 8),
        Tile(col: 4, row: 13),
        Tile(col: 8, row: 18),
        Tile(col: 3, row: 22),
    ] }
    private var checkpointNodes: [SKSpriteNode] = []
    private var reached: Set<Int> = []
    let tileSize: CGFloat = 32
    var heroTile = Tile(col:18, row:1)
    var floorColors: (SKColor, SKColor) { (.systemGreen, .green) }
    var onCheckpoint: ((Int) -> Void)?
    var onExit: (() -> Void)?
    var exitTile: Tile? { nil }
    var showDebugOverlay = false
    var onTouchpointPrompt: ((Int) -> Void)?
    var onHeroMoved: (() -> Void)?
    /// The MC reached a touchpoint after the player TAPPED its glowing object:
    /// launch the puzzle straight away (no prompt).
    var onTouchpointArrived: ((Int) -> Void)?

    /// The joystick's A button was pressed (edge-triggered).
    var onInteract: (() -> Void)?
    private var aWasPressed = false
    /// Called once, when the room has been built (background + MC on screen).
    var onReady: (() -> Void)?

    /// Touchpoints the player has finished.
    private(set) var completedTouchpoints: Set<Int> = []

    /// The active (glowing, unfinished) touchpoint whose area the MC stands in.
    var touchpointUnderHero: Int? {
        guard let id = activeTouchpointID, touchpointAreas[id]?.contains(heroTile) == true else { return nil }
        return id
    }

    /// Puts the MC on a tile without walking (used when starting mid-game).
    func placeHero(at tile: Tile) {
        hero.removeAllActions()
        heroTile = tile
        hero.position = center(of: tile)
        setFacing(.front, walking: false)
    }
    /// Set when a tap on a glowing object started the walk.
    private var pendingTouchpoint: Int?

    /// The touchpoint whose object is glowing right now.
    var activeTouchpointID: Int? {
        unlockedTouchpoints.subtracting(completedTouchpoints).min()
    }

    /// Where each touchpoint's object sits in the painted room art
    /// (fractions of the 874 × 402 background, origin top-left). Tapping inside
    /// it walks the MC over and opens that touchpoint.
    private let objectRects: [Int: CGRect] = [
        1: CGRect(x: 0.905, y: 0.80, width: 0.095, height: 0.20),   // generator
        2: CGRect(x: 0.460, y: 0.00, width: 0.085, height: 0.26),   // hanging lamp
        3: CGRect(x: 0.515, y: 0.25, width: 0.115, height: 0.39),   // bookshelf
        4: CGRect(x: 0.335, y: 0.25, width: 0.180, height: 0.39),   // desk & PC
        5: CGRect(x: 0.895, y: 0.05, width: 0.095, height: 0.26),   // painting
    ]
    /// The PC monitor's screen in the room art (locked → decrypted for TP4).
    private let monitorScreenRect = CGRect(x: 309.0 / 874, y: 113.0 / 402, width: 63.0 / 874, height: 40.0 / 402)
    private var monitorScreen: SKSpriteNode?

    
    private var generatorOverlay: SKSpriteNode?
    private var backgroundNode: SKSpriteNode?
    func showGeneratorOverlay() {
        guard generatorOverlay == nil else { return }
        let node = SKSpriteNode(imageNamed: "TP1")
        node.position = CGPoint(x: frame.midX, y: frame.midY)
        node.size = frame.size
        node.zPosition = 0
        addChild(node)
        generatorOverlay = node
        
        let pulse = SKAction.sequence([
            .fadeAlpha(to: 0.6, duration: 1.5),
            .fadeAlpha(to: 1.5, duration: 0.8)
        ])
        node.run(.repeatForever(pulse), withKey: "glow")
    }
    
    
    
    
    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
    }
    required init?(coder: NSCoder) {
        fatalError()
    }
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        if showDebugOverlay { buildDebugOverlay() }
        
        
        
        guard !isBuilt else { return }
        isBuilt = true
        
        //        for (index, tile) in checkpoints.enumerated() {
        //            let node = SKSpriteNode(color: .systemBlue, size: CGSize(width: tileSize, height: tileSize))
        //            node.position = center(of: tile)
        //            node.zPosition = 5
        //
        //            let label = SKLabelNode(text: "\(index + 1)")
        //            label.fontName = "Menlo-Bold"
        //            label.fontSize = 16
        //            label.verticalAlignmentMode = .center
        //            node.addChild(label)
        //            addChild(node)
        //            checkpointNodes.append(node)
        //        }
        
        let background = SKSpriteNode(imageNamed: "background_dimmed")
        background.position = CGPoint(x: frame.midX, y: frame.midY)
        background.size = frame.size
        background.zPosition = -1
        addChild(background)
        backgroundNode = background
        
        
        let natural = hero.texture?.size() ?? CGSize(width: 1, height: 1)
        let fit = min(tileSize * 2.5 / natural.width, tileSize * 4.5 / natural.height)
        hero.size = CGSize(width: natural.width * fit, height: natural.height * fit)
        hero.anchorPoint = CGPoint(x: 0.5, y: 0)
        hero.position = center(of: heroTile)
        hero.zPosition = 10
        addChild(hero)
        onReady?()
        
        //        let breathe = SKAction.sequence([
        //            .scaleY(to: 0.9, duration: 0.35),
        //            .scaleY(to: 1.0, duration: 0.35)
        //        ])
        //        hero.run(.repeatForever(breathe), withKey: "idle")
        
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard let pad = (GCController.current ?? GCController.controllers().first)?.extendedGamepad else { return }
        let stick = pad.leftThumbstick
        guard !inputLocked else { aWasPressed = pad.buttonA.isPressed; return }

        // A button: interact with the object the MC is standing at.
        let aPressed = pad.buttonA.isPressed
        if aPressed && !aWasPressed { onInteract?() }
        aWasPressed = aPressed

        let x = stick.xAxis.value
        let y = stick.yAxis.value
        let deadZone: Float = 0.4
        
        // Dominant axis only, so movement stays on the tile grid
        if abs(x) > abs(y), abs(x) > deadZone {
            step(dx: x > 0 ? 1 : -1, dy: 0)
        } else if abs(y) > deadZone {
            step(dx: 0, dy: y > 0 ? 1 : -1)
        }
        
    }
    
    
    // MARK: Tap to walk

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !inputLocked, let point = touches.first?.location(in: self) else { return }
        handleTap(at: point)
    }

    /// Tap on the glowing object → walk to its touchpoint and open it on arrival.
    /// Tap anywhere else → walk to the nearest reachable floor tile.
    func handleTap(at point: CGPoint) {
        if let id = activeTouchpointID,
           let rect = objectRects[id].map(sceneRect(for:)),
           rect.insetBy(dx: -tileSize * 0.5, dy: -tileSize * 0.5).contains(point)
            || (touchpointAreas[id]?.contains(tile(at: point)) ?? false),
           let areaTiles = touchpointAreas[id] {
            pendingTouchpoint = id
            if areaTiles.contains(heroTile) {
                arrived()
                return
            }
            let target = areaTiles.min { distance($0, heroTile) < distance($1, heroTile) }!
            walk(path: path(to: target))
            return
        }
        pendingTouchpoint = nil
        guard let target = nearestWalkable(to: tile(at: point)) else { return }
        walk(path: path(to: target))
    }

    /// Room-art fraction rect (origin top-left) → scene rect (origin bottom-left).
    private func sceneRect(for unit: CGRect) -> CGRect {
        CGRect(x: unit.minX * size.width,
               y: size.height - unit.maxY * size.height,
               width: unit.width * size.width,
               height: unit.height * size.height)
    }

    private func distance(_ a: Tile, _ b: Tile) -> Int { abs(a.col - b.col) + abs(a.row - b.row) }

    private var gridSize: (cols: Int, rows: Int) { (Int(size.width / tileSize), Int(size.height / tileSize)) }

    private func isWalkable(_ t: Tile) -> Bool {
        let g = gridSize
        guard (0..<g.cols).contains(t.col), (0..<g.rows).contains(t.row) else { return false }
        if case .blocked = kind(of: t) { return false }
        return true
    }

    private func nearestWalkable(to target: Tile) -> Tile? {
        let g = gridSize
        let clamped = Tile(col: min(max(target.col, 0), g.cols - 1), row: min(max(target.row, 0), g.rows - 1))
        if isWalkable(clamped) { return clamped }
        var best: Tile?
        for row in 0..<g.rows {
            for col in 0..<g.cols {
                let t = Tile(col: col, row: row)
                guard isWalkable(t) else { continue }
                if best == nil || distance(t, clamped) < distance(best!, clamped) { best = t }
            }
        }
        return best
    }

    /// Breadth-first path over walkable tiles (4 directions), excluding the start.
    private func path(to target: Tile) -> [Tile] {
        let g = gridSize
        func key(_ t: Tile) -> Int { t.row * g.cols + t.col }
        var previous: [Int: Tile] = [:]
        var queue = [heroTile]
        var visited: Set<Int> = [key(heroTile)]
        var head = 0
        while head < queue.count {
            let current = queue[head]; head += 1
            if current == target { break }
            for (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)] {
                let next = Tile(col: current.col + dx, row: current.row + dy)
                guard isWalkable(next), !visited.contains(key(next)) else { continue }
                visited.insert(key(next))
                previous[key(next)] = current
                queue.append(next)
            }
        }
        guard visited.contains(key(target)) else { return [] }
        var route: [Tile] = []
        var step = target
        while step != heroTile, let prev = previous[key(step)] {
            route.append(step)
            step = prev
        }
        return route.reversed()
    }

    /// Same pace and walk cycle as joystick movement (0.12 s per tile).
    func walk(path route: [Tile]) {
        guard !route.isEmpty else {
            checkReached()
            return
        }
        onHeroMoved?()
        hero.removeAction(forKey: "walk")
        var steps: [SKAction] = []
        var current = heroTile
        for next in route {
            let direction: Facing = next.col > current.col ? .right
                : next.col < current.col ? .left
                : next.row > current.row ? .back : .front
            steps.append(.run { [weak self] in self?.setFacing(direction, walking: true) })
            steps.append(.move(to: center(of: next), duration: 0.12))
            steps.append(.run { [weak self] in self?.heroTile = next })
            current = next
        }
        steps.append(.run { [weak self] in
            guard let self else { return }
            self.setFacing(self.facing, walking: false)
            self.checkReached()
        })
        hero.run(.sequence(steps), withKey: "walk")
    }

    private func arrived() {
        guard let id = pendingTouchpoint else { return }
        pendingTouchpoint = nil
        onTouchpointArrived?(id)
    }

    // MARK: Painting glow (before Touchpoint 5)

    /// The painting on the east wall, exactly as painted in the room art.
    static let paintingArtRect = CGRect(x: 794.0 / 874, y: 29.0 / 402, width: 59.0 / 874, height: 89.0 / 402)
    private var objectGlow: SKNode?

    /// Same look as the team's TP overlays: a pulsing blue halo behind the
    /// object, with the object itself drawn on top (sliced from the room art).
    func showPaintingGlow() {
        guard isBuilt, let background = backgroundNode?.texture else { return }
        hideObjectGlow()
        let rect = sceneRect(for: Self.paintingArtRect)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let node = SKNode()
        node.zPosition = 0.5

        let glow = SKSpriteNode(texture: Self.glowTexture)
        glow.size = CGSize(width: rect.width * 3.4, height: rect.height * 2.2)
        glow.position = center
        glow.run(.repeatForever(.sequence([.fadeAlpha(to: 0.55, duration: 0.8),
                                           .fadeAlpha(to: 1.0, duration: 0.8)])))
        node.addChild(glow)

        let r = Self.paintingArtRect
        let slice = SKTexture(rect: CGRect(x: r.minX, y: 1 - r.maxY, width: r.width, height: r.height), in: background)
        slice.filteringMode = .nearest
        let painting = SKSpriteNode(texture: slice)
        painting.size = rect.size
        painting.position = center
        painting.zPosition = 0.1
        node.addChild(painting)

        addChild(node)
        objectGlow = node
    }

    func hideObjectGlow() {
        objectGlow?.removeFromParent()
        objectGlow = nil
    }

    private static let glowTexture: SKTexture = {
        let size = CGSize(width: 128, height: 128)
        let accent = UIColor(named: "Accent") ?? .cyan
        let image = UIGraphicsImageRenderer(size: size).image { ctx in
            let colors = [accent.withAlphaComponent(0.85).cgColor, accent.withAlphaComponent(0).cgColor] as CFArray
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) else { return }
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            ctx.cgContext.drawRadialGradient(gradient, startCenter: c, startRadius: 0, endCenter: c, endRadius: size.width / 2, options: [])
        }
        return SKTexture(image: image)
    }()

    // MARK: Laptop / PC screen

    enum MonitorState { case normal, locked, decrypted }

    func setMonitor(_ state: MonitorState) {
        guard isBuilt else { return }
        switch state {
        case .normal:
            monitorScreen?.removeFromParent()
            monitorScreen = nil
        case .locked, .decrypted:
            let key = state == .locked ? "px_screen_locked" : "px_screen_decrypted"
            guard let texture = PixelArtGenerator.texture(named: key) else { return }
            let rect = sceneRect(for: monitorScreenRect)
            let node = monitorScreen ?? SKSpriteNode(texture: texture)
            node.texture = texture
            node.size = rect.size
            node.position = CGPoint(x: rect.midX, y: rect.midY)
            node.zPosition = 1        // above the TP4 glow overlay (which redraws the monitor), below the MC (10)
            if monitorScreen == nil { addChild(node); monitorScreen = node }
            if state == .decrypted {
                node.run(.sequence([.fadeAlpha(to: 0.2, duration: 0.08), .fadeAlpha(to: 1, duration: 0.08),
                                    .fadeAlpha(to: 0.4, duration: 0.06), .fadeAlpha(to: 1, duration: 0.12)]))
            }
        }
    }
    
    func center(of tile: Tile) -> CGPoint {
        CGPoint(x: (CGFloat(tile.col) + 0.5) * tileSize,
                y: (CGFloat(tile.row) + 0.5) * tileSize)
    }
    
    func footPoint(of tile: Tile) -> CGPoint {
        CGPoint(x: (CGFloat(tile.col) + 0.5) * tileSize,
                y: CGFloat(tile.row) * tileSize)
    }
    
    func tile(at point: CGPoint) -> Tile {
        Tile(col: Int(point.x / tileSize),
             row: Int(point.y / tileSize))
    }
    
    
    
    func walk(to target: Tile) {
        hero.removeAction(forKey: "walk")
        var steps: [SKAction] = []
        var current = heroTile

        while current.col != target.col {
            let dx = current.col < target.col ? 1 : -1
            current.col += dx
            let next = current
            let direction: Facing = dx > 0 ? .right : .left
            steps.append(.run { [weak self] in self?.setFacing(direction, walking: true) })
            steps.append(.move(to: center(of: next), duration: 0.12))
            steps.append(.run { [weak self] in self?.heroTile = next })
        }
        while current.row != target.row {
            let dy = current.row < target.row ? 1 : -1
            current.row += dy
            let next = current
            let direction: Facing = dy > 0 ? .back : .front
            steps.append(.run { [weak self] in self?.setFacing(direction, walking: true) })
            steps.append(.move(to: center(of: next), duration: 0.12))
            steps.append(.run { [weak self] in self?.heroTile = next })
        }
        steps.append(.run { [weak self] in
            guard let self else { return }
            self.setFacing(self.facing, walking: false)
            self.checkReached()
        })
        hero.run(.sequence(steps), withKey: "walk")
    }

    private func setFacing(_ newFacing: Facing, walking: Bool) {
        let directionChanged = facing != newFacing
        facing = newFacing

        let idle: SKTexture
        let walkTexture: SKTexture?
        let scale: CGFloat
        switch newFacing {
        case .front: idle = tFront; walkTexture = tFrontWalk; scale = 1
        case .back:  idle = tBack;  walkTexture = nil;        scale = 1
        case .left:  idle = tSideLeft; walkTexture = tSideWalkLeft; scale = -1
        case .right: idle = tSideLeft; walkTexture = tSideWalkLeft; scale = 1
        }
        hero.xScale = scale

        if walking, let walkTexture {
            if directionChanged || hero.action(forKey: "step") == nil {
                hero.removeAction(forKey: "step")
                let anim = SKAction.repeatForever(.animate(with: [walkTexture, idle], timePerFrame: 0.12))
                hero.run(anim, withKey: "step")
            }
        } else {
            hero.removeAction(forKey: "step")
            hero.texture = idle
        }
    }
    
    func checkReached() {
        if heroTile == exitTile {
            onExit?()
            return
        }
        //        guard let index = checkpoints.firstIndex(of: heroTile) else { return }
        
        if let pending = pendingTouchpoint {
            if touchpointAreas[pending]?.contains(heroTile) == true {
                arrived()
            } else {
                pendingTouchpoint = nil
            }
            return
        }
        // Only the next unfinished touchpoint prompts; finished ones stay quiet
        // so walking past the PC after TP4 doesn't reopen it.
        if case .touchpoint(let id) = kind(of: heroTile), !completedTouchpoints.contains(id) {
            onTouchpointPrompt?(id)
        }
    }
    
    func step(dx: Int, dy: Int) {
        guard hero.action(forKey: "walk") == nil else { return }
        let next = Tile(col: heroTile.col + dx, row: heroTile.row + dy)
        let cols = Int(size.width / tileSize)
        let rows = Int(size.height / tileSize)
        guard (0..<cols).contains(next.col), (0..<rows).contains(next.row) else { return }
        guard case .blocked = kind(of: next) else {
            pendingTouchpoint = nil
            onHeroMoved?()      // <- the only added line
            walk(to: next)
            return
        }
    }
    
    func kind(of tile: Tile) -> TileKind {
        if blockedTiles.contains(tile) { return .blocked }
        if let i = checkpoints.firstIndex(of: tile) { return .interactable(id: i) }
        for (id, tiles) in touchpointAreas where tiles.contains(tile) {
            return .touchpoint(id: id)
        }
        return .walkable
    }
    
    func completeTouchpoint(_ id: Int) {
        completedTouchpoints.insert(id)
        unlockedTouchpoints.insert(id + 1)
    }
    
    
    func debugColor(for kind: TileKind) -> SKColor {
        switch kind {
        case .blocked: return .systemRed
        case .interactable: return .systemYellow
        case .walkable: return .systemGreen
        case .touchpoint: return .systemOrange
        }
    }
    
    func swapGeneratorOverlay(to imageName: String) {
        generatorOverlay?.texture = SKTexture(imageNamed: imageName)
    }

    func swapBackground(to imageName: String) {
        backgroundNode?.texture = SKTexture(imageNamed: imageName)
    }
    
    func buildDebugOverlay() {
        let cols = Int(size.width / tileSize)
        let rows = Int(size.height / tileSize)
        
        for row in 0..<rows {
            for col in 0..<cols {
                let tile = Tile(col: col, row: row)
                let kind = kind(of: tile)
                
                let square = SKShapeNode(rectOf: CGSize(width: tileSize, height: tileSize))
                square.fillColor = debugColor(for: kind)
                square.alpha = 0.35
                square.strokeColor = .black
                square.lineWidth = 0.5
                square.position = center(of: tile)
                square.zPosition = 1
                addChild(square)
                
                let label = SKLabelNode(text: "\(col),\(row)")
                label.fontName = "Menlo"
                label.fontSize = 8
                label.fontColor = .black
                label.verticalAlignmentMode = .center
                label.zPosition = 2
                square.addChild(label)
            }
        }
    }
}



#Preview {
    ContentView()
}
