//
//  FunctionsPuzzleModel.swift
//  learning_game
//
//  Touchpoint 5 — Functions. State for the painting-safe puzzle:
//  intro → True/False interrogation → drag-and-drop assembly → success.
//

import SwiftUI
import CoreTransferable
import UniformTypeIdentifiers

// MARK: - Code blocks

/// A syntax block the player can drag from the bank into the code editor.
enum CodeToken: String, CaseIterable, Identifiable, Codable {
    case funcKeyword = "func"
    case varKeyword = "var"
    case unlockSafe = "unlockSafe()"
    case executeBypassSequence = "executeBypassSequence()"

    var id: String { rawValue }
}

/// What travels during a drag: the token, plus the slot it came from
/// (nil when it was pulled fresh from the bank), so slot-to-slot moves can swap.
struct BlockPayload: Codable, Transferable {
    let token: CodeToken
    let sourceSlot: Int?

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .json)
    }
}

// MARK: - Model

@Observable
final class FunctionsPuzzleModel {

    enum Phase: Equatable {
        case intro
        case interrogation
        case assembly
        case success
    }

    enum Verdict: Equatable {
        case none
        case wrongAnswer          // checked "False" in the interrogation
        case syntaxError          // executed an incorrect assembly
    }

    /// Correct order:
    /// 1: func unlockSafe() {
    /// 2:     executeBypassSequence()
    /// 3: }
    /// 4: unlockSafe()
    static let solution: [CodeToken] = [.funcKeyword, .unlockSafe, .executeBypassSequence, .unlockSafe]

    var phase: Phase = .intro
    var verdict: Verdict = .none

    /// The answer card the player has picked but not yet checked.
    var selectedAnswer: Bool?

    var slots: [CodeToken?] = Array(repeating: nil, count: FunctionsPuzzleModel.solution.count)
    /// Slots flagged wrong after a failed Execute; cleared as soon as they change.
    var wrongSlots: Set<Int> = []
    /// Tap-to-place alternative to dragging.
    var selectedToken: CodeToken?
    /// The slot that just received a block, for the snap flash.
    var lastSnapped: Int?

    /// Bumped to drive haptics / shake animations from the view.
    var successPulse = 0
    var errorPulse = 0
    var snapPulse = 0

    var allSlotsFilled: Bool { slots.allSatisfy { $0 != nil } }

    // MARK: Intro

    func begin() {
        phase = .interrogation
    }

    // MARK: Interrogation

    func select(answer: Bool) {
        selectedAnswer = answer
        if verdict == .wrongAnswer { verdict = .none }
    }

    func checkAnswer() {
        guard let answer = selectedAnswer else { return }
        if answer {
            verdict = .none
            successPulse += 1
            phase = .assembly
        } else {
            verdict = .wrongAnswer
            errorPulse += 1
        }
    }

    // MARK: Assembly

    /// Drop `payload` into `slot`. A block dragged from another slot swaps places
    /// with whatever was there; a block from the bank is a fresh copy.
    func drop(_ payload: BlockPayload, into slot: Int) {
        guard slots.indices.contains(slot) else { return }
        if let source = payload.sourceSlot, slots.indices.contains(source) {
            guard source != slot else { return }
            slots[source] = slots[slot]
            wrongSlots.remove(source)
        }
        slots[slot] = payload.token
        wrongSlots.remove(slot)
        selectedToken = nil
        lastSnapped = slot
        snapPulse += 1
        if verdict == .syntaxError, wrongSlots.isEmpty { verdict = .none }
    }

    /// Dropping a placed block back on the bank removes it from the editor.
    func returnToBank(_ payload: BlockPayload) {
        guard let source = payload.sourceSlot else { return }
        clear(slot: source)
    }

    func tapSlot(_ slot: Int) {
        if let token = selectedToken {
            drop(BlockPayload(token: token, sourceSlot: nil), into: slot)
        } else {
            clear(slot: slot)
        }
    }

    func clear(slot: Int) {
        guard slots.indices.contains(slot) else { return }
        slots[slot] = nil
        wrongSlots.remove(slot)
    }

    func toggleSelection(_ token: CodeToken) {
        selectedToken = (selectedToken == token) ? nil : token
    }

    func execute() {
        guard allSlotsFilled else { return }
        let wrong = Set(slots.indices.filter { slots[$0] != Self.solution[$0] })
        if wrong.isEmpty {
            verdict = .none
            wrongSlots = []
            successPulse += 1
            phase = .success
        } else {
            wrongSlots = wrong
            verdict = .syntaxError
            errorPulse += 1
        }
    }
}
