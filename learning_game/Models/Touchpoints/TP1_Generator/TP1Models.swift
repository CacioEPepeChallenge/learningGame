//
//  TP1Models.swift
//  learning_game
//
//  Touchpoint 1 — Variables & Data Types (The Generator).
//  Plain data only: which card is showing and the text each card displays.
//

import Foundation

/// The challenge cards of Touchpoint 1, in play order.
enum TP1Screen: Int, CaseIterable {
    case generatorCore = 3       // Screen 3  — intro: Leo's override notes
    case variableOrConstant      // Screen 4  — var vs let sliders
    case dataTypes               // Screens 5–7 — data type matcher
    case declaringVariable       // Screen 8  — blocks: var powerLevel = 100 (note ①)
    case declaringConstant       // Screen 9  — blocks: let maxVoltage = 220
    case typeSafety              // Screen 10 — type safety: overrideKey: String (note ②)
    case chooseAnswer            // Screen 11 — choose the correct answer (Bool, note ③)
    case trueOrFalse             // Screen 12 — true or false
    case boolSwitch              // Screen 13 — Bool: coolingPump = true (note ③)
    case ignition                // Screen 14 — all notes done → Ignite the generator
    case congratulations         // Screen 15 — Congratulations, open your present (next clue)

    var next: TP1Screen? { TP1Screen(rawValue: rawValue + 1) }
}

/// One line of Leo's override notes, e.g. `powerLevel = 100 (must stay adjustable)`.
struct TP1OverrideNote: Identifiable, Hashable {
    let code: String
    let hint: String
    var id: String { code }
    var text: String { "\(code) (\(hint))" }
}

/// Text for Screen 3 — Generator Core.
struct TP1GeneratorCoreContent {
    let title: String
    let subtitle: String
    let notesTitle: String
    let notes: [TP1OverrideNote]
    let monitorMessage: String
    let monitorStatus: String
    let buttonTitle: String

    static let figma = TP1GeneratorCoreContent(
        title: "Generator Core",
        subtitle: "Inspect hardware bays and Leo’s manual note.",
        notesTitle: "Leo’s Override Notes",
        notes: [
            TP1OverrideNote(code: "powerLevel = 100", hint: "must stay adjustable"),
            TP1OverrideNote(code: "overrideKey = \"OMEGA\"", hint: "LOCKED — never change!"),
            TP1OverrideNote(code: "coolingPump = true", hint: "turn ON before ignition"),
        ],
        monitorMessage: "OFFLINE",
        monitorStatus: "STATUS: BOOT MEMORY WIPED",
        buttonTitle: "Start mission"
    )
}

// MARK: - Leo's manual (the goal of Touchpoint 1)

/// Leo's 3 override notes. Each challenge from Screen 8 on completes one;
/// the ①②③ circles on the cards show this progress.
enum TP1LeoNote: Int, CaseIterable, Identifiable {
    case powerLevel, overrideKey, coolingPump
    var id: Int { rawValue }
}

// MARK: - Screens 8–9 — Put the blocks in order

/// A draggable code block, e.g. `var` or `powerLevel`.
struct TP1CodeBlock: Identifiable, Hashable {
    let id: Int
    let text: String
}

/// A "put the blocks in the correct order" puzzle.
struct TP1BlockPuzzleContent {
    let title: String
    let subtitle: String
    /// Leo's note this puzzle completes (nil = practice, not in the manual).
    let note: TP1LeoNote?
    let taskLabel: String
    let taskText: String
    /// Tray order (shuffled), including distractor blocks.
    let blocks: [TP1CodeBlock]
    /// Block ids in the correct slot order.
    let answer: [TP1CodeBlock.ID]
    let successFeedback: String
    let wrongFeedback: String
    /// Extra hint shown when a specific distractor block ends up in a slot.
    let distractorHints: [TP1CodeBlock.ID: String]
    let checkTitle: String
    let nextTitle: String
    let tryAgainTitle: String

    /// Screen 8 — Leo's note ①: `var powerLevel = 100`.
    static let declareVariable = TP1BlockPuzzleContent(
        title: "Declaring Variables",
        subtitle: "Put the blocks in the correct order.",
        note: .powerLevel,
        taskLabel: "Leo’s note:",
        taskText: "powerLevel = 100 (must stay adjustable)",
        blocks: [
            TP1CodeBlock(id: 0, text: "let"),
            TP1CodeBlock(id: 1, text: "100"),
            TP1CodeBlock(id: 2, text: "var"),
            TP1CodeBlock(id: 3, text: "powerLevel"),
            TP1CodeBlock(id: 4, text: "="),
        ],
        answer: [2, 3, 4, 1],
        successFeedback: "Correct! var lets powerLevel change later.",
        wrongFeedback: "Not quite. Read it like a sentence: keyword, name, =, value.",
        distractorHints: [0: "powerLevel must stay adjustable, so it can’t be a let."],
        checkTitle: "Check",
        nextTitle: "Next",
        tryAgainTitle: "Try again"
    )

