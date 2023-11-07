//
//  Risk.swift
//  Risk
//  Sources
//
//  Created by Precious Ossai on 13/10/2023.
//

import Foundation

public class Risk {
    private static var sharedInstance: Risk?
    private let fingerprintService: FingerprintService
    
    private init(fingerprintService: FingerprintService) {
        self.fingerprintService = fingerprintService
    }
    
    public static func createInstance(config: RiskConfig, completion: @escaping (Risk?) -> Void) {
        guard sharedInstance === nil else {
            return completion(sharedInstance)
        }
        
        let internalConfig = RiskSDKInternalConfig(config: config)
        let deviceDataService = DeviceDataService(config: internalConfig)
        
        deviceDataService.getConfiguration {
            configuration in
            
            guard configuration.fingerprintIntegration.enabled else {
                return completion(nil)
            }
                
            let fingerprintService = FingerprintService(fingerprintPublicKey: configuration.fingerprintIntegration.publicKey!, internalConfig: internalConfig)
            
            let riskInstance = Risk(fingerprintService: fingerprintService)
            sharedInstance = riskInstance
                
            completion(riskInstance)
        }
    }
    
    public func publishData () {
        
        self.fingerprintService.publishData(cardToken: nil) { requestId in
            print("Published to Fingerprint with requestId: \(requestId)")
        }
    }
}
