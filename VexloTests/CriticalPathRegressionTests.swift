import Foundation
import LinkPresentation
import Testing
import UIKit
@testable import Vexlo

struct CriticalPathRegressionTests {
    @Test
    func liveNormalRunSnapshotRoundTrips() throws {
        let engine = GameEngine()
        engine.startNormalRun(seed: 0xCAFE)

        let openingPiece = try #require(engine.pieces[0])
        let anchor = try #require(firstLegalAnchor(for: openingPiece, in: engine))
        engine.place(openingPiece, at: anchor, slotIndex: 0)

        let snapshot = try #require(engine.makeLiveRunSnapshot(runStartBest: 0))

        let restored = GameEngine()
        restored.restoreLiveRun(from: snapshot)
        let restoredSnapshot = try #require(restored.makeLiveRunSnapshot(runStartBest: 0))

        #expect(try encodedSnapshot(snapshot) == encodedSnapshot(restoredSnapshot))
    }

    @Test
    func terminalRunDoesNotProduceLiveSnapshot() {
        let engine = GameEngine()
        engine.loadCaptureTerminalState(
            mode: .normal,
            emptyCoordinates: Set([HexCoordinate(0, 0), HexCoordinate(3, 3), HexCoordinate(6, 6)]),
            tray: [
                HexPiece(offsets: [HexCoordinate(0, 0), HexCoordinate(0, 1)], color: UIColor(hex: "7A74F7")),
                HexPiece(offsets: [HexCoordinate(0, 0), HexCoordinate(1, 0)], color: UIColor(hex: "55A7F6")),
                HexPiece(offsets: [HexCoordinate(0, 0), HexCoordinate(1, 0), HexCoordinate(0, 1)], color: UIColor(hex: "63C7B0"))
            ],
            score: 240,
            best: 240,
            combo: 2,
            didClearAny: true,
            maxCombo: 2
        )

        #expect(engine.isGameOver)
        #expect(engine.makeLiveRunSnapshot(runStartBest: 180) == nil)
    }

    @Test
    func dailyChallengePathIsDeterministicForSameDay() throws {
        let dayID = "2025-01-15"
        let seed = DailyChallengeService.shared.seed(for: dayID)
        let left = GameEngine()
        let right = GameEngine()
        left.startDailyRun(dayID: dayID, seed: seed)
        right.startDailyRun(dayID: dayID, seed: seed)

        for slot in 0..<3 {
            let leftPiece = try #require(left.pieces[slot])
            let rightPiece = try #require(right.pieces[slot])
            #expect(pieceSignature(leftPiece) == pieceSignature(rightPiece))

            let anchor = try #require(firstLegalAnchor(for: leftPiece, in: left))
            #expect(right.canPlace(rightPiece, at: anchor))
            left.place(leftPiece, at: anchor, slotIndex: slot)
            right.place(rightPiece, at: anchor, slotIndex: slot)
        }

        #expect(left.board.snapshot.cells.map(\.coordinate) == right.board.snapshot.cells.map(\.coordinate))
        #expect(pieceSignatures(left.pieces) == pieceSignatures(right.pieces))
    }

    @Test
    func normalModeOpeningGenerationTightensEarlierThanExplicitBalancedBoardCharacterPath() {
        var normalGenerator = PieceFactory.SeededGenerator(seed: 2)
        var normalMemory = PieceFactory.GenerationMemory()
        let normalOpening = PieceFactory.openingBatch(count: 3, memory: &normalMemory, using: &normalGenerator)
        let normalRefill = PieceFactory.randomBatch(count: 3, occupiedCellCount: 5, memory: &normalMemory, using: &normalGenerator)

        var standardGenerator = PieceFactory.SeededGenerator(seed: 2)
        var standardMemory = PieceFactory.GenerationMemory()
        let standardOpening = PieceFactory.openingBatch(
            count: 3,
            memory: &standardMemory,
            using: &standardGenerator,
            boardCharacter: .balanced
        )
        let standardRefill = PieceFactory.randomBatch(
            count: 3,
            occupiedCellCount: 5,
            memory: &standardMemory,
            using: &standardGenerator,
            boardCharacter: .balanced
        )

        #expect(batchOffsetSignatures(normalOpening) == ["0:0|1:0", "0:0|1:0|1:1", "0:0|0:1|0:2"])
        #expect(batchOffsetSignatures(standardOpening) == ["0:0|0:1|1:0", "0:0|1:0", "0:0"])
        #expect(batchOffsetSignatures(normalRefill) == ["0:0|0:1|1:0", "0:0|0:1", "0:0|1:0|1:1"])
        #expect(batchOffsetSignatures(standardRefill) == ["0:0|1:0", "0:0|0:1|0:2", "0:0|1:0|1:1"])
    }

    @Test
    func dailyToneVariantMapsToAcceptedBoardCharacter() {
        #expect(DailyToneVariant.glacial.boardCharacter == .open)
        #expect(DailyToneVariant.lucid.boardCharacter == .balanced)
        #expect(DailyToneVariant.iris.boardCharacter == .focused)
    }

    @Test
    func dailyBeginSceneRunMarksArrivalPresentedForDay() throws {
        clearSharedResumeState()
        UserDefaults.standard.removeObject(forKey: "nf_vexlo_daily_arrival_presented_day_id")
        defer {
            UserDefaults.standard.removeObject(forKey: "nf_vexlo_daily_arrival_presented_day_id")
            clearSharedResumeState()
        }

        let dayID = "2025-01-15"
        let seed = DailyChallengeService.shared.seed(for: dayID)
        let scene = GameScene(size: CGSize(width: 390, height: 844))
        scene.testingBeginSceneRun(mode: .daily(dayID: dayID, seed: seed))

        #expect(scene.testingPresentedDailyArrivalDayID == dayID)
    }

    @Test
    func dailySceneStartUsesMappedBoardCharacter() throws {
        clearSharedResumeState()
        defer { clearSharedResumeState() }

        let dayID = "2025-01-15"
        let seed = DailyChallengeService.shared.seed(for: dayID)
        let expectedCharacter = DailyChallengeService.shared.toneVariant(for: dayID).boardCharacter

        let scene = GameScene(size: CGSize(width: 390, height: 844))
        scene.testingBeginSceneRun(mode: .daily(dayID: dayID, seed: seed))

        let snapshot = try #require(scene.testingMakeLiveRunSnapshot(runStartBest: 0))
        #expect(snapshot.runMode.runMode == .daily(dayID: dayID, seed: seed))
        #expect(snapshot.dailyBoardCharacterRawValue == expectedCharacter.rawValue)
    }

    @Test
    func dailyLiveRunSnapshotRestorePreservesBoardCharacter() throws {
        let dayID = "2025-01-17"
        let seed = DailyChallengeService.shared.seed(for: dayID)
        let boardCharacter = DailyToneVariant.iris.boardCharacter
        let engine = GameEngine()
        engine.startDailyRun(dayID: dayID, seed: seed, boardCharacter: boardCharacter)

        let openingPiece = try #require(engine.pieces[0])
        let anchor = try #require(firstLegalAnchor(for: openingPiece, in: engine))
        engine.place(openingPiece, at: anchor, slotIndex: 0)

        let snapshot = try #require(engine.makeLiveRunSnapshot(runStartBest: 0))
        let restored = GameEngine()
        restored.restoreLiveRun(from: snapshot)
        let restoredSnapshot = try #require(restored.makeLiveRunSnapshot(runStartBest: 0))

        #expect(snapshot.dailyBoardCharacterRawValue == boardCharacter.rawValue)
        #expect(restoredSnapshot.dailyBoardCharacterRawValue == boardCharacter.rawValue)
        #expect(try encodedSnapshot(snapshot) == encodedSnapshot(restoredSnapshot))
    }

