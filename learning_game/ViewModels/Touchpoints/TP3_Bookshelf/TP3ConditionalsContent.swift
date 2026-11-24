//
//  TP3ConditionalsContent.swift
//  learning_game
//
//  Touchpoint 3 — Conditionals (the bookshelf & hidden data port).
//  Leo hid a data port behind the books; the right decisions in code open it.
//
//    Lesson  · If / else
//    Puzzle 1 · True or False      if runs only when its condition is true
//    Puzzle 2 · Correct order      if shelfPower > 50 { openPort() }
//    Puzzle 3 · Pick the book      if … { pullBook() } else { skipBook() }
//    Puzzle 4 · Port light         else if / else chain
//    Puzzle 5 · Both keys          if hasKeycard && portIsLive { downloadFiles() }
//

import Foundation

enum TP3Content {

    static let lesson = LessonContent(
        title: "If / else",
        subtitle: "How does code make decisions?",
        paragraphs: [
            "An **if** statement checks a condition. When the condition is **true**, the code inside its braces runs. When it's **false**, Swift skips it.",
            "Add **else** to say what should happen otherwise, and **else if** to check another case.",
        ],
        bullets: [
            "If the shelf has power, open the port.",
            "If the book is the Atlas, pull it. Else, leave it.",
        ],
        code: """
        let power = 80

        if power > 50 {
            openPort()
        } else {
            wait()
        }
        """)

    // MARK: Puzzle 1

    static let puzzle1 = TrueFalseContent(
        statement: "An if statement runs the code inside its braces only when its condition is true.",
        answer: true,
        successFeedback: "Correct. A false condition skips the block entirely.",
        wrongFeedback: "Not quite. if only runs its block when the condition is true.")

    // MARK: Puzzle 2 · if

    static var puzzle2: CodePuzzleContent {
        CodePuzzleContent(
            title: "Correct order",
            subtitle: "Open the data port only if the shelf has enough power.",
            lines: [
                [.code("let shelfPower = 80")],
                [.slot(0), .slot(1), .code("{")],
                [.code("    "), .slot(2)],
                [.code("}")],
            ],
            blocks: ["if", "shelfPower > 50", "openPort()", "for", "shelfPower < 50", "while"],
            answer: ["if", "shelfPower > 50", "openPort()"],
            trayBelow: true,
            stage: PuzzleStage(scene: .bookshelf, title: "Data port",
                               items: [StageItem(id: 0, label: "hidden port", icon: "px_port")],
                               counter: "shelfPower = 80"),
            run: [
                .at(0, "shelfPower = 80"),
                .at(1, "80 > 50 → true") { $0.items[0].state = .active },
                .at(2, "openPort()") { $0.items[0].state = .done },
            ],
            successMessage: "80 > 50 is true, so the code inside the braces ran and the port opened.",
            hints: [
                "for": "for walks through a collection. To make a yes/no decision, use if.",
                "while": "while would keep calling openPort() forever (80 stays above 50). We only want to check once: if.",
            ],
            orderHint: "The shape is: if condition { code }",
            simulate: { slots in
                guard slots == ["if", "shelfPower < 50", "openPort()"] else { return nil }
                return RunOutcome(steps: [.at(1, "80 < 50 → false") { $0.items[0].state = .skipped }],
                                  success: false,
                                  message: "80 < 50 is false, so Swift skipped the braces and the port stayed shut.")
            })
    }

    // MARK: Puzzle 3 · if / else

    private static func bookRun(swapped: Bool) -> [RunStep] {
        [
            .at(0, "book = Atlas") { $0.items[0].state = .active },
            .at(0, "Atlas == Atlas → true"),
            .at(1, swapped ? "skipBook()" : "pullBook()") { $0.items[0].state = swapped ? .skipped : .picked },
            .at(0, "book = Dune") { $0.items[1].state = .active },
            .at(0, "Dune == Atlas → false"),
            .at(3, swapped ? "pullBook()" : "skipBook()") { $0.items[1].state = swapped ? .failed : .skipped },
        ]
    }

