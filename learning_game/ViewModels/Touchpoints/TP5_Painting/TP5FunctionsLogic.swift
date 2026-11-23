//
//  TP5FunctionsLogic.swift
//  learning_game
//
//  Touchpoint 5 — Functions. Pure puzzle logic (no UI): each puzzle "runs"
//  the player's program and returns a step-by-step trace plus an outcome,
//  so the view can animate execution line by line and IRIS can explain
//  exactly what went wrong.
//

import Foundation

// MARK: - Puzzle 1 · Define, then call

/// Full code lines the player drags into the program (each can be used once).
enum P1Line: String, CaseIterable, Codable {
    case defOpen = "func disengage() {"
    case rotate  = "rotateDial()"
    case pull    = "pullLever()"
    case close   = "}"
    case call    = "disengage()"
    case bare    = "disengage"        // decoy: names the function, never calls it
    case run     = "run disengage"    // decoy: not Swift
}

enum P1Action: Equatable { case rotate, pull }

struct P1Step: Equatable {
    var line: Int
    var action: P1Action? = nil
    var note: String? = nil
    var stack: [String] = []
}

enum P1Outcome: Equatable {
    case success
    case syntax(String)
    case neverCalled
    case bareName
    case wrongOrder
    case notStored
    case incomplete
    case callBeforeDefinition
    case recursion
    case undefined

    var message: String {
        switch self {
        case .success:
            "Dial turned, lever pulled. Defined once, called once. The first deadbolt is open."
        case .syntax(let why):
            why
        case .neverCalled:
            "Nothing moved. You defined disengage(), but defining only stores the steps. Something has to call it."
        case .bareName:
            "You wrote disengage without (). That only names the function. The () is what calls it."
        case .wrongOrder:
            "The lever jammed. It was pulled before the dial turned, so check the order inside the braces."
        case .notStored:
            "The bolt moved, but those steps ran on their own instead of inside disengage(). Put them between the braces so they're reusable."
        case .incomplete:
            "Only part of the sequence ran. The bolt needs rotateDial() and then pullLever()."
        case .callBeforeDefinition:
            "This console reads top to bottom, and it hasn't seen disengage() yet. Define it first, then call it."
        case .recursion:
            "disengage() calls itself from inside its own body, so it never stops! Move the call outside the braces."
        case .undefined:
            "disengage() is called, but it's never defined. There's no func disengage() { … } anywhere."
        }
    }
}

struct P1Result {
    var steps: [P1Step]
    var outcome: P1Outcome
}

enum P1Engine {
    static let slotCount = 5

