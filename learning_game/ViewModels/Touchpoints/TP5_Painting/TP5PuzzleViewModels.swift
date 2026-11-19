//
//  TP5PuzzleViewModels.swift
//  learning_game
//
//  State for the five Touchpoint 5 locks. Each one:
//    • holds the player's slots (drag a block in, tap a tray block to fill
//      the next empty slot, tap a filled slot to send it back),
//    • "runs" the program through its engine in TP5FunctionsLogic.swift,
//    • plays the trace back step by step (active line, call stack, stage
//      animation) so the player can watch their code execute.
//

import Foundation
import Observation
import CoreTransferable
import UniformTypeIdentifiers

// MARK: - Shared

enum TP5RunPhase: Equatable {
    case editing
    case running
    case solved(String)
    case failed(String)

    var isRunning: Bool { self == .running }
    var isSolved: Bool { if case .solved = self { true } else { false } }
    var isFailed: Bool { if case .failed = self { true } else { false } }
    var canEdit: Bool { self == .editing }
}

/// What travels during a drag: the block's raw value, plus the slot it was
/// dragged out of (nil = from the tray), so slot-to-slot moves can swap.
struct TP5DragItem: Codable, Transferable {
    let raw: String
    let fromSlot: Int?

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .json)
    }
}

/// Cycles through a puzzle's hints, one per tap.
struct TP5Hints {
    let lines: [String]
    private(set) var shown: String?
    private var next = 0

    init(_ lines: [String]) { self.lines = lines }

    mutating func reveal() {
        shown = lines[next % lines.count]
        next += 1
    }

    mutating func hide() { shown = nil }
}

private func pause(_ ms: Int) async {
    try? await Task.sleep(for: .milliseconds(ms))
}

// MARK: - Lock 1 · Define, then call

@Observable
final class TP5DefineCallViewModel {
    /// Tray order (shuffled on purpose). Each block can be used once.
    static let tray: [P1Line] = [.call, .pull, .defOpen, .bare, .close, .rotate, .run]

    private(set) var slots: [P1Line?] = Array(repeating: nil, count: P1Engine.slotCount)
    private(set) var phase: TP5RunPhase = .editing
    private(set) var activeLine: Int?
    private(set) var stack: [String] = []
    private(set) var note: String?
    private(set) var runCount = 0
    var hints = TP5Hints([
        "Three jobs: store the steps in a function, keep them in the right order, then call it.",
        "The two steps go between { and }. The call goes on its own line, after the }.",
        "Two blocks are traps. One is missing its (), and the other isn't Swift at all.",
    ])

    // Stage
    private(set) var dialTurns = 0
    private(set) var leverPulled = false
    private(set) var boltOpen = false
    private(set) var jammed = false

    var onSolved: (() -> Void)?

    var allFilled: Bool { !slots.contains(nil) }
    var hasStarted: Bool { slots.contains { $0 != nil } }

    func isPlaced(_ line: P1Line) -> Bool { slots.contains(line) }

    /// Auto-indent: one level inside { … }.
    func indent(at index: Int) -> Int {
        var depth = 0
        for i in 0..<index {
            if slots[i] == .defOpen { depth += 1 }
            if slots[i] == .close { depth = max(0, depth - 1) }
        }
        if slots[index] == .close { depth = max(0, depth - 1) }
        return depth
    }

    func place(_ line: P1Line) {
        guard phase.canEdit, !isPlaced(line), let empty = slots.firstIndex(of: nil) else { return }
        slots[empty] = line
        hints.hide()
    }

    func place(_ line: P1Line, at index: Int) {
        guard phase.canEdit, slots.indices.contains(index) else { return }
        if let old = slots.firstIndex(of: line) {
            slots[old] = slots[index]          // swap with whatever was there
        }
        slots[index] = line
        hints.hide()
    }

    func remove(at index: Int) {
        guard phase.canEdit, slots.indices.contains(index) else { return }
        slots[index] = nil
    }

    func showHint() { hints.reveal() }

    func retry() {
        phase = .editing
        resetStage()
    }

