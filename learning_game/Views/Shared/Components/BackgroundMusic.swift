//
//  BackgroundMusic.swift
//  learning_game
//
//  Procedural chiptune backsound (no audio files needed): a 16-bar A-minor loop
//  with a triangle bass, a soft pulse arpeggio, a pulse lead with echo and
//  light drums. Rendered once into a PCM buffer, then looped with AVAudioEngine.
//

import AVFoundation

@MainActor
final class BackgroundMusic {
    static let shared = BackgroundMusic()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    private let maxVolume: Float = 0.22
    private var buffer: AVAudioPCMBuffer?
    private var isRendering = false
    private var wantsPlaying = false
    private var fadeTask: Task<Void, Never>?

    private init() {}

    /// Fades the loop in or out. Pausing keeps the position, so it resumes where it left off.
    func setPlaying(_ playing: Bool) {
        wantsPlaying = playing
        if playing { start() } else { fade(to: 0) { [weak self] in self?.player.pause() } }
    }

    private func start() {
        guard let buffer else { renderThenStart(); return }
        guard prepareEngine(with: buffer) else { return }
        if !player.isPlaying { player.volume = 0; player.play() }
        fade(to: maxVolume)
    }

    private func renderThenStart() {
        guard !isRendering else { return }
        isRendering = true
        let sampleRate = format.sampleRate
        Task {
            let samples = await Task.detached(priority: .utility) { ChiptuneSong.render(sampleRate: sampleRate) }.value
            isRendering = false
            guard let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)),
                  let data = buf.floatChannelData?[0] else { return }
            buf.frameLength = AVAudioFrameCount(samples.count)
            samples.withUnsafeBufferPointer { data.update(from: $0.baseAddress!, count: samples.count) }
            buffer = buf
            if wantsPlaying { start() }
        }
    }

    private func prepareEngine(with buffer: AVAudioPCMBuffer) -> Bool {
        if engine.isRunning { return true }
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            if player.engine == nil {
                engine.attach(player)
                engine.connect(player, to: engine.mainMixerNode, format: format)
                player.scheduleBuffer(buffer, at: nil, options: .loops)
            }
            try engine.start()
            return true
        } catch {
            return false
        }
    }

    private func fade(to target: Float, duration: Double = 0.8, then completion: (() -> Void)? = nil) {
        fadeTask?.cancel()
        let from = player.volume
        fadeTask = Task {
            let steps = 20
            for i in 1...steps {
                try? await Task.sleep(for: .seconds(duration / Double(steps)))
                if Task.isCancelled { return }
                player.volume = from + (target - from) * Float(i) / Float(steps)
            }
            completion?()
        }
    }
}

// MARK: - Song

/// The loop's score and a tiny software synth that renders it.
private enum ChiptuneSong {
    static let bpm = 96.0
    static let stepsPerBar = 16                  // 16th notes

    /// (arpeggio notes, bass root) per bar, as MIDI note numbers.
    static let chords: [([Int], Int)] = {
        let am = ([69, 72, 76], 45), f = ([65, 69, 72], 41), c = ([67, 72, 76], 48)
        let g = ([67, 71, 74], 43), em = ([64, 67, 71], 40), dm = ([65, 69, 74], 38)
        let e = ([64, 68, 71], 40)
        return [am, f, c, g,  am, f, c, g,  f, g, em, am,  dm, f, e, e]
    }()

    /// Lead melody in 8th notes: a note number, 0 = hold the previous note, nil = rest.
    /// Bars 0–3 are an intro with no lead.
    static let melody: [[Int?]] = {
        let rest: [Int?] = Array(repeating: nil, count: 8)
        return [
            rest, rest, rest, rest,
            [76, 0, 0, 74, 72, 0, 69, 0],
            [72, 0, 0, 0, 69, 0, 72, 74],
            [76, 0, 79, 0, 76, 0, 74, 72],
            [74, 0, 0, 0, nil, nil, nil, nil],
            [72, 0, 74, 0, 76, 0, 77, 0],
            [79, 0, 0, 77, 76, 0, 74, 0],
            [71, 0, 0, 74, 76, 0, 0, 0],
            [72, 0, 71, 0, 69, 0, 0, 0],
            [77, 0, 0, 76, 74, 0, 72, 0],
            [72, 0, 0, 0, 69, 0, 72, 0],
            [71, 0, 0, 0, 68, 0, 71, 0],
            [76, 0, 0, 0, nil, nil, nil, nil],
        ]
    }()