    static func run(_ lines: [P1Line]) -> P1Result {
        // 1. Syntax: braces must balance, "run" isn't Swift.
        var depth = 0
        for line in lines {
            switch line {
            case .run:
                return P1Result(steps: [], outcome: .syntax("Swift has no run command. To call a function, write its name followed by ()."))
            case .defOpen:
                depth += 1
            case .close:
                depth -= 1
                if depth < 0 {
                    return P1Result(steps: [], outcome: .syntax("That } doesn't close anything. Every } needs an opening { above it."))
                }
            default:
                break
            }
        }
        if depth != 0 {
            return P1Result(steps: [], outcome: .syntax("The function is missing its closing }."))
        }

        let defIndex = lines.firstIndex(of: .defOpen)
        let closeIndex = defIndex.flatMap { d in lines[(d + 1)...].firstIndex(of: .close) }
        let body: [Int] = {
            guard let d = defIndex, let c = closeIndex else { return [] }
            return Array((d + 1)..<c)
        }()

        if body.contains(where: { lines[$0] == .call }) {
            let d = defIndex!
            let loop = (0..<3).flatMap { _ in body.map { P1Step(line: $0, stack: ["disengage()"]) } }
            return P1Result(steps: [P1Step(line: d, note: "stored")] + loop, outcome: .recursion)
        }

        // 2. Execute top-level code in order.
        var steps: [P1Step] = []
        var mentionedBare = false
        var i = 0
        while i < lines.count {
            if let d = defIndex, let c = closeIndex, i == d {
                steps.append(P1Step(line: d, note: "stored, not run"))
                i = c + 1
                continue
            }
            switch lines[i] {
            case .rotate:
                steps.append(P1Step(line: i, action: .rotate))
            case .pull:
                steps.append(P1Step(line: i, action: .pull))
            case .bare:
                mentionedBare = true
                steps.append(P1Step(line: i, note: "named, not called"))
            case .call:
                guard let d = defIndex, let c = closeIndex else {
                    return P1Result(steps: steps + [P1Step(line: i)], outcome: .undefined)
                }
                if i < d {
                    return P1Result(steps: steps + [P1Step(line: i, note: "unknown")], outcome: .callBeforeDefinition)
                }
                let frame = ["disengage()"]
                steps.append(P1Step(line: i, note: "call", stack: frame))
                for j in body {
                    switch lines[j] {
                    case .rotate: steps.append(P1Step(line: j, action: .rotate, stack: frame))
                    case .pull:   steps.append(P1Step(line: j, action: .pull, stack: frame))
                    case .bare:   steps.append(P1Step(line: j, note: "named, not called", stack: frame))
                    default: break
                    }
                }
                steps.append(P1Step(line: c, note: "return", stack: frame))
            default:
                break
            }
            i += 1
        }

        // 3. Judge what happened.
        let acted = steps.filter { $0.action != nil }
        let actions = acted.compactMap(\.action)
        let outside = acted.filter { $0.stack.isEmpty }.count

        let outcome: P1Outcome
        if actions == [.rotate, .pull] && outside == 0 {
            outcome = .success
        } else if actions.isEmpty {
            if mentionedBare { outcome = .bareName }
            else if defIndex != nil && !lines.contains(.call) { outcome = .neverCalled }
            else { outcome = .incomplete }
        } else if actions.first == .pull {
            outcome = .wrongOrder
        } else if outside > 0 {
            outcome = .notStored
        } else {
            outcome = .incomplete
        }
        return P1Result(steps: steps, outcome: outcome)
    }
}

// MARK: - Puzzle 2 · Trace the calls (predict the output)

enum P2Signal: String, CaseIterable, Codable {
    case flash = "flash"
    case beep  = "beep"
}

struct P2Step: Equatable {
    var line: Int
    var emit: P2Signal? = nil
    var stack: [String] = []
}

enum P2Engine {
    static let code: [String] = [
        "func blink() {",
        "    flash()",
        "}",
        "func signal() {",
        "    blink()",
        "    beep()",
        "}",
        "blink()",
        "signal()",
        "signal()",
    ]
    static let tapeLength = 6

    private enum Statement { case emit(P2Signal), call(String) }
    private struct Function { let close: Int; let body: [(Int, Statement)] }

    private static let functions: [String: Function] = [
        "blink":  Function(close: 2, body: [(1, .emit(.flash))]),
        "signal": Function(close: 6, body: [(4, .call("blink")), (5, .emit(.beep))]),
    ]
    private static let topLevel: [(Int, Statement)] = [(7, .call("blink")), (8, .call("signal")), (9, .call("signal"))]

    static func trace() -> [P2Step] {
        var steps: [P2Step] = []
        func exec(_ statement: Statement, line: Int, stack: [String]) {
            switch statement {
            case .emit(let s):
                steps.append(P2Step(line: line, emit: s, stack: stack))
            case .call(let name):
                guard let fn = functions[name] else { return }
                let frame = stack + ["\(name)()"]
                steps.append(P2Step(line: line, stack: frame))
                for (l, s) in fn.body { exec(s, line: l, stack: frame) }
                steps.append(P2Step(line: fn.close, stack: frame))
            }
        }
        for (line, statement) in topLevel { exec(statement, line: line, stack: []) }
        return steps
    }

    static var expected: [P2Signal] { trace().compactMap(\.emit) }

    /// Per-slot correctness of the player's (gap-free) prediction.
    static func grade(_ prediction: [P2Signal]) -> (marks: [Bool], success: Bool) {
        let exp = expected
        let marks = prediction.indices.map { $0 < exp.count && prediction[$0] == exp[$0] }
        return (marks, prediction == exp)
    }
}

// MARK: - Puzzle 3 · Arguments (the dial)

enum P3Direction: String, CaseIterable, Codable {
    case left  = ".left"
    case right = ".right"
}

enum P3Engine {
    static let combination = [7, 3, 8]
    static let start = 0
    static let maxClicks = 5
    static let positions = 10

