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

struct DeviceDataService {
    let config: RiskSDKInternalConfig
    let apiService: APIServiceProtocol
    
    init(config: RiskSDKInternalConfig, apiService: APIServiceProtocol = APIService()) {
        self.config = config
        self.apiService = apiService
    }
    
    func getConfiguration(completion: @escaping (DeviceDataConfiguration) -> Void) {
        let endpoint = "\(config.deviceDataEndpoint)/configuration?integrationType=\(config.integrationType)"
        let authToken = config.merchantPublicKey

        apiService.getJSONFromAPIWithAuthorization(endpoint: endpoint, authToken: authToken, responseType: DeviceDataConfiguration.self) {
            result in
            switch result {
            case .success(let configuration):
                // #warning("TODO: - Handle disabled fingerpint integraiton, e.g. dispatch and/or log event (https://checkout.atlassian.net/browse/PRISM-10482)")
                completion(configuration)
            case .failure:
                // #warning("TODO: - Handle the error here (https://checkout.atlassian.net/browse/PRISM-10482)")
                completion(DeviceDataConfiguration(fingerprintIntegration: FingerprintIntegration(enabled: false, publicKey: nil)))
            }
        }
    }

}
