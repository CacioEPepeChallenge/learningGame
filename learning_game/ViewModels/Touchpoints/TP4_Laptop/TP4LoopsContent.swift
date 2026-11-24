//
//  TP4LoopsContent.swift
//  learning_game
//
//  Touchpoint 4 — Loops (the laptop / encrypted video logs).
//  All card text, code templates, answers, run animations and "why" messages.
//
//    Lesson  · For in loop        (mockup: "FOR IN LOOP")
//    Puzzle 1 · True or False      for-in fundamentals
//    Puzzle 2 · Correct order      for log in secureFiles { decrypt(log) }
//    Puzzle 3 · Filter the logs    for entry in rawLogs { if entry.isVideo { decrypt(entry) } }
//    Lesson  · While loop
//    Puzzle 4 · Buffer decryption  while progress < 100 { stepDecrypt() }
//    Puzzle 5 · The final log      for log in decryptedLogs { if log.isFinal { isolate(log) } }
//

import Foundation

enum TP4Content {

    // MARK: Lessons

    static let forInLesson = LessonContent(
        title: "For in loop",
        subtitle: "How to repeat actions efficiently?",
        paragraphs: [
            "In programming, **loops** allow the computer to execute a block of code multiple times automatically, saving you from writing the exact same command over and over.",
            "Think of it as doing a repetitive task in everyday life:",
        ],
        bullets: [
            "For every dish in the sink, wash it.",
            "For every page in a book, read it.",
            "For every encrypted log on this drive, decrypt it.",
        ],
        code: """
        let secureLogs = ["Log1",
            "Log2", "Log3"]

        for log in secureLogs {
            decrypt(log)
        }
        """)

    static let whileLesson = LessonContent(
        title: "While loop",
        subtitle: "What if you don't know how many times?",
        paragraphs: [
            "A **for-in** loop walks through a list, one item at a time. A **while** loop is different: it keeps repeating **as long as its condition is true**.",
            "Every pass must change something. If nothing changes, the condition stays true forever and the loop never ends.",
        ],
        bullets: [
            "While the kettle isn't boiling, wait.",
            "While the buffer is under 100%, keep decrypting.",
        ],
        code: """
        var progress = 0

        while progress < 100 {
            stepDecrypt()
            // progress += 25
        }
        """)

    // MARK: Puzzle 1 · True or False

    static let puzzle1 = TrueFalseContent(
        statement: "A for-in loop allows you to run the exact same block of code over every single item in a collection without writing it hundreds of times.",
        answer: true,
        successFeedback: "Correct. One block of code, run once for every item.",
        wrongFeedback: "Not quite. That's exactly what for-in does: write it once, run it for each item.")

    // MARK: Puzzle 2 · Correct order

    private static let whileHint = "while repeats while a condition is true. To walk through every item of a collection, use for … in."

    static var puzzle2: CodePuzzleContent {
        let files = ["Log1", "Log2", "Log3"]
        var run: [RunStep] = []
        for (i, name) in files.enumerated() {
            run.append(.at(1, "log = \"\(name)\"") { $0.items[i].state = .active })
            run.append(.at(2, "decrypt(\(name))") { $0.items[i].state = .done })
        }
        run.append(.at(3, "No items left: loop ends"))

        return CodePuzzleContent(
            title: "Correct order",
            subtitle: "Drag the right block to complete the code.",
            lines: [
                [.code("let secureFiles = [\"Log1\", \"Log2\", \"Log3\"]")],
                [.slot(0), .code("log"), .slot(1), .slot(2), .code("{")],
                [.code("    "), .slot(3)],
                [.code("}")],
            ],
            blocks: ["in", "for", "decrypt(log)", "delete(file)", "while", "secureFiles"],
            answer: ["for", "in", "secureFiles", "decrypt(log)"],
            trayBelow: true,
            stage: PuzzleStage(scene: .monitor, title: "secureFiles",
                               items: files.enumerated().map { StageItem(id: $0, label: $1, icon: "px_file") }),
            run: run,
            successMessage: "3 files, 1 line of code. The loop ran decrypt(log) once for every file.",
            hints: [
                "while": whileHint,
                "delete(file)": "delete(file) would wipe the evidence! And there's no `file` here. The loop variable is `log`.",
            ],
            orderHint: "The shape is always: for item in collection { … }")
    }

    // MARK: Puzzle 3 · Filter the logs

    private static let rawLogs: [(name: String, icon: String, isVideo: Bool, isAudio: Bool)] = [
        ("cam_01.mov", "px_video", true, false),
        ("mic_02.wav", "px_audio", false, true),
        ("cam_03.mov", "px_video", true, false),
        ("tmp_04.dat", "px_corrupt", false, false),
    ]

