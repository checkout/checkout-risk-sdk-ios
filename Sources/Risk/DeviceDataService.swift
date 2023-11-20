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

struct DeviceDataConfiguration: Decodable, Equatable {
    let fingerprintIntegration: FingerprintIntegration
}

struct PersistDeviceDataServiceData: Codable, Equatable {
    
    private enum CodingKeys: String, CodingKey {
        case integrationType, fingerprintRequestID = "fpRequestId", cardToken
    }
    
    let integrationType: RiskIntegrationType
    let fingerprintRequestID: String
    let cardToken: String?
}

struct PersistDeviceDataResponse: Decodable, Equatable {
    let deviceSessionID: String
    
    private enum CodingKeys: String, CodingKey {
        case deviceSessionID = "deviceSessionId"
    }
}

struct DeviceDataService {
    let config: RiskSDKInternalConfig
    let apiService: APIServiceProtocol
    
    init(config: RiskSDKInternalConfig, apiService: APIServiceProtocol = APIService()) {
        self.config = config
        self.apiService = apiService
    }
    
    func getConfiguration(completion: @escaping (DeviceDataConfiguration) -> Void) {
        let endpoint = "\(config.deviceDataEndpoint)/configuration?integrationType=\(config.integrationType.rawValue)"
        let authToken = config.merchantPublicKey
        
        apiService.getJSONFromAPIWithAuthorization(endpoint: endpoint, authToken: authToken, responseType: DeviceDataConfiguration.self) {
            result in
            switch result {
            case .success(let configuration):
                #warning("TODO: - Handle disabled fingerpint integraiton, e.g. dispatch and/or log event (https://checkout.atlassian.net/browse/PRISM-10482)")
                completion(configuration)
            case .failure:
                #warning("TODO: - Handle the error here (https://checkout.atlassian.net/browse/PRISM-10482)")
                completion(DeviceDataConfiguration(fingerprintIntegration: FingerprintIntegration(enabled: false, publicKey: nil)))
            }
        }
    }
    
    func persistFpData(fingerprintRequestID: String, cardToken: String?, completion: @escaping (Result<PersistDeviceDataResponse, PublishRiskDataError>) -> Void) {
        let endpoint = "\(config.deviceDataEndpoint)/fingerprint"
        let authToken = config.merchantPublicKey
        let integrationType = config.integrationType
        
        let data = PersistDeviceDataServiceData(
            integrationType: integrationType,
            fingerprintRequestID: fingerprintRequestID,
            cardToken: cardToken
        )
        
        apiService.putDataToAPIWithAuthorization(endpoint: endpoint, authToken: authToken, data: data, responseType: PersistDeviceDataResponse.self) { result in
            
            switch result {
            case .success(let response):
                #warning("TODO: - dispatch and/or log published event (https://checkout.atlassian.net/browse/PRISM-10482)")
                completion(.success(response))
            case .failure:
                #warning("TODO: - Handle the error here (https://checkout.atlassian.net/browse/PRISM-10482)")
                completion(.failure(PublishRiskDataError.description("Error persisting risk data")))
            }
        }
    }
    
}
