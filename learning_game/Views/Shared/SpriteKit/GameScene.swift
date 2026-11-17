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
        let topHalfStart = rows / 2
        return (topHalfStart..<rows).flatMap { row in
            (0..<cols).map { col in Tile(col: col, row: row) }
        }
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
    var heroTile = Tile(col:2, row:2)
    var floorColors: (SKColor, SKColor) { (.systemGreen, .green) }
    var onCheckpoint: ((Int) -> Void)?
    var onExit: (() -> Void)?
    var exitTile: Tile? { nil }

    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
    }
    required init?(coder: NSCoder) {
        fatalError()
    }
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        onDialog?([
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
        ])
        
        guard !isBuilt else { return }
        isBuilt = true

        for (index, tile) in checkpoints.enumerated() {
            let node = SKSpriteNode(color: .systemBlue, size: CGSize(width: tileSize, height: tileSize))
            node.position = center(of: tile)
            node.zPosition = 5
            
            let label = SKLabelNode(text: "\(index + 1)")
            label.fontName = "Menlo-Bold"
            label.fontSize = 16
            label.verticalAlignmentMode = .center
            node.addChild(label)
            addChild(node)
            checkpointNodes.append(node)
        }
        
        let background = SKSpriteNode(imageNamed: "background_dimmed")
        background.position = CGPoint(x: frame.midX, y: frame.midY)
        background.size = frame.size
        background.zPosition = -1
        addChild(background)
        
        
        hero.size = CGSize(width: hero.size.width*1.5, height: hero.size.height*1.5)
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
        guard let index = checkpoints.firstIndex(of: heroTile) else { return }

        if !reached.contains(index) {
            reached.insert(index)
            let node = checkpointNodes[index]
            node.color = .systemYellow
            node.run(.sequence([.scale(to: 1.3, duration: 0.1), .scale(to: 1, duration: 0.1)]))
        }

        onCheckpoint?(index)
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
        return .walkable
    }

}



#Preview {
    ContentView()
}
