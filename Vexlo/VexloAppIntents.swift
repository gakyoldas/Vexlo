import AppIntents

struct StartTodaysChallengeIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.start_today.title"
    static var description = IntentDescription("intent.start_today.description")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult & ProvidesDialog {
        SystemEntryService.shared.queue(.todayChallenge)
        return .result(dialog: IntentDialog(VexloStrings.Intents.startTodayDialog))
    }
}

struct ResumeLastRunIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.resume.title"
    static var description = IntentDescription("intent.resume.description")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard SystemEntryService.shared.canResumeLastRun else {
            return .result(dialog: IntentDialog(VexloStrings.Intents.noResumableRunDialog))
        }
        SystemEntryService.shared.queue(.resumeLastRun)
        return .result(dialog: IntentDialog(VexloStrings.Intents.resumeDialog))
    }
}

struct VexloAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        return [
            AppShortcut(
                intent: StartTodaysChallengeIntent(),
                phrases: [
                    "Start today's challenge in \(.applicationName)",
                    "Open today's challenge in \(.applicationName)"
                ],
                shortTitle: "intent.start_today.short_title",
                systemImageName: "calendar"
            ),
            AppShortcut(
                intent: ResumeLastRunIntent(),
                phrases: [
                    "Resume my run in \(.applicationName)",
                    "Open my last run in \(.applicationName)"
                ],
                shortTitle: "intent.resume.short_title",
                systemImageName: "play.circle"
            )
        ]
    }

    static var shortcutTileColor: ShortcutTileColor {
        .blue
    }
}
