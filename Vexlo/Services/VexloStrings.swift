import Foundation

enum VexloStrings {
    enum HUD {
        static let best = localized("hud.best", value: "BEST")
        static let today = localized("hud.today", value: "TODAY")
        static let score = localized("hud.score", value: "SCORE")
        static let title = localized("hud.title", value: "VEXLO")
        static let mainRun = localized("hud.main_run", value: "Main Run")
        static let boardReading = localized("hud.board_reading", value: "Board reading")
        static let runOpen = localized("hud.run_open", value: "Run open")
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

        static var modestFootholdDetail: String {
            localized("daily.modest_foothold_detail", value: "Today's foothold — more still in the board")
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
        static let playCleanerRun = localized("overlay.play_cleaner_run", value: "Play a Cleaner Run")
        static let dailyReplayForBest = localized("overlay.daily_replay", value: "Replay for best")
        static let bestToday = localized("overlay.best_today", value: "Best Today")
        static let newBest = localized("overlay.new_best", value: "New Best")
        static let supporterOwned = localized("overlay.supporter_owned", value: "Supporter Owned")
        static let challengeFriends = localized("overlay.challenge_friends", value: "Challenge Friends")
        static let playTogether = localized("overlay.play_together", value: "Play Together")
        static let share = localized("overlay.share", value: "Share")
        static let yourBestRunYet = localized("overlay.your_best_run_yet", value: "Your best run yet")
        static let closeToBest = localized("overlay.close_to_best", value: "Close to best")
        static let oneCleanerReadGoesFartherStill = localized(
            "overlay.one_cleaner_read_goes_farther_still",
            value: "One cleaner read goes farther still"
        )
        static let oneCleanerReadGoesFarther = localized(
            "overlay.one_cleaner_read_goes_farther",
            value: "One cleaner read goes farther"
        )
        static let runRecoveredLate = localized("overlay.run_recovered_late", value: "Recovery came late")
        static let runChainLed = localized("overlay.run_chain_led", value: "Chain-led")
        static let runSteadyClears = localized("overlay.run_steady_clears", value: "Clear rhythm held")
        static let runTightBoard = localized("overlay.run_tight_board", value: "No clear found")
        static let boardClosedEarly = localized("overlay.board_closed_early", value: "Board closed early")
        static let readUnderPressure = localized("overlay.read_under_pressure", value: "Read under pressure")
        static let stabilizeOneTurnEarlier = localized("overlay.stabilize_one_turn_earlier", value: "Stabilize one turn earlier")
        static let rematchReleaseEarlier = localized("overlay.rematch_release_earlier", value: "Release pressure one line earlier")
        static let keepOneLaneOpenEarlier = localized("overlay.keep_one_lane_open_earlier", value: "Keep one lane open earlier")
        static let rematchKeepAnchorOpen = localized("overlay.rematch_keep_anchor_open", value: "Keep one anchor open through the turn")
        static let keepOneAnchorFree = localized("overlay.keep_one_anchor_free", value: "Keep one anchor free")
        static let rematchOpenLaneEarlier = localized("overlay.rematch_open_lane_earlier", value: "Open one lane earlier next run")
        static let oneCleanerBoardGoesFarther = localized("overlay.one_cleaner_board_goes_farther", value: "One cleaner board goes farther")
        static let oneCleanerBoardPressesBest = localized("overlay.one_cleaner_board_presses_best", value: "One cleaner board presses today's best")
        static let clearRhythmConversionStillThin = localized(
            "overlay.clear_rhythm_conversion_still_thin",
            value: "Rhythm held, conversion still thin"
        )
        static let clearRhythmLanesClosedIn = localized(
            "overlay.clear_rhythm_lanes_closed_in",
            value: "Held together, but lanes closed in"
        )
        static let clearRhythmNotExtended = localized(
            "overlay.clear_rhythm_not_extended",
            value: "Stable clears, rhythm not extended"
        )
        static let chainLedConversionStillThin = localized(
            "overlay.chain_led_conversion_still_thin",
            value: "Chain read landed, conversion still thin"
        )
        static let chainLedOpennessSlipped = localized(
            "overlay.chain_led_openness_slipped",
            value: "Reading held, openness slipped"
        )
        static let chainLedPaceDidNotHold = localized(
            "overlay.chain_led_pace_did_not_hold",
            value: "Chains opened, pace did not hold"
        )
        static let dailyModestBoardStillHasMore = localized(
            "overlay.daily_modest_board_still_has_more",
            value: "The board still has more in it today"
        )

        static func streak(_ value: Int) -> String {
            String(format: localized("overlay.streak_format", value: "Streak %d"), value)
        }

        static func gapToBest(_ value: Int) -> String {
            String(format: localized("overlay.gap_to_best", value: "Close %d to best"), value)
        }
    }

