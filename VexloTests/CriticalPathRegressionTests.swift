import Foundation
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
    func normalOpeningModeLabelTextUsesBoardReadingThesis() {
        #expect(VexloStrings.HUD.boardReading == "Board reading")
        #expect(GameScene.normalOpeningModeLabelText() == "Board reading")
    }

    @Test
    func dragPreviewProfilesDistinguishValidClearAndMultiClearPlacements() {
        #expect(GameScene.dragPreviewProfile(isValid: false, clearedLineCount: 0) == .invalidPlacement)
        #expect(GameScene.dragPreviewProfile(isValid: true, clearedLineCount: 0) == .validPlacement)
        #expect(GameScene.dragPreviewProfile(isValid: true, clearedLineCount: 1) == .clearPlacement)
        #expect(GameScene.dragPreviewProfile(isValid: true, clearedLineCount: 2) == .multiClearPlacement)
    }

    @Test
    func openingReliefPreviewEmphasisOnlyArmsForOpeningValidPlacementsWithMeaningfulBoardContact() {
        let placement = [HexCoordinate(2, 2), HexCoordinate(3, 2)]
        let occupied = Set([HexCoordinate(2, 1), HexCoordinate(3, 1)])

        #expect(GameScene.openingReliefContactScore(placementCoordinates: placement, occupiedCoordinates: occupied) == 2)
        #expect(GameScene.shouldEmphasizeOpeningReliefPlacement(
            isOpeningState: true,
            previewProfile: .validPlacement,
            placementCoordinates: placement,
            occupiedCoordinates: occupied
        ))
        #expect(!GameScene.shouldEmphasizeOpeningReliefPlacement(
            isOpeningState: false,
            previewProfile: .validPlacement,
            placementCoordinates: placement,
            occupiedCoordinates: occupied
        ))
        #expect(!GameScene.shouldEmphasizeOpeningReliefPlacement(
            isOpeningState: true,
            previewProfile: .clearPlacement,
            placementCoordinates: placement,
            occupiedCoordinates: occupied
        ))
        #expect(!GameScene.shouldEmphasizeOpeningReliefPlacement(
            isOpeningState: true,
            previewProfile: .validPlacement,
            placementCoordinates: [HexCoordinate(0, 0)],
            occupiedCoordinates: Set([HexCoordinate(0, 1)])
        ))
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

private func makeDefaults() -> (UserDefaults, String) {
    let suiteName = "CriticalPathRegressionTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName) ?? .standard
    defaults.removePersistentDomain(forName: suiteName)
    return (defaults, suiteName)
}

private func clear(_ suiteName: String) {
    UserDefaults.standard.removePersistentDomain(forName: suiteName)
}
