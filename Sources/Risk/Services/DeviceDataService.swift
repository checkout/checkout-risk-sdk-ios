//
//  DeviceDataService.swift
//  Risk
//  Sources
//
//  Created by Precious Ossai on 30/10/2023.
//

import Foundation

struct FingerprintIntegration: Decodable, Equatable {
    let enabled: Bool
    let publicKey: String?
}

struct FingerprintConfiguration: Equatable {
    let publicKey: String
}

struct DeviceDataConfiguration: Decodable, Equatable {
    let fingerprintIntegration: FingerprintIntegration
}

struct PersistDeviceDataServiceData: Codable, Equatable {
    
    private enum CodingKeys: String, CodingKey {
        case integrationType, fingerprintRequestId = "fpRequestId", cardToken
    }
    
    let integrationType: RiskIntegrationType
    let fingerprintRequestId: String
    let cardToken: String?
}

struct PersistDeviceDataResponse: Decodable, Equatable {
    let deviceSessionId: String
    
    private enum CodingKeys: String, CodingKey {
        case deviceSessionId = "deviceSessionId"
    }
}

protocol DeviceDataServiceProtocol {
    func getConfiguration(completion: @escaping (Result<FingerprintConfiguration, RiskError.Configuration>) -> Void)
    func persistFpData(fingerprintRequestId: String, cardToken: String?, completion: @escaping (Result<PersistDeviceDataResponse, RiskError.Publish>) -> Void)
}

struct DeviceDataService: DeviceDataServiceProtocol {
    let config: RiskSDKInternalConfig
    let apiService: APIServiceProtocol
    let loggerService: LoggerServiceProtocol
    
    init(config: RiskSDKInternalConfig, apiService: APIServiceProtocol = APIService(), loggerService: LoggerServiceProtocol) {
        self.config = config
        self.apiService = apiService
        self.loggerService = loggerService
    }
    
    func getConfiguration(completion: @escaping (Result<FingerprintConfiguration, RiskError.Configuration>) -> Void) {
        let endpoint = "\(config.deviceDataEndpoint)/configuration?integrationType=\(config.integrationType.rawValue)&riskSdkVersion=\(Constants.riskSdkVersion)&timezone=\(TimeZone.current.identifier)"
        let authToken = config.merchantPublicKey
        
        apiService.getJSONFromAPIWithAuthorization(endpoint: endpoint, authToken: authToken, responseType: DeviceDataConfiguration.self) {
            result in
            switch result {
            case .success(let configuration):
                
                guard configuration.fingerprintIntegration.enabled, let fingerprintPublicKey = configuration.fingerprintIntegration.publicKey else {
                    loggerService.log(riskEvent: .publishDisabled, deviceSessionId: nil, requestId: nil, error: RiskLogError(reason: "getConfiguration", message: RiskError.Configuration.integrationDisabled.localizedDescription, status: nil, type: "Error"))
                    
                    return completion(.failure(.integrationDisabled))
                }
                
                completion(.success(
                    FingerprintConfiguration.init(publicKey: fingerprintPublicKey)))
            case .failure(let error):
                
                loggerService.log(riskEvent: .loadFailure, deviceSessionId: nil, requestId: nil, error: RiskLogError(reason: "getConfiguration", message: error.localizedDescription, status: nil, type: "Error"))
                return completion(.failure(.couldNotRetrieveConfiguration))
            }
        }
    }
    
    func persistFpData(fingerprintRequestId: String, cardToken: String?, completion: @escaping (Result<PersistDeviceDataResponse, RiskError.Publish>) -> Void) {
        let endpoint = "\(config.deviceDataEndpoint)/fingerprint?riskSdkVersion=\(Constants.riskSdkVersion)"
        let authToken = config.merchantPublicKey
        let integrationType = config.integrationType
        
        let data = PersistDeviceDataServiceData(
            integrationType: integrationType,
            fingerprintRequestId: fingerprintRequestId,
            cardToken: cardToken
        )
        
        apiService.putDataToAPIWithAuthorization(endpoint: endpoint, authToken: authToken, data: data, responseType: PersistDeviceDataResponse.self) { result in
            
            switch result {
            case .success(let response):
                loggerService.log(riskEvent: .published, deviceSessionId: response.deviceSessionId, requestId: fingerprintRequestId, error: nil)
                
                completion(.success(response))
            case .failure(let error):
                loggerService.log(riskEvent: .publishFailure, deviceSessionId: nil, requestId: nil, error: RiskLogError(reason: "persistFpData", message: error.localizedDescription, status: nil, type: "Error"))
                
                completion(.failure(.couldNotPersisRiskData))
            }
        }
    }
    
}