    /// Screen 9 — `let maxVoltage = 220`, the locked constant from Screen 4.
    /// Trap: `var` (the voltage limit must never change).
    static let declareConstant = TP1BlockPuzzleContent(
        title: "Declaring Constant",
        subtitle: "Put the blocks in the correct order.",
        note: nil,
        taskLabel: "Safety rule:",
        taskText: "maxVoltage = 220 (must never change)",
        blocks: [
            TP1CodeBlock(id: 0, text: "220"),
            TP1CodeBlock(id: 1, text: "var"),
            TP1CodeBlock(id: 2, text: "maxVoltage"),
            TP1CodeBlock(id: 3, text: "="),
            TP1CodeBlock(id: 4, text: "let"),
        ],
        answer: [4, 2, 3, 0],
        successFeedback: "Correct! let locks maxVoltage at 220 for good.",
        wrongFeedback: "Not quite. Read it like a sentence: keyword, name, =, value.",
        distractorHints: [
            1: "maxVoltage must never change, so it has to be a let, not a var.",
        ],
        checkTitle: "Check",
        nextTitle: "Next",
        tryAgainTitle: "Try again"
    )
}

// MARK: - Screen 10 — Type Safety

/// One code line with a type blank: `let overrideKey: [____] = "OMEGA"`.
struct TP1TypedLine: Identifiable {
    let id: Int
    let keyword: String          // "let" / "var"
    let name: String             // "overrideKey"
    let value: String            // "\"OMEGA\""
    let valueType: TP1DataType   // the type of `value` = the right answer
}

/// Text for Screen 10 — drag the right type into each blank.
struct TP1TypeSafetyContent {
    let title: String
    let subtitle: String
    let comment: String
    let lines: [TP1TypedLine]
    let chips: [TP1DataType]
    let taskLabel: String
    let taskText: String
    let successFeedback: String
    let wrongFeedback: String
    let checkTitle: String
    let nextTitle: String
    let tryAgainTitle: String

    /// Swift's real compiler message for a type mismatch.
    static func compilerError(value: TP1DataType, declared: TP1DataType) -> String {
        "error: cannot convert value of type '\(value.rawValue)' to specified type '\(declared.rawValue)'"
    }

    static let figma = TP1TypeSafetyContent(
        title: "Type Safety",
        subtitle: "Drag the right type to complete the code.",
        comment: "// Swift is type-safe: a value must match its type.",
        lines: [
            TP1TypedLine(id: 0, keyword: "let", name: "overrideKey", value: "\"OMEGA\"", valueType: .string),
            TP1TypedLine(id: 1, keyword: "var", name: "powerLevel", value: "100", valueType: .int),
        ],
        chips: [.int, .double, .string, .bool],
        taskLabel: "Leo’s note:",
        taskText: "overrideKey = \"OMEGA\" must be text.",
        successFeedback: "Correct! Every value matches its type.",
        wrongFeedback: "Type mismatch! Read the red error in the code.",
        checkTitle: "Check",
        nextTitle: "Next",
        tryAgainTitle: "Try again"
    )
}

// MARK: - Screen 11 — Choose the Correct Answer

/// One answer card: a short code snippet + why it is right / wrong.
struct TP1ChoiceOption: Identifiable {
    let id: Int
    let code: String
    let explanation: String
}

struct TP1ChoiceContent {
    let title: String
    let subtitle: String
    let options: [TP1ChoiceOption]
    let correctID: TP1ChoiceOption.ID
    let correctLabel: String
    let wrongLabel: String
    let taskLabel: String
    let taskText: String
    let checkTitle: String
    let nextTitle: String
    let tryAgainTitle: String