    private func resetStage() {
        dialTurns = 0
        leverPulled = false
        boltOpen = false
        jammed = false
        activeLine = nil
        stack = []
        note = nil
    }

    @MainActor
    func run() async {
        guard allFilled, phase.canEdit else { return }
        runCount += 1
        hints.hide()
        resetStage()
        phase = .running
        let result = P1Engine.run(slots.compactMap { $0 })

        for step in result.steps {
            activeLine = step.line
            stack = step.stack
            note = step.note
            switch step.action {
            case .rotate:
                dialTurns += 1
            case .pull:
                if dialTurns == 0 { jammed = true } else { leverPulled = true }
            case nil:
                break
            }
            await pause(step.action == nil ? 520 : 760)
        }
        await pause(200)
        activeLine = nil
        stack = []
        note = nil

        if result.outcome == .success {
            boltOpen = true
            phase = .solved(result.outcome.message)
            onSolved?()
        } else {
            if result.outcome == .wrongOrder { jammed = true }
            phase = .failed(result.outcome.message)
        }
    }
}

// MARK: - Lock 2 · Trace the calls

@Observable
final class TP5TraceCallsViewModel {
    static let tray: [P2Signal] = P2Signal.allCases

    private(set) var tape: [P2Signal?] = Array(repeating: nil, count: P2Engine.tapeLength)
    private(set) var phase: TP5RunPhase = .editing
    private(set) var activeLine: Int?
    private(set) var stack: [String] = []
    private(set) var runCount = 0
    var hints = TP5Hints([
        "Defining a function doesn't send any signal. Start reading at the first line outside the braces.",
        "blink() sends one flash. signal() runs blink() first, then beep().",
        "There are three calls at the bottom. Finish tracing each one before moving to the next.",
    ])

    // Stage
    private(set) var lampOn = false
    private(set) var beepCount = 0
    private(set) var emitted: [P2Signal] = []
    /// ✓ / ✗ per tape slot, revealed as the program runs.
    private(set) var marks: [Bool?] = Array(repeating: nil, count: P2Engine.tapeLength)

    var onSolved: (() -> Void)?

    var prediction: [P2Signal] { tape.compactMap { $0 } }
    var canRun: Bool { !prediction.isEmpty && phase.canEdit }
    var hasStarted: Bool { !prediction.isEmpty }

    func place(_ signal: P2Signal) {
        guard phase.canEdit, let empty = tape.firstIndex(of: nil) else { return }
        tape[empty] = signal
        hints.hide()
    }

    func place(_ signal: P2Signal, at index: Int, from source: Int?) {
        guard phase.canEdit, tape.indices.contains(index) else { return }
        if let source, tape.indices.contains(source), source != index {
            tape[source] = tape[index]
        }
        tape[index] = signal
        hints.hide()
    }

    func remove(at index: Int) {
        guard phase.canEdit, tape.indices.contains(index) else { return }
        tape[index] = nil
    }

    func showHint() { hints.reveal() }

    func retry() {
        phase = .editing
        marks = Array(repeating: nil, count: P2Engine.tapeLength)
        emitted = []
        lampOn = false
    }

