//
//  DeviceDataService.swift
//  Risk
//  Sources
//
//  Created by Precious Ossai on 30/10/2023.
//

import Foundation
import QuartzCore

struct FingerprintIntegration: Decodable, Equatable {
    let enabled: Bool
    let publicKey: String?
}

struct FingerprintConfiguration: Equatable {
    let publicKey: String
    let blockTime: Double
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
    func persistFpData(fingerprintRequestId: String, fpLoadTime: Double, fpPublishTime: Double, cardToken: String?, completion: @escaping (Result<PersistDeviceDataResponse, RiskError.Publish>) -> Void)
}

final class DeviceDataService: DeviceDataServiceProtocol {
    let config: RiskSDKInternalConfig
    let apiService: APIServiceProtocol
    let loggerService: LoggerServiceProtocol
    var blockTime: Double
    
    init(config: RiskSDKInternalConfig, apiService: APIServiceProtocol = APIService(), loggerService: LoggerServiceProtocol) {
        self.config = config
        self.apiService = apiService
        self.loggerService = loggerService
        self.blockTime = 0.00
    }
    
    func getConfiguration(completion: @escaping (Result<FingerprintConfiguration, RiskError.Configuration>) -> Void) {
        let startBlockTime = CACurrentMediaTime()
        let endpoint = "\(config.deviceDataEndpoint)/configuration?integrationType=\(config.integrationType.rawValue)&riskSdkVersion=\(Constants.riskSdkVersion)&timezone=\(TimeZone.current.identifier)"
        let authToken = config.merchantPublicKey
        
        apiService.getJSONFromAPIWithAuthorization(endpoint: endpoint, authToken: authToken, responseType: DeviceDataConfiguration.self) {
            result in
            switch result {
            case .success(let configuration):
                let endBlockTime = CACurrentMediaTime()
                self.blockTime = (endBlockTime - startBlockTime) * 1000
                guard configuration.fingerprintIntegration.enabled, let fingerprintPublicKey = configuration.fingerprintIntegration.publicKey else {
                    self.loggerService.log(riskEvent: .publishDisabled, blockTime: self.blockTime, deviceDataPersistTime: nil, fpLoadTime: nil, fpPublishTime: nil, deviceSessionId: nil, requestId: nil, error: RiskLogError(reason: "getConfiguration", message: RiskError.Configuration.integrationDisabled.localizedDescription, status: nil, type: "Error"))
                    
                    return completion(.failure(.integrationDisabled))
                }
                
                completion(.success(
                    FingerprintConfiguration.init(publicKey: fingerprintPublicKey, blockTime: self.blockTime)))
            case .failure(let error):
                self.loggerService.log(riskEvent: .loadFailure, blockTime: nil, deviceDataPersistTime: nil, fpLoadTime: nil, fpPublishTime: nil, deviceSessionId: nil, requestId: nil, error: RiskLogError(reason: "getConfiguration", message: error.localizedDescription, status: nil, type: "Error"))
                return completion(.failure(.couldNotRetrieveConfiguration))
            }
        }
    }
    
    func persistFpData(fingerprintRequestId: String, fpLoadTime: Double, fpPublishTime: Double, cardToken: String?, completion: @escaping (Result<PersistDeviceDataResponse, RiskError.Publish>) -> Void) {
        let startPersistTime = CACurrentMediaTime()
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
                let endPersistTime = CACurrentMediaTime()
                let persistTime = (endPersistTime - startPersistTime) * 1000
                self.loggerService.log(riskEvent: .published, blockTime: self.blockTime, deviceDataPersistTime: persistTime, fpLoadTime: fpLoadTime, fpPublishTime: fpPublishTime, deviceSessionId: response.deviceSessionId, requestId: fingerprintRequestId, error: nil)
                
                completion(.success(response))
            case .failure(let error):
                self.loggerService.log(riskEvent: .publishFailure, blockTime: self.blockTime, deviceDataPersistTime: nil, fpLoadTime: fpLoadTime, fpPublishTime: fpPublishTime, deviceSessionId: nil, requestId: nil, error: RiskLogError(reason: "persistFpData", message: error.localizedDescription, status: nil, type: "Error"))
                
                completion(.failure(.couldNotPersisRiskData))
            }
        }
    }
}
