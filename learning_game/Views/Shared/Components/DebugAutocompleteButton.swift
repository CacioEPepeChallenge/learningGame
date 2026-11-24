//
//  DebugAutocompleteButton.swift
//  learning_game
//

import SwiftUI

struct DebugAutocompleteButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("DEBUG: complete")
                .font(.system(.caption2, design: .monospaced).bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.85))
                .clipShape(Capsule())
        }
        .padding(12)
    }
}
