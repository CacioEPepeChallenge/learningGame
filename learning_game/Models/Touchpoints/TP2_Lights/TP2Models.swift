//
//  TP2Models.swift
//  learning_game
//
//  Touchpoint 2 — Arrays & Enums (The Lights).
//  Plain data only: which card is showing, the room's lights and the text
//  each card displays.
//

import Foundation

/// The challenge cards of Touchpoint 2, in play order.
enum TP2Screen: Int, CaseIterable {
    case dialogue = 2            // Screen 2 — I.R.I.S. dialogue bar (friend's DialogBox)
    case lightingSchematic       // Screen 3 — intro: what Arrays and Enums are
    case switchLights            // Screen 4 — tap lamps: roomLights[i] = .on / .off / .dim
    case reconstruct             // Screen 5 — blocks: roomLights[0] = .on
    case readArray               // Screen 6 — match schedule[i] to its value (+ out of range)
    case trueOrFalse             // Screen 7 — "the first item is at index 1" → False
    case appendCount             // Screen 8 — roomLights.append(.off) → count?
    case fixCode                 // Screen 9 — fill `enum` and `.dim` (traps .bright / "dim")
    case lightsRestored          // Screen 10 — payoff + recap, Continue finishes TP2

    var next: TP2Screen? { TP2Screen(rawValue: rawValue + 1) }
}

/// Swift enum taught in this touchpoint — a light can only be one of these.
enum TP2LightState: String, CaseIterable {
    case on, off, dim

    /// How it is written in Swift code: `.on`, `.off`, `.dim`.
    var code: String { ".\(rawValue)" }

    /// Tap order on the lamps: off → dim → on → off.
    var next: TP2LightState {
        switch self {
        case .off: .dim
        case .dim: .on
        case .on: .off
        }
    }
}

/// One light in Leo's room = one element of `roomLights`.
struct TP2Lamp: Identifiable {
    let index: Int               // position in the array: roomLights[index]
    let name: String             // "hanging lamp"
    let codeName: String         // "hangingLamp"
    var id: Int { index }

    /// Sprite for each state (from Sprites.xcassets).
    func sprite(for state: TP2LightState) -> String {
        switch (index, state) {
        case (0, .off): "hanging_lamp"
        case (0, _): "hanging_lamp_on"       // dim = the lit sprite, darkened
        default: "desk_lamp"                 // one lit sprite, darkened for dim / off
        }
    }

    /// Extra darkening on top of the sprite (0 = as drawn, negative = darker).
    func darkening(for state: TP2LightState) -> Double {
        switch (index, state) {
        case (_, .on): 0
        case (_, .dim): -0.22
        case (0, .off): 0                    // hanging lamp has its own "off" sprite
        case (_, .off): -0.45
        }
    }

    /// Colour kept on top of the sprite (1 = full colour, 0 = grey).
    func saturation(for state: TP2LightState) -> Double {
        state == .off && index != 0 ? 0.35 : 1
    }

    static let room: [TP2Lamp] = [
        TP2Lamp(index: 0, name: "hanging lamp", codeName: "hangingLamp"),
        TP2Lamp(index: 1, name: "desk lamp", codeName: "deskLamp"),
    ]
}

// MARK: - Screen 4 — Switch the Lights

struct TP2SwitchLightsContent {
    let title: String
    let subtitle: String
    let codeHeader: String       // first, fixed line of the code panel
    let tapHint: String
    let taskLabel: String
    let taskText: String
    let successFeedback: String
    let goalIndex: Int           // roomLights[goalIndex] …
    let goalState: TP2LightState // … must be this
    let buttonTitle: String

    static let figma = TP2SwitchLightsContent(
        title: "Switch the Lights",
        subtitle: "Tap a lamp to change its LightState.",
        codeHeader: "var roomLights: [LightState] = [.off, .off]",
        tapHint: "// tap a lamp to run a line of code",
        taskLabel: "Task:",
        taskText: "Turn on the hanging lamp → roomLights[0] = .on",
        successFeedback: "roomLights[0] is .on, the hanging lamp is lit!",
        goalIndex: 0,
        goalState: .on,
        buttonTitle: "Next"
    )
}

// MARK: - Screen 5 — Reconstruct the Code

/// A code block for the single-line puzzle, e.g. `roomLights` or `[0]`.
struct TP2Block: Identifiable, Hashable {
    let id: Int
    let text: String
}

struct TP2ReconstructContent {
    let title: String
    let subtitle: String
    /// Tray order (shuffled), including the traps.
    let blocks: [TP2Block]
    /// Block ids of the correct line, in order.
    let answer: [TP2Block.ID]
    let taskLabel: String
    let taskText: String
    let successFeedback: String
    let wrongFeedback: String
    /// Extra hint when a trap block is used.
    let trapHints: [TP2Block.ID: String]
    let checkTitle: String
    let nextTitle: String
    let tryAgainTitle: String