    @Test
    func dailyChallengeSurfaceUsesQuietWeekdayCharacter() {
        let (defaults, suiteName) = makeDefaults()
        defer { clear(suiteName) }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        calendar.locale = Locale(identifier: "en_US_POSIX")
        let service = DailyChallengeService(defaults: defaults, calendar: calendar)

        #expect(service.weekdayTitle(for: "2025-01-15") == "Wednesday")
        let jan15Tone = service.toneVariant(for: "2025-01-15")
        #expect(service.toneVariant(for: "2025-01-15") == jan15Tone)
        let toneSet = Set([
            service.toneVariant(for: "2025-01-15").rawValue,
            service.toneVariant(for: "2025-01-16").rawValue,
            service.toneVariant(for: "2025-01-17").rawValue
        ])
        #expect(!toneSet.isEmpty)
        #expect(toneSet.allSatisfy { DailyToneVariant(rawValue: $0) != nil })
        #expect(VexloStrings.HUD.boardReading == "Board reading")
        #expect(VexloStrings.HUD.todaysBoard(weekday: "Wednesday") == "Today's Board • Wednesday")
        #expect(VexloStrings.HUD.dailyBoard(weekday: "Wednesday") == "Wednesday Board")
        #expect(GameScene.normalOpeningModeLabelText() == "Board reading")

        let wednesdayIdentity = DailyRitualIdentity.identity(
            for: "2025-01-15",
            weekdayTitle: "Wednesday",
            tone: jan15Tone
        )
        #expect(wednesdayIdentity.weekdayTitle == "Wednesday")
        #expect(wednesdayIdentity.tone == jan15Tone)
        #expect(wednesdayIdentity.arrivalLine == "Wednesday board")
        #expect(wednesdayIdentity.ritualHeadline == "Wednesday · \(wednesdayIdentity.characterName) Board")
        #expect(wednesdayIdentity.resultDetailLine == "\(wednesdayIdentity.characterName) read")
        #expect(wednesdayIdentity.continuityLine(streakCount: 3) == "Continuity · 3")
        #expect(DailyRitualIdentity.identity(
            for: "2025-01-15",
            weekdayTitle: "Wednesday",
            tone: jan15Tone
        ) == wednesdayIdentity)
    }

    @Test
    func dailyArrivalBeatShowsOncePerCalendarDay() {
        let (defaults, suiteName) = makeDefaults()
        defer { clear(suiteName) }

        let arrival = DailyArrivalRitualService(defaults: defaults)
        let dayID = "2025-01-15"

        #expect(arrival.shouldPresentArrival(for: dayID))
        arrival.markArrivalPresented(for: dayID)
        #expect(!arrival.shouldPresentArrival(for: dayID))
        #expect(arrival.presentedArrivalDayID() == dayID)
        #expect(arrival.shouldPresentArrival(for: "2025-01-16"))
    }

    @Test
    func dailyArrivalIdentityArrivalLineUsesWeekdayBeforeFullHeadline() {
        let identity = DailyRitualIdentity.identity(
            for: "2025-01-15",
            weekdayTitle: "Wednesday",
            tone: .iris
        )
        #expect(identity.arrivalLine == "Wednesday board")
        #expect(identity.ritualHeadline == "Wednesday · Focused Board")
        #expect(VexloStrings.DailyRitual.arrivalLine(weekday: "") == "Today's board")
    }

    @Test
    func dailyArrivalRitualDoesNotMutateDailyChallengeProgress() {
        let (defaults, suiteName) = makeDefaults()
        defer { clear(suiteName) }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        let service = DailyChallengeService(defaults: defaults, calendar: calendar)
        let arrival = DailyArrivalRitualService(defaults: defaults)
        let dayID = "2025-01-15"

        let beforeBest = service.bestScore(for: dayID)
        let beforeStreak = service.status(for: dayID).streakCount

        arrival.markArrivalPresented(for: dayID)

        #expect(service.bestScore(for: dayID) == beforeBest)
        #expect(service.status(for: dayID).streakCount == beforeStreak)
        #expect(service.seed(for: dayID) == DailyChallengeService.shared.seed(for: dayID))
        #expect(service.toneVariant(for: dayID) == service.toneVariant(for: dayID))
    }

    @Test
    func dailyRitualClosureMapsCompletionFactsToEditorialResultCopy() {
        let identity = DailyRitualIdentity.identity(
            for: "2025-01-15",
            weekdayTitle: "Wednesday",
            tone: .iris
        )
        let newBest = DailyRitualClosure.closure(
            identity: identity,
            completion: DailyChallengeCompletion(
                dayID: "2025-01-15",
                score: 80,
                isNewBestToday: true,
                todayBest: 80,
                streakCount: 3
            )
        )
        #expect(newBest.completionCaption == "Wednesday · Complete")
        #expect(newBest.closureDetail == "Focused board complete")
        #expect(newBest.badge == "Best Today")
        #expect(newBest.progress == "Continuity · 3")
        #expect(newBest.replayLabel == "Replay for best")

        let recorded = DailyRitualClosure.closure(
            identity: identity,
            completion: DailyChallengeCompletion(
                dayID: "2025-01-15",
                score: 42,
                isNewBestToday: false,
                todayBest: 80,
                streakCount: 3
            )
        )
        #expect(recorded.badge == "Today recorded")
        #expect(recorded.closureDetail == "Focused board complete")
        #expect(VexloStrings.DailyRitual.completionCaption(weekday: "") == "Today complete")
    }

    @Test
    func dailyRitualClosureDoesNotMutateDailyChallengeState() {
        let (defaults, suiteName) = makeDefaults()
        defer { clear(suiteName) }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        let service = DailyChallengeService(defaults: defaults, calendar: calendar)
        let dayID = "2025-01-15"
        let identity = DailyRitualIdentity.identity(
            for: dayID,
            weekdayTitle: service.weekdayTitle(for: dayID),
            tone: service.toneVariant(for: dayID)
        )
        let before = (
            best: service.bestScore(for: dayID),
            streak: service.status(for: dayID).streakCount,
            seed: service.seed(for: dayID)
        )

        _ = DailyRitualClosure.closure(
            identity: identity,
            completion: DailyChallengeCompletion(
                dayID: dayID,
                score: 55,
                isNewBestToday: false,
                todayBest: before.best,
                streakCount: 2
            )
        )

        #expect(service.bestScore(for: dayID) == before.best)
        #expect(service.status(for: dayID).streakCount == before.streak)
        #expect(service.seed(for: dayID) == before.seed)
    }

    @Test
    func dailyRitualIdentityMapsToneToEditorialCharacterNames() {
        #expect(VexloStrings.DailyRitual.characterName(for: .glacial) == "Spacious")
        #expect(VexloStrings.DailyRitual.characterName(for: .lucid) == "Balanced")
        #expect(VexloStrings.DailyRitual.characterName(for: .iris) == "Focused")
    }

    @Test
    func dailyRitualIdentityDoesNotMutateDailyChallengeState() {
        let (defaults, suiteName) = makeDefaults()
        defer { clear(suiteName) }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        let service = DailyChallengeService(defaults: defaults, calendar: calendar)
        let dayID = "2025-01-15"
        let before = (
            bestDay: defaults.string(forKey: ICloudProgressSyncService.Keys.dailyBestDayID),
            bestScore: defaults.integer(forKey: ICloudProgressSyncService.Keys.dailyBestScore),
            completedDay: defaults.string(forKey: ICloudProgressSyncService.Keys.dailyCompletedDayID),
            streak: defaults.integer(forKey: ICloudProgressSyncService.Keys.dailyStreakCount),
            lastStreakDay: defaults.string(forKey: ICloudProgressSyncService.Keys.dailyLastStreakDayID)
        )

        _ = DailyRitualIdentity.identity(
            for: dayID,
            weekdayTitle: service.weekdayTitle(for: dayID),
            tone: service.toneVariant(for: dayID)
        )
        _ = DailyRitualIdentity.identity(for: dayID)

        #expect(defaults.string(forKey: ICloudProgressSyncService.Keys.dailyBestDayID) == before.bestDay)
        #expect(defaults.integer(forKey: ICloudProgressSyncService.Keys.dailyBestScore) == before.bestScore)
        #expect(defaults.string(forKey: ICloudProgressSyncService.Keys.dailyCompletedDayID) == before.completedDay)
        #expect(defaults.integer(forKey: ICloudProgressSyncService.Keys.dailyStreakCount) == before.streak)
        #expect(defaults.string(forKey: ICloudProgressSyncService.Keys.dailyLastStreakDayID) == before.lastStreakDay)
    }

    @Test
    func dailyRitualIdentityLayerStaysReadOnlyPresentation() throws {
        let repoRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let identitySource = try String(
            contentsOf: repoRoot.appendingPathComponent("Vexlo/Services/DailyRitualIdentity.swift"),
            encoding: .utf8
        )
        let gameSceneSource = try String(
            contentsOf: repoRoot.appendingPathComponent("Vexlo/UI/GameScene.swift"),
            encoding: .utf8
        )
        #expect(!identitySource.contains("UserDefaults"))
        #expect(!identitySource.contains("completeRun"))
        #expect(!identitySource.contains("PieceFactory"))
        #expect(identitySource.contains("toneVariant(for:"))
        #expect(gameSceneSource.contains("DailyRitualIdentity.identity"))
        #expect(gameSceneSource.contains("ritualIdentity.ritualHeadline"))
        #expect(gameSceneSource.contains("DailyRitualClosure.closure"))
        #expect(!gameSceneSource.contains("resultDetailLine"))
        #expect(!gameSceneSource.contains("VexloStrings.Overlay.streak"))
        #expect(!gameSceneSource.contains("VexloStrings.Overlay.dailyComplete"))
    }

    @Test
    func dailyCompletionClosureLayerStaysReadOnlyPresentation() throws {
        let repoRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let closureSource = try String(
            contentsOf: repoRoot.appendingPathComponent("Vexlo/Services/DailyRitualClosure.swift"),
            encoding: .utf8
        )
        let gameSceneSource = try String(
            contentsOf: repoRoot.appendingPathComponent("Vexlo/UI/GameScene.swift"),
            encoding: .utf8
        )
        #expect(!closureSource.contains("completeRun"))
        #expect(!closureSource.contains("UserDefaults"))
        #expect(!closureSource.contains("seed(for:"))
        #expect(gameSceneSource.contains("restartText: ritualClosure.replayLabel"))
        #expect(gameSceneSource.contains("VexloStrings.Overlay.dailyReplayForBest"))
    }

    @Test
    func dailyArrivalBeatUsesSceneStartPathOnly() throws {
        let repoRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let gameSceneSource = try String(
            contentsOf: repoRoot.appendingPathComponent("Vexlo/UI/GameScene.swift"),
            encoding: .utf8
        )
        let arrivalServiceSource = try String(
            contentsOf: repoRoot.appendingPathComponent("Vexlo/Services/DailyArrivalRitualService.swift"),
            encoding: .utf8
        )
        #expect(gameSceneSource.contains("presentDailyArrivalBeatIfNeeded()"))
        #expect(gameSceneSource.contains("DailyArrivalRitualService.shared.shouldPresentArrival"))
        #expect(gameSceneSource.contains("identity.arrivalLine"))
        #expect(gameSceneSource.contains("isPresentingDailyArrivalBeat"))
        #expect(gameSceneSource.contains("syncAll()\n        presentDailyArrivalBeatIfNeeded()"))
        #expect(gameSceneSource.components(separatedBy: "presentDailyArrivalBeatIfNeeded").count == 3)
        #expect(!arrivalServiceSource.contains("completeRun"))
        #expect(!arrivalServiceSource.contains("seed(for:"))
        #expect(!arrivalServiceSource.contains("toneVariant"))
        #expect(!arrivalServiceSource.contains("PieceFactory"))
    }

    @Test
    func rerollReplacesOnlyOneTrayPieceAndPreservesRunState() throws {
        let engine = GameEngine()
        engine.startNormalRun(seed: 0xBEEF)

        let originalBoard = engine.board.snapshot
        let originalScore = engine.scoreEngine.score
        let originalPieces = pieceSignatures(engine.pieces)

        #expect(engine.canRerollPiece(at: 0))
        #expect(engine.rerollPiece(at: 0))

        let updatedPieces = pieceSignatures(engine.pieces)
        #expect(updatedPieces[0] != originalPieces[0])
        #expect(updatedPieces[1] == originalPieces[1])
        #expect(updatedPieces[2] == originalPieces[2])
        #expect(boardSignature(engine.board.snapshot) == boardSignature(originalBoard))
        #expect(engine.scoreEngine.score == originalScore)
        #expect(engine.hasUsedReroll)
    }

    @Test
    func liveRunPersistenceSavesLoadsAndRespectsCaptureSuppression() throws {
        let (defaults, suiteName) = makeDefaults()
        defer { clear(suiteName) }

        let engine = GameEngine()
        engine.startNormalRun(seed: 0x1234)
        let snapshot = try #require(engine.makeLiveRunSnapshot(runStartBest: 0))

        let persistence = LiveRunPersistenceService(defaults: defaults, isCaptureModeProvider: { false })
        persistence.save(snapshot)

        #expect(persistence.hasPersistedRun)
        let restored = try #require(persistence.load())
        #expect(try encodedSnapshot(snapshot) == encodedSnapshot(restored))

        let (captureDefaults, captureSuiteName) = makeDefaults()
        defer { clear(captureSuiteName) }
        let capturePersistence = LiveRunPersistenceService(defaults: captureDefaults, isCaptureModeProvider: { true })
        capturePersistence.save(snapshot)
        #expect(!capturePersistence.hasPersistedRun)
        #expect(capturePersistence.load() == nil)
    }

    @Test
    func systemEntryResumeReflectsTruthfulPersistedOrInMemoryState() {
        let none = SystemEntryService(hasPersistedRunProvider: { false })
        #expect(!none.canResumeLastRun)

        none.markRunActive(mode: .normal)
        #expect(none.canResumeLastRun)
        #expect(none.hasInMemoryResumableRun)

        none.clearResumableRun()
        #expect(!none.canResumeLastRun)

        let persisted = SystemEntryService(hasPersistedRunProvider: { true })
        #expect(persisted.canResumeLastRun)
        #expect(!persisted.hasInMemoryResumableRun)
        #expect(persisted.hasPersistedResumableRun)
    }

    @Test
    func onboardingHintsStaySuppressedOnceLearned() {
        let (defaults, suiteName) = makeDefaults()
        defer { clear(suiteName) }

        let onboarding = OnboardingService(defaults: defaults)
        #expect(onboarding.shouldShowPlacementHint)
        #expect(onboarding.shouldShowClearHint)

        onboarding.markPlacementLearned()
        #expect(!onboarding.shouldShowPlacementHint)
        #expect(onboarding.shouldShowClearHint)

        onboarding.markClearLearned()
        #expect(!onboarding.shouldShowPlacementHint)
        #expect(!onboarding.shouldShowClearHint)
    }

    @Test
    func firstSessionPlacementHintSurfaceOnlyShowsForFreshNormalOpeningState() {
        let state = GameScene.OnboardingSurfaceState(
            isCaptureMode: false,
            isDailyChallenge: false,
            isOverlayHidden: true,
            isUtilityPresented: false,
            isInteractionLocked: false,
            isShowingTransientHint: false,
            isDraggingPiece: false,
            shouldShowPlacementHint: true,
            score: 0,
            didClearAny: false,
            isBoardEmpty: true
        )

        #expect(state.canShowFirstSessionHintSurface)
        #expect(state.shouldShowPlacementHintSurface)
    }

    @Test
    func firstSessionPlacementHintSurfaceStaysSuppressedOutsidePrimaryOpeningContext() {
        let hiddenByContext = [
            GameScene.OnboardingSurfaceState(
                isCaptureMode: true,
                isDailyChallenge: false,
                isOverlayHidden: true,
                isUtilityPresented: false,
                isInteractionLocked: false,
                isShowingTransientHint: false,
                isDraggingPiece: false,
                shouldShowPlacementHint: true,
                score: 0,
                didClearAny: false,
                isBoardEmpty: true
            ),
            GameScene.OnboardingSurfaceState(
                isCaptureMode: false,
                isDailyChallenge: true,
                isOverlayHidden: true,
                isUtilityPresented: false,
                isInteractionLocked: false,
                isShowingTransientHint: false,
                isDraggingPiece: false,
                shouldShowPlacementHint: true,
                score: 0,
                didClearAny: false,
                isBoardEmpty: true
            ),
            GameScene.OnboardingSurfaceState(
                isCaptureMode: false,
                isDailyChallenge: false,
                isOverlayHidden: false,
                isUtilityPresented: false,
                isInteractionLocked: false,
                isShowingTransientHint: false,
                isDraggingPiece: false,
                shouldShowPlacementHint: true,
                score: 0,
                didClearAny: false,
                isBoardEmpty: true
            ),
            GameScene.OnboardingSurfaceState(
                isCaptureMode: false,
                isDailyChallenge: false,
                isOverlayHidden: true,
                isUtilityPresented: true,
                isInteractionLocked: false,
                isShowingTransientHint: false,
                isDraggingPiece: false,
                shouldShowPlacementHint: true,
                score: 0,
                didClearAny: false,
                isBoardEmpty: true
            ),
            GameScene.OnboardingSurfaceState(
                isCaptureMode: false,
                isDailyChallenge: false,
                isOverlayHidden: true,
                isUtilityPresented: false,
                isInteractionLocked: true,
                isShowingTransientHint: false,
                isDraggingPiece: false,
                shouldShowPlacementHint: true,
                score: 0,
                didClearAny: false,
                isBoardEmpty: true
            )
        ]

        for state in hiddenByContext {
            #expect(!state.canShowFirstSessionHintSurface)
            #expect(!state.shouldShowPlacementHintSurface)
        }
    }

    @Test
    func firstSessionPlacementHintSurfaceStaysSuppressedOnceOpeningStateHasProgressed() {
        let hiddenByRunState = [
            GameScene.OnboardingSurfaceState(
                isCaptureMode: false,
                isDailyChallenge: false,
                isOverlayHidden: true,
                isUtilityPresented: false,
                isInteractionLocked: false,
                isShowingTransientHint: true,
                isDraggingPiece: false,
                shouldShowPlacementHint: true,
                score: 0,
                didClearAny: false,
                isBoardEmpty: true
            ),
            GameScene.OnboardingSurfaceState(
                isCaptureMode: false,
                isDailyChallenge: false,
                isOverlayHidden: true,
                isUtilityPresented: false,
                isInteractionLocked: false,
                isShowingTransientHint: false,
                isDraggingPiece: true,
                shouldShowPlacementHint: true,
                score: 0,
                didClearAny: false,
                isBoardEmpty: true
            ),
            GameScene.OnboardingSurfaceState(
                isCaptureMode: false,
                isDailyChallenge: false,
                isOverlayHidden: true,
                isUtilityPresented: false,
                isInteractionLocked: false,
                isShowingTransientHint: false,
                isDraggingPiece: false,
                shouldShowPlacementHint: false,
                score: 0,
                didClearAny: false,
                isBoardEmpty: true
            ),
            GameScene.OnboardingSurfaceState(
                isCaptureMode: false,
                isDailyChallenge: false,
                isOverlayHidden: true,
                isUtilityPresented: false,
                isInteractionLocked: false,
                isShowingTransientHint: false,
                isDraggingPiece: false,
                shouldShowPlacementHint: true,
                score: 12,
                didClearAny: false,
                isBoardEmpty: true
            ),
            GameScene.OnboardingSurfaceState(
                isCaptureMode: false,
                isDailyChallenge: false,
                isOverlayHidden: true,
                isUtilityPresented: false,
                isInteractionLocked: false,
                isShowingTransientHint: false,
                isDraggingPiece: false,
                shouldShowPlacementHint: true,
                score: 0,
                didClearAny: true,
                isBoardEmpty: true
            ),
            GameScene.OnboardingSurfaceState(
                isCaptureMode: false,
                isDailyChallenge: false,
                isOverlayHidden: true,
                isUtilityPresented: false,
                isInteractionLocked: false,
                isShowingTransientHint: false,
                isDraggingPiece: false,
                shouldShowPlacementHint: true,
                score: 0,
                didClearAny: false,
                isBoardEmpty: false
            )
        ]

        for state in hiddenByRunState {
            #expect(state.canShowFirstSessionHintSurface)
            #expect(!state.shouldShowPlacementHintSurface)
        }
    }

    @Test
    func firstMinuteMasteryCueCopyStaysStrategicAndCalm() {
        #expect(VexloStrings.Onboarding.completeLine == "Chain the next clear to lift score")
        #expect(VexloStrings.Onboarding.chainBuildsScore == "Consecutive clears build a chain")
        #expect(GameScene.comboCueText(for: 2) == "Combo ×2")
        #expect(GameScene.chainCueText(for: 2) == "Chain ×2")
    }

    @Test
    func comboAndChainEventSemanticsStayDistinctAndComboWinsPrecedence() {
        #expect(GameScene.masteryEventCueText(clearedLineCount: 2, chainCount: 1) == "Combo ×2")
        #expect(GameScene.masteryEventCueText(clearedLineCount: 1, chainCount: 2) == "Chain ×2")
        #expect(GameScene.masteryEventCueText(clearedLineCount: 2, chainCount: 3) == "Combo ×2")
        #expect(GameScene.masteryEventCueText(clearedLineCount: 1, chainCount: 1) == nil)
    }

    @Test
    func firstChainMasteryHintOnlyArmsForRealUnseenChainsWithoutComboCompetition() {
        #expect(!GameScene.shouldShowFirstChainMasteryHint(clearedLineCount: 1, chainCount: 1, chainAdvanced: false, hasShownHint: false))
        #expect(GameScene.shouldShowFirstChainMasteryHint(clearedLineCount: 1, chainCount: 2, chainAdvanced: true, hasShownHint: false))
        #expect(!GameScene.shouldShowFirstChainMasteryHint(clearedLineCount: 2, chainCount: 2, chainAdvanced: true, hasShownHint: false))
        #expect(!GameScene.shouldShowFirstChainMasteryHint(clearedLineCount: 1, chainCount: 3, chainAdvanced: true, hasShownHint: true))
    }

    @Test
    func firstClearMasteryHintYieldsToComboAndChainPrecedence() {
        #expect(GameScene.shouldShowFirstClearMasteryHint(clearedCellCount: 1, clearedLineCount: 1, chainAdvanced: false, shouldShowClearHint: true))
        #expect(!GameScene.shouldShowFirstClearMasteryHint(clearedCellCount: 1, clearedLineCount: 2, chainAdvanced: false, shouldShowClearHint: true))
        #expect(!GameScene.shouldShowFirstClearMasteryHint(clearedCellCount: 1, clearedLineCount: 1, chainAdvanced: true, shouldShowClearHint: true))
        #expect(!GameScene.shouldShowFirstClearMasteryHint(clearedCellCount: 0, clearedLineCount: 1, chainAdvanced: false, shouldShowClearHint: true))
        #expect(!GameScene.shouldShowFirstClearMasteryHint(clearedCellCount: 1, clearedLineCount: 1, chainAdvanced: false, shouldShowClearHint: false))
    }

    @Test
    func illegalPlacementResolutionIsNotLegalAndClearsNothing() {
        var board = HexBoard(cols: 7, rows: 7)
        board.place(color: UIColor(hex: "7A74F7"), at: HexCoordinate(0, 0))
        let piece = HexPiece(offsets: [HexCoordinate(0, 0)], color: UIColor(hex: "55A7F6"))
        let resolution = board.placementResolution(for: piece, at: HexCoordinate(0, 0))

        #expect(!resolution.isLegal)
        #expect(resolution.clearedLineCount == 0)
        #expect(resolution.clearedCellCoordinates.isEmpty)
        #expect(resolution.placedCoordinates == [HexCoordinate(0, 0)])
    }

    @Test
    func legalPlacementResolutionOnEmptyBoardHasNoClears() {
        let board = HexBoard(cols: 7, rows: 7)
        let piece = HexPiece(offsets: [HexCoordinate(0, 0)], color: UIColor(hex: "7A74F7"))
        let resolution = board.placementResolution(for: piece, at: HexCoordinate(3, 3))

        #expect(resolution.isLegal)
        #expect(resolution.placedCoordinates == [HexCoordinate(3, 3)])
        #expect(resolution.clearedLineCount == 0)
        #expect(resolution.clearedCellCoordinates.isEmpty)
    }

    @Test
    func legalPlacementResolutionClearsSingleRow() {
        var board = HexBoard(cols: 7, rows: 7)
        let fill = UIColor(hex: "7A74F7")
        for col in 0..<7 where col != 3 {
            board.place(color: fill, at: HexCoordinate(col, 0))
        }
        let piece = HexPiece(offsets: [HexCoordinate(0, 0)], color: UIColor(hex: "55A7F6"))
        let resolution = board.placementResolution(for: piece, at: HexCoordinate(3, 0))

        #expect(resolution.isLegal)
        #expect(resolution.clearedRowIndices == [0])
        #expect(resolution.clearedColIndices.isEmpty)
        #expect(resolution.clearedLineCount == 1)
        #expect(resolution.clearedCellCoordinates.count == 7)
        #expect(resolution.clearedCellCoordinates.contains(HexCoordinate(3, 0)))
    }

    @Test
    func legalPlacementResolutionClearsRowAndColumnWithOverlap() {
        var board = HexBoard(cols: 7, rows: 7)
        let fill = UIColor(hex: "7A74F7")
        for col in 0..<7 where col != 3 {
            board.place(color: fill, at: HexCoordinate(col, 3))
        }
        for row in 0..<7 where row != 3 {
            board.place(color: fill, at: HexCoordinate(3, row))
        }
        let piece = HexPiece(offsets: [HexCoordinate(0, 0)], color: UIColor(hex: "55A7F6"))
        let resolution = board.placementResolution(for: piece, at: HexCoordinate(3, 3))

        #expect(resolution.isLegal)
        #expect(resolution.clearedRowIndices == [3])
        #expect(resolution.clearedColIndices == [3])
        #expect(resolution.clearedLineCount == 2)
        #expect(resolution.clearedCellCoordinates.count == 13)
        #expect(resolution.clearedCellCoordinates.contains(HexCoordinate(3, 3)))
    }

    @Test
    func legalPlacementResolutionReportsTwoCompletedRows() {
        var board = HexBoard(cols: 7, rows: 7)
        let fill = UIColor(hex: "7A74F7")
        for row in 0..<2 {
            for col in 0..<6 {
                board.place(color: fill, at: HexCoordinate(col, row))
            }
        }
        let piece = HexPiece(
            offsets: [HexCoordinate(0, 0), HexCoordinate(0, 1)],
            color: UIColor(hex: "55A7F6")
        )
        let resolution = board.placementResolution(for: piece, at: HexCoordinate(6, 0))

        #expect(resolution.isLegal)
        #expect(resolution.placedCoordinates == [HexCoordinate(6, 0), HexCoordinate(6, 1)])
        #expect(resolution.clearedRowIndices == [0, 1])
        #expect(resolution.clearedColIndices.isEmpty)
        #expect(resolution.clearedLineCount == 2)
    }

    @Test
    func illegalPlacementEvaluationReturnsNil() {
        var board = HexBoard(cols: 7, rows: 7)
        board.place(color: UIColor(hex: "7A74F7"), at: HexCoordinate(0, 0))
        let piece = HexPiece(offsets: [HexCoordinate(0, 0)], color: UIColor(hex: "55A7F6"))
        #expect(
            placementEvaluation(on: board, piece: piece, anchor: HexCoordinate(0, 0)) == nil
        )
    }

    @Test
    func legalNoClearPlacementOnEmptyBoardEvaluatesAsSurvival() throws {
        let board = HexBoard(cols: 7, rows: 7)
        let piece = HexPiece(offsets: [HexCoordinate(0, 0)], color: UIColor(hex: "7A74F7"))
        let evaluation = try #require(
            placementEvaluation(on: board, piece: piece, anchor: HexCoordinate(3, 3))
        )
        #expect(evaluation.tier == .survival)
        #expect(evaluation.reliefContactCount == 0)
        #expect(evaluation.occupiedCellCountBeforePlacement == 0)
    }

    @Test
    func singleRowClearEvaluatesAsConstructive() throws {
        var board = HexBoard(cols: 7, rows: 7)
        let fill = UIColor(hex: "7A74F7")
        for col in 0..<7 where col != 3 {
            board.place(color: fill, at: HexCoordinate(col, 0))
        }
        let piece = HexPiece(offsets: [HexCoordinate(0, 0)], color: UIColor(hex: "55A7F6"))
        let evaluation = try #require(
            placementEvaluation(on: board, piece: piece, anchor: HexCoordinate(3, 0))
        )
        #expect(evaluation.tier == .constructive)
        #expect(evaluation.resolution.clearedLineCount == 1)
    }

    @Test
    func rowAndColumnOverlapClearEvaluatesAsExpert() throws {
        var board = HexBoard(cols: 7, rows: 7)
        let fill = UIColor(hex: "7A74F7")
        for col in 0..<7 where col != 3 {
            board.place(color: fill, at: HexCoordinate(col, 3))
        }
        for row in 0..<7 where row != 3 {
            board.place(color: fill, at: HexCoordinate(3, row))
        }
        let piece = HexPiece(offsets: [HexCoordinate(0, 0)], color: UIColor(hex: "55A7F6"))
        let evaluation = try #require(
            placementEvaluation(on: board, piece: piece, anchor: HexCoordinate(3, 3))
        )
        #expect(evaluation.tier == .expert)
        #expect(evaluation.resolution.clearedLineCount == 2)
    }

    @Test
    func twoRowClearEvaluatesAsExpert() throws {
        var board = HexBoard(cols: 7, rows: 7)
        let fill = UIColor(hex: "7A74F7")
        for row in 0..<2 {
            for col in 0..<6 {
                board.place(color: fill, at: HexCoordinate(col, row))
            }
        }
        let piece = HexPiece(
            offsets: [HexCoordinate(0, 0), HexCoordinate(0, 1)],
            color: UIColor(hex: "55A7F6")
        )
        let evaluation = try #require(
            placementEvaluation(on: board, piece: piece, anchor: HexCoordinate(6, 0))
        )
        #expect(evaluation.tier == .expert)
        #expect(evaluation.resolution.clearedLineCount == 2)
    }

    @Test
    func meaningfulBoardContactWithoutClearEvaluatesAsRelief() throws {
        var board = HexBoard(cols: 7, rows: 7)
        let fill = UIColor(hex: "7A74F7")
        board.place(color: fill, at: HexCoordinate(2, 1))
        board.place(color: fill, at: HexCoordinate(3, 1))
        let piece = HexPiece(
            offsets: [HexCoordinate(0, 0), HexCoordinate(1, 0)],
            color: UIColor(hex: "55A7F6")
        )
        let evaluation = try #require(
            placementEvaluation(on: board, piece: piece, anchor: HexCoordinate(2, 2))
        )
        #expect(evaluation.tier == .relief)
        #expect(evaluation.reliefContactCount >= PlacementEvaluation.reliefContactThreshold)
        #expect(evaluation.resolution.clearedLineCount == 0)
    }

    @Test
    func highOccupancyIsolatedNoClearEvaluatesAsSurvival() throws {
        var board = HexBoard(cols: 7, rows: 7)
        let fill = UIColor(hex: "7A74F7")
        for col in 0..<7 {
            for row in 0..<7 where !(col == 6 && row == 6) {
                board.place(color: fill, at: HexCoordinate(col, row))
            }
        }
        let piece = HexPiece(offsets: [HexCoordinate(0, 0)], color: UIColor(hex: "55A7F6"))
        let evaluation = try #require(
            placementEvaluation(on: board, piece: piece, anchor: HexCoordinate(6, 6))
        )
        #expect(evaluation.tier == .survival)
        #expect(evaluation.reliefContactCount < PlacementEvaluation.reliefContactThreshold)
        #expect(
            evaluation.occupiedCellCountBeforePlacement >= PlacementEvaluation.survivalOccupancyThreshold
        )
    }

    @Test
    func emptyBoardEvaluatesAsCalmPressure() {
        let board = HexBoard(cols: 7, rows: 7)
        let snapshot = boardPressure(on: board, isOpeningState: false)

        #expect(snapshot.band == .calm)
        #expect(snapshot.cellWhisper.count == 49)
        #expect(snapshot.cellWhisper.values.allSatisfy { $0 == .calm })
    }

    @Test
    func openingStateSuppressesWarmLinePressureToCalm() {
        var board = HexBoard(cols: 7, rows: 7)
        let fill = UIColor(hex: "7A74F7")
        for col in 0..<6 {
            board.place(color: fill, at: HexCoordinate(col, 0))
        }

        let snapshot = boardPressure(on: board, isOpeningState: true)
        #expect(snapshot.band == .calm)
        #expect(snapshot.cellWhisper[HexCoordinate(6, 0)] == .calm)
        #expect(snapshot.cellWhisper.values.allSatisfy { $0 == .calm })
    }

    @Test
    func hotRowMarksRemainingEmptyCellsTaut() {
        var board = HexBoard(cols: 7, rows: 7)
        let fill = UIColor(hex: "7A74F7")
        for col in 0..<6 {
            board.place(color: fill, at: HexCoordinate(col, 0))
        }

        let snapshot = boardPressure(on: board, isOpeningState: false)
        #expect(snapshot.cellWhisper[HexCoordinate(6, 0)] == .taut)
    }

    @Test
    func hotColMarksRemainingEmptyCellsTaut() {
        var board = HexBoard(cols: 7, rows: 7)
        let fill = UIColor(hex: "7A74F7")
        for row in 0..<6 {
            board.place(color: fill, at: HexCoordinate(0, row))
        }

        let snapshot = boardPressure(on: board, isOpeningState: false)
        #expect(snapshot.cellWhisper[HexCoordinate(0, 6)] == .taut)
    }

    @Test
    func warmRowSetsAttentiveFloorWithoutTaut() {
        var board = HexBoard(cols: 7, rows: 7)
        let fill = UIColor(hex: "7A74F7")
        for col in 0..<5 {
            board.place(color: fill, at: HexCoordinate(col, 0))
        }

        let snapshot = boardPressure(on: board, isOpeningState: false)
        #expect(snapshot.cellWhisper[HexCoordinate(5, 0)] == .attentive)
        #expect(snapshot.cellWhisper[HexCoordinate(6, 0)] == .attentive)
    }

    @Test
    func highOccupancyWithoutNearLinesUsesGlobalTautBandOnEmptyCells() {
        var board = HexBoard(cols: 7, rows: 7)
        let fill = UIColor(hex: "7A74F7")
        let occupied: [HexCoordinate] = [
            HexCoordinate(0, 0), HexCoordinate(1, 0), HexCoordinate(2, 0), HexCoordinate(3, 0),
            HexCoordinate(0, 1), HexCoordinate(1, 1), HexCoordinate(2, 1), HexCoordinate(3, 1),
            HexCoordinate(0, 2), HexCoordinate(1, 2), HexCoordinate(2, 2), HexCoordinate(3, 2),
            HexCoordinate(0, 3), HexCoordinate(1, 3)
        ]
        for coord in occupied {
            board.place(color: fill, at: coord)
        }

        let snapshot = boardPressure(on: board, isOpeningState: false)
        #expect(snapshot.band == .taut)
        #expect(snapshot.cellWhisper[HexCoordinate(6, 6)] == .taut)
        #expect(snapshot.cellWhisper[HexCoordinate(4, 4)] == .taut)
    }

    @Test
    func boardPressureSnapshotExcludesOccupiedCells() {
        var board = HexBoard(cols: 7, rows: 7)
        let fill = UIColor(hex: "7A74F7")
        board.place(color: fill, at: HexCoordinate(3, 3))

        let snapshot = boardPressure(on: board, isOpeningState: false)
        #expect(snapshot.cellWhisper[HexCoordinate(3, 3)] == nil)
        #expect(snapshot.cellWhisper.count == 48)
    }

    @Test
    func boardPressureEvaluationIsDeterministicAndDoesNotMutateBoard() {
        var board = HexBoard(cols: 7, rows: 7)
        let fill = UIColor(hex: "7A74F7")
        for col in 0..<5 {
            board.place(color: fill, at: HexCoordinate(col, 2))
        }
        let before = board.snapshot
        let context = BoardPressureContext(
            occupiedCellCount: before.cells.count,
            isOpeningState: false,
            cols: board.cols,
            rows: board.rows
        )

        let first = BoardPressure.evaluate(board: board, context: context)
        let second = BoardPressure.evaluate(board: board, context: context)

        #expect(first == second)
        #expect(boardSignature(board.snapshot) == boardSignature(before))
    }

    @Test
    func placementReliefContactCountUsesEngineReliefVectors() {
        let placement = [HexCoordinate(2, 2), HexCoordinate(3, 2)]
        let occupied = Set([HexCoordinate(2, 1), HexCoordinate(3, 1)])

        #expect(
            PlacementEvaluation.reliefContactCount(
                placementCoordinates: placement,
                occupiedCoordinates: occupied
            ) == 2
        )
        #expect(
            PlacementEvaluation.reliefContactCount(
                placementCoordinates: [HexCoordinate(0, 0)],
                occupiedCoordinates: Set([HexCoordinate(0, 1)])
            ) == 1
        )
    }

    @Test
    func gameEnginePreviewPlacementBundleMatchesSeparateResolutionAndEvaluation() throws {
        let piece = HexPiece(offsets: [HexCoordinate(0, 0)], color: UIColor(hex: "55A7F6"))
        var empty = Set(engineOccupiedCoordinates(excluding: []))
        for col in 0..<7 where col != 3 {
            empty.remove(HexCoordinate(col, 0))
        }
        let engine = makeEngineForPlacementParity(emptyCoordinates: empty, tray: [piece])
        let anchor = HexCoordinate(3, 0)

        let bundle = engine.previewPlacementBundle(piece, at: anchor)
        #expect(bundle.resolution == engine.previewPlacement(piece, at: anchor))
        #expect(bundle.evaluation == engine.previewPlacementEvaluation(piece, at: anchor))

        let evaluation = try #require(bundle.evaluation)
        #expect(evaluation.tier == .constructive)
        #expect(bundle.resolution.clearedLineCount == 1)
    }

    @Test
    func gameEnginePreviewPlacementBundleUsesSingleResolutionForIllegalPlacement() {
        let piece = HexPiece(offsets: [HexCoordinate(0, 0)], color: UIColor(hex: "55A7F6"))
        let engine = makeEngineForPlacementParity(
            emptyCoordinates: Set(engineOccupiedCoordinates(excluding: [HexCoordinate(0, 0)])),
            tray: [piece]
        )
        let bundle = engine.previewPlacementBundle(piece, at: HexCoordinate(0, 0))
        #expect(!bundle.resolution.isLegal)
        #expect(bundle.evaluation == nil)
        #expect(bundle.resolution == engine.previewPlacement(piece, at: HexCoordinate(0, 0)))
    }

    @Test
    func gameEnginePlacementEvaluationContextAtNormalRunStart() {
        let engine = GameEngine()
        engine.startNormalRun(seed: 0xBEEF)
        let context = engine.placementEvaluationContext()
        #expect(context.occupiedCellCount == 0)
        #expect(context.isOpeningState)
    }

    @Test
    func gameEngineBoardPressureContextAtNormalRunStart() {
        let engine = GameEngine()
        engine.startNormalRun(seed: 0xBEEF)
        let context = engine.boardPressureContext()
        #expect(context.occupiedCellCount == 0)
        #expect(context.isOpeningState)
        #expect(context.cols == engine.board.cols)
        #expect(context.rows == engine.board.rows)
    }

    @Test
    func gameEngineBoardPressureSnapshotMatchesDirectBoardPressureEvaluate() {
        var empty = Set(engineOccupiedCoordinates(excluding: []))
        for col in 0..<5 {
            empty.remove(HexCoordinate(col, 0))
        }
        let engine = makeEngineForPlacementParity(
            emptyCoordinates: empty,
            tray: [HexPiece(offsets: [HexCoordinate(0, 0)], color: UIColor(hex: "55A7F6"))]
        )
        let context = engine.boardPressureContext()
        let direct = BoardPressure.evaluate(board: engine.board, context: context)
        #expect(engine.boardPressureSnapshot() == direct)
    }

    @Test
    func gameEngineBoardPressureOpeningStateSuppressesWarmLinePressure() {
        let emptyCoordinates = Set(
            engineOccupiedCoordinates(
                excluding: (0..<6).map { HexCoordinate($0, 0) }
            )
        )
        let engine = makeEngineForPlacementParity(
            emptyCoordinates: emptyCoordinates,
            tray: [HexPiece(offsets: [HexCoordinate(0, 0)], color: UIColor(hex: "55A7F6"))]
        )
        #expect(engine.boardPressureContext().isOpeningState)
        let snapshot = engine.boardPressureSnapshot()
        #expect(snapshot.band == .calm)
        #expect(snapshot.cellWhisper[HexCoordinate(6, 0)] == .calm)
    }

    @Test
    func gameEngineBoardPressureContextAlignsOccupancyWithPlacementEvaluationContext() {
        var empty = Set(engineOccupiedCoordinates(excluding: []))
        for col in 0..<4 {
            empty.remove(HexCoordinate(col, 2))
        }
        let engine = makeEngineForPlacementParity(
            emptyCoordinates: empty,
            tray: [HexPiece(offsets: [HexCoordinate(0, 0)], color: UIColor(hex: "55A7F6"))]
        )
        let placementContext = engine.placementEvaluationContext()
        let pressureContext = engine.boardPressureContext()
        #expect(pressureContext.occupiedCellCount == placementContext.occupiedCellCount)
        #expect(pressureContext.isOpeningState == placementContext.isOpeningState)
    }

    @Test
    func gameEnginePlacementEvaluationContextClearsOpeningStateAfterFirstClear() throws {
        let piece = HexPiece(offsets: [HexCoordinate(0, 0)], color: UIColor(hex: "55A7F6"))
        var empty = Set(engineOccupiedCoordinates(excluding: []))
        for col in 0..<7 where col != 3 {
            empty.remove(HexCoordinate(col, 0))
        }
        let engine = makeEngineForPlacementParity(
            emptyCoordinates: empty,
            tray: [piece]
        )
        #expect(engine.placementEvaluationContext().isOpeningState)
        _ = engine.place(piece, at: HexCoordinate(3, 0), slotIndex: 0)
        #expect(!engine.placementEvaluationContext().isOpeningState)
        #expect(engine.placementEvaluationContext().occupiedCellCount < 49)
    }

    @Test
    func gameEnginePreviewPlacementEvaluationMatchesDirectPlacementEvaluationLogic() throws {
        let piece = HexPiece(offsets: [HexCoordinate(0, 0)], color: UIColor(hex: "55A7F6"))
        var empty = Set(engineOccupiedCoordinates(excluding: []))
        for col in 0..<7 where col != 3 {
            empty.remove(HexCoordinate(col, 0))
        }
        let engine = makeEngineForPlacementParity(emptyCoordinates: empty, tray: [piece])
        let anchor = HexCoordinate(3, 0)
        let resolution = engine.previewPlacement(piece, at: anchor)
        let context = engine.placementEvaluationContext()
        let occupied = Set(engine.board.snapshot.cells.map(\.coordinate))
        let direct = try #require(
            PlacementEvaluation.evaluate(
                resolution: resolution,
                context: context,
                occupiedCoordinates: occupied
            )
        )
        let viaEngine = try #require(engine.previewPlacementEvaluation(piece, at: anchor))
        #expect(viaEngine == direct)
        #expect(viaEngine.tier == .constructive)
    }

    @Test
    func gameEngineEvaluatePlacementMatchesPreviewPlacementEvaluation() throws {
        let engine = GameEngine()
        engine.startNormalRun(seed: 0xBEEF)
        let piece = try #require(engine.pieces[0])
        let anchor = try #require(firstLegalAnchor(for: piece, in: engine))
        #expect(engine.evaluatePlacement(piece, at: anchor) == engine.previewPlacementEvaluation(piece, at: anchor))
    }

    @Test
    func gameEnginePreviewPlacementEvaluationTiersMatchCommit1aGoldens() throws {
        let singleRowPiece = HexPiece(offsets: [HexCoordinate(0, 0)], color: UIColor(hex: "55A7F6"))
        var singleRowEmpty = Set(engineOccupiedCoordinates(excluding: []))
        for col in 0..<7 where col != 3 {
            singleRowEmpty.remove(HexCoordinate(col, 0))
        }
        let singleRowEngine = makeEngineForPlacementParity(
            emptyCoordinates: singleRowEmpty,
            tray: [singleRowPiece]
        )
        let constructive = try #require(
            singleRowEngine.previewPlacementEvaluation(singleRowPiece, at: HexCoordinate(3, 0))
        )
        #expect(constructive.tier == .constructive)

        let expertPiece = HexPiece(
            offsets: [HexCoordinate(0, 0), HexCoordinate(0, 1)],
            color: UIColor(hex: "55A7F6")
        )
        var twoRowEmpty = Set(engineOccupiedCoordinates(excluding: []))
        for row in 0..<2 {
            for col in 0..<6 {
                twoRowEmpty.remove(HexCoordinate(col, row))
            }
        }
        let expertEngine = makeEngineForPlacementParity(
            emptyCoordinates: twoRowEmpty,
            tray: [expertPiece]
        )
        let expert = try #require(
            expertEngine.previewPlacementEvaluation(expertPiece, at: HexCoordinate(6, 0))
        )
        #expect(expert.tier == .expert)

        let reliefPiece = HexPiece(
            offsets: [HexCoordinate(0, 0), HexCoordinate(1, 0)],
            color: UIColor(hex: "55A7F6")
        )
        var reliefEmpty = Set(
            (0..<7).flatMap { col in
                (0..<7).map { HexCoordinate(col, $0) }
            }
        )
        reliefEmpty.remove(HexCoordinate(2, 1))
        reliefEmpty.remove(HexCoordinate(3, 1))
        let reliefEngine = makeEngineForPlacementParity(
            emptyCoordinates: reliefEmpty,
            tray: [reliefPiece]
        )
        let relief = try #require(
            reliefEngine.previewPlacementEvaluation(reliefPiece, at: HexCoordinate(2, 2))
        )
        #expect(relief.tier == .relief)

        let survivalEngine = GameEngine()
        survivalEngine.startNormalRun(seed: 0xBEEF)
        let survivalPiece = try #require(survivalEngine.pieces[0])
        let survivalAnchor = try #require(firstLegalAnchor(for: survivalPiece, in: survivalEngine))
        let survival = try #require(
            survivalEngine.previewPlacementEvaluation(survivalPiece, at: survivalAnchor)
        )
        #expect(survival.tier == .survival)
    }

    @Test
    func enginePreviewPlacementMatchesCommittedOutcomeForIllegalPlacement() {
        let piece = HexPiece(offsets: [HexCoordinate(0, 0)], color: UIColor(hex: "55A7F6"))
        let engine = makeEngineForPlacementParity(
            emptyCoordinates: Set(engineOccupiedCoordinates(excluding: [HexCoordinate(0, 0)])),
            tray: [piece]
        )
        expectEnginePreviewMatchesCommitted(engine, piece: piece, anchor: HexCoordinate(0, 0), slotIndex: 0)
    }

    @Test
    func enginePreviewPlacementMatchesCommittedOutcomeForLegalNoClear() throws {
        let engine = GameEngine()
        engine.startNormalRun(seed: 0xBEEF)
        let piece = try #require(engine.pieces[0])
        let anchor = try #require(firstLegalAnchor(for: piece, in: engine))
        expectEnginePreviewMatchesCommitted(engine, piece: piece, anchor: anchor, slotIndex: 0)
    }

    @Test
    func enginePreviewPlacementMatchesCommittedOutcomeForSingleRowClear() {
        let piece = HexPiece(offsets: [HexCoordinate(0, 0)], color: UIColor(hex: "55A7F6"))
        var empty = Set(engineOccupiedCoordinates(excluding: []))
        for col in 0..<7 where col != 3 {
            empty.remove(HexCoordinate(col, 0))
        }
        let engine = makeEngineForPlacementParity(emptyCoordinates: empty, tray: [piece])
        expectEnginePreviewMatchesCommitted(engine, piece: piece, anchor: HexCoordinate(3, 0), slotIndex: 0)
    }

    @Test
    func enginePreviewPlacementMatchesCommittedOutcomeForRowAndColumnOverlapClear() {
        let piece = HexPiece(offsets: [HexCoordinate(0, 0)], color: UIColor(hex: "55A7F6"))
        var empty = Set(engineOccupiedCoordinates(excluding: []))
        for col in 0..<7 where col != 3 {
            empty.remove(HexCoordinate(col, 3))
        }
        for row in 0..<7 where row != 3 {
            empty.remove(HexCoordinate(3, row))
        }
        let engine = makeEngineForPlacementParity(emptyCoordinates: empty, tray: [piece])
        expectEnginePreviewMatchesCommitted(engine, piece: piece, anchor: HexCoordinate(3, 3), slotIndex: 0)
    }

    @Test
    func enginePreviewPlacementMatchesCommittedOutcomeForTwoRowClear() {
        let piece = HexPiece(
            offsets: [HexCoordinate(0, 0), HexCoordinate(0, 1)],
            color: UIColor(hex: "55A7F6")
        )
        var empty = Set(engineOccupiedCoordinates(excluding: []))
        for row in 0..<2 {
            for col in 0..<6 {
                empty.remove(HexCoordinate(col, row))
            }
        }
        let engine = makeEngineForPlacementParity(emptyCoordinates: empty, tray: [piece])
        expectEnginePreviewMatchesCommitted(engine, piece: piece, anchor: HexCoordinate(6, 0), slotIndex: 0)
    }

    @Test
    func dragPreviewProfilesDistinguishValidClearAndMultiClearPlacements() {
        #expect(GameScene.dragPreviewProfile(isValid: false, clearedLineCount: 0) == .invalidPlacement)
        #expect(GameScene.dragPreviewProfile(isValid: true, clearedLineCount: 0) == .validPlacement)
        #expect(GameScene.dragPreviewProfile(isValid: true, clearedLineCount: 1) == .clearPlacement)
        #expect(GameScene.dragPreviewProfile(isValid: true, clearedLineCount: 2) == .multiClearPlacement)
    }

    @Test
    func dragPreviewProfileDerivesFromPlacementResolution() {
        let illegal = PlacementResolution(
            anchor: HexCoordinate(0, 0),
            placedCoordinates: [HexCoordinate(0, 0)],
            isLegal: false,
            clearedRowIndices: [],
            clearedColIndices: [],
            clearedCellCoordinates: []
        )
        let multiClear = PlacementResolution(
            anchor: HexCoordinate(3, 3),
            placedCoordinates: [HexCoordinate(3, 3)],
            isLegal: true,
            clearedRowIndices: [3],
            clearedColIndices: [3],
            clearedCellCoordinates: [HexCoordinate(3, 3)]
        )
        #expect(GameScene.dragPreviewProfile(for: illegal) == .invalidPlacement)
        #expect(GameScene.dragPreviewProfile(for: multiClear) == .multiClearPlacement)
    }

    @Test
    func gameSceneDoesNotDuplicateRowColClearPrediction() throws {
        let repoRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let gameSceneSource = try String(
            contentsOf: repoRoot.appendingPathComponent("Vexlo/UI/GameScene.swift"),
            encoding: .utf8
        )
        let previewSemanticsSource = try String(
            contentsOf: repoRoot.appendingPathComponent("Vexlo/UI/GameScene+PreviewSemantics.swift"),
            encoding: .utf8
        )
        let boardWhisperSource = try String(
            contentsOf: repoRoot.appendingPathComponent("Vexlo/UI/GameScene+BoardWhisper.swift"),
            encoding: .utf8
        )
        #expect(!gameSceneSource.contains("func predictedClearCoordinates"))
        #expect(!gameSceneSource.contains("func predictedClearLineCount"))
        #expect(gameSceneSource.contains("engine.previewPlacement"))
        #expect(gameSceneSource.contains("engine.previewPlacementBundle"))
        #expect(gameSceneSource.contains("engine.place(piece"))
        #expect(gameSceneSource.contains("highlightCells(resolution:"))
        #expect(!previewSemanticsSource.contains("openingReliefContactScore"))
        #expect(!previewSemanticsSource.contains("openingNeighborCoordinates"))
        #expect(gameSceneSource.contains("boardPressureSnapshot"))
        #expect(gameSceneSource.contains("engine.boardPressureSnapshot()"))
        #expect(gameSceneSource.contains("applyEmptyCellAppearance(for:"))
        #expect(gameSceneSource.contains("refreshBoardPressureSnapshot()"))
        #expect(!gameSceneSource.contains("BoardPressure.evaluate"))
        #expect(!boardWhisperSource.contains("BoardPressure.evaluate"))
        #expect(!gameSceneSource.contains("fullRows()"))
        #expect(!boardWhisperSource.contains("fullRows"))
        #expect(!boardWhisperSource.contains("fullCols"))
        #expect(!boardWhisperSource.contains("heatmap"))
        let moveQualityResponseSource = try String(
            contentsOf: repoRoot.appendingPathComponent("Vexlo/UI/GameScene+MoveQualityResponse.swift"),
            encoding: .utf8
        )
        #expect(gameSceneSource.contains("moveQualityDragResponse"))
        #expect(gameSceneSource.contains("playCommitPlaceHaptic"))
        #expect(!gameSceneSource.contains("evaluation.tier == .relief"))
        #expect(!moveQualityResponseSource.contains("BoardPressure"))
        let policySource = try String(
            contentsOf: repoRoot.appendingPathComponent("Vexlo/Engine/MoveQualityResponsePolicy.swift"),
            encoding: .utf8
        )
        #expect(policySource.contains("evaluateCommit"))
        #expect(!policySource.contains("BoardPressure"))
    }

    @Test
    func gameSceneBoardWhisperSuppressedDuringOpeningAndTerminal() {
        #expect(!GameScene.shouldApplyBoardWhisper(isOpeningState: true, isTerminal: false))
        #expect(!GameScene.shouldApplyBoardWhisper(isOpeningState: false, isTerminal: true))
        #expect(!GameScene.shouldApplyBoardWhisper(isOpeningState: true, isTerminal: true))
        #expect(GameScene.shouldApplyBoardWhisper(isOpeningState: false, isTerminal: false))
    }

    @Test
    func gameSceneBoardWhisperMaterialDeltaIncreasesWithIntensity() {
        #expect(
            GameScene.boardWhisperMaterialAlphaDelta(for: .attentive)
                < GameScene.boardWhisperMaterialAlphaDelta(for: .taut)
        )
        #expect(
            GameScene.boardWhisperStrokeAlphaDelta(for: .attentive)
                < GameScene.boardWhisperStrokeAlphaDelta(for: .taut)
        )
        #expect(GameScene.boardWhisperMaterialAlphaDelta(for: .calm) == 0)
        #expect(GameScene.boardWhisperStrokeAlphaDelta(for: .calm) == 0)
    }

    @Test
    func moveQualityResponsePolicyCommitHapticMapsConstructiveAndExpertClearsOnly() {
        let constructive = MoveQualityResponseContext(
            moment: .commit,
            tier: nil,
            isOpeningState: false,
            clearedLineCount: 1,
            isLegalPlacement: true
        )
        let expert = MoveQualityResponseContext(
            moment: .commit,
            tier: nil,
            isOpeningState: false,
            clearedLineCount: 2,
            isLegalPlacement: true
        )
        let reliefNoClear = MoveQualityResponseContext(
            moment: .commit,
            tier: .relief,
            isOpeningState: false,
            clearedLineCount: 0,
            isLegalPlacement: true
        )
        let survivalNoClear = MoveQualityResponseContext(
            moment: .commit,
            tier: .survival,
            isOpeningState: false,
            clearedLineCount: 0,
            isLegalPlacement: true
        )

        #expect(MoveQualityResponsePolicy.evaluate(constructive).commitHaptic == .constructive)
        #expect(MoveQualityResponsePolicy.evaluate(expert).commitHaptic == .expert)
        #expect(MoveQualityResponsePolicy.evaluate(reliefNoClear).commitHaptic == .baseline)
        #expect(MoveQualityResponsePolicy.evaluate(survivalNoClear).commitHaptic == .baseline)
    }

    @Test
    func moveQualityCommitResponseUsesCommittedPlacementResolution() {
        let constructiveResolution = PlacementResolution(
            anchor: HexCoordinate(3, 0),
            placedCoordinates: [HexCoordinate(3, 0)],
            isLegal: true,
            clearedRowIndices: [0],
            clearedColIndices: [],
            clearedCellCoordinates: (0..<7).map { HexCoordinate($0, 0) }
        )
        #expect(
            GameScene.moveQualityCommitResponse(for: constructiveResolution).commitHaptic == .constructive
        )

        let expertResolution = PlacementResolution(
            anchor: HexCoordinate(3, 3),
            placedCoordinates: [HexCoordinate(3, 3)],
            isLegal: true,
            clearedRowIndices: [3],
            clearedColIndices: [3],
            clearedCellCoordinates: [HexCoordinate(3, 3)]
        )
        #expect(GameScene.moveQualityCommitResponse(for: expertResolution).commitHaptic == .expert)
    }

    @Test
    func moveQualityResponsePolicyOpeningReliefDragMatchesPriorOpeningReliefRules() {
        let reliefContext = MoveQualityResponseContext(
            moment: .drag,
            tier: .relief,
            isOpeningState: true,
            clearedLineCount: 0,
            isLegalPlacement: true
        )
        #expect(
            MoveQualityResponsePolicy.evaluate(reliefContext).emphasizesOpeningReliefOnDrag
        )

        let postOpening = MoveQualityResponseContext(
            moment: .drag,
            tier: .relief,
            isOpeningState: false,
            clearedLineCount: 0,
            isLegalPlacement: true
        )
        #expect(
            !MoveQualityResponsePolicy.evaluate(postOpening).emphasizesOpeningReliefOnDrag
        )

        let constructiveClear = MoveQualityResponseContext(
            moment: .drag,
            tier: .constructive,
            isOpeningState: true,
            clearedLineCount: 1,
            isLegalPlacement: true
        )
        #expect(
            !MoveQualityResponsePolicy.evaluate(constructiveClear).emphasizesOpeningReliefOnDrag
        )

        let commitMoment = MoveQualityResponseContext(
            moment: .commit,
            tier: .relief,
            isOpeningState: true,
            clearedLineCount: 0,
            isLegalPlacement: true
        )
        #expect(
            !MoveQualityResponsePolicy.evaluate(commitMoment).emphasizesOpeningReliefOnDrag
        )
    }

    @Test
    func moveQualityResponsePolicyHasNoBoardPressureCoupling() throws {
        let repoRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let policySource = try String(
            contentsOf: repoRoot.appendingPathComponent("Vexlo/Engine/MoveQualityResponsePolicy.swift"),
            encoding: .utf8
        )
        let moveQualityResponseSource = try String(
            contentsOf: repoRoot.appendingPathComponent("Vexlo/UI/GameScene+MoveQualityResponse.swift"),
            encoding: .utf8
        )
        #expect(!policySource.contains("BoardPressure"))
        #expect(!policySource.contains("BoardWhisper"))
        #expect(!policySource.contains("boardPressure"))
        #expect(!moveQualityResponseSource.contains("BoardPressure"))
        #expect(!policySource.contains("recommend"))
        #expect(!policySource.contains("hint"))
        #expect(!policySource.contains("heatmap"))
        #expect(!policySource.contains("targetCell"))
    }

    @Test
    func openingReliefPreviewEmphasisOnlyArmsForOpeningValidPlacementsWithMeaningfulBoardContact() throws {
        var reliefBoard = HexBoard(cols: 7, rows: 7)
        let fill = UIColor(hex: "7A74F7")
        reliefBoard.place(color: fill, at: HexCoordinate(2, 1))
        reliefBoard.place(color: fill, at: HexCoordinate(3, 1))
        let reliefPiece = HexPiece(
            offsets: [HexCoordinate(0, 0), HexCoordinate(1, 0)],
            color: UIColor(hex: "55A7F6")
        )
        let reliefEvaluation = try #require(
            placementEvaluation(on: reliefBoard, piece: reliefPiece, anchor: HexCoordinate(2, 2))
        )
        #expect(reliefEvaluation.tier == .relief)
        #expect(GameScene.shouldEmphasizeOpeningReliefPlacement(
            evaluation: reliefEvaluation,
            previewProfile: .validPlacement,
            isOpeningState: true
        ))
        #expect(!GameScene.shouldEmphasizeOpeningReliefPlacement(
            evaluation: reliefEvaluation,
            previewProfile: .validPlacement,
            isOpeningState: false
        ))
        #expect(!GameScene.shouldEmphasizeOpeningReliefPlacement(
            evaluation: reliefEvaluation,
            previewProfile: .clearPlacement,
            isOpeningState: true
        ))

        let sparseBoard = HexBoard(cols: 7, rows: 7)
        let sparsePiece = HexPiece(offsets: [HexCoordinate(0, 0)], color: UIColor(hex: "55A7F6"))
        let sparseEvaluation = try #require(
            placementEvaluation(on: sparseBoard, piece: sparsePiece, anchor: HexCoordinate(3, 3))
        )
        #expect(sparseEvaluation.tier == .survival)
        #expect(!GameScene.shouldEmphasizeOpeningReliefPlacement(
            evaluation: sparseEvaluation,
            previewProfile: .validPlacement,
            isOpeningState: true
        ))
    }

    @Test
    func runReadingSummaryUsesDeterministicReadingCharacterPriority() {
        let base = RunReadingContext(
            score: 100,
            best: 200,
            runStartBest: 0,
            maxCombo: 1,
            didClearAny: false,
            hasUsedContinue: false,
            terminalPressureBand: .calm,
            occupiedCellCount: 4,
            completedRuns: 0
        )
        #expect(RunReadingSummary.readingDetail(for: base) == "Tight board")

        var cleared = base
        cleared = RunReadingContext(
            score: base.score,
            best: base.best,
            runStartBest: base.runStartBest,
            maxCombo: base.maxCombo,
            didClearAny: true,
            hasUsedContinue: base.hasUsedContinue,
            terminalPressureBand: base.terminalPressureBand,
            occupiedCellCount: base.occupiedCellCount,
            completedRuns: base.completedRuns
        )
        #expect(RunReadingSummary.readingDetail(for: cleared) == "Steady clears")

        let chainLed = RunReadingContext(
            score: 120,
            best: 200,
            runStartBest: 0,
            maxCombo: 2,
            didClearAny: true,
            hasUsedContinue: false,
            terminalPressureBand: .attentive,
            occupiedCellCount: 10,
            completedRuns: 5
        )
        #expect(RunReadingSummary.readingDetail(for: chainLed) == "Chain-led reading")

        let underPressure = RunReadingContext(
            score: 90,
            best: 200,
            runStartBest: 0,
            maxCombo: 1,
            didClearAny: true,
            hasUsedContinue: false,
            terminalPressureBand: .taut,
            occupiedCellCount: 15,
            completedRuns: 0
        )
        #expect(RunReadingSummary.readingDetail(for: underPressure) == "Read under pressure")

        let lateRecovery = RunReadingContext(
            score: 80,
            best: 200,
            runStartBest: 0,
            maxCombo: 3,
            didClearAny: true,
            hasUsedContinue: true,
            terminalPressureBand: .taut,
            occupiedCellCount: 16,
            completedRuns: 2
        )
        #expect(RunReadingSummary.readingDetail(for: lateRecovery) == "Late recovery")
    }

    @Test
    func runReadingSummaryProgressUsesSingleMeaningfulLine() {
        let nearMissContext = RunReadingContext(
            score: 210,
            best: 240,
            runStartBest: 0,
            maxCombo: 2,
            didClearAny: true,
            hasUsedContinue: false,
            terminalPressureBand: .attentive,
            occupiedCellCount: 11,
            completedRuns: 4
        )
        #expect(RunReadingSummary.progressLine(for: nearMissContext, isNewBest: false) == "One cleaner run was there")

        let gapContext = RunReadingContext(
            score: 210,
            best: 240,
            runStartBest: 0,
            maxCombo: 1,
            didClearAny: true,
            hasUsedContinue: false,
            terminalPressureBand: .calm,
            occupiedCellCount: 6,
            completedRuns: 4
        )
        #expect(RunReadingSummary.progressLine(for: gapContext, isNewBest: false) == "30 to best")

        let runCountContext = RunReadingContext(
            score: 50,
            best: 240,
            runStartBest: 0,
            maxCombo: 0,
            didClearAny: false,
            hasUsedContinue: false,
            terminalPressureBand: .calm,
            occupiedCellCount: 3,
            completedRuns: 12
        )
        #expect(RunReadingSummary.progressLine(for: runCountContext, isNewBest: false) == "Run 12")

        #expect(RunReadingSummary.quietNearMissMasteryLine(
            score: 209,
            best: 240,
            maxCombo: 2,
            didClearAny: true,
            hasUsedContinue: false
        ) == nil)
        #expect(RunReadingSummary.credibleGapToBestLine(
            score: 210,
            best: 240,
            didClearAny: true,
            hasUsedContinue: true,
            isNewBest: false
        ) == nil)
        #expect(RunReadingSummary.credibleGapToBestLine(
            score: 0,
            best: 240,
            didClearAny: true,
            hasUsedContinue: false,
            isNewBest: false
        ) == nil)
    }

    @Test
    func runReadingSummaryMapsNewBestBadgeOnly() {
        let context = RunReadingContext(
            score: 250,
            best: 250,
            runStartBest: 200,
            maxCombo: 2,
            didClearAny: true,
            hasUsedContinue: false,
            terminalPressureBand: .attentive,
            occupiedCellCount: 9,
            completedRuns: 3
        )
        let summary = RunReadingSummary.summary(context: context)
        #expect(summary.caption == "Run complete")
        #expect(summary.badge == "New Best")
        #expect(summary.readingDetail == "Chain-led reading")
    }

    @Test
    func runReadingSummaryLayerStaysReadOnlyPresentation() throws {
        let repoRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let summarySource = try String(
            contentsOf: repoRoot.appendingPathComponent("Vexlo/Services/RunReadingSummary.swift"),
            encoding: .utf8
        )
        let gameSceneSource = try String(
            contentsOf: repoRoot.appendingPathComponent("Vexlo/UI/GameScene.swift"),
            encoding: .utf8
        )
        #expect(!summarySource.contains("UserDefaults"))
        #expect(!summarySource.contains("completeRun"))
        #expect(!summarySource.contains("PieceFactory"))
        #expect(!summarySource.contains("registerClear"))
        #expect(gameSceneSource.contains("RunReadingSummary.summary"))
        #expect(gameSceneSource.contains("DailyRitualClosure.closure"))
        #expect(!gameSceneSource.contains("editorialRunCharacter"))
        #expect(!gameSceneSource.contains("resultDetailLine"))
        #expect(!gameSceneSource.contains("caption = VexloStrings.Overlay.gameOver"))
    }

    @Test
    func resultOverlayCaptureSuppressesGamesButPreservesMeaningfulProgress() {
        #expect(!GameScene.shouldShowResultGames(isResultOverlayCapture: true, showsGames: true, canShare: false, showsContinue: false))
        #expect(!GameScene.shouldShowResultGames(isResultOverlayCapture: false, showsGames: true, canShare: true, showsContinue: false))
        #expect(!GameScene.shouldShowResultGames(isResultOverlayCapture: false, showsGames: true, canShare: false, showsContinue: true))
        #expect(GameScene.shouldShowResultGames(isResultOverlayCapture: false, showsGames: true, canShare: false, showsContinue: false))
        #expect(GameScene.shouldShowResultProgress(showsProgress: true, progressText: "Streak 4"))
        #expect(GameScene.shouldShowResultProgress(showsProgress: true, progressText: "Run 12"))
        #expect(!GameScene.shouldShowResultProgress(showsProgress: true, progressText: ""))
        #expect(!GameScene.shouldShowResultProgress(showsProgress: false, progressText: "Streak 4"))
        #expect(!GameScene.shouldShowResultShare(canShare: true, showsContinue: true))
        #expect(GameScene.shouldShowResultShare(canShare: true, showsContinue: false))
        #expect(!GameScene.shouldShowResultShare(canShare: false, showsContinue: false))
    }

    @Test
    func dailyChallengeCompletionOnlyCountsOncePerDayAndSeedStaysStable() {
        let (defaults, suiteName) = makeDefaults()
        defer { clear(suiteName) }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        let service = DailyChallengeService(defaults: defaults, calendar: calendar)

        let dayID = "2025-01-15"
        #expect(service.seed(for: dayID) == service.status(for: dayID).seed)

        let first = service.completeRun(dayID: dayID, score: 120)
        let second = service.completeRun(dayID: dayID, score: 90)

        #expect(first.streakCount == 1)
        #expect(second.streakCount == 1)
        #expect(second.todayBest == 120)
    }

    @Test
    func hiddenCaptureLaunchConfigurationKeepsEditorialStatesRecognized() {
        let publicStates: [(String, CaptureState)] = [
            ("normal-run", .normalRun),
            ("normal-hero", .normalHero),
            ("daily-challenge", .dailyChallenge),
            ("daily-hero", .dailyHero),
            ("normal-result", .normalResult),
            ("daily-result", .dailyResult)
        ]

        for (rawValue, expectedState) in publicStates {
            let configuration = CaptureLaunchConfiguration(arguments: ["Vexlo", "-VexloCaptureState", rawValue])

            #expect(configuration.state == expectedState)
            #expect(configuration.isCaptureMode)
            #expect(configuration.intent == .editorial)
            #expect(!configuration.isInternalCapture)
            #expect(configuration.resultScoreOverride == nil)
        }
    }

    @Test
    func resultShareServiceKeepsImageLedCardsReachableForNormalAndDailyPayloads() throws {
        let controller = UIActivityViewController(activityItems: ["placeholder"], applicationActivities: nil)
        let cases: [(ResultSharePayload, String)] = [
            (
                ResultSharePayload(mode: .normal, score: 210, badge: "New Best", detail: "12 to best"),
                "VEXLO - Main Run - 210 - New Best"
            ),
            (
                ResultSharePayload(mode: .daily, score: 70, badge: "Best Today", detail: "Balanced board complete"),
                "VEXLO - Today's Challenge - 70 - Best Today"
            ),
            (
                ResultSharePayload(
                    mode: .daily,
                    score: 70,
                    badge: "Best Today",
                    detail: "Balanced board complete",
                    dailyRitualHeadline: "WEDNESDAY · BALANCED BOARD"
                ),
                "VEXLO - Today's Challenge - WEDNESDAY · BALANCED BOARD - 70 - Best Today"
            )
        ]

        for (payload, expectedTitle) in cases {
            let items = ResultShareService.activityItems(for: payload)
            #expect(items.count == 1)

            let source = try #require(items.first as? UIActivityItemSource)
            let placeholder = try #require(source.activityViewControllerPlaceholderItem(controller) as? UIImage)
            #expect(placeholder.size == CGSize(width: 1200, height: 1600))

            let item = try #require(source.activityViewController(controller, itemForActivityType: nil) as? UIImage)
            #expect(item.size == CGSize(width: 1200, height: 1600))

            let subject = source.activityViewController?(controller, subjectForActivityType: nil)
            #expect(subject == expectedTitle)

            let metadata = try #require(source.activityViewControllerLinkMetadata?(controller))
            #expect(metadata.title == expectedTitle)
            #expect(metadata.imageProvider != nil)
        }
    }

    @Test
    func hiddenCaptureResultStatesStayDistinctAndOwnScoreOverride() {
        let normal = CaptureLaunchConfiguration(arguments: [
            "Vexlo",
            "-VexloCaptureState=normal-result",
            "-VexloCaptureScore",
            "12"
        ])
        let daily = CaptureLaunchConfiguration(arguments: [
            "Vexlo",
            "-VexloCaptureState",
            "daily-result",
            "-VexloCaptureScore=34"
        ])
        let opening = CaptureLaunchConfiguration(arguments: [
            "Vexlo",
            "-VexloCaptureState",
            "normal-run",
            "-VexloCaptureScore",
            "7"
        ])

        #expect(normal.state == .normalResult)
        #expect(daily.state == .dailyResult)
        #expect(normal.isResultOverlayCapture)
        #expect(daily.isResultOverlayCapture)
        #expect(normal.resultScoreOverride == 12)
        #expect(daily.resultScoreOverride == 34)
        #expect(!opening.isResultOverlayCapture)
        #expect(opening.resultScoreOverride == nil)
    }

    @Test
    func hiddenCaptureHeroStatesAndInternalIntentStayExplicit() {
        let normalHero = CaptureLaunchConfiguration(arguments: ["Vexlo", "-VexloCaptureState", "normal-hero"])
        let dailyHero = CaptureLaunchConfiguration(arguments: ["Vexlo", "-VexloCaptureState", "daily-hero"])
        let internalCapture = CaptureLaunchConfiguration(arguments: [
            "Vexlo",
            "-VexloCaptureState",
            "utility-surface",
            "-VexloCaptureIntent",
            "internal"
        ])
        let invalidIntent = CaptureLaunchConfiguration(arguments: [
            "Vexlo",
            "-VexloCaptureState",
            "utility-surface",
            "-VexloCaptureIntent",
            "private"
        ])

        #expect(normalHero.state == .normalHero)
        #expect(dailyHero.state == .dailyHero)
        #expect(internalCapture.intent == .internal)
        #expect(internalCapture.isInternalCapture)
        #expect(invalidIntent.intent == .editorial)
        #expect(!invalidIntent.isInternalCapture)
    }
}

