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

        let config = RiskConfig(publicKey: publicKey, environment: .qa, mssd: mssd)
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
        let config = RiskConfig(publicKey: "mocked_public_key", environment: .qa, mssd: "12345678")
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

        let config = RiskConfig(publicKey: publicKey, environment: RiskEnvironment.qa, mssd: mssd)
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

    /// The endpoint paths are otherwise untestable: a typo in either breaks every device session
    /// in production and nothing would fail. Asserted on the path only, so query parameters
    /// (`riskSdkVersion`, `timezone`, …) can change without churning this test.
    func testGetConfigurationCallsTheConfigurationsEndpoint() {
        let mockAPIService = MockAPIService()
        let config = RiskConfig(publicKey: "mocked_public_key", environment: .qa, mssd: "12345678")
        let internalConfig = RiskSDKInternalConfig(config: config)
        let deviceDataService = DeviceDataService(config: internalConfig, apiService: mockAPIService, loggerService: MockLoggerService(internalConfig: internalConfig))

        mockAPIService.expectedResult = .success(DeviceDataConfiguration(dataCollectors: ["simple"], publicKey: nil, simple: nil))

        let expectation = self.expectation(description: "Configuration requested")
        deviceDataService.getConfiguration { _ in expectation.fulfill() }
        waitForExpectations(timeout: 5, handler: nil)

        let endpoint = mockAPIService.lastGetEndpoint
        XCTAssertNotNil(endpoint)
        XCTAssertTrue(
            endpoint?.hasPrefix("\(internalConfig.deviceDataEndpoint)/collect/configurations?") ?? false,
            "Unexpected configurations endpoint: \(endpoint ?? "nil")"
        )
    }

    func testPersistFpDataCallsTheFingerprintV2Endpoint() throws {
        let mockAPIService = MockAPIService()
        let config = RiskConfig(publicKey: "mocked_public_key", environment: .qa, mssd: "12345678")
        let internalConfig = RiskSDKInternalConfig(config: config)
        let deviceDataService = DeviceDataService(config: internalConfig, apiService: mockAPIService, loggerService: MockLoggerService(internalConfig: internalConfig))

        mockAPIService.expectedDeviceDataResult = .success(PersistDeviceDataResponse(deviceSessionId: "abc"))

        let expectation = self.expectation(description: "Data sent")
        deviceDataService.persistFpData(
            fingerprintRequestId: "12345.ab0cd", fpLoadTime: 0, fpPublishTime: 0,
            cardToken: nil, collectors: [], deviceCollectorProviders: []
        ) { _ in
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)

        let endpoint = mockAPIService.lastPutEndpoint
        XCTAssertNotNil(endpoint)
        XCTAssertTrue(
            endpoint?.hasPrefix("\(internalConfig.deviceDataEndpoint)/collect/fingerprint/v2?") ?? false,
            "Unexpected persist endpoint: \(endpoint ?? "nil")"
        )
    }

    /// Locks the on-the-wire shape the backend reads: snake_cased `fp_request_id` at the root and
    /// a `collectors` array whose `simple` entry carries the base64 `sealed_result` while the PRO
    /// entry omits it (its identifier travels in the root request id instead).
    func testPersistFpDataEncodesTheCollectorsWireShape() throws {
        let mockAPIService = MockAPIService()
        let config = RiskConfig(publicKey: "mocked_public_key", environment: .qa, mssd: "12345678")
        let internalConfig = RiskSDKInternalConfig(config: config)
        let deviceDataService = DeviceDataService(config: internalConfig, apiService: mockAPIService, loggerService: MockLoggerService(internalConfig: internalConfig))

        mockAPIService.expectedDeviceDataResult = .success(PersistDeviceDataResponse(deviceSessionId: "abc"))

        let collectors = [
            CollectorData(collector: "fingerprint", sealedResult: nil),
            CollectorData(collector: "simple", sealedResult: "c2VhbGVkX29z")
        ]

        let expectation = self.expectation(description: "Data sent")
        deviceDataService.persistFpData(
            fingerprintRequestId: "12345.ab0cd", fpLoadTime: 0, fpPublishTime: 0,
            cardToken: "card_token", collectors: collectors,
            deviceCollectorProviders: ["fingerprint", "simple"]
        ) { _ in
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)

        let body = try XCTUnwrap(mockAPIService.lastPutBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertEqual(json["fp_request_id"] as? String, "12345.ab0cd")
        XCTAssertEqual(json["card_token"] as? String, "card_token")

        let encodedCollectors = try XCTUnwrap(json["collectors"] as? [[String: Any]])
        XCTAssertEqual(encodedCollectors.count, 2)

        let pro = encodedCollectors.first { $0["collector"] as? String == "fingerprint" }
        XCTAssertNotNil(pro)
        XCTAssertNil(pro?["sealed_result"])

        let simple = encodedCollectors.first { $0["collector"] as? String == "simple" }
        XCTAssertEqual(simple?["sealed_result"] as? String, "c2VhbGVkX29z")
    }
}
