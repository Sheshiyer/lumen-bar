import AppKit
import Foundation

/// Three short, quiet cues. Generated once, cached, and never played during snapshots or self-tests.
@MainActor
final class SoundCues {
    static let shared = SoundCues()

    enum Cue {
        /// A soft rising pair when a break begins.
        case breakStart
        /// A single falling tone when a break ends.
        case breakEnd
        /// A short tick when a preset lands.
        case preset
    }

    private var sounds: [Cue: NSSound] = [:]

    private init() {}

    func play(_ cue: Cue) {
        guard AppModel.sharedSoundEnabled, !DisplayGammaEngine.shared.isSimulationMode else { return }
        let sound = sounds[cue] ?? Self.make(cue)
        sounds[cue] = sound
        sound.stop()
        sound.volume = 0.35
        sound.play()
    }

    private static func make(_ cue: Cue) -> NSSound {
        let tones: [(hz: Double, start: Double, length: Double)]
        switch cue {
        case .breakStart:
            tones = [(523.25, 0.0, 0.18), (659.25, 0.16, 0.26)]
        case .breakEnd:
            tones = [(440.0, 0.0, 0.30)]
        case .preset:
            tones = [(880.0, 0.0, 0.07)]
        }
        let duration = (tones.map { $0.start + $0.length }.max() ?? 0.2) + 0.05
        let data = wav(tones: tones, duration: duration)
        return NSSound(data: data) ?? NSSound(contentsOfFile: "/System/Library/Sounds/Tink.aiff", byReference: true) ?? NSSound()
    }

    /// A 16-bit mono WAV of soft sine tones with short fades, so nothing clicks.
    private static func wav(tones: [(hz: Double, start: Double, length: Double)], duration: Double) -> Data {
        let rate = 44_100
        let count = Int(duration * Double(rate))
        var samples = [Int16](repeating: 0, count: count)
        let amplitude = 0.22
        for tone in tones {
            let first = Int(tone.start * Double(rate))
            let last = min(count, first + Int(tone.length * Double(rate)))
            let span = max(1, last - first)
            for i in first..<last {
                let t = Double(i - first) / Double(rate)
                let edge = Double(i - first) / Double(span)
                let envelope = min(edge * 12, 1, (1 - edge) * 12)
                let value = sin(2 * .pi * tone.hz * t) * amplitude * envelope
                let mixed = Double(samples[i]) / 32767.0 + value
                samples[i] = Int16(max(-1, min(1, mixed)) * 32767)
            }
        }

        var data = Data()
        func append(_ string: String) { data.append(contentsOf: string.utf8) }
        func append32(_ value: UInt32) { var v = value.littleEndian; data.append(Data(bytes: &v, count: 4)) }
        func append16(_ value: UInt16) { var v = value.littleEndian; data.append(Data(bytes: &v, count: 2)) }

        let pcmBytes = count * 2
        append("RIFF")
        append32(UInt32(36 + pcmBytes))
        append("WAVEfmt ")
        append32(16)
        append16(1)
        append16(1)
        append32(UInt32(rate))
        append32(UInt32(rate * 2))
        append16(2)
        append16(16)
        append("data")
        append32(UInt32(pcmBytes))
        samples.withUnsafeBytes { data.append(contentsOf: $0) }
        return data
    }
}

extension AppModel {
    /// Read by the sound player without holding the model.
    @MainActor static var sharedSoundEnabled = true
}