    @MainActor
    func run() async {
        guard canRun else { return }
        runCount += 1
        hints.hide()
        retry()
        phase = .running

        let prediction = prediction
        let filled = tape.indices.filter { tape[$0] != nil }

        for step in P2Engine.trace() {
            activeLine = step.line
            stack = step.stack
            if let signal = step.emit {
                emitted.append(signal)
                let k = emitted.count - 1
                if signal == .flash { lampOn = true } else { beepCount += 1 }
                if k < filled.count { marks[filled[k]] = prediction[k] == signal }
                await pause(620)
                lampOn = false
                await pause(120)
            } else {
                await pause(430)
            }
        }
        // Predicted more signals than the program sent: those extras are wrong.
        for k in emitted.count..<max(filled.count, emitted.count) {
            marks[filled[k]] = false
        }
        activeLine = nil
        stack = []
        await pause(250)

        let expected = P2Engine.expected
        if P2Engine.grade(prediction).success {
            phase = .solved("flash, flash, beep, flash, beep. You followed every call, even the ones hidden inside signal(). Lock 2 is open.")
            onSolved?()
        } else if prediction.count < expected.count, Array(expected.prefix(prediction.count)) == prediction {
            phase = .failed("Right so far, but the program sent \(expected.count) signals and you predicted \(prediction.count). Did you trace both signal() calls?")
        } else if prediction.count > expected.count {
            phase = .failed("You predicted \(prediction.count) signals, but only \(expected.count) were sent. Defining a function doesn't send anything.")
        } else {
            let i = prediction.indices.first { $0 >= expected.count || prediction[$0] != expected[$0] } ?? 0
            phase = .failed("Signal \(i + 1) was \(i < expected.count ? expected[i].rawValue : "nothing"), not \(prediction[i].rawValue). Follow blink() inside signal() step by step.")
        }
    }
}

// MARK: - Lock 3 · Arguments (the dial)

@Observable
final class TP5ArgumentsViewModel {
    static let numbers = Array(1...P3Engine.maxClicks)
    /// Code lines: 0 comment, 1 func header, 2 body, 3 "}", 4–6 calls.
    static let callLine = 4

    private(set) var directions: [P3Direction?] = [nil, nil, nil]
    private(set) var clicks: [Int?] = [nil, nil, nil]
    private(set) var phase: TP5RunPhase = .editing
    private(set) var activeLine: Int?
    private(set) var binding: String?
    private(set) var runCount = 0
    var hints = TP5Hints([
        ".right counts up (0 → 1 → 2…). .left counts down (0 → 9 → 8…).",
        "Reaching 7 from 0 by going right takes 7 clicks, and the gears stop at 5. Try going the other way.",
        "Each turn starts where the last one stopped, not back at 0.",
    ])

    // Stage
    /// Needle angle in degrees (cumulative, so it spins the right way round).
    private(set) var needleAngle: Double = 0
    private(set) var reading = P3Engine.start
    private(set) var results: [Bool?] = [nil, nil, nil]
    /// Where the needle stopped after each call.
    private(set) var landed: [Int?] = [nil, nil, nil]

    var onSolved: (() -> Void)?

    var allFilled: Bool { !directions.contains(nil) && !clicks.contains(nil) }
    var hasStarted: Bool { directions.contains { $0 != nil } || clicks.contains { $0 != nil } }

    func placeDirection(_ d: P3Direction) {
        guard phase.canEdit, let i = directions.firstIndex(of: nil) else { return }
        directions[i] = d
        hints.hide()
    }

    func placeDirection(_ d: P3Direction, at i: Int, from source: Int?) {
        guard phase.canEdit, directions.indices.contains(i) else { return }
        if let source, directions.indices.contains(source), source != i { directions[source] = directions[i] }
        directions[i] = d
        hints.hide()
    }

    func placeClicks(_ n: Int) {
        guard phase.canEdit, let i = clicks.firstIndex(of: nil) else { return }
        clicks[i] = n
        hints.hide()
    }

    func placeClicks(_ n: Int, at i: Int, from source: Int?) {
        guard phase.canEdit, clicks.indices.contains(i) else { return }
        if let source, clicks.indices.contains(source), source != i { clicks[source] = clicks[i] }
        clicks[i] = n
        hints.hide()
    }

    func clearDirection(_ i: Int) { if phase.canEdit { directions[i] = nil } }
    func clearClicks(_ i: Int) { if phase.canEdit { clicks[i] = nil } }

    func showHint() { hints.reveal() }

    func retry() {
        phase = .editing
        results = [nil, nil, nil]
        landed = [nil, nil, nil]
        binding = nil
        needleAngle = 0
        reading = P3Engine.start
    }

