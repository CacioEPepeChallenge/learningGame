//
//  TP1QuizViewModels.swift
//  learning_game
//
//  State for the two "guess the answer" cards:
//    TP1ChoiceViewModel    — Screen 11, Choose the Correct Answer (3 cards).
//    TP1TrueFalseViewModel — Screen 12, True or False.
//

import Foundation
import Observation

enum TP1QuizResult: Equatable { case unanswered, correct, wrong }

// MARK: - Screen 11

@Observable
final class TP1ChoiceViewModel {
    let content: TP1ChoiceContent

    private(set) var selected: TP1ChoiceOption.ID?
    private(set) var result: TP1QuizResult = .unanswered
    private(set) var checkCount = 0

    init(content: TP1ChoiceContent) { self.content = content }

    var selectedOption: TP1ChoiceOption? {
        content.options.first { $0.id == selected }
    }

    func select(_ id: TP1ChoiceOption.ID) {
        guard result == .unanswered else { return }
        selected = id
    }

    func check() {
        guard let selected else { return }
        checkCount += 1
        result = selected == content.correctID ? .correct : .wrong
    }

    func retry() {
        selected = nil
        result = .unanswered
    }
}

// MARK: - Screen 12

@Observable
final class TP1TrueFalseViewModel {
    let content: TP1TrueFalseContent

    private(set) var answer: Bool?
    private(set) var result: TP1QuizResult = .unanswered
    private(set) var answerCount = 0

    init(content: TP1TrueFalseContent) { self.content = content }

    func answer(_ value: Bool) {
        guard result == .unanswered else { return }
        answer = value
        answerCount += 1
        result = value == content.answer ? .correct : .wrong
    }

    func retry() {
        answer = nil
        result = .unanswered
    }
}
