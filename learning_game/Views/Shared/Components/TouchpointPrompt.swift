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
                            .foregroundStyle(.neutralBlack)
                    }

                    Text(line.text)
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundStyle(.neutralBlack)
                        .fixedSize(horizontal: false, vertical: true)

                    Button(action: onConfirm) {
                        Text("LET'S GO")
                            .font(.system(.footnote, design: .monospaced).bold())
                            .foregroundStyle(.accent)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(.neutralBlack, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .frame(maxWidth: 260, alignment: .leading)
                .background(.accent, in: RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(.neutralBlack, lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.25), radius: 6, y: 3)

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