@Suite(.serialized)
struct SceneResumeFirstRegressionTests {
    @Test
    func freshLaunchRestorePassRestoresPersistedRunAtSceneLevel() throws {
        clearSharedResumeState()
        defer { clearSharedResumeState() }

        let snapshot = try makeResumableNormalSnapshot(seed: 0x1234, placements: 2)
        LiveRunPersistenceService.shared.save(snapshot)

        let scene = GameScene(size: CGSize(width: 390, height: 844))
        let state = scene.testingResumeFirstState
        #expect(state.runMode == .normal)
        #expect(state.score == snapshot.score)
        #expect(state.occupiedCellCount == snapshot.board.cells.count)
        #expect(state.hasAttemptedPersistedRestore)
        #expect(!state.isGameOver)
    }

    @Test
    func activeInMemoryResumeRouteDoesNotReRestorePersistedRun() throws {
        clearSharedResumeState()
        defer { clearSharedResumeState() }

        let initialSnapshot = try makeResumableNormalSnapshot(seed: 0xCAFE, placements: 1)
        LiveRunPersistenceService.shared.save(initialSnapshot)

        let scene = GameScene(size: CGSize(width: 390, height: 844))
        let restoredState = scene.testingResumeFirstState
        #expect(restoredState.occupiedCellCount == initialSnapshot.board.cells.count)

        let laterSnapshot = try makeResumableNormalSnapshot(seed: 0xBEEF, placements: 3)
        LiveRunPersistenceService.shared.save(laterSnapshot)
        SystemEntryService.shared.markRunActive(mode: .normal)

        scene.testingApplySystemEntryRoute(.resumeLastRun)

        let state = scene.testingResumeFirstState
        #expect(state.runMode == restoredState.runMode)
        #expect(state.score == restoredState.score)
        #expect(state.occupiedCellCount == restoredState.occupiedCellCount)
        #expect(state.occupiedCellCount != laterSnapshot.board.cells.count)
    }