    static func apply(_ direction: P3Direction, _ clicks: Int, from position: Int) -> Int {
        switch direction {
        case .right: (position + clicks) % positions
        case .left:  ((position - clicks) % positions + positions) % positions
        }
    }

    /// Dial reading after each call.
    static func readings(_ calls: [(P3Direction, Int)]) -> [Int] {
        var pos = start
        return calls.map { call in
            pos = apply(call.0, call.1, from: pos)
            return pos
        }
    }

    static func message(for readings: [Int]) -> String {
        guard let miss = readings.indices.first(where: { readings[$0] != combination[$0] }) else {
            return "7… 3… 8. Click! Same function, three different arguments. The second deadbolt is open."
        }
        let from = miss == 0 ? start : readings[miss - 1]
        return "Turn \(miss + 1) went from \(from) to \(readings[miss]), but the combination needs \(combination[miss]). Which direction gets there in 5 clicks or fewer?"
    }
}

// MARK: - Puzzle 4 · Return values (nested calls)

enum P4Function: String, CaseIterable, Codable {
    case double   = "double"
    case addThree = "addThree"
    case square   = "square"

    func apply(_ n: Int) -> Int {
        switch self {
        case .double:   n * 2
        case .addThree: n + 3
        case .square:   n * n
        }
    }

    var body: String {
        switch self {
        case .double:   "return n * 2"
        case .addThree: "return n + 3"
        case .square:   "return n * n"
        }
    }
}

enum P4Engine {
    static let input = 4
    static let target = 22

    /// Values after inner, middle, outer (inner runs first).
    static func values(outer: P4Function, middle: P4Function, inner: P4Function) -> [Int] {
        let a = inner.apply(input)
        let b = middle.apply(a)
        let c = outer.apply(b)
        return [a, b, c]
    }

    /// How the expression collapses as each call returns.
    static func collapse(outer: P4Function, middle: P4Function, inner: P4Function) -> [String] {
        let v = values(outer: outer, middle: middle, inner: inner)
        return [
            "\(outer.rawValue)(\(middle.rawValue)(\(inner.rawValue)(\(input))))",
            "\(outer.rawValue)(\(middle.rawValue)(\(v[0])))",
            "\(outer.rawValue)(\(v[1]))",
            "\(v[2])",
        ]
    }

    static func message(outer: P4Function, middle: P4Function, inner: P4Function) -> String {
        let v = values(outer: outer, middle: middle, inner: inner)
        if v[2] == target {
            return "\(input) → \(v[0]) → \(v[1]) → 22. Each return value became the next call's argument. The third deadbolt is open."
        }
        return "The keypad got \(v[2]), not 22. Remember: the innermost call runs first, and its return value is passed outward."
    }
}

// MARK: - Puzzle 5 · Reuse (write it once, call it three times)

enum P5Token: String, CaseIterable, Codable {
    case noParam   = "()"
    case idParam   = "(_ id: Int)"
    case unlatchID = "unlatch(id)"
    case slideID   = "slide(id)"
    case unlatch1  = "unlatch(1)"
    case slide1    = "slide(1)"
    case call1     = "openLatch(1)"
    case call2     = "openLatch(2)"
    case call3     = "openLatch(3)"
    case callID    = "openLatch(id)"

    var isParameter: Bool { self == .noParam || self == .idParam }
    var usesID: Bool { self == .unlatchID || self == .slideID || self == .callID }
    var isCall: Bool { [.call1, .call2, .call3, .callID].contains(self) }

    var callArgument: Int? {
        switch self {
        case .call1: 1
        case .call2: 2
        case .call3: 3
        default: nil
        }
    }
}

enum LatchState: Equatable { case locked, unlatched, open }

enum P5Action: Equatable {
    case unlatch(Int)
    case slide(Int)
}

struct P5Step: Equatable {
    var line: Int
    var action: P5Action? = nil
    var binding: String? = nil
    var stack: [String] = []
    var jammed = false
}

enum P5Outcome: Equatable {
    case success
    case compile(String)
    case jammed(Int)
    case stillLocked([Int], ignoresID: Bool)
    case notReused
    case recursion

