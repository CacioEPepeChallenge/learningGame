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
    @State private var showDialog = false
    @State private var dialogIndex = 0
    
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
                    if dialogIndex < lines.count - 1 {
                        dialogIndex += 1
                    } else {
                        onComplete()
                    }
                }
                )
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(duration))
            showDialog = true
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
