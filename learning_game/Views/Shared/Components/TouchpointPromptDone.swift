//
//  TouchpointPrompt.swift
//  learning_game
//
//  Created by Rudi Butarbutar on 17/11/26.
//

import SwiftUI

struct TouchpointPrompt: View {
    let line: DialogLine
    let onConfirm: () -> Void

    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        Image(line.image)
                            .resizable()
                            .frame(width: 36, height: 36)
                            .background(.neutralBlack)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        Text(line.speaker)
                            .font(.system(.caption, design: .monospaced).bold())
                            .foregroundStyle(.accent)
                    }

                    Text(line.text)
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundStyle(.neutralWhite)
                        .fixedSize(horizontal: false, vertical: true)

                    Button(action: onConfirm) {
                        Text("LET'S GO")
                            .font(.system(.footnote, design: .monospaced).bold())
                            .foregroundStyle(.neutralWhite)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(.burgundy, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .frame(maxWidth: 280, alignment: .leading)
                .background(.twilight, in: RoundedRectangle(cornerRadius: 10))
                /*.overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(.neutralBlack, lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.25), radius: 6, y: 3)*/

                Spacer()
            }
            Spacer()
        }
        .padding(16)
    }
}


#Preview("Interactive") {
    @Previewable @State var isShowing = true
    
    ZStack {
        Color.green.ignoresSafeArea()
        if isShowing {
            TouchpointPrompt(
                line: DialogLine(speaker: "IRIS", text: "Let's check the generator."),
                onConfirm: { isShowing = false }
            )
        } else {
            Button("Restart") { isShowing = true }
        }
    }
}
