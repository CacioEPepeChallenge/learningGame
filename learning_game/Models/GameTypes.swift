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
    case touchpoint(id: Int)
}


struct DialogLine {
    let speaker: String
    let text: String
    /// Optional portrait override (e.g. "iris" on the touchpoint cards).
    /// nil = the default portrait for the speaker.
    var portrait: String? = nil

    var image: String {
        portrait ?? (speaker == "IRIS" ? "iris_dialogue" : "mc_head")
    }
}

