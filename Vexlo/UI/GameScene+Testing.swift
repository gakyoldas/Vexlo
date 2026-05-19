import Foundation

extension GameScene {
    struct ResumeFirstTestingState {
        let runMode: GameEngine.RunMode
        let score: Int
        let occupiedCellCount: Int
        let hasAttemptedPersistedRestore: Bool
        let isGameOver: Bool
    }

    struct TerminalFinalizationTestingState {
        let runMode: GameEngine.RunMode
        let score: Int
        let hasFinalizedRun: Bool
        let canShowContinueAfterLoss: Bool
        let isGameOver: Bool
        let isOverlayPresented: Bool
    }

    struct MonetizationOfferLifecycleTestingState {
        let runMode: GameEngine.RunMode
        let canShowContinueAfterLoss: Bool
        let visibleRerollOfferSlots: Set<Int>
        let hasRecordedContinueOfferForCurrentLoss: Bool
        let hasUsedContinue: Bool
        let hasUsedReroll: Bool
        let isGameOver: Bool
    }

    var testingResumeFirstState: ResumeFirstTestingState {
        ResumeFirstTestingState(
            runMode: engine.runMode,
            score: engine.scoreEngine.score,
            occupiedCellCount: engine.board.snapshot.cells.count,
            hasAttemptedPersistedRestore: hasAttemptedPersistedRestore,
            isGameOver: engine.isGameOver
        )
    }

    func testingApplySystemEntryRoute(_ route: SystemEntryRoute) {
        applySystemEntryRoute(route)
    }

    var testingTerminalFinalizationState: TerminalFinalizationTestingState {
        TerminalFinalizationTestingState(
            runMode: engine.runMode,
            score: engine.scoreEngine.score,
            hasFinalizedRun: hasFinalizedRun,
            canShowContinueAfterLoss: canShowContinueAfterLoss(),
            isGameOver: engine.isGameOver,
            isOverlayPresented: isOverlayPresented
        )
    }

    var testingMonetizationOfferLifecycleState: MonetizationOfferLifecycleTestingState {
        MonetizationOfferLifecycleTestingState(
            runMode: engine.runMode,
            canShowContinueAfterLoss: canShowContinueAfterLoss(),
            visibleRerollOfferSlots: visibleRerollOfferSlots,
            hasRecordedContinueOfferForCurrentLoss: hasRecordedContinueOfferForCurrentLoss,
            hasUsedContinue: engine.hasUsedContinue,
            hasUsedReroll: engine.hasUsedReroll,
            isGameOver: engine.isGameOver
        )
    }

    func testingBeginSceneRun(mode: GameEngine.RunMode) {
        beginSceneRun(mode: mode)
    }

    var testingPresentedDailyArrivalDayID: String? {
        DailyArrivalRitualService.shared.presentedArrivalDayID()
    }

    func testingRestoreLiveRun(from snapshot: GameEngine.LiveRunSnapshot) {
        restoreLiveRun(from: snapshot)
    }

    func testingMakeLiveRunSnapshot(runStartBest: Int) -> GameEngine.LiveRunSnapshot? {
        engine.makeLiveRunSnapshot(runStartBest: runStartBest)
    }

    func testingLoadTerminalState(
        mode: GameEngine.RunMode,
        emptyCoordinates: Set<HexCoordinate>,
        tray: [HexPiece],
        score: Int,
        best: Int,
        combo: Int,
        didClearAny: Bool,
        maxCombo: Int,
        runStartBest: Int
    ) {
        cancelDrag()
        resetVisualActions()
        hideOverlayIfNeeded()
        hideUtilitySurface()
        lastDailyCompletion = nil
        hasFinalizedRun = false
        hasRecordedContinueOfferForCurrentLoss = false
        isRestarting = false
        isPresentingContinue = false
        isPresentingReroll = false
        isPresentingSupporterPurchase = false
        isPresentingNewRunConfirmation = false
        self.runStartBest = runStartBest
        engine.loadCaptureTerminalState(
            mode: mode,
            emptyCoordinates: emptyCoordinates,
            tray: tray,
            score: score,
            best: best,
            combo: combo,
            didClearAny: didClearAny,
            maxCombo: maxCombo
        )
    }

    func testingSyncAll() {
        syncAll()
    }

    @discardableResult
    func testingResolveContinueRewardedIfPossible() -> Bool {
        guard canShowContinueAfterLoss(), engine.continueAfterLoss() else { return false }
        MonetizationService.shared.recordOfferPresentation(.continueAfterLoss)
        AnalyticsService.shared.recordContinueUsedSuccessfully(
            viaSupporterBypass: MonetizationService.shared.capabilities.supporterOwned
        )
        MonetizationService.shared.resumeRunAfterContinue()
        resetVisualActions()
        hideOverlayIfNeeded()
        syncAll()
        return true
    }

    @discardableResult
    func testingResolveRerollRewarded(at slotIndex: Int) -> Bool {
        guard canShowReroll(for: slotIndex), engine.rerollPiece(at: slotIndex) else { return false }
        MonetizationService.shared.recordOfferPresentation(.rerollTrayPiece)
        AnalyticsService.shared.recordRerollUsedSuccessfully(
            viaSupporterBypass: MonetizationService.shared.capabilities.supporterOwned
        )
        syncTray()
        return true
    }
}
