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
        let mssd="12345678"

        let config = RiskConfig(publicKey: publicKey, mssd: mssd, environment: .qa)
        let internalConfig = RiskSDKInternalConfig(config: config)
        let mockLogger = MockLoggerService(internalConfig: internalConfig)
        let deviceDataService = DeviceDataService(config: internalConfig, apiService: mockAPIService, loggerService: mockLogger)

        let expectation = self.expectation(description: "Configuration received")

        let expectedApiConfiguration = DeviceDataConfiguration(dataCollectors: ["fingerprint", "simple"], publicKey: "mockPublicKey", simple: nil)

        mockAPIService.expectedResult = .success(expectedApiConfiguration)

        deviceDataService.getConfiguration { configuration in
            switch configuration {
            case .success(let result):
                XCTAssertEqual(result.fingerprintPublicKey, "mockPublicKey")
                XCTAssertTrue(result.proEnabled)
                XCTAssertTrue(result.simpleEnabled)
            case .failure:
                XCTFail("Expected a successful configuration")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testGetConfigurationDisabledWhenNoCollectors() {
        let mockAPIService = MockAPIService()
        let config = RiskConfig(publicKey: "mocked_public_key", mssd: "12345678", environment: .qa)
        let internalConfig = RiskSDKInternalConfig(config: config)
        let mockLogger = MockLoggerService(internalConfig: internalConfig)
        let deviceDataService = DeviceDataService(config: internalConfig, apiService: mockAPIService, loggerService: mockLogger)

        let expectation = self.expectation(description: "Configuration disabled")

        mockAPIService.expectedResult = .success(DeviceDataConfiguration(dataCollectors: [], publicKey: nil, simple: nil))

        deviceDataService.getConfiguration { configuration in
            switch configuration {
            case .success:
                XCTFail("Expected integration to be disabled")
            case .failure(let error):
                XCTAssertEqual(error, .integrationDisabled)
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testDecodeConfigurationJSON() throws {
        let json = """
        {
          "data_collectors": ["simple", "fingerprint"],
          "public_key": "pk_test_key",
          "simple": {
            "drop_field_paths": ["procCpuInfoV2", "canvas.value.text"],
            "timeout_ms": 1000
          }
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let configuration = try decoder.decode(DeviceDataConfiguration.self, from: json)

        XCTAssertEqual(configuration.dataCollectors, ["simple", "fingerprint"])
        XCTAssertEqual(configuration.publicKey, "pk_test_key")
        XCTAssertEqual(configuration.simple?.dropFieldPaths, ["procCpuInfoV2", "canvas.value.text"])
        XCTAssertEqual(configuration.simple?.timeoutMs, 1000)
    }

    func testDecodeConfigurationJSONLeavesSimpleNilWhenAbsent() throws {
        let json = """
        {
          "data_collectors": ["fingerprint"],
          "public_key": "pk_test_key"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let configuration = try decoder.decode(DeviceDataConfiguration.self, from: json)

        XCTAssertNil(configuration.simple)
        XCTAssertEqual(configuration.dataCollectors, ["fingerprint"])
    }

    func testPersistFpData() {
        let mockAPIService = MockAPIService()
        let publicKey="mocked_public_key"
        let mssd="12345678"

        let config = RiskConfig(publicKey: publicKey, mssd: mssd, environment: RiskEnvironment.qa)
        let internalConfig = RiskSDKInternalConfig(config: config)
        let mockLogger = MockLoggerService(internalConfig: internalConfig)

        let deviceDataService = DeviceDataService(config: internalConfig, apiService: mockAPIService, loggerService: mockLogger)

        let expectation = self.expectation(description: "Data sent")

        let expectedResponse = PersistDeviceDataResponse(deviceSessionId: "abc")

        mockAPIService.expectedDeviceDataResult = .success(expectedResponse)

        let collectors = [
            CollectorData(collector: "fingerprint", sealedResult: nil),
            CollectorData(collector: "simple", sealedResult: "c2VhbGVkX29z")
        ]

        deviceDataService.persistFpData(fingerprintRequestId: "12345.ab0cd", fpLoadTime: 123.00, fpPublishTime: 321.00, cardToken: "", collectors: collectors, deviceCollectorProviders: ["fingerprint", "simple"]) { result in
            XCTAssertEqual(result, .success(expectedResponse))

            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }
}
