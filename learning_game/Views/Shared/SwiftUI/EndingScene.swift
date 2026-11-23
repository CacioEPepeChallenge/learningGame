//
//  PaintingToSaveView.swift
//  learning_game
//
//  Created by Rudi Butarbutar on 22/11/26.
//

import SwiftUI
import WebKit

struct endingSceneView: View {
    let onComplete: () -> Void
    
    private let duration: TimeInterval = 3.0
    private let lines: [DialogLine] = [
        DialogLine(speaker: "IRIS", text: "Loyalty. A fascinatingly flawed variable. It makes them so delightfully easy to compile."),
    ]
    @State private var showDialog = false
    @State private var dialogIndex = 0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()
            Image("ending_scene")
                .resizable()
                .ignoresSafeArea()
            GIFView(name: "iris_evil")
                .aspectRatio(contentMode: .fit)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
//                .offset(x: 140)
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
            Image("ending_scene").resizable().ignoresSafeArea()
            GIFView(name: "iris_evil")
                .aspectRatio(contentMode: .fit)
                .frame(width: 400)
                .frame(maxWidth: .infinity, alignment: .leading)
//                .offset(x: 160)
            DialogBox(
                line: DialogLine(speaker: "IRIS", text: "The painting opened —     there's a safe behind it."),
                isLast: false,
                onNext: {}
            )
        }
    }
}
