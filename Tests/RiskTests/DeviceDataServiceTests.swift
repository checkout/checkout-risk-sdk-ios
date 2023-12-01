//
//  DeviceDataServiceTests.swift
//  RiskTests
//  Tests
//
//  Created by Precious Ossai on 31/10/2023.
//

import Foundation
import XCTest
@testable import Risk

class DeviceDataServiceTests: XCTestCase {
    func testGetConfiguration() {
        let mockAPIService = MockAPIService()

        let config = RiskConfig(publicKey: "pk_qa_7wzteoyh4nctbkbvghw7eoimiyo", environment: .qa)
        let internalConfig = RiskSDKInternalConfig(config: config)
        let mockLogger = MockLoggerService(internalConfig: internalConfig)
        let deviceDataService = DeviceDataService(config: internalConfig, apiService: mockAPIService, loggerService: mockLogger)

        let expectation = self.expectation(description: "Configuration received")

        let expectedConfiguration = DeviceDataConfiguration(fingerprintIntegration: FingerprintIntegration(enabled: true, publicKey: "mockPublicKey"))

        mockAPIService.expectedResult = .success(expectedConfiguration)

        deviceDataService.getConfiguration { configuration in
            XCTAssertEqual(configuration, .success(expectedConfiguration))
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testPersistFpData() {
        let mockAPIService = MockAPIService()

        let config = RiskConfig(publicKey: "pk_qa_7wzteoyh4nctbkbvghw7eoimiyo", environment: RiskEnvironment.qa)
        let internalConfig = RiskSDKInternalConfig(config: config)
        let mockLogger = MockLoggerService(internalConfig: internalConfig)

        let deviceDataService = DeviceDataService(config: internalConfig, apiService: mockAPIService, loggerService: mockLogger)

        let expectation = self.expectation(description: "Data sent")

        let expectedResponse = PersistDeviceDataResponse(deviceSessionID: "abc")

        mockAPIService.expectedDeviceDataResult = .success(expectedResponse)

        deviceDataService.persistFpData(fingerprintRequestID: "12345.ab0cd", cardToken: "") { result in
            XCTAssertEqual(result, .success(expectedResponse))

            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }
}
