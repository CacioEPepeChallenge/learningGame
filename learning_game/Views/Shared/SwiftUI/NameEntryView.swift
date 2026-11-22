//
//  NameEntryView.swift
//  learning_game
//

import SwiftUI

struct NameEntryView: View {
    let onSubmit: (String) -> Void

    @State private var name: String = ""
    @FocusState private var fieldFocused: Bool

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("You haven't seen Leo for a long time.\nToday, you decide to visit his home.")
                    .font(.system(.title3, design: .monospaced))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Text("What's your name?")
                    .font(.system(.headline, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.75))

                TextField("", text: $name)
                    .font(.system(.title2, design: .monospaced))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .focused($fieldFocused)
                    .submitLabel(.go)
                    .onSubmit(submit)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 48)

                Button(action: submit) {
                    Text("Continue →")
                        .font(.system(.title3, design: .monospaced).bold())
                        .foregroundStyle(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .clipShape(Capsule())
                }
            }
        }
    }

    private func submit() {
        onSubmit(name)
    }
}
