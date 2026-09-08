//
//  SimpleServiceTests.swift
//  RiskTests
//  Tests
//
//  Threading contract for the open-source `simple` collector service.
//

import FingerprintJS
import Foundation
import QuartzCore
import XCTest
@testable import RiskSDK

class SimpleServiceTests: XCTestCase {

    private func makeService(timeoutMs: Int? = SimpleService.defaultTimeoutMs) -> SimpleService {
        SimpleService(
            dropFieldPaths: [],
            timeoutMs: timeoutMs,
            fingerprinter: FingerprinterFactory.getInstance(Configuration(version: .latest, stabilityLevel: .optimal))
        )
    }

    /// `Fingerprinter` gathers every signal and invokes its completion synchronously on the calling
    /// thread, so `publishData` must hop off it. Collection takes orders of magnitude longer than
    /// the dispatch itself, so a `publishData` that returns promptly with the completion still
    /// pending is one that is not doing the work inline.
    func testPublishDoesNotBlockTheCallingThread() {
        // Warm the fingerprinter up front — its construction opens CoreTelephony and
        // LocalAuthentication connections, which is slow and unrelated to what is measured here.
        let service = makeService()
        let expectation = self.expectation(description: "Simple collector published")
        var didComplete = false

        let start = CACurrentMediaTime()
        service.publishData { _ in
            didComplete = true
            expectation.fulfill()
        }
        let elapsed = (CACurrentMediaTime() - start) * 1000

        XCTAssertFalse(didComplete, "publishData invoked its completion synchronously on the caller")
        XCTAssertLessThan(elapsed, 500, "publishData blocked the caller for \(elapsed)ms")

        waitForExpectations(timeout: 10, handler: nil)
    }

    /// Both racing paths (collection and the timeout) must deliver on the same documented queue.
    func testPublishDeliversCompletionOnTheMainQueue() {
        let expectation = self.expectation(description: "Simple collector published")

        makeService(timeoutMs: 1).publishData { _ in
            XCTAssertTrue(Thread.isMainThread)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    /// With a 1ms budget both the timeout and collection complete well inside the wait, so a
    /// broken exactly-once guard shows up as an over-fulfilled expectation.
    func testPublishInvokesCompletionExactlyOnceWhenTimeoutRacesCollection() {
        let expectation = self.expectation(description: "Simple collector published once")
        expectation.assertForOverFulfill = true

        makeService(timeoutMs: 1).publishData { _ in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2, handler: nil)
        // Give the losing path time to call back a second time if the guard is broken.
        let settled = self.expectation(description: "Losing path settled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { settled.fulfill() }
        wait(for: [settled], timeout: 2)
    }

    /// Must stay in step with the Android SDK's `DEFAULT_TIMEOUT_MS`: one merchant with no
    /// `timeout_ms` in `configurations` has to behave identically on both platforms.
    func testDefaultTimeoutMatchesAndroid() {
        XCTAssertEqual(SimpleService.defaultTimeoutMs, 1000)
    }

    /// A missing or non-positive budget means "not configured", not "no limit" — collection runs
    /// on the payment path, so it is always bounded. Verified through observable behaviour: a
    /// budget so short that it always wins the race still produces a timely failure.
    func testAbsentBudgetFallsBackToTheDefaultRatherThanRunningUnbounded() {
        for timeoutMs in [nil, 0, -1] as [Int?] {
            let expectation = self.expectation(description: "Bounded for budget \(String(describing: timeoutMs))")

            makeService(timeoutMs: timeoutMs).publishData { _ in
                expectation.fulfill()
            }

            // Comfortably above `defaultTimeoutMs` but far below "unbounded".
            wait(for: [expectation], timeout: 5)
        }
    }
}