    static let figma = TP2ReconstructContent(
        title: "Reconstruct the Code",
        subtitle: "Put the blocks in the correct order.",
        blocks: [
            TP2Block(id: 0, text: "[1]"),
            TP2Block(id: 1, text: "roomLights"),
            TP2Block(id: 2, text: ".on"),
            TP2Block(id: 3, text: "="),
            TP2Block(id: 4, text: "\"on\""),
            TP2Block(id: 5, text: "[0]"),
        ],
        answer: [1, 5, 3, 2],                  // roomLights [0] = .on
        taskLabel: "Task:",
        taskText: "Write the line that turns the hanging lamp on.",
        successFeedback: "Correct! roomLights[0] = .on lights the hanging lamp.",
        wrongFeedback: "Not quite. Array name, then [index], then = and the new value.",
        trapHints: [
            0: "[1] is the desk lamp. The hanging lamp is the first item: [0].",
            4: "\"on\" is a String. LightState cases are written with a dot: .on",
        ],
        checkTitle: "Check",
        nextTitle: "Next",
        tryAgainTitle: "Try again"
    )
}

// MARK: - Screen 6 — Read the Array

/// One chip in a two-column matcher.
struct TP2MatchItem: Identifiable, Hashable {
    let id: Int
    let text: String
}

struct TP2ReadArrayContent {
    let title: String
    let subtitle: String
    let code: String
    let explanation: String
    let taskLabel: String
    let taskText: String
    /// Left column: index expressions (ids 0…3).
    let left: [TP2MatchItem]
    /// Right column (shuffled): values (ids 0…3).
    let right: [TP2MatchItem]
    /// Correct pairs: left id → right id.
    let answer: [Int: Int]
    let successFeedback: String
    let wrongFeedback: String
    let checkTitle: String
    let nextTitle: String
    let tryAgainTitle: String

    static let figma = TP2ReadArrayContent(
        title: "Read the Array",
        subtitle: "Match each index to the value stored there.",
        code: """
        // Leo's light schedule: morning, evening, night
        let schedule: [LightState] = [.on, .dim, .off]
        """,
        explanation: "Reading an array: put the index in brackets. schedule has 3 items, so its indexes are 0, 1 and 2. Asking for [3] crashes the app.",
        taskLabel: "Exercise:",
        taskText: "Match the pairs on the side.",
        left: [
            TP2MatchItem(id: 0, text: "schedule[0]"),
            TP2MatchItem(id: 1, text: "schedule[1]"),
            TP2MatchItem(id: 2, text: "schedule[2]"),
            TP2MatchItem(id: 3, text: "schedule[3]"),
        ],
        right: [
            TP2MatchItem(id: 1, text: ".dim"),
            TP2MatchItem(id: 3, text: "out of range"),
            TP2MatchItem(id: 0, text: ".on"),
            TP2MatchItem(id: 2, text: ".off"),
        ],
        answer: [0: 0, 1: 1, 2: 2, 3: 3],
        successFeedback: "Correct! [3] doesn't exist: the last index is count − 1.",
        wrongFeedback: "Some pairs don't match. Count from 0: .on is schedule[0].",
        checkTitle: "Check",
        nextTitle: "Next",
        tryAgainTitle: "Try again"
    )
}

// MARK: - Screen 7 — True or False

struct TP2TrueFalseContent {
    let title: String
    let subtitle: String
    let code: String
    let answer: Bool
    let explanationCode: String     // shown after answering
    let successFeedback: String
    let wrongFeedback: String
    let trueTitle: String
    let falseTitle: String
    let nextTitle: String
    let tryAgainTitle: String

    static let figma = TP2TrueFalseContent(
        title: "True or False",
        subtitle: "The first item of an array is at index 1. True or false?",
        code: """
        let schedule: [LightState] = [.on, .dim, .off]
        let first = schedule[1]
        """,
        answer: false,
        explanationCode: "// schedule[1] is .dim, the SECOND item. The first is schedule[0].",
        successFeedback: "Right! Arrays count from 0, so the first item is [0].",
        wrongFeedback: "Not quite. Arrays count from 0, so [1] is the second item.",
        trueTitle: "True",
        falseTitle: "False",
        nextTitle: "Next",
        tryAgainTitle: "Try again"
    )
}

// MARK: - Screen 8 — Add a Light (append + count)

struct TP2AppendCountContent {
    let title: String
    let subtitle: String
    let code: String
    let options: [Int]
    let correct: Int
    let explanations: [Int: String]
    let taskLabel: String
    let taskText: String
    let checkTitle: String
    let nextTitle: String
    let tryAgainTitle: String