    static func render(sampleRate: Double) -> [Float] {
        let stepLen = 60.0 / bpm / 4 * sampleRate
        let total = Int(stepLen * Double(stepsPerBar * chords.count))
        var mix = [Float](repeating: 0, count: total)
        var lead = [Float](repeating: 0, count: total)
        func at(_ step: Int) -> Int { Int(Double(step) * stepLen) }
        func freq(_ midi: Int) -> Double { 440 * pow(2, Double(midi - 69) / 12) }

        for (bar, (arp, root)) in chords.enumerated() {
            let barStart = bar * stepsPerBar

            // Bass: triangle, root on the beat, octave bounce on the off-beat 8ths.
            for eighth in 0..<8 {
                let note = eighth % 2 == 0 ? root : root + 12
                tone(&mix, start: at(barStart + eighth * 2), length: Int(stepLen * 1.8),
                     freq: freq(note), wave: .triangle, gain: 0.26, sampleRate: sampleRate)
            }

            // Arpeggio: thin 12.5% pulse, up-down 16ths, very quiet (the "tech" shimmer).
            let pattern = [0, 1, 2, 1]
            for s in 0..<stepsPerBar {
                let note = arp[pattern[s % 4]] + 12
                tone(&mix, start: at(barStart + s), length: Int(stepLen * 0.7),
                     freq: freq(note), wave: .pulse(0.125), gain: 0.045, sampleRate: sampleRate)
            }

            // Drums: soft kick on 1 and 3 (plus a pickup every other bar), snare on 2 and 4, off-beat hats.
            var kicks = [0, 8]
            if bar % 2 == 1 { kicks.append(14) }
            for s in kicks { kick(&mix, start: at(barStart + s), sampleRate: sampleRate) }
            if bar >= 2 {
                for s in [4, 12] { noise(&mix, start: at(barStart + s), length: 0.11, gain: 0.07, sampleRate: sampleRate) }
            }
            for s in [2, 6, 10, 14] { noise(&mix, start: at(barStart + s), length: 0.025, gain: 0.04, sampleRate: sampleRate) }

            // Lead: 25% pulse with delayed vibrato.
            let notes = melody[bar]
            var i = 0
            while i < notes.count {
                guard let note = notes[i], note != 0 else { i += 1; continue }
                var length = 1
                while i + length < notes.count, notes[i + length] == 0 { length += 1 }
                tone(&lead, start: at(barStart + i * 2), length: Int(stepLen * 2 * Double(length) * 0.92),
                     freq: freq(note), wave: .pulse(0.25), gain: 0.11, sampleRate: sampleRate, vibrato: true)
                i += length
            }
        }

        // Echo on the lead (dotted 8th, wraps around so the loop stays seamless).
        let delay = Int(stepLen * 3)
        let dry = lead
        for i in 0..<total {
            lead[i] += dry[(i - delay + total) % total] * 0.32 + dry[(i - 2 * delay + total) % total] * 0.12
        }

        return zip(mix, lead).map { max(-1, min(1, $0 + $1)) }
    }

    enum Wave { case pulse(Double), triangle }

    /// Adds a note into `buffer`, wrapping past the end so the loop has no seam.
    static func tone(_ buffer: inout [Float], start: Int, length: Int, freq: Double, wave: Wave,
                     gain: Double, sampleRate: Double, vibrato: Bool = false) {
        let attack = 0.004 * sampleRate, release = 0.03 * sampleRate
        var phase = 0.0
        for k in 0..<length {
            let t = Double(k) / sampleRate
            var f = freq
            if vibrato, t > 0.18 { f *= 1 + 0.006 * sin(2 * .pi * 5.5 * t) }
            phase = (phase + f / sampleRate).truncatingRemainder(dividingBy: 1)
            let sample: Double
            switch wave {
            case .pulse(let duty): sample = phase < duty ? 1 : -1
            case .triangle:        sample = 4 * abs(phase - 0.5) - 1
            }
            let env = min(1, Double(k) / attack, Double(length - k) / release) * (vibrato ? max(0.65, 1 - t * 0.8) : 1)
            buffer[(start + k) % buffer.count] += Float(sample * env * gain)
        }
    }

    /// Sine kick with a fast pitch drop.
    static func kick(_ buffer: inout [Float], start: Int, sampleRate: Double) {
        let length = Int(0.14 * sampleRate)
        var phase = 0.0
        for k in 0..<length {
            let t = Double(k) / Double(length)
            phase += (45 + 95 * (1 - t) * (1 - t)) / sampleRate
            buffer[(start + k) % buffer.count] += Float(sin(2 * .pi * phase) * (1 - t) * 0.3)
        }
    }

    /// Short decaying noise burst (hat / snare), deterministic so every render sounds the same.
    static func noise(_ buffer: inout [Float], start: Int, length seconds: Double, gain: Double, sampleRate: Double) {
        let length = Int(seconds * sampleRate)
        var seed: UInt32 = 0xACE1
        for k in 0..<length {
            seed ^= seed << 13; seed ^= seed >> 17; seed ^= seed << 5
            let white = Double(seed) / Double(UInt32.max) * 2 - 1
            let env = pow(1 - Double(k) / Double(length), 2)
            buffer[(start + k) % buffer.count] += Float(white * env * gain)
        }
    }
}
