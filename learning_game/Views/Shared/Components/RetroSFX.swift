//
//  RetroSFX.swift
//  learning_game
//
//  Tiny procedural chiptune sound effects (no audio files needed):
//  square / pulse / triangle / noise tones synthesised into a PCM buffer and
//  played with AVAudioEngine.
//

import AVFoundation

@MainActor
final class RetroSFX {
    static let shared = RetroSFX()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    /// Footsteps get their own node so they never cut off the other effects.
    private let stepPlayer = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    private var isReady = false
    private var stepFlip = false

    private init() {}

    /// Every effect goes through here, so the sound button's mute is checked once.
    private func prepare() -> Bool {
        guard SoundMode.current.sfxOn else { return false }
        if isReady { return true }
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            for node in [player, stepPlayer] {
                engine.attach(node)
                engine.connect(node, to: engine.mainMixerNode, format: format)
            }
            engine.mainMixerNode.outputVolume = 0.35
            try engine.start()
            isReady = true
        } catch {
            isReady = false
        }
        return isReady
    }

    // MARK: Touchpoints

    /// Scrambled data chatter that resolves into a rising "unlocked" arpeggio.
    func playDecrypt() {
        var notes: [Tone] = []
        var seed: UInt64 = 0x5EED
        for _ in 0..<14 {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            let f = 500 + Double(seed >> 52) / 4096 * 1400
            notes.append(Tone(f, 0.035))
        }
        notes += [Tone(523, 0.07), Tone(659, 0.07), Tone(784, 0.07), Tone(1047, 0.16)]
        play(notes)
    }

    /// Short confirmation blip.
    func playBlip() { play([Tone(880, 0.05), Tone(1320, 0.06)]) }

    /// Touchpoint finished: bright rising jingle.
    func playSuccess() {
        play([Tone(587, 0.07), Tone(740, 0.07), Tone(880, 0.07),
              Tone(1175, 0.22, wave: .pulse(0.25))])
    }

    /// TP1: the generator spins up, then the success jingle.
    func playPowerUp() {
        play([Tone(70, 0.55, to: 420, wave: .triangle, gain: 0.45),
              Tone(587, 0.07), Tone(880, 0.07), Tone(1175, 0.2, wave: .pulse(0.25))])
    }

    /// TP2: switch click, then the lamp hums on.
    func playLightOn() {
        play([Tone(0, 0.03, wave: .noise, gain: 0.35), Tone(0, 0.06, gain: 0),
              Tone(880, 0.06), Tone(1320, 0.06), Tone(1760, 0.18, wave: .pulse(0.125))])
    }

    /// TP5: safe code accepted, heavy lock thunk then the unlock chime.
    func playUnlock() {
        play([Tone(110, 0.09, to: 60, wave: .triangle, gain: 0.5), Tone(0, 0.05, wave: .noise, gain: 0.2),
              Tone(784, 0.07), Tone(1047, 0.07), Tone(1568, 0.2, wave: .pulse(0.25))])
    }

    // MARK: Map

    /// One soft footstep per tile; alternates pitch so walking sounds like left/right feet.
    func playStep() {
        guard prepare() else { return }
        stepFlip.toggle()
        let tones = [Tone(stepFlip ? 95 : 80, 0.045, to: 45, wave: .triangle, gain: 0.3),
                     Tone(0, 0.015, wave: .noise, gain: 0.04)]
        guard let buffer = render(tones) else { return }
        stepPlayer.scheduleBuffer(buffer, at: nil, options: .interrupts)
        if !stepPlayer.isPlaying { stepPlayer.play() }
    }

    /// I.R.I.S. pops up a touchpoint prompt.
    func playPrompt() {
        play([Tone(988, 0.05, wave: .pulse(0.125)), Tone(1319, 0.05, wave: .pulse(0.125)),
              Tone(1976, 0.1, wave: .pulse(0.125), gain: 0.18)])
    }

    /// A new glowing objective appears on the map.
    func playObjective() {
        play([Tone(1319, 0.04, wave: .pulse(0.125)), Tone(1568, 0.04, wave: .pulse(0.125)),
              Tone(1976, 0.04, wave: .pulse(0.125)), Tone(1568, 0.04, wave: .pulse(0.125)),
              Tone(1976, 0.12, wave: .pulse(0.125), gain: 0.18)])
    }

    /// LET'S GO: rising sweep into a puzzle.
    func playEnter() {
        play([Tone(300, 0.18, to: 1200, wave: .pulse(0.25), gain: 0.2), Tone(1200, 0.06)])
    }

    /// Left a puzzle without finishing it.
    func playBack() { play([Tone(660, 0.05), Tone(440, 0.09)]) }

    // MARK: Dialog & menus

    /// Advancing a dialog line.
    func playTick() { play([Tone(1200, 0.025, gain: 0.12)]) }

    /// Menu button (Continue, Start Again).
    func playConfirm() { play([Tone(660, 0.05), Tone(990, 0.1)]) }

    // MARK: Cutscenes

    /// The painting slides aside.
    func playSlide() {
        play([Tone(0, 0.5, wave: .noise, gain: 0.12), Tone(220, 0.12, to: 110, wave: .triangle, gain: 0.4)])
    }

    /// The safe door swings open: creak then a low thud.
    func playSafeOpen() {
        play([Tone(180, 0.6, to: 260, wave: .pulse(0.125), gain: 0.1),
              Tone(90, 0.18, to: 50, wave: .triangle, gain: 0.5), Tone(0, 0.08, wave: .noise, gain: 0.15)])
    }

    /// I.R.I.S. is revealed as the villain (~5 s): a boom on a tritone stab, an
    /// uneasy low drone, a heartbeat, corrupted data chatter, and a falling robotic laugh.
    func playIrisReveal() {
        // Impact: noise crash + sub boom + tritone stab (A / D#), the "devil's interval".
        let boom = [Tone(0, 0.5, wave: .noise, gain: 0.22, fade: true)]
        let sub = [Tone(120, 0.9, to: 32, wave: .triangle, gain: 0.45, fade: true)]
        let stab = [Tone(220, 1.1, to: 208, gain: 0.14, fade: true)]
        let stab2 = [Tone(311, 1.1, to: 294, gain: 0.12, fade: true)]

        // Drone: two slightly detuned low pulses that beat against each other.
        let drone = [Tone(55, 4.6, to: 49, wave: .pulse(0.3), gain: 0.14, fade: true)]
        let drone2 = [Tone(55.7, 4.6, to: 49.5, wave: .pulse(0.3), gain: 0.12, fade: true)]

        // Heartbeat: lub-dub, twice.
        let thump = Tone(70, 0.11, to: 38, wave: .triangle, gain: 0.6)
        let heart = [thump, Tone(0, 0.12, gain: 0), thump, Tone(0, 0.55, gain: 0), thump, Tone(0, 0.12, gain: 0), thump]

        // Glitch: I.R.I.S.'s code tearing itself apart.
        var glitch: [Tone] = []
        var seed: UInt64 = 0xBADC0DE
        for _ in 0..<22 {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            let hi = seed >> 40
            glitch.append(hi % 3 == 0 ? Tone(0, 0.025, wave: .noise, gain: 0.12)
                                      : Tone(200 + Double(hi % 1800), 0.025, wave: .pulse(0.125), gain: 0.07))
            if hi % 4 == 0 { glitch.append(Tone(0, 0.03, gain: 0)) }
        }

        // Robotic laugh: "ha-ha-ha..." stepping down, each "ha" bending flat.
        var laugh: [Tone] = []
        for (i, f) in [740.0, 698, 659, 622, 587, 554, 523].enumerated() {
            laugh.append(Tone(f, 0.09, to: f * 0.85, wave: .pulse(0.25), gain: 0.16 - Double(i) * 0.012))
            laugh.append(Tone(0, 0.06, gain: 0))
        }
        laugh.append(Tone(392, 0.7, to: 196, wave: .pulse(0.125), gain: 0.14, fade: true))

        playLayered([(0, boom), (0, sub), (0, stab), (0, stab2),
                     (0.2, drone), (0.2, drone2),
                     (1.0, heart), (1.4, glitch), (2.3, laugh)])
    }

    /// "To be continued...": one low, fading note.
    func playToBeContinued() {
        play([Tone(220, 0.25, wave: .triangle, gain: 0.4), Tone(165, 0.8, wave: .triangle, gain: 0.35)])
    }

    // MARK: Synth

    enum Wave { case square, pulse(Double), triangle, noise }

    /// One note: `freq` Hz (sliding to `to` if set) for `dur` seconds. `gain` 0 is a rest.
    /// `fade` makes it die away over its whole length instead of holding.
    struct Tone {
        var freq: Double, dur: Double, to: Double? = nil, wave: Wave = .square, gain: Double = 0.25, fade = false
        init(_ freq: Double, _ dur: Double, to: Double? = nil, wave: Wave = .square, gain: Double = 0.25,
             fade: Bool = false) {
            self.freq = freq; self.dur = dur; self.to = to; self.wave = wave; self.gain = gain; self.fade = fade
        }
    }

    private func play(_ notes: [Tone]) {
        guard prepare(), let buffer = render(notes) else { return }
        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
        if !player.isPlaying { player.play() }
    }

    /// Mixes several note sequences on top of each other, each starting `at` seconds in.
    private func playLayered(_ layers: [(at: Double, notes: [Tone])]) {
        guard prepare() else { return }
        let rate = format.sampleRate
        let tracks = layers.map { (offset: Int($0.at * rate), samples: samples($0.notes)) }
        let total = tracks.map { $0.offset + $0.samples.count }.max() ?? 0
        guard let buffer = makeBuffer(frames: total), let data = buffer.floatChannelData?[0] else { return }
        for i in 0..<total { data[i] = 0 }
        for track in tracks {
            for (k, s) in track.samples.enumerated() { data[track.offset + k] += s }
        }
        for i in 0..<total { data[i] = max(-1, min(1, data[i])) }
        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
        if !player.isPlaying { player.play() }
    }

    private func makeBuffer(frames: Int) -> AVAudioPCMBuffer? {
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frames)) else { return nil }
        buffer.frameLength = AVAudioFrameCount(frames)
        return buffer
    }

    private func render(_ notes: [Tone]) -> AVAudioPCMBuffer? {
        let pcm = samples(notes)
        guard let buffer = makeBuffer(frames: pcm.count), let data = buffer.floatChannelData?[0] else { return nil }
        pcm.withUnsafeBufferPointer { data.update(from: $0.baseAddress!, count: pcm.count) }
        return buffer
    }

    private func samples(_ notes: [Tone]) -> [Float] {
        let rate = format.sampleRate
        let total = notes.reduce(0) { $0 + Int($1.dur * rate) }
        var data = [Float](repeating: 0, count: total)
        var i = 0
        var seed: UInt32 = 0xACE1
        for note in notes {
            let n = Int(note.dur * rate)
            var phase = 0.0
            for k in 0..<n {
                let progress = Double(k) / Double(n)
                let freq = note.to.map { note.freq + ($0 - note.freq) * progress } ?? note.freq
                phase = (phase + freq / rate).truncatingRemainder(dividingBy: 1)
                let sample: Double
                switch note.wave {
                case .square:          sample = phase < 0.5 ? 1 : -1
                case .pulse(let duty): sample = phase < duty ? 1 : -1
                case .triangle:        sample = 4 * abs(phase - 0.5) - 1
                case .noise:
                    seed ^= seed << 13; seed ^= seed >> 17; seed ^= seed << 5
                    sample = (Double(seed) / Double(UInt32.max) * 2 - 1) * (1 - progress)
                }
                let envelope = min(1, Double(n - k) / 400)            // click-free release
                    * (note.fade ? (1 - progress) * (1 - progress) : 1)
                data[i] = Float(sample * note.gain * envelope)
                i += 1
            }
        }
        return data
    }
}
