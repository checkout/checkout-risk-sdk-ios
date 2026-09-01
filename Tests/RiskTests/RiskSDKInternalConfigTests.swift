//
//  RiskSDKInternalConfigTests.swift
//  RiskTests
//  Tests
//

import Foundation
import XCTest
@testable import RiskSDK

class RiskSDKInternalConfigTests: XCTestCase {
    func testUsesSharedDeviceDataEndpointWhenNoMssdIsProvided() {
        XCTAssertEqual(endpointFor(environment: .qa, mssd: nil), "https://prism-qa.ckotech.co/collect")
        XCTAssertEqual(endpointFor(environment: .sandbox, mssd: nil), "https://risk.sandbox.checkout.com/collect")
        XCTAssertEqual(endpointFor(environment: .production, mssd: nil), "https://risk.checkout.com/collect")
    }

    func testUsesMerchantSpecificDeviceDataEndpointWhenMssdIsProvided() {
        XCTAssertEqual(endpointFor(environment: .qa, mssd: "merchant"), "https://merchant.devices-egw.cko-qa.ckotech.co")
        XCTAssertEqual(endpointFor(environment: .sandbox, mssd: "merchant"), "https://merchant.devices.api.sandbox.checkout.com")
        XCTAssertEqual(endpointFor(environment: .production, mssd: "merchant"), "https://merchant.devices.api.checkout.com")
    }

    func testTreatsBlankMssdAsAbsent() {
        XCTAssertEqual(endpointFor(environment: .production, mssd: "  "), "https://risk.checkout.com/collect")
    }

    private func endpointFor(environment: RiskEnvironment, mssd: String?) -> String {
        let config = RiskConfig(publicKey: "pk_test_xxx", environment: environment, mssd: mssd)

        return RiskSDKInternalConfig(config: config).deviceDataEndpoint
    }
}