    var message: String {
        switch self {
        case .success:
            "Three latches, one function, three calls. That's reuse. The final deadbolt is open!"
        case .compile(let why):
            why
        case .jammed(let n):
            "slide(\(n)) jammed because latch \(n) wasn't unlatched first. Check the order of the steps."
        case .stillLocked(let latches, let ignoresID):
            ignoresID
            ? "Every call opened latch 1 again! The body uses 1 instead of id, so the argument is ignored."
            : "Latch\(latches.count > 1 ? "es" : "") \(latches.map(String.init).joined(separator: " & ")) \(latches.count > 1 ? "are" : "is") still locked. Does every latch get its own call?"
        case .notReused:
            "Everything opened, but latch 1 was done by hand outside the function. Use openLatch for every latch."
        case .recursion:
            "openLatch calls itself from inside its own body, and that never ends. Calls belong below the closing }."
        }
    }
}

struct P5Result {
    var steps: [P5Step]
    var outcome: P5Outcome
    var latches: [LatchState]
}

enum P5Engine {
    // Display lines: 0 header, 1–2 body, 3 "}", 4–6 calls
    static let headerLine = 0
    static let bodyLines = [1, 2]
    static let closeLine = 3
    static let callLines = [4, 5, 6]

    static func run(parameter: P5Token, body: [P5Token], calls: [P5Token]) -> P5Result {
        let locked = [LatchState](repeating: .locked, count: 3)

        if body.contains(where: \.isCall) {
            let loop = (0..<2).flatMap { _ in bodyLines.map { P5Step(line: $0, stack: ["openLatch()"]) } }
            return P5Result(steps: [P5Step(line: callLines[0])] + loop, outcome: .recursion, latches: locked)
        }
        if parameter == .noParam {
            if body.contains(where: \.usesID) {
                return P5Result(steps: [], outcome: .compile("id doesn't exist inside openLatch. Add a parameter so each call can hand it an id."), latches: locked)
            }
            if calls.contains(where: \.isCall) {
                return P5Result(steps: [], outcome: .compile("openLatch() has no parameters, but the calls pass it a number. The header has to accept one."), latches: locked)
            }
        }
        if calls.contains(where: \.usesID) {
            return P5Result(steps: [], outcome: .compile("id only exists inside openLatch. Down here, pass a real number like openLatch(2)."), latches: locked)
        }

        var latches = locked
        var steps: [P5Step] = []
        var handDone = false

        func perform(_ token: P5Token, line: Int, id: Int?, stack: [String]) -> Int? {
            let target = token.usesID ? (id ?? 1) : 1
            switch token {
            case .unlatchID, .unlatch1:
                if latches[target - 1] == .locked { latches[target - 1] = .unlatched }
                steps.append(P5Step(line: line, action: .unlatch(target), stack: stack))
            case .slideID, .slide1:
                if latches[target - 1] == .locked {
                    steps.append(P5Step(line: line, action: .slide(target), stack: stack, jammed: true))
                    return target
                }
                latches[target - 1] = .open
                steps.append(P5Step(line: line, action: .slide(target), stack: stack))
            default:
                break
            }
            return nil
        }

        for (index, call) in calls.enumerated() {
            let line = callLines[index]
            if let arg = call.callArgument {
                let frame = ["openLatch(\(arg))"]
                steps.append(P5Step(line: line, binding: "id = \(arg)", stack: frame))
                for (b, token) in body.enumerated() {
                    if let jam = perform(token, line: bodyLines[b], id: arg, stack: frame) {
                        return P5Result(steps: steps, outcome: .jammed(jam), latches: latches)
                    }
                }
                steps.append(P5Step(line: closeLine, stack: frame))
            } else {
                handDone = true
                if let jam = perform(call, line: line, id: nil, stack: []) {
                    return P5Result(steps: steps, outcome: .jammed(jam), latches: latches)
                }
            }
        }

        let stillLocked = latches.indices.filter { latches[$0] != .open }.map { $0 + 1 }
        let outcome: P5Outcome
        if stillLocked.isEmpty {
            outcome = handDone ? .notReused : .success
        } else {
            let ignoresID = parameter == .idParam && !body.contains(where: \.usesID)
            outcome = .stillLocked(stillLocked, ignoresID: ignoresID)
        }
        return P5Result(steps: steps, outcome: outcome, latches: latches)
    }
}
