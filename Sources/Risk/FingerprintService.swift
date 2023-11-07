//
//  FingerprintService.swift
//  
//
//  Created by Precious Ossai on 31/10/2023.
//

import FingerprintPro
import Foundation

class FingerprintService {
    private var requestId: String? = nil
    private let client: FingerprintClientProviding
    private let internalConfig: RiskSDKInternalConfig
    
    init(fingerprintPublicKey: String, internalConfig: RiskSDKInternalConfig) {
        print("Initialising fingerprint")
        
        let customDomain: Region = .custom(domain: internalConfig.fingerprintEndpoint)
        let configuration = Configuration(apiKey: fingerprintPublicKey, region: customDomain)
        self.client = FingerprintProFactory.getInstance(configuration)
        self.internalConfig = internalConfig
    }
    
    public func publishData(cardToken: String?, completion: @escaping (String?) -> Void) {
        
            guard self.requestId == nil else {
                return completion(self.requestId)
            }
            
        let metaTags = self.internalConfig.createFpTags()
        
        self.client.getVisitorIdResponse(metaTags) { result in
            
            switch result {
            case let .failure(error):
                print("Error: ", error.localizedDescription)
            case let .success(response):
                self.requestId = response.requestId
                return completion(response.requestId)
            }
        }
    }
    
}