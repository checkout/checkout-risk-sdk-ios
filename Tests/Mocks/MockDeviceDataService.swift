//
//  MockDeviceDataService.swift
//  
//
//  Created by Precious Ossai on 10/12/2023.
//

import Foundation
@testable import Risk

class MockDeviceDataService: DeviceDataServiceProtocol {
    var shouldReturnConfiguration: Bool = true
    var shouldSucceedPersistFpData: Bool = true

    func getConfiguration(completion: @escaping (Result<FingerprintConfiguration, RiskError.Configuration>) -> Void) {
        if shouldReturnConfiguration {
            let configuration = FingerprintConfiguration(publicKey: "mocked_public_key")
            completion(.success(configuration))
        } else {
            completion(.failure(.couldNotRetrieveConfiguration))
        }
    }
    
    func persistFpData(fingerprintRequestId: String, fpLoadTime: Double, fpPublishTime: Double, cardToken: String?, completion: @escaping (Result<PersistDeviceDataResponse, RiskError.Publish>) -> Void) {
        if shouldSucceedPersistFpData {
            let response = PersistDeviceDataResponse(deviceSessionId: "mocked_device_session_id")
            completion(.success(response))
        } else {
            completion(.failure(.couldNotPersisRiskData))
        }
    }
}
