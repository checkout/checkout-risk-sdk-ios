//
//  Risk.swift
//  Risk
//  Sources
//
//  Created by Precious Ossai on 13/10/2023.
//

import Foundation

public final class Risk {
    private let internalConfig: RiskSDKInternalConfig
    private var timer: Timer?
    private var blockTime: Double?
    var fingerprintTimeoutInterval: Double = 3.00
    
    var loggerService: LoggerServiceProtocol
    var deviceDataService: DeviceDataServiceProtocol
    var fingerprintService: FingerprintServiceProtocol?
    
    public init(config: RiskConfig) {
        internalConfig = RiskSDKInternalConfig(config: config)
        loggerService = LoggerService(internalConfig: internalConfig)
        deviceDataService = DeviceDataService(config: internalConfig, loggerService: loggerService)
    }
    
    public func configure(completion: @escaping (Result<Void, RiskError.Configuration>) -> Void) {
        deviceDataService.getConfiguration { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let configuration):
                blockTime = configuration.blockTime
                self.fingerprintService = FingerprintService(
                    fingerprintPublicKey: configuration.publicKey,
                    internalConfig: self.internalConfig,
                    loggerService: self.loggerService,
                    blockTime: configuration.blockTime
                )
                completion(.success(()))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func publishData(cardToken: String? = nil, completion: @escaping (Result<PublishRiskData, RiskError.Publish>) -> Void) {
        guard let fingerprintService else {
          completion(.failure(.fingerprintServiceIsNotConfigured))
          return
        }

        DispatchQueue.main.async {
            // Timer setup remains on the main queue
            self.timer = Timer.scheduledTimer(withTimeInterval: self.fingerprintTimeoutInterval, repeats: false) { [weak self] _ in // 3.00
            guard let self else { return }
              
                self.loggerService.log(riskEvent: .publishFailure, blockTime: self.blockTime, deviceDataPersistTime: nil, fpLoadTime: fingerprintService.fpLoadTime, fpPublishTime: nil, deviceSessionId: nil, requestId: nil, error: RiskLogError(reason: "publishData", message: RiskError.Publish.fingerprintTimeout.localizedDescription, status: nil, type: "Timeout"))
                completion(.failure(.fingerprintTimeout))
          }
        }

        fingerprintService.publishData { [weak self] fpResult in
          guard let self = self else { return }

          DispatchQueue.main.async {
            guard let timer = self.timer, timer.isValid else { // 2.59 -> valid
              return
            }

            // Timer invalidation remains on the main queue
            self.timer?.invalidate()
            self.timer = nil

            switch fpResult {
            case .success(let response):
              self.persistFpData(cardToken: cardToken, fingerprintRequestId: response.requestId, fpLoadTime: response.fpLoadTime, fpPublishTime: response.fpPublishTime, completion: completion)

            case .failure(let error):
              completion(.failure(error))
            }
          }
        }
    }
    
    private func persistFpData(cardToken: String?, fingerprintRequestId: String, fpLoadTime: Double, fpPublishTime: Double, completion: @escaping (Result<PublishRiskData, RiskError.Publish>) -> Void) {
        self.deviceDataService.persistFpData(fingerprintRequestId: fingerprintRequestId, fpLoadTime: fpLoadTime, fpPublishTime: fpPublishTime, cardToken: cardToken) { result in
            switch result {
            case .success(let response):
                completion(.success(PublishRiskData(deviceSessionId: response.deviceSessionId)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
