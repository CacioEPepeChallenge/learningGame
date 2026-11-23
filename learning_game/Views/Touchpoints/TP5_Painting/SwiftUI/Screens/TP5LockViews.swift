//
//  TP5LockViews.swift
//  learning_game
//
//  Touchpoint 5 — the five lock cards. Each one: drag blocks into the code,
//  press Run, and watch the program execute line by line (highlighted line,
//  live call stack, animated stage). IRIS explains exactly what went wrong.
//
//    Lock 1 · Define, then call   — order whole lines, avoid two traps
//    Lock 2 · Trace the calls     — predict the output of nested calls
//    Lock 3 · Pass the arguments  — reach 7·3·8 with turn(_:clicks:), max 5 clicks
//    Lock 4 · Return the key      — compose three functions so 4 becomes 22
//    Lock 5 · Write it once       — rewrite repeated code as one function + parameter
//

import SwiftUI

// MARK: - Lock 1 · Define, then call

struct TP5Lock1DefineCallView: View {
    @Bindable var viewModel: TP5PaintingViewModel

    var body: some View {
        let p = viewModel.defineCall
        TP5PuzzleCard(
            title: "Define, then call",
            subtitle: "Store the bolt's steps in disengage(), then make them run.",
            lock: 1, opened: viewModel.openedLocks,
            phase: p.phase, hint: p.hints.shown,
            idleText: "The dial must turn before the lever is pulled. Careful: two blocks are traps.",
            codeWidth: 262,
            canRun: p.allFilled, runCount: p.runCount,
            onRun: { Task { await p.run() } }, onRetry: p.retry, onHint: p.showHint,
            onNext: viewModel.goToNext, onClose: viewModel.close
        ) {
            TP5SafeDoorStage(dialTurns: p.dialTurns, leverPulled: p.leverPulled,
                             boltOpen: p.boltOpen, jammed: p.jammed, opened: viewModel.openedLocks)
        } code: {
            TP5CodeBox(phase: p.phase) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("bolt.swift")
                            .font(GameFont.play(10))
                            .foregroundStyle(GameColor.ashGrey)
                        Spacer()
                        TP5CallStack(frames: p.stack)
                    }
                    .frame(height: 18)

                    ForEach(0..<P1Engine.slotCount, id: \.self) { i in
                        TP5CodeRow(number: i, isActive: p.activeLine == i, height: 23, indent: p.indent(at: i)) {
                            TP5Slot(text: p.slots[i]?.rawValue, slotIndex: i,
                                    minWidth: 140, height: 20, isEnabled: p.phase.canEdit,
                                    onDrop: { item in
                                        guard let line = P1Line(rawValue: item.raw) else { return false }
                                        p.place(line, at: i)
                                        return true
                                    },
                                    onTap: { p.remove(at: i) })
                            if p.activeLine == i, let note = p.note {
                                Text(note)
                                    .font(GameFont.play(9))
                                    .foregroundStyle(GameColor.info)
                                    .lineLimit(1)
                                    .transition(.opacity)
                            }
                        }
                    }
                }
            }
        } tray: {
            TP5Tray(isEnabled: p.phase.canEdit, onReturn: { item in
                if let s = item.fromSlot { p.remove(at: s) }
            }) {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)], spacing: 6) {
                    ForEach(TP5DefineCallViewModel.tray, id: \.self) { line in
                        TP5TrayBlock(text: line.rawValue, isUsed: p.isPlaced(line),
                                     isEnabled: p.phase.canEdit, height: 28) { p.place(line) }
                    }
                }
            }
        }
    }
}

// MARK: - Lock 2 · Trace the calls

struct TP5Lock2TraceCallsView: View {
    @Bindable var viewModel: TP5PaintingViewModel