    @MainActor
    func run() async {
        guard allFilled, phase.canEdit else { return }
        runCount += 1
        hints.hide()
        retry()
        phase = .running
        await pause(350)

        let calls = zip(directions, clicks).map { ($0!, $1!) }
        let readings = P3Engine.readings(calls)

        for (i, call) in calls.enumerated() {
            activeLine = Self.callLine + i
            binding = "direction = \(call.0.rawValue)   clicks = \(call.1)"
            await pause(650)
            activeLine = 2
            for _ in 0..<call.1 {
                needleAngle += call.0 == .right ? 36 : -36
                reading = P3Engine.apply(call.0, 1, from: reading)
                await pause(230)
            }
            await pause(300)
            landed[i] = reading
            results[i] = reading == P3Engine.combination[i]
            if results[i] == false { break }
            await pause(300)
        }
        activeLine = nil
        await pause(200)

        if readings == P3Engine.combination {
            phase = .solved(P3Engine.message(for: readings))
            onSolved?()
        } else {
            phase = .failed(P3Engine.message(for: readings))
        }
    }
}

// MARK: - Lock 4 · Return values

@Observable
final class TP5ReturnValuesViewModel {
    static let tray: [P4Function] = P4Function.allCases
    /// Code lines: 0–2 function definitions, 3 comment, 4 `let key = …`.
    static let expressionLine = 4

    /// Display order: outer, middle, inner (inner sits next to the 4).
    private(set) var slots: [P4Function?] = [nil, nil, nil]
    private(set) var phase: TP5RunPhase = .editing
    private(set) var activeLine: Int?
    /// The expression as it collapses, e.g. "double(11)".
    private(set) var expression: String?
    private(set) var runCount = 0
    var hints = TP5Hints([
        "Read it inside-out. The slot right next to (4) runs first.",
        "Work backwards: 22 = 11 × 2, and 11 = 8 + 3. Where could the 8 come from?",
        "There's more than one answer. Try square in the inner slot and see what you get.",
    ])

    // Stage
    /// Which machine is working: 0 inner, 1 middle, 2 outer.
    private(set) var activeMachine: Int?
    private(set) var orbValue = P4Engine.input
    /// 0 = at the input, 1…3 = after each machine.
    private(set) var orbPosition = 0
    private(set) var keypad: Int?

    var onSolved: (() -> Void)?

    var allFilled: Bool { !slots.contains(nil) }
    var hasStarted: Bool { slots.contains { $0 != nil } }

    /// Machines in the order the value flows through them (inner → outer).
    var pipeline: [P4Function?] { [slots[2], slots[1], slots[0]] }

    func place(_ f: P4Function) {
        guard phase.canEdit else { return }
        // Fill inside-out: the inner slot first, like the evaluation order.
        guard let i = [2, 1, 0].first(where: { slots[$0] == nil }) else { return }
        slots[i] = f
        hints.hide()
    }

    func place(_ f: P4Function, at i: Int, from source: Int?) {
        guard phase.canEdit, slots.indices.contains(i) else { return }
        if let source, slots.indices.contains(source), source != i { slots[source] = slots[i] }
        slots[i] = f
        hints.hide()
    }

    func remove(at i: Int) { if phase.canEdit { slots[i] = nil } }

    func showHint() { hints.reveal() }

    func retry() {
        phase = .editing
        expression = nil
        activeMachine = nil
        orbValue = P4Engine.input
        orbPosition = 0
        keypad = nil
    }

    static func definitionLine(of f: P4Function) -> Int {
        P4Function.allCases.firstIndex(of: f) ?? 0
    }

    @MainActor
    func run() async {
        guard allFilled, phase.canEdit, let outer = slots[0], let middle = slots[1], let inner = slots[2] else { return }
        runCount += 1
        hints.hide()
        retry()
        phase = .running

        let values = P4Engine.values(outer: outer, middle: middle, inner: inner)
        let collapse = P4Engine.collapse(outer: outer, middle: middle, inner: inner)

        activeLine = Self.expressionLine
        expression = collapse[0]
        await pause(800)

        for (k, f) in [inner, middle, outer].enumerated() {
            activeMachine = k
            activeLine = Self.definitionLine(of: f)
            await pause(650)
            orbValue = values[k]
            orbPosition = k + 1
            activeLine = Self.expressionLine
            expression = collapse[k + 1]
            await pause(750)
        }
        activeMachine = nil
        keypad = values[2]
        activeLine = nil
        await pause(300)

        let message = P4Engine.message(outer: outer, middle: middle, inner: inner)
        if values[2] == P4Engine.target {
            phase = .solved(message)
            onSolved?()
        } else {
            phase = .failed(message)
        }
    }
}

