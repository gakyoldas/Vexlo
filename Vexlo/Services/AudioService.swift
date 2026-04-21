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
        let preferredExtensions: [String]
        let cooldown: TimeInterval
        let priority: Int
        let volume: Float
        let maxSimultaneousPlayers: Int
    }

    private enum Keys {
        static let soundEnabled = ICloudProgressSyncService.Keys.soundEnabled
    }

    private let defaults = UserDefaults.standard
    private let session = AVAudioSession.sharedInstance()
    private var cachedURLs: [Event: URL] = [:]
    private var missingEvents: Set<Event> = []
    private var activePlayers: [AVAudioPlayer] = []
    private var activePlayerEvents: [ObjectIdentifier: Event] = [:]
    private var lastPlaybackDates: [Event: Date] = [:]
    private var lastGlobalPlaybackDate: Date = .distantPast
    private var lastGlobalPriority: Int = 0
    private var sessionPrepared = false

    private init() {}

    var isEnabled: Bool {
        get { defaults.object(forKey: Keys.soundEnabled) as? Bool ?? true }
        set {
            defaults.set(newValue, forKey: Keys.soundEnabled)
            ICloudProgressSyncService.shared.publishBooleanPreference(key: Keys.soundEnabled, value: newValue)
        }
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
        cleanupFinishedPlayers()
        let activeCountForEvent = activePlayers.reduce(into: 0) { count, player in
            if activePlayerEvents[ObjectIdentifier(player)] == event, player.isPlaying {
                count += 1
            }
        }
        guard activeCountForEvent < definition.maxSimultaneousPlayers else { return }
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return }
        player.volume = definition.volume
        player.prepareToPlay()
        activePlayers.append(player)
        activePlayerEvents[ObjectIdentifier(player)] = event
        if player.play() {
            lastPlaybackDates[event] = now
            lastGlobalPlaybackDate = now
            lastGlobalPriority = definition.priority
        } else {
            activePlayers.removeAll { $0 === player }
            activePlayerEvents.removeValue(forKey: ObjectIdentifier(player))
        }
    }

    private func prepareSessionIfNeeded() {
        guard !sessionPrepared else { return }
        sessionPrepared = true
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true, options: [])
    }

    private func cleanupFinishedPlayers() {
        activePlayers.removeAll { player in
            let finished = !player.isPlaying
            if finished {
                activePlayerEvents.removeValue(forKey: ObjectIdentifier(player))
            }
            return finished
        }
    }

    private func soundURL(for event: Event) -> URL? {
        if let cached = cachedURLs[event] {
            return cached
        }
        if missingEvents.contains(event) {
            return nil
        }
        let baseName = definition(for: event).baseName
        for ext in definition(for: event).preferredExtensions {
            if let url = Bundle.main.url(forResource: baseName, withExtension: ext) {
                cachedURLs[event] = url
                missingEvents.remove(event)
                return url
            }
        }
        missingEvents.insert(event)
        return nil
    }

    private func definition(for event: Event) -> SoundDefinition {
        switch event {
        case .placement:
            return SoundDefinition(
                baseName: "sfx_place",
                preferredExtensions: ["caf", "wav", "m4a"],
                cooldown: 0.09,
                priority: 2,
                volume: 0.36,
                maxSimultaneousPlayers: 1
            )
        case .clear:
            return SoundDefinition(
                baseName: "sfx_clear",
                preferredExtensions: ["caf", "wav", "m4a"],
                cooldown: 0.16,
                priority: 4,
                volume: 0.5,
                maxSimultaneousPlayers: 1
            )
        case .combo:
            return SoundDefinition(
                baseName: "sfx_combo",
                preferredExtensions: ["caf", "wav", "m4a"],
                cooldown: 0.24,
                priority: 5,
                volume: 0.42,
                maxSimultaneousPlayers: 1
            )
        case .fail:
            return SoundDefinition(
                baseName: "sfx_fail",
                preferredExtensions: ["caf", "wav", "m4a"],
                cooldown: 0.38,
                priority: 3,
                volume: 0.34,
                maxSimultaneousPlayers: 1
            )
        case .bestScore:
            return SoundDefinition(
                baseName: "sfx_best",
                preferredExtensions: ["caf", "wav", "m4a"],
                cooldown: 0.4,
                priority: 5,
                volume: 0.44,
                maxSimultaneousPlayers: 1
            )
        case .continueResume:
            return SoundDefinition(
                baseName: "sfx_continue",
                preferredExtensions: ["caf", "wav", "m4a"],
                cooldown: 0.28,
                priority: 3,
                volume: 0.38,
                maxSimultaneousPlayers: 1
            )
        case .rerollSuccess:
            return SoundDefinition(
                baseName: "sfx_reroll",
                preferredExtensions: ["caf", "wav", "m4a"],
                cooldown: 0.22,
                priority: 2,
                volume: 0.34,
                maxSimultaneousPlayers: 1
            )
        }
    }
}