    var body: some View {
        let p = viewModel.traceCalls
        TP5PuzzleCard(
            title: "Trace the calls",
            subtitle: "Predict every signal this code sends, in order. Then run it.",
            lock: 2, opened: viewModel.openedLocks,
            phase: p.phase, hint: p.hints.shown,
            idleText: "Fill the tape from the left. Leave extra boxes empty if the code sends fewer signals.",
            runningText: "Tracing… watch the call stack grow and shrink.",
            codeWidth: 226,
            canRun: p.canRun, runCount: p.runCount,
            onRun: { Task { await p.run() } }, onRetry: p.retry, onHint: p.showHint,
            onNext: viewModel.goToNext, onClose: viewModel.close
        ) {
            TP5SignalStage(lampOn: p.lampOn, beepCount: p.beepCount, emitted: p.emitted,
                           opened: viewModel.openedLocks)
        } code: {
            TP5CodeBox(phase: p.phase) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(P2Engine.code.indices, id: \.self) { i in
                        TP5CodeRow(number: i, isActive: p.activeLine == i, height: 13) {
                            TP5CodeText(P2Engine.code[i], size: 11)
                        }
                    }
                    Spacer(minLength: 2)
                    TP5CallStack(frames: p.stack)
                        .frame(height: 16)
                }
            }
        } tray: {
            TP5Tray(title: "YOUR PREDICTION", isEnabled: p.phase.canEdit, onReturn: { item in
                if let s = item.fromSlot { p.remove(at: s) }
            }) {
                HStack(spacing: 5) {
                    ForEach(0..<P2Engine.tapeLength, id: \.self) { i in
                        VStack(spacing: 4) {
                            TP5Slot(text: p.tape[i]?.rawValue, slotIndex: i,
                                    status: p.marks[i].map { $0 ? .correct : .wrong } ?? .normal,
                                    minWidth: 42, height: 30, isEnabled: p.phase.canEdit,
                                    onDrop: { item in
                                        guard let s = P2Signal(rawValue: item.raw) else { return false }
                                        p.place(s, at: i, from: item.fromSlot)
                                        return true
                                    },
                                    onTap: { p.remove(at: i) })
                            ZStack {
                                Text("\(i + 1)")
                                    .font(GameFont.play(9))
                                    .foregroundStyle(GameColor.slateGrey)
                                    .opacity(p.marks[i] == nil ? 1 : 0)
                                if let mark = p.marks[i] {
                                    GameFeedbackIcon(isSuccess: mark, size: 12)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .frame(height: 12)
                            .animation(.spring(duration: 0.3, bounce: 0.5), value: p.marks[i])
                        }
                    }
                }
                Text("SIGNALS")
                    .font(GameFont.silkscreen(9))
                    .foregroundStyle(GameColor.ashGrey)
                    .padding(.top, 6)
                HStack(spacing: 8) {
                    ForEach(TP5TraceCallsViewModel.tray, id: \.self) { s in
                        TP5TrayBlock(text: s.rawValue, isEnabled: p.phase.canEdit, height: 34) { p.place(s) }
                    }
                }
                Text("Each block can be used as many times as you like.")
                    .font(GameFont.play(9))
                    .foregroundStyle(GameColor.slateGrey)
            }
        }
    }
}

// MARK: - Lock 3 · Pass the arguments

struct TP5Lock3ArgumentsView: View {
    @Bindable var viewModel: TP5PaintingViewModel

    private let code = [
        "// .right counts up · .left counts down",
        "func turn(_ direction: Direction, clicks: Int) {",
        "    // moves the needle one number per click",
        "}",
    ]