    @Test
    func nonResumableResumeRouteDoesNotFalselyRestore() {
        clearSharedResumeState()
        defer { clearSharedResumeState() }

        let scene = GameScene(size: CGSize(width: 390, height: 844))
        let baseline = scene.testingResumeFirstState

        scene.testingApplySystemEntryRoute(.resumeLastRun)

        let state = scene.testingResumeFirstState
        #expect(state.runMode == baseline.runMode)
        #expect(state.score == baseline.score)
        #expect(state.occupiedCellCount == baseline.occupiedCellCount)
        #expect(state.hasAttemptedPersistedRestore == baseline.hasAttemptedPersistedRestore)
    }
}

@Suite(.serialized)
struct TerminalResultFinalizationRegressionTests {
    @Test
    func dailyCompletionFinalizesExactlyOnceAtTrueTerminalCompletion() throws {
        clearSharedResumeState()
        MonetizationService.shared.testingClearCanPresentOverrides()
        defer {
            MonetizationService.shared.testingClearCanPresentOverrides()
            clearSharedResumeState()
        }

        let dayID = uniqueDayID()
        let seed = DailyChallengeService.shared.seed(for: dayID)
        let analyticsBefore = analyticsSnapshot()
        let dailyBefore = DailyChallengeService.shared.status(for: dayID)
        let scene = GameScene(size: CGSize(width: 390, height: 844))

        scene.testingBeginSceneRun(mode: .daily(dayID: dayID, seed: seed))
        scene.testingLoadTerminalState(
            mode: .daily(dayID: dayID, seed: seed),
            emptyCoordinates: Set([HexCoordinate(1, 0), HexCoordinate(4, 2), HexCoordinate(6, 5)]),
            tray: terminalTrayPieces(),
            score: 70,
            best: 40,
            combo: 1,
            didClearAny: true,
            maxCombo: 1,
            runStartBest: 40
        )

        scene.testingSyncAll()
        scene.testingSyncAll()

        let state = scene.testingTerminalFinalizationState
        let dailyAfter = DailyChallengeService.shared.status(for: dayID)
        let analyticsAfter = analyticsSnapshot()

        #expect(state.runMode == .daily(dayID: dayID, seed: seed))
        #expect(state.isGameOver)
        #expect(state.isOverlayPresented)
        #expect(state.hasFinalizedRun)
        #expect(!state.canShowContinueAfterLoss)
        #expect(!dailyBefore.hasCompletedToday)
        #expect(dailyAfter.hasCompletedToday)
        #expect(dailyAfter.todayBest == 70)
        #expect(analyticsAfter.dailyChallengeCompletedCount == analyticsBefore.dailyChallengeCompletedCount + 1)
        #expect(analyticsAfter.runsEnded == analyticsBefore.runsEnded + 1)
        #expect(analyticsAfter.dailyRunsEnded == analyticsBefore.dailyRunsEnded + 1)
    }

