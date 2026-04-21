import Foundation

enum VexloStrings {
    enum HUD {
        static let best = localized("hud.best", value: "BEST")
        static let today = localized("hud.today", value: "TODAY")
        static let score = localized("hud.score", value: "SCORE")
        static let title = localized("hud.title", value: "VEXLO")
        static let mainRun = localized("hud.main_run", value: "Main Run")
        static let todaysChallenge = localized("hud.todays_challenge", value: "Today's Challenge")

        static func todaysChallenge(streak: Int) -> String {
            String(format: localized("hud.todays_challenge_streak", value: "Today's Challenge • %d"), streak)
        }
    }

    enum Overlay {
        static let gameOver = localized("overlay.game_over", value: "Game Over")
        static let dailyComplete = localized("overlay.daily_complete", value: "Daily Complete")
        static let gameCenter = localized("overlay.game_center", value: "Game Center")
        static let leaderboard = localized("overlay.leaderboard", value: "Leaderboard")
        static let supporterPack = localized("overlay.supporter_pack", value: "Supporter Pack")
        static let restorePurchases = localized("overlay.restore_purchases", value: "Restore Purchases")
        static let exportDiagnostics = localized("overlay.export_diagnostics", value: "Export Diagnostics")
        static let continueRun = localized("overlay.continue_run", value: "Continue Run")
        static let playAgain = localized("overlay.play_again", value: "Play Again")
        static let bestToday = localized("overlay.best_today", value: "Best Today")
        static let newBest = localized("overlay.new_best", value: "New Best")
        static let supporterOwned = localized("overlay.supporter_owned", value: "Supporter Owned")
        static let challengeFriends = localized("overlay.challenge_friends", value: "Challenge Friends")
        static let playTogether = localized("overlay.play_together", value: "Play Together")
        static let oneCleanerRun = localized("overlay.one_cleaner_run", value: "Tied Best")

        static func streak(_ value: Int) -> String {
            String(format: localized("overlay.streak_format", value: "Streak %d"), value)
        }

        static func gapToBest(_ value: Int) -> String {
            String(format: localized("overlay.gap_to_best", value: "%d to best"), value)
        }
    }

    enum Utility {
        static let soundOn = localized("utility.sound_on", value: "Sound On")
        static let soundOff = localized("utility.sound_off", value: "Sound Off")
        static let hapticsOn = localized("utility.haptics_on", value: "Haptics On")
        static let hapticsOff = localized("utility.haptics_off", value: "Haptics Off")
    }

    enum Onboarding {
        static let dragToBoard = localized("onboarding.drag_to_board", value: "Drag a piece to the board")
        static let completeLine = localized("onboarding.complete_line", value: "Complete a line to clear")
    }

    enum Accessibility {
        static let utilityMenu = localized("accessibility.utility_menu", value: "Utility")
        static let utilityMenuHint = localized("accessibility.utility_menu_hint", value: "Opens game controls")
        static let modeSwitchToDaily = localized("accessibility.mode_switch_daily", value: "Today's Challenge")
        static let modeSwitchToDailyHint = localized("accessibility.mode_switch_daily_hint", value: "Starts today's daily challenge")
        static let modeSwitchToMain = localized("accessibility.mode_switch_main", value: "Main Run")
        static let modeSwitchToMainHint = localized("accessibility.mode_switch_main_hint", value: "Returns to the main run")
        static let leaderboard = localized("accessibility.leaderboard", value: "Leaderboard")
        static let leaderboardHint = localized("accessibility.leaderboard_hint", value: "Shows Game Center scores")
        static let dailyActivity = localized("accessibility.daily_activity", value: "Daily Activity")
        static let dailyActivityHint = localized("accessibility.daily_activity_hint", value: "Opens today's Game Center activity")
        static let challengeFriends = localized("accessibility.challenge_friends", value: "Challenge Friends")
        static let challengeFriendsHint = localized("accessibility.challenge_friends_hint", value: "Opens the Game Center challenge flow")
        static let playTogether = localized("accessibility.play_together", value: "Play Together")
        static let playTogetherHint = localized("accessibility.play_together_hint", value: "Opens the Game Center activity")
        static let continueRunHint = localized("accessibility.continue_run_hint", value: "Watch a rewarded video to continue this run when available")
        static let playAgainHint = localized("accessibility.play_again_hint", value: "Starts a new run")
        static let supporterPackHint = localized("accessibility.supporter_pack_hint", value: "Unlocks ad-free continue and reroll when available")
        static let restorePurchasesHint = localized("accessibility.restore_purchases_hint", value: "Restores your previous purchase")
        static let exportDiagnosticsHint = localized("accessibility.export_diagnostics_hint", value: "Shares a tester diagnostics snapshot")
        static let rerollPiece = localized("accessibility.reroll_piece", value: "Reroll Piece")
        static let rerollPieceHint = localized("accessibility.reroll_piece_hint", value: "Replaces this tray piece when a reroll is available")
        static let soundState = localized("accessibility.sound_state", value: "Sound")
        static let hapticsState = localized("accessibility.haptics_state", value: "Haptics")
        static let on = localized("accessibility.state_on", value: "On")
        static let off = localized("accessibility.state_off", value: "Off")
        static let gameOverSummary = localized("accessibility.game_over_summary", value: "Run complete")
        static let dailyCompleteSummary = localized("accessibility.daily_complete_summary", value: "Daily challenge complete")
    }

    enum Intents {
        static let startTodayTitle = LocalizedStringResource("intent.start_today.title")
        static let startTodayDescription = LocalizedStringResource("intent.start_today.description")
        static let startTodayDialog = LocalizedStringResource("intent.start_today.dialog")
        static let startTodayShortTitle = LocalizedStringResource("intent.start_today.short_title")

        static let resumeTitle = LocalizedStringResource("intent.resume.title")
        static let resumeDescription = LocalizedStringResource("intent.resume.description")
        static let resumeDialog = LocalizedStringResource("intent.resume.dialog")
        static let noResumableRunDialog = LocalizedStringResource("intent.resume.unavailable")
        static let resumeShortTitle = LocalizedStringResource("intent.resume.short_title")
    }

    private static func localized(_ key: String, value: String) -> String {
        NSLocalizedString(key, tableName: nil, bundle: .main, value: value, comment: "")
    }
}
