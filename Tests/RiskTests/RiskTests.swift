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
        
        let invalidConfig = RiskConfig(publicKey: "invalid_public_key", mssd: "12345678", environment: RiskEnvironment.qa)
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

    private func verifyFingerprintTimeout(shouldTimeout: Bool, fingerprintTimeoutInterval: TimeInterval, delayTime: TimeInterval, file: StaticString = #file, line: UInt = #line) {
        
            let expectation = self.expectation(description: "Risk data timed out")
            
            let publicKey = "dummy_key"
            let validConfig = RiskConfig(publicKey: publicKey, mssd: "12345678", environment: RiskEnvironment.qa)
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
