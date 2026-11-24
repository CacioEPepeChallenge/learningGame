//
//  TP5PaintingViewModel.swift
//  learning_game
//
//  Drives the Touchpoint 5 (Functions) card flow: the painting intro, five
//  lesson → lock pairs, and the open safe. Same shape as TP1GeneratorViewModel.
//
//  Flow:
//    intro → lesson 1 → lock 1 (define & call)
//          → lesson 2 → lock 2 (trace nested calls)
//          → lesson 3 → lock 3 (parameters & arguments)
//          → lesson 4 → lock 4 (return values)
//          → lesson 5 → lock 5 (reuse with a parameter)
//          → safe open (painting_safe.gif)
//

import Foundation
import Observation

enum TP5Screen: Int, CaseIterable {
    case intro
    case lesson1, defineCall
    case lesson2, traceCalls
    case lesson3, arguments
    case lesson4, returnValues
    case lesson5, reuse
    case safeOpen

    var next: TP5Screen? { TP5Screen(rawValue: rawValue + 1) }

    /// 1…5 for a lesson or a lock, nil for intro / finale.
    var lockNumber: Int? {
        switch self {
        case .lesson1, .defineCall:   1
        case .lesson2, .traceCalls:   2
        case .lesson3, .arguments:    3
        case .lesson4, .returnValues: 4
        case .lesson5, .reuse:        5
        case .intro, .safeOpen:       nil
        }
    }
}

@Observable
final class TP5PaintingViewModel {
    /// The card on screen. `nil` = no card (back to the game).
    private(set) var currentScreen: TP5Screen?

    /// × tapped — the touchpoint is NOT done (game: `GameModel.closeOverlay`).
    var onClose: (() -> Void)?
    /// Finished the last card — the touchpoint is done (game: `GameModel.completeOverlay`).
    var onComplete: (() -> Void)?

    // MARK: Puzzles

    let defineCall = TP5DefineCallViewModel()
    let traceCalls = TP5TraceCallsViewModel()
    let arguments = TP5ArgumentsViewModel()
    let returnValues = TP5ReturnValuesViewModel()
    let reuse = TP5ReuseViewModel()

    /// Locks opened so far (1…5).
    private(set) var openedLocks: Set<Int> = []

    // MARK: Intro

    /// The player slid the painting aside and found the safe.
    private(set) var isPaintingMoved = false

    func movePainting() { isPaintingMoved = true }

    // MARK: Lessons

    func lesson(for screen: TP5Screen) -> TP5Lesson? {
        switch screen {
        case .lesson1: TP5Lesson.all[0]
        case .lesson2: TP5Lesson.all[1]
        case .lesson3: TP5Lesson.all[2]
        case .lesson4: TP5Lesson.all[3]
        case .lesson5: TP5Lesson.all[4]
        default: nil
        }
    }

    /// `paintingRevealed`: the game already played the painting-reveal animation,
    /// so the intro card starts with the safe uncovered.
    init(startAt screen: TP5Screen = .intro, paintingRevealed: Bool = false) {
        currentScreen = screen
        defineCall.onSolved   = { [weak self] in self?.openedLocks.insert(1) }
        traceCalls.onSolved   = { [weak self] in self?.openedLocks.insert(2) }
        arguments.onSolved    = { [weak self] in self?.openedLocks.insert(3) }
        returnValues.onSolved = { [weak self] in self?.openedLocks.insert(4) }
        reuse.onSolved        = { [weak self] in self?.openedLocks.insert(5) }
        // Starting mid-flow (previews / testing): earlier locks count as open.
        if let lock = screen.lockNumber {
            openedLocks = Set(1..<lock)
        } else if screen == .safeOpen {
            openedLocks = Set(1...5)
        }
        if screen != .intro || paintingRevealed { isPaintingMoved = true }
    }

    func goToNext() {
        guard let screen = currentScreen else { return }
        currentScreen = screen.next
        if currentScreen == nil { onComplete?() }
    }

    var canGoBack: Bool {
        guard let screen = currentScreen else { return false }
        return TP5Screen(rawValue: screen.rawValue - 1) != nil
    }

    /// Previous card. Puzzle answers are kept, so a solved lock stays solved.
    func goBack() {
        guard let screen = currentScreen,
              let previous = TP5Screen(rawValue: screen.rawValue - 1) else { return }
        currentScreen = previous
    }

    func close() {
        currentScreen = nil
        onClose?()
    }
}

// MARK: - Lesson content

/// One step of a lesson's "Watch it run" demo.
struct TP5DemoStep {
    var line: Int
    var note: String? = nil
    var output: String? = nil
    var stack: [String] = []
}

struct TP5Lesson {
    let title: String
    let subtitle: String
    let paragraphs: [String]
    let keyIdea: String
    let code: [String]
    let demo: [TP5DemoStep]

