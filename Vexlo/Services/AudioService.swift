import AVFoundation
import Foundation

final class AudioService {
    enum Event: CaseIterable {
        case placement
        case clear
        case combo
        case fail
        case bestScore
        case continueResume
        case rerollSuccess
    }

    static let shared = AudioService()

    private struct SoundDefinition {
        let baseName: String
        let cooldown: TimeInterval
        let priority: Int
        let volume: Float
    }

    private enum Keys {
        static let soundEnabled = "nf_vexlo_sound_enabled"
    }

    private let defaults = UserDefaults.standard
    private let session = AVAudioSession.sharedInstance()
    private var cachedURLs: [Event: URL] = [:]
    private var activePlayers: [AVAudioPlayer] = []
    private var lastPlaybackDates: [Event: Date] = [:]
    private var lastGlobalPlaybackDate: Date = .distantPast
    private var lastGlobalPriority: Int = 0
    private var sessionPrepared = false

    private init() {}

    var isEnabled: Bool {
        get { defaults.object(forKey: Keys.soundEnabled) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.soundEnabled) }
    }

    func play(_ event: Event) {
        guard isEnabled, !LaunchSupport.shared.isCaptureMode else { return }
        let definition = definition(for: event)
        let now = Date()
        if let last = lastPlaybackDates[event], now.timeIntervalSince(last) < definition.cooldown {
            return
        }
        let timeSinceGlobal = now.timeIntervalSince(lastGlobalPlaybackDate)
        if timeSinceGlobal < 0.06 && definition.priority < lastGlobalPriority {
            return
        }
        guard let url = soundURL(for: event) else { return }
        prepareSessionIfNeeded()
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return }
        player.volume = definition.volume
        player.prepareToPlay()
        cleanupFinishedPlayers()
        activePlayers.append(player)
        if player.play() {
            lastPlaybackDates[event] = now
            lastGlobalPlaybackDate = now
            lastGlobalPriority = definition.priority
        } else {
            activePlayers.removeAll { $0 === player }
        }
    }

    private func prepareSessionIfNeeded() {
        guard !sessionPrepared else { return }
        sessionPrepared = true
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true, options: [])
    }

    private func cleanupFinishedPlayers() {
        activePlayers.removeAll { !$0.isPlaying }
    }

    private func soundURL(for event: Event) -> URL? {
        if let cached = cachedURLs[event] {
            return cached
        }
        let baseName = definition(for: event).baseName
        let extensions = ["caf", "wav", "m4a"]
        for ext in extensions {
            if let url = Bundle.main.url(forResource: baseName, withExtension: ext) {
                cachedURLs[event] = url
                return url
            }
        }
        return nil
    }

    private func definition(for event: Event) -> SoundDefinition {
        switch event {
        case .placement:
            return SoundDefinition(baseName: "sfx_place", cooldown: 0.06, priority: 2, volume: 0.48)
        case .clear:
            return SoundDefinition(baseName: "sfx_clear", cooldown: 0.14, priority: 4, volume: 0.56)
        case .combo:
            return SoundDefinition(baseName: "sfx_combo", cooldown: 0.2, priority: 5, volume: 0.5)
        case .fail:
            return SoundDefinition(baseName: "sfx_fail", cooldown: 0.35, priority: 3, volume: 0.42)
        case .bestScore:
            return SoundDefinition(baseName: "sfx_best", cooldown: 0.35, priority: 5, volume: 0.5)
        case .continueResume:
            return SoundDefinition(baseName: "sfx_continue", cooldown: 0.25, priority: 3, volume: 0.46)
        case .rerollSuccess:
            return SoundDefinition(baseName: "sfx_reroll", cooldown: 0.18, priority: 2, volume: 0.44)
        }
    }
}
