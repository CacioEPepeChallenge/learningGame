//
//  DialogBox.swift
//  learning_game
//
//  Created by Rudi Butarbutar on 17/11/26.
//

import SwiftUI

struct DialogBox: View {
    let line: DialogLine
    let isLast: Bool
    let onNext: () -> Void
    var body: some View {
        GeometryReader { geo in
            VStack {
                Spacer()
                HStack {
                    Image(line.image)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()          // keep the portrait's proportions (wide sprites aren't squashed)
                        .frame(width: 80, height: 80)
                        .background(.neutralBlack)
                        .cornerRadius(8)
                    VStack(alignment: .leading) {
                        Text(line.speaker)
                            .font(.system(.headline, design: .monospaced))
                            .foregroundStyle(line.speaker == "IRIS" ? Color.accent : Color.peach)
                        Text(line.text)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.neutralWhite)
                    }
                    Spacer()
                    HStack {
                        //                        Button(action: onNext) {
                        Image(systemName: "chevron.right")
                            .font(.system(.subheadline, design: .monospaced).bold())
                            .foregroundStyle(.neutralWhite)
                            .padding(.horizontal, 14).padding(.vertical, 6)
                        //                        }
                    }
                }
                .padding()
                .frame(width: geo.size.width - 24, height: geo.size.height * 0.3)
                .background(.twilight.opacity(0.96))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .contentShape(Rectangle())
                .onTapGesture(perform: onNext)
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
    }
}

#Preview("Interactive") {
    @Previewable @State var index = 0
    let lines = [
        DialogLine(speaker: "IRIS", text:
"""
This is Leo's room. Something feels off...
This is Leo's room. Something feels off...
"""
                  ),
        DialogLine(speaker: "IRIS", text: "Let's look for clues."),
        DialogLine(speaker: "You", text: "Leo, where did you go?")
    ]
    
    ZStack {
        Color.green.ignoresSafeArea()
        if index < lines.count {
            DialogBox(line: lines[index],
                      isLast: index == lines.count - 1,
                      onNext: { index += 1 })
        } else {
            Button("Restart") { index = 0 }
        }
    }
}