    private static func filterRun(pickAudio: Bool) -> [RunStep] {
        var run: [RunStep] = []
        for (i, log) in rawLogs.enumerated() {
            let hit = pickAudio ? log.isAudio : log.isVideo
            run.append(.at(0, "entry = \(log.name)") { $0.items[i].state = .active })
            run.append(.at(1, "\(pickAudio ? "isAudio" : "isVideo") → \(hit)") {
                if !hit { $0.items[i].state = .skipped }
            })
            if hit {
                run.append(.at(2, "decrypt(\(log.name))") { $0.items[i].state = pickAudio ? .failed : .done })
            }
        }
        return run
    }

    static var puzzle3: CodePuzzleContent {
        CodePuzzleContent(
            title: "Filter the logs",
            subtitle: "Loop through rawLogs, but only decrypt the video entries.",
            lines: [
                [.slot(0), .code("entry"), .slot(1), .code("rawLogs {")],
                [.code("    "), .slot(2), .slot(3), .code("{")],
                [.code("        "), .slot(4)],
                [.code("    }")],
                [.code("}")],
            ],
            blocks: ["for", "in", "if", "entry.isVideo", "decrypt(entry)", "while", "entry.isAudio", "decrypt(log)"],
            answer: ["for", "in", "if", "entry.isVideo", "decrypt(entry)"],
            stage: PuzzleStage(scene: .monitor, title: "rawLogs",
                               items: rawLogs.enumerated().map { StageItem(id: $0, label: $1.name, icon: $1.icon) }),
            run: filterRun(pickAudio: false),
            successMessage: "2 videos decrypted, the audio and the junk file skipped. The if filters inside the loop.",
            hints: [
                "while": whileHint,
                "decrypt(log)": "There's no `log` in this loop. Here the loop variable is called `entry`.",
                "entry.isAudio": "isAudio picks the audio recording. We're after the videos.",
            ],
            orderHint: "Loop first (for entry in rawLogs), then decide inside it (if … { }).",
            simulate: { slots in
                // Only the condition is wrong: actually run it, so the player sees the audio get decrypted.
                var fixed = slots
                fixed[3] = "entry.isVideo"
                guard slots[3] == "entry.isAudio", fixed == ["for", "in", "if", "entry.isVideo", "decrypt(entry)"] else { return nil }
                return RunOutcome(steps: filterRun(pickAudio: true), success: false,
                                  message: "That decrypted the audio recording and skipped both videos. Check the condition.")
            })
    }

    // MARK: Puzzle 4 · while loop

    static var puzzle4: CodePuzzleContent {
        var run: [RunStep] = []
        for pass in 1...4 {
            let before = (pass - 1) * 25
            run.append(.at(1, "\(before) < 100 → true"))
            run.append(.at(2, "+25%") { $0.progress = pass * 25; $0.counter = "passes: \(pass)" })
        }
        run.append(.at(1, "100 < 100 → false: stop"))

        return CodePuzzleContent(
            title: "Buffer decryption",
            subtitle: "Keep decrypting the buffer until progress reaches 100%.",
            lines: [
                [.code("var progress = 0")],
                [.slot(0), .slot(1), .code("{")],
                [.code("    "), .slot(2), .code("  // +25%")],
                [.code("}")],
            ],
            blocks: ["while", "for", "progress < 100", "progress > 100", "progress == 100", "stepDecrypt()", "decrypt(log)"],
            answer: ["while", "progress < 100", "stepDecrypt()"],
            stage: PuzzleStage(scene: .monitor, title: "Decryption buffer", progress: 0, counter: "passes: 0"),
            run: run,
            successMessage: "4 passes: 25, 50, 75, 100. Then progress < 100 became false, so the loop stopped by itself.",
            hints: [
                "for": "for needs `in` and a collection: for x in list. To repeat until something changes, use while.",
                "decrypt(log)": "decrypt(log) never changes progress, so the loop can't finish.",
            ],
            orderHint: "The shape is: while condition { body }",
            simulate: { slots in
                guard slots[0] == "while" else { return nil }
                let condition = slots[1], body = slots[2]
                switch condition {
                case "progress > 100", "progress == 100":
                    let shown = condition.replacingOccurrences(of: "progress", with: "0")
                    return RunOutcome(steps: [.at(1, "\(shown) → false")], success: false,
                                      message: "The condition was false from the very start (\(shown)), so the loop never ran. Still 0%.")
                case "progress < 100" where body != "stepDecrypt()":
                    var steps: [RunStep] = []
                    for pass in 1...6 {
                        steps.append(.at(1, "0 < 100 → true"))
                        steps.append(.at(2, "progress still 0") { $0.counter = "passes: \(pass)…" })
                    }
                    steps.append(.at(nil, "ABORTED") { $0.counter = "∞ infinite loop" })
                    return RunOutcome(steps: steps, success: false,
                                      message: "Infinite loop! \(body) never changes progress, so 0 < 100 stays true forever. IRIS pulled the plug.")
                default:
                    return nil
                }
            })
    }

