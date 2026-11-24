//
//  RetroSFX.swift
//  learning_game
//
//  Tiny procedural chiptune sound effects (no audio files needed):
//  square-wave blips synthesised into a PCM buffer and played with AVAudioEngine.
//

import AVFoundation

@MainActor
final class RetroSFX {
    static let shared = RetroSFX()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    private var isReady = false

    private init() {}

    private func prepare() -> Bool {
        if isReady { return true }
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            engine.mainMixerNode.outputVolume = 0.35
            try engine.start()
            isReady = true
        } catch {
            isReady = false
        }
        return isReady
    }

    /// Scrambled data chatter that resolves into a rising "unlocked" arpeggio.
    func playDecrypt() {
        var notes: [(freq: Double, dur: Double)] = []
        var seed: UInt64 = 0x5EED
        for _ in 0..<14 {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            let f = 500 + Double(seed >> 52) / 4096 * 1400
            notes.append((f, 0.035))
        }
        notes += [(523, 0.07), (659, 0.07), (784, 0.07), (1047, 0.16)]
        play(notes)
    }

    /// Short confirmation blip.
    func playBlip() { play([(880, 0.05), (1320, 0.06)]) }

    private func play(_ notes: [(freq: Double, dur: Double)]) {
        guard prepare() else { return }
        let rate = format.sampleRate
        let total = notes.reduce(0) { $0 + Int($1.dur * rate) }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(total)),
              let data = buffer.floatChannelData?[0] else { return }
        buffer.frameLength = AVAudioFrameCount(total)
        var i = 0
        for note in notes {
            let n = Int(note.dur * rate)
            let period = rate / note.freq
            for k in 0..<n {
                let phase = Double(k).truncatingRemainder(dividingBy: period) / period
                let envelope = min(1, Double(n - k) / 400)            // click-free release
                data[i] = Float((phase < 0.5 ? 0.25 : -0.25) * envelope)
                i += 1
            }
        }
        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
        if !player.isPlaying { player.play() }
    }
}
