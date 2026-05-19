import Foundation

enum VexloStrings {
    enum HUD {
        static let best = localized("hud.best", value: "BEST")
        static let today = localized("hud.today", value: "TODAY")
        static let score = localized("hud.score", value: "SCORE")
        static let title = localized("hud.title", value: "VEXLO")
        static let mainRun = localized("hud.main_run", value: "Main Run")
        static let boardReading = localized("hud.board_reading", value: "Board reading")
        static let todaysChallenge = localized("hud.todays_challenge", value: "Today's Challenge")
        static let todaysBoard = localized("hud.todays_board", value: "Today's Board")

        static func todaysChallenge(streak: Int) -> String {
            String(format: localized("hud.todays_challenge_streak", value: "Today's Challenge • %d"), streak)
        }

        static func todaysChallenge(weekday: String) -> String {
            String(format: localized("hud.todays_challenge_weekday", value: "Today's Challenge • %@"), weekday)
        }

        static func todaysBoard(weekday: String) -> String {
            String(format: localized("hud.todays_board_weekday", value: "Today's Board • %@"), weekday)
        }

        static func dailyBoard(weekday: String) -> String {
            String(format: localized("hud.daily_board_weekday", value: "%@ Board"), weekday)
        }
    }

    enum DailyRitual {
        static func characterName(for tone: DailyToneVariant) -> String {
            switch tone {
            case .glacial:
                return localized("daily.character.spacious", value: "Spacious")
            case .lucid:
                return localized("daily.character.balanced", value: "Balanced")
            case .iris:
                return localized("daily.character.focused", value: "Focused")
            }
        }

        static func arrivalLine(weekday: String) -> String {
            if weekday.isEmpty {
                return localized("daily.arrival", value: "Today's board")
            }
            return String(
                format: localized("daily.arrival_weekday_board", value: "%@ board"),
                weekday
            )
        }

        static func ritualHeadline(weekday: String, characterName: String) -> String {
            if weekday.isEmpty {
                return String(
                    format: localized("daily.headline.character_board", value: "%@ Board"),
                    characterName
                )
            }
            return String(
                format: localized("daily.headline.weekday_character_board", value: "%@ · %@ Board"),
                weekday,
                characterName
            )
        }

        static func resultDetail(characterName: String) -> String {
            String(format: localized("daily.result.detail", value: "%@ read"), characterName)
        }

        static func completionCaption(weekday: String) -> String {
            if weekday.isEmpty {
                return localized("daily.completion.caption_today", value: "Today complete")
            }
            return String(
                format: localized("daily.completion.caption_weekday", value: "%@ · Complete"),
                weekday
            )
        }

        static func closureDetail(characterName: String) -> String {
            String(
                format: localized("daily.result.closure", value: "%@ board complete"),
                characterName
            )
        }

        static var todayRecorded: String {
            localized("daily.result.recorded", value: "Today recorded")
        }

        static func continuity(days: Int) -> String {
            String(format: localized("daily.continuity", value: "Continuity · %d"), days)
        }
    }

    enum Overlay {
        static let gameOver = localized("overlay.game_over", value: "Game Over")
        static let dailyComplete = localized("overlay.daily_complete", value: "Daily Complete")
        static let gameCenter = localized("overlay.game_center", value: "Game Center")
        static let leaderboard = localized("overlay.leaderboard", value: "Leaderboard")
        static let shareResult = localized("overlay.share_result", value: "Share Result")
        static let supporterPack = localized("overlay.supporter_pack", value: "Supporter Pack")
        static let supporterPackValue = localized("overlay.supporter_pack_value", value: "Supporter Pack • Ad-Free Continue + Reroll")
        static let restorePurchases = localized("overlay.restore_purchases", value: "Restore Purchases")
        static let exportDiagnostics = localized("overlay.export_diagnostics", value: "Export Diagnostics")
        static let continueRun = localized("overlay.continue_run", value: "Continue Run")
        static let playAgain = localized("overlay.play_again", value: "Play Again")
        static let dailyReplayForBest = localized("overlay.daily_replay", value: "Replay for best")
        static let bestToday = localized("overlay.best_today", value: "Best Today")
        static let newBest = localized("overlay.new_best", value: "New Best")
        static let supporterOwned = localized("overlay.supporter_owned", value: "Supporter Owned")
        static let challengeFriends = localized("overlay.challenge_friends", value: "Challenge Friends")
        static let playTogether = localized("overlay.play_together", value: "Play Together")
        static let share = localized("overlay.share", value: "Share")
        static let oneCleanerRun = localized("overlay.one_cleaner_run", value: "One cleaner run was there")
        static let runRecoveredLate = localized("overlay.run_recovered_late", value: "Late recovery")
        static let runChainLed = localized("overlay.run_chain_led", value: "Chain-led")
        static let runSteadyClears = localized("overlay.run_steady_clears", value: "Steady clears")
        static let runTightBoard = localized("overlay.run_tight_board", value: "Tight board")

        static func runCount(_ value: Int) -> String {
            String(format: localized("overlay.run_count", value: "Run %d"), value)
        }

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
        static let startNewRun = localized("utility.start_new_run", value: "Start New Run")
        static let studio = localized("utility.studio", value: "Northfall Studio")
        static let startNewRunAlertTitle = localized("utility.start_new_run_alert_title", value: "Start New Run?")
        static let startNewRunAlertMessage = localized("utility.start_new_run_alert_message", value: "Your current run will be abandoned.")
        static let cancel = localized("utility.cancel", value: "Cancel")
    }

    enum Onboarding {
        static let dragToBoard = localized("onboarding.drag_to_board", value: "Drag a piece to the board")
        static let completeLine = localized("onboarding.complete_line", value: "Chain the next clear to lift score")
        static let chainBuildsScore = localized("onboarding.chain_builds_score", value: "Consecutive clears build a chain")

        static func comboClear(_ value: Int) -> String {
            String(format: localized("onboarding.combo_multi_clear", value: "Combo ×%d"), value)
        }

        static func chainStreak(_ value: Int) -> String {
            String(format: localized("onboarding.chain_streak", value: "Chain ×%d"), value)
        }
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
        static let shareResult = localized("accessibility.share_result", value: "Share Result")
        static let shareResultHint = localized("accessibility.share_result_hint", value: "Opens the native share sheet")
        static let continueRunHint = localized("accessibility.continue_run_hint", value: "Watch a rewarded video to continue this run when available")
        static let playAgainHint = localized("accessibility.play_again_hint", value: "Starts a new run")
        static let dailyReplayForBestHint = localized(
            "accessibility.daily_replay_hint",
            value: "Starts another attempt to improve today's best"
        )
        static let supporterPackHint = localized("accessibility.supporter_pack_hint", value: "Unlocks ad-free continue and reroll when available")
        static let restorePurchasesHint = localized("accessibility.restore_purchases_hint", value: "Restores your previous purchase")
        static let exportDiagnosticsHint = localized("accessibility.export_diagnostics_hint", value: "Shares a tester diagnostics snapshot")
        static let startNewRun = localized("accessibility.start_new_run", value: "Start New Run")
        static let startNewRunHint = localized("accessibility.start_new_run_hint", value: "Starts a fresh run after confirmation.")
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