    // MARK: Puzzle 5 · The final log

    private static let decryptedLogs = ["Nov 12 · 09:14", "Nov 16 · 22:03", "Nov 19 · 18:40", "Nov 21 · 23:47"]

    private enum P5Twist { case correct, first, delete }

    private static func isolateRun(_ twist: P5Twist) -> [RunStep] {
        var run: [RunStep] = []
        let last = decryptedLogs.count - 1
        for (i, name) in decryptedLogs.enumerated() {
            let hit = twist == .first ? i == 0 : i == last
            run.append(.at(0, "log = \(name)") { $0.items[i].state = .active })
            run.append(.at(1, "\(twist == .first ? "isFirst" : "isFinal") → \(hit)") {
                if !hit { $0.items[i].state = .skipped }
            })
            if hit {
                run.append(.at(2, twist == .delete ? "delete(log) ✗" : "isolate(log) ★") {
                    $0.items[i].state = twist == .delete ? .failed : .picked
                })
            }
        }
        return run
    }

    static var puzzle5: CodePuzzleContent {
        CodePuzzleContent(
            title: "The final log",
            subtitle: "Loop through the decrypted logs and isolate the last recording Leo made.",
            lines: [
                [.slot(0), .code("log"), .slot(1), .slot(2), .code("{")],
                [.code("    "), .slot(3), .slot(4), .code("{")],
                [.code("        "), .slot(5)],
                [.code("    }")],
                [.code("}")],
            ],
            blocks: ["for", "in", "decryptedLogs", "if", "log.isFinal", "isolate(log)",
                     "while", "rawLogs", "log.isFirst", "delete(log)"],
            answer: ["for", "in", "decryptedLogs", "if", "log.isFinal", "isolate(log)"],
            stage: PuzzleStage(scene: .monitor, title: "decryptedLogs",
                               items: decryptedLogs.enumerated().map { StageItem(id: $0, label: $1, icon: "px_video") }),
            run: isolateRun(.correct),
            successMessage: "Found it: Nov 21 at 23:47, the last log Leo ever recorded. Isolated.",
            hints: [
                "while": whileHint,
                "rawLogs": "rawLogs are still encrypted. Loop over decryptedLogs.",
                "log.isFirst": "isFirst finds his first log. We need the last one.",
                "delete(log)": "Don't delete it, isolate it!",
            ],
            orderHint: "Loop through the logs first, then use if inside the loop to pick one.",
            simulate: { slots in
                let answer = ["for", "in", "decryptedLogs", "if", "log.isFinal", "isolate(log)"]
                let diff = slots.indices.filter { slots[$0] != answer[$0] }
                guard diff.count == 1 else { return nil }
                if slots[4] == "log.isFirst" {
                    return RunOutcome(steps: isolateRun(.first), success: false,
                                      message: "That isolated Leo's FIRST log (Nov 12). We need the last one he recorded.")
                }
                if slots[5] == "delete(log)" {
                    return RunOutcome(steps: isolateRun(.delete), success: false,
                                      message: "You deleted the final log! Luckily IRIS keeps a backup. Isolate it, don't delete it.")
                }
                return nil
            })
    }

    // MARK: Transcript (after Puzzle 5)

    enum TranscriptSpeaker { case sensor, leo, iris }

    static let transcript: [(speaker: TranscriptSpeaker, text: String)] = [
        (.sensor, "Target (Leo) is pacing rapidly. Heart rate: 140 BPM."),
        (.leo, "It's not a bug anymore... I can't let it continue any further."),
        (.sensor, "Target forcefully detaches a glowing hardware module from the primary PC tower."),
        (.leo, "I have to hide this. If anyone finds it — [AUDIO CUTS OFF]"),
        (.iris, "...."),
        (.iris, "The audio seems to have cut off from here."),
        (.sensor, "Target moves to the East Wall. Target rips the Painting off the wall. Target inputs 14-digit passcode into the hidden wall safe. Target places module inside. Target flees the room."),
    ]
}