    var body: some View {
        let p = viewModel.arguments
        TP5PuzzleCard(
            title: "Pass the arguments",
            subtitle: "One function, three calls. Pass arguments that dial 7, then 3, then 8.",
            lock: 3, opened: viewModel.openedLocks,
            phase: p.phase, hint: p.hints.shown,
            idleText: "The needle starts at 0. The old gears jam past 5 clicks per turn.",
            runningText: "Turning… each call starts where the last one stopped.",
            codeWidth: 356,
            canRun: p.allFilled, runCount: p.runCount,
            onRun: { Task { await p.run() } }, onRetry: p.retry, onHint: p.showHint,
            onNext: viewModel.goToNext, onClose: viewModel.close
        ) {
            TP5DialStage(needleAngle: p.needleAngle, reading: p.reading, results: p.results)
        } code: {
            TP5CodeBox(phase: p.phase) {
                VStack(alignment: .leading, spacing: 1) {
                    ForEach(code.indices, id: \.self) { i in
                        TP5CodeRow(number: i, isActive: p.activeLine == i, height: 15) {
                            if i == 2, let binding = p.binding {
                                Text("    // \(binding)")
                                    .font(GameFont.play(11, bold: true))
                                    .foregroundStyle(GameColor.accent)
                                    .transition(.opacity)
                            } else {
                                TP5CodeText(code[i], size: 11)
                            }
                        }
                    }
                    ForEach(0..<3, id: \.self) { i in
                        TP5CodeRow(number: 4 + i, isActive: p.activeLine == 4 + i, height: 26) {
                            TP5CodeText("turn(", size: 12)
                            TP5Slot(text: p.directions[i]?.rawValue, slotIndex: i,
                                    minWidth: 52, height: 21, isEnabled: p.phase.canEdit,
                                    accepts: { P3Direction(rawValue: $0.raw) != nil },
                                    onDrop: { item in
                                        guard let d = P3Direction(rawValue: item.raw) else { return false }
                                        p.placeDirection(d, at: i, from: item.fromSlot.flatMap { $0 < 10 ? $0 : nil })
                                        return true
                                    },
                                    onTap: { p.clearDirection(i) })
                            TP5CodeText(", clicks:", size: 12)
                            TP5Slot(text: p.clicks[i].map(String.init), slotIndex: 10 + i,
                                    minWidth: 28, height: 21, isEnabled: p.phase.canEdit,
                                    accepts: { Int($0.raw) != nil },
                                    onDrop: { item in
                                        guard let n = Int(item.raw) else { return false }
                                        p.placeClicks(n, at: i, from: item.fromSlot.flatMap { $0 >= 10 ? $0 - 10 : nil })
                                        return true
                                    },
                                    onTap: { p.clearClicks(i) })
                            TP5CodeText(")", size: 12)
                            if let ok = p.results[i] {
                                HStack(spacing: 3) {
                                    GameFeedbackIcon(isSuccess: ok, size: 12)
                                    Text("→ \(p.landed[i] ?? 0)")
                                        .font(GameFont.play(10, bold: true))
                                        .foregroundStyle(ok ? GameColor.success : GameColor.error)
                                }
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .animation(.spring(duration: 0.3, bounce: 0.4), value: p.results[i])
                    }
                }
            }
        } tray: {
            TP5Tray(title: "ARGUMENTS", isEnabled: p.phase.canEdit, onReturn: { item in
                guard let s = item.fromSlot else { return }
                s >= 10 ? p.clearClicks(s - 10) : p.clearDirection(s)
            }) {
                Text("direction")
                    .font(GameFont.play(10))
                    .foregroundStyle(GameColor.lightGrey)
                HStack(spacing: 6) {
                    ForEach(P3Direction.allCases, id: \.self) { d in
                        TP5TrayBlock(text: d.rawValue, isEnabled: p.phase.canEdit, height: 32) { p.placeDirection(d) }
                    }
                }
                Text("clicks (max 5)")
                    .font(GameFont.play(10))
                    .foregroundStyle(GameColor.lightGrey)
                    .padding(.top, 4)
                HStack(spacing: 4) {
                    ForEach(TP5ArgumentsViewModel.numbers, id: \.self) { n in
                        TP5TrayBlock(text: "\(n)", isEnabled: p.phase.canEdit, height: 32) { p.placeClicks(n) }
                    }
                }
            }
        }
    }
}

// MARK: - Lock 4 · Return the key

struct TP5Lock4ReturnValuesView: View {
    @Bindable var viewModel: TP5PaintingViewModel

    var body: some View {
        let p = viewModel.returnValues
        TP5PuzzleCard(
            title: "Return the key",
            subtitle: "Chain the functions so their return values turn 4 into 22.",
            lock: 4, opened: viewModel.openedLocks,
            phase: p.phase, hint: p.hints.shown,
            idleText: "Each function returns a number, and that number is passed to the next call out.",
            runningText: "Evaluating inside-out… watch the value travel.",
            codeWidth: 366,
            canRun: p.allFilled, runCount: p.runCount,
            onRun: { Task { await p.run() } }, onRetry: p.retry, onHint: p.showHint,
            onNext: viewModel.goToNext, onClose: viewModel.close
        ) {
            TP5MachineStage(pipeline: p.pipeline, activeMachine: p.activeMachine,
                            orbValue: p.orbValue, orbPosition: p.orbPosition, keypad: p.keypad)
        } code: {
            TP5CodeBox(phase: p.phase) {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(P4Function.allCases, id: \.self) { f in
                        let i = TP5ReturnValuesViewModel.definitionLine(of: f)
                        TP5CodeRow(number: i, isActive: p.activeLine == i, height: 16) {
                            TP5CodeText("func \(f.rawValue)(_ n: Int) -> Int { \(f.body) }", size: 11)
                        }
                    }
                    TP5CodeRow(number: 3, isActive: false, height: 16) {
                        TP5CodeText("// the keypad needs 22", size: 11)
                    }
                    TP5CodeRow(number: 4, isActive: p.activeLine == 4, height: 30) {
                        TP5CodeText("let key =", size: 12)
                        HStack(spacing: 1) {
                            slot(0, p)
                            TP5CodeText("(", size: 12)
                            slot(1, p)
                            TP5CodeText("(", size: 12)
                            slot(2, p)
                            TP5CodeText("(4)))", size: 12)
                        }
                    }

                    Spacer(minLength: 2)

                    HStack(spacing: 6) {
                        Text("EVAL")
                            .font(GameFont.silkscreen(8))
                            .foregroundStyle(GameColor.ashGrey)
                        Text(p.expression ?? "press Run to evaluate")
                            .font(GameFont.play(12, bold: p.expression != nil))
                            .foregroundStyle(p.expression == nil ? GameColor.slateGrey : GameColor.accent)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .id(p.expression)
                            .transition(.push(from: .bottom))
                    }
                    .frame(height: 22)
                    .padding(.horizontal, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 3).fill(GameColor.midnight.opacity(0.45)))
                    .animation(.snappy(duration: 0.3), value: p.expression)
                }
            }
        } tray: {
            TP5Tray(title: "FUNCTIONS", isEnabled: p.phase.canEdit, onReturn: { item in
                if let s = item.fromSlot { p.remove(at: s) }
            }) {
                ForEach(TP5ReturnValuesViewModel.tray, id: \.self) { f in
                    TP5TrayBlock(text: f.rawValue, isEnabled: p.phase.canEdit, height: 30) { p.place(f) }
                }
                Text("Reusable. The slot next to (4) runs first.")
                    .font(GameFont.play(9))
                    .foregroundStyle(GameColor.slateGrey)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func slot(_ i: Int, _ p: TP5ReturnValuesViewModel) -> some View {
        TP5Slot(text: p.slots[i]?.rawValue, slotIndex: i,
                minWidth: 58, height: 22, isEnabled: p.phase.canEdit,
                onDrop: { item in
                    guard let f = P4Function(rawValue: item.raw) else { return false }
                    p.place(f, at: i, from: item.fromSlot)
                    return true
                },
                onTap: { p.remove(at: i) })
    }
}

// MARK: - Lock 5 · Write it once

struct TP5Lock5ReuseView: View {
    @Bindable var viewModel: TP5PaintingViewModel

    var body: some View {
        let p = viewModel.reuse
        TP5PuzzleCard(
            title: "Write it once",
            subtitle: "Leo repeated unlatch(n) then slide(n) for latches 1, 2 and 3. Rewrite it.",
            lock: 5, opened: viewModel.openedLocks,
            phase: p.phase, hint: p.hints.shown,
            idleText: "Give openLatch a parameter, use it in the body, then call it once per latch.",
            runningText: "Running… watch id change with every call.",
            codeWidth: 318,
            canRun: p.allFilled, runCount: p.runCount,
            onRun: { Task { await p.run() } }, onRetry: p.retry, onHint: p.showHint,
            onNext: viewModel.goToNext, onClose: viewModel.close
        ) {
            TP5LatchStage(latches: p.latches, activeLatch: p.activeLatch,
                          jammedLatch: p.jammedLatch, binding: p.binding, opened: viewModel.openedLocks)
        } code: {
            TP5CodeBox(phase: p.phase) {
                VStack(alignment: .leading, spacing: 0) {
                    TP5CodeRow(number: 0, isActive: p.activeLine == 0, height: 22) {
                        TP5CodeText("func openLatch", size: 12)
                        slot(TP5ReuseViewModel.parameterSlot, p, width: 74)
                        TP5CodeText("{", size: 12)
                    }
                    ForEach(Array(TP5ReuseViewModel.bodySlots.enumerated()), id: \.offset) { k, s in
                        TP5CodeRow(number: P5Engine.bodyLines[k], isActive: p.activeLine == P5Engine.bodyLines[k],
                                   height: 22, indent: 1) {
                            slot(s, p, width: 92)
                        }
                    }
                    TP5CodeRow(number: P5Engine.closeLine, isActive: p.activeLine == P5Engine.closeLine, height: 16) {
                        TP5CodeText("}", size: 12)
                    }
                    ForEach(Array(TP5ReuseViewModel.callSlots.enumerated()), id: \.offset) { k, s in
                        TP5CodeRow(number: P5Engine.callLines[k], isActive: p.activeLine == P5Engine.callLines[k],
                                   height: 22) {
                            slot(s, p, width: 104)
                            if k == 0 {
                                Spacer(minLength: 4)
                                TP5CallStack(frames: p.stack)
                            }
                        }
                    }
                }
            }
        } tray: {
            TP5Tray(isEnabled: p.phase.canEdit, onReturn: { item in
                if let s = item.fromSlot { p.remove(at: s) }
            }) {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 5), GridItem(.flexible(), spacing: 5)], spacing: 5) {
                    ForEach(TP5ReuseViewModel.tray, id: \.self) { t in
                        TP5TrayBlock(text: t.rawValue, isEnabled: p.phase.canEdit, height: 21) { p.place(t) }
                    }
                }
            }
        }
    }

    private func slot(_ s: Int, _ p: TP5ReuseViewModel, width: CGFloat) -> some View {
        TP5Slot(text: p.slots[s]?.rawValue, slotIndex: s,
                minWidth: width, height: 20, isEnabled: p.phase.canEdit,
                accepts: { item in P5Token(rawValue: item.raw).map { p.accepts($0, slot: s) } ?? false },
                onDrop: { item in
                    guard let t = P5Token(rawValue: item.raw) else { return false }
                    return p.place(t, at: s, from: item.fromSlot)
                },
                onTap: { p.remove(at: s) })
    }
}
