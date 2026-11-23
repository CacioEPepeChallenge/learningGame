//
//  TP4LaptopViewModel.swift
//  learning_game
//
//  Drives the Touchpoint 4 (Loops — the laptop) card flow. Same shape as
//  TP1GeneratorViewModel / TP5PaintingViewModel.
//
//  Flow:  lesson (for-in) → P1 → P2 → P3 → lesson (while) → P4 → P5 → DECRYPTING…
//  The in-room dialogue before, and the transcript readout after, are run by
//  GameModel (they happen over the room, not on a card).
//

import Foundation
import Observation

enum TP4Screen: Int, CaseIterable {
    case forInLesson
    case puzzle1, puzzle2, puzzle3
    case whileLesson
    case puzzle4, puzzle5
    case decrypting

    var next: TP4Screen? { TP4Screen(rawValue: rawValue + 1) }
}

@Observable
final class TP4LaptopViewModel {
    private(set) var currentScreen: TP4Screen?

    /// × tapped — the touchpoint is NOT done (game: `GameModel.closeOverlay`).
    var onClose: (() -> Void)?
    /// DECRYPTING… finished — the touchpoint is done (game: `GameModel.completeOverlay`).
    var onComplete: (() -> Void)?

    let puzzle1 = TrueFalseViewModel(content: TP4Content.puzzle1)
    let puzzle2 = CodePuzzleViewModel(content: TP4Content.puzzle2)
    let puzzle3 = CodePuzzleViewModel(content: TP4Content.puzzle3)
    let puzzle4 = CodePuzzleViewModel(content: TP4Content.puzzle4)
    let puzzle5 = CodePuzzleViewModel(content: TP4Content.puzzle5)

    /// Puzzles solved so far (1…5), for the step dots.
    private(set) var completed: Set<Int> = []

    init(startAt screen: TP4Screen = .forInLesson) {
        currentScreen = screen
        puzzle1.onSolved = { [weak self] in self?.completed.insert(1) }
        puzzle2.onSolved = { [weak self] in self?.completed.insert(2) }
        puzzle3.onSolved = { [weak self] in self?.completed.insert(3) }
        puzzle4.onSolved = { [weak self] in self?.completed.insert(4) }
        puzzle5.onSolved = { [weak self] in self?.completed.insert(5) }
    }

    func goToNext() {
        guard let screen = currentScreen else { return }
        currentScreen = screen.next
        if currentScreen == nil { onComplete?() }
    }

    var canGoBack: Bool {
        guard let screen = currentScreen, screen != .decrypting else { return false }
        return TP4Screen(rawValue: screen.rawValue - 1) != nil
    }

    func goBack() {
        guard let screen = currentScreen,
              let previous = TP4Screen(rawValue: screen.rawValue - 1) else { return }
        currentScreen = previous
    }

    func close() {
        currentScreen = nil
        onClose?()
    }
}
