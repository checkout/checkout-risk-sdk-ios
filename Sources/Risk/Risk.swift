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
  private let deviceDataService: DeviceDataService
  private let loggerService: LoggerServiceProtocol
  
  private var fingerprintService: FingerprintService?
  
  public init(config: RiskConfig) {
    internalConfig = RiskSDKInternalConfig(config: config)
    loggerService = LoggerService(internalConfig: internalConfig)
    deviceDataService = DeviceDataService(config: internalConfig, loggerService: loggerService)
  }
  
  public func configure(completion: @escaping (Error?) -> Void) {
    deviceDataService.getConfiguration { [weak self] result in
      guard let self = self else { return }
      
      switch result {
      case .success(let configuration):
        let fingerprintPublicKey = configuration.fingerprintIntegration.publicKey
        self.fingerprintService = FingerprintService(fingerprintPublicKey: fingerprintPublicKey,
                                                     internalConfig: self.internalConfig,
                                                     loggerService: self.loggerService)
        completion(nil)
        
      case .failure(let error):
        return completion(error)
      }
    }
  }
  
  public func publishData (cardToken: String? = nil, completion: @escaping (Result<PublishRiskData, RiskError>) -> Void) {
    guard let fingerprintService = fingerprintService else {
      completion(.failure(.fingerprintServiceIsNotConfigured))
      return
    }
    
    fingerprintService.publishData { [weak self] fpResult in
      guard let self = self else { return }
      
      switch fpResult {
      case .success(let requestId):
        self.persistFpData(cardToken: cardToken, fingerprintRequestId: requestId, completion: completion)
        
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
  
  private func persistFpData(cardToken: String?, fingerprintRequestId: String, completion: @escaping (Result<PublishRiskData, RiskError>) -> Void) {
    self.deviceDataService.persistFpData(fingerprintRequestId: fingerprintRequestId, cardToken: cardToken) { result in
      switch result {
      case .success(let response):
        completion(.success(PublishRiskData(deviceSessionId: response.deviceSessionId)))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
}
