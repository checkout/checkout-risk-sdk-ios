//
//  File.swift
//  
//
//  Created by Precious Ossai on 30/10/2023.
//

import Foundation

public struct FingerprintIntegration: Decodable, Equatable {
    let enabled: Bool
    let publicKey: String?
}

public struct DeviceDataConfiguration: Decodable, Equatable {
    let fingerprintIntegration: FingerprintIntegration
}

internal class DeviceDataService {
    public var config: RiskSdkInternalConfig
    public var apiService: ApiServiceProtocol
    
    public init(config: RiskSdkInternalConfig, apiService:ApiServiceProtocol = ApiService()) {
        self.config = config
        self.apiService = apiService
    }
    
    public func getConfiguration(completion: @escaping (DeviceDataConfiguration) -> Void) {
        let endpoint = "\(self.config.deviceDataEndpoint)/configuration?integrationType=\(self.config.integrationType)"
        let authToken = self.config.merchantPublicKey

        apiService.getJSONFromAPIWithAuthorization(endpoint: endpoint, authToken: authToken, responseType: DeviceDataConfiguration.self) {
            result in
            switch result {
            case .success(let configuration):
                completion(configuration)
            case .failure:
                completion(DeviceDataConfiguration(fingerprintIntegration: FingerprintIntegration(enabled: false, publicKey: nil)))
            }
        }
    }

}
