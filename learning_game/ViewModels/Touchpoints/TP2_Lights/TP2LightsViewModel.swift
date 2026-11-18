//
//  TP2LightsViewModel.swift
//  learning_game
//
//  Drives the Touchpoint 2 card flow (Arrays & Enums): which card is on
//  screen, the room's lights, and Next / Back / ×.
//

import Foundation
import Observation

@Observable
final class TP2LightsViewModel {
    /// The card currently shown. `nil` = no card (back to the game).
    private(set) var currentScreen: TP2Screen?

    /// The player tapped × — hide the cards, the touchpoint is NOT done
    /// (game: `GameModel.closeOverlay`).
    var onClose: (() -> Void)?

    /// The player finished the last card — Touchpoint 2 is done
    /// (game: `GameModel.completeOverlay`).
    var onComplete: (() -> Void)?

    // MARK: The room — `var roomLights: [LightState]`

    let lamps = TP2Lamp.room
    private(set) var roomLights: [TP2LightState] = [.off, .off]

    // MARK: Screen 2 — I.R.I.S. dialogue
    let dialogue = TP2DialogueContent.figma
    private(set) var dialogueIndex = 0

    var currentDialogueLine: DialogLine { dialogue.lines[dialogueIndex] }
    var isLastDialogueLine: Bool { dialogueIndex == dialogue.lines.count - 1 }

    /// Tap on the dialogue bar: next line, or on to the first card.
    func nextDialogueLine() {
        if isLastDialogueLine {
            goToNext()
        } else {
            dialogueIndex += 1
        }
    }

    // MARK: Screen 3 — Lighting Schematic
    let lightingSchematic = TP2LightingSchematicContent.figma

    // MARK: Screen 4 — Switch the Lights
    let switchLights = TP2SwitchLightsContent.figma

    /// The lamp the player tapped last (shows `roomLights[i] = …` in the code).
    private(set) var lastChangedIndex: Int?

    var hasTouchedLights: Bool { lastChangedIndex != nil }
    var isSwitchTaskDone: Bool {
        roomLights[switchLights.goalIndex] == switchLights.goalState
    }

    /// Tap on a lamp: `roomLights[index] = <next case>` (off → dim → on → off).
    func cycleLight(at index: Int) {
        guard roomLights.indices.contains(index) else { return }
        roomLights[index] = roomLights[index].next
        lastChangedIndex = index
    }

    /// The whole array as Swift prints it, e.g. `[.on, .off]`.
    var roomLightsCode: String {
        "[" + roomLights.map(\.code).joined(separator: ", ") + "]"
    }

    // MARK: Screen 5 — Reconstruct the Code

    enum CheckResult: Equatable {
        case unchecked
        case correct
        case wrong(Set<Int>)                   // wrong positions in the line
    }

    let reconstruct = TP2ReconstructContent.figma

    /// Block in each answer slot, left to right (nil = empty slot).
    private(set) var slots: [TP2Block.ID?] = Array(repeating: nil, count: TP2ReconstructContent.figma.answer.count)
    private(set) var reconstructResult: CheckResult = .unchecked
    private(set) var reconstructCheckCount = 0

    var isLineFull: Bool { !slots.contains(nil) }
    var hasStartedLine: Bool { slots.contains { $0 != nil } }
    var isReconstructSolved: Bool { reconstructResult == .correct }

    func block(_ id: TP2Block.ID) -> TP2Block? { reconstruct.blocks.first { $0.id == id } }
    func block(inSlot index: Int) -> TP2Block? {
        guard let id = slots[index] else { return nil }
        return block(id)
    }
    func isPlaced(_ id: TP2Block.ID) -> Bool { slots.contains(id) }

    func isWrong(slot index: Int) -> Bool {
        if case .wrong(let wrong) = reconstructResult { return wrong.contains(index) }
        return false
    }

    /// Tap a tray block: drop it into the first empty slot.
    func placeBlock(_ id: TP2Block.ID) {
        guard !isReconstructSolved, !isPlaced(id), let empty = slots.firstIndex(of: nil) else { return }
        resetReconstructCheck()
        slots[empty] = id
    }

    /// Drag a tray block onto a specific slot (replaces what's there).
    func placeBlock(_ id: TP2Block.ID, at index: Int) {
        guard !isReconstructSolved, slots.indices.contains(index) else { return }
        resetReconstructCheck()
        if let old = slots.firstIndex(of: id) { slots[old] = nil }
        slots[index] = id
    }

    /// Tap a filled slot: send the block back to the tray.
    func removeBlock(at index: Int) {
        guard !isReconstructSolved, slots.indices.contains(index) else { return }
        resetReconstructCheck()
        slots[index] = nil
    }

    func checkLine() {
        guard isLineFull else { return }
        reconstructCheckCount += 1
        let wrong = Set(slots.indices.filter { slots[$0] != reconstruct.answer[$0] })
        reconstructResult = wrong.isEmpty ? .correct : .wrong(wrong)
        if wrong.isEmpty {
            roomLights[0] = .on                // the code really runs: the hanging lamp turns on
            lastChangedIndex = 0
        }
    }

    /// Clears only the wrong slots so correct blocks stay in place.
    func retryLine() {
        if case .wrong(let wrong) = reconstructResult {
            for index in wrong { slots[index] = nil }
        }
        reconstructResult = .unchecked
    }

    /// Specific hint when a trap block is in a slot.
    var reconstructWrongMessage: String {
        for id in slots.compactMap({ $0 }) {
            if let hint = reconstruct.trapHints[id] { return hint }
        }
        return reconstruct.wrongFeedback
    }

    private func resetReconstructCheck() {
        if case .wrong = reconstructResult { reconstructResult = .unchecked }
    }

    // MARK: Screens 6–10

    let readArray = TP2MatchViewModel(content: .figma)
    let trueOrFalse = TP2TrueFalseViewModel(content: .figma)
    let appendCount = TP2CountChoiceViewModel(content: .figma)
    let fixCode = TP2FixCodeViewModel(content: .figma)
    let lightsRestored = TP2LightsRestoredContent.figma

    /// Screen 10: the final state of the room — every light on.
    func restoreAllLights() {
        roomLights = roomLights.map { _ in .on }
    }

    init(startAt screen: TP2Screen = .dialogue) {
        currentScreen = screen
        // Screen 9's code really runs: roomLights[1] = .dim
        fixCode.onSolved = { [weak self] in
            self?.roomLights[1] = .dim
            self?.lastChangedIndex = 1
        }
    }

    // MARK: Navigation

    func goToNext() {
        guard let screen = currentScreen else { return }
        currentScreen = screen.next
        if currentScreen == nil { onComplete?() }
    }

    /// Back is offered on every card after the dialogue
    /// (going back to the dialogue replays it from the first line).
    var canGoBack: Bool {
        guard let screen = currentScreen else { return false }
        return TP2Screen(rawValue: screen.rawValue - 1) != nil
    }

    func goBack() {
        guard let screen = currentScreen,
              let previous = TP2Screen(rawValue: screen.rawValue - 1) else { return }
        if previous == .dialogue { dialogueIndex = 0 }
        currentScreen = previous
    }

    /// The × button.
    func close() {
        currentScreen = nil
        onClose?()
    }
}