    static var puzzle3: CodePuzzleContent {
        CodePuzzleContent(
            title: "Pick the book",
            subtitle: "Leo's notes say the port hides behind the Atlas. Pull it, leave every other book.",
            lines: [
                [.slot(0), .code("book.title == \"Atlas\" {")],
                [.code("    "), .slot(1)],
                [.code("}"), .slot(2), .code("{")],
                [.code("    "), .slot(3)],
                [.code("}")],
            ],
            blocks: ["if", "else", "pullBook()", "skipBook()", "elif", "while"],
            answer: ["if", "pullBook()", "else", "skipBook()"],
            stage: PuzzleStage(scene: .bookshelf, title: "Bookshelf",
                               items: [StageItem(id: 0, label: "Atlas", icon: "px_book_amber"),
                                       StageItem(id: 1, label: "Dune", icon: "px_book_green")]),
            run: bookRun(swapped: false),
            successMessage: "Atlas → true → pullBook(). Dune → false → the else branch: skipBook(). Exactly one branch runs each time.",
            hints: [
                "elif": "elif is Python. In Swift it's else (or else if).",
                "while": "while repeats. We only want to decide once per book: if.",
            ],
            orderHint: "if comes first; else goes after the closing } of the if.",
            simulate: { slots in
                guard slots == ["if", "skipBook()", "else", "pullBook()"] else { return nil }
                return RunOutcome(steps: bookRun(swapped: true), success: false,
                                  message: "That skipped the Atlas and pulled Dune! The if branch runs when the condition is true.")
            })
    }

    // MARK: Puzzle 4 · else if / else

    static var puzzle4: CodePuzzleContent {
        CodePuzzleContent(
            title: "Port light",
            subtitle: "The port's light is amber: it's mid-handshake. Chain the checks so only one branch runs.",
            lines: [
                [.code("let light = \"amber\"")],
                [.code("if light == \"green\" { connect() }")],
                [.slot(0), .code("light == \"amber\" {"), .slot(1), .code("}")],
                [.slot(2), .code("{ reset() }")],
            ],
            blocks: ["else if", "else", "wait()", "connect()", "if", "elif"],
            answer: ["else if", "wait()", "else"],
            stage: PuzzleStage(scene: .bookshelf, title: "Port light",
                               items: [StageItem(id: 0, label: "green → connect", icon: "px_port"),
                                       StageItem(id: 1, label: "amber → wait", icon: "px_port"),
                                       StageItem(id: 2, label: "other → reset", icon: "px_port")]),
            run: [
                .at(0, "light = \"amber\""),
                .at(1, "green? → false") { $0.items[0].state = .skipped },
                .at(2, "amber? → true") { $0.items[1].state = .active },
                .at(2, "wait()") { $0.items[1].state = .picked },
                .at(3, "skipped: a branch already ran") { $0.items[2].state = .skipped },
            ],
            successMessage: "green was false, amber was true, so wait() ran and the final else was skipped. Only one branch ever runs.",
            hints: [
                "if": "A second plain if is checked on its own, separately from the first one. Chain the checks with else if.",
                "elif": "elif is Python. Swift says else if.",
                "connect()": "connect() while the light is amber would break the handshake. Amber means wait.",
            ],
            orderHint: "The chain reads: if … else if … else …")
    }

    // MARK: Puzzle 5 · &&

    private static func keysRun(or: Bool) -> [RunStep] {
        [
            .at(0, "A: true \(or ? "||" : "&&") true → true") { $0.items[0].state = .active },
            .at(1, "downloadFiles()") { $0.items[0].state = .done },
            .at(0, "B: true \(or ? "||" : "&&") false → \(or)") { $0.items[1].state = or ? .active : .skipped },
        ] + (or ? [.at(1, "downloadFiles() ✗ dead port") { $0.items[1].state = .failed }] : [])
    }

    static var puzzle5: CodePuzzleContent {
        CodePuzzleContent(
            title: "Both keys",
            subtitle: "Download Leo's files only when you have the keycard AND the port is live.",
            lines: [
                [.code("if"), .slot(0), .slot(1), .slot(2), .code("{")],
                [.code("    "), .slot(3)],
                [.code("}")],
            ],
            blocks: ["hasKeycard", "&&", "portIsLive", "downloadFiles()", "||", "!hasKeycard", "deleteFiles()"],
            answer: ["hasKeycard", "&&", "portIsLive", "downloadFiles()"],
            stage: PuzzleStage(scene: .bookshelf, title: "Two test runs",
                               items: [StageItem(id: 0, label: "A: card ✓ port ✓", icon: "px_keycard"),
                                       StageItem(id: 1, label: "B: card ✓ port ✗", icon: "px_keycard")]),
            run: keysRun(or: false),
            successMessage: "&& needs BOTH sides true. Run A downloaded the files; run B safely did nothing.",
            hints: [
                "!hasKeycard": "! flips true to false. !hasKeycard means 'NOT holding the keycard', which is the opposite of what we want.",
                "deleteFiles()": "Whoa, we need those files! Download them, don't delete them.",
            ],
            orderHint: "Read it like a sentence: if A && B { … }",
            simulate: { slots in
                guard slots == ["hasKeycard", "||", "portIsLive", "downloadFiles()"] else { return nil }
                return RunOutcome(steps: keysRun(or: true), success: false,
                                  message: "|| only needs ONE side to be true, so run B downloaded from a dead port and corrupted the files. Both must be true: &&.")
            })
    }
}
