//
//  CodePuzzleKit.swift
//  learning_game
//
//  Shared, content-driven state for the "Predict → Run → Explain" cards used by
//  Touchpoint 3 and Touchpoint 4 (same shape as TP1's block puzzle):
//
//    • LessonContent        — intro card text + example code
//    • TrueFalseViewModel   — "True or False" card
//    • CodePuzzleViewModel  — drag blocks into a multi-line code box, press Check,
//                             watch the code RUN on the stage, then read WHY.
//

import Foundation
import Observation
import CoreTransferable
import UniformTypeIdentifiers

// MARK: - Lesson

struct LessonContent {
    let title: String
    let subtitle: String
    /// Supports **bold** markdown.
    let paragraphs: [String]
    var bullets: [String] = []
    let code: String
    var buttonTitle = "Next"
}

// MARK: - True / False

struct TrueFalseContent {
    var title = "True or False"
    var subtitle = "Definition"
    let statement: String
    let answer: Bool
    let successFeedback: String
    let wrongFeedback: String
}

@Observable
final class TrueFalseViewModel {
    enum Result: Equatable { case unanswered, correct, wrong }

    let content: TrueFalseContent
    private(set) var result: Result = .unanswered
    private(set) var answerCount = 0
    var onSolved: (() -> Void)?

    init(content: TrueFalseContent) { self.content = content }

    var isSolved: Bool { result == .correct }

    func answer(_ value: Bool) {
        guard result == .unanswered else { return }
        answerCount += 1
        result = value == content.answer ? .correct : .wrong
        if result == .correct { onSolved?() }
    }

    func retry() { result = .unanswered }
}

// MARK: - Code puzzle content

enum CodeSegment: Hashable {
    case code(String)
    case slot(Int)
}

enum StageItemState: Equatable { case idle, active, done, skipped, failed, picked }

struct StageItem: Identifiable, Equatable {
    let id: Int
    var label: String
    /// Pixel sprite name (PixelSprites / Sprites.xcassets).
    var icon: String
    var state: StageItemState = .idle
}

/// Which room object the stage box shows the items on.
enum StageScene: Equatable {
    /// Plain list.
    case list
    /// Leo's PC: the items are files on its screen (Touchpoint 4).
    case monitor
    /// Leo's bookshelf: the items sit on its shelves (Touchpoint 3).
    case bookshelf
}

/// What the left "stage" box shows: the room object the code acts on, with
/// its items (logs, books…), an optional progress bar and a counter line.
struct PuzzleStage: Equatable {
    var scene: StageScene = .list
    var title: String
    var items: [StageItem] = []
    var progress: Int? = nil
    var counter: String? = nil
}

/// One frame of the run animation: highlight a code line, show a note,
/// and change the stage.
struct RunStep {
    var line: Int?
    var note: String?
    var change: (inout PuzzleStage) -> Void

    static func at(_ line: Int?, _ note: String? = nil,
                   _ change: @escaping (inout PuzzleStage) -> Void = { _ in }) -> RunStep {
        RunStep(line: line, note: note, change: change)
    }
}

struct RunOutcome {
    var steps: [RunStep]
    var success: Bool
    var message: String
    var wrongSlots: Set<Int> = []
}

struct CodePuzzleContent {
    var title: String
    var subtitle: String
    var lines: [[CodeSegment]]
    /// Tray blocks (unique).
    var blocks: [String]
    /// Correct block for each slot.
    var answer: [String]
    /// Blocks can be used more than once.
    var reusable = false
    /// Figma "Correct order" layout (tray under the code) vs "Fix the function" (tray on the right).
    var trayBelow = false
    var stage: PuzzleStage
    /// Run animation for the correct answer.
    var run: [RunStep]
    var successMessage: String
    /// Explanation for a specific wrong block.
    var hints: [String: String] = [:]
    var orderHint = "All the right pieces, wrong places. Read the code from left to right."
    /// Optional simulation for interesting wrong answers (e.g. a loop that never ends).
    var simulate: (([String]) -> RunOutcome?)? = nil

    func evaluate(_ slots: [String]) -> RunOutcome {
        if slots == answer {
            return RunOutcome(steps: run, success: true, message: successMessage)
        }
        let wrong = Set(slots.indices.filter { slots[$0] != answer[$0] })
        if var simulated = simulate?(slots) {
            simulated.wrongSlots = wrong
            return simulated
        }
        let hinted = wrong.sorted().compactMap { hints[slots[$0]] }.first
        return RunOutcome(steps: [], success: false, message: hinted ?? orderHint, wrongSlots: wrong)
    }
}

// MARK: - Drag payload

struct CodeBlockDragItem: Codable, Transferable {
    let block: String
    let fromSlot: Int?

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .json)
    }
}

// MARK: - Code puzzle state

@Observable
final class CodePuzzleViewModel {
    enum Phase: Equatable {
        case editing, running, solved(String), failed(String)
    }

    let content: CodePuzzleContent
    private(set) var slots: [String?]
    private(set) var phase: Phase = .editing
    private(set) var activeLine: Int?
    private(set) var note: String?
    private(set) var stage: PuzzleStage
    private(set) var wrongSlots: Set<Int> = []
    private(set) var checkCount = 0
    var onSolved: (() -> Void)?

    init(content: CodePuzzleContent) {
        self.content = content
        slots = Array(repeating: nil, count: content.answer.count)
        stage = content.stage
    }

    var allFilled: Bool { !slots.contains(nil) }
    var isSolved: Bool { if case .solved = phase { true } else { false } }
    var canEdit: Bool { phase == .editing }
    var hasStarted: Bool { slots.contains { $0 != nil } }

    func isUsed(_ block: String) -> Bool { !content.reusable && slots.contains(block) }

    /// Tap a tray block: drop it into the first empty slot.
    func place(_ block: String) {
        guard canEdit, !isUsed(block), let empty = slots.firstIndex(of: nil) else { return }
        slots[empty] = block
    }

    /// Drop a block on a slot. Moving a placed block swaps it with the occupant.
    func place(_ block: String, at index: Int, from source: Int?) {
        guard canEdit, slots.indices.contains(index) else { return }
        if let source, slots.indices.contains(source), source != index {
            slots[source] = slots[index]
        } else if !content.reusable, let old = slots.firstIndex(of: block), old != index {
            slots[old] = nil
        }
        slots[index] = block
    }

    func remove(at index: Int) {
        guard canEdit, slots.indices.contains(index) else { return }
        slots[index] = nil
    }

    /// Clears only the wrong slots so the right blocks stay put.
    func retry() {
        for i in wrongSlots { slots[i] = nil }
        wrongSlots = []
        stage = content.stage
        activeLine = nil
        note = nil
        phase = .editing
    }

    @MainActor
    func check() async {
        guard allFilled, canEdit else { return }
        checkCount += 1
        stage = content.stage
        phase = .running
        let outcome = content.evaluate(slots.compactMap { $0 })

        for step in outcome.steps {
            activeLine = step.line
            note = step.note
            step.change(&stage)
            try? await Task.sleep(for: .milliseconds(700))
        }
        if outcome.steps.isEmpty { try? await Task.sleep(for: .milliseconds(250)) }
        activeLine = nil
        note = nil
        wrongSlots = outcome.wrongSlots
        if outcome.success {
            phase = .solved(outcome.message)
            onSolved?()
        } else {
            phase = .failed(outcome.message)
        }
    }
}