    enum AsyncCompetition {
        static let todaysTable = localized("async_competition.todays_table", value: "Today's table")
        static let sendReadingChallenge = localized(
            "async_competition.send_reading_challenge",
            value: "Send a reading challenge"
        )
        static let shareThisRun = localized("async_competition.share_this_run", value: "Share this run")
        static let allTimeScores = localized("async_competition.all_time_scores", value: "All-time scores")
        static let dailyShareSubjectDefault = localized(
            "async_competition.daily_share_subject",
            value: "Vexlo — Today's board"
        )
        static let dailyShareInviteLine = localized(
            "async_competition.daily_share_invite",
            value: "Play today's board in Vexlo."
        )

        static func dailyShareSubject(headline: String) -> String {
            String(
                format: localized("async_competition.daily_share_subject_headline", value: "Vexlo — %@"),
                headline
            )
        }
    }

    enum RunReading {
        static let runComplete = localized("run.complete", value: "Run complete")
        static let chainLedReading = localized("run.reading.chain_led", value: "Chain-led reading")
        static let readUnderPressure = localized("run.reading.under_pressure", value: "Read under pressure")
    }

    enum MonetizationAttachment {
        static let continueIntent = localized(
            "monetization.attach.continue_intent",
            value: "One honest recovery after a run that already had reading shape."
        )
        static let rerollIntent = localized(
            "monetization.attach.reroll_intent",
            value: "One tray reshuffle mid-run—never a gamble surface."
        )
        static let supporterIntent = localized(
            "monetization.attach.supporter_intent",
            value: "Patronage for quieter practice and craft support."
        )
        static let atelierIntent = localized(
            "monetization.attach.atelier_intent",
            value: "Durable self-expression through mineral finishes only."
        )

        static let continueFraming = localized(
            "monetization.attach.continue_framing",
            value: "Recover the run once when the read already had shape."
        )
        static let rerollFraming = localized(
            "monetization.attach.reroll_framing",
            value: "Reshuffle one tray piece during an active run."
        )
        static let supporterFraming = localized(
            "monetization.attach.supporter_framing",
            value: "Support the craft: quieter practice, ad-free continue and reroll."
        )
        static let atelierFraming = localized(
            "monetization.attach.atelier_framing",
            value: "Own calm mineral finishes—never power or pressure."
        )

        static let supporterSpineUninterrupted = localized(
            "monetization.attach.supporter_spine_practice",
            value: "Uninterrupted normal practice when offers are available."
        )
        static let supporterSpineEarnedMemory = localized(
            "monetization.attach.supporter_spine_memory",
            value: "Residue, mastery, codex, and reader memory stay earned—not sold."
        )
        static let supporterSpineNoPower = localized(
            "monetization.attach.supporter_spine_no_power",
            value: "No score, combo, or board-power grants."
        )
    }

    enum ReaderProfile {
        static let sectionHeader = localized("reader.section_header", value: "Reader")

        static let headlineChainLed = localized(
            "reader.headline.chain_led",
            value: "Lately, your reads have been chain-led."
        )
        static let headlineAnchorLed = localized(
            "reader.headline.anchor_led",
            value: "Lately, your reads hold steady anchors."
        )
        static let headlinePressureLed = localized(
            "reader.headline.pressure_led",
            value: "Lately, you read through pressure."
        )
        static let headlineLaneLed = localized(
            "reader.headline.lane_led",
            value: "Lately, lane shape has led your reads."
        )
        static let headlineRecoveryLed = localized(
            "reader.headline.recovery_led",
            value: "Lately, recovery has shaped your runs."
        )
        static let headlineTightBoard = localized(
            "reader.headline.tight_board",
            value: "Lately, the board has stayed tight."
        )

        static let strengthChainReader = localized(
            "reader.strength.chain_reader",
            value: "Chains convert when openness holds through the turn."
        )
        static let strengthPressureReader = localized(
            "reader.strength.pressure_reader",
            value: "You keep structure alive under pressure."
        )
        static let strengthAnchorReader = localized(
            "reader.strength.anchor_reader",
            value: "Clear rhythm holds when the board stays open."
        )
        static let strengthLaneReader = localized(
            "reader.strength.lane_reader",
            value: "You sense when lanes narrow before they close."
        )
        static let strengthRecoveryReader = localized(
            "reader.strength.recovery_reader",
            value: "You recover board shape after late slips."
        )