    @Test
    func completedNormalRunCountingFinalizesExactlyOnce() throws {
        clearSharedResumeState()
        MonetizationService.shared.testingClearCanPresentOverrides()
        defer {
            MonetizationService.shared.testingClearCanPresentOverrides()
            clearSharedResumeState()
        }

        let completedRunsBefore = GameCenterService.shared.completedRunCount
        let analyticsBefore = analyticsSnapshot()
        let scene = GameScene(size: CGSize(width: 390, height: 844))

        MonetizationService.shared.testingSetCanPresentOverride(false, for: .continueAfterLoss)
        scene.testingBeginSceneRun(mode: .normal)
        scene.testingLoadTerminalState(
            mode: .normal,
            emptyCoordinates: Set([HexCoordinate(0, 0), HexCoordinate(3, 3), HexCoordinate(6, 6)]),
            tray: terminalTrayPieces(),
            score: 240,
            best: 240,
            combo: 2,
            didClearAny: true,
            maxCombo: 2,
            runStartBest: 180
        )

        scene.testingSyncAll()
        scene.testingSyncAll()

        let state = scene.testingTerminalFinalizationState
        let analyticsAfter = analyticsSnapshot()

        #expect(state.runMode == .normal)
        #expect(state.isGameOver)
        #expect(state.isOverlayPresented)
        #expect(state.hasFinalizedRun)
        #expect(!state.canShowContinueAfterLoss)
        #expect(GameCenterService.shared.completedRunCount == completedRunsBefore + 1)
        #expect(analyticsAfter.runsEnded == analyticsBefore.runsEnded + 1)
        #expect(analyticsAfter.normalRunsEnded == analyticsBefore.normalRunsEnded + 1)
    }

