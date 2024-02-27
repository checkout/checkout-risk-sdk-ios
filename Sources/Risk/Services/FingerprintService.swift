//
//  FingerprintService.swift
//
//
//  Created by Precious Ossai on 31/10/2023.
//

import FingerprintPro
import Foundation

protocol FingerprintServiceProtocol {
    func publishData(completion: @escaping (Result<String, RiskError.Publish>) -> Void)
}

extension FingerprintServiceProtocol {
    func createMetadata(sourceType: SourceType.RawValue) -> Metadata {
        var meta = Metadata()
        meta.setTag(sourceType, forKey: "fpjsSource")
        meta.setTag(Date().timeIntervalSince1970 * 1000, forKey: "fpjsTimestamp")
        
        return meta
    }
}

final class FingerprintService: FingerprintServiceProtocol {
    private var requestId: String?
    private let client: FingerprintClientProviding
    private let internalConfig: RiskSDKInternalConfig
    private let loggerService: LoggerServiceProtocol
    
    init(fingerprintPublicKey: String, internalConfig: RiskSDKInternalConfig, loggerService: LoggerServiceProtocol) {
        let customDomain: Region = .custom(domain: internalConfig.fingerprintEndpoint)
        let configuration = Configuration(apiKey: fingerprintPublicKey, region: customDomain)
        client = FingerprintProFactory.getInstance(configuration)
        self.internalConfig = internalConfig
        self.loggerService = loggerService
    }
    
    func publishData(completion: @escaping (Result<String, RiskError.Publish>) -> Void) {
        
        guard requestId == nil else {
            return completion(.success(requestId!))
        }
        
        let metadata = createMetadata(sourceType: internalConfig.sourceType.rawValue)
        
        client.getVisitorIdResponse(metadata) { [weak self] result in
            
            switch result {
            case .failure(let error):
                self?.loggerService.log(riskEvent: .publishFailure, deviceSessionId: nil, requestId: nil, error: RiskLogError(reason: "publishData", message: error.localizedDescription, status: nil, type: "Error"))
                
                return completion(.failure(.couldNotPublishRiskData))
            case let .success(response):
                self?.loggerService.log(riskEvent: .collected, deviceSessionId: nil, requestId: response.requestId, error: nil)
                self?.requestId = response.requestId
                
                completion(.success(response.requestId))
            }
        }
    }
    
    
}
