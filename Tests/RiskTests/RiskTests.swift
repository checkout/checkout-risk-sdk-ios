//
//  RiskTests.swift
//  RiskTests
//  Tests
//
//  Created by Precious Ossai on 31/10/2023.
//

import XCTest
@testable import RiskSDK

class RiskTests: XCTestCase {

    func testGetInstanceWithInvalidPublicKey() {
        let expectation = self.expectation(description: "Risk instance creation with invalid public key")
        
        let invalidConfig = RiskConfig(publicKey: "invalid_public_key",  environment: RiskEnvironment.qa, mssd: "12345678")
        let riskSDK = Risk(config: invalidConfig)
        riskSDK.configure { error in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testPublishTimeout() {
        verifyFingerprintTimeout(shouldTimeout: true, fingerprintTimeoutInterval: 0.01, delayTime: 0.1)
    }
    
    func testPublishDoesNotTimeoutWhenCompletedInTime() {
        verifyFingerprintTimeout(shouldTimeout: false, fingerprintTimeoutInterval: 0.1, delayTime: 0.01)
    }
    
    func testPublishShouldTimeoutWhenCompletedInTheSameTime() {
        verifyFingerprintTimeout(shouldTimeout: true, fingerprintTimeoutInterval: 0.01, delayTime: 0.01)
    }
    
    func testPublishWithSimpleCollectorOnly() {
        let expectation = self.expectation(description: "Risk data published via simple collector")

        let config = RiskConfig(publicKey: "dummy_key", mssd: "12345678", environment: .qa)
        let riskSDK = Risk(config: config)

        let stubDeviceDataService = MockDeviceDataService()
        let stubSimpleService = MockSimpleService()
        riskSDK.deviceDataService = stubDeviceDataService
        riskSDK.simpleService = stubSimpleService

        riskSDK.publishData { result in
            switch result {
            case .success(let data):
                XCTAssertEqual(data.deviceSessionId, "mocked_device_session_id")
                XCTAssertEqual(stubDeviceDataService.lastCollectors.count, 1)
                XCTAssertEqual(stubDeviceDataService.lastCollectors.first?.collector, "simple")
                XCTAssertEqual(stubDeviceDataService.lastCollectors.first?.sealedResult, "mocked_sealed_result")
                XCTAssertEqual(stubDeviceDataService.lastDeviceCollectorProviders, ["simple"])
            case .failure(let error):
                XCTFail("Expected success, got \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testPublishWithBothCollectors() {
        let expectation = self.expectation(description: "Risk data published via both collectors")

        let config = RiskConfig(publicKey: "dummy_key", mssd: "12345678", environment: .qa)
        let riskSDK = Risk(config: config)

        let stubDeviceDataService = MockDeviceDataService()
        let stubFingerprintService = MockFingerprintService()
        stubFingerprintService.requestId = "pro_request_id"
        let stubSimpleService = MockSimpleService()
        riskSDK.deviceDataService = stubDeviceDataService
        riskSDK.fingerprintService = stubFingerprintService
        riskSDK.simpleService = stubSimpleService

        riskSDK.publishData { result in
            switch result {
            case .success:
                XCTAssertEqual(stubDeviceDataService.lastCollectors.count, 2)
                XCTAssertEqual(stubDeviceDataService.lastDeviceCollectorProviders, ["fingerprint", "simple"])
                let simple = stubDeviceDataService.lastCollectors.first { $0.collector == "simple" }
                XCTAssertEqual(simple?.sealedResult, "mocked_sealed_result")
                let pro = stubDeviceDataService.lastCollectors.first { $0.collector == "fingerprint" }
                XCTAssertNil(pro?.sealedResult)
            case .failure(let error):
                XCTFail("Expected success, got \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testPublishFailsWhenAllCollectorsFail() {
        let expectation = self.expectation(description: "Publish fails when every collector fails")

        let config = RiskConfig(publicKey: "dummy_key", mssd: "12345678", environment: .qa)
        let riskSDK = Risk(config: config)

        let stubDeviceDataService = MockDeviceDataService()
        let stubFingerprintService = MockFingerprintService()
        stubFingerprintService.shouldSucceed = false
        let stubSimpleService = MockSimpleService()
        stubSimpleService.shouldSucceed = false
        riskSDK.deviceDataService = stubDeviceDataService
        riskSDK.fingerprintService = stubFingerprintService
        riskSDK.simpleService = stubSimpleService

        riskSDK.publishData { result in
            switch result {
            case .success:
                XCTFail("Expected failure when all collectors fail")
            case .failure(let error):
                XCTAssertEqual(error, .couldNotPublishRiskData)
                XCTAssertEqual(stubDeviceDataService.persistFpDataCallCount, 0)
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    /// The headline claim of the multi-collector work: one collector failing must not stop the
    /// others publishing. Asserted in both directions, since the two collectors contribute
    /// differently to the payload (PRO via the root `fp_request_id`, simple via `sealed_result`).
    func testPublishSucceedsWhenOnlyTheProCollectorFails() {
        let expectation = self.expectation(description: "Publish succeeds on simple alone")

        let riskSDK = Risk(config: RiskConfig(publicKey: "dummy_key", mssd: "12345678", environment: .qa))
        let stubDeviceDataService = MockDeviceDataService()
        let stubFingerprintService = MockFingerprintService()
        stubFingerprintService.shouldSucceed = false
        let stubSimpleService = MockSimpleService()
        stubSimpleService.requestId = "simple_request_id"
        riskSDK.deviceDataService = stubDeviceDataService
        riskSDK.fingerprintService = stubFingerprintService
        riskSDK.simpleService = stubSimpleService

        riskSDK.publishData { result in
            switch result {
            case .success:
                XCTAssertEqual(stubDeviceDataService.lastDeviceCollectorProviders, ["simple"])
                XCTAssertEqual(stubDeviceDataService.lastCollectors.count, 1)
                XCTAssertEqual(stubDeviceDataService.lastCollectors.first?.sealedResult, "mocked_sealed_result")
                // With PRO absent the root id falls back to the simple collector's client id,
                // which is the one embedded in its sealed_result.
                XCTAssertEqual(stubDeviceDataService.lastFingerprintRequestId, "simple_request_id")
            case .failure(let error):
                XCTFail("Expected the simple collector to publish alone, got \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testPublishSucceedsWhenOnlyTheSimpleCollectorFails() {
        let expectation = self.expectation(description: "Publish succeeds on PRO alone")

        let riskSDK = Risk(config: RiskConfig(publicKey: "dummy_key", mssd: "12345678", environment: .qa))
        let stubDeviceDataService = MockDeviceDataService()
        let stubFingerprintService = MockFingerprintService()
        stubFingerprintService.requestId = "pro_request_id"
        let stubSimpleService = MockSimpleService()
        stubSimpleService.shouldSucceed = false
        riskSDK.deviceDataService = stubDeviceDataService
        riskSDK.fingerprintService = stubFingerprintService
        riskSDK.simpleService = stubSimpleService

        riskSDK.publishData { result in
            switch result {
            case .success:
                XCTAssertEqual(stubDeviceDataService.lastDeviceCollectorProviders, ["fingerprint"])
                XCTAssertEqual(stubDeviceDataService.lastCollectors.count, 1)
                XCTAssertNil(stubDeviceDataService.lastCollectors.first?.sealedResult)
                XCTAssertEqual(stubDeviceDataService.lastFingerprintRequestId, "pro_request_id")
            case .failure(let error):
                XCTFail("Expected the PRO collector to publish alone, got \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    /// `configure()` is documented as re-callable on a live instance, and the README advertises
    /// collectors being toggled server-side with no integration change. A collector the backend
    /// has since removed from `data_collectors` must therefore be torn down, not left running.
    func testReconfigureTearsDownCollectorsDisabledServerSide() {
        let riskSDK = Risk(config: RiskConfig(publicKey: "dummy_key", mssd: "12345678", environment: .qa))
        let stubDeviceDataService = MockDeviceDataService()
        riskSDK.deviceDataService = stubDeviceDataService

        stubDeviceDataService.configuration = DeviceDataConfig(
            fingerprintPublicKey: "mocked_public_key",
            simpleConfig: SimpleCollectorConfig(dropFieldPaths: [], timeoutMs: 1000),
            proEnabled: true,
            simpleEnabled: true,
            blockTime: 123.00
        )

        let firstConfigure = self.expectation(description: "First configure")
        riskSDK.configure { _ in firstConfigure.fulfill() }
        wait(for: [firstConfigure], timeout: 5)

        XCTAssertNotNil(riskSDK.fingerprintService)
        XCTAssertNotNil(riskSDK.simpleService)

        // The backend now serves neither collector for this merchant.
        stubDeviceDataService.configuration = DeviceDataConfig(
            fingerprintPublicKey: nil,
            simpleConfig: nil,
            proEnabled: false,
            simpleEnabled: false,
            blockTime: 123.00
        )

        let secondConfigure = self.expectation(description: "Second configure")
        riskSDK.configure { _ in secondConfigure.fulfill() }
        wait(for: [secondConfigure], timeout: 5)

        XCTAssertNil(riskSDK.fingerprintService, "PRO collector survived being disabled server-side")
        XCTAssertNil(riskSDK.simpleService, "Simple collector survived being disabled server-side")
    }

    /// The reverse direction: a collector newly enabled server-side is picked up, and the one
    /// dropped in the same response is cleared.
    func testReconfigureSwapsTheEnabledCollector() {
        let riskSDK = Risk(config: RiskConfig(publicKey: "dummy_key", mssd: "12345678", environment: .qa))
        let stubDeviceDataService = MockDeviceDataService()
        riskSDK.deviceDataService = stubDeviceDataService

        // Default mock configuration is PRO-only.
        let firstConfigure = self.expectation(description: "First configure")
        riskSDK.configure { _ in firstConfigure.fulfill() }
        wait(for: [firstConfigure], timeout: 5)

        XCTAssertNotNil(riskSDK.fingerprintService)
        XCTAssertNil(riskSDK.simpleService)

        stubDeviceDataService.configuration = DeviceDataConfig(
            fingerprintPublicKey: nil,
            simpleConfig: SimpleCollectorConfig(dropFieldPaths: [], timeoutMs: 1000),
            proEnabled: false,
            simpleEnabled: true,
            blockTime: 123.00
        )

        let secondConfigure = self.expectation(description: "Second configure")
        riskSDK.configure { _ in secondConfigure.fulfill() }
        wait(for: [secondConfigure], timeout: 5)

        XCTAssertNil(riskSDK.fingerprintService, "PRO collector survived being disabled server-side")
        XCTAssertNotNil(riskSDK.simpleService)
    }

    private func verifyFingerprintTimeout(shouldTimeout: Bool, fingerprintTimeoutInterval: TimeInterval, delayTime: TimeInterval, file: StaticString = #file, line: UInt = #line) {
        
            let expectation = self.expectation(description: "Risk data timed out")
            
            let publicKey = "dummy_key"
            let validConfig = RiskConfig(publicKey: publicKey, environment: RiskEnvironment.qa, mssd: "12345678")
            let riskSDK = Risk(config: validConfig)
            
            riskSDK.fingerprintTimeoutInterval = fingerprintTimeoutInterval
            let stubFingerprintService = MockFingerprintService()
            let stubDeviceDataService = MockDeviceDataService()
            stubFingerprintService.delayTime = delayTime
        
            
            riskSDK.fingerprintService = stubFingerprintService
            riskSDK.deviceDataService = stubDeviceDataService
            
            riskSDK.publishData { result in
                switch result {
                case .success:
                    if shouldTimeout {
                        XCTFail("Risk data published without timeout", file: file, line: line)
                    }
                    XCTAssertEqual(stubDeviceDataService.persistFpDataCallCount, shouldTimeout ? 0 : 1)
                    expectation.fulfill()
                case .failure(let error):
                    XCTAssertEqual(error, .fingerprintTimeout, file: file, line: line)
                    expectation.fulfill()
                }
            }
            
            waitForExpectations(timeout: 5, handler: nil)
    }
}
