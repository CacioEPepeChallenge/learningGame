//
//  onboardingModels.swift
//  learning_game
//
//  Created by Rudi Butarbutar on 17/11/26.
//


struct Tile: Equatable {
    var col: Int
    var row: Int
}

enum TileKind {
    case walkable
    case blocked
    case interactable(id: Int)
}

struct DialogLine {
    let speaker: String
    let text: String

    var image: String {
        speaker == "IRIS" ? "iris_dialogue" : "mc_head"
    }
}


