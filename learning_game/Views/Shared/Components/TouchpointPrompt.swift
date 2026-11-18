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
    let onCancel: () -> Void
    
    var body: some View {
        GeometryReader { geo in
            VStack {
                Spacer()
                HStack {
                    Image(line.image)
                        .resizable()
                        .frame(width: 80, height: 80)
                        .background(.neutralBlack)
                        .cornerRadius(8)
                    VStack(alignment: .leading) {
                        Text(line.speaker)
                            .font(.system(.headline, design: .monospaced))
                            .foregroundStyle(.accent)
                        Text(line.text)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.neutralWhite)
                    }
                    Spacer()
                    VStack(spacing: 12) {
                          Button(action: onCancel) {
                              Text("CANCEL")
                                  .foregroundStyle(.neutralWhite.opacity(0.6))
                                  .padding(.horizontal, 16)
                                  .padding(.vertical, 8)
//                                  .background(.neutralBlack)
//                                  .overlay(
//                                      Rectangle()
//                                          .stroke(.neutralWhite, lineWidth: 2)
//                                  )
                          }
                          .buttonStyle(.plain)
                                                                                                         
                          Button(action: onConfirm) {
                              Text("LET'S GO")
                                  .foregroundStyle(.neutralBlack)
                                  .padding(.horizontal, 16)
                                  .padding(.vertical, 8)
                                  .background(.accent)
                                  .overlay(
                                      Rectangle()
                                          .stroke(.neutralBlack, lineWidth: 2)
                                  )
                          }
                          .buttonStyle(.plain)
                      }
                }
                .padding()
                .frame(width: geo.size.width - 24, height: geo.size.height * 0.3)
                .background(.twilight.opacity(0.90))
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .contentShape(Rectangle())
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
