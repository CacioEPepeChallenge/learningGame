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
        1: [Tile(col: 24, row: 0), Tile(col: 24, row: 1)],
        2: [Tile(col: 13, row: 4), Tile(col: 13, row: 3)],
        3: [Tile(col: 15, row: 4), Tile(col: 16, row: 4)],
        4: [Tile(col: 9, row: 4), Tile(col: 10, row: 4)],
        5: [Tile(col: 25, row: 4), Tile(col: 26, row: 4)]
    ]
                                                                                       
    var unlockedTouchpoints: Set<Int> = [1]
                    
    var touchpointAreas: [Int: [Tile]] {
        allTouchpointAreas.filter { unlockedTouchpoints.contains($0.key) }
    }

    var onDialog: (([DialogLine]) -> Void)?
    var inputLocked = false
    private var isBuilt = false
    private let hero = SKSpriteNode(imageNamed: "mc1")
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
    
    private var generatorOverlay: SKSpriteNode?
    func showGeneratorOverlay() {
        guard generatorOverlay == nil else { return }
        let node = SKSpriteNode(imageNamed: "TP1")
        node.position = CGPoint(x: frame.midX, y: frame.midY)
        node.size = frame.size
        node.zPosition = 0
        addChild(node)
        generatorOverlay = node
        
        let pulse = SKAction.sequence([
            .fadeAlpha(to: 0.6, duration: 0.8),
            .fadeAlpha(to: 1.0, duration: 0.8)
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
        
        
        hero.size = CGSize(width: hero.size.width*1.5, height: hero.size.height*1.5)
        hero.anchorPoint = CGPoint(x: 0.5, y: 0)
        hero.position = center(of: heroTile)
        hero.zPosition = 10
        addChild(hero)
        
//        let breathe = SKAction.sequence([
//            .scaleY(to: 0.9, duration: 0.35),
//            .scaleY(to: 1.0, duration: 0.35)
//        ])
//        hero.run(.repeatForever(breathe), withKey: "idle")
        
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard let stick = (GCController.current ?? GCController.controllers().first)?
                .extendedGamepad?.leftThumbstick else { return }
        guard !inputLocked else { return }
        
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
    
    
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        guard let point = touches.first?.location(in: self) else { return }
//        walk(to: tile(at: point))
//    }
    
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

        
        if target.col != current.col {
            hero.xScale = target.col > current.col ? 1 : -1
        }
        
        while current.col != target.col {
            current.col += current.col < target.col ? 1 : -1
            let next = current
            steps.append(.move(to: center(of: next), duration: 0.12))
            steps.append(.run {
                [weak self] in self?.heroTile = next
            })
        }
        while current.row != target.row {
            current.row += current.row < target.row ? 1 : -1
            let next = current
            steps.append(.move(to: center(of: next), duration: 0.12))
            steps.append(.run {
                [weak self] in self?.heroTile = next
            })
        }
        steps.append(.run {
            [weak self] in self?.checkReached()
        })
        hero.run(.sequence(steps), withKey: "walk")
    }
    
    func checkReached() {
        if heroTile == exitTile {
            onExit?()
            return
        }
//        guard let index = checkpoints.firstIndex(of: heroTile) else { return }

        if case .touchpoint(let id) = kind(of: heroTile) {
            onTouchpointPrompt?(id)
            print(id)
        }
    }
    
    func step(dx: Int, dy: Int) {
        guard hero.action(forKey: "walk") == nil else { return }
        let next = Tile(col: heroTile.col + dx, row: heroTile.row + dy)
        let cols = Int(size.width / tileSize)
        let rows = Int(size.height / tileSize)
        guard (0..<cols).contains(next.col), (0..<rows).contains(next.row) else { return }
        guard case .blocked = kind(of: next) else {
            walk(to: next)
            return
        }
    }
    func kind(of tile: Tile) -> TileKind {
        if blockedTiles.contains(tile) { return .blocked }
        if let i = checkpoints.firstIndex(of: tile) { return .interactable(id: i) }
        for (id, tiles) in allTouchpointAreas where tiles.contains(tile) {
            return .touchpoint(id: id)
        }
        return .walkable
    }
    
    func completeTouchpoint(_ id: Int) {
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
