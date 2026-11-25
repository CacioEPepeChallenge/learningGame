//
//  PaintingToSaveView.swift
//  learning_game
//
//  Created by Rudi Butarbutar on 22/11/26.
//

import SwiftUI
import WebKit

struct PaintingRevealView: View {
    let onComplete: () -> Void
    
    private let duration: TimeInterval = 3.0
    private let lines: [DialogLine] = [
        DialogLine(speaker: "IRIS", text: "The painting opened — there's a safe behind it."),
        DialogLine(speaker: "IRIS", text: "Let's see what Leo was hiding.")
    ]
    @State private var showDialog = false
    @State private var dialogIndex = 0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()
            Image("painting_reveal")
                .resizable()
                .ignoresSafeArea()
            GIFView(name: "paintingreveal")
                .aspectRatio(contentMode: .fit)
                .padding()
                .frame(maxWidth: .infinity, alignment: .trailing)
                .offset(x: 140)
            if showDialog, dialogIndex < lines.count {
                DialogBox(line: lines[dialogIndex], isLast: dialogIndex == lines.count - 1, onNext: {
                    RetroSFX.shared.playTick()
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
            Image("painting_reveal").resizable().ignoresSafeArea()
            GIFView(name: "paintingreveal")
                .aspectRatio(contentMode: .fit)
                .frame(width: 400)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .offset(x: 160)
            DialogBox(
                line: DialogLine(speaker: "IRIS", text: "The painting opened —     there's a safe behind it."),
                isLast: false,
                onNext: {}
            )
        }
    }
}
