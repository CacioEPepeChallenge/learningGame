//
//  TP1BlockPuzzleViewModel.swift
//  learning_game
//
//  State for a "put the blocks in the correct order" card (Screens 8 and 9).
//  Tap a block → it drops into the next empty slot. Drag a block → it drops
//  into the slot under the finger. Tap a filled slot → the block goes back.
//

import Foundation
import Observation

@Observable
final class TP1BlockPuzzleViewModel {
    enum Result: Equatable {
        case unchecked
        case correct
        case wrong(Set<Int>)          // wrong slot indexes
    }

    let content: TP1BlockPuzzleContent

    /// Block id in each slot (nil = empty).
    private(set) var slots: [TP1CodeBlock.ID?]
    private(set) var result: Result = .unchecked
    /// Increments on each Check (drives haptics / shake).
    private(set) var checkCount = 0

    /// Called once when the puzzle is solved.
    var onSolved: (() -> Void)?

    init(content: TP1BlockPuzzleContent) {
        self.content = content
        slots = Array(repeating: nil, count: content.answer.count)
    }

    // MARK: Derived state

    var allFilled: Bool { !slots.contains(nil) }
    var isSolved: Bool { result == .correct }
    var hasStarted: Bool { slots.contains { $0 != nil } }

    /// How many slots already hold the right block (drives the power core glow).
    var correctlyPlacedCount: Int {
        zip(slots, content.answer).filter { $0 == $1 }.count
    }

    var progress: Double { Double(correctlyPlacedCount) / Double(content.answer.count) }

    func isPlaced(_ id: TP1CodeBlock.ID) -> Bool { slots.contains(id) }

    func block(inSlot index: Int) -> TP1CodeBlock? {
        guard let id = slots[index] else { return nil }
        return content.blocks.first { $0.id == id }
    }

    func isWrong(slot index: Int) -> Bool {
        if case .wrong(let wrong) = result { return wrong.contains(index) }
        return false
    }

    /// Specific hint if a distractor is in a slot, otherwise the generic message.
    var wrongMessage: String {
        for id in slots.compactMap({ $0 }) {
            if let hint = content.distractorHints[id] { return hint }
        }
        return content.wrongFeedback
    }

    // MARK: Actions

    /// Tap on a tray block: drop it into the first empty slot.
    func place(_ id: TP1CodeBlock.ID) {
        guard !isSolved, !isPlaced(id), let empty = slots.firstIndex(of: nil) else { return }
        resetCheck()
        slots[empty] = id
    }

    /// Drag a tray block onto a slot (replaces whatever is there).
    func place(_ id: TP1CodeBlock.ID, at index: Int) {
        guard !isSolved, slots.indices.contains(index) else { return }
        resetCheck()
        if let old = slots.firstIndex(of: id) { slots[old] = nil }
        slots[index] = id
    }

    /// Tap on a filled slot: send the block back to the tray.
    func removeBlock(at index: Int) {
        guard !isSolved, slots.indices.contains(index) else { return }
        resetCheck()
        slots[index] = nil
    }

    func check() {
        guard allFilled else { return }
        checkCount += 1
        let wrong = Set(slots.indices.filter { slots[$0] != content.answer[$0] })
        result = wrong.isEmpty ? .correct : .wrong(wrong)
        if wrong.isEmpty { onSolved?() }
    }

    /// Clears only the wrong slots so correct blocks stay in place.
    func retry() {
        if case .wrong(let wrong) = result {
            for index in wrong { slots[index] = nil }
        }
        result = .unchecked
    }

    private func resetCheck() {
        if case .wrong = result { result = .unchecked }
    }
}
