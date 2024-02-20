//
//  Risk.swift
//  Risk
//  Sources
//
//  Created by Precious Ossai on 13/10/2023.
//

import Foundation

public class Risk {
    private let fingerprintService: FingerprintService
    private let deviceDataService: DeviceDataService
    private let loggerService: LoggerServiceProtocol

    private init(fingerprintService: FingerprintService, deviceDataService: DeviceDataService, loggerService: LoggerServiceProtocol) {
        self.fingerprintService = fingerprintService
        self.deviceDataService = deviceDataService
        self.loggerService = loggerService
    }

    public static func getInstance(config: RiskConfig, completion: @escaping (Risk?) -> Void) {
        let internalConfig = RiskSDKInternalConfig(config: config)
        let loggerService = LoggerService(internalConfig: internalConfig)
        let deviceDataService = DeviceDataService(config: internalConfig, loggerService: loggerService)

        deviceDataService.getConfiguration { result in

            switch result {
            case .failure:
                return completion(nil)
            case .success(let configuration):
                let fingerprintPublicKey = configuration.fingerprintIntegration.publicKey!
                let fingerprintService = FingerprintService(fingerprintPublicKey: fingerprintPublicKey, internalConfig: internalConfig, loggerService: loggerService)
                let riskInstance = Risk(fingerprintService: fingerprintService, deviceDataService: deviceDataService, loggerService: loggerService)

                completion(riskInstance)
            }

        }
    }

    public func publishData (cardToken: String? = nil, completion: @escaping (Result<PublishRiskData, RiskError>) -> Void) {
      fingerprintService.publishData { [weak self] fpResult in
            switch fpResult {
            case .failure(let errorMessage):
                completion(.failure(errorMessage))
            case .success(let requestId):
                self?.persistFpData(cardToken: cardToken, fingerprintRequestId: requestId, completion: completion)
            }
        }
    }

    private func persistFpData(cardToken: String?, fingerprintRequestId: String, completion: @escaping (Result<PublishRiskData, RiskError>) -> Void) {
        self.deviceDataService.persistFpData(fingerprintRequestId: fingerprintRequestId, cardToken: cardToken) { result in
            switch result {
            case .success(let response):
                completion(.success(PublishRiskData(deviceSessionId: response.deviceSessionId)))
            case .failure(let errorMessage):
                completion(.failure(errorMessage))
            }
        }
    }
}
