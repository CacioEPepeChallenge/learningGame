//
//  PaintingToSaveView.swift
//  learning_game
//
//  Created by Rudi Butarbutar on 22/11/26.
//

import SwiftUI
import WebKit

struct startSceneView: View {
    let onComplete: () -> Void
    var playerName: String = "Anonymous"

    private let duration: TimeInterval = 3.0
    private var lines: [DialogLine] {
        [
            DialogLine(speaker: playerName, text: "Leo, are you in there? I haven't seen you in weeks."),
            DialogLine(speaker: playerName, text: "If you don't answer, I'm coming in.")
        ]
    }
    // Voice clip per dialog line, and the knock that plays before each line.
    private let voiceClips = ["start_line_1", "start_line_2"]
    private let knockClips = ["start_knock_1", "start_knock_2"]
    @State private var showDialog = false
    @State private var dialogIndex = 0

    /// Knock, wait for it to finish (dialog hidden), then show the line and play its voice.
    private func playLine(_ index: Int) async {
        showDialog = false
        let knock = SoundPlayer.shared.play(knockClips[index])
        try? await Task.sleep(for: .seconds(knock > 0 ? knock : duration))
        guard !Task.isCancelled else { return }
        dialogIndex = index
        showDialog = true
        SoundPlayer.shared.play(voiceClips[index])
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()
            Image("start_scene")
                .resizable()
                .ignoresSafeArea()
            GIFView(name: "knock_fx")
                .aspectRatio(contentMode: .fit)
                .padding()
                .frame(maxWidth: .infinity, alignment: .trailing)
                .offset(x: 80, y: 80)
            if showDialog, dialogIndex < lines.count {
                DialogBox(line: lines[dialogIndex], isLast: dialogIndex == lines.count - 1, onNext: {
                    RetroSFX.shared.playTick()
                    if dialogIndex < lines.count - 1 {
                        let next = dialogIndex + 1
                        Task { await playLine(next) }
                    } else {
                        SoundPlayer.shared.stopAll()
                        onComplete()
                    }
                }
                )
            }
        }
        .task {
            await playLine(0)
        }
        .onDisappear {
            SoundPlayer.shared.stopAll()
        }
    }
}

#Preview("Dialog state") {
    PaintingRevealView_DialogPreview()
}
                                        
private struct PaintingRevealView_DialogPreview: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
            Image("start_scene").resizable().ignoresSafeArea()
            GIFView(name: "knock_fx")
                .aspectRatio(contentMode: .fit)
                .frame(width: 400)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .offset(x: 80, y: 80)
            DialogBox(
                line: DialogLine(speaker: "Rudi", text: "Leo, Are you there?"),
                isLast: false,
                onNext: {}
            )
        }
    }
}
