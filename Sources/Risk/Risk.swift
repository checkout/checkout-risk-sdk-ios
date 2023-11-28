//
//  Risk.swift
//  Risk
//  Sources
//
//  Created by Precious Ossai on 13/10/2023.
//

import Foundation

public struct PublishRiskData {
    public let deviceSessionID: String
}

public enum RiskError: Error, Equatable {
    case description(String)
    
    var localizedDescription: String {
        switch self {
        case .description(let errorMessage):
            return errorMessage
        }
    }
}

public class Risk {
    private static var sharedInstance: Risk?
    private let fingerprintService: FingerprintService
    private let deviceDataService: DeviceDataService
    private let loggerService: LoggerServiceProtocol
    
    private init(fingerprintService: FingerprintService, deviceDataService: DeviceDataService, loggerService: LoggerServiceProtocol) {
        self.fingerprintService = fingerprintService
        self.deviceDataService = deviceDataService
        self.loggerService = loggerService
    }
    
    public static func getInstance(config: RiskConfig, completion: @escaping (Risk?) -> Void) {
        guard sharedInstance === nil else {
            return completion(sharedInstance)
        }
        
        let internalConfig = RiskSDKInternalConfig(config: config)
        let loggerService = LoggerService(internalConfig: internalConfig)
        let deviceDataService = DeviceDataService(config: internalConfig, loggerService: loggerService)
        
        deviceDataService.getConfiguration { result in
            
            switch(result) {
            case .failure:
                return completion(nil)
            case .success(let configuration):
                let fingerprintPublicKey = configuration.fingerprintIntegration.publicKey!
                let fingerprintService = FingerprintService(fingerprintPublicKey: fingerprintPublicKey, internalConfig: internalConfig, loggerService: loggerService)
                let riskInstance = Risk(fingerprintService: fingerprintService, deviceDataService: deviceDataService, loggerService: loggerService)
                sharedInstance = riskInstance
                
                completion(riskInstance)
            }
            
        }
    }
    
    public func publishData (cardToken: String? = nil, completion: @escaping (Result<PublishRiskData, RiskError>) -> Void) {
        fingerprintService.publishData() { fpResult in
            switch(fpResult) {
            case .failure(let errorMessage):
                completion(.failure(errorMessage))
            case .success(let requestID):
                self.persistFpData(cardToken: cardToken, fingerprintRequestID: requestID, completion: completion)
            }
        }
    }
    
    private func persistFpData(cardToken: String?, fingerprintRequestID: String, completion: @escaping (Result<PublishRiskData, RiskError>) -> Void) {
        self.deviceDataService.persistFpData(fingerprintRequestID: fingerprintRequestID, cardToken: cardToken) { result in
            switch(result) {
            case .success(let response):
                completion(.success(PublishRiskData(deviceSessionID: response.deviceSessionID)))
            case .failure(let errorMessage):
                completion(.failure(errorMessage))
            }
        }
    }
}
