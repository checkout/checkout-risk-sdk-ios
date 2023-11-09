//
//  FingerprintService.swift
//  
//
//  Created by Precious Ossai on 31/10/2023.
//

import FingerprintPro
import Foundation

final class FingerprintService {
    private var requestID: String? = nil
    private let client: FingerprintClientProviding
    private let internalConfig: RiskSDKInternalConfig
    
    init(fingerprintPublicKey: String, internalConfig: RiskSDKInternalConfig) {
        let customDomain: Region = .custom(domain: internalConfig.fingerprintEndpoint)
        let configuration = Configuration(apiKey: fingerprintPublicKey, region: customDomain)
        client = FingerprintProFactory.getInstance(configuration)
        self.internalConfig = internalConfig
    }
    
    func publishData(cardToken: String?, completion: @escaping (String?) -> Void) {
        
        guard requestID == nil else {
            return completion(requestID)
        }
            
        let metadata = createMetadata(sourceType: internalConfig.sourceType)
        
        client.getVisitorIdResponse(metadata) { [weak self] result in
            
            switch result {
            case let .failure(error):
                // #warning("TODO: - Handle the error here (https://checkout.atlassian.net/browse/PRISM-10482)")
                print("Error: ", error.localizedDescription)
            case let .success(response):
                // #warning("TODO: - Dispatch collected event and/or log (https://checkout.atlassian.net/browse/PRISM-10482)")
                self?.requestID = response.requestId
                return completion(response.requestId)
            }
        }
    }
    
    func createMetadata(sourceType: SourceType.RawValue) -> Metadata {
        var meta = Metadata()
        meta.setTag(sourceType, forKey: "fpjsSource")
        meta.setTag(Date().timeIntervalSince1970 * 1000, forKey: "fpjsTimestamp")
        
        return meta
    }
    
}