    @Test
    func continueEligibleTerminalStatesDoNotFinalizeBeforeContinueResolves() throws {
        clearSharedResumeState()
        MonetizationService.shared.testingClearCanPresentOverrides()
        defer {
            MonetizationService.shared.testingClearCanPresentOverrides()
            clearSharedResumeState()
        }

        let completedRunsBefore = GameCenterService.shared.completedRunCount
        let analyticsBefore = analyticsSnapshot()
        let scene = GameScene(size: CGSize(width: 390, height: 844))

        MonetizationService.shared.testingSetCanPresentOverride(true, for: .continueAfterLoss)
        scene.testingBeginSceneRun(mode: .normal)
        scene.testingLoadTerminalState(
            mode: .normal,
            emptyCoordinates: Set([HexCoordinate(0, 0), HexCoordinate(3, 3), HexCoordinate(6, 6)]),
            tray: terminalTrayPieces(),
            score: 240,
            best: 240,
            combo: 2,
            didClearAny: true,
            maxCombo: 2,
            runStartBest: 180
        )

        scene.testingSyncAll()
        scene.testingSyncAll()

        let state = scene.testingTerminalFinalizationState
        let analyticsAfter = analyticsSnapshot()

        #expect(state.runMode == .normal)
        #expect(state.isGameOver)
        #expect(state.isOverlayPresented)
        #expect(!state.hasFinalizedRun)
        #expect(state.canShowContinueAfterLoss)
        #expect(GameCenterService.shared.completedRunCount == completedRunsBefore)
        #expect(analyticsAfter.runsEnded == analyticsBefore.runsEnded)
        #expect(analyticsAfter.normalRunsEnded == analyticsBefore.normalRunsEnded)
    }
}

