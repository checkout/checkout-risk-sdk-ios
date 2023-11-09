//
//  DeviceDataService.swift
//  Risk
//  Sources
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

struct DeviceDataService {
    public let config: RiskSDKInternalConfig
    public let apiService: APIServiceProtocol
    
    public init(config: RiskSDKInternalConfig, apiService: APIServiceProtocol = APIService()) {
        self.config = config
        self.apiService = apiService
    }
    
    public func getConfiguration(completion: @escaping (DeviceDataConfiguration) -> Void) {
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
