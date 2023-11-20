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
    
    private init(fingerprintService: FingerprintService, deviceDataService: DeviceDataService) {
        self.fingerprintService = fingerprintService
        self.deviceDataService = deviceDataService
    }
    
    public static func createInstance(config: RiskConfig, completion: @escaping (Risk?) -> Void) {
        guard sharedInstance === nil else {
            return completion(sharedInstance)
        }
        
        let internalConfig = RiskSDKInternalConfig(config: config)
        let deviceDataService = DeviceDataService(config: internalConfig)
        
        deviceDataService.getConfiguration { result in
            
            switch(result) {
            case .failure:
                return completion(nil)
            case .success(let configuration):
                let fingerprintPublicKey = configuration.fingerprintIntegration.publicKey!
                let fingerprintService = FingerprintService(fingerprintPublicKey: fingerprintPublicKey, internalConfig: internalConfig)
                let riskInstance = Risk(fingerprintService: fingerprintService, deviceDataService: deviceDataService)
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
                self.deviceDataService.persistFpData(fingerprintRequestID: requestID, cardToken: cardToken) { result in
                    switch(result) {
                    case .success(let response):
                        completion(.success(PublishRiskData(deviceSessionID: response.deviceSessionID)))
                    case .failure(let errorMessage):
                        completion(.failure(errorMessage))
                    }
                }
            }
        }
    }
}
