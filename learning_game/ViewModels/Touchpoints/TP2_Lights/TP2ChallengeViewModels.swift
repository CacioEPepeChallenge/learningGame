//
//  TP2ChallengeViewModels.swift
//  learning_game
//
//  State for the Touchpoint 2 challenges from Screen 6 on:
//    TP2MatchViewModel       — Screen 6, Read the Array (two-column matcher)
//    TP2TrueFalseViewModel   — Screen 7, True or False
//    TP2CountChoiceViewModel — Screen 8, Add a Light (append + count)
//    TP2FixCodeViewModel     — Screen 9, Fix the Code (enum blanks)
//

import Foundation
import Observation

/// Shared check result: unchecked, correct, or wrong (ids of the wrong items).
enum TP2Result: Equatable {
    case unchecked
    case correct
    case wrong(Set<Int>)

    func isWrong(_ id: Int) -> Bool {
        if case .wrong(let ids) = self { return ids.contains(id) }
        return false
    }
}

// MARK: - Screen 6 — Read the Array

@Observable
final class TP2MatchViewModel {
    let content: TP2ReadArrayContent

    /// left id → right id
    private(set) var pairs: [Int: Int] = [:]
    private(set) var selectedLeft: Int?
    private(set) var selectedRight: Int?
    private(set) var result: TP2Result = .unchecked
    private(set) var checkCount = 0

    init(content: TP2ReadArrayContent) { self.content = content }

    var allPaired: Bool { pairs.count == content.left.count }
    var hasStarted: Bool { !pairs.isEmpty || selectedLeft != nil || selectedRight != nil }
    var isSolved: Bool { result == .correct }

    func left(pairedWith right: Int) -> Int? { pairs.first { $0.value == right }?.key }

    func tapLeft(_ id: Int) {
        guard !isSolved else { return }
        resetCheck()
        if pairs[id] != nil { pairs[id] = nil; return }
        if let right = selectedRight { pair(id, right) } else { selectedLeft = selectedLeft == id ? nil : id }
    }

    func tapRight(_ id: Int) {
        guard !isSolved else { return }
        resetCheck()
        if let left = left(pairedWith: id) { pairs[left] = nil; return }
        if let left = selectedLeft { pair(left, id) } else { selectedRight = selectedRight == id ? nil : id }
    }

    func check() {
        guard allPaired else { return }
        checkCount += 1
        let wrong = Set(content.left.map(\.id).filter { pairs[$0] != content.answer[$0] })
        result = wrong.isEmpty ? .correct : .wrong(wrong)
    }

    /// Clears only the wrong pairs.
    func retry() {
        if case .wrong(let wrong) = result { wrong.forEach { pairs[$0] = nil } }
        result = .unchecked
    }

    private func pair(_ left: Int, _ right: Int) {
        pairs[left] = right
        selectedLeft = nil
        selectedRight = nil
    }

    private func resetCheck() {
        if case .wrong = result { result = .unchecked }
    }
}

// MARK: - Screen 7 — True or False

@Observable
final class TP2TrueFalseViewModel {
    let content: TP2TrueFalseContent

    private(set) var answer: Bool?
    private(set) var result: TP2Result = .unchecked
    private(set) var answerCount = 0

    init(content: TP2TrueFalseContent) { self.content = content }

    func answer(_ value: Bool) {
        guard result == .unchecked else { return }
        answer = value
        answerCount += 1
        result = value == content.answer ? .correct : .wrong([])
    }

    func retry() {
        answer = nil
        result = .unchecked
    }
}

// MARK: - Screen 8 — Add a Light

@Observable
final class TP2CountChoiceViewModel {
    let content: TP2AppendCountContent

    private(set) var selected: Int?
    private(set) var result: TP2Result = .unchecked
    private(set) var checkCount = 0

    init(content: TP2AppendCountContent) { self.content = content }

    var isSolved: Bool { result == .correct }
    var explanation: String { selected.flatMap { content.explanations[$0] } ?? "" }

    func select(_ option: Int) {
        guard result == .unchecked else { return }
        selected = option
    }

    func check() {
        guard let selected else { return }
        checkCount += 1
        result = selected == content.correct ? .correct : .wrong([selected])
    }

    func retry() {
        selected = nil
        result = .unchecked
    }
}

// MARK: - Screen 9 — Fix the Code

@Observable
final class TP2FixCodeViewModel {
    let content: TP2FixCodeContent

    /// blank id → chip id
    private(set) var filled: [Int: Int] = [:]
    private(set) var result: TP2Result = .unchecked
    private(set) var checkCount = 0

    /// Called once when solved (the desk lamp dims).
    var onSolved: (() -> Void)?

    init(content: TP2FixCodeContent) { self.content = content }

    var allFilled: Bool { filled.count == content.blanks.count }
    var hasStarted: Bool { !filled.isEmpty }
    var isSolved: Bool { result == .correct }

    func chip(_ id: Int) -> TP2FixChip? { content.chips.first { $0.id == id } }
    func chip(inBlank blank: Int) -> TP2FixChip? {
        guard let id = filled[blank] else { return nil }
        return chip(id)
    }
    func isUsed(_ chip: Int) -> Bool { filled.values.contains(chip) }

    /// Swift's message for a wrong blank (shown under the code).
    func error(forBlank blank: Int) -> String? {
        guard result.isWrong(blank),
              let spec = content.blanks.first(where: { $0.id == blank }),
              let chip = filled[blank] else { return nil }
        return spec.errors[chip] ?? spec.genericError
    }

    /// Tap a chip: fill the first empty blank.
    func place(_ chip: Int) {
        guard !isSolved, !isUsed(chip),
              let blank = content.blanks.map(\.id).first(where: { filled[$0] == nil }) else { return }
        resetCheck()
        filled[blank] = chip
    }

    /// Drag a chip onto a blank.
    func place(_ chip: Int, in blank: Int) {
        guard !isSolved else { return }
        resetCheck()
        if let old = filled.first(where: { $0.value == chip })?.key { filled[old] = nil }
        filled[blank] = chip
    }

    func clear(_ blank: Int) {
        guard !isSolved else { return }
        resetCheck()
        filled[blank] = nil
    }

    func check() {
        guard allFilled else { return }
        checkCount += 1
        let wrong = Set(content.blanks.filter { filled[$0.id] != $0.answer }.map(\.id))
        result = wrong.isEmpty ? .correct : .wrong(wrong)
        if wrong.isEmpty { onSolved?() }
    }

    func retry() {
        if case .wrong(let wrong) = result { wrong.forEach { filled[$0] = nil } }
        result = .unchecked
    }

    private func resetCheck() {
        if case .wrong = result { result = .unchecked }
    }
}
