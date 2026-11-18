//
//  TP1BoolSwitchViewModel.swift
//  learning_game
//
//  State for Screen 13 "Boolean Switch" (Leo's note ③: coolingPump = true).
//  Drag a value into `var coolingPump: Bool = [____]`:
//    "true" (String) / 1 (Int) → compiler error (type safety again)
//    false (Bool)              → compiles, but the pump stays OFF
//    true  (Bool)              → the switch flips ON
//  After solving, tapping the switch runs `coolingPump.toggle()`.
//

import Foundation
import Observation

@Observable
final class TP1BoolSwitchViewModel {
    enum Result: Equatable { case unchecked, correct, wrong }

    let content: TP1BoolSwitchContent

    private(set) var placed: TP1BoolChoice.ID?
    private(set) var result: Result = .unchecked
    private(set) var checkCount = 0
    /// The pump / switch state shown in the picture box.
    private(set) var isPumpOn = false
    /// How many times the player used `.toggle()` after solving.
    private(set) var toggleCount = 0

    var onSolved: (() -> Void)?

    init(content: TP1BoolSwitchContent) { self.content = content }

    var placedChoice: TP1BoolChoice? { content.choices.first { $0.id == placed } }
    var isSolved: Bool { result == .correct }
    /// Next is only allowed with the pump ON (Leo's note).
    var canContinue: Bool { isSolved && isPumpOn }

    /// Swift's message for a non-Bool value, nil if it compiles.
    var compilerError: String? {
        guard result == .wrong, let choice = placedChoice, choice.type != .bool else { return nil }
        return TP1TypeSafetyContent.compilerError(value: choice.type, declared: .bool)
    }

    // MARK: Actions

    func place(_ id: TP1BoolChoice.ID) {
        guard !isSolved else { return }
        if result == .wrong { result = .unchecked }
        placed = id
    }

    func clear() {
        guard !isSolved else { return }
        if result == .wrong { result = .unchecked }
        placed = nil
    }

    func check() {
        guard let choice = placedChoice else { return }
        checkCount += 1
        if choice.type == .bool && choice.turnsOn {
            result = .correct
            isPumpOn = true
            onSolved?()
        } else {
            result = .wrong
        }
    }

    func retry() {
        placed = nil
        result = .unchecked
    }

    /// `coolingPump.toggle()` — only after the challenge is solved.
    func toggle() {
        guard isSolved else { return }
        isPumpOn.toggle()
        toggleCount += 1
    }
}