@Suite(.serialized)
struct MonetizationOfferLifecycleRegressionTests {
    @Test
    func continueAndRerollVisibilityFollowPerRunLifecycleWithoutShownDoubleCounts() {
        clearSharedResumeState()
        MonetizationService.shared.testingClearCanPresentOverrides()
        defer {
            MonetizationService.shared.testingClearCanPresentOverrides()
            clearSharedResumeState()
        }

        let analyticsBefore = analyticsSnapshot()
        let scene = GameScene(size: CGSize(width: 390, height: 844))

        MonetizationService.shared.testingSetCanPresentOverride(true, for: .continueAfterLoss)
        MonetizationService.shared.testingSetCanPresentOverride(true, for: .rerollTrayPiece)

        scene.testingBeginSceneRun(mode: .normal)
        let analyticsAfterBegin = analyticsSnapshot()
        scene.testingSyncAll()
        scene.testingSyncAll()

        let activeState = scene.testingMonetizationOfferLifecycleState
        let activeAnalytics = analyticsSnapshot()

        #expect(activeState.runMode == .normal)
        #expect(!activeState.isGameOver)
        #expect(!activeState.canShowContinueAfterLoss)
        #expect(!activeState.visibleRerollOfferSlots.isEmpty)
        #expect(activeAnalytics.continueOfferShownCount == analyticsAfterBegin.continueOfferShownCount)
        #expect(activeAnalytics.rerollOfferShownCount == analyticsAfterBegin.rerollOfferShownCount)
        #expect(analyticsAfterBegin.rerollOfferShownCount > analyticsBefore.rerollOfferShownCount)

        scene.testingLoadTerminalState(
            mode: .normal,
            emptyCoordinates: Set([HexCoordinate(0, 0), HexCoordinate(3, 3), HexCoordinate(6, 6)]),
            tray: terminalTrayPieces(),
            score: 240,
            best: 240,
            combo: 2,
            didClearAny: true,
            maxCombo: 2,
            runStartBest: 180
        )
        scene.testingSyncAll()
        scene.testingSyncAll()

        let analyticsAfterTerminalBegin = analyticsSnapshot()
        scene.testingSyncAll()
        scene.testingSyncAll()

        let terminalState = scene.testingMonetizationOfferLifecycleState
        let terminalAnalytics = analyticsSnapshot()

        #expect(terminalState.isGameOver)
        #expect(terminalState.canShowContinueAfterLoss)
        #expect(terminalState.hasRecordedContinueOfferForCurrentLoss)
        #expect(terminalState.visibleRerollOfferSlots.isEmpty)
        #expect(analyticsAfterTerminalBegin.continueOfferShownCount == activeAnalytics.continueOfferShownCount + 1)
        #expect(terminalAnalytics.continueOfferShownCount == analyticsAfterTerminalBegin.continueOfferShownCount)
        #expect(terminalAnalytics.rerollOfferShownCount == analyticsAfterTerminalBegin.rerollOfferShownCount)
    }