    static let figma = TP2AppendCountContent(
        title: "Choose the Correct Answer",
        subtitle: "Leo adds a new light. What will the code display?",
        code: """
        var roomLights: [LightState] = [.on, .dim]
        roomLights.append(.off)
        print(roomLights.count)
        """,
        options: [2, 3, 4],
        correct: 3,
        explanations: [
            2: "append adds an item, so the array grows past 2.",
            3: "Correct! 2 lights + 1 appended = 3. The new one is roomLights[2].",
            4: "append adds just one item: 2 + 1 = 3.",
        ],
        taskLabel: "Tip:",
        taskText: "Tap an answer, then Check.",
        checkTitle: "Check",
        nextTitle: "Next",
        tryAgainTitle: "Try again"
    )
}

// MARK: - Screen 9 — Fix the Code (enum)

/// A chip that can go into a blank of the Fix-the-Code panel.
struct TP2FixChip: Identifiable, Hashable {
    let id: Int
    let text: String
}

/// One blank in the code: which chip is right and what Swift says otherwise.
struct TP2FixBlank: Identifiable {
    let id: Int
    let answer: TP2FixChip.ID
    /// Compiler error / hint per wrong chip (fallback: `genericError`).
    let errors: [TP2FixChip.ID: String]
    let genericError: String
}

struct TP2FixCodeContent {
    let title: String
    let subtitle: String
    let chips: [TP2FixChip]
    let blanks: [TP2FixBlank]       // [0] = keyword before LightState, [1] = new value
    let taskLabel: String
    let taskText: String
    let successFeedback: String
    let wrongFeedback: String
    let checkTitle: String
    let nextTitle: String
    let tryAgainTitle: String

    static let figma = TP2FixCodeContent(
        title: "Fix the Code",
        subtitle: "Drag the right block to complete the code.",
        chips: [
            TP2FixChip(id: 0, text: ".bright"),
            TP2FixChip(id: 1, text: "enum"),
            TP2FixChip(id: 2, text: "\"dim\""),
            TP2FixChip(id: 3, text: ".dim"),
        ],
        blanks: [
            TP2FixBlank(id: 0, answer: 1,
                        errors: [:],
                        genericError: "error: expected declaration · LightState needs the enum keyword"),
            TP2FixBlank(id: 1, answer: 3,
                        errors: [
                            0: "error: type 'LightState' has no member 'bright'",
                            2: "error: cannot assign value of type 'String' to type 'LightState'",
                        ],
                        genericError: "error: roomLights[1] needs a LightState case"),
        ],
        taskLabel: "Task:",
        taskText: "Declare the enum and make the desk lamp dim.",
        successFeedback: "Correct! An enum only allows its own cases: .dim works, .bright doesn't.",
        wrongFeedback: "Swift found a problem. Read the red error in the code.",
        checkTitle: "Check",
        nextTitle: "Next",
        tryAgainTitle: "Try again"
    )
}

// MARK: - Screen 10 — Lights Restored

struct TP2LightsRestoredContent {
    let title: String
    let subtitle: String
    let recapTitle: String
    let recap: [String]
    let buttonTitle: String

    static let figma = TP2LightsRestoredContent(
        title: "Lights Restored",
        subtitle: "I can see the room again. Thank you!",
        recapTitle: "What you learned",
        recap: [
            "An array keeps items in order. The first one is [0].",
            ".append() adds an item to the end, .count says how many.",
            "Reading an index that doesn't exist crashes the app.",
            "An enum allows only its cases: .on, .off, .dim. Nothing else.",
        ],
        buttonTitle: "Continue"
    )
}

// MARK: - Screen 2 — I.R.I.S. dialogue

struct TP2DialogueContent {
    /// Shown one after another in the friend's `DialogBox` (tap to continue).
    let lines: [DialogLine]

    static let figma = TP2DialogueContent(lines: [
        DialogLine(speaker: "IRIS",
                   text: "The generator is running but I am locked out of the light.\nLeo organized them using Arrays and Enums.",
                   portrait: "iris"),          // Figma: the smiling I.R.I.S. sprite
    ])
}

// MARK: - Screen 3 — Lighting Schematic

/// One concept explained on the intro card, e.g. "Array".
struct TP2Concept: Identifiable {
    let name: String
    let explanation: String
    let example: String          // short code example
    let exampleNote: String      // what the example means
    var id: String { name }
}

struct TP2LightingSchematicContent {
    let title: String
    let subtitle: String
    let concepts: [TP2Concept]
    let code: String
    let buttonTitle: String

    static let figma = TP2LightingSchematicContent(
        title: "Lighting Schematic",
        subtitle: "How Leo stores and controls the lights.",
        concepts: [
            TP2Concept(name: "Array",
                       explanation: "An ordered list of values. Each item has a position, its index, starting at 0. .append() adds one, .count says how many.",
                       example: "roomLights[0]",
                       exampleNote: "the first light"),
            TP2Concept(name: "Enum",
                       explanation: "A type with a fixed list of choices. A light can only be one of them, nothing else.",
                       example: ".on  .off  .dim",
                       exampleNote: "the only LightStates"),
        ],
        code: """
        enum LightState {
            case on, off, dim
        }

        var roomLights: [LightState] = [.off, .off]
        """,
        buttonTitle: "Next"
    )
}
