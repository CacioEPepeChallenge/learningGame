//
//  TP3BookshelfViewModel.swift
//  learning_game
//
//  Drives the Touchpoint 3 (Conditionals — the bookshelf & data port) card flow.
//  Same shape as TP4LaptopViewModel / TP1GeneratorViewModel.
//
//  Flow:  lesson (if / else) → P1 → P2 → P3 → P4 → P5 → done
//

import Foundation
import Observation

enum TP3Screen: Int, CaseIterable {
    case lesson
    case puzzle1, puzzle2, puzzle3, puzzle4, puzzle5

    var next: TP3Screen? { TP3Screen(rawValue: rawValue + 1) }
}

@Observable
final class TP3BookshelfViewModel {
    private(set) var currentScreen: TP3Screen?

    var onClose: (() -> Void)?
    var onComplete: (() -> Void)?

    let puzzle1 = TrueFalseViewModel(content: TP3Content.puzzle1)
    let puzzle2 = CodePuzzleViewModel(content: TP3Content.puzzle2)
    let puzzle3 = CodePuzzleViewModel(content: TP3Content.puzzle3)
    let puzzle4 = CodePuzzleViewModel(content: TP3Content.puzzle4)
    let puzzle5 = CodePuzzleViewModel(content: TP3Content.puzzle5)

    private(set) var completed: Set<Int> = []

    init(startAt screen: TP3Screen = .lesson) {
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
        guard let screen = currentScreen else { return false }
        return TP3Screen(rawValue: screen.rawValue - 1) != nil
    }

    func goBack() {
        guard let screen = currentScreen,
              let previous = TP3Screen(rawValue: screen.rawValue - 1) else { return }
        currentScreen = previous
    }

    func close() {
        currentScreen = nil
        onClose?()
    }
}