        static let strengthChainLed = localized(
            "reader.strength.chain_led",
            value: "Chain reads are landing when pace holds."
        )
        static let strengthAnchorLed = localized(
            "reader.strength.anchor_led",
            value: "Steady clears are carrying the run."
        )
        static let strengthPressureLed = localized(
            "reader.strength.pressure_led",
            value: "Pressure reads still find release."
        )
        static let strengthLaneLed = localized(
            "reader.strength.lane_led",
            value: "You notice board closure before it sets."
        )
        static let strengthRecoveryLed = localized(
            "reader.strength.recovery_led",
            value: "Late recovery is keeping runs alive."
        )
        static let strengthTightBoard = localized(
            "reader.strength.tight_board",
            value: "You stay with the board even when clears are thin."
        )
        static let strengthTightWithLanes = localized(
            "reader.strength.tight_lanes",
            value: "Lane reads appear once structure opens."
        )

        static let growthOpenLaneEarlier = localized(
            "reader.growth.open_lane",
            value: "More value appears when you open one lane earlier."
        )
        static let growthExtendChainConversion = localized(
            "reader.growth.extend_chain",
            value: "Let the next chain extend before the board closes."
        )
        static let growthReleaseUnderPressure = localized(
            "reader.growth.release_pressure",
            value: "Release pressure one turn earlier under a taut board."
        )
        static let growthKeepAnchorOpen = localized(
            "reader.growth.keep_anchor",
            value: "Keep one anchor open through the next read."
        )
        static let growthReleaseEarlier = localized(
            "reader.growth.release_earlier",
            value: "Earlier release will lighten the next pressure read."
        )
        static let growthStabilizeEarlier = localized(
            "reader.growth.stabilize_earlier",
            value: "Stabilize one turn earlier before recovery is needed."
        )
    }

    enum DailyCodex {
        static let ritualHeader = localized("codex.ritual_header", value: "Ritual")
        static let bestTodaySuffix = localized("codex.best_today_suffix", value: " · Best today")

        static func entryLine(weekday: String, phrase: String, score: Int) -> String {
            String(
                format: localized("codex.entry_line", value: "%@ · %@ · %d"),
                weekday,
                phrase,
                score
            )
        }
    }

    enum Mastery {
        static let laneReader = localized("mastery.lane_reader", value: "Lane reader")
        static let anchorReader = localized("mastery.anchor_reader", value: "Anchor reader")
        static let pressureReader = localized("mastery.pressure_reader", value: "Pressure reader")
        static let chainReader = localized("mastery.chain_reader", value: "Chain reader")
        static let recoveryReader = localized("mastery.recovery_reader", value: "Recovery reader")

        static func readingPattern(_ competencies: String) -> String {
            String(
                format: localized("mastery.reading_pattern", value: "Reading pattern: %@"),
                competencies
            )
        }
    }

    enum RunResidue {
        static let dailyStrongCompletion = localized("residue.daily_strong", value: "Strong board read")
        static let dailyModestCompletion = localized("residue.daily_modest", value: "Board foothold held")
        static let dailyWeakRecorded = localized("residue.daily_weak", value: "Recorded finish")
        static let dailyRecorded = localized("residue.daily_recorded", value: "Today's board")

        static func lastRead(phrase: String) -> String {
            String(format: localized("residue.last_read", value: "Last read: %@"), phrase)
        }

        static func lastDaily(weekday: String, phrase: String) -> String {
            if weekday.isEmpty {
                return String(
                    format: localized("residue.last_daily_no_weekday", value: "Last daily: %@"),
                    phrase
                )
            }
            return String(
                format: localized("residue.last_daily", value: "Last daily: %@ · %@"),
                weekday,
                phrase
            )
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
        static let firstClearLine = localized("onboarding.first_clear_line", value: "Line clear")
        static let firstClearRunOpen = localized(
            "onboarding.first_clear_run_open",
            value: "Structure cleared. Your run is scoring."
        )
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
        static let todaysTable = localized("accessibility.todays_table", value: "Today's table")
        static let todaysTableHint = localized(
            "accessibility.todays_table_hint",
            value: "Opens today's shared board in Game Center"
        )
        static let sendReadingChallenge = localized(
            "accessibility.send_reading_challenge",
            value: "Send a reading challenge"
        )
        static let sendReadingChallengeHint = localized(
            "accessibility.send_reading_challenge_hint",
            value: "Opens the Game Center challenge flow for this run"
        )
        static let shareThisRun = localized("accessibility.share_this_run", value: "Share this run")
        static let shareThisRunHint = localized(
            "accessibility.share_this_run_hint",
            value: "Opens the Game Center activity for this run"
        )
        static let allTimeScores = localized("accessibility.all_time_scores", value: "All-time scores")
        static let allTimeScoresHint = localized(
            "accessibility.all_time_scores_hint",
            value: "Shows Game Center all-time scores"
        )
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
