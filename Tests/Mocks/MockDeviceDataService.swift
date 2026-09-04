//
//  MockDeviceDataService.swift
//
//
//  Created by Precious Ossai on 10/12/2023.
//

import Foundation
@testable import RiskSDK

class MockDeviceDataService: DeviceDataServiceProtocol {
    var shouldReturnConfiguration: Bool = true
    var shouldSucceedPersistFpData: Bool = true
    var persistFpDataCallCount: Int = 0
    var lastCollectors: [CollectorData] = []
    var lastDeviceCollectorProviders: [String] = []
    var lastFingerprintRequestId: String?

    /// The configuration handed back on each `getConfiguration`. Overridable so tests can drive
    /// either collector enabled or disabled, and can change it between successive `configure()`
    /// calls on one `Risk` instance.
    var configuration = DeviceDataConfig(
        fingerprintPublicKey: "mocked_public_key",
        simpleConfig: nil,
        proEnabled: true,
        simpleEnabled: false,
        blockTime: 123.00
    )

    func getConfiguration(completion: @escaping (Result<DeviceDataConfig, RiskError.Configuration>) -> Void) {
        if shouldReturnConfiguration {
            completion(.success(configuration))
        } else {
            completion(.failure(.couldNotRetrieveConfiguration))
        }
    }

    func persistFpData(fingerprintRequestId: String, fpLoadTime: Double, fpPublishTime: Double, cardToken: String?, collectors: [CollectorData], deviceCollectorProviders: [String], completion: @escaping (Result<PersistDeviceDataResponse, RiskError.Publish>) -> Void) {
        persistFpDataCallCount += 1
        lastCollectors = collectors
        lastDeviceCollectorProviders = deviceCollectorProviders
        lastFingerprintRequestId = fingerprintRequestId
        if shouldSucceedPersistFpData {
            let response = PersistDeviceDataResponse(deviceSessionId: "mocked_device_session_id")
            completion(.success(response))
        } else {
            completion(.failure(.couldNotPersisRiskData))
        }
    }
}
