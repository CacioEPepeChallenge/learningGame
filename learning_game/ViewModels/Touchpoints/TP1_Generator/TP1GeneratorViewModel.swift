//
//  TP1GeneratorViewModel.swift
//  learning_game
//
//  Drives the Touchpoint 1 card flow: which card is on screen and what
//  happens when the player taps Start / Next / ×.
//

import Foundation
import Observation

@Observable
final class TP1GeneratorViewModel {
    /// The card currently shown. `nil` = no card (back to the game).
    private(set) var currentScreen: TP1Screen?

    /// The player tapped × — hide the cards, the touchpoint is NOT done
    /// (game: `GameModel.closeOverlay`).
    var onClose: (() -> Void)?

    /// The player finished the last card ("Discover a new clue") — Touchpoint 1
    /// is done (game: `GameModel.completeOverlay`).
    var onComplete: (() -> Void)?

    // MARK: Screen 3 — Generator Core
    let generatorCore = TP1GeneratorCoreContent.figma

    // MARK: Screen 4 — Variable or Constant
    let variableOrConstant = TP1VariableOrConstantContent.figma

    /// `var powerLevel` — the player drags this to Leo's value (100).
    private(set) var powerLevel: Int
    /// Increments every time the player tries to move the `let` slider (drives error feedback).
    private(set) var constantChangeAttempts = 0

    /// Becomes true the first time the player drags the `var` slider (stops the drag hint).
    private(set) var hasTouchedPowerLevel = false

    var isPowerLevelCorrect: Bool { powerLevel == variableOrConstant.variableGoal }
    var hasTriedChangingConstant: Bool { constantChangeAttempts > 0 }

    func setPowerLevel(_ value: Int) {
        hasTouchedPowerLevel = true
        let range = variableOrConstant.variableRange
        powerLevel = min(max(value, range.lowerBound), range.upperBound)
    }

    /// The `let` slider refuses to move — record the attempt so the view shows the compiler error.
    func attemptToChangeConstant() {
        constantChangeAttempts += 1
    }

    // MARK: Screens 5–7 — Data Types matcher

    enum MatchResult: Equatable {
        case unchecked
        case correct
        case wrong(Set<TP1DataValue.ID>)
    }

    let dataTypes = TP1DataTypesContent.figma

    /// value id → the type the player wired it to.
    private(set) var pairs: [TP1DataValue.ID: TP1DataType] = [:]
    private(set) var selectedValue: TP1DataValue.ID?
    private(set) var selectedType: TP1DataType?
    private(set) var matchResult: MatchResult = .unchecked
    /// Increments on each Check (drives haptics / shake).
    private(set) var checkCount = 0

    var allPaired: Bool { pairs.count == dataTypes.values.count }
    var hasStartedMatching: Bool { !pairs.isEmpty || selectedValue != nil || selectedType != nil }

    func value(pairedWith type: TP1DataType) -> TP1DataValue.ID? {
        pairs.first(where: { $0.value == type })?.key
    }

    /// Tap a value chip: select it, or unpair it if it's already wired.
    func tapValue(_ id: TP1DataValue.ID) {
        guard matchResult != .correct else { return }
        resetCheckIfNeeded()
        if pairs[id] != nil {
            pairs[id] = nil
            return
        }
        if let type = selectedType {
            pair(id, type)
        } else {
            selectedValue = (selectedValue == id) ? nil : id
        }
    }

    /// Tap a type chip: select it, or unpair it if it's already wired.
    func tapType(_ type: TP1DataType) {
        guard matchResult != .correct else { return }
        resetCheckIfNeeded()
        if let id = value(pairedWith: type) {
            pairs[id] = nil
            return
        }
        if let id = selectedValue {
            pair(id, type)
        } else {
            selectedType = (selectedType == type) ? nil : type
        }
    }

    func checkPairs() {
        guard allPaired else { return }
        checkCount += 1
        let wrong = Set(dataTypes.values.filter { pairs[$0.id] != $0.type }.map(\.id))
        matchResult = wrong.isEmpty ? .correct : .wrong(wrong)
    }

    /// Clears only the wrong pairs so the player keeps the right ones.
    func retryPairs() {
        if case .wrong(let wrong) = matchResult {
            for id in wrong { pairs[id] = nil }
        }
        matchResult = .unchecked
    }

    private func pair(_ id: TP1DataValue.ID, _ type: TP1DataType) {
        pairs[id] = type
        selectedValue = nil
        selectedType = nil
    }

    private func resetCheckIfNeeded() {
        if case .wrong = matchResult { matchResult = .unchecked }
    }

    // MARK: Leo's manual progress (① ② ③)

    private(set) var completedNotes: Set<TP1LeoNote> = []

    func complete(_ note: TP1LeoNote) {
        completedNotes.insert(note)
    }

    // MARK: Screen 8 — Declaring Variables (note ①)

    let declareVariable = TP1BlockPuzzleViewModel(content: .declareVariable)

    // MARK: Screen 9 — Declaring Constant (let maxVoltage = 220)

    let declareConstant = TP1BlockPuzzleViewModel(content: .declareConstant)

    // MARK: Screen 10 — Type Safety (note ②)

    let typeSafety = TP1TypeSafetyViewModel(content: .figma)

    // MARK: Screens 11–12 — Choose the answer / True or False

    let chooseAnswer = TP1ChoiceViewModel(content: .figma)
    let trueOrFalse = TP1TrueFalseViewModel(content: .figma)

    // MARK: Screen 13 — Boolean Switch (note ③)

    let boolSwitch = TP1BoolSwitchViewModel(content: .figma)

    // MARK: Screens 14–15 — Ignition & Congratulations

    let ignition = TP1IgnitionContent.figma
    let congratulations = TP1CongratulationsContent.figma

    /// Grid power shown on the Ignition card (0…100).
    private(set) var gridPower = 0
    private(set) var isIgnited = false
    private(set) var isPresentOpened = false

    var allNotesDone: Bool { completedNotes.count == TP1LeoNote.allCases.count }

    /// Runs the ignition: grid power counts up to 100, then the generator is online.
    @MainActor
    func ignite() async {
        guard allNotesDone, !isIgnited else { return }
        for value in stride(from: gridPower, through: 100, by: 4) {
            gridPower = value
            try? await Task.sleep(for: .milliseconds(45))
        }
        gridPower = 100
        isIgnited = true
    }

    func openPresent() {
        isPresentOpened = true
    }

    init(startAt screen: TP1Screen = .generatorCore) {
        currentScreen = screen
        powerLevel = TP1VariableOrConstantContent.figma.variableStart
        declareVariable.onSolved = { [weak self] in self?.complete(.powerLevel) }
        typeSafety.onSolved = { [weak self] in self?.complete(.overrideKey) }
        boolSwitch.onSolved = { [weak self] in self?.complete(.coolingPump) }
    }

    /// Advance to the next card (Start / Next buttons).
    func goToNext() {
        guard let screen = currentScreen else { return }
        currentScreen = screen.next
        if currentScreen == nil { onComplete?() }
    }

    /// Is there a card before the current one?
    var canGoBack: Bool {
        guard let screen = currentScreen else { return false }
        return TP1Screen(rawValue: screen.rawValue - 1) != nil
    }

    /// The Back button: show the previous card. Its answers are kept,
    /// so a solved card stays solved.
    func goBack() {
        guard let screen = currentScreen,
              let previous = TP1Screen(rawValue: screen.rawValue - 1) else { return }
        currentScreen = previous
    }

    /// The × button.
    func close() {
        currentScreen = nil
        onClose?()
    }
}
