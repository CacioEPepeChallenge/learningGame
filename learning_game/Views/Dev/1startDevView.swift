//
//  1startDevView.swift
//  learning_game
//
//  Dedicated screen for pitch-deck screenshots.
//  Shows the StartingScene background only, with no dialog or overlays.
//

import SwiftUI

struct StartDevView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()
            Image("background_light")
                .resizable()
                .ignoresSafeArea()
            Image("mc_side_left")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 120)
                .scaleEffect(x: -1, y: 1)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        }
    }
}

#Preview {
    StartDevView()
}