    @Test
    func restoredRunsPreserveConsumedOfferStateWithoutFalseOfferAnalytics() throws {
        clearSharedResumeState()
        MonetizationService.shared.testingClearCanPresentOverrides()
        defer {
            MonetizationService.shared.testingClearCanPresentOverrides()
            clearSharedResumeState()
        }

        let analyticsBefore = analyticsSnapshot()
        let restoredSnapshot = try makeConsumedOfferRestoreSnapshot()
        MonetizationService.shared.testingSetCanPresentOverride(true, for: .continueAfterLoss)
        MonetizationService.shared.testingSetCanPresentOverride(true, for: .rerollTrayPiece)
        let scene = GameScene(size: CGSize(width: 390, height: 844))

        scene.testingSyncAll()
        scene.testingSyncAll()
        let analyticsAfterSceneWarmup = analyticsSnapshot()

        scene.testingRestoreLiveRun(from: restoredSnapshot)
        scene.testingSyncAll()
        scene.testingSyncAll()

        let state = scene.testingMonetizationOfferLifecycleState
        let monetizationState = MonetizationService.shared.testingRunState
        let analyticsAfter = analyticsSnapshot()

        #expect(state.runMode == .normal)
        #expect(!state.isGameOver)
        #expect(state.hasUsedContinue)
        #expect(state.hasUsedReroll)
        #expect(!state.canShowContinueAfterLoss)
        #expect(state.visibleRerollOfferSlots.isEmpty)
        #expect(monetizationState.isActive)
        #expect(!monetizationState.hasEnded)
        #expect(monetizationState.continueOfferCount == 1)
        #expect(monetizationState.rerollOfferCount == 1)
        #expect(analyticsAfterSceneWarmup.continueOfferShownCount >= analyticsBefore.continueOfferShownCount)
        #expect(analyticsAfter.continueOfferShownCount == analyticsAfterSceneWarmup.continueOfferShownCount)
        #expect(analyticsAfter.continueUsedCount == analyticsAfterSceneWarmup.continueUsedCount)
        #expect(analyticsAfter.rerollOfferShownCount == analyticsAfterSceneWarmup.rerollOfferShownCount)
        #expect(analyticsAfter.rerollUsedCount == analyticsAfterSceneWarmup.rerollUsedCount)
    }

    @Test
    func newRunResetsConsumedOfferStateWithoutDoubleCountingUsedAnalytics() {
        clearSharedResumeState()
        MonetizationService.shared.testingClearCanPresentOverrides()
        defer {
            MonetizationService.shared.testingClearCanPresentOverrides()
            clearSharedResumeState()
        }

        let analyticsBefore = analyticsSnapshot()
        let scene = GameScene(size: CGSize(width: 390, height: 844))

        MonetizationService.shared.testingSetCanPresentOverride(true, for: .continueAfterLoss)
        MonetizationService.shared.testingSetCanPresentOverride(true, for: .rerollTrayPiece)

        scene.testingBeginSceneRun(mode: .normal)
        scene.testingSyncAll()

        let rerollSlot = scene.testingMonetizationOfferLifecycleState.visibleRerollOfferSlots.sorted().first
        #expect(rerollSlot != nil)
        if let rerollSlot {
            #expect(scene.testingResolveRerollRewarded(at: rerollSlot))
        }

        let afterRerollState = scene.testingMonetizationOfferLifecycleState
        let afterRerollMonetization = MonetizationService.shared.testingRunState
        let analyticsAfterReroll = analyticsSnapshot()

        #expect(afterRerollState.hasUsedReroll)
        #expect(afterRerollState.visibleRerollOfferSlots.isEmpty)
        #expect(afterRerollMonetization.rerollOfferCount == 1)
        #expect(analyticsAfterReroll.rerollUsedCount == analyticsBefore.rerollUsedCount + 1)

        scene.testingBeginSceneRun(mode: .normal)
        scene.testingSyncAll()

        let afterRerollResetState = scene.testingMonetizationOfferLifecycleState
        let afterRerollResetMonetization = MonetizationService.shared.testingRunState
        let analyticsAfterRerollReset = analyticsSnapshot()

        #expect(!afterRerollResetState.hasUsedReroll)
        #expect(!afterRerollResetState.visibleRerollOfferSlots.isEmpty)
        #expect(afterRerollResetMonetization.rerollOfferCount == 0)
        #expect(analyticsAfterRerollReset.rerollUsedCount == analyticsAfterReroll.rerollUsedCount)

        scene.testingLoadTerminalState(
            mode: .normal,
            emptyCoordinates: Set([HexCoordinate(0, 0), HexCoordinate(3, 3), HexCoordinate(6, 6)]),
            tray: terminalTrayPieces(),
            score: 240,
            best: 240,
            combo: 2,
            didClearAny: true,
            maxCombo: 2,
            runStartBest: 180
        )
        scene.testingSyncAll()

        #expect(scene.testingResolveContinueRewardedIfPossible())

        let afterContinueState = scene.testingMonetizationOfferLifecycleState
        let afterContinueMonetization = MonetizationService.shared.testingRunState
        let analyticsAfterContinue = analyticsSnapshot()

        #expect(afterContinueState.hasUsedContinue)
        #expect(!afterContinueState.canShowContinueAfterLoss)
        #expect(afterContinueMonetization.continueOfferCount == 1)
        #expect(analyticsAfterContinue.continueUsedCount == analyticsBefore.continueUsedCount + 1)

        scene.testingBeginSceneRun(mode: .normal)
        scene.testingSyncAll()
        scene.testingSyncAll()

        let afterContinueResetState = scene.testingMonetizationOfferLifecycleState
        let afterContinueResetMonetization = MonetizationService.shared.testingRunState
        let analyticsAfterContinueReset = analyticsSnapshot()

        #expect(afterContinueResetState.runMode == .normal)
        #expect(!afterContinueResetState.isGameOver)
        #expect(!afterContinueResetState.hasUsedContinue)
        #expect(!afterContinueResetState.canShowContinueAfterLoss)
        #expect(afterContinueResetMonetization.continueOfferCount == 0)
        #expect(analyticsAfterContinueReset.continueUsedCount == analyticsAfterContinue.continueUsedCount)
        #expect(analyticsAfterContinueReset.rerollUsedCount == analyticsAfterContinue.rerollUsedCount)
    }
}

private func boardPressure(
    on board: HexBoard,
    occupiedCellCount: Int? = nil,
    isOpeningState: Bool
) -> BoardPressureSnapshot {
    let context = BoardPressureContext(
        occupiedCellCount: occupiedCellCount ?? board.snapshot.cells.count,
        isOpeningState: isOpeningState,
        cols: board.cols,
        rows: board.rows
    )
    return BoardPressure.evaluate(board: board, context: context)
}

private func placementEvaluation(
    on board: HexBoard,
    piece: HexPiece,
    anchor: HexCoordinate,
    isOpeningState: Bool = false
) -> PlacementEvaluation? {
    let occupied = Set(board.snapshot.cells.map(\.coordinate))
    let resolution = board.placementResolution(for: piece, at: anchor)
    let context = PlacementEvaluationContext(
        occupiedCellCount: occupied.count,
        isOpeningState: isOpeningState
    )
    return PlacementEvaluation.evaluate(
        resolution: resolution,
        context: context,
        occupiedCoordinates: occupied
    )
}

private func engineOccupiedCoordinates(excluding empty: [HexCoordinate]) -> [HexCoordinate] {
    let emptySet = Set(empty)
    return (0..<7).flatMap { col in
        (0..<7).map { HexCoordinate(col, $0) }
    }.filter { !emptySet.contains($0) }
}

private func makeEngineForPlacementParity(
    emptyCoordinates: Set<HexCoordinate>,
    tray: [HexPiece]
) -> GameEngine {
    let engine = GameEngine()
    engine.loadCaptureTerminalState(
        mode: .normal,
        emptyCoordinates: emptyCoordinates,
        tray: tray,
        score: 0,
        best: 0,
        combo: 0,
        didClearAny: false,
        maxCombo: 0
    )
    return engine
}

private func expectEnginePreviewMatchesCommitted(
    _ engine: GameEngine,
    piece: HexPiece,
    anchor: HexCoordinate,
    slotIndex: Int
) {
    let boardBefore = engine.board.snapshot
    let preview = engine.previewPlacement(piece, at: anchor)
    let committed = engine.place(piece, at: anchor, slotIndex: slotIndex)
    #expect(preview == committed)
    if !preview.isLegal {
        #expect(boardSignature(engine.board.snapshot) == boardSignature(boardBefore))
    }
}

private func firstLegalAnchor(for piece: HexPiece, in engine: GameEngine) -> HexCoordinate? {
    engine.board.allCoordinates().first { engine.canPlace(piece, at: $0) }
}

private func pieceSignature(_ piece: HexPiece) -> String {
    let offsets = piece.offsets
        .map { "\($0.col):\($0.row)" }
        .joined(separator: "|")
    return "\(offsets)#\(piece.color.hexString)"
}

private func pieceSignatures(_ pieces: [HexPiece?]) -> [String?] {
    pieces.map { $0.map(pieceSignature) }
}

private func batchOffsetSignatures(_ pieces: [HexPiece]) -> [String] {
    pieces.map { piece in
        piece.offsets
            .sorted { lhs, rhs in
                if lhs.col == rhs.col {
                    return lhs.row < rhs.row
                }
                return lhs.col < rhs.col
            }
            .map { "\($0.col):\($0.row)" }
            .joined(separator: "|")
    }
}

private func boardSignature(_ snapshot: HexBoard.Snapshot) -> [String] {
    snapshot.cells.map { "\($0.coordinate.col):\($0.coordinate.row)#\($0.colorHex)" }
}

private func encodedSnapshot(_ snapshot: GameEngine.LiveRunSnapshot) throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let data = try encoder.encode(snapshot)
    return String(decoding: data, as: UTF8.self)
}

private func terminalTrayPieces() -> [HexPiece] {
    [
        HexPiece(offsets: [HexCoordinate(0, 0), HexCoordinate(0, 1)], color: UIColor(hex: "7A74F7")),
        HexPiece(offsets: [HexCoordinate(0, 0), HexCoordinate(1, 0)], color: UIColor(hex: "55A7F6")),
        HexPiece(offsets: [HexCoordinate(0, 0), HexCoordinate(1, 0), HexCoordinate(0, 1)], color: UIColor(hex: "63C7B0"))
    ]
}

private func analyticsSnapshot() -> AnalyticsSnapshot {
    let data = AnalyticsService.shared.exportSnapshot().data(using: .utf8) ?? Data()
    let snapshot = try? JSONDecoder().decode(AnalyticsSnapshot.self, from: data)
    return snapshot ?? AnalyticsSnapshot(
        continueOfferShownCount: 0,
        continueUsedCount: 0,
        rerollOfferShownCount: 0,
        rerollUsedCount: 0,
        runsEnded: 0,
        normalRunsEnded: 0,
        dailyRunsEnded: 0,
        dailyChallengeCompletedCount: 0
    )
}

private func uniqueDayID() -> String {
    let token = abs(UUID().uuidString.hashValue)
    let month = token % 12 + 1
    let day = (token / 12) % 28 + 1
    return String(format: "2099-%02d-%02d", month, day)
}

private func makeResumableNormalSnapshot(seed: UInt64, placements: Int) throws -> GameEngine.LiveRunSnapshot {
    let engine = GameEngine()
    engine.startNormalRun(seed: seed)

    for _ in 0..<placements {
        let slotIndex = try #require(engine.pieces.firstIndex { $0 != nil })
        let piece = try #require(engine.pieces[slotIndex])
        let anchor = try #require(firstLegalAnchor(for: piece, in: engine))
        engine.place(piece, at: anchor, slotIndex: slotIndex)
    }

    return try #require(engine.makeLiveRunSnapshot(runStartBest: 0))
}

private func makeConsumedOfferRestoreSnapshot() throws -> GameEngine.LiveRunSnapshot {
    let engine = GameEngine()
    engine.startNormalRun(seed: 0xBEEF)
    engine.loadCaptureTerminalState(
        mode: .normal,
        emptyCoordinates: Set([HexCoordinate(0, 0), HexCoordinate(3, 3), HexCoordinate(6, 6)]),
        tray: terminalTrayPieces(),
        score: 240,
        best: 240,
        combo: 2,
        didClearAny: true,
        maxCombo: 2
    )

    #expect(engine.continueAfterLoss())
    let rerollSlot = try #require(firstRerollableSlot(in: engine))
    #expect(engine.rerollPiece(at: rerollSlot))

    return try #require(engine.makeLiveRunSnapshot(runStartBest: 180))
}

private func firstRerollableSlot(in engine: GameEngine) -> Int? {
    engine.pieces.indices.first { engine.canRerollPiece(at: $0) }
}

private func makeDefaults() -> (UserDefaults, String) {
    let suiteName = "CriticalPathRegressionTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName) ?? .standard
    defaults.removePersistentDomain(forName: suiteName)
    return (defaults, suiteName)
}

private func clear(_ suiteName: String) {
    UserDefaults.standard.removePersistentDomain(forName: suiteName)
}

private func clearSharedResumeState() {
    SystemEntryService.shared.clearResumableRun()
    LiveRunPersistenceService.shared.clear()
}

private struct AnalyticsSnapshot: Decodable {
    let continueOfferShownCount: Int
    let continueUsedCount: Int
    let rerollOfferShownCount: Int
    let rerollUsedCount: Int
    let runsEnded: Int
    let normalRunsEnded: Int
    let dailyRunsEnded: Int
    let dailyChallengeCompletedCount: Int
}