// MARK: - Lock 5 · Reuse

@Observable
final class TP5ReuseViewModel {
    static let tray: [P5Token] = P5Token.allCases
    /// Slot ids: 0 parameter, 1–2 body, 3–5 calls.
    static let parameterSlot = 0
    static let bodySlots = [1, 2]
    static let callSlots = [3, 4, 5]

    private(set) var slots: [P5Token?] = Array(repeating: nil, count: 6)
    private(set) var phase: TP5RunPhase = .editing
    private(set) var activeLine: Int?
    private(set) var stack: [String] = []
    private(set) var binding: String?
    private(set) var runCount = 0
    var hints = TP5Hints([
        "Leo's old code did unlatch then slide for latch 1, 2 and 3. Only the number changed.",
        "That changing number should be the parameter id, and the body should use it.",
        "The calls go below the }, one for each latch, each with its own number.",
    ])

    // Stage
    private(set) var latches: [LatchState] = [.locked, .locked, .locked]
    private(set) var activeLatch: Int?
    private(set) var jammedLatch: Int?

    var onSolved: (() -> Void)?

    var allFilled: Bool { !slots.contains(nil) }
    var hasStarted: Bool { slots.contains { $0 != nil } }

    func accepts(_ token: P5Token, slot: Int) -> Bool {
        slot == Self.parameterSlot ? token.isParameter : !token.isParameter
    }

    func place(_ token: P5Token) {
        guard phase.canEdit,
              let i = slots.indices.first(where: { slots[$0] == nil && accepts(token, slot: $0) }) else { return }
        slots[i] = token
        hints.hide()
    }

    @discardableResult
    func place(_ token: P5Token, at i: Int, from source: Int?) -> Bool {
        guard phase.canEdit, slots.indices.contains(i), accepts(token, slot: i) else { return false }
        if let source, slots.indices.contains(source), source != i {
            let occupant = slots[i]
            slots[source] = occupant.flatMap { accepts($0, slot: source) ? $0 : nil }
        }
        slots[i] = token
        hints.hide()
        return true
    }

    func remove(at i: Int) { if phase.canEdit { slots[i] = nil } }

    func showHint() { hints.reveal() }

    func retry() {
        phase = .editing
        latches = [.locked, .locked, .locked]
        activeLatch = nil
        jammedLatch = nil
        binding = nil
        stack = []
        activeLine = nil
    }

    @MainActor
    func run() async {
        guard allFilled, phase.canEdit, let parameter = slots[0] else { return }
        runCount += 1
        hints.hide()
        retry()
        phase = .running

        let result = P5Engine.run(parameter: parameter,
                                  body: Self.bodySlots.compactMap { slots[$0] },
                                  calls: Self.callSlots.compactMap { slots[$0] })

        if case .compile = result.outcome {
            await pause(250)
            phase = .failed(result.outcome.message)
            return
        }

        for step in result.steps {
            activeLine = step.line
            stack = step.stack
            if let b = step.binding { binding = b }
            switch step.action {
            case .unlatch(let n):
                activeLatch = n
                if latches[n - 1] == .locked { latches[n - 1] = .unlatched }
            case .slide(let n):
                activeLatch = n
                if step.jammed { jammedLatch = n } else { latches[n - 1] = .open }
            case nil:
                break
            }
            await pause(step.action == nil ? 480 : 640)
        }
        activeLine = nil
        activeLatch = nil
        stack = []
        await pause(250)

        if result.outcome == .success {
            phase = .solved(result.outcome.message)
            onSolved?()
        } else {
            phase = .failed(result.outcome.message)
        }
    }
}
