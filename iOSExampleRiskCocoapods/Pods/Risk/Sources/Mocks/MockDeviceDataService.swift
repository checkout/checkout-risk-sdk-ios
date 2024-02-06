//
//  MockDeviceDataService.swift
//  
//
//  Created by Precious Ossai on 10/12/2023.
//

import Foundation

class MockDeviceDataService: DeviceDataServiceProtocol {
    var shouldReturnConfiguration: Bool = true
    var shouldSucceedPersistFpData: Bool = true

    func getConfiguration(completion: @escaping (Result<DeviceDataConfiguration, RiskError>) -> Void) {
        if shouldReturnConfiguration {
            let configuration = DeviceDataConfiguration(fingerprintIntegration: FingerprintIntegration(enabled: true, publicKey: "mocked_public_key"))
            completion(.success(configuration))
        } else {
            completion(.failure(RiskError.description("Mocked configuration error")))
        }
    }

    func persistFpData(fingerprintRequestId: String, cardToken: String?, completion: @escaping (Result<PersistDeviceDataResponse, RiskError>) -> Void) {
        if shouldSucceedPersistFpData {
            let response = PersistDeviceDataResponse(deviceSessionId: "mocked_device_session_id")
            completion(.success(response))
        } else {
            completion(.failure(RiskError.description("Mocked persistFpData error")))
        }
    }
}
