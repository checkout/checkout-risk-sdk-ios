//
//  ResolveRequestIdTests.swift
//  RiskTests
//  Tests
//
//  Unit tests for the root fp_request_id resolution.
//

import Foundation
import XCTest
@testable import RiskSDK

class ResolveRequestIdTests: XCTestCase {

    func testPrefersProRequestIdWhenPresent() {
        XCTAssertEqual(resolveRequestId(proRequestId: "pro-id", simpleRequestId: "os-id"), "pro-id")
        XCTAssertEqual(resolveRequestId(proRequestId: "pro-id", simpleRequestId: nil), "pro-id")
    }

    func testFallsBackToSimpleRequestIdWhenProAbsent() {
        XCTAssertEqual(resolveRequestId(proRequestId: nil, simpleRequestId: "os-id"), "os-id")
    }

    func testGeneratesFreshIdWhenNeitherCollectorProvidedOne() {
        let id = resolveRequestId(proRequestId: nil, simpleRequestId: nil)

        XCTAssertFalse(id.isEmpty)
        // A second call must not reuse the first — a new id is generated each time.
        XCTAssertNotEqual(id, resolveRequestId(proRequestId: nil, simpleRequestId: nil))
    }
}