    static let figma = TP1ChoiceContent(
        title: "Choose the Correct Answer",
        subtitle: "Leo needs to raise the power later. Which code works?",
        options: [
            TP1ChoiceOption(id: 0,
                            code: "let powerLevel = 100\npowerLevel = 120",
                            explanation: "let can’t change, so Swift blocks powerLevel = 120."),
            TP1ChoiceOption(id: 1,
                            code: "var powerLevel = 100\npowerLevel = 120",
                            explanation: "var can change, and 120 is still an Int."),
            TP1ChoiceOption(id: 2,
                            code: "var powerLevel = \"100\"\npowerLevel = 120",
                            explanation: "\"100\" is a String, so an Int can’t go in it."),
        ],
        correctID: 1,
        correctLabel: "Correct!",
        wrongLabel: "Not quite",
        taskLabel: "Tip:",
        taskText: "Tap a card, then Check.",
        checkTitle: "Check",
        nextTitle: "Next",
        tryAgainTitle: "Try again"
    )
}

// MARK: - Screen 12 — True or False

struct TP1TrueFalseContent {
    let title: String
    let subtitle: String
    let code: String
    let answer: Bool
    let successFeedback: String
    let wrongFeedback: String
    let trueTitle: String
    let falseTitle: String
    let nextTitle: String
    let tryAgainTitle: String

    static let figma = TP1TrueFalseContent(
        title: "True or False",
        subtitle: "This code works — true or false?",
        code: "let overrideKey = \"OMEGA\"\noverrideKey = \"ALPHA\"",
        answer: false,
        successFeedback: "Right! overrideKey is a let, so it can never change.",
        wrongFeedback: "Not quite. A let is locked, so Swift shows an error.",
        trueTitle: "True",
        falseTitle: "False",
        nextTitle: "Next",
        tryAgainTitle: "Try again"
    )
}

// MARK: - Screen 13 — Bool switch (coolingPump)

/// A value chip for `var coolingPump: Bool = [____]`.
struct TP1BoolChoice: Identifiable, Hashable {
    let id: Int
    let text: String          // shown on the chip, e.g. "true", "\"true\"", "1"
    /// The value's real type. Only `.bool` compiles.
    let type: TP1DataType
    /// For Bool chips: does it turn the pump ON?
    let turnsOn: Bool
    let feedback: String
}

struct TP1BoolSwitchContent {
    let title: String
    let subtitle: String
    let comment: String
    let name: String
    let choices: [TP1BoolChoice]
    let taskLabel: String
    let taskText: String
    let successFeedback: String
    let toggleHint: String
    let pumpOffWarning: String
    let checkTitle: String
    let nextTitle: String
    let tryAgainTitle: String

    static let figma = TP1BoolSwitchContent(
        title: "Boolean Switch",
        subtitle: "Drag the right value to turn the cooling pump ON.",
        comment: "// A Bool can only be true or false.",
        name: "coolingPump",
        choices: [
            TP1BoolChoice(id: 0, text: "\"true\"", type: .string, turnsOn: false,
                          feedback: "Quotes make it a String, not a Bool."),
            TP1BoolChoice(id: 1, text: "false", type: .bool, turnsOn: false,
                          feedback: "That’s a real Bool, but it keeps the pump OFF."),
            TP1BoolChoice(id: 2, text: "1", type: .int, turnsOn: false,
                          feedback: "1 is an Int. A Bool is only true or false."),
            TP1BoolChoice(id: 3, text: "true", type: .bool, turnsOn: true,
                          feedback: "Pump ON! coolingPump is true."),
        ],
        taskLabel: "Leo’s note:",
        taskText: "coolingPump = true (turn ON before ignition)",
        successFeedback: "Pump ON! coolingPump is true.",
        toggleHint: "Tap the switch to try coolingPump.toggle()",
        pumpOffWarning: "Turn the pump back ON before ignition!",
        checkTitle: "Check",
        nextTitle: "Next",
        tryAgainTitle: "Try again"
    )
}

// MARK: - Screens 14–15 — Ignition & Congratulations

extension TP1LeoNote {
    /// The finished line of Swift for this note.
    var code: String {
        switch self {
        case .powerLevel: "var powerLevel = 100"
        case .overrideKey: "let overrideKey = \"OMEGA\""
        case .coolingPump: "var coolingPump = true"
        }
    }
}

struct TP1IgnitionContent {
    let title: String
    let subtitle: String
    let notesTitle: String
    let gridPowerLabel: String
    let missingNotes: String
    let onlineFeedback: String
    let igniteTitle: String
    let nextTitle: String

    static let figma = TP1IgnitionContent(
        title: "Ignition",
        subtitle: "Leo’s manual is complete. Restart the generator!",
        notesTitle: "Leo’s Override Notes",
        gridPowerLabel: "GRID POWER",
        missingNotes: "Finish all of Leo’s notes first.",
        onlineFeedback: "Generator online! Grid power at 100%.",
        igniteTitle: "Ignite",
        nextTitle: "Next"
    )
}

