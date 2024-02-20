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
    func getConfiguration(completion: @escaping (Result<DeviceDataConfiguration, RiskError>) -> Void)
    func persistFpData(fingerprintRequestId: String, cardToken: String?, completion: @escaping (Result<PersistDeviceDataResponse, RiskError>) -> Void)
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

    func getConfiguration(completion: @escaping (Result<DeviceDataConfiguration, RiskError>) -> Void) {
        let endpoint = "\(config.deviceDataEndpoint)/configuration?integrationType=\(config.integrationType.rawValue)&riskSdkVersion=\(Constants.riskSdkVersion)"
        let authToken = config.merchantPublicKey

        apiService.getJSONFromAPIWithAuthorization(endpoint: endpoint, authToken: authToken, responseType: DeviceDataConfiguration.self) {
            result in
            switch result {
            case .success(let configuration):

                guard configuration.fingerprintIntegration.enabled && configuration.fingerprintIntegration.publicKey != nil else {
                    loggerService.log(riskEvent: .publishDisabled, deviceSessionId: nil, requestId: nil, error: RiskLogError(reason: "getConfiguration", message: "Integration disabled", status: nil, type: "Error"))

                    return completion(.failure(RiskError.integrationDisabled))
                }

                completion(.success(configuration))
            case .failure(let error):

                loggerService.log(riskEvent: .loadFailure, deviceSessionId: nil, requestId: nil, error: RiskLogError(reason: "getConfiguration", message: error.localizedDescription, status: nil, type: "Error"))
                return completion(.failure(RiskError.couldNotRetrieveConfiguration))
            }
        }
    }

    func persistFpData(fingerprintRequestId: String, cardToken: String?, completion: @escaping (Result<PersistDeviceDataResponse, RiskError>) -> Void) {
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

                completion(.failure(RiskError.couldNotPersisRiskData))
            }
        }
    }

}
