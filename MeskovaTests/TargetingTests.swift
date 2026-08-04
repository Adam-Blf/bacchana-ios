import XCTest
@testable import MeskovaCore

final class TargetingTests: XCTestCase {
    /// Deterministic rng that always picks the first candidate (never shuffles).
    private let noShuffle: Targeting.Rng = { 0 }

    private func makePlayers() -> [Player] {
        let alice = Player(name: "Alice", gender: .feminine, relationship: .single)
        let bob = Player(name: "Bob", gender: .masculine, relationship: .couple)
        let chris = Player(name: "Chris", gender: .other)
        let dana = Player(name: "Dana", gender: .feminine, relationship: .couple)
        return [alice, bob, chris, dana]
    }

    func testIsResolvableRecognizesResolvableTargets() {
        XCTAssertTrue(Targeting.isResolvable(.genderMasculine))
        XCTAssertTrue(Targeting.isResolvable(.genderFeminine))
        XCTAssertTrue(Targeting.isResolvable(.pair))
        XCTAssertTrue(Targeting.isResolvable(.single))
        XCTAssertTrue(Targeting.isResolvable(.couple))
    }

    func testIsResolvableRejectsTargetsOutsideItsScope() {
        XCTAssertFalse(Targeting.isResolvable(.selfTarget))
        XCTAssertFalse(Targeting.isResolvable(.chosen))
        XCTAssertFalse(Targeting.isResolvable(.all))
        XCTAssertFalse(Targeting.isResolvable(nil))
    }

    func testResolvesGenderMasculineToMatchingPlayer() {
        let result = Targeting.resolve(players: makePlayers(), target: .genderMasculine, rng: noShuffle)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.gender, .masculine)
    }

    func testResolvesGenderFeminineToMatchingPlayer() {
        let result = Targeting.resolve(players: makePlayers(), target: .genderFeminine, rng: noShuffle)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.gender, .feminine)
    }

    func testResolvesSingleToMatchingPlayer() {
        let result = Targeting.resolve(players: makePlayers(), target: .single, rng: noShuffle)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.relationship, .single)
    }

    func testResolvesCoupleToMatchingPlayer() {
        let result = Targeting.resolve(players: makePlayers(), target: .couple, rng: noShuffle)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.relationship, .couple)
    }

    func testResolvesPairToTwoDistinctPlayers() {
        let result = Targeting.resolve(players: makePlayers(), target: .pair, rng: noShuffle)
        XCTAssertEqual(result.count, 2)
        XCTAssertNotEqual(result[0].id, result[1].id)
    }

    func testFallsBackToRandomActivePlayerWhenNobodyMatches() {
        let players = [Player(name: "X"), Player(name: "Y")]
        let result = Targeting.resolve(players: players, target: .genderMasculine, rng: noShuffle)
        XCTAssertEqual(result.count, 1)
        XCTAssertTrue(["X", "Y"].contains(result.first?.name))
    }

    func testFallsBackGracefullyForASinglePlayerWithNoMatchingAttribute() {
        let solo = [Player(name: "Zoé")]
        let result = Targeting.resolve(players: solo, target: .couple, rng: noShuffle)
        XCTAssertEqual(result.map(\.name), ["Zoé"])
    }

    func testIgnoresInactivePlayers() {
        let alice = Player(name: "Alice", gender: .feminine)
        alice.active = false
        let bob = Player(name: "Bob", gender: .masculine)
        let result = Targeting.resolve(players: [alice, bob], target: .genderFeminine, rng: noShuffle)
        XCTAssertEqual(result.map(\.name), ["Bob"])
    }

    func testRespectsTheInjectedRngDeterministically() {
        let players = makePlayers()
        let always1: Targeting.Rng = { 0.999 }
        let a = Targeting.resolve(players: players, target: .pair, rng: always1)
        let b = Targeting.resolve(players: players, target: .pair, rng: always1)
        XCTAssertEqual(a.map(\.id), b.map(\.id))
    }

    func testReturnsAnEmptyListWhenThereAreNoPlayersAtAll() {
        XCTAssertEqual(Targeting.resolve(players: [], target: .pair, rng: noShuffle), [])
    }

    func testResolvesTheSameTargetAcrossCallsWithTheSameSeededRng() {
        let players = makePlayers()
        let rngA = Targeting.seededRng("item-3-turn-5")
        let rngB = Targeting.seededRng("item-3-turn-5")
        let a = Targeting.resolve(players: players, target: .pair, rng: rngA)
        let b = Targeting.resolve(players: players, target: .pair, rng: rngB)
        XCTAssertEqual(a.map(\.id), b.map(\.id))
    }

    func testCanResolveDifferentlyForADifferentSeed() {
        let players = makePlayers()
        let seeds = ["a-1", "b-2", "c-3", "d-4", "e-5", "f-6"]
        let results = seeds.map { seed in
            Targeting.resolve(players: players, target: .genderFeminine, rng: Targeting.seededRng(seed)).first?.id
        }
        XCTAssertGreaterThan(Set(results).count, 1)
    }

    func testSeededRngProducesNumbersInZeroToOne() {
        let rng = Targeting.seededRng("some-seed")
        for _ in 0..<20 {
            let value = rng()
            XCTAssertGreaterThanOrEqual(value, 0)
            XCTAssertLessThan(value, 1)
        }
    }
}