struct TP1CongratulationsContent {
    let title: String
    let subtitle: String
    let tapHint: String
    let clue: String
    let buttonTitle: String

    static let figma = TP1CongratulationsContent(
        title: "Congratulations",
        subtitle: "Open your present",
        tapHint: "Tap to open",
        clue: "Leo’s next clue is hidden in the desk lamp…",
        buttonTitle: "Discover a new clue"
    )
}

// MARK: - Screens 5–7 — Data Types matcher

/// The four Swift types taught in Touchpoint 1.
enum TP1DataType: String, CaseIterable, Identifiable {
    case int = "Int", double = "Double", string = "String", bool = "Bool"
    var id: String { rawValue }
}

/// A value chip in the left column, e.g. `24.5` (a Double).
struct TP1DataValue: Identifiable, Hashable {
    let id: Int
    let text: String
    let type: TP1DataType
}

/// One bullet of the type rules: "Int — Whole numbers without decimals (100)".
struct TP1TypeRule: Identifiable {
    let type: TP1DataType
    let description: String
    var id: TP1DataType { type }
}

/// Text for Screens 5–7 — Data Types (match each value to its type).
struct TP1DataTypesContent {
    let title: String
    let subtitle: String
    let intro: String
    let rules: [TP1TypeRule]
    let exerciseLabel: String
    let exerciseText: String
    /// Left column, top to bottom.
    let values: [TP1DataValue]
    /// Right column, top to bottom (shuffled so rows don't line up).
    let types: [TP1DataType]
    let checkTitle: String
    let nextTitle: String
    let tryAgainTitle: String
    let wrongFeedback: String

    static let figma = TP1DataTypesContent(
        title: "Data Types",
        subtitle: "How to store different kinds of data?",
        intro: "Swift is Type-Safe: every value has a specific type so numbers, text, and switches never mix by accident.",
        rules: [
            TP1TypeRule(type: .int,    description: "Whole numbers without decimals (100)"),
            TP1TypeRule(type: .double, description: "Numbers with a decimal point (24.5)"),
            TP1TypeRule(type: .string, description: "Text wrapped in \" \" quotes (\"OMEGA\")"),
            TP1TypeRule(type: .bool,   description: "Simple true or false switch (true)"),
        ],
        exerciseLabel: "Exercise:",
        exerciseText: "Match the pairs on the side.",
        values: [
            TP1DataValue(id: 0, text: "100",       type: .int),
            TP1DataValue(id: 1, text: "24.5",      type: .double),
            TP1DataValue(id: 2, text: "“OMEGA”",   type: .string),
            TP1DataValue(id: 3, text: "true",      type: .bool),
        ],
        types: [.double, .int, .bool, .string],
        checkTitle: "Check",
        nextTitle: "Next",
        tryAgainTitle: "Try again",
        wrongFeedback: "Some pairs don’t match. Check the rules and try again."
    )
}

/// Text and numbers for Screen 4 — Variable or Constant.
struct TP1VariableOrConstantContent {
    let title: String
    let subtitle: String

    // Left column: `var` — free to change.
    let variableKeyword: String          // highlighted word in the explanation
    let variableExplanation: String      // text after the keyword
    let variableName: String
    let variableStart: Int
    let variableGoal: Int                // Leo's note: powerLevel = 100
    let variableRange: ClosedRange<Int>
    let variableSuccess: String
    let taskLabel: String                // "Task:" (Accent, bold)
    let taskText: String                 // what the player must do

    // Right column: `let` — locked.
    let constantKeyword: String
    let constantExplanation: String
    let constantName: String
    let constantValue: Int
    let constantRange: ClosedRange<Int>
    let constantError: String

    let buttonTitle: String

    static let figma = TP1VariableOrConstantContent(
        title: "Variable or Constant",
        subtitle: "Change values to fit with Leo’s notes.",
        variableKeyword: "variable",
        variableExplanation: "is a container that stores a value that can be changed any time.",
        variableName: "powerLevel",
        variableStart: 20,
        variableGoal: 100,
        variableRange: 0...100,
        variableSuccess: "powerLevel is 100 — matches Leo’s notes.",
        taskLabel: "Task:",
        taskText: "Slide powerLevel to 100.",
        constantKeyword: "constant",
        constantExplanation: "is a container that stores a value that  cannot be changed once declared.",
        constantName: "maxVoltage",
        constantValue: 220,
        constantRange: 0...440,
        constantError: "Error: cannot assign to 'maxVoltage', it's a constant.",
        buttonTitle: "Next"
    )
}
