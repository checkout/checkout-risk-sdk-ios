//
//  RiskTests.swift
//  RiskTests
//  Tests
//
//  Created by Precious Ossai on 31/10/2023.
//

import XCTest
@testable import Risk

class RiskTests: XCTestCase {
    
//    func testGetInstanceWithValidConfiguration() {
//        let expectation = self.expectation(description: "Risk instance creation")
//        
//        // TODO: Update CI to pass environment variable
//        //          guard let publicKey = ProcessInfo.processInfo.environment["SAMPLE_MERCHANT_PUBLIC_KEY"] else {
//        //              XCTFail("Environment variable SAMPLE_MERCHANT_PUBLIC_KEY is not set.")
//        //              return
//        //          }
//        let publicKey = "dummy_key"
//        let validConfig = RiskConfig(publicKey: publicKey, environment: RiskEnvironment.qa)
//        let riskSDK = Risk(config: validConfig)
//        
//        riskSDK.configure { [weak self] result in
//            guard let _ = self else { return }
//            
//            switch result {
//            case .success:
//                riskSDK.publishData { result in
//                    switch result {
//                    case .success(let response):
//                        XCTAssertNotNil(response.deviceSessionId)
//                        expectation.fulfill()
//                    case .failure:
//                        XCTFail("Risk data published failed")
//                        expectation.fulfill()
//                    }
//                }
//            case .failure(let error):
//                XCTFail("Failed to configure Risk SDK with valid configuration: \(error)")
//            }
//        }
//        
//        waitForExpectations(timeout: 5, handler: nil)
//        XCTAssertNotNil(riskSDK)
//    }
    
    func testGetInstanceWithInvalidPublicKey() {
        let expectation = self.expectation(description: "Risk instance creation with invalid public key")
        
        let invalidConfig = RiskConfig(publicKey: "invalid_public_key", environment: RiskEnvironment.qa)
        let riskSDK = Risk(config: invalidConfig)
        riskSDK.configure { error in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    //    func testPublishTimeout() {
    //        let expectation = self.expectation(description: "Risk data timed out")
    //
    //    let publicKey = "dummy_key"
    //        let validConfig = RiskConfig(publicKey: publicKey, environment: RiskEnvironment.qa)
    //
    //
    //
    //        let riskSDK = Risk(config: validConfig)
    //
    //        riskSDK.fingerprintTimeoutInterval = 0.01
    //
    //        riskSDK.configure { [weak self] result in
    //            guard let _ = self else { return }
    //
    //            switch result {
    //            case .success:
    //                let stubFingerprintService = MockFingerprintService()
    //                stubFingerprintService.delayTime = 0.1
    //
    //                riskSDK.fingerprintService = stubFingerprintService
    //
    //                riskSDK.publishData { result in
    //                    switch result {
    //                    case .success:
    //                        XCTFail("Risk data published without timeout")
    //                        expectation.fulfill()
    //                    case .failure(let error):
    //                        XCTAssertEqual(error, .fingerprintTimeout)
    //                        expectation.fulfill()
    //                    }
    //                }
    //            case .failure(let error):
    //                XCTFail("Failed to configure Risk SDK with valid configuration: \(error)")
    //            }
    //        }
    //
    //        waitForExpectations(timeout: 5, handler: nil)
    //    }
    
    
    
    func testPublishTimeout() {
        verifyFingerprintTimeout(shouldTimeout: true, fingerprintTimeoutInterval: 0.01, delayTime: 0.1)
    }
    
    func testPublishDoesNotTimeoutWhenCompletedInTime() {
        verifyFingerprintTimeout(shouldTimeout: false, fingerprintTimeoutInterval: 0.1, delayTime: 0.01)
    }
    
    func testPublishShouldTimeoutWhenCompletedInTheSameTime() {
        verifyFingerprintTimeout(shouldTimeout: true, fingerprintTimeoutInterval: 0.01, delayTime: 0.01)
    }
    
    private func verifyFingerprintTimeout(shouldTimeout: Bool, fingerprintTimeoutInterval: TimeInterval, delayTime: TimeInterval, file: StaticString = #file, line: UInt = #line) {
        
            let expectation = self.expectation(description: "Risk data timed out")
            
            let publicKey = "dummy_key"
            let validConfig = RiskConfig(publicKey: publicKey, environment: RiskEnvironment.qa)
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
