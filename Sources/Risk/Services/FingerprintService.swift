//
//  FingerprintService.swift
//
//
//  Created by Precious Ossai on 31/10/2023.
//

import FingerprintPro
import Foundation
import QuartzCore

protocol FingerprintServiceProtocol {
    func publishData(completion: @escaping (Result<FpPublishData, RiskError.Publish>) -> Void)
}

extension FingerprintServiceProtocol {
    func createMetadata(sourceType: SourceType.RawValue) -> Metadata {
        var meta = Metadata()
        meta.setTag(sourceType, forKey: "fpjsSource")
        meta.setTag(Date().timeIntervalSince1970 * 1000, forKey: "fpjsTimestamp")
        
        return meta
    }
}

struct FpPublishData {
    let requestId: String
    let fpLoadTime: Double
    let fpPublishTime: Double
}

final class FingerprintService: FingerprintServiceProtocol {
    private var requestId: String?
    private let client: FingerprintClientProviding
    private let internalConfig: RiskSDKInternalConfig
    private let loggerService: LoggerServiceProtocol
    private let fpLoadTime: Double
    private var fpPublishTime: Double
    
    init(fingerprintPublicKey: String, internalConfig: RiskSDKInternalConfig, loggerService: LoggerServiceProtocol) {
        
        let startBlockTime = CACurrentMediaTime()
        
        let customDomain: Region = .custom(domain: internalConfig.fingerprintEndpoint)
        let configuration = Configuration(apiKey: fingerprintPublicKey, region: customDomain)
        client = FingerprintProFactory.getInstance(configuration)
        let endBlockTime = CACurrentMediaTime()
        self.fpLoadTime = (endBlockTime - startBlockTime) * 1000
        self.fpPublishTime = 0.00
        
        self.internalConfig = internalConfig
        self.loggerService = loggerService
    }
    
    func publishData(completion: @escaping (Result<FpPublishData, RiskError.Publish>) -> Void) {
        let startFpPublishTime = CACurrentMediaTime()
        
        guard requestId == nil else {
            return completion(.success(FpPublishData(requestId: requestId!, fpLoadTime: self.fpLoadTime, fpPublishTime: self.fpPublishTime)))
        }
        
        let metadata = createMetadata(sourceType: internalConfig.sourceType.rawValue)
        
        client.getVisitorIdResponse(metadata) { [weak self] result in
            let endFpPublishTime = CACurrentMediaTime()
            self?.fpPublishTime = (endFpPublishTime - startFpPublishTime) * 1000
            
            switch result {
            case .failure(let error):
                self?.loggerService.log(riskEvent: .publishFailure, blockTime: nil, deviceDataPersistTime: nil, fpLoadTime: self?.fpLoadTime, fpPublishTime: self?.fpPublishTime, deviceSessionId: nil, requestId: nil, error: RiskLogError(reason: "publishData", message: error.localizedDescription, status: nil, type: "Error"))
                
                return completion(.failure(.couldNotPublishRiskData))
            case let .success(response):
                self?.loggerService.log(riskEvent: .collected, blockTime: nil, deviceDataPersistTime: nil, fpLoadTime: self?.fpLoadTime, fpPublishTime: self?.fpPublishTime, deviceSessionId: nil, requestId: response.requestId, error: nil)
                self?.requestId = response.requestId
                
                completion(.success(FpPublishData(requestId: response.requestId, fpLoadTime: self?.fpLoadTime ?? 0.00, fpPublishTime: self?.fpPublishTime ?? 0.00)))
            }
        }
    }
    
    
}