    static let all: [TP5Lesson] = [
        TP5Lesson(
            title: "Defining & calling",
            subtitle: "What actually makes a function run?",
            paragraphs: [
                "A function is a named block of steps. Writing func greet() { … } only stores those steps. Nothing happens yet.",
                "Writing greet() calls it. Swift jumps into the braces, runs each line from top to bottom, then goes back to where it was called.",
            ],
            keyIdea: "Define once → call it as many times as you need.",
            code: [
                "func greet() {",
                "    say(\"Hi Leo\")",
                "}",
                "greet()",
                "greet()",
            ],
            demo: [
                TP5DemoStep(line: 0, note: "Stored. Nothing runs yet."),
                TP5DemoStep(line: 3, note: "Call! Jump into greet()", stack: ["greet()"]),
                TP5DemoStep(line: 1, output: "Hi Leo", stack: ["greet()"]),
                TP5DemoStep(line: 2, note: "Done, back to the caller", stack: ["greet()"]),
                TP5DemoStep(line: 4, note: "Call it again", stack: ["greet()"]),
                TP5DemoStep(line: 1, output: "Hi Leo", stack: ["greet()"]),
                TP5DemoStep(line: 2, note: "Same steps, reused", stack: ["greet()"]),
            ]),
        TP5Lesson(
            title: "Calls inside calls",
            subtitle: "Where does Swift go when a function calls another?",
            paragraphs: [
                "A function's body can call other functions. Swift keeps a call stack: each new call goes on top.",
                "When a body finishes, its call is removed from the stack and Swift carries on right after the line that called it.",
            ],
            keyIdea: "Every call runs the whole body, every time.",
            code: [
                "func stepA() {",
                "    say(\"A\")",
                "}",
                "func stepB() {",
                "    stepA()",
                "    say(\"B\")",
                "}",
                "stepB()",
            ],
            demo: [
                TP5DemoStep(line: 0, note: "stepA stored"),
                TP5DemoStep(line: 3, note: "stepB stored"),
                TP5DemoStep(line: 7, note: "Call stepB()", stack: ["stepB()"]),
                TP5DemoStep(line: 4, note: "stepB calls stepA", stack: ["stepB()", "stepA()"]),
                TP5DemoStep(line: 1, output: "A", stack: ["stepB()", "stepA()"]),
                TP5DemoStep(line: 2, note: "stepA returns to stepB", stack: ["stepB()", "stepA()"]),
                TP5DemoStep(line: 5, output: "B", stack: ["stepB()"]),
                TP5DemoStep(line: 6, note: "stepB returns", stack: ["stepB()"]),
            ]),
        TP5Lesson(
            title: "Parameters",
            subtitle: "How does one function handle different situations?",
            paragraphs: [
                "A parameter is an input the function asks for: func knock(times: Int). The caller passes an argument: knock(times: 3).",
                "Inside the body, times holds whatever value the caller passed, so the same function can do something different each time.",
            ],
            keyIdea: "Same function, different arguments → different results.",
            code: [
                "func knock(times: Int) {",
                "    say(\"knock × \\(times)\")",
                "}",
                "knock(times: 2)",
                "knock(times: 3)",
            ],
            demo: [
                TP5DemoStep(line: 0, note: "Stored, waiting for a times value"),
                TP5DemoStep(line: 3, note: "times = 2", stack: ["knock(times: 2)"]),
                TP5DemoStep(line: 1, output: "knock × 2", stack: ["knock(times: 2)"]),
                TP5DemoStep(line: 4, note: "times = 3", stack: ["knock(times: 3)"]),
                TP5DemoStep(line: 1, output: "knock × 3", stack: ["knock(times: 3)"]),
            ]),
        TP5Lesson(
            title: "Return values",
            subtitle: "How does a function hand a result back?",
            paragraphs: [
                "-> Int means the function gives back an Int with return. You can store that value, or pass it straight into another call.",
                "Nested calls run inside-out: in double(double(3)) the inner call finishes first, and its result becomes the outer call's argument.",
            ],
            keyIdea: "Read nested calls from the inside out.",
            code: [
                "func double(_ n: Int) -> Int {",
                "    return n * 2",
                "}",
                "let x = double(double(3))",
                "say(x)",
            ],
            demo: [
                TP5DemoStep(line: 0, note: "Stored"),
                TP5DemoStep(line: 3, note: "Inner call first: double(3)", stack: ["double(3)"]),
                TP5DemoStep(line: 1, note: "n = 3 → returns 6", stack: ["double(3)"]),
                TP5DemoStep(line: 3, note: "Now the outer one: double(6)", stack: ["double(6)"]),
                TP5DemoStep(line: 1, note: "n = 6 → returns 12", stack: ["double(6)"]),
                TP5DemoStep(line: 3, note: "x = 12"),
                TP5DemoStep(line: 4, output: "12"),
            ]),
        TP5Lesson(
            title: "Don't repeat yourself",
            subtitle: "Why write a function at all?",
            paragraphs: [
                "When you copy the same steps and change only one thing, that one thing should become a parameter.",
                "Write the steps once inside a function, then call it once for each case. Fix a bug in one place and every call gets the fix.",
            ],
            keyIdea: "Repeated code → one function + a parameter.",
            code: [
                "// copy-paste: same steps twice",
                "feed(\"cat\"); brush(\"cat\")",
                "feed(\"dog\"); brush(\"dog\")",
                "// reuse: write it once",
                "func care(_ pet: String) {",
                "    feed(pet); brush(pet)",
                "}",
                "care(\"cat\")",
                "care(\"dog\")",
            ],
            demo: [
                TP5DemoStep(line: 1, note: "Works… but it's repeated", output: "feed cat · brush cat"),
                TP5DemoStep(line: 2, output: "feed dog · brush dog"),
                TP5DemoStep(line: 4, note: "One function, one parameter"),
                TP5DemoStep(line: 7, note: "pet = \"cat\"", stack: ["care(\"cat\")"]),
                TP5DemoStep(line: 5, output: "feed cat · brush cat", stack: ["care(\"cat\")"]),
                TP5DemoStep(line: 8, note: "pet = \"dog\"", stack: ["care(\"dog\")"]),
                TP5DemoStep(line: 5, output: "feed dog · brush dog", stack: ["care(\"dog\")"]),
            ]),
    ]
}
