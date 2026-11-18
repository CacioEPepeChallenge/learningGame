//
//  TP1TypeSafetyViewModel.swift
//  learning_game
//
//  State for Screen 10 "Type Safety": drag a type chip (Int / Double /
//  String / Bool) into each `name: [____] = value` blank. A wrong type shows
//  Swift's real compiler error under that line.
//

import Foundation
import Observation

@Observable
final class TP1TypeSafetyViewModel {
    enum Result: Equatable {
        case unchecked
        case correct
        case wrong(Set<TP1TypedLine.ID>)
    }

    let content: TP1TypeSafetyContent

    /// The type the player put in each line's blank (by line id).
    private(set) var blanks: [TP1TypedLine.ID: TP1DataType] = [:]
    private(set) var result: Result = .unchecked
    private(set) var checkCount = 0

    var onSolved: (() -> Void)?

    init(content: TP1TypeSafetyContent) {
        self.content = content
    }

    var allFilled: Bool { blanks.count == content.lines.count }
    var isSolved: Bool { result == .correct }
    var hasStarted: Bool { !blanks.isEmpty }

    func isUsed(_ type: TP1DataType) -> Bool { blanks.values.contains(type) }

    func isWrong(_ line: TP1TypedLine.ID) -> Bool {
        if case .wrong(let ids) = result { return ids.contains(line) }
        return false
    }

    /// Compiler error for a wrong line, e.g. cannot convert 'String' to 'Int'.
    func compilerError(for line: TP1TypedLine) -> String? {
        guard isWrong(line.id), let chosen = blanks[line.id] else { return nil }
        return TP1TypeSafetyContent.compilerError(value: line.valueType, declared: chosen)
    }

    // MARK: Actions

    /// Tap a chip: fill the first empty blank.
    func place(_ type: TP1DataType) {
        guard !isSolved, !isUsed(type),
              let line = content.lines.first(where: { blanks[$0.id] == nil }) else { return }
        resetCheck()
        blanks[line.id] = type
    }

    /// Drag a chip onto a specific blank (replaces what's there).
    func place(_ type: TP1DataType, in line: TP1TypedLine.ID) {
        guard !isSolved else { return }
        resetCheck()
        if let old = blanks.first(where: { $0.value == type })?.key { blanks[old] = nil }
        blanks[line] = type
    }

    /// Tap a filled blank: send the chip back.
    func clear(_ line: TP1TypedLine.ID) {
        guard !isSolved else { return }
        resetCheck()
        blanks[line] = nil
    }

    func check() {
        guard allFilled else { return }
        checkCount += 1
        let wrong = Set(content.lines.filter { blanks[$0.id] != $0.valueType }.map(\.id))
        result = wrong.isEmpty ? .correct : .wrong(wrong)
        if wrong.isEmpty { onSolved?() }
    }

    /// Clears only the wrong blanks.
    func retry() {
        if case .wrong(let ids) = result {
            for id in ids { blanks[id] = nil }
        }
        result = .unchecked
    }

    private func resetCheck() {
        if case .wrong = result { result = .unchecked }
    }
}
