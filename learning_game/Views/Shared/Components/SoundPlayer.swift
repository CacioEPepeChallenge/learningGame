//
//  SoundPlayer.swift
//  learning_game
//
//  Plays bundled audio files (voice lines, SFX) with AVAudioPlayer.
//

import AVFoundation

@MainActor
final class SoundPlayer {
    static let shared = SoundPlayer()

    // Players are kept alive here until replaced or stopped, otherwise playback cuts off.
    private var players: [String: AVAudioPlayer] = [:]

    private init() {}

    /// Plays `name.ext` from the app bundle. Returns the clip's duration (0 if it couldn't be played).
    @discardableResult
    func play(_ name: String, ext: String = "mp3", volume: Float = 1.0) -> TimeInterval {
        guard SoundMode.current.sfxOn,
              let url = Bundle.main.url(forResource: name, withExtension: ext),
              let player = try? AVAudioPlayer(contentsOf: url) else { return 0 }
        players[name]?.stop()
        player.volume = volume
        player.play()
        players[name] = player
        return player.duration
    }

    func stopAll() {
        players.values.forEach { $0.stop() }
        players.removeAll()
    }
}
