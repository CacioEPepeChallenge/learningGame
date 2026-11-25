//
//  SoundModeButton.swift
//  learning_game
//
//  Top-left sound toggle: cycles Music + SFX → SFX only → Muted.
//  The choice is saved in UserDefaults so it survives relaunches.
//

import SwiftUI

enum SoundMode: String, CaseIterable {
    case all, sfxOnly, mute

    static let storageKey = "soundMode"

    /// Read by the audio players (RetroSFX, SoundPlayer) that live outside SwiftUI.
    static var current: SoundMode {
        SoundMode(rawValue: UserDefaults.standard.string(forKey: storageKey) ?? "") ?? .all
    }

    var musicOn: Bool { self == .all }
    var sfxOn: Bool { self != .mute }

    var next: SoundMode {
        switch self {
        case .all: .sfxOnly
        case .sfxOnly: .mute
        case .mute: .all
        }
    }

    var icon: String {
        switch self {
        case .all: "speaker.wave.2.fill"
        case .sfxOnly: "speaker.wave.1.fill"
        case .mute: "speaker.slash.fill"
        }
    }

    var label: String {
        switch self {
        case .all: "ALL"
        case .sfxOnly: "SFX"
        case .mute: "OFF"
        }
    }
}

struct SoundModeButton: View {
    @AppStorage(SoundMode.storageKey) private var mode: SoundMode = .all

    var body: some View {
        Button {
            mode = mode.next
            if mode.sfxOn { RetroSFX.shared.playBlip() } else { SoundPlayer.shared.stopAll() }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: mode.icon)
                    .frame(width: 22)
                Text(mode.label)
            }
            .font(.system(.footnote, design: .monospaced).bold())
            .foregroundStyle(.neutralWhite)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.twilight.opacity(0.9), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Sound: \(mode.label)")
    }
}

#Preview {
    ZStack {
        Color.green.ignoresSafeArea()
        SoundModeButton()
    }
}
