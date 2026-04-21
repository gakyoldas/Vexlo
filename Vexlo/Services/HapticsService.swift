import CoreHaptics
import UIKit

final class HapticsService {
    static let shared = HapticsService()
    private enum Keys {
        static let hapticsEnabled = ICloudProgressSyncService.Keys.hapticsEnabled
    }

    private let defaults = UserDefaults.standard
    private let supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
    private var engine: CHHapticEngine?

    private init() {
        guard supportsHaptics else { return }
        engine = try? CHHapticEngine()
        try? engine?.start()
        engine?.resetHandler = { [weak self] in
            try? self?.engine?.start()
        }
        engine?.stoppedHandler = { [weak self] _ in
            try? self?.engine?.start()
        }
    }

    var isEnabled: Bool {
        get { defaults.object(forKey: Keys.hapticsEnabled) as? Bool ?? true }
        set {
            defaults.set(newValue, forKey: Keys.hapticsEnabled)
            ICloudProgressSyncService.shared.publishBooleanPreference(key: Keys.hapticsEnabled, value: newValue)
        }
    }

    var isSupported: Bool {
        supportsHaptics
    }

    func playPlace() {
        play(intensity: 0.6, sharpness: 0.8, duration: 0.08)
    }

    func playClear() {
        play(intensity: 1.0, sharpness: 0.3, duration: 0.25)
    }

    func playInvalid() {
        play(intensity: 0.3, sharpness: 1.0, duration: 0.05)
    }

    func playCombo() {
        play(intensity: 1.0, sharpness: 0.6, duration: 0.35)
    }

    private func play(intensity: Float, sharpness: Float, duration: TimeInterval) {
        guard isEnabled else { return }
        guard let engine else { return }
        let i = CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
        let s = CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [i, s],
            relativeTime: 0,
            duration: duration
        )
        guard let pattern = try? CHHapticPattern(events: [event], parameters: []),
              let player = try? engine.makePlayer(with: pattern) else { return }
        try? player.start(atTime: CHHapticTimeImmediate)
    }
}
