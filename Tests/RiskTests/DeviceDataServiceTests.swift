//
//  DeviceDataServiceTests.swift
//  RiskTests
//  Tests
//
//  Created by Precious Ossai on 31/10/2023.
//

import Foundation
import XCTest
@testable import RiskSDK

class DeviceDataServiceTests: XCTestCase {
    func testGetConfiguration() {
        let mockAPIService = MockAPIService()
        let publicKey="mocked_public_key"

        let config = RiskConfig(publicKey: publicKey, environment: .qa)
        let internalConfig = RiskSDKInternalConfig(config: config)
        let mockLogger = MockLoggerService(internalConfig: internalConfig)
        let deviceDataService = DeviceDataService(config: internalConfig, apiService: mockAPIService, loggerService: mockLogger)

        let expectation = self.expectation(description: "Configuration received")

        let expectedApiConfiguration = DeviceDataConfiguration(fingerprintIntegration: FingerprintIntegration(enabled: true, publicKey: "mockPublicKey"))
        let expectedDeviceDataServiceConfiguration = FingerprintConfiguration(publicKey: "mockPublicKey", blockTime: 123.00)

        mockAPIService.expectedResult = .success(expectedApiConfiguration)

        deviceDataService.getConfiguration { configuration in
            switch configuration {
            case .success(let result):
                XCTAssertEqual(result.publicKey, expectedDeviceDataServiceConfiguration.publicKey)
            case .failure:
                return
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testPersistFpData() {
        let mockAPIService = MockAPIService()
        let publicKey="mocked_public_key"

        let config = RiskConfig(publicKey: publicKey, environment: RiskEnvironment.qa)
        let internalConfig = RiskSDKInternalConfig(config: config)
        let mockLogger = MockLoggerService(internalConfig: internalConfig)

        let deviceDataService = DeviceDataService(config: internalConfig, apiService: mockAPIService, loggerService: mockLogger)

        let expectation = self.expectation(description: "Data sent")

        let expectedResponse = PersistDeviceDataResponse(deviceSessionId: "abc")

        mockAPIService.expectedDeviceDataResult = .success(expectedResponse)

        deviceDataService.persistFpData(fingerprintRequestId: "12345.ab0cd", fpLoadTime: 123.00, fpPublishTime: 321.00, cardToken: "") { result in
            XCTAssertEqual(result, .success(expectedResponse))

            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }
}
